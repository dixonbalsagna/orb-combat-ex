# WorldPlanet: planet window 1 (World, 2026-10-16)

Owner: World and Environment. The stored planet as a pure module: the planet function (ice included), the places, the slice picker, the slice read, the run's wear list and the offers. **Nothing reads it yet and no golden moves** (EP, planet window 1). It follows `planet-slice.md` and `planet-ice.md` (the design), and is bound by Simulation's `docs/architecture/planet-slice-core.md` and its proof (`planet-proof/`, 68ac7839). Game Design's run mode (`docs/design/run-mode.md`) asks it for the wear list and three measures; Legal's c01 to c09 (`docs/legal/catastrophe-and-city-screen.md`) bind anything catastrophe-scale (section 8).

## 1. Files

| Path | What |
| :--- | :--- |
| `sim/world/planet.gd` | `WorldPlanet`: the module (static functions; inner classes `Planet` and `Slice`) |
| `data/biomes/planet.json`, `tools/schemas/biomes-planet.schema.json` | 129 numbers: every constant of the function, the ice, the places, the picker, the wear list, the offers; `story` (story planets by id, empty). Written by `docs/world/planet-window1/mk_planet_data.py` |
| `sim/world/tools/planet_check.gd`, `planet_vectors.json` | The checks (section 6) and the golden vectors they compare to |
| `sim/world/tools/planet_measure.gd` | Game Design's measures and the costs (section 7); output in `docs/world/planet-window1/measure.txt` |
| `docs/world/planet-window1/tools-map.diff`, `tools-fixtures.diff` | Tools' two lines (the folder-to-schema rule, four invalid-data cases). **Needed in the same commit as the schema** or `validate.js --self-test` fails its coverage rule; with them it passes 7495 of 7495 |

## 2. The rules it keeps (planet-slice-core.md section 3)

- **float64 scalars only.** A point is three floats; no `Vector3`, no `Vector2` (both float32). Arrays of floats are `Array` and `PackedFloat64Array`; heights are computed in float64 and stored as float32, as `S.base` is.
- **Arithmetic is + - * / sqrt floor, `SimDetMath.sin cos pow`, `SimRng`, integer hashing.** No engine trig, `pow`, `exp`, `lerpf`, `clampf`, `smoothstep`: `planet_check.gd` scans the source and fails on any of them.
- **The picker needs no libm inverse trig.** Our own `atanf`, `atan2f`, `asinf`, `acosf` (`WorldPlanet`): the argument reduced to [0, 0.4143] by 1/x and (x - 1) / (x + 1), then twelve terms of the series; + - * / only, so bit-identical anywhere IEEE arithmetic is. They agree with the engine's to under 1e-9 radians (a column is 1.3e-3). Simulation may fold them into `SimDetMath` with golden vectors if it prefers; the module does not depend on that.
- **Bit-identical to Simulation's reference.** On the ordinary ground (|y| below the caps), `WorldPlanet.surfAt` and `planet-proof/p64lib.gd` agree on **2,176 of 2,176 points, height bits and biome**. The ice adds the same kind of arithmetic (a cellular noise from the same integer hash).
- **Integer setup keys.** A planet is its seed; a touch-down is the integer `touch` (`touchPoint` draws it with `SimRng.keyed`, redrawn until it is on land when `touchLand` is 1); the picker's choice is its index. Nothing carries a float.
- **Memoised, never changing a result.** `make(seed)` keeps the planet (its places and its cell caches); `sliceFor(seed, touch, standing, relaxed)` keeps the slice outside the sim state, keyed by the planet, the touch, the mask and the data hash (Simulation's memo). `planet_check` proves a point reads the same bits with cold or warm caches, in either order.
- **No clock, no engine randomness.**

## 3. The two savings (the EP's asks)

| Saving | What | Measured (this PC was busy, below-normal priority: upper bounds) |
| :--- | :--- | :--- |
| **One call a column** | `surfAt` sets height and biome together (the prototype asked the function twice a column: once for height, once for biome) | an arena through both poles: 1.9 s in the prototype, now 0.78 s; an arena with no ice 0.56 to 0.79 s |
| **A coarse floe field** | The cellular noise's feature points are cached per cell (the field at the floe size, 2,200 units, and the berg size, 1,100): a slice shares almost all its cells from column to column, so each column does 27 distance sums and no hashes. It returns exactly what a fresh read would (tested). Not an interpolation: nothing is approximated | the polar arena costs 5 to 40% more than one without ice; it cost twice as much |
| (also) **The picker reads the surface last** | A candidate's counts (cities, towns) are tested first; the 96 surface samples are read only when the counts could pass | a pick 41 ms down to 13 ms; three offers with 8 cities fallen, median 173 ms |

## 4. The API

| Call | Gives |
| :--- | :--- |
| `make(seed)` | The `Planet`: its places (cities then towns: position, radius, kind) and caches |
| `surf(P, x, y, z)` / `surfAt` | `[height, biome]` at a point (biomes 0 to 6: ocean, plains, forest, desert, mountains, ice sheet, sea ice) |
| `touchPoint(P, touch)`, `pick(P, touch, standing, relaxed)`, `pickThrough(P, T, touch, ...)` | The touch-down; the first candidate circle in the seeded order that meets the minimum: `{ok, circle, tried, eval, T, index}` (`index` is the `pick` key) |
| `readSlice(P, circle, T, standing)` | A `Slice`: 4,800 float32 heights, biomes, and `held`: the places the line passes with their nearest column, signed lateral offset, chord half-length. The touch-down is the middle column (the seam is its antipode) |
| `sliceFor(seed, touch, ...)`, `sliceHash(S)` | The memoised slice; the FNV-1a hash of what the read produced (Simulation's `world` hash reads it) |
| `offers(P, stream, standing)` | Up to three slices from different touch-downs holding different cities, at least `offerMinSep` apart; strict, else relaxed |
| wear: `wearNew`, `wearCrater`, `wearBuilding`, `wearPeople`, `placeStatus`, `standingMask`, `slicePeople`, `wearMarks`, `applyBowls`, `wearFromJson`, `toFrame`, `fromFrame` | Section 5 |
| `dataErrors()`, `dataHash()` | The data's load errors; its hash for the replay's data hash |

**Changes from the prototype (all in the module's data or noted here):** an ice sheet never dips below the shelf it stands on (the dome is clamped at the shelf's height, so no ice sheet is below sea level); the fine relief (300 units) is added to ordinary land only, and a quarter of it to a sheet; the `relaxed` minimum is the run mode's fallback (1 standing city, 4 towns, 3 biomes, 40% land), not a weaker strict one, so `pickEither` (strict, else relaxed) is what the offers use; a candidate through a fallen city is not drawn.

## 5. The wear list

A run's damage lives outside the match, in whole numbers, per place and in the place's own frame (Simulation's section 5). The module's design:

```
wear = { "v": 1,
         "pl":   { "<place id>": { "cr": [[east, north, radius16, depth16, cause], ...],
                                   "bl": [[building index, stage], ...],
                                   "lost": permille, "gone": permille } },
         "open": [[x6, y6, z6, radius16, depth16, cause], ...] }
```

- **A place's frame:** its centre c, east `e = norm(Y x c)`, north `c x e`. An offset of whole units (east, north) is the point `c sqrt(1 - (x^2 + y^2)/R^2) + e x/R + north y/R`. `toFrame` and `fromFrame` round-trip to within one unit (tested). Two slices through one city read the same records at their own columns: nothing asks two circles for the same bits.
- **Craters** (radius and depth in 1/16 units, so a crater is exact in JSON). A negative depth is a raised mound: cooled magma becomes rock that raises the ground (run-core.md, Research's magma). A crater outside every place is an **open-country** record: the point times 1,000,000, rounded. Past `craterCap` (400 a place) the two oldest merge (the midpoint, the larger radius, the depths summed to a cap): the list stays a few KB.
- **Buildings** by their index in the place's plan (the plan is seeded, so the same buildings recur; the plan itself is window 3) and a stage 0 to 4: the highest stage is kept.
- **People** in thousandths of the place's people: `lost` (dead) and `gone` (fled a fallen place for good); they only grow and never pass a thousand together. Casualties by cause and the ledger are Simulation's run state; the wear list holds only what the world needs to draw the place and count its people.
- **Status** (`placeStatus`): fresh, damaged (5% or more of its buildings down or its people lost) or fallen (under 40% of its buildings standing or of its people present), from `damagedPermille` and `fallenPermille`. The plan's building count comes in as an argument; until window 3 an estimate stands in (2.6 per thousand units of the place's chord). `standingMask` is the picker's mask: a fallen place is not drawn, not counted, not offered; it stays in the slice as ruins (`held[i].standing` is false).
- **People of a slice** (`slicePeople`): whole numbers summing to 1,800 at full (today's arena), split by the places' weights (area, so a city holds about seven towns' people, as Bellgate and the villages do), less each place's lost and gone: a slice through a ruin has fewer, and the meters read what is there.
- **Read-back** (`wearMarks`, `applyBowls`): the craters of the held places and the open ones within `bandUnits` of the line, as `{col, lateral, radius16, depth16, cause}` (our own atan2 for the column, our own asin for the offset), and a squared-falloff bowl laid on the float32 heights. Window 2 swaps the bowl for `WorldCrater`'s own shape; the marks are the interface. Tested: a crater laid on the line comes back at its column (within 1) and on the line.
- **Both ways:** `wearCrater` takes a point of the sphere, so a stage's end can turn the match's marks into records (column and lateral to a point: `columnPoint`, then the place's frame); the extraction from `S.craters`, the buildings' stages and the casualties is Simulation's with these calls.
- **For the start:** "no stage starts with a fighter in a crater or under water" (run-core.md): the start's placement reads the laid heights; a helper that finds the nearest safe columns to the touch-down is the touch-down window's (4).

## 6. The checks (`planet_check.gd`: 0 failed)

The data loads clean; the inverse trig; the source scan (no vector types, no engine trig); a planet is the same twice; a point reads the same bits cold or warm; **planet 7 has exactly the 42 places of picture A2**; both ice biomes occur; no ice outside the caps; no land inside the north pack; floes are thicker toward the pole; bergs stand 45 to 215 units; the shelf is flat at 36 units and no sheet dips under it; the picker (93% of 150 touch-downs, 3.4 candidates tried; deterministic); an accepted slice holds the minimum; 4,800 columns; the middle column is the touch-down; the held places are the ones the picker counted and their columns are the nearest; the slice hash is the same from a cold planet; the memoised slice is the one the read gives; one point reached along two circles agrees to 7e-9 units; the wear list (frame round trip, a crater read back at its column, the bowl, a mound, the open-country point, a building's highest stage, people capped, whole numbers through JSON, the cap and the merge, status thresholds, the mask, people sums, no fallen city counted); three offers, the same twice, holding different cities; **the vectors file** (64 points on each of two planets: the height's 64 bits and the biome; 8 picks; the places' hash).

```
godot --headless --path . --script res://sim/world/tools/planet_check.gd              (about 20 s)
godot --headless --path . --script res://sim/world/tools/planet_check.gd -- --write   (regenerates the vectors)
node tools/validate.js data/biomes/planet.json                                        (with tools-map.diff applied)
```

## 7. Game Design's measures (`planet_measure.gd`; two planets, seeds 7 and 11; `measure.txt`)

**Slices that meet the minimum with cities fallen** (144 touch-downs a row; planet 7 holds 11 cities and 31 towns, planet 11 holds 12 and 41): the share of touch-downs that find a slice.

| Fallen | 0 | 2 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Strict minimum (2 cities, 3 towns, 3 biomes) | 98% | 97% | 90% | 78% | 72% | 59% | 36% | 18% | 6% |
| Relaxed (1 city, 4 towns) | 95% | 93% | 88% | 87% | 83% | 76% | 73% | 62% | 42% |
| Either | 100% | 99% | 97% | 94% | 92% | 82% | 76% | 67% | 42% |

Up to 4 fallen the strict minimum is nearly always met; from 6 the relaxed fallback does the work; at 8 fallen a touch-down finds a slice 76% of the time, so three offers take about four touch-downs (still fast, below); at 10 fallen only 42% do and the planet can no longer offer reliably. Game Design's "about 8 fallen before the offers run dry" is right.

**Falls in one stage, by the tier's ceiling of the slice's people** (116 accepted slices; a place falls at 60% of its people lost; no match was played: this is arithmetic on the slice's places, so it is a bound and an estimate, not a measurement of play):

| Ceiling | Most places that could fall (smallest first) | Cities of those | Spent nearest the touch-down first | Cities | More left damaged |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 10% | 3.2 | 0.0 | 1.1 | 0.0 | 0.95 |
| 30% | 4.4 | 0.7 (at most 1) | 2.9 | 1.1 | 0.75 |
| 60% | 6.5 | 2.7 (at most 4) | 6.4 | 2.8 | 0.22 |
| 90% | 6.6 | 2.9 (at most 4) | 6.6 | 2.9 | 0 |

An accepted slice holds about 6.6 places (2.9 cities, 3.7 towns), so the tier-3 ceiling (30%) can fell about one city and the tier-4 ceiling (60%) nearly all of them, as Game Design estimated for the boss. The people of a slice are the weights above, so the ceilings are shares of what the slice holds.

**Three offers with 8 cities fallen** (20 trials): found in 18 of 20, **median 173 ms, 90th percentile 563 ms, worst 572 ms** (under a second on this busy PC); the relaxed minimum served 30 of the offers; with none fallen 57 ms. The two that found fewer than three had 3 or 4 cities standing, so fewer than three distinct sets of held cities existed. (First version, before the counts-first picker: median 821 ms, worst 5.4 s.)

**Costs** (best of 3, busy PC): the planet (places) 0.5 s; a slice 0.56 s without ice, 0.78 s through both poles; a pick 13 ms. The planet and the slice are memoised and are read once at touch-down.

## 8. Legal's c01 to c09, as they reach this module

The photosensitivity items (c01 to c05) and the originality items (c06, c07) bind effects and art, which this module does not draw. It meets the rest in its design: **c08 and c09** (casualties across a run): the wear list holds the people lost as a state in thousandths, never a score, bonus or reward; no place is staged as a school, hospital or place of worship (the module has only cities and towns as places); a fallen place stays in the world as ruins rather than being deleted. The catastrophe marks (a crust beam's shaft, magma and its rock, the darkened sky) reach it only as records in the same list (craters, mounds) or, for a planet-wide mark such as the sky, as a run-state field outside the places: that is Simulation's and Game Design's, and its Legal screening is theirs.

## 9. What is left (the windows after this one)

Window 2 reads the slice in place of `genWorld` for a setup with a planet (heights smoothed, mountains with several summits, `WorldCrater`'s shape for the marks): golden keys. Window 3 lays a city from its plan (rings, wedges, landmarks) into the lanes and rows. Window 4 puts `planet`, `touch` and `pick` in the setup and `world` in the replay header, with the start's safe columns. None of them is begun.
