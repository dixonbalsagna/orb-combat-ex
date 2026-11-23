# The fill takes the coarsest level first

Parked by Rendering, 2026-11-01. `coarse.diff` stacks on `2026-11-01p-tile-pool/pool.diff`. Only with the tile ground's switch on.

**The fault.** The fill went nearest-first, so fine tiles by the camera finished while far level-1 tiles starved. At the moment of a pause at tick 541, levels 3 and 4 were arriving while 34 of 44 level-1 tiles were missing.

**The change.** The coarsest wanted level first, nearest first within it. One level-1 tile covers sixteen level-3 tiles' ground. No more CPU a frame.

**Not seen.** This diff has had gates only: no picture and no timing of the catch-up. It also delays the fine tiles near the camera while far coarse ones fill, and that hasn't been looked at in play.

**Gates:** as `2026-11-01p-tile-pool`'s.
