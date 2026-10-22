# The shifting arena, window 1: the arena as a plane (World, 2026-10-19): in scratch on main's HEAD, parked, not applied

The design and the windows are `docs/world/shifting-arena-design.md`. **Nothing is applied.** The golden is unchanged with the arena at its default (the Whole, 4,800 columns).

| File | What |
| :--- | :--- |
| `planet-window2-recut.diff` | **Window 0**, planet window 2's draft re-cut on today's main (6 files: `sim.gd` (the planet branch and the start), `biomes.gd`, `planet_world.gd`, `planet_world_check.gd`, with `.uid`): a setup with a `planet` builds its world from the slice. Prerequisite of window 1. `mk_window2.py`, `planet_world.gd.txt` make it |
| `arena-window1.diff` | **Window 1**, on top of window 0 (11 files): `constants.gd` (`W`, `NC`, `HALF` statics, `PLANET_NC`, `setArena`) and `sim.gd` (Simulation's); `director/location.gd` (Encounter's: `STEP` follows the arena); `planet.gd`, `planet_world.gd`, `collateral.gd`, `structures.gd`, `planet_check.gd`, `planet_world_check.gd` (World's); `arena_check.gd` (new, + `.uid`). `mk_arena.py` makes it |
| `arena_check.gd.txt`, `bench_arena.gd.txt` | The check and a speed bench (4 default AI matches of 3,600 ticks) |

**Order:** window 0, then window 1 (`git apply --check` of both on the newest main: ok; the result equals the scratch tree byte for byte).

## What it does

A setup with a `planet` and `arena: {cols, side}` plays on a ring of the planet: `cols` 4,800 is the great circle (today's), 2,400 a Half, 1,200 a Close. The ring is the small circle through the picker's touch-down, tangent to the great circle there, on its left (`side` 1) or right (`side` -1); its radius is `cols / 4,800` of the planet's, so a column is exactly 32 units of arc and the ring closes. The arena's length is a static set by every `newMatch` (a match with no `arena` sets 4,800), and the planet's own size is a constant. `WorldPlanet` reads a ring with today's expressions to the bit when it is the great circle.

## Proof (scratch export of main's HEAD plus both patches; below-normal priority)

- **`arena_check.gd`: 0 failed.** The statics follow `setArena`, and the wrap and shortest arc with them. Rings of 2,400, 1,600, 1,200 and 600 columns are unit, closed (a gap under 0.01 unit), a column of arc apart (within 0.2%), tangent to the great circle at the touch-down, and zero lateral on themselves. The Whole slice is today's (hash `d0f86ade`, 4,800 columns); a slice of each size has its columns, its held places and the Whole slice's middle column. A place's lateral offset from the ring is its distance to the ring. **A match on planet 7, touch 3, seed 1 on 2,400, 1,600, 1,200 and 600 columns builds (71, 31, 20 and 17 buildings, about 1,800 people each), every building and fighter inside the world, plays 3,600 ticks and plays to the same hash twice.** An arena of 4,800 plays the same as none; a default match after a small one is the default world again (118 buildings).
- `planet_check.gd`, `planet_world_check.gd`, `brunt_check.gd`, `collateral_check.gd`, `interior_check.gd`: 0 failed.
- **The golden:** `node sim/core/tools/run-all.js`, all 5 stages passed (unit 13.8 s, parity 89.6 s, soak 18.3 s, golden 0.7 s, godot 290.2 s: the 9 golden matches' every digest identical); Rendering's 15 gates all passed; `node tools/validate.js` 229 files, 0 errors, 0 warnings; `--self-test` 8519 of 8519. (The first full run was before one function's engine `clampf` became `SimMathx.jclamp`, for planet.gd's lint; **`run-all.js --only=godot,golden` was run again on the final tree: both stages passed (golden 0.7 s, godot 284.5 s).**)
- **Speed:** four default AI matches of 3,600 ticks: HEAD 5,391 and 4,823 ms, with the patch 5,051 and 5,136 ms (a shared PC; no difference outside noise): a static read costs nothing measurable.

## Re-cut 2026-10-22 on b3a3aa74: Simulation's three conditions

1. **Guard `arena.cols`:** `SimCore._arenaCols(setup)`: needs a `planet` and `cols` a whole number from 600 to 4,800 and **a multiple of 8** (Rendering's rule: the ground's largest stride); anything else is the planet's own 4,800, with an error (quiet under `FighterData.quiet`).
2. **Re-assert in `SimCore.step`:** the match keeps `S.arenaCols`, `S.planetCols` and `S.worldId` (state.gd, not hashed); at the top of `step`, if the static arena length or `WorldBiomes.worldId` is not this match's, it sets its own again. Two matches alive in one process, stepped alternately, play as each plays alone (`arena_check`: a 2,400-column match and a default one, 100 ticks at a time, equal their solo hashes).
3. **The four load-time constants:** re-scanned on b3a3aa74: still the same four (`location.gd` `STEP`, `collateral.gd` `HIST_STEP`, `structures.gd` `BUCKET_W`, `planet.gd` `TOUCH_COL`), all four are functions or statics in the patch.

**Encounter's location.gd lines changed from what they were told:** the tables are keyed on the arena's length and `WorldBiomes.worldId` (a counter `newMatch` claims for each world it builds), so there is **no `reset()`** and a planet world rebuilds them too. At the default arena `STEP` is `W / 48` = 3,200 exactly, as before.

**The gates on the re-cut tree (clean export of b3a3aa74 plus both patches, below-normal):** `run-all.js` all 5 stages passed (unit 12.2 s, parity 78.3 s, soak 19.8 s, golden 0.6 s, godot 304.8 s); Rendering's 15 gates all passed; `arena_check` 0 failed. The diffs are 6 files (window 0) and 13 files (window 1), apply on the newest main and equal the scratch tree.

**Final (2026-10-22), with the multiple-of-8 rule re-proved:** `run-all.js` all 5 stages passed (unit 11.0 s, parity 78.7 s, soak 16.6 s, golden 0.5 s, godot 273.1 s), Rendering's 15 gates all passed, `arena_check` and World's checks 0 failed; with Encounter's two grants and Simulation's brake2 (`brake2.py` and `grant_world.py`) applied on top, `arena_check`, `planet_check`, `planet_world_check`, `brunt_check`, `wall_check`, `collateral_check`, `interior_check`, `repeat_check`, `props_check` and `probe` all 0 failed. The diffs are frozen.

## Lines in files that are not World's

| File | Owner | What |
| :--- | :--- | :--- |
| `sim/core/state.gd` | Simulation | `arenaCols`, `planetCols`, `worldId` (three fields, not hashed) |
| `sim/core/constants.gd` | Simulation | `W`, `NC`, `HALF` from `const` to `static var`; `PLANET_NC` (const 4,800); `static func setArena(cols)` |
| `sim/core/sim.gd` | Simulation | `newMatch`: the guarded `_arenaCols`, `SimConst.setArena(...)` first, `S.planetCols`/`S.worldId = WorldBiomes.claim()` after the world, the planet start reads `WorldPlanet.touchCol()` (window 0 adds the planet branch); `step`: the re-assert |
| `sim/director/location.gd` | Encounter | `STEP` a static, the tables rebuilt when the arena's length or the world changes (`_ensure` keyed on the length and `WorldBiomes.worldId`) |
| `replay.gd`, `hash.gd` | none | The replay's `setup` already carries `arena`; nothing is hashed |

## What it does not do (the later windows)

- **The picker for rings.** A ring is read through the great-circle picker's touch-down; there is no scoring of a small ring (a centre, a size, a bearing). That is window 4's (story stages), and the picker's minimum scaled to the length (`small-circles.md`).
- **Rendering and Camera at 38,400 and 76,800.** The sim plays; the far fog, the zoom ceiling and any buffers sized at the first match are theirs to look at (nothing in `render/` has a compile-time constant that reads the arena's length; the scan found none).
- **Window 0's own open items** (the ice biomes' stand-ins, the golden keys for planet matches, depth rows over a slice): `docs/world/planet-window2.md`.
- The parked `planet-slicing` and `planet-stored` patches touch `planet.gd` too: they are re-cut after this window lands.
