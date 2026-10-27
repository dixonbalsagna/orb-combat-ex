# Park: the audio warm-up across frames, re-cut (Audio and Music, 2026-10-26)

Performance measured the first park (`docs/audio/pending/warm-async/`, `docs/perf/audio-warm-async-2026-10-26.md`, 66fcf873): the boot block loses exactly the warm-up (14 s at x6), but at a flat 6 ms a frame the run takes 46 s at x4 and 145 s at x6 after the first frame, and drops 31 and 176 cues. This is the re-cut the EP asked for, **stacked on the first park** (apply that first; it is going to main as it is). Audio's own files only. Design, proof and knobs: `src/docs/audio/warm-async.md` (it replaces the first park's doc).

## The three changes

1. **An adaptive budget.** 25 ms a frame while nothing is playing, 6 ms in play, 10 ms in play while cues wait for their sound. "Nothing is playing" is the host's word if it gives one (`bank.warm_quiet = 1`; the host's line is `host.audio_cues.bank.warm_quiet = 1 if host.paused else 0` in `main.gd`'s frame, Rendering's file, not applied here) and, if it does not, the cue traffic (no cue asked for 1.5 s; every overlay pauses the sim, so a card, a menu or the loading screen goes quiet by itself).
2. **A cue asked for while its sound is queued waits and plays.** Its sound jumps to the front of the queue and renders in the next slices (the same sliced code: no long render at any CPU), the cue waits in `AudioVoices` and plays when the sound is ready, unless it would be later than its own length (then it is lost); at most 6 s, at most 24 waiting.
3. **The lost cues are named.** `bank.skipped_log` (a debug ring of 64: sound, variant, why, late_ms), `bank.skipped_by_sound`, `bank.skipped_report()`, and `bank.deferred_played`.

## What changes

Replaces four files by path (`src/`, guarded by `old_hashes.json` against the first park's versions): `audio/synth/slice.gd` (a `budget_fn` asked at the start of each frame the run gets), `audio/audio_bank.gd` (`_pick_budget`, `warm_quiet`, `warm_want`, `note_skip`, `skipped_report`, the ring), `audio/audio_voices.gd` (`_defer`, `_run_deferred`, the traffic stamp), `audio/tools/warm_async_check.gd` (new sections 6 and 7 and the held-cue test in 4), and the doc `docs/audio/warm-async.md`. Provenance: `recut_edits.py` and `recut_check_edits.py` are the anchored edits that made them from the first park's files.

## Apply

```
python docs/audio/pending/warm-async-2/apply.py <root> --check
python docs/audio/pending/warm-async-2/apply.py <root>
```
From a scratch export that already has the first park; the repo root only for the EP's apply, and then commit.

## Needs

1. Rendering or UI: the one line from `host.paused` (above); without it the traffic heuristic does the job after 1.5 s of silence.
2. Performance: re-probe x4 and x6.
3. Rendering: `bank.warm_ids_async(cues.world.warm_beds(S))` for the beds, as before.

## Risks

- A cue for a big sound asked for in the first seconds on the slowest phone can still be lost (it waited longer than its own length): named in the ring, so the probe can say which. The common small hits are ready within a frame or two of being asked for.
- Without the host's line, a lull of 1.5 s in a live fight gives one 25 ms frame.
- Untested in a real browser or on a phone.
