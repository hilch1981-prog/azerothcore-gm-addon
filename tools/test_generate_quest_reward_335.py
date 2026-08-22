import struct
import sys
import unittest
import re
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate_quest_reward_335 as generator


class QuestRewardGeneratorTests(unittest.TestCase):
    def test_parses_area_dbc(self):
        records = struct.pack("<4I", 3537, 571, 0, 0)
        payload = b"WDBC" + struct.pack("<4I", 1, 4, 16, 1) + records + b"\0"
        self.assertEqual(generator.parse_area_dbc(payload), {3537: 571})

    def test_rejects_truncated_area_dbc(self):
        payload = b"WDBC" + struct.pack("<4I", 1, 4, 16, 1)
        with self.assertRaisesRegex(ValueError, "truncated"):
            generator.parse_area_dbc(payload)

    def test_builds_separate_fixed_and_choice_buckets(self):
        row = ["0"] * 50
        row[4] = "3537"
        row[22] = "100"
        row[24] = "101"
        row[38] = "200"
        row[40] = "201"
        buckets = generator.build_buckets([row], {3537: 571})
        self.assertEqual(buckets["z1"]["fixed"], {100, 101})
        self.assertEqual(buckets["z1"]["choice"], {200, 201})

    def test_committed_data_has_expected_bucket_counts(self):
        path = (
            Path(__file__).resolve().parents[1]
            / "AzerothAdmin/Embedded/BlueItemInfo3/QuestRewards335.lua"
        )
        counts = {}
        bucket = None
        kind = None
        values = set()
        for line in path.read_text(encoding="utf-8").splitlines():
            bucket_match = re.match(r"  (z[1-4]) = \{", line)
            if bucket_match:
                bucket = bucket_match.group(1)
                continue
            kind_match = re.match(r"    (fixed|choice) = \{", line)
            if kind_match:
                kind = kind_match.group(1)
                values = set()
                continue
            if bucket and kind and line.startswith("      "):
                row = [int(value) for value in re.findall(r"\d+", line)]
                self.assertEqual(len(row), len(set(row)))
                values.update(row)
            elif bucket and kind and line == "    },":
                counts[(bucket, kind)] = len(values)
                kind = None

        self.assertEqual(
            counts,
            {
                ("z1", "fixed"): 27,
                ("z1", "choice"): 1230,
                ("z2", "fixed"): 113,
                ("z2", "choice"): 1005,
                ("z3", "fixed"): 307,
                ("z3", "choice"): 532,
                ("z4", "fixed"): 394,
                ("z4", "choice"): 417,
            },
        )


if __name__ == "__main__":
    unittest.main()
