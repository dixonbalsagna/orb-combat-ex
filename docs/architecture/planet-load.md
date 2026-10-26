# The planet's load step

Owner: Simulation and Engine. 2026-10-26, on the EP's brief after Performance's gen 2 bench (`docs/perf/gen2-bench-2026-10-26.md`). A cold gen 2 planet takes 1.7 s on this PC, 9.5 s on an old laptop and 16 s on a phone. A match start with a cold planet takes 1.8, 10.5 and 17.8 s; with the planet made, 6, 35 and 58 ms. So a host loads the planet in steps before the match, and no match's start makes a gen 2 planet cold. Parked at `pending/planet-load/`.

## 1. `SimPlanetLoad`

- **`begin(seed, gen)`** starts a planet's load: World's `PlanetJob`, plus the flow field when rivers are on. **`beginFor(setup)`** loads a match's setup: its planet by its generation, then its ring.
- **`Job.step(units)`** spends one frame's slice. The host passes `SimRun.planetUnitsPerRead` (the data's 250 units, about 5 ms on this PC: one of World's units is about 20 microseconds). It returns true when the planet is ready for a match.
- **`Job.progress()`** (0 to 1, by World's units, about even in time) and **`Job.phase`** are for the loading screen. A budget of the whole load or more goes through every step in one call, so `finishNow()` and the run's `GroundJob.finishNow()` still finish in one.
- **The steps:**
  1. `plates`: gen 2's plates, and Research's B plates when on. The first ground read makes them in one piece, so they get a step of their own.
  2. `climate`: World's climate grid, a slice of cells a step, then the wind's carry.
  3. `rivers`: the flow field when rivers are on. With World's grant line it is a slice of its own: a frame's slice that ends the grid leaves it to the next. A whole budget goes on in the same call.
  4. `places`: the cities and towns, a try-set a step.
  5. `ring` (`beginFor` only): the match's ring, read as `newMatch` reads it (its arena's columns, its generation) and memoised where the match finds it. An arena that names its ring (a run's, a campaign's: `WorldRingPick.arenaOf`) is read with World's `RingJob`, about 62 columns a slice. A touch-down's ring (`{"cols": n}` and a `touch`) has no stepped read, so it is one piece. A ring already read (World's `ringRead`) is skipped.
- **The planet and the match are the same however they are stepped.** `make(seed)` is World's job run to the end. Parity compares the planets, and a match started after the load with one started cold, to the bit, and the same for a ring read in slices.
- **`ready(seed, gen)`:** the planet is made (World's memo) and, with rivers on, its flow field too. **`mayStart(setup)`:** no planet, a gen 1 planet, or a gen 2 planet that is ready.

## 2. No cold gen 2 planet in a match's start

- **`SimPlanetLoad.strict`**, which the game's host sets: `SimCore.newMatch` refuses a setup whose gen 2 planet isn't ready. It leaves the state as it was, counts `refused` and logs an error. The host loads first.
- Tools leave `strict` off and make their planets as before, so World's and Performance's tools that start gen 2 matches directly keep working.
- A gen 1 planet is never refused. It takes 0.36 s on the web at x1 and has been made inside a match's start all along.
- **World's memo holds seven planets**, and it clears when an eighth is made. A host loads right before the match it is for.

## 3. The paths

- **A versus match (the host):** before `SimCore.newMatch` with a planet setup, `beginFor(setup)`, a step a frame with the loading screen on `progress()` and `phase` until it is done, then the match. A planet made and a ring read already are done at once. This is Rendering's `SimHost.new_match` and UI's loading screen (the hook is below).
- **The run:** `SimRun.beginGround`'s `GroundJob` loads its planet with `SimPlanetLoad` (the same steps), and `GroundJob.progress()` reads the load's progress (1 once the ground has started).
- **The campaign:** the arc's planet is loaded before the first column (`SimPlanetLoad.begin(state.planet.seed)`). World's column job makes the planet if it is cold, in one piece.

## 4. What a load costs, and the pieces that are one chunk each

Native, on this PC (seed 13, gen 2, slices of 250 units, two runs each, the machine 35 to 60% busy with other sessions). Performance's web build is about 1 to 1.5 times native at x1, and its phone tier about 6 times that.

| | Native | Phone tier (about x6 to x9) | Whose |
| :--- | :--- | :--- | :--- |
| The whole load | 1.28 s; 1.40 to 1.49 s with rivers; 2.70 s with the B plates and rivers | about 8 to 24 s | World's generation |
| Its frames, at the data's slice | 137 to 139 | the same | |
| A match start after the load | 9 to 17 ms (38 ms the first time in a process) | about 55 to 150 ms | |
| A match start, cold | 1.3 to 2.7 s | | |
| A climate slice (250 cells) | 7.5 to 8.4 ms (18 with the B plates) | 45 to 160 ms | the data's slice: a phone can take fewer units |
| The plates | under 1.5 ms | | |
| The B plates | 49 to 55 ms | 0.3 to 0.5 s | World |
| The wind's carry (ends the grid) | 17 to 26 ms | 0.1 to 0.24 s | World |
| **The flow field** (rivers on) | **136 to 143 ms** | 0.8 to 1.3 s | World: in steps |
| **A try-set** (the worst) | **76 to 80 ms** (126 to 128 with the B plates) | 0.45 to 1.2 s | World: a try at a time |
| **The places' last step** | **73 to 117 ms** | 0.45 to 1.1 s | World |
| **A touch-down's ring** (one piece) | **114 to 205 ms** | 0.7 to 1.8 s | World: a stepped `sliceFor`; or hosts give arenas that name their ring (stepped, about 5 ms a slice) |

- **Before the load, the first match start on a made planet was 135 to 165 ms here, not Performance's 6 ms.** The 6 ms is a start whose ring's slice was read already. The first start reads it, so the load reads it too (step 5).
- **On a phone, the five pieces in bold are the frames over a loading screen's budget** (Performance's: 150 ms in one call at x1, 400 ms at most). Stepping them is inside World's code, so it is under the hooks.
- **No stepping brings a cold gen 2 planet under Performance's "done within 5 s on the phone tier":** the whole make is 8 to 24 s there. That is the generation's own cost.

## 5. The hooks

- **World** (`grant_world.py`, three small things, in this park):
  - `WorldPlanet.isMade(seed)`;
  - `WorldPlanet.ringRead(seed, ring)`;
  - `PlanetJob`'s flow field becomes a slice of its own when a frame's slice ends the grid.
- **World, later (not in this park):** step the flow field, a try-set (a try at a time) and the places' last step, and give a touch-down's ring a stepped read.
- **Rendering** (`render/core/sim_host.gd`):
  - set `SimPlanetLoad.strict = true` when the game starts (not in tools);
  - in `new_match`, for a setup with a planet: `beginFor(su)`. Until `done`, step it once a frame with `SimRun.planetUnitsPerRead` units and show the loading screen, then call `SimCore.newMatch`.
- **UI:** a loading screen that reads `progress()` (0 to 1) and `phase` (plates, climate, rivers, places, ring).
- **The campaign's and the run's hosts:**
  - the run's `GroundJob` already loads its planet (`GroundJob.progress()`);
  - the campaign loads the arc's planet before its first column, with `SimPlanetLoad.begin(state.planet.seed)`.
