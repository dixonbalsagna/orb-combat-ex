# Performance budgets (first table, 2026-10-16)

Owner: Performance and Platform. This is the budget table the wave-1 brief asked for. It is written against the measurements of `main` (HEAD e6fa72ff) in `docs/perf/audit-2026-10-16.md`, taken in a quiet stretch of the shared PC; the "Today" column is from those valid runs. **Every limit is PROVISIONAL**: it is a number to build toward and to gate against until a quiet re-run (one command, in the audit) on a real old laptop, a phone and a Steam Deck confirms or moves it. A **target** is where we want to be; a **hard limit** is where a build is held.

## The hardware tiers the budgets are written for

Orb's platforms are Windows, Linux, macOS, the browser, Steam Deck and phones, "down to old laptops" (`docs/ep/vision.md`), and "old laptops and phones: 30 frames a second with reduced effects is fine". We have no old laptop, phone or Steam Deck on the bench, so each tier is stood in for by **Chrome's CPU throttle on the web build, on the dev PC** (a Ryzen 7 9800X3D, the RTX 5070 Ti, 1280 by 720). The throttle makes the browser's main thread N times slower. It does not slow the GPU, memory or a hot, power-limited chip, so a throttled run is a **lower bound** on the cost on that kind of machine, never a promise.

| Tier | Stands for | Throttle | Frame budget | Effects |
| :-- | :-- | :-- | :-- | :-- |
| **T1 Desktop** | a 2019-or-later PC; the web build in a current browser | x2 | 60 fps = 16.7 ms | full |
| **T2 Old laptop, Steam Deck** | a 2015 dual-core ultrabook (PassMark single-thread 2.6 to 3.9 times slower than the 9800X3D, Research's spike); a Deck is probably between T1 and T2 (unmeasured) | x4 | 30 fps = 33.3 ms | full, then the game's own automatic step down (VFX drops a level below 42 fps for 2 s) |
| **T3 Phone** | a mid-range Android phone in Chrome (an iPhone's CPU is faster; its limit is memory) | x6 | 30 fps = 33.3 ms | **reduced** (VFX quality low, Animation quality low) |

**The two numbers that decide most rows, on the dev PC unthrottled ("x1"):** **8.3 ms at p95** for full effects (16.7 / 2 for T1 and 33.3 / 4 for T2, the same number) and **5.5 ms at p95** for reduced effects on a phone (33.3 / 6).

## The table

Scenes are the audit's three (a city brawl, a signature beam in the city, a ring of three; Tools' staged scenes). "x1" is the dev PC's web build. "Today" is the audit's valid runs.

| Row | Target | Hard limit | Today (x1 unless said) | Owner | Measured by |
| :-- | :-- | :-- | :-- | :-- | :-- |
| **Frame time, full effects** | p50 6.0 ms, p95 8.3 ms | p99 12 ms; **no frame over 50 ms after the warm-up** | p50 6.5 to 7.3, **p95 9.8 to 11.5 (18 to 39% over)**, p99 12.3 to 19.3; **hitches of 150 to 510 ms** | Rendering (the frame), every director for their share | `frame-bench.mjs`; at throttle x4 the p95 must read under 33.3 |
| **Frame time, reduced effects (phone)** | p50 4.0 ms, p95 5.5 ms | p99 8 ms | x6 low quality: p50 31.6 to 40.9 ms, p95 52 to 64 ms, i.e. **8.7 to 10.7 ms at x1 (58 to 95% over)** | Rendering, VFX, Animation, UI | `frame-bench.mjs --throttle 6 --page-args lowq=1` |
| **Sim tick** (the GDScript sim) | 0.4 ms mean | 1.0 ms p99; **8 ticks inside 3 ms if rollback comes** (ADR 0001's revisit line) | 0.31 ms mean, p99 0.83 (native headless); 0.39 to 0.41 mean (web). **Eight ticks: 2.7 ms** | Simulation | the game's `sim tick ms`; `native-cpu-bench.ps1` |
| **FX and camera, per tick** | 0.6 ms mean | 1.5 ms p99 | 0.48 mean, p99 0.96 (native); 0.57 to 0.81 (web) | VFX, Camera | the game's `fx+camera ms` |
| **View update, per frame** (fighters, planet, VFX layer, HUD script) | 2.0 ms mean | 4 ms p99 | 1.89 mean, p99 5.2 (native); 2.0 to 2.4 (web) | Animation (fighters), UI (HUD), World (planet), VFX | the game's `view update ms`; the profiling timers |
| **Draw calls, per frame** | **100** | 300 | **305 to 347** (peaks 377 to 452); **94% are the HUD's** | **UI** first, then Rendering | `RenderingInfo` (exact: the same in every run of a scene) |
| **Primitives, per frame** | 300 k | 450 k | **523 to 624 k** (peaks 1.4 M and 1.8 M); terrain, water and crowd are 96% | World, Rendering, Camera (inset) | the same (exact) |
| **Particles** (the debris pool and the particle view) | VFX's pools as written in `docs/vfx/effect-budgets.md` (460 debris, 90 crack sets, 12 to 24 rock quads) | the pools' caps are the limit; no pool grows without this row | live particles at most 85 in the staged scenes | VFX | the live count; VFX's `worst_case.gd` |
| **Terrain deformation** (4,800 columns of 32 units; a crater is a few dozen columns) | deform upload under 0.05 ms a tick, at most 60 craters a second | 0.15 ms a tick | **not separately measured**; Research's stand-in had 0.02 to 0.025 ms | World, Simulation | to be added to the next audit |
| **Memory: the page's process** (the wasm heap and the page; private bytes) | 450 MB | 600 MB | **495 to 537 MB (over target)** | Rendering, Tools | `frame-bench.mjs` (`browserMemMB`) |
| **Memory: the whole browser** (all processes, private bytes) | 900 MB | 1.2 GB | 0.96 to 1.05 GB | Rendering, Tools | the same |
| **Memory: video and texture** (as the engine reports it) | 128 MB | 256 MB (an integrated GPU shares memory) | 73 to 91 MB video, 23 to 25 MB texture | Art, Rendering | `RENDER_VIDEO_MEM_USED`, `RENDER_TEXTURE_MEM_USED` |
| **First load** (compressed as GitHub Pages serves it) | 12 MB | 15 MB (Pages' soft limit is 100 GB a month: 15 MB a load is about 6,800 first loads a month) | **14.4 MB** (wasm 9.7, pack 4.6; 45.9 MB raw) | Tools | `gzip -6` of the export |
| **Start to first frame** (cold, no cache, local server) | 12 s at x1 | 30 s at x1 | **20 to 26 s** (plus the real download) | Tools, Rendering | `loadSeconds` in the run files |
| **Planet slice: the strip read** (once, at touch-down) | 150 ms in one call at x1, or no more than 4 ms in any frame | 400 ms in one call; 8 ms in any frame; done within 5 s on T3 | 0.69 s (equator) and 1.36 s (poles) at x1; 4.9 and 9.8 s at x6; **coarse 0.085 and 0.17 s at x1, 0.6 and 1.2 s at x6** | World | the audit's slice read |
| **Run-mode state** (the wear list between stages) | 50 KB a run, a save under 20 ms, restorable from a text of at most 4 KB | 150 KB | not built | World, Simulation | file size and a timed save |
| **GC and allocation** (objects made each frame by script) | no steady growth over a 3,000-tick scene | any growth | **not measured** (the engine's static-memory counter reads 0 in the web build) | every director with a per-frame loop | a debug export with the memory monitor |

Extra rows for the planet slice, the run mode, the catastrophe visuals and more bodies are in the audit's section 6.

## Why these numbers (so they can be re-derived when a measurement moves)

- **8.3 and 5.5 ms** come straight from Orb's tier rule and the throttles above.
- **Today's p50 is already at the target** (6.5 against 6.0 to 6.5); **p95 is the gap**, and it is made of the beam in the city (a thicker second view and a longer draw list) and the first-use hitches, not of the median.
- **The page's main thread is the bottleneck.** Its CPU time per frame is within 0.5 to 0.7 ms of the frame time at x1 (the audit's section 3.2); the GPU is not the limit on the dev PC, and the integrated GPU's headroom cannot be read from a web run locked to the display's refresh.
- **Draw calls are in the table because the web build's main thread pays for each one**: hiding the HUD takes a paused frame from 2.4 to 1.1 ms and removes 344 of 364 draw calls. The 100-call target is what the world's 23 calls plus a cached HUD would give.
- **Draw calls and primitives are exact.** A scene stepped by tick draws the same list on every run (305, 337 and 346 draw calls, never one more or less in any run), so they gate strictly. Timing moves 8 to 28% between runs on a shared machine and gates only as a ratio.
- **The memory rows follow the evidence on phones**, which is thin: Godot's issue tracker lists about 450 MB as a default web build's size and ties it to iOS losing the context, and a phone's tab limit is the system's and varies. They need a real phone to confirm.

## The build gate (proposed; QA and Tools own the wiring)

1. **Run the staged scenes through `docs/perf/tools/audit-run.mjs --plan ab`** on the commit and on its parent, interleaved in rotating order, three repeats, one browser at a time (about 15 minutes on a quiet PC). It is added to `node qa/run-all.js` only on a quiet, named machine or on the EP's schedule; on a shared runner it gives noise.
2. **Exact rows fail on any change over 5%:** draw calls and primitives (peak and median), per scene. They are deterministic.
3. **Timing rows are ratios on the same machine in the same session:** the page's main-thread CPU time per frame (the renderer process) and the game's own `view update`, `sim tick` and `fx+camera` timers, of the commit over its parent. A **regression is a median ratio over 1.10 across three interleaved repeats**; between 1.05 and 1.10 is reported and not failed. Frame p95 is reported beside it and never gates alone.
4. **A run on a saturated machine is marked invalid and not compared.** The driver measures the load before and after and writes it in the file.
5. **The hard limits in the table are absolute gates only on a quiet, named machine.** Elsewhere only the ratios apply.
6. **Noise on shared runners.** A hosted runner shares cores and caches, so wall time moves by tens of percent between identical runs (the audit measured 28% on this PC with about twenty sessions on it). Draw calls, primitives and the sim hash are the only numbers worth gating there.
7. **Parity is part of the gate:** a render-side change must leave the sim hash unchanged (`--headless --bench --seed=4` prints it; 5c8a828d4ef852c2 at tick 1800, 8f2e64728709d8d9 at tick 2400 on e6fa72ff).

## Reading someone else's frame-time numbers (a template for Research's and VFX's reports)

- **An average hides the frames that matter.** Ask for p50, p95, p99, the worst frame and the count over budget. A 1 ms average with a 300 ms freeze at the first beam looks fine and plays badly: the audit's beam and ring scenes have exactly that.
- **Ask what the scene was, and whether it includes the first use of each effect.** A scene with no beams, no collapse and no crowd measures a different game.
- **Ask how a frame was timed.** A loop that waits for the browser's next frame after each tick takes two animation frames a tick (this audit's first version did, and every number from it was thrown away). The frame is the interval between animation frames with the game running one tick a frame.
- **Ask for CPU time per frame, and for the machine's load.** Wall time under load is an upper bound; CPU time moves less.
- **Ask what machine and GPU, and whether the GPU was the one reported.** On this PC there are two; a run is the integrated GPU only if the page's GPU string says so, and a run locked to the display's refresh cannot show headroom.
- **A fast GPU is not a lead on the CPU.** The web build is bound by the page's main thread.
- **Throttled runs are lower bounds on old hardware, not predictions.** They cannot show a slow GPU, small caches, a thermal limit or a phone's memory ceiling.
- **A stepped capture is not play.** Tools' hook draws one tick a frame at the browser's pace; the real game interpolates at the display's rate with audio and input on top.

## Where the audit and these tables came from

`docs/perf/audit-2026-10-16.md`. Scripts: `docs/perf/tools/` (`make-audit-sites.mjs`, `frame-bench.mjs`, `audit-run.mjs`, `audit-summary.mjs`, `native-cpu-bench.ps1`, `scratch-hooks/`).
