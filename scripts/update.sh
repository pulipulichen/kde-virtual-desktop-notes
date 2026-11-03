#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: bash scripts/update.sh [--no-reload]
  (default)    Pull the latest changes, reinstall, and restart Plasma Shell.
  --no-reload  Pull and reinstall without restarting Plasma Shell.
  -h, --help   Show this help.
EOF
}

RELOAD=true
case "${1:-}" in
  "") ;;
  --reload) RELOAD=true ;;
  --no-reload) RELOAD=false ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
if (( $# > 1 )); then usage >&2; exit 2; fi

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required (sudo apt install git)." >&2
  exit 1
fi
if [[ "$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null || true)" != "$ROOT" ]]; then
  echo "Error: $ROOT is not the root of a Git checkout." >&2
  echo "Clone the repository first, then run this script from inside it." >&2
  exit 1
fi

echo "==> Pulling the latest changes..."
git -C "$ROOT" pull --ff-only

echo "==> Reinstalling Virtual Desktop Notes..."
if [[ "$RELOAD" == true ]]; then
  echo "Plasma Shell will restart, clearing all session-only notes."
  bash "$ROOT/scripts/install.sh" --reload
else
  bash "$ROOT/scripts/install.sh"
fi

echo "==> Update complete."
