# The rock's edge follows the hill, not the grid

Parked by Rendering, 2026-11-01. `rock_edge.diff` stacks on `2026-11-01t-tundra-strata/strata.diff`. Only with the tile ground's switch on.

**The fault.** The rock on a steep hillside has a saw-toothed top edge, with stray vertical hairlines below it.

**The cause, from reading the code and this one test.** The finest tiles' nodes lie on the planet's 128-unit lattice, whose triangles are flat. A slope read across one fine node jumps at each triangle's edge, and the rock tone's hard threshold zigzags along those edges.

**The change.** On the tiles finer than 128 units the slope is read across a 128-unit span: two nodes each way at level 3, four at level 4. Near a tile's border the span is shorter on that side, divided by the real distance. The slope also sets the light's tones and the lift's normal, so those change slightly too.

**Seen:** `docs/rendering/img/lookgate/rock-edge-before-after.png`, 3x, the pause at tick 3301, top before, bottom after. The edge reads as a line along the slope, and the hairlines are gone. No seam at a tile's border shows in that frame.

**Not done.**
- A little tooth is left at the frame's far left.
- The big flat rock facets stay: that's the look, Art's call.
- Art hasn't seen this.
- One frame only. A crater's bowls add their slope separately; not looked at. Flash with tiles on hasn't been run: this changes tones wherever slopes are fine-tiled, and a tone step could move with the view.
- The vertex stage reads the same four heights as before, so no added cost is expected. Not timed.

**Gates**, with a to u stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; off 13 stills 0 differ. The 20 render gates exit 0, but run without the tile word. The chain applies on d00bc7ab, apply check only.
