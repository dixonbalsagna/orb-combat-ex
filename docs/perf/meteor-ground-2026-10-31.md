# Is the far ground ready when the meteor lands, and what does a read there cost? (Performance and Platform, 2026-10-31 night)

For the EP, on the added item: the meteor's landing at 36°, 48° and 60° round (D = 15,355, 20,473 and 25,592 u; Research's curve lands 1.551 H out, 36° round = 15,355, 59.6° = 25,436; `docs/world/ring-any-angle/meteor-arc.md`). Native, headless, main `66654335` plus the stack (the tree of `hitch-table-2026-10-31.md`), planets 7, 12 and 21, both sides of the send, **one fresh process per case** (a field world's lattice nodes are built on first read and kept, so a cold read is only the first in a process). The bake is finished as the host's load finishes it.

## Answer

1. **For the sim, the landing is ready and a read there is cheap.** At all 18 (planet, angle, side) cases the landing's ground and sea read (`WorldTerrain.groundY` + `seaAt`) cost **90 µs to 1.0 ms cold (one outlier; the rest under 450 µs), 20 to 300 µs warm, 0 new lattice nodes**, on the far scope (the 512 bake) and on the near scope alike. Research's descent check (25 reads, one every 500 u back from the landing) costs **0.8 to 2.2 ms** on either scope, 0 new nodes. In the launch tick that is +1 to 2 ms on top of today's 18 to 27 ms. With both fighters put on the landing and 90 ticks stepped cold: 0 new nodes in all three planets; planet 12 and 21 first tick 2.8 and 3.2 ms and a mean 0.7 ms; planet 7 had 13 to 25 ms ticks in its first ten (cause not split; machine busy, three jobs running).
2. **For the tile ground, the far ground is NOT ready when the shot arrives.** Level 0 is there after the load; levels 1 and 2 (256 and 128 u) under the landing's footprint (the line ±4,500 u, three depths) are **all missing**: 3 to 6 level-1 tiles and 8 to 12 level-2 tiles, **1,400 to 2,900 (level 1) plus 3,700 to 5,700 (level 2) new lattice nodes, 0.5 to 1.3 s of work** (about 100 µs a node: `WorldField.ensure` inside `RenderTileField._fill_job`). The fill runs 1,500 µs a frame (`RenderLook.TILE_FILL_US`, ×3 only for a tile within 3,000 u of the camera's ground), so it needs **330 to 890 frames at the normal slice, 110 to 300 urgent**, against a flight of 372 frames (6.2 s). It does not depend on the angle (the footprint is the same size at 15,000 or 25,000 u; only the cold nodes count), and the table below is the same for the three.
3. **Nothing asks for those tiles early.** `RenderTileGround._walk` wants tiles where the camera's walk goes, nearest first; the landing is far from the camera until the descent, so its tiles are first wanted when it comes into view (the apex on, 2.6 s ≈ 156 frames, at the normal slice: about 230 ms of the 500 to 1,300 ms needed, 18 to 47%). The ground the meteor lands on would show as coarse level-0 or level-1 ground and pop finer after the impact.

## The tiles under the landing, cold (frames at 1.5 ms and at 4.5 ms for levels 1 and 2 together)

| planet | deg | side | D | level 1 tiles missing of under, fill | level 2 | frames at 1.5 ms (L1+L2) | at 4.5 ms |
|---|---|---|---|---|---|---|---|
| 7 | 36 | -1 | 15355 | 5 of 5, 262 ms, 2429 nodes | 8 of 8, 369 ms, 3802 nodes | 421 | 140 |
| 7 | 36 | +1 | 15355 | 5 of 5, 325 ms, 2426 nodes | 12 of 12, 595 ms, 5665 nodes | 613 | 204 |
| 7 | 48 | -1 | 20473 | 5 of 5, 537 ms, 2438 nodes | 11 of 11, 797 ms, 5140 nodes | 889 | 296 |
| 7 | 48 | +1 | 20473 | 5 of 5, 287 ms, 2398 nodes | 12 of 12, 675 ms, 5512 nodes | 641 | 214 |
| 7 | 60 | -1 | 25592 | 4 of 4, 551 ms, 1914 nodes | 12 of 12, 639 ms, 5541 nodes | 794 | 265 |
| 7 | 60 | +1 | 25592 | 3 of 3, 154 ms, 1382 nodes | 10 of 10, 440 ms, 4444 nodes | 396 | 132 |
| 12 | 36 | -1 | 15355 | 6 of 6, 368 ms, 2820 nodes | 8 of 8, 395 ms, 3737 nodes | 508 | 169 |
| 12 | 36 | +1 | 15355 | 6 of 6, 433 ms, 2893 nodes | 10 of 10, 553 ms, 4600 nodes | 657 | 219 |
| 12 | 48 | -1 | 20473 | 4 of 4, 253 ms, 2000 nodes | 8 of 8, 350 ms, 3761 nodes | 402 | 134 |
| 12 | 48 | +1 | 20473 | 5 of 5, 276 ms, 2511 nodes | 8 of 8, 323 ms, 3784 nodes | 400 | 133 |
| 12 | 60 | -1 | 25592 | 4 of 4, 190 ms, 1980 nodes | 10 of 10, 367 ms, 4739 nodes | 371 | 124 |
| 12 | 60 | +1 | 25592 | 3 of 3, 127 ms, 1564 nodes | 9 of 9, 365 ms, 4291 nodes | 328 | 109 |
| 21 | 36 | -1 | 15355 | 5 of 5, 433 ms, 2350 nodes | 9 of 9, 657 ms, 4244 nodes | 727 | 242 |
| 21 | 36 | +1 | 15355 | 4 of 4, 249 ms, 1916 nodes | 11 of 11, 639 ms, 5053 nodes | 592 | 197 |
| 21 | 48 | -1 | 20473 | 4 of 4, 353 ms, 2043 nodes | 10 of 10, 725 ms, 4740 nodes | 719 | 240 |
| 21 | 48 | +1 | 20473 | 4 of 4, 273 ms, 1894 nodes | 10 of 10, 625 ms, 4406 nodes | 599 | 200 |
| 21 | 60 | -1 | 25592 | 4 of 4, 452 ms, 1935 nodes | 9 of 9, 744 ms, 4167 nodes | 797 | 266 |
| 21 | 60 | +1 | 25592 | 5 of 5, 512 ms, 2341 nodes | 10 of 10, 791 ms, 4488 nodes | 869 | 290 |

Load for reference: level 0 and the fight's near tiles take 1.1 to 2.0 s and about 5,300 new nodes (that is the tile ground's share of the page load already in `page-load-*.md`).

## What to do (proposals; nothing changed)

- **Rendering: want the landing's tiles at the send.** The landing is known then (`x0 + side·D`, or the three candidates at 85 to 100%): request levels 1 and 2 around it from the send, with a bigger slice (3 to 4.5 ms) for the first 2 s of the flight when the camera is looking at the pair and the frame has room. Level 1 alone (150 to 550 ms) fits in 120 to 370 frames at 1.5 ms; level 2 needs the larger slice.
- **Simulation/World: the node build is the cost** (100 µs a node; 784 nodes a tile). A cheaper node, or building the coarse levels of the landing in the load's idle time, shortens everything above; the per-node cost is also what makes the 40 to 60 ms water ticks in `hitch-table-2026-10-31.md`.
- **Combat/Encounter: the 25-read descent check is affordable** (about 1 to 2 ms); with the closed form there is no need for `predictFlight`'s 240 ticks, which is the launch tick's biggest cost today (4 to 16 ms).

## Limits

Headless native: the tile fill is timed, but nothing is drawn, so "ready" means the heights and ids are stored (`RenderTileField.has`), not that the picture was seen. The camera's footprint is my guess (the line ±4,500 u, three depths); a wider view wants more tiles. The ground is read straight along the line at x0 ± D (a great-circle line, as Research's closed form flies); the swing and the camera may turn the bearing, which moves the tiles but not the cost. Wall time on a busy PC with three jobs at once; read the node counts first, the milliseconds as upper bounds. The 18 cases are AI-free (no match was played to the send); the landing's tick (a crater, damage, civilians) was not run.

## Files

`docs/perf/tools/swing-bench/meteor_ground.gd` (one case: `--planet=7 --deg=60 --side=1`).
