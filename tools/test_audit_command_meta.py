import hashlib
import sys
import tempfile
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))

import audit_command_meta as audit


class CommandMetadataAuditTests(unittest.TestCase):
    def test_parses_command_sql_rows(self):
        commands = audit.parse_command_sql(
            "('account',0,'Syntax: .account'),\n"
            r"('example',2,'It\'s valid');" + "\n"
        )

        self.assertEqual(commands, {"account": 0, "example": 2})

    def test_lua_entries_allow_optional_commas_and_comments(self):
        security, syntax = audit.parse_lua_metadata(
            '''addon.CommandSecurity = {
    ["account"] = 0 -- final entry
}
addon.CommandSyntax = {
    ["account"] = "Syntax: .account" -- final entry
}
'''
        )

        self.assertEqual(security, {"account": 0})
        self.assertEqual(syntax, {"account"})

    def test_lua_parser_rejects_unparsed_data_lines(self):
        with self.assertRaisesRegex(ValueError, "unparsed CommandSecurity line"):
            audit.parse_lua_metadata(
                '''addon.CommandSecurity = {
    broken metadata
}
'''
            )

    def test_local_source_sha256_is_verified(self):
        payload = b"command data"
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "command.sql"
            source.write_bytes(payload)
            expected = hashlib.sha256(payload).hexdigest()

            self.assertEqual(audit.load_source(str(source), expected), "command data")
            with self.assertRaisesRegex(ValueError, "SHA-256 mismatch"):
                audit.load_source(str(source), "0" * 64)


if __name__ == "__main__":
    unittest.main()
