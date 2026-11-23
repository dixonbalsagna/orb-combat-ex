# A running figure reads the ground less often on the tile ground

Parked by Rendering, 2026-11-01. `crowdrun.diff` stacks on `2026-11-01x-tile-frame/tileframe.diff`. Only with the tile ground's switch on; today's ground is untouched.

**The fault.** In Orb's second match, ticks 3570 to 3705, the planet view's update rose by about 2 ms over its standing cost. The timer put it in `CrowdFlight.step`: every running civilian read `WorldTerrain.groundY` under it every frame, and on a field world after a swing those are cold terrain columns.

**The change.** On the tile ground a running figure reads the ground under it one frame in four, by turns (`RenderLook.CROWD_RUN_GROUND_FRAMES`), and keeps the last read between. A runner covers a few units in that time, so its height barely changes. Its first frame always reads.

**Result**, perf-run on Orb's second match: the frame and view numbers are in the sweep-by-view park (`2026-11-01z-sweep-by-view`), measured with both against x alone. The runners' step alone, ticks 3570 to 3705, fell from 2.3 to 1.2 ms a frame (both runs valid, load 57/49 and 46/49).

**What it costs.** On a steep slope a runner can sit a few units off the ground for up to three frames. Not seen in stills.

**Gates**, with a to y stacked on 8ea982c5's render, sim and data: golden byte-identical; with z on top, tile, lake water, cover water and sweep checks pass, the 20 render gates exit 0 (without the tile word), off 13 stills 0 differ. The chain applies on main 04aa9228, apply check only.
