# KDE Virtual Desktop Notes — agent instructions

This repository targets **Kubuntu 24.04, KDE Plasma 5.27 and Qt 5**.

For QML, panels, popups, icons, localization, packaging, or scripts, read
[the KDE Plasmoid Development skill](.agents/skills/kde-plasmoid-development/SKILL.md).

- Edit and commit directly to `main`. Do not make a separate branch or PR.
- Do not force-push; re-read fresh state before writes.
- Use Plasma 5-compatible QML; do not copy Plasma 6 imports and root types.
- Follow KDE theme colors and maintain accessible foreground/background contrast.
- Keep UI prepared for English, zh_TW, zh_CN, and ja.
- Preserve session-only notes, KDE-native rename behavior, and the install,
  update, uninstall and build scripts.
- Run available tests and document anything requiring a real KDE session.
