#!/usr/bin/env bash
# Flash clips of the four catastrophe scenes, normal and "Reduce flashing", through Tools' guarded launcher only.
# One clip at a time, 640x360, one PNG per sim tick (60 a second), into $1/<scene>-<mode>/. Then Tools' analyser:
#   node tools/flash/analyse-frames.js $1 --json $1/flash.json
# Usage (from the repo root): bash docs/research/world-catastrophe/tools/clips.sh <out dir>
set -u
OUT="$1"
SITE=docs/research/world-catastrophe/proto/build/web
# scene first count: the window of the scene's timeline in ticks (t = n / 60)
for spec in "magma 300 600" "cloud 1 300" "orbit 1 660" "collapse 30 330"; do
  set -- $spec
  for mode in normal reduced; do
    R=0; [ "$mode" = reduced ] && R=1
    D="$OUT/$1-$mode"
    mkdir -p "$D"
    printf '{"scenario":"%s","reduced":%s,"fps":60}\n' "$1" "$([ $R = 1 ] && echo true || echo false)" > "$D/clip.json"
    node tools/machine/capture.mjs frames --dir "$SITE" --path "/index.html?scene=$1&frames=1&reduced=$R" --out "$D" \
      --first "$2" --count "$3" --step-js "window.__adv = {n}" --tick-js "window.__tick" --width 640 --height 360 \
      --session research-catastrophe --purpose flashclip --time-limit 1500 --quiet || echo "clip $1-$mode failed"
    echo "clip $1-$mode: $(ls "$D" | grep -c png) frames"
  done
done
