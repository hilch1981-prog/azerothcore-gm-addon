import unittest

from tools.validate_addon_structure import validate


class AddonStructureTests(unittest.TestCase):
    def test_manifest_xml_order_and_feature_boundaries(self):
        self.assertEqual([], validate())


if __name__ == "__main__":
    unittest.main()
