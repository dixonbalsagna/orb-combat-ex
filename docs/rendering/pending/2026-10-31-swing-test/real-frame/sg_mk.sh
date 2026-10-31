#!/bin/bash
# SCRATCH: the real-frame tree: HEAD, the pb hooks, the patch; bake two places; export. Args: bake | (none). Below normal, one Godot at a time.
LN="$(cd "$(dirname "$0")/.." && pwd)"
LW="$(cd "${LN:?}" && pwd -W)"
R="C:/Users/itsha/Documents/Claude Proj/Breakers-Like"
GD="C:/Users/itsha/AppData/Local/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"
HK="$R/docs/perf/tools/scratch-hooks"
T="${LN:?}/sgt"
powershell -NoProfile -Command "(Get-Process -Id $(cat /proc/$$/winpid)).PriorityClass = 'BelowNormal'" 2>/dev/null
keep=""
if [ -d "${T:?}/swing/city" ]; then
	rm -rf "${LN:?}/sg_keep"
	mkdir -p "${LN:?}/sg_keep"
	cp -r "${T:?}/swing/city" "${T:?}/swing/open" "${LN:?}/sg_keep/" 2>/dev/null
	keep=1
fi
rm -rf "${LN:?}/sgt"
mkdir "${T:?}" && git -C "$R" archive HEAD | tar -x -C "${T:?}" || exit 1
cp -r "${LN:?}/sw/.godot" "${T:?}/.godot" 2>/dev/null
echo "tree at $(git -C "$R" rev-parse --short=8 HEAD)"
node "$HK/hook-perf.mjs" "$LW/sgt" > /dev/null && node "$HK/hook-slice.mjs" "$LW/sgt" "$R/docs/world/scratch-build/planet-slice/planet2_lib.gd" > /dev/null && node "$HK/hook-pbiome.mjs" "$LW/sgt" > /dev/null || { echo "hooks failed"; exit 1; }
(cd "${T:?}" && python "$LW/sg/sg_patch.py") || { echo "patch failed"; exit 1; }
cp "${LN:?}/sg/swing_drive.gd" "${T:?}/render/core/swing_drive.gd"
cp "${LN:?}/sg/sg_bake.gd" "${T:?}/swing/sg_bake.gd"
if [ -n "$keep" ] && [ "$1" != "bake" ]; then cp -r "${LN:?}/sg_keep/city" "${LN:?}/sg_keep/open" "${T:?}/swing/"; fi
timeout 1500 "$GD" --headless --path "$LW/sgt" --import > "${LN:?}/sg.import.log" 2>&1
echo "import $? errors $(grep -a -c 'SCRIPT ERROR\|SHADER ERROR\|Parse Error' "${LN:?}/sg.import.log")"
grep -a 'SCRIPT ERROR\|SHADER ERROR\|Parse Error\|swing' "${LN:?}/sg.import.log" | head -14 | cut -c1-200
if [ "$1" = "bake" ]; then
	for x in "city city" "open forest"; do
		set -- $x
		timeout 500 "$GD" --headless --path "$LW/sgt" --script res://swing/sg_bake.gd -- "$1" "$2" > "${LN:?}/sg.bake.$1.log" 2>&1
		echo "bake $1 $?"; grep -a "^RES\|SCRIPT ERROR\|at: _run\|at: node\|at: tile" "${LN:?}/sg.bake.$1.log" | head -6 | cut -c1-280
	done
	timeout 600 "$GD" --headless --path "$LW/sgt" --import > "${LN:?}/sg.import.log" 2>&1
fi
rm -rf "${LN:?}/sg_site"
mkdir -p "${LN:?}/sg_site/play"
timeout 1500 "$GD" --headless --path "$LW/sgt" --export-release Web "$LW/sg_site/play/index.html" > "${LN:?}/sg.export.log" 2>&1
echo "export $? errors $(grep -a -c 'SCRIPT ERROR\|SHADER ERROR\|Parse Error' "${LN:?}/sg.export.log")"
grep -a 'SCRIPT ERROR\|SHADER ERROR\|Parse Error' -A3 "${LN:?}/sg.export.log" | head -14 | cut -c1-200
echo sgmkdone
