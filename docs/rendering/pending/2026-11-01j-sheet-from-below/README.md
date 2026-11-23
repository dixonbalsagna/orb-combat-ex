# The water sheet isn't drawn from below

Parked by Rendering, 2026-11-01. `below.diff` stacks on `2026-11-01i-crater-scar-look/look.diff`. Only with the tile ground's switch on.

**The fault.** With fighters on a deep sea bed, the lens goes under the sea's top, and the sheet seen from below fills the frame as a flat blue wall with a hard edge where the wet tiles end (Camera: tick 3700, `docs/camera/img/close-brawl/`).

**The change.** A vertex whose water top is above the lens isn't drawn. The sea bed shows instead, in its depth colours.

**Seen:** `docs/rendering/img/lookgate/sheet-from-below.png`, left before, right after: a lens under the sea, a test scene on an earlier stack. **Camera's own tick hasn't been run on this.**

**Known:**
- At the moment the lens crosses the surface the sheet appears or goes at once, with no fade.
- Under the sea there's no sign of being underwater beyond the bed's colours.

**Gates**, on HEAD 8ea982c5 with all my diffs: `tile_check`, lake and cover water checks pass, render gates all exit 0.
