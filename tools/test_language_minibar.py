import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AzerothAdmin"
LANGUAGE_MODULE = ADDON / "Modules" / "Language" / "Module.lua"
LOCALES = ["enUS", "koKR", "zhCN", "zhTW"]


class LanguageMinibarTests(unittest.TestCase):
    def test_language_button_uses_wotlk_safe_primitives(self):
        text = LANGUAGE_MODULE.read_text(encoding="utf-8-sig")
        self.assertIn('CreateFrame("Button", "AzerothAdminLanguageMinibarButton", toolbar)', text)
        self.assertIn('button:SetPoint("LEFT", toolbar, "RIGHT", 6, 0)', text)
        self.assertIn('GameTooltip:SetOwner(self, "ANCHOR_TOP")', text)
        self.assertIn('if ReloadUI then ReloadUI() end', text)
        for retail_api in ("C_Container", "C_Item", "ScrollBox", "C_QuestLog"):
            self.assertNotIn(retail_api, text)

    def test_language_cycle_contains_auto_and_four_supported_locales(self):
        text = LANGUAGE_MODULE.read_text(encoding="utf-8-sig")
        self.assertIn('{ "auto", "koKR", "enUS", "zhCN", "zhTW" }', text)
        self.assertIn('AzerothAdminEasyDB.localeOverride', text)
        self.assertIn('addon:SetLocaleOverride(requested)', text)

    def test_all_locale_packs_have_minibar_strings(self):
        for locale in LOCALES:
            text = (ADDON / "Locales" / f"{locale}.lua").read_text(encoding="utf-8-sig")
            self.assertIn("LANGUAGE_BUTTON_TITLE", text, locale)
            self.assertIn("LANGUAGE_BUTTON_HINT", text, locale)


if __name__ == "__main__":
    unittest.main()
