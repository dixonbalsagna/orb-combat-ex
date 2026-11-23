# A building's foot on the tile ground

Parked by Rendering, 2026-11-01. `foot.diff` stacks on `2026-11-01j-sheet-from-below/below.diff`. Only with the tile ground's switch on. Land `2026-11-01l-no-base-past-line/slab.diff` with it: with correct footings, a kept base that used to be buried shows as a floating plate.

**The fault.** Towns on hills look like boxes hanging in the air, with spikes under them (`docs/tools/img/page-reel-minute/sheet-3.png`).

**The cause, the part that's Rendering's.** A building's body goes down to the lowest ground under its footprint, but that was read before the tile field existed, from the fighters' line rather than the building's place: for example base 3,655, footing 607. Parts stretched to the wrong depth, which drew the spikes.

**The change.**
- The footing is read at the building's plan place, on the ground as drawn, and no deeper than `RenderLook.TILE_FOOT_CAP`, 320, under its base. World suggested about 120 (`docs/world/lot-gap.md`); 120 can't close the gaps measured here.
- Every building gets it once, in slices, then those near the camera again as finer tiles come. A footing that moved sets its building again.

**Seen:** `docs/rendering/img/lookgate/foot-walls-before-after.png`, left before, right after with `slab.diff` too: one hillside on planet 7, a test scene. **The reel's hanging town itself hasn't been seen fixed:** this stack plays a different fight, so Tools' re-run of that reel is the real test.

**Not closed by this.** A footprint on ground steeper than the cap can close still has air under it. World's `plans.maxFootSlope` is meant to remove those, and buildings with corners 1,300 apart were still laid at 0.7 in this stack, read from tiles that may be coarse at that distance. World's to check.

**Known:**
- Up to six footings a frame are read, and a building can be set again when one moves, which isn't timed. The frame bench is owed.
- A footing that moves when a finer tile arrives changes the wall's depth at once.

- At six a frame the first pass takes a while, and it doesn't start near the camera: until it reaches a building, that building has its old footing, spike included.

**Gates**, on HEAD 8ea982c5 with all my diffs and `slab.diff`: golden byte-identical; tile, lake water, cover water and sweep checks pass; off 13 stills 0 differ. The 20 render gates all exit 0, but they run without the tile word, so they say the switch-off path is safe, not that this looks right. Render, sim and data haven't changed from 8ea982c5 to 07135713, and the whole chain applies on 07135713.
