# Parked: a new match's first frame stands on its own ground (reset-frame)

Camera, 2026-11-26. Rendering found it: on Play again, the tile ground popped for one frame, at every planet size. It's needed for the small-and-big window, and it fixes Orb's own Play again.

**Apply on main** (cut on a0e5a537): `git -c core.autocrlf=false apply reset-frame.patch` (sha1 84196e60, 2 files, mine). It also applies after door-holds and cd04, and after Rendering's sky-handover.
- `render/camera/split_rig.gd`: one line.
- `render/camera/tests/reset_frame_check.gd`: new.

## The fault

`SplitRig.reset(S)` builds the match's first frame. `main._mb_end` calls it at every match build. It cleared the swing state but kept the sim frame it held (`_pl`, `CamPlaces.frame_of`) from before, so the frame's `place` came from:
- **a following match:** the last match's frame, so the tile ground was placed through the last match's bearing for one frame;
- **the first match:** no frame at all, because a new rig holds none.

`cut()` re-reads the frame; `reset()` didn't.

## The change

In `reset()`, after the split line is taken: `_pl = CamPlaces.frame_of(S) if swing_view else PackedFloat64Array()`. This is Rendering's line.

## Proof (`docs/camera/runs/a0e5a537/reset-frame/gates.txt`)

- `reset_frame_check` (new, 8 rows):
  - One rig, as the game keeps one: match 1 plays on until its frame has moved, then match 2 is reset on the same rig.
  - The first frame's `place` is the new match's frame, not the last one's.
  - The next tick follows the new frame.
  - No swing carries over.
  - With the swing view off, there is no frame.
  - **On main without the fix: 3 of 8 fail** (both matches' first frames). **With it: 8 of 8.**
- Every camera check passes, including split_sweep (at standard, later and sooner) and own_pane at later and sooner.
- The pane, seam and determinism gates pass. The golden is unchanged (989878d6d335).
- Rendering's feet check at small and big, with this line, passes (Rendering's record b313b934).
