import tempfile
import unittest
from pathlib import Path

from tools.build_release_zip import build_archive, verify_archive


class ReleaseZipTests(unittest.TestCase):
    def test_release_zip_is_complete_and_deterministic(self):
        with tempfile.TemporaryDirectory() as directory:
            first = Path(directory) / "first.zip"
            second = Path(directory) / "second.zip"
            first_digest = build_archive(first)
            second_digest = build_archive(second)
            verify_archive(first)
            verify_archive(second)
            self.assertEqual(first_digest, second_digest)
            self.assertEqual(first.read_bytes(), second.read_bytes())


if __name__ == "__main__":
    unittest.main()
