import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INTEGRATED = ROOT / "AzerothAdmin/Modules/ItemBrowser/Module.lua"
ITEMS = ROOT / "AzerothAdmin/KoKRSearchData.lua"
RECIPES = ROOT / "AzerothAdmin/Embedded/InvenCraftInfoData/RecipeDB.lua"
SPELLS = ROOT / "AzerothAdmin/Embedded/InvenCraftInfoData/SpellDB.lua"


def parse_locale_items():
    item_source = ITEMS.read_text(encoding="utf-8").split("\n  quest = {", 1)[0]
    return {
        int(item_id): name
        for item_id, name in re.findall(r'\{(\d+),"([^"]*)"\}', item_source)
    }


def parse_recipe_spells():
    return {
        int(item_id): int(spell_id)
        for item_id, spell_id in re.findall(
            r"^\s*\[(\d+)\]\s*=\s*(\d+)",
            RECIPES.read_text(encoding="utf-8"),
            re.MULTILINE,
        )
    }


def profession_spell_ids(profession):
    source = SPELLS.read_text(encoding="utf-8")
    match = re.search(
        rf'\[L\["{re.escape(profession)}"\]\]\s*=\s*\{{(.*?)\n\s*\}},',
        source,
        re.DOTALL,
    )
    if not match:
        raise AssertionError(f"missing SpellDB block: {profession}")
    spell_ids = set()
    for line in match.group(1).splitlines():
        row = re.search(r"^\s*\[\d+\]\s*=\s*(.*?)(?:,\s*(?:--.*)?)?$", line)
        if row:
            spell_ids.update(int(value) for value in re.findall(r"\b\d+\b", row.group(1)))
    return spell_ids


class ProfessionAndEnhancementCategoryTests(unittest.TestCase):
    def test_embedded_data_contains_cooking_and_first_aid_recipes(self):
        items = parse_locale_items()
        recipes = parse_recipe_spells()
        expected_minimums = {"요리": 100, "응급치료": 7}

        for profession, minimum in expected_minimums.items():
            craft_spells = profession_spell_ids(profession)
            matched = {
                item_id
                for item_id, spell_id in recipes.items()
                if item_id in items and item_id <= 56806 and spell_id in craft_spells
            }
            self.assertGreaterEqual(len(matched), minimum, profession)

    def test_runtime_exposes_secondary_professions(self):
        source = INTEGRATED.read_text(encoding="utf-8")
        self.assertIn('IDX.seconds["t"]["t9"] = "요리"', source)
        self.assertIn('IDX.seconds["t"]["ta"] = "응급치료"', source)
        self.assertIn('{"t9",2550}', source)
        self.assertIn('{"ta",3273}', source)
        self.assertIn('"처방전"', source)

    def test_runtime_exposes_profession_only_enhancement_slots(self):
        source = INTEGRATED.read_text(encoding="utf-8")
        for key in ("v7", "vb", "vd", "vl"):
            self.assertRegex(source, rf'IDX\.seconds\["v"\]\["{key}"\]')
        for snippet in (
            'addSpell("v7", 55002)',
            'addSpell("vl", 55016)',
            'addSpell("vb", 55628)',
            'addSpell("vd", 55641)',
            'copyBucket("vb", "vt")',
            'copyBucket("vd", "vt")',
        ):
            self.assertIn(snippet, source)


if __name__ == "__main__":
    unittest.main()
