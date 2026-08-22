import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
QUEST_HELPER = ROOT / "AzerothAdmin/QuestHelper.lua"


def lua_function(source, name, next_name):
    match = re.search(
        rf"function\s+{re.escape(name)}\([^)]*\)(.*?)\nend\n\nfunction\s+{re.escape(next_name)}",
        source,
        re.DOTALL,
    )
    if not match:
        raise AssertionError(f"missing Lua function: {name}")
    return match.group(1)


class QuestDropSourceCycleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = QUEST_HELPER.read_text(encoding="utf-8")
        cls.sources = lua_function(
            cls.source,
            "addon:GetQuestItemDropSources",
            "addon:QuestObjectiveLookup",
        )
        cls.teleport = lua_function(
            cls.source,
            "addon:QuestObjectiveTeleport",
            "addon:QuestObjectiveAddItem",
        )

    def test_questie_public_drop_query_is_used(self):
        self.assertIn(
            'pcall(qdb.QueryItem, itemID, {"npcDrops", "objectDrops"})',
            self.sources,
        )
        self.assertIn("local npcs = raw[1]", self.sources)
        self.assertIn("local objects = raw[2]", self.sources)
        self.assertNotIn("_itemAdapterQueryOrder", self.sources)

    def test_sources_are_deduplicated_and_sorted(self):
        self.assertIn('local key = kind .. ":" .. id', self.sources)
        self.assertIn("if seen[key] then return end", self.sources)
        self.assertIn("local sourceOrder = { monster = 1, object = 2 }", self.sources)
        self.assertIn("table.sort(sources", self.sources)
        self.assertIn("return a.id < b.id", self.sources)

    def test_repeated_clicks_cycle_all_sources(self):
        self.assertIn(
            "((tonumber(obj._aaeDropSourceIndex) or 0) % table.getn(sources)) + 1",
            self.teleport,
        )
        self.assertIn("local source = sources[obj._aaeDropSourceIndex]", self.teleport)

    def test_npc_and_gameobject_use_distinct_go_commands(self):
        self.assertIn('self:SendNow(".go creature id " .. source.id)', self.teleport)
        self.assertIn('self:SendNow(".go gameobject id " .. source.id)', self.teleport)

    def test_missing_drop_data_falls_back_to_quest_poi(self):
        self.assertIn("local areaID, x, y = self:GetQuestPOILocation(obj)", self.teleport)
        self.assertIn('self:SendNow(string.format(".go zonexy', self.teleport)


if __name__ == "__main__":
    unittest.main()
