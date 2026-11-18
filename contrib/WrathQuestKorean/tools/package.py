#!/usr/bin/env python3
"""Build the 3.3.5a koKR installation ZIP from generated data and TooltipKOR."""
import argparse
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
TOOLTIP = "TooltipKOR-wotlk"
EXCLUDE = {"data/globalstrings.lua", "zone_font.lua"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("quest_data", type=Path)
    parser.add_argument("tooltip_source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    toc = args.tooltip_source / f"{TOOLTIP}.toc"
    lines = toc.read_text(encoding="utf-8-sig").splitlines()

    def path(line):
        return line.strip().replace("\\", "/")

    required = [path(line) for line in lines if line.strip() and not line.startswith("#")]
    if not EXCLUDE.issubset(required):
        raise ValueError("Expected koKR exclusions missing from pinned TooltipKOR TOC")
    with ZipFile(args.output, "w", ZIP_DEFLATED) as archive:
        for name in ("WrathQuestKorean.toc", "Core.lua", "README.md"):
            archive.write(ROOT / name, f"WrathQuestKorean/{name}")
        archive.write(args.quest_data, "WrathQuestKorean/QuestData.lua")
        archive.write(args.tooltip_source / "LICENSE", f"{TOOLTIP}/LICENSE")
        archive.write(args.tooltip_source / "README.md", f"{TOOLTIP}/README.md")
        archive.writestr(f"{TOOLTIP}/{TOOLTIP}.toc",
                         "\n".join(line for line in lines if path(line) not in EXCLUDE) + "\n")
        archive.writestr(f"{TOOLTIP}/KO_CLIENT_PACKAGE.txt",
                         "Upstream: https://github.com/samahee/TooltipKOR-wotlk\n"
                         "Commit: c3cb6c12eb230fe5a377d8955c809f4cee22cd71\n"
                         "The packaged TOC omits data/globalstrings.lua and zone_font.lua.\n"
                         "Use the native 3.3.5a Korean UI strings and fonts.\n")
        for name in required:
            if name not in EXCLUDE:
                archive.write(args.tooltip_source / name, f"{TOOLTIP}/{name}")
    with ZipFile(args.output) as archive:
        assert archive.testzip() is None
        names = archive.namelist()
        assert len(names) == len(set(names))
        assert {name.split("/")[0] for name in names} == {"WrathQuestKorean", TOOLTIP}
        for name in ("WrathQuestKorean", TOOLTIP):
            for line in archive.read(f"{name}/{name}.toc").decode("utf-8").splitlines():
                if line.strip() and not line.startswith("#"):
                    assert f"{name}/{path(line)}" in names


if __name__ == "__main__":
    main()
