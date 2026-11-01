# Every tick over 16 ms in a real match on the stack, by cause (Performance and Platform, 2026-10-31 night)

For the EP, on the work order "name every step over 16 ms, by cause". Native, headless, AI against AI, planets 7, 12 and 21, seeds 77 and 5, swing on and off, 7,200 ticks (two minutes) each, **two matches per process** (the first, and a rematch in the same process). Nothing here changes the game; every fix below is a proposal for its owner, and the one I tried is in a scratch tree.

## Result in five lines

1. **The 58 to 86 ms tick is `WorldContact._buildSurf`, rebuilt lazily at the first surface lookup of every match after the first in a process.** 12 of 12 rematches hit it once (56 to 92 ms; minimum of three independent processes 56 to 92 ms), at the first launch's biome check (`WorldContact.lookAt`, 55 to 67 ms) or, if a fighter skids first, in `stepFighter` (p7, 57 to 64 ms). It has **0 new lattice nodes** and **no swing** involved: swing on or off, same size. Priming the table at match start removes it (Evidence).
2. **Launch ticks cost 18 to 27 ms** (first match: 21 ticks over 16 ms in 12 matches; wall time on a busy machine) in `DirLaunch.chooseLaunch`: `predictFlight` 4 to 16 ms, the building aims (`L2_brunt`) 3 to 11, the biome candidates 3 to 6. Same with the swing off. Owner: Combat.
3. **Water ticks cost 14 to 62 ms** when `WorldWater.step`'s flow window runs: 25 of 34 such ticks built 7 to 118 new lattice nodes (the 40 to 62 ms ones at ticks 3154 to 3166 of 12/77/on are Combat's 27 to 32 ms hitch), 9 had none (14 to 21 ms). It is the flow loop's per-column `baseAt` reads, not the aftermath, the fire or the fill. Only 12/77/on had a water stretch; its swing-off twin played another match without one.
4. **The rest of the match is cheap**: mean 0.35 to 0.58 ms a tick, p99 1.0 to 2.0 ms, in every case. The tick is not the frame problem except on these named ticks.
5. Everything is in wall time on a machine 70 to 90% busy, so the numbers are upper bounds; the minimum over three independent processes removes the machine's spikes (counted below), not its steady slowdown (Combat's quiet-machine launch ticks are 9.7 to 14.1 ms against my 18 to 27).

## Method

- **Tree**: main `66654335` plus the stack (`node tools/preview/stack.mjs --no-godot --keep-tree`: 18 parks applied; `world-gen3-field`, `architecture-field-frame-2` and `architecture-field-pads` have landed in main and read "missing" because their patch files are gone; the two net parks are not in the tree), switches `gen2 ... rightStick, gen3, meteor, tiles, swing` on. Trimmed copy, imported once, Godot 4.7.2 `--headless`, below-normal, three jobs at a time.
- **Setup**: `planetGen 3`, `touch 1`, intro off, both fighters AI, the ring baked before tick 0 (as the host's load does: `WorldField.bakeStep`). Swing off is `setup.swing = "off"` (the page's `swings=off` word); DirSwing and SimSwing still run their ticks.
- **Per tick**: wall microseconds around `SimCore.step` (the whole sim step; no drawing), stage timers inside `SimCore._step` (statement-level `Time.get_ticks_usec`, no wrapper functions: those changed the match before), marks inside `DirLaunch`/`DirSwing`/`WorldWater`/`WorldContact`, and the count of new lattice nodes (`SimField._F.reads` delta).
- **CPU time**: each case runs in **three independent processes**; the table uses the **per-tick minimum over the three**. A spike that one process shows and another does not is the machine's (preemption), and is removed ("run-only spikes" in the report: 9 to 100 per match above 16 ms). A cost every process shows is the code's. The ends of the three matches are identical in every case (deterministic).
- **First vs rematch**: the second match of a process starts with static caches warm (lattice nodes, tables) and one stale one (the surface table below). "First" is what a player sees on a fresh page; "rematch" is a second match in the same session.

## Per-case summary (minimum over three processes, microseconds)

| planet / seed / swing | match | mean us | p50 | p95 | p99 | max us | ticks over 16 ms |
|---|---|---|---|---|---|---|---|
| 12 / 5 / off | first | 479 | 518 | 901 | 1225 | 19537 | 1 |
| 12 / 5 / off | rematch | 488 | 520 | 902 | 1208 | 77664 | 1 |
| 12 / 5 / on | first | 529 | 530 | 1111 | 1654 | 21012 | 1 |
| 12 / 5 / on | rematch | 516 | 533 | 993 | 1370 | 69825 | 2 |
| 12 / 77 / off | first | 576 | 576 | 1001 | 1605 | 25371 | 6 |
| 12 / 77 / off | rematch | 578 | 575 | 992 | 1583 | 91801 | 6 |
| 12 / 77 / on | first | 1129 | 686 | 2938 | 4322 | 61816 | 38 |
| 12 / 77 / on | rematch | 665 | 562 | 1613 | 2372 | 90622 | 4 |
| 21 / 5 / off | first | 472 | 503 | 908 | 1201 | 23843 | 2 |
| 21 / 5 / off | rematch | 475 | 498 | 894 | 1195 | 86008 | 2 |
| 21 / 5 / on | first | 533 | 518 | 1279 | 1674 | 22790 | 1 |
| 21 / 5 / on | rematch | 533 | 512 | 1260 | 1629 | 78745 | 1 |
| 21 / 77 / off | first | 466 | 490 | 889 | 1205 | 12057 | 0 |
| 21 / 77 / off | rematch | 478 | 491 | 893 | 1211 | 70601 | 1 |
| 21 / 77 / on | first | 486 | 490 | 1097 | 1482 | 18202 | 1 |
| 21 / 77 / on | rematch | 497 | 496 | 1092 | 1441 | 73641 | 1 |
| 7 / 5 / off | first | 458 | 503 | 918 | 1196 | 26908 | 1 |
| 7 / 5 / off | rematch | 473 | 512 | 931 | 1217 | 64328 | 2 |
| 7 / 5 / on | first | 545 | 523 | 1306 | 1992 | 17971 | 1 |
| 7 / 5 / on | rematch | 549 | 529 | 1285 | 1799 | 56858 | 2 |
| 7 / 77 / off | first | 510 | 517 | 991 | 1450 | 18710 | 2 |
| 7 / 77 / off | rematch | 502 | 505 | 979 | 1318 | 77787 | 3 |
| 7 / 77 / on | first | 475 | 490 | 988 | 1555 | 23289 | 1 |
| 7 / 77 / on | rematch | 471 | 482 | 944 | 1358 | 78115 | 2 |

## Ticks over 16 ms by class

| match | class | ticks over | ms over the limit, summed | worst ms |
|---|---|---|---|---|
| first | launch | 21 | 106 | 27 |
| first | water+n | 25 | 252 | 62 |
| first | water | 9 | 25 | 21 |
| rematch | launch | 15 | 85 | 27 |
| rematch | surf | 12 | 724 | 92 |

Classes: **surf** `WorldContact._buildSurf`; **launch** `DirMelee.launchBeat` -> `DirLaunch.chooseLaunch`; **water+n** `WorldWater.step` on a tick that built new lattice nodes; **water** the same with none.

## The 58 to 86 ms tick

- **What it is**: `WorldContact.surfaceAt` rebuilds its per-column table (`_buildSurf`) when `_colSurfKey != WorldBiomes.worldId`. A match's first world claims a new id; the table is built once at data load for the first match (line 255 of `sim/world/contact.gd`), but **a second match in the same process gets a new id and the table is rebuilt lazily, inside whichever tick first asks for a surface**: the first launch's `_biomeCandsRead` (`Bi_look` 55 to 67 ms) or a skid in `stepFighter`.
- **Evidence**: a mark inside `_buildSurf` reads `Bs_total` 62.3 ms in the rematch's tick 3730 (p12, seed 5), of which `WorldGround.columns` is **1.0 ms**: the 61 ms is the per-column `WorldBiomes.biomeAt(float(i) * COL)` loop over the arena's columns. p7 seed 5's tick 1407 (stage `fighter`, 93 ms in that run) read `Bs_total` 91.7 ms. All three independent processes show it at the same tick (e.g. p12/77/off tick 452: 138, 117 and 92 ms; the minimum 92). **Priming**: reading `WorldContact.surfaceAt(S, 0.0)` once after `newMatch` makes the same rematch tick 18.8 ms and the match's worst tick 23.6 ms (`--prime` in `stage_bench2.gd`).
- **Ruled out**: lattice nodes (0 new at every one of these ticks); the swing (same with it off); GC or preemption (the same tick in all three processes; priming removes it); `WorldGround.columns` (1 ms); `SimField` memo (not on the path).
- **Real-game reach**: any match after the first in a session (a rematch, a new planet from the menu) if the host's `newMatch` takes a new world id as my bench's does; **not run through the host's rematch path**.

## Water and lattice nodes

- `WorldWater.step`'s flow window loops its columns calling `WorldTerrain.baseAt(S, b)` (a field world: `SimField.col`) **three times per column** each water tick (every second tick), over windows of up to hundreds of columns. 12/77/on: 34 ticks over 16 ms, all in this loop (a sub-timer split: aftermath 0, fire 1 us, fill 0; the flow loop is the rest).
- On ticks that build nodes the cost is the node builds (118 nodes in 48 ms at tick 3154: about 0.4 ms a node; 118 in 14 ms at tick 1026: 0.12 ms; the same tick-3154 cost whether or not the repeat reads are cut), which is Simulation's lattice work. Without new nodes the 14 to 21 ms is repeat reads.
- **Scratch fix tried** (`docs/perf/tools/swing-bench/fix-water-base.py`, World's `water.gd`): read each window column's base once into a local array and use it in both loops. The match is **bit-identical** (same end state), the case's mean tick 1,513 to 1,185 us (-22%), ticks over 16 ms 34 to 23, excess over 16 ms 230 to 174 ms (minimum over 3 and 4 runs); the new-node ticks (3154 to 3166: 50 to 47 ms) do not change.

## Launch ticks

`DirMelee.launchBeat` -> `DirLaunch.chooseLaunch` in one tick: `predictFlight` (up to five flights of `PREDICT_STEPS` ticks of ground and sea reads each) 4 to 16 ms, building aims 3 to 11, biome candidates 3 to 6 (PROP SMASH no longer in it), `DirSwing.scored` 0.5 to 5 on swing-on matches, the rest under 2. 21 first-match ticks over 16 ms in 12 matches, worst 27 ms; the same ticks with the swing off.

## Fixes, ranked by what they save

Savings are the milliseconds over 16 ms across these 12 matches (two matches each) and how often a player meets them.

1. **World + Simulation: build the surface table at match start** (`WorldContact._buildSurf` called from the match job's end, or `WorldContact.prime(S)`; better, derive the column biomes from `planetCols` instead of 9,600 `biomeAt` calls). Saves 724 ms over the limit (12 ticks of 56 to 92 ms), one 60 to 90 ms frame in **every match after the first**. Benched: removes the spike, the table is the same one, built earlier. About ten lines.
2. **World (+ Simulation for the lattice): `WorldWater.step`**: read each column's base once per step (proposal benched, bit-identical, -22% of this case's mean tick, 11 fewer ticks over 16 ms); then Simulation's node builds (118 nodes in 48 to 62 ms) in the loading frame or sliced, since a node build inside a fight tick is the 40 to 62 ms stutter. Saves 277 ms over the limit here (34 ticks), in **clusters of consecutive water ticks** that read as a stutter of a second.
3. **Combat: `DirLaunch` forecast loops** (`predictFlight`, building aims): skip the ground and sea reads while the body is far above any terrain (a bound on terrain height), and cheaper building aims. Saves about 191 ms over the limit (36 launch ticks, 18 to 27 ms each), 3 to 6 launches a match, and the 8 ms target needs both cuts (see `swing-tick-recut-2026-10-31.md`).

## Limits

Wall time on a busy PC (the minimum over three processes drops preemption, not a steady slowdown); AI against AI on three planets and two seeds, not a human match; the native sim only (the frame's draw, the web build's 4x slower script and the first-use shader hitches are other tables); the rematch reach is by my bench's `newMatch` loop, not the host's menu path; Combat's park state and Simulation's lattice work were not changed by me. The match with swing off and on are different matches (the swing changes the fight), so a swing-on stretch with no swing-off twin is not proof the swing causes it.

## Files

`docs/perf/tools/swing-bench/`: `hook-14-stages.py`, `hook-15-pm-and-biome-split.py` (the marks), `stage_bench2.gd` (per-tick JSON, `--prime`), `matrix3.mjs` (36 runs, three at a time), `stage-report.mjs`, `stage-classes.mjs`, `fix-water-base.py`. Raw runs are in my scratch folder, not the repo.

## Every tick over 16 ms


| planet / seed / swing | match | tick | ms | class | what cost it |
|---|---|---|---|---|---|
| 12/5/off | first | 3730 | 19.5 | launch | building aims (L2_brunt) 8.7, biome candidates (L4_biome) 4.4 |
| 12/5/off | rematch | 3730 | 77.7 | surf | WorldContact._buildSurf |
| 12/5/on | first | 4288 | 21.0 | launch | predictFlight 13.5, biome candidates (L4_biome) 3.9 |
| 12/5/on | rematch | 3730 | 69.8 | surf | WorldContact._buildSurf |
| 12/5/on | rematch | 4288 | 21.1 | launch | predictFlight 14.1, biome candidates (L4_biome) 3.5 |
| 12/77/off | first | 452 | 25.4 | launch | predictFlight 11.1, building aims (L2_brunt) 8.7 |
| 12/77/off | first | 1052 | 21.6 | launch | predictFlight 12.6, building aims (L2_brunt) 3.5 |
| 12/77/off | first | 1493 | 21.9 | launch | predictFlight 12.8, biome candidates (L4_biome) 4.4 |
| 12/77/off | first | 1740 | 21.7 | launch | predictFlight 10.7, building aims (L2_brunt) 5.1 |
| 12/77/off | first | 4075 | 21.4 | launch | predictFlight 14.2, biome candidates (L4_biome) 4.9 |
| 12/77/off | first | 5363 | 20.7 | launch | predictFlight 13.9, biome candidates (L4_biome) 5.0 |
| 12/77/off | rematch | 452 | 91.8 | surf | WorldContact._buildSurf |
| 12/77/off | rematch | 1052 | 23.0 | launch | predictFlight 13.4, building aims (L2_brunt) 3.7 |
| 12/77/off | rematch | 1493 | 20.6 | launch | predictFlight 11.7, biome candidates (L4_biome) 4.2 |
| 12/77/off | rematch | 1740 | 24.7 | launch | predictFlight 12.9, building aims (L2_brunt) 5.2 |
| 12/77/off | rematch | 4075 | 19.5 | launch | predictFlight 12.6, biome candidates (L4_biome) 4.4 |
| 12/77/off | rematch | 5363 | 18.3 | launch | predictFlight 11.6, biome candidates (L4_biome) 4.8 |
| 12/77/on | first | 452 | 18.5 | launch | building aims (L2_brunt) 6.8, predictFlight 3.9 |
| 12/77/on | first | 1026 | 20.4 | water+n | WorldWater.step, 118 new lattice nodes |
| 12/77/on | first | 1176 | 16.3 | launch | predictFlight 9.7, biome candidates (L4_biome) 4.5 |
| 12/77/on | first | 1187 | 17.5 | water+n | WorldWater.step, 21 new lattice nodes |
| 12/77/on | first | 1191 | 17.5 | water+n | WorldWater.step, 42 new lattice nodes |
| 12/77/on | first | 1193 | 17.0 | water+n | WorldWater.step, 46 new lattice nodes |
| 12/77/on | first | 1195 | 20.0 | water+n | WorldWater.step, 56 new lattice nodes |
| 12/77/on | first | 1197 | 20.7 | water+n | WorldWater.step, 50 new lattice nodes |
| 12/77/on | first | 1199 | 20.1 | water+n | WorldWater.step, 54 new lattice nodes |
| 12/77/on | first | 1201 | 16.4 | water+n | WorldWater.step, 53 new lattice nodes |
| 12/77/on | first | 1218 | 20.9 | water+n | WorldWater.step, 64 new lattice nodes |
| 12/77/on | first | 1220 | 16.6 | water+n | WorldWater.step, 58 new lattice nodes |
| 12/77/on | first | 1224 | 16.7 | water+n | WorldWater.step, 56 new lattice nodes |
| 12/77/on | first | 1226 | 21.1 | water+n | WorldWater.step, 49 new lattice nodes |
| 12/77/on | first | 1228 | 17.1 | water+n | WorldWater.step, 33 new lattice nodes |
| 12/77/on | first | 2050 | 22.2 | water+n | WorldWater.step, 49 new lattice nodes |
| 12/77/on | first | 2052 | 28.4 | water+n | WorldWater.step, 83 new lattice nodes |
| 12/77/on | first | 2056 | 29.9 | water+n | WorldWater.step, 43 new lattice nodes |
| 12/77/on | first | 2058 | 29.7 | water+n | WorldWater.step, 43 new lattice nodes |
| 12/77/on | first | 2060 | 22.0 | water+n | WorldWater.step, 19 new lattice nodes |
| 12/77/on | first | 2066 | 18.8 | water+n | WorldWater.step, 2 new lattice nodes |
| 12/77/on | first | 2241 | 17.3 | water | WorldWater.step |
| 12/77/on | first | 2245 | 18.7 | water | WorldWater.step |
| 12/77/on | first | 2247 | 18.2 | water | WorldWater.step |
| 12/77/on | first | 2249 | 17.5 | water | WorldWater.step |
| 12/77/on | first | 2429 | 18.2 | water | WorldWater.step |
| 12/77/on | first | 2431 | 19.7 | water | WorldWater.step |
| 12/77/on | first | 2433 | 21.4 | water | WorldWater.step |
| 12/77/on | first | 2435 | 18.5 | water | WorldWater.step |
| 12/77/on | first | 3154 | 50.6 | water+n | WorldWater.step, 118 new lattice nodes |
| 12/77/on | first | 3158 | 56.1 | water+n | WorldWater.step, 74 new lattice nodes |
| 12/77/on | first | 3162 | 61.8 | water+n | WorldWater.step, 59 new lattice nodes |
| 12/77/on | first | 3166 | 40.2 | water+n | WorldWater.step, 39 new lattice nodes |
| 12/77/on | first | 3168 | 27.7 | water+n | WorldWater.step, 11 new lattice nodes |
| 12/77/on | first | 3170 | 22.2 | water+n | WorldWater.step, 7 new lattice nodes |
| 12/77/on | first | 3174 | 19.9 | water | WorldWater.step |
| 12/77/on | first | 3540 | 19.6 | launch | predictFlight 10.2, biome candidates (L4_biome) 6.2 |
| 12/77/on | first | 4368 | 20.5 | launch | predictFlight 9.4, biome candidates (L4_biome) 4.5 |
| 12/77/on | rematch | 452 | 90.6 | surf | WorldContact._buildSurf |
| 12/77/on | rematch | 1355 | 22.9 | launch | predictFlight 14.1, biome candidates (L4_biome) 5.5 |
| 12/77/on | rematch | 2118 | 19.4 | launch | predictFlight 9.4, biome candidates (L4_biome) 3.7 |
| 12/77/on | rematch | 4103 | 25.9 | launch | predictFlight 14.0, building aims (L2_brunt) 5.8 |
| 21/5/off | first | 6724 | 23.7 | launch | predictFlight 15.5, biome candidates (L4_biome) 3.7 |
| 21/5/off | first | 7171 | 23.8 | launch | predictFlight 16.0, biome candidates (L4_biome) 3.5 |
| 21/5/off | rematch | 6724 | 86.0 | surf | WorldContact._buildSurf |
| 21/5/off | rematch | 7171 | 25.5 | launch | predictFlight 18.4, biome candidates (L4_biome) 3.1 |
| 21/5/on | first | 6724 | 22.8 | launch | predictFlight 13.9, biome candidates (L4_biome) 4.2 |
| 21/5/on | rematch | 6724 | 78.7 | surf | WorldContact._buildSurf |
| 21/77/off | rematch | 5244 | 70.6 | surf | WorldContact._buildSurf |
| 21/77/on | first | 5244 | 18.2 | launch | building aims (L2_brunt) 7.6, biome candidates (L4_biome) 3.6 |
| 21/77/on | rematch | 5244 | 73.6 | surf | WorldContact._buildSurf |
| 7/5/off | first | 6740 | 26.9 | launch | building aims (L2_brunt) 10.8, predictFlight 9.8 |
| 7/5/off | rematch | 1407 | 64.3 | surf | WorldContact._buildSurf |
| 7/5/off | rematch | 6740 | 27.1 | launch | predictFlight 10.5, building aims (L2_brunt) 9.3 |
| 7/5/on | first | 4342 | 18.0 | launch | building aims (L2_brunt) 7.7, predictFlight 4.2 |
| 7/5/on | rematch | 1407 | 56.9 | surf | WorldContact._buildSurf |
| 7/5/on | rematch | 4342 | 19.1 | launch | building aims (L2_brunt) 8.9, predictFlight 4.2 |
| 7/77/off | first | 3593 | 18.7 | launch | predictFlight 12.0, biome candidates (L4_biome) 4.0 |
| 7/77/off | first | 6812 | 18.4 | launch | predictFlight 9.4, biome candidates (L4_biome) 2.5 |
| 7/77/off | rematch | 1389 | 77.8 | surf | WorldContact._buildSurf |
| 7/77/off | rematch | 3593 | 19.3 | launch | predictFlight 12.4, biome candidates (L4_biome) 4.1 |
| 7/77/off | rematch | 6812 | 18.3 | launch | predictFlight 10.0, biome candidates (L4_biome) 2.5 |
| 7/77/on | first | 1585 | 23.3 | launch | predictFlight 14.6, biome candidates (L4_biome) 5.5 |
| 7/77/on | rematch | 1389 | 78.1 | surf | WorldContact._buildSurf |
| 7/77/on | rematch | 1585 | 20.4 | launch | predictFlight 12.2, biome candidates (L4_biome) 5.7 |
