# The planet stack on main b0e20f9a: order, re-cuts, and one World run per stage (World, 2026-11-21; EP order)

Built on clean copies of main after GW1a landed, stage on stage in landing order. Each stage is one run of the whole World list (`tools/world-checks.json`) at below-normal priority, one Godot at a time; records in `docs/world/runs/planet-stack-recut/`. Nothing here is landed.

## Stage 1, GW1b (91 checks)

| Order | Park | Result |
| :--- | :--- | :--- |
| 1 | `a-world-01/a-world-01.diff` | applies as is |
| 2 | `a-world-01/grant-simulation-sim.patch` | applies as is |
| 3 | `a-world-01/default-gate.diff` | applies as is |
| 4 | `checks-gw1a/pins-gw1b.diff` (re-cut 2026-11-21: 26 checks + `pin.gd`) | applies |
| 5 | `bystanders-gw1b/bystanders-gw1b.diff` | applies as is |
| 6 | `floor-rise/grant-simulation-floorfor.patch`, then `floor-rise.diff` | apply as is |
| 7 | `lake-places/lake-places.diff` (`lakeMax`), `grant-rendering-tile-water.patch` (Rendering's file), `lake-places-data.diff` | apply as is |
| 8 | `a-world-01/data-switches-gw1b.diff` (the flip, last) | applies as is |
| 9 | `floor-rise/floor-walk-probe.diff` (**new**) | see the red below |

**Red: `floor_walk_probe` (1 row, class: the floor rise's intended change; a check re-read, not a fault).** "No pop on the way out": the largest change of height in a tick on leaving the sea was 15.71 against a limit of 7.5 (the rise limit). With the floor rise the one-tick lift is the rise limit plus what the floor itself rose that tick (Game Design: the lift is uncapped, `docs/design/buildings.md`). The row now measures the change *beyond what the floor rose*: 2.73, within the 7.5; on main (and in the run without floor-rise) it is the same measure and passes. `floor-walk-probe.diff`, strict after the pins. After it: 0 failed. The rest (90 of 91), `memory_model_check`, the 26 arena pins and `floor_rise_check`, `lake_places_check`, `bystanders_check` pass.

## Stage 2, GW1c (96 checks)

| Order | Park | Result |
| :--- | :--- | :--- |
| 1 | `globe-step2/grant-tools-lint.patch` | applies as is |
| 2 | `globe-step2/globe-step2.diff` | **real re-cut**: it failed at `data/biomes/water.json:63` (GW1a switched the floor on: the new block goes after it) and `tools/world-checks.json:15` (the list moved). Re-cut with the two hunks moved; strict on main + stage 1 |
| 3 | `globe-step2/grant-simulation-field.patch` | applies as is |
| 4 | `planet-sizes/grant-simulation-sizes.patch`, `planet-sizes.diff` | apply as is |
| 5 | Rendering's `grant-world-field-size-key.patch` (the field memo, C-01) | applies as is |
| 6 | a meteor grant: **VFX's `planet-sizes-meteor` is the one that lands at GW1c** (EP, 2026-11-21: World's `grant-rendering-meteor.patch` is removed from the list); the scratch trees of these runs used World's only to compile: without one of them the project does not compile (`meteor.gd` has `const R_PLANET = float(SimConst.PLANET_NC) ...`, which is not a constant once the size is a variable) | applies as is |
| 7 | `gw1c-world/gw1c-world.diff` | applies as is |
| 8 | `gw1c-world/gw1c-world-fix.diff` | **real re-cut**: the landed `cache-determinism` form of the `geometry` key line and the fix's size tag are merged in one line (`..., (shift's exact bits), _sizeTag()`); strict on stage 2's tree |
| 9 | `store-parts/store-parts.diff` | applies as is |
| 10 | `box-key-20bit/box-key-20bit.diff` | applies as is |
| 11 | `crater-tiers/crater-tiers.diff` | **re-cut**: its check-list hunk failed (the list moved); the diff is now without it and **`grant-tools-crater-tiers.patch`** (Tools' file) carries the one line |
| 12 | `relief-cap-gw1c/relief-cap.diff`, `grant-tools-relief-cap.patch` (the data row `relief-cap-data.diff` **not** applied: it waits for the stills) | apply as is |
| 13 | `floor-rise/floor-walk-probe.diff` | applies (needs stage 1's) |
| 14 | `globe-step2/globe-check-pin.diff` (**new**) | see below |
| — | `cache-determinism/cache-determinism.after-gw1c-fix.diff` | **deleted**: it was the GW1c form of a diff that landed in GW1a; `gw1c-world-fix.diff` now carries the merge |

**Red: `globe_check` (2 rows, class: OFF-PATH by construction, a new check not in the GW1a pin list).** "An ordinary blow on a 960-radius special crater supersedes nothing (it could dig only 600)": the energy model lifts the ordinary dig cap. "A trench cut on from the coast carries the sea's level along its length" (36.35 against 0): water v2 and the floor are on. Both are written for the world before GW1a, like the nine checks of `pins-and-the-model.md`: `WorldPin.shipped()` at its start (`globe-check-pin.diff`). After it: 0 failed. `floor_walk_probe` is the stage 1 red (same fix). All other checks, including `size_check`, `relief_cap_check` and `tier_ratio_check`, pass (94 of 96 before the two fixes).

## Stage 3, GW2 (98 checks)

| Order | Park | Result |
| :--- | :--- | :--- |
| 1 | `lake-shore/lake-shore.diff` (the data row `lake-shore-data.diff` only checked: it applies) | applies as is |
| 2 | `lake-dig/lake-dig.diff` | **real re-cut**: gw1c-world changed the lake record's reach line (`38400 / F.N` is now `PLANET_NC x COL / 4 / F.N`), the one hunk that failed; merged by hand |
| 3 | `lake-dig/grant-tools-lake-dig.patch` | **re-cut** (the check list moved) |
| — | data rows (`lake-dig-data`, `crater-tiers-data`, `relief-cap-data`, `lake-shore-data`) | each applies on this tree (checked, not applied) |

One red: `globe_check`, the same 2 rows (the pin applies and clears them). Everything else passes, including `lake_dig_check` (with its building and edge rows), `lake_shore_check`, `lake_places_check`, `floor_rise_check`, `size_check`, `relief_cap_check`.

## Summary

- **Applied as is:** everything in stage 1; in stage 2, `grant-tools-lint`, `grant-simulation-field`, both planet-sizes grants, `planet-sizes`, the memo grant, `gw1c-world`, `store-parts`, `box-key-20bit`, `relief-cap` and its grant; in stage 3, `lake-shore`.
- **Re-cut:** `globe-step2.diff`, `gw1c-world-fix.diff`, `crater-tiers.diff` (+ a Tools grant for its line), `lake-dig.diff` and its Tools grant. **Deleted:** `cache-determinism.after-gw1c-fix.diff`. **New:** `floor-walk-probe.diff`, `globe-check-pin.diff`.
- **Reds, classed:** `floor_walk_probe` (the floor rise's intended change: the row re-read), `globe_check` (a new check, off-path by construction: pinned). No fault.
- Not built in these trees (other directors'): the Rendering and Simulation steps of the GW1b and GW1c lists (floorlift-rise, parity-lake-unpin, replay-sizes, step-up, Rendering's tile parks). The checks above are World's.
