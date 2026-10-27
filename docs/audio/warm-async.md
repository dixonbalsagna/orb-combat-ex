# The audio warm-up across frames (2026-10-26)

Owner: Audio and Music, for the EP's priority brief after Performance's `docs/perf/phone-freeze-2026-10-26.md` (§1 and §3, 89e34ec8): on the live pin `bank.warm()` rendered every sound inside `main._ready`, one synchronous block of 2.0 s on this PC, 9.7 s at 4x CPU and 14.4 s at 6x, a quarter of a phone's frozen splash. **Parked** (`docs/audio/pending/warm-async/`); nothing outside `audio/` and `docs/audio/` changes.

## What it does

`bank.warm()` is called in `main.gd` as before, and now **returns at once on a game with a screen**: it queues every sound it used to render and renders them **a few milliseconds a frame**, most wanted first. Nothing in `render/` changes. A headless run, a tool or a test (no screen) still gets the one block, as today.

- **Time-slicing without a second implementation.** The synths' long loops (`ImpactSynth`, `GruntSynth`, `FlashSynth`, `BabbleSynth`, `DroneSynth`, `AmbienceSynth`, and the loops of `AudioDsp` through `AudioDspA`) are written as coroutines: a loop of 1,024 iterations at a time with `if AudioSlice.due(): await AudioSlice.next_frame()` between the chunks. **The arithmetic and its order are untouched**, so the output is the same bits. The public functions keep their names and signatures as thin sync wrappers (`AudioSlice.run_sync`) that run the coroutine with slicing off, so it never suspends: every caller (the bank, the tools, the tests) is unchanged. With slicing off `due()` is false and the cost of the chunking is nil (measured: 1,745 ms against 1,772 ms for the same 255 clips, back to back).
- **Most wanted first** (`AudioBank.warm_plan`): the babble (the intro's lines), the grunts, then the hits and the rest of the match's sounds, then the head flashes, then the optional sets (drones, surfaces). Within a rank, the bank's own order.
- **A knob:** `AudioSlice.budget_us`, 6,000 microseconds of synthesis a frame by default. The longest run between two yields is the budget plus one chunk (a chunk is 1,024 iterations of the longest loop, about 1.1 ms on this PC).

## The fallback for a sound asked for before it is rendered

While the warm-up runs, `AudioVoices.play` **drops** a cue whose sound is not rendered yet (silently, counted in `bank.skipped`), and plays it as ever once it is. Not a hitch: a late render of a sound on a phone would be a block of up to 78 ms x CPU factor in the middle of a fight, which is what the warm-up exists to avoid. The most wanted sounds come first, so on a desktop everything the intro and the first blows play is ready within the first seconds (the whole run is about 1.8 s of CPU, 6 ms a frame: about 5 s of frames here). Once the run is over an un-warmed sound renders on its first play, as it always did. A sound rendered synchronously by anything else (the UI timing a line to its grunt, a tool) meanwhile goes straight into the same cache and the run skips it.

## Proof (scratch export of HEAD, the park applied)

- **Bit-identical.** `warm_hashes.gd` dumps the sha256 of every buffer the bank can render (305 clips: the 255 of `warm()`, the surfaces, the beds, the drones); HEAD without the park and with it give the same file. `warm_async_check` (new) compares the **streams** (format, rate, bytes) of all 285 clips rendered across thousands of frames at a 1 ms budget with `warm()`'s: 0 differ.
- **The slices.** At a 1 ms budget the longest run between two yields was 2.1 ms (the chunk is the granularity). The 4x bar: the budget is wall time, so a CPU 4 times slower runs the same budget and a chunk 4 times longer (4.4 ms): the longest main-thread call in the warm-up is about 6 + 4.4 = 10 ms at 4x, under the 50 ms the brief asks for (the largest single sound used to be 78 ms at 1x, 312 ms at 4x).
- The nine audio checks pass (`world_check`, `tone_check`, `carry_check`, `tug_check`, `brawl_check`, `beat_check`, `babble_check`, `warm_check`, `host_check`), and `host_check`'s sim hashes and cue logs are identical to HEAD's. Headless still renders the block (`warm_async_check` section 5).
- **Not measured here:** Performance's freeze probe (`docs/perf/tools/freeze-probe.mjs`, which needs Chrome through Tools' launcher). On their numbers the gain is the 2.0 / 9.7 / 14.4 s (x1 / x4 / x6) taken out of `_ready`'s block, moved into frames of about 6 ms each.

## For the host

- The beds the world mapper wants (`AudioWorld.warm_beds(S)`) can use the same machinery without a block: `bank.warm_ids_async(cues.world.warm_beds(S))` queues them behind what is running (each bed is 160 ms of CPU at 1x). Rendering's boot warm-up is the owner of that call.
- `bank.warming`, `bank.warmed` (a signal) and `bank.skipped` say where the run is, for a progress line if UI wants one.
- Web: GDScript coroutines are the same on the web build; no thread is used (the web export has none). The run needs a node in the tree to give it frames: `AudioVoices` sets `bank.async_ok` when it enters the tree, which `main.gd` does before it calls `warm()`.

## Not done

The freeze probe on a phone-like throttle; the intro's own first draws (Rendering's); the `start_match` block (Simulation and World's). The explicit call (`warm_async_begin`) in `main.gd` instead of the implicit redirect inside `warm()` is a one-line choice for Rendering if they prefer it to be visible there.
