# Park: World's check pins for GW1a and GW1b (World, 2026-11-14; EP briefs of 11-13 and 11-14)

When the data goes on (GW1a: the 9 November build's switches, and Simulation's energy model and dash) and then the default world moves to the round planet (GW1b: A-WORLD-01), World's checks that pin the old shipped values or the hand-made arena go red. This is the patch that keeps them testing the old path. Checks only; **no sim file, no data file**. Runs: `docs/world/runs/checks-gw1a/`.

| File | What |
| :--- | :--- |
| `pins-gw1a.diff` | `sim/world/tools/pin.gd` (`WorldPin.shipped()`) and one line at the top of `_init` in 33 checks. Stands on HEAD def3445a (`git apply --check` clean) |
| `pins-gw1b.diff` | **Re-cut 2026-11-20 (B-09): `WorldPin.arena()` and one line in 25 checks** (the 12 before and the 13 the full run on the flipped tree showed: floor, arena, brunt, craters, deepen, epoch, farsites, fill, ground, repeat, sea_rules, wall, street_axis), and `planet_world_check`'s row "a setup without a planet is today's world" reworded to say the arena is named (the default is the planet). Strict-applies on HEAD + `pins-gw1a.diff`. Stacks after `pins-gw1a.diff` and after `a-world-01` (it calls `WorldDefault`) |

## How a pin works

`WorldPin.shipped()` sets, in this process's memory only, the values main shipped before GW1a: `climate.json` gen 1, water v2 off (enabled, surface, floor, flowWarm 0), contact settle off, field plans everywhere off, the arena's calm turn off (`rings.json turn.on` 0, `interrupts.json` calmTurn and water), the planner not reading the ground, and the energy model and the dash off (`SimPower`). Each module's data is loaded first, so a module that loads on its first call does not write the file's values back over the pin. It is the check-side form of what Simulation's `energy-on` asks ("pin `power: false` to keep testing the off path"), done once for all of World's checks. `WorldPin.arena()` sets the default world back to the hand-made arena (`WorldDefault.setForTest`). A check that tests the new default does not call either; one that tests the old path calls one first.

## Which go red from what (the split you asked for)

Measured on scratch trees of HEAD: GW1a's World rows alone (no energy model); the same rows with Simulation's `energy-on`; the rows plus the mode flip.

| Source | Checks |
| :--- | :--- |
| **GW1a's World rows alone** (23) | `floor_check` 3, `arena_check` 2, `climate_check` 2, `power_world_check` 1, `epoch_check` 5, `far_check` 2, `farmap_check` 1, `farsites_check` 1, `field_water_check` 1, `field_lot_check` 3, `fill_check` 2, `gen2_state_check` 5, `ground_check` 5, `lakes_check` 1, `land_check` 1, `planet_check` 3, `ringpick_check` 3, `sea_rules_check` 2, `sites_check` 1, `surface_check` 2, `street_axis_check` 4, `water_warm_check` 1, `struggle_meet_check` 1 (the number is failing rows; every one pins a shipped value, a generation, or a hash recorded on the old data) |
| **Only with the energy model and the dash** (9, and `wrecks_check`) | `brunt_check` 6, `craters_check` 1, `deepencheck` 1, `interior_check` 3, `repeat_check` 1, `meteor_crater_check` 1, `wall_hold_check` 3, `struggle_dir_check` 1, `bystanders_check` 1; Simulation's list adds `ground_check` 2 and `wrecks_check` 1, which `wrecks_check` is pinned for but not run (it wants the quiet window: about an hour on a loaded machine) |
| **Only with the mode flip** (GW1b, 12) | `depthreads_check` (read statically: it asks the hand-made arena for the crossing at x 46,599; the planet has none, so `ix[0]` is out of bounds at line 19), `lane_check`, `after_check`, `control_check`, `demostart_check`, `planet_world_check`, `skate_check`, `surface_follow_check`, `fire_check`, `ground_props_check`, `isect_check`, `floor_walk_probe`: each assumes a setup with no planet plays the hand-made arena |

Not in the split: `step_check`'s timing line fails under load whatever the data (passes alone), and `wrecks_check`, `depthreads_check` are the two slow ones.

## Proof

| | Result |
| :--- | :--- |
| The 32 checks, unpinned, on HEAD with the GW1a rows and `energy-on` | 32 red; the other 51 of 83 pass (`before-the-pins-on-GW1a-rows-and-energy-on.txt`) |
| The same 32, pinned, on the same data | **all 32 pass** (`with-the-pins-on-GW1a-rows-and-energy-on.txt`) |
| The same 32, pinned, on today's main data | **all 32 pass**: a pin is a no-op where the data is the old data, so the patch can land before the data (`with-the-pins-on-todays-main-data.txt`) |
| The 11 mode-only checks with `WorldPin.arena()`, on the GW1a rows and the planet default | all 11 pass |
| Not covered | `depthreads_check` (pinned for the mode by static reading, not run; waits for the quiet window), the energy model's own re-read rows beyond the ones named in `docs/world/pins-and-the-model.md`. `wrecks_check` runs with the model on on the s422 tree and passes (its failing row was staging: the thrower's tier is now set) |

## Re-cut 2026-11-14 (GW1a review blocker 1): the model is no longer pinned off where it matters

`WorldPin.shipped(power)` (default false) keeps the old pin; `shipped(true)` leaves the energy model and the dash as the data has them. **23 checks now run with the model on** (21 of the original list, plus `bystanders_check` and `struggle_dir_check`, which pass with it on; `bystanders_check` plays Orb's path with no civilian dying). **Eight checks run twice** in one process, model off then on (`repeat`, `wrecks`, `meteor_crater`, `interior`, `wall_hold`, `brunt`, `deepen`, `craters`): each failing row is OFF-PATH (model off only, with the reason) or a REAL FAULT run with the model on as a ceiling at today's value (`KNOWN FAULT (owed: ...)`). `ground_check` stays on the old path (it pins recorded hashes). 2026-11-20: `repeat_check`'s ladder row is off-path (it measures a house) and `wall_hold_check`'s memory row is a ceiling, now that the memory fault they found is fixed in `pending/memory-under-model`. The class of every row, the owed fixes and the records: `docs/world/pins-and-the-model.md`, `docs/world/runs/checks-gw1a/`. Gates: all 33 pass on the s422 tree (the GW1a stack). `pins-gw1b.diff` is re-cut on the new `pin.gd`. Both diffs apply strictly on HEAD (`git -c core.autocrlf=false apply`), in order.

## NEEDS FROM EP

- Land `pins-gw1a.diff` with or before GW1a; `pins-gw1b.diff` with A-WORLD-01 (the first step of GW1b).
- A quiet window for `wrecks_check` and `depthreads_check` on the new data.
- The pins no longer hide the model: see the re-cut section and `docs/world/pins-and-the-model.md` for every row that fails with it on (off-path with its reason, or a ceiling with the owed fix). Whether any pinned check should be re-read under the new default world (GW1b) is a separate question; the new default's own checks are `world_default_check` and `size_check`.

## RISKS

- A pin changes memory, not files: a check run in the same process after another that pinned sees pinned data (each check is its own Godot process in CI, so it does not).
- `WorldPin.shipped()` reaches into five modules' data (World's, the director's, the planner's, Simulation's power). If one of them changes how it loads, the pin must follow; `pins-gw1a` carries the check that would show it (each pinned check fails against a moved value).

**Status at quiet time (2026-11-14):** the re-class is complete and parked (both diffs apply strictly on HEAD; all 33 pass on the s422 tree, 23 with the model on, 8 in both passes, ground_check old-path). Nothing half-done. Next: the quiet-window run of depthreads_check with its pin (not run), and the two owed World parks it names (memory-under-model, wrecks-power) only if briefed.

## B-09 (2026-11-20): the arena pin list, complete, and one re-record it showed

Run on a copy of the EP's GW1a tree (s423) with `a-world-01`, `default-gate` and the flip (`world.json` mode `planet`): the whole World list (89 checks), **13 failed, all on the hand-made arena** (floor 5 rows, arena 2, brunt 1, craters 28, deepen 6, epoch 1, farsites 1, fill 8, ground 9, repeat 2, sea_rules 3, wall 2, street_axis 1). Each got `WorldPin.arena()`; the re-run of the 13 passes, except **`ground_check` 2 rows** (gen 1 planet matches, the hand-made world and a gen 1 turn hash as before window 2). Those are not the flip: the rows name a planet or the arena. With the 15 data files other directors change in GW1a (fight: brake, hitstop, kick, ladder, power; director: stick, swing, ai, interrupts, launch; input timing; combat; camera) put back to HEAD, `ground_check` passes, so **the hashes the check pins move with the play, not with World**. **Bisected (EP ruling: not a-world-01, default-gate or the flip):** with the default hook, `WorldPin.arena()`, `default.gd` and the flip all taken out the check fails the same two rows, so none of the three moves them; the data groups reverted alone do not fix it (fight + timing; director; combat + camera each leave both rows failing); fight + timing + director together fix it; director + brake, hitstop or kick alone do not, director + all three of brake, hitstop and kick do, director + ladder, power and timing do not. So it is the interplay of the director's data (ai, interrupts, launch, stick, swing) with at least two of fight/brake, hitstop and kick (all GW1a data). (The "ground check passed" in the EP's s424 log is the other check, "Ground check 138 checks over seeds", not World's `ground_check` with its `GROUND:` verdict.) (it was re-pinned before for the same reason, 2026-11-08). `ground-repin.diff` re-records its six hashes on the GW1a tree (it applies after `pins-gw1b.diff`, strictly): **a GW1b piece (EP ruling 2026-11-20): it is to be re-cut on the GW1b steps 1-19 stack right before the flip, and lands with Simulation's single golden re-record**. The six values now in it were taken on the GW1a tree + a-world-01 (World's s24), not on that stack, so they are provisional; it must be cut again if the tree changes before then (any data change by any director moves them). Records: `docs/world/runs/checks-gw1a/gw1b-arena-flip/`.

Not run in that window: `depthreads_check` (waits for the EP's quiet go; its pin is in `pins-gw1b.diff`) and the re-run of all 89 after the final edits (the 13, `planet_world_check` and `ground_check` were re-run; the other 74 are untouched by the edits and passed before).

**GW1a version of the re-pin (EP, 2026-11-20): `ground-repin-gw1a.diff`.** `ground_check` fails the same two rows on the EP's s424 GW1a tree alone, so CI's `world-checks --run` would go red on GW1a without it. The diff re-records the six hashes (the values are identical to the ones read on World's GW1b-flip tree, so the flip and `a-world-01` moved nothing); it strict-applies on a copy of s424 **without `pins-gw1b.diff`**, and `ground_check` then passes in full (`runs/checks-gw1a/gw1a-ground-repin/`). It lands with GW1a. `ground-repin.diff` (the GW1b version) is superseded in its values and conflicts with this one if both are applied: once this lands the GW1b stack needs only a re-cut of whatever moves on it, from its own tree. **No other World check moves for the same reason**: the full 89-check run on the GW1a tree plus the flip failed the arena rows (pinned by `pins-gw1b.diff`) and these two `ground_check` rows, nothing else.

**Status 2026-11-21: `pins-gw1a.diff` and `ground-repin-gw1a.diff` LANDED in GW1a (b0e20f9a, World's commits) and are removed from this folder. What stays is GW1b: `pins-gw1b.diff` (the arena pins and the reworded planet_world_check row) and `ground-repin.diff` (the GW1b version, only if something moves on the GW1b tree).**

**Re-cut on main b0e20f9a, 2026-11-21 (GW1b): `pins-gw1b.diff` is now 26 checks plus `pin.gd`** (the 25 and `memory_model_check`, which landed with GW1a after the first list; it starts a match with no planet). It strict-applies on main after `a-world-01.diff`. Run: the whole World list (89 checks) on main + a-world-01 + grant-simulation-sim + default-gate + this + the flip: 88 passed and `memory_model_check` failed 2 rows until it got the pin; with it 0 (`runs/checks-gw1a/gw1b-on-main-b0e20f9a/`). **`ground_check` passes on that tree with the GW1a re-pin alone, so nothing moved and the GW1b `ground-repin.diff` is deleted.** `depthreads_check` and `wrecks_check` also pass on main itself (`runs/checks-gw1a/main-b0e20f9a/`).
