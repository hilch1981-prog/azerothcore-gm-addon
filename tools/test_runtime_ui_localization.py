from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "AzerothAdmin" / "AzerothAdmin.toc"
UI = ROOT / "AzerothAdmin" / "Framework" / "UILocalization.lua"
FEATURE = ROOT / "AzerothAdmin" / "Framework" / "FeatureLocalization.lua"


class RuntimeUILocalizationTests(unittest.TestCase):
    def test_toc_loads_ui_framework_and_packs_before_feature_runtime(self):
        lines = [line.strip() for line in TOC.read_text(encoding="utf-8-sig").splitlines() if line.strip() and not line.startswith("##")]
        required = [
            r"Framework\UILocalization.lua",
            r"Locales\UI\enUS.lua",
            r"Locales\UI\zhCN.lua",
            r"Locales\UI\zhTW.lua",
            r"Locales\UI\Features\enUS.lua",
            r"Locale.lua",
            r"Framework\FeatureLocalization.lua",
            r"Modules\Commands\Module.lua",
            r"Modules\Shell\UI.lua",
        ]
        positions = [lines.index(item) for item in required]
        self.assertEqual(positions, sorted(positions))

    def test_non_korean_ui_has_english_fallback(self):
        source = UI.read_text(encoding="utf-8-sig")
        self.assertIn("selected[text] or english[text]", source)
        self.assertIn('self.ActiveLocale == "koKR"', source)
        self.assertIn("LocalizeFrame", source)
        self.assertIn('localizeField(frame, "aaeHint")', source)

    def test_command_overlay_preserves_server_commands(self):
        source = FEATURE.read_text(encoding="utf-8-sig")
        self.assertIn("LocalizeCommandDefinitions", source)
        self.assertIn("if self.ActiveLocale == \"koKR\"", source)
        self.assertNotIn("def.command =", source)
        self.assertNotIn("def.permissionCommand =", source)
        self.assertIn("fallbackCommandHint", source)

    def test_runtime_localizer_uses_wotlk_safe_apis(self):
        combined = UI.read_text(encoding="utf-8-sig") + FEATURE.read_text(encoding="utf-8-sig")
        for retail_api in ("C_Container", "C_Item", "ScrollBox", "C_QuestLog"):
            self.assertNotIn(retail_api, combined)
        self.assertIn('CreateFrame("Frame")', combined)


if __name__ == "__main__":
    unittest.main()
