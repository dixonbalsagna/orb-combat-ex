#!/bin/bash
# The interim return, start to finish, on the frozen commit (Legal's RL-136, docs/legal/photosensitivity-note.md addendum 8; docs/tools/site-interim.md):
#   bash tools/flash/interim-run.sh <commit> <from YYYY-MM-DD> <expires YYYY-MM-DD> [work dir]
# 1. exports the commit's web build (a scratch tree: nothing in the working tree changes);
# 2. captures the full required set (every clip, normal and reduced) through the guarded launcher at three jobs, switches off;
# 3. captures the clips that need a second capture (primary above 2.0 and up to 3.0, not already failing) again;
# 4. reads the margins table;
# 5. RECORDS the pass with the interim and its three waivers into tools/flash/release-pass.json (the one write this script makes in the tree), for that commit;
# 6. builds the interim site locally from that export and checks it (tools/check-site-interim.mjs), then takes the gate's stills (desktop, phone, after the click, About).
# It does not publish and does not touch tools/site.json: the switch is the EP's.
# One capture set at a time, below normal, inside the 40% budget: this is the machine's long job. About 1 h 45 for the set, 25 minutes for the second captures.
set -u
COMMIT=${1:?commit}
FROM=${2:?from date}
EXPIRES=${3:?expiry date}
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SHORT=$(git -C "$ROOT" rev-parse --short "$COMMIT") || exit 2
FULL=$(git -C "$ROOT" rev-parse "$COMMIT") || exit 2
W=${4:-"${TEMP:-/tmp}/interim-$SHORT"}
G=${GODOT:-"C:/Users/itsha/AppData/Local/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"}
export MSYS_NO_PATHCONV=1
export MERIDIAN_SESSION=${MERIDIAN_SESSION:-tools}
mkdir -p "$W" || exit 2
LOG="$W/interim-run.log"
say() { echo "== $* $(date +%H:%M:%S)" | tee -a "$LOG"; }
cd "$ROOT" || exit 2

say "export $SHORT"
if [ ! -f "$W/web/index.html" ]; then
  rm -rf "$W/x" "$W/web"; mkdir -p "$W/x" "$W/web"
  git archive "$FULL" | tar -x -C "$W/x" || exit 2
  ( cd "$W/x" && "$G" --headless --path . --import > "$W/import.log" 2>&1; "$G" --headless --path . --export-release "Web" "$W/web/index.html" > "$W/export.log" 2>&1 )
  [ -f "$W/web/index.html" ] || { echo "export failed: see $W/export.log"; exit 3; }
fi

CLIP_ARGS=(--dir "$W/web" --path "/index.html?flashcap=1" --jobs 3 --keep-ranges)
say "the full required set"
mkdir -p "$W/clips"
node tools/flash/run-pixels.mjs "${CLIP_ARGS[@]}" --out "$W/clips" > "$W/pixels.txt" 2>&1
echo "set exit $?" | tee -a "$LOG"
[ -f "$W/clips/summary.json" ] || { echo "no summary.json: see $W/pixels.txt"; exit 4; }

# the clips that need a second capture
SECOND=$(node -e "
const s = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
const ids = s.filter((e) => !e.error && e.result && e.result.general && e.result.general.flashes > 2.0 && e.result.general.flashes <= 3 && e.result.combined.verdict !== 'FAIL').map((e) => e.id);
console.log(ids.join(','));" "$W/clips/summary.json")
echo "second captures: ${SECOND:-none}" | tee -a "$LOG"
SECOND_ARGS=()
if [ -n "$SECOND" ]; then
  say "second captures"
  mkdir -p "$W/clips_second"
  node tools/flash/run-pixels.mjs "${CLIP_ARGS[@]}" --out "$W/clips_second" --clip "$SECOND" > "$W/pixels_second.txt" 2>&1
  echo "second exit $?" | tee -a "$LOG"
  [ -f "$W/clips_second/summary.json" ] && SECOND_ARGS=(--seconds "$W/clips_second/summary.json")
fi

# NIGHTLY-STYLE seeds on the same commit (Legal RL-156, addendum 10): seeds 1008 and 1009 and 20 fresh ones, both modes, none over 3 on the primary reading
say "nightly-style seeds"
EXTRA_SEEDS=$(node --input-type=module -e "
import { nextSeeds } from "./tools/flash/nightly-seeds.mjs";
import { readFileSync, existsSync } from "node:fs";
const src = JSON.parse(readFileSync("tools/flash/sources.json", "utf8"));
const recorded = new Set((src.pairings || []).flatMap((p) => p.seeds || []));
const hist = existsSync("tools/flash/nightly-seeds.json") ? JSON.parse(readFileSync("tools/flash/nightly-seeds.json", "utf8")) : { runs: [] };
const used = hist.runs.flatMap((r) => r.seeds).filter((s) => s !== 1008 && s !== 1009);
console.log([1008, 1009, ...nextSeeds(20, 1010, recorded, used).filter((s) => s !== 1008 && s !== 1009)].join(","));
")
echo "nightly-style seeds: $EXTRA_SEEDS" | tee -a "$LOG"
mkdir -p "$W/clips_extra"
node tools/flash/run-pixels.mjs "${CLIP_ARGS[@]}" --out "$W/clips_extra" --seeds "$EXTRA_SEEDS" > "$W/pixels_extra.txt" 2>&1
echo "extra exit $?" | tee -a "$LOG"

say "margins"
node tools/flash/margins.mjs "$W/clips" --json "$W/margins.json" --md "$W/margins.md" > "$W/margins.txt" 2>&1
[ -n "$SECOND" ] && node tools/flash/margins.mjs "$W/clips_second" --json "$W/margins_second.json" > "$W/margins_second.txt" 2>&1

# the condition of the EP's word: record ONLY if no clip reads over 3 on the primary reading (the worse of a clip and its second capture); otherwise stop here, with the clips
OVER=$(node -e "
const fs = require('fs');
const rd = (p) => { try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return []; } };
const base = rd(process.argv[1]), sec = rd(process.argv[2]);
const out = [];
for (const e of base) { if (e.error || !e.result) { out.push(e.id + ' (no result)'); continue; }
  const s = sec.find((x) => x.id === e.id && !x.error && x.result);
  const p = Math.max(e.result.general.flashes, s ? s.result.general.flashes : 0);
  if (p > 3) out.push(e.id + ' primary ' + p + ' (' + [e.result.combined.primary, e.result.combined.lower, e.result.combined.stricter].join('/') + ')'); }
const ex = rd(process.argv[3]);
for (const e of ex) { if (e.error || !e.result) { out.push(e.id + ' (no result, nightly-style seed)'); continue; } if (e.result.general.flashes > 3) out.push(e.id + ' primary ' + e.result.general.flashes + ' (nightly-style seed)'); }
console.log(out.join('; '));
" "$W/clips/summary.json" "$W/clips_second/summary.json" "$W/clips_extra/summary.json")
if [ -n "$OVER" ]; then
  echo "NOT RECORDED: clips over 3 on the primary reading: $OVER" | tee -a "$LOG"
  echo "$OVER" > "$W/NOT-RECORDED.txt"
  exit 5
fi
say "record the interim pass for $SHORT"
# the AI seeds of the set and the rule that picked them (sources.json at the commit); the HUD's own worst flicker is the largest UiLook.HZ_* of the commit
git -C "$ROOT" show "$FULL:tools/flash/sources.json" > "$W/sources.at.commit.json"
git -C "$ROOT" show "$FULL:ui/core/ui_look.gd" > "$W/ui_look.at.commit.gd"
node -e "
const fs = require('fs');
const src = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
const seeds = [...new Set((src.pairings || []).flatMap((p) => p.seeds || []))];
const look = fs.readFileSync(process.argv[2], 'utf8');
const hz = [...look.matchAll(/const HZ_[A-Z_]+ := ([0-9.]+)/g)].map((m) => Number(m[1]));
fs.writeFileSync(process.argv[3], JSON.stringify({ rule: 'tools/flash/pick-seeds.mjs: the seeds of tools/flash/sources.json at the commit', seeds, pairings: (src.pairings || []).map((p) => ({ slots: p.slots, seeds: p.seeds })) }, null, 2));
fs.writeFileSync(process.argv[4], String(hz.length ? Math.max(...hz) : 0));
" "$W/sources.at.commit.json" "$W/ui_look.at.commit.gd" "$W/pick.json" "$W/hud-rate.txt"
node tools/flash/release-pass.mjs --record --summary "$W/clips/summary.json" --extra "$W/clips_extra/summary.json" "${SECOND_ARGS[@]}" --hud-rate "$(cat "$W/hud-rate.txt")" --hud-source "ui/core/ui_look.gd HZ_* (the largest, read from the commit)" \
  --seed-pick "$W/pick.json" --interim RL-136 --from "$FROM" --expires "$EXPIRES" --commit "$FULL" 2>&1 | tee -a "$LOG"
node tools/flash/release-pass.mjs --verify --commit "$FULL" 2>&1 | tee -a "$LOG"

say "the interim site, locally"
cat > "$W/site.json" <<EOF2
{ "offline": false, "approved": "$FROM", "interim": { "legal": "RL-136", "approved": "$FROM", "expires": "$EXPIRES", "notice": "site-interim.json" } }
EOF2
rm -rf "$W/site"
node tools/build-site.mjs --web "$W/web" --out "$W/site" --commit "$FULL" --config "$W/site.json" 2>&1 | tee -a "$LOG"
node tools/check-site-interim.mjs --site "$W/site" --config "$W/site.json" --root "$W/x" --today "$FROM" 2>&1 | tee -a "$LOG"

say "the stills"
mkdir -p "$W/stills"
JS="document.getElementById('gate-start').click(); new Promise(function (r) { setTimeout(r, 40000); })"
node tools/machine/capture.mjs still --dir "$W/site" --path /play/ --out "$W/stills/gate-desktop.png" --width 1024 --height 768 --wait-ms 4000 --time-limit 240 --purpose interim > /dev/null 2>&1
node tools/machine/capture.mjs still --dir "$W/site" --path /play/ --out "$W/stills/gate-phone.png" --width 390 --height 844 --wait-ms 4000 --time-limit 240 --purpose interim > /dev/null 2>&1
node tools/machine/capture.mjs still --dir "$W/site" --path /play/ --out "$W/stills/after-start-desktop.png" --width 1024 --height 768 --wait-ms 3000 --time-limit 300 --purpose interim --after-js "$JS" > /dev/null 2>&1
node tools/machine/capture.mjs still --dir "$W/site" --path /play/ --out "$W/stills/after-start-phone.png" --width 390 --height 844 --wait-ms 3000 --time-limit 300 --purpose interim --after-js "$JS" > /dev/null 2>&1
node tools/machine/capture.mjs still --dir "$W/site" --path / --out "$W/stills/holding-phone.png" --width 390 --height 844 --wait-ms 3000 --time-limit 240 --purpose interim > /dev/null 2>&1
node tools/machine/capture.mjs still --dir "$W/site" --path /about/ --out "$W/stills/about-desktop.png" --width 1024 --height 768 --wait-ms 3000 --time-limit 240 --purpose interim > /dev/null 2>&1
ls "$W/stills" | tee -a "$LOG"
say "done: $W"
