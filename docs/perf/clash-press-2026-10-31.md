# The clash press: shader cost per level on the Radeon iGPU, against the old flare (Performance and Platform, 2026-10-31 night)

For the EP, on the bench for VFX's `docs/vfx/pending/clash-press` (arithmetic only in the README). Speed only: no clip, no picture and no flash number is kept (RL-226's pause; the EP's go).

## Answer

**The press costs about 0 to 2 ms a frame while a clash is on screen on the Radeon iGPU, about 1.2 to 1.6 ms (4 to 5%) at 3840×2160, and this load cannot tell the three levels apart.** At 1280×720 the paired differences are inside the run-to-run spread; at 3840×2160 (1920×1080 at a pixel ratio of 2, where the iGPU is fill-bound at about 30 ms a frame) the median pair is +1.6 ms at level 0 and +1.2 ms at level 2, against a spread of 1.5 ms across the old flare's own runs. Low draws less than High, so the order should be level 0 below level 2; it does not show, which says the noise is larger than the difference between levels. It is small; it is not zero.

## What was run

- **Builds** (web export, standard template, capture hook on, scratch trees only): **A** = main `fd54349d` + the stack + `clash-look` + `beam-buckle` (the old flare; the stack's `vfx-meteor-trail` left out, its `effects_check.gd` edit conflicts with clash-look); **B** = A + `clash-press/apply.patch` (checks clean, sha1 552a7bed) + a scratch page word `?pq=0|1|2` that sets the press level alone (`press_quality`: 0 flare and sheet only, 1 adds the eddies' shape, 2 their hue).
- **Bench**: `frame-bench.mjs --scene clash --igpu` (Tools' launcher; the page reports `ANGLE (AMD, AMD Radeon(TM) Graphics … Direct3D11)`; vsync and the frame limit off; one tick and one drawn frame per animation frame), paired rounds in rotating order (A, B level 0, 1, 2; the order shifts each round), **6 rounds at 1280×720 and 4 at 3840×2160**, median of the runs and the paired difference B minus A per round.
- **The window matters**: a pixel check (below) shows the clash is on screen from about tick 60 to about 330 of the scene. My first runs timed ticks 120 to 720 and were two thirds empty frames (diluted: every difference under 0.3 ms); the numbers below time ticks 60 to 300.

## Is the press drawn? (hash of one in-memory screenshot per tick, nothing kept)

| tick | 60 | 120 | 180 | 240 | 300 | 360 and after |
|---|---|---|---|---|---|---|
| A, B0, B1, B2 | all four differ | all four differ | all four differ | all four differ | all four differ | all four the same |

So the press is drawn and each level changes the picture while the clash lasts, and the old flare differs from every level; after the clash the four are identical (an earlier check at tick 400 alone, which read "identical", was after the clash). A repeat of the old flare gave the same hash both times (the method is exact).

## The numbers (clash window, milliseconds a frame, median over rounds)

| | runs | p10 | p50 | mean | p95 | paired B minus A, p50 median (per round) |
|---|---|---|---|---|---|---|
| **1280×720** A, old flare | 6 | 4.30 | 8.40 | 14.85 | 32.3 | |
| B level 0 | 6 | 4.80 | 14.20 | 18.63 | 45.0 | +5.8 (9.9 2.7 0 5.8 6.4 -1.2) |
| B level 1 | 6 | 5.90 | 11.00 | 16.75 | 32.3 | +4.0 (6 4 0 -0.7 19.5 -2.6) |
| B level 2 | 6 | 6.00 | 7.70 | 13.36 | 30.9 | -0.1 (2.6 2.7 -0.1 -1.3 -2.3 -2.2) |
| **3840×2160** A | 4 | 22.80 | 29.80 | 30.29 | 46.1 | |
| B level 0 | 4 | 21.30 | 31.10 | 31.60 | 46.8 | +1.6 (4.2 -0.8 -0.2 1.6) |
| B level 2 | 4 | 28.30 | 31.00 | 32.58 | 62.5 | +1.2 (1.0 1.2 0.0 1.7) |

Reading: at 720p the machine's noise (the old flare alone ranges 7.0 to 9.9 ms at p50, and 14.9 ms mean against the diluted runs' 7.8) is bigger than any effect, and the level order is inconsistent (level 0 reads worse than level 2); I do not read a cost out of it. At 3840×2160 the frame is fill-bound and steadier: level 2 sits 0 to 1.7 ms above the old flare in all four rounds (median +1.2) and level 0 in two of four (median +1.6, with two rounds at about zero or below). That is the only reading I would quote: **≤ 1.6 ms, about 5%, at 3840×2160 on the Radeon iGPU**; a 1080p frame has a quarter of those pixels, so about a quarter of that cost if it is fragment-bound (arithmetic, not measured).

## Limits

- **Every run is marked INVALID by the load rule** (the machine was 60 to 100% busy throughout: other sessions' Godot and browsers); the pairs are taken in rotating order to share the load, and the medians still carry that noise (in either direction). A quiet-machine rerun would separate the levels.
- One scene (`clash`, seed from the hook), one GPU (this PC's Radeon iGPU via Chrome's `--force_low_power_gpu`), headless Chrome with D3D11; not a native window, not the old laptop's iGPU. The hook's per-frame fields (tick, view, draws) are not in this export, so there is no tick/view split: the figure is the whole frame.
- The clash is on screen for about 270 ticks in this scene; a longer clash costs the same per frame.
- The press as built has the Encounter beam struggle stacked (`Clash.mid` has no writer on main); the eddies follow surges only with that park.

## Files

`docs/perf/tools/swing-bench/`: `bench-pairs.mjs` (aggregates the paired runs), `press-drawn-check.mjs` (the hash check, through Tools' launcher). Builds and raw runs are in my scratch folder, not the repo.
