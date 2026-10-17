#!/usr/bin/env bash
# The section 7 re-run, for a quiet window (about 10 minutes). One Godot process, then one browser at a time.
#   bash docs/research/world-catastrophe/tools/rerun.sh <clean HEAD export, already imported> <out dir>
# 1. The sim probe (magma, atmosphere, collapse) in the clean export: its timings are what section 1, 2 and 4 lack.
# 2. The web prototype's own frame and update times, scene by scene (bench=1: 2 s warm-up, 10 s measured), through
#    Tools' guarded launcher. Headless Chrome may cap frames at the display rate, so the frame time is an upper bound
#    of the cost; the in-page update time (cpuUpdateUs) is the GDScript work per frame on the web build.
set -u
HEAD_DIR="$1"; OUT="$2"
GODOT="/c/Users/itsha/AppData/Local/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"
mkdir -p "$OUT" "$HEAD_DIR/scratch_probe"
cp docs/research/world-catastrophe/sim_probe.gd "$HEAD_DIR/scratch_probe/"
echo "load before: $(powershell -NoProfile -Command "(Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples | Measure-Object CookedValue -Average | % { [math]::Round(\$_.Average,1) }")% cpu" | tee "$OUT/load.txt"
timeout 600 "$GODOT" --headless --path "$HEAD_DIR" -s res://scratch_probe/sim_probe.gd -- magma atmo collapse 2>&1 | grep '^PROBE' > "$OUT/probe.jsonl"
echo "probe: $(wc -l < "$OUT/probe.jsonl") parts"
for sc in magma cloud orbit collapse; do
  timeout 240 node tools/machine/capture.mjs eval --dir docs/research/world-catastrophe/proto/build/web2 \
    --path "/index.html?scene=$sc&bench=1&dur=10" --wait-js "window.__benchResult" --js "JSON.stringify(window.__benchResult)" \
    --width 1280 --height 720 --session research-catastrophe --purpose bench --time-limit 200 --quiet 2>&1 | tail -1 > "$OUT/bench-$sc.json"
  echo "bench $sc: $(head -c 300 "$OUT/bench-$sc.json")"
done
echo "load after: $(powershell -NoProfile -Command "(Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples | Measure-Object CookedValue -Average | % { [math]::Round(\$_.Average,1) }")% cpu" | tee -a "$OUT/load.txt"
