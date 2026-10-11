#!/bin/sh
# apply_lanes_window.sh <root>: L1 with D1 (docs/world/scratch-build/d1 and l1d1) and the three rulings on a tree at <root>
SP="C:/Users/itsha/AppData/Local/Temp/claude/C--Users-itsha-Documents-Claude-Proj-Breakers-Like/d5f87b8b-81e8-47eb-890c-b2d3fea2905c/scratchpad"
REPO="/c/Users/itsha/Documents/Claude Proj/Breakers-Like"
D="$REPO/docs/world/scratch-build"
cd "$1" || exit 1
patch -p1 < "$D/l1d1/l1d1.diff" > /dev/null 2>&1
cp "$D/d1/lanes.json" "$D/d1/settlements.json" data/biomes/
cp "$D/d1/lanes.gd" sim/world/lanes.gd
cp "$D/l1d1/lane_check.gd" sim/world/tools/
python "$D/d1/d1_window.py" . | tail -1
python "$SP/mk_rulings.py" . | tail -1
