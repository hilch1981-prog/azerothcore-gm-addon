from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
FEATURE = ROOT / "AzerothAdmin" / "Framework" / "FeatureLocalization.lua"
FIXES = ROOT / "AzerothAdmin" / "Modules" / "Creatures" / "Fixes.lua"
TELEPORTS = ROOT / "AzerothAdmin" / "Teleports.lua"
EN_UI = ROOT / "AzerothAdmin" / "Locales" / "UI" / "enUS.lua"


class LocaleTeleportIntegrityTests(unittest.TestCase):
    def test_localization_preserves_canonical_source_labels(self):
        source = FEATURE.read_text(encoding="utf-8-sig")
        self.assertIn("entry._aaeSourceName", source)
        self.assertIn("entry._aaeSourceZone", source)
        self.assertIn("addon:TranslateUI(entry._aaeSourceName)", source)
        self.assertIn("addon:TranslateUI(entry._aaeSourceZone)", source)

    def test_creature_instance_lookup_uses_canonical_labels(self):
        source = FIXES.read_text(encoding="utf-8-sig")
        self.assertIn("row._aaeSourceName or row.name", source)
        self.assertIn("row._aaeSourceZone or row.zone", source)
        self.assertIn("normalizeTeleportLabel(sourceName(row))", source)
        self.assertIn("normalizeTeleportLabel(sourceZone(row))", source)

    def test_display_translation_does_not_touch_coordinate_command(self):
        source = FEATURE.read_text(encoding="utf-8-sig")
        self.assertNotIn("entry.command =", source)
        self.assertNotIn("entry.map =", source)
        self.assertNotIn("entry.x =", source)
        self.assertNotIn("entry.y =", source)
        self.assertNotIn("entry.z =", source)

    def test_silvermoon_destination_names_have_english_fallbacks(self):
        teleports = TELEPORTS.read_text(encoding="utf-8-sig")
        english = EN_UI.read_text(encoding="utf-8-sig")
        names = re.findall(r'zone = "실버문", name = "([^"]+)"', teleports)
        self.assertGreaterEqual(len(names), 14)
        for name in names:
            self.assertIn(f'["{name}"]', english, f"missing enUS fallback for Silvermoon destination: {name}")


if __name__ == "__main__":
    unittest.main()
