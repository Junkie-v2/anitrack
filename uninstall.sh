#!/usr/bin/env bash
set -euo pipefail

echo "=== AniTrack Uninstaller ==="

FISH_FUNCTIONS_DIR="${HOME}/.config/fish/functions"
ANITRACK_SCRIPT_DIR="${HOME}/.scripts/anitrack"
ANITRACK_CONFIG_DIR="${HOME}/.config/anitrack"
ANITRACK_LOG_DIR="${HOME}/.local/state/anitrack"

read -p "Remove all AniTrack files? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Uninstall cancelled."
  exit 0
fi

rm -f "${FISH_FUNCTIONS_DIR}/play.fish"
rm -f "${FISH_FUNCTIONS_DIR}/download.fish"
rm -f "${FISH_FUNCTIONS_DIR}/godownload.fish"
rm -rf "${ANITRACK_SCRIPT_DIR}"
rm -rf "${ANITRACK_CONFIG_DIR}"
rm -rf "${ANITRACK_LOG_DIR}"

echo "Removed AniTrack files."
echo "You may also want to remove the source line from ~/.config/fish/config.fish"
