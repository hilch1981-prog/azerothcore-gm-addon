import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
QUEST = ROOT / "AzerothAdmin/QuestHelper.lua"


class PartyBotQuestSyncTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = QUEST.read_text(encoding="utf-8-sig")

    def test_ui_has_two_opt_in_saved_checkboxes(self):
        for snippet in (
            '"파티 봇 동기화"',
            '"없는 퀘스트 자동 추가"',
            '"본캐 조건완료 시 봇 완료"',
            "AzerothAdminEasyDB.partyBotQuestAddMissing",
            "AzerothAdminEasyDB.partyBotQuestComplete",
        ):
            self.assertIn(snippet, self.source)

    def test_missing_quests_use_native_wotlk_sharing(self):
        self.assertIn('entry.action == "share"', self.source)
        self.assertIn("QuestLogPushQuest", self.source)
        self.assertIn('self:QueuePartyBotQuestSync("share", quest)', self.source)

    def test_completion_uses_playerbot_group_chat_without_gm_targeting(self):
        self.assertIn('SendChatMessage("quest complete " .. link, channel)', self.source)
        self.assertIn('return "RAID"', self.source)
        self.assertIn('return "PARTY"', self.source)
        queue_match = re.search(
            r"function addon:QueuePartyBotQuestSync\(action, quest\)(.*?)\nend\n\nfunction addon:UpdatePartyBotQuestSnapshot",
            self.source,
            re.DOTALL,
        )
        self.assertIsNotNone(queue_match)
        self.assertNotIn(".quest complete", queue_match.group(1))
        self.assertNotIn("TargetUnit", queue_match.group(1))

    def test_new_quests_and_completion_transitions_are_deduplicated(self):
        for snippet in (
            "self.partyBotQuestQueueKeys[key]",
            "self.elapsed < 0.35",
            "addMissing and previous[id] == nil",
            "completeWithPlayer and isComplete and previous[id] ~= true",
        ):
            self.assertIn(snippet, self.source)

    def test_roster_and_quest_events_trigger_sync(self):
        for event in (
            'questEvent:RegisterEvent("QUEST_LOG_UPDATE")',
            'questEvent:RegisterEvent("PARTY_MEMBERS_CHANGED")',
            'questEvent:RegisterEvent("RAID_ROSTER_UPDATE")',
            'questEvent:RegisterEvent("PLAYER_ENTERING_WORLD")',
        ):
            self.assertIn(event, self.source)
        self.assertIn("addon._partyBotRosterGeneration", self.source)


if __name__ == "__main__":
    unittest.main()
