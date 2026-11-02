# The rest of the beam's ticks: the second window, the scorch and a building's heap (World, 2026-11-02)

Performance's bench of Orb's second-play inputs on the new kept build (the replay diverges from tick 1200, expected), and Encounter's read of `beamStep`. Timers inside the calls on that tree (`orb-first-play-3d997381-7e2d88ff`, with field-place, water-read and the warm at 48), native, below normal, a shared PC: the milliseconds are upper bounds, the comparisons carry. Parks: `docs/world/pending/water-cost/` (this), `water-read/`, `water-window-warm/`, `meteor-power/`.

## Tick 20679: a swing's first tick (21 ms of water)

Not the columns the warm reads. Water had three windows (105, 481 and 481 columns: 1,067) and stepped warm, about 1 ms a step, every second tick (the strip's ground memo is warm). **At tick 20679 a swing starts**: the ground memo's serial moves 1,664 to 1,666 (the strip is re-posed) and the swing is active at the end of the tick, but that tick `SimSwing.waterHeld` still says the water may step (the line is not "moving" yet: it is held by the clock), so the step read all 1,067 columns on the new strip, every one cold: **21 to 31 ms in one tick** (890 memo misses, 35 microseconds a column). The fix (`water.gd`, under the warm switch): while a swing is active the water waits, whether or not the line has begun to move; `waterHeld`'s own bookkeeping (the warm after the swing rests) is still called first. Result at 20679: **water 21.1 ms to 0**, the tick **40 to 15.6 ms** (what is left is the swing's own start, Encounter's). It moves the hash only with the warm on (it is tied to `flowWarm.cols`): the water is held a tick or two longer when a swing starts.

## The scorch (ticks 20164 to 20176, six samples a tick, 4 to 9 ms a tick)

Per tick, before and after: `WorldWater.touched` (called by each scorch) **3.8 to 5.4 ms to 1.5 to 2.8**; the dig loop (the ground of the columns the new record reaches, cold: the memo is voided exactly there) 1.2 to 2.2 ms (unchanged); the store record 0.7 to 1.1 ms (unchanged). Whole scorch time a tick **5.7 to 8.7 ms to 3.6 to 6.0**. What was slow in `touched`: it read each column's ground three to five times over three loops (a function call and a lookup each, hundreds of times a call); now each column is read once (the widest span only if a window is wanted). **Hash-exact** (same reads, same order of effects): Orb's first play replays with it and reproduces every checkpoint (to tick 12,700, windows included; the run is in the park's README). What remains is the cold reads of the reached columns (14 microseconds a column of node, records and delta each time), which only a static memo in `SimField` cuts (`docs/world/pending/field-static-memo/request.md`, Simulation's).

## A falling building's heap (tick 19147: 12.8 ms in one `damageArea`)

Not the damage: `WorldStructures._heap` is 12.5 ms and **`WorldCrater.relax` is 12.45 of it**: the heap's relaxation to the angle of repose runs up to 64 passes of two sweeps over its window, and read each pair's ground four times in each iteration through `WorldTerrain.baseAt`. The ground never changes in a relaxation (only the deform and the rubble do), so it is read once into a local array with each pair's allowed step, and the passes use those. **Bit-exact**: `RELAX` runs the original (kept in the check) and the new on the same steep ground, 36 windows of 29 to 84 columns with and without a frozen side, and compares deform, rubble and the returned lowest ground: 0 of 36 differ, and the new one takes **37 ms against 386 ms (10 times)** over them. At 19147 that is a 12.5 ms heap going to about 1.3.

## Not done

- **The cold reads of the reached columns** (what remains of the scorch and of the first step of any window): the static memo, Simulation's.
- **Tick 20679's other 15.6 ms** and 20164 to 20176's remainder in `beamStep`: Encounter's and Combat's.
- `arc_check` with the energy model: `meteor-power` (one failing line, the meteor's bowl 4,571 against 5,000; lines 348 and 349 pass with or without the tier term).
