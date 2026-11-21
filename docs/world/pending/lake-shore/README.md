# Park: no lake's water begins above its shore (World, 2026-11-20; EP, from Animation's edge numbers on the GW1a stack plus floor-rise)

Animation's finding: walking right from x 23,800 on planet 7 the fighter meets a lake edge at x 23,976 to 24,008 and floor-rise lifts him from ground 1,236 to the lake level 2,062.5 (837 units over 5 ticks); the ground climbs smoothly while the floor jumps 846 in 48; two more edges (x 21,792 to 21,824: the water starts 456 above the ground; x 27,872 to 27,904: it ends 500 above). **It is not the everywhere fault**: with `plans.everywhere` off or on the floor at those columns is identical (probed), so it is not lake-places' either. It is the lake generator's, in Orb's 9 November build too. Runs: `docs/world/runs/lake-shore/`.

| File | What |
| :--- | :--- |
| `lake-shore.diff` | World's: `sim/world/waterrec.gd` (`lakeOf`'s flood, `spillOn`, `spillOverride`), `data/biomes/field.json` (`plans.lakeSpill` **false**) and its schema, `sim/world/tools/lake_shore_check.gd` (new, `LAKESHORE`, in CI) and its line in `tools/world-checks.json`. Applies strictly on HEAD, and in order after cache-determinism, floor-rise, lake-places and memory-under-model (tested) |
| `lake-shore-data.diff` | The GW1b data row: `plans.lakeSpill` true. It changes every gen 3 planet's lake records (the hash), so it flips in a window |

## Cause

`WorldWaterRec.lakeOf` takes the ring plan's lake (`[first column, last column, level, width]`: a valley on **one line**, its level that line's rim) and floods the field's canonical nodes in 2D from the lowest column's cell **up to that level, but only out to `maxr`** (twice the lake's width on the line, 800 to 6,000 units): "a leak is cut here". Where the flood is cut while the land beyond is still below the level, the water simply ends in the air over a hillside: a slab. Measured on planets 7 (touch 3), 12 and 3: **every lake has about half of its shore links open** (a node with water beside a node outside the lake whose ground is below the level): 1,404 of 2,430 links, the worst **2,898 units** (planet 7's highest lake, level 2,748.7).

## The fix (`plans.lakeSpill`)

The level of a lake is the lower of the plan's level and its **spill**: a priority flood from the seed (the lowest ground first, each node's pass the highest ground on the best way to it) finds the lowest pass out of the basin: out of its bound, into a lake planned before it (`claimed`), down to the sea (`TRIM_G`), or past the node cap. The lake's nodes are those whose pass is under the final level, so the water runs where the land holds it and nowhere else. Off (shipped): the old flood, unchanged.

## Result

| | Off (today) | `lakeSpill` on |
| :--- | :--- | :--- |
| `LAKESHORE`: open shore links, planets 7, 12, 3 | 1,404 (the worst 2,898 units) | **0** |
| lake nodes | 13,327 | 148 |
| the reported edges (x 23,960 to 24,120; 21,792 to 21,824; 27,872 to 27,904) | the floor jumps to 2,062.5, 989.5, 2,062.5 over ground 1,276, 533, 1,570 | the floor is the ground at every one |

**The cost is the finding: nearly all of the generator's lakes are not real in 2D.** The ring's valley is a valley on the line; as a basin in the planet's ground almost none is closed: their seeds sit on slopes and the water would run off. With true hydrology 148 nodes remain of 13,327 (planet 7: 79 of 6,641), i.e. almost no lakes. So the choice is Game Design's and Orb's, not a number I can pick:
1. **Real basins only** (this park): honest water, almost no lakes on the globe ground. The strip's own valleys (the old 1D lakes on the ring, the gen 2 look) are no longer water.
2. **Carve the basins**: make each lake real by cutting the ground round the ring's valley into a bowl at the plan's level (a crater-like dig of the field at generation, or lower the walls to the rim along the line): lakes stay as they were, on ground that holds them. Larger: a change to the planet's ground (the hash, the tiles, Rendering).
3. **A real lake planner on the field** (basins found in the planet's 2D ground, independent of the ring): the right long-term answer, after Alpha.

Until one of these, the slab lakes stay as Orb's build has them, and the tile fix (`lake-places`' grant) draws them as raised slabs: the fighters stand on the water the picture shows, but the water is over a hillside.

## NEEDS FROM EP

- **Game Design** (and Orb): which of the three. I would not flip this row without it (it removes most lakes).
- **Rendering**: if option 1 or 3, nothing; if the slabs stay, the water on a hillside is a look call.

## RISKS

- `SimField`'s record-water memo (`_w0`, `_w1`) kept values across two matches in one process when I switched the switch between them (a probe read the first match's lakes in the second); in play the data does not change within a process, so it is a tests-only trap, noted here and not fixed.
- The priority flood's cost: a sorted insert per node, at most `MAX_NODES` 8,000 a lake; not timed (shared machine).
