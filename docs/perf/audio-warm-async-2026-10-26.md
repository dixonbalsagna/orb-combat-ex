# Audio's warm-async park against plain HEAD 89e34ec8, on the phone-freeze probe (2026-10-26)

Owner: Performance and Platform, for the EP. Park: `docs/audio/pending/warm-async/` (`bank.warm()` sliced across frames, `AudioSlice.budget_us` 6 ms, bit-identical buffers, `bank.skipped` counts cues dropped while warming). Two clean `git archive` exports of 89e34ec8, headless import and Web export: `p89` plain, `a89` with the park (`python apply.py <root> --check` passed, then applied, from the park folder; scratch hooks `hook-bootprof2.mjs` for time marks in `main._ready`, `hook-warmasync.mjs`, `hook-warmmarks-audio.mjs` for the `warm_async_done` mark and a sample of `bank.skipped` and `bank.warming` every 20 frames). Probe: `freeze-probe.mjs`, mobile emulation (Android UA, touch, 915 by 412 CSS px at 2.625, a 2402 by 1082 canvas), through Tools' launcher, one capture at a time, **every run valid** (quiet check before each: nothing skipped), taps on the card at +0 s and the How to play close at +8 s after the first frame. One run per cell, so the cells carry the run-to-run noise of a few percent; x4 and x6 are Chrome's CPU throttle, x6 a lower bound for a phone.

## 1. The block, with and without the park (seconds; the one long main-thread task before the card)

| Throttle | Plain HEAD | With the park | Removed | Audio warm-up inside `_ready`, plain | with the park |
|---|---|---|---|---|---|
| x1 (this PC) | 26.1 | 24.5 | 1.6 | 2.07 | 0.01 |
| x4 (old laptop) | 48.5 | 37.5 | **11.0** | 9.94 | 0.03 |
| x6 (phone estimate) | 60.8 | 46.6 | **14.2** | 14.07 | 0.05 |

The park removes exactly the bank's warm-up from the block, no more (the saving matches the plain warm-up inside 0.5 s at every throttle). What is left is the engine start, the `start_match`, and the first frame's shader compile: 24.5, 37.5 and 46.6 s. **A phone still sits on a frozen splash for most of a minute; the park takes about a quarter off, not the freeze away.** (HEAD's block is longer than the pin's 22 s, mostly the first frame: 19 s at x1.) Stalls over 250 ms after the card: x1 4 to 3, x4 9 to 4, x6 7 to 7: the intro is no worse.

## 2. The warm-up's wall time in frames

The warm-up now starts at the first frame and ends in the frames after it. Frames counted from the first frame (`process_frame_0`); the warm-up's own work is unchanged (2.0, 9.9 and 14.1 s of CPU in total), it is only spread:

| Throttle | Frames to finish | Wall time after the first frame | Per frame while warming |
|---|---|---|---|
| x1 | about 350 (warming through sample 340, clear by 360) | 4.7 s | about 13.8 ms, steady play about 7 ms |
| x4 | about 1,370 | 46.4 s | about 34 ms against about 25 ms |
| x6 | about 2,150 | **145.4 s** | about 68 ms against about 54 ms |

At 6 ms a frame the slice costs one extra 6 ms (on the throttled clock) on every frame, so the game runs 10 to 20 ms a frame slower than steady state for 5 s (x1), 46 s (x4) and **2.4 minutes (x6)**; that is the price of a short block. (Frame times are averages over the warming window against the rest of the run; I did not extract the worst frame.)

## 3. Cues dropped (`bank.skipped`)

| Throttle | Dropped by the end of the warm-up | When |
|---|---|---|
| x1 | **1** | 2.3 s after the first frame (the intro's first cue) |
| x4 | **31** | 3 in the first 12 s, 22 by 17 s, all 31 by 27 s |
| x6 | **176** | 10 by 11 s, 37 by 16 s, 80 by 31 s, 141 by 64 s, 176 by 90 s; then the counter stops (the rest of the warm-up is quiet) |

After the warm-up is done the count stays flat to the end of the run (110 s, 260 s, 360 s). **At x1 it is nothing; at x4 the first 27 s of the match lose 31 cues; at x6 a player hears about one cue in three for the first 90 s and has a bank that is 145 s from complete.** `bank.skipped` counts every cue, so the figure includes the intro's ambience and the AI match's hits; it does not say which ones the player misses.

## 4. The budget I would suggest on the first-run card

The cost is a trade of wall time for block: a larger `budget_us` shortens the warming window (frames needed = work / budget), at the price of longer frames while it runs. By the numbers above (estimate, **not measured**: I did not re-run the park with another constant):

- The card (the notice, then the How to play card) has no fight the player can lose, so a long frame there is free; a drop of cues behind a card costs nothing either. **Use a large budget while the first-run card is up (25 to 30 ms a frame, a whole frame's worth at 30 fps), and the 6 ms the park ships with once play starts.** The warm-up's work at x6 is 14 s: at 25 ms a frame that is 560 frames, about 40 s of card-time at 70 ms a frame, against 145 s today; the card is read for 5 to 15 s, so it would be done about a third of the way into the match instead of after 2.4 minutes, and the cues dropped under the match would fall from 176 to about 40. At x4 (10 s of work, 400 frames at 25 ms) it is done in 14 s and the 31 drops mostly vanish.
- If the card gives the page only a few seconds, a better answer than any one number is **a budget that grows while nothing is playing**: 6 ms with a fight on screen, 25 ms with the card or the menu up.
- Also worth doing whatever the budget: let the audio engine drop the **cue's first play, not the cue**, by rendering it on demand while its warm-up is queued. Then `skipped` should be 0 at every tier. That is the Audio director's call.

I can re-run x4 and x6 at 25 ms (one rebuild, 2 captures, about 25 minutes of quiet machine) if the EP wants the measured numbers.

## Not covered

One run per cell; a real phone's audio decode (the render is CPU, but a phone's browser may run the Web Audio output path differently); which cues were dropped (the counter has no names); whether the card pauses the sim (I did not check, so "a fight the player can lose" assumes the AI match behind the card is not scored).

## Files

`make-audit-sites.mjs` variants `p89` and `a89`; `scratch-hooks/hook-bootprof2.mjs`, `hook-warmasync.mjs`, `hook-warmmarks-audio.mjs`; `freeze-probe.mjs`. Raw runs in my scratch folder (`w/farun/`).
