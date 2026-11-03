# KDE Virtual Desktop Notes

![Virtual Desktop Notes icon](package/contents/images/icon.svg)

A panel notes widget for **KDE Plasma 5.27** (such as Kubuntu 24.04). It automatically displays the current virtual desktop's name and lets you keep separate one- or two-line notes for each virtual desktop.

## Features

- **Automatic desktop name display:** Retrieves the current virtual desktop name from KDE and updates it when you switch desktops or rename one. Enabled by default and can be hidden in the widget settings.
- **Name-only mode:** Check **Show only the virtual desktop name (hide notes)** in Appearance to display the current desktop name across the entire widget. Notes are hidden (not deleted) until the option is disabled.
- **Notes for each desktop:** Uses KDE virtual desktop IDs to keep notes separate, even if a desktop is renamed.
- **Single editor for one or two lines:** Click the note area to edit. Enter a single line or press Enter to add a second line (up to two lines total). The desktop name appears above the notes and does not count toward the two-line limit.
- **Adaptive font size:** Automatically scales text based on the available panel height, configured widget width, and text length. The editor uses the same actual font size as the displayed text.
- **Adjustable width:** 80–900 px (**100 px by default**).
- **Notes reset on restart:** Notes are held only in the widget's memory and are never written to files. Restarting `plasmashell`, logging out, rebooting, or removing the widget clears all notes. Widget width and desktop-name visibility preferences are preserved.

## Installation (Kubuntu 24.04 / KDE Plasma 5)

```bash
sudo apt install git
git clone https://github.com/pulipulichen/kde-virtual-desktop-notes.git
cd kde-virtual-desktop-notes
bash scripts/install.sh
```

The widget includes both a vector SVG icon and a PNG thumbnail, referenced directly by `metadata.json` as `/images/icon.png` for the **Add Widgets** panel. The installation script also copies both icons into your user's `hicolor` icon theme for compatibility. **No `sudo` is needed** to run the installation script.

After installation, **right-click the KDE panel → Add Widgets → search for "Virtual Desktop Notes" → add it to the panel**.

To update an existing installation:

```bash
cd kde-virtual-desktop-notes
git pull
bash scripts/install.sh --reload
```

The `--reload` option restarts Plasma Shell so that the existing widget reloads the updated QML and icon. **This clears all unsaved notes**, since notes are intentionally stored only in memory. If you prefer not to restart Plasma Shell immediately, run `bash scripts/install.sh` without `--reload` and log out and back in later. If the old interface is still shown, remove the widget from the panel and add it again. Previously saved custom width settings remain unchanged; new instances default to 100 px.

## Uninstallation

First, enter panel edit mode and select **Remove Widget** for **Virtual Desktop Notes**. Then run:

```bash
cd kde-virtual-desktop-notes
git pull
bash scripts/uninstall.sh
```

This removes the Plasmoid package and custom SVG/PNG icons installed for the current user. It **does not remove other panel settings**, and **does not require `sudo`**. Running it again is safe, even if the package has already been removed. If KDE still displays a cached icon, log out and back in or run `bash scripts/uninstall.sh --reload` (which clears session notes).

## Usage

1. Switch to any KDE virtual desktop. Its name (for example, "Work" or "Research") is displayed automatically above the note area.
2. Click the note area to enter text. Press Enter for a second line, or leave it as a single line.
3. Click outside the editor or press Esc to finish editing.
4. Switch virtual desktops to see each desktop's own name and notes.
5. Right-click the widget and open **Configure → Appearance** to adjust its width, enable **Show only the virtual desktop name (hide notes)**, or disable the desktop-name heading in normal notes mode.

To rename a virtual desktop, use KDE **System Settings → Workspace Behavior → Virtual Desktops** rather than the widget itself. If you have not assigned custom names, KDE's default names (such as "Desktop 1") are shown.

## Build a .plasmoid Package

```bash
sudo apt install zip
bash scripts/build.sh
kpackagetool5 --type Plasma/Applet --install dist/kde-virtual-desktop-notes.plasmoid
```

The package is created at `dist/kde-virtual-desktop-notes.plasmoid`. If the widget is already installed, replace `--install` with `--upgrade` in the command above. Installing through `scripts/install.sh` is recommended because it also installs the custom icon into the user's icon theme.

## Project Structure

```text
package/
  metadata.json
  contents/ui/main.qml            # Desktop IDs, names, notes, and font scaling
  contents/images/icon.svg        # Custom vector icon
  contents/images/icon.png        # Bundled Add Widgets thumbnail
  contents/ui/configGeneral.qml   # Width, name-only mode, heading visibility
  contents/config/config.qml      # Configuration categories
  contents/config/main.xml        # Appearance preferences only
scripts/install.sh
scripts/uninstall.sh
scripts/build.sh
```

## Known Limitations

- This version targets KDE Plasma 5 / Qt 5. **Compatibility with Plasma 6 has not been verified.**
- Primarily designed for horizontal panels; vertical panels may require additional adjustments.
- A minimum font size is enforced, so extremely long text may be truncated.
- Interactive testing in a live Plasma desktop session has not yet been performed.

Repository: https://github.com/pulipulichen/kde-virtual-desktop-notes
