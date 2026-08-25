#!/usr/bin/env python3
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "MODULE_MANIFEST.json"
HANGUL = re.compile(r"[가-힣]")
QUOTED = re.compile(r"(['\"])(.*?)(?<!\\)\1")


def manifest_payload():
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def runtime_file_roles(payload):
    roles = {}
    for module_name, module in payload.get("modules", {}).items():
        for relative in module.get("runtime_files", []):
            path = ROOT / relative
            if path.suffix.lower() != ".lua" or not path.is_file():
                continue
            roles.setdefault(path, []).append(module_name)
    return roles


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
    payload = manifest_payload()
    roles = runtime_file_roles(payload)
    findings = []
    total = 0

    for path in sorted(roles, key=lambda item: str(item.relative_to(ROOT))):
        literals = hardcoded_literals(path)
        if not literals:
            continue
        total += len(literals)
        findings.append((path.relative_to(ROOT), roles[path], literals))

    print("Canonical Hangul source inventory (runtime Lua string literals)")
    print("=" * 72)
    print("This is NOT an untranslated-UI failure count.")
    print("Runtime UI is localized through Framework/UILocalization.lua and")
    print("Framework/FeatureLocalization.lua. koKR search/parser/classification")
    print("terms and unverified proper names intentionally remain in source.")
    print("-" * 72)
    print(f"UNIQUE FILES          {len(findings):4d}")
    print(f"SOURCE LITERALS       {total:4d}")

    modules = payload.get("modules", {})
    print("\nModule localization status")
    print("-" * 72)
    for module_name in sorted(modules):
        status = modules[module_name].get("status", "unknown")
        print(f"{module_name:20s} {status}")

    for relative, module_names, literals in findings:
        print(f"\n[{', '.join(module_names)}] {relative}")
        for line_number, value in literals:
            compact = value.replace("\\n", " ")
            if len(compact) > 100:
                compact = compact[:97] + "..."
            print(f"  L{line_number}: {compact}")

    # Informational inventory only. Source Hangul is expected to remain when it
    # is canonical koKR data, parser vocabulary, classification vocabulary, or
    # a proper name that has not been independently verified for translation.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
