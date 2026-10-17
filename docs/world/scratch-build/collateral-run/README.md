# The collateral window for the run (World): a commit-ready patch, split by owner, parked, not applied

Built on main af5151b5 (re-cut 2026-10-17 from the 2026-10-16 draft on 992adcbb; the same changes). The design and the audit of the owner paths are in `docs/world/collateral-run.md`. **Not applied.** The EP routes the grants when the depth window is committed.

## What it does

| Ask | In the patch |
| :--- | :--- |
| The three tables in data, with the catastrophe kind | `data/biomes/collateral.json` and its schema: `budget`, `ceiling`, `eventAllow` (slide, chain, landslide, quake, **catastrophe**, zeros below tier 5), `meterNorm`. `collateral.gd` loads them in `_static_init` (so `WorldCollateral.EVENT_ALLOW[...]` still works for every reader); `eventAllow(kind, tier)` reads a tier or the table's last entry; `tier()` follows the table's length, so a fifth entry (`data/fight/tier5.json`, Simulation's) extends it |
| Shares of `stage.present` | `S.world.present` (= `pop0` at `init`); `budget`, `ceilingLeft`, `beginEvent` and the two `pop_refs` read it. The meters' norm and the mood's casualty impulse read `normPeople(S)`: `pop0` or `present` **by data** (`meterNorm`, "pop0": Game Design's question) |
| `ceilingLeft` with `peopleLeft` | `S.world.peopleLeft` (-1: no limit); the lower of the tier's ceiling and `peopleLeft - casualties` |
| A building's place id and plan index | `Building.place`, `Building.plan`, set in `terrain.gd`'s generation loop; not hashed |
| The owner on every path | The check `collateral_check.gd` scans for a literal null owner at every `damageBuilding`, `damageArea`, `explode`, `collapse` and `startFail` call (20 on main) |

## The patch, by owner (each applies to HEAD on its own; apply all four)

| File | Owner | Touches |
| :--- | :--- | :--- |
| `world-collateral.diff` | World | `sim/world/collateral.gd`, `structures.gd` (the two `pop_refs`), `terrain.gd` (place and plan), `data/biomes/collateral.json`, `tools/schemas/biomes-collateral.schema.json`, `sim/world/tools/collateral_check.gd` |
| `simulation-collateral.diff` | **Simulation** (grant needed) | `sim/core/state.gd` (`World.present`, `World.peopleLeft`, `Building.place`, `Building.plan`: 4 lines) and `sim/core/hash.gd` (two conditional appends: written only when `present` differs from `pop0` or `peopleLeft` is set, so a versus hash is byte-identical: 4 lines) |
| `encounter-collateral.diff` | **Encounter** (grant needed) | `sim/core/mood.gd` (one token: the casualty impulse reads `normPeople`) and `sim/director/launch.gd` (one token: the chain's allowance reads `eventAllow` and `present`) |
| `tools-collateral.diff` | **Tools** (grant needed) | `tools/schemas/map.json` (a rule for `data/biomes/collateral.json`) and `tools/fixtures/cases.json` (five invalid cases: **same commit as the schema**, the self-test needs three a schema) |

Check before applying, in a **scratch export** (never the repo root):

```
git apply --check world-collateral.diff simulation-collateral.diff encounter-collateral.diff tools-collateral.diff
```

## Proof (a clean export of HEAD af5151b5 plus the four diffs, below-normal priority)

- `git apply --check` of each diff on HEAD: ok; applied together they equal the scratch tree byte for byte.
- `collateral_check.gd`: **0 failed** (16 checks: the tables equal the constants they replace; `present` and the budget; `peopleLeft` (a match with 100 left never loses more than 100); place and plan (118 buildings in 4 places, unique, the same every match); the hash appends; the owner scan).
- `node sim/core/tools/run-all.js --only=godot,golden`: **both stages passed** (`parity.gd` 309 s: the 9 golden matches' every per-tick digest and full-state checkpoint identical: **no golden moves**).
- `node tools/validate.js --self-test` 7518 of 7518; `node tools/validate.js` 0 errors, 0 warnings.
- The earlier full `run-all.js` (all 5 stages, including the 1000-match soak) passed on 992adcbb.

## The other parked patches, after this one

`nbody-after-collateral.diff`, `b-after-collateral.diff`, `c-after-collateral.diff` apply **in that order after the four above** on HEAD af5151b5 (checked 2026-10-17: they apply as they were cut). `mk_collateral.py`, `mk_nbody2.py` and `collateral_fixture_cases.json` are the scripts and cases that made them.
