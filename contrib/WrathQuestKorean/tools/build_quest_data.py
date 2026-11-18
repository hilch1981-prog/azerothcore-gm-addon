#!/usr/bin/env python3
"""Convert pinned world SQL snapshots into a read-only Lua data pack."""
import argparse
from collections import Counter
import json
from pathlib import Path
import re

INSERT = re.compile(r"^INSERT(?: IGNORE)? INTO `(\w+)`(?:\s*\(([`\w, ]+)\))?\s+VALUES\s*")
CREATE = re.compile(r"^CREATE TABLE `(\w+)`")
DOUBLE_QUOTED = r'"(?:\\.|""|[^"\\])*"'
SQL_VALUE = DOUBLE_QUOTED + "|" + r"'(?:\\.|''|[^'\\])*'|NULL|-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?"
ROW = re.compile(r"\(\s*(" + SQL_VALUE + r")(?:\s*,\s*(?:" + SQL_VALUE + r"))*\s*\)")
VALUE = re.compile(SQL_VALUE)
ESCAPES = {"0": "\0", "n": "\n", "r": "\r", "t": "\t", "b": "\b", "Z": "\x1a"}
HANGUL = re.compile(r"[가-힣]")
TOKEN = re.compile(r"\$[A-Za-z]")
SUPPORTED = re.compile(r"\$[bBnNcCrR]|\$[gG][^:;]*:[^;]*;")

FIELDS = {
    "quest_template": {
        "title": ("LogTitle", "Title"),
        "description": ("QuestDescription", "Details"),
        "objectives": ("LogDescription", "Objectives"),
    },
    "quest_request_items": {"progress": ("CompletionText", "CompletionText")},
    "quest_offer_reward": {"completion": ("RewardText", "RewardText")},
}


def decode(token):
    if token == "NULL":
        return None
    if token[0] in ("'", '"'):
        escape = re.compile(r"\\(.)|" + re.escape(token[0] * 2))
        return escape.sub(lambda m: ESCAPES.get(m[1], m[1]) if m[1] else token[0], token[1:-1])
    return token


def records(paths, wanted):
    for path in paths:
        columns = {}
        table = schema = None
        with path.open(encoding="utf-8-sig") as source:
            for line in source:
                if table:
                    pieces = list(ROW.finditer(line))
                    remainder = ROW.sub("", line).strip(" \r\n,;")
                    if remainder:
                        raise ValueError(f"Unsupported SQL tuple in {path} ({table}): {remainder[:90]!r}")
                    for match in pieces:
                        values = VALUE.findall(match[0])
                        if len(values) != len(columns[table]):
                            raise ValueError((path, table, len(values), len(columns[table])))
                        yield table, dict(zip(columns[table], map(decode, values)))
                    if line.rstrip().endswith(";"):
                        table = None
                    continue
                if match := CREATE.match(line):
                    schema = match[1] if match[1] in wanted else None
                    if schema:
                        columns[schema] = []
                    continue
                if schema:
                    if match := re.match(r"^\s+`([A-Za-z0-9_]+)`\s", line):
                        columns[schema].append(match[1])
                    elif line.startswith(")"):
                        schema = None
                if (match := INSERT.match(line)) and match[1] in wanted:
                    table = match[1]
                    if match[2]:
                        columns[table] = re.findall(r"`(\w+)`", match[2])
                    if line[match.end():].strip():
                        raise ValueError(f"Expected VALUES to start on a new line in {path}")


def keyed(rows, locale=False):
    result = {}
    for table, row in rows:
        if locale and row.get("locale", row.get("Locale")) != "koKR":
            continue
        key = (table, int(row["ID"]))
        current = result.setdefault(key, {})
        current.update({field: value for field, value in row.items() if value is not None})
    return result


def normalize(value):
    value = re.sub(r"\$[bB]", " ", value)
    value = re.sub(r"\$([nNcCrRgG])", lambda m: "$" + m[1].lower(), value)
    value = value.translate(str.maketrans({"’": "'", "‘": "'", "“": '"', "”": '"', "\xa0": " "}))
    value = re.sub(r"[ \t\r\n\v\f]+", " ", value).strip(" ")
    return value.translate(str.maketrans("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz"))


def runtime_key(value):
    if TOKEN.search(re.sub(r"\$[bB]", "", value)):
        return value
    length = len(normalize(value).encode("utf-8"))
    checksum = 0
    for byte in normalize(value).encode("utf-8"):
        checksum = (checksum * 131 + byte) % 2147483647
    return [length, checksum]


def lua(value):
    if isinstance(value, list):
        return "{" + ",".join(map(str, value)) + "}"
    return json.dumps(value, ensure_ascii=False).replace("\\u0000", "\\000")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--ids", nargs="*", type=int)
    args = parser.parse_args()
    folder = args.source
    tables = tuple(FIELDS)
    locale_tables = {table + "_locale" for table in tables}
    wotlk = keyed(records((folder / f"{table}.sql" for table in tables), tables))
    ac_pr = keyed(records([folder / "ac-pr.sql"], locale_tables), True)

    quests, counts = {}, Counter()
    for (table, quest_id), row in wotlk.items():
        parent = wotlk.get(("quest_template", quest_id), {})
        if not parent.get("LogTitle") or (args.ids and quest_id not in args.ids):
            continue
        locale_key = table + "_locale", quest_id
        for field, (english_col, ac_col) in FIELDS[table].items():
            english = row.get(english_col)
            if not english or not normalize(english) or TOKEN.search(SUPPORTED.sub("", english)):
                continue
            text = ac_pr.get(locale_key, {}).get(ac_col)
            if not text or not HANGUL.search(text) or TOKEN.search(SUPPORTED.sub("", text)):
                continue
            quest = quests.setdefault(quest_id, {"enTitle": parent["LogTitle"]})
            quest[field] = text if field == "title" else (runtime_key(english), text)
            counts[field] += 1

    if not quests:
        raise ValueError("No AzerothCore PR #27829 translations emitted")
    with args.output.open("w", encoding="utf-8", newline="\n") as out:
        out.write("-- Korean quest translations from AzerothCore WotLK PR #27829. See README.md.\n")
        out.write("local _, addon = ...\naddon.quests = {}\nlocal quests = addon.quests\n")
        for quest_id, row in sorted(quests.items()):
            values = []
            for field, value in row.items():
                if isinstance(value, tuple):
                    guard, text = value
                    values.append(f"{field}={{{lua(guard)},{lua(text)}}}")
                else:
                    values.append(f"{field}={lua(value)}")
            out.write(f"quests[{quest_id}]={{{','.join(values)}}}\n")
    print(json.dumps(dict(quests=len(quests), fields=counts, source="AzerothCore#27829"), ensure_ascii=False))


if __name__ == "__main__":
    main()
