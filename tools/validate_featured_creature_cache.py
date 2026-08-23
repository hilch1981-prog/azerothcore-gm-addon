#!/usr/bin/env python3
"""Strict validator for the generated WotLK 3.3.5a creaturecache patch."""
from __future__ import annotations

import argparse
import struct
from pathlib import Path

HEADER_SIZE = 24
EXPECTED_MAGIC = b"BOMW"
EXPECTED_BUILD = 12340
EXPECTED_LOCALE = b"RKok"
EXPECTED_RECORD_SIZE = 96


def read_cstr(payload: bytes, offset: int) -> tuple[str, int]:
    end = payload.find(b"\0", offset)
    if end < 0:
        raise ValueError("unterminated string")
    return payload[offset:end].decode("utf-8"), end + 1


def parse_payload(payload: bytes) -> dict:
    offset = 0
    strings = []
    for _ in range(6):
        value, offset = read_cstr(payload, offset)
        strings.append(value)
    if offset + 40 + 8 + 1 + 24 + 4 != len(payload):
        raise ValueError(f"payload fixed tail mismatch: offset={offset} len={len(payload)}")
    numbers = struct.unpack_from("<10I", payload, offset)
    offset += 40
    health, mana = struct.unpack_from("<2f", payload, offset)
    offset += 8
    racial = payload[offset]
    offset += 1
    questitems = struct.unpack_from("<6I", payload, offset)
    offset += 24
    movement = struct.unpack_from("<I", payload, offset)[0]
    offset += 4
    if offset != len(payload):
        raise ValueError("payload trailing bytes")
    return {
        "name": strings[0],
        "title": strings[4],
        "icon": strings[5],
        "type_flags": numbers[0],
        "type": numbers[1],
        "family": numbers[2],
        "rank": numbers[3],
        "killcredits": numbers[4:6],
        "models": numbers[6:10],
        "health": health,
        "mana": mana,
        "racial": racial,
        "questitems": questitems,
        "movement": movement,
    }


def parse_wdb(path: Path) -> tuple[bytes, list[tuple[int, bytes, bytes]]]:
    data = path.read_bytes()
    if len(data) < HEADER_SIZE + 8:
        raise ValueError("WDB too small")
    header = data[:HEADER_SIZE]
    magic = header[:4]
    build = struct.unpack_from("<I", header, 4)[0]
    locale = header[8:12]
    record_size, record_version, _cache_version = struct.unpack_from("<III", header, 12)
    if magic != EXPECTED_MAGIC:
        raise ValueError(f"magic {magic!r}")
    if build != EXPECTED_BUILD:
        raise ValueError(f"build {build}")
    if locale != EXPECTED_LOCALE:
        raise ValueError(f"locale bytes {locale!r}")
    if record_size != EXPECTED_RECORD_SIZE:
        raise ValueError(f"recordSize {record_size}")
    if record_version == 0:
        raise ValueError("recordVersion is zero")

    records = []
    seen = set()
    pos = HEADER_SIZE
    while True:
        if pos + 8 > len(data):
            raise ValueError("missing WDB EOF")
        start = pos
        entry, size = struct.unpack_from("<II", data, pos)
        pos += 8
        if entry == 0 and size == 0:
            if pos != len(data):
                raise ValueError(f"trailing bytes after EOF: {len(data) - pos}")
            break
        if entry == 0:
            raise ValueError("zero entry with non-zero payload")
        if entry in seen:
            raise ValueError(f"duplicate entry {entry}")
        seen.add(entry)
        if size > len(data) - pos:
            raise ValueError(f"entry {entry}: size {size} beyond file")
        payload = data[pos:pos + size]
        pos += size
        raw = data[start:pos]
        parse_payload(payload)
        records.append((entry, payload, raw))
    return header, records


def parse_expect(value: str) -> tuple[int, int]:
    left, right = value.split(":", 1)
    return int(left), int(right)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--wdb", required=True, type=Path)
    parser.add_argument("--expected-count", type=int)
    parser.add_argument("--expect-model", action="append", default=[])
    parser.add_argument("--expect-quest", action="append", default=[])
    args = parser.parse_args()

    try:
        header, records = parse_wdb(args.wdb)
        index = {entry: parse_payload(payload) for entry, payload, _raw in records}
        if args.expected_count is not None and len(records) != args.expected_count:
            raise ValueError(f"record count {len(records)} != {args.expected_count}")
        for raw in args.expect_model:
            entry, display_id = parse_expect(raw)
            if entry not in index:
                raise ValueError(f"missing expected model entry {entry}")
            if display_id not in index[entry]["models"]:
                raise ValueError(f"entry {entry}: expected display {display_id}, got {index[entry]['models']}")
        for raw in args.expect_quest:
            entry, item_id = parse_expect(raw)
            if entry not in index:
                raise ValueError(f"missing expected quest entry {entry}")
            if item_id not in index[entry]["questitems"]:
                raise ValueError(f"entry {entry}: expected quest item {item_id}, got {index[entry]['questitems']}")
    except (OSError, UnicodeDecodeError, ValueError, struct.error) as exc:
        print(f"creaturecache validation: FAIL: {exc}")
        return 1

    record_size, record_version, cache_version = struct.unpack_from("<III", header, 12)
    print(
        "creaturecache validation: PASS "
        f"(records={len(records)}, recordSize={record_size}, recordVersion={record_version}, cacheVersion={cache_version})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
