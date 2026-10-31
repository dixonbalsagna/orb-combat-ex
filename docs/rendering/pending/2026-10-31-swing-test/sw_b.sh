#!/bin/bash
# SCRATCH: the pass lines that are readings: frame cost (1) and flash (6). One browser at a time, below normal; a run marks itself invalid if the machine was saturated.
LN="$(cd "$(dirname "$0")" && pwd)"
LW="$(cd "${LN:?}" && pwd -W)"
R="C:/Users/itsha/Documents/Claude Proj/Breakers-Like"
powershell -NoProfile -Command "(Get-Process -Id $(cat /proc/$$/winpid)).PriorityClass = 'BelowNormal'" 2>/dev/null
cd "$R" || exit 1
rm -rf "${LN:?}/swb" "${LN:?}/swf"
mkdir -p "${LN:?}/swb" "${LN:?}/swf"
if [ ! -d "${LN:?}/sw_base/play" ]; then mkdir -p "${LN:?}/sw_base/play" && cp "${LN:?}"/web_cb_p0/* "${LN:?}/sw_base/play/"; fi
fb() {   # site, scene, label, flags...
	local site="$1" sc="$2" lb="$3"; shift 3
	MERIDIAN_SESSION=rendering timeout 900 env PATH="/c/Windows/System32:$PATH" node docs/perf/tools/frame-bench.mjs --site "$LW/$site" --scene "$sc" --label "$lb" --session rendering --ticks 600 --warm 60 --out "$LW/swb/$lb.json" "$@" 2>&1 | tail -1 | cut -c1-260
}
fb sw_site s60rule s60-igpu --igpu
fb sw_site s98rule s98-igpu --igpu
fb sw_base pb base-igpu --igpu --page-args "pgen=2&pplanet=7&pbiome=city"
fb sw_site s60rule s60-x4 --throttle 4
fb sw_site s98rule s98-x4 --throttle 4
fb sw_site flight1.5 fl15-x4 --throttle 4
fb sw_base pb base-x4 --throttle 4 --page-args "pgen=2&pplanet=7&pbiome=city"
fb sw_site s60rule s60-x1
fb sw_base pb base-x1 --page-args "pgen=2&pplanet=7&pbiome=city"
echo benchdone
cap() {   # scene, w, h, mode flag
	local sc="$1" w="$2" h="$3" fl="$4"
	local o="${LN:?}/swf/$sc-${w}x$h${fl:+-reduced}"
	MERIDIAN_SESSION=rendering timeout 1200 env MSYS_NO_PATHCONV=1 PATH="/c/Windows/System32:$PATH" node tools/flash/capture-web.mjs --dir "$LW/sw_site/play" --path "/index.html?flashcap=1&nohud=1" --scenario "$sc" --ticks 600 --width "$w" --height "$h" $fl --out "$(cd "${LN:?}" && pwd -W)/swf/$sc-${w}x$h${fl:+-reduced}" --session rendering 2>&1 | tail -2 | head -1 | cut -c1-140
	env PATH="/c/Windows/System32:$PATH" node tools/flash/analyse-frames.js "$o" --scale 1 --allow-short 2>&1 | grep -a " 600 " | cut -c1-190
}
for sz in "1024 768" "960 540"; do
	set -- $sz
	cap s60rule "$1" "$2" ""
	cap s98rule "$1" "$2" ""
	cap s65rule "$1" "$2" "--reduced"
	cap s30rule "$1" "$2" "--reduced"
done
echo flashdone
