# The VFX script cost, profiled, and the Performance level (2026-11-01)

Owner: VFX Director. Performance's order (2026-10-31, `docs/perf/quality-range.md` 2.2, `swing-tick-2026-10-31.md`): VFX is 0.41 ms mean and 1.4 p95 on the script side, and `Q_LOW` saves only 0.1 to 0.3 of it. Goal: a Performance-level cap on emitters and particles per tick, batched spawns on burst frames, and dust and debris skipped on the far side of the plane, off-identical, **target -0.5 to -0.8 ms p95 beyond LOW.** Parked in `docs/vfx/pending/perf-level/`.

## What I measured, and how far to trust it

`render/vfx/tools/perf_bench.gd` plays the real game scene (`render/main.tscn` in a SubViewport) headless, three seeds of 2,400 ticks with the forms readied and a tier raised (as `hash_check` does), one frame to the tick, and sums each frame's `h_vfx` (the hub's consume) and `r_vfxlayer` (every pane's layer update). **Headless is the dummy renderer: the numbers are the script side only, the half Performance's 2.2 table calls `h_vfx` and `r_vfxlayer`, and the GPU is not here.** The bench ran below-normal priority on a machine at 85 to 96% load (the EP's machine order), so **the absolute numbers are not valid under the rule of 2026-10-12**; the run-to-run spread is about 0.04 ms on the mean. What I rely on are the ratios inside one run, and the stage table, which is a share. A quiet-window re-run (`godot --headless --path . --script res://render/vfx/tools/perf_bench.gd -- --seeds=12345,4,7 --ticks=2400`) is the thing to ask Performance for.

## Where the time goes at LOW (the stage profile; scratch timers around every hub step and view, not in the park)

Mean ms a frame, 6,840 frames: `trail_view.update` 0.116 (it holds the shots view), `shots_view.update` 0.093, `shard_view.update` 0.047, `debris.step` 0.045, `transform_view.update` 0.036, `crack_view.update` 0.020, then 14 stages under 0.02. **No stage is large on average: the mean is spread over about forty small ones.** The p95 is different. **In the slowest 5% of frames (1.08 ms and over) the time was the shots view's flight streaks: 0.52 ms of 1.1**, then `debris.step` 0.18, `shard_view.update` 0.17, `crack_view.update` 0.09. The flight streaks are the speed lines drawn along a launched body's line of flight (Research's rec 8 and 12): the frames of a fast launch, which is the "layer 2.3x at high speed" in the order.

## What changed

**A. The flight streaks, exact (all levels, no setting).** `_flight_streaks` walks a grid of cells until it has kept 56 of them; it asked the host for both fighters' place for *every kept cell* (four host calls, 56 times a frame), and called a hash function for every cell it looked at (hundreds, to keep 56). Now the two bodies' places are read once, and the acceptance hash is written out in the loop (the same integer steps). **The streaks drawn are the same ones: a check compares the new loop with a copy of the old one over 12 camera and width combinations and finds every float of the buffer equal (672 streaks).** The slowest frames' flight streaks fell from 0.52 to 0.11 ms.

**B. The Performance level (`VfxHub.perf_level`, off by default; `data/vfx/perf.json`, `render/vfx/perf.gd`).** With the switch off nothing is read and the pool is exactly as it was (a check holds that). On:
- **A smaller pool and lower per-tick budgets than LOW:** 80 bits (LOW has 460, peaking at 140), 50 puffs and 40 shards a tick (260 and 200).
- **A burst's overflow is batched:** bits past the tick's budget wait in a queue of 60, 20 are let in each tick with their flight advanced by the ticks they waited, and one that waits 8 ticks is dropped. A collapse's overflow no longer lands on one frame.
- **The far side is skipped before it is built:** a shard or a dust burst farther than 1.4 half-views plus 1,200 units from both fighters, and dust more than 900 units behind the fighter plane, is not made. The random draws it would have taken are still taken, so the stream a later spawn reads is the one it would have read.
- **At most two of the pool's timed jobs run in a tick** (the ripples and the floors' waves); the rest run on the next.

## Result

VFX script ms, mean and p95 (three seeds, one process each; the spread between runs is about 0.04 on the mean):

| | High | Low | Low + Performance level |
| :--- | ---: | ---: | ---: |
| Before (HEAD) | 0.683 and 1.762 | 0.475 and 1.017 | (caps at 220 and 90, 70) 0.450 and 0.945 |
| After A | 0.603 and 1.388 | 0.431 and 0.805 | |
| After A and B (as parked) | | 0.424 and 0.788 | 0.425 and 0.754 |

**So A took 0.21 to 0.23 ms off LOW's p95 (and 0.37 off High's), at every level and with no look change. B, beyond LOW, takes only 0.03 ms off the p95 and 0.16 off the p99** (mean unchanged). **The target of 0.5 to 0.8 beyond LOW is not reached by what was asked for**, and the profile says why: at LOW the pool peaks at 140 bits and a frame's pool cost is `debris.step` plus `shard_view.update`, about 0.1 ms each in a busy frame: the caps cannot save what is not spent. B is real for the burst frames (the p99 and the max: a collapse's frame is the one it flattens) and it is the lever for a machine five times slower, where the same bits cost five times as much; but on this bench its gain is small.

## What is left, in order of the profile (not built)
1. **`shots_view.update`'s idle cost, 0.09 ms a frame on average (a fifth of LOW's mean):** it runs the press, zip, reach and glare drawing every frame (`sv:_press` 0.022 of it) when nothing is happening; each needs a "nothing to draw" early out that is exact (the hub knows when no press, zip or reach event is live).
2. **`trail_view.update`'s own work and `transform_view`** (0.036, standing even with no transformation).
3. **The pool's per-bit cost** (1.6 µs a bit in `debris.step`, the same in `shard_view.update`): a packed-array pool instead of an Array of objects is the big one and a rewrite; not for tonight.
4. A quiet-window measurement on the Radeon with Performance's stage hook.

## Where it lives
`render/vfx/perf.gd`, `data/vfx/perf.json` + `tools/schemas/vfx-perf.schema.json` (+ map row, seven cases), the pool's fields in `debris.gd`, the switch in `vfx_hub.gd` (a field, set by Rendering's or UI's ladder), `render/vfx/tools/perf_bench.gd`, `_perf_level()` in effects_check (10 checks).
