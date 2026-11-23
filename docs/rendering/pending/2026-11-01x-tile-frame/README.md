# The tile ground's frame does less while the view turns

Parked by Rendering, 2026-11-01. `tileframe.diff` stacks on `2026-11-01w-no-street-on-steep/low_street.diff`, and needs `2026-11-01r-fill-slice`. Only with the tile ground's switch on.

**The fault.** Performance's bisect: Orb's slow stretch with the fighters far apart is `RenderTileGround.apply`, about 6.7 ms always and 15 to 16 ms while the frame turns.

**What it was.** Not the tile selection, which is cheap. A timer on each part (per pane, per call, capture ratios), far apart and turning:

| Part | Before | Why |
| :--- | ---: | :--- |
| Fill | 4.80 ms | its urgent budget, whatever the frame is doing |
| Sight line | 2.47 ms | 64 reads of the sim's ground, each a cold terrain column once a swing moves the frame |
| Lift table | 0.97 ms | any change in the line's axis marked all of it stale, so it never finished while turning |
| Footings | 0.23 ms | kept scanning with no tile changed |
| Picking tiles | 0.22 ms | |

**The change.** Nothing is released or culled, so no pop or hole comes from it.
- The fill's urgent budget only when the frame is under its target.
- The sight line takes a crater's dent from the store directly (a grid lookup), and is read at most every 4 selections while only the view turns.
- The lift table goes stale at most every 8 frames, at half budget while turning, read from the feet out.
- The footings scan again only after a tile changed, and read 2 a frame, not 6, when the frame is over target.
- Captures set `RenderTileField.steady_fill`, so reels keep their fill rate and don't go coarse. Timing them needs it off.

**Result, Performance's `perf-stretch`, Orb's first match, ticks 1562 to 1644, scratch exports of stack tree 2b9dfe14, two runs each, ms a frame.** Before / in the stretch / after:

| | Whole frame | View update |
| :--- | ---: | ---: |
| Before this diff | 34.6 / 47.3 / 32.9 and 34.4 / 49.2 / 34.5 | 15.2 / 24.3 / 14.6 and 15.1 / 24.8 / 15.3 |
| With it, captures pinned | 30.6 / 36.1 / 33.3 and 30.8 / 33.8 / 29.2 | 13.9 / 14.8 / 13.9 and 13.8 / 14.0 / 12.6 |
| With it, as in play | 25.1 / 29.0 / 26.6 and 25.4 / 30.4 / 25.6 | 11.1 / 11.1 / 9.6 and 11.3 / 11.4 / 9.5 |

The view update's rise in the stretch, about 9.5 ms, is gone. The first "before" run read 61 and 62 percent load, just past the 60 percent rule, so it's marked invalid; the rest are valid. The harness's frame is slower than Orb's, so ratios carry and absolutes don't. That tree's data differs from the recording's, so this may not be the very same match; draw calls match run to run, and Orb's second match is measured separately against a tree that reproduces it.

**Seen:** `docs/rendering/img/lookgate/tile-frame-before-after.png`, six ticks, each pair left before, right after: no visible difference.

**What it costs.** While tiles are arriving and the frame is over target, the fill runs at 1.5 ms: finer ground comes later there, and the coarser parent stays drawn. The sight line can lag up to 4 selections while the view turns and the camera has moved under 128 units. Neither was seen as a change in those frames. In play, not looked at.

**Dents.** The sight line now reads the store on a field world. World's own store holds craters, scorch and trenches, which is what it needed; `groundY` also took anything else the sim's ground has on the line, and any such thing is now not in the sight line.

**Gates**, with a to x stacked on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; off 13 stills 0 differ. The 20 render gates exit 0, but run without the tile word. The chain applies on main, apply check only.
