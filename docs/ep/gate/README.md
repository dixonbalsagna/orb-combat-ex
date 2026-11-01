# The EP's landing gate

Scripts for gating parks in a scratch copy before landing them on main. Nothing here touches the repo's working tree.

1. **Set up a tree.** Export HEAD to `$S/$T`, `git init` it, commit a base with `core.autocrlf=false`, copy an imported `.godot` in if you have one, and put `.godot` in `.git/info/exclude`. Apply each park with `git -c core.autocrlf=false apply --ignore-whitespace --whitespace=nowarn <absolute path>`. Never point an apply at the repo root before the gate has passed.
2. **Run it at below-normal priority, detached.** Set `S` (a scratch folder), `T` (the tag) and `GODOT` (the console exe), then start `bash docs/ep/gate/run-gate.sh` through PowerShell `Start-Process` and set `PriorityClass = 'BelowNormal'`. Keep the PID. Results land in `$S/$T-sim/r.txt`, ending in `ALLDONE`.
3. **Read it.** Each line is a name, an exit code and a verdict. A failed World check on a saturated machine may be load: re-run it alone before believing it. `golden_cmp` compares the regenerated golden to the repo's.
4. **Land it.** Copy the files `git status --short -uall` lists in the scratch tree (first check they don't overlap anything dirty or moved on main), including new `.uid` files, then `git add` those paths, `node tools/validate.js`, commit and push. Delete the parks you landed. Confirm CI's result next time you look, not just "in progress".

A new schema needs its file in `tools/schemas`, a `map.json` row and at least 3 cases in `tools/fixtures/cases.json`. When UI data changes, run `node tools/l10n/pseudo.mjs --write`.

Golden and `launchbiome_probe` read switches as shipped, so they only mean something with the switches off.
