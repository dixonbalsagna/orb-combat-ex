#!/bin/bash
# Rendering's gates, for run-gate.sh. Usage: render-gates.sh <tree> <out>. Needs GODOT in the environment.
: "${GODOT:?set GODOT to the Godot console exe}"
# every run through tools/godot-run.sh, so none touches a person's game data
G="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)/tools/godot-run.sh"
export ORB_GODOT_EXE="${ORB_GODOT_EXE:-$GODOT}" ORB_RUN_DATA="${ORB_RUN_DATA:-$2-userdata}"
cd "$1" || exit 1
O="$2"; mkdir -p "$O"
"$G" --headless --path . --import > "$O/import.log" 2>&1
run(){ n=$1; shift; "$G" --headless --path . --script res://render/tools/$n.gd "$@" > "$O/$n$TAG.log" 2>&1; echo "$n$TAG exit $?" >> "$O/results.txt"; }
: > "$O/results.txt"
( run seam_sweep -- --size=1280x720; run ground_check; run flight_check; run flash_check; run pane_check; run lane_check; run drawn_check -- --tiles; run ground_link_check ) &
( run feet_check; TAG=_small run feet_check -- --size=small --split; TAG=_big run feet_check -- --size=big --split ) &
( run determinism; TAG=_intro run determinism -- --intro --seeds=2 --ticks=900; run cue_check -- --profile=spaced; run patch_check; run shape_check ) &
( run sky_check; run flash_reg_check; run depth_check; run open_check; run after_check; run hud_words_check; run stage_check ) &
wait
(cd "$1" && node tools/validate.js > "$O/validate.log" 2>&1; echo "validate exit $?" >> "$O/results.txt")
echo DONE >> "$O/results.txt"
