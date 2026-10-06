#!/bin/bash
# apply.sh <root> [nudgeShare e,m,h] [walkOut e,m,h]: the C1 slice on a tree or a copy at 197592a1 or later (the
# files it edits must be HEAD's). The goldens are regenerated after it (sim/core/tools/golden.gd).
D="$(cd "$(dirname "$0")" && pwd)"
R="$1"
node "$D/e1.cjs" "$R/sim/director/brawl.gd" || exit 1
node "$D/e2.cjs" "$R/sim/director/brawl.gd" "$D/frag_control.gd" || exit 1
node "$D/e3.cjs" "$R" ${2:+"$2"} ${3:+"$3"} || exit 1
node "$D/e4.cjs" "$R" || exit 1
echo "C1 applied to $R"
