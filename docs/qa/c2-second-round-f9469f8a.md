# The second-round tune measured: f9469f8a (QA, 2026-10-12)

Clean export of f9469f8a ("The brawl's second-round tune": wear slowed, the second breath sooner, the AI perfect-blocks a heavy it sees and gives ground more, limb breaks spread off the arms, mood and acts re-paced). The harness `.gd` files are the export's own, with no overlay. Godot 4.7.2, headless, `--jobs=3`, below-normal priority (from the restart), wall cap 1,800 s a match and a budget of 8 hours a job.

**The run.** A first pass (07:14 to 12:16) was **void** and is not reported: the machine was saturated by abandoned browser captures and 20-odd Godot processes, and my jobs were wall-capped and budget-stopped. The clean pass ran from about 12:50 to 19:23 (6.5 hours): Orb's four tests (stage 1, 28 jobs, about 50 minutes), the rest of the masher stage (33 jobs, 2 hours 29 minutes), and the eight arms at 400 matches with the easy and hard level runs (about 3 hours). **No job was marked invalid.** The run survived the app's sign-out: its processes were detached, all three stages had finished by 19:23, and the three Godot jobs the EP saw still running (15:54 to 16:01) were the last masher jobs; they finished and saved at 16:24. Nothing needs re-running. The T, E, F plans and the downtime probes did not run.

**Totals.** Arm bands: 105 pass, 18 fail, 18 pending; acceptance tests 7 pass, 0 fail, 42 pending. The masher stage (61 jobs): 45 pass, 27 fail, 30 reported, 6 pending.

## The headline numbers

| Row | Reads | Band | |
| :--- | ---: | :--- | :--- |
| **The route against the X masher at the right cadence** (both against the medium AI, the absolute S.tick cadence of masher.gd) | route **13%** (13 of 100); the pair masher **35%** (35 of 100); masher.gd's banded masher 35.0% | the masher 35 to 50 | the route is **22 points worse** than the masher it is built from; it wins more launches (9.25 a match) and loses more matches |
| **Double hits a match, a steady lights-only presser against medium** | **2.00 a match, in 100% of matches** (200 in 100 matches; the most in a match 2: the cap) | 0.5 to 2; 35 to 65% | out (the cap is reached every match). The mixing presser: 0.00 |
| **The Y masher** (a Y every 12 ticks) | **3%** (3 of 100) | 20 to 50 | out |
| **The B masher** (a B every 30 ticks) | **40%** | 20 to 50 | in |
| **X held** (60 ticks down, 8 up) | **0%** (0 of 100) | 10 to 35 | out |
| **Y held** (to its flash at 26 ticks, 4 up) | **0%** (0 of 100) | 10 to 40 | out |
| B held to its flash | 24% | 15 to 45 | in |
| The three mashed in turn | 9% | 30 to 55 | out |
| **Bodies into buildings** | brunts **0.07 a minute** (about 0.5 a match over the 7.2-minute median); **3.9%** of planner launches end on a building (3.6% of all landings); 42.2% of launches with a building in reach pick it | 0.3 to 1.0 a minute; 4 to 10% | out, as before (0.07 and 3.5%) |
| **Match length** | median **432.9 s**, 10th percentile **313.1 s**, 90th 596.1 s | 360 to 480; at least 300; at most 600 | **all three in** (the 10th percentile floor is met on 400 matches an arm, 3,200 in all) |

## Before (b1b2ed6a) and after

| Row | b1b2ed6a | f9469f8a | Status after |
| :--- | :--- | :--- | :--- |
| Match length median / p10 / p90 | 360.9 / 263.6 / 498.7 s | **432.9 / 313.1 / 596.1 s** | all in (p90 on the edge: 600) |
| First brink / brink to KO | 267.7 / 74.2 s | 336.5 / 73.6 s | in / in |
| Limb breaks a match; arms' share | 0.22; 93.1% | **0.44; 46.9%** | both in |
| Mood Calm / Tense / Frenzied | 41.9 / 54.9 / 3.1% | 30.7 / 57.6 / 11.7% | all in |
| Frenzied share of act 4 | 8.3% | 19.2% | in |
| Acts 2, 3, 4 start | 89.3, 149.6, 231.8 s | 111.6, 195.9, 304.8 s | all in |
| Act 4 before the first brink | 79.8% | **63.2%** [58.4, 67.8] | out (further under) |
| Launches of those that separate / reaching a decision | 53.3 / 32.1% | 50.0 / 30.3% | out / out (by 0.3) |
| Launches a match, the AI against itself | | **13.1**, median 433 s, p10 313 s, civilians 20.1% | the band's top 14 holds with all three in band |
| Blasts' share of damage | 12.3% | 12.0% | in |
| AI's share of fight time in a brawl; median brawl | 40.4% | 41.6%; 6.8 s and 77 blows | in |
| Protagonist win rate | 46.8% | 51.4% [47.9, 54.8] | in |
| **X masher (masher.gd) vs medium** | 54% | **35%** | in, on the floor |
| Y masher / B masher | 0% / 100% | **3% / 40%** | out / **in** |
| X over Y; Y over B; B over X | 100; 98; 32.9% | 100; 98; 42.1% | all out |
| Mixed blaster vs medium (the blast script) | 49% | **63%** | out (Game Design: 37 of 60 expected; the blast script is a known fail by the EP's ruling) |
| Dead stick (live ticks) | 0.2% | 0.2% | out by a handful of ticks |
| AI holds against a held stick; held stick vs AI | 20.6%; 0.95 | 20.5%; 0.96 | in; in |
| Second breath: battered wear recovered through it | 21.7% (in) | **44.0%** | out: **known fail by the EP's ruling** (`breathAfterTicks` 150), Game Design reverses it next tune |
| Perfect blocks a minute: easy / medium / hard | 2.53 / 2.55 / 5.18 | 1.97 / 3.04 / **5.86** | in / in / **out** (band 2 to 5.5) |
| Zips countered; caught | 22.8%; 33.6% (out on its interval) | **26.8%** [23.9, 30.0]; 32.4% [29.3, 35.7] | out (by 1.8 points); in |
| Structures lost, front row; civilians lost | | 35.8%; 20.1% | in |
| 68-unit hard row (known fail) | 3 of 5,274,066 | **1 of 6,225,653**, the longest 74.9 | out by 7 units: the build fix worked |

## Orb's four tests (the interim, now with the whole stage)

1. **Moving in combat:** dead stick 0.2% of live held ticks (627 of 299,678; 823 of 419,821 for a presser toward against the medium AI), 99.9% of drifts within 2 live ticks, the AI holds on 20.5% of ticks, `c1.aistick` 0.96, walk-outs all pass.
2. **Moving while the rival charges:** out of an unfollowed tapped heavy 7,403 of 7,403, out of a followed one 0 of 5,875; **one new fail: the slowest first step of a free giver was 9 ticks** (10,051 wind-ups; it was 2), and 3 ticks against a followed Y wind-up. The 9 is probably a giver still in a missed blow's 20-tick "unable to give ground" window; my read does not exempt it.
3. **Launching:** every B in a ready opening launches (413, 368, 298 used, 0 lapsed). Route share easy 65.8% (out), medium 72.3% (in), hard 56.8% (out by 1.8); first launch inside 30 s 61.0% (out), inside 60 s 83.0% (out).
4. **Energy:** bolt and flashes pass. `energy.blast` reads 18 of 395 clean blasts knocked back and 377 cold; 16 of the 18 are other knock-backs. `burst.share` 56.3% (35.6 against 63.2 damage a second; band 70 to 80).

## Notes

- **The match is long enough again.** The 10th percentile reads 313.1 s on 3,200 matches (the floor 300 holds at 400 an arm); the median is 432.9 s. The brink to KO barely moved (73.6 s), so the lengthening is the first brink (336.5 s): wear arrives later.
- **The maskers moved the right way, and the edges did not.** The B masher is in band, the X masher on its floor. The Y masher and the X holder are shut out: 3% and 0%. The edges are unchanged (X over Y 100%, Y over B 98%), as the §14 levers for them are not in this build.
- **The double hit now saturates.** Every match of a lights-only presser reaches the cap of 2 (200 in 100 matches). The band's top is 2, so 2.00 is "in" on the mean but fails the 35 to 65% matches-with-one row.
- **Standing:** brunts, flights off terrain, lock-break median 1.3 s, structures levelled, mirror-villain biome share (40.4%), perfect blocks at hard (5.86, over by 0.36).
- **Mirrors:** the even mirror finishes 100%, first slot 42.5% (live), 42.5% (exact tie), 38.0% (tick-offset; its first 60 seeds 30%); brink to KO 70.3, 142.7 and 64.2 s (the exact-tie mirror at 142.7 s is out of 45 to 90). The uneven mirror finishes 100%, the faster tapper wins 200 of 200, brink 18.1 s.

## Harness (qa/, mine)

- `players.gd`: `clock=tick` is the absolute S.tick cadence (as masher.gd), `clock=since` the old one; `approach=1`; a B holder; the dead-stick on live ticks only.
- `masher.js`: the `invalid` gate, `QA_WALL` and `QA_BUDGET`; new pairs `x-medium`, `cell-y-held`, `cell-b-held`; the nine-cell ids; the launches row.
- `run-godot.js`, `timing-edge.js`, `masher-only.js`: start at below-normal priority.
- Not yet made: the holder pressing again when free and holding through the floor pace (waits for Encounter's shape), the burst's trigger, and the blast's own knock-back field.

---

# Baseline on the GDScript sim

Generated by `node qa/run-godot.js --matches=400 --scale=game`. Godot 4.7.2.stable.official.ed1daf0bf; clean export of commit f9469f8a; slices in the tree: S0 yes, S1 yes. Seeds 1..400 in every arm; cap 900 sim-seconds (S.T). Every number reproduces from the seeds: the digests are below.

| Arm | Digest |
| :--- | :--- |
| default | `c636302aef231f99` |
| swap | `04b827d2232a6e4c` |
| mirror-villain | `b03bce24a0c61887` |
| mirror-hero | `c1e8d6f147ffda61` |
| default-flip | `c478c831a3a1343b` |
| swap-flip | `6d7f051c40407d10` |
| mirror-villain-flip | `12097c60795d5b66` |
| mirror-hero-flip | `60f24caae6d4b078` |

## Slice S0 re-test

PASS: the Protagonist 51.4% [47.9, 54.8] over both slots (50.5% from P1, 52.3% from P2), 400 matches per arm; the whole interval is at or above 42%. Pacing rows passing: 5; failing: 10.reach, 10.exPerMin, 10.end.launch, 10.end.separating, 10.end.continue, 10.longHaul.

## Bands (`docs/design/balance-targets.md`)

| Status | § | Measure | Value | Band | Note |
| :--- | :--- | :--- | :--- | :--- | :--- |
| PASS | §1 | Protagonist win rate, averaged over both slots (1v1 pairing) | 51.4% [47.9%, 54.8%] | 45.0% to 55.0% | 411 of 800 decided matches |
| PASS | §9 | The Protagonist at least 42% (the placeholder-balance target from slice S0) | 51.4% [47.9%, 54.8%] | 42.0% to 100.0% | the 45 to 55% band applies to the real roster |
| PASS | §1 | mirror-villain: slot effect within ±3 points | +1.4 pts [-2.1 pts, +4.8 pts] | -3.0 pts to +3.0 pts |  |
| PASS | §1 | mirror-villain: spawn-side effect within ±3 points | +0.1 pts [-3.3 pts, +3.6 pts] | -3.0 pts to +3.0 pts |  |
| **FAIL** | §1 | mirror-hero: slot effect within ±3 points | +1.6 pts [-1.8 pts, +5.1 pts] | -3.0 pts to +3.0 pts | point inside the band, interval outside the widened band |
| PASS | §1 | mirror-hero: spawn-side effect within ±3 points | +0.9 pts [-2.6 pts, +4.3 pts] | -3.0 pts to +3.0 pts |  |
| PASS | §2 | Match length median (game, 1v1) | 432.9 s | 360.0 s to 480.0 s |  |
| PASS | §2 | Match length, 10th percentile | 313.1 s | at least 300.0 s |  |
| PASS | §2 | Match length, 90th percentile | 596.1 s | at most 600.0 s |  |
| PASS | §2 | Timeouts at the 900 s cap | 0.0% [0.0%, 1.0%] | at most 1.0% |  |
| PASS | §3 | A fighter reaches tier 3 before the KO | 100.0% [99.0%, 100.0%] | at least 70.0% |  |
| PASS | §3 | A fighter reaches tier 4 before the KO | 94.5% [91.8%, 96.3%] | at least 60.0% |  |
| PENDING | §3 | First transformation timing; the last 60 s has a clash or finisher |  |  | game scale: needs transformations (roster) and finishers (S2) |
| PASS | §4 | Civilians lost at the KO, mean, default arm | 20.06 | 12.00 to 30.00 | % |
| PASS | §4 | Worst pairing's mean civilians lost (swap) | 21.18 | at most 55.00 | % |
| PASS | §4 | Matches losing 90% or more of civilians (default) | 0.0% [0.0%, 1.0%] | at most 10.0% |  |
| PASS | §4 | Matches losing 90% or more of civilians (swap) | 0.0% [0.0%, 1.0%] | at most 10.0% |  |
| PASS | §4 | Matches losing 90% or more of civilians (mirror-villain) | 0.0% [0.0%, 1.0%] | at most 10.0% |  |
| PASS | §4 | Matches losing 90% or more of civilians (mirror-hero) | 0.0% [0.0%, 1.0%] | at most 10.0% |  |
| PASS | §4 | Low-tier bleed: civilians lost per minute while both fighters are at tier 2 or below, % of population (default arm) | 0.29 | at most 4.00 | 3.5 min at low tier per match; includes every source the sim has |
| PASS | §4 | Structures lost at the KO, mean share of row-1 (front-row) structures | 35.79 | 25.00 to 50.00 | % |
| INFO | §4 | Structures lost, all rows (watch metric, not a gate; §21 band 15 to 40%) | 29.7% |  | rows 1, 2, 3 |
| INFO | §4 | Structures lost, row 1 | 35.8% |  |  |
| INFO | §4 | Structures lost, row 2 | 37.2% |  |  |
| INFO | §4 | Structures lost, row 3 | 0.0% |  |  |
| INFO | §4 | Structures wrecked at the KO (stage 3 or 4), all rows, mean share (default arm) | 41.8% |  | 400 matches |
| INFO | §4 | Structures wrecked at the KO, row 1 | 50.8% |  |  |
| INFO | §4 | Structures wrecked at the KO, row 2 | 52.0% |  |  |
| INFO | §4 | Structures wrecked at the KO, row 3 | 0.0% |  |  |
| PENDING | §4 | Civilians left at 4:00: at least 25% alive in at least 80% of matches |  |  | game scale: needs 7-minute matches (Wounds S2) |
| INFO | §4b | Matches with a 60 s window over the tier budget (2%, 4%, 8%, 15%): what the ramp will have to change (default arm) | 23.3% |  | the rolling-window test is pending the ramp World is building (skeleton C1) |
| INFO | §4b | Matches over the cumulative ceiling (10%, 30%, 60%, 90% by highest tier so far) (default arm) | 0.0% |  | the ceiling test is pending the cap World is building (skeleton C2) |
| INFO | §4b | Per-tier split of casualties by the higher tier when they happened (default arm) | tier 1 0%, tier 2 5%, tier 3 31%, tier 4 64% |  | skeleton C3 bands it once the ramp exists |
| PASS | §5 | No launch type above 45% (default): largest is SMASH ACROSS | 10.5% [9.8%, 11.2%] | at most 45.0% | match-clustered upper bound must be at most 47% (M1b re-banding, balance-targets 18) |
| PASS | §5 | Largest launch type's clustered upper bound at most 47% (default) | 11.2% | at most 47.0% |  |
| PASS | §5 | No launch type above 45% (swap): largest is SMASH ACROSS | 10.2% [9.5%, 10.8%] | at most 45.0% | match-clustered upper bound must be at most 47% (M1b re-banding, balance-targets 18) |
| PASS | §5 | Largest launch type's clustered upper bound at most 47% (swap) | 10.8% | at most 47.0% |  |
| PASS | §5 | No launch type above 45% (mirror-villain): largest is SMASH ACROSS | 18.4% [17.5%, 19.2%] | at most 45.0% | match-clustered upper bound must be at most 47% (M1b re-banding, balance-targets 18) |
| PASS | §5 | Largest launch type's clustered upper bound at most 47% (mirror-villain) | 19.2% | at most 47.0% |  |
| PASS | §5 | No launch type above 45% (mirror-hero): largest is SMASH ACROSS | 10.7% [10.0%, 11.5%] | at most 45.0% | match-clustered upper bound must be at most 47% (M1b re-banding, balance-targets 18) |
| PASS | §5 | Largest launch type's clustered upper bound at most 47% (mirror-hero) | 11.5% | at most 47.0% |  |
| PASS | §5 | At least 4 launch types at or above 5% (default arm) | 7.00 | at least 4.00 |  |
| **FAIL** | §5b | Share of all planner launches that are building brunts (4 to 10%; re-based at M1b) | 3.9% [3.4%, 4.5%] | 4.0% to 10.0% |  |
| **FAIL** | §5b | Brunts per minute (0.3 to 1.0, game-scale band; re-based at M1b) | 0.07 | 0.30 to 1.00 |  |
| INFO | §5b | Villain and hero mirror brunt rows | retired |  | retired on the testbed (balance-targets 18); measured per minute: villain mirror 0.07, hero mirror 0.04 |
| PASS | §5b | Launches that pick a building, out of those with a building candidate in reach (35 to 60% pooled) | 42.2% [37.9%, 46.7%] | 35.0% to 60.0% | 490 plans with a candidate; from launch_plan events |
| PENDING | §5b | Chains among brunts, chain lengths, the per-tier casualty budget for one chain (hard test), the launcher tier cap (hard test) |  |  | needs brunt-chain events (World, buildings-in-depth §4b); skeleton in qa/godot/pending-tests.js |
| PASS | §5c | How launches end: halted: the journey ends skidding or tumbling to a stop, with or without bounces first (40 to 60%, the largest class) (per launch) | 40.3% [39.1%, 41.6%] | 40.0% to 60.0% |  |
| PASS | §5c | How launches end: against a wall (a slope steeper than 0.8; 5 to 15%) (per launch) | 14.1% [13.2%, 15.0%] | 5.0% to 15.0% |  |
| PASS | §5c | How launches end: slam: the journey ends in a crater (8 to 18%) (per launch) | 17.7% [16.7%, 18.7%] | 8.0% to 18.0% |  |
| PASS | §5c | How launches end: caught in the air (the follow-up before the journey ends; 15 to 30%) (per launch) | 15.4% [14.4%, 16.3%] | 15.0% to 30.0% |  |
| PASS | §5c | Halted as a share of journeys that end on the ground (halt, wall or slam; at least 55%) | 55.9% [54.5%, 57.3%] | 55.0% to 100.0% |  |
| PASS | §5c | Halted is the largest class (balance-targets 20) | halt 40.3%, wall 14.1%, slam 17.7%, caught 15.4%, water 7.6%, brunt 3.6% | halted largest |  |
| PASS | §5c | Launches with at least one bounce (20 to 40%, balance-targets 23; the boundary is 40 degrees) | 30.3% [29.1%, 31.5%] | 20.0% to 40.0% |  |
| PASS | §5c | First contacts: skids at least as common as bounces | skid or tumble 1641, bounce 840, slam 1118, stop 0 | skids at least bounces |  |
| PASS | §5c | How launches end: water (skim or splash first; 2 to 10%, re-based at §21) (per launch) | 7.6% [6.8%, 8.3%] | 2.0% to 10.0% |  |
| **FAIL** | §5c | How launches end: brunt (a building first; 4 to 10%) (per launch) | 3.6% [3.1%, 4.1%] | 4.0% to 10.0% |  |
| INFO | §5c | Planner launches with no contact and not caught (KO, the cap, launched again first), share of launches | 1.2% |  | a class of its own so the classes add up to 100% |
| INFO | §5c | Planner launches that landed at a stop (a contact under 350, no skid or tumble), share of launches | 0.2% |  | a class of its own; not banded |
| INFO | §5c | Landing mix over every launch event, beam and finisher launches included (not banded) | slide 47.4%, slam 21.4%, caught 8.9%, bounce 0.0%, water 9.2%, brunt 1.8%, none 2.5% |  |  |
| **FAIL** | §5c | Flights off a crater lip a minute, seen (in the air at least 10 ticks; 0.5 to 2.5) | 0.47 | 0.50 to 2.50 |  |
| **FAIL** | §5c | Flights off any terrain a minute, seen (lips, crests, cliffs, heaps; 1.5 to 5) | 0.73 | 1.50 to 5.00 |  |
| PASS | §5c | Journeys that reach the 4 s or 8-contact bound (at most 8%) | 0.0% | at most 8.0% |  |
| PASS | §5c | Journeys longer than 4,000 units (at most 20%; Camera chase rule covers them) | 15.8% | at most 20.0% |  |
| PASS | §5c | Bounces per bounced journey, mean (1.2 to 2.0) | 1.66 | 1.20 to 2.00 |  |
| PASS | §5c | Halted journeys with a tumble that is seen (tumble_end of 18 ticks or more; 30 to 60%) | 34.0% [31.9%, 36.2%] | 30.0% to 60.0% |  |
| PENDING | §5c | Early recoveries as a share of the chances, medium AI (20 to 40%) |  |  | switches on with World G5 (`tech_offer` when the chance opens, `tech` when taken) |
| INFO | §5c | Slides: mean length and trench width; slams per match; water skims per match | 2816 units, 289.7 wide; 21.2 slams; 2.3 skims |  |  |
| PENDING | §5c | Casualties from one slide at most 2% (tier 2 or below), 5% (tier 3), 10% (tier 4); 0 in open country; the planner declines launches over budget (hard tests) |  |  | needs casualties attributed per slide (a slide event with the population lost, or the predicted slide of the planner) and the predicted-vs-actual landing test from Encounter |
| INFO | §10 | Heavies landed and heavy clashes won per minute of match, both fighters (default; Game Design's estimates about 6 and 1.5) | 5.05 and 0.00 |  | per fighter PROTAGONIST/RIVAL: 2.60/2.45 landed; 0.00/0.00 clash wins (slot order) |
| INFO | §10 | Heavies landed and heavy clashes won per minute of match, both fighters (swap; Game Design's estimates about 6 and 1.5) | 5.04 and 0.00 |  | per fighter RIVAL/PROTAGONIST: 2.49/2.56 landed; 0.00/0.00 clash wins (slot order) |
| INFO | §10 | Heavies landed and heavy clashes won per minute of match, both fighters (mirror-villain; Game Design's estimates about 6 and 1.5) | 4.78 and 0.00 |  | per fighter RIVAL-A/RIVAL-B: 2.35/2.44 landed; 0.00/0.00 clash wins (slot order) |
| INFO | §10 | Heavies landed and heavy clashes won per minute of match, both fighters (mirror-hero; Game Design's estimates about 6 and 1.5) | 5.01 and 0.00 |  | per fighter PROTAGONIST-A/PROTAGONIST-B: 2.49/2.52 landed; 0.00/0.00 clash wins (slot order) |
| PASS | §15 | Structures levelled per minute at tier 1, % of all structures (at most 2%) | 0.07 | at most 2.00 | 752 match minutes at this tier |
| PASS | §15 | Structures levelled per minute at tier 2, % of all structures (at most 4%) | 0.61 | at most 4.00 | 628 match minutes at this tier |
| PASS | §15 | Structures levelled per minute at tier 3, % of all structures (2 to 10%) | 4.12 | 2.00 to 10.00 | 719 match minutes at this tier |
| PASS | §15 | Structures levelled per minute at tier 4, % of all structures (6 to 20%) | 9.98 | 6.00 to 20.00 | 849 match minutes at this tier |
| INFO | §14 second pass | Launches a match, the AI against itself, with the match median, the 10th percentile and the civilians lost beside it (6 to 12; the top is 14 if all three hold) | 13.1 a match; median 433 s, 10th percentile 313 s, civilians lost 20.1% |  | 400 default-arm matches; the planner's launch decisions (a beam or finisher launch is in the count) |
| PASS | §11 | Blasts as a share of match damage (10 to 25%, provisional) | 12.0% [11.9%, 12.2%] | 10.0% to 25.0% |  |
| PASS | §11 | Signatures (beams) as a share of match damage (at most 30%, provisional) | 6.6% [6.4%, 6.8%] | at most 30.0% |  |
| **FAIL** | §10 | Damaging melee strikes within 68 units of horizontal reach (hard test, 100%) | 1 of 6225653 strikes beyond 68 units; longest 74.9 | 100% within 68 | lights, heavies and guarded hits, at the damage event, every arm |
| PASS | §10 | A height difference beyond 68 units only on sloped ground (hard test) | 516 strikes with more than 68 units of height difference, 0 of them on flat ground; largest 112.0 | none on flat ground (slope at most 0.15, no ground step between the two) | the slope is read over 80 units at the victim; a ground step between the fighters of half the height difference or more explains it; 1548 follow-up blows on a buried fighter (the dive into the crater) are counted apart |
| PASS | §6 | No biome holds more than 40% of fight time (default): largest is desert | 33.1% | at most 40.0% |  |
| PASS | §6 | Every biome holds at least half its planet share or 3% of fight time, whichever is lower (default arm) | ocean 8.6%, village 14.6%, plains 5.0%, city 4.1%, forest 13.4%, desert 33.1%, mountains 21.1% | see rule |  |
| PASS | §6 | No biome holds more than 40% of fight time (swap): largest is desert | 30.5% | at most 40.0% |  |
| **FAIL** | §6 | No biome holds more than 40% of fight time (mirror-villain): largest is desert | 40.4% | at most 40.0% |  |
| PASS | §6 | No biome holds more than 40% of fight time (mirror-hero): largest is desert | 37.2% | at most 40.0% |  |
| PASS | §6 | No beam variant above 40% of beams: largest is GLASS TRENCH | 35.1% | at most 40.0% |  |
| PASS | §6 | Every beam variant at least 3% of beams (one planet; FIELD SCAR at least 2%, §21) | HORIZON CLEAVE 7.6%, BOULEVARD RAZE 19.8%, FIRESTORM 12.5%, RIDGE BORE 21.0%, GLASS TRENCH 35.1%, FIELD SCAR 3.9% | at least 3.0% each (SCAR 2.0%) |  |
| PENDING | §6 | Location and variant bands over a fixed set of at least 20 seeded planets |  |  | the sim has one planet (W1: variable circumference / procedural planets) |
| INFO | §7 | Parries per 100 melee exchanges | retired |  | the parry window was replaced by the perfect block in step 3 (ADR 0008); the perfect-block rows below carry the band. Measured parries: 0.00 |
| PASS | §7 | Perfect blocks a minute, medium AI (1 to 4; Game Design, melee-press-feel 9f) | 3.04 | 1.00 to 4.00 |  |
| INFO | §7 | Perfect blocks per 100 melee exchanges, medium AI (the old basis, reported; 5 to 15 before the brawl) | 47.06 |  | a brawl is one exchange of many blows; the rows above and below read it a minute and per 100 blows |
| INFO | §7 brawl | Perfect blocks per 100 blows thrown in brawls (the brawl basis; proposed band to be set by Game Design) | 1.04 |  | 8923 perfect blocks over 854957 blows; the per-exchange row above reads 47.06 |
| INFO | §10 brawl | Brawls a minute, blows a minute, closes a minute (flurry staggers), heavy staggers a minute, trade breaks a minute | 2.8, 291.1, 1.3, 4.2, 1.6 |  | proposed basis for "exchanges started a minute": brawls and strings, not exchanges of the old kind |
| INFO | §10 brawl | Median brawl length and blows (B5: 6 to 12 s and 10 blows or more; the share of fight time in a brawl 45 to 60%) | 6.8 s and 77 blows; 41.6% of fight time |  | 8026 brawls in 400 matches (live ticks; 90th percentile 20.3 s) |
| PASS | §9f | Share of fight time in a brawl, the AI against itself (30 to 50%; until the zip the demo target is 25%) | 41.6% | 30.0% to 50.0% |  |
| INFO | §10 brawl | How brawls end, as shares of brawls (the basis for "knock-backs" and "continues": a brawl continues until it ends; the 25 to 35% and 40 to 50% bands read against launch decisions) | signature 44.7%, launch 19.8%, knockback 18.6%, idle 11.7%, break 5.0%, double 0.2% |  | 8026 brawl endings |
| INFO | §2c | Zips a minute, and by kind | 0.27 a minute (564 strikes, 241 heavies over 805) |  | 400 matches |
| PASS | §2c | Zips whose blow lands clean, against an opponent who answers (35 to 55%) | 43.6% [40.2%, 47.1%] | 35.0% to 55.0% |  |
| **FAIL** | §2c | Zips countered by a tech or heavy strike (10 to 25%) | 26.8% [23.9%, 30.0%] | 10.0% to 25.0% |  |
| PASS | §2c | Zips that end with the zipper caught (20 to 35%) | 32.4% [29.3%, 35.7%] | 20.0% to 35.0% |  |
| PASS | §2c | Ki spent on zips, as a share of all ki spent (at most 25%) | 2.0% | at most 25.0% |  |
| INFO | §2c | Zips reported: blocked, dodged (a zip that completed and did no damage), stopped by a shot, outrun, knocked down, and every end | blocked 15.4%, dodged 8.1%, stopped by a shot 7.3%, outrun 2.6%, down 0.0%; ends {"caught":261,"done":248,"stopped":34,"countered":216,"shot":25,"outrun":21} |  | 805 zips in 400 matches |
| PASS | §2c | A zip costs exactly the table ki, paid at the press (hard test) | 805 of 805 on the table (read from the ki a tick later: within 0.5) | strike 20, heavy 30 | read as the ki the zipper held the tick before the cue less the ki after it (within 0.5, the regeneration of one tick); records made before the harness read the director line |
| PASS | §2c | A zip tell is the table ticks and its whole length is in the table range for the default exit (hard test; the ticks in reach are the zip.reach row) | 805 of 805 on the table | strike tell 6, whole 32 to 34; heavy tell 10, whole 52 to 54 (up to 12 more for a longer exit) | the tell and the whole length; the ticks in reach are read from the cues in the next row |
| PASS | §2c | The ticks in reach before and after the blow are exactly the table: strike 4 and 6 (8 before when held), heavy 12 and 10 (4 off a rushed tap, two at most) (hard test) | 534 played zips and 805 plans on the table | strike 4 and 6 (held 8 before); heavy 12 and 10 | the plan is read at the press; the played ticks at zip_out. A zip countered or caught before its blow has no zip_out and is not read. The zip away shapes (4 and 4, 6 and 8) are accepted |
| PASS | §2c | Travel is never under the floor, each way: at least max(4, ceil(distance in bh / 3)) ticks (Legal RL-076, a hard test) | 805 of 805 at or over the floor | at least max(4, ceil(bh / 3)) ticks | the way in is the cue n over the start distance; the way out is zip_out n over the path from the zipper to the exit point |
| PASS | §2c | No stick exit over 12.5 bh from the rival or inside the ground or a building; the home exit is exempt (hard test) | 115 exits checked (690 home) | at most 12.5 bh, never inside | inside is World blockedAt at the exit point with no margin |
| PASS | §2c | No brawl is announced during a zip unless the zipper is caught or countered (hard test) | 0 over 805 zips | never | a brawl_start while the zip is open whose text is not caught or countered |
| INFO | §2c | The dropped state: drop_start, drop_land and drop_end (reported; every start should land and end, apart from a KO in the air) | 0 starts, 0 lands, 0 ends |  | 400 matches |
| INFO | §7 second pass | Double hits a match, the AI against itself (reported; the band 0.5 to 2 is for a presser against the medium AI: the double.presser rows) | 0.04 |  | 400 matches; none is in order between AIs (no level trade lasts 240 ticks) |
| INFO | §7 second pass | Matches with at least one double hit, the AI against itself (reported) | 4.0% (16 of 400) |  | the band 35 to 65% is for a presser against the medium AI |
| PASS | §7 second pass | Never more than 4 double hits in one match (hard test) | the most in one match is 1 | at most 4 | 400 matches |
| PASS | §7 second pass | Every double_hit cue ends its brawl with the text double, and every double end follows a cue (hard test; a KO in the 8 ticks between may cost one) | 16 cues, 16 double ends | equal (within 2%) |  |
| PASS | §7 second pass | Every double hit comes from a trade level for 240 ticks (hard test: the cue's dur, the trade's length, is 240 to 244) | 16 of 16 at 240 to 244 | 240 to 244 | a hit freeze may add a tick or two |
| PASS | §7 second pass | Both fighters are hit by a double hit (hard test) | 16 of 16 hit both | both take damage on the landing tick | damage events on the landing tick and the next, by victim |
| INFO | §7 second pass | The double hit: damage to each and the separation 30 ticks after the landing (reported; the rule: 4 brawl lights each, thrown back 6 bh each way, so about 12 bh apart from the centre) | 35.9 and 35.6 damage; apart 0.8 bh at the throw, 6.3 bh after 30 ticks |  | 16 double hits |
| INFO | §7 second pass | Perfect blocks per 100 blows by strength (reported; held as bands after the first three-strength baseline: lights 0.5 to 1.5, mediums 2 to 6, heavies 6 to 15 at medium) | no perfect block carries its strength on this build (the stagger source) |  | 400 matches; the total per 100 blows is retired as a band |
| PASS | §5b | Energy blows as a share of the AI's brawl blows (5 to 15%) | 8.5% | 5.0% to 15.0% |  |
| PASS | §1 second pass | The AI winds up or charges a medium or a heavy, a minute of brawl, per fighter (4 to 10; an AI-against-AI match has two fighters, so the total is counted twice: 14.3 in all) | 7.15 | 4.00 to 10.00 |  |
| PASS | §7 | Chains per 100 melee exchanges (10 to 30, agency pass 14; strings now come from the presses) | 15.71 | 10.00 to 30.00 |  |
| PASS | §7 | Pursuit slip rate (escape gamble) | 43.4% [41.4%, 45.4%] | 35.0% to 65.0% |  |
| PASS | §7 | Beam escape rate against an ESCAPE defender | 25.2% [20.7%, 30.2%] | 20.0% to 50.0% |  |
| PENDING | §7 | Fixed-stance round robin: no forced stance above 55%, each stance below 45% against some other |  |  | needs the stance probe of stance-matrix.md §6 (two role-neutral fighters, one stance forced): not in the sim yet |
| INFO | §8 | Hides and ambushes | retired |  | hiding is removed from the base game and kept for a future stealth fighter (balance-targets §8); the rows return with that fighter (canHide) |
| PENDING | §13 | Signatures fired per match (2 to 4, median 3) | today 12.0 (median) | 2 to 4 | pending Q4: the 120 s signature cooldown is not in the sim yet |
| PASS | §8 | Beam clashes: share of signatures fired that end in a CLASH (30 to 60%; re-based at G0) | 40.5% [39.2%, 41.7%] | 30.0% to 60.0% |  |
| PASS | §1c | No lock break longer than 4 s, all arms (hard test) | longest 4.02 s (default seed 34 from 608.0 s); 0 over 4 s of 7121 | at most 4 s | GB-008: sim/director/launch.gd:316 and sim/core/fighter.gd:319 clear `hidden` with no regainLock, so no `found` is emitted and the episode stays open |
| PASS | §1c | Lock breaks per match (1 to 4) | 2.42 | 1.00 to 4.00 |  |
| **FAIL** | §1c | Median lock-break length (2 to 3 s) | 1.3 s | 2.0 s to 3.0 s |  |
| PASS | §1c | No lock break longer than 4 s (hard test) | longest 4.02 s over 969 breaks | at most 4 s | episodes are read from searching and found events; a hunt sweep with no lock loss can lengthen one |
| PASS | §1c | Never within 6 s of the same fighters last one (hard test) | shortest gap 6.90 s over 503 | at least 6 s |  |
| INFO | §1c | Attacks refused for lost lock (lock_lost) per match | 0.13 |  |  |
| PASS | §8 | Brink to KO, median (45 to 90 s) | 73.6 s | 45.0 s to 90.0 s |  |
| PASS | §8 | First brink, median (4:30 to 7:00) | 336.5 s | 270.0 s to 420.0 s |  |
| PASS | §8 | Finisher survival rate (25 to 40%) | 31.0% [27.4%, 34.9%] | 25.0% to 40.0% |  |
| PASS | §8 | Rallies per match (0.3 to 0.7) | 0.37 | 0.30 to 0.70 |  |
| PASS | §8 | Region breaks per match (1.5 to 2.5) | 2.23 | 1.50 to 2.50 |  |
| PASS | §8 | Limb breaks per match (0.3 to 0.5) | 0.44 | 0.30 to 0.50 |  |
| PASS | §8 | Arms share of limb breaks (35 to 65%; legs is the rest) | 46.9% | 35.0% to 65.0% |  |
| **FAIL** | §8 | Second breath: battered wear recovered through it, as a share of all battered wear taken (at most 25%) | 44.0% | at most 25.0% |  |
| INFO | §10 k | Damage per minute to the loser (input to the k retune: k_new = k_old x rate before / rate after) | 1730.1 |  | volleys and beam-clash chip count once Encounter Q4 lands, so k absorbs them; median length target 6 to 8 min, p10 at least 5:00, timeouts at most 1% |
| PENDING | §8 | Blitz rate: 2 to 6 a minute in Tense and Frenzied acts |  |  | needs a `blitz` fx event and the act (mood) per event (Encounter Q4) |
| PENDING | §8 | Comebacks 15 to 35% of matches; lead changes median at least 2 |  |  | needs the brink and region stages (Wounds S1, S2) |
| PASS | §9 | Mood: Calm share of match time (20 to 40%, re-based for the brawl, spec-wounds §9) | 30.7% | 20.0% to 40.0% |  |
| PASS | §9 | Mood: Tense share of match time (40 to 65%, re-based for the brawl, spec-wounds §9) | 57.6% | 40.0% to 65.0% |  |
| PASS | §9 | Mood: Frenzied share of match time (5 to 20%) | 11.7% | 5.0% to 20.0% |  |
| PASS | §9 | Calm share of act 1 (at least 60%) | 74.7% | at least 60.0% |  |
| PASS | §9 | Frenzied share of act 4, the climax (at least 15%) | 19.2% | at least 15.0% |  |
| PASS | §9 | Act 2 starts at, median (1:30 to 2:30) | 111.6 s | 90.0 s to 150.0 s |  |
| PASS | §9 | Act 3 starts at, median (2:30 to 4:00) | 195.9 s | 150.0 s to 240.0 s |  |
| PASS | §9 | Act 4 starts at, median (4:30 to 5:45) | 304.8 s | 270.0 s to 345.0 s |  |
| **FAIL** | §9 | Act 4 arrives before the first brink (at least 80% of matches with a brink) | 63.2% [58.4%, 67.8%] | at least 80.0% |  |
| PASS | §9 style | Style label entries per fighter per match, median (at most 3; AI play) | 1.00 | at most 3.00 |  |
| PASS | §9 style | Style label events per fighter per match, entries and endings, median (at most 5) | 2.00 | at most 5.00 |  |
| PASS | §9 style | Shortest label held (at least 12 s; a label cut off by the KO is not counted) | 30.0 s | at least 12.0 s |  |
| PASS | §9 style | Unlabelled share of match time, mean (at most 40%) | 16.2% | at most 40.0% |  |
| **FAIL** | §10 | Exchanges started per minute (15 to 28, agency pass 14) | 8.17 | 15.00 to 28.00 |  |
| INFO | §10 | Exchange length, request to release, median | retired |  | retired by the dynamic feel (G0 triage); the feel rows replace it. Measured: 1.37 s |
| INFO | §10 | Breathing room, release to the next request, median | retired |  | replaced by the feel row release to next request at most 1.0 s. Measured: 1.33 s |
| PASS | §10 | Matches with no gap over 10 s (a gap: no strike, blast, charge or taunt from either fighter) | 99.0% [97.5%, 99.6%] | at least 95.0% |  |
| **FAIL** | §10 | Exchanges that end in a launch, of those that reach a launch decision (18 to 30%, agency pass 14) | 30.3% [29.6%, 31.0%] | 18.0% to 30.0% |  |
| PASS | §10 | Exchanges that end in a knock-back, of those that reach a launch decision (25 to 35%, agency pass 14) | 30.3% [29.6%, 31.1%] | 25.0% to 35.0% |  |
| **FAIL** | §10 | Launches as a share of the exchanges that separate the fighters (a knock-back or a launch; 25 to 40%, around Orb 30) | 50.0% [49.0%, 50.9%] | 25.0% to 40.0% |  |
| **FAIL** | §10 | Exchanges after which the brawl continues (STAY), of those that reach a launch decision (40 to 50%) | 39.4% [38.6%, 40.2%] | 40.0% to 50.0% |  |
| INFO | §10 | Melee exchanges: reach a launch decision / of those launch, knock-back, stay | 50.0% reach one; 30.3% / 30.3% / 39.4% |  | the rest end with no launch decision (a light string that never reaches a launch beat) |
| INFO | §10 | Launches as a share of exchanges, planner launches over all exchanges (old row, band 40 to 65% retired by agency pass section 3) | 21.9% |  | the standing row is 10.end.launch |
| **FAIL** | §10 | Launches with at least 9,000 units of horizontal travel (1,500 x the launch traversal factor) | 29.8% | at least 30.0% |  |
| PASS | §10 | Launches that land in a different biome | 47.1% | at least 25.0% |  |
| PASS | §10 | Fight time underwater (both fighters) | 0.6% | at most 10.0% |  |
| PENDING | §10 | Strike spacing, wind-up width, hit-stop floors, gap-close flight |  |  | read from data and atoms, not from a batch: Combat and Controls own them (needs the event log of the composer) |
| PASS | §11 | Low-tier bleed with every living-destruction source included (same measure as §4) | 0.29 | at most 4.00 | % of population per minute |
| PENDING | §11 | Spreading fires: 0.5 to 3 in matches with 5% of fight time in forest or villages |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Forest burnt at the end among tier-3 matches: 15 to 60% of trees |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Cover-capable clouds 3 to 10 |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Real slides 0.5 to 2; at most 1 peak collapse |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Quakes in 30 to 70% of tier-4 matches, at most 2; rifts at most 1 |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Lava events 1 to 3 in tier-4 matches |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Hazard share of all wear at most 15% |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PASS | §7 | Perfect blocks a minute, easy AI (0.5 to 2; Game Design, melee-press-feel 9f) | 1.97 | 0.5 to 2 | 100 default-arm matches at easy; point estimate; per 100 blows 0.69 |
| INFO | §7 | Perfect blocks per 100 melee exchanges, easy AI (the old basis, reported; 3 to 8 before the brawl) | 28.44 |  | 100 default-arm matches at easy |
| **FAIL** | §7 | Perfect blocks a minute, hard AI (2 to 5.5; Game Design, melee-press-feel 9f) | 5.86 | 2 to 5.5 | 100 default-arm matches at hard; point estimate; per 100 blows 4.34 |
| INFO | §7 | Perfect blocks per 100 melee exchanges, hard AI (the old basis, reported; 12 to 20 before the brawl) | 56.97 |  | 100 default-arm matches at hard |

## Masher stage rows (`qa/godot/masher-only.js`, 61 jobs)

| Status | Id | Measure | Value | Band | Note |
| :--- | :--- | :--- | :--- | :--- | :--- |
| PASS | masher.easy | The banded masher (masher.gd: a human slot that presses light on every 8th S.tick by the absolute count; 8 S.ticks, takes forms) wins against the easy AI | 95.0% (95 of 100) | at least 60% | 100 matches, 0 timed out, median 175 s; point estimate only; per match: launches by the masher 3.49, of which air catches 0.18; launches on the masher 5.62, air catches 0.35 |
| PASS | masher.medium | The banded masher (masher.gd: a human slot that presses light on every 8th S.tick by the absolute count; 8 S.ticks, takes forms) wins against the medium AI | 35.0% (35 of 100) | 35 to 50% | 100 matches, 0 timed out, median 199.9 s; point estimate only; per match: launches by the masher 2.4, of which air catches 0.17; launches on the masher 7.96, air catches 0.61 |
| PASS | masher.hard | The banded masher (masher.gd: a human slot that presses light on every 8th S.tick by the absolute count; 8 S.ticks, takes forms) wins against the hard AI | 0.0% (0 of 100) | at most 15% | 100 matches, 0 timed out, median 212.2 s; point estimate only; per match: launches by the masher 1.52, of which air catches 0.29; launches on the masher 16.84, air catches 1.59 |
| INFO | masher.noforms.easy | The banded masher (masher.gd: a human slot that presses light on every 8th S.tick by the absolute count; 8 S.ticks, no forms) wins against the easy AI | 81.0% (81 of 100) | (at least 60% if forms are taken) | 100 matches, 0 timed out, median 178.9 s; point estimate only; a beginner who never transforms fights at tier 1 (Game Design to rule); per match: launches by the masher 3.05, of which air catches 0.13; launches on the masher 6.21, air catches 0.42 |
| INFO | masher.noforms.medium | The banded masher (masher.gd: a human slot that presses light on every 8th S.tick by the absolute count; 8 S.ticks, no forms) wins against the medium AI | 26.0% (26 of 100) | (35 to 50% if forms are taken) | 100 matches, 0 timed out, median 201.7 s; point estimate only; a beginner who never transforms fights at tier 1 (Game Design to rule); per match: launches by the masher 2.13, of which air catches 0.17; launches on the masher 8.32, air catches 0.61 |
| INFO | masher.noforms.hard | The banded masher (masher.gd: a human slot that presses light on every 8th S.tick by the absolute count; 8 S.ticks, no forms) wins against the hard AI | 0.0% (0 of 100) | (at most 15% if forms are taken) | 100 matches, 0 timed out, median 206.6 s; point estimate only; a beginner who never transforms fights at tier 1 (Game Design to rule); per match: launches by the masher 1.17, of which air catches 0.19; launches on the masher 16.33, air catches 1.75 |
| INFO | masher.medium.g6 | The banded masher (masher.gd: a human slot that presses light on every 6th S.tick by the absolute count; 6 S.ticks, takes forms) wins against the medium AI | 80.0% (80 of 100) | 35 to 50% | 100 matches, 0 timed out, median 193.6 s; point estimate only; per match: launches by the masher 3.36, of which air catches 0.21; launches on the masher 6.66, air catches 0.62 |
| INFO | masher.medium.g10 | The banded masher (masher.gd: a human slot that presses light on every 10th S.tick by the absolute count; 10 S.ticks, takes forms) wins against the medium AI | 2.0% (2 of 100) | 35 to 50% | 100 matches, 0 timed out, median 195.1 s; point estimate only; per match: launches by the masher 1.43, of which air catches 0.05; launches on the masher 8.69, air catches 0.59 |
| PASS | masher.bolt.finish | A bolt-only player (energy held, a bolt every 8 ticks) finishes the match against a melee masher before the cap (agency pass 16: at least 95%) | 100.0% (40 of 40; 0 ran to the cap) | at least 95% | median 129.6 s; point estimate |
| PASS | masher.bolt.medium | A bolt-only player wins against the medium AI (agency pass 16: 20 to 40%) | 40.0% (40 of 100) | 20 to 40% | 100 matches, 0 ran to the cap; point estimate |
| **FAIL** | masher.blast.rush | A blast-heavy timed script (a bolt about every 14 ticks) against a rush-heavy timed script (agency pass 15.6: 40 to 60%, and at least 95% of matches finish) | 100.0% (40 of 40); 100% finished | 40 to 60%, finish at least 95% | 40 matches, 0 ran to the cap; point estimate |
| **FAIL** | masher.blast.rushslow | The slow blaster (L L and a tapped H, one press every 24 ticks) against a rush-heavy timed script: at least 95% of matches finish before the cap (slice 12 is meant to fix this; 40 to 60% for the win share) | 100.0% (27 of 27); 68% finished | 40 to 60%, finish at least 95% | 40 matches, 13 ran to the cap; point estimate |
| INFO | masher.zip.medium | A player who only zip strikes (LT then a light, in the mid band) against the medium AI (reported) | 0.0% (0 of 100); 928 zips in 100 matches, ends {"caught":92,"countered":145,"done":480,"outrun":6,"shot":82,"stopped":123} | reported | 100 matches, 0 ran to the cap |
| **FAIL** | masher.blast.medium | A mixed blaster (a bolt about every 14 ticks, a tapped heavy now and then) wins against the medium AI (agency pass section 22: 30 to 50%) | 63.0% (63 of 100) | 30 to 50% | 100 matches, 0 ran to the cap; point estimate |
| INFO | masher.blast.slowmedium | The slow blaster (L L and a tapped H, one press every 24 ticks) wins against the medium AI (reported; the band of the mixed blaster, 30 to 50%, is the reference) | 12.0% (12 of 100) | (25 to 45%) | 100 matches, 0 ran to the cap; point estimate |
| INFO | c1.drift.one | How far a held stick moves a brawl, after its ramp: one fighter holds east, the other none (reported, bh a second; the design is 0.4 of free-flight speed for one stick and 0.8 for two) | 2.296 bh a second along the stick; 1143 drifts | reported | largest step 0.046 bh a tick |
| **FAIL** | c1.centre.latency | The centre moves at all within 2 live ticks of a stick (hard test; it answers on the tick after the stick is first read, small at first; the striking state, a lights mash) | 99.9% of 1143 drifts moved within 2 live ticks; histogram {"1":229,"2":913,"999":1} (999 means it never moved) | at most 2 ticks | 1143 drifts; read from DirBrawl.centre velocity when it has one, else from a step over 0.15 units; the other states (charging, guarding, reeling) are for the C2 slices |
| PASS | c1.centre.step.one | The nudge never moves the pair more than 0.3 bh in a tick (hard test, read on the centre's speed, every tick of every brawl in this run: one stick; the pair's middle jumping because a strike placed its attacker is reported beside it) | 0 of 309572 brawl ticks over; the fastest 0.058 bh a tick. Reported: the middle moved over 0.3 bh on 0 of 229265 ticks, the largest 0.287 bh | at most 0.3 bh a tick | 60 matches |
| **FAIL** | c1.dead | No live tick of a brawl with a dead stick, outside a knock-back and its kind (hard test; states reached: striking and mashing, staggered, reeling; the wind-up, charge and guard states come with C2a and C2b) [a lights masher holding east against a rival with no stick] | 627 dead ticks of 299678 held LIVE ticks (0.2%); a further 155442 held ticks fell in a hit freeze and are not counted; by direction {"east":"627 of 299678"}; by state {"locked":627}; by cause {"ground":344,"other":280,"stun":3} | none | 60 matches; before C1 this is the lock itself (every held tick of a locked fighter is dead; 12,369 of 15,323 on 53d13b55 in a 2-match smoke); a fighter against a building face or the ground also stops, which this read cannot tell from a dead stick: look at the states first |
| **FAIL** | c1.dead.ai | No live tick of a brawl with a dead stick, outside a knock-back and its kind (hard test; states reached: striking and mashing, staggered, reeling; the wind-up, charge and guard states come with C2a and C2b) [a presser holding toward against the medium AI] | 823 dead ticks of 419821 held LIVE ticks (0.2%); a further 213710 held ticks fell in a hit freeze and are not counted; by direction {"toward":"823 of 419821"}; by state {"locked":823}; by cause {"building":4,"ground":197,"other":599,"stun":23} | none | 60 matches; before C1 this is the lock itself (every held tick of a locked fighter is dead; 12,369 of 15,323 on 53d13b55 in a 2-match smoke); a fighter against a building face or the ground also stops, which this read cannot tell from a dead stick: look at the states first |
| PASS | c1.aihold | The medium AI holds its own stick against a player's held stick on under 25% of the ticks he holds it (DirBrawl.stick) | 20.5% (5140 of 25051 ticks) | under 25% | 419 drifts against the AI |
| PASS | c1.aistick | A held stick against the medium AI moves the brawl at least 0.7 as far as against a rival who holds no stick (the AI holds against it on under 25% of the ticks: that read needs the AIs stick on a cue) | 0.96 (2.193 bh a second against the medium AI, 2.296 against a rival with no stick) | at least 0.7 | 419 drifts against the AI and 1143 against the script; point estimates |
| INFO | c1.drift.both | How far a held stick moves a brawl, after its ramp: both hold east (reported, bh a second; the design is 0.4 of free-flight speed for one stick and 0.8 for two) | 4.332 bh a second along the stick; 2242 drifts | reported | largest step 0.089 bh a tick |
| PASS | c1.centre.step.both | The nudge never moves the pair more than 0.3 bh in a tick (hard test, read on the centre's speed, every tick of every brawl in this run: two sticks; the pair's middle jumping because a strike placed its attacker is reported beside it) | 0 of 307625 brawl ticks over; the fastest 0.089 bh a tick. Reported: the middle moved over 0.3 bh on 0 of 228145 ticks, the largest 0.285 bh | at most 0.3 bh a tick | 60 matches |
| PASS | c1.walk.both | Both fighters hold away within 45 degrees: the brawl ends walk, never sooner than 12 ticks after the later stick (hard test; free, nobody decisive) | 14140 walk ends in 14140 brawls where both sticks were away (100%); 0 came under 12 ticks after the later stick or the jab; the shortest was 17 ticks and the longest 24 | never under 12 ticks; the walk must happen | 60 matches; the other ends of those brawls: {"break":2} |
| PASS | c1.walk.jab | A blow thrown by either fighter in the 12 ticks starts the count again: the end comes at least 12 ticks after the blow press (hard test) | 12082 walk ends in 12091 brawls where both sticks were away (100%); 0 came under 12 ticks after the later stick or the jab; the shortest was 17 ticks and the longest 24 | never under 12 ticks; the walk must happen | 60 matches; the other ends of those brawls: {"break":13} |
| PASS | c1.walk.guard | The 12 ticks count while either guards: both walk with guards held, and the brawl still ends walk, never early (hard test) | 14358 walk ends in 14358 brawls where both sticks were away (100%); 0 came under 12 ticks after the later stick or the jab; the shortest was 15 ticks and the longest 23 | never under 12 ticks; the walk must happen | 60 matches; the other ends of those brawls: {"break":1} |
| PASS | c1.walk.held | The 12 ticks do not count while an attack button is held: one fighter holds the light button while both hold away, and no walk end comes (hard test) | 0 walk ends in 60 matches (7240 brawls; 7182 with both sticks away) | none | a brawl that ends for any other reason is not counted |
| PASS | c1.walk.one | One fighter alone cannot end a brawl by walking: the other keeps mashing, and no walk end comes (hard test) | 0 walk ends in 60 matches (128 brawls; 0 with both sticks away) | none | a brawl that ends for any other reason is not counted |
| PENDING | zip.drop.bolt | A real bolt that reaches the zipper on the way out drops him: zip_end down, then drop_start, drop_land, drop_end, and the state dropped between (hard test) | no bolt reached a zipper on the way out in 100 matches (168 zips; ends {"done":47,"shot":121}): a coverage gap, not a pass | every down is a drop | the turret presses a bolt on each tick of the way out and after the blow, with chance 50% |
| PASS | zip.drop | A shot reported on the way out (DirZip.shot, the way the module check does) drops the zipper: zip_end down, then drop_start, drop_land, drop_end, and the state dropped between (hard test) | 178 zips ended down; 178 drop_start, 3 drop_land, 178 drop_end; the state was not dropped at 0 starts and still dropped at 0 ends | one drop_start and one drop_end for every down, the state dropped between; drop_land at most one each (a drop that began on the ground may have no land: reported) | 100 matches, 178 zips; ends {"down":178} |
| PASS | double.presser.max.lights | Never more than 4 double hits in a match for a steady presser against the medium AI (hard test; X every 8 ticks, stick toward) | the most in one match is 2 (mean 2.00) | at most 4 | 100 matches |
| **FAIL** | double.presser.lights | Double hits against the medium AI by a lights-only presser (stick toward): a match, and matches with at least one (0.5 to 2; 35 to 65%) | 2.00 a match; 100.0% of matches (100 of 100); 200 double hits | 0.5 to 2; 35 to 65% | 100 matches; measured on C1 at 0.3 and 0.2, tuned on C2a by the AI's digIn; the trade length on the cue is the double.trade240 row |
| PASS | double.presser.max.mix | Never more than 4 double hits in a match for a steady presser against the medium AI (hard test; L L H, stick toward) | the most in one match is 0 (mean 0.00) | at most 4 | 100 matches |
| PENDING | double.presser.mix | Double hits against the medium AI by a mixing presser (L L H, stick toward): a match, and matches with at least one (0.5 to 2; 35 to 65%) | 0.00 a match; 0.0% of matches (0 of 100); 0 double hits | 0.5 to 2; 35 to 65% | 100 matches; measured on C1 at 0.3 and 0.2, tuned on C2a by the AI's digIn; the trade length on the cue is the double.trade240 row |
| **FAIL** | masher.str-y | a Y masher (a medium every 12 ticks) against the medium AI (20 to 50%: no single button mashed should beat medium more than half the time, and none should be shut out) | 3.0% (3 of 100); 0 ran to the cap | 20 to 50% | 100 matches; blows {"blast":21,"bolt":5693,"heavy":1087,"light":73261,"medium":48391,"release":1} |
| **FAIL** | cell.y.mashed | Y mashed (a Y every 12 ticks), alone against the medium AI (20 to 50%) | 3.0% (3 of 100) | 20 to 50% | the same read as masher.str-y, under the nine-cell id |
| PASS | masher.str-b | a B masher (a heavy every 30 ticks) against the medium AI (20 to 50%: no single button mashed should beat medium more than half the time, and none should be shut out) | 40.0% (40 of 100); 0 ran to the cap | 20 to 50% | 100 matches; blows {"blast":13,"bolt":3097,"heavy":25909,"light":34859,"medium":23332} |
| PASS | cell.b.mashed | B mashed (a B every 30 ticks), alone against the medium AI (20 to 50%) | 40.0% (40 of 100) | 20 to 50% | the same read as masher.str-b, under the nine-cell id |
| PASS | closing.d | A blow lands d ticks later than its own time, d from 0 to 4 (2 ticks a bh of gap, at most 4): the cue's landing tick less the press tick, less the wind-up (hard test; the exact formula is checked when the gap's definition is confirmed) | 0 of 400 outside 0 to 4; the largest d 4 | 0 to 4 ticks | samples [wind-up, ticks to landing, gap bh]: [[2,6,2.51],[12,12,0.77],[28,28,0.77],[12,12,0.77],[28,28,0.77],[12,13,0.77]] |
| PASS | closing.step | No blow moves its attacker more than 0.6 bh in a tick (hard test from C2t; reported before it) | 0 of 125829 blows moved their attacker over 0.6 bh in the tick; the most 0.599 bh | at most 0.6 bh a tick | 100 matches |
| INFO | masher.str-alt | the alternator (X, Y, B in turn, a press every 12 ticks) against the medium AI (reported; the X masher's 35 to 50% is kept) | 9.0% (9 of 100); 0 ran to the cap | reported | 100 matches; blows {"blast":28,"bolt":5804,"heavy":15246,"light":78858,"medium":27019,"release":5} |
| **FAIL** | cell.mix.alone | The three mashed in turn (X, Y, B, a press every 12 ticks), alone against the medium AI (30 to 55%: it takes no thought, and should not beat medium this often) | 9.0% (9 of 100) | 30 to 55% | 100 matches |
| **FAIL** | masher.str-holdx | the player who only holds X (60 ticks down, 8 up) against the medium AI (10 to 35%: Game Design, third round) | 0.0% (0 of 100); 0 ran to the cap | 10 to 35% | 100 matches; blows {"blast":25,"bolt":6091,"heavy":1438,"light":140335,"medium":1089,"release":16} |
| **FAIL** | cell.x.held | X held down, alone against the medium AI (10 to 35%) | 0.0% (0 of 100) | 10 to 35% | the same read as masher.str-holdx, under the nine-cell id |
| INFO | masher.str-x10b | the 10-tick tapper with B (X X B) against the medium AI (reported; the X masher's 35 to 50% is kept) | 25.0% (25 of 100); 0 ran to the cap | reported | 100 matches; blows {"blast":22,"bolt":6110,"heavy":24209,"light":106027,"medium":11641,"release":3} |
| **FAIL** | flurry.xy | The X flurry beats the Y flurry (it lands twice as many blows) (60 to 90%: two fixed rhythms give nearly the same result every time, and a lock at 100% leaves the loser nothing) | 100.0% (100 of 100) | 60 to 90% | 100 matches, the second player on a seeded offset of 0 to 7 ticks; point estimate (about ±10 points) |
| **FAIL** | flurry.yb | The Y flurry beats the B flurry (a medium lands inside the 20 ticks in which a heavy can be stopped) (60 to 90%: two fixed rhythms give nearly the same result every time, and a lock at 100% leaves the loser nothing) | 98.0% (98 of 100) | 60 to 90% | 100 matches, the second player on a seeded offset of 0 to 7 ticks; point estimate (about ±10 points) |
| **FAIL** | flurry.bx | The B flurry beats the X flurry (lights do not stop a heavy) (60 to 90%: two fixed rhythms give nearly the same result every time, and a lock at 100% leaves the loser nothing) | 42.1% (32 of 76) | 60 to 90% | 100 matches, the second player on a seeded offset of 0 to 7 ticks; point estimate (about ±10 points) |
| **FAIL** | cell.y.held | Y held to its flash and let go, again and again, alone against the medium AI (10 to 40%) | 0.0% (0 of 100); 0 ran to the cap | 10 to 40% | 100 matches; the charged medium is not built (a held Y goes by itself at 16 ticks at a tap strength), so this reads the trap |
| PASS | cell.b.held | B held to its flash and let go, again and again, alone against the medium AI (15 to 45%) | 24.0% (24 of 100); 0 ran to the cap | 15 to 45% | 100 matches; the charge from 32 ticks, full at 44, a launch at full |
| INFO | masher.pair.medium | The pair masher (players.gd masher: a press when 8 S.ticks have passed since its last press was consumed, forms taken) against the medium AI (reported; the band 35 to 50% is the banded masher's, masher.medium) | 35.0% (35 of 100) | reported | 100 matches; the route player is read against this masher |
| **FAIL** | route.easy | The launcher's route launches in 70 to 90% of the brawls it is tried in against the easy AI (launches by the route's player over brawls) | 65.8% (716 launches in 1088 brawls); route player wins 89.0% | 70 to 90% | 100 matches; an approximation: launches, not brawls with a launch |
| PASS | route.every.easy | From a stagger of 12 ticks or more a tapped B lands and launches, every time (hard test), against the easy AI | 413 launchers used and 0 lapsed by the route's player; 716 launches by him | none lapsed, a launch for each | 588 launcher_open cues in 100 matches |
| PASS | route.medium | The launcher's route launches in 50 to 75% of the brawls it is tried in against the medium AI (launches by the route's player over brawls) | 72.3% (925 launches in 1279 brawls); route player wins 13.0% | 50 to 75% | 100 matches; an approximation: launches, not brawls with a launch |
| PASS | route.every.medium | From a stagger of 12 ticks or more a tapped B lands and launches, every time (hard test), against the medium AI | 368 launchers used and 0 lapsed by the route's player; 925 launches by him | none lapsed, a launch for each | 765 launcher_open cues in 100 matches |
| **FAIL** | route.first30 | A first launch inside 30 s of the first brawl, in at least 65% of matches at medium (a first launch needs a close, and how often a masher earns one is the brawl's own texture) | 61.0% of 100 matches (100 had a launch at all) | at least 65% | a launch by the route's player |
| **FAIL** | route.first60 | A first launch inside 60 s of the first brawl, in at least 90% of matches at medium | 83.0% of 100 matches | at least 90% | a launch by the route's player |
| INFO | route.vs.masher | The route player against the pair script X masher, both against the medium AI (reported: the like-for-like comparison; masher.gd masher is a different script) | route 13.0% (13 of 100); masher 35.0% (35 of 100) | reported | the route is the masher plus one B on a launcher opening |
| PASS | route.perMatch | Launches a match at medium: by the route's player (4 to 10), and on him (4 to 8); collateral is reported beside it (the arms' rows) | 9.25 by him, 6.09 on him | 4 to 10; 4 to 8 | 100 matches; point estimates |
| **FAIL** | route.hard | The launcher's route launches in 30 to 55% of the brawls it is tried in against the hard AI (launches by the route's player over brawls) | 56.8% (1681 launches in 2960 brawls); route player wins 0.0% | 30 to 55% | 100 matches; an approximation: launches, not brawls with a launch |
| PASS | route.every.hard | From a stagger of 12 ticks or more a tapped B lands and launches, every time (hard test), against the hard AI | 298 launchers used and 0 lapsed by the route's player; 1681 launches by him | none lapsed, a launch for each | 544 launcher_open cues in 100 matches |
| **FAIL** | give.lat.b-free | A fighter with his hands down moves within 2 ticks of his stick while the rival winds up (hard test) | the slowest first step came 9 ticks after the stick (10051 wind-ups; -1 means he never moved) | at most 2 ticks | 60 matches |
| PASS | give.out.b | Out of a tapped heavy that is not followed, every time, when he starts by tick 16 (hard test: the blow ends as a miss with the text gave_ground) | 7403 of 7403 gave ground when he started by tick 16; later starts: 349 of 2588 (reported) | every time | miss texts {"gave_ground":7752} |
| PASS | give.lat.b-follow | A fighter with his hands down moves within 2 ticks of his stick while the rival winds up (hard test) | the slowest first step came 1 ticks after the stick (5938 wind-ups; -1 means he never moved) | at most 2 ticks | 60 matches |
| PASS | give.followed.b | Out of a tapped heavy that is followed from its first tick: never (hard test) | 0 of 5875 gave ground | none | miss texts {} |
| PASS | give.lat.y-free | A fighter with his hands down moves within 2 ticks of his stick while the rival winds up (hard test) | the slowest first step came 2 ticks after the stick (21970 wind-ups; -1 means he never moved) | at most 2 ticks | 60 matches |
| INFO | give.medium.free | Out of a tapped medium: only from its first 6 ticks, and never when followed (reported) | 6662 of 6684 gave ground when he started in the first 6 ticks; later starts 166 of 15286 | reported | miss texts {"gave_ground":6828} |
| **FAIL** | give.lat.y-follow | A fighter with his hands down moves within 2 ticks of his stick while the rival winds up (hard test) | the slowest first step came 3 ticks after the stick (20183 wind-ups; -1 means he never moved) | at most 2 ticks | 60 matches |
| INFO | give.medium.followed | Out of a tapped medium that is followed: only from its first 6 ticks, and never when followed (reported) | 0 of 6125 gave ground when he started in the first 6 ticks; later starts 0 of 14058 | reported | miss texts {} |
| PASS | energy.bolt | A point-blank bolt lands 2 ticks after its press, plus the closing rule's d (0 to 4) when it was pressed from a gap (hard test: the announced contact tick less the press tick) | 57135 of 57330 announced at exactly 2 ticks, 57330 within 2 to 6 ({"blast:12":12,"bolt:2":57135,"bolt:3":57,"bolt:4":46,"bolt:5":49,"bolt:6":43}) | 2 (in reach), up to 6 (from a gap) | 60 matches |
| PASS | energy.flash | No more than three full flashes in any second, and one blow in 20 ticks at most may take one (hard test; a mashed RB + X) | 24168 full flashes; the most in 60 ticks 3; the shortest gap 20 ticks | at most 3 in 60 ticks, 20 ticks apart | 60 matches; sources {"blast:hit":7,"bolt:armour":687,"bolt:guard":11256,"bolt:hit":44942} |
| **FAIL** | energy.blast | A clean blast's own knock-back is 4 bh (hard test: the knock-back of its target within 3 ticks; since the follow-up a cold blast has none of its own and knocks back only as a string's ender) | 18 of 395 clean blasts knocked back, 16 off 4 bh by more than 0.25 (range 0.03 to 4); the other 377 were cold | 4 bh, within 0.25 | 691 blasts pressed; sources {"blast:guard":168,"blast:hit":395,"bolt:hit":2613} |
| **FAIL** | burst.share | The burst (a held X) against a mash (X every 8 ticks), damage a second against a rival who never moves: 70 to 80%, never over | 56.3% (35.6 against 63.2 damage a second; 3690 bursts, 0 of eight blows) | 70 to 80% | 30 matches each; damage per match over the match's median length, a rough read |
| PASS | masher.blur.blind | The perfect blur locks on a blind 8-tick masher: share of five-blow strings against the medium AI (agency pass 20) | 11.1% (164 of 1477 strings) | at most 20% | 100 matches; the script wins 0%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes |
| **FAIL** | masher.blur.contact | The perfect blur locks on a script that presses on every contact and follows the links: share of five-blow strings against the medium AI (agency pass 20) | 12.2% (228 of 1863 strings) | at least 80% | 100 matches; the script wins 0%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes |
| PASS | masher.blur.m10 | The perfect blur locks on a blind metronome every 10 ticks: share of five-blow strings against the medium AI (agency pass 20) | 5.5% (98 of 1778 strings) | at most 20% (assumed ceiling) | 100 matches; the script wins 0%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes |
| PASS | masher.blur.m12 | The perfect blur locks on a blind metronome every 12 ticks: share of five-blow strings against the medium AI (agency pass 20) | 3.1% (58 of 1871 strings) | at most 20% (assumed ceiling) | 100 matches; the script wins 0%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes |
| PASS | masher.blur.m14 | The perfect blur locks on a blind metronome every 14 ticks: share of five-blow strings against the medium AI (agency pass 20) | 5.0% (98 of 1971 strings) | at most 20% (assumed ceiling) | 100 matches; the script wins 0%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes |
| PASS | masher.mirror | Two lights-only players (mashers who take their forms) finish the match before the cap | 100.0% (200 of 200; 0 ran to the cap) | at least 95% | median 214.7 s; point estimate |
| PASS | masher.brink | Lights-only mirror: brink to KO, median (read against the overall 45 to 90 s: the 25 to 50 s band was derived when a level trade ended in a draw, and that rule is gone) | 70.3 s | 45 to 90 s | 200 matches that ended in a KO |
| INFO | masher.brinkcloses | Lights-only mirror: share of closes made by the fighter on the brink, while only one of them is on it (reported, not banded: melee-press-feel 9e) | 19.2% (5 of 26 closes) | reported | 710 closes in 200 matches |
| PASS | masher.firstslot | Lights-only mirror: matches won from the first slot (40 to 60%, read on 200 matches) | 42.5% (85 of 200); first 60 seeds 40% of 60, the next 140 44% of 140 | 40 to 60% | point estimate; the interval at 200 matches is about +-7 points; the split is Encounter's (35% on the first 60 seeds, 67% on the other 140): a slot effect that moves with the seed range is the thing to look at; PENDING under 100 decided matches |
| INFO | masher.tradelimit | A trade breaks at its limit or on the tick a lead of 2 appears after it (reported; no bound but the double hit at 240 ticks) | 710 breaks; 0 before the limit; lateness in ticks: 95th percentile 2, longest 2 | reported | the old hard test (never early, at most 4 late) is retired: a lead appears whenever the other fighter stops landing |
| INFO | masher.breakclose | A close follows a trade break within 24 ticks, and 4 more for a hit-stop (reported: 85 to 95% expected) | 100.0% of 710 breaks (0 took longer) | reported (85 to 95%) | counted on S.tick from the trade_break event to the next flurry close or brawl_end |
| INFO | masher.closes | Lights-only mirror: brawls, blows and closes (reported) | 8.6 brawls a minute, 0.9 closes a minute, 0 heavy staggers; blows {"light":329591}; ends {"break":383,"double":6140} | reported | 200 matches |
| PASS | masher.mirror.tick | Two lights-only players (mashers who take their forms) finish the match before the cap (taps on S.tick, both on the same ticks: the exact tie) | 100.0% (200 of 200; 0 ran to the cap) | at least 95% | median 265.1 s; point estimate |
| **FAIL** | masher.brink.tick | Lights-only mirror: brink to KO, median (read against the overall 45 to 90 s: the 25 to 50 s band was derived when a level trade ended in a draw, and that rule is gone) (taps on S.tick, both on the same ticks: the exact tie) | 142.7 s | 45 to 90 s | 200 matches that ended in a KO |
| INFO | masher.brinkcloses.tick | Lights-only mirror: share of closes made by the fighter on the brink, while only one of them is on it (reported, not banded: melee-press-feel 9e) (taps on S.tick, both on the same ticks: the exact tie) | 19.1% (13 of 68 closes) | reported | 4269 closes in 200 matches |
| INFO | masher.firstslot.tick | Lights-only mirror: matches won from the first slot (40 to 60%, read on 200 matches) (taps on S.tick, both on the same ticks: the exact tie) | 42.5% (85 of 200); first 60 seeds 47% of 60, the next 140 41% of 140 | reported (the exact tie; the banded row is the offset mirror) | point estimate; the interval at 200 matches is about +-7 points; the split is Encounter's (35% on the first 60 seeds, 67% on the other 140): a slot effect that moves with the seed range is the thing to look at; PENDING under 100 decided matches |
| INFO | masher.tradelimit.tick | A trade breaks at its limit or on the tick a lead of 2 appears after it (reported; no bound but the double hit at 240 ticks) (taps on S.tick, both on the same ticks: the exact tie) | 4272 breaks; 0 before the limit; lateness in ticks: 95th percentile 3, longest 6 | reported | the old hard test (never early, at most 4 late) is retired: a lead appears whenever the other fighter stops landing |
| INFO | masher.breakclose.tick | A close follows a trade break within 24 ticks, and 4 more for a hit-stop (reported: 85 to 95% expected) (taps on S.tick, both on the same ticks: the exact tie) | 100.0% of 4272 breaks (0 took longer) | reported (85 to 95%) | counted on S.tick from the trade_break event to the next flurry close or brawl_end |
| INFO | masher.closes.tick | Lights-only mirror: brawls, blows and closes (reported) (taps on S.tick, both on the same ticks: the exact tie) | 9.2 brawls a minute, 4.1 closes a minute, 0 heavy staggers; blows {"light":758922}; ends {"break":390,"double":9202} | reported | 200 matches |
| PASS | masher.mirror.tickoff | Two lights-only players (mashers who take their forms) finish the match before the cap (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 100.0% (200 of 200; 0 ran to the cap) | at least 95% | median 188.3 s; point estimate |
| PASS | masher.brink.tickoff | Lights-only mirror: brink to KO, median (read against the overall 45 to 90 s: the 25 to 50 s band was derived when a level trade ended in a draw, and that rule is gone) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 64.2 s | 45 to 90 s | 200 matches that ended in a KO |
| INFO | masher.brinkcloses.tickoff | Lights-only mirror: share of closes made by the fighter on the brink, while only one of them is on it (reported, not banded: melee-press-feel 9e) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 11.1% (34 of 305 closes) | reported | 6328 closes in 200 matches |
| **FAIL** | masher.firstslot.tickoff | Lights-only mirror: matches won from the first slot (40 to 60%, read on 200 matches) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 38.0% (76 of 200); first 60 seeds 30% of 60, the next 140 41% of 140 | 40 to 60% | point estimate; the interval at 200 matches is about +-7 points; the split is Encounter's (35% on the first 60 seeds, 67% on the other 140): a slot effect that moves with the seed range is the thing to look at; PENDING under 100 decided matches |
| INFO | masher.tradelimit.tickoff | A trade breaks at its limit or on the tick a lead of 2 appears after it (reported; no bound but the double hit at 240 ticks) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 2888 breaks; 0 before the limit; lateness in ticks: 95th percentile 26, longest 26 | reported | the old hard test (never early, at most 4 late) is retired: a lead appears whenever the other fighter stops landing |
| INFO | masher.breakclose.tickoff | A close follows a trade break within 24 ticks, and 4 more for a hit-stop (reported: 85 to 95% expected) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 100.0% of 2888 breaks (0 took longer) | reported (85 to 95%) | counted on S.tick from the trade_break event to the next flurry close or brawl_end |
| INFO | masher.closes.tickoff | Lights-only mirror: brawls, blows and closes (reported) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 8.2 brawls a minute, 8.3 closes a minute, 0 heavy staggers; blows {"light":573844}; ends {"break":358,"double":5797} | reported | 200 matches |
| INFO | masher.fastslow | A faster masher against a slower one (6 ticks against 12): closes a minute, and who wins (reported, as the cost of tapping slowly) | closes a minute: 45.7 for the 6-tick tapper, 0 for the 12-tick tapper; the 6-tick tapper wins 200 of 200 | reported | 200 matches; closes are flurry staggers; the clock is S.tick |
| PASS | masher.uneven.finish | An uneven mirror (8 ticks against 10) finishes before the cap (an 8-tick tapper against a 10-tick tapper) | 100.0% (200 of 200; 0 ran to the cap) | at least 95% | median 116.1 s; point estimate |
| PASS | masher.uneven.faster | The faster tapper (8 ticks) wins the uneven mirror (an 8-tick tapper against a 10-tick tapper) | 100.0% (200 of 200) | at least 80% | 200 matches; point estimate |
| INFO | masher.uneven.brink | Uneven mirror: brink to KO, median (reported) (an 8-tick tapper against a 10-tick tapper) | 18.1 s | reported | 200 matches that ended in a KO |
| PENDING | cell.x.tapped | X tapped on every beat, alone against the medium AI (40 to 75%) | the beat (the skill strike on all three) is C3, not built | 40 to 75% | needs the skill strike and a script that presses on the beat |
| PENDING | cell.y.tapped | Y tapped on every beat, alone against the medium AI (40 to 75%) | the beat (the skill strike on all three) is C3, not built | 40 to 75% | needs the skill strike and a script that presses on the beat |
| PENDING | cell.b.tapped | B tapped on every beat, alone against the medium AI (40 to 75%) | the beat (the skill strike on all three) is C3, not built | 40 to 75% | needs the skill strike and a script that presses on the beat |
| PENDING | masher.expert | An expert script (guards, punishes with a heavy, perfect-blocks heavies and enders) wins against the medium AI (at most 15%) |  | at most 15% | needs the expert script: it reads the rival tells (Encounter scratch build has one, not in the tree) |

## Acceptance tests

| Status | ID | Spec | Test | Detail |
| :--- | :--- | :--- | :--- | :--- |
| PASS | W1 | spec-wounds §5.1 | Determinism: the same seed gives an identical record and event log, whatever the job count | 6 seeds, 1 and 3 jobs |
| PASS | W2 | spec-wounds §5.2 | No KO without a finisher: 100% of KOs follow the loser's brink_enter and a finisher_start | 400 KOs |
| PASS | W3 | spec-wounds §5.3 | Length and chapters: 1.5 to 2.5 region breaks a match (rebased); first brink median 4:30 to 7:00; length median 6:00 to 8:00, p90 at most 10:00, p99 at most 12:00 | breaks 2, first brink 336 s, median length 433 s |
| PASS | W4 | spec-wounds §5.4 | No loops: 0.3 to 0.7 rallies per match (rebased); no region rallied twice; finisher survival 0 from 11:00 (relaxed for the third Rally at M1b, balance-targets 18; the sim enforces the 11:00 rule) | 0.37 rallies per match |
| PASS | W5 | spec-wounds §5.5 | Spread: no region above 45% of all wear; arms take 35 to 65% of limb breaks (the old first-broken shares are retired: the brink is the core) | damage share by region {"arms":31.8,"core":11.5,"head":34.3,"legs":22.4}%; first region broken in % of matches {"head":0,"core":78,"arms":9.8,"legs":12.3} (0 of 400 matches broke no region) |
| PENDING | W6 | spec-wounds §5.6 | Profiles: Cyborg chip takes 0 while the hatch is closed; Anti-hero penalties follow Pride and facade; refit mends shrink; no finisher while Boiling; core wear never decreases | waiting for F1 (roster fighters): no hatch_open, facade_crack, boil_over event in the sim |
| PENDING | W7 | spec-wounds §5.7 | Balance: every pairing 45 to 55%; pacing bands still pass; heat-track bands (Boiling reached in 40 to 80%, at most 5% of time, boil-overs at most 0.5 a match, boil-over matches won 35 to 55%, internal wear 10 to 35% of brinks) | waiting for S2 for pairings, F1 for heat: no heat_stage event in the sim |
| PENDING | H1 | §11 hard test | Hazards never break a region: hazard wear stops at 89 | waiting for LD1 with Wounds S1: no hazard* event in the sim |
| PENDING | H2 | §11 hard test | Zero casualties from living-destruction effects while the higher tier is 1 | waiting for LD1: no hazard* event in the sim |
| PENDING | H3 | §11 hard test | At most 3 active hazard fronts inside the camera framing at once | waiting for LD1 (needs S.frontsInFrame from the view side): no hazard* event in the sim |
| PENDING | H4 | §11 | Effects are credited to the fighter whose event started them; knock-on effects keep the cause; no hazard starts during a finisher or a cinematic | waiting for LD1 and Wounds S2: no hazard* event in the sim |
| PENDING | G1 | balance-targets §20 hard test | One journey has at most 8 contacts of all kinds and lasts at most 4 s from the first contact to the stop | events present, but the check has no body yet: write it against World G5's fields |
| PENDING | G2 | balance-targets §20 hard test | Bounces allowed by the launcher tier: at most 1 at tier 1, 2 at tier 2, 3 at tiers 3 and 4; a journey never costs more wear than one impact | events present, but the check has no body yet: write it against World G5's fields |
| PENDING | OC1 | spec-wounds §3 QA bands | The rival reaches Apex in 30 to 50% of his matches | waiting for the rival mechanic (after his moveset): no chin_start event in the sim |
| PENDING | OC2 | spec-wounds §3 QA bands | The rival completes 1 to 3 absorbs a match (3 hits, or a signature) | waiting for the rival mechanic (after his moveset): no chin_start event in the sim |
| PENDING | OC3 | spec-wounds §3 QA bands | The rival is thrown out of On the Chin in 15 to 35% of its uses | waiting for the rival mechanic (after his moveset): no chin_start event in the sim |
| PENDING | H5 | §5b hard tests | A chain never exceeds the launcher's tier cap (2 at tiers 1 and 2, 3 at tier 3, 4 at tier 4; 5 only for a scripted finisher) and the planner drops any chain over its casualty budget (4% at tier 2 or below, 12% at 3, 20% at 4) | waiting for World buildings-in-depth §4b: no brunt_chain event in the sim |
| PASS | C1 | §4b rolling budget | Rolling 60 s casualty budget by the higher tier: 2%, 4%, 8%, 15% of the starting population. No borrowing at tier 1 or 2; at tier 3 and above a set piece may borrow its own per-event budget | tier 3+ windows over budget (set-piece borrowing, to be bounded by per-event budgets): 18759 |
| PASS | C2 | §4b ceiling | Cumulative ceiling by the highest tier reached so far: 10%, 30%, 60%, 90% of the starting population | no match over its ceiling |
| PENDING | C3 | §4b split | Per-tier casualty split: casualties by the higher tier at the time, checked against the ramp (tier 1 and 2 together at most about a third of the losses of a match once the ramp exists) | events present, but the check has no body yet: write it against World collateral ramp (after S2)'s fields |
| PENDING | SC1 | stage-c-tests §2 | Weight starts light | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC2 | stage-c-tests §2 | Weight sticks across exchanges | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC3 | stage-c-tests §2 | No-op on the current weight (press_ack weight_light once) | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC4 | stage-c-tests §2 | Same-tick light and heavy: heavy wins | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC5 | stage-c-tests §2 | Heavy fallback to light when ki is short (press_ack weight_fallback) | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC6 | stage-c-tests §2 | Signature queue and cancel (sig_queued, sig_cancelled) | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC7 | stage-c-tests §2 | Unfunded signature waits | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC8 | stage-c-tests §2 | Expiry after 600 ticks (sig_expired once) | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC9 | stage-c-tests §2 | Funded signature fires within 180 ticks of sig_funded | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC10 | stage-c-tests §2 | The 180-tick cap pauses during charge | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC11 | stage-c-tests §2 | The cap pauses inside an exchange | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC12 | stage-c-tests §2 | A signature has no fallback | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC13 | stage-c-tests §2 | Presses are accepted while charging | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC14 | stage-c-tests §2 | Queue cleared by a KO or a decisive launch | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC15 | stage-c-tests §2 | Determinism under press timing | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC16 | stage-c-tests §2 | The AI uses the same input path | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC17 | stage-c-tests §2 | No timing dependence for parry, chain or struggle outcomes | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC18 | stage-c-tests §2 | Holds pause attacks | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC19 | stage-c-tests §2 | Transform confirm: 30-tick hold | waiting for Controls Stage C: no availability event in the sim |
| PENDING | SC20 | stage-c-tests §2 | Encore offer: 18-tick hold, 180-tick lapse | waiting for Controls Stage C: no availability event in the sim |
| PENDING | SC21 | stage-c-tests §2 | Stance always accepted, debounce 4 and repeat 12 | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SC22 | stage-c-tests §2 | Acknowledgement on the same tick (press_ack) | waiting for Controls Stage C: no press_ack event in the sim |
| PENDING | SB1 | stage-c-tests §3 | Funded-to-fired: p99 and max at most 180 ticks (paused ticks excluded), 1,000 matches with a scripted queuer | waiting for Controls Stage C (+ Encounter scheduler for B1, B2): no sig_funded, sig_fired event in the sim |
| PENDING | SB2 | stage-c-tests §3 | Queue never wedges: no sigQueued older than 600 unfunded or 180 funded ticks, 1,000 matches with random presses | waiting for Controls Stage C (+ Encounter scheduler for B1, B2): no sig_queued event in the sim |
| PENDING | SB3 | stage-c-tests §3 | Weight mix follows the latched weight (within fallbacks), 400 matches per arm | waiting for Controls Stage C (+ Encounter scheduler for B1, B2): no press_ack event in the sim |
| PENDING | SB4 | stage-c-tests §3 | Stance-flick arm wins at most 55% (rulings §12 risk 5) | waiting for Controls Stage C (+ Encounter scheduler for B1, B2): no press_ack event in the sim |
| PENDING | SB5 | stage-c-tests §3 | Ki fairness: sticky heavy against sticky light, neither above 55%; ki-starved fallbacks per match reported | waiting for Controls Stage C (+ Encounter scheduler for B1, B2): no press_ack event in the sim |
| PENDING | SB6 | stage-c-tests §3 | Determinism: 100 seeds with random queue presses, run twice, identical hashes | waiting for Controls Stage C (+ Encounter scheduler for B1, B2): no press_ack event in the sim |
| PENDING | C-human | stage-c-tests §4 | Human checks: readability (80% say what the next attack is and why it has not fired), weightlessness (each "nothing happened" is a missing ack), agency survey against the prototype baseline | waiting for playtest: no playtest event in the sim |

---

## Addendum (2026-10-13): World's wall slam, HEAD f5c001e6 (579dd984) against f9469f8a

Paired by seed on the default arm (seeds 1 to 100; f9469f8a from the clean pass's records, HEAD fresh) and on one arm from World's demo start at a crossing (`--start=crossing`, an option added to `records.gd` for this; 100 matches each build). Below-normal priority, `--jobs=3` in three waves, 6 to 7 minutes a wave; no job wall-capped or budget-stopped. Harness `.gd` files are the working tree's (records.gd with `--start`) on both exports.

| Per match (100 matches) | f9469f8a default | HEAD default | f9469f8a crossing | HEAD crossing |
| :--- | ---: | ---: | ---: | ---: |
| **Wall slams (a `lodge` event)** | 0 | **0.34** | 0 | **0.40** |
| Bodies into buildings (landings that end on a building) | 0.39 | 0.45 | 1.15 | 1.18 |
| Landings against a wall (the older slope class) | 1.85 | 1.82 | 1.57 | 1.33 |
| Damage from impacts (the only kind a slam can land in) | 985 | 997 (+12) | 1,033 | 1,033 |
| Match length: median / 10th percentile | 432.0 / 313.2 s | 434.4 / 312.7 s | 464.0 / 357.8 s | 466.6 / 357.8 s |
| First slot (the Protagonist's side) wins | 50% | 55% | 43% | 51% |
| Civilians lost | 21.1% | 20.9% | 22.4% | 22.8% |

- **Damage from walls a match is not separable in the records:** a slam's extra hit lands in the damage kind `impact` with every other impact, so the only figure is the impact total, up 12 a match (1.2%) on the default arm and unchanged from the crossing. A `wall` damage kind (or the lodge event carrying its damage) would give the number exactly.
- **Paired by seed:** on the default arm 67 of 100 matches are identical to f9469f8a (the same length and winner) and 13 changed winner; from the crossing 29 of 100 are identical and 32 changed winner. The mean change in length is +0.8 s and -1.9 s. A slam changes a match from that point on, so the win split moves by chance rather than by a rule (the interval at 100 matches is about 10 points on each).
- **Bands:** of 161 rows the default arm's evaluation compares, 155 keep their status. The six that crossed their lines are all on a band edge and inside the noise: `10.end.launch` 29.8 to 30.1% (band 18 to 30), `10.longHaul` 30.2 to 29.6% (at least 30), `10.gap10` 100 to 98% of matches with no gap over 10 s (at least 95; the interval is the cause), `8.limbBreaks` 0.29 to 0.34 (now in 0.3 to 0.5), `7.beamEscape` 24.1 to 26.4% (the interval), and `4.struct.row1` (a display change). None is the wall slam's doing that a larger sample would not move back and forth.
- **So:** the slam is rare (one body in three matches), costs about 12 damage a match, and moves nothing that is not already on an edge.
