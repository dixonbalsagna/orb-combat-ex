# Planet window 2: a draft (World, 2026-10-17)

Owner: World and Environment. The EP: "a draft of window 2 (the slice read in place of genWorld for a setup with a planet, golden keys only) in scratch is fine, if it's mechanical." **A draft in scratch, parked, not applied.** `scratch-build/planet-window2/` has the patch, its check and the keys. It builds on the collateral window (it sets `Building.place` and `Building.plan`) and on `WorldPlanet` (window 1).

## What the draft does

A setup with a `planet` key (and a `touch`) builds its world from the slice instead of `genWorld`; **a setup without one is today's world, unchanged** (the default match, the golden and every replay).

| Piece | How (`sim/world/planet_world.gd`, new) |
| :--- | :--- |
| The ground | `S.base` is the slice's 4,800 float32 heights; `S.deform`, the rubble, scorch, crack, craters and slides start as `genWorld` starts them; water and the collateral are initialised as it does |
| The biome of each column | `WorldBiomes.planetCols` (a per-match table; `biomeAt` reads it when it is set, `newMatch` clears it otherwise) holds the slice's biomes; a town's or a city's chord reads as `village` or `city` so the beam variants and the lure that key on them still work |
| The settlements | For each standing place the line passes, `WorldSettle.generate` (today's D1 city generator) is run on a copy of Bellgate's archetype for a city and the outskirts village's for a town, the span set from the place's chord on the line and the people from the place's weight (so a slice's people are 1,800 as today). The ground under each is lifted to the settlement floor with `genWorld`'s own platform blend. Each building gets its place id and plan index (the collateral window's fields) |
| The start | The fighters stand astride the touch-down (the middle column) |
| Lanes, the index | `WorldLanes.build` and `WorldStructures.buildIndex` as in `genWorld` |

## Evidence (scratch, `planet_world_check.gd`: 0 failed)

- A match on planet 7, touch 3: 133 buildings, 1,800 people, 6 places held; planet 11, touch 2: 65 buildings, 1,798 people.
- Every building has a place and plan index (unique) and stands on dry ground and inside the world; `biomeAt` agrees with the slice's biomes.
- **An AI match plays 3,600 ticks (50 s of match) with no error** (casualties 10, 9 craters) and **plays to the same hash twice**. The default world is still 118 buildings with the city at x 50,000.
- **Golden keys it would add** (`golden.gd` and `golden.json` are Simulation's, so I list the values rather than editing them): slice hashes `planetSlice` 7/3 `d0f86ade`, 7/9 `2fa739f2`, 11/2 `81af5442`; tick-0 gameplay hashes 7/3 `772a8bd9a2de54d2`, 11/2 `9ef0bf142bf3b95e`; one AI match 7/3 seed 1, 3,600 ticks: `b5836c764fe1266b`. **The existing golden does not move:** `run-all.js --only=godot` on the draft tree passed (`parity.gd` 316 s: the 9 golden matches' every per-tick digest and full-state checkpoint identical).

## Why it is not entirely mechanical: what the draft decides for you

1. **The ice biomes.** The director, the cover rules, the contact surfaces and the renderer's palette know seven names (ocean, plains, forest, desert, mountains, village, city). The draft **maps ice sheet to mountains and sea ice to plains** (`BIOME_NAME`), so an ice arena plays but looks and hides as rock and meadow. Real ice biomes need a decision in each place that keys on a name (cover and hiding in snow, a beam variant, a slide on ice, the palette, thin ice and open water): Game Design's, Rendering's and Art's.
2. **`WorldBiomes.biomeAt(x)` takes no state.** The draft keeps a static table set at `newMatch`: the same shape of global the `arena` setting would be, and safe only because every match sets it. The alternative is a state field and an `S` argument at 15 call sites in the director and the renderer.
3. **A city is Bellgate's archetype** on the place's chord, not a city from its plan (window 3): rings, wedges and landmarks are not there; a town is the outskirts village. A city that crosses the seam is cut at it (rare: the seam is the antipode).
4. **Not done:** `world` in the replay header and the data hash (Simulation's, window 4); the placement of fighters clear of a crater or water (run-core's rule, window 4); depth rows over a slice (`depthOn`); the planet-wide state of a run.

## Lines in files that are not World's

`sim/core/sim.gd` (`newMatch`: the planet branch, the clearing of `planetCols` and the start): two small hunks, Simulation's. Everything else is World's (`planet_world.gd`, `biomes.gd`).

## What it needs to land

The collateral window first (the fields), planet window 1 (committed), a decision on the ice biomes' stand-ins, Simulation's golden regeneration with the keys above, Orb's answers on homework 31 (small arenas change `NC` and `W`, which this draft reads as constants).
