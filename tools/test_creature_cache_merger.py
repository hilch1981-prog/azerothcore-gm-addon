#!/usr/bin/env python3
"""Create and verify a synthetic live WDB for the R8.1 PowerShell merger CI."""
from __future__ import annotations

import argparse
import hashlib
import struct
from pathlib import Path


def read(path: Path):
    data = path.read_bytes()
    header = data[:24]
    pos = 24
    records = []
    while True:
        entry, size = struct.unpack_from("<II", data, pos)
        start = pos
        pos += 8
        if entry == 0 and size == 0:
            if pos != len(data):
                raise ValueError("trailing bytes after WDB EOF")
            break
        raw = data[start:pos + size]
        records.append((entry, raw))
        pos += size
    return header, records


def create(patch: Path, target: Path):
    patch_header, patch_records = read(patch)
    index = dict(patch_records)
    if 4949 not in index:
        raise SystemExit("patch lacks Thrall 4949")
    header = bytearray(patch_header)
    struct.pack_into("<I", header, 20, 0x12345678)
    records = [index[4949]]
    for entry, raw in patch_records:
        if entry not in (4949, 10184):
            records.append(raw)
            break
    target.write_bytes(bytes(header) + b"".join(records) + b"\0" * 8)
    print("created", target, "records", len(records), "sha256", hashlib.sha256(target.read_bytes()).hexdigest())


def verify(original: Path, merged: Path, patch: Path):
    original_header, original_records = read(original)
    merged_header, merged_records = read(merged)
    _patch_header, patch_records = read(patch)
    if original_header != merged_header:
        raise SystemExit("target header changed")
    original_index = dict(original_records)
    merged_index = dict(merged_records)
    patch_index = dict(patch_records)
    for entry, raw in original_index.items():
        if merged_index.get(entry) != raw:
            raise SystemExit(f"existing record changed: {entry}")
    for entry in patch_index:
        if entry not in merged_index:
            raise SystemExit(f"patch entry missing: {entry}")
    cache_version = struct.unpack_from("<I", merged_header, 20)[0]
    if cache_version != 0x12345678:
        raise SystemExit("cacheVersion changed")
    print("verify PASS", "original", len(original_index), "patch", len(patch_index), "merged", len(merged_index), "cacheVersion", hex(cache_version))


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)
    create_parser = sub.add_parser("create")
    create_parser.add_argument("--patch", type=Path, required=True)
    create_parser.add_argument("--target", type=Path, required=True)
    verify_parser = sub.add_parser("verify")
    verify_parser.add_argument("--original", type=Path, required=True)
    verify_parser.add_argument("--merged", type=Path, required=True)
    verify_parser.add_argument("--patch", type=Path, required=True)
    args = parser.parse_args()
    if args.cmd == "create":
        create(args.patch, args.target)
    else:
        verify(args.original, args.merged, args.patch)


if __name__ == "__main__":
    main()
