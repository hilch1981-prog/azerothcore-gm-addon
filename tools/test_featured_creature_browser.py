import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AzerothAdmin"
DATA_PATH = ADDON / "Modules/Creatures/Data.lua"
EXPANDED_DATA_PATH = ADDON / "Modules/Creatures/ExpandedData.lua"
BROWSER_PATH = ADDON / "Modules/Creatures/Browser.lua"
FIXES_PATH = ADDON / "Modules/Creatures/Fixes.lua"
RUNTIME_PATH = ADDON / "Modules/Creatures/RuntimeFixes.lua"
SHELL_CORE = ADDON / "Modules/Shell/Core.lua"
COMMANDS_PATH = ADDON / "Modules/Commands/Module.lua"


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
        for entry, name, *_ in parse_featured_records(DATA_PATH):
            self.assertIn(entry, catalog)
            self.assertEqual(name, catalog[entry])

    def test_every_expanded_name_matches_kokr_catalog(self):
        catalog = parse_kokr_creatures()
        expanded = parse_featured_records(EXPANDED_DATA_PATH)
        self.assertGreaterEqual(len(expanded), 240)
        for entry, name, *_ in expanded:
            self.assertIn(entry, catalog)
            self.assertEqual(name, catalog[entry])
        self.assertEqual(catalog[8567], "게걸먹보")
        self.assertEqual(catalog[9035], "격노의 문지기")

    def test_gundrak_colossus_uses_static_boss_entry_not_elemental_add(self):
        catalog = parse_kokr_creatures()
        self.assertEqual(catalog[29307], "드라카리 거대골렘")
        self.assertEqual(catalog[29573], "드라카리 정령")
        expanded = {
            entry: (name, place)
            for entry, name, _group, _expansion, place, _restricted
            in parse_featured_records(EXPANDED_DATA_PATH)
        }
        self.assertEqual(expanded[29307], ("드라카리 거대골렘", "군드락"))
        self.assertNotIn(29573, expanded)
        self.assertIn(29307, parse_all_featured_entries())
        fixes = FIXES_PATH.read_text(encoding="utf-8-sig")
        self.assertNotIn("correctGundrakEntry", fixes)
        self.assertNotIn("table.insert(list, { 29307", fixes)
        self.assertNotIn("table.insert(list, { 29573", fixes)

    def test_every_instance_record_resolves_to_a_coordinate_command(self):
        fixes = FIXES_PATH.read_text(encoding="utf-8-sig")
        teleports = (ADDON / "Teleports.lua").read_text(encoding="utf-8-sig")

        def table_block(name):
            match = re.search(r"local " + name + r" = \{([\s\S]*?)\n\}", fixes)
            self.assertIsNotNone(match, name)
            return match.group(1)

        safe_places = dict(re.findall(
            r'\["([^"]+)"\]\s*=\s*"([^"]+)"',
            table_block("INSTANCE_SAFE_TELEPORTS"),
        ))
        safe_entries = {
            int(entry): command
            for entry, command in re.findall(
                r'\[(\d+)\]\s*=\s*"([^"]+)"',
                table_block("ENTRY_SAFE_TELEPORTS"),
            )
        }
        aliases = dict(re.findall(
            r'\["([^"]+)"\]\s*=\s*"([^"]+)"',
            table_block("INSTANCE_LABEL_ALIASES"),
        ))
        rows = re.findall(
            r'\{\s*group\s*=\s*"[^"]+",\s*zone\s*=\s*"([^"]+)",'
            r'\s*name\s*=\s*"([^"]+)",\s*command\s*=\s*"([^"]+)"\s*\}',
            teleports,
        )

        def normalize(value):
            return re.sub(r"[\s:\-·_/()\[\]]", "", value or "")

        def resolves(entry, place):
            if entry in safe_entries or place in safe_places:
                return True
            for label in (aliases.get(place), place):
                if not label:
                    continue
                wanted = normalize(label)
                if any(normalize(name) == wanted for _, name, _ in rows):
                    return True
                if any(normalize(zone) == wanted for zone, _, _ in rows):
                    return True
            return False

        unresolved = []
        for path in (DATA_PATH, EXPANDED_DATA_PATH):
            for entry, _, group, _, place, _ in parse_featured_records(path):
                if group in {"raid", "dungeon"} and not resolves(entry, place):
                    unresolved.append((entry, place))
        self.assertEqual(unresolved, [])

    def test_pinned_azerothcore_instance_coordinates_are_exact(self):
        fixes = FIXES_PATH.read_text(encoding="utf-8-sig")
        expected = {
            "용사의 시험장": ".go xyz 804.065 618.033 412.393 650 3.1456",
            "사론의 구덩이": ".go xyz 435.743 212.413 528.709 658 6.25646",
            "영혼의 제련소": ".go xyz 4922.86 2175.63 638.734 632 2.00355",
            "낙스라마스": ".go xyz 3019.34 -3434.36 293.99 533 6.27",
            "흑요석 성소": ".go xyz 3228.58 385.86 65.5484 615 1.578",
            "영원의 눈": ".go xyz 728.055 1329.03 267.235 616 5.51524",
            "울두아르": ".go xyz -914.041 -148.98 463.137 603 6.28",
            "십자군의 시험장": ".go xyz 563.61 80.6815 395.2 649 1.59",
            "오닉시아의 둥지": ".go xyz 29.1607 -71.3372 -8.18032 249 4.58",
            "얼음왕관 성채": ".go xyz 65.7692 2211.28 30 631 3.14651",
            "루비 성소": ".go xyz 3274 533.531 87.665 724 3.16",
        }
        for place, command in expected.items():
            self.assertIn(f'["{place}"] = "{command}"', fixes)
        self.assertNotIn("3005.68 -3447.77 293.93", fixes)

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
        for marker in (
            'frame:SetWidth(900)',
            'frame:SetHeight(610)',
            '"UIPanelScrollFrameTemplate"',
            'AzerothAdminCreatureResultScroll',
            'resultScroll:EnableMouseWheel(true)',
            'table.getn(self.FeaturedCreatures or {})',
            'creatureBrowserExpansionChecks',
            'creatureBrowserRestrictedCheck',
            'creatureBrowserOpenCheck',
        ):
            self.assertIn(marker, browser)

    def test_selected_creature_uses_native_335_model_preview(self):
        browser = BROWSER_PATH.read_text(encoding="utf-8-sig")
        self.assertIn('CreateFrame("PlayerModel", "AzerothAdminCreatureModelPreview"', browser)
        self.assertIn("self.creatureBrowserModel.SetCreature", browser)
        self.assertIn("self.creatureBrowserModel.SetRotation", browser)
        self.assertNotIn("SetPortraitTextureFromCreatureDisplayID", browser)

    def test_r81_runtime_uses_native_npcscan_model_lifecycle(self):
        runtime = RUNTIME_PATH.read_text(encoding="utf-8-sig")
        for marker in (
            'addon.CreatureBrowserRuntimeRevision = "IME R6 / MODEL R8.1 PRECHECK"',
            'model:Show()',
            'model.ClearModel',
            'model:SetScript("OnUpdateModel"',
            'safeCall(model.SetCreature, model, entry)',
            'safeCall(model.SetUnit, model, "target")',
            'string.sub(guid, 8, 12)',
        ):
            self.assertIn(marker, runtime)
        self.assertNotIn('sendPreviewCommand(".morph target ', runtime)
        self.assertNotIn('sendPreviewCommand(".morph reset")', runtime)
        self.assertNotIn("SetDisplayInfo", runtime)

    def test_game_verified_r6_korean_ime_release_is_restored_without_chat_submit(self):
        runtime = RUNTIME_PATH.read_text(encoding="utf-8-sig")
        for marker in (
            "function addon:ReleaseKoreanSearchInput(edit)",
            "edit.ToggleInputLanguage",
            'language == "ROMAN"',
            "GetCurrentKeyBoardFocus",
            "edit.EnableKeyboard",
            "makeEditReactivatable",
            "ChatEdit_DeactivateChat",
            "hookSubmitButton",
            "hookEnter",
        ):
            self.assertIn(marker, runtime)
        for marker in (
            "ChatEdit_OnEnterPressed",
            "ChatEdit_SendText",
            "ChatEdit_ActivateChat",
            'edit:SetText("  ")',
        ):
            self.assertNotIn(marker, runtime)

    def test_unused_private_model_map_is_not_shipped_or_loaded(self):
        self.assertFalse((ADDON / "FeaturedCreatureModels.lua").exists())
        toc = (ADDON / "AzerothAdmin.toc").read_text(encoding="utf-8-sig")
        self.assertNotIn("FeaturedCreatureModels.lua", toc)

    def test_temp_and_permanent_spawn_are_separate_confirmed_actions(self):
        browser = BROWSER_PATH.read_text(encoding="utf-8-sig")
        self.assertIn('".npc add temp " .. tostring(entry)', browser)
        self.assertIn('".npc add " .. tostring(entry)', browser)
        self.assertRegex(browser, r'creatureDefinition\("\.npc add temp .*?label, true, false\)')
        self.assertRegex(browser, r'creatureDefinition\("\.npc add .*?label, true, true\)')
        search = (ADDON / "Modules/Search/Module.lua").read_text(encoding="utf-8-sig")
        self.assertIn("현재 위치에 임시 소환 (DB 미저장)", search)
        self.assertIn("현재 위치에 영구 생성 (DB 저장)", search)
        self.assertIn("전체 DB 검색 항목은 지역·인스턴스 스크립트 여부가 분류되지 않았습니다.", search)

    def test_browser_routes_from_existing_creature_search_action(self):
        core = SHELL_CORE.read_text(encoding="utf-8-sig")
        commands = COMMANDS_PATH.read_text(encoding="utf-8-sig")
        self.assertIn('definition.action == "kr_creature_search"', core)
        self.assertIn("self:ToggleCreatureBrowser()", core)
        self.assertIn("주요 크리처 / 한글·ID 검색", commands)

    def test_toc_load_order_and_managed_frame_registration(self):
        toc = (ADDON / "AzerothAdmin.toc").read_text(encoding="utf-8-sig")
        self.assertLess(toc.index("Modules\\Creatures\\Data.lua"), toc.index("Modules\\Creatures\\Browser.lua"))
        self.assertLess(toc.index("Modules\\Creatures\\ExpandedData.lua"), toc.index("Modules\\Creatures\\RuntimeFixes.lua"))
        self.assertLess(toc.index("Modules\\Creatures\\Browser.lua"), toc.index("Modules\\Shell\\Core.lua"))
        self.assertLess(toc.index("Modules\\Creatures\\RuntimeFixes.lua"), toc.index("Modules\\Creatures\\Registration.lua"))
        core = SHELL_CORE.read_text(encoding="utf-8-sig")
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
