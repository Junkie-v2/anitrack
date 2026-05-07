#!/usr/bin/env bash
set -euo pipefail

echo "=== AniTrack Installer ==="

# Directories
FISH_CONFIG_DIR="${HOME}/.config/fish"
FISH_FUNCTIONS_DIR="${FISH_CONFIG_DIR}/functions"
ANITRACK_SCRIPT_DIR="${HOME}/.scripts/anitrack"
ANITRACK_CONFIG_DIR="${HOME}/.config/anitrack"
ANITRACK_LOG_DIR="${HOME}/.local/state/anitrack"

mkdir -p "${ANITRACK_SCRIPT_DIR}" "${ANITRACK_SCRIPT_DIR}/lib" \
  "${ANITRACK_CONFIG_DIR}" "${FISH_FUNCTIONS_DIR}" "${ANITRACK_LOG_DIR}"

# Core tracking scripts
echo "Installing core tracking scripts..."
cp anitrack-update.fish "${ANITRACK_SCRIPT_DIR}/"
cp anitrack-watch.fish "${ANITRACK_SCRIPT_DIR}/"
cp lib/parse_response.fish "${ANITRACK_SCRIPT_DIR}/lib/"
chmod +x "${ANITRACK_SCRIPT_DIR}/anitrack-update.fish" \
  "${ANITRACK_SCRIPT_DIR}/anitrack-watch.fish"

# Rename utility (always installed)
cp rename_episodes.py "${ANITRACK_SCRIPT_DIR}/"
chmod +x "${ANITRACK_SCRIPT_DIR}/rename_episodes.py"
echo "Installed rename_episodes.py to ${ANITRACK_SCRIPT_DIR}/"

# Fish function: play (always installed)
cp fish/functions/play.fish "${FISH_FUNCTIONS_DIR}/"
chmod +x "${FISH_FUNCTIONS_DIR}/play.fish"

# Optional download functions
install_download=false
install_godownload=false

if command -v whiptail &>/dev/null; then
  choices=$(whiptail --title "Optional Features" \
    --checklist "Select features to install (Space to toggle, Enter to confirm):" \
    15 60 2 \
    "download" "SeaDex/nyaa downloader (download.fish)" OFF \
    "godownload" "GoAnime downloader (godownload.fish)" OFF \
    3>&1 1>&2 2>&3)

  if [[ "$choices" == *"download"* ]]; then
    install_download=true
  fi
  if [[ "$choices" == *"godownload"* ]]; then
    install_godownload=true
  fi
else
  echo ""
  read -p "Install SeaDex/nyaa downloader (download.fish)? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_download=true
  fi
  read -p "Install GoAnime downloader (godownload.fish)? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_godownload=true
  fi
fi

if $install_download; then
  cp fish/functions/download.fish "${FISH_FUNCTIONS_DIR}/"
  chmod +x "${FISH_FUNCTIONS_DIR}/download.fish"
  echo "Installed download.fish"
fi
if $install_godownload; then
  cp fish/functions/godownload.fish "${FISH_FUNCTIONS_DIR}/"
  chmod +x "${FISH_FUNCTIONS_DIR}/godownload.fish"
  echo "Installed godownload.fish"
fi

# Config file
if [ ! -f "${ANITRACK_CONFIG_DIR}/config.fish" ]; then
  cp config.fish.example "${ANITRACK_CONFIG_DIR}/config.fish"
  echo "Created ${ANITRACK_CONFIG_DIR}/config.fish -- edit it with your AniList token."
else
  echo "${ANITRACK_CONFIG_DIR}/config.fish already exists, not overwriting."
fi

# Add source snippet to fish config if needed
FISH_CONFIG="${FISH_CONFIG_DIR}/config.fish"
if [ -f "${FISH_CONFIG}" ]; then
  if ! grep -q "ANITRACK_TOKEN" "${FISH_CONFIG}"; then
    cat >>"${FISH_CONFIG}" <<'EOF'

# AniTrack auto-load (set your token in ~/.config/anitrack/config.fish)
if test -f ~/.config/anitrack/config.fish
    source ~/.config/anitrack/config.fish
end
EOF
    echo "Added AniTrack source snippet to ${FISH_CONFIG}"
  else
    echo "AniTrack snippet already present in fish config."
  fi
else
  echo "No fish config found. Add manually:"
  echo "  source ~/.config/anitrack/config.fish"
fi

echo ""
echo "=== Installation complete ==="
echo "Next: edit ~/.config/anitrack/config.fish and set your ANITRACK_TOKEN"
echo "      (see https://docs.anilist.co/guide/auth/authorization-code)"
echo "Then restart your shell or run 'exec fish'."
