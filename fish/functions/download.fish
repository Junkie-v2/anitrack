# SeaDex best release finder | Usage: download "Anime Title"
function download
    set title $argv[1]

    # Step 1: Get AniList ID from AniList API
    set al_query '{"query":"query($search:String){Media(search:$search,type:ANIME){id title{romaji}}}","variables":{"search":"'$title'"}}'
    set al_response (curl -s -X POST -H "Content-Type: application/json" -d $al_query https://graphql.anilist.co)
    set al_id (echo $al_response | jq -r '.data.Media.id')
    set al_title (echo $al_response | jq -r '.data.Media.title.romaji')

    if test -z "$al_id" -o "$al_id" = null
        echo "Could not find AniList entry for '$title'"
        return 1
    end

    echo "Found: $al_title (AniList ID: $al_id)"

    # Step 2: Query SeaDex for entry
    set seadex_response (curl -s "https://releases.moe/api/collections/entries/records?filter=alID%3D$al_id")
    set total (echo $seadex_response | jq -r '.totalItems')

    if test "$total" = 0
        echo "No SeaDex entry found for '$al_title'"
        return 1
    end

    # Step 3: Get torrent IDs and fetch each one
    set trs (echo $seadex_response | jq -r '.items[0].trs[]')

    set results ""
    for tr in $trs
        set torrent (curl -s "https://releases.moe/api/collections/torrents/records/$tr")
        set is_best (echo $torrent | jq -r '.isBest')
        set group (echo $torrent | jq -r '.releaseGroup')
        set tracker (echo $torrent | jq -r '.tracker')
        set dual (echo $torrent | jq -r '.dualAudio')
        set info_hash (echo $torrent | jq -r '.infoHash')
        set best_label ""
        if test "$is_best" = true
            set best_label " [BEST]"
        end
        set results "$results$group$best_label | $tracker | dual: $dual | $info_hash\n"
    end

    # Step 4: fzf to pick, then launch qbittorrent with magnet
    set selected (printf $results | fzf --prompt="Select release: ")
    if test -z "$selected"
        return 0
    end

    set info_hash (echo $selected | awk -F' | ' '{print $NF}')
    set magnet "magnet:?xt=urn:btih:$info_hash"
    echo "Launching qbittorrent with magnet..."
    qbittorrent $magnet & disown
end
