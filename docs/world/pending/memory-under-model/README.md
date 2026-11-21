# Park: a building remembers under the energy model (World, 2026-11-20; the real fault of the checks-gw1a re-class)

**Fault.** `repeatMarks` (Orb, homework 30: a send into a building already marked meets it one tier higher for each mark, up to two) was inert with the energy model on, which is Orb's real path. A mark raised only `tierAt`'s number; `_outcomePower` never reads a tier, so a repeat did the same damage as the first send. Found by re-reading `repeat_check` and `wall_hold_check` with the model on (`docs/world/pins-and-the-model.md`); `wall-hold-on`'s `repeatMarks` 2 did nothing on Orb's path. Runs: `docs/world/runs/memory-under-model/`.

| File | What |
| :--- | :--- |
| `memory-under-model.diff` | World's: `sim/world/brunt.gd` (`_memory`, `heldMul`, `sumS0`, both used in `_outcomePower`; `_memoryOff` for tests), `data/biomes/brunt.json` (`heldMul` **1.0**: off) and its schema, `sim/world/tools/memory_model_check.gd` (new, `MEMORYMODEL`, in CI) and its line in `tools/world-checks.json`. No grant. Applies strictly on HEAD |
| `memory-under-model-data.diff` | The GW1b data row: `heldMul` **2.0** (Game Design's lever, below). Off in the shipped data, on in the GW1b row |

## The rule

With the model on there is no tier to raise, so **a mark is one tier of the model's own step** (the level a tier is worth: `SimPower.tierShare` over the three steps between tier 1 and 4), and it shows as the building's weakening: it takes `energyTop ^ (-tierShare / 3)` of its mass per mark of the body's energy, **0.513 for one mark and 0.263 for two** (capped at `repeatMarks`). `_outcomePower` uses `massOf(b) x _memory(b)`; everything else about the model's ladder is unchanged (a body goes through while it has the mass in energy, the keep is `sqrt((E - m) / E)`, a held hit does `E / m` of the covered floors' strength, so the same send does `1 / 0.513` = 1.95 times then `1 / 0.263` = 3.80 times the damage). `massOf` itself, which collateral and the terror gain read, is not touched. No new number: it follows `power.json`'s own step, and Game Design's "one tier higher" in the model's words. With `repeatMarks` 0 (shipped: marks are not counted then) the factor is exactly 1.0 and nothing moves: **the golden is unchanged**.

## Result

| Gate | Result |
| :--- | :--- |
| `MEMORYMODEL` | 0 failed: marks do nothing with `repeatMarks` 0 (bit for bit); the factor is 0.513 and 0.263, capped; a send of 80 percent of a low tower's mass is held unmarked and goes through at one mark and at two, keeping 0.60 then 0.82 of its speed; a tall tower that holds at every mark takes **1.95x then 3.80x** the first send's damage; a house is gone through at every mark; a real `hit` marks the building and the next send meets it weaker. Negative control (`_memoryOff`): 5 rows fail |
| `power_world_check`, `brunt_check`, `interior_check` | 0 failed (the last two in both passes of checks-gw1a) |
| `repeat_check`, `wall_hold_check` (both passes, the re-cut rows), `bystanders_check` | 0 failed |
| golden | unchanged (checked without the floor-rise grant, which moves it on its own) |

## The held hit (Game Design's lever, 2026-11-20): `heldMul`

Game Design chose the lever for the finding below: **a held hit does 2 x E / m of the covered floors' strength** (`brunt.json heldMul` 2.0, model path only; a mark stays one model tier and a tower's mass stays 15). Built as: a body that is held (less energy than the tower's mass) stops in the building, so all its energy goes into the few floors it covers, **by what they were**: the hit is `heldMul x E / m x` the covered floors' **undamaged** strength (`sumS0`, new in `outcomeDmg`'s result), so each hit weakens them for the next (a floor breaks when a hit reaches its strength less 25 percent of what it has taken). With the damage taken from the floors' current strength (as the code did) the weakening cancelled out of the ratio and nothing accumulated: the first cut with `heldMul` 2 broke no floor in three sends of 1.7. `heldMul` 1.0 (shipped) is the old expression bit for bit. Houses (their own branch) and the through case are unchanged.

| Sends at a mass-15 tower, memory on (`repeatMarks` 2) | Standing floors of 20 after each |
| :--- | :--- |
| `heldMul` 1 (before): 1.7, 1.7, 1.7 | 20, 20, 20 |
| `heldMul` 2: 1.7, 1.7, 1.7 | 20, 20, **18** (the third) |
| `heldMul` 2: 3.4, 3.4 | 20, **18** (the second) |
| `heldMul` 2: 7.5 | **18** (the first, held) |

Exactly Game Design's arithmetic. In `wall_hold_check`'s 24 staged slams (real launches at 1,500-unit towers, sends of 1.7 to 3.9): **the covered floors of 24 of 24 towers are broken after three sends with the memory, 0 without it** (the tower stands: a hold breaks floors, and the core goes by its own rule). A low tower still holds unmarked and goes through at one mark, and houses are the same dict at `heldMul` 1 and 2 (`MEMORYMODEL`).

## Finding for Game Design: answered

The finding (three sends of the model's energy did not bring a mass-15 tower down) is closed by the lever above.

## NEEDS FROM EP

- **Land** with the model's other World work in GW1b: the code is inert until `repeatMarks` is above 0 (the `wall-hold-data` row of `wall-hold-split`, GW2) and, for the held hit, until the `heldMul` row (`memory-under-model-data.diff`) goes on; so the code can land first, and the data row with GW1b.
- **Simulation**: the `heldMul` row changes a held hit's damage on the model path (the hash where a body is held by a tower), so it flips in the GW1b window with the other data rows.

## RISKS

- `_memory` reads `SimPower` (`energyTop`, `tierShare`), so a change to the model's level step changes a mark's worth; both are Simulation's data.
- The planner (`chainPlan`, `outcomeOf` via `tierAt`) meets the marked building through the same `_outcomePower`, so aims see the weakened mass; not separately measured.
