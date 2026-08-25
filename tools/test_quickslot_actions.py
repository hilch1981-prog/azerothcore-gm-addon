import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "AzerothAdmin"


class QuickslotActionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.core = (ADDON / "Core.lua").read_text(encoding="utf-8-sig")
        cls.ui = (ADDON / "UI.lua").read_text(encoding="utf-8-sig")
        cls.commands = (ADDON / "Modules/Commands/Module.lua").read_text(encoding="utf-8-sig")

    def test_commands_and_client_actions_have_stable_typed_keys(self):
        self.assertIn('return "cmd:" .. tostring(definition.command)', self.core)
        self.assertIn('local key = "action:" .. tostring(definition.action)', self.core)
        self.assertIn("definition.lookupKind", self.core)

    def test_legacy_raw_command_slots_remain_resolvable(self):
        self.assertIn("def.command and def.command == key", self.core)
        self.assertIn("definition.command and favs[i] == definition.command", self.core)

    def test_quickslot_executes_full_definition(self):
        self.assertIn("addon:ExecuteDefinition(def)", self.ui)
        self.assertIn("def.command or def.action", self.ui)
        self.assertNotIn("GM 명령 버튼만 퀵슬롯", self.core)
        self.assertIn("명령·검색·창 열기·토글 기능", self.ui)

    def test_explicit_permission_command_is_preserved(self):
        self.assertIn(
            "def.permissionCommand or def.command or actionPermissionCommands[def.action]",
            self.core,
        )

    def test_creature_diagnostics_keep_target_checks_and_safe_near_distance(self):
        self.assertIn('label = "NPC 정보", command = ".npc info", requires = "creature"', self.commands)
        self.assertIn('label = "NPC GUID", command = ".npc guid", requires = "creature"', self.commands)
        self.assertIn('label = "거리 확인", command = ".distance", requires = "creature"', self.commands)
        self.assertIn('label = "NPC 근처 20m", command = ".npc near 20"', self.commands)

    def test_no_server_response_is_not_reported_as_success(self):
        self.assertIn('"sent", "서버 응답 미확인 · 시스템 채팅 확인"', self.core)
        self.assertNotIn('or "명령 전송 완료"', self.core)
        self.assertIn('state == "sent"', self.ui)


if __name__ == "__main__":
    unittest.main()
