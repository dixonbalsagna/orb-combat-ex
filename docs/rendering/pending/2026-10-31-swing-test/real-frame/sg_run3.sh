#!/bin/bash
# SCRATCH: the real frame's readings with today's ground truly gone (the split's culling had put it back at the merge). One browser at a time, below normal.
LN="$(cd "$(dirname "$0")/.." && pwd)"
LW="$(cd "${LN:?}" && pwd -W)"
R="C:/Users/itsha/Documents/Claude Proj/Breakers-Like"
powershell -NoProfile -Command "(Get-Process -Id $(cat /proc/$$/winpid)).PriorityClass = 'BelowNormal'" 2>/dev/null
S="${LN:?}/sg/sg_shot.sh"
C="pgen=2&pplanet=7&pbiome=city&swset=city"
O="pgen=2&pplanet=7&pbiome=forest&swset=open"
T="pgen=2&pplanet=7&pbiome=city"
rm -rf "${LN:?}/sgst" "${LN:?}/sgb2" "${LN:?}/sgf2"
mkdir -p "${LN:?}/sgst" "${LN:?}/sgb2" "${LN:?}/sgf2"
bash "$S" pb today 1 241 60 "$T"
bash "$S" pb city60 1 481 40 "$C&sw=1&swrate=60"
bash "$S" pb city95 1 241 60 "$C&sw=1&swrate=60&swshare=95"
bash "$S" pb open60 1 481 40 "$O&sw=1&swrate=60"
cd "$R" || exit 1
fb() {
	local lb="$1" args="$2"; shift 2
	for a in 1 2 3; do
		MERIDIAN_SESSION=rendering timeout 900 env PATH="/c/Windows/System32:$PATH" node docs/perf/tools/frame-bench.mjs --site "$LW/sg_site" --scene pb --label "$lb" --session rendering --ticks 600 --warm 120 --out "$LW/sgb2/$lb.json" --page-args "$args" "$@" 2>&1 | tail -1 | cut -c1-200 > "$LW/sgb2/$lb.txt"
		cat "$LW/sgb2/$lb.txt"
		grep -q INVALID "$LW/sgb2/$lb.txt" || break
	done
}
fb today-igpu "$T" --igpu
fb tiles-igpu "$C&sw=1&swrate=60" --igpu
fb simple-igpu "$C&sw=1&swrate=60&swsimple=1" --igpu
fb notiles-igpu "$C&sw=1&swrate=60&swoff=tiles" --igpu
fb tiles98-igpu "$C&sw=1&swrate=98" --igpu
fb open-igpu "$O&sw=1&swrate=60" --igpu
fb today2-igpu "$T" --igpu
fb tiles2-igpu "$C&sw=1&swrate=60" --igpu
fb simple2-igpu "$C&sw=1&swrate=60&swsimple=1" --igpu
fb today-x4 "$T" --throttle 4
fb tiles-x4 "$C&sw=1&swrate=60" --throttle 4
fb today-x1 "$T"
fb tiles-x1 "$C&sw=1&swrate=60"
echo benchdone
cap() {   # label, scenario, page words, w, h, flag, ticks, keep
	local lb="$1" sc="$2" pw="$3" w="$4" h="$5" fl="$6" tk="${7:-600}" kp="$8"
	local nm="$lb-${w}x$h${fl:+-reduced}"
	MERIDIAN_SESSION=rendering timeout 1800 env MSYS_NO_PATHCONV=1 PATH="/c/Windows/System32:$PATH" node tools/flash/capture-web.mjs --dir "$LW/sg_site/play" --path "/index.html?flashcap=1&$pw" --scenario "$sc" --ticks "$tk" --width "$w" --height "$h" $fl --out "$LW/sgf2/$nm" --session rendering 2>&1 | tail -2 | head -1 | cut -c1-110 > /dev/null
	env PATH="/c/Windows/System32:$PATH" node tools/flash/analyse-frames.js "$LW/sgf2/$nm" --scale 1 --allow-short 2>&1 | grep -a " $tk " | cut -c1-200
	if [ -n "$kp" ]; then
		node "$LW/detmap.js" "$R" "$LW/sgf2/$nm" 1 "$tk" > "$LW/sgf2/$nm.det" 2>&1
	else
		rm -rf "${LN:?}/sgf2/$nm"
	fi
}
for sz in "960 540" "1024 768"; do
	set -- $sz
	cap today pb "$T" "$1" "$2" ""
	cap today pb "$T" "$1" "$2" "--reduced"
	cap c60 pb "$C&sw=1&swrate=60" "$1" "$2" "" 600 keep
	cap c98 pb "$C&sw=1&swrate=98" "$1" "$2" ""
	cap c65 pb "$C&sw=1&swrate=65" "$1" "$2" "--reduced"
	cap c60 pb "$C&sw=1&swrate=60" "$1" "$2" "--reduced"
	cap o60 pb "$O&sw=1&swrate=60" "$1" "$2" ""
	for q in 240 120; do
		for fl in "" "--reduced"; do
			cap "q${q}c" pb "$C&sw=1&swq=1&swrate=$q" "$1" "$2" "$fl"
			cap "q${q}o" pb "$O&sw=1&swq=1&swrate=$q" "$1" "$2" "$fl" 600 ${fl:-keep}
		done
	done
done
echo flashcitydone
cap c60-nobld pb "$C&sw=1&swrate=60&swoff=bld" 960 540 ""
cap q240o-notrees pb "$O&sw=1&swq=1&swrate=240&swoff=trees" 960 540 ""
for sz in "1024 768" "960 540"; do
	set -- $sz
	cap collapse60 collapse "sw=2&swrate=60" "$1" "$2" "" 1500
	cap collapse60 collapse "sw=2&swrate=60" "$1" "$2" "--reduced" 1500
done
echo sgrundone
