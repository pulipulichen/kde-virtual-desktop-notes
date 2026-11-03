"""Source-level regressions for the per-desktop emoji/KDE icon picker."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
MAIN = (ROOT / "package/contents/ui/main.qml").read_text(encoding="utf-8")
DIALOG = (ROOT / "package/contents/ui/DesktopIconDialog.qml").read_text(encoding="utf-8")
XML = (ROOT / "package/contents/config/main.xml").read_text(encoding="utf-8")


class DesktopIconPickerTests(unittest.TestCase):
    def test_common_work_emojis_and_kde_icons(self):
        emoji_section = DIALOG.split("readonly property var emojiChoices:", 1)[1].split(
            "readonly property var kdeIconChoices:", 1
        )[0]
        icon_section = DIALOG.split("readonly property var kdeIconChoices:", 1)[1].split(
            "function openIcons", 1
        )[0]
        self.assertGreaterEqual(len(re.findall(r'value: ".+?", label: qsTr\("', emoji_section)), 30)
        self.assertGreaterEqual(len(re.findall(r'value: ".+?", label: qsTr\("', icon_section)), 12)
        for emoji in ("💼", "✅", "📝", "💻", "📅", "💬", "🔬", "📚", "🎨"):
            self.assertIn(emoji, emoji_section)
        self.assertIn('value: "utilities-terminal"', icon_section)
        self.assertIn('value: "folder"', icon_section)

    def test_modal_draft_cancel_and_text_only(self):
        self.assertIn("modal: true", DIALOG)
        self.assertIn("Controls.Popup.CloseOnEscape", DIALOG)
        self.assertIn('text: qsTr("No icon — show desktop name")', DIALOG)
        self.assertIn('onClicked: dialog.selectIcon("", "")', DIALOG)
        self.assertIn("signal iconAccepted(string kind, string value)", DIALOG)
        self.assertIn("dialog.iconAccepted(dialog.draftKind, dialog.draftValue)", DIALOG)
        self.assertIn("onClicked: dialog.close()", DIALOG)
        self.assertIn('onIconAccepted: root.saveCurrentDesktopIcon(kind, value)', MAIN)

    def test_name_field_has_independent_icon_button(self):
        self.assertIn("id: iconPickerButton", MAIN)
        self.assertLess(MAIN.index("id: iconPickerButton"), MAIN.index("id: desktopNameEditor"))
        self.assertLess(MAIN.index("id: desktopNameEditor"), MAIN.index("id: colorPickerButton"))
        self.assertIn("onClicked: iconDialog.openIcons(", MAIN)
        self.assertIn("onClicked: colorDialog.openColors(", MAIN)
        self.assertIn("function saveCurrentDesktopIcon(kind, value)", MAIN)
        self.assertIn("function submitDesktopRename(rawName, forceUpdate)", MAIN)

    def test_per_desktop_persistent_icons_and_plain_text_fallback(self):
        self.assertIn('name="desktopIcons" type="String"', XML)
        self.assertIn('JSON.parse(plasmoid.configuration.desktopIcons || "{}")', MAIN)
        self.assertIn("desktopIcons[desktopKey]", MAIN)
        self.assertIn("map[desktopKey] = {kind: kind, value: String(value)}", MAIN)
        self.assertIn("delete map[desktopKey]", MAIN)
        self.assertIn("plasmoid.configuration.desktopIcons = JSON.stringify(map)", MAIN)
        self.assertIn("? root.currentDesktopIcon.value : root.desktopName", MAIN)
        self.assertIn("root.currentDesktopIcon.kind === \"icon\"", MAIN)
        # Notes are intentionally session-only, even when icon settings persist.
        self.assertNotIn('name="notes"', XML)


if __name__ == "__main__":
    unittest.main()
