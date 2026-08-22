import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INTEGRATIONS = ROOT / "AzerothAdmin/Integrations.lua"


class RemoteBankFlowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = INTEGRATIONS.read_text(encoding="utf-8")

    def test_toggle_requests_real_azerothcore_bank_session(self):
        match = re.search(
            r"function addon:ToggleBankWindow\(\)(.*?)\nend\n\nlocal bankEvent",
            self.source,
            re.DOTALL,
        )
        self.assertIsNotNone(match)
        body = match.group(1)
        self.assertIn('self:SendNow(".character check bank")', body)
        self.assertNotIn("StaticPopup_Show", body)
        self.assertNotIn("BankFrame:Show()", body)

    def test_native_bank_is_shown_only_after_server_open_event(self):
        match = re.search(
            r"local bankEvent=CreateFrame\(\"Frame\"\)(.*?)\nlocal function isDescendantOf",
            self.source,
            re.DOTALL,
        )
        self.assertIsNotNone(match)
        body = match.group(1)
        self.assertIn('bankEvent:RegisterEvent("BANKFRAME_OPENED")', body)
        self.assertIn('bankEvent:RegisterEvent("BANKFRAME_CLOSED")', body)
        self.assertIn('if event=="BANKFRAME_OPENED" then', body)
        self.assertIn("ShowUIPanel", body)
        self.assertIn("BankFrame:Show()", body)

    def test_obsolete_text_viewer_cannot_reopen(self):
        create_match = re.search(
            r"function addon:CreateRemoteBankFrame\(\)(.*?)\nend",
            self.source,
            re.DOTALL,
        )
        self.assertIsNotNone(create_match)
        self.assertIn("return nil", create_match.group(1))
        self.assertIn("function addon:SuppressRemoteBankPopups()", self.source)
        self.assertIn("AzerothAdminRemoteBankFrame", self.source)


if __name__ == "__main__":
    unittest.main()
