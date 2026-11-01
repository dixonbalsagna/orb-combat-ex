# The two-fighter ratchet (Tools, 2026-11-01)

The EP's order, for the restructure toward 2v2 over LAN: shipped code that names exactly two fighters may not grow. `node tools/ratchet-two-fighter.mjs` counts four spellings, `S.dirS.ex`, `fighters[0]`, `fighters[1]` and `SimRoster.opp`, in the shipped GDScript under `sim/`, `render/`, `ui/`, `net/` and `audio/`, and fails CI when the total is above `tools/ratchet-two-fighter.json`. A fix that takes one out only ever lowers it.

**Not counted:** tests, tools, probes and checks (a directory named `test`, `tests`, `tools`, `probe` or `probes`, or a file ending `_check`, `_test`, `_probe` or `_bench`), docs and data. Looping over the list (`for f in S.fighters`) and `fighters[10]` are not counted.

**The ratchet is on the total**, so moving a reference from one file to another is free and a refactor that removes one is never red. A rise prints the files that grew. `--list` shows every file's count against its baseline; `--root <dir>` counts another tree (a stack tree); `--write` lowers the baseline to today's count and **refuses to raise it**.

**The numbers (2026-11-01):** 362 on main (579369ef: 145 `S.dirS.ex`, 85 `fighters[0]`, 67 `fighters[1]`, 65 `SimRoster.opp`, in 65 files) and 402 on the stack with every ready park applied (76 files). The baseline is the stack's 402, so landing the simulation batch does not go red. The biggest: `render/camera/split_rig.gd` 50, `sim/director/exchange.gd` 32, `sim/director/brawl.gd` 31, `sim/core/swing.gd` 21, `sim/director/zip.gd` 18, `render/anim/anim_fighter.gd` 17. **After the batch lands, run `--write`** to take back the slack between main and the stack (parks left out of the stack, such as the mixed string, may add a few: if CI goes red on a landing that is not a fix, re-take the baseline from a stack that includes it).

`node tools/ratchet-two-fighter-selftest.mjs` runs on a synthetic tree: the count, the exclusions, a rise failing and naming its file, an honest fix passing, a moved reference being free, `--write` lowering and refusing to raise.
