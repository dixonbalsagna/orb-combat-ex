# The wall slam, breaches and the failing state: built in scratch and parked (World, 2026-10-12)

Owner: World and Environment. **Nothing here is in the tree**: Simulation holds the sim tree. Everything is three cumulative patches (made on 60f82149, applied clean on c13deb6b) in `docs/world/scratch-build/windows-bc/` (`stage-w.diff`, `stage-b.diff`, `stage-c.diff`, the scripts that make them `mk_w.py`, `mk_b.py`, `mk_c.py`, `mk_wbc_lib.py`, `struct_fail.gd.txt`, and the check `bc_check.gd`). Each is its own window with one golden when applied. A fresh checkout takes `git apply stage-w.diff`, then `stage-b.diff`, then `stage-c.diff` (checked: the three give the same files as the scripts).

**Status 2026-10-12 (late): stage W is applied to the tree** (on 66a3cf27; golden regenerated and unchanged, as no golden match touches a building). One change from the patch as parked: **the stagger counts down on every live tick, flight included, and not in the hit-stop** (Simulation's condition), so it is set to the flight to the ground plus `wallStaggerTicks` (`_flightTicks`): he is staggered 24 ticks after he lands, as a max, never assigned or lowered. `stage-w.diff` is regenerated to match; `stage-b.diff` and `stage-c.diff` still apply on it. B and C wait.

## 1. What each stage is, and the lines in other directors' files

| Stage | What | World's files | Lines in Simulation's files |
| :--- | :--- | :--- | :--- |
| **W** the wall slam | A body held at a wall takes the building's hit again over (`wallSlamMul` 2.0) and is staggered (`wallStaggerTicks` 24); `building_hit.outcome` "wall" for a held hit; the `lodge` event; `lodgeHold` switch | `brunt.gd`, `data/biomes/brunt.json`, its schema | `state.gd`: `FxEvent.hold`; `fx.gd`: `SimFx.lodge`; `hash.gd`: FX_FIELDS `lodge` |
| **B** breaches | A punch breaks a run of the story (`Building.fhole`); the story is gone at 0.7 of the width; `floor_hit` carries `x0`, `x1` | `brunt.gd` (`punchFloors`), `blast.gd`, `structures.gd` (stage), data, schema | `state.gd`: `Building.fhole`, `FxEvent.x0`; `fx.gd`: `floorHit` and `floorHitShot` take `x0`, `x1`; `hash.gd`: the `fhole` array, `floor_hit` fields |
| **C** the failing state | A spent or pancaked tower comes down over seconds: a warning, then a floor a step; the falling stack hurts (switch); `building_failing` | `structures.gd` (`startFail`, `stepFailing`), `brunt.gd` (pancake), `probe.gd` | `state.gd`: `Building.failT, failK, failDir, failBy, failN, failHurt`, `FxEvent.t_warn, t_fall`; `fx.gd`: `SimFx.buildingFailing`; `hash.gd`: the five names, the `failHurt` array, FX_FIELDS `building_failing`; `sim.gd`: one line, `WorldStructures.stepFailing(S, dt)` after `SimShots.step` |

Simulation said yes to `stunTicks` (W sets it from `brunt.hit`). Nothing else of the fighter or the director is touched. The fx-events doc (`docs/architecture/fx-events.md`, Simulation's) needs the rows in section 3.

## 2. The values used

- **The wall slam** (Combat's number is Game Design's value in `docs/design/buildings.md` section 2, "He takes twice the building's hit"): `wallSlamMul` **2.0**, a data key; one line in `hit` reads it. The stagger is Game Design's **24 ticks** (`wallStaggerTicks`). The attacker's first move after 45 ticks is Encounter's (the approach lock, `brawl-second-pass.md` section 14); I do not touch it.
- **The warning:** `failWarn` 1.5 s (Game Design: at least 1.5), and **0.6 s over any hold a fighter under the tower is in** (`failWarnOver`; the holds read are `stunTicks`, `embedT` and the sim's hit-stop).
- **The fall:** at least `failMin` **2.0 s**, a floor at most each `failStep` 0.25 s (so a 14-floor tower takes 3.5 s, a 5-floor one 2 s).
- **The stack:** `failDamageFloor` 6 a floor on a fighter inside the footprint and `failBesideBh` 0.5 bh beside it (and within `failReachZ` 4 bh in depth), `failDamageCap` 100 from one building, buried `failBuryTicks` 45. **Which way it tips:** a hit inside the footprint that is `failTipAt` 0.5 of the half width or more off the middle tips it toward the breach; a blow from beside it, within `failTipFar` 3 half widths, pushes it over away from the blow; a farther one leaves it to fall in place (a pancake). A tipping stack is thrown `failTipReach` 0.4 of its height to its side (at most `failTipMaxBh` 6).

## 3. The events, in fx-events.md terms

| Event | Fields | When | Reads it |
| :--- | :--- | :--- | :--- |
| `lodge` **(new)** | `actor` (slot), `b`, `x`, `y`, `z`, `hold` (seconds), `n` (the chain's link), `owner`, `victim` | A body ends inside the last building of a chain (right after its `building_hit`); `hold` is the tier's lodge seconds | Camera (hold the frame), VFX (the dust in the breach), Audio |
| `building_hit` | `outcome` **adds `"wall"`**: a building that holds him (the floor_hit says crack or dent). A lodge stays a `building_hit` that passes (outcome punch, collapse or pancake) with `keep` 0, and is followed by `lodge` | Every brunt | VFX: `debris.burst_through` and `_on_building_hit` test `outcome != "crack"` for the exit side: **"wall" must be treated like "crack"** there |
| `floor_hit` | adds **`x0`, `x1`**: the breach on the lowest floor hit, world x (0, 0 for a crack or a dent) | A punch; a shot through floors | VFX (dust and glass at the hole), Rendering (the breach is in `fhole`) |
| `floors_fall` | as today; **one per landed floor** with the failing state (`from` and `to` the same floor, `n` 1) instead of one per pancake | Each step of a failing tower | Rendering, VFX, Audio |
| `building_failing` **(new)** | `b`, `x`, `y` (ground), `w`, `h` (standing height), `t_warn`, `t_fall` (seconds), `n` (the tip: -1, 0, 1), `owner`, `kind` | Once, when a tower starts to fail | Camera (the relay of stages), Audio (the groan), Rendering |
| `hazard_telegraph` | exists: `source` **"collapse"**, `eta` the warning, `x`, `actor` the fighter under it | At the same moment, once for each fighter in reach | the AI's danger read, UI |
| `building_stage`, `building_fall` | unchanged; the fall's `mode` is "implode" at the end of a failing tower | | |

Rendering reads the **state** directly (a pure function of hashed state, so a seek or a late join agrees): `Building.failK` (the lowest floor not yet landed; -1 standing), `failT` (negative: the warning; zero and above: the fall), `failDir`, `failN`, and `fhole`.

## 4. The names Rendering may change: one table

| Name | Meaning | Used in |
| :--- | :--- | :--- |
| `Building.fhole` | two floats a floor: the breach's centre (a fraction of the half width, -1 to 1) and its share of the width | `state.gd`, `hash.gd`, `brunt.gd` (`punchFloors`, `outcomeDmg`), `structures.gd` (`_holed`) |
| `Building.failK`, `failT`, `failDir`, `failBy`, `failN`, `failHurt` | the failing state (above) | `state.gd`, `hash.gd`, `structures.gd`, `brunt.gd` |
| `FxEvent.x0`, `hold`, `t_warn`, `t_fall` | the new event fields | `state.gd`, `fx.gd`, `hash.gd` |
| event types `lodge`, `building_failing`; `outcome` "wall" | | `fx.gd`, `hash.gd`, `brunt.gd` |
| data keys `wallSlamMul`, `wallStaggerTicks`, `lodgeHold`, `breaches` ... `failTipMaxBh`, `failHurts` | | `data/biomes/brunt.json`, `tools/schemas/biomes-brunt.schema.json` |

A rename is a text replace in those files (each name is used in at most five places); the scripts take them from this table.

## 5. Orb's homework: three switches, each at today's behaviour

| Question | Switch (`data/biomes/brunt.json`) | Default (today) | Other values |
| :--- | :--- | :--- | :--- |
| Does a lodge freeze the whole fight or only the lodged fighter? | `lodgeHold` | **"world"**: a hit-stop of the whole sim | "body": the sim goes on and the body is stunned for the seconds |
| Does a tower hold early on? | `towerPunches[0]` (window A) | **0**: a tier-1 body is held by an intact tower | 1: through one tower |
| Does a falling building hurt both fighters? | `failHurts` | **"none"** (no falling stack hurt anyone before) | "both" (Game Design's ruling in buildings.md), "rival" (only the one who did not bring it down) |

Nothing else depends on the answers. With `failHurts` "none" the failing state still warns and falls, the people still die as the floors land, and no fighter is hurt; the number of fighters hurt in a match with "both" is below.

## 6. Known fault, noted for the record

**A crater in the middle street shows in the front street.** The ground is one plane while depth is off (and Rendering draws the terrain rows only with T on): a crater dug by a fight in the middle street is seen in the front street. Not new and not fixed here; it goes away with the depth windows (T's depth rows are the ground per row).

## 7. Measured, in scratch (30 matches from the crossing start, seeds 1 to 30, HEAD against HEAD with W, B and C)

| | HEAD | W + B + C |
| :--- | ---: | ---: |
| Structures lost a match | 44.6 | 45.8 |
| People lost | 24.1% | 23.2% |
| Length | 471 s | 471 s |
| Towers that fail a match | 0 | 10.5 (warning 1.5 s, the fall 3.3 s on average) |
| Floors that land a match | 0 (all at once) | 131 |
| Body hits a match | 1.7 | 2.2 |
| Held at a wall a match (wall slams) | 0.7 (cracks and dents) | 0.9 |
| Chains of two buildings or more | 0.27 | 0.43 |
| Fight time within 1,500 units of a building, first 30 s | 81% | 80% |

The failing state moves what happens to the buildings, not how many go down (44.6 to 45.8) or how many people die (24.1% to 23.2%): the people die floor by floor as it falls. **Fighters hurt by a falling stack** (`failHurts` "both", 30 matches, fighters that never move away): **1.4 a match**, 36 damage each on average, 62% of the failures tip. Game Design's band is 0.2 to 1 "rare and remembered"; the fighters here are oblivious (the AI does not read `hazard_telegraph` today), so this is an upper bound: with the AI leaving when it is warned (Encounter) and a player who hears the groan it comes down. The knobs are `failBesideBh`, `failReachZ`, `failTipAt`, `failTipReach`. Gates in the scratch tree: probe 0 failed (its three blast checks read the fallen building, so they settle the failing state first), `brunt_check`, `probe_collide`, `stagecheck`, `blockcheck`, `directcheck`, `minecheck`, `isect_check`, `depthreads_check` 0 failed; render stage, shape, ground, patch, depth and VFX effects checks pass; the flash count passes (collapse 67 building falls, mashcity as before); `bc_check.gd` (25 checks: the wall slam is twice the hit, the lodge event, breaches add up and clear, a spent tower warns 1.5 s and falls over at least 2 s, a floor lands each step, the warning is 0.6 over a hold, the three `failHurts` values, `failing` 0 is the old tick).
