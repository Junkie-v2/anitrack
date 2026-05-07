# AniTrack

Automatically mark anime episodes as watched on [AniList](https://anilist.co/) when you finish watching them with **mpv**. Built for the **Fish shell** -- simple, invisible, and reliable.

The repository also includes a **rename utility** for episode files and offers optional **downloading functions** for SeaDex/nyaa and GoAnime.

---

## How it works

1. You start a video file with mpv using the provided `play` function.
2. A background script (`anitrack-watch`) listens to mpv's Unix socket.
3. When the episode ends naturally, `anitrack-update` parses the filename, finds the show and episode number, and updates your AniList progress.

All of this happens without any manual input.

---

## Prerequisites

- **fish** shell (version 3.0 or later)
- **mpv** (required -- the whole system depends on it)
- **python3** (for API calls and the rename script)
- **curl**
- **notify-send** (from `libnotify`) -- optional, for desktop notifications
- An [AniList](https://anilist.co/) account

For the optional download features:

- `download.fish` requires **jq**, **fzf**, and **qbittorrent** (or another magnet handler)
- `godownload.fish` requires the [goanime](https://github.com/alex2006hw/goanime) CLI

---

## Suggested video directory

For best results, store your anime in this structure:
~/Videos/Anime/<Show Name>/<Season>/<Episode File>

Example: ~/Videos/Anime/Jujutsu Kaisen/S01/Jujutsu Kaisen - E01.mkv

The included `rename_episodes.py` script helps you achieve this naming convention.

---

## Installation

```bash
git clone https://github.com/Junkie-v2/anitrack.git
cd anitrack
chmod +x install.sh uninstall.sh
./install.sh

The installer will:

    Place the tracking scripts and rename utility into ~/.scripts/anitrack/

    Add the play fish function to ~/.config/fish/functions/

    Optionally install download.fish and/or godownload.fish (interactive checkboxes)

    Create a config file at ~/.config/anitrack/config.fish (if not present)

    Add a source line to ~/.config/fish/config.fish if needed

Configuration

After installation, edit ~/.config/anitrack/config.fish:

set -gx ANITRACK_TOKEN "your_token_here"
set -gx ANITRACK_CLIENT_ID "your_client_id"
set -gx ANITRACK_USER "your_username"

How to obtain a token

Follow the official AniList guide:
https://docs.anilist.co/guide/auth/authorization-code

    Create an application in your AniList Developer Settings.

    Redirect to authorize the app.

    Exchange the code for a long JWT access_token.

The ANITRACK_TOKEN is the JWT (access_token) -- not your client secret. It is a long string (roughly 800-900 characters).
Fields
Field	Required	Description
ANITRACK_TOKEN	Yes	The long JWT access token
ANITRACK_CLIENT_ID	Yes	Default 40738 for the AniTrack app
ANITRACK_USER	Optional	Your AniList username (display/logging only)

Never commit your token or real credentials to a public repository.
Usage
Tracking while watching

Navigate to a directory containing your video files and run:
fish

play 0        # start from first video
play 5        # start from video index 5
play resume   # resume last watched file

When an episode ends naturally, you will see a desktop notification and your AniList list will update.

To manually update progress for a specific file:
fish

anitrack-update "/path/to/file.mkv"

Renaming episodes

After installing, rename_episodes.py lives in ~/.scripts/anitrack/. Use it like this:
bash

cd <your_anime_directory>
python3 ~/.scripts/anitrack/rename_episodes.py "Jujutsu Kaisen" --dry-run
# review the preview, then run without --dry-run
python3 ~/.scripts/anitrack/rename_episodes.py "Jujutsu Kaisen"

Options:

    --padding N (default 3) -- zero-pad episode numbers, e.g. E001

    --interactive -- ask before continuing if conflicts are found

Downloading anime (optional)

If you opted to install them:
fish

download "Jujutsu Kaisen"         # fzf select from SeaDex + opens magnet
godownload "Jujutsu Kaisen" 1-24  # fetches episodes via goanime

Logs

All tracking activity is logged to ~/.local/state/anitrack/anitrack.log.
Uninstallation
bash

./uninstall.sh

It removes all installed scripts, functions, config, and logs. You may also want to manually delete the source line from ~/.config/fish/config.fish.


## License

MIT -- see [LICENSE](LICENSE) file.
```
