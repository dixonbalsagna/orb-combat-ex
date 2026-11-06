# Does machine load change a flash reading? (Tools, 2026-10-30)

The EP's question, from Orb: stop voiding flash readings because the machine was busy. All the load comes from our own sessions, and there is no quiet to wait for. `capture-web.mjs` steps exactly one tick a frame, so load should make a capture slower and not different. The void rule rests on one incident (2026-10-12, a one-frame artefact of 87,000 pixels that turned a 2 into a 2.5). Animation read HEAD's collapse clip at 3.5 under load while others read 2 and 2.5.

## What was measured

Same export, same clip (`collapse`, seed 12345, normal, 1500 ticks, 1024x768), captured twice in a row while the nightly and everyone else's gates kept the machine at 87 to 100% (never below 74%; no quiet window existed to compare with), and the two compared frame by frame (`compare-frames.mjs`'s decoder, tolerance 0 and 8).

| build | captures | frames byte-identical | frames that differ | the worst frame | the readings |
| --- | --- | --- | --- | --- | --- |
| pin 257a766c as it is | 2 at 87 to 100% load (8.7 and 7.2 frames a second) | 210 of 1500 | 1290 | 0.126% of the pixels (993 of 786,432), in a band across the ground, from tick 2 on | identical, 2 / 3.5 / 1 both times |
| the same with `TIME` in `render/shaders/crowd.gdshader` replaced by 0.0 (scratch copy) | 2 at 76 to 88% load (7.3 and 8.7 frames a second) | **1496 of 1500** | 4 | 1 to 4 pixels, one grey level (GPU rounding) | not read: the frames are the same |

**So load does not change the frames; one wall-clock read in the render does.** `crowd.gdshader` uses the engine's `TIME` three times (the civilians' run cycle, the startle tremble, the idle hop), so the crowd's pose depends on when the page started, not on the sim tick. That shows as a band of scattered pixels at ground level in every capture, load or no load (two captures at the same load differ as much as two at different loads). With the clock pinned, two captures at different loads are the same picture. The flash readings did not move with it (2 / 3.5 / 1 both times), because the crowd is small and never near a counted change.

The 87,000-pixel artefact of 2026-10-12 was a one-frame event, not a load level. A test of the frames finds it; a test of CPU percent does not.

## Why the same collapse clip reads 3.5 for one session and 2 for another

Not load: frame size (Rendering found it first; the table below confirms it, and it is the same on the pin and on main). Collapse-normal, seed 12345, 1500 ticks:

| size and scale | pin 257a766c | main b7a2cd86 |
| --- | --- | --- |
| 960x540 full-size | 3.5 / 3.5 / 1 | 3.5 / 3.5 / 1 |
| 960x540 half (scale 2) | 2.5 / 3.5 / 2 | 3.5 / 3.5 / 1 |
| 1024x768 full-size | 2 / 3.5 / 1 | 2 / 2.5 / 1 |
| 1024x768 half (scale 2) | 2.5 / 3.5 / 2 | 2 / 2.5 / 2 |

(primary / area-15% / two-second memory). The first blast (ticks 66 to 72) puts changed pixels in one analyser window at **0.91 of the area threshold at 1024x768 and 1.23 of it at 960x540**: at 4:3 it misses by a tenth and at 16:9 it counts, once, at tick 69. It is **not** the shape of the analyser's window: the same 960x540 frames read 3.5 under four windows (a third by a third, 4:3 of the same height, 4:3 of the same width, a square). It is where the blast lands relative to the threshold, so a clip with a blast near the threshold is size-sensitive. Box-averaging to the half scale also moves the count (the pin's collapse-normal at 960x540 reads 3.5 full-size and 2.5 at the half scale). Legal's RL-209 answers it by counting the worst of four readings (two sizes, two scales) for the fixed clips (docs/tools/pin-child.md).

## The proposed rule (replacing "void if the machine was busy")

1. **A tick-locked clip counts at any load.** Drop the frames-a-second void (`MIN_FRAMES_A_SECOND`, tools/flash/release-pass.mjs) and the quiet-machine wait; the capture's own time limit stays (a capture that does not finish is not a reading). The load before and after stay recorded (information, not a condition).
2. **The capture proves itself, by its frames.** After a clip is read, re-capture the frames behind its peak readings (the worst second and every dip: the ranges `run-pixels --keep-ranges` already keeps, with `--skip` fast-forwarding to them; a window of about 250 ticks is a minute or two) and compare them with the first capture's frames by `compare-frames.mjs`. A reading stands when the re-captured window **reads the same** and its frames are **byte-identical or within the noise bound** (the bound is measured on the build: 0.158% of the pixels while the crowd clock leaks, 0.0000% when it does not). A frame beyond the bound is an artefact to find, and the reading does not stand until it is explained or the window re-captured again. That detects the one case the old rule came from (a one-frame spike that does not reproduce) at any load.
3. **Fix the leak so the bound is zero.** Pass the crowd shader a uniform driven by the sim tick (the crowd's code that sets the shader's parameters feeds it; the three `TIME` reads go) so a capture is byte-reproducible; until then the bound above is used. Rendering's file; one line each in three places; no look change by design (a frozen crowd phase is replaced by a tick-driven one).
4. **Release-pass rows record the proof, not the load**: `proof: { window: [from, to], frames, identical, withinNoise, bound }` replaces the load fields as the gate; the guard (CPU cap, time limit, tag) stays as information.

**Not done, and why:** the window re-capture itself and a capture under deliberate starvation (16 busy loops on the capture's cores) were queued behind the EP's priority reads and stopped by the pause; the proposal's re-capture step is therefore designed on a hook that supports `--skip` ("the same sim as a clip that drew them", flash_capture.gd) but not yet shown byte-identical on a window. The lowest load obtained was 74%.

## Which measurements need quiet

- **Wall-clock figures**: frame times and their percentiles (`docs/perf/tools/frame-bench.mjs`, `latency-bench.mjs`), boot and load times, the audio warm-up, hitch probes. Contention changes them directly. Two partial remedies exist: `frame-bench` already records **CPU milliseconds per frame** (renderer and gpu-process, `cpu_ms_per_frame`), a figure that load inflates much less than the wall clock (SMT, cache and turbo still move it; by how much is not measured here), and a **calibration spin** (a fixed loop timed before and after a run) would give a load factor to divide by. Neither is proved; the proposal is to report CPU time per frame as the load-tolerant figure and keep wall-clock percentiles as quiet-only, and to measure once, on the next quiet window, how far each moves between a quiet and a loaded run of the same scene.
- **Not wall-clock, so no quiet needed**: every flash reading (tick-locked), frame comparisons, the headless sim runs (determinism), counts of events and draw calls.

## What Legal must accept (the rule touches RL-131 and the release-pass condition)

- RL-131 (addendum 7): a clip captured on a starved machine is void, and the rate under 1 frame a second voids it. The proposal replaces both with the frame proof; the second capture of a clip whose worst second is above 2.0 and the re-capture of a sensitive clip (a different run, never a later window of the same run) stay as they are. The proof window is a re-capture of the **same** run, so it does not replace the sensitive clip's second run.
- The release-pass record's capture-condition fields become information, and the proof fields become required.
- Tools' nightly already runs under load (the whole night here ran at 74 to 100%): its readings stand under the rule, with the proof run on a reading that is at or over a tripwire.
