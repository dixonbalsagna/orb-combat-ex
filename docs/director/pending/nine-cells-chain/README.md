# The nine cells' chain, parked (2026-10-13, built on main 91b3722f)

Owner: Encounter Systems Director. One chain with one golden: the nine cells' pass 1 as Game Design ruled it in the fifth round, the recipes hook, and the fourth round. What each part does and what it read is in `docs/director/brawl-c2.md`, sections 14 to 17 (in `files/`).

**The order of the chain.**
1. Combat's recipes: `docs/combat/pending/recipes.brawl.json` becomes `data/combat/recipes.json` (drop `_target` and `_changes`), and Tools' `node docs/tools/pending/apply-brawl-recipes.cjs`.
2. `bash apply.sh <root> --check`, then `bash apply.sh <root>`: my eight files and one new one (`sim/director/tools/brawl_cases.gd`). Each must still be the base it was built on (`base.txt`), or nothing is copied; `--check` copies nothing.
3. `bash granted/apply.sh <root>`: the granted lines, as two whole files: `data/fight/wounds.json` (`wearPerDamage` 225.0, `fade.breathAfterTicks` 240) and `data/fight/ladder.json` (`takenPerDamage` 0.006, `dealtPerDamage` 0.0037). Nothing else in them differs from main.
4. `node schema/schema-chain.cjs <root>`: five optional keys (`brawl.burst.floorGap`, `brawl.burst.holdCarries`, `brawl.firstMove.lockTicks`, `brawl.firstMove.pursue`, `digInAfterS`).
5. Simulation's `docs/architecture/pending/weight_event.py`, which rides with this regeneration.
5b. Animation's `git apply docs/animation/pending/nine-cells-asserts.patch` (its two asserts for the new picture).
6. An import (no new class), the golden regenerated once, the gates, and `sim/director/tools/brawl_cases.gd` (the scripted case for the parked medium's reel: it fails on main and passes on the chain).

**Also in it.** The blast's knock-back mark for QA: the `energy_land` cue of a blast that lands as a string's ender carries `amount` 1 (section 14). A zip's blow under the 68-unit rule (`z1`). A double hit whose two blows both land when the first breaks a region.

**Measured and gated** on the scratch build of 91b3722f; the eight files and the granted two are unchanged on main up to 8e2ee750, where `base.txt` was taken. 28 of 30 gates; the two that fail are below.

**Rehearsed** on 2026-10-13 on a fresh export of main 710b6905, from this park as committed and in this order: every step applies, and the validator reads 189 files with 0 errors.

**With it, for others:** Animation's two asserts in `anim_check` that hold the picture from before the recipes; the flash count's one run at its edge (section 15).
