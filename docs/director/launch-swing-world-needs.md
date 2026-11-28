# What the launch swing needs from World (Encounter, 2026-11-28)

Brief 3 of the combat-overhaul directive (`docs/ep/proposals/combat-overhaul-directive.md` section 5): a launch swings the turntable toward the biggest landmark the player can see behind the fight, a city first. The swing (`sim/director/swing.gd`) already reads the planet's places and the standing buildings for itself. From World it needs **one read-only function**, and nothing more.

## The function
`WorldLandmarks.inView(S: SimState, eye: Array, eyeAlt: float) -> Array` (World names the class and file).

- **What it gets:**
  - `eye`: a unit vector on the planet (the fight's point, from `DirSwing._frame`).
  - `eyeAlt`: the viewer's height above sea level, in units.
- **What it gives:** one Dictionary per landmark whose top can be seen from the eye, in any order, with these fields only:

| Field | What |
| :--- | :--- |
| `kind` | `"city"`, `"town"` or `"peak"` |
| `id` | for a city or town, the planet's place index (`WorldPlanet` P index, the same as `Building.place`). For a peak, `P.n` plus its index in World's peak list, the same for the whole match |
| `q` | its centre as a unit vector `[x, y, z]`: the place's centre, or the summit |
| `rad` | its radius in units: `P.rad` for a place; for a peak, whatever World takes as its footprint |
| `count` | standing buildings in the place: `alive`, with at least one standing floor. 0 for a peak |
| `top` | the height above sea level of its highest point: the tallest standing building's roof (its ground plus its standing height) for a place; the summit for a peak |
| `seenTo` | the farthest distance along the surface from which `top` can still be seen: the curvature horizon of the eye at `eyeAlt` plus that of `top`, capped by the farthest the renderer draws scenery (Rendering's number; World reads it or asks the EP) |

- Only landmarks within `seenTo` of the eye are returned.
- A place with no standing building is still returned if its terrain shows. A place whose ground the match laid nothing near is left out, as the swing does today (`DirSwing._builtPlaces`).

## Peaks
- **Static per world:** worked out once per planet (seed and generation), as World's other planet tables are.
- **Which summits:** World's call, with its numbers in World's data. A summit should be a local high point at or above 1,500 (the swing's `terrain.highAt`), with no taller summit within a few thousand units, at most a few dozen per planet, tallest first.

## Rules
- **A pure read.** No writes to `S`, and no lazy sizing of hashed fields or arrays.
- **Deterministic.** float64, World's or the core's own trig (`SimDetMath`, `WorldPlanet.acosf`), no RNG, no memo that changes an answer.
- **Cost:** it is called at most once per launch (later perhaps once per chase or form pause), so a walk of the places and buildings is fine. Any memo is World's choice, keyed by the world, as `_builtPlaces` is.

## Not needed (please don't build)
- **Bearing, screen and view wedge.** The swing works out each landmark's bearing from the fight's line itself, and keeps those behind the fight inside Camera's lens.
- **Ranking.** Cities first, then by count and top, is the swing's.
- **Terrain hiding a landmark** (a ridge between the fight and the city). Not for the trial.
- **People, wear, streets, districts, biomes.**

## How the swing uses it
At a launch, with its switch on:
1. It asks from the launcher's point, at the pair's height.
2. It keeps what lies behind the fight inside the view.
3. It turns the line toward the first city it can fit, then a town, then a peak, never by less than 20 degrees.
