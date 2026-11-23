# The tile fill's least slice halves, with World's water-read

Parked by Rendering, 2026-11-02. `fill_floor.diff` stacks on `2026-11-01z-sweep-by-view/viewcap.diff`. **Lands with or after World's `docs/world/pending/water-read`, not before.** Only with the tile ground's switch on.

**What the standing cost was.** After x, y and z, the tile ground's frame is about 2.4 ms on Orb's second match, and 1.8 of it is the fill. A probe (scratch) counted why. The whole match starts only about 170 tiles, all levels 1 and 2, none of them a re-bake. Each takes about 90 ms of baking, at about 115 us a ground point, so 17 to 55 wanted tiles are always queued and the fill spends its least slice (1.5 ms) on every frame. Where a point's time went: World's node read (`WorldField.ensure`) 38 us, the records 26, the water 32, the rest about 20.

**World's water-read halves the point.** With it applied: records 26 to 6 us, water 32 to 2.4, a point 115 to 62 us. Tiles start twice as often (330 in the match, not 175). The fill's time a frame doesn't move, since it spends its slice either way.

**The change.** `RenderLook.TILE_FILL_US` 1500 to 750 us. With water-read, tiles arrive at today's pace (163 in the match, against 175 today) for half the time. With room in the frame the fill still takes its share of the room (up to 6 ms), as before. An urgent tile near the camera still raises it there to 4.5 ms: `TILE_URGENT_X` goes 3 to 6 so the product stays.

**Result, perf-run on Orb's second match to tick 8000, both with x, y, z and World's water-read, back to back, both valid (load 20/12 and 15/58), ms a frame.** Before / after:

| | Fill | Tile ground's frame | View |
| :--- | ---: | ---: | ---: |
| Whole match (median) | 1.7 / 0.9 | 2.4 / 1.5 | 5.7 / 5.2 |
| 3570-3705 (mean) | 1.7 / 0.9 | 3.4 / 2.5 | 8.0 / 6.9 |

The harness's frames are always over target, so it always runs the least slice: that's the case this changes. On a frame with room nothing changes.

**What it costs.** Without water-read, tiles would arrive at half today's pace, the coarser parent drawn meanwhile: hence the land order. With it, the pace is today's, so the picture is today's.

**What's left of a point's time:** World's node read, about 32 to 40 us, half of it now. That's World's (`WorldField.ensure`); a warm-up at load would move it out of play.

**Gates**, on a to z plus this: import clean; tile and sweep checks pass; with 11-02b on top, golden byte-identical, the 20 render gates exit 0 and off 13 stills 0 differ. The constants are read only on the tile ground. The chain applies on main 18852c72, apply check only.
