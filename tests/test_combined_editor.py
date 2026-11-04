"""Source-level regression checks for the shared desktop-name/note popup.

Run with: python3 -m unittest discover -s tests -v
A live KDE Plasma session is still required for interactive UI verification.
"""

from pathlib import Path
import re
import unittest
import xml.etree.ElementTree as ET


PROJECT = Path(__file__).resolve().parents[1]
MAIN_QML = PROJECT / "package/contents/ui/main.qml"
SETTINGS_QML = PROJECT / "package/contents/ui/configGeneral.qml"
KCONFIG = PROJECT / "package/contents/config/main.xml"


class CombinedEditorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = MAIN_QML.read_text(encoding="utf-8")
        cls.settings = SETTINGS_QML.read_text(encoding="utf-8")

    def test_name_only_is_default_in_kconfig(self):
        ns = {"k": "http://www.kde.org/standards/kcfg/1.0"}
        root = ET.parse(KCONFIG).getroot()
        default = root.find(
            "./k:group/k:entry[@name='desktopNameOnly']/k:default", ns
        )
        self.assertIsNotNone(default)
        self.assertEqual(default.text, "true")

    def test_name_only_checkbox_matches_kconfig_default(self):
        self.assertRegex(
            self.settings,
            r'id: nameOnly\s+text: qsTr\("Show only the virtual desktop name '
            r'\(hide notes\)"\)\s+checked: true',
        )

    def test_name_and_note_are_editable_from_both_popup_entry_points(self):
        self.assertIn("visible: root.renamingDesktop || root.editing", self.main)
        self.assertRegex(
            self.main,
            r"id: noteEditor\s+visible: "
            r"!plasmoid\.configuration\.desktopNameOnly",
        )
        self.assertIn("desktopNameEditor.text = root.desktopName", self.main)
        self.assertIn("noteEditor.text = root.currentNote", self.main)

    def test_save_stages_note_until_rename_succeeds(self):
        self.assertIn("pendingNoteSave = noteDraft !== undefined", self.main)
        self.assertIn("pendingNoteDraft = pendingNoteSave", self.main)
        self.assertRegex(
            self.main,
            r"if \(succeeded\) \{\s+if \(shouldSaveNote\)"
            r"\s+root\.saveNote\(noteDraft\)",
        )
        # Even without a KWin name change, clicking Done must save the note.
        self.assertRegex(
            self.main,
            r"if \(name === desktopName && !useDefault && !forceUpdate\)"
            r" \{\s+if \(noteDraft !== undefined\)\s+saveNote\(noteDraft\)",
        )
        self.assertIn("plasmoid.configuration.desktopNameOnly ? undefined : noteEditor.text", self.main)


if __name__ == "__main__":
    unittest.main()
