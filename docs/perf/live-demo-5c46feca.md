# The live demo's framerate in combat: 5c46feca and 728596d0 against d3f1ca0e (2026-10-19)

Owner: Performance and Platform, for the EP. Orb played the live demo (pin 5c46feca, web build, Reduce flashing locked on): "the framerate seems to tank during combat". The build Orb played before is d3f1ca0e (203 commits earlier, 320 files). **Part 1 (5c46feca) has no valid time** (the PC gave no window); **part 2 (the new pin 728596d0, dissolve off) is measured and valid** (see "Validity"). What follows is what does not depend on load, and what is still to time.

## Validity

Both builds were exported from clean `git archive`s (`make-audit-sites.mjs --rev`), run in Tools' hook in reduced mode (reduced motion and reduced flashing), one browser at a time. Every run since 22:00 started at 36 to 51% total load and ran at 50 to 66%, and **the capture's own four cores (12 to 15, shared by every guarded capture) read 55 to 99% busy** because up to three other sessions' flash captures run on the same four cores. Every time is therefore marked invalid and not reported. Draw calls, primitives and the ticks at which hitches happen do not depend on load and are reported. `quiet.cjs` now also requires the capture cores under 40%; a valid window needs the other captures paused, not just the total load low.

## What is exact

**Draw list in a frozen frame (tick 104, hiding one layer at a time), draw calls / primitives (k), old then new:**

| | AI match | Signature beam in the city |
|---|---|---|
| Everything | 170 / 492 then 176 / 233 | 350 / 1,385 then 360 / 396 |
| Terrain, water | 8 / 216 then 8 / 216 removed | 24 / 835 then 10 / 343 removed |
| Crowd | 1 / 259 then 0 / 0 | 2 / 518 then 2 / 28 |
| Fighters, beams, particles, VFX (each) | 7 to 9 draws, 9 k, both builds | 9 to 17 draws then 7 to 11 |
| **The HUD** | **152 draws then 159** | **298 draws then 334** |

- **The geometry is much lighter in 5c46feca**: the crowd chunks work (the beam scene's 518 k crowd is 28 k) and the second world the inset pane drew is gone (1.39 M primitives in the beam scene is 0.40 M). That is the fix my audit proposed, and it landed. So a GPU limit is less likely than it was.
- **The HUD did not get lighter**: it is 159 of 176 draw calls in the AI match and **334 of 360 in the beam scene, 36 more than in d3f1ca0e**. The audit's hot spot 1 is still there, slightly worse. A cached HUD has not landed in 5c46feca.
- **The draw list grew by 6 to 10 calls** overall (AI 170 to 176, beam 350 to 360); in the staged scenes' median frames AI 173 to 206 and beam 307 to 348. The new effects (blast cloud, tremor) are inside "vfx", "particles" and "beams" and are not large in a frozen frame; they may act only during an event.
- **Hitches at fixed ticks** in the new AI match (reduced): tick 131 (110 to 140 ms) and tick 238 (146 to 172 ms) even with the boot warm-up; tick 817 and 818 (50 ms). In the old build the same match had the old hitches (tick 238 at 958 ms, 360, 499, 817: starved, the ticks are the finding). The warm-up does not cover whatever first happens at ticks 131 and 238.
- **Camera's cut dissolve** (new since f15d7de3; `split_view.gd _dissolve()`: `get_viewport().get_texture().get_image()`, `convert`, `ImageTexture.create_from_image` on every cut while Reduce flashing or reduced motion is on) timed inside the engine over one 1,500-tick AI match: **at most 4.8 ms for one cut, 0.007 ms averaged over all frames** (a starved run; a readback stall is mostly waiting, so it is not inflated much). On the RTX through Chrome it is small. On a GPU that shares memory it may differ; not measured.

## What is not known, and what would find it

Whether the new build is slower per frame than the old one in combat: my 16 paired runs disagree in both directions (the new build looked slower in the city brawl and ring, faster in the AI match and beam) because the cores they ran on were starved. **A valid window is needed**: the three flash captures and other sessions' Godot batches paused for about 25 minutes. The queue is ready and runs by itself when `quiet.cjs` says quiet: `scratchpad/live/chain.sh` (the cut-dissolve timing in a reduced and a full AI match, then old against new in the AI match, the beam, the ring and the city brawl at throttle 1 and 4) and `igpu.sh` (the same on the integrated Radeon).

**Where Orb's browser draws matters**: this PC has an RTX 5070 Ti and a 2-CU integrated Radeon, and a browser on Windows defaults to the power-saving GPU. My audit found the integrated GPU already at the 60 Hz limit with a miss every 20 frames in the old city brawl. If Orb's tab is on the Radeon, "tanks in combat" is that GPU; the geometry fix helps it a lot, and the answer is whether it still tanks. One question for Orb answers it: what does `chrome://gpu` (or `opera://gpu`) say for the demo tab?

## Files

`docs/perf/tools/frame-bench.mjs` (`--reduced`, `--igpu`, `--layers`, `over_25`), `make-audit-sites.mjs` (`--rev`), `scratch-hooks/hook-dissolve.mjs` (times the cut dissolve) and `hook-layers.mjs` (crowd chunks and the inset pane are cut by name). The native bench Orb can run by hand: `docs/perf/tools/orb-native-bench.cmd`.


## Part 2: the new pin 728596d0 against d3f1ca0e (valid runs)

728596d0 turns the cut dissolve off. Both builds in reduced mode, interleaved, one browser at a time, the capture cores free of other sessions' captures (every run below passed the load rule: total load 11 to 35%, capture cores 26 to 43% before; the runner now refuses to start while another capture is open). x1 is this PC's RTX unthrottled, x4 is Chrome's 4 times slower CPU (an old laptop's CPU, not its GPU).

| Scene | x1 p50 / p95 ms, old then pin | x4 p50 / p95 ms, old then pin | Main-thread CPU per frame at x4, old then pin | Draw calls, old then pin |
|---|---|---|---|---|
| City brawl | 6.3 / 9.6 then 6.7 / 9.9 | 33.6 / 58.0 then (invalid, repeating) | 40.7 then 45.1 (invalid run, indicative) | 303 then 309 |
| Signature beam in the city | 6.4 / 9.5 then 7.3 / 10.7 | 29.5 / 55.9 then 30.3 / 56.5 | 42.6 then 46.1 | 307 then 348 |
| AI match | 5.9 / 9.1 then 6.4 / 9.8 | 27.8 / 45.4 then 29.1 / 52.2 | 36.8 then 40.9 | 173 then 206 |

- **With the dissolve off the pin costs 0.4 to 0.9 ms more a frame at x1 (5 to 14%) and about 10% more main-thread CPU at x4.** Not a collapse; a slower CPU sees a few ms more.
- **Where the extra goes** (the game's own timers, x1, means, the three scenes): the GDScript pieces add only **+0.12 to +0.23 ms**, of which **`fighters_update` +0.12 to +0.18 ms** (Animation's new layers; the sim tick and FX are unchanged); the rest, **about +0.3 to +0.6 ms, is the engine's draw submission**: the draw list grew by 6 (city), 33 (AI match) and 41 (beam) calls, mostly the HUD (152 to 159 and 298 to 334 in a frozen frame).
- **The integrated Radeon is much better in the pin** (crowd chunks, no second world): frames over 25 ms, old then pin, AI match 173 of 1,200 then 30, beam 166 of 600 then 10, city 183 of 600 then 17; p95 32.8 then 22.2, 35.3 then 15.4, 35.7 then 16.0.
- **Hitches at fixed ticks remain** (AI match ticks 131 and 238, 110 to 170 ms).

**Top remaining costs and owners:** (1) **UI**: the HUD is still 159 of 176 draw calls (AI) and 334 of 360 (beam), 36 more than d3f1ca0e, with no cache; (2) **Animation**: `fighters_update` +0.12 to +0.18 ms for the new layers; (3) **Rendering and VFX**: the warm-up leaves two first-use hitches (ticks 131, 238). **Camera**: nothing left with the dissolve off.

**What Orb saw** most likely came from the dissolve (5c46feca) and/or the GPU the browser used; with the dissolve off this PC's RTX differs from d3f1ca0e by under 1 ms at x1. Orb's `chrome://gpu` answer would settle the GPU part.
