#!/usr/bin/env python3
"""Validate the WotLK addon manifest, XML syntax, and critical load order."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AzerothAdmin"
TOC = ADDON / "AzerothAdmin.toc"
QUEST_HELPER = ADDON / "Modules/QuestHelper/Module.lua"
ITEM_BROWSER = ADDON / "Modules/ItemBrowser/Module.lua"
CRAFT_UI = ADDON / "Modules/ProfessionInfo/UI.lua"
INTEGRATIONS = ADDON / "Modules/Integrations/Module.lua"

ORDER_RULES = (
    ("Locale.lua", r"Modules\Language\Module.lua"),
    (r"Modules\Language\Module.lua", r"Modules\Shell\Registration.lua"),
    (r"Modules\Shell\Registration.lua", r"Modules\Commands\CommandMeta.lua"),
    (r"Modules\Commands\CommandMeta.lua", r"Modules\Commands\Module.lua"),
    ("KoKRSearchData.lua", r"Modules\Creatures\Data.lua"),
    (r"Modules\Creatures\Data.lua", r"Modules\Creatures\ExpandedData.lua"),
    (r"Modules\Creatures\ExpandedData.lua", r"Modules\Search\Module.lua"),
    (r"Modules\Search\Module.lua", r"Modules\Search\Registration.lua"),
    (r"Modules\Search\Registration.lua", r"Modules\Creatures\Browser.lua"),
    (r"Modules\Creatures\Browser.lua", r"Modules\Shell\Core.lua"),
    ("Teleports.lua", r"Modules\Teleports\Module.lua"),
    (r"Modules\Teleports\Module.lua", r"Modules\Teleports\Registration.lua"),
    (r"Modules\Teleports\Registration.lua", r"Modules\Commands\Module.lua"),
    (r"Modules\Commands\Module.lua", r"Modules\Commands\Registration.lua"),
    (r"Modules\Commands\Registration.lua", r"Modules\Shell\Core.lua"),
    (r"Modules\Shell\Core.lua", r"Modules\QuestHelper\Module.lua"),
    (r"Modules\QuestHelper\Module.lua", r"Modules\QuestHelper\Registration.lua"),
    (r"Modules\QuestHelper\Registration.lua", r"Modules\Shell\UI.lua"),
    (r"Embedded\InvenCraftInfo\libs\LibStub\LibStub.lua", r"Embedded\InvenCraftInfo\libs\CallbackHandler-1.0\CallbackHandler-1.0.lua"),
    (r"Embedded\InvenCraftInfo\Core.lua", r"Embedded\InvenCraftInfoData\KnownRecipe.lua"),
    (r"Embedded\InvenCraftInfoData\RecipeDB.lua", r"Modules\ProfessionInfo\UI.lua"),
    (r"Embedded\BlueItemInfo3\Data.lua", r"Embedded\BlueItemInfo3\CategoryIndex.lua"),
    (r"Embedded\BlueItemInfo3\CategoryIndex.lua", r"Embedded\BlueItemInfo3\QuestRewards335.lua"),
    (r"Embedded\BlueItemInfo3\QuestRewards335.lua", r"Modules\ItemBrowser\Module.lua"),
    (r"Modules\ItemBrowser\Module.lua", r"Modules\ItemBrowser\Registration.lua"),
    (r"Modules\ItemBrowser\Registration.lua", r"Modules\ProfessionInfo\UI.lua"),
    (r"Modules\ProfessionInfo\UI.lua", r"Modules\ProfessionInfo\Registration.lua"),
    (r"Modules\ProfessionInfo\Registration.lua", r"Modules\Integrations\Module.lua"),
    (r"Modules\Integrations\Module.lua", r"Modules\Integrations\Registration.lua"),
    (r"Modules\Integrations\Registration.lua", r"Modules\Creatures\Fixes.lua"),
    (r"Modules\Creatures\Fixes.lua", r"Modules\Creatures\RuntimeFixes.lua"),
    (r"Modules\Creatures\RuntimeFixes.lua", r"Modules\Creatures\Registration.lua"),
)

RETAIL_ONLY_TOKENS = ("C_Container","C_Item","C_QuestLog","ScrollBox","ScrollUtil","CreateFramePool","BackdropTemplate","Settings.","Enum.")

def toc_entries() -> list[str]:
    entries=[]
    for raw in TOC.read_text(encoding="utf-8-sig").splitlines():
        line=raw.strip()
        if line and not line.startswith("#"):
            entries.append(line)
    return entries

def exact_child(parent: Path, name: str) -> Path | None:
    if not parent.is_dir(): return None
    for child in parent.iterdir():
        if child.name == name: return child
    return None

def resolve_exact(entry: str) -> Path | None:
    current=ADDON
    for part in entry.replace("/","\\").split("\\"):
        current=exact_child(current,part)
        if current is None: return None
    return current if current.is_file() else None

def validate() -> list[str]:
    errors=[]
    entries=toc_entries()
    positions={entry:index for index,entry in enumerate(entries)}
    toc_text=TOC.read_text(encoding="utf-8-sig")
    if "## Interface: 30300" not in toc_text: errors.append("TOC Interface must be 30300")
    duplicates=sorted({entry for entry in entries if entries.count(entry)>1})
    if duplicates: errors.append("duplicate TOC entries: "+", ".join(duplicates))
    for entry in entries:
        if resolve_exact(entry) is None: errors.append(f"missing or case-mismatched TOC path: {entry}")
    for before,after in ORDER_RULES:
        if before not in positions: errors.append(f"load-order source missing: {before}")
        elif after not in positions: errors.append(f"load-order target missing: {after}")
        elif positions[before]>=positions[after]: errors.append(f"invalid load order: {before} must precede {after}")
    for xml_path in sorted(ADDON.rglob("*.xml")):
        try: ET.parse(xml_path)
        except ET.ParseError as exc: errors.append(f"invalid XML {xml_path.relative_to(ROOT)}: {exc}")
    for source_path in sorted((*ADDON.rglob("*.lua"),*ADDON.rglob("*.xml"))):
        source=source_path.read_bytes()
        for token in RETAIL_ONLY_TOKENS:
            if token.encode("ascii") in source: errors.append(f"Retail-only token {token} in {source_path.relative_to(ROOT)}")
    item_source=ITEM_BROWSER.read_text(encoding="utf-8-sig")
    craft_source=CRAFT_UI.read_text(encoding="utf-8-sig")
    integration_source=INTEGRATIONS.read_text(encoding="utf-8-sig")
    for snippet,label,source in (
        ('CreateFrame("Frame", "BlueItemInfo3", UIParent)',"item frame",item_source),
        ('"UIPanelScrollFrameTemplate"',"WotLK item ScrollFrame",item_source),
        ('CreateFrame("Frame", "AzerothAdminCraftInfoFrame", UIParent)',"craft frame",craft_source),
        ("function addon:ToggleItemInfo()","item toggle",integration_source),
        ("function addon:ToggleCraftInfo()","craft toggle",integration_source),
    ):
        if snippet not in source: errors.append(f"missing separated {label}: {snippet}")
    quest_source=QUEST_HELPER.read_text(encoding="utf-8-sig")
    for snippet in ("function addon:RefreshQuestHelperSelectionHighlight()","self.questHelperSelectedQuest = quest","self:SelectQuestHelperQuest(found)","self:RefreshQuestHelperSelectionHighlight()"):
        if snippet not in quest_source: errors.append(f"missing quest selection lifecycle: {snippet}")
    return errors

def main() -> int:
    errors=validate()
    if errors:
        for error in errors: print(f"ERROR: {error}")
        return 1
    print(f"addon structure validation: PASS ({len(toc_entries())} TOC files, {len(list(ADDON.rglob('*.xml')))} XML files)")
    return 0

if __name__ == "__main__": sys.exit(main())
