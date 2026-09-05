#!/usr/bin/env bash
# Build a KDE Store / GitHub-ready .plasmoid zip from the repo root.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ID="$(python3 -c 'import json; print(json.load(open("metadata.json"))["KPlugin"]["Id"])')"
VER="$(python3 -c 'import json; print(json.load(open("metadata.json"))["KPlugin"]["Version"])')"
OUT="${ID}-${VER}.plasmoid"

STAGE="$(mktemp -d)"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

mkdir -p "$STAGE/$ID"
# Runtime package only: metadata + contents. Skip docs/assets noise for the applet zip.
cp metadata.json "$STAGE/$ID/"
cp -a contents "$STAGE/$ID/"
if [[ -d po ]]; then
  cp -a po "$STAGE/$ID/"
fi

rm -f "$OUT"
(
  cd "$STAGE"
  zip -r -q "$ROOT/$OUT" "$ID"
)

echo "Wrote $OUT ($(du -h "$OUT" | cut -f1))"
