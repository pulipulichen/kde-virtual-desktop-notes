# KDE Virtual Desktop Notes

![Virtual Desktop Notes icon](package/contents/images/icon.svg)

A panel notes widget for **KDE Plasma 5.27** (such as Kubuntu 24.04). It automatically displays the current virtual desktop's name and lets you keep separate one- or two-line notes for each virtual desktop.

## Features

- **Automatic desktop name display:** Retrieves the current virtual desktop name from KDE and updates it when you switch desktops or rename one. Enabled by default and can be hidden in the widget settings.
- **Name-only mode (default):** New widget instances show only the current desktop name; the note area is hidden. Uncheck **Show only the virtual desktop name (hide notes)** in Appearance to enable notes. Hiding notes never deletes the current session's note text. Existing instances retain their saved choice.
- **Native context-menu actions:** Right-click the widget and choose **Rename current virtual desktop** or **Open virtual desktop settings**. The latter opens the KDE System Settings module shown in the screenshot.
- **Direct, persistent renaming and reset:** Click the desktop title (or the entire widget in name-only mode) to open a **KDE-native editor anchored above the panel**. Name-only mode offers the desktop name, icon/emoji, and color controls; with notes enabled, the **same popup also contains the two-line note editor**. Press **Enter** or use **Rename/Done** to update the KDE/KWin desktop name and, when visible, save the note draft together. A failed rename does not save the note draft. An empty name restores **Desktop N** (N is the desktop number); **Reset** renames to that default immediately, without submitting a note draft. **Esc** or **Cancel** discards unsaved text.
- **Reset every desktop name from Appearance:** Open **Configure → Appearance** and select **Reset all virtual desktop names…**. Confirm to rename each existing KWin virtual desktop to **Desktop 1**, **Desktop 2**, and so on in the current order. This takes effect immediately (no **Apply** needed). It leaves temporary notes, saved colors, and icon preferences untouched. If any desktop cannot be renamed, the settings page displays the helper's error; successful earlier renames are not rolled back.
- **Optional per-desktop icon or emoji:** The **☺** button immediately to the **left** of the desktop-name field opens a modal chooser with **36 common work emojis** (projects, tasks, coding, meetings, chat, research, etc.) and **16 KDE theme icons**. The chooser has search, selection highlighting, **Apply/Cancel**, and **No icon — show desktop name**. When an icon/emoji is selected it replaces the desktop name in the panel's title area; clearing it restores the text. This never renames the actual KDE desktop. The choice is saved by desktop ID across restarts, independent of the note and the color palette.
- **Notes for each desktop:** Uses KDE virtual desktop IDs to keep notes separate, even if a desktop is renamed.
- **One- or two-line note editor:** First disable name-only mode in **Configure → Appearance**. Clicking either the desktop title or note area opens the shared popup containing **both** name and note fields; clicking the note area focuses the note field. Enter up to two note lines and select **Done** to save; **Cancel** / **Esc** discards both drafts. The desktop name does not count toward the note's two-line limit.
- **Adaptive panel font size:** Automatically scales displayed panel text based on height, width, and length. The separate popup has a comfortable editing font size and a real window for IME input.
- **Adjustable width:** 80–900 px (**100 px by default**).
- **Distinct colors out of the box:** Desktops **1–16** automatically receive different **Material 3-inspired container/on-container palettes** (pastel backgrounds with dark, legible foregrounds). Desktop **8 is green**, suitable for a LINE workspace. No setup is required. For more than sixteen desktops, the palette repeats.
- **Custom foreground and background:** Set colors independently for each desktop; choose from the sixteen Material palettes or enter custom `#RRGGBB` values. The foreground applies to both the desktop name and note text; optional advanced overrides allow different text colors. Existing saved name/note/background overrides remain supported. **Restore this desktop's automatic colors** returns to its assigned preset.
- **Color picker modal next to the name:** Click the desktop title (or right-click and choose **Rename current virtual desktop**). A small **Aa** button immediately to the right of the name field shows the *currently saved foreground/background colors*. Click it to open a separate **modal color dialog** with 16 pair previews and editable foreground/background `#RRGGBB` values. The selected pair is outlined. Changes are previewed but not saved until **Apply**; **Cancel** or **Esc** discard the draft. For legibility, custom colors must have at least a 4.5:1 WCAG contrast ratio. **Automatic colors** restores the desktop's position-based default and is independent of the name's **Reset** button. Saving colors never submits an uncommitted desktop-name edit. Palette selections persist across restarts.
- **Notes reset on restart:** Notes are held only in the widget's memory and are never written to files. Restarting `plasmashell`, logging out, rebooting, or removing the widget clears all notes. Widget width, desktop-name visibility, per-desktop icon/emoji choices, and per-desktop colors are preserved.

## Default desktop palette

The sixteen automatic pairs use Material 3's container/on-container approach. The values below are carefully chosen **Material 3-inspired** tonal combinations, not a claim that they are official fixed Material theme tokens. Each foreground/background pair has at least **9:1 WCAG contrast** for normal-sized text.

- **1 Blue:** foreground `#0B2545`, background `#D3E3FD`
- **2 Teal:** foreground `#003731`, background `#B2F5EA`
- **3 Purple:** foreground `#35165A`, background `#E9DDFF`
- **4 Rose:** foreground `#5B1131`, background `#FFD9E2`
- **5 Amber:** foreground `#4B2800`, background `#FFE0B2`
- **6 Indigo:** foreground `#1E2855`, background `#DEE1FF`
- **7 Cyan:** foreground `#003641`, background `#B9EAF5`
- **8 Green (LINE workspace):** foreground `#183B1E`, background `#CDECCB`
- **9 Slate:** foreground `#1C2935`, background `#DFE5EB`
- **10 Coral:** foreground `#5E2319`, background `#FFDDD5`
- **11 Sky:** foreground `#0A3552`, background `#D6EFFE`
- **12 Lime:** foreground `#263800`, background `#E3F6BD`
- **13 Mint:** foreground `#074233`, background `#D2F6E4`
- **14 Peach:** foreground `#532C13`, background `#FFE5CF`
- **15 Lavender:** foreground `#38265F`, background `#E8E1FA`
- **16 Sand:** foreground `#4E3719`, background `#F8E8CC`

These presets are assigned by **desktop position**, not by desktop name. Saved customizations are keyed to **KDE desktop IDs**, so renaming a desktop preserves its custom colors. Moving desktops may change their automatic color order. No per-desktop color records are written until you customize a desktop.

## Readable popup and accessibility

The rename/note editor popup uses **PlasmaComponents 3** widgets on Plasma 5.
Its heading uses the Plasma theme's `textColor` so dark themes no longer
render an almost invisible dark heading on a dark popup. Panel desktop titles
and empty-note hints no longer use lowered opacity; empty-note hints are shown
in italic instead. The sixteen Material 3-inspired palettes have at least 9:1
contrast. The modal prevents applying custom colors with less than **4.5:1**
text contrast; still inspect actual light and dark Breeze themes.

Automated source and palette tests:

```bash
python3 -m unittest discover -s tests -v
```

A live KDE Plasma 5.27 session is still required to verify the actual theme
and input method behavior.

## Development skill

Repository-specific coding guidance is in
[`.agents/skills/kde-plasmoid-development/SKILL.md`](.agents/skills/kde-plasmoid-development/SKILL.md).
It incorporates KDE official documentation and a community Plasma 6 skill,
while targeting this project's **Plasma 5.27** runtime. It covers palette
contrast, Qt Quick/Plasma controls, popups, keyboard/IME, four-language
internationalization (English, Traditional Chinese, Simplified Chinese,
Japanese), install/update/uninstall/build scripts, and direct-`main` edits.
[`AGENTS.md`](AGENTS.md) links the skill for coding assistants.

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

1. Switch to any KDE virtual desktop. Its name (for example, "Work" or "Research") is shown **without a note area by default**.
2. To use temporary notes, open **Configure → Appearance** and uncheck **Show only the virtual desktop name (hide notes)**. Click the title or note area to edit both the desktop name and up to two note lines in one popup; click **Done** to save, or **Esc** / **Cancel** to discard your text.
3. The editor is a KDE-native popup next to the widget, rather than an input field embedded in the narrow panel. Clicking outside closes the popup.
4. Switch virtual desktops to see each desktop's own name and notes.
5. To rename the current virtual desktop, click its title to open the anchored editor, type the new name, and press **Enter** or the primary button (**Rename** in name-only mode; **Done** when notes are visible). In **name-only mode**, click anywhere on the displayed name. Alternatively, right-click and choose **Rename current virtual desktop**. **Esc** or **Cancel** discards the draft. Clear the field and submit to restore **Desktop N** (e.g., **Desktop 3** for virtual desktop 3), or click **Reset** to rename it immediately. Existing widgets with saved Appearance settings keep those settings until you change them.
6. Right-click the widget and choose **Open virtual desktop settings** to open the KDE Virtual Desktops KCM, or **Configure → Appearance** to adjust widget width, desktop-name options, and colors.
7. To set a work icon, open the desktop-name editor and click **☺** at the **left** of the text field. Search or choose an emoji/KDE icon in the modal, then press **Apply**. Choose **No icon — show desktop name** and **Apply** to restore plain text. **Cancel** / **Esc** discard the selection. Icons/emoji replace only the title area of the panel widget; the KDE desktop name itself stays intact and continues to be editable.
8. Desktops 1–16 have distinct automatic color pairs; desktop 8 defaults to green for LINE. To change the current desktop quickly, click the **Aa** color button to the right of the rename field; choose one of 16 pairs or edit both HEX values in the modal, then **Apply**. **Cancel** / **Esc** discard the color draft. For advanced settings, use **Configure → Appearance → Colors for virtual desktop**. Saved overrides are preserved when upgrading, so click **Automatic colors** in the modal if desktop 8 has an older custom color.
9. Enable **Advanced: customize name and note text separately** if you need different text colors. **Restore this desktop's automatic colors** removes its overrides and brings back the default Material palette. Custom colors persist after a reboot; notes do not.

Virtual desktop names are managed by KWin and **persist after a reboot**; the widget's separate notes are temporary. The helper resolves X11 desktop numbers to KWin UUIDs before renaming; Wayland UUIDs are passed through. This project targets Plasma 5.27, and has not been live-tested on a KDE session in this environment. If D-Bus renaming is unavailable, use the **Open virtual desktop settings** action instead.

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
  contents/ui/ColorPairDialog.qml # Modal color preset/custom picker
  contents/ui/DesktopIconDialog.qml # Modal work emoji/KDE icon picker
  contents/ui/DesktopPalette.js    # Shared Material 3 color pairs and fallbacks
  contents/images/icon.svg        # Custom vector icon
  contents/images/icon.png        # Bundled Add Widgets thumbnail
  contents/ui/configGeneral.qml   # Width, desktop options, per-desktop colors
  contents/scripts/desktop-control.sh # Open KCM / rename via KWin D-Bus
  contents/config/config.qml      # Configuration categories
  contents/config/main.xml        # Persistent appearance preferences (including desktopIcons)
scripts/install.sh
scripts/uninstall.sh
scripts/update.sh                 # Pull, reinstall, optionally reload Plasma
scripts/build.sh
```

## Known Limitations

- This version targets KDE Plasma 5 / Qt 5. **Compatibility with Plasma 6 has not been verified.**
- Primarily designed for horizontal panels; vertical panels may require additional adjustments.
- A minimum font size is enforced, so extremely long text may be truncated.
- Interactive testing in a live Plasma desktop session has not yet been performed. Plasma's native popup supplies IMEs (including Fcitx5) a separate window coordinate system; verify candidate placement in your installation.

Repository: https://github.com/pulipulichen/kde-virtual-desktop-notes
