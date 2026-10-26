# The gen 2 ring read and the planet's load in steps (World, window 20, 2026-10-26)

Parked in `docs/world/pending/gen2-read-speed/`. Everything here gives the same planet, the same ring and the same match as before, to the last bit, and runs behind no switch: the golden does not move.

## 1. The ring read (Performance: gen 2 130 us a column at x1, gen 1 about 50; target under 60)

**What the cost is.** A land column of a gen 2 ring runs about 28 octaves of the lattice noise (continents and relief, the plate edges' ridges and shoreline, the polar edge, temperature, moisture, the jitter, the volcanic field, the surface detail): about 25 of its 51 native microseconds. The rest is the plate pairs (7), the trig (3), and the climate's and biome's arithmetic. Native, this PC: gen 1 16.5 us a column, gen 2 46.6 (a mixed bench ring) and 51 to 57 (the calm turn's own land rings).

**What was cut** (`mk_p20a.py`, `mk_p20b.py`, `mk_p20c.py`): the noise written out in the octave loop (no call an octave); the climate data's numbers kept as typed statics instead of dictionary reads a column (`WorldClimate._cache`); `readColumns` reading the planet's numbers once a call and taking the ordinary-ground path of `surfAt` inline; the plate pairs of `WorldLand._terms` over the plates that can pair (and a ball inside which it is known to add nothing). All the same arithmetic in the same order.

**What it bought.** The bench ring (`ring_bench`): 46.6 to 35.2-36.9 us a column (-21 to -24%; gen 1 16.5 to 14.4). The calm turn's real rings (`warm_ring_prof`, `epoch_prof`, 97% land): 57 to 54 us a column, the whole warm 295 to 285 ms for the 4,800 columns. **That is nowhere near the 60 us web target** (which needs about 22 us native): the 28 octaves at 0.9 us each are the cost, and a bit-exact octave cannot be made much cheaper in GDScript (an integer-floor variant measured no faster; the corner cache already hits 99% of octaves). The remaining levers are structural and not mine: fewer columns a tick in the state's `k` (a longer warm), reading a ring's columns only as the swap needs them, or a coarser gen 2 read (a different planet).

Proof: `read_digest.gd` (float64 heights, biomes and fine biomes of 24,000 points on four planets, both generations) and `ring_bench` hashes identical to the base for all of them; `planet_digest.gd` (places, grid, flow field and two touch-down slices, both generations, rivers on and off) identical to HEAD plus planet-load.

## 2. The planet's load in steps (EP's add-on)

Each piece goes on where it left off, bounded by the units a read gets (`SimRun.planetUnitsPerRead`, 250: about 5 ms; a unit is about 20 us).

| Piece | One call before | After |
| :--- | :--- | :--- |
| The wind's carry (ends the grid) | 17 to 26 ms | `Grid.step`: ten units a row of the wind, one a row of each blend |
| The flow field (rivers on) | 136 to 149 ms | `Flow.new(G, false)` and `step(ticks)`: setup, seeds, the flood (a pop is 15 ticks), drainage, runoff, count; a tick is 0.4 us; `PlanetJob.FLOW_CELLS` ticks a unit; `FLOW_COST` is now 7,400 units |
| A place's try-set | 72 to 80 ms (cities); the replacement sets up to 117 | `_tryRun` resumes a set at its next try (a try is 3, 6 or 14 units by how far it gets: measured 53, 124, 284 us), draw for draw |
| A touch-down's ring | one `sliceFor` call, 80 to 90 ms | `WorldPlanet.SliceJob`: the pick a circle a step (one circle is 96 surface reads, 4 to 6 ms), the columns a slice, the held places; memoised where `sliceFor` finds it |

Measured at a budget of 250 on this PC (the machine 35 to 40% busy): the planet job's longest call 148.8 to **7.7 ms**; the longest touch-down step 7.9 ms; a touch-down's match after the host's load is the cold one to the bit and starts in 5 ms. (7 to 8 ms is the 5 ms budget plus one try, one circle or a row of the wind.)

`WorldPlanet._planets` and `_slices` evict the oldest entry, not all of them: an eighth planet drops the first only.

**Not done.** Research's B plates (49 to 55 ms in one call, `WorldPlateB.stateOf`) and a B planet's slower try-sets (a try is dearer: the weights are measured without B). Simulation's `planet_load.gd` wants two lines (`grant_sim_load.py`): `spent += u` for the job's steps (the try-set floor of `PLACE_COST` units is gone) and `SliceJob` for a touch-down's ring.

Checks: `step_check.gd` (stepped equals whole at budgets 250, 37 and the whole, with and without rivers and for gen 1; `SliceJob` equals `sliceFor` for three touch-downs; the host's load then the match is the cold match; the eviction), `rivers_check.gd` (the stepped flow field equals the whole one at chunks of 1, 7, 1,000 and 20,000). Tools: `job_prof` (the job's calls), `try_prof`, `flow_prof`, `touch_prof`, `step_prof`, `warm_ring_prof`, `ring_prof`, `epoch_prof`.
