# Re-run on e09dbbbf: the hitches and the ring read (2026-10-22)

Owner: Performance and Platform, for the EP (standing brief, items 3 and 5). Clean `git archive` of e09dbbbf, web export, reduced mode, valid by the load rule.

## The hitch repro (`ai --reduced --ticks 400`)

| Config | Hitches over 50 ms, before (HEAD d4795fa5, valid runs) | e09dbbbf (2 runs each) |
|---|---|---|
| RTX | tick 131: 75 to 95 ms; tick 238: 160 to 165 ms | **none**; slowest frame 12.5 and 24 ms |
| Integrated Radeon | 131: 78 to 96; 238: 165 to 183 | **none**; slowest frame 32 and 33 ms |
| Radeon, CPU x4 | 131: 153; 238: 278 | **131 gone**; **238: 67 to 69 ms** (about 3.5 frames of 17 to 20 ms), and a few 50 to 60 ms frames at 240 to 270 |

The warm-up fix clears both hitches on the RTX and the Radeon. On the old-laptop CPU bound tick 131 is gone and tick 238 is four times smaller (278 to 68 ms) but not gone: a crater's first draw still costs about three slow frames when the CPU is four times slower. Owner: Rendering (the crater's warm-up) with VFX.

## k32 at throttle 4: World's ring read, the same bit for bit and 6.5 to 7 times cheaper in the web build

`WorldPlanet.readSlice` of one ring (World's `ring_bench.gd`, seed 7) in the page, best of 3, microseconds a column, before (9cb5b6ba) then e09dbbbf; the slice hashes are identical:

| Arena size | x1 | x4 (old-laptop CPU) |
|---|---|---|
| 1,200 columns | 118 then 17 us (142 then 20 ms) | 566 then 88 us (679 then 105 ms) |
| 2,400 | 104 then 15 us | 486 then 74 us |
| 4,800 | 125 then 17 us (598 then 83 ms) | 594 then 86 us (2,852 then 414 ms) |

- **k32 columns a tick at x4 now costs 32 x 74 to 88 us = 2.4 to 2.8 ms a tick** (it was 16 to 19 ms), and 0.5 ms at x1. At k64 it is 5 ms at x4. A whole ring (4,800) at x4 is 0.41 s, and at x1 83 ms. That is under a frame at x4 (17 to 20 ms in the AI match).
- (The old planet-slice bench in my audit, `--slice` on the `base` variant, reads a scratch copy of the planet library and does not move with World's park; the `ring` variant reads main's code.) The arena turn's own sim step (RingJob inside `WorldEpoch.tick`) is not on main yet, so the swap tick is not measured (item 4).

## Not re-run yet

AI, city beam and transformation against the last pass (item 3) wait for the next batch on main. The frame cost of e09dbbbf itself in those scenes was not measured here beyond the repro above.
