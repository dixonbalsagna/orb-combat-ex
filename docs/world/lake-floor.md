# The floor of a lake or the sea (World, 2026-10-30)

Owner: World and Environment. Ruling: Game Design `docs/design/rulings-2026-10-30.md` (rows 1 to 8). Switch: `data/biomes/water.json` `floor.enabled` (off). Code: `sim/world/water.gd` (`floorAt`), `sim/world/fill.gd` (`floorOn`, `wadeBelow`, `wading`), `sim/world/terrain.gd` (`seaAt`), `sim/world/contact.gd` (the surfacing, the replay header). Checks: `sim/world/tools/floor_check.gd`, and `floor_walk_probe.gd` with the grant.

## What it does

A fighter under his own control stands on a floor at `surface - feet`, where `d` is the depth of the ring's own water at his column and `feet = max(0, min(d, wade.below - d))`. With `wade.below` at 75:

| depth `d` | feet | floor |
| :--- | :--- | :--- |
| 0 to 37.5 | `d` | the bed (the ground) |
| 37.5 to 75 | `75 - d` | rising out of the water (`ground + 2d - 75`) |
| 75 and deeper | 0 | the sheet (the surface) |

The curve has no step: `floorAt` is continuous across a column boundary and along the shore (`floor_check` scans every unit of x on the hand-made world and every 2 units on 14 gen 2 rings, and finds none). Tundra's 46-deep column puts 29 of him under the sheet.

- **`WorldWater.floorAt(S, x, z)`** is the ground to the bit with the switch off. With it on, it is the ground in dry columns and the curve in the ring's own water.
- **The ring's own water** is the sea and its shallows (the original ground under `SHORE_WET`), a planned lake and a river (`S.planetRing["lakes"]`). A fill a fight dug (water v2, a flow into a crater) is not: the floor never lifts or holds a fighter in it (rows 5, 14, 15), and a fill in `floor_check` leaves the floor at the ground.
- **Depth is measured from the undug bed** (`WorldWater.undugAt`, the ring's original ground), as row 5 does for fills. A straight-down launch digs a crater about 300 deep in a lake and the lake refills level over it; measured from the dug ground that counts the hole as water, and he popped 327 to 388 a tick about 1.4 s later (Encounter's measurement). Now a crater leaves his floor where it was (he stands over the hole, as he would over a fill), and a berm still lifts it: the floor is never under the actual ground.
- **The level** is read between the two nearest columns, a dry column counting as its ground, so the floor is continuous. On the sheet it is `WorldWater.seaTop`'s value to the bit when the two are within 0.001 (float32 columns of one flat lake differ by a few 1e-4): a fighter standing on the sheet is never "below" the surface a rule asks about (`y < seaTop`).
- **Rules measured from the ground stay measured from it.** `groundY` is untouched: a power-up's crater (`y < g + 140`), a launch's landing and the crater a slam digs all still read the bed.

## The sea (rows 7 and 8)

The sea is the same floor with no special case. The sea and its shallows are the ring's own water (`nativeLevel`: the original ground under `SHORE_WET`), so a beach wades in to the waist (37.5), rises out of the water over the next 37.5 and from 75 down stands on the sheet, which on the open sea is `SEA_LEVEL`, 0. `floorAt` is the ground to the bit with the switch off; on, it reaches every world: gen 2, gen 1 and the hand-made world ("one switch, every world"). Nothing is added to a world's state, so the hash of a ring moves only through the replay header (`floor`, `wade`).

- **Depth is measured from the undug bed**, as for a lake: a crater dug into the sea's bed or into its shallows leaves his floor where it was (`floor_check`: 300 deep in the open sea and in 41-deep shallows). A bay dug on dry coast and filled by the sea is a fill, never the ring's water (row 5), and the floor there is its ground.
- **A sea column 75 or more deep is sea to the rules in every world.** `seaAt` and `seaTop` read a column of `seaMin()` or more as sea only where `WorldGround.live()` (a gen 2 world); the hand-made world's shore slope (ground between `RESERVOIR_BASE` and the beach, 68 columns 75 to 240 deep) was water the floor put him on the sheet of and no rule called sea. `WorldWater.deepIsSea()` is `floorOn() or live()`, so with the floor on the sheet he stands on is the surface those rules ask about, in every world. Off, `seaAt` is the open sea there as it always was (`floor_check` reads every column).
- **A burial reads the water before the dig.** The slam's embed gate read `burialOK` after `WorldCrater.dig`, when the hole has not refilled: the level there was the new ground plus the old water, a depth of 0, and a slam into 50-deep shallows embedded him. It now reads it before the dig (`burial_check` slams a real special launch straight down at the beach, 20, 50 and 90 deep and the open sea, with the floor off as the control: it embeds him at 20 deep and nowhere beyond 37.5, and in the sea he comes up to the sheet standing, with no down state).
- **Checks.** `floor_check` reads the hand-made world's sea rules, the craters and the bay, and 8 gen 2 rings with an open sea (4,255 sea columns 75 or more deep, 515 shallower); `burial_check` the beach and the sea; `floor_walk_probe` a walk from the hand-made world's beach out over the sea; `gen2_soak --floor` counts the ticks over the sheet and the longest run below the floor, and `--sea` starts both fighters over the open sea.
- **Row 8 is not World's.** A finisher's `submerged` variant and the `submerged` band are Combat's (`data/combat/finishers.json`, `data/combat/styles.json`); the underwater-time cap is QA's row in `balance-targets.md` section 10. With the floor on a fighter under his own control is never below the surface, so the band is true only in a launch and the surfacing, as the ruling says.

## The threshold lines (row 4)

`wade.below` is the one line for a lake. With the floor on:

- `WorldTerrain.seaAt` and `WorldWater.seaTop` call a lake sea from `wade.below` (75), not `HIDE_MIN_DEPTH` (100, hiding's leftover). The hiding rule (`cover.gd`) keeps 100.
- `WorldFill.wading` reads `wade.below` even when water v2 is off (it returned false whenever the fill's switch was off). A column under 75 is waded, from 75 it is sea.
- A river is never deeper than 70, so it is always waded and never sea.

## Row 3: the surfacing

The floor needs both halves of the surfacing rule (rows 3 and 10): `surface.enabled` in `water.json` (a launched body is brought up) and `water.enabled` in `data/director/interrupts.json` (a drop is brought up and counts as landed). `WorldFill` reports a load error naming both (and the water module stays off) if `floor.enabled` is true without either; `WorldFill.floorProblem` is the check, and `floor_check` holds it. A launched body that goes into water that is not waded rises over `surface.ticks` ticks to the floor of its column instead of the surface (`WorldContact.moveAir`); it never rises above where it is, and the floor does not snap a body up: it applies once the surfacing ends. In water deep enough to surface a body the floor is the sheet, so this only differs on a lake's shoulder.

## A body under his floor (row 9)

A waded body that is below his floor (a drop's end or a get-up in water 37.5 to 75 deep: the floor is up to 65 above the bed there) rises toward it at most `WorldWater.riseMax` a tick: `wade.below / riseTicks`, 75 / 10 = 7.5 units, the surfacing's own rate over its full depth (`riseTicks` is Encounter's `interrupts.json` water.riseTicks, read through `DirWater.riseTicks` and the forward `SimDir.waterRiseTicks`). His height is the state; nothing is kept and he keeps the stick. The deepest lift takes 10 ticks and a 16-unit one takes 3. `floor_walk_probe` runs a real get-up and a real drop's end on the bed of a 60 to 70 deep shoulder (a 65.7 lift): 7.5 a tick over 9 ticks, ending on the floor; the control (`riseTicks` 1, no limit) lifts the whole 65.7 in one tick, the bug Simulation measured. An ordinary walk into the lake peaks at 5.57 a tick, under the limit.

## A burial needs the bed (row 11)

With the floor on, `WorldWater.burialOK(S, x)` is true only where the ring's own water at his column is under half of `wade.below` (37.5 deep), measured from the undug bed. `WorldContact` reads it at a slam's embed (the ordinary embed and MARSH SWALLOW's always-embed alike): deeper, no embed and no follow-up; the impact still digs the bed and he comes up by the surfacing or row 9, with no down state. A burial that has started keeps him on the bed until it ends, and if the deepened crater takes the water past 37.5 he rises by row 9 then. `burial_check` reads whether this ever takes a MARSH SWALLOW's embed away: MARSH SWALLOW is offered over mud and not over sea (`launch.gd`), so only a wetland column holding 37.5 to 75 deep of the ring's own water can lose it. On 54 gen 2 rings (planets 3 to 101, touches 0 to 3) 64 of 3,607 wetland columns do (1.8%): not the marsh's own water table (6 deep) but a lake or a bay inside a wetland, for example 47.5 deep (planet 42, touch 0). A further 59 wetland columns are 75 deep or more, which is sea with the floor on, where it is never offered.

## What changes the replay

`WorldContact.dataHash` folds `floor` and `wade` in when the switch is on, as it does `surface`. Off, no hash moves.

## The grant

Simulation's `sim/core/fighter.gd` reads the floor instead of the ground for a free, locked, rushing or placed fighter (`SimFighter.floorFor`), and not while he is dropped or launched or the water has him under after a drop (`SimDir.waterUnder`, a forward to `DirWater.under`: the core may not name a director class, and `load_split` catches it). The 0.55 water speed does not apply with the floor on. `floorFor` is also where row 9's rise rate lives, from the height his tick began at. The one Encounter line is `DirWater.riseTicks`, which the new forward `SimDir.waterRiseTicks` reads. The director's own lines that place a body or ask whether it stands on the ground (the closing steps, the rush targets, the knock-back's and the recoil's ground tests, the pair's placement) are Encounter's park, stacked on this one: each is `WorldTerrain.groundY(` to `SimFighter.floorFor(S, body, ...)` where it continues a body's own height, and to `WorldWater.floorAt(` where it sets a position; the core's clamps catch what they leave. See `docs/world/pending/lake-floor/README.md`.

## Props and the flood strip (Rendering's finding)

`WorldGround.propsIn` tested a column against the lakes only for the lone trees, so boulders, rocks and the rest stood in a lake's water and on the dry strip the water shader floods beside it. `WorldLakes.flooded` is that test (the lake's columns, and dry land at most `SHORE_FLOOD` (24) under its level within `SHORE_COLS` (16) columns of it: `GroundField.flooded`'s rule, with Rendering's two numbers copied and held equal by `props_wet_check`). `propsIn` leaves a flooded column out for every row, and a lone tree there is no candidate and so suppresses no neighbour. Every keyed draw is by column, so every other prop on the ring is where it was. On 9 gen 2 rings (planets 21, 7, 47, 3, 11, touches 3 and 0) 255 of 2,218 props stood in the water or on the strip; none do now. The ring's own trees (`S.trees`, `dryTrees`) are sim state and are untouched; a strip tree there would be a change to the world's state.

## Which World data moves a planet's world (for the replay header)

| | moves a planet's world? | header |
| :--- | :--- | :--- |
| `WorldLakes` (`lakes.json`) | Yes, always on a gen 2 ring: which valleys hold water, so `S.water`, `S.trees` (`dryTrees`), `planetRing["lakes"]` and which rivers fit | gen 2: fold it in |
| `WorldGround` (`ground.json`) | Yes, on a gen 2 ring: `layTrees` at the match's start (`S.trees`), and the grip, absorb, rough and furrow of every landing, the cover and the props | gen 2: fold it in |
| `WorldRingPick` (`rings.json`) | Only its `turn` block, and only while the calm turn is on for the setup (`WorldEpoch.enabled`): when and how the ring turns. The rest picks a run's ring before the setup exists; the setup records the arena it chose | the `turn` block, when `WorldEpoch.enabled(setup)` |
| `WorldWrecks` (`wrecks.json`) | No. Nothing outside tools calls it yet; once Encounter's pick and burst are wired it is combat data (the wreck's reach and burst damage), not the planet's world | with Combat's data, when wired |
| `WorldProps` (`props.json`) | No. Hold points for Animation; nothing in the sim calls it | none |
