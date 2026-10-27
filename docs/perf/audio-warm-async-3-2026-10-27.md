# Audio's warm-async 3 on the phone-freeze probe, HEAD 19e56ab3 (2026-10-27)

Owner: Performance and Platform, for the EP. One clean `git archive` export of 19e56ab3 (variant `p1f` with `--rev 19e56ab3`: boot marks, counters, the bank's `skipped_report()`), imported and exported headless, no park applied (warm-async 3 is on main). Same probe as the warm-async-2 note: mobile emulation (Android UA, touch, 915 by 412 at 2.625), Tools' launcher, one capture at a time, taps on the first-run card and the How to play close, x4 and x6 CPU (x6 a lower bound for a phone), two runs per cell. **All four runs valid** (quiet check before each, none skipped). `main.gd` still has no `host.paused` line, so the quiet budget never turns on behind the card.

## Results (seconds unless marked)

| | x4 | x6 |
|---|---|---|
| **Block before the card** (longest main-thread stall), warm-async 2 (a1f) | 36.9, 36.5 | 45.5, 46.8 |
| Block, warm-async 3 | 38.2, 37.7 | 45.7, 47.6 |
| **Warm-up after the first frame**, warm-async 2 | 43.9, 41.2 (about 1,210 frames) | 98.7, 99.3 (about 1,250 frames) |
| Warm-up, warm-async 3 | 30.1, 31.6 (840, 900 frames) | 110.0, 108.2 (1,660, 1,520 frames) |
| **Cues skipped** at the end, warm-async 2 | 11, 9 | 29, 31 |
| Cues skipped, warm-async 3 | **0, 0** | **7, 6** |
| Cues that waited and played late, warm-async 3 | 1, 1 | 1, 1 |

- **Skipped cues**: 0 at x4 (was 9 to 11) and 6 to 7 at x6 (was about 30). At x6 the lost ones are 5 to 6 of the rarer sounds, not the common light hits: impact.heavy x1 to x2, impact.medium, impact.crater, flash.hurt.circles in both runs, plus voice.protagonist.pain.limb/head and voice.anti_hero.effort.heavy (run 1) and flash.found.blades (run 2). impact.light, impact.light.lite and energy.bolt are no longer in the list. At x6 the skips come in the first 90 s after the first frame (2 and 1 by frame 200, 7 and 5 by frame 600).
- **Block**: unchanged within noise (the x4 pair reads about 1 s longer than warm-async 2, inside the 1 to 2 s spread between repeats). The 120 ms boot slice adds 0.5 to 0.7 s at x4 and x6 on a 37 to 47 s block.
- **Warm-up length**: x4 is 12 s shorter (30 to 32 s against 41 to 44 s). **x6 is not shorter: 108 to 110 s against 99 s.** It takes more frames (1,500 to 1,660 against about 1,250) at the same per-frame cost, so the budget stayed at the in-play step and the work grew (variant by variant, with the common hits first). As the EP expected, the AI match behind the card keeps the quiet budget off until the `host.paused` line lands. I did not measure that line.
- **x1** was not re-run (nothing was lost at x1 with warm-async 2, and the boot slice is the only x1 change).

## Not covered

A real phone; the 25 ms step behind the card (needs the `host.paused` line in `main.gd`); the ring's `why` and `late_ms` for each lost cue (my hook reads the summary text only); two runs per cell.

## Files

`make-audit-sites.mjs --rev 19e56ab3 --only p1f` (no change to the script); `scratch-hooks/hook-warmmarks-audio2.mjs`; `freeze-probe.mjs`. Raw runs in my scratch folder (`w/farun4/`).
