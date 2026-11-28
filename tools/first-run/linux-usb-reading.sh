#!/bin/sh
# Orb Combat EX: the Linux reading from a USB stick (gate G21's Linux half, and G23; Legal RL-298 and RL-300). docs/tools/linux-usb-kit.md.
# Made into RUN-READING.sh by tools/first-run/linux-usb-kit.mjs; the lines marked @...@ are filled in then. Run it on a Linux LIVE system ("Try Ubuntu"), never an installed one by our asking.
#   1. the first start (FIRST-START.sh beside it): the file's checksum, the headless test, the warning screen, closed by itself;
#   2. the game plays its own matches on a HIDDEN screen, so nobody sees them, and writes every frame onto this drive.
# The frames are read later on Orb's main PC. NOTHING IS SENT ANYWHERE; frames never go into the repository. It installs one small program (Xvfb, the hidden screen) into the live system's memory, which is gone at power off. It deletes nothing.
set -u

ARCHIVE_NAME="@ARCHIVE@"
WANT_SUM="@SUM@"
WANT_HASH="@HASH@"
TICKS="@TICKS@"
FRAMES="${ORB_READING_FRAMES:-1500}"
SEEDS="${ORB_READING_SEEDS:-12345}"
SIZE="${ORB_READING_SIZE:-1024x768}"

say() { printf '%s\n' "$*"; }
stop() { say ""; say "STOPPED: $*"; say "Nothing more was run."; exit 1; }

here=$(cd "$(dirname "$0")" && pwd) || exit 1
archive="$here/$ARCHIVE_NAME"
out="$here/reading"

say "Orb Combat EX: the Linux reading"
say ""
[ -f "$archive" ] || stop "I cannot find $ARCHIVE_NAME beside this script."
[ -f "$here/FIRST-START.sh" ] || stop "FIRST-START.sh is not beside this script."
[ ! -e "$out" ] || stop "there is already a folder called reading here. Give it another name first (nothing is overwritten)."

say "PART 1: the first start. Follow what it says."
say ""
sh "$here/FIRST-START.sh" "$archive" || stop "the first start did not finish."
case "$(cat "$here/first-start-result.txt" 2>/dev/null)" in
  *"(same)"*) ;;
  *) stop "the game's own test did not give the build's result, so a reading of it would not count." ;;
esac

say ""
say "PART 2: recording, on a hidden screen. You will see nothing of the game. It can take a long time."
if ! command -v Xvfb >/dev/null 2>&1; then
  say "    Fetching the hidden screen (Xvfb) into the live system. This needs the internet."
  sudo apt-get update -qq || stop "no internet, or the list of programs could not be read."
  sudo apt-get install -y -qq xvfb >/dev/null || stop "the hidden screen could not be fetched."
fi

need=$(( FRAMES * 2 / 1000 + 2 ))
free=$(df -Pk "$here" | awk 'NR==2 { print int($4 / 1048576) }')
[ "${free:-0}" -ge "$need" ] || [ "${ORB_READING_ANY_SPACE:-}" = "1" ] || stop "this drive has ${free:-0} GB free; the recording needs about $need GB."

work=$(mktemp -d) || stop "no room for the game in memory."
tar -xzf "$archive" -C "$work" || stop "the file would not unpack."
bin=$(find "$work" -type f -name 'orb-combat-ex.x86_64' | head -n 1)
[ -n "$bin" ] || stop "the game is not in the file."
[ -x "$bin" ] || chmod u+x "$bin" || stop "I could not make the game runnable."

mkdir -p "$out" || stop "I cannot write on this drive."
# the hidden screen, on a number nothing else is using; the game is pointed at it and nowhere else
screen=97
Xvfb ":$screen" -screen 0 1920x1200x24 >"$out/hidden-screen.log" 2>&1 &
xvfb=$!
sleep "${ORB_READING_SCREEN_WAIT:-3}"
kill -0 "$xvfb" 2>/dev/null || stop "the hidden screen did not start (see reading/hidden-screen.log)."

{
  say "archive sha256 $WANT_SUM"
  say "headless result $WANT_HASH at tick $TICKS (the build's, and this machine's)"
  say "setup: a Linux live system; the matches drawn on a hidden screen"
} >"$out/record.txt" 2>/dev/null || true

for seed in $SEEDS; do
  dir="$out/seed-$seed"
  mkdir -p "$dir/frames" || stop "I cannot write on this drive."
  say "    match $seed: $FRAMES frames..."
  DISPLAY=":$screen" WAYLAND_DISPLAY= "$bin" --display-driver x11 --rendering-driver opengl3 --audio-driver Dummy --resolution "$SIZE" \
    --write-movie "$dir/frames/frame.png" --fixed-fps 60 -- --seed="$seed" --frames="$FRAMES" --bench >"$dir/game.log" 2>&1
  code=$?
  n=$(find "$dir/frames" -name 'frame*.png' | wc -l | tr -d ' ')
  printf '{ "scenario": "linux-program-ai-%s", "reduced": true, "fps": 60 }\n' "$seed" >"$dir/frames/clip.json"
  renderer=$(grep -m 1 -iE 'OpenGL API' "$dir/game.log" || true)
  say "match $seed: ended $code; frames $n of $FRAMES asked; ${renderer:-renderer not reported}" >>"$out/record.txt"
  if [ "$code" != "0" ] || [ "$n" -lt "$FRAMES" ]; then
    say "    match $seed did NOT write every frame ($n of $FRAMES, ended $code). A reading needs every one."
    bad=1
  fi
done
kill "$xvfb" 2>/dev/null
wait "$xvfb" 2>/dev/null || true

say ""
say "What is written in reading/record.txt:"
cat "$out/record.txt"
say ""
[ "${bad:-0}" = "0" ] || stop "at least one match is short. Keep the folder: it says what happened."
say "Done. Shut the computer down, take this drive to the main PC, and say it is ready."
say "The frames stay on your own computers. This script sent nothing."
