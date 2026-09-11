import unittest
from scripts.route_task import route

class RouterTests(unittest.TestCase):
    def test_small_ui_tweak(self):
        d = route("Small UI tweak: change the save button color")
        self.assertEqual(d["category"], "ui_tweak")
        self.assertEqual(d["primary"]["role"], "implementer")
        self.assertFalse(d["review_required"])
    def test_unclear_bug(self):
        d = route("Unclear crash regression when loading a route")
        self.assertEqual(d["category"], "bug")
        self.assertEqual([x["role"] for x in d["role_stack"]], ["planner", "implementer", "reviewer"])
    def test_major_architecture_change(self):
        d = route("Major architecture migration for the database")
        self.assertEqual(d["category"], "architecture")
        self.assertEqual(d["risk_level"], "high")
        self.assertEqual(d["role_stack"][-1]["role"], "reviewer")
    def test_documentation_cleanup(self):
        d = route("Format and summarize release notes documentation")
        self.assertEqual(d["category"], "documentation")
        self.assertEqual(d["primary"]["role"], "utility")

if __name__ == "__main__": unittest.main()
