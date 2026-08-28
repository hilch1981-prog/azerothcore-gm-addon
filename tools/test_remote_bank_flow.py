import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "AzerothAdmin/Modules/Bank/Module.lua"
INTEGRATIONS = ROOT / "AzerothAdmin/Modules/Integrations/Module.lua"


class RemoteBankFlowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = MODULE.read_text(encoding="utf-8")

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
            r"local bankEvent=CreateFrame\(\"Frame\"\)(.*?)\nif addon.RegisterModule",
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

    def test_bank_implementation_is_removed_from_integrations(self):
        integrations = INTEGRATIONS.read_text(encoding="utf-8")
        for marker in (
            "function addon:ToggleBankWindow()",
            "BANKFRAME_OPENED",
            ".character check bank",
            "AzerothAdminRemoteBankFrame",
        ):
            self.assertNotIn(marker, integrations)

    def test_module_load_order_and_registration(self):
        toc = (ROOT / "AzerothAdmin/AzerothAdmin.toc").read_text(encoding="utf-8-sig")
        locale_paths = [
            "Modules\\Bank\\Locales\\enUS.lua",
            "Modules\\Bank\\Locales\\koKR.lua",
            "Modules\\Bank\\Locales\\zhCN.lua",
            "Modules\\Bank\\Locales\\zhTW.lua",
        ]
        self.assertLess(toc.index("Modules\\Integrations\\Module.lua"), toc.index(locale_paths[0]))
        for path in locale_paths:
            self.assertLess(toc.index(path), toc.index("Modules\\Bank\\Module.lua"))
        self.assertIn('addon:RegisterModule("bank"', self.source)
        self.assertIn('status = "module-active"', self.source)

    def test_module_locales_have_identical_keys(self):
        locale_dir = ROOT / "AzerothAdmin/Modules/Bank/Locales"
        expected = None
        for locale in ("enUS", "koKR", "zhCN", "zhTW"):
            text = (locale_dir / f"{locale}.lua").read_text(encoding="utf-8")
            keys = set(re.findall(r"^\s{4}([A-Z][A-Z0-9_]*)\s*=", text, re.MULTILINE))
            if expected is None:
                expected = keys
            self.assertEqual(expected, keys, locale)
        self.assertEqual({"BANK_FRAME_LOAD_FAILED", "BANK_COMMAND_SEND_FAILED"}, expected)
        self.assertIn('self:T("BANK_FRAME_LOAD_FAILED")', self.source)
        self.assertIn('self:T("BANK_COMMAND_SEND_FAILED")', self.source)


if __name__ == "__main__":
    unittest.main()
