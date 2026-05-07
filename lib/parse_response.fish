# parse_response.fish
# Helper: returns a specific field from AniList search JSON
# Usage: parse_response <json_string> <field>
# field can be: id, progress, title, status
function parse_response
    set -l json $argv[1]
    set -l field $argv[2]

    switch $field
        case id
            echo $json | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    results = d['data']['Page']['media']
    if results:
        print(results[0]['id'])
except:
    pass" 2>/dev/null
        case progress
            echo $json | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    results = d['data']['Page']['media']
    if results:
        entry = results[0].get('mediaListEntry')
        print(entry['progress'] if entry and entry.get('progress') is not None else 0)
except:
    print(0)" 2>/dev/null
        case title
            echo $json | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    results = d['data']['Page']['media']
    if results:
        t = results[0]['title']
        print(t.get('english') or t.get('romaji') or '')
except:
    pass" 2>/dev/null
        case status
            echo $json | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    results = d['data']['Page']['media']
    if results:
        entry = results[0].get('mediaListEntry')
        print(entry['status'] if entry and entry.get('status') else 'CURRENT')
except:
    print('CURRENT')" 2>/dev/null
        case '*'
            echo "parse_response: unknown field '$field'" >&2
            return 1
    end
end
