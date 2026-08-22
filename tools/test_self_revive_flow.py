import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "AzerothAdmin/Core.lua"


class SelfReviveFlowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = CORE.read_text(encoding="utf-8")
        match = re.search(
            r"function addon:ReviveSmart\(definition\)(.*?)\nend\n\nfunction addon:ExecuteDefinition",
            cls.source,
            re.DOTALL,
        )
        if not match:
            raise AssertionError("missing addon:ReviveSmart")
        cls.body = match.group(1)

    def test_all_wotlk_death_states_are_checked(self):
        self.assertIn('UnitIsDeadOrGhost("player")', self.body)
        self.assertIn('UnitIsDead("player")', self.body)
        self.assertIn('UnitIsGhost("player")', self.body)

    def test_dead_player_uses_unambiguous_self_whisper(self):
        self.assertIn('local playerName = UnitName("player")', self.body)
        self.assertIn("if ClearTarget then pcall(ClearTarget) end", self.body)
        self.assertIn(
            'addon:SendNow(".revive", definition, "WHISPER", playerName)',
            self.body,
        )
        self.assertIn(
            'addon:SendNow(".revive", nil, "WHISPER", playerName)',
            self.body,
        )

    def test_retries_only_while_still_dead(self):
        self.assertIn("self:RunAfter(0.35", self.body)
        self.assertIn("self:RunAfter(0.90", self.body)
        self.assertGreaterEqual(self.body.count("if stillDead then"), 2)
        self.assertIn('addon:SendNow(".revive")', self.body)

    def test_alive_path_keeps_target_or_self_behavior(self):
        self.assertIn('self:SendNow(".revive", definition)', self.body)

    def test_send_now_supports_self_whisper_transport(self):
        match = re.search(
            r"function addon:SendNow\(command, definition, chatType, chatTarget\)(.*?)\nend\n\nfunction addon:GetSelfLowGUID",
            self.source,
            re.DOTALL,
        )
        self.assertIsNotNone(match)
        body = match.group(1)
        self.assertIn('if chatType == "WHISPER" then', body)
        self.assertIn(
            'SendChatMessage(command, "WHISPER", nil, chatTarget or UnitName("player"))',
            body,
        )


if __name__ == "__main__":
    unittest.main()
