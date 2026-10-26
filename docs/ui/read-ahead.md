# The host's read-ahead of the calm turn's rings

UI's hookup, on the EP's brief of 2026-10-26, for World's `WorldEpoch.readAhead` (docs/world/gen2-read-speed.md section 4, parked in `docs/world/pending/gen2-read-speed-b/`). Nothing the player sees changes.

## What it does

While a calm turn is warming, `SimHost.advance` spends a little of each frame's idle time reading the turn's rings ahead of the columns the sim has counted, so the sim's own warm ticks find their columns read and do almost nothing. The sim does not know: `readAhead` touches no state (the slices are derived data outside it), a ring counts as read and the swap happens on the same ticks whatever the host does, and a replay with the host's read-ahead off is the same match.

## The rule

After a frame's ticks (`advance`, the last thing it does; never inside a tick), `_read_ahead(frame_dt, spent_us)`:

- reads nothing unless `WorldEpoch.warmPlan(S)` is not empty (a turn is decided and its rings are warming), the host is not paused (a paused `advance` returns before the ticks), and the frame was not late (`frame_dt` over 22 ms, under about 45 frames a second: the machine is behind, so it does not add work);
- otherwise spends `min(2 ms, 16.7 ms - what this frame's ticks cost)`, in World's units of about 20 us (`left_us / 20` units, so at most 100, about 33 columns of gen 2 at 3 units a column); less than one unit left reads nothing;
- `SimHost.read_ahead = false` turns it off (a tool that wants no side work); `read_ahead_cols` counts the columns read ahead so far.

The numbers are the host's own constants (`READ_AHEAD_CAP_US`, `READ_AHEAD_UNIT_US`, `READ_AHEAD_FRAME_US`, `READ_AHEAD_LATE_US`). The 16.7 ms frame is a guess at the display; `advance` cannot see how long the draw takes, so the cap is what keeps it honest. Performance should bench it on a phone and a web build.

## Checks

`ui/tools/read_ahead_check.gd` (headless, a host and `advance` one tick a frame): a calm turn played to its swap with the read-ahead on and off, gen 1 and 2, k 32 and 12, with and without `warmTotal`: the same swap tick and the same gameplay hash every 100 ticks (12 pairs); on reads columns, off reads none; no decided turn reads nothing; a late frame reads nothing; a paused frame reads nothing; a frame reads within its cap; a frame whose ticks used all of its time reads nothing. Beside it `render/tools/determinism.gd` (plain, and `--intro --seeds=2 --ticks=900`).
