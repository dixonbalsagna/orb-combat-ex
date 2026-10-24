# Planet generation: three techniques, pictured

Research & Prototyping, 2026-10-23, for Orb's request: "pour resources into improving our planet generation, biomes, fighter animations". This study covers the planet and biome part.

It compares three techniques against today's planet. Each was built as a fast JS prototype and rendered for the same six seeds (7, 11, 23, 42, 101, 2026). The pictures are an equirect map, a globe and a side view of the 4,800-column ring a fight happens on.
- **Code:** `research/planet-gen/` (README there).
- **Pictures:** `research/planet-gen/img/`.
- **Every number per seed:** [planet-gen-tables.md](planet-gen-tables.md).

Nothing in the game was changed.

**Two rounds.**
- **Round 1** built the three approaches.
- **Round 2** came from the EP's follow-up brief. Three agents worked in separate copies of the study, each with a judge and a revision round: B was tuned, A was sped up, and C's rivers were bent off the grid. I then added floes on the north sea ice and a shallow pack sea, widened the climate belts, kept rivers off ice, and put every fight ring's touch-down on land, as WorldPlanet's is. A final judge-and-critic agent checked the pictures, the claims and the port.

This document describes round 2, the code as it stands. The round-1 pictures are kept outside the repo.

## The short answer

- **A, the climate table, is the one to port first.** Temperature comes from latitude and height. Moisture is carried by prevailing winds and has a rain shadow. A temperature-by-moisture table picks the biome.
  - **Variety:** today's 5 land biomes become 12 to 15 a planet, and a fight ring crosses a median of 11.5 biomes instead of 4.
  - **Fit:** it is a pure function of a point, so it drops into `WorldPlanet.surfAt`. No per-planet set-up.
  - **Cost:** about 1.8 times today per column, in both noise work and JS time. That is about 20 µs a column and 95 ms a slice in GDScript, against today's 52 ms.
- **B, plate-lite, changes the shapes most, and the tuning has landed.**
  - **What it adds:** ranges on plate edges (a crest belt on foothills), island arcs and trenches, rifts in offset segments, hotspot island chains. Coastlines bend inside plates.
  - **Fixed in round 2:** the parallel plate edges, the range spits in the polar sea and the junction plateaus.
  - **Cost:** 3.4 times today in noise work, 4.3 in JS time. About 40 to 50 µs a column and 180 to 230 ms a slice in GDScript.
- **C, erosion-lite, gives rivers and lakes.**
  - **Rivers:** fight rings cross 6 to 27 of them, now as curves that stay on the valley floor.
  - **Lakes:** 0.2 to 2.9% of the planet.
  - **The catch:** it needs a whole-planet grid at the planet's start. At 600-unit cells that costs 69 ms (on today's ground) to 153 ms (on B) in JS, an estimated 1 to 5 s in GDScript. That calls for a time-sliced job.
  - **After the grid,** a column costs about 2 (on A) to 4.6 (on B) times today's.
- **The poles.** Today's north pack and south sheet cut continents along straight lines of latitude, which every "today" map shows at about 47 to 55 degrees. Here:
  - a noisy polar bias makes the south a continent and the far north a shallow pack sea;
  - the climate's cold makes the ice;
  - today's own floes, leads and bergs sit on the sea ice.
- **Everhold changes under every approach.** Seed 7 is the canon planet Orb was "very pleased" with. `compare-s7.png` shows today's Everhold against the new ones. The question is in Orb's homework: pin story planets to generator 1, or re-canon.

## What to look at

| Picture | Shows |
| :--- | :--- |
| `img/compare-s<seed>.png` | Today, A, B and C side by side for one seed: maps on top, then the front and back of each globe |
| `img/sheet-<approach>.png` | One approach across the six seeds: how varied its planets are |
| `img/rings-s<seed>.png` | The fight ring side on in every approach: what a match would cross |
| `img/<approach>/s<seed>-globe.png` | The globe centred on the fight ring's touch-down, with the ring drawn |
| `img/legend.png` | The 24 biomes and which approaches produce them |

**Reading the pictures:**
- On the maps, the dotted line is the fight ring and the red cross is its touch-down.
- The ring strips use a square-root height scale, mark rivers as blue ticks, and draw sea ice as a slab from the ice down to the sea floor, as they do for today's planet.

## 1. The toolkit, and why World can port it bit-exact

`lib/det.mjs` is WorldPlanet's own arithmetic in JS:
- the 32-bit lattice hash (`_fm`), value noise and fbm, written as the same expressions in the same order;
- the series atan;
- the sim's sin, cos and pow (`sim/core/detmath.js`);
- keyed integer draws.

**What is proven:**
1. A line-for-line JS port of today's surface reads **128 of 128** of World's golden points bit-identically, height bits and biome (`check-base.mjs`).
2. A GDScript run of `WorldPlanet.surfAt` over 4,800 points gives the same checksums as the JS run (2450021.215 and 25877850.853). That run also measured GDScript at about **16 times** slower than JS on this noise code.
3. Every approach reads the same values cold, warm and from a fresh planet: 300 of 300 points each for A, B, C and on-A, so the memos change no result (`check-pure.mjs`).
4. The climate's lean path agrees with its full path on 120,000 sampled points (`check-lean.mjs`). Its correctness rests on monotone bounds computed in the same order as the values, so a port must keep that order.

**What is not proven:**
- A, B and C were not run in GDScript.
- `draw()` and `randUnit()` (keyed draws and seeded unit vectors) are not in `planet.gd`, so they need golden vectors of their own (section 6).

## 2. The approaches

### A: the climate table (`gen/climate.mjs`)

- **Temperature.** Sea-level temperature falls with latitude (28 - 30a² - 18a⁴ °C: 19 °C at 30 degrees, -5 °C at 60, -20 °C at the pole). It drops 6 °C per 1,000 units of height. A noise of ±3 °C breaks up the bands.
  - Here a is |y| read with a meander of ±0.13 (beltAmp, scale 10,000; round 1 used ±0.07 at 12,000), so the climate belts wave and the zonal stripes soften.
- **Moisture.** The air marches 10 steps upwind, 1,800 units each, along the band's prevailing wind: easterlies to 30 degrees, westerlies to 60, then polar easterlies, blended across the edges.
  - Over warm sea the air recharges. Over land it loses water. Every rise rains it out, so the lee of a range is dry.
  - The arriving moisture is scaled by a latitude band and a windward boost, with a convection floor.
  - The march reads a low-pass ground, so single peaks cast no shadow lines. A smooth coast ramp avoids aliasing stripes.
- **The lattice.** The arriving moisture is computed only at the corners of a 1,500-unit 3D lattice and blended like value noise, as a pure memo. A slice marches about 240 to 470 corners instead of 4,800 points.
- **The table.** Five temperature rows, each with precipitation bands, pick the biome.
  - Cold and height add ice sheet, snowcap and alpine. Low and wet ground adds wetland, and the coast adds beach. Cold sea becomes sea ice.
  - A broad dither makes the borders ragged.
- **The lean path (round 2).** Each noise is drawn only while it can still change the biome. Bounds from |y|, the belt, the sea-level noise and the dither settle the biome early. On land, the rain's bounds skip the windward read and the rain noise when both fall in one band of the table.
  - The output is identical: round 2's speed-up alone left every picture byte-identical.
  - On that path, temperature is NaN where it was never needed. A caller that wants temperature and precipitation passes `full = true`, as approach C does.
- **Biomes:** 16 land biomes plus deep ocean, shallow sea and sea ice.

### The poles and the floes (`gen/poles.mjs`, `gen/floes.mjs`)

- **The bias.** A noisy polar bias on the ground: the south becomes low land (an ice continent by the cold), and the north sinks by 3,200 units.
- **The shallow pack sea.** Past 55% of the way into the north band, the ground is eased to a shallow pack sea at -500 units (today's is -380). The pole is always open sea, and no high range survives as an ice slab.
- **The floes.** Today's floes, leads and bergs (WorldPlanet's cellular noise and numbers) sit on sea colder than -1 °C. The pack's concentration comes from the sea's temperature, not latitude.
  - Floes stand only on sea shallower than -1,200, because a slice holds one height a column. Elsewhere the climate's flat sea ice stands at the sea's depth.
  - The floe test is skipped where the sea cannot be that cold, which changes no result.

### B: plate-lite (`gen/plates.mjs`)

- **The plates.** 14 seeded plates, each with an Euler pole, continental or oceanic.
  - Each plate is made of one or more of 30 Voronoi cells, whose centres keep a minimum separation (no sliver plates, so no rows of parallel edges). Plate outlines bend at every cell corner.
  - A point finds its nearest cells from a noise-warped point.
- **The crust.** A low-frequency noise read at the warped point, with a small plate bias blended over every cell in reach, levelled per planet to a land share. Coastlines wander inside plates.
- **Landforms by relative motion across each edge:**
  - continents converging: a crest belt on a foothill apron, cut by ridged noise into crests, saddles and spurs;
  - ocean under continent: a trench offshore and a volcanic arc;
  - ocean meeting ocean: a trench and an island arc of ragged islands on a shallow ridge;
  - oceans diverging: a mid-ocean ridge;
  - continents diverging: a rift in offset segments, each with one raised shoulder.
- **Junctions and poles.** Where three plates meet, the two stronger arms join and the weakest stops short in a rounded cap. Landforms fade toward the poles in the poles' own coordinate.
- **Other features:** hotspots leave island chains; old worn ranges cross the interiors in pieces.
- **Continuity:** the field is continuous everywhere, with 0 jumps on all six seeds.
- **Set-up:** 1 to 7 ms in JS per planet, counting plate areas and the crust's level on 2,000 seeded points and tabulating each pair of cells' edge.
- **Biomes:** A's table, plus volcanic fields on arcs, rifts and hotspots.

### C: erosion-lite (`gen/erosion.mjs`)

- **The grid.** A cube-sphere grid of 6N² cells (N = 128 in the pictures: 300-unit cells). Heights come from the input ground, and rain from A's precipitation.
- **Four passes, each:**
  1. **Priority flood from the sea inward.** Every land cell then drains; a deep fill in a wet basin is a lake.
  2. **Route.** Each cell drains to its steepest lower neighbour.
  3. **Accumulate rain downstream.**
  4. **Carve, in drainage order.** An implicit stream-power step: h = (h + F h_downstream) / (1 + F), F = K √flow / distance. It is stable at any K.
  5. **Slump.** Slopes steeper than the talus angle slide down. Each move is computed from the pass's starting heights, then summed in cell and neighbour order.
- **The rivers (round 2).** Each river step becomes a Hermite curve through the routed centres, with tangents from the largest upstream cell to the receiver.
  - Two waves push it sideways, continuous along the river: a meander whose amplitude varies slowly by keyed noise, and a longer bend that grows on straight runs.
  - A sideways budget of at most half a cell shrinks where the valley sides rise, so the channel stays on its valley floor.
  - Mouths end where the river crosses the coast.
  - Every cell lists the river runs that can reach it, and the per-column read and the map drawing use the same 9-point runs.
- **The read.** A column reads the input ground plus the bilinear carve, a lake's level, or a river channel cut into it. A river on an ice sheet or a snowcap is frozen: no channel, no water.
- **Lakes.** The river work left lakes and the carve bit-identical. B's new ground did change C's lakes, from 1.1–3.2% to 0.2–1.6% of the planet.
- **Biomes:** A's table, plus lake, river and badlands. **C on A** is the same on A's ground.

## 3. Results (six seeds; medians, with the range in brackets)

| | Today | A | B | C (on B) | C on A |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Land, % of the planet | 63 (54 to 81) | 66 (59 to 85) | 51 (49 to 57) | 50 (49 to 57) | 65 (59 to 84) |
| Land biomes over 1% of the land | 5 | 12 to 15 | 12 to 14 | 12 to 14 | 12 to 15 |
| Biomes the fight ring crosses | 4 (3 to 5) | 11.5 (6 to 14) | 11 (7 to 13) | 10.5 (7 to 13) | 11 (6 to 14) |
| Biome changes along the ring | 16.5 | 48 | 70 | 69 | 53.5 |
| Rivers the ring crosses | 0 | 0 | 0 | 9 to 17 | 6 to 27 |
| Lakes, % of the planet | 0 | 0 | 0 | 0.2 to 1.6 | 0 to 2.9 |
| Rings meeting the picker's minimum | 6 of 6 | 6 of 6 | 6 of 6 | 6 of 6 | 6 of 6 |

**Notes:**
- **The touch-down is on land in round 2.** As in WorldPlanet (`touchLand`), each candidate ring is turned along its circle to the land column nearest its middle, never on sea or ice sheet. With that change every ring meets the minimum; in round 1, seed 42 (B and C) and then seed 2026 missed.
- **Rings near the equator are narrow.** The 6- and 7-biome rings (seed 23 in A and B, for example) never leave the tropics. Of the 96 candidate rings, 15 stay below 30 degrees. The picker could prefer rings that cross more climate belts (see Risks).

## 4. Cost against the 4,800-column slice

**How it was measured:**
- **GDScript, today:** `WorldPlanet.surfAt` costs about **11 µs a column, 52 ms a slice** in GDScript on this PC (busy: an upper bound). That is about 16 times its JS cost.
- **The approaches:** `bench-ring.mjs` reads each fight ring cold, alternating 7 times with today's function on the same ring, and gives the median time ratio. It also counts the noise octaves a column reads (det.mjs `OCT_COUNT`) against today's.
- **Which to trust:** the octave ratio is the steadier figure and scales to GDScript. The time ratio also holds JS-only effects and non-noise work. B's plate loops are non-noise and may weigh more in GDScript.
- **Load:** the machine was at about 60 to 80% load from other sessions, so the time ratios are noisy.

| Per column, times today | Octaves | JS time | GDScript per column (est.) | A slice in GDScript (est.) | Per-planet set-up (JS) |
| :--- | ---: | ---: | ---: | ---: | :--- |
| Today | 1 (9.5 octaves) | 1 | 11 µs | 52 ms | none |
| A | 1.84 | 1.74 | about 20 µs | about 95 ms | none |
| B | 3.43 | 4.3 (3.1 to 6.4) | 38 to 47 µs | 180 to 230 ms | 1 to 7 ms |
| C (on B) | 3.83 | 4.6 (3.8 to 6.0) | 42 to 51 µs | 200 to 240 ms | the grid: 0.32 to 0.58 s at N = 128 |
| C on A | 2.34 | 2.05 | 23 to 26 µs | 110 to 125 ms | the grid: 0.25 to 0.41 s at N = 128 |
| Round 1, for comparison | A 2.96, B about 5.5 | A 3.3, B 6.6, C 5.8 | | A 170 ms, B 350 ms | |

**The grid's cost by size** (`costs.mjs`, seed 7, the current code):

| N | Cells | Cell (units) | On B, JS | On today's ground, JS | Rivers (cells) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 32 | 6,144 | 1,200 | 132 ms | 50 ms | about 90 |
| 48 | 13,824 | 800 | 125 ms | 63 ms | about 250 |
| 64 | 24,576 | 600 | 153 ms | 69 ms | about 490 to 570 |
| 96 | 55,296 | 400 | 249 ms | 112 ms | about 1,250 to 1,350 |
| 128 | 98,304 | 300 | 375 ms | 183 ms | about 2,400 to 2,760 |

**What dominates the grid's cost:**
- At N = 64, the grid equals 24 (today's ground) to 52 (B) of today's JS slice reads.
- At the measured 16 times, that is about 1.1 to 2.4 s in GDScript. The routing, heap and river loops were not measured in GDScript and may run slower than the noise code, so the honest range is 1 to 5 s on this PC and about ten times that on a slow phone.
- The river curves add 1 to 28 ms of the grid's JS cost.
- Every picture uses N = 128. The river look at N = 64 has not been reviewed.

## 5. What World should port first

1. **The climate table (A), in `surfAt`.**
   - **Data:** the temperature, the moisture lattice with its upwind march, the lean path, the floes on its sea ice, and the table as data in `data/biomes/planet.json` (rows of [temperature, [rain, biome]...]).
   - **Biome ids:** the list grows from 7 to about 19. Keep the ids of today's ice biomes.
   - **Goldens:** the vectors regenerate.
   - **Cost:** about 1.8 times per column, no set-up.
2. **The polar bias with the shallow pack sea (`gen/poles.mjs`)** in place of the straight-edged blend. Today's floes and bergs carry over as `gen/floes.mjs` shows.
3. **Plates (B) as the ground, behind a switch.**
   - **What it replaces:** the continent and range noise.
   - **Cost:** about 3.4 to 4.3 times per column, or 180 to 230 ms a slice in GDScript.
   - **Measure first:** the plate loops once ported.
4. **The erosion grid (C) at N = 64 as a time-sliced per-planet job.**
   - **Use:** its rivers and lakes enter the slice as a water flag per column and lake levels. The carve is optional.
   - **Fit:** it fits World's existing time-sliced loading. Read the grid nearest the touch-down first.
   - **Without plates:** C on A gives the same rivers on today's ground.

## 6. Port notes for World (from the critic's read of the code)

- **32-bit grids.** The erosion grid stores its carve, lake, flow and height in `Float32Array` (`erosion.mjs`), and the lake level becomes the column's height. Use `PackedFloat32Array` to get the same bits.
- **Keyed draws.** `draw()` and `randUnit()` (`det.mjs`) use `Math.imul` and 32-bit XOR. In GDScript, mask each product and XOR with `& 0xFFFFFFFF` as `planet.gd` does. Every plate centre, pole, hotspot, island, rift segment and meander depends on them, so give them golden vectors.
- **Order of operations.**
  - The slump sums its moves in cell order and neighbour-list order.
  - The carve runs in drainage order.
  - The climate's lean bounds are computed in the same order as the values.

  Keep all three orders.
- **JS idioms.** `Math.sqrt(...) || 1` in `plates.mjs` treats NaN as falsy; GDScript's `or` returns a bool, so write the test out. `& 63` and `& 1023` on `Math.floor` results need `int()` first.
- **Memo sentinels and NaN.** NaN marks an empty slot in the climate's memo, so use `is_nan()`. The lean path returns temperature as NaN.
- **Hidden mutable state.** `S.volc` must be read before the climate's march overwrites it. The plates' `S.dots`, and the climate's march buffers and last-cell cache, are shared scratch. The code is not re-entrant, so a threaded slice job needs one state per worker.
- **Timing calls.** `performance.now()` in `buildErosion` is timing only; drop it.

## Risks and limits

- **Everhold changes under all of them** (Orb's homework).
- **Cost on weak machines.**
  - A slice in GDScript grows from about 52 ms to about 95 ms (A) or 180 to 230 ms (B).
  - The erosion grid is seconds, so phones need the time-sliced job or a smaller grid.
  - All GDScript figures are estimates from one measured ratio; B's plate loops are the least certain.
- **Still to look at, by eye:**
  - **A:** the zonal bands are softer, not gone. The worst is the south coast, where forest, tundra and ice run as bands right round the planet at 45 to 60°S. Seed 101 keeps a round dome island at about 58°N.
  - **B:**
    - at map scale the ranges can read as scattered crest dabs, so the plate story is weaker than in round 1 (seeds 42 and 23);
    - the crest texture can look pocked close up;
    - north coasts tend to run along about 50°N;
    - the north fade is a latitude mask, not a cause.
  - **C:**
    - rivers bend only within half a cell, so at map scale they read almost as before;
    - long straight runs stay straight;
    - lake edges are blocky.
- **A rule for Game Design and World.** A river that runs along the fight ring makes a comb of crossings (seed 23's C ring: 9 crossings, the closest 2 columns apart). Count it as one river (fill gaps under about 6 columns), or set a minimum spacing?
- **The picker.** It now puts the touch-down on land. It could also prefer rings that leave the tropics, but the game's own picker is World's (WorldPlanet's candidates through cities).
- **Fingerprints.** The ring fingerprints hash 32-bit heights: they show the read is unchanged, not 64-bit identity. 64-bit identity is what `check-base` and `check-pure` test.
- **Machine.** One headless Godot process ran in round 1, about 20 s. Round 2 ran JS only: renders and benches at below-normal priority, the agents' short renders at normal. No Chrome. Nothing is still running.

## Files

- **Code:** `research/planet-gen/`: the generators, renderer, checks (`check-base`, `check-pure`, `check-lean`), `bench-ring.mjs`, `costs.mjs`, and the runs.
- **Pictures:** `research/planet-gen/img/`. The comparison sheets and legend are committed; the per-seed maps stay local.
- **Tables:** `docs/research/planet-gen-tables.md`: each biome's share of land per seed and approach, the fight read per seed, and run.mjs's costs per seed (best of 5, noisier than bench-ring).
