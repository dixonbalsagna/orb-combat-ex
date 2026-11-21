#!/bin/bash
# gates.sh <base>: the plan-cost diff: paired timing, then the gates one job at a time beside QA's arm (2 jobs). Log: pf/g.log.
SP="C:/Users/<user>/AppData/Local/Temp/claude/C--Users-<user>-Documents-Claude-Proj-Breakers-Like/eb896954-cae4-4e38-a830-e1f1ec7e3853/scratchpad"
R="C:/Users/<user>/Documents/Claude Proj/Breakers-Like"
GD="C:/Users/<user>/AppData/Local/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"
export GODOT="$GD"
BASE="$1"; LOG="$SP/pf/g.log"; O="$SP/pf/o2"; mkdir -p "$O"
say() { echo "$(date +%H:%M:%S) $*" >> "$LOG"; }
# paired timing, same moment
( timeout 560 "$GD" --headless --path "$SP/pf/t" --script res://plan_cost.gd -- 6 --rep=3 --mode=0 2>&1 | grep -E '^COST ' > "$O/pair_old.txt" ) & a=$!
( timeout 560 "$GD" --headless --path "$SP/pf/m" --script res://plan_cost.gd -- 6 --rep=3 2>&1 | grep -E '^COST ' > "$O/pair_new.txt" ) & b=$!
wait $a $b; say "paired timing done"
T="$SP/pf/g"; mkdir -p "$T"; git -C "$R" archive "$BASE" | tar -x -C "$T"; git -C "$T" init -q
git -C "$T" -c core.autocrlf=false apply --unsafe-paths --directory= "$SP/pf/plan-cost.diff"; say "apply $?"
Q="$SP/pf/q"; mkdir -p "$Q"; git -C "$R" archive "$BASE" | tar -x -C "$Q"; git -C "$Q" init -q
git -C "$Q" -c core.autocrlf=false apply --unsafe-paths --directory= "$SP/pf/plan-cost.diff"; say "apply q $?"
python "$SP/pf/flipq.py" "$Q" >> "$LOG" 2>&1
( cd "$Q" && timeout 600 "$GD" --headless --path . --import > "$O/import_q.txt" 2>&1; QA_PLANET="gen=2;planets=3,7,11,13,17,19,23,25,37,31;touches=0,1,2,3;cols=2400" node qa/godot/run-arm.js --count=200 --arm=default --jobs=2 --out="$O/arm.json" --md="$O/arm.md" > "$O/arm.txt" 2>&1; echo "$(date +%H:%M:%S) qa arm done $?" >> "$LOG" ) & q=$!
g() { n="$1"; s="$2"; shift 2; timeout 1800 "$GD" --headless --path "$T" --script "res://$s" "$@" > "$O/$n.txt" 2>&1; say "$n exit $? | $(grep -v 'WARNING\|at: \|ObjectDB\|resources still\|^\s*$\|^gate:' "$O/$n.txt" | tail -1 | cut -c1-150)"; }
timeout 600 "$GD" --headless --path "$T" --import > "$O/import.txt" 2>&1; say "import $?"
cp "$T/sim/core/test/golden.json" "$O/golden.main.json"
g golden sim/core/tools/golden.gd
cmp -s "$T/sim/core/test/golden.json" "$O/golden.main.json" && say "GOLDEN byte-identical to main" || say "GOLDEN MOVED"
cp "$O/golden.main.json" "$T/sim/core/test/golden.json"
g twin sim/director/tools/dir_prof.gd -- --ticks=3600 --seed=1
say "twin: $(grep -o 'twin hash [a-z]*' "$O/twin.txt")"
g parity sim/core/tools/parity.gd
g propreach sim/director/tools/propreach_probe.gd
g launchbiome sim/director/tools/launchbiome_probe.gd
g sigafter sim/director/tools/sigafter_probe.gd
g sigvariants sim/director/tools/sigvariants_check.gd
g flighthooks sim/world/tools/flighthooks_probe.gd
g determinism render/tools/determinism.gd
g rb_planet2 net/tools/rollback_check.gd -- --setup=planet2 --seeds=1 --ticks=300 --profiles=lan,p120,far
( cd "$T" && node tools/validate.js ) > "$O/validate.txt" 2>&1; say "validate $?: $(tail -1 "$O/validate.txt" | cut -c1-90)"
( cd "$T" && node tools/validate.js --self-test ) > "$O/selftest.txt" 2>&1; say "selftest $?: $(tail -2 "$O/selftest.txt" | head -1 | cut -c1-90)"
( cd "$T" && node tools/lint-determinism.mjs ) > "$O/lint.txt" 2>&1; say "lint $?: $(tail -1 "$O/lint.txt" | cut -c1-90)"
# biome on, twice the same: the bound is in ticks, so the plan repeats
python "$SP/pf/flipb.py" "$T" >> "$LOG" 2>&1
g soak_biome sim/world/tools/gen2_soak.gd
g rb_planet2_biome net/tools/rollback_check.gd -- --setup=planet2 --seeds=1 --ticks=600 --profiles=lan,p120,far
wait $q
say "plan gates done"
