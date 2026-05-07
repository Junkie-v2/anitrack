# mpv playlist with resume support + AniList auto-tracking
# Usage: play <index> or play resume
function play
    set ani_sock /tmp/mpv-ani.sock

    if test -S $ani_sock
        rm -f $ani_sock
    end

    if test "$argv[1]" = resume
        set watch_dir ~/.local/state/mpv/watch_later
        set best_file ""
        for wfile in (/usr/bin/ls -t $watch_dir)
            set first_line (head -1 $watch_dir/$wfile)
            if string match -q "# redirect entry" $first_line
                continue
            end
            if string match -q "# /*" $first_line
                set filepath (string replace "# " "" $first_line)
                set fname (basename $filepath)
                if test -f ./$fname
                    set best_file $fname
                    break
                end
            end
        end
        if test -z "$best_file"
            echo "No resume data found for files in this directory"
            return 1
        end
        set files (find . -maxdepth 1 \( -name "*.mp4" -o -name "*.mkv" \) -printf "%f\n" | sort)
        set index 0
        for f in $files
            if test "$f" = "$best_file"
                break
            end
            set index (math $index + 1)
        end
        echo "Resuming: $best_file at index $index"
        nohup mpv --input-ipc-server=$ani_sock --playlist-start=$index . >/dev/null 2>&1 &
        disown
    else
        nohup mpv --input-ipc-server=$ani_sock --playlist-start=$argv[1] . >/dev/null 2>&1 &
        disown
    end

    if test -n "$ANITRACK_TOKEN"
        fish ~/.scripts/anitrack/anitrack-watch.fish $ani_sock &
        disown
    end
end
