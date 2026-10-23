# Planet generation: three techniques, pictured

Research & Prototyping, 2026-10-23, for Orb's request: "pour resources into improving our planet generation, biomes, fighter animations". This study covers the planet and biome part.

It compares three techniques against today's planet. Each was built as a fast JS prototype and rendered for the same six seeds (7, 11, 23, 42, 101, 2026). The pictures are an equirect map, a globe and a side view of the 4,800-column ring a fight happens on.
- **Code:** `research/planet-gen/` (README there).
- **Pictures:** `research/planet-gen/img/`.
- **Every number per seed:** [planet-gen-tables.md](planet-gen-tables.md).

Nothing in the game was changed.

## The short answer

- **A, the climate table, is the biggest step for the least cost.** Temperature by latitude and height, plus moisture carried by prevailing winds with a rain shadow, feed a temperature-by-moisture biome table.
  - **Variety:** today's 5 land biomes become 12 to 14 a planet, and a fight ring crosses about 10 biomes instead of 4.
  - **Fit:** it is a pure function of a point, so it drops into `WorldPlanet.surfAt` as it is. No per-planet set-up.
  - **Cost:** about 3.3 times today's per-column cost, so about 170 ms a slice in GDScript against today's 52 ms.
  - **Port first.**
- **B, plate-lite, changes the shapes most.**
  - **What changes:** ranges run along plate edges; island arcs and trenches face oceans; continents can rift; hotspots leave island chains. Continents stop being noise blobs.
  - **Cost:** about 6.7 times today's per column.
  - **Still to fix:** it needs a day of tuning against three artifacts: parallel edges, range spits poking into the polar sea, and flat triangles where three plates meet.
  - **Port second, behind a switch.**
- **C, erosion-lite, gives rivers and lakes.** Fight rings cross 3 to 26 rivers.
  - **The catch:** it is the only technique that needs per-planet set-up, a grid over the whole planet.
  - **Grid cost:** at 600-unit cells it costs as much as reading 35 to 56 of today's slices, once per planet. That is an estimated 2 to 7 s in GDScript.
  - **How to run it:** it belongs in a time-sliced job at the run's start, like World's slice job. The read per column after that is cheap.
  - **Port third.** Rivers and lakes are its value; its carving matters less.
- **The poles.** Today's north pack and south sheet cut continents along straight lines of latitude, visible in every "today" map at about 47 to 55 degrees. All three approaches use a noisy polar bias instead and let the cold make the ice. World's floes and bergs can sit on that sea ice unchanged.
- **Every one of these changes Everhold.** Seed 7 is the canon planet Orb was "very pleased" with. `compare-s7.png` shows today's Everhold against the new ones, so this is Orb's call before any port lands (see Risks).

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
- The ring strips use a square-root height scale, so the hills a fight crosses show next to the ranges.
- The ring strips mark rivers as blue ticks.

## 1. The toolkit, and why World can port it bit-exact

`lib/det.mjs` is WorldPlanet's own arithmetic in JS:
- the 32-bit lattice hash (`_fm`), value noise and fbm, written as the same expressions in the same order;
- the series atan;
- the sim's sin, cos and pow (`sim/core/detmath.js`);
- keyed integer draws.

**Proven twice:**
1. A line-for-line JS port of today's surface reads **128 of 128** of World's golden points bit-identically, height bits and biome (`check-base.mjs`, `sim/world/tools/planet_vectors.json`).
2. A GDScript run of `WorldPlanet.surfAt` over 4,800 points gives the same checksums as the JS run (2450021.215 and 25877850.853).

**The same rules hold in all three approaches:**
- only + - * / sqrt floor, the sim's sin, cos and pow, and integer hashing;
- seeded, integer-keyed draws;
- sorts and the erosion heap break ties by index;
- the erosion's passes are order-free (Jacobi).

**Caveat:** A, B and C themselves were not run in GDScript. Their portability rests on using only the proven primitives. In JS, every approach reads the same values cold, warm (in reverse order) and from a fresh planet: 900 of 900 points, so the memos change no result.

## 2. The three approaches

### A: the climate table (`gen/climate.mjs`, about 200 lines)

- **Temperature.** Sea-level temperature falls with latitude (28 - 30y² - 18y⁴ °C: 19 °C at 30 degrees, -5 °C at 60, -20 °C at the pole). It drops 6 °C per 1,000 units of height, and noise breaks up the bands. The climate belts meander, because |y| is read with a little noise.
- **Moisture.** The air marches 10 steps upwind, 1,800 units each, along the band's prevailing wind: easterlies to 30 degrees, westerlies to 60, then polar easterlies, blended across the edges.
  - Over warm sea the air recharges. Over land it loses water. Every rise rains it out, so the lee of a range is dry.
  - The arriving moisture is scaled by a latitude band (wet equator, dry subtropics, wet mid-latitudes, dry poles) and a windward boost.
  - A convection floor keeps tropical interiors from drying out.
- **The table.** Five temperature rows, each with precipitation bands, pick the biome.
  - Cold and height add ice sheet, snowcap and alpine. Low and wet ground adds wetland, and the coast adds beach. Cold sea becomes sea ice.
  - A broad noise dithers temperature and rain, so borders are ragged ecotones rather than contour lines.
- **The cost lever.** The arriving moisture is computed only at the corners of a 1,500-unit 3D lattice and blended like value noise. A slice shares corners, so it marches about 410 corners instead of 4,800 points. That brought A from about 5 to about 3 times today's per-column cost.
- **Two traps found and fixed:**
  - a hard land-or-sea test in the march aliased into stripes parallel to every coast, one step apart. A smooth coast ramp cured it;
  - marching over single peaks cast thin shadow lines along the wind. The march now reads a low-pass ground.
- **Biomes:** 16 land biomes plus deep ocean, shallow sea and sea ice.

### B: plate-lite (`gen/plates.mjs`, about 160 lines)

- **The plates.** 14 seeded plates, each with a centre and an Euler pole; 8 carry continents. Each point finds its three nearest plates from a noise-warped point, a warped Voronoi on the sphere.
- **The crust.** It is low-frequency noise biased by plate type and blended near shared edges, so coastlines do not follow plate edges.
- **Landforms by relative motion across each edge:**
  - continents converging: a high range;
  - ocean under continent: a trench offshore and a volcanic coastal range;
  - ocean meeting ocean: a trench and an island arc broken by noise;
  - oceans diverging: a mid-ocean ridge;
  - continents diverging: a rift valley with raised shoulders, opening in segments.
- **Other features:** hotspots leave chains of older, lower islands along the plate's motion. Continents get rolling relief and old worn ranges (ridged noise).
- **Continuity.** Every pair term is gated by how close the point is to that pair's shared edge, from dot products only, so heights are continuous across every edge.
- **Biomes:** A's table, plus volcanic fields on arcs, rifts and hotspots (17 land biomes).
- **The cost** is the ground itself, about 30 octaves a point against today's 7 to 15. Fewer warp and relief octaves are the first lever.

### C: erosion-lite (`gen/erosion.mjs`, about 190 lines)

- **The grid.** A cube-sphere grid of 6N² cells: N = 128 gives 300-unit cells; N = 64 gives 600-unit cells. Neighbours across cube edges are found by reprojecting.
- **Inputs:** heights from the input ground; rain from A's precipitation.
- **Four passes, each:**
  1. **Priority flood from the sea inward.** Every land cell then drains; a deep fill in a wet basin is a lake.
  2. **Route.** Each cell drains to its steepest lower neighbour.
  3. **Accumulate rain downstream.** This is the flow.
  4. **Carve.** An implicit stream-power step: h = (h + F h_downstream) / (1 + F), with F = K √flow / distance. It is stable at any K.
  5. **Slump.** Slopes steeper than the talus angle slide down (a Jacobi pass).
- **The read** is the input ground plus the bilinear carve, a lake's level, and a river channel where the point is within a channel's width of a river segment.
- **Biomes:** A's table, plus lake, river and badlands (arid, warm and strongly eroded).
- **`Cb`** is the same on A's ground, the route if plates wait.

## 3. Results (six seeds; medians, with the range in brackets)

| | Today | A | B | C (on B) | C on A |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Land, % of the planet | 63 (54 to 81) | 68 (59 to 86) | 54 (46 to 60) | 52 (44 to 57) | 68 (59 to 84) |
| Land biomes over 1% of the land | 5 | 12 to 14 | 12 to 15 | 12 to 15 | 12 to 14 |
| Biomes the fight ring crosses | 4 (3 to 5) | 10.5 (9 to 14) | 11 (7 to 12) | 12 (9 to 13) | 10.5 (9 to 14) |
| Biome changes along the ring | 16.5 | 46.5 | 75 | 79.5 | 47.5 |
| Rivers the ring crosses | 0 | 0 | 0 | 3 to 14 | 6 to 26 |
| Lakes, % of the planet | 0 | 0 | 0 | 1.1 to 3.2 | 0 to 2.9 |
| Rings meeting the picker's minimum | 6 of 6 | 6 of 6 | 5 of 6 | 5 of 6 | 6 of 6 |

**Notes:**
- **B and C missed once.** For seed 42 no ring met the minimum. The likely reason is that the land spreads over many small biomes, so fewer than three reach 8% on 96 samples. The picker's "3 biomes of 8%" was tuned for 5 biomes and needs a second look with 16.
- **Land share.** A keeps today's continents (plus the southern land). B's land share is set by how many plates carry continents (`contShare`).

## 4. Cost against the 4,800-column slice

**How it was measured:**
- **GDScript, today:** `WorldPlanet.surfAt` with World's corner cache costs **10.4 to 11.4 µs a column**, about **52 ms a slice**, on this PC on 2026-10-23. Other sessions held the CPU at about 49%, so treat it as an upper bound.
- **JS, the same function and points:** 0.6 to 0.7 µs a column. GDScript is therefore about **16 times** slower on this noise-heavy code.
- **Approaches:** measured in JS against today in the same run (cold memo, best of 5), then scaled by today's GDScript cost.

| | Per column, times today | Per column, GDScript (est.) | A slice, GDScript (est.) | Per-planet set-up |
| :--- | ---: | ---: | ---: | :--- |
| Today | 1 | 11 µs | 52 ms | none |
| A (lattice) | 3.3 (2.8 to 3.9) | 36 µs | 170 ms | none (a memo fills as slices read) |
| A without the lattice | 5 to 10 | | | |
| B | 6.7 (4.6 to 8.0) | 72 µs | 350 ms | none |
| C (on B) | 6.4 (4.9 to 9.1) | 69 µs | 330 ms | the grid: JS 0.53 s at N = 128, 0.17 s at N = 64 |
| C on A | 3.9 (2.7 to 5.5) | 42 µs | 200 ms | the grid: JS 0.38 s at N = 128, 0.11 s at N = 64 |

**The grid's cost by size** (`costs.mjs`, seed 7):

| N | Cells | Cell (units) | On B, JS | On today's ground, JS | Rivers (cells) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 32 | 6,144 | 1,200 | 119 ms | 57 ms | about 40 to 100 |
| 48 | 13,824 | 800 | 118 ms | 88 ms | about 210 to 240 |
| 64 | 24,576 | 600 | 171 ms | 106 ms | about 480 |
| 96 | 55,296 | 400 | 240 ms | 190 ms | about 1,220 |
| 128 | 98,304 | 300 | 424 ms | 259 ms | about 2,400 |

**What dominates the grid's cost:** the heights and the rain. The erosion passes themselves are 7 to 83 ms. At N = 64 the grid equals 35 to 56 of today's JS slice reads; in GDScript that is about 1.7 to 2.7 s at the measured 16 times. The heap and array loops were not measured in GDScript and may run slower than the noise code. The honest range is therefore 2 to 7 s on this PC, and about ten times that on a slow phone (`docs/perf/audit-2026-10-16.md`).

## 5. What World should port first

1. **The climate table (A), in `surfAt`.**
   - **Data:** the temperature, the moisture lattice with its upwind march, and the table as data in `data/biomes/planet.json` (rows of [temperature, [rain, biome]...]), plus the dither and the belt meander.
   - **Biome ids:** the list grows from 7 to about 19. Keep the ids of today's ice biomes.
   - **Goldens:** the vectors regenerate.
   - **Cost:** about 3 times per column, no set-up.
   - **Biggest win.** The prototype is `gen/climate.mjs`, about 200 lines.
2. **The polar bias (`gen/poles.mjs`) in place of the straight-edged blend.** The north sinks and the south becomes low land, with noisy edges. The climate makes the ice; World's floes and bergs stay as the sea ice's detail.
3. **Plates (B) as the ground, behind a switch.**
   - **What it replaces:** the continent and range noise.
   - **First tuning:** parallel edges, polar spits, triple-junction plateaus and the octave count.
   - **Cost:** about 7 times per column, or 350 ms a slice in GDScript. It is worth it only with the octave cuts.
4. **The erosion grid (C) at N = 64 as a time-sliced per-planet job.**
   - **Use:** take its rivers and lakes into the slice as a water flag per column (a channel cut in the column) and lake levels. The carve is optional.
   - **Fit:** it fits World's existing time-sliced loading. Read the grid nearest the touch-down first.
   - **Without plates:** C on A gives the same rivers on today's ground.

## Risks and limits

- **Everhold changes under all of them.** Two ways forward:
  - keep a generator version in the planet data, so story planets pin today's function;
  - or have Orb judge the new seed 7 (`compare-s7.png`) and re-canon it.

  Either needs Orb's word before a port lands.
- **Cost on weak machines.**
  - A slice in GDScript grows from about 52 ms to 170 ms (A) or 350 ms (B).
  - The erosion grid is seconds on desktop, so phones need the time-sliced job or a smaller grid.
  - All GDScript figures are estimates from one measured ratio.
- **B's artifacts.** These need tuning before Orb judges B on its merits:
  - long parallel edges where several plates line up;
  - snowy ranges that survive the north's sinking as thin spits;
  - flat triangles where three converging plates meet;
  - value noise's grid alignment showing in the ridged ranges.
- **Rivers follow grid segments.** They are straight runs of 300 to 600 units. A small meander noise on the channel position would hide it.
- **The climate is a game model, not physics.** It has no seasons or ocean currents, and zonal stripes show on the maps (less on globes). The numbers (°C, mm) are there to make the table readable, not to claim realism.
- **Land share drifts by approach.** A plus the south lift gives up to 86% land on seeds that today already have 81%. The south lift can be weakened where the ground is already land.
- **Machine.** One headless Godot process ran for the GDScript ratio, about 20 s, from a scratch script, while about 16 other Godot processes from other sessions were running. Every JS run was short, and nothing of this study is still running.

## Files

- **Code:** `research/planet-gen/`: the generators, renderer, runs and README. Nothing outside `research/` imports it.
- **Pictures and numbers:** `research/planet-gen/img/` (about 31 MB: maps, ring-centred globes, rings, sheets) and `research/planet-gen/stats/*.json`.
- **Tables:** `docs/research/planet-gen-tables.md`: each biome's share of land per seed and approach, the fight read per seed, and the costs per seed.
