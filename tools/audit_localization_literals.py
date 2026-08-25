#!/usr/bin/env python3
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "MODULE_MANIFEST.json"
HANGUL = re.compile(r"[가-힣]")
QUOTED = re.compile(r"(['\"])(.*?)(?<!\\)\1")


def runtime_files():
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    for module_name, module in payload.get("modules", {}).items():
        for relative in module.get("runtime_files", []):
            path = ROOT / relative
            if path.suffix.lower() == ".lua" and path.is_file():
                yield module_name, path


def hardcoded_literals(path):
    results = []
    text = path.read_text(encoding="utf-8-sig")
    for line_number, line in enumerate(text.splitlines(), 1):
        stripped = line.lstrip()
        if stripped.startswith("--"):
            continue
        for match in QUOTED.finditer(line):
            value = match.group(2)
            if HANGUL.search(value):
                results.append((line_number, value))
    return results


def main():
    totals = {}
    findings = []
    seen = set()
    for module_name, path in runtime_files():
        key = (module_name, path)
        if key in seen:
            continue
        seen.add(key)
        literals = hardcoded_literals(path)
        if not literals:
            continue
        totals[module_name] = totals.get(module_name, 0) + len(literals)
        findings.append((module_name, path.relative_to(ROOT), literals))

    print("Localization literal audit (Hangul in runtime Lua string literals)")
    print("=" * 72)
    for module_name in sorted(totals):
        print(f"{module_name:20s} {totals[module_name]:4d}")
    print("-" * 72)
    print(f"TOTAL                {sum(totals.values()):4d}")

    for module_name, relative, literals in findings:
        print(f"\n[{module_name}] {relative}")
        for line_number, value in literals:
            compact = value.replace("\\n", " ")
            if len(compact) > 100:
                compact = compact[:97] + "..."
            print(f"  L{line_number}: {compact}")

    # This audit is intentionally informational while translation-pending
    # modules are being converted feature by feature. CI should expose the
    # remaining scope without blocking unrelated refactor PRs.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
