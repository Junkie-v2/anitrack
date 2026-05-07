#!/usr/bin/env fish
# anitrack-watch -- background mpv IPC watcher
# Listens on /tmp/mpv-ani.sock for end-file events, then triggers anitrack-update.
# Usage: anitrack-watch [socket_path]

# Help
if test "$argv[1]" = -h -o "$argv[1]" = --help
    echo "Usage: anitrack-watch [socket_path]"
    echo "  Background process that watches mpv's Unix socket and calls"
    echo "  anitrack-update when an episode finishes."
    exit 0
end

set socket $argv[1]
if test -z "$socket"
    set socket /tmp/mpv-ani.sock
end

set LOG_FILE ~/.local/state/anitrack/anitrack.log
set SCRIPT_DIR ~/.scripts/anitrack

mkdir -p (dirname $LOG_FILE)

echo "[anitrack-watch] Started, waiting for socket: $socket" >>$LOG_FILE

# Wait up to 10s for mpv to create the socket
set waited 0
while not test -S $socket
    sleep 0.5
    set waited (math $waited + 1)
    if test $waited -ge 20
        echo "[anitrack-watch] Timed out waiting for socket $socket" >>$LOG_FILE
        exit 1
    end
end

echo "[anitrack-watch] Socket found, listening..." >>$LOG_FILE

python3 -c "
import socket, json, sys, subprocess, os, time

sock_path = '$socket'
logfile = '$LOG_FILE'
update_script = os.path.expanduser('$SCRIPT_DIR/anitrack-update.fish')
token = os.environ.get('ANITRACK_TOKEN', '')

def log(msg):
    with open(logfile, 'a') as f:
        f.write(msg + '\n')

def send(s, obj):
    s.sendall((json.dumps(obj) + '\n').encode())

try:
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(sock_path)
except Exception as e:
    log(f'[anitrack-watch] Failed to connect: {e}')
    sys.exit(1)

send(s, {'command': ['observe_property', 1, 'path'], 'request_id': 1})
send(s, {'command': ['observe_property', 2, 'percent-pos'], 'request_id': 2})

current_path = None
buf = b''

while True:
    try:
        chunk = s.recv(4096)
        if not chunk:
            log('[anitrack-watch] Socket closed (mpv quit)')
            break
        buf += chunk
        while b'\n' in buf:
            line, buf = buf.split(b'\n', 1)
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
            except:
                continue

            if msg.get('event') == 'property-change' and msg.get('name') == 'path':
                current_path = msg.get('data')
                log(f'[anitrack-watch] Now playing: {current_path}')

            if msg.get('event') == 'end-file':
                reason = msg.get('reason', '')
                log(f'[anitrack-watch] end-file event, reason={reason}, path={current_path}')
                if reason in ('eof', 'stop') and current_path:
                    log(f'[anitrack-watch] EOF confirmed, triggering update for: {current_path}')
                    env = {**os.environ, 'ANITRACK_TOKEN': token}
                    subprocess.Popen(
                        ['fish', update_script, current_path],
                        stdout=open(logfile, 'a'),
                        stderr=subprocess.STDOUT,
                        env=env
                    )
    except Exception as e:
        log(f'[anitrack-watch] Error: {e}')
        break

s.close()
log('[anitrack-watch] Exiting.')
" >>$LOG_FILE 2>&1
