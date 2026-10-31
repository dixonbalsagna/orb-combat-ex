#!/bin/bash
# SCRATCH: after edit 9: World's canonical ground stills, and Orb's small fast swings: stills and flash readings at both sizes. Reduced is the same picture in this scene: proved once by bytes.
LN="$(cd "$(dirname "$0")" && pwd)"
LW="$(cd "${LN:?}" && pwd -W)"
R="C:/Users/itsha/Documents/Claude Proj/Breakers-Like"
powershell -NoProfile -Command "(Get-Process -Id $(cat /proc/$$/winpid)).PriorityClass = 'BelowNormal'" 2>/dev/null
S="${LN:?}/sw_shot.sh"
for x in "fine 0 2600" "fine 0 1000" "bare 1 2600" "bare 1 1000" "coast 2 2600" "coast 2 1000"; do
	set -- $x
	bash "$S" s60rule "cg-$1-$3" 1 121 60 "camd=$3&coarse=$2&nohud=1"
done
bash "$S" s60rule solid60b 1 817 48 nohud=1
cmp "${LN:?}/swst/solid60b/t00385.png" "${LN:?}/swst/solid60b/t00817.png" && echo "s60, final build: after a full turn and after two, byte-identical"
rm -rf "${LN:?}/swst/seam60" "${LN:?}/swst/seam98" "${LN:?}/swst/seamfl" "${LN:?}/swst/seamco"
bash "$S" s60rule seam60 1 381 3 "magenta=1&nohud=1&nobld=1"
bash "$S" s98rule seam98 1 241 3 "magenta=1&nohud=1&nobld=1"
bash "$S" flight4 seamfl 1 361 3 "magenta=1&nohud=1&nobld=1"
bash "$S" s60rule seamco 1 381 3 "magenta=1&nohud=1&nobld=1&coarse=2"
for d in seam60 seam98 seamfl seamco; do node "$LW/sw_seam.mjs" "$R/tools/flash/wcag.js" "$LW/swst/$d"; done
for sc in q240c q120c q240o q120o; do bash "$S" "$sc" "st-$sc" 1 241 40 ""; done
cd "$R" || exit 1
rm -rf "${LN:?}/swq"
mkdir -p "${LN:?}/swq"
cap() {
	local sc="$1" w="$2" h="$3" fl="$4"
	local o="${LN:?}/swq/$sc-${w}x$h${fl:+-reduced}"
	MERIDIAN_SESSION=rendering timeout 1200 env MSYS_NO_PATHCONV=1 PATH="/c/Windows/System32:$PATH" node tools/flash/capture-web.mjs --dir "$LW/sw_site/play" --path "/index.html?flashcap=1&nohud=1" --scenario "$sc" --ticks 600 --width "$w" --height "$h" $fl --out "$LW/swq/$sc-${w}x$h${fl:+-reduced}" --session rendering 2>&1 | tail -2 | head -1 | cut -c1-120
	env PATH="/c/Windows/System32:$PATH" node tools/flash/analyse-frames.js "$o" --scale 1 --allow-short 2>&1 | grep -a " 600 " | cut -c1-190
}
for sz in "1024 768" "960 540"; do
	set -- $sz
	for sc in q240c q120c q240o q120o; do cap "$sc" "$1" "$2" ""; done
done
cap q240c 1024 768 "--reduced"
node "$LW/cr_cmp.mjs" "$LW/swq/q240c-1024x768" "$LW/swq/q240c-1024x768-reduced" "q240c, normal against reduced"
echo qdone
