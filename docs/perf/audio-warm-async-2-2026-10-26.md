# Audio's re-cut warm-up (warm-async-2) on the phone-freeze probe, against HEAD with the first park (2026-10-26)

Owner: Performance and Platform, for the EP. Park: `docs/audio/pending/warm-async-2/` (sha1: slice.gd eb637619, audio_bank.gd 4752d0fb, audio_voices.gd 51d6086f, apply.py 99c819f0, all checked): an adaptive budget (25 ms a frame when nothing plays, 6 ms in play, 10 ms in play while cues wait), a cue asked for while its sound is queued waits and plays, and named skipped cues. Two clean `git archive` exports of HEAD 1f6b42dc, each imported and exported headless: `p1f` = HEAD as it is (it already has the first park, 6 ms a frame, from 1b3f5a29), `a1f` = HEAD plus the re-cut (`apply.py <root> --check`, then applied, from the park folder, by `hook-warmasync2.mjs`). Hooks: `hook-bootprof2.mjs` (boot marks), `hook-warmmarks-audio2.mjs` (a mark when the warm-up ends, counters every 20 frames, the bank's `skipped_report()`). Probe: `freeze-probe.mjs`, mobile emulation (Android UA, touch, 915 by 412 at 2.625), Tools' launcher, one capture at a time, taps on the first-run card and the How to play close, x1, x4 and x6 CPU (x6 a lower bound for a phone). **Every run valid** (quiet check before each, none skipped). `main.gd` does not yet have the `host.paused` line, so the adaptive budget ran on its traffic guess. One run per cell, and x4 and x6 of `a1f` twice (second run for the names).

## Results (seconds unless marked)

| | x1 | x4 | x6 |
|---|---|---|---|
| **Block before the card**, no park (89e34ec8, earlier measure) | 26.1 | 48.5 | 60.8 |
| Block, HEAD with the first park (p1f) | 24.9 | 37.8 | 45.3 |
| Block, with the re-cut (a1f) | 25.4 | 36.9, 36.5 | 45.5, 46.8 |
| **Warm-up, after the first frame**, first park | 4.7 (about 350 frames) | 53.6 (about 1,430) | 127.1 (about 2,130) |
| Warm-up, re-cut | 5.1 (about 270) | 43.9 and 41.2 (about 1,210) | 98.7 and 99.3 (about 1,250) |
| **Cues skipped** (`bank.skipped`), first park | 1 | 42 | 189 |
| Cues skipped, re-cut | 0 | 11 and 9 | 29 and 31 |
| Cues that waited and played late (`deferred_played`), re-cut | 1 | 11 and 7 | 0 and 1 |
| Stalls over 250 ms in the run, first park / re-cut | 3 / 3 | 5 / 4 | 6 / 8 |

- **The block does not change** (the re-cut moves nothing out of it; both parks already took the bank's warm-up out). It is 25 s, 37 s and 45 to 47 s of frozen splash, the engine start, `start_match` and the first frame's shader compile.
- **The re-cut loses far fewer cues**: 42 to 11 at x4 and 189 to about 30 at x6 (an 85% cut), nothing at x1. The warm-up finishes about 10 s sooner at x4 and 28 s sooner at x6, but at x6 it still takes **99 s after the first frame**, not the 40 s I estimated for a steady 25 ms.
- **Why not 25 ms: the adaptive budget never saw "nothing is playing".** At x6 the frames while warming average about 79 ms against 60 ms for the first park (127 s over 2,130 frames): that is a 10 ms slice (the in-play, cues-waiting step), not 25 ms. Behind the first-run card the AI match plays on, so cues keep arriving and the traffic guess (1.5 s of silence) never turns true. The park's own README says so: the host's line `host.audio_cues.bank.warm_quiet = 1 if host.paused else 0` in `main.gd` is what would give the 25 ms while the card is up. **I did not measure that line.** Without it the gain is the queue-jumping and the 10 ms step, which is real (above).
- **The cues still lost are the common hits**, named (second runs): x4: impact.light.lite x4, impact.light x2, windup.medium, impact.heavy, energy.bolt (9). x6: impact.light x6, impact.light.lite x5, impact.heavy x4, energy.bolt x4, impact.crater x3, impact.whiff x2, impact.medium x2, and one each of windup.medium, ui.launcher, flash.hurt.circles, energy.gather, energy.blast (31). The README expected small hits to be ready within a frame or two of being asked for; on the slowest tiers they are not, probably because the queue's front is still the sounds ahead of them. The ring's `why` and `late_ms` fields were not captured (my hook reads the summary text only).
- **x1 (this PC)**: nothing is lost (0 against 1), the warm-up runs 5 s.

## What I would do next (not measured)

1. **Land the `host.paused` line** (Rendering or UI, `main.gd`) so the 25 ms step is used while the card is up, and re-probe. The x6 warm-up is 14 s of work: at 25 ms a frame that is about 560 frames, so it would be mostly done while the card is read (5 to 15 s at 70 ms a frame is only 70 to 210 frames, so not all of it), and the cues lost in the first seconds should fall again.
2. Rendering's `warm_ids_async` for the beds, as the README says (Needs 3).
3. Ask Audio to rank the common hits (impact.light, impact.light.lite, impact.heavy, energy.bolt) first in the queue: they are the names that are lost.

## Not covered

A real phone; the host's `paused` line; the reasons the ring gives for each lost cue; one run per cell (second runs at x4 and x6 agree within 2 cues and 2 s).

## Files

`make-audit-sites.mjs` variants `p1f` and `a1f`; `scratch-hooks/hook-warmasync2.mjs`, `hook-warmmarks-audio2.mjs`; `freeze-probe.mjs` (now also saves `bpreport`). Raw runs in my scratch folder (`w/farun2/`, `w/farun3/`).
