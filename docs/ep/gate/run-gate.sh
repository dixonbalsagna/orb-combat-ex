#!/bin/bash
S="${S:?set S to a scratch folder}"; T="${T:?set T to a gate tag}"; H="$(cd "$(dirname "$0")" && pwd)"; R="$(git -C "$H" rev-parse --show-toplevel)"
G="${GODOT:?set GODOT to the Godot console exe}"
export GODOT=$G
cd "$S/$T"; O="$S/$T-sim"; rm -rf "${O:?}"; mkdir -p "$O"; : > "$O/r.txt"
"$H/render-gates.sh" "$S/$T" "$S/$T-out"
echo "render $(grep -c 'exit 0' $S/$T-out/results.txt) passed; $(grep -v 'exit 0' $S/$T-out/results.txt | tr '\n' ' ')" >> "$O/r.txt"
"$G" --headless --path . --import > /dev/null 2>&1; for c in density_check fire_check floor_check burial_check props_wet_check floor_walk_probe arena_check b_check blastcheck blockcheck brunt_check climate_check collateral_check control_check deepencheck demostart_check depthreads_check directcheck epoch_check far_check farmap_check farsites_check fill_check gen2_state_check ground_check host_check interior_check isect_check lakes_check land_check lane_check minecheck noise_check planet_check planet_world_check probe probe_collide props_check repeat_check ringpick_check sea_rules_check sites_check skate_check stagecheck switchon_check wall_check campaign_check wrecks_check rivers_check surface_check ; do "$G" --headless --path . --script res://sim/world/tools/$c.gd > "$O/$c.log" 2>&1; echo "$c $? $(grep -iE "failed" $O/$c.log | tail -n1)" >> "$O/r.txt"; done
node tools/lint-determinism.mjs > "$O/lint.txt" 2>&1; echo "lint $?" >> "$O/r.txt"; node tools/validate.js --self-test > "$O/st.txt" 2>&1; echo "selftest $? $(tail -n2 $O/st.txt | head -n1)" >> "$O/r.txt"
node qa/run-all.js > "$O/qa.txt" 2>&1; echo "qa $?" >> "$O/r.txt"
( npm test --prefix sim > "$O/npm.log" 2>&1; echo "npm $? $(grep -c PASS $O/npm.log) PASS" >> "$O/r.txt"
  "$G" --headless --path . --script res://sim/core/tools/golden.gd > "$O/golden.log" 2>&1; echo "golden regen $? diff:$(git diff --stat sim/core/test/golden.json | tail -n1)" >> "$O/r.txt" ) &
( "$G" --headless --path . --script res://tools/flash/flash_worst.gd -- --out="$O/flash" > "$O/fw.log" 2>&1; echo "fw $?" >> "$O/r.txt"; node tools/flash/check-log.js "$O/flash" 2>&1 | tail -n1 >> "$O/r.txt" ) &
wait
"$G" --headless --path . --script res://render/anim/tools/anim_check.gd > "$O/anim.log" 2>&1; echo "anim_check $? $(grep -iE "failed|passed" $O/anim.log | tail -n1)" >> "$O/r.txt"
node tools/validate.js > "$O/val.txt" 2>&1; echo "validate $? $(tail -n1 $O/val.txt)" >> "$O/r.txt"
for t in split_sweep; do f=$(ls render/camera/tests/$t.gd render/camera/tools/$t.gd 2>/dev/null | head -1); "$G" --headless --path . --script res://$f > "$O/$t.log" 2>&1; echo "$t $? $(grep -iE "fail|pass" $O/$t.log | tail -n1)" >> "$O/r.txt"; done
"$G" --headless --path . --script res://sim/core/tools/campaign_episode.gd > "$O/camp.log" 2>&1; echo "campaign_episode $? $(tail -n1 $O/camp.log)" >> "$O/r.txt"
"$G" --headless --path . --script res://sim/core/tools/parity.gd > "$O/parity.log" 2>&1; echo "parity $? $(grep -iE "of [0-9]+|fail|pass" $O/parity.log | tail -n1)" >> "$O/r.txt"
"$G" --headless --path . --script res://sim/director/tools/sigvariants_check.gd > "$O/sv.log" 2>&1; echo "sigvariants_check $? $(grep -iE "fail|pass" $O/sv.log | tail -n1)" >> "$O/r.txt"
for c in "rollback_check -- --seeds=1 --ticks=1200 --delay=auto" "rollback_check -- --seeds=1 --ticks=240 --delay=auto --negative-control" "desync_check -- --seeds=1 --ticks=600 --profiles=lan,p120" "desync_check -- --seeds=1 --ticks=600 --profiles=lan,p120 --negative-control" "spectator_check -- --seeds=1 --ticks=600 --profiles=lan,p120,far" "spectator_check -- --seeds=1 --ticks=600 --profiles=lan,p120,far --negative-control" "delay_check" "delay_check -- --negative-control" "transport_check" "transport_check -- --negative-control"; do
  set -- $c; n=$1; shift; tag=$(echo "$c" | tr ' =,' '___' | cut -c1-60)
  "$G" --headless --path . --script res://net/tools/$n.gd "$@" > "$O/$tag.log" 2>&1; echo "$tag $? $(grep -E "PASS|FAIL" $O/$tag.log | tail -n1 | cut -c1-140)" >> "$O/r.txt"
done
for t in sim/input/test/*_test.gd; do n=$(basename $t .gd); "$G" --headless --path . --script res://$t > "$O/$n.log" 2>&1; echo "input $n $? $(tail -n1 $O/$n.log | cut -c1-100)" >> "$O/r.txt"; done
"$G" --headless --path . --script res://render/tools/determinism.gd -- --intro --seeds=2 --ticks=900 > "$O/detintro.log" 2>&1; echo "det-intro $? $(tail -n1 $O/detintro.log)" >> "$O/r.txt"
"$G" --headless --path . --script res://render/tools/sweep_check.gd > "$O/sweep.log" 2>&1; echo "sweep_check $? $(grep -iE 'pass|fail' $O/sweep.log | tail -n1)" >> "$O/r.txt"
f=$(ls render/camera/tests/seam_sweep.gd render/camera/tools/seam_sweep.gd render/tools/seam_sweep.gd 2>/dev/null | head -1); "$G" --headless --path . --script res://$f > "$O/seam.log" 2>&1; echo "seam_sweep $? $(grep -iE 'pass|fail' $O/seam.log | tail -n1)" >> "$O/r.txt"
"$G" --headless --path . --script res://ui/tools/hud_check.gd > "$O/hud.log" 2>&1; echo "hud_check $? $(grep -E 'checks' $O/hud.log | tail -n1)" >> "$O/r.txt"
"$G" --headless --path . --script res://render/tools/props_check.gd > "$O/props.log" 2>&1; echo "props_check $? $(grep -iE 'pass|fail' $O/props.log | tail -n1)" >> "$O/r.txt"
"$G" --headless --path . --script res://sim/world/tools/flighthooks_probe.gd > "$O/fh.log" 2>&1; echo "flighthooks $? $(grep -E 'probe passed|FAIL' $O/fh.log | tail -n1)" >> "$O/r.txt"
for c in "rollback_check -- --setup=depth --seeds=1 --ticks=300 --profiles=lan,p120,far" "rollback_check -- --setup=planet2 --seeds=1 --ticks=300 --profiles=lan,p120,far" "rollback_check -- --setup=calm --turn-at=300 --seeds=1 --ticks=600 --profiles=lan,p120,far" "rollback_check -- --ai --seeds=1 --ticks=600 --profiles=lan,p120,far" "rollback_check -- --ai=sim --seeds=1 --ticks=600 --profiles=lan,p120,far" "rollback_check -- --ai=sim --takeover=150 --seeds=1 --ticks=300 --profiles=lan,p120,far" "rollback_check -- --drop=150 --seeds=1 --ticks=300 --profiles=lan,p120,far" "desync_check -- --ai-timers --seeds=1 --ticks=600 --profiles=lan,p120" ; do
  set -- $c; n=$1; shift; tag=x_$(echo "$c" | tr ' =,' '___' | cut -c15-70)
  "$G" --headless --path . --script res://net/tools/$n.gd "$@" > "$O/$tag.log" 2>&1; echo "$tag $? $(grep -E "PASS|FAIL" $O/$tag.log | tail -n1 | cut -c1-120)" >> "$O/r.txt"
done
for t in sim/core/tools/two_states_check.gd sim/core/tools/replay_xproc_check.gd sim/director/tools/floorlift_check.gd sim/director/tools/launchbiome_probe.gd sim/director/tools/sigafter_probe.gd sim/world/tools/gen2_soak.gd; do "$G" --headless --path . --script res://$t > "$O/$(basename $t).log" 2>&1; echo "$(basename $t) $? $(grep -E 'PASS|FAIL|same|check\(s\)|passed' $O/$(basename $t).log | tail -n1 | cut -c1-120)" >> "$O/r.txt"; done
"$G" --headless --path . --script res://sim/world/tools/gen2_soak.gd -- --floor > "$O/soakfloor.log" 2>&1; echo "soak_floor $? $(grep 'GEN2 SOAK' $O/soakfloor.log | tail -n1 | cut -c1-100)" >> "$O/r.txt"
"$G" --headless --path . --script res://sim/world/tools/gen2_soak.gd -- --sea > "$O/soaksea.log" 2>&1; echo "soak_sea $? $(grep 'GEN2 SOAK' $O/soaksea.log | tail -n1 | cut -c1-100)" >> "$O/r.txt"
"$G" --headless --path . --script res://sim/world/tools/gen2_soak.gd -- --floor --sea > "$O/soakfs.log" 2>&1; echo "soak_floor_sea $? $(grep 'GEN2 SOAK' $O/soakfs.log | tail -n1 | cut -c1-100)" >> "$O/r.txt"
node tools/desktop-package-selftest.mjs 2>&1 | tail -n1 | cut -c1-100 >> "$O/r.txt"
node tools/world-checks.mjs --verify 2>&1 | tail -n1 | cut -c1-100 >> "$O/r.txt"
node tools/world-checks.mjs --run 2>&1 | tail -n1 | cut -c1-140 >> "$O/r.txt"
cmp sim/core/test/golden.json "$R/sim/core/test/golden.json" && echo "golden_cmp 0 same" >> "$O/r.txt"
echo ALLDONE >> "$O/r.txt"
