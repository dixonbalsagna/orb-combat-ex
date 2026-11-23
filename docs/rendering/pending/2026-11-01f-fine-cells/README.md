# 32 units near the fight

Parked by Rendering, 2026-11-01. `fine.diff` stacks on `2026-11-01e-crater-line/crater.diff`. Only with the tile ground's switch on.

**The fault.** Near the camera a steep slope drew as single 128-unit triangles, flat-shaded: the big grey slabs of the first look.

**What it does.** The tile data goes on to two finer levels near the camera, 64 and 32 units, read from World's field at its N = 1200 sub-nodes through `SimField.heightOf`, the sim's own ground there, with the same records on top. Tile keys get one more level bit. A mesh finer than 128 still goes on when its data isn't there yet, and reads the finest data it has. Biome is the nearest canonical node's.

**Seen:** `docs/rendering/img/lookgate/fine-cells-before-after.png`, planet 7, seed 12345, tick 1441, left before, right after. The jagged slabs become smooth slopes.

**It doesn't fix that frame by itself.** That place is a steep flank with no horizon, and World is looking at steep pads.

**Gates**, on the EP's tree s400 plus the parks below this one: golden byte-identical, `tile_check` passes, lake water, cover water and sweep checks pass, render gates all exit 0. `tile_check`'s worst against the sim's line goes from 17.3 to 22.1 units, since the view is now finer than the sim's read along the line.

**Costs not measured:**
- No fill bench yet. Fill stays inside its existing per-frame budget, so a slow fill means coarse ground for longer, not a slower frame. In fast flight the near ground was already coarse and may stay so.
- Pool use: the same 430 layers now also hold the two fine levels.

**Known:** when a tile's fine data arrives the shape changes where World refines a cell, a small jump near the camera. No fade. Not measured in motion.
