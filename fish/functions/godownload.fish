function godownload --description "Download anime episodes via GoAnime"
    if test (count $argv) -lt 2
        echo "Usage: godownload <anime_name> <episode_range>"
        echo "Example: godownload \"Harukana Receive\" 1-12"
        return 1
    end

    set anime_name $argv[1]
    set episode_range $argv[2]

    goanime -d -r -o ~/Videos/Anime/ "$anime_name" $episode_range
end
