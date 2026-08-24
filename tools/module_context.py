#!/usr/bin/env python3
"""Print the smallest file set needed for one AzerothAdmin feature task."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "MODULE_MANIFEST.json"


def load_manifest() -> dict:
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def context_for(name: str, include_data: bool = False) -> list[str]:
    manifest = load_manifest()
    module = manifest["modules"].get(name)
    if module is None:
        raise KeyError(name)
    paths = list(manifest.get("shared_context", []))
    paths.extend(module.get("runtime_files", []))
    paths.extend(module.get("tests", []))
    if include_data:
        paths.extend(module.get("data_files", []))
    return list(dict.fromkeys(paths))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("module", nargs="?")
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--include-data", action="store_true")
    args = parser.parse_args()

    manifest = load_manifest()
    if args.list:
        for name in sorted(manifest["modules"]):
            print(name)
        return 0
    if not args.module:
        parser.error("module is required unless --list is used")
    try:
        for path in context_for(args.module, args.include_data):
            print(path)
    except KeyError:
        parser.error(f"unknown module: {args.module}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
