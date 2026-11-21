# Lakes under plans.everywhere: water drawn, at the lake's level (for GW1b)

Rendering, 2026-11-20, on the EP's item: Animation's `water-tile-check` (`docs/animation/pending/water-tile-check/`) found that with `plans.everywhere` on (Orb's build and GW1a), the tile field drew no water at 17 lake places, and fighters stood up to 681 units in the air over dry lake beds. World and I found the same tile cause independently. This park is **World's grant as written** (`docs/world/pending/lake-places/grant-rendering-tile-water.patch`), reviewed and gated here.

`water_everywhere.diff` (sha1 d753545f, byte-identical to World's grant, two lines of `render/core/tile_field.gd`) applies on HEAD 8baf6f8a. It lands with World's `lake-places` (its code and the `lakeMax` 8 data row) in GW1b. Run records: `docs/rendering/runs/3f85bbb2/water-everywhere.txt` and `water-everywhere-dry-probe.txt`.

## The two lines

1. **The place band leaves water to World's records** (line 542).
   - Inside a place's band (`place_w >= 0.5`) the tile read no water. The band stood in for a place's footprint, which wasn't World's yet.
   - The band is marked per column of the line from every building's strip x. With `plans.everywhere` every place is laid planet-fixed, and so are the first ring's buildings beyond their lanes, with their x projected onto the line. So the bands covered the line's lakes.
   - With World's lots in the records (`_has_pads`), a place's ground is the records' already, and so is its water: `recordWater` against the ground with the lots applied.
   - I wrote the same line before World's grant came. The guard I also tried (only buildings within the band's depth mark it) brought back 12 of 17 lakes and adds nothing beside this line, so it isn't here.
2. **`water_top` is the wet node's own ground plus its depth** (line 613): the level the sheet draws at that node. It used to be the ground at the point plus the node's depth, which was off the level where the bed slopes inside a cell: Animation's 59.2 above and 35.6 below, on main's data too.
   - Only the water rings and wakes read `water_top` (`RenderTileGround._water_marks`). They now fire when a body crosses the surface as drawn.

## Review

- Line 1 is mine word for word apart from its comment.
- Line 2 reads the same texel the depth already came from (`q`, the nearest node), so the level and the depth are one node's. On a lake every wet node gives the lake's level, so it's exact. On the sea, level 0, it's exact too.
- Nothing else reads `water_top`, and neither line touches the sim (golden unmoved: see the gates).

## Gates (`water-everywhere.txt`; HEAD 3f85bbb2 + Animation's check, scratch)

| | before | with this park |
|---|---|---|
| GW1b's data (everywhere, World's `lake-places` and `lakeMax` 8), `--strict` | lakes 17 of 17 beyond 6, no water drawn, up to 681.5 above; dry 5 over 6 | **every lake drawn at the sim's level** (up to 0.0 above): 1 lake place beyond 6 (12.9 under), dry 1 over 6 (12.5), sea and wade ok |
| main's data, the water check | Animation's main record: lake 14 beyond 6 (59.2 / 35.6) | sea, dry and wade as that record; lake **1 beyond 6** (12.9); passes |

- `golden.json` is byte-identical to HEAD's.
- The tile, lake water, cover water, sweep and ground checks pass.
- The render gates pass 20 of 20.

## The two places left: the check's coarse tiles (the EP: my call with Animation, the check being theirs)

Both are ground the check reads too coarse, not water:
- **x 32,000** (dry, 12.5): a World lot record raises the ground about 116 units there, on a ramp of about 1:1.
- **x 22,400** (lake, 12.9): a steep lake bed. The drawn water is at the lake's level, 989.5, but the feet take the lift of a coarse tile's ground.
- **The check reads tile levels 1 and 2 only** (`ask_around`). Their nodes are 128 units apart, too coarse for either slope.
- **With levels 3 and 4 loaded,** as the camera loads them round a fight in play (`water-everywhere-dry-probe.txt`):
  - x 22,400: the drawn ground equals the sim's (865.37), the lift is 0, and the feet stand on the water at 989.5;
  - x 32,000: the feet come within 1.8 of the drawn ground.
- **My proposal for Animation's check:** ask for the finest levels at each place (want levels 3 and 4 at the place and 64 either side, then fill), as the probe does. Then `--strict` should pass with no pad-edge tolerance. That's my reading at both places, not a run of their check.

## The look

Both lines change what's drawn in Orb's build (`everywhere` on): lakes appear under fighters who stood over dry beds, and the water rings fire at the drawn surface. That fixes a broken picture, but ADR 0010 asks for a side-by-side before landing. It needs a capture window: the same lake place, before and after, on the GW1b data.
