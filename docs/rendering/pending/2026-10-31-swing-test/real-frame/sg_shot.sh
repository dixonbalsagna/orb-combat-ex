#!/bin/bash
# SCRATCH: stills of the real frame: sg_shot.sh <scene> <out> <first> <count> <every> <page words> [w h]
LN="$(cd "$(dirname "$0")/.." && pwd)"
LW="$(cd "${LN:?}" && pwd -W)"
R="C:/Users/itsha/Documents/Claude Proj/Breakers-Like"
powershell -NoProfile -Command "(Get-Process -Id $(cat /proc/$$/winpid)).PriorityClass = 'BelowNormal'" 2>/dev/null
START="(window.__flashcap && window.__flashcap.ready && (window.__psStarted || (window.__flashcap.start(\"$1\", {}), window.__psStarted = true)))"
cd "$R" || exit 1
MERIDIAN_SESSION=rendering timeout 500 node tools/machine/capture.mjs frames --dir "$LW/sg_site" --path "/play/index.html?flashcap=1&$6" --out "$LW/sgst/$2" --first "$3" --count "$4" --every "$5" --wait-js "$START" --step-js "window.__flashcap.step()" --tick-js "window.__flashcap.tick" --width "${7:-1280}" --height "${8:-720}" --session rendering --quiet 2>&1 | tail -2 | cut -c1-240
ls "${LN:?}/sgst/$2" 2>/dev/null | wc -l
