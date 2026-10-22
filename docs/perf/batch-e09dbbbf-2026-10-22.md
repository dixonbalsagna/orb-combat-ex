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

## The three scenes against the build before it (item 3)

AI match (1,200 ticks), signature beam in the city (600), transformation (1,200); reduced mode; the build before the batch (HEAD d4795fa5) and e09dbbbf interleaved, one browser at a time, valid by the load rule. Frame p50 / p95 / p99 ms, then hitches over 50 ms.

| Scene | Config | Before | e09dbbbf |
|---|---|---|---|
| AI match | RTX | 4.7 / 7.2 / 10.1; hitches 131 (93), 238 (163) | 4.8 / 7.5 / 10.9; **none** |
| | Radeon | 8.3 / 21.4 / 24.0; 131 (79), 238 (168) | 8.2 / 21.0 / 23.3; **none** |
| | RTX CPU x4 | 20.9 / 34.0 / 48.2; 131 (112), 238 (247), 817 (80) | 20.9 / 34.0 / 47.6; 238 (71) |
| Beam in the city | RTX | 5.6 / 8.3 / 11.6; 427 (57) | 5.5 / 8.5 / 11.6; **none** |
| | Radeon | 11.6 / 14.1 / 21.6; 121 (76) | 11.6 / 14.4 / 22.5; 121 (73), 432 (70) |
| | RTX CPU x4 | 22.8 / 39.2 / 51.5 | 22.6 / 40.2 / 49.7 |
| Transformation | RTX | 4.5 / 6.5 / 8.3; 120 (178) | 4.5 / 6.4 / 7.7; **none** |
| | Radeon | 9.1 / 17.2 / 33.2; 120 (181) | 9.1 / 16.8 / 33.2; **none** |
| | RTX CPU x4 | 21.3 / 33.9 / 44.9; 120 (264), 453 (71) | 19.5 / 33.7 / 36.6; 120 (73) |

- **The steady frame cost did not change** (p50 and p95 within a few tenths of a millisecond; draw calls 97, 222 to 228 and 101; primitives the same to the thousand; the engine's CPU time per frame within 3% in every pair). The batch costs nothing per frame.
- **The warm-up cleared the first-use hitches in all three scenes at x1**: ticks 131, 238 (AI), 427 (beam on the RTX) and 120 (transformation, 178 to 181 ms before). At the old-laptop CPU (x4) they shrink, not vanish: the AI's 238 is 71 ms (was 247), the transformation's 120 is 73 ms (was 264).
- **Left:** the city beam on the Radeon still hitches at tick 121 (73 ms) and now at 432 (70 ms) (the first beam's first draw on that GPU); and every x4 run has scattered 50 to 60 ms frames (about 200 to 300 frames over 25 ms in 600 to 1,200: the CPU bound's own tail, not a repeat tick). Owner of the beam hitch: Rendering and VFX (the beam's warm-up on the integrated GPU).
