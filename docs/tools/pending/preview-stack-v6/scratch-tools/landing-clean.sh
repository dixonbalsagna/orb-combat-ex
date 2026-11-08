#!/bin/bash
# Rebuilds the clean landing tree at a NEW path (landing-clean-<name>), applies the v6 ci.yml steps, runs validate and the two-fighter ratchet, writes the changed-file list. Usage: bash landing-clean.sh <name>
S="$TEMP/claude/C--Users-itsha-Documents-Claude-Proj-Breakers-Like/f4930939-92a3-468f-86d1-efe5cc11ac6a/scratchpad"
R="C:/Users/<user>/Documents/Claude Proj/Breakers-Like"
N="$1"; OUT="$TEMP/meridian-stack-preview/landing-clean-$N"
SKIP=ui-working-tree,controls-layouts,art-biomes-working-tree,controls-quick-read,audio-host-check,controls-stick-feel,controls-beam-aim,controls-stage-haptics,controls-queue-20,controls-first-pad
[ -e "$OUT" ] && { echo "refused: $OUT exists"; exit 1; }
bash "$S/fp/gen-park6b.sh" > /dev/null 2>&1
cd "$S/dev3" && rm -rf "${S:?}/fp/lc-tmp" && node ../t/clean-tree.mjs "$S/fp/lc-tmp" $SKIP 2>&1 | tail -1 | cut -c1-1500
T=$(ls -d "$S"/fp/lc-tmp/*/tree | head -1)
(cd "$T" && git -c core.autocrlf=false apply --include=.github/workflows/ci.yml "$R/docs/tools/pending/preview-stack-v6/preview-stack-v6.patch" && echo "ci.yml steps applied")
mkdir -p "$OUT" && mv "$T" "$OUT/tree" && rm -rf "${S:?}/fp/lc-tmp" "${S:?}/fp/lc-tmp.json"
T2="$OUT/tree"
echo "--- json check"; (cd "$T2" && node -e "
const fs=require('fs'),path=require('path');let bad=[],n=0;const walk=(d)=>{for(const e of fs.readdirSync(d,{withFileTypes:true})){if(['.git','.godot','node_modules'].includes(e.name))continue;const p=path.join(d,e.name);if(e.isDirectory())walk(p);else if(/\.json$/.test(e.name)){n++;try{JSON.parse(fs.readFileSync(p,'utf8'))}catch(x){bad.push(p+': '+String(x.message).slice(0,70))}}}};walk('.');console.log('json files',n,'invalid',bad.length);bad.forEach(b=>console.log(b))")
echo "--- validate"; (cd "$T2" && timeout 200 node tools/validate.js 2>&1 | tail -4 | cut -c1-240; echo "validate exit ${PIPESTATUS[0]}")
echo "--- ratchet"; (cd "$R" && node tools/ratchet-two-fighter.mjs --root "$T2" 2>&1 | head -3 | cut -c1-240)
export GIT_INDEX_FILE="$S/fp/lc-index"; rm -f "$GIT_INDEX_FILE"; G="$R/.git"
git --git-dir="$G" --work-tree="$T2" read-tree 10d8b8cf
{ git --git-dir="$G" --work-tree="$T2" -c core.autocrlf=false diff --name-status 2>/dev/null; git --git-dir="$G" --work-tree="$T2" ls-files --others --exclude-standard 2>/dev/null | sed 's/^/A\t/'; } > "$OUT/changed-files.txt"
unset GIT_INDEX_FILE; rm -f "$S/fp/lc-index"
echo "changed files: $(wc -l < "$OUT/changed-files.txt")  tree: $T2"
