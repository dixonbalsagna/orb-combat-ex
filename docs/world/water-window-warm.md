# A new water window reads its span in chunks (World, 2026-11-01)

**Spike:** Performance's `docs/perf/orb-first-play-spikes-2026-11-01.md`: `WorldWater.step` 27.1 ms (tick 11548) and 18.9 ms (tick 11570) at a beam's first water window, 309 and 421 ground reads in one tick (Simulation's count). **Park:** `docs/world/pending/water-window-warm/`, **off** (`water.json` `flowWarm.cols` 0).

## Why one tick

A flow window is the stretch of columns round a beam's change where water can move (`WorldWater.touched` opens it; `hw` columns each side, up to 240). Each step reads every column's base once (`WorldTerrain.baseAt`, so the whole span: 2 hw + 1, 309 and 421 here) before the flow is worked out. A ground read on a field world is a lookup into the ground memo; when the memo is cold (a column the match has not read, or a record has joined the store since) the read is the field's own, about 70 microseconds, so 300 to 420 of them in the window's first step are the 19 to 27 ms.

## What the fix does

`flowWarm.cols` (data, 0 = today): a new window starts at a negative age, minus the steps its span needs (ceil of the span over `cols`). Each step it reads the next `cols` columns of its span (the same `baseAt`, discarded: it only fills the memo and changes no state) and **no water moves in it until all are read**, so no tick reads more than `cols` columns of a window and the first flow comes ceil(span / cols) steps (2 ticks each) later. A window that merges into an existing one extends it as before. The window keeps its four-number shape, so it is not mistaken for a fill window (the water v2 windows are longer arrays). Nothing else changes: with `cols` 0 the code takes today's path.

**Cost to play:** the water in a new window starts 16 ticks (0.27 s) late at 351 columns and 48 a step. **Hash:** the window's age is hashed, so every hash with a window moves with it on; off, none does.

## What I measured, and what I could not

`WATERWARM` (`sim/world/tools/water_warm_check.gd`) 0 failed on planet 7 touch 1: off, the window starts at age 0; on (48), at -8 for 351 columns and the first flow step comes exactly 16 ticks later; the same twice; the water after 1,200 ticks within 0.04% of the off run's. **I could not reproduce the spike**: at my test coast (and with a record pushed before each step, as the beam does) a flow step took 0.3 to 0.8 ms, because the ground there was already read. So this is built to the mechanism in the note, not shown to fix Orb's ticks. **The test that decides it is Performance's: Orb's replay with `flowWarm.cols` 48, ticks 11548 and 11570.** If the cost is the records (a memo miss re-reads each column through the store's records, which a warm chunk does not save when the beam pushes another record the next tick) then warming ahead is wasted and the cure is Simulation's field-place; this park does not claim otherwise.

## If it works, what to set

48 a step keeps a tick under about 3.4 ms of window reads (48 x 70 us); 96 halves the delay and doubles the cost per tick. The delay is the part to watch: a beam's bay filling 0.27 s late is not likely to be seen; at 24 it is 0.55 s.
