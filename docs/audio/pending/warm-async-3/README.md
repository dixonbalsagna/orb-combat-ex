# Park: the audio warm-up, the common hits first (Audio and Music, 2026-10-27)

Performance's re-probe of the re-cut (`docs/perf/audio-warm-async-2-2026-10-26.md`, 404fea20): lost cues fell from 42 to 11 at x4 and from 189 to about 30 at x6, but the ones still lost are the common hits (impact.light, impact.light.lite, impact.heavy, energy.bolt, then crater, whiff, medium). This reorders the queue as the EP asked. Audio's own files only; the first two parks (warm-async in 1b3f5a29, the re-cut in 105ac025) are on main. Design: `src/docs/audio/warm-async.md` (a new section, "The common hits first").

## The three changes

1. **Order.** Rank 0 the cheap common hits (about 85 ms of CPU at 1x), then the intro's babble, then the grunts, then the dear common hits (medium, heavy, crater, blast, double, the heavy wind-up, the grind) *right after the grunts and ahead of the rest of the match set*, then the rest, the flashes, the optional sets. The lists are `AudioBank.WARM_FIRST` and `WARM_SECOND`.
2. **Variant-major within a rank** (the first variant of every sound before the second of any), and **a cue for a variant not yet rendered plays another variant of the same sound** instead of waiting; only a sound with no variant yet holds its cue.
3. **The run's first slice is 120 ms** (`bank.boot_slice_us`), inside `warm()` at boot: it renders the cheap common hits before the first frame, "even at the 6 ms budget". It adds 0.1 s to a boot block of 25 to 47 s.

## What changes

Replaces `audio/audio_bank.gd`, `audio/audio_voices.gd`, `audio/tools/warm_async_check.gd` and `docs/audio/warm-async.md` by path, guarded by `old_hashes.json` against the files on main. `warm3_edits.py` is the anchored edits that made them (provenance). `warm_async_check` gets: the first 17 of the plan are the cheap hits in order, the queue is variant-major, the first slice has rendered the cheap hits' first variants, a cue for an unrendered variant plays another at once (nothing waits, nothing skipped), and `pick_ready`.

## Apply

```
python docs/audio/pending/warm-async-3/apply.py <root> --check
python docs/audio/pending/warm-async-3/apply.py <root>
```
From a scratch export of HEAD first; the repo root only for the EP's apply, and then commit.

## Not in this park

The x6 warm-up still running 99 s because "nothing is playing" never fires (an AI match plays behind the first-start card): that is the host's `warm_quiet` line, which Rendering is adding to `main.gd` (`host.audio_cues.bank.warm_quiet = 1 if host.paused else 0` was the shape; with the AI match playing behind the card it needs the card's own state, not `paused`).

## Risks

- The first slice adds 0.1 s to the boot block (about 0.4% of it).
- A cue that plays another variant while the warm-up runs repeats the same variant for a moment: only during the warm-up.
- Untested in a real browser or on a phone; Performance re-probes.
