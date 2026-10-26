# Park: the host reads the calm turn's rings ahead (2026-10-26)

UI, on the EP's brief: wire World's `WorldEpoch.readAhead` into `SimHost` (docs/world/pending/gen2-read-speed-b/). Based on HEAD db2c8fec **plus World's gen2-read-speed-b.diff and its `grant_sim_plates.py`** (the grant patch calls `WorldEpoch.warmPlan` and `readAhead`, which do not exist before it). Account: `docs/ui/read-ahead.md` (inside the UI patch). Nothing the player sees changes.

## What it is

After each frame's ticks (`SimHost.advance`, the last thing it does; never inside a tick), `_read_ahead(frame_dt, spent_us)`: only when `WorldEpoch.warmPlan(S)` is not empty (a calm turn is warming), not paused (a paused `advance` returns first) and the frame was not late (`frame_dt` over 22 ms reads nothing); otherwise `min(2 ms, 16.7 ms - the ticks' cost)` in World's 20 us units (at most 100 units a frame, about 33 gen 2 columns). `SimHost.read_ahead = false` turns it off; `read_ahead_cols` counts what was read. No state is touched, so frame pacing changes how much is read ahead and never the match.

## Two patches, in this order from the repo root (after World's diff is on)

```
patch -p1 < docs/ui/pending/read-ahead/read-ahead-ui.patch      # ui/tools/read_ahead_check.gd (+ .uid), docs/ui/read-ahead.md
patch -p1 < docs/ui/pending/read-ahead/read-ahead-grant.patch   # render/core/sim_host.gd: needs the EP's grant (the same file the planet-load grant covers)
```

sha1: read-ahead-ui.patch 5946d9cc63acee1fd1083936acfe0104d9963328; read-ahead-grant.patch 4baf946bf4f553f9b9490c2e32547cba96788cf0.

## NEEDS FROM EP: the grant

`render/core/sim_host.gd` only: the constants `READ_AHEAD_CAP_US`, `READ_AHEAD_UNIT_US`, `READ_AHEAD_FRAME_US`, `READ_AHEAD_LATE_US`, `read_ahead`, `read_ahead_cols`; `advance` times its tick loop and calls `_read_ahead`; `_read_ahead`.

## Gates (a scratch tree of HEAD + World's diff + grant_sim_plates.py + both patches, below-normal, one Godot at a time)

- `ui/tools/read_ahead_check.gd`: 31 checks, 0 failed. A calm turn played to its swap through `advance` with the read-ahead on and off, gen 1 and 2, k 32 and 12, with and without `warmTotal` (12 pairs): the same swap tick and the same gameplay hash every 100 ticks; on reads columns, off reads none; the same again at a jittering frame time (2 to 50 ms) on and off, both generations; no decided turn, a late frame and a paused frame read nothing; a frame reads within its cap; a frame whose ticks used all of it reads nothing.
- `determinism` plain and `--intro --seeds=2 --ticks=900` passed (they run `advance` at 60, 144 and jittering frame times; they have no calm turn, so they prove the path adds nothing where no turn is warming; the proof that read-ahead changes no state is the check above). hud_check 5816 and 0 failed, hud_words and pane_check passed, `load_check` 28 of 28, all 14 render gates (after, cue `--profile=spaced`, depth, flash, flash_reg, flight, ground, lane, open, patch, shape, sky, stage, city) and seam_sweep exit 0, sim parity golden check passed.
- No look change, so no side-by-side or flash run.

## Traps

- The 16.7 ms frame is an assumption: `advance` cannot see how long the draw takes, so the 2 ms cap is what keeps it honest. Performance to bench it on a phone and the web build; the knob is the four constants.
- A tool that steps through `advance` while a turn is warming now also reads ahead (state-neutral, a little time); set `read_ahead = false` for a clean timing.
- Apply order matters: World's diff first, or the host fails to parse.
