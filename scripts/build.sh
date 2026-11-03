#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/kde-virtual-desktop-notes.plasmoid"

command -v zip >/dev/null 2>&1 || {
  echo "Error: install zip first (sudo apt install zip)." >&2
  exit 1
}

mkdir -p "$ROOT/dist"
rm -f "$OUT"
(
  cd "$ROOT/package"
  zip -q -r "$OUT" metadata.json contents
)
echo "Created: $OUT"
