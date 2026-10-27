# Park: the audio warm-up across frames (Audio and Music, 2026-10-26)

The EP's priority brief after Performance's phone-freeze note (`docs/perf/phone-freeze-2026-10-26.md` §1 and §3): `bank.warm()` renders every sound inside `main._ready`, one synchronous block (2.0 s on this PC, 9.7 s at 4x CPU, 14.4 s at 6x). This takes it out of the block: the same sounds, the same bits, a few milliseconds a frame, most wanted first. **Audio's own files only** (`audio/`, `docs/audio/`); `render/core/main.gd` is not touched. Design, proof and knobs: `src/docs/audio/warm-async.md` (it lands as `docs/audio/warm-async.md`).

## Against the acceptance criteria

| The brief | How |
| :--- | :--- |
| No single main-thread call in the warm-up over about 50 ms at 4x CPU | The synth loops yield every 1,024 iterations when the frame's budget (`AudioSlice.budget_us`, 6 ms) is spent. Longest run between two yields: the budget plus one chunk, about 1.1 ms at 1x (4.4 ms at 4x): **about 10 ms at 4x**, against 312 ms for the largest single sound before (78 ms at 1x) |
| No sound plays un-warmed, unless there is a defined fallback | **The fallback: while the warm-up runs, a cue whose sound is not rendered yet is dropped, silently and counted (`bank.skipped`)**; the most wanted sounds are first (the intro's babble and grunts, then the hits and the match's sounds, then flashes, then the optional sets); after the run an un-warmed sound renders on its first play as it always did |
| The warm-up's output is bit-identical to today's | The arithmetic and its order are untouched (only `await` and the chunking are added). `warm_hashes.gd`: the sha256 of every buffer (305 clips) is the same with and without the park; `warm_async_check`: all 285 clips rendered across thousands of frames have the same streams as `warm()`'s |
| The audio checks pass; headless still skips the warm-up as today | The nine checks pass; `warm()` in headless (and in any run with no screen or no node in the tree) is the one block as today, so the tools and tests see no change; `host_check` cue logs and sim hashes are identical to HEAD's |
| Perf's freeze-probe shows the gain | **Not run here** (it needs Chrome through Tools' launcher; the EP asks Performance). On their numbers the 2.0 / 9.7 / 14.4 s (x1 / x4 / x6) leave `_ready`'s block and become frames of about 6 ms; the total CPU is unchanged (a chunked loop costs nothing measurable: 1,745 ms against 1,772 ms) |

## What changes

- New: `audio/synth/slice.gd` (`AudioSlice`: `due()`, `next_frame()`, `run_sync()`, the budget), `audio/synth/dsp_a.gd` (`AudioDspA`: the coroutine twins of `AudioDsp`'s loops; `AudioDsp` itself is unchanged), `audio/tools/warm_async_check.gd`, `audio/tools/warm_hashes.gd` (with their `.uid`), `docs/audio/warm-async.md`.
- Replaced: the six synths (`impact`, `grunt`, `flash`, `babble`, `drone`, `ambience`): every function with a long loop is now `NAME_a`, a coroutine, and the public ones keep their names as thin sync wrappers, so **no caller changes**. `audio/audio_bank.gd` (the async warm-up: `warm_plan`, `warm_async_begin`, `warm_ids_async`, `buffer_a`, `stream_a`, `is_ready`, `warming`, `warmed`, `skipped`; `warm()` redirects to it when a node in the tree and a screen are there) and `audio/audio_voices.gd` (sets `bank.async_ok` in `_ready`; drops an un-rendered sound while warming).
- **The synths are now the generated form.** `make_warm_async.py` (here) is how they were made from the old ones, and `bank_async_edits.py` the edits to the bank and the voices; after the park lands the files in `audio/synth/` are the source (edit `NAME_a`, keep the sync wrapper). `warm_async_check` fails if a change makes the async path differ from the sync one.

## Apply

From a scratch export first, the repo root only for the EP's apply (and then commit):

```
python docs/audio/pending/warm-async/apply.py <root> --check
python docs/audio/pending/warm-async/apply.py <root>
```

It replaces the eight files by path only where each is what the park was made from (`old_hashes.json`), and refuses files that already exist among the new ones.

## Needs

1. The EP: Performance's freeze probe on a scratch export with the park applied (and the live pin's A/B).
2. Rendering: the boot warm-up for the world's beds can call `bank.warm_ids_async(cues.world.warm_beds(S))` (160 ms of CPU a bed at 1x, no block), and may call `bank.warm_async_begin()` in `main.gd` instead of the implicit redirect inside `warm()` if they want it visible there.
3. Orb or UI (optional): a progress line from `bank.warming`, the `warmed` signal and `bank.skipped`.

## Risks

- On a slow phone the whole run is long in wall time (about 1.8 s of CPU at 6 ms a frame is 5 s of frames here; at 6x about 30 s): the first seconds of play can have some hits silent (the babble and grunts are first, then the hits). The budget is one number (`AudioSlice.budget_us`) if Performance wants it higher during the first-run card.
- Untested in a real browser or on a phone; the web build has no threads, the coroutines are the same VM.
