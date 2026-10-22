# The inset warm-up, the tick-131 hitch and the aura's cost (2026-10-22)

Owner: Performance and Platform, for the EP. Builds: clean `git archive` of HEAD d4795fa5 (render/ is main's 5fe08207; later commits are docs and parked work), the web export, Tools' capture hook, reduced mode, a fresh browser profile per run (cold at the browser level; the GPU driver's own shader cache persists between runs, so a first run after a reboot may be colder still). A run is valid by the load rule (all processors 60% or less, capture cores 70% or less); invalid ones are marked and only used for the tick at which something happens, which does not depend on load. Variants are in `make-audit-sites.mjs` (`base`, `nowarm` = the inset warm-up patch reversed, `aura`, `evlog`, `evprof`); the repro is below.

## 1. Camera's inset warm-up: it does not move or shrink the hitch

The AI match (seed 4) hitches at two fixed ticks, 131 and 238, with and without the warm-up. Hitch (ms), with the warm-up then without:

| GPU | tick 131 | tick 238 |
|---|---|---|
| RTX 5070 Ti, valid runs from match start (2) | 77, 94 then 77, 95 | 161, 178 then 194, 181 |
| RTX, 600-tick runs (3 each, invalid by load, ticks exact) | 111 to 123 then 110 to 121 | 212 to 238 then 214 to 228 |
| Integrated Radeon, valid (2) | 115, 114 then 130, 115 | 224, 217 then 246, 249 |

- **No hitch appears at the match start in either build** (runs from tick 0: the first frames show nothing over 50 ms), and the tick-238 hitch is the same size and at the same tick with the warm-up. On the RTX the difference is inside the run-to-run spread; on the integrated GPU it is about 25 ms of 220 (a tenth), two runs each.
- **What is at tick 238** (the event log, `hook-evlog.mjs`): the match's first crater (`scorch`, `crater`, `dust`, `spark`, `shake`), and that is also the moment Camera's strip opens. With **no strip** (`nopanel=1`) or **no camera at all** (`nocam=1`) the hitch is still **160 ms**, so about **160 ms is the crater's first use and about 55 ms (215 against 160) is the strip's first drawn frame, which the warm-up was meant to remove and does not**.
- **The strip's frame in numbers:** at tick 238 the draw list goes from 91 to 122 calls and the primitives from 186 k to 650 k for as long as the strip is up (it is a second drawing of the world); with the strip off the same tick adds 5 draws and 3 k primitives. The game's own CPU timers (sim tick, fx, view) read 0.8, 1.8 and 6.3 ms on that frame: the 215 ms is not game code but the driver's first use of something.
- **A hypothesis for Camera (not tested):** the warm-up draws the inset's viewport once (UPDATE_ONCE), but the strip's own TextureRect and its material (`_panel_mat`) are drawn only when the strip is visible, and the real strip also uses the cutaway request with targets. If the first-use cost is the strip material's pipeline or the cutaway variant of the terrain shader, the warm-up has to draw those too. A strip visible for one frame is not an option under the look gate, so it has to be a hidden draw at boot, as VFX proposes for the shards.
- The crater's 160 ms is a separate first use (scorch, crater, dust in one tick). Next look: Rendering's boot warm-up with VFX (what draws first at a crater).

## 2. The tick-131 hitch reproduces cold, and it is the driver, not game code

- **It happens in every run (14 of 14 from the first frames, reduced and full mode), 75 to 125 ms on the RTX and 95 to 115 ms on the integrated Radeon**, at the first hit of the match: the events of that tick are `spark`, `shake`, `damage`, `cue`.
- **The frame's numbers** (evprof, the profiling timers differenced): particles 21 to 29 (the first shard burst), draw calls 95 to 97, primitives +29, the game's own timers add under 1.5 ms in total (the host's advance +1.7 ms is the largest), the renderer's CPU time 0.1 ms. So it is **not CPU work in the game**; the cost lands in the 2 new draws: a first use in the driver (a shader variant or the multi-mesh's buffer), which fits VFX's reading.
- **Repro for VFX's candidate** (shard MultiMesh drawn once at boot in its real configuration):

```
node docs/perf/tools/make-audit-sites.mjs --out <scratch>/main --only base --rev HEAD
node docs/perf/tools/frame-bench.mjs --site <scratch>/main/base/build/site --scene ai --reduced --ticks 400 --out r.json
```

`r.json` `hitches` reads `[[131, ~110], [238, ~215]]` on the RTX. To test a candidate, add a spec to `SPEC` in `make-audit-sites.mjs` with their change as a patch (as `aura` does) and compare the same command. `evlog` and `evprof` add `hitchEvents` (the tick's event types) and `hitchRows` (the draw list around it). A candidate works if tick 131 drops under about 30 ms in the same run.

## 3. The aura (docs/vfx/pending/aura3d, off): cost on the old-laptop bound

Both patches apply clean on HEAD. The aura is turned on by a page flag; `auradem=1` also holds both shells at full level the whole time (the steady worst case, since the real rules show it as a burst of about 2 s once in 4). Valid runs, two repeats each, interleaved; p50 / p95 ms.

| Scene | Frame, base then aura (burst rules) then aura (steady) |
|---|---|
| AI match, x4 CPU, integrated GPU | 28.4 / 52 then 27.0 / 49 then 27.8 / 50 |
| Beam in the city, x4 CPU, integrated GPU | 36.9 / 62 then 35.9 / 60 then 35.4 / 61 |
| AI match, RTX unthrottled (one valid run) | 5.6 / 9.0 then (not run) then 6.0 / 9.6 |
| AI match, integrated GPU unthrottled | 8.3 / 21.3 then (not run) then 8.9 / 22.3 |
| Beam in the city, integrated GPU unthrottled | 11.8 / 14.5 then (not run) then 12.4 / 15.0 |
| City brawl, integrated GPU unthrottled | 11.7 / 14.0 then (not run) then 12.3 / 14.7 |

- **On the old-laptop bound (x4 CPU, integrated GPU) the aura is not measurable**: base against aura differ by less than the spread between two runs of the same build (up to 5 ms at p50 in these CPU-bound scenes). It adds **1 to 2 draw calls and about 4.7 k primitives**, nothing else in the draw list.
- **Where the GPU is the limit (integrated GPU unthrottled) the steady worst case costs about +0.5 to +0.7 ms a frame (5 to 8%)**, and **on the RTX +0.2 to +0.4 ms**. The depth copy it needs (the Compatibility renderer copies the scene depth when a shader reads it) is not a draw call; it shows only in this frame time.
- **Frames over 16.7 ms on the integrated GPU, city brawl: 1 and 3 in 600 without, 11 and 13 with the aura held up** (p99 15 then 40 ms); the beam scene is the same (17 against 17 and 18) and the AI match 116 and 115 against 126 and 123. So the steady worst case pushes about 2% more frames of a brawl past 60 Hz on that GPU. Under the real burst rules it is up a fraction of the time, so the mean is smaller; I did not time the burst on the unthrottled integrated GPU.
- **A first-use hitch of 50 to 75 ms** appears at the first tick the shell draws in the city scenes (tick 121 in the three unthrottled brawl and beam runs with the aura, none without; the AI match shows none on the RTX), although the patch adds the shader to `RenderWarmup.SHADERS`. The warm-up does not draw it in its real configuration (a sphere shell reading depth, in a fight's pass). Same class as ticks 131 and 238.
- **Verdict for the gate:** the cost is inside the budgets on the old-laptop bound and under 1 ms on every GPU measured, so it can go default-on from the performance side **once its first draw is in the boot warm-up** (the 50 to 75 ms hitch). Not measured: a phone GPU, and the burst rules on the unthrottled integrated GPU.

## Files

`docs/perf/tools/make-audit-sites.mjs` (variants `nowarm`, `aura`, `evlog`, `evprof`), `scratch-hooks/hook-aura.mjs`, `hook-evlog.mjs`, `inset-warm.patch` (the reverse of Camera's warm-up, as it was parked), `frame-bench.mjs` (`hitchEvents`, `hitchRows`). The raw runs are in my scratch folder, not the repo.
