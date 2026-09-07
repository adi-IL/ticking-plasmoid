#!/usr/bin/env bash
# Development helper: install/upgrade the plasmoid locally and reload plasmashell.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ID="org.adi_il.ticking"
TARGET_DIR="${HOME}/.local/share/plasma/plasmoids/${ID}"

RESTART=false
VIEWER=false

for arg in "$@"; do
    case "$arg" in
        --restart|-r)
            RESTART=true
            ;;
        --viewer|-v)
            VIEWER=true
            ;;
        *)
            echo "Usage: $0 [--restart|-r] [--viewer|-v]"
            exit 1
            ;;
    esac
done

echo "==> Syncing files to ${TARGET_DIR}..."
mkdir -p "${TARGET_DIR}"
cp -f metadata.json "${TARGET_DIR}/"
cp -rf contents "${TARGET_DIR}/"
if [[ -d po ]]; then
    cp -rf po "${TARGET_DIR}/"
fi

echo "==> Clearing QML cache..."
rm -rf ~/.cache/plasmashell/qmlcache

echo "==> Updating KDE system configuration cache..."
kbuildsycoca6 --noincremental > /dev/null 2>&1 || true

if [ "$RESTART" = true ]; then
    echo "==> Restarting plasma-plasmashell systemd service..."
    systemctl --user restart plasma-plasmashell.service
    echo "==> Plasmashell restarted successfully."
fi

if [ "$VIEWER" = true ]; then
    echo "==> Launching plasmoidviewer..."
    plasmoidviewer -a "${TARGET_DIR}"
fi

echo "==> Done. Ticking Plasmoid installed locally."
