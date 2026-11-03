#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID="org.pulipulichen.virtualdesktopnotes"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
INSTALLED_DIR="$DATA_HOME/plasma/plasmoids/$PLUGIN_ID"
ICON_TARGET="$DATA_HOME/icons/hicolor/scalable/apps/$PLUGIN_ID.svg"
ICON_PNG_TARGET="$DATA_HOME/icons/hicolor/192x192/apps/$PLUGIN_ID.png"

usage() {
  echo "Usage: bash scripts/uninstall.sh [--reload]"
  echo "  --reload  Restart Plasma Shell after uninstall (clears all in-memory notes)."
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

if [[ -d "$INSTALLED_DIR" ]]; then
  kpackagetool5 --type Plasma/Applet --remove "$PLUGIN_ID"
  echo "Removed package: $PLUGIN_ID"
else
  echo "Package not installed for this user: $PLUGIN_ID"
fi

for target in "$ICON_TARGET" "$ICON_PNG_TARGET"; do
  if [[ -f "$target" ]]; then
    rm -- "$target"
    echo "Removed custom icon: $target"
  fi
done

echo "Panel instances/configuration are not changed automatically."
echo "Before uninstalling, right-click the panel and remove Virtual Desktop Notes from it."
if [[ "$RELOAD" == true ]]; then
  echo "Restarting Plasma Shell (all in-memory notes will be cleared)..."
  reload_plasma
else
  echo "If a stale panel instance remains, remove it from the panel and log out/back in."
fi
