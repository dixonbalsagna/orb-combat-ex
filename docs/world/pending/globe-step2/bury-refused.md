# Park: a hard impact still buries on dented ground, and a refused dig sends crater_refused (World, 2026-11-23)

**Landed in GW1c (2026-11-25): the diff and both grants (25cfc527, 602fef37, 1d9b1e1f), Simulation's golden target 2 (c741c4ec) and VFX's `crater_refused` play (960d5a28). The patches are removed from this folder.**

Found by Combat from the code (EP, 2026-11-23): the shaft cap of globe-step2 refuses a dig on ground already as dented as the blow can dig (`d < MIN_DEPTH`, no crater). `contact.gd` buries a fighter only against a crater it dug, and only when that crater is deep enough (`depth / 75 >= K_EMB_MIN * threshold`). So a hard slam onto an old crater, or onto a smaller one the cap lets it dig only a little into, did not bury him. Orb said yes to burying (vision.md:514). VFX's addition: a refused dig sent no `crater` event, so the ejecta arc, rim dust, `blast.on_crater` and the biome burst were all lost.

**One follow-on diff, cut on the end of the stack** (all 24 pieces of `docs/ep/reviews/GW1c-stack.txt`), applied **last of the world pieces**: no earlier piece is re-cut, and the five later pieces that touch `crater.gd` keep their context.

| File | What |
| :--- | :--- |
| `bury-refused.diff` | World's: `sim/world/crater.gd` (the refusal, the sit depth, the event call), `sim/world/contact.gd` (the bury reads them), new `sim/world/tools/bury_check.gd` (`BURY`) and its `.uid` |
| `grant-simulation-crater-refused.patch` | Simulation's: `sim/core/fx.gd` (`SimFx.craterRefused`), `sim/core/hash.gd` (`FX_FIELDS`), `sim/core/view/fx.gd` (the event is cosmetic). Apply **before** `bury-refused.diff`: the diff calls `SimFx.craterRefused` |
| `grant-tools-bury-check.patch` | Tools': `tools/world-checks.json`, one line (`bury_check` after `globe_check`) |

## What changed in play

- **The bury.** After a dig the contact asks how deep the bowl he sits in is. A dug crater: as before. A dented spot: the whole dent plus what this blow dug, never more than the blow would dig on fresh ground (`WorldCrater.sitDepth`: `min(dRaw, relief + d)`; on fresh ground it is the dug depth exactly, so nothing changes there). A refused dig buries against that, with the floor at the ground as it stands. **A hard impact is as hard as it is whatever the cap left it to dig; a soft one buries nobody**, however deep the old dent (the check proves both).
- **Beyond the refusal.** The same defect hit a hard slam on a *smaller* old crater (the cap lets it dig only 78 of its 159): it dug a crater too shallow to bury him. It buries now. This is wider than the refusal alone: any impact on a partly dented spot that would have buried on fresh ground buries now.
- **The event.** A dig refused because the spot is already as dented as the blow can dig sends **`crater_refused`**: `x`, `y` (the ground there before the blow), `z`, `r` (the blow's own radius), `depth` (the dent already there), `energy`, `cause` (the kind of blow: `impact`, `beam`, `powerup`, ...). No record, no crater event, no bowl, no cracks: it is only a read for the renderers. A blow too weak to dig on fresh ground (`dRaw < MIN_DEPTH`) sends nothing. The refusals are the shaft cap and the settling taking the bowl under the minimum.
- **What stays.** The refusal itself: nothing more is dug. The contact's own ring, debris, dust, hit-stop, shake and damage still play (the check counts them).

## What it moves

**It moves the golden beyond Simulation's target** (`docs/sim/runs/bc1e5558/gw1c-target/golden-target.json`), in three matches: **mirror-villain seed 1, swap-flip seed 2 and default seed 11** fail on their per-tick digest. Their checkpoints agree (the state hashes at the checkpoints are the target's): the difference is between the checkpoints, in the feed text or the fx events. The stack without this fix passes the same target (0 FAIL, exit 0), so the fix is what moves them. **Both parts move it.** With `SimFx.craterRefused` made a no-op (the bury alone) two matches still fail, mirror-villain seed 1 (the same digest as with the event) and swap-flip seed 2 (a different digest): the bury moves those. Default seed 11 passes without the event and fails with it: that one is the event alone (a refusal there that the bury did not change). Simulation re-records once, for the bury and the event together. `docs/world/runs/bury-refused/` (the three parity runs).

## Tests

`BURY` (`sim/world/tools/bury_check.gd`): 16 rows, 0 fail; `--negative-control` (the stack before the fix, `WorldContact.buryRefused` false) fails 4. With it: `globe_check`, `craters_check`, `burial_check`, `tier_ratio_check`, `relief_cap_check` and `crater_flatten_check` pass on the fixed stack (`runs/bury-refused/world-checks-7.txt`).
