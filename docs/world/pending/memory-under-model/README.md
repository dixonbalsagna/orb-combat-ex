# Park: a building remembers under the energy model (World, 2026-11-20; the real fault of the checks-gw1a re-class)

**Fault.** `repeatMarks` (Orb, homework 30: a send into a building already marked meets it one tier higher for each mark, up to two) was inert with the energy model on, which is Orb's real path. A mark raised only `tierAt`'s number; `_outcomePower` never reads a tier, so a repeat did the same damage as the first send. Found by re-reading `repeat_check` and `wall_hold_check` with the model on (`docs/world/pins-and-the-model.md`); `wall-hold-on`'s `repeatMarks` 2 did nothing on Orb's path. Runs: `docs/world/runs/memory-under-model/`.

| File | What |
| :--- | :--- |
| `memory-under-model.diff` | World's: `sim/world/brunt.gd` (`_memory`, one use in `_outcomePower`, `_memoryOff` for tests), `sim/world/tools/memory_model_check.gd` (new, `MEMORYMODEL`, in CI) and its line in `tools/world-checks.json`. No data, no grant. Applies strictly on HEAD |

## The rule

With the model on there is no tier to raise, so **a mark is one tier of the model's own step** (the level a tier is worth: `SimPower.tierShare` over the three steps between tier 1 and 4), and it shows as the building's weakening: it takes `energyTop ^ (-tierShare / 3)` of its mass per mark of the body's energy, **0.513 for one mark and 0.263 for two** (capped at `repeatMarks`). `_outcomePower` uses `massOf(b) x _memory(b)`; everything else about the model's ladder is unchanged (a body goes through while it has the mass in energy, the keep is `sqrt((E - m) / E)`, a held hit does `E / m` of the covered floors' strength, so the same send does `1 / 0.513` = 1.95 times then `1 / 0.263` = 3.80 times the damage). `massOf` itself, which collateral and the terror gain read, is not touched. No new number: it follows `power.json`'s own step, and Game Design's "one tier higher" in the model's words. With `repeatMarks` 0 (shipped: marks are not counted then) the factor is exactly 1.0 and nothing moves: **the golden is unchanged**.

## Result

| Gate | Result |
| :--- | :--- |
| `MEMORYMODEL` | 0 failed: marks do nothing with `repeatMarks` 0 (bit for bit); the factor is 0.513 and 0.263, capped; a send of 80 percent of a low tower's mass is held unmarked and goes through at one mark and at two, keeping 0.60 then 0.82 of its speed; a tall tower that holds at every mark takes **1.95x then 3.80x** the first send's damage; a house is gone through at every mark; a real `hit` marks the building and the next send meets it weaker. Negative control (`_memoryOff`): 5 rows fail |
| `power_world_check`, `brunt_check`, `interior_check` | 0 failed (the last two in both passes of checks-gw1a) |
| `repeat_check`, `wall_hold_check` (both passes, the re-cut rows) | 0 failed |

## Finding for Game Design (not a fault in the memory)

**Three sends of the model's energy do not bring a mass-15 tower down, with or without memory.** `wall_hold_check`'s 24 staged sends carry 1.7 to 3.9 against a mass of 15 (towers of 1,500 units: tall), and the memory makes them 7.7 then 3.9: a held hit does `E / m` of the covered floors' strength (0.11, then 0.22 and 0.43 of the first). That is the model's own design (`power-scale.md`'s table: a tall tower holds a base send), and "the second and third sends bring it down, tier for tier" (buildings.md section 9) holds on the tier ladder, not under the model for a tall tower. If three base sends should bring a tall tower down, the lever is Game Design's: the tower's mass, a bigger step per mark (a mark worth more than one model tier), or the damage a hold does. A low tower (mass 5) at 80 percent of its mass goes through at one mark.

## NEEDS FROM EP

- **Game Design**: the finding above, and whether a mark is one model tier (as built) or more.
- **Land** with the model's other World work in GW1b: it is inert until `repeatMarks` is above 0 (the `wall-hold-data` row of `wall-hold-split`, GW2), so it can land first.

## RISKS

- `_memory` reads `SimPower` (`energyTop`, `tierShare`), so a change to the model's level step changes a mark's worth; both are Simulation's data.
- The planner (`chainPlan`, `outcomeOf` via `tierAt`) meets the marked building through the same `_outcomePower`, so aims see the weakened mass; not separately measured.
