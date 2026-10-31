#!/bin/bash
# SCRATCH: after the flight's follow and a wider bake (a missing tile stops a split, which left two levels side by side): seams, flight, open ground on the canonical spacing, a final solid turn and bench.
LN="$(cd "$(dirname "$0")" && pwd)"
LW="$(cd "${LN:?}" && pwd -W)"
R="C:/Users/itsha/Documents/Claude Proj/Breakers-Like"
powershell -NoProfile -Command "(Get-Process -Id $(cat /proc/$$/winpid)).PriorityClass = 'BelowNormal'" 2>/dev/null
S="${LN:?}/sw_shot.sh"
rm -rf "${LN:?}/swst/seam60" "${LN:?}/swst/seam98" "${LN:?}/swst/seamfl" "${LN:?}/swst/seamco" "${LN:?}/swst/fl15" "${LN:?}/swst/fl4" "${LN:?}/swst/fl0" "${LN:?}/swst/solid60b"
bash "$S" s60rule solid60b 1 817 48 nohud=1
cmp "${LN:?}/swst/solid60b/t00385.png" "${LN:?}/swst/solid60b/t00817.png" && echo "s60, final build: after a full turn and after two, byte-identical"
bash "$S" s60rule seam60 1 381 3 "magenta=1&nohud=1&nobld=1"
bash "$S" s98rule seam98 1 241 3 "magenta=1&nohud=1&nobld=1"
bash "$S" q240c seamq 1 241 3 "magenta=1&nohud=1&nobld=1"
bash "$S" flight4 seamfl 1 361 3 "magenta=1&nohud=1&nobld=1"
bash "$S" s60rule seamco 1 381 3 "magenta=1&nohud=1&nobld=1&coarse=2"
for d in seam60 seam98 seamq seamfl seamco; do node "$LW/sw_seam.mjs" "$R/tools/flash/wcag.js" "$LW/swst/$d"; done
bash "$S" flight1.5 fl15 1 1201 60
bash "$S" flight4 fl4 1 1201 60
bash "$S" flight0 fl0 1 361 60 "coarse=2"
for x in "fine 0" "bare 1" "coast 2"; do
	set -- $x
	bash "$S" q120o "og-$1" 1 121 60 "coarse=$2&nohud=1"
	bash "$S" q120o "og1-$1" 1 121 60 "coarse=$2&nohud=1&camd=1000"
done
cd "$R" || exit 1
fb() {
	local site="$1" sc="$2" lb="$3"; shift 3
	MERIDIAN_SESSION=rendering timeout 900 env PATH="/c/Windows/System32:$PATH" node docs/perf/tools/frame-bench.mjs --site "$LW/$site" --scene "$sc" --label "$lb" --session rendering --ticks 600 --warm 60 --out "$LW/swb/$lb.json" "$@" 2>&1 | tail -1 | cut -c1-260
}
fb sw_site s60rule s60-igpu --igpu
fb sw_site s60rule s60-x4 --throttle 4
fb sw_site flight1.5 fl15-x4 --throttle 4
fb sw_site flight1.5 fl15-igpu --igpu
fb sw_site s60rule s60-coast-igpu --igpu --page-args "coarse=2"
echo sw_ddone
