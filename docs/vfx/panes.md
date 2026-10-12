# Glass from the panes (the re-laid city, 2026-10-11)

Owner: VFX. Code: `render/vfx/panes.gd` (`VfxPanes`), read by `debris.gd` (`window_row`, `stage_glass`, `stage_shed`), `react.gd`, `stages.gd` and `vfx_hub.gd`.

## What changed

The window blow-out used to throw one sliver about every 70 units at a random height of the floor band, on the assumption of a column every 62 units and one row a floor. Rendering's re-laid city draws panes by district look: a column every `pitch` units (46 downtown, 120 mid-rise, 95 suburb, ...), the pane's span across its cell and the share of cells that have one, rows by floor height (`RenderShapes.rows`: a floor taller than 150 units carries more than one), the pane's span up the row, and one or two strips a row (`building.gdshader` section 7).

`VfxPanes.grid(S, b)` reads those numbers at the moment from `RenderShapes.look(RenderShapes.look_of(RenderLanes.table(S), b))` (nothing is copied, so a look Art changes moves the glass with it) and returns the building's grid. `VfxPanes.nearest(grid, x, y)` is the centre and size of the pane nearest a point on that wall. Glass is thrown from there (within a third of the pane's size of its centre).

- `react.gd` puts the grid in each blow-out job; `_blow` sets `debris.pane` for its rows.
- `floor_hit` (hub) and `stage_glass` / `stage_shed` (stages) set `debris.pane` for the call.
- The silhouette: the grid carries each part of the drawn building (`RenderShapes.parts`), and a point is pulled inside the drawn width at its height, so a stepped tower, a crown or a spire throws from its real wall and not from the sim's box (which is wider up there). Above the highest part the point comes down to its top.

## What it does not do

The shader decides which cells have a pane by a hash of the drawn part's instance index (`win_hash(vec3(instance, column, row + 57))`); VFX cannot read the instance, so a sliver may be thrown from a cell Rendering drew blank. The columns, rows and pane spans are right; the share of cells with one (`win[3]`) is ignored. If Rendering exposes `RenderShapes.pane_present(b, column, row)` (the same hash from the building's index), the grid can skip blank cells.

## Downtown at fight framing (collapse clip, HEAD 45564bc6 plus this)

Facade tone about 21, 23, 31 in sRGB, relative luminance 0.010 to 0.019 (`capture-web` ai collapse, ticks 150 to 400). Against it:

| Effect colour | Luminance | Contrast against the slate |
| :-- | ---: | ---: |
| city dust: light, mid, shadow | 0.60, 0.42, 0.21 | 10 to 4 : 1 |
| flame tongue | 0.45 | 7 : 1 |
| ember core, hot, warm | 0.89, 0.69, 0.54 | 14 to 9 : 1 |
| ember **char** (the last fifth of its life) | 0.018 | 1 : 1, read by its light rim only |
| glass sliver | 0.93 | 14 : 1 |

Everything reads. The trouble downtown is the other way round: any moving mark is a high step against a near-black wall, so under a camera pan the counted area is the marks' own. That is what the area budgets (`EMBER_AREA_SHARE`, `PUFF_AREA_SHARE`) are for.
