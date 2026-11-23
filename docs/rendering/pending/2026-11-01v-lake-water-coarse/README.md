# Lakes keep their water on the coarsest tiles

Parked by Rendering, 2026-11-01. `lake_l0.diff` stacks on `2026-11-01u-rock-edge/rock_edge.diff`. Only with the tile ground's switch on.

**The fault.** In fast low flight, hard-edged brown tables appeared in the land. They're lake beds with no water. The coarsest level didn't read water, and in flight the ground under the fight is often that level: at 3,600 units a second, 231 of 600 frames, measured earlier this session on a busy machine.

**The change.** Level 0 reads water like the others.

**Seen:** earlier in this session, on an older stack, held still and in flight. **Not seen again on this stack:** the reel's fight doesn't cross a lake at low level, so `low-hills-fight-sheet.png` doesn't show it. Level 0's fill does a little more work per node where a record reaches it. At load, level 0's tiles are read in a block, so load time may rise slightly. Not timed.

**Gates**, with a to w stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; off 13 stills 0 differ. The 20 render gates exit 0, but run without the tile word. The chain applies on main, apply check only.
