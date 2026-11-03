---
name: kde-plasmoid-development
description: Create, debug, test, and ship KDE Plasma widgets with Plasma 5.27/6 compatibility, accessible theme colors, translations, icon packaging, and reliable install/update/uninstall.
---

# KDE Plasmoid Development

Use for any KDE Plasma desktop/panel widget, QML, icon, packaging, settings,
color/theme, localization, or virtual desktop interaction work.

This project's supported runtime is **Kubuntu 24.04 / KDE Plasma 5.27 / Qt 5**.
Use the Plasma 6 widget-development reference for ideas, **not** as drop-in code.

## Check the runtime before editing

- Inspect `README.md`, `package/metadata.json`, `package/contents/ui/`,
  and `scripts/` to establish the actual target and current behavior.
- **Plasma 5**: `import QtQuick 2.15`;
  `import org.kde.plasma.core 2.0 as PlasmaCore`;
  `import org.kde.plasma.plasmoid 2.0`;
  `import org.kde.plasma.components 3.0 as PlasmaComponents3`;
  use an `Item` root with `Plasmoid.compactRepresentation` and
  `Plasmoid.fullRepresentation`.
- **Plasma 6**: use unversioned imports, `PlasmoidItem`,
  `org.kde.kirigami as Kirigami`, `Kirigami.Theme`, `Kirigami.Units`
  and `Kirigami.Icon`; use `kpackagetool6` and update metadata.
  **Do not mix Plasma 6 types into this Plasma 5 project** or assume
  the Plasma 5 executable data engine works unmodified on Plasma 6.
- Porting is a separate task requiring the official
  [KF6 porting guide](https://develop.kde.org/docs/plasma/widget/porting_kf6/)
  and actual testing on Plasma 6.

## Theme, colors and accessibility

- For **Plasma 5 panel popups**, use `PlasmaComponents3.Label`,
  `TextField`, `TextArea`, `Button`, and other themed controls instead
  of generic Qt Quick Controls with potentially incompatible palettes.
- Use `PlasmaCore.Theme.textColor`, `backgroundColor`, and suitable
  related roles on Plasma 5; use `Kirigami.Theme` roles on Plasma 6.
  Don't hardcode dark foregrounds for a native popup that can be dark.
- Maintain **WCAG AA contrast at least 4.5:1 for normal text** and
  at least 3:1 for sufficiently large text and meaningful UI boundaries.
  Check the **rendered** ratio after opacity blending. Never fade
  ordinary small text or empty-state hints below the contrast target;
  use italic style, weight, or a clear prefix instead.
- Keep sixteen Material 3-inspired per-desktop palette pairs
  in `package/contents/ui/DesktopPalette.js`; preserve distinct
  desktops 1–16 (desktop 8 defaults to green for the LINE workspace),
  custom colors keyed by desktop ID, and at least 4.5:1 effective
  foreground/background contrast. Default pairs should exceed 9:1.
- Place a live foreground/background preview button at the right edge of
  the desktop-name text field. Only open the 16-color picker on demand,
  as a modal dialog inside Plasma's anchored popup. Permit editing both
  `#RRGGBB` fields and show the contrast ratio. Apply should persist only
  valid accessible pairs; Cancel/Escape must discard draft choices.
  Keep the name Reset distinct from the automatic-color reset and avoid
  submitting the name when saving appearance.
- Inspect light/dark Breeze styles, panel text, full popup, text caret,
  button/field states, focus/hover, custom colors, and scaling.
  Don't report a manual theme check unless a real KDE session was tested.

## Panel behavior and implementation

- The compact panel defaults to **100 px** width. Preserve dynamic
  font fitting and one-/two-line note layout.
- Use an **anchored fullRepresentation popup** for input instead of
  placing a text field inside a narrow panel item; CJK IMEs need a real
  caret/window coordinate system.
- Keep temporary notes **in memory only**, cleared on Plasma restart.
  Only appearance preferences persist through KConfig.
- Read desktop IDs/names via `TaskManager.VirtualDesktopInfo` and
  route rename/settings actions through the existing trusted helper,
  preserving input validation and informative failures.
- Preserve icon SVG and PNG, `metadata.json`, KPackage layout, context
  actions, desktop switching, and X11/Wayland paths.

## Four-language UI requirements

- Support **English, Traditional Chinese (zh_TW), Simplified Chinese
  (zh_CN), and Japanese (ja)** in every new or updated UI.
- Mark user-facing QML strings for translation (`qsTr()` or the existing
  project-standard API), not raw English concatenations.
- Maintain translation catalogs and install/load paths if present.
  If no translation pipeline exists, identify this as unfinished
  work rather than claiming all four languages already display.
- Verify long-language strings, CJK glyph rendering, control spacing,
  button labels, tooltips, truncation, and input-method composition.

## Main-only workflow, scripts and validation

- **Edit and commit directly on `main`**; no feature branch or PR.
  Never force-push or overwrite concurrent changes; re-read the latest
  file SHA/branch head before any write.
- Maintain `scripts/install.sh`, `scripts/uninstall.sh`,
  `scripts/update.sh`, `scripts/build.sh`, package icon, and README.
- For updates: pull the current main, reinstall, and optionally reload
  Plasma Shell. Tell users that reloading clears session-only notes.
- Run `python3 -m unittest discover -s tests -v` and
  `bash scripts/build.sh` where dependencies are available; use
  `plasmoidviewer` or `plasmawindowed` and QML error logs in a real
  desktop session when possible. Distinguish static checks from
  runtime or visual verification.
- Make targeted fixes, add regressions for past bugs, keep changelogs
  or README accurate, and report unverified behavior explicitly.

## References

- [KDE Plasma Widget Tutorial](https://develop.kde.org/docs/plasma/widget/)
- [Plasma QML API](https://develop.kde.org/docs/plasma/widget/plasma-qml-api/)
- [Plasmoid properties](https://develop.kde.org/docs/plasma/widget/properties/)
- [Porting to KF6](https://develop.kde.org/docs/plasma/widget/porting_kf6/)
- [Community Plasma 6 widget skill reference](https://github.com/majiayu000/claude-skill-registry-data/blob/a21980a5b576646393ed574f158d7dd92fae4c3f/data/kde-plasma-widget-dev/SKILL.md)
