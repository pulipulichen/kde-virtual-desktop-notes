#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGE="$ROOT/package"
PLUGIN_ID="org.pulipulichen.virtualdesktopnotes"

if ! command -v kpackagetool5 >/dev/null 2>&1; then
  echo "Error: kpackagetool5 is missing. This package targets KDE Plasma 5." >&2
  exit 1
fi

if [[ -d "$HOME/.local/share/plasma/plasmoids/$PLUGIN_ID" ]]; then
  kpackagetool5 --type Plasma/Applet --upgrade "$PACKAGE"
else
  kpackagetool5 --type Plasma/Applet --install "$PACKAGE"
fi

echo "Installed $PLUGIN_ID"
echo "Right-click the panel > Add Widgets > Virtual Desktop Notes."
echo "Panel text is session-only; restarting plasmashell clears notes."
