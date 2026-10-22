# The ring picker (window 4) and farColumn (window 2's World part): in scratch on main's HEAD, parked, not applied

Built on b3a3aa74 with windows 0 and 1 applied (`../arena-plane/`). Design: `docs/world/shifting-arena-design.md` sections 2 and 5. **Nothing is applied; nothing here reads a golden.**

| File | What |
| :--- | :--- |
| `ringpick-window4.diff` (10 files) | `sim/world/ringpick.gd` (`WorldRingPick`), `data/biomes/rings.json` and `tools/schemas/biomes-rings.schema.json`; `WorldPlanet.sliceRing` and the arena that names its ring (`planet_world.gd`); `ringpick_check.gd`; **Tools' lines**: a rule in `map.json` and three invalid cases in `cases.json` (the same commit as the schema). `mk_ringpick.py` makes it |
| `farcolumn-window2.diff` (3 files) | `WorldPlanet.farColumn` and `far_check.gd`. `mk_far.py` makes it |
| `*.gd.txt` | The modules and checks as they stand |

## What the picker does

A **ring** is an axis `c` (the circle's centre, a unit vector), a length in columns and a touch-down `t` on it (the arena's middle column). `WorldRingPick.pick(P, claim, size, stream, opts)` returns the ring for an opponent: **candidates** in a seeded order (rings round or through the planet's places, the claim's home first, and round random points: 48 at Close and Half, 32 at Whole), each **read coarsely** (every 8th column: the biome shares, the coast, the places it holds by the slice's own reach rule), those under the size's **minimum** dropped (a cruder minimum, then none, if nothing is left), the rest **scored by the claim** (suits weighted, avoids taken off, must-cross checked, a bonus for passing the home), and the best taken. A ring **round** a place counts the place as held (the centre behind the fight). A pick in steps is `beginPick(...)` and `PickJob.step(n)`: the same answer however it is stepped (a candidate's read is about 30 ms on a busy PC, so a pick is about 1.5 s of work: the time-sliced loader's, a few candidates a frame).

- **The claims are Narrative's** (`docs/narrative/pending/opponent_grounds.json`), passed in as a Dictionary: the data's path is theirs to land (`data/narrative/` when the EP applies it); `rings.json` holds only World's numbers (the sizes in columns, the minimum by size, the weights). Features the planet function cannot see are proxies, written in `featureValue`: a pier or quay is a coast with a settled place, a terrace a city with mountains on the ring, an avenue's end any city, hulks a coast with desert, a dense city with no exit a city on a ring with almost no water. A claim feature the table does not know scores 0 (a new claim word needs a line there).
- **`firstRing`** (Close round the player's home) and **`bossRing`** (the Whole circle through the boss's home and the most populous other place standing: Game Design 2c). A home is a place id: the homes themselves (four fixed places per seed) wait for Orb's names (homework 39), so the checks stand in the planet's most populous city.
- **`arenaOf(spec)` and `ringOfArena(arena)`** carry a ring through a setup as exact bit patterns (a JSON number does not round-trip a float64); a match with `setup.arena = {cols, c, t}` builds on that ring.

## Proof (scratch export; below-normal priority)

- `ringpick_check.gd`: **0 failed.**
  - **Geometry:** a ring round a point and one through a point have their touch-down as the first point, are unit and on the ring; an arena round-trips through JSON to the bit; the read of the picker's own great circle holds the same cities and towns as `evalCircle`, and its shares sum to 1.
  - **Candidates:** 48 a Half, the pinned place first, the same from the same stream.
  - **Picks:** across 8 planets, 4 claims and 3 sizes (96 picks) **all 96 found a ring that meets the size's minimum**; the four claims choose 3 different rings on planet 7 at Half; and the claims show in the rings (mean over 8 planets, Half: plains Empress 0.39 against Rival 0.31; mountains Rival 0.20 against Empress 0.01; open water Protagonist 0.36 against Empress 0.30). **On the first 6 planets 66 of 72 also met the claim's must-cross; the misses are the Rival at Close (3 of 6) and Whole (4 of 6): a Close ring that holds mountains and a settled place is rare.** Where no ring fits, the best-scoring candidate is taken, flagged (`must` false).
  - **Determinism:** the same claim, size and stream pick the same ring to the bit; a pick stepped 3 candidates at a time (16 steps) is the pick in one call.
  - **The first and boss rings:** the first holds its home as the centre; the boss's passes within half a unit of his home and the other place.
  - **A match on the Rival's Close ring** builds from it, plays 1,200 ticks and plays the same twice.
- `far_check.gd`: **0 failed.** At z = 0 `farColumn` is the slice's own column (height to float32, biome) on the Planet and a Close ring; the same read twice is the same; a column's far ground out to 12,000 units each side changes kind with distance.
- `planet_check` 0 failed; `node tools/validate.js` 234 files, 0 errors, 0 warnings; `--self-test` 8575 of 8575 (with Tools' lines); `run-all.js --only=godot,golden` on the window 4 tree: both stages passed (golden 0.6 s, godot 294.5 s: the golden is unchanged). The four diffs (windows 0, 1, 4, then farColumn) apply in that order on the newest main and equal the scratch tree.

## Lines in files that are not World's

Tools' (`tools/schemas/map.json`, `tools/fixtures/cases.json`: a rule and `rings-schema-version`, `rings-size-too-small`, `rings-minimum-land-over-one`), in the same commit as the schema. Nothing in Simulation's files (a setup's `arena` is already carried in a replay's header).

## Open

- **The time-sliced pick in the run:** `PickJob` is stepped by the host a few candidates a frame during the previous stage's beats; the run's owner calls it (run-core).
- **Homes and wear:** the home place ids come with Orb's names; a damaged-place list from the wear list feeds `damaged` (the Cyborg's claim).
- **Claims' words:** Narrative's `place:city_end_of_avenue`, `coast:breakwater` and the like are proxies until a city's plan (window 3 of the planet series) can say; the picker does not fail on them.
