#!/usr/bin/env python3
"""Build and verify a deterministic AzerothAdmin release archive."""

from __future__ import annotations

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path

try:
    from tools.validate_addon_structure import toc_entries, validate
except ModuleNotFoundError:  # Direct execution: python tools/build_release_zip.py
    from validate_addon_structure import toc_entries, validate


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AzerothAdmin"
DEFAULT_OUTPUT = ROOT / "dist/AzerothAdmin_3.2.8-335a_20260822.zip"
ZIP_TIMESTAMP = (2026, 8, 22, 0, 0, 0)
EXCLUDED_DIRS = {"__pycache__", "Cache", "Logs", "Screenshots", "WTF"}
EXCLUDED_FILES = {".DS_Store", "Thumbs.db", "desktop.ini"}


def source_files() -> list[Path]:
    files: list[Path] = []
    for path in ADDON.rglob("*"):
        relative = path.relative_to(ADDON)
        if not path.is_file() or any(part in EXCLUDED_DIRS for part in relative.parts):
            continue
        if path.name in EXCLUDED_FILES or path.suffix.lower() in {".zip", ".pyc"}:
            continue
        files.append(path)
    return sorted(files, key=lambda path: path.relative_to(ADDON).as_posix())


def archive_names() -> list[str]:
    return [f"AzerothAdmin/{path.relative_to(ADDON).as_posix()}" for path in source_files()]


def verify_archive(output: Path) -> None:
    expected = archive_names()
    with zipfile.ZipFile(output, "r") as archive:
        actual = archive.namelist()
        corrupt = archive.testzip()
    if corrupt:
        raise ValueError(f"corrupt ZIP entry: {corrupt}")
    if actual != expected:
        missing = sorted(set(expected) - set(actual))
        extra = sorted(set(actual) - set(expected))
        raise ValueError(f"ZIP contents differ (missing={missing}, extra={extra})")
    required = {f"AzerothAdmin/{entry.replace(chr(92), '/')}" for entry in toc_entries()}
    absent = sorted(required - set(actual))
    if absent:
        raise ValueError(f"ZIP is missing TOC files: {absent}")
    if any(not name.startswith("AzerothAdmin/") for name in actual):
        raise ValueError("ZIP contains an entry outside the AzerothAdmin folder")


def build_archive(output: Path) -> str:
    structure_errors = validate()
    if structure_errors:
        raise ValueError("addon structure is invalid: " + "; ".join(structure_errors))
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path, name in zip(source_files(), archive_names()):
            info = zipfile.ZipInfo(name, ZIP_TIMESTAMP)
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, path.read_bytes(), compresslevel=9)
    verify_archive(output)
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(output.suffix + ".sha256").write_text(
        f"{digest}  {output.name}\n", encoding="ascii"
    )
    return digest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    try:
        digest = build_archive(args.output.resolve())
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        print(f"release ZIP validation: FAIL: {exc}", file=sys.stderr)
        return 1
    print(f"release ZIP validation: PASS ({len(source_files())} files)")
    print(f"archive: {args.output.resolve()}")
    print(f"sha256: {digest}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
