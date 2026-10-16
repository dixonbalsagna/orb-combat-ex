# A stored planet and a slice of it for every fight (World, 2026-10-16)

Owner: World and Environment. Early prototype and diagrams for Orb's homework 5 ("fights touch down at a random spot on a procedurally built planet; the arena is a slice along the whole diameter; the same cities and landmarks recur, different ones pop up; at least two cities, several towns and a few biomes"). **Paper and scratch only: nothing in the sim changed.** Diagrams (SVG, drawn from the prototype's own output, seed 7): [A](planet-slice/a-planet-stored.svg) the planet stored, [B](planet-slice/b-slice-pick.svg) how a fight picks its slice, [C](planet-slice/c-touchdown.svg) the touch-down, [D](planet-slice/d-arena-holds.svg) what one arena holds, [E](planet-slice/e-shared-city.svg) two fights, one city. Prototype scripts and data: `docs/world/scratch-build/planet-slice/`.

**A correction to the brief:** today's arena is not 9,600 units round (that was the prototype). It is **153,600 units, 4,800 columns of 32, about 2,050 fighter heights** (`constants.gd`: `PS` 16). The slice below keeps that length.

## The idea in five lines

1. **The planet is a seed and a function.** Height and biome at any point of the unit sphere come from one pure function of the point (our integer hash noise, our own sin and cos, sqrt: float64, no engine trig). What is *stored* is the seed (8 bytes) and a short list of places: 12 cities, about 31 towns and their landmarks, each a position, radius, kind and seed (about 2 KB). An optional coarse map (6 x 128 x 128 cells of 300 units, 384 KB) is a cache for a map screen, rebuildable from the seed. The ground at the sim's resolution would be 7.3 million cells (14.6 MB): never stored, read only where the slice goes. (A)
2. **A fight is a touch-down point T and a great circle through it.** Candidates: the circle through T and each city, plus four of random bearing; a seeded shuffle; the first that holds at least 2 cities, 3 towns, 3 biomes of 8% each and 50% land wins. (B) One seed in, one slice out, on every machine.
3. **The arena is that circle read as columns:** `p(i) = cos(32 i / R) u + sin(32 i / R) v`, with `u = T` and `v = n x T`, `R` = 24,446 units (153,600 / 2 pi). Only sin, cos and sqrt: no inverse trig in the sim. Column i takes its height and biome from the function and its buildings from the places the line passes. **The sim gets today's shape** (a wrapped heightfield, buildings in lanes, people, biomes); only the generator in front of it changes. Rendering can read the sphere for the backdrop (places off the line are the far skyline: `backdrop.md`).
4. **A city is a plan, not a line.** Centre, radius (6,500 units), rings (downtown, mid-rise, suburb, outskirts), a few wedges (harbour, industrial) and landmarks, all from its seed. The line passes at offset d; at distance s along it the district is read at `rho = sqrt(s^2 + d^2)`. A line through the middle shows towers; one near the edge shows houses, with the towers on the far skyline. The same seed gives the same buildings in every fight. (E) The district data we have (`settlements.json`) is the vocabulary.
5. **The touch-down:** pure random on land; or random but within 6,000 units of a place (a knob); or named by a story level. (C)

## What the prototype measured (300 random touch-downs per planet; this PC was busy, so times are upper bounds)

| | 8 cities, 19 towns | 10 cities, 27 towns | **12 cities, 31 towns** |
| :--- | ---: | ---: | ---: |
| Touch-downs that found a slice meeting the minimum | 62% | 87% | **92%** |
| Candidates tried a touch-down | 7.5 | 5.5 | **4.4** |
| One accepted arena holds (cities, towns, biomes) | 2.4, 3.3, 3.7 | 2.7, 3.5, 3.9 | **2.9, 3.5, 4.0** |
| Land / length settled | 73% / 35% | 71% / 34% | 71% / 34% |

- **Cost of a fight's slice:** 4,800 columns of height, detail and biome: about **0.9 s in GDScript on a busy PC** (best of 5; it should be well under that on a quiet one, and the web build and an old laptop are not measured). Picking the slice: 70 to 110 ms. Placing the planet's places: 0.1 to 0.4 s. Done once, at touch-down. The coarse cache cost 10.8 s to build and is not worth building. If the strip read is too slow, the coarse octaves can be read every 8th column and interpolated (about 8 times fewer evaluations; not built).
- **Same point, two circles:** the planet function agreed to 0.003 units over 200 crossings (the difference is float rounding of the point, far below a pixel).
- **Buildings:** today's 118 buildings sit on 46,000 settled units (2.6 per 1,000); a slice that is 34% settled has about 52,000, so about 134 buildings: the same order. People are normalised to today's `pop0` (1,800 per arena) so the collateral budget, the menace and the anguish meters stay as they are.
- **The honest gap:** 8% of touch-downs have no circle that meets the minimum. The fix is cheap and seeded: move T to the nearest place, or accept one city and five towns.

## What this changes and what it costs (windows, each with its own test)

| Window | What | Golden |
| :--- | :--- | :--- |
| 1 | The planet function, the places, the slice picker (data in `data/biomes/planet.json`, a pure module `WorldPlanet`, tests: determinism, crossings, the minimum, no sim change) | none |
| 2 | The slice read in place of `genWorld`'s hand-made order of biomes: heights, biomes, mountains with several summits (`backdrop.md`), the settlements by their list | yes: new matches |
| 3 | A city from its plan: rings and wedges into the lanes and rows the lane table already has, the landmarks (`settlements.json` is the vocabulary) | yes |
| 4 | The touch-down in the setup (`setup.touch`, `setup.planetSeed`; both in the replay header), the demo start as a story-mode touch-down | header only |

QA keeps one **fixed planet** for baselines and gets a random-planet arm for coverage (a measurement is per planet seed). The hand-made Bellgate would become a story-mode planet (a fixed seed with a hand-placed list), so the demo is not lost.

## Questions for Orb (in `homework/22-planet-slice.md`)

1. Arena length: today's 153,600 (recommended), or longer (the planet and its places grow four times for twice the length)?
2. Touch-down: pure random, or random but always within sight of a town, city or landmark?
3. Should damage carry over? A city levelled in one fight stays levelled in the next on the same planet (a short wear list per place, a few KB), or every fight starts whole?
