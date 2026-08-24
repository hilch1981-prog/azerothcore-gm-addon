#!/usr/bin/env python3
"""Build a WotLK 3.3.5a creaturecache patch from AzerothCore SQL.

The record payload mirrors AzerothCore WorldSession::HandleCreatureQueryOpcode.
The output is a PATCH WDB only: cacheVersion is intentionally 0. The installer
must preserve the user's live 24-byte header and append only missing records.
"""
from __future__ import annotations

import argparse
import csv
import re
import struct
from pathlib import Path
from typing import Iterator

FEATURE_RE = re.compile(
    r'\{\s*(\d+),\s*"[^"]+",\s*"(?:raid|dungeon|world|rare|event|utility|leader)",\s*'
    r'"(?:classic|tbc|wotlk)",\s*"[^"]+",\s*(?:true|false)\s*\}'
)

HEADER_SIZE = 24
BUILD = 12340
LOCALE = b"RKok"
RECORD_SIZE = 96
RECORD_VERSION = 1
MAX_QUEST_ITEMS = 6


def featured_entries(addon: Path) -> set[int]:
    entries: set[int] = set()
    for name in ("FeaturedCreatures.lua", "FeaturedCreaturesExpanded.lua"):
        entries.update(map(int, FEATURE_RE.findall((addon / name).read_text(encoding="utf-8-sig"))))
    return entries


def parse_sql_tuple(value: str) -> list[str | None]:
    """Parse one SQL VALUES tuple body using the legacy dump escape rules."""
    row = next(
        csv.reader(
            [value],
            delimiter=",",
            quotechar="'",
            escapechar="\\",
            doublequote=True,
            skipinitialspace=True,
        )
    )
    return [None if item.strip().upper() == "NULL" else item.strip() for item in row]


def statement_is_complete(text: str) -> bool:
    """Return True when an unquoted semicolon terminates the INSERT statement."""
    quoted = False
    escaped = False
    index = 0
    while index < len(text):
        char = text[index]
        if quoted:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == "'":
                if index + 1 < len(text) and text[index + 1] == "'":
                    index += 1
                else:
                    quoted = False
        else:
            if char == "'":
                quoted = True
            elif char == ";":
                return True
        index += 1
    return False


def iter_sql_tuple_bodies(values_text: str) -> Iterator[str]:
    """Yield every top-level tuple body from a complete VALUES clause."""
    index = 0
    length = len(values_text)
    found = False

    while index < length:
        while index < length and (values_text[index].isspace() or values_text[index] == ","):
            index += 1
        if index >= length or values_text[index] == ";":
            break
        if values_text[index] != "(":
            snippet = values_text[index:index + 80].replace("\n", "\\n")
            raise RuntimeError(f"Unexpected SQL after VALUES: {snippet!r}")

        start = index + 1
        depth = 1
        quoted = False
        escaped = False
        index += 1
        while index < length and depth > 0:
            char = values_text[index]
            if quoted:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == "'":
                    if index + 1 < length and values_text[index + 1] == "'":
                        index += 1
                    else:
                        quoted = False
            else:
                if char == "'":
                    quoted = True
                elif char == "(":
                    depth += 1
                elif char == ")":
                    depth -= 1
                    if depth == 0:
                        found = True
                        yield values_text[start:index]
            index += 1

        if depth != 0 or quoted or escaped:
            raise RuntimeError("Unterminated SQL tuple or quoted string in VALUES clause")

    if not found:
        raise RuntimeError("VALUES clause contained no SQL tuples")


def create_columns(path: Path, table: str) -> list[str]:
    columns: list[str] = []
    inside = False
    needle = f"CREATE TABLE `{table}` ("
    with path.open("r", encoding="utf-8", errors="strict") as handle:
        for line in handle:
            if needle in line:
                inside = True
                continue
            if inside:
                stripped = line.lstrip()
                if stripped.startswith("`"):
                    columns.append(stripped.split("`", 2)[1])
                elif stripped.startswith(")"):
                    break
    return columns


def iter_rows(path: Path, table: str):
    """Yield INSERT/REPLACE rows from multiline and extended mysqldump SQL."""
    default_columns = create_columns(path, table)
    insert_re = re.compile(
        rf"^\s*(?:INSERT|REPLACE)\s+INTO\s+`{re.escape(table)}`"
        rf"(?:\s*\((.*?)\))?\s+VALUES\s*(.*)$",
        re.IGNORECASE,
    )
    parsed_rows = 0

    with path.open("r", encoding="utf-8", errors="strict") as handle:
        iterator = iter(handle)
        for line in iterator:
            match = insert_re.match(line.rstrip("\r\n"))
            if not match:
                continue

            raw_columns = match.group(1)
            columns = (
                [item.strip().strip("`") for item in raw_columns.split(",")]
                if raw_columns
                else default_columns
            )
            if not columns:
                raise RuntimeError(
                    f"No column order available for {table} in {path}; "
                    "include CREATE TABLE columns or an explicit INSERT column list"
                )

            values_text = match.group(2)
            while not statement_is_complete(values_text):
                try:
                    values_text += "\n" + next(iterator).rstrip("\r\n")
                except StopIteration as exc:
                    raise RuntimeError(f"Unterminated INSERT/REPLACE for {table} in {path}") from exc

            statement_rows = 0
            for tuple_body in iter_sql_tuple_bodies(values_text):
                values = parse_sql_tuple(tuple_body)
                if len(values) != len(columns):
                    preview = tuple_body[:120].replace("\n", "\\n")
                    raise RuntimeError(
                        f"{table}: value count {len(values)} != columns {len(columns)}: {preview!r}"
                    )
                statement_rows += 1
                parsed_rows += 1
                yield dict(zip(columns, values))

            if statement_rows == 0:
                raise RuntimeError(f"{table}: INSERT/REPLACE contained no rows in {path}")

    if parsed_rows == 0:
        raise RuntimeError(
            f"{table}: no INSERT/REPLACE rows parsed from {path}; "
            "check the SQL dump format and table name"
        )


def as_int(value) -> int:
    if value is None or value == "":
        return 0
    return int(float(value))


def as_u32(value) -> int:
    return as_int(value) & 0xFFFFFFFF


def as_float(value) -> float:
    return float(value or 0)


def as_str(value) -> str:
    return "" if value is None else str(value)


def cstr(value) -> bytes:
    return as_str(value).encode("utf-8") + b"\0"


def load_locales(path: Path | None, wanted: set[int], locale_code: str) -> dict[int, dict[str, str]]:
    if path is None:
        return {}
    locales: dict[int, dict[str, str]] = {}
    for row in iter_rows(path, "creature_template_locale"):
        entry = as_int(row.get("entry"))
        if entry not in wanted or as_str(row.get("locale")) != locale_code:
            continue
        locales[entry] = {
            "Name": as_str(row.get("Name")),
            "Title": as_str(row.get("Title")),
        }
    return locales


def build(args) -> None:
    addon = Path(args.addon)
    wanted = featured_entries(addon)
    templates: dict[int, dict] = {}
    for row in iter_rows(Path(args.template), "creature_template"):
        entry = as_int(row["entry"])
        if entry in wanted:
            templates[entry] = row

    models: dict[int, list[dict]] = {}
    for row in iter_rows(Path(args.models), "creature_template_model"):
        entry = as_int(row["CreatureID"])
        if entry in wanted:
            models.setdefault(entry, []).append(row)

    questitems: dict[int, dict[int, int]] = {}
    for row in iter_rows(Path(args.questitems), "creature_questitem"):
        entry = as_int(row["CreatureEntry"])
        if entry in wanted:
            index = as_int(row["Idx"])
            if 0 <= index < MAX_QUEST_ITEMS:
                questitems.setdefault(entry, {})[index] = as_u32(row["ItemId"])

    locales = load_locales(Path(args.locale) if args.locale else None, wanted, args.locale_code)

    missing_templates = sorted(wanted - set(templates))
    missing_models = sorted(wanted - set(models))
    if missing_templates or missing_models:
        raise SystemExit(f"missing templates={missing_templates[:20]} models={missing_models[:20]}")

    for rows in models.values():
        rows.sort(key=lambda row: as_int(row["Idx"]))

    header = b"BOMW" + struct.pack("<I", BUILD) + LOCALE + struct.pack(
        "<III", RECORD_SIZE, RECORD_VERSION, 0
    )
    output = bytearray(header)

    for entry in sorted(wanted):
        template = templates[entry]
        model_ids = [as_u32(row["CreatureDisplayID"]) for row in models[entry]][:4]
        model_ids += [0] * (4 - len(model_ids))
        quest_ids = [questitems.get(entry, {}).get(index, 0) for index in range(MAX_QUEST_ITEMS)]

        name = as_str(template["name"])
        title = as_str(template["subname"])
        locale = locales.get(entry)
        if locale:
            if locale["Name"]:
                name = locale["Name"]
            if locale["Title"]:
                title = locale["Title"]

        payload = bytearray()
        for value in (name, "", "", "", title, template["IconName"]):
            payload += cstr(value)
        payload += struct.pack(
            "<10I",
            *[
                as_u32(value)
                for value in (
                    template["type_flags"],
                    template["type"],
                    template["family"],
                    template["rank"],
                    template["KillCredit1"],
                    template["KillCredit2"],
                    *model_ids,
                )
            ],
        )
        payload += struct.pack("<2f", as_float(template["HealthModifier"]), as_float(template["ManaModifier"]))
        payload += struct.pack("<B", as_u32(template["RacialLeader"]) & 0xFF)
        payload += struct.pack("<6I", *quest_ids)
        payload += struct.pack("<I", as_u32(template["movementId"]))
        output += struct.pack("<II", entry, len(payload)) + payload

    output += b"\0" * 8
    destination = Path(args.output)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(output)
    print(f"Wrote {destination}: {len(wanted)} records, {len(output)} bytes, locale={args.locale_code}")
    for entry in (4949, 4968, 10181, 10184, 12397, 36597):
        if entry in wanted:
            mids = [as_u32(row["CreatureDisplayID"]) for row in models[entry]][:4]
            qids = [questitems.get(entry, {}).get(i, 0) for i in range(MAX_QUEST_ITEMS)]
            locale = locales.get(entry, {})
            print(
                f"{entry}: models={mids} questitems={qids} "
                f"name={locale.get('Name') or templates[entry]['name']!r}"
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--addon", required=True)
    parser.add_argument("--template", required=True)
    parser.add_argument("--models", required=True)
    parser.add_argument("--questitems", required=True)
    parser.add_argument("--locale")
    parser.add_argument("--locale-code", default="koKR")
    parser.add_argument("--output", required=True)
    build(parser.parse_args())


if __name__ == "__main__":
    main()
