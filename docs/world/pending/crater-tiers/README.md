# Park: A-WORLD-06, crater width by tier, with its ratio check (World, 2026-11-14; EP order, Game Design's ruling in docs/design/buildings.md section 6.2)

The rule, the numbers and what the check asserts: `docs/world/crater-tiers.md`. Runs: `docs/world/runs/crater-tiers/`.

| File | What |
| :--- | :--- |
| `crater-tiers.diff` | `sim/world/crater.gd` (`impactEnergy` reads the table with the model off), `sim/world/blast.gd` (`craterEnergy`: a shot's crater energy, the table with the model off; with the model on the kind's base times 12.25 to the level **only if `shotModelOn()`**, which reads `blast.json shotModel`, absent or false in the shipped data, so with the model on it is `tierEnergy[tier]` as before), `sim/world/craters.gd` (`tier` block: `tierOn`, `tierEnergy`, `tierTable`, `setTier`, loader and validation), `data/biomes/craters.json` (`tier`, **on false**), its schema, `tier_ratio_check.gd` (new, in CI through `tools/world-checks.json`), and two checks made either-state (`power_world_check`, `meteor_crater_check`). World's files only: no grant. **Stands on the stack** (after globe-step2 and gw1c-world; the `craters.json` and shared-list hunks sit beside theirs) and after `wall-hold-split` (it edits `crater.gd` too, in other lines) |
| `crater-tiers-data.diff` | **Row A, the table**: `craters.json tier.on` true and `blast.json tierEnergy` 1, 2.1, 4.3, 9 (shots use the table too, with the model off). A crater-size change with the model off: flips with the other crater rows in a hash window |
| `crater-tiers-shots-data.diff` | **Row B, the shot rule** (**new, 2026-11-23**): `blast.json shotModel` true (one line after `_about`, so it applies with row A in either order). Until it lands, the code below is off: with the energy model on a shot's crater is the kind's base times `blast.json tierEnergy[tier]` exactly as the 9 November build and main have it |
| `grant-tools-crater-tiers.patch` | Tools' check-list line for `tier_ratio_check` |

## Result

| | |
| :--- | :--- |
| Model off, table | tier 4 digs **3.000** times tier 1 (3.0 within 5 percent); tiers 2 and 3 dig 1.449 and 2.074 (1.45, 2.07) |
| Model on | a fresh base fighter's full send digs 356, a top-tier one's 1,245: **3.50 times** (at least 3); tier 4 over tier 1 at equal power **2.72** at power 0, and inside 2.5 to 3.5 at 25, 50, 75 and 100 |
| Shots, model on (GD's ruling) | each of the six kinds: base at level 0, **3.50 times** the radius fresh base to full top, 2.72 tier for tier; the table is not read |
| Table off (shipped) | today's 25 percent a tier: E 1.75 and 1.323 times the width at tier 4. **Nothing moves with the shipped data**, **and the shot rule under the model is off with it**: `TIERRATIO` proves that with the model on a shot's crater is the kind's base times `tierEnergy[tier]` for every kind at every tier, and that the rule on is not that |
| `TIERRATIO` | 0 failed on the shipped data and on the flipped data; negative control (the code before this park): 3 FAIL; shot control (`craterEnergy` ignoring the model): 2 FAIL |
| The 15 impact-related World checks on the flipped data | all pass (`power_world_check` and `meteor_crater_check` after being made either-state); the table is read by nothing else |
| `validate`, golden | schemas clean; golden unchanged (the table is off) |

## NEEDS FROM EP

- **The split (C-02 of the GW1c readiness review; the path to the first Alpha build):** (a) the code and the check land in GW1c with **nothing that moves on Orb's path**: the model-off table is off, the shot rule is off, the golden does not move. (b) **Row A** (the table: a crater-size change with the model off) and **row B** (the shot rule: moves the energy-on golden, shot craters read 12.25 to the level instead of `tierEnergy`) are separate rows in later hash windows. **Before row B flips:** the World checks and Simulation's gates on the post-GW1b data, and a side-by-side of a top-tier shot's crater against the 9 November build (Rendering). Row B is Orb-visible: Game Design ruled it, and it lands with a look taken.

## RISKS

- Two checks assumed the 25 percent term: `meteor_crater_check` is pinned to it (its numbers were taken there), `power_world_check` reads the table when it is on. A check written later that assumes a tier-4 impact is E 1.75 will go red on the flipped data.

**Re-cut on main b0e20f9a, 2026-11-21** (`docs/world/planet-stack-recut.md`, records `docs/world/runs/planet-stack-recut/`): `crater-tiers.diff` re-cut without its check-list hunk; the line is `grant-tools-crater-tiers.patch` (Tools).
