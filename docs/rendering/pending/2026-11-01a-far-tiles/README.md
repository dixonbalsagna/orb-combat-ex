# Parked: far tiles asked for before the camera gets there (`2026-11-01a-far-tiles`)

Rendering, 2026-11-01, for `docs/perf/meteor-ground-2026-10-31.md`. Stacks on `2026-10-31a-tile-ground/tile.diff` and `2026-10-31b-near-towers/near.diff`. On only with the tile ground's switch.

**What it adds:**
- `RenderTileField.ask_around(x, frame)`: asks for levels 1 and 2 under a strip x (the line 4,500 u either side, at three depths), level 1 first, at a 4.5 ms slice for 120 frames, then the normal 1.5 ms. The camera's own wants still come first.
- `RenderTileGround._look_ahead`: every 30 ticks, a fighter faster than 2,500 u/s along the line has the ground 2 s ahead of him asked for. This covers fast flight generally.

**The meteor's send has no caller yet:** the shot isn't in the sim. When it lands, the send calls `pane.planet.tile_field.ask_around(x0 + side * D, S.frame)`, or the view watches for the send's event. On a closed-form flight `vx` may not be set, so `_look_ahead` can't be relied on for it.

**Cost, native, headless, 18 cases (planets 7, 12, 21; 36°, 48°, 60°; both sides), each from a level-0-only field, machine at 60% load:**

| | |
| :--- | :--- |
| Tiles asked | 7 to 13 |
| Nodes read | 5,488 to 10,192 |
| Work | 239 to 741 ms |
| Frames, against a 372-frame flight | 69 to 224 |
| Worst slice | 5 ms (once 19) |

**On the web expect about 2.6 times the node cost** (a scaling, not measured): about 180 to 580 frames at the same slice, so on some landings level 2 wouldn't finish in the flight. Level 1 comes first, so what shows then is 256 u ground. A frame pays up to 4.5 ms more for up to 2 s of a launch that's already expensive.

**Apply:** on a scratch export with the two parks under it: `git -c core.autocrlf=false apply --ignore-whitespace far.diff`. `tile_check` passes on it.
