#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGE="$ROOT/package"
PLUGIN_ID="org.pulipulichen.virtualdesktopnotes"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
INSTALLED_DIR="$DATA_HOME/plasma/plasmoids/$PLUGIN_ID"
ICON_DIR="$DATA_HOME/icons/hicolor/scalable/apps"
ICON_NAME="$PLUGIN_ID"
ICON_SOURCE="$PACKAGE/contents/images/icon.svg"
ICON_TARGET="$ICON_DIR/$ICON_NAME.svg"

usage() {
  echo "Usage: bash scripts/install.sh [--reload]"
  echo "  --reload  Restart Plasma Shell to show the new UI/icon (clears in-memory notes)."
}

reload_plasma() {
  if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active --quiet plasma-plasmashell.service; then
    systemctl --user restart plasma-plasmashell.service
  elif command -v kquitapp5 >/dev/null 2>&1 && command -v kstart5 >/dev/null 2>&1; then
    kquitapp5 plasmashell || true
    nohup kstart5 plasmashell >/dev/null 2>&1 </dev/null &
  else
    echo "Could not restart Plasma Shell automatically; log out and back in." >&2
    return 1
  fi
}

RELOAD=false
case "${1:-}" in
  "") ;;
  --reload) RELOAD=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
if (( $# > 1 )); then usage >&2; exit 2; fi

if ! command -v kpackagetool5 >/dev/null 2>&1; then
  echo "Error: kpackagetool5 is missing. This package targets KDE Plasma 5." >&2
  exit 1
fi
if [[ ! -f "$ICON_SOURCE" ]]; then
  echo "Error: icon source missing: $ICON_SOURCE" >&2
  exit 1
fi

# Make the bespoke icon discoverable in Plasma's Add Widgets browser.
install -Dm644 "$ICON_SOURCE" "$ICON_TARGET"

if [[ -d "$INSTALLED_DIR" ]]; then
  kpackagetool5 --type Plasma/Applet --upgrade "$PACKAGE"
else
  kpackagetool5 --type Plasma/Applet --install "$PACKAGE"
fi

echo "Installed $PLUGIN_ID"
echo "Custom icon: $ICON_TARGET"
if [[ "$RELOAD" == true ]]; then
  echo "Restarting Plasma Shell (this clears all session-only notes)..."
  reload_plasma
else
  echo "Already have the widget on the panel? The running instance may still show the old UI."
  echo "Run: bash scripts/install.sh --reload"
  echo "Note: reloading Plasma clears all in-memory notes."
fi
echo "Add Widgets > Virtual Desktop Notes to add a new panel instance."
