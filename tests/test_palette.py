"""Dependency-free checks for Material 3-inspired desktop colors."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
PALETTE = (ROOT / "package/contents/ui/DesktopPalette.js").read_text(encoding="utf-8")
MAIN = (ROOT / "package/contents/ui/main.qml").read_text(encoding="utf-8")
CONFIG = (ROOT / "package/contents/ui/configGeneral.qml").read_text(encoding="utf-8")
PICKER = (ROOT / "package/contents/ui/ColorPreference.qml").read_text(encoding="utf-8")
DIALOG = (ROOT / "package/contents/ui/ColorPairDialog.qml").read_text(encoding="utf-8")


def luminance(hex_color):
    channels = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
              for v in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


class DesktopPaletteTests(unittest.TestCase):
    def test_sixteen_unique_readable_pairs(self):
        pairs = re.findall(
            r'name:\s*"([^"]+)",\s*foreground:\s*"(#[0-9A-F]{6})",\s*background:\s*"(#[0-9A-F]{6})"',
            PALETTE
        )
        self.assertEqual(len(pairs), 16)
        self.assertEqual(len(set(pairs)), 8)
        self.assertEqual(len({bg for _, _, bg in pairs}), 16)
        for name, fg, bg in pairs:
            l1, l2 = luminance(fg), luminance(bg)
            ratio = (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
            self.assertGreaterEqual(ratio, 9.0, f"{name}: {ratio:.2f}:1")
        # The eighth automatic desktop is dedicated to a green LINE workspace.
        self.assertEqual(pairs[7][0], "Green")
        self.assertEqual(pairs[7][1:], ("#183B1E", "#CDECCB"))
        self.assertEqual(pairs[5][0], "Indigo")

    def test_runtime_and_settings_use_the_same_palette(self):
        self.assertIn("DesktopPalette.forIndex(desktopIndex)", MAIN)
        self.assertIn("DesktopPalette.forIndex(selectedDesktopNumber - 1)", CONFIG)
        for role in ("title", "note", "background"):
            self.assertIn(f'DesktopPalette.roleColor(currentDesktopColors, "{role}"', MAIN)
        self.assertIn('onColorChosen: settings.setColor("foreground", value)', CONFIG)
        self.assertIn('onColorChosen: settings.setColor("background", value)', CONFIG)
        self.assertIn('text: qsTr("Use desktop preset")', PICKER)

    def test_color_button_opens_modal_with_live_preview(self):
        self.assertIn("id: colorPickerButton", MAIN)
        self.assertIn("Layout.preferredWidth: 56", MAIN)
        self.assertIn("color: root.backgroundColor", MAIN)
        self.assertIn("color: root.titleTextColor", MAIN)
        self.assertIn("onClicked: colorDialog.openColors(", MAIN)
        self.assertIn("ColorPairDialog {", MAIN)
        self.assertIn("modal: true", DIALOG)
        self.assertIn("Controls.Popup.CloseOnEscape", DIALOG)
        self.assertIn("model: DesktopPalette.presets.length", DIALOG)
        self.assertIn("onClicked: dialog.choosePreset(index)", DIALOG)

    def test_custom_hex_draft_apply_cancel_and_contrast(self):
        self.assertIn("id: foregroundField", DIALOG)
        self.assertIn("id: backgroundField", DIALOG)
        self.assertIn("signal colorsAccepted(string foregroundHex, string backgroundHex)", DIALOG)
        self.assertIn("ratio >= 4.5", DIALOG)
        self.assertIn("enabled: dialog.canApply", DIALOG)
        self.assertIn("onClicked: dialog.close()", DIALOG)
        self.assertIn("onColorsAccepted: root.saveCurrentDesktopColorPair({", MAIN)
        self.assertIn("plasmoid.configuration.desktopColors = JSON.stringify(map)", MAIN)
        self.assertIn("function contrastRatio(foreground, background)", PALETTE)
        self.assertIn("function indexOfPair(foreground, background)", PALETTE)

    def test_rename_reset_remains_independent(self):
        self.assertIn("function resetDesktopName()", MAIN)
        self.assertIn("function restoreAutomaticColors()", MAIN)
        self.assertIn("submitDesktopRename(defaultDesktopName, true)", MAIN)
        self.assertIn("onAutomaticRequested: root.restoreAutomaticColors()", MAIN)
        self.assertIn('text: qsTr("Automatic colors")', DIALOG)
        self.assertNotIn('text: qsTr("Color combinations")', MAIN)

    def test_popup_controls_follow_plasma_theme(self):
        self.assertIn("import org.kde.plasma.components 3.0 as PlasmaComponents3", MAIN)
        self.assertIn("PlasmaComponents3.Label {", MAIN)
        self.assertIn("PlasmaComponents3.TextField {", MAIN)
        self.assertIn("PlasmaComponents3.TextArea {", MAIN)
        self.assertIn("PlasmaComponents3.Button {", MAIN)
        self.assertIn("color: PlasmaCore.Theme.textColor", MAIN)
        self.assertNotIn("Controls.Label {", MAIN)

    def test_panel_text_is_not_dimmed_below_accessible_contrast(self):
        self.assertNotIn("opacity: compact.nameOnly ? 1 : 0.72", MAIN)
        self.assertNotIn("opacity: root.currentNote.length ? 1 : 0.55", MAIN)
        self.assertIn("font.italic: root.currentNote.length === 0", MAIN)

    def test_session_notes_remain_unpersisted(self):
        xml = (ROOT / "package/contents/config/main.xml").read_text(encoding="utf-8")
        self.assertNotIn('name="notes"', xml)
        self.assertIn('name="desktopColors"', xml)


if __name__ == "__main__":
    unittest.main()
