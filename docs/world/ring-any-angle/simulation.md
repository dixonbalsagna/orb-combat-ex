# A bearing change at any tick: what the core needs (Simulation, research only, 2026-10-30)

For the EP, on Orb's ask. Nothing is built and no tree was edited. I ran throwaway probes in a scratch copy of HEAD f19a3523, on a gen 2 Half ring of planet 7. The probes use the real turn code with its caps lifted in memory, plus a small prototype of a curved road. World's and Netcode's pages cover the ring read's cost and the online rules; this page covers the core.

**How to read the numbers.** The machine sat at 74 to 100% load, so under the rule of 2026-10-12 I report none of my timings. Costs here are counted columns x World's quiet figure, 54 µs a gen 2 column natively. Counts, states and bits don't depend on load.

## The answer

1. **The core does not block any angle or any tick.** A real swap ran on every tick, at 180° and in the middle of AI fights. The state was the same both runs, with no script errors, and the two runs I compared matched between native and web.
2. **What blocks it is the columns.** A whole-ring change every tick is 2,400 columns a tick (130 ms). It can't ship.
3. **A curved road can change every tick,** at 12 columns a tick (0.65 ms), the rate already budgeted. `W`, `NC`, `sdx` and `wrap` stay exactly as they are.
4. **A curve only changes the ground ahead.** A pair standing still never reaches it, so the large steps Game Design wants still need a swap. The two work together.

## The three options

| | Whole ring every tick | Sparse swap (today's turn, caps off) | Curved road |
| :--- | :--- | :--- | :--- |
| **Change rate** | Every tick | One per 205 ticks at `K` 12 (3.4 s). Counted: 80 at k 32, 43 at 64, 24 at 128, 15 at 240, 10 at 480. The floor is 6 (`prepTicks`) | Every tick, at the road's front |
| **Columns a tick** | 2,400 (counted: 60,000 in 25 ticks) | 12 | 12 (6 a side) |
| **Cost a tick, native** | 130 ms, plus the preparation | 0.65 ms, plus the swap tick | 0.65 ms, ground only |
| **What moves under a fighter** | Everything outside the kept zone, every tick | The same, once, at a known moment | Nothing he has reached: only the road ahead |
| **A rollback of 21 ticks** | 50,400 columns (2.7 s) by arithmetic | 0 columns if the pick is older than the window; a whole ring per pick if it's inside (below) | 252 columns (13.6 ms) with no cache, 0 with one |
| **Prototyped how far** | Real swap | Real swap | Ground heights only: no places, buildings, carry or view |
| **My call** | Refuse | **Build first** | Build only if Orb wants a visible curve |

6 columns a side is 192 units a tick, and a flat-out dash is about 171. So the road's front outruns any free flight, by 12%. I haven't sized a long rush against it.

## `SimConst.W` and `NC` as statics

**Keep them fixed for the match in all three options.** A change of bearing never needs a change of length.

- **Shipping code outside tools reads them often:** `W` 56 times, `HALF` 23, `NC` 185, `COL` 178, `sdx` 616, `wrap` 343. None of those change.
- **The statics are already safe.** `step()` rebinds them when another sim has run (the conditions in `arena-conditions.md`).
- **Changing `W` mid-match is refused.** A curve whose length changed would have to resize the per-column arrays and rescale every `x` and the `DirLocation.STEP` buckets on each change, and it buys nothing that a fixed-length buffer doesn't give.

## Shortest-arc math if the path isn't a closed circle

**Make the columns a ring buffer of the road.** `x` stays in `[0, W)`, and column `i` holds the newest road point whose distance along the road is `i x COL` modulo `W`.

- **`sdx` stays exact along the road** while two bodies are less than `HALF` apart, and that is the same limit as today. It measures road distance, never planet distance. The fight code has never asked for planet distance.
- **The old and new road meet opposite the pair.** That seam needs World's blend. A body crossing it has `sdx` reading through a join that isn't one place on the planet. Pillar 3 still holds, because the buffer still closes.
- **A lap no longer comes home.** Game Design has accepted that.
- **Anything recorded in a column must end when its column is overwritten:** marks, craters, slides, aftermath and water. The swap has this rule by zone today; the road needs it by column.

## Ring position against planet coordinates

- **The fight has no planet coordinates.** Fighters, shots, craters and structures all hold ring `x`. Outside tools, `ringPoint` and `lateral` are read only by the world's build, the turn and the campaign, and never in a fight's tick.
- **So the map from `x` to the planet is one piece of state:** the epoch's ring today, the road tomorrow. A swap keeps every `x`, so nothing is converted.
- **The road's state is small:** each front's point and tangent, 12 floats. Rendering's far land and the wear list need a point for a column. As a table that's 57.6 KB on a Half ring and 115 KB on a Whole, or arc records if those are smaller. Never keep a history (Netcode's rule).
- **Stable building slots are the core's real job for a road.** `S.buildings = keep + made` re-indexes everything, which orphans `f.interior`, wreck ids and `splashed`. `bIdx` says it never changes in a match. A road adds and retires buildings as it goes, so it needs fixed slots and an index updated one building at a time. Those are my packed arrays.
- **Far readers are the largest unknown; I haven't audited them.** The director has 19 `groundY` calls, and 11 director and core files read `S.buildings`. A launch planner could aim at a tower that the road overwrites before he arrives. Either planners read only the committed road, or a plan commits what it aims at.

## Hash and replay

- **A replay needs no format change.** If the bearing is a director decision from the state and seed, nothing new is recorded. The forced runs below confirm that the same inputs give the same turns.
- **New data keys must join `SimReplay.dataHash`,** so a replay on other data is refused.
- **`stateHash` doesn't read `S.base`.** The ground is covered only by `E.sh`, the slice's hash. A road folds each column into a running hash as it's read, as `_hashTo` does. Re-hashing a whole ring each tick is not an option.
- **The bearing, the lead's queue and the fronts go in `hash.gd`,** and in `NetDesync.digest`, which doesn't read `S.epoch` today (Netcode's page).

## Snapshot and rollback

- **Size:** 83.5 KB on this ring (67.7 KB packed, 2,075 scalars). How often the bearing changes doesn't grow it.
- **The road adds little:** `S.base` must leave `SNAPSHOT.share`, which adds 9.6 KB, since writing a shared array in place corrupts every snapshot. Most of a take's cost is scalars; a packed block is one copy.
- **Rollback over a swap is exact:** 6 of 6 depth-21 re-runs at each of k 32, 240 and 2,400 gave the same `stateHash` and digest, with no cold swaps.

**Measured: a pick inside the window throws the ring away.** `choose` calls `_dropJobs`, so a re-run that passes the pick reads the ring again on the rollback frame:

| Pick rate | Picks inside the 21 ticks | Columns read by each re-run | Native |
| :--- | ---: | ---: | ---: |
| k 32 | 0 | **0** (the kept job is found) | 0 |
| k 240 | 1 | **2,400** | 130 ms |
| k 2,400 | 3 | **7,200** | 390 ms |

Netcode found this by reading the code; these counts confirm it. The fix is World's: key the job cache by seed and ring, and don't drop it at `choose` or `cancel`. It should land before any turn goes on. A road needs the same cache keyed by a front's exact bits, or its re-run costs 13.6 ms, over the 12.5 ms budget.

**Netcode's lead of 20 ticks fits the road.** Inputs through T - 20 are confirmed before T runs, so a change made 21 ticks ahead of the body can't flip on screen. The road must be committed for 21 ticks x 171 units, plus half a screen: 5,085 units, 159 columns. At a flat-out dash a change therefore reaches his feet in about half a second.

## float64 trig, web and native

**Holds, on everything run.** The sim's math is scalars with `+ - * / sqrt` and our own sin, cos, atan and acos. `Vector3` is float32 and stays out, as `planet.gd` already does.

**Native and web agree to the bit** (Chrome 156, x64; all 45 golden keys and 14 extras identical, 8 of them new):

| New key | What it runs |
| :--- | :--- |
| `drift`, `driftNorm` | 216,000 composed turns and steps, without and with renormalising |
| `stream`, `streamWild` | The road for 1,200 ticks at up to 1° a tick; 400 ticks at up to 30° |
| `turns25`, `turn180` | Real turns at 2.5° and 180° |
| `perTick` | A real cold swap on each of 12 ticks |
| `anyTick` | An AI fight with a swap forced every 60 ticks at 45° |

**Rounding is not a problem.** After 2,160,000 composed steps (10 hours of ticks), a point is 0.0000008 units from the closed form and its length is off by 9e-11. Renormalising brings that to 0.00000007 at about twice the cost, so it isn't needed for accuracy.

**Not proven:** ARM (macOS on Apple silicon is a target platform), Firefox and Safari. This is the gap `web-parity.md` already lists; any-angle adds nothing new to it.

## Forced swaps in a real fight

World's calm test skipped, AI on both sides, the swap called directly. Each row ran twice with the same state; there were no script errors.

| Angle, spacing | Ticks | Swaps | On a tick that wasn't calm |
| :--- | ---: | ---: | ---: |
| 45°, every 60 ticks | 3,600 | 60 | 59 |
| 180°, every 30 ticks | 3,600 | 120 | 53 |
| 10°, every tick | 240 | 240 | 96 |

This shows the core stays deterministic and doesn't crash. It does **not** show the fight stays right: World's list of what a non-calm swap breaks (water, tower chains) still stands, and no fighter was in a tower chain in these runs. I also ran the swap with idle fighters at 45°, 90° and 180°, with no cold swaps, which closes one item World could not run.

## The curve's ground

Kinks don't show as steps. The height step between neighbouring columns stays close to a straight road's, so the ground needs no smoothing at the arcs' joins:

| Up to, a tick | Step, p50 | p99 |
| ---: | ---: | ---: |
| 0° | 2.66 | 26.0 |
| 0.5° | 2.70 | 29.6 |
| 5° | 2.61 | 33.9 |
| 30° | 4.50 | 39.4 |

The largest single step varies by what the road crosses (57 to 329 units), and one run per row can't separate that from the curve. A fighter is about 75 units tall.

## What the core would need

**For sparse swaps at any angle (small):**
- the lead's queue in `S.epoch`, and its hash lines;
- the call at a launch's stop;
- nothing in `W`, `NC` or the wrap math.

**For a road (a slice of its own, behind a switch, golden byte-identical with it off):**
- `S.base` out of the shared list;
- stable building and tree slots, with an index updated one at a time;
- the fronts in the state and the hash;
- records ended by column;
- the far-reader audit, with Encounter.

## Not measured

- Any timing that counts as valid. One quiet window of about 3 minutes would give the swap tick and the rollback frame.
- The road's places, buildings, carry and view; the column reads are the only part prototyped.
- A long rush against the road's front.
- A road under rollback: the 252 columns are arithmetic.
- ARM.
