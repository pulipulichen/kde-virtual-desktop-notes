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
- **Independent desktop colors:** Assign each virtual desktop separate colors for its name, note text, and optional background. Choose a preset or enter a custom `#RRGGBB` value. **System default** restores theme-based text colors or a transparent background.
- **Notes reset on restart:** Notes are held only in the widget's memory and are never written to files. Restarting `plasmashell`, logging out, rebooting, or removing the widget clears all notes. Widget width, desktop-name visibility, and per-desktop colors are preserved.

## Installation (Kubuntu 24.04 / KDE Plasma 5)

```bash
sudo apt install git
git clone https://github.com/pulipulichen/kde-virtual-desktop-notes.git
cd kde-virtual-desktop-notes
bash scripts/install.sh
```

The widget includes both a vector SVG icon and a PNG thumbnail, referenced directly by `metadata.json` as `/images/icon.png` for the **Add Widgets** panel. The installation script also copies both icons into your user's `hicolor` icon theme for compatibility. **No `sudo` is needed** to run the installation script.

After installation, **right-click the KDE panel → Add Widgets → search for "Virtual Desktop Notes" → add it to the panel**.

## Updating

From an existing Git checkout, run:

```bash
cd kde-virtual-desktop-notes
bash scripts/update.sh
```

If your local checkout predates `scripts/update.sh`, run `git pull` once to obtain the script. Subsequent updates need only `bash scripts/update.sh`.

This performs `git pull --ff-only`, reinstalls the widget with `scripts/install.sh`, and **restarts Plasma Shell by default** so existing panel instances load the latest QML and icon. **Restarting Plasma Shell clears all session-only notes.** The script requires no `sudo`.

To reinstall without immediately restarting Plasma Shell:

```bash
bash scripts/update.sh --no-reload
```

With `--no-reload`, the existing panel widget may continue to display the old interface until you log out and back in or restart Plasma Shell. If the old interface still remains after a restart, remove the widget from the panel and add it again. Previously saved custom width settings remain unchanged; new instances default to 100 px.

The update uses a fast-forward-only Git pull to avoid creating an accidental merge commit. If your working tree has conflicting local changes or the branch has diverged, Git stops instead of overwriting your work; resolve the conflict before retrying.

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
5. Right-click the widget and open **Configure → Appearance** to adjust its width, desktop-name options, and colors.
6. Under **Colors for virtual desktop**, select a desktop from the drop-down list. For **Desktop name text**, **Note text**, or **Background**, select a preset or type a six-digit hex color such as `#FF9800`. Click **Apply**.
7. Repeat for other desktops. **Reset colors for this desktop** restores system theme text colors and a transparent background. Colors persist after a reboot; notes do not.

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
  contents/ui/ColorPreference.qml # Color presets, hex entry, and swatch preview
  contents/images/icon.svg        # Custom vector icon
  contents/images/icon.png        # Bundled Add Widgets thumbnail
  contents/ui/configGeneral.qml   # Width, desktop options, per-desktop colors
  contents/config/config.qml      # Configuration categories
  contents/config/main.xml        # Persistent appearance preferences only
scripts/install.sh
scripts/uninstall.sh
scripts/update.sh                 # Pull, reinstall, optionally reload Plasma
scripts/build.sh
```

## Known Limitations

- This version targets KDE Plasma 5 / Qt 5. **Compatibility with Plasma 6 has not been verified.**
- Primarily designed for horizontal panels; vertical panels may require additional adjustments.
- A minimum font size is enforced, so extremely long text may be truncated.
- Interactive testing in a live Plasma desktop session has not yet been performed.

Repository: https://github.com/pulipulichen/kde-virtual-desktop-notes
