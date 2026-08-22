#!/usr/bin/env python3
"""Validate AzerothAdmin command metadata against a pinned AzerothCore dump."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import urllib.request
from pathlib import Path


SQL_ROW = re.compile(
    r"^\('((?:\\.|''|[^'])*)',(\d+),'((?:\\.|''|[^'])*)'\)[,;]$"
)
SECURITY_ENTRY = re.compile(
    r'^\s*\["([^"]+)"\]\s*=\s*(\d+)\s*,?\s*(?:--.*)?$'
)
SYNTAX_ENTRY = re.compile(
    r'^\s*\["([^"]+)"\]\s*=\s*"(?:\\.|[^"])*"\s*,?\s*(?:--.*)?$'
)
TABLE_END = re.compile(r"^\s*}\s*,?\s*(?:--.*)?$")


def decode_mysql_string(value: str) -> str:
    replacements = {
        "\\0": "\0",
        "\\n": "\n",
        "\\r": "\r",
        "\\t": "\t",
        "\\b": "\b",
        "\\Z": "\x1a",
        "\\'": "'",
        '\\"': '"',
        "\\\\": "\\",
    }
    value = value.replace("''", "'")
    for encoded, decoded in replacements.items():
        value = value.replace(encoded, decoded)
    return value


def parse_command_sql(text: str) -> dict[str, int]:
    commands: dict[str, int] = {}
    for line_number, line in enumerate(text.splitlines(), 1):
        if not line.startswith("('"):
            continue
        match = SQL_ROW.match(line)
        if not match:
            raise ValueError(f"command.sql row parse failure at line {line_number}")
        name = decode_mysql_string(match.group(1))
        if name in commands:
            raise ValueError(f"duplicate command.sql command: {name}")
        commands[name] = int(match.group(2))
    return commands


def parse_lua_metadata(text: str) -> tuple[dict[str, int], set[str]]:
    security: dict[str, int] = {}
    syntax: set[str] = set()
    section = None

    for line in text.splitlines():
        if line.strip() == "addon.CommandSecurity = {":
            section = "security"
            continue
        if line.strip() == "addon.CommandSyntax = {":
            section = "syntax"
            continue
        if section and TABLE_END.match(line):
            section = None
            continue

        if section == "security":
            match = SECURITY_ENTRY.match(line)
            if match:
                name = match.group(1)
                if name in security:
                    raise ValueError(f"duplicate CommandSecurity entry: {name}")
                security[name] = int(match.group(2))
            elif line.strip() and not line.lstrip().startswith("--"):
                raise ValueError(f"unparsed CommandSecurity line: {line.strip()}")
        elif section == "syntax":
            match = SYNTAX_ENTRY.match(line)
            if match:
                name = match.group(1)
                if name in syntax:
                    raise ValueError(f"duplicate CommandSyntax entry: {name}")
                syntax.add(name)
            elif line.strip() and not line.lstrip().startswith("--"):
                raise ValueError(f"unparsed CommandSyntax line: {line.strip()}")

    return security, syntax


def load_source(source: str, expected_sha256: str) -> str:
    if re.match(r"^https://", source):
        with urllib.request.urlopen(source, timeout=30) as response:
            payload = response.read()
    else:
        payload = Path(source).read_bytes()

    actual_sha256 = hashlib.sha256(payload).hexdigest()
    if actual_sha256.lower() != expected_sha256.lower():
        raise ValueError(
            "command.sql SHA-256 mismatch: "
            f"expected {expected_sha256}, got {actual_sha256}"
        )
    return payload.decode("utf-8")


def format_names(names: set[str]) -> str:
    return ", ".join(sorted(names)) if names else "none"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--manifest", default="tools/command_metadata_source.json"
    )
    parser.add_argument("--metadata", default="AzerothAdmin/CommandMeta.lua")
    parser.add_argument(
        "--source",
        help="Local command.sql path. Defaults to the pinned HTTPS URL in the manifest.",
    )
    args = parser.parse_args()

    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    source = args.source or manifest["command_sql_url"]
    sql_text = load_source(source, manifest["command_sql_sha256"])
    official = parse_command_sql(sql_text)
    metadata, syntax = parse_lua_metadata(
        Path(args.metadata).read_text(encoding="utf-8-sig")
    )

    required_modules = set(manifest["required_module_commands"])
    official_names = set(official)
    metadata_names = set(metadata)
    missing = official_names - metadata_names
    extras = metadata_names - official_names
    unexpected_extras = extras - required_modules
    missing_modules = required_modules - extras
    security_mismatches = {
        name
        for name in official_names & metadata_names
        if official[name] != metadata[name]
    }
    missing_syntax = metadata_names - syntax
    orphan_syntax = syntax - metadata_names

    errors: list[str] = []
    if len(official) != manifest["expected_core_command_count"]:
        errors.append(
            "official command count mismatch: "
            f"expected {manifest['expected_core_command_count']}, got {len(official)}"
        )
    if missing:
        errors.append(f"official commands missing from metadata: {format_names(missing)}")
    if security_mismatches:
        detail = ", ".join(
            f"{name} (official={official[name]}, metadata={metadata[name]})"
            for name in sorted(security_mismatches)
        )
        errors.append(f"security mismatches: {detail}")
    if unexpected_extras:
        errors.append(f"unapproved metadata-only commands: {format_names(unexpected_extras)}")
    if missing_modules:
        errors.append(f"required module commands missing from metadata: {format_names(missing_modules)}")
    if missing_syntax:
        errors.append(f"commands without syntax metadata: {format_names(missing_syntax)}")
    if orphan_syntax:
        errors.append(f"syntax entries without security metadata: {format_names(orphan_syntax)}")

    print(f"upstream commit: {manifest['upstream_commit']}")
    print(f"official commands: {len(official)}")
    print(f"metadata commands: {len(metadata)}")
    print(f"required module commands: {len(extras)}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print("command metadata audit: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
