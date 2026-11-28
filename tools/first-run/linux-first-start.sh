#!/bin/sh
# Orb Combat EX: the first start on Linux (gate G23). Made by tools/first-run/linux-first-start.mjs from the build's record; the lines marked @...@ are filled in then.
# It checks the game's file, runs the game's own test with no window, then opens the game to its warning screen and closes it by itself. No match is started. NOTHING IS SENT ANYWHERE.
# It deletes nothing. It records no name, computer name, system name or folder path.
set -u

ARCHIVE_NAME="@ARCHIVE@"
WANT_SUM="@SUM@"
WANT_HASH="@HASH@"
TICKS="@TICKS@"
WAIT="${ORB_FIRST_START_WAIT:-20}"

say() { printf '%s\n' "$*"; }
stop() { say ""; say "STOPPED: $*"; say "Nothing more was run. Tell Orb what this says."; exit 1; }

here=$(cd "$(dirname "$0")" && pwd) || exit 1
archive="${1:-$here/$ARCHIVE_NAME}"

say "Orb Combat EX: first start on Linux"
say ""
if [ "${ORB_FIRST_START_ANY_SYSTEM:-}" != "1" ]; then
  case "$(uname -s)/$(uname -m)" in Linux/x86_64 | Linux/amd64) ;; *) stop "this is for a 64-bit Intel or AMD Linux computer." ;; esac
fi
[ -f "$archive" ] || stop "I cannot find $ARCHIVE_NAME. Put it in the same folder as this script, or give its path: sh FIRST-START.sh <path to the file>"

say "1 of 3. Checking the game's file..."
if command -v sha256sum >/dev/null 2>&1; then sum=$(sha256sum "$archive" | cut -d' ' -f1)
elif command -v shasum >/dev/null 2>&1; then sum=$(shasum -a 256 "$archive" | cut -d' ' -f1)
else stop "this computer has no tool to check the file (sha256sum)."; fi
[ "$sum" = "$WANT_SUM" ] || stop "this is not the file Orb made (its checksum is different). Do not run it. Its checksum: $sum"
say "    It is the right file."

work=$(mktemp -d "$here/first-start-XXXXXX") || stop "I could not make a folder here."
tar -xzf "$archive" -C "$work" || stop "the file would not unpack."
bin=$(find "$work" -type f -name 'orb-combat-ex.x86_64' | head -n 1)
[ -n "$bin" ] || stop "the game is not in the file."
[ -x "$bin" ] || chmod u+x "$bin" || stop "I could not make the game runnable."

say "2 of 3. Running the game's own test. No window opens. This takes a few minutes..."
got=$("$bin" --headless --fixed-fps 60 -- --seed=4 --frames="$TICKS" --bench 2>/dev/null | grep '^gameplay hash at tick' | head -n 1)
hash=${got##*: }
if [ -z "$got" ]; then match="no result"; say "    The test gave no result."
elif [ "$hash" = "$WANT_HASH" ]; then match="same"; say "    The test gave the expected result."
else match="DIFFERENT"; say "    The test gave a different result. That is worth knowing; carry on."; fi

notice="not tried"
closed="not tried"
if [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  say "3 of 3. Skipped: there is no desktop to open a window on. Run this again from your desktop's terminal."
else
  say ""
  say "3 of 3. The game will now open and show a WARNING ABOUT FLASHING PICTURES."
  say "    Do not press anything: no key, no mouse button, no controller button."
  say "    It closes by itself after $WAIT seconds. If anything starts to move or flash, close the window."
  printf 'Press Enter to open it... '
  read -r _ || true
  "$bin" >/dev/null 2>&1 &
  game=$!
  sleep "$WAIT"
  if kill -0 "$game" 2>/dev/null; then
    kill "$game" 2>/dev/null
    sleep 2
    if kill -0 "$game" 2>/dev/null; then kill -9 "$game" 2>/dev/null; fi
    closed="yes, by this script"
  else
    closed="it closed before the time was up"
  fi
  wait "$game" 2>/dev/null || true
  printf 'Did a warning about flashing pictures appear? (y or n) '
  read -r answer || answer=""
  case "$answer" in y | Y | yes | Yes) notice="yes" ;; n | N | no | No) notice="no" ;; *) notice="not answered" ;; esac
fi

line="G23 first start | archive sha256 $sum | bench $hash ($match) | warning appeared: $notice | closed at the warning: $closed | a Linux x86_64 desktop"
printf '%s\n' "$line" > "$here/first-start-result.txt"
say ""
say "Done. Send Orb this one line (it is also in first-start-result.txt):"
say ""
say "$line"
say ""
say "This script sent nothing. The unpacked game is in the folder $(basename "$work"); you can delete that folder."
