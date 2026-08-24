import tempfile
import unittest
from pathlib import Path

from tools import build_featured_creature_cache as builder


class FeaturedCreatureSqlParserTests(unittest.TestCase):
    def write_sql(self, text: str) -> Path:
        temp = tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".sql", delete=False)
        with temp:
            temp.write(text)
        self.addCleanup(Path(temp.name).unlink, missing_ok=True)
        return Path(temp.name)

    def test_parses_standard_one_line_extended_insert(self):
        path = self.write_sql(
            "CREATE TABLE `sample` (\n"
            "  `entry` int,\n"
            "  `name` text\n"
            ");\n"
            "INSERT INTO `sample` VALUES (1,'Alpha'),(2,'Beta'),(3,NULL);\n"
        )
        rows = list(builder.iter_rows(path, "sample"))
        self.assertEqual(rows, [
            {"entry": "1", "name": "Alpha"},
            {"entry": "2", "name": "Beta"},
            {"entry": "3", "name": None},
        ])

    def test_parses_multiline_explicit_columns_and_quoted_delimiters(self):
        path = self.write_sql(
            "INSERT INTO `sample` (`name`, `entry`) VALUES\n"
            "('A, B (test); still text', 7),\n"
            "('It''s quoted', 8),\n"
            "('Backslash \\' quote', 9);\n"
        )
        rows = list(builder.iter_rows(path, "sample"))
        self.assertEqual([row["entry"] for row in rows], ["7", "8", "9"])
        self.assertEqual(rows[0]["name"], "A, B (test); still text")
        self.assertEqual(rows[1]["name"], "It's quoted")
        self.assertEqual(rows[2]["name"], "Backslash ' quote")

    def test_parses_replace_statement(self):
        path = self.write_sql(
            "CREATE TABLE `sample` (\n  `entry` int\n);\n"
            "REPLACE INTO `sample` VALUES\n(10),\n(11);\n"
        )
        self.assertEqual(
            list(builder.iter_rows(path, "sample")),
            [{"entry": "10"}, {"entry": "11"}],
        )

    def test_rejects_missing_column_order(self):
        path = self.write_sql("INSERT INTO `sample` VALUES (1,'Alpha');\n")
        with self.assertRaisesRegex(RuntimeError, "No column order available"):
            list(builder.iter_rows(path, "sample"))

    def test_rejects_missing_rows_with_clear_table_name(self):
        path = self.write_sql("CREATE TABLE `sample` (\n  `entry` int\n);\n")
        with self.assertRaisesRegex(RuntimeError, "sample: no INSERT/REPLACE rows parsed"):
            list(builder.iter_rows(path, "sample"))

    def test_rejects_mismatched_value_count(self):
        path = self.write_sql(
            "CREATE TABLE `sample` (\n  `entry` int,\n  `name` text\n);\n"
            "INSERT INTO `sample` VALUES (1);\n"
        )
        with self.assertRaisesRegex(RuntimeError, "value count 1 != columns 2"):
            list(builder.iter_rows(path, "sample"))


if __name__ == "__main__":
    unittest.main()
