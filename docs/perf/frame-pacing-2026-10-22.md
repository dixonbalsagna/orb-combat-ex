# Frame pacing: a 2-minute AI match and a 2-player brawl (2026-10-22)

Owner: Performance and Platform, for the EP (standing brief, item 2). Build: HEAD before e09dbbbf (so the first-use hitches at ticks 131 and 238 are still in these runs), web export, Tools' hook in auto mode (one tick per animation frame, reduced mode), 7,200 frames each (two minutes at 60 Hz) after 120 warm-up ticks, one browser at a time, valid by the load rule. **Frame time is the interval between two animation frames with vsync and the frame-rate limit off** (a free-running loop, not a 60 Hz one), so on the RTX a frame of 5 ms is the work, not the display; frames over 16.7 ms are the ones a 60 Hz screen would miss. The AI match is `ai` (seed 4); the 2-player brawl is `mash` (both players on pads, walking into reach and mashing, a heavy now and then). Configs: RTX, integrated Radeon, integrated Radeon with the CPU four times slower (x4).

## The distribution (ms; frames over a limit as a count of 7,200)

| | p50 | p95 | p99 | worst 1% (mean) | max | over 16.7 | over 25 | over 33 | over 50 | swing p95 | swings over 16.7 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **AI match, RTX** | 4.8 | 6.7 | 8.8 | 15.0 | 163.5 | 8 | 4 | 3 | 2 | 2.1 | 13 |
| **AI match, Radeon** | 9.7 | 23.0 | 31.9 | 37.6 | 201.7 | 1,117 (15.5%) | 106 | 37 | 3 | 3.6 | 170 |
| **AI match, Radeon x4** | 23.2 | 38.1 | 51.3 | 69.6 | 263.2 | 6,776 | 2,698 | 714 (9.9%) | 96 | 23.3 | 727 |
| **Brawl, RTX** | 4.6 | 6.9 | 8.4 | 11.0 | 27.3 | 5 | 1 | 0 | 0 | 2.9 | 7 |
| **Brawl, Radeon** | 7.6 | 9.0 | 10.0 | 11.7 | 29.3 | 1 | 1 | 0 | 0 | 2.5 | 2 |
| **Brawl, Radeon x4** | 20.3 | 34.1 | 43.5 | 51.9 | 120 | 6,483 | 1,505 | 549 (7.6%) | 32 | 25.1 | 883 |

"Swing" is the difference between two consecutive frames; p95 and the count over 16.7 ms say how often the frame rate lurches. At x4 the median frame (20 to 23 ms) is over 16.7 ms nearly always (a CPU that slow cannot hold 60 fps) and about a tenth of frames are over 33 ms (a 30 fps floor missed).

## The worst 1%

- **RTX:** the worst 1% of the AI match averages 15 ms; that is two frames (the first-use hitches at ticks 131 and 238, 94 and 164 ms) and a handful of 17 to 50 ms frames. The brawl has none over 28 ms. Both are inside 60 Hz except those few.
- **Radeon:** the AI match's worst 1% averages **38 ms**, and 15.5% of all frames are over 16.7 ms: **not spikes but long slow stretches** (below). The brawl is flat: worst 1% 11.7 ms, one frame over 25.
- **Radeon x4:** worst 1% averages 70 ms (AI) and 52 ms (brawl).

## Any repeating spike? No.

- Autocorrelation of the spike frames (a frame over twice the median and 6 ms over): no period stands out in any config (AI match, 7,200 frames). The most common lags (2 to 12 frames) are **clustering of consecutive slow frames**, not a period; the only regular runs are two short ones on the Radeon (spikes of 32 ms every 5 frames, five of them, at ticks 2756 to 2776 and 5378 to 5393).
- **The fixed-tick hitches are the repeating thing:** ticks 121 (25 ms), 131 (80 to 94 ms), 238 (160 to 200 ms), then 817 (40 to 76 ms) in the AI match in every run. e09dbbbf clears 131 and 238 (see batch-e09dbbbf-2026-10-22.md); 817 is not yet looked at.
- The brawl has no fixed-tick hitches at all (a scene with no new first use after the start).

## What makes the Radeon's slow stretches: the terrain's primitives grow with the match

The Radeon's frames over 16.7 ms come in blocks (in 300-frame blocks of the AI match: 112 at 600 to 900, 100 to 108 at 1800 to 2700, 210 and 204 at 5700 to 6300, with 0 at 6300 to 6600), the same blocks with or without Camera's strip (`nopanel=1`: 988 frames over 16.7 against 1,117), so **the strip is not the main cause** (it adds some at ticks 5400 to 6000: 94 frames against 25). Layer cuts on the Radeon at three ticks of the match (the frame with a layer hidden, the same frozen picture):

| Tick | Frame | Draw calls | Primitives | Without terrain | Without water | Without the HUD |
|---|---|---|---|---|---|---|
| 750 | 8.0 ms | 99 | 231 k | 3.7 ms | 7.2 ms | 7.7 ms |
| 2,100 | 9.7 ms | 112 | 355 k | 4.1 ms | 8.5 ms | 9.4 ms |
| 6,000 | **24.3 ms** | 157 | **808 k** | **7.7 ms** | 21.2 ms | 23.9 ms |

- **The terrain is 4.3 of 8 ms at tick 750 and 16.6 of 24.3 ms at tick 6,000** (386 k of the 808 k primitives), and **the primitive count of the terrain rises as craters pile up and with the part of the world the camera is over** (231 k, 355 k, 808 k; the brawl scene, which never makes a crater, stays at 187 to 193 k). On a GPU this small, a match that has cratered the ground cannot hold 60 fps. The water (a second copy of the grid) is now cut; the HUD costs draw calls, not time here.
- These layer cuts were made on the build from before this batch's HEAD (layerprof, an older export), which is one reason to call the 6,000-tick figure indicative until it is repeated on a current build.
- Owner: **Rendering (the planet view's terrain mesh and its detail near craters) with World (the deformation's mesh)**. A cap on the terrain's primitives, or coarser chunks for a crater's far side, is the lever. On the old-laptop CPU bound (x4) the cost is the draw submission and the tick, not these primitives.

## Verdict

- **Brawl: smooth on every config** with a GPU (no frame over 29 ms on the RTX or Radeon; swing p95 2.5 to 2.9 ms).
- **AI match on the RTX: smooth except the two first-use hitches** (cleared on e09dbbbf at x1).
- **AI match on the Radeon: 15% of the frames miss 60 Hz, in stretches, from the terrain's growth.** On the old-laptop CPU bound both scenes are 20 to 23 ms a frame (about 45 fps) with a tenth of the frames over 33 ms.

## Files

`frame-bench.mjs` now reports `pacing` (worst 1%, swing distribution, counts over 16.7, 25, 33 and 50 ms, spike gap histogram, the first spikes, counts per 600 frames) and `--save-rtt` keeps every frame time. Raw runs are in my scratch folder.
