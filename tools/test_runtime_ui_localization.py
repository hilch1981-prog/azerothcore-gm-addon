from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "AzerothAdmin" / "AzerothAdmin.toc"
UI = ROOT / "AzerothAdmin" / "Framework" / "UILocalization.lua"
FEATURE = ROOT / "AzerothAdmin" / "Framework" / "FeatureLocalization.lua"
OUTPUT = ROOT / "AzerothAdmin" / "Modules" / "Language" / "Output.lua"
AUDIT = ROOT / "tools" / "audit_localization_literals.py"


class RuntimeUILocalizationTests(unittest.TestCase):
    def test_toc_loads_ui_framework_and_packs_before_feature_runtime(self):
        lines = [line.strip() for line in TOC.read_text(encoding="utf-8-sig").splitlines() if line.strip() and not line.startswith("##")]
        required = [
            r"Framework\UILocalization.lua", r"Locales\UI\enUS.lua",
            r"Locales\UI\zhCN.lua", r"Locales\UI\zhTW.lua",
            r"Locales\UI\Features\enUS.lua", r"Locales\UI\Features\zhCN.lua",
            r"Locales\UI\Features\zhTW.lua", r"Locales\UI\Messages\enUS.lua",
            r"Locales\UI\Messages\zhCN.lua", r"Locales\UI\Messages\zhTW.lua",
            r"Locale.lua", r"Framework\FeatureLocalization.lua",
            r"Modules\Commands\Module.lua", r"Modules\Shell\Core.lua",
            r"Modules\Language\Output.lua", r"Modules\Shell\UI.lua",
        ]
        positions = [lines.index(item) for item in required]
        self.assertEqual(positions, sorted(positions))

    def test_non_korean_ui_has_english_fallback(self):
        source = UI.read_text(encoding="utf-8-sig")
        self.assertIn("selected[text] or english[text]", source)
        self.assertIn('self.ActiveLocale == "koKR"', source)
        self.assertIn("LocalizeFrame", source)
        self.assertIn('localizeField(frame, "aaeHint")', source)
        self.assertIn('localizeField(frame, "aaeTitle")', source)

    def test_command_overlay_preserves_server_commands(self):
        source = FEATURE.read_text(encoding="utf-8-sig")
        self.assertIn("LocalizeCommandDefinitions", source)
        self.assertIn('if self.ActiveLocale == "koKR"', source)
        self.assertNotIn("def.command =", source)
        self.assertNotIn("def.permissionCommand =", source)
        self.assertIn("fallbackCommandHint", source)

    def test_lazy_frames_and_owned_tooltips_are_localized(self):
        source = FEATURE.read_text(encoding="utf-8-sig")
        self.assertIn("InstallRuntimeLocalizationHooks", source)
        self.assertIn('GameTooltip:HookScript("OnShow"', source)
        self.assertIn("IsLocalizationOwnedFrame", source)
        self.assertIn('driver:SetScript("OnUpdate"', source)
        self.assertIn("self.teleportFrame", source)
        self.assertIn("self.favoriteFrame", source)
        self.assertIn("self.questHelperFrame", source)

    def test_late_registered_popups_are_localized_when_shown(self):
        source = FEATURE.read_text(encoding="utf-8-sig")
        self.assertIn("LocalizePopupDefinition", source)
        self.assertIn("InstallPopupLocalizationHook", source)
        self.assertIn("aaeOriginalStaticPopupShow", source)
        self.assertIn("addon:LocalizePopupDefinition(which)", source)
        self.assertIn('"_aaeSource_" .. field', source)

    def test_chat_output_wrapper_translates_display_text_only(self):
        source = OUTPUT.read_text(encoding="utf-8-sig")
        self.assertIn("aaeOriginalPrint", source)
        self.assertIn("TranslateUI(text)", source)
        self.assertIn('self.ActiveLocale ~= "koKR"', source)
        self.assertNotIn("SendNow", source)
        self.assertNotIn("command =", source)

    def test_source_hangul_audit_is_informational_and_deduplicated(self):
        source = AUDIT.read_text(encoding="utf-8-sig")
        self.assertIn("This is NOT an untranslated-UI failure count.", source)
        self.assertIn("runtime_file_roles", source)
        self.assertIn("roles.setdefault(path, []).append(module_name)", source)
        self.assertIn("canonical koKR data", source)

    def test_runtime_localizer_uses_wotlk_safe_apis(self):
        combined = UI.read_text(encoding="utf-8-sig") + FEATURE.read_text(encoding="utf-8-sig") + OUTPUT.read_text(encoding="utf-8-sig")
        for retail_api in ("C_Container", "C_Item", "ScrollBox", "C_QuestLog"):
            self.assertNotIn(retail_api, combined)
        self.assertIn('CreateFrame("Frame")', combined)


if __name__ == "__main__":
    unittest.main()
