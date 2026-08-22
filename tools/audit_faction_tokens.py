#!/usr/bin/env python3
"""Reject malformed BlueItemInfo faction formatter tokens."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCES = (
    ROOT / "AzerothAdmin/Embedded/BlueItemInfo3/Data.lua",
    ROOT / "AzerothAdmin/Embedded/BlueItemInfo3/CategoryIndex.lua",
)
TOKEN_START = re.compile(r"\$f|@f")
CANONICAL_TOKEN = re.compile(r"\$f\{[^{}@/]+/[^{}@/]+\}")


def find_errors(path: Path) -> list[str]:
    errors: list[str] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        for match in TOKEN_START.finditer(line):
            if not CANONICAL_TOKEN.match(line, match.start()):
                errors.append(f"{path.relative_to(ROOT)}:{line_number}: {line.strip()}")
    return errors


def main() -> int:
    errors = [error for path in SOURCES for error in find_errors(path)]
    if errors:
        print("Malformed faction formatter tokens:")
        print("\n".join(errors))
        return 1
    print("faction token audit: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
