# The collateral window for the run (World): a commit-ready patch, split by owner, parked, not applied

Built on main 20b95092 (re-cut 2026-10-17 on HEAD; the same changes as the 2026-10-16 draft on 992adcbb; the Tools diff is re-cut because `cases.json` moved). The design and the audit of the owner paths are in `docs/world/collateral-run.md`. **Not applied.** The EP routes the grants when the depth window is committed.

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
| `simulation-collateral.diff` | **Simulation** (grant needed) | `sim/core/state.gd` (`World.present`, `World.peopleLeft`, `Building.place`, `Building.plan`: 4 lines), `sim/core/hash.gd` (two conditional appends: written only when `present` differs from `pop0` or `peopleLeft` is set, so a versus hash is byte-identical: 4 lines) and `sim/core/mood.gd` (one token: the casualty impulse reads `normPeople`; **`mood.gd` is in `sim/core/`, so Simulation's**, not Encounter's) |
| `encounter-collateral.diff` | **Encounter** (grant needed) | `sim/director/launch.gd` only (one token: the chain's allowance reads `eventAllow` and `present`) |
| `tools-collateral.diff` | **Tools** (grant needed) | `tools/schemas/map.json` (a rule for `data/biomes/collateral.json`) and `tools/fixtures/cases.json` (five invalid cases: **same commit as the schema**, the self-test needs three a schema) |

Check before applying, in a **scratch export** (never the repo root):

```
git apply --check world-collateral.diff simulation-collateral.diff encounter-collateral.diff tools-collateral.diff
```

## Proof (a clean export of HEAD af5151b5 plus the four diffs, below-normal priority)

- `git apply --check` of each diff on HEAD 20b95092: ok (re-checked 2026-10-17 after Encounter's window 2); applied together they equal the scratch tree byte for byte. The gates below ran on af5151b5; **the full gate is run again in the one window when the owners say yes** (EP's order).
- `collateral_check.gd`: **0 failed** (16 checks: the tables equal the constants they replace; `present` and the budget; `peopleLeft` (a match with 100 left never loses more than 100); place and plan (118 buildings in 4 places, unique, the same every match); the hash appends; the owner scan).
- `node sim/core/tools/run-all.js --only=godot,golden`: **both stages passed** (`parity.gd` 309 s: the 9 golden matches' every per-tick digest and full-state checkpoint identical: **no golden moves**).
- `node tools/validate.js --self-test` 7518 of 7518; `node tools/validate.js` 0 errors, 0 warnings.
- The earlier full `run-all.js` (all 5 stages, including the 1000-match soak) passed on 992adcbb.

## The other parked patches (re-cut 2026-10-18 on HEAD f15d7de3)

The four diffs above were applied by the EP (971018e1). `nbody-after-collateral.diff`, `b-after-collateral.diff` and `c-after-collateral.diff` apply **in that order after `../interior-chain/interior-chain.diff`** (HEAD, then the interior chain, then these three: verified with `git apply` on a clean export, byte for byte the scratch tree). They stay parked until after the demo record, because they move the golden. What the re-cut changed:

- **N-body** (`mk_nbody2.py`): the stepFighter hook anchors on the function's header, so the pinned-body block comes before the interior chain's hook; on a tree with `sim/world/interior.gd` it also takes the launcher from `launcherOf` and passes `lodged = true` for a lodge or a capped end (so more than two bodies pin per body). `wall_check.gd` is updated for the lodgeHold default `auto` and the per-body pin (`holdT`); it failed on the N-body patch before (its default and its "body" case), now 0 failed.
- **B and C** (`mk_b_repo.py`, `mk_c.py`, with `../windows-bc/mk_wbc_lib.py`'s helpers): their `BRUNT_KEYS` anchors no longer end at the dictionary's closing brace (the interior chain's keys come after the wall slam's), so each inserts its keys where it always did.
- **Checks on the whole chain** (scratch import of HEAD plus all four): `interior_check`, `brunt_check`, `wall_check`, `collateral_check`, `bc_check`, `nbody_check`: 0 failed each. The full gate of the chain is for the window in which they are applied (they move the golden).
