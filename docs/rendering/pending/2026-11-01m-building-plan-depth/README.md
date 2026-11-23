# A building's depth from its plan on the tile ground

Parked by Rendering, 2026-11-01. `depth.diff` stacks on `2026-11-01l-no-base-past-line/slab.diff`. Only with the tile ground's switch on. One line.

**The fault.** Towns on hills hang in open sky as tilted boxes with their undersides showing (`docs/tools/img/page-reel-minute/sheet-3.png`). Foot walls and the slab fix don't change it.

**The cause.** On the tile ground a building's mesh takes x from its plan (`b.g.x`) but depth from `b.z`, the sim's pose, which has already swung. The shader then turns the mesh with the planet from its plan place, so a swing counts twice. The mesh keeps whatever `b.z` was when it was last set: at build, or when the building is set again for damage or for ground that changed under it. A swing alone doesn't set it again.

Read at tick 1216, seed 12345, planet 7, with this stack's readout. Building 453:

| | |
|---|---|
| plan place | x 74382, depth -3832 |
| `b.z` at that tick | -2254 |
| ground at the plan place | 1815, its base is 1815 |
| distance from plan place to the mixed place | about 1,580 |
| ground under the mixed place | 1177, so about 640 of air |

The readout computes the place the way the shader does. It reads `b.z` at that tick, not the mesh's own stored transform.

**The change.** `_set_building` uses `b.g.z` when the tile ground is on. The other uses of `_depth` pair `b.x` with `b.z` to compare against the fighters, so they stay as they are.

**Seen:** `docs/rendering/img/lookgate/hanging-towns-before-after.png`, top right of the frame at ticks 1216, 1351, 2161 and 2431. Left has none of k, l, m; right has all three. The boxes become a tower and low buildings standing behind the ridge. All 21 ticks to 2701 were looked at, and nothing new stands in front of the fight.

**Not the reel's frame.** The same seed and planet play a different fight on this stack, with the same fault at the same kind of place. Tools' re-run of the reel is the check on its own ticks.

**Not known:**
- Some of the towers now seen have jagged tops, like battlements. Damage or shape, not traced. They couldn't be seen as such before.
- Removing the slab uncovers a notch in the ground at ticks 946 and 1081, still there with this diff. Not identified.
- Whether a fighter's blow lands where a building is now drawn during a swing: the sim's box is at its pose, the mesh at its plan turned by the swing. They should agree within the swing's reach. Not measured.
- Cost: more buildings may now be in frame. For the frame bench.
- With tiles on, stills of the same build differ between runs (16 of 19 ticks), so a pixel count says nothing there; the evidence is the pictures.

**Gates**, on 8ea982c5's render, sim and data with all my diffs: golden byte-identical; tile, lake water, cover water and sweep checks pass; off 13 stills 0 differ. The 20 render gates exit 0, but run without the tile word.
