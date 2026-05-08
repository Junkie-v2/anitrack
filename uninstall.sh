#!/usr/bin/env bash
set -euo pipefail
echo "=== AniTrack Uninstaller ==="

FISH_CONFIG="${HOME}/.config/fish/config.fish"
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

# Remove Fish functions
rm -f "${FISH_FUNCTIONS_DIR}/play.fish"
rm -f "${FISH_FUNCTIONS_DIR}/download.fish"
rm -f "${FISH_FUNCTIONS_DIR}/godownload.fish"

# Remove scripts, config, and logs
rm -rf "${ANITRACK_SCRIPT_DIR}"
rm -rf "${ANITRACK_CONFIG_DIR}"
rm -rf "${ANITRACK_LOG_DIR}"

# Remove source snippet from fish config if present
if [ -f "${FISH_CONFIG}" ]; then
  if grep -q "# AniTrack auto-load" "${FISH_CONFIG}"; then
    sed -i '/# AniTrack auto-load/,/^end$/d' "${FISH_CONFIG}"
    echo "Removed AniTrack source snippet from ${FISH_CONFIG}"
  else
    echo "No AniTrack snippet found in ${FISH_CONFIG}, skipping."
  fi
fi

echo ""
echo "=== AniTrack uninstalled successfully ==="
