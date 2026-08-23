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


def split_sql_tuple(line: str):
    value = line.strip()
    if not value.startswith("("):
        return None
    if value.endswith(",") or value.endswith(";"):
        value = value[:-1]
    if not value.endswith(")"):
        return None
    value = value[1:-1]
    row = next(csv.reader([value], delimiter=",", quotechar="'", escapechar="\\", skipinitialspace=True))
    return [None if item.strip().upper() == "NULL" else item.strip() for item in row]


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
    default_columns = create_columns(path, table)
    columns = None
    active = False
    insert_re = re.compile(rf"^(?:INSERT|REPLACE) INTO `{re.escape(table)}`(?: \((.*?)\))? VALUES")
    with path.open("r", encoding="utf-8", errors="strict") as handle:
        for line in handle:
            match = insert_re.match(line)
            if match:
                active = True
                raw = match.group(1)
                columns = [item.strip().strip("`") for item in raw.split(",")] if raw else default_columns
                if not columns:
                    raise RuntimeError(f"No column order available for {table} in {path}")
                continue
            if active:
                stripped = line.lstrip()
                if stripped.startswith("("):
                    values = split_sql_tuple(line)
                    if values is None:
                        continue
                    if len(values) != len(columns):
                        raise RuntimeError(
                            f"{table}: value count {len(values)} != columns {len(columns)}: {line[:120]!r}"
                        )
                    yield dict(zip(columns, values))
                    if line.rstrip().endswith(";"):
                        active = False
                elif line.startswith("UNLOCK TABLES") or line.startswith("/*!40000 ALTER TABLE"):
                    active = False


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
