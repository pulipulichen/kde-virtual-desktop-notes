"""Tests for the Plasma 5 panel's KWin desktop-management helper."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "package/contents/scripts/desktop-control.sh"


class DesktopControlTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.bin_dir = Path(self.tmp.name, "bin")
        self.bin_dir.mkdir()
        self.log = Path(self.tmp.name, "commands.log")
        self.env = dict(os.environ, PATH=str(self.bin_dir) + os.pathsep + os.environ["PATH"],
                        TEST_DESKTOP_LOG=str(self.log))
        self.mock_command("dbus-send")
        self.mock_command("kwriteconfig5")
        self.mock_command("kreadconfig5", 'printf "test-kwin-desktop-uuid\\n"')

    def mock_command(self, name, body='printf "%s\\0" "$@" >> "$TEST_DESKTOP_LOG"'):
        path = self.bin_dir / name
        path.write_text("#!/usr/bin/env bash\nset -euo pipefail\n" + body + "\n", encoding="utf-8")
        path.chmod(0o755)

    def run_helper(self, *args):
        return subprocess.run(["bash", str(HELPER), *args], env=self.env,
                              text=True, capture_output=True, check=False)

    def test_x11_numeric_desktop_is_resolved_to_kwin_uuid(self):
        unsafe_name = "API's; $(touch /tmp/should-not-run) 中文"
        result = self.run_helper("rename", "3", "3", unsafe_name)
        self.assertEqual(result.returncode, 0, result.stderr)
        items = self.log.read_bytes().split(b"\0")
        self.assertIn(b"string:test-kwin-desktop-uuid", items)
        self.assertIn(("string:" + unsafe_name).encode(), items)
        self.assertIn(b"Name_3", items)
        self.assertIn(unsafe_name.encode(), items)

    def test_wayland_uuid_is_passed_through(self):
        result = self.run_helper("rename", "wayland-uuid-123", "2", "開發")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(b"string:wayland-uuid-123", self.log.read_bytes())

    def test_blank_names_restore_desktop_number(self):
        for raw in ("", "  ", "\t "):
            with self.subTest(raw=raw):
                self.log.unlink(missing_ok=True)
                result = self.run_helper("rename", "3", "3", raw)
                self.assertEqual(result.returncode, 0, result.stderr)
                items = self.log.read_bytes().split(b"\0")
                self.assertIn(b"string:Desktop 3", items)
                self.assertIn(b"Name_3", items)
                self.assertIn(b"Desktop 3", items)

    def test_blank_name_on_wayland_restores_numbered_default(self):
        result = self.run_helper("rename", "wayland-uuid-123", "5", "")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(b"string:Desktop 5", self.log.read_bytes())

    def test_rejects_invalid_indices_and_multiline_names(self):
        for args in (("rename", "2", "1", "Name"),
                     ("rename", "uuid", "0", "Name"), ("rename", "uuid", "1", "a\nb")):
            with self.subTest(args=args):
                self.assertNotEqual(self.run_helper(*args).returncode, 0)
        self.assertFalse(self.log.exists())

    def test_reset_all_names_x11_uses_each_position(self):
        result = self.run_helper("reset-all", "1", "1", "2", "2", "3", "3")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Reset 3 desktop name(s).", result.stdout)
        items = self.log.read_bytes().split(b"\\0")
        for number in (1, 2, 3):
            with self.subTest(desktop=number):
                self.assertIn(f"string:Desktop {number}".encode(), items)
                self.assertIn(f"Name_{number}".encode(), items)
                self.assertIn(f"Desktop {number}".encode(), items)

    def test_reset_all_names_wayland_uses_ids_not_ordinals(self):
        result = self.run_helper("reset-all", "uuid-abc", "1", "uuid-def", "2")
        self.assertEqual(result.returncode, 0, result.stderr)
        items = self.log.read_bytes().split(b"\\0")
        self.assertIn(b"string:uuid-abc", items)
        self.assertIn(b"string:uuid-def", items)
        self.assertIn(b"string:Desktop 1", items)
        self.assertIn(b"string:Desktop 2", items)

    def test_reset_all_validates_complete_request_before_writing(self):
        invalid = (
            ("reset-all",),
            ("reset-all", "uuid-abc", "1", "uuid-def"),
            ("reset-all", "1", "1", "2", "3"),
            ("reset-all", "uuid-abc", "1", "uuid-def", "1"),
            ("reset-all", "uuid-abc", "0"),
            ("reset-all", "", "1"),
        )
        for args in invalid:
            with self.subTest(args=args):
                result = self.run_helper(*args)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertFalse(self.log.exists(), "Invalid input must not change any names")

    def test_reset_all_continues_after_one_kwin_failure(self):
        self.mock_command(
            "dbus-send",
            'printf "%s\\0" "$@" >> "$TEST_DESKTOP_LOG"; '
            'if [[ " $* " == *"string:Desktop 2"* ]]; then exit 1; fi',
        )
        result = self.run_helper("reset-all", "uuid-one", "1", "uuid-two", "2",
                                 "uuid-three", "3")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Failed to reset Desktop 2", result.stderr)
        self.assertIn("Unable to reset 1 virtual desktop name", result.stderr)
        items = self.log.read_bytes().split(b"\\0")
        self.assertIn(b"string:Desktop 1", items)
        self.assertIn(b"string:Desktop 2", items)
        self.assertIn(b"string:Desktop 3", items)
        self.assertNotIn(b"Name_2", items)
        self.assertIn(b"Name_1", items)
        self.assertIn(b"Name_3", items)

    def test_appearance_settings_reset_is_confirmed_and_does_not_touch_prefs(self):
        qml = (ROOT / "package/contents/ui/configGeneral.qml").read_text(encoding="utf-8")
        self.assertIn('qsTr("Reset all virtual desktop names…")', qml)
        self.assertIn('id: resetNamesConfirmation', qml)
        self.assertIn('standardButtons: Controls.Dialog.Yes | Controls.Dialog.Cancel', qml)
        self.assertIn('helperCommand("reset-all", args)', qml)
        self.assertIn('engine: "executable"', qml)
        self.assertIn('args.push(String(ids[i]))', qml)
        self.assertIn('args.push(String(i + 1))', qml)

    def test_qml_uses_native_context_menu_and_separate_name_editor(self):
        qml = (ROOT / "package/contents/ui/main.qml").read_text(encoding="utf-8")
        self.assertIn('Plasmoid.setAction("renameDesktop"', qml)
        self.assertIn('Plasmoid.setAction("openDesktopSettings"', qml)
        self.assertIn('function action_renameDesktop()', qml)
        self.assertIn('function action_openDesktopSettings()', qml)
        self.assertIn('org.kde.plasma.core 2.0 as PlasmaCore', qml)
        self.assertIn('id: desktopNameEditor', qml)
        self.assertIn('root.submitDesktopRename(text)', qml)
        self.assertIn('function resetDesktopName()', qml)
        self.assertIn('submitDesktopRename(defaultDesktopName, true)', qml)
        self.assertIn('onClicked: root.resetDesktopName()', qml)
        self.assertIn('placeholderText: root.defaultDesktopName', qml)
        self.assertIn('readonly property string defaultDesktopName: "Desktop "', qml)
        self.assertIn('Plasmoid.fullRepresentation: FocusScope', qml)
        self.assertIn('id: editPopup', qml)
        self.assertIn('root.saveNote(noteEditor.text)', qml)
        self.assertIn('root.startEditingNote()', qml)
        self.assertIn('plasmoid.expanded = true', qml)


if __name__ == "__main__":
    unittest.main()
