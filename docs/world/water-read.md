# What is slow in a beam's water window tick, and the fix (World, 2026-11-02)

Performance's spike (`docs/perf/orb-first-play-spikes-2026-11-01.md`, `orb-second-play-2026-11-01.md`; the EP's order: `WorldWater.step` 27 to 58 ms at a beam's first window, now the worst single tick). `water-window-warm` alone did not move it on Performance's trees. This finds why, with timers inside the call on Orb's own first-play replay (the rebuilt tree in `homework/Files/builds/orb-first-play-018b4edf-fddd34b4/tree`, copied; it reproduces every checkpoint and the final hash; native, below normal, a shared PC, so the milliseconds are upper bounds and the comparisons carry).

## Where the time is

At tick 11548 the step takes 38.8 ms. **37.5 ms of it is one loop: the read of every column of the window's span** (`WorldTerrain.baseAt` for 309 columns); the flow arithmetic is 0.2 ms, and the aftermath, fire and fill windows read 0. The read splits by what a column's ground costs (309 columns, microseconds):

| | ms | per column | what it is |
| :--- | ---: | ---: | :--- |
| `WorldField.sample` | 20.6 | 67 | the planet's own ground at a node, **cold**: nodes the match had not read (the window had grown into new ground); at the next window (tick 11570) the same call is 3.6 ms, 8.5 a column |
| `WorldField.applyRecords` | 11.8 | 38 | the lots, pads and platforms: **63 records scanned per column** |
| `WorldStore.heightDelta` | 3.1 | 10 | the craters, scorches and trenches |
| `pointAt` | 1.2 | 4 | the strip column's point on the planet |

And **every second tick while the beam runs (11580 to 11594) the step read 23 to 27 ms again**, because the build had no `field-place`: each record the beam pushed voided the whole ground memo, so the window's 300 to 420 columns were read from scratch every step. With `field-place` those sweeps are gone (Performance saw this; I reproduce it: the next window spikes are 11548 and 11570 only). That is why `water-window-warm` showed no gain on their trees: the columns it warmed were voided by the next record.

Of the 63 records per column, **54 are the platforms**, which reach far (a platform is thousands of units across) and so were listed for every point and tested one by one; `WorldWaterRec.near` also rebuilt and sorted its list on every call (4.4 ms of the 11.8).

## The fix: two parks, one small, one exact

**`water-read` (`docs/world/pending/water-read/`, hash-exact, no data, no switch).** `WorldWaterRec.near`: (1) keeps each box's merged, ordered list once a box and index (it was built and sorted on every call, hundreds of times a tick); (2) lists the big records (reach past 2,048) in a coarse grid of 4,096-unit boxes, so a point meets the one or two platforms near it and not all fifty. **The lookup lists 5.9 records on average where it listed 58.3** (`WATERREAD` check: for 2,202 points it lists every record whose reach contains the point, in plan order, the same twice; 0 missed). Nothing is skipped that could change a height, so every hash is identical: **Orb's replay still reproduces every checkpoint and the final hash**, and the golden (parity) passes.

**`water-window-warm`, re-cut.** The first cut read only the span a window had when it opened, so when the beam merged into it and widened it (309, then 421 columns) the new columns were still cold at the first flow step. Now a merge into a window still warming adds the steps the new columns need (at most 16 in all, `MAX_WARM_STEPS`), so every column is read before water moves. Still off by default (`water.json` `flowWarm.cols` 0); with it on the water starts up to 0.5 s later and hashes with a window move.

## Before and after (Orb's first play, ticks of the window; ms of the whole tick)

| Build | 11548 | 11570 | 11580 to 11594 (every 2nd) | worst tick of 11500 to 11700 |
| :--- | ---: | ---: | ---: | ---: |
| As played (no field-place) | 49.7 | 30.8 | 25 to 29 | 49.7 |
| + field-place | 45.0 | 31.0 | none over 3 | 45.0 |
| + `water-read` (the merged list only) | 41.1 | 23.3 | none | 41.1 |
| + `water-read` (the coarse grid too) | 34.5 | 15.3 | none | 34.5 |
| + warm 48, merge-aware (cold nodes read ahead, 3 to 9 ms a step) | **5.6** (a warm step) | under 12 (the water took under 2) | none | **9.9** (a warm step on cold nodes; the first flow step 8.2) |

The cold node reads (`sample`, 20 to 24 ms for the first window) are the planet function and cannot be made cheaper; the warm is how they are spread over steps without a spike. With `cols` 32 a warm step is about 6 ms instead of 9; the delay before the water moves is about 8 steps (0.27 s) at 351 columns.

## What I did not do

- **Collateral's single ticks** (`WorldCollateral.tick` 11.6 ms at tick 2802 in Performance's list): I put timers in `WorldCollateral.tick` on the second-play replay up to tick 3000 and its whole tick is **under 0.4 ms** at every tick in the list (the 12 to 16 ms ticks there are the swing offers, `DirSwing`; 583 is the first swing, 2171 a launch). So it is not collateral; if there is a tick it is slow, it is somewhere I did not reach (after tick 3000), and I have not run the match to its end.
- **Performance's bench's 44.7 and 57.8 ms** (kept build, ticks 20179 and 20679): not replayed; I do not have that match. They are bigger than Orb's 15 to 33, which fits a window that has grown over more cold ground; the same cure applies (the warm reads ahead, the read is cheaper), but I have not seen those ticks.
- **A static memo for `sample` + `applyRecords`** (a re-read after a record joined the store would then pay only `heightDelta`, about 4 times cheaper): it is in Simulation's `SimField`, so it is a grant; not built.
