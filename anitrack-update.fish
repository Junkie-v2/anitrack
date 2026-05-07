#!/usr/bin/env fish
# anitrack-update -- called by anitrack-watch when an episode ends
# Usage: anitrack-update <filepath>

# Help
if test "$argv[1]" = -h -o "$argv[1]" = --help
    echo "Usage: anitrack-update <filepath>"
    echo "  Parses the filename, matches it against your AniList list,"
    echo "  and updates your progress to the detected episode number."
    exit 0
end

set filepath $argv[1]

if test -z "$filepath"
    echo "anitrack-update: no filepath given" >&2
    exit 1
end

# Configurable paths
set CONFIG_DIR ~/.config/anitrack
set LOG_FILE ~/.local/state/anitrack/anitrack.log
set LIB_DIR ~/.scripts/anitrack/lib

# Load token
if test -f $CONFIG_DIR/config.fish
    source $CONFIG_DIR/config.fish
end

if test -z "$ANITRACK_TOKEN"
    echo "anitrack-update: no token set. Set ANITRACK_TOKEN in $CONFIG_DIR/config.fish" >&2
    exit 1
end

set filename (basename $filepath)
mkdir -p (dirname $LOG_FILE)

# ── Episode number extraction ────────────────────────────────────────
set ep_num ""

# S01E12 or S1E12
if string match -qr '(?i)[Ss]\d+[Ee](\d+)' $filename
    set ep_num (string match -r '(?i)[Ss]\d+[Ee](\d+)' $filename)[2]
    set ep_num (echo $ep_num | string replace -r '.*[Ee](\d+).*' '$1')
end

# Fallback: digits after E/e
if test -z "$ep_num"
    set ep_num (echo $filename | grep -oP '(?<=[Ee])\d{2,3}' | head -1)
end

# Fallback: number surrounded by separators
if test -z "$ep_num"
    set ep_num (echo $filename | grep -oP '(?<=[\s\-\[_])\d{1,3}(?=[\s\-\]_\.])' | grep -v '^0$' | head -1)
end

# Last resort: any 1-3 digit number
if test -z "$ep_num"
    set ep_num (echo $filename | grep -oP '\b\d{1,3}\b' | grep -v '^0$' | head -1)
end

if test -z "$ep_num"
    echo "[anitrack] Could not extract episode number from: $filename" | tee -a $LOG_FILE
    exit 1
end

set ep_num (math $ep_num + 0)

# ── Show title extraction ────────────────────────────────────────────
set dir_name (basename (dirname $filepath))

if string match -qr '^(Anime|Videos|Downloads|anime|\.|Season\d*|Season \d*|S\d+)$' $dir_name
    set show_title $filename
else
    set show_title $dir_name
end

# Clean metadata
set show_title (echo $show_title | \
    sed 's/\[.*\]//g' | \
    sed 's/(.*)//' | \
    sed 's/\b[12][0-9]\{3\}\b//' | \
    sed 's/\b[0-9]\{3,4\}p\b//I' | \
    sed 's/\bBluRay\b//I' | \
    sed 's/\bWEBRip\b//I' | \
    sed 's/\bx264\b//I' | \
    sed 's/\bx265\b//I' | \
    sed 's/\bHEVC\b//I' | \
    sed 's/[._]/ /g' | \
    sed 's/  \+/ /g' | \
    string trim)

set show_title (echo $show_title | sed 's/ [Ss][0-9]\+[Ee][0-9]\+.*//' | sed 's/ [Ee][Pp]\?[0-9]\+.*//' | sed 's/ -\s*$//' | string trim)

echo "[anitrack] File: $filename" | tee -a $LOG_FILE
echo "[anitrack] Detected show: '$show_title' | Episode: $ep_num" | tee -a $LOG_FILE

# ── AniList search ───────────────────────────────────────────────────
set search_resp (python3 -c "
import urllib.request, json, sys, os
token = os.environ.get('ANITRACK_TOKEN', '')
title = '$show_title'
query = '''query(\$s:String){Page(perPage:5){media(search:\$s,type:ANIME,sort:SEARCH_MATCH){id title{romaji english}mediaListEntry{id progress status}}}}'''
payload = json.dumps({'query': query, 'variables': {'s': title}}).encode()
req = urllib.request.Request('https://graphql.anilist.co', data=payload, headers={
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json',
    'User-Agent': 'AniTrack/1.0'
})
res = urllib.request.urlopen(req)
print(res.read().decode())
" 2>/dev/null)

# Use helper to extract fields
source ~/.scripts/anitrack/lib/parse_response.fish

set media_id (parse_response "$search_resp" id)
set current_progress (parse_response "$search_resp" progress)
set found_title (parse_response "$search_resp" title)
set current_status (parse_response "$search_resp" status)

if test -z "$media_id"
    echo "[anitrack] No AniList match found for '$show_title'" | tee -a $LOG_FILE
    notify-send AniTrack "No AniList match for: $show_title" --icon=dialog-warning 2>/dev/null
    exit 1
end

echo "[anitrack] Matched: '$found_title' (ID: $media_id) | Current progress: $current_progress" | tee -a $LOG_FILE

if test $ep_num -le $current_progress
    echo "[anitrack] Episode $ep_num already logged (current: $current_progress), skipping." | tee -a $LOG_FILE
    exit 0
end

# ── Update AniList ───────────────────────────────────────────────────
set new_status $current_status
if test -z "$new_status" -o "$new_status" = PLANNING
    set new_status CURRENT
end

set mutation (printf '{"query":"mutation($mid:Int,$prog:Int,$stat:MediaListStatus){SaveMediaListEntry(mediaId:$mid,progress:$prog,status:$stat){id progress status}}","variables":{"mid":%s,"prog":%s,"stat":"%s"}}' \
    $media_id $ep_num $new_status)

set update_resp (curl -s -X POST https://graphql.anilist.co \
    -H "Authorization: Bearer $ANITRACK_TOKEN" \
    -H "Content-Type: application/json" \
    -d $mutation)

set saved_progress (echo $update_resp | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d['data']['SaveMediaListEntry']['progress'])
except:
    pass
" 2>/dev/null)

if test -n "$saved_progress"
    echo "[anitrack] Updated '$found_title' to episode $saved_progress" | tee -a $LOG_FILE
    notify-send "AniTrack OK" "$found_title -- Episode $saved_progress logged" --icon=dialog-information 2>/dev/null
else
    echo "[anitrack] Update failed. Response: $update_resp" | tee -a $LOG_FILE
    notify-send AniTrack "Failed to update AniList" --icon=dialog-error 2>/dev/null
end
