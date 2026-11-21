# Five planet sizes: places and launches

Owner: Game Design. 2026-11-15, on World's park (`docs/world/pending/planet-sizes/README.md`; `docs/world/planet-sizes.md`). Orb: "five different planet sizes", and on 11-09: "ideally each planet should have a megacity, several large cities, townships, points of interest ... player customization should be allowed".

## 1. Place counts: by the square root of the area, accepted for Alpha

| | Tiny | Small | Medium | Big | Huge |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Columns round | 1,280 | 2,560 | 4,800 | 9,600 | 19,200 |
| Cities / towns (`sizes.json` `places`) | **2 / 4** | **4 / 12** | 12 / 44 | **24 / 88** | **48 / 176** |
| Places per area, against medium | about 0.5 to 2 times (it's tight) | about 0.9 | 1 | 0.5 | 0.25 |

**Ruling: accepted as World set it, as data.**
- The plan's counts by area need windowed places, which aren't built, and a tiny planet can't hold twelve cities of 6,500 units' radius.
- **The cost, said plainly:** big and huge are emptier between places, at half and a quarter of medium's density. That's a real feel (long wild stretches), and it fits Orb's "a large desert world" as one kind of planet, but it shouldn't decide a fight.

**Two conditions, so a fight always has something to break** (pillar 4, power has weight):
1. **At every size, the spawn pair sits within a launch's reach of a town or a city,** so the fight starts where places are. World's spawn picker reads it.
2. **QA reads places reached and the share of buildings fallen, by size** (`bystanders.md`'s spread number). **The lever, if a big or huge fight spends most of a match away from places:** raise that size's **town count first** (towns are small and cheap), toward the by-area counts once windowed places exist.

**Later, not now:** Orb's planet dials (more cities on a small planet, a desert world) belong to A4's dials. The square-root counts are the default each dial starts from.

## 2. Per-size tuning of launches

**A size is a distance, and launches stay absolute:** energy decides a send's speed and how far it goes, at every size. That's the physics Orb asked for. A strong send on a small planet goes a long way round it, which is the rule of cool, and it's the round-the-world hit.

**One exception, the authored curves** (the meteor and the high arc, which aren't physics; `power-scale.md`):

| | Tiny and small | Medium, big, huge |
| :--- | :--- | :--- |
| The curve's peak height | **At most 1.0 × the planet's radius** | Unchanged |
| Its sideways distance | **At most a quarter of the lap** | Unchanged |

- **Why:** today's first meteor peaks near 15,700 units up and travels 25,400 sideways. On tiny (radius about 6,500, lap 41,000), that's two and a half radii up and more than half the planet round. The fighter would leave the picture of the planet altogether and land nearly where he started. Capped, it still reads as a meteor and lands on the face the camera can follow.
- **Data:** `power.json` `arcBySize: { "peakOfRadius": 1.0, "sideOfLap": 0.25, "sizes": ["tiny", "small"] }`. Encounter applies it in `DirArc`.

**The swing's read budget** (Camera's two-fights rest, `apartReach`) **stays absolute.** It's a distance on screen, not a share of the planet.

**Travel:** at flat-out 3,500, a lap takes about 12 s on tiny and 175 s on huge. Flat-out flight costs stamina only within 60 bh of a rival (`energy-stamina-body.md` §12, row 13), so crossing a huge planet never arrives winded.

## 3. For the EP

- **Art, through you: tiny's relief against its radius.** A 4,875-unit tower on a 6,519 radius reads as a spike off the planet. **Game Design's need:** a structure's height on tiny stays under the fight's play height and inside what the camera can frame with both fighters. I'd suggest a height cap as a share of the radius (about 0.3) for tiny and small, but the look is Art's.
- **World:** the spawn condition in §1.
- **Encounter:** `arcBySize`.
- **QA:** places reached and buildings fallen, by size.

**Confirmed for GW1c (2026-11-15):** "unchanged on medium, big and huge" means **today's absolute launch numbers**, the values medium flies now, on all three. Encounter has made `DirArc` absolute on every whole planet. Before that, big and huge would have flown the meteor 2 and 4 times higher, which is not what was ruled. Only tiny and small take `arcBySize`'s caps.

## 4. Lakes that end in the air (2026-11-20, World's `pending/lake-shore/`)

**The finding:** the lake generator floods a valley's level only out to twice the lake's width, so about half of every lake's shore is open, and the water ends in the air over a hillside (by up to 2,898 units). It's in Orb's 9 November build too. With true hydrology only 148 of 13,327 lake nodes are real.

**My recommendation: option 2, carve the basins, in the terrain window (GW2, with the terrain rows).** Each lake stays where the plan put it, at its level, and the ground round its valley is dug into a bowl that holds it.
- **Why not 1** (real basins only): it's honest, but it deletes almost every lake. Lakes are part of what makes a planet read as a place, and Orb asked for planets that are "recognizable but novel" with water as one of the dials.
- **Why not wait for 3** (a real lake planner): it's the right long-term answer, but it's after Alpha, and water standing in the air over a hillside is a visible fault for every outside tester until then. Option 2 doesn't block 3: the planner can replace the carve later.
- **The cost:** carving changes the planet's ground, so the hash, the tiles and Rendering's water. One hash window, shared with GW2's terrain rows, which re-record the golden anyway.

**This is mine and World's to decide, not a question for Orb.** It fixes a visible fault in the direction Orb already set ("math based, procedural terrain"). Nothing in it changes what Orb asked for. **Orb sees it through the look gate:** a side-by-side of planet 7's lakes, carved against the 9 November build, before the EP lands it (ADR 0010). If the carve changes a lake Orb knows in a way that reads worse, Orb's eye decides there.

**Until GW2, the slab lakes stay,** as in Orb's build, with the tile fix drawing them where the fighters stand.

### 4b. Re-ruled on World's price (2026-11-20)

**World's price:** keeping each lake at the plan's level means raising walls on the downhill shore, not digging. On planet 7 that's 642 open shore links needing walls with a median of 426 units, p90 1,704 and a maximum of 2,898: about 90 million square units of new ground. **Walls are out.** They'd be dams and ridges perched on hillsides, which is a worse fault than the slabs.

**The pick: dig down at the spill level, with a depth cap,** in GW2's terrain window:
- **each lake's level is its spill level,** the lowest pass out (`lakeSpill`'s rule), so the water is honest;
- **inside the lake's planned footprint, ground no more than 300 units (4 bh) above that level is dug into a bowl below it,** sloping no steeper than 1 in 3 from the new shore. Ground higher than the cap stays, as shore or island;
- **a lake that ends up under a quarter of its planned area isn't dug at all** and keeps only its real basin, or is dry ground;
- so lakes on gentle land keep a fair size, lakes on steep slopes shrink, nothing rises, and no pit is deeper than 4 bh.

- **Why not real basins only:** it's honest and costs only a data flip, but it leaves almost no lakes (planet 7: 79 of 6,641 nodes). It's **the fallback:** if the look gate's side-by-side of planet 7 reads worse with the capped dig, `lakeSpill` on and nothing dug.
- **Why not wait for the planner:** it still comes after Alpha (option 3), and the capped dig is the kind of tool it would use. Nothing here blocks it.
- **Still mine and World's, not a question for Orb.** Orb sees it at the look gate.
- **The tile lines that draw lakes** follow this pick in GW2, and `lakeMax` alone goes in GW1b (no towns on lake beds), as you said.
- **Data:** `field.json` `plans.lakeSpill` true, `plans.lakeDig: { "maxDepth": 300, "slope": 0.33, "minAreaShare": 0.25 }`. World's check reads 0 open shore links and no dug point deeper than 300.
