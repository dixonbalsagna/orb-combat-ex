# Planet generation 3: the field (World, 2026-11-01)

Owner: World and Environment. Orb's order of 2026-10-31: a working version with the 3D world. This is stage 3 of `ring-any-angle/research.md` T6: **the field defines the ground**, behind a switch. The switch is a setup's `planetGen: 3`; gen 1 and gen 2 never read any of it and are byte-identical (proved by the gates in each park's README). Code: `sim/world/field.gd` (`WorldField`), data: `data/biomes/field.json` (schema `biomes.field/1`), checks: `sim/world/tools/field_check.gd`, `field_load_check.gd`, `field_records_check.gd`.

## What it is

A gen 3 planet is a **field of nodes on a cube-sphere**. A node is exactly what a gen 2 ring column holds at that point (the planet's surface read plus the surface detail), so gen 3's ground is gen 2's, sampled and joined by triangles. A ring column (the 32-unit strip the sim stands on) is a **lookup**, the same at any bearing, for any ring, in any order. Places, the picker and the climate are still the planet's own function (a gen 3 planet has the same places as its gen 2 twin, to the bit).

| | |
| :--- | :--- |
| **Lattice** | Six faces, equal-angle: `direction = normalize(n + e1 tan(s pi/4) + e2 tan(t pi/4))`, `s, t` in [-1, 1]. Rendering's tile key (the `FACES` table of `docs/rendering/pending/2026-10-31-swing-test/bake.gd`), with our own sin, cos and atan |
| **Canonical** | `cells` 300 a face: 128 units along a face's edge (38,400 / 300). 543,606 nodes in all, read **on demand**, kept as float32 heights plus a stored and a fine biome byte (about 3.3 MB when whole) |
| **Bake** | Every 4th node (`bakeStride`): 512 units, 75 cells a face, 34,656 nodes, **nested** in the canonical lattice (a bake node is a canonical node, so the two levels agree at every shared point). Read whole as a phase of the planet load (`SimPlanetLoad`, phase `bake`) before a match starts. 1.7 s on this PC (48 us a node); its hash (`bakeHash`) is the thing two builds must agree on |
| **Between nodes** | The cell's two triangles (diagonal `u + v = 1`, as the drawn mesh), height; the nearest node's biome |
| **Records** | `refine` (field.json): a cell whose corners step by more than 75 units, or whose corner heights span the shoreline's (SHORE_WET, widened by 40), is read again at 32 units (`sub` 4), exactly as the planet's function gives it. A cell beside it carries the difference along the shared edge, fading across the cell, so there is no crack (0.16 units at most, measured). A rule of the cell's own four corners, so every machine refines the same cells whatever it has read. Cells on a face's rim are never refined. On planet 7, touch 1, Half ring: column RMS against gen 2's exact ring **9.55 to 3.34**, shoreline displacement **95 to 16 units RMS** (max 160 to 32), 2,877 extra reads (about 140 ms), 4 of 4 shore crossings kept |
| **Trees** | `WorldGround.layTrees` keys a tree by the column's **planet cell** (`WorldField.cellKey`: face and the point in quarters of a cell, 32 units) and a planet seed, not by the column's index and the slice's hash. A ring read backwards lays the same trees (checked); the old keying lays others (the control) |
| **Water** | Unchanged code: the sea and shore water read `S.base`, which is now the field's ground |

## Rules that keep it safe (from `simulation.md` 7 and 9)

1. Whether the bake is done is never a sim input. The load finishes it before tick 0 (`mayStart`/`ready` ask `WorldField.bakeReady`).
2. **Which level a read uses is fixed by the reader.** Near readers (`sample`, step 1) always read the canonical nodes and the records, computing a missing node on the spot. The forecasts (step `bakeStride`) always read the bake. Nothing picks a level by what happens to be loaded.
3. One thread, no bake on disk, the field is outside the sim state and a pure function of the seed and the data. `WorldPlanet.forget()` drops it.
4. A gen 3 planet's data hash carries field.json (`WorldPlanet.dataHash(3)` ends `/f<hash>`): a replay on another field is refused.

## The API (for Simulation and Rendering)

All static on `WorldField`; the planet must be gen 3 (`WorldClimate.useGen(3)` then `WorldPlanet.make(seed)`).

- `of(P) -> Field`: the planet's field, memoised by the seed (three kept).
- `sample(F, qx, qy, qz, step = 1)`: the ground at a unit direction; sets `F.oh` (height), `F.ob` (stored biome of the nearest node), `F.ofine`. `step` 1 is the canonical read with the records, `bakeStride()` the bake's read.
- `dirOf(face, i, j, n) -> [x, y, z]`: node (i, j) of a face at `n` cells. `n = cells()` for canonical nodes, `cells() * sub` for sub-nodes.
- `block(F, face, i0, j0, n, step = 1) -> {h, b, f}`: (n + 1)^2 canonical or bake nodes as packed arrays for a tile. **No records in a block**: a tile that wants the exact ground in a creased cell calls `sample` at its own vertices.
- `ensure(F, face, i, j)`, `cellRefined(F, face, i, j)`, `cellKey(F)` (after a `sample`), `bakeStep(F, units)`, `bakeUnits(F)`, `bakeReady(seed)`, `F.bakeHash`.
- `WorldPlanet.farColumn` and `farField` read the field for a gen 3 planet (the canonical read where the detail is read, the bake past `coarseFrom`).

## Costs measured here (this PC, native, below-normal, shared)

| | |
| :--- | :--- |
| Bake | 34,656 nodes, 1,669 ms (48 us a node); the web at 50 us a node is about 1.7 s, the old laptop about 6 to 11 s, by Performance's figures |
| A Half ring cold | 1,144 canonical nodes beyond the bake, about 55 ms; with the records 2,877 sub-reads more, about 140 ms |
| Match start, planet cold | gen 2 1.5 to 1.9 s, gen 3 1.2 to 1.3 s without the records and the same with them (the planet's make dominates) |
| The ring against gen 2's exact one | RMS 9.5 without the records, 3.3 with them; max 79 to 80 (one wall on a face's rim or a step the records miss) |

## What this does not do

- **Lakes and rivers are still planned on the ring's own line** (`WorldLakes.plan`, `WorldRivers.plan` on the gen 3 strip). They are right for a ring that does not swing and would blink in a swing: stage 8.
- **Places are still laid from the chord** (towns by plan is stage 9; cities frozen on the strip stay as they are).
- **The renderer's props** (`WorldGround.propsIn`) are still keyed by column index; only the sim's trees are keyed by planet cell.
- **Labs, the `hill_chapel` and `bell_tower` data change, the level argument on `seaTop`, `baseY` and `slope`, the 64-node seeded sample in the match key, and the bake's web parity** are other owners' or later. See each park's README.
- `render/core/ground_field.gd` `gen2_ring` tests `== 2`: a gen 3 match reads as not gen 2 there until it says `>= 2` (a Rendering grant, `docs/world/pending/gen3-field/grant-rendering.patch`).

## Rendering's four asks (EP, 2026-10-31)

1. **Refined reads are on the N = 1200 lattice, nested in 300, on `dirOf`, 32 units.** `dirOf(face, i4, j4, cells() * sub)` with `i4 = i * sub + k`; every fourth sub-node is the canonical node (the same value, to the bit).
2. **`WorldField.refinedByCorners(h00, h10, h01, h11) -> bool`** is the one rule, from four corner heights, no noise and no state. `WorldField.refined(P, face, i, j)` reads the corners for a planet. A cell on a face's rim is never refined (the rule says so in `cellRefined`).
3. **The diagonal** runs from (a+1, b) to (a, b+1), `u + v = 1`: below it the triangle (a, b), (a+1, b), (a, b+1); above it (a+1, b+1), (a, b+1), (a+1, b). Documented at `WorldField.sample`; a refined cell cuts its sub-cells the same way.
4. **One shoreline value: `WorldField.shore()` = `WorldWater.SHORE_WET`** (-18.75 units), the height below which the sim's sea fills a connected column. The water's surface is `WorldWater.SEA_LEVEL` (0); open sea is ground below `WorldWater.RESERVOIR_BASE`.

Also in the contract with Simulation: `height`, `biome`, `fine`, `heightBake`, `biomeBake` (pure reads at a unit direction), `nodeH(P, face, i, j)`, `dataHash()`. `WorldStore` (`sim/world/store.gd`) is the planet store for craters: records at planet points, `heightDelta` at a direction, a count and running hash for the state's digest, `copy` for a snapshot.

## Towns and cities by plan (World, first cut, `sim/world/plan.gd`, field.json `plans`)

A gen 3 place is generated in its own frame and the strip takes what falls in a lane, so **the same town stands the same at any bearing**: the same buildings (`plan` index, seed, size, kind) at the same planet point (`dir`), measured on two rings of any bearing through a city and a town (0 differ, 46 and 60 shared).

- **The plan**: WorldSettle.generate on a flat dry stand-in, the place's street (a strip with its rows) laid in **bands** one lane-band (32 fighter heights) apart, 2 each side of the middle for a city and 1 for a town, each as long as the disc is wide at its offset, each its own seeded layout. The street axis is the place's frame turned by a keyed yaw (24 choices in a half turn), so the town does not turn with the ring.
- **On a ring**: a building's planet point is read against the ring (arc along, lateral offset l); it stands if z = l falls in a block or scenery lane (rows 1 and 2, and 0 and 3 when the foreground is on), takes that lane's row and flush z, is kept if the ground under it takes a footprint and no kept building of the row overlaps it. Footprints are not rotated: an oblique cut shows a staircase of lanes, not a turned town. Avenues are kept where the street runs within about 10 degrees of the line.
- **People** are shared out among the buildings that stand (`WorldSettle.assignPeople`, taken out of `generate` unchanged), so a place's people are the same whatever stands: 1,800 in all, every ring tried.
- **Bound to the state**: `planet_world.settle` takes the ring and returns each building's unit planet direction (`dirs`); `gen` fills `S.bDir` (PackedFloat64Array, three each, building order) when the state has that field, for Simulation's bound pose arrays. A place that would stand fewer than `minBuildings` (6) on a ring falls back to the chord layout, and the calm turn's new places are still laid from the chord.
- **What it costs in density** (buildings standing, chord layout against plan, gen 3, Half ring, planets and touches 7/1, 7/2, 3/1, 3/2, 11/1, 25/1): 46 to 25, 169 to 110, 105 to 48, 47 to 29, 9 to 9, 117 to 58. About a half, because a plan is a few streets and a ring cuts them at an angle. `plans.enabled` false restores the chord layout; more bands or a closer pitch raise the count. This is a look for Orb and a number for Game Design's 60-structure rule.
- **Not done**: cities are still frozen where the ring first meets them (the calm turn aside), no two-dimensional street grid, and no rotated footprints.

## RL-214: `bell_tower` and `hill_chapel` (data half)

`data/biomes/settlements.json`: the landmark `bell_tower` is now `clock_tower` (the key only; its index, shape and numbers are the same, so no building and no golden key moves: parity passes), and `hill_chapel` carries `"noTarget": true`, read by `WorldSettle.noTarget(landmarkIndex)`. The schema has the optional `noTarget`. **Encounter's half**: the director's candidate lists and arrival scores skip a building whose `noTarget(b.landmark)` is true. **Rendering's half**: `render/core/shapes.gd:440` tests `mark == "bell_tower"`. **Tools'**: the fixture `settle-landmark-duplicate` names the old key (changed in this park). **Art's**: `art/concepts/world/gen.mjs` still names `bell_tower`.

**Depth sign (EP's check, 2026-11-01).** The sim's z is positive toward the camera, away from the ring's centre; `farColumn`'s z and `farPlaces`' z are positive toward the centre. No gen 3 code hands either of those to the sim: `WorldField` has no depth, and `farPlaces` is not read. `plan.gd` was wrong on first writing (it took `lateral()`, positive toward the centre, as the sim's z) and is fixed: a building's depth is `-lateral`, a plan's `v` runs toward the camera (`pointOf` moves by `-v` along the left axis), and `dirAtStrip(x, z)` takes the sim's z (it rotates toward the centre by `-z / R`). A check holds the sign (aligned with the street, 44 of 44 buildings keep the sign of their plan depth).

### Density: why a keyed plan halves, and the fix (EP's order of 2026-11-01)

Why a plan with a keyed street yaw stood about half the chord layout (25 of 46, 110 of 169, 48 of 105, 29 of 47, 58 of 117): the fight lanes are cut to the blocks of a street that runs along the line, so the line's two block rows (17 of a lane band's 32 fighter heights) are all building; a street at an angle to the line crosses them over blocks and streets alike, so about half of the lane area lands on a block and half on street or yard. Footprints are not rotated, so a rotated block is not re-fitted into the lane. Two smaller losses: the disc is not a strip (a plan bounded by the place's radius is shorter than a chord that grazes it) and a street that is a straight geodesic leaves a ring of the Half arena (radius 12,223) by 1,500 units at 6,000 out.

The fix is `plans.align` (on): the plan is **turned to the ring it is first laid on**. Its bands are laid by ring coordinates (arc x, depth z), so a street curves with the ring, and its offset across the street is snapped so a band's block rows sit on the lanes (`shift`, at most 1,200 units). The place keeps that turn for the whole match, so a swing later crosses a fixed town at an angle (the oblique count above is then the physical one: about half). **Cost:** the town's street direction and band offset are a function of the match's ring, not only of the planet and the place, so the same place on two matches has the same buildings (plan indices, sizes, kinds, seeds, wear) but not the same compass direction. The wear list is by plan index and place frame, so it is unaffected.

Result, buildings standing, chord layout against plan turned to the ring: 46 and 46, 169 and 173, 105 and 129, 47 and 55, 9 and 13, 117 and 124 (planets and touches 7/1, 7/2, 3/1, 3/2, 11/1, 25/1). Parity or better everywhere; the extra are foreground and background scenery from the neighbouring bands.

**`dir` is the plan's true point, not the laid pose (Simulation's finding, 2026-11-01).** A building's `dir` is its planet point in the plan; its laid `z` is then snapped flush into its lane (`lane.top - d/2`), so about 30 percent of buildings stand 130 to 300 units in depth from `dir`. I left it: Simulation sets `bDir` from where each building is laid, so a swing and a rest agree with the fight; a `dir` that followed the snap would no longer be the same point on two rings, which is the identity `field_plan_check` holds. If the true plan point is wanted later, the snap has to become part of the plan (the lanes' flush rule laid in plan space) rather than of the ring.

## Lakes and rivers as planet records (World, first cut, `sim/world/waterrec.gd`)

On gen 2 a lake is a valley of the ring's own line and a river a crossing of it, so both would blink when the line turns. On gen 3 each is a record at planet points in `S.fieldRecs`, read at any direction:

- **Lake** `{k: "lake", c, r, level, nodes}`: the ring's plan finds the lakes as before (on the field's heights along the line); each is then **flooded in two dimensions** on the field's canonical nodes from the seed cell (connected nodes under the level; it crosses face seams), lowest level first so a higher lake stops at a lower lake's shore. A point has the lake's water where its cell, or a node beside it, is in the basin and its ground is under the level: depth = level - ground. On the line this equals the ring's own water exactly (59 of 59 columns, 0.000 units, planet 7 touch 1), and off the line it is a body: the four lakes there are 19, 33, 28 and 24 of 33 points wet across the line.
- **River** `{k: "river", a, b, flow, w}`: one segment of the planet's drainage (cell centre to receiver, flow at least the river threshold, above the sea), kept within 9,000 units of the ring. The level at a point is the lower of the two banks a few columns either side across the river, less the freeboard; the bed is the level less the depth with the ring plan's profile. Continuous along the river (12.8 units at most between points a twentieth of a segment apart on the strongest, flow 196, planet 7 touch 2: 102 segments near the ring). **Rivers are behind `rivers.json enabled`, which is off; the half is built and checked with the switch set for the process.**
- **Reads** (pure at a unit direction): `WorldField.applyRecords(S, q, h)` now also cuts a river's channel; `WorldField.recordWater(S, q, h)` is the deepest record water at the point (the lowest lake that holds it, or a river). The sea is not a record: it is derived from the ground. The records are found through a grid index (`WorldWaterRec.near`) so a read touches a few.
- **Limits**: a lake is **bounded to twice its width on the line** (at most 6,000 units, at least 800): the line's plan reads a valley on one line, and in two dimensions its level may spill over a crest the line did not see (the flood would leak down a hillside); a leak is cut at the bound. A lake beyond the ring's neighbourhood is not planned (water out of a swing's path). The sea's shore with Rendering's water waits for its tile park.

## The bake cache (World, `sim/world/field_cache.gd`, `field.json cache`; the EP's order of 2026-11-01: a warm visit under 10 s)

The bake (34,656 nodes) is the part of a gen 3 load that a repeat visit does not need to repeat. It is kept in `user://field-cache/` (the page origin's IndexedDB on the web, a folder on disk natively), 208,152 bytes a planet, newest 8 kept.

- **The key is whole.** The file's name is the SHA-256 of the key text and the key text is inside the file and compared: data hash (`WorldPlanet.dataHash(3)`: planet, climate, land, sites, rivers and field data), Godot version and hash, seed, generation, cells, stride. `user://` is one folder for every copy of the project on a PC; a different copy with different data has a different key and finds nothing.
- **A file is used only if** its magic and key are exactly this key, its length and SHA-256 are right, **six witness nodes read fresh now equal the file's bits** (this catches a code change the data hash cannot see), and the hash rebuilt from the loaded bits is the uncached bake's hash. Anything else is a miss and the bake runs as ever; a bad read never fails a load (a flipped byte, a truncated file, a stale value with a right checksum, another seed and another data hash are each checked).
- **Same bits (the check Simulation asked for).** A hit gives the same bake hash as an uncached bake: planet 7 `06334d3ce141b644` both ways, planet 4246 `e43d98c89e9982a5`; every bake node is bit-equal (`field_cache_check`), a canonical read between bake nodes is the same after a hit, and a load on a warm cache starts the same match state as a cold one (`field_load_check`). The hash is folded in as nodes arrive, in bake order, so it needs no call of its own, and `_hashBake` (the tool's whole-bake hash) agrees with it.
- **Slices.** A hit is checked in one call (9 ms native: read, SHA-256, six witnesses) and then copied and hashed in slices of eight times a bake's nodes (34 slices at 250 units), so no frame carries more than the 4 ms rule's worth.
- **Writes.** Natively a temporary name then a rename; on the web the final name directly (the page's storage is synced when a file closes, not on a rename; a torn write fails the checksum and is a miss).
- **What it saves.** The bake only: 2.4 s native on this machine against 12 ms to read it back; 5 to 7 s on the loaded web page by Rendering's timing. A warm gen 3 load then costs a gen 2 load plus the ring (the planet's own make, the climate grid and the places, is what is left: 6.0 to 7.1 s on that page), under the 10 s target.
- **What I did not thin.** The 904 duplicate face-edge reads are 2.6 percent of the bake (45 ms native): not worth a mapping. The ring's own reads (1,144 canonical nodes and 2,877 sub-reads at a Half ring, about 0.2 s native) could join the cache file; they depend on the ring, so the key would too: left for a later cut. Heights-first (half the bake) is unsafe: the sim reads biomes too.

### The made planet and the node pool in the cache (Performance's load split, 2026-11-01)

Performance split a warm load into ring 4.5 s (a 0.85 s freeze), places 1.5 s and climate 0.7 s on the web. The "ring" step in that table is mostly the bake: measured natively it was 277 of its 298 slices (the bake) and 21 the ring's own columns. The bake cache above removes the bake, and with it the 0.85 s freeze (the end-of-bake hash is now folded in as nodes arrive). Two more pieces of the warm load are now cached on the same envelope (`WorldFieldCache.readBlob` and `writeBlob`: key text, length, SHA-256):

- **The made planet** (`sim/world/planet_cache.gd`): the climate grid (moisture and height, 18,432 cells) and the places (kind, point, radius, people). Read in 4 ms against 1.5 s native for the grid and places together; the job is done at its start. Checked by the key (data hash, Godot version, seed, **`CODE_REV`**) and by 24 grid heights recomputed now. A change to the climate carry or the placing code with the data unchanged is invisible to both, so **bump `WorldPlanetCache.CODE_REV` and the vectors when that code changes**: `planet_cache_check` holds the made planet's digest for two seeds in `planet_cache_vectors.json` and fails if the code moved under the same rev.
- **The node pool** (`sim/world/field_pool.gd`): the canonical and sub nodes beyond the bake that a ring read. A node is a point of the planet, so a pool written for one ring serves every ring. Written whole at the end of a load that read something new (capped at 60,000 nodes), read after the bake, four nodes checked fresh. The ring read on this machine: 227 ms (3,707 reads of the planet's function) cold, 25 ms with every node held.

**A fully warm load reads nothing from the planet's function** (`field_load_check`): the planet, the bake and the ring's nodes all came from the cache, 54 load steps of 250 units against 531 cold, the same match state. The remaining warm cost is the ring's lookups (25 ms natively), the places' chords and settlements for the match's start, and the pacing of the slices (Simulation's: run slices to a time, not a count, about -2.5 to -3 s on the web).

**Ring read under gen 3, algorithmically** (the strip is a view now): the lookup is 10 microseconds a column and is not the cost; the cost is the 3,700 reads of the planet's function the ring's cells and creased cells need (61 microseconds each). The only cuts that keep every bit are caching them (done) and not reading the neighbours' corners for the edge correction when no neighbour is creased (the neighbour rows are about a third of the nodes; a coarse test from the bake would need a new rule for "refined", which the one shared rule forbids). Left as it is.

## A building's pad (the EP's order of 2026-11-01: the buried and floating buildings)

Rendering's probe on planet 7: a building's base at 613 and the field under it 3,663. The cause: a plan's building is laid at a lateral offset from the line (its depth row), but the sim's base for it was the **line's** ground at its x, while a tile or a swing reads the ground at the building's own planet point. Measured on planet 7 touch 2: **91 of 173 buildings stand where the line's ground is over 50 units from their own ground, up to 805.** A flattened place disc is not honest (the field spreads 300 to 3,000 units across a city's disc), so the flat is the building's:

- **Pad** `{k: "pad", c, r, blend, h}` (`WorldField.padRecords`, built in `planet_world.gen` after the settlements, for chord-laid and plan-laid buildings alike): `h` is the ground at the building's own point (the field with the platform under the place); the ground is exactly `h` out to the footprint radius (the half-diagonal) and eases to the field over `blend`, which is at most half the gap to the nearest other pad's edge, so a blend never reaches into a neighbour's footprint. Planet-keyed: the sim's ground through the frame, a tile and the building's base read the same height at any bearing.
- **Overlaps** (adjacent buildings' half-diagonal discs overlap): pads compose by their **weighted mean** after the platforms and the river cuts, so the order of the records does not matter and the ground is smooth; a building whose neighbours' pads reach it stands at their mean. 19 of 173 stand alone on planet 7 (the ground at their point is their pad's height and flat across the footprint, 0.000 units off); the other 154 stand between the lowest and highest pad that reaches them. A building's base is therefore **the ground read at its centre through `applyRecords`**, not its pad's `h`.
- Strip: `S.base` is untouched (the line's ground stays the line's; only readers that go through the records see pads), so a standalone gen 3 match with no frame is as before.
- Also fixed on the way: the record index (`WorldWaterRec.near`) followed a growing array only by identity, so pads added after a first read were not seen; it now follows the array's size, and returns records in plan order whichever list holds them.

## The cache hit, sliced finer (the EP's order of 2026-11-01)

A hit was checked and copied in the first slice (key, SHA-256 of 208 KB, six witnesses, 34,656 index entries). It is now staged in `WorldField.bakeStep`: the file is read and its header and key checked at once (a mismatch is still a miss at once), then the checksum runs 32 KB a slice (7 slices), then the witnesses and the set-up (a slice), then the copy and the hash in slices of eight times a bake's nodes, the node index computed in the loop and not up front. A fault found in a later slice (a flipped byte, a stale witness) gives the load up and the bake runs as if there had been no cache, to the same hash. The first slice of a hit is 1 ms natively.

## Cold planet gen, 10.7 s on the web to about 5: what I can name

A cold load is the made planet (climate 0.7 s, places 1.5 s on the web), the bake (4.5 s), the ring (1 s) and the match. The caches take the warm path to the ring alone. For a cold visit:
1. **Ship the demo planets' cache files** (the default planets, say 7, 3 and 25): Tools builds them at export by running the load (the key carries the data hash and Godot version, so a shipped file is valid exactly for its build) and the page fetches the three files for the chosen planet, about 0.5 MB each, not in the first-load pack. A first visit to those planets is then a warm one: about 5 s. Any other seed stays cold.
2. **Choose the places on the climate grid, not the planet's function** (gen 3 only, a different planet from its gen 2 twin: Orb's look): the places' try-sets are the 1.5 s, and nearly all of it is thousands of reads of the surface function to score sites; the grid already holds the height at 192 by 96 cells. About -1.4 s web. It moves where cities stand on every gen 3 planet.
3. **A coarser climate grid** (96 by 48) halves the 0.7 s and changes the climate: the same kind of change.
4. **A coarser bake** (768 or 1,024 for the forecasts) is 2 to 4 times cheaper (-3 to -3.4 s) but the forecast error doubles or worse (World 11.1: 48 RMS at 1,024): Simulation's and Orb's call.
With 1 alone, the default planets are about 5 s and a random seed 10.7 s; 1 with 2 and 3, a random seed is about 8 s. There is no thread on the web build to hide any of it behind.

## Marks in the planet store, stage 7 (the EP's order of 2026-11-01: cracks hanging in the air after a swing)

Every mark was a column of the strip, so a swing left it where the line used to be. Each kind is now also a record at planet points in `S.store`, read at any direction and laid on the strip again after the line moves. The store's record is `[kind, 15 numbers]` (16 a record, cap 16,384; Simulation's digest takes only the count and the running hash). Behind gen 3 and a state with the store's fields; gen 2 never touches it; the strip's own arrays are written as ever, so a standalone gen 3 match is as before.

| Kind | Made by | Record | Read | Laid on the strip |
| :--- | :--- | :--- | :--- | :--- |
| crater (0) | `WorldCrater._dig` | point, radius, depth, rim, energy... | `heightDelta` | (the ground; with a frame the strip's bowl is not dug) |
| **crack (1)** | `_carveSegment` on paved ground | segment a to b, intensity, half width 24 | `crackAt` (full inside the half width, smooth to nothing at twice it) | `layCracks(S, pointOfX)` sets `S.crack` |
| **scorch (2)** | `WorldCrater.scorch` (a beam sample) | point, half width, depth, intensity; a sample the last eight already cover (within a quarter of its half width, no weaker) is not added | `scorchAt` -> [burn, groove]; the groove is the deepest, never summed, and the ground is the lower of the craters' sum and it | `layScorch` sets `S.scorch`; with a frame the strip's groove is not dug |
| **trench (3)** | `_carveSegment` (a slide's groove) | segment, depth, half width one column | `trenchAt`; same groove rule | (the ground; with a frame not dug) |

`layCracks` and `layScorch` take Simulation's `pointOfX` (a strip x to the planet direction on the line now) and set every column, zero where there is nothing: they are the call after a swing rests (4,800 index lookups). The checks (`field_crack_check`, `field_scorch_check`, `field_trench_check`) turn the line 50 degrees and show the crack and the burn under the new line where they were made. **Not yet:** beam scars (`WorldAfter`, behind `after.json`, off by default: kinds per column with timed jobs) and heaps (rubble belongs to fallen buildings and moves with them: a design tied to the building records).

## Lots: one flat per street block, and the laid pose (Art's rule and Simulation's finding, 2026-11-01)

- **The laid pose.** A plan building's `dir` was its plan point, taken before the lane snap, so 25 to 30 percent of buildings (and their pads) stood 130 to 300 units from where they are laid. `dir` is now the planet point of the building's final x and z (`WorldPlan.pointAtX` at the snapped z); the plan's own point is kept as `pdir` (the identity check across rings uses that). Chord-laid buildings were already laid-pose.
- **Lots replace per-building pads** (`WorldField.lotRecords`, `lots` in field.json: sidewalk 15, gap 300, blendMax 180). Buildings of one row of one place within 300 units of each other (an avenue is 375 to 525 wide, the building gaps 15 to 180) share one flat lot at one height, an oriented box along the ring's tangent, edge = footprints + sidewalk; the height is the mean of the ground at the members' laid points. A lone building is a lone lot (`lone`): its ground is flat too, but Rendering draws only a contact shadow for it, as Art says. A lot eases into the ground over half the gap to the nearest other lot, at most 180 units (the ramp down an avenue). Planet 7 touch 2: 173 buildings, 62 lots (25 lone); the buildings of a lot stand at one height (1 lot of 62 deviates, a neighbour's blend reaching an edge building); every building's laid point is inside its lot, 0.000 units out.
- **What it costs to the eye (flagging as asked):** a long block on a slope is cut and filled to one height, so the lot's end is a step: median 50, 90th percentile 167, largest 403 units against the ground just past the ramp (a fighter is 75 tall; measured on planet 7 touch 2). The ramp is the avenue's half-width; a steeper reading needs the street's own terracing, which per-building pads gave in smaller steps.
