# Park: World's check pins for GW1a and GW1b (World, 2026-11-14; EP briefs of 11-13 and 11-14)

When the data goes on (GW1a: the 9 November build's switches, and Simulation's energy model and dash) and then the default world moves to the round planet (GW1b: A-WORLD-01), World's checks that pin the old shipped values or the hand-made arena go red. This is the patch that keeps them testing the old path. Checks only; **no sim file, no data file**. Runs: `docs/world/runs/checks-gw1a/`.

| File | What |
| :--- | :--- |
| `pins-gw1a.diff` | `sim/world/tools/pin.gd` (`WorldPin.shipped()`) and one line at the top of `_init` in 33 checks. Stands on HEAD def3445a (`git apply --check` clean) |
| `pins-gw1b.diff` | `WorldPin.arena()` and one line in 11 more checks. Stacks after `pins-gw1a.diff` and after `a-world-01` (it calls `WorldDefault`) |

## How a pin works

`WorldPin.shipped()` sets, in this process's memory only, the values main shipped before GW1a: `climate.json` gen 1, water v2 off (enabled, surface, floor, flowWarm 0), contact settle off, field plans everywhere off, the arena's calm turn off (`rings.json turn.on` 0, `interrupts.json` calmTurn and water), the planner not reading the ground, and the energy model and the dash off (`SimPower`). Each module's data is loaded first, so a module that loads on its first call does not write the file's values back over the pin. It is the check-side form of what Simulation's `energy-on` asks ("pin `power: false` to keep testing the off path"), done once for all of World's checks. `WorldPin.arena()` sets the default world back to the hand-made arena (`WorldDefault.setForTest`). A check that tests the new default does not call either; one that tests the old path calls one first.

## Which go red from what (the split you asked for)

Measured on scratch trees of HEAD: GW1a's World rows alone (no energy model); the same rows with Simulation's `energy-on`; the rows plus the mode flip.

| Source | Checks |
| :--- | :--- |
| **GW1a's World rows alone** (23) | `floor_check` 3, `arena_check` 2, `climate_check` 2, `power_world_check` 1, `epoch_check` 5, `far_check` 2, `farmap_check` 1, `farsites_check` 1, `field_water_check` 1, `field_lot_check` 3, `fill_check` 2, `gen2_state_check` 5, `ground_check` 5, `lakes_check` 1, `land_check` 1, `planet_check` 3, `ringpick_check` 3, `sea_rules_check` 2, `sites_check` 1, `surface_check` 2, `street_axis_check` 4, `water_warm_check` 1, `struggle_meet_check` 1 (the number is failing rows; every one pins a shipped value, a generation, or a hash recorded on the old data) |
| **Only with the energy model and the dash** (9, and `wrecks_check`) | `brunt_check` 6, `craters_check` 1, `deepencheck` 1, `interior_check` 3, `repeat_check` 1, `meteor_crater_check` 1, `wall_hold_check` 3, `struggle_dir_check` 1, `bystanders_check` 1; Simulation's list adds `ground_check` 2 and `wrecks_check` 1, which `wrecks_check` is pinned for but not run (it wants the quiet window: about an hour on a loaded machine) |
| **Only with the mode flip** (GW1b, 11) | `lane_check`, `after_check`, `control_check`, `demostart_check`, `planet_world_check`, `skate_check`, `surface_follow_check`, `fire_check`, `ground_props_check`, `isect_check`, `floor_walk_probe`: each assumes a setup with no planet plays the hand-made arena |

Not in the split: `step_check`'s timing line fails under load whatever the data (passes alone), and `wrecks_check`, `depthreads_check` are the two slow ones.

## Proof

| | Result |
| :--- | :--- |
| The 32 checks, unpinned, on HEAD with the GW1a rows and `energy-on` | 32 red; the other 51 of 83 pass (`before-the-pins-on-GW1a-rows-and-energy-on.txt`) |
| The same 32, pinned, on the same data | **all 32 pass** (`with-the-pins-on-GW1a-rows-and-energy-on.txt`) |
| The same 32, pinned, on today's main data | **all 32 pass**: a pin is a no-op where the data is the old data, so the patch can land before the data (`with-the-pins-on-todays-main-data.txt`) |
| The 11 mode-only checks with `WorldPin.arena()`, on the GW1a rows and the planet default | all 11 pass |
| Not covered | `wrecks_check` (pinned, not run), `depthreads_check` (not run on the new data), and the energy model's own re-read rows: the pins keep the off path; a row that should read under the model (the tier ladder at the model's numbers) is a separate job for Encounter and Game Design |

## NEEDS FROM EP

- Land `pins-gw1a.diff` with or before GW1a; `pins-gw1b.diff` with A-WORLD-01 (the first step of GW1b).
- A quiet window for `wrecks_check` and `depthreads_check` on the new data.
- Whether any of the pinned checks should instead be re-read under the new default (the pin hides nothing: each pinned row still tests the path it was written for, and nothing else tests the new path yet). The new default's own checks are `world_default_check` and `size_check`.

## RISKS

- A pin changes memory, not files: a check run in the same process after another that pinned sees pinned data (each check is its own Godot process in CI, so it does not).
- `WorldPin.shipped()` reaches into five modules' data (World's, the director's, the planner's, Simulation's power). If one of them changes how it loads, the pin must follow; `pins-gw1a` carries the check that would show it (each pinned check fails against a moved value).
