# The collateral window for the run (World, 2026-10-16): built in scratch on main's HEAD, parked, not applied

The EP's brief: GO as in `docs/world/collateral-run.md`, in scratch, parked. Built on main 992adcbb. **Not applied.**

## What it does

| Ask (collateral-run.md) | In the patch |
| :--- | :--- |
| 5. The three tables in data, with the catastrophe kind | `data/biomes/collateral.json` and its schema: `budget`, `ceiling`, `eventAllow` (slide, chain, landslide, quake, **catastrophe**, zeros below tier 5), `meterNorm`. `collateral.gd` reads them (`_static_init`, so `WorldCollateral.EVENT_ALLOW[...]` still works for every reader); `eventAllow(kind, tier)` reads a tier or the table's last entry; `tier()` clamps to the table's length, so a fifth entry in the data (`data/fight/tier5.json`, Simulation's) extends it |
| 3. Shares of `stage.present` | `S.world.present` (set to `pop0` at `init`; a stage's setup sets it). `budget`, `ceilingLeft`, `beginEvent`'s allowance and the two `pop_refs` of `structures.gd` read it. The meters' norm and the mood's casualty impulse read `normPeople(S)`, which is `pop0` or `present` **by data** (`meterNorm`, "pop0" for now: Game Design's question) |
| 4. `ceilingLeft` with `peopleLeft` | `S.world.peopleLeft` (-1: no limit); `ceilingLeft` is the lower of the tier's ceiling and `peopleLeft - casualties` |
| 1. A building's place id and plan index | `Building.place` (the settlement index today) and `Building.plan` (its index in that settlement's plan), set in `terrain.gd`'s generation loop; not hashed |
| 2. The owner on every path | The audit is in collateral-run.md section 2. The patch adds the lint as a check: no call of `damageBuilding`, `damageArea`, `explode`, `collapse` or `startFail` passes a literal null (23 calls scanned in the chain, 20 on main) |

## Files

| File | What |
| :--- | :--- |
| `collateral.diff` | The window on main's HEAD: `collateral.gd`, `state.gd`, `hash.gd`, `terrain.gd`, `structures.gd`, `mood.gd`, `launch.gd`, the data file and schema, and `sim/world/tools/collateral_check.gd` |
| `collateral-tools.diff` | Tools' two lines: the map rule and five invalid cases. **Same commit as the schema** (the self-test needs three cases a schema) |
| `nbody-after-collateral.diff`, `b-after-collateral.diff`, `c-after-collateral.diff` | The parked N-body, B and C patches re-cut to apply **after** this one (they all edit `collateral.gd` and `hash.gd`): `eventKinds()` reads the data's key order where the N-body patch had a constant; B and C are unchanged but for a hunk offset. Apply order: `collateral.diff`, `nbody-after-collateral.diff`, `b-after-collateral.diff`, `c-after-collateral.diff`; verified with `git apply` on a clean export of HEAD (byte for byte the scratch tree) |
| `mk_collateral.py`, `mk_nbody2.py`, `collateral_check.gd`, `collateral_fixture_cases.json` | The scripts that made them and the check |

## Lines in files that are not World's (need the EP's grant)

`sim/core/state.gd` (`World.present`, `World.peopleLeft`, `Building.place`, `Building.plan`), `sim/core/hash.gd` (two conditional appends: written only when `present` differs from `pop0` or `peopleLeft` is set, so a versus hash is byte-identical), `sim/core/mood.gd` (one token: `normPeople`), `sim/director/launch.gd` (one token: `eventAllow` and `present`), `tools/schemas/map.json` and `tools/fixtures/cases.json` (Tools').

## Proof (scratch, clean export of HEAD plus the patch and the Tools diff, below-normal priority)

- `collateral_check.gd`: 0 failed (16 checks: the tables equal the constants they replace; `present` and the budget; `peopleLeft` (a match with 100 left never loses more than 100); place and plan (118 buildings in 4 places, unique, the same in every match); the hash appends; the owner lint).
- `node sim/core/tools/run-all.js`: **all 5 stages passed**, including `parity.gd` (every per-tick digest and full-state checkpoint of the 9 golden matches identical: **no golden moves**), the 1000-match soak and `validate.js --self-test` 7518 of 7518.
- The whole chain (collateral, N-body, B, C) on one tree: `collateral_check`, `nbody_check` and `bc_check` all 0 failed.
