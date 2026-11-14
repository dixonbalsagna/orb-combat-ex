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
