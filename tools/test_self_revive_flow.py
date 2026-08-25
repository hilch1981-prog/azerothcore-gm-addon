import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / "AzerothAdmin/Modules/Shell/Core.lua"
MODULE = ROOT / "AzerothAdmin/Modules/Revive/Module.lua"


def revive_body(text: str, trailer: str) -> str:
    match = re.search(
        rf"function addon:ReviveSmart\(definition\)(.*?)\nend\n\n{trailer}",
        text,
        re.DOTALL,
    )
    if not match:
        raise AssertionError("missing addon:ReviveSmart")
    return match.group(1)


class SelfReviveFlowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = CORE.read_text(encoding="utf-8")
        cls.source = MODULE.read_text(encoding="utf-8")
        cls.body = revive_body(cls.source, "if addon.RegisterModule")
        cls.core_body = revive_body(cls.core, "function addon:ExecuteDefinition")

    def test_module_matches_game_verified_fallback_byte_for_byte(self):
        self.assertEqual(self.core_body, self.body)

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
            self.core,
            re.DOTALL,
        )
        self.assertIsNotNone(match)
        body = match.group(1)
        self.assertIn('if chatType == "WHISPER" then', body)
        self.assertIn(
            'SendChatMessage(command, "WHISPER", nil, chatTarget or UnitName("player"))',
            body,
        )

    def test_core_dispatches_to_runtime_module_function(self):
        self.assertIn('elseif definition.action == "revive" then', self.core)
        self.assertIn("self:ReviveSmart(definition)", self.core)

    def test_module_load_order_and_registration(self):
        toc = (ROOT / "AzerothAdmin/AzerothAdmin.toc").read_text(encoding="utf-8-sig")
        self.assertLess(toc.index("Modules\\Shell\\Core.lua"), toc.index("Modules\\Revive\\Module.lua"))
        self.assertIn('addon:RegisterModule("revive"', self.source)
        self.assertIn('status = "module-active-legacy-fallback"', self.source)
        self.assertIn('addon.ReviveModuleRevision = "1.0.0-fallback"', self.source)


if __name__ == "__main__":
    unittest.main()
