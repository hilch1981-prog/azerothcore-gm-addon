import json
import re
import unittest
from pathlib import Path

from tools import module_context

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AzerothAdmin"


def locale_keys(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8-sig")
    return set(re.findall(r"^\s{4}([A-Z][A-Z0-9_]*)\s*=", text, re.MULTILINE))


class ModuleArchitectureTests(unittest.TestCase):
    def test_framework_and_locales_load_before_modules(self):
        toc = (ADDON / "AzerothAdmin.toc").read_text(encoding="utf-8-sig")
        ordered = [
            "Framework\\Bootstrap.lua",
            "Framework\\ModuleRegistry.lua",
            "Framework\\Localization.lua",
            "Locales\\enUS.lua",
            "Locales\\koKR.lua",
            "Locales\\zhCN.lua",
            "Locales\\zhTW.lua",
            "Locale.lua",
            "Modules\\Language\\Module.lua",
            "Modules\\Shell\\Registration.lua",
            "Modules\\Commands\\CommandMeta.lua",
            "Modules\\Shell\\Core.lua",
        ]
        positions = [toc.index(item) for item in ordered]
        self.assertEqual(positions, sorted(positions))
        self.assertNotIn("Modules\\LegacyManifest.lua", toc)
        self.assertFalse((ADDON / "Modules/LegacyManifest.lua").exists())

    def test_locale_pack_keys_match_enus(self):
        locale_dir = ADDON / "Locales"
        expected = locale_keys(locale_dir / "enUS.lua")
        self.assertGreaterEqual(len(expected), 34)
        for locale in ("koKR", "zhCN", "zhTW"):
            locale_path = locale_dir / f"{locale}.lua"
            self.assertEqual(expected, locale_keys(locale_path), locale)
            locale_text = locale_path.read_text(encoding="utf-8-sig")
            self.assertNotIn("GetLocale() ~=", locale_text)
            self.assertIn("LANGUAGE_USAGE", locale_text)
            self.assertIn("LANGUAGE_UNSUPPORTED", locale_text)
            self.assertIn("LANGUAGE_SAVED", locale_text)

    def test_locale_entrypoint_reactivates_after_saved_variables(self):
        text = (ADDON / "Locale.lua").read_text(encoding="utf-8-sig")
        self.assertLess(len(text), 1600)
        self.assertIn("addon:ActivateLocale", text)
        self.assertIn('RegisterEvent("ADDON_LOADED")', text)
        self.assertIn('name ~= "AzerothAdmin"', text)

    def test_language_override_is_explicit_and_persistent(self):
        localization = (ADDON / "Framework" / "Localization.lua").read_text(encoding="utf-8-sig")
        language = (ADDON / "Modules" / "Language" / "Module.lua").read_text(encoding="utf-8-sig")
        self.assertIn("function addon:SetLocaleOverride", localization)
        self.assertIn("function addon:GetConfiguredLocale", localization)
        self.assertIn("AzerothAdminEasyDB.localeOverride", localization)
        self.assertIn("SLASH_AZEROTHADMINLANG1", language)
        self.assertIn('"/aalang"', language)
        self.assertIn("ReloadUI", language)
        self.assertNotIn('printLine("', language)

    def test_manifest_paths_exist_and_data_is_excluded_by_default(self):
        manifest = json.loads((ROOT / "MODULE_MANIFEST.json").read_text(encoding="utf-8"))
        self.assertTrue(manifest["rules"]["one_feature_per_pr"])
        self.assertEqual("enUS", manifest["rules"]["default_locale"])
        self.assertIn("AzerothAdmin/KoKRSearchData.lua", manifest["ignore_by_default"])
        self.assertIn("AzerothAdmin/Embedded/BlueItemInfo3/Data.lua", manifest["ignore_by_default"])
        self.assertIn("AzerothAdmin/Modules/Creatures/ExpandedData.lua", manifest["ignore_by_default"])
        for relative in manifest.get("shared_context", []):
            self.assertTrue((ROOT / relative).exists(), relative)
        for module in manifest["modules"].values():
            for key in ("runtime_files", "data_files", "tests"):
                for relative in module.get(key, []):
                    self.assertTrue((ROOT / relative).exists(), relative)

    def test_context_tool_omits_large_data_unless_requested(self):
        normal = module_context.context_for("search")
        expanded = module_context.context_for("search", include_data=True)
        self.assertNotIn("AzerothAdmin/KoKRSearchData.lua", normal)
        self.assertIn("AzerothAdmin/KoKRSearchData.lua", expanded)
        self.assertIn("AzerothAdmin/Framework/Localization.lua", normal)

    def test_notice_is_packaged_and_matches_repository_copy(self):
        root_notice = (ROOT / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
        addon_notice = (ADDON / "THIRD_PARTY_NOTICES.md").read_text(encoding="utf-8")
        self.assertEqual(root_notice, addon_notice)
        self.assertIn("AzerothCore WotLK", root_notice)
        self.assertIn("WOW Legends GM Addon", root_notice)
        self.assertIn("라이선스를 별도로 확인", root_notice)

    def test_framework_contains_no_retail_api_or_feature_implementation(self):
        text = "\n".join(path.read_text(encoding="utf-8-sig") for path in (ADDON / "Framework").glob("*.lua"))
        for banned in ("C_Container", "C_Item", "ScrollBox", "C_QuestLog"):
            self.assertNotIn(banned, text)
        for feature_marker in (".revive", ".character check bank", ".go xyz"):
            self.assertNotIn(feature_marker, text)


if __name__ == "__main__":
    unittest.main()
