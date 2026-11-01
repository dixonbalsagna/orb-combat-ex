# Launch ticks on the stack: what is left that is cheap (Performance and Platform, 2026-11-01)

For the EP. Base: a copy of the EP's `s400` (the stack as the gate sees it, 49a143a plus the working changes). Measured with statement-level timers and counters on a scratch copy, then with a lean bench on a clean copy plus one proposed patch. Nothing in the repo's `sim/` is touched.

## Answer

**A launch tick is 10 to 30 ms here, and about two thirds of it is memo misses, not arithmetic. Warming those memos a few entries a tick in the background takes the worst launch tick from 29.5 ms to 8.8 ms (ring) and 7.9 ms (ring plus buildings), and changes no result: the gameplay hash trace of the whole match is identical in all 18 runs.** It is a patch to Simulation's `sim/core/field.gd` and `sim/core/sim.gd` (`docs/perf/tools/swing-bench/fix-ring-warm.py`, about 40 lines, off by default).

## Where a launch tick goes (36 matches: planets 7/12/21 × seeds 77/5, three processes each, a first match and a rematch in each; ticks over 16 ms)

Ten ticks of the 36 matches are over 16 ms (taking the lowest of the three processes): **nine are launches** (`DirLaunch.chooseLaunch`, 16 to 35 ms), **one is `WorldWater.step`** (11.9 ms of a 16.1 ms tick, a rematch on 12:77; `fix-water-base.py` of the hitch table is not in this base). None is the swing and none is the rematch's contact table (World's fix is in this base: no 58 to 86 ms tick). Inside a launch tick:

| Part | ms | What it is |
| :--- | :--- | :--- |
| `L5_score` (scoring the candidates) | 9 to 34 | almost all `predictFlight`: 3 calls a launch |
| of which `SimField.groundCeilAt` | 8 to 22 (95% of `predictFlight`) | 17 to 25 calls at 300 to 900 µs each, where its comment says about 30 µs |
| `L2_brunt` (building aims) | 1 to 14 | `WorldBrunt.candidates` 1 to 10 (reads every building within reach) plus `aim` 0.3 to 10 for the 3 to 5 it picks |
| the rest (`L1`, `L3`, `L4`, filters) | < 1 | |

**Why `groundCeilAt` is slow.** Of `predictFlight`'s 360 to 520 steps a launch, 96 to 99% are skipped by the ceiling, so the stepping is cheap. The cost is the ceiling itself: 110 to 180 `SimField._coarse` misses a launch tick (the ring has 600 at stride 8), about 50 µs each (one field sample), the memo's first read of those columns since the memo was last laid again. It is laid again when the store or the frame changes (`_bind`: 83 to 129 times in 7,200 ticks, in bursts after craters), and between launches (64 to 970 ticks after the last rebind) it is mostly warm for the places the fight touches but cold for the stretches a flight crosses. The nodes are not the cost: a rematch (0 new lattice nodes) pays 8 to 12 ms too.

**Why `candidates` is slow.** It reads `WorldStructures.baseY` of every building within `BR_MAX`: 11 to 48 buildings near, about 0.11 ms each cold (`SimField.buildingGround`, a memo keyed on the store hash), 1 to 5.3 ms. **That cost is linear in the buildings near the fight.** This base has 163 to 263 buildings; with buildings everywhere (the EP's case) it grows with them, and it is what the ring fix alone does not cover.

## The cheap fix (bit-identical)

`SimField.warmStep` (called at the end of `SimCore._step`): once the memos have been quiet 6 ticks since a rebind, fill 8 coarse columns a tick (and the record water there) in ring order, then 8 buildings' ground a tick, until warm; a rebind starts it over. The values are those a read would compute in the same state, so nothing a player or a hash can see changes. It costs 8 × 50 µs = 0.4 ms a tick while warming (75 ticks for the ring, 33 for 263 buildings).

| Case (planet:seed) | Launch ticks | off (ms) | ring (ms) | ring + buildings (ms) |
| :--- | :--- | :--- | :--- | :--- |
| 21:5 | 4331 5330 6575 7025 | 29.5 10.1 17.9 24.8 | 8.8 6.5 4.6 7.5 | 7.9 5.4 3.9 3.7 |
| 12:77 | 452 2005 4123 6605 | 13.7 17.8 10.5 3.6 | 10.0 4.6 4.5 3.1 | 5.3 3.6 2.6 2.7 |
| 7:77 | 1389 2127 | 9.0 14.5 | 5.9 3.5 | 5.8 2.9 |

Each cell is the lower of two runs of the same launch tick (the launches fall on the same ticks in every variant because the match is identical). **Worst launch: 29.5 → 7.9 ms; every launch tick after the fix is under 8 ms except 10.0 (the ring alone, 12:77 at tick 452, which the building warm-up takes to 5.3).**

**Proof it changes nothing:** the gameplay hash every 600 ticks (12 checkpoints) and the end state (tick, both x and hp) are equal in all 18 runs (3 cases × off, ring, ring + buildings × 2 rounds). Mean tick rises by about 10% (503 → 553 µs on 21:5; 651 → 753 µs on 12:77; 512 → 554 µs on 7:77), the price of warming columns that are never read; p99 does not move beyond the run-to-run spread (1.95 ms → 1.95 ms; 3.6 → 3.7 ms; 2.4 → 2.3 ms for ring + buildings).

**Two launches at once (2v2), by arithmetic, not measured:** the memos belong to the one field of the sim, so a second fight's launch finds the same warm ring; what the second one adds is its own `aim` (about 0.3 to 5 ms) and `predictFlight` steps (under 1 ms). Today the first launch pays the whole cold read and the second finds part of it warm, so the pair is about the cold launch plus a few ms; after the fix about 8 ms plus a few ms. A real pair needs 2v2 to exist (it does not yet).

## What is left after it (and what is not cheap)

- **`WorldBrunt.aim`**: 0.3 to 5.5 ms for the 3 to 5 picked buildings, about 1 to 3 ms each. Not measured further; it re-flies a launch against the building's box for several `AIM_UY` values. A pre-rejection by the cheap score would change which candidates compete, so it is a design call for Combat, not a pure speed-up.
- **A rebind in a burst** (a crater every tick for 10 to 20 ticks, seen at ticks 509 to 524 and 1516 to 1565) starts the warm-up over each time. The 6-tick quiet rule keeps it from spending anything during the burst.
- **Invalidating by place** (a crater only changes the columns and buildings near it) would stop the ring from going cold at all; that is a bigger change in `sim/core/field.gd` and worth Simulation's look after this one.

## Limits

- **Every wall time here is under a loaded machine** (CPU 90 to 93% busy through the runs, 11 other Godot processes): marked INVALID by the load rule as absolute numbers. The comparison is paired on the same ticks (the same launches), two rounds, the lower taken, and the mechanism is counted (misses, calls) and not only timed; the order of magnitude (30 → 9 ms) is beyond the noise, the 1 to 2 ms differences are not.
- 18 matches on three planets; first matches in a process, the cold case, which is the one Orb plays.
- **"Buildings everywhere" is not in this base** (163 to 263 buildings). The linear cost per near building (0.11 ms) is measured; the 10 to 20 times more buildings of a dense town are extrapolated, and the first quiet-machine run on World's park is the check.
- `predictFlight` with `S.depthOn` or no frame (the old model) does not use the ceiling and is not covered.
- One slip on my side: four Godot jobs ran for about three minutes at one point (the cap is three).

## Files

`docs/perf/tools/swing-bench/`: `fix-ring-warm.py` (the patch; `--` off by default through `SimField.warmN` and `warmB`), `launch_bench.gd` (the lean bench: per-tick time, launch ticks, hash trace; `--warm=8 --warmb=8`). The instrumented runs (stage timers, miss counters) are in my scratch folder, not the repo.
