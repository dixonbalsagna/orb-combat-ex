# Park: the lake dig, GW2 (World, 2026-11-20; GD's section 4b ruling: no walls; Game Design's `minNodes` ruling; re-cut after the stand-in's review, LD-01 to LD-06)

**Shipped off, with no key in the code patch** (a missing `plans.lakeDig` reads as off, so the planet data's hash and every saved match's key are exactly what they were). The data row that switches it on is separate. The look gate (planet 7's lakes against the 9 November build) is **not** done: the EP's window comes after GW1a lands. Records: `docs/world/runs/lake-dig/`.

## Files and the tree they stack on

Cut and run on the planet stack on main `6bb03b08`: `data-switches-gw1a`, `cache-determinism`, `floor-rise` (+ `grant-simulation-floorfor`), `lake-places` (+ `grant-rendering-tile-water`), `memory-under-model`, `lake-shore`; re-cut with the rest of the planet stack after GW1a and GW1b.

| File | What |
| :--- | :--- |
| `lake-dig.diff` | the code and the check: `sim/world/waterrec.gd` (`digCfg` with `DIG_DEFAULTS`, `_footprint`, `_spillFlood`, `_digLake`, `_twins`, `_canon`, `dugGround`, the dig in `lakeOf`; a lake record gains `dug`), `sim/world/field.gd` (`applyRecords` cuts the bowl before the pads and the water read the ground), `sim/world/plan.gd` (the eight-corner test of a building's footprint, **only where the dig is on**: LD-06 below), `sim/world/tools/lake_dig_check.gd` (new, `LAKEDIG`). **No data, no schema, no check-list line.** Strict-applies on the tree above |
| `grant-tools-lake-dig.patch` | **Tools' files** (LD-05): `tools/schemas/biomes-field.schema.json` (`plans.lakeDig`) and `tools/world-checks.json` (the `lake_dig_check` line after `street_axis_check`). Lands before the data row |
| `lake-dig-data.diff` | the GW2 row: `plans.lakeDig {on true, maxDepth 300, slope 0.33, minNodes 40}`, **added after `farShare`, not beside `lakeSpill`**. It applies together with `lake-shore-data.diff` **in either order** (tested both ways on the stack's `field.json`). The dig only runs with `lakeSpill` on, so it goes with `lake-shore-data.diff` |

Order: the stack, `lake-dig.diff`, the grant, then the two data rows (`lake-shore-data`, `lake-dig-data`, either order).

## What it does

The lake's level is its spill level (`lakeSpill`). Inside the lake's **planned footprint** the ground joined to the seed and at most `maxDepth` (300) over that level is cut into a bowl: the new shore is the edge of the cut ground, the floor falls from the level at no more than `slope` (1 in 3, counted along the grid with a 3 percent margin) and no deeper than 300 under it. Higher ground stays shore or island. Never cut: the lower ground the real basin's flood did not reach, and the nodes touching it (the rim keeps its height, so the level holds). **A lake whose dug water is under `minNodes` (40) is not dug** and stays the real basin. The bowl is a field record: a point's ground is the field's less what the dug nodes of its cell take off, never under the lowest floor.

**On a face edge of the cube (LD-04).** The three test planets do cross edges: planet 12 has 54 dug nodes on an edge and planet 3 has 24 (planet 7 none). A point on an edge has one number on each face it touches, and the reader looks a cell's corners up by the face the point is on, while the graph reached a node by whichever number its neighbour gave: two numbers had two independent depths, and the ground stepped by up to 59 units across the edge (210 with no twin stored at all). Fixed: the dig's graph is on **canonical nodes** (the lowest of a node's numbers), and the water's nodes and the dug floors are stored under every twin as well. The row reads the dug amount 0.002 of a cell to either side of every dug edge node: **0.56 at most** (the control without the twins: 209.5).

## Result (`runs/lake-dig/`): 6 of the 12 lakes dig

| Planet, touch | lakes | real basins only | dug | water nodes | open shore links | deepest dug point | steepest bowl |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 7, 3 | 6 | 79 | **2** of 6 | 655 | **0** | 242 | 0.226 |
| 12, 1 | 2 | 29 | **2** of 2 | 300 | 0 | 142 | 0.241 |
| 3, 2 | 4 | 40 | **2** of 4 | 367 | 0 | 139 | 0.226 |

**`LAKEDIG`: 0 failed**, forced on with the code's numbers whether or not the data row has landed:
- the dig digs (6 of 12), holds more water than the spill alone (1,322 nodes against 148), **0 open shore links**, no dug point deeper than 300 (**every dug node** sampled, at the node and inside its cell, on the ground the game reads: the field plus every record, pads and lots included; the old sampler stopped at 400 nodes), the bowl no steeper than 0.33, and the edge row above;
- **controls that must fail (LD-03):** the lakes as the plan made them (no spill, no dig) have 642 open shore links (so "no walls" can fail); a dig allowed to 1,000 deep on a steeper bowl is 1,000 deep (so "at most 300" can fail); a dig allowed to 100 stays within it; without the twins the edge steps by 209.5; `minNodes` above every lake and the dig off both give the spill's water exactly; with no `lakeDig` key in the data the dig is off and the lakes are the spill's.

**Shipped off (LD-02).** State hash (gameplay) of a gen 3 match, 240 ticks, planets 7, 12 and 3, spill off and on: **identical with the dig code absent and with it present and off, in all six runs**; with the dig on the same matches run twice give the same hash (planet 12 with the spill on differs from the off run, as it must: its lakes are dug) (`parity-dig-off-and-twice.txt`). With no key in the code patch the planet data's hash and every saved match's key are unchanged by this park; the data row changes `field.json` and so changes them when it lands, as `lake-shore-data` does.

**Animation's gate**, `water_tile_check --strict --shore` on planet 7 with `lakeSpill`, `lakeMax` 8 and the dig on: passes (2 places hold a lake's level, 0 beyond 6 of the drawn surface, the first wet column 78.5 deep at worst, tolerance 150). With the dig row alone and the spill off the shore row fails (795.6), as it does without the dig: the rows go together. The match is made as fast with the dig as without (planet 7: 4.5 s each; planet 3: 4.3 against 4.1).

## Buildings in the dug lakes (LD-06): fixed, on the dig path only

With the places laid on the whole planet, `lakeMax` 8 and the spill on, the first count found **1 building standing in the dug water on planet 3, 27 units deep** (none on planets 7 and 12): the trim read the ground at a building's centre and the pad is flat across its footprint, so a building at a bowl's shore could end deeper than `lakeMax`. The EP asked for the eight-corner test: `layFree` now also tests the water at the eight points of the circle round the footprint (the points `_overhangs` uses) and drops a building if any is deeper than `lakeMax`, **but only where the dig is on** (`lakeMax` on, the spill on, a dig config), so with the dig off the places are exactly what they were. Result: **0 buildings in water over 1 in the dug lakes** on all three planets (planet 3 lays 3,868 of 3,872; planet 7 3,834 of 3,835; planet 12 3,704 of 3,705); the control without the corner test (a test-only flag) finds the 1 building again, so the row can fail. **The proof the dig off moves nothing** (`parity-places-dig-off.txt`, the same comparison as LD-02, now with the places on the whole planet and `lakeMax` 8): the count of buildings, a hash of every building's direction, and the state hash are **identical** with the dig code absent and with it present and off, on all three planets; with the dig on, each run twice gives the same digest.

## For the look gate (Art, Camera: after GW1a)

- **The bowl's wall**: ground over the level and under level + 300 is cut, ground over level + 300 is not, so where the natural wall continues up the cut edge is a step of the difference over one node (a node is a few hundred units across): a cut hillside, not a slope. That is the ruling. **If it reads as a cliff, Game Design wants it softened as a look fix with no change to the water**: it can only reshape ground above the level (a ramp from the cut edge up to the natural wall), a separate piece after the stills.
- **The rim**: a node touching lower outside ground keeps its height, so a lake on a slope has a rim line at its level and a pit above it.

## NEEDS FROM EP

- **The look-gate window** after GW1a lands.
- **Tools**: `grant-tools-lake-dig.patch` and the cases: `plans.lakeDig` valid `{on: true, maxDepth: 300, slope: 0.33, minNodes: 40}` and `{}`; invalid `{on: 1}`, `{maxDepth: 0}`, `{slope: 0}`, `{minNodes: 1.5}`, `{minNodes: -1}`, `{extra: 1}`.

## RISKS

- The dug lakes change the ground (so the hash) of every gen 3 planet with a dug lake: the data row flips with `lake-shore-data.diff`, in a window.
- The cache keys: `lakeDig` is in `field.json`, whose hash is in a saved match's key; shipped off there is no key and no change.
- The tiles read the dug ground through the same records. A lake record's `r` reaches the farthest dug node, but Rendering's `_records_reach` was not widened for it: watch the tiles at a bowl's edge in the look gate.
- The water's node lookup (`lakeDepth`) is by the face a point is on; the dug lakes' nodes now carry their twins, the undug lakes' do not (as before).

**Re-cut on main b0e20f9a, 2026-11-21** (`docs/world/planet-stack-recut.md`, records `docs/world/runs/planet-stack-recut/`): `lake-dig.diff` and `grant-tools-lake-dig.patch` re-cut (gw1c-world changed the lake record's reach line; the check list moved).
