# AniTrack

An all-in-one anime tool for Linux users running the Fish shell. AniTrack combines automatic AniList progress tracking with flexible anime downloading, episode renaming, and seamless mpv integration.

Built around three core ideas: watch your anime, let the tool handle the rest.

---

## What It Does

**Automatic AniList Tracking**
When you finish an episode in mpv, AniTrack detects it, identifies the show and episode number, and marks it as watched on your AniList account. No manual input required.

**SeaDex + Nyaa Downloading**
The `download` function queries [SeaDex](https://releases.moe) to find the best quality release for any anime title, pulls the magnet link from Nyaa, and opens it directly in qBittorrent. SeaDex is a community-maintained index that identifies the definitive best release for each show, so you always get the right encode without having to research it yourself.

**GoAnime Downloading**
The `godownload` function wraps the [goanime](https://github.com/alvarorichard/GoAnime) CLI for fast batch episode downloads. It trades some of the quality you would get from a curated Nyaa torrent for speed and convenience, which makes it a good option when you want a full season quickly without waiting on a torrent to seed.

**Episode Renaming**
A Python utility to batch rename downloaded episodes into a consistent format. This matters because the AniList tracker depends on being able to parse the show title and episode number from the filename, and raw downloads often come with inconsistent or messy naming.

---

## How It Works

1. You launch a video using the `play` function.
2. A background watcher script (`anitrack-watch`) connects to mpv's Unix socket and listens for events.
3. When an episode ends naturally (not skipped, not closed early), `anitrack-update` fires.
4. It parses the filename or parent directory to extract the show title and episode number.
5. It searches AniList for the matching entry, checks your current progress, and updates it if the episode is new.
6. A desktop notification confirms the update.

All of this runs silently in the background. The only thing you will ever see is the notification.

---

## Prerequisites

**Required for tracking:**

- [Fish shell](https://fishshell.com/) (version 3.0 or later)
- [mpv](https://mpv.io/) (the entire tracking system depends on it)
- Python 3
- curl
- `notify-send` from `libnotify` (optional, but recommended for desktop notifications)
- An [AniList](https://anilist.co/) account

**Required for `download.fish` (SeaDex + Nyaa):**

- [jq](https://stedolan.github.io/jq/)
- [fzf](https://github.com/junegunn/fzf)
- [qBittorrent](https://www.qbittorrent.org/) or any other torrent client that handles magnet links

**Required for `godownload.fish` (GoAnime):**

- [goanime](https://github.com/alvarorichard/GoAnime) CLI installed and accessible in your PATH

---

## Suggested Directory Structure

AniTrack extracts show titles from the parent directory name when possible, which is more reliable than parsing the filename itself. The recommended structure is:

```
~/Videos/Anime/<Show Name>/<Episodes>
```

Example:
```
~/Videos/Anime/Made in Abyss/Made in Abyss - E01.mkv
~/Videos/Anime/Jujutsu Kaisen/S01/Jujutsu Kaisen - S01E01.mkv
```

If your files are not named consistently, use the included `rename_episodes.py` script before watching.

---

## Installation

```bash
git clone https://github.com/Junkie-v2/anitrack.git
cd anitrack
chmod +x install.sh uninstall.sh
./install.sh
```

The installer will:

- Place the core tracking scripts into `~/.scripts/anitrack/`
- Add the `play` Fish function to `~/.config/fish/functions/`
- Prompt you interactively to optionally install `download.fish` and/or `godownload.fish`
- Create a config file at `~/.config/anitrack/config.fish` if one does not already exist
- Add a source line to `~/.config/fish/config.fish` if needed

You can install only the tracking functionality and skip the download functions entirely. The tool works independently of them.

---

## Configuration

After installation, open `~/.config/anitrack/config.fish` and fill in your values:

```fish
set -gx ANITRACK_TOKEN "your_token_here"
set -gx ANITRACK_CLIENT_ID "your_client_id"
set -gx ANITRACK_USER "your_username"
```

| Field | Required | Description |
|---|---|---|
| `ANITRACK_TOKEN` | Yes | Your AniList JWT access token (roughly 800-900 characters) |
| `ANITRACK_CLIENT_ID` | Yes | Default is `40738` for the AniTrack app |
| `ANITRACK_USER` | No | Your AniList username, used for display and logging only |

A template is provided at `config.fish.example` in the repository root.

### Getting Your AniList Token

1. Go to your [AniList Developer Settings](https://anilist.co/settings/developer) and create a new API client.
2. Set the redirect URI to `https://anilist.co/api/v2/oauth/pin`.
3. Visit the authorization URL to grant access and receive an authorization code.
4. Exchange the code for an access token following the [AniList OAuth guide](https://docs.anilist.co/guide/auth/authorization-code).
5. Copy the `access_token` value from the response into your config. This is your `ANITRACK_TOKEN`.

The token is a long JWT string. It is not your client secret. Do not share it or commit it to a public repository.

---

## Usage

### Watching and Tracking

Navigate to your anime directory and use the `play` function:

```fish
play 0        # start from the first file
play 5        # start from index 5
play resume   # resume the last watched file
```

When an episode ends, you will receive a desktop notification and your AniList progress will update automatically. You do not need to do anything.

To manually trigger an update for a specific file:

```fish
anitrack-update "/path/to/episode.mkv"
```

### Downloading via SeaDex + Nyaa

```fish
download "Made in Abyss"
```

This will:
1. Query SeaDex for the best available release of the show.
2. Present matching results in an fzf picker so you can select the specific release you want.
3. Fetch the magnet link from Nyaa and open it in qBittorrent.

SeaDex curates the definitive best release for each title based on encode quality, subtitles, and source. Using this function means you get the community's recommended version without having to look it up yourself.

### Downloading via GoAnime

```fish
godownload "Made in Abyss" 1-24
```

This fetches a batch of episodes using the goanime CLI. It is faster to get started than waiting for a torrent to seed, but the quality ceiling is lower than what you would get from a curated Nyaa release. Use this when you want an entire season available immediately.

### Renaming Episodes

If your downloaded files have inconsistent naming, run the rename script before watching:

```fish
cd ~/Videos/Anime/Made\ in\ Abyss

# Preview changes without applying them
python3 ~/.scripts/anitrack/rename_episodes.py "Made in Abyss" --dry-run

# Apply the rename
python3 ~/.scripts/anitrack/rename_episodes.py "Made in Abyss"
```

Options:

- `--padding N` sets the zero-padding width for episode numbers (default is 3, producing `E001`)
- `--interactive` prompts for confirmation before applying if any conflicts are detected

Consistent naming is important because the tracker relies on being able to parse the show title and episode number from the file. If the tracker fails to identify an episode, renaming is usually the fix.

---

## Logs

All tracking activity is written to:

```
~/.local/state/anitrack/anitrack.log
```

If an update fails or a show is not matched, the log will tell you why. Check it first before opening an issue.

---

## Uninstallation

```fish
./uninstall.sh
```

This removes all installed scripts, functions, config files, and logs. You may also want to manually remove the source line from `~/.config/fish/config.fish` if one was added during installation.

---

## License

MIT. See the [LICENSE](LICENSE) file.
