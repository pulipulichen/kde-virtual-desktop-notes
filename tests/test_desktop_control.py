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

    def test_rejects_blank_names_and_invalid_indices(self):
        for args in (("rename", "1", "1", ""), ("rename", "2", "1", "Name"),
                     ("rename", "uuid", "0", "Name"), ("rename", "uuid", "1", "a\nb")):
            with self.subTest(args=args):
                self.assertNotEqual(self.run_helper(*args).returncode, 0)
        self.assertFalse(self.log.exists())

    def test_qml_uses_native_context_menu_and_separate_name_editor(self):
        qml = (ROOT / "package/contents/ui/main.qml").read_text(encoding="utf-8")
        self.assertIn('Plasmoid.setAction("renameDesktop"', qml)
        self.assertIn('Plasmoid.setAction("openDesktopSettings"', qml)
        self.assertIn('function action_renameDesktop()', qml)
        self.assertIn('function action_openDesktopSettings()', qml)
        self.assertIn('org.kde.plasma.core 2.0 as PlasmaCore', qml)
        self.assertIn('id: desktopNameEditor', qml)
        self.assertIn('root.submitDesktopRename(text)', qml)
        self.assertIn('root.saveNote(text)', qml)


if __name__ == "__main__":
    unittest.main()
