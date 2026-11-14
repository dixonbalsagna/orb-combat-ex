# crater-collapse: a big bowl brings down what stands in it (World, 2026-11-01)

Design, Legal's conditions and what is not done: `docs/world/crater-collapse.md` (copy it into docs/world/ with the diff). **Off** (`craters.json` `collapse.enabled` false). **Run (2026-11-02, overnight):** `COLLAPSE` 0 failed on a tree with field-place, power-core and the meteor and through parks beneath it (one test bug fixed: the dig is special, so the test passes the energy over nine); the world checks and the sim gates are not re-run on it yet.

**Apply:** `crater-collapse.diff` (6 files; `git apply` clean on HEAD with the meteor park and on the stack tree with Encounter's parks beneath it, 2026-11-02: the `craters.gd` function is at the file's end, so it does not meet the other parks). **`tools/world-checks.json` needs `"collapse_check"` in "run"** (one word; hand-merge). **No grant:** the first cut had `grant-encounter-blast.patch` (DirArc._blast calls `WorldStructures.levelIn`); it did not apply on the stack (arc.gd differs) and is not needed: the crater's fall works without it, the meteor's own blast stays Encounter's and does not spare a barred landmark (it never did).

**Grant (Encounter's file):** `grant-encounter-blast.patch` (applies on HEAD): `DirArc._blast` calls `WorldStructures.levelIn`, same behaviour except that a barred landmark (the chapel) now stands (RL-232). Without it the meteor's blast is as it was and the crater's collapse works on its own; with the diff and not the grant, nothing breaks (`DirArc._blast` still has its own copy).

**To run before landing:** `godot --headless --path . --script res://sim/world/tools/collapse_check.gd` (prints `COLLAPSE: N check(s) failed`), then `tools/world-checks.mjs --run`, `validate`, the sim gates (parity, determinism, twostates, framecheck) with the switch off (must not move a hash) and once on, and QA's civilian band at tier 4 with it on (RL-232).

**Re-cut 2026-11-06 on HEAD 51ab2001:** applies as it was; **now carries its own line in `tools/world-checks.json`** (`collapse_check`, in the diff). With it landed `landmark_spare_check` runs its crater part too (passes). `COLLAPSE` 0 failed on the full stack.
