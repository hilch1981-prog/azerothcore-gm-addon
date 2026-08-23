import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AzerothAdmin"
DATA_PATH = ADDON / "FeaturedCreatures.lua"
EXPANDED_DATA_PATH = ADDON / "FeaturedCreaturesExpanded.lua"
MODEL_DATA_PATH = ADDON / "FeaturedCreatureModels.lua"
BROWSER_PATH = ADDON / "CreatureBrowser.lua"
RUNTIME_PATH = ADDON / "CreatureBrowserRuntimeFixes.lua"


def parse_featured_records(path=DATA_PATH):
    text = path.read_text(encoding="utf-8-sig")
    pattern = re.compile(
        r'\{\s*(\d+),\s*"([^"]+)",\s*"(raid|dungeon|world|rare|event|utility|leader)",\s*'
        r'"(classic|tbc|wotlk)",\s*"([^"]+)",\s*(true|false)\s*\}'
    )
    return [
        (int(entry), name, group, expansion, place, restricted == "true")
        for entry, name, group, expansion, place, restricted in pattern.findall(text)
    ]


def parse_all_featured_entries():
    entries = {record[0] for record in parse_featured_records(DATA_PATH)}
    entries.update(record[0] for record in parse_featured_records(EXPANDED_DATA_PATH))
    return entries


def parse_model_map():
    text = MODEL_DATA_PATH.read_text(encoding="utf-8-sig")
    return {
        int(entry): (int(display_id), float(scale), int(build))
        for entry, display_id, scale, build in re.findall(
            r'\[(\d+)\]\s*=\s*\{\s*(\d+)\s*,\s*([0-9.]+)\s*,\s*(-?\d+)\s*\}', text
        )
    }


def parse_kokr_creatures():
    text = (ADDON / "KoKRSearchData.lua").read_text(encoding="utf-8-sig")
    creature_section = text.split("creature = {", 1)[1]
    return {
        int(entry): name
        for entry, name in re.findall(r'\{\s*(\d+),\s*"([^"]+)"\s*\}', creature_section)
    }


class FeaturedCreatureBrowserTests(unittest.TestCase):
    def test_featured_table_is_closed_at_end_of_file(self):
        text = DATA_PATH.read_text(encoding="utf-8-sig")
        self.assertRegex(text, r"addon\.FeaturedCreatures\s*=\s*\{[\s\S]*\}\s*$")

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

    def test_r81_model_map_covers_every_featured_entry(self):
        featured = parse_all_featured_entries()
        models = parse_model_map()
        self.assertGreaterEqual(len(featured), 400)
        self.assertEqual(featured - set(models), set())
        for entry in featured:
            display_id, scale, _build = models[entry]
            self.assertGreater(display_id, 0)
            self.assertGreater(scale, 0)

    def test_r81_known_azerothcore_display_ids_are_pinned(self):
        models = parse_model_map()
        self.assertEqual(models[4949][0], 4527)
        self.assertEqual(models[4968][0], 30863)
        self.assertEqual(models[10181][0], 28213)
        self.assertEqual(models[10184][0], 8570)
        self.assertEqual(models[12397][0], 12449)
        self.assertEqual(models[36597][0], 30721)

    def test_r81_runtime_uses_native_npcscan_model_lifecycle(self):
        runtime = RUNTIME_PATH.read_text(encoding="utf-8-sig")
        required = [
            'addon.CreatureBrowserRuntimeRevision = "IME/MODEL R8.1 PRECHECK"',
            'model:Show()',
            'model.ClearModel',
            'model:SetScript("OnUpdateModel"',
            'safeCall(model.SetCreature, model, entry)',
            'safeCall(model.SetUnit, model, "target")',
            'string.sub(guid, 8, 12)',
        ]
        for marker in required:
            self.assertIn(marker, runtime)
        self.assertNotIn('sendPreviewCommand(".morph target ', runtime)
        self.assertNotIn('sendPreviewCommand(".morph reset")', runtime)
        self.assertNotIn("SetDisplayInfo", runtime)

    def test_r81_korean_ime_uses_native_blank_chat_flush_on_every_exit(self):
        runtime = RUNTIME_PATH.read_text(encoding="utf-8-sig")
        required = [
            "function addon:ReleaseKoreanSearchInput(edit)",
            "nativeBlankChatFlush",
            'edit:SetText("  ")',
            "ChatEdit_OnEnterPressed",
            "ChatEdit_ActivateChat",
            "hasMeaningfulText",
            "hookSubmitButton",
            "hookEnter",
            "hookEscape",
            "hookFrameHide",
        ]
        for marker in required:
            self.assertIn(marker, runtime)
        self.assertNotIn("edit.ToggleInputLanguage", runtime)
        self.assertNotIn("safeCall(edit.ToggleInputLanguage", runtime)

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
        self.assertLess(toc.index("FeaturedCreaturesExpanded.lua"), toc.index("FeaturedCreatureModels.lua"))
        self.assertLess(toc.index("FeaturedCreatureModels.lua"), toc.index("CreatureBrowserRuntimeFixes.lua"))
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
