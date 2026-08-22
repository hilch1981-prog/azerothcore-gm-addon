import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AzerothAdmin"
DATA_PATH = ADDON / "FeaturedCreatures.lua"
BROWSER_PATH = ADDON / "CreatureBrowser.lua"


def parse_featured_records():
    text = DATA_PATH.read_text(encoding="utf-8-sig")
    pattern = re.compile(
        r'\{\s*(\d+),\s*"([^"]+)",\s*"(raid|dungeon|world|rare|event|utility|leader)",\s*'
        r'"(classic|tbc|wotlk)",\s*"([^"]+)",\s*(true|false)\s*\}'
    )
    return [
        (int(entry), name, group, expansion, place, restricted == "true")
        for entry, name, group, expansion, place, restricted in pattern.findall(text)
    ]


def parse_kokr_creatures():
    text = (ADDON / "KoKRSearchData.lua").read_text(encoding="utf-8-sig")
    creature_section = text.split("creature = {", 1)[1]
    return {
        int(entry): name
        for entry, name in re.findall(r'\{\s*(\d+),\s*"([^"]+)"\s*\}', creature_section)
    }


class FeaturedCreatureBrowserTests(unittest.TestCase):
    def test_curated_data_is_bounded_and_unique(self):
        records = parse_featured_records()
        self.assertGreaterEqual(len(records), 180)
        self.assertLessEqual(len(records), 220)
        entries = [record[0] for record in records]
        self.assertEqual(len(entries), len(set(entries)))

    def test_curated_entries_match_kokr_creature_catalog(self):
        catalog = parse_kokr_creatures()
        for entry, name, *_ in parse_featured_records():
            self.assertIn(entry, catalog)
            self.assertEqual(name, catalog[entry])

    def test_restricted_warning_policy_is_explicit(self):
        records = parse_featured_records()
        for _, _, group, _, _, restricted in records:
            if group in {"raid", "dungeon", "world", "rare", "event"}:
                self.assertTrue(restricted)
            elif group in {"leader", "utility"}:
                self.assertFalse(restricted)

        browser = BROWSER_PATH.read_text(encoding="utf-8-sig")
        self.assertIn("지역 제한 가능", browser)
        self.assertIn("인스턴스·조우 스크립트", browser)
        self.assertIn("오류 또는 비정상 전투", browser)

    def test_item_info_style_layout_and_filters_exist(self):
        browser = BROWSER_PATH.read_text(encoding="utf-8-sig")
        required = [
            'frame:SetWidth(900)',
            'frame:SetHeight(610)',
            '"UIPanelScrollFrameTemplate"',
            'AzerothAdminCreatureResultScroll',
            'resultScroll:EnableMouseWheel(true)',
            'table.getn(self.FeaturedCreatures or {})',
            'creatureBrowserExpansionChecks',
            'creatureBrowserRestrictedCheck',
            'creatureBrowserOpenCheck',
        ]
        for marker in required:
            self.assertIn(marker, browser)

    def test_selected_creature_uses_native_335_model_preview(self):
        browser = BROWSER_PATH.read_text(encoding="utf-8-sig")
        self.assertIn('CreateFrame("PlayerModel", "AzerothAdminCreatureModelPreview"', browser)
        self.assertIn("self.creatureBrowserModel.SetCreature", browser)
        self.assertIn("self.creatureBrowserModel.SetRotation", browser)
        self.assertNotIn("SetPortraitTextureFromCreatureDisplayID", browser)

    def test_temp_and_permanent_spawn_are_separate_confirmed_actions(self):
        browser = BROWSER_PATH.read_text(encoding="utf-8-sig")
        self.assertIn('".npc add temp " .. tostring(entry)', browser)
        self.assertIn('".npc add " .. tostring(entry)', browser)
        self.assertRegex(browser, r'creatureDefinition\("\.npc add temp .*?label, true, false\)')
        self.assertRegex(browser, r'creatureDefinition\("\.npc add .*?label, true, true\)')

        search = (ADDON / "KoKRSearch.lua").read_text(encoding="utf-8-sig")
        self.assertIn("현재 위치에 임시 소환 (DB 미저장)", search)
        self.assertIn("현재 위치에 영구 생성 (DB 저장)", search)
        self.assertIn("전체 DB 검색 항목은 지역·인스턴스 스크립트 여부가 분류되지 않았습니다.", search)

    def test_browser_routes_from_existing_creature_search_action(self):
        core = (ADDON / "Core.lua").read_text(encoding="utf-8-sig")
        commands = (ADDON / "Commands.lua").read_text(encoding="utf-8-sig")
        self.assertIn('definition.action == "kr_creature_search"', core)
        self.assertIn("self:ToggleCreatureBrowser()", core)
        self.assertIn("주요 크리처 / 한글·ID 검색", commands)

    def test_toc_load_order_and_managed_frame_registration(self):
        toc = (ADDON / "AzerothAdmin.toc").read_text(encoding="utf-8-sig")
        self.assertLess(toc.index("FeaturedCreatures.lua"), toc.index("CreatureBrowser.lua"))
        self.assertLess(toc.index("CreatureBrowser.lua"), toc.index("Core.lua"))
        core = (ADDON / "Core.lua").read_text(encoding="utf-8-sig")
        self.assertIn("add(self.creatureBrowserFrame)", core)

    def test_full_database_search_remains_available(self):
        browser = BROWSER_PATH.read_text(encoding="utf-8-sig")
        self.assertIn('makeButton(frame, 96, 24, "전체 DB 검색")', browser)
        self.assertIn('addon:OpenLocaleSearch("creature", searchEdit:GetText() or "")', browser)

    def test_filtered_out_selection_cannot_keep_hidden_actions(self):
        browser = BROWSER_PATH.read_text(encoding="utf-8-sig")
        self.assertIn("local selectedFound = false", browser)
        self.assertIn("self:SelectFeaturedCreature(self.creatureBrowserResults[1])", browser)
        self.assertIn('self.creatureBrowserSelectedText:SetText("크리처를 선택하세요.")', browser)


if __name__ == "__main__":
    unittest.main()
