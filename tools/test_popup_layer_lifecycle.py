import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "AzerothAdmin/Core.lua"
QUEST = ROOT / "AzerothAdmin/Modules/QuestHelper/Module.lua"
SEARCH = ROOT / "AzerothAdmin/KoKRSearch.lua"
CRAFT = ROOT / "AzerothAdmin/Embedded/InvenCraftInfoUI/Rebuilt.lua"


def popup_block(source, key):
    match = re.search(
        rf'StaticPopupDialogs\["{re.escape(key)}"\]\s*=\s*\{{(.*?)(?=\n[ \t]*\}}[ \t]*\n)',
        source,
        re.DOTALL,
    )
    if not match:
        raise AssertionError(f"missing popup definition: {key}")
    return match.group(1)


class PopupLayerLifecycleTests(unittest.TestCase):
    def test_major_popups_raise_and_restore_managed_layer(self):
        cases = (
            (QUEST, "AZEROTHADMIN_QUEST_COMPLETE_AND_GO"),
            (SEARCH, "AZEROTHADMIN_ITEM_ADD_QUANTITY"),
            (SEARCH, "AZEROTHADMIN_QUEST_ADD_SEARCH"),
            (CRAFT, "AZEROTHADMIN_CRAFT_LEARN"),
            (CORE, "AZEROTHADMIN_EASY_CONFIRM"),
        )
        for path, key in cases:
            block = popup_block(path.read_text(encoding="utf-8"), key)
            self.assertIn("RaisePopup(self)", block, key)
            self.assertIn("SuspendManagedEscapeForPopup(self)", block, key)
            self.assertIn("ResumeManagedEscapeForPopup(self)", block, key)

    def test_raise_uses_top_wotlk_layer(self):
        source = CORE.read_text(encoding="utf-8")
        self.assertIn('frame:SetFrameStrata("TOOLTIP")', source)
        self.assertIn("frame:SetFrameLevel(1000)", source)
        self.assertIn("frame:SetToplevel(true)", source)

    def test_shared_static_popup_layer_is_restored_on_hide(self):
        source = CORE.read_text(encoding="utf-8")
        for snippet in (
            "frame._aaePopupOriginalStrata = frame:GetFrameStrata()",
            "frame._aaePopupOriginalLevel = frame:GetFrameLevel()",
            "frame._aaePopupOriginalToplevel = frame:IsToplevel() and true or false",
            "function addon:RestorePopupLayer(frame)",
            "frame:SetFrameStrata(frame._aaePopupOriginalStrata)",
            "frame:SetFrameLevel(frame._aaePopupOriginalLevel)",
            "frame:SetToplevel(frame._aaePopupOriginalToplevel)",
            "self:RestorePopupLayer(frame)",
        ):
            self.assertIn(snippet, source)


if __name__ == "__main__":
    unittest.main()
