import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
UI_SOURCE = ROOT / "AzerothAdmin/Embedded/InvenCraftInfoUI/Rebuilt.lua"
INTEGRATIONS_SOURCE = ROOT / "AzerothAdmin/Integrations.lua"


def function_body(source, function_name):
    match = re.search(
        rf"function\s+{re.escape(function_name)}\([^)]*\)(.*?)(?=\nfunction\s|\Z)",
        source,
        re.DOTALL,
    )
    if not match:
        raise AssertionError(f"missing Lua function: {function_name}")
    return match.group(1)


class CraftFrameLifecycleTests(unittest.TestCase):
    def test_only_integrated_profession_browser_is_created(self):
        source = UI_SOURCE.read_text(encoding="utf-8")
        self.assertEqual(
            source.count('CreateFrame("Frame", "AzerothAdminCraftInfoFrame", UIParent)'),
            1,
        )
        self.assertIn("UI.aaeIntegratedCraftFrame = true", source)

    def test_normal_toggle_uses_managed_frame_navigation(self):
        source = INTEGRATIONS_SOURCE.read_text(encoding="utf-8")
        body = function_body(source, "addon:ToggleCraftInfo")
        self.assertIn("self:OpenManagedFrame(AzerothAdminCraftInfoFrame)", body)
        self.assertNotIn("AzerothAdminCraftInfoFrame.aaeReturnFrame = nil", body)
        self.assertNotIn("self._closingManagedWindows = true", body)

    def test_reopen_resets_transient_view_state(self):
        source = UI_SOURCE.read_text(encoding="utf-8")
        body = function_body(source, "UI:ResetGMProfessionView")
        for snippet in (
            'searchBox:SetText("")',
            "searchBox:ClearFocus()",
            'sortMode = "skill"',
            'sortButton:SetText("숙련↓")',
            "page = 1",
            "clearDetail()",
            "self._loadingLive = nil",
            "self._liveCaptureScheduled = nil",
            "restoreTradeSkillFrame()",
            "updateProfessionButtons()",
            "refreshRows()",
        ):
            self.assertIn(snippet, body)


if __name__ == "__main__":
    unittest.main()
