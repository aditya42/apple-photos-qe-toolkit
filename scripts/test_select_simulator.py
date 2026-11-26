"""Offline regression tests for simulator selection."""
import unittest
from select_simulator import select_simulator


class SimulatorSelectionTests(unittest.TestCase):
    def setUp(self):
        self.data = {
            "runtimes": [
                {"name": "iOS 18.4", "identifier": "ios18.4", "isAvailable": True},
                {"name": "iOS 18.5", "identifier": "ios18.5", "isAvailable": True},
                {"name": "iOS 26.2", "identifier": "ios26.2", "isAvailable": True},
            ],
            "devicetypes": [{"name": "iPhone 16", "identifier": "iPhone16"}],
        }

    def test_xcode_16(self):
        self.assertEqual(select_simulator(self.data, "Xcode 16.4\nBuild version 16F6"), ("iPhone16", "ios18.5"))

    def test_xcode_17(self):
        self.assertEqual(select_simulator(self.data, "Xcode 17.0\nBuild version ABC"), ("iPhone16", "ios26.2"))

    def test_no_compatible_runtime(self):
        self.data["runtimes"] = [self.data["runtimes"][-1]]
        with self.assertRaisesRegex(ValueError, "No compatible iOS 18"):
            select_simulator(self.data, "Xcode 16.4")

    def test_unknown_xcode(self):
        with self.assertRaisesRegex(ValueError, "Unsupported Xcode 15"):
            select_simulator(self.data, "Xcode 15.4")


if __name__ == "__main__":
    unittest.main()
