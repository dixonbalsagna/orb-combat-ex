# The audio warm-up across frames (2026-10-26, re-cut the same day)

Owner: Audio and Music, for the EP's priority brief after Performance's `docs/perf/phone-freeze-2026-10-26.md` (§1 and §3, 89e34ec8): on the live pin `bank.warm()` rendered every sound inside `main._ready`, one synchronous block of 2.0 s on this PC, 9.7 s at 4x CPU and 14.4 s at 6x. First cut: `docs/audio/pending/warm-async/` (Performance measured it: `docs/perf/audio-warm-async-2026-10-26.md`, 66fcf873: the block loses exactly the warm-up; but at a flat 6 ms a frame the run took 46 s at x4 and 145 s at x6, and dropped 31 and 176 cues). **Re-cut:** `docs/audio/pending/warm-async-2/`. Nothing outside `audio/` and `docs/audio/` changes.

## What it does

`bank.warm()` is called in `main.gd` as before, and now **returns at once on a game with a screen**: it queues every sound it used to render and renders them across frames, most wanted first. Nothing in `render/` changes. A headless run, a tool or a test (no screen) still gets the one block, as today.

- **Time-slicing without a second implementation.** The synths' long loops (`ImpactSynth`, `GruntSynth`, `FlashSynth`, `BabbleSynth`, `DroneSynth`, `AmbienceSynth`, and the loops of `AudioDsp` through `AudioDspA`) are coroutines: 1,024 iterations at a time with `if AudioSlice.due(): await AudioSlice.next_frame()` between the chunks. **The arithmetic and its order are untouched**, so the output is the same bits. The public functions keep their names and signatures as thin sync wrappers (`AudioSlice.run_sync`), so every caller is unchanged. The chunking costs nothing measurable (1,745 ms against 1,772 ms for the same 255 clips).
- **Most wanted first** (`AudioBank.warm_plan`): the babble (the intro's lines), the grunts, then the hits and the rest of the match's sounds, then the head flashes, then the optional sets (drones, surfaces).

## The budget adapts (re-cut, item 1)

`AudioSlice.budget_us` is no longer one number. The bank names it afresh at the start of every frame the run gets (`AudioBank._pick_budget`):

| When | Budget a frame |
| :--- | :--- |
| **Nothing is playing**: the host says so (`bank.warm_quiet = 1`: the first-run card, How to play, a menu, the loading screen, the sim paused), or, if it has not said (`-1`, the default), no cue has been asked for 1.5 s | **25 ms** (`quiet_budget_us`): a long frame behind a card costs nothing |
| A fight is on (`warm_quiet = 0`, or cues are being asked for) | **6 ms** (`play_budget_us`) |
| In play, with cues waiting for their sound | **10 ms** (`pending_budget_us`) |

Without the host's word the cue traffic decides: while the sim is paused (every overlay pauses it: `main._hold_for_overlay`) no cue is asked for, so after 1.5 s the budget goes up by itself; a lull of 1.5 s in a live fight is rare but would give one long frame, which is why **the host's word is better**: one line in `main.gd`'s frame, `host.audio_cues.bank.warm_quiet = 1 if host.paused else 0` (Rendering's file; not applied here). Perf estimates x6 then finishes in about 40 s of card-time against 145 s.

## A cue asked for before its sound is rendered (re-cut, item 2)

The first cut dropped it. Now **its sound jumps to the front of the queue** (`bank.warm_want`) and renders in the next slices (the same sliced code, so no long render, at any CPU), and **the cue waits in `AudioVoices` and plays when the sound is ready, unless it would be later than its own length** (the stream's length over the cue's pitch): then it is lost. A cue waits at most 6 s and at most 24 wait at once (the oldest is lost). In the check a held cue's sound was rendered in 5 frames and the cue played, with nothing skipped. In play, a loss now means a sound that took longer than its own length to be rendered after it was wanted: a big sound at x6 (about 0.5 s of CPU at 10 ms a frame is several seconds), so the biggest sounds can still be lost on the very slowest phone if the player is fighting in the first seconds, but the common small ones (light and medium hits, 6 to 10 ms of CPU) are ready within a frame or two.

## The lost cues are named (re-cut, item 3)

`bank.skipped` counts them; `bank.skipped_log` is a debug ring of the last 64 (`{sound, variant, why, late_ms, ms}`; why is `late`, `timeout` or `overflow`); `bank.skipped_by_sound` counts all of them; `bank.skipped_report()` prints "skipped N: impact.heavy x3, ... (played late: M)". `bank.deferred_played` counts the cues that waited and then played.

## The common hits first (warm-async-3)

Performance's re-probe of the re-cut (`docs/perf/audio-warm-async-2-2026-10-26.md`, 404fea20) cut the lost cues from 42 to 11 at x4 and from 189 to about 30 at x6, but the ones still lost were the common hits (impact.light, impact.light.lite, impact.heavy, energy.bolt, then crater, whiff, medium): a jump to the front costs the sound's whole render, which at x6 is longer than a hit's own length. So the queue is now ordered by what the fight plays most (`AudioBank.WARM_FIRST` and `WARM_SECOND`):

1. **The cheap common hits**, about 85 ms of CPU in all at 1x: impact.light, light.lite, whiff, guard, absorbed, energy.bolt and bolt.lite, windup.medium, ui.launcher, the perfect and charge ticks, energy.gather. **The run's first slice, inside `warm()` at boot, is 120 ms long** (`bank.boot_slice_us`), enough to render these at 1x; at x6 it renders the first part and the first frames the rest. It adds 0.1 s to a boot block of 25 s or more.
2. The intro's babble. 3. The grunts.
4. **The dear common hits**, right after: medium, heavy, crater, the blast, the double, the heavy wind-up, the grind.
5. The rest of the match's sounds, 6. the head flashes, 7. the optional sets.

**Within a rank the queue is variant-major**: the first variant of every sound, then the second of every sound, and so on, so every sound has a variant ready as early as possible. **A cue for a variant not yet rendered plays another variant of the same sound** (they differ by a little pitch, decay and level only) instead of waiting; only a sound with no variant rendered yet holds its cue (and jumps to the front, as before). The cue log is not touched (the choice is made in `AudioVoices`).

## Proof (scratch export of HEAD, the first park then the re-cut applied)

- **Bit-identical.** `warm_hashes.gd`: the sha256 of every buffer the bank can render (305 clips) is the same with and without the parks. `warm_async_check`: all 285 clips rendered across thousands of frames (a 1 ms budget) have the same streams as `warm()`'s.
- **The slices.** At a 1 ms budget the longest run between two yields was 2.2 ms (a chunk is the granularity). With the quiet budget the longest run is 25.9 ms; at 4x the budget is the same wall time and the chunk 4 times longer: about 25 + 4.7 = 30 ms, under the 50 ms the brief asks for (the largest single sound used to be 78 ms at 1x, 312 ms at 4x).
- The nine audio checks pass (`world_check`, `tone_check`, `carry_check`, `tug_check`, `brawl_check`, `beat_check`, `babble_check`, `warm_check`, `host_check`), `host_check`'s sim hashes and cue logs are identical to HEAD's, and headless still renders the block.
- **Not measured here:** Performance's phone probe on the re-cut (`freeze-probe.mjs`).

## For the host

- `bank.warm_quiet`: 1 when nothing is playing, 0 in play, -1 (default) to read the cue traffic. Rendering or UI sets it from `host.paused` (see above).
- `bank.warm_ids_async(cues.world.warm_beds(S))` queues the world's beds without a block (160 ms of CPU a bed at 1x).
- `bank.warming`, `bank.warmed` (a signal), `bank.skipped`, `bank.skipped_report()` for a progress line or a probe.
- Web: GDScript coroutines are the same on the web build; no thread is used. The run needs a node in the tree: `AudioVoices` sets `bank.async_ok` when it enters the tree, which `main.gd` does before it calls `warm()`.

## Not done

The phone probe on the re-cut; the intro's own first draws (Rendering's); the `start_match` block (Simulation and World's); the host's `warm_quiet` line.
