# The C2 chain after the follow-up and the stick slice: b1b2ed6a (QA, 2026-10-12)

Clean export of b1b2ed6a ("The brawl's stick": a held stick always moves the pair, up and over a building's face, the AI digs in at most twice a match), which sits on Encounter's follow-up tune 14ae38c9 (`wearPerDamage` 270, `digIn`, the blast as an ender, the 68-unit fix). Godot 4.7.2, headless, `--jobs=3`, wall and budget caps at their defaults. The harness `.gd` files in `qa/godot/` are byte for byte the export's, except for two disclosed overlays used only for the burst pair (`approach=1`, in `players.gd`). The before column is `docs/qa/c2-chain-2e0f3b2.md`.

**What ran:** the full masher stage (58 jobs: the first-stage pairs for Orb's four tests, then the rest), the eight arms at 400 matches (3,200) and the easy and hard level runs, and the 7 acceptance tests (5 pass: W3 and W5 fail). **Not run:** the T, E, F plans and the downtime probes.

**Totals.** Arm bands: 91 pass, 32 fail, 18 pending (2e0f3b2c: 93, 30, 18). The masher stage reads 44 pass, 22 fail, 29 reported, 2 pending.

## Before and after

| Row | Before (2e0f3b2c) | After (b1b2ed6a) | Band, and status after |
| :--- | :--- | :--- | :--- |
| Match length, median | 319.5 s | **360.9 s** | 360 to 480: **in**, on the floor |
| Match length, 10th percentile | 232.4 s | 263.6 s | at least 300: **out** |
| Match length, 90th percentile | 431.9 s | 498.7 s | at most 600: in |
| First brink, median | 229.7 s | 267.7 s | 270 to 420: **out by 2 s** |
| Brink to KO, median | 68.9 s | 74.2 s | 45 to 90: in |
| Limb breaks a match | 0.19 | 0.22 | 0.3 to 0.5: **out** |
| Arms' share of limb breaks | 89.6% | 93.1% | 35 to 65: **out** |
| Mood: Calm / Tense / Frenzied | 46.2 / 51.4 / 2.4% | 41.9 / 54.9 / 3.1% | 20-40 / 40-65 / 5-20: out / in / out |
| Frenzied share of act 4 | 8.2% | 8.3% | at least 15: out |
| Acts 2, 3, 4 start | 90.0, 138.8, 222.7 s | 89.3, 149.6, 231.8 s | 90-150, 150-240, 270-345: all three **out**, each by 1 s (act 2 and act 3) or 38 s (act 4) |
| Act 4 before the first brink | 29.5% | **79.8%** | at least 80: **out by 0.2 points** |
| Launches, of those that separate | 53.6% | 53.3% | 25-40: out |
| Launches, of those reaching a decision | 32.4% | 32.1% | 18-30: out |
| Blasts' share of damage | 13.6% | 12.3% | 10-25: in |
| AI's share of fight time in a brawl | 40.3% | 40.4% | 30-50: in |
| Protagonist win rate | 47.5% | 46.8% [43.3, 50.2] | 45-55: in |
| **X masher vs medium** | 45% | **54%** | 35 to 50: **out (over)** |
| Y masher vs medium | 0% | **0%** | 20 to 50: out |
| B masher vs medium | 100% | **100%** | 20 to 50: out |
| X over Y; Y over B; B over X | 100%; 95%; 45.5% | 100%; 98%; **32.9%** (25 of 76) | 60 to 90: all out |
| Mixed blaster vs medium (the blast script) | 97% | **49%** | 30 to 50: **in** |
| Double hits, lights-only presser | 0.00 a match, 0% | **0.70 a match, 58.0% of matches** | 0.5-2; 35-65: **in** |
| Double hits, mixing presser | 0.01, 1% | 0.03, 3% | out |
| Double hits, at most 4 in a match (hard) | | the most is 2 (lights), 1 (mixing) | in |
| AI holds against a held stick | 30.8% | **20.6%** | under 25: **in** |
| Held stick against the AI | 0.88 | 0.95 | at least 0.7: in |
| **Dead stick, live ticks** | 27.8% (freeze not separated) | **0.2%** (655 of 318,922); against the AI, toward: 0.4% (1,546 of 371,251) | none: out by a handful |

## Orb's four tests

1. **Moving in combat. Essentially passes.** The dead stick is **0.2%** of held live ticks against a rival with no stick (655 of 318,922; all east; by cause ground 367, other 287, stun 1) and **0.4%** for a presser holding toward against the medium AI (1,546 of 371,251; building 601, other 654, ground 234, stun 57). A further 121,896 and 186,750 held ticks fell in hit freezes and are shown apart. Latency: **99.9%** of 1,184 drifts moved within 2 live ticks (334 at 1, 849 at 2), one never moved. The AI holds against a player's stick on 20.6% of ticks (in). Walk-outs all pass (never under 12 ticks; the longest is 22). Drift: 2.41 bh a second with one stick, 4.56 with two; the centre's speed is at most 0.097 bh a tick.
2. **Moving while the rival charges. Passes.** First step within 2 ticks (slowest 2; **3 ticks against a followed Y wind-up, one tick over, on 22,492 wind-ups**), out of an unfollowed tapped heavy from tick 16 7,379 of 7,379, out of a followed heavy 0 of 7,382; a medium gave ground 6,380 of 6,403 from its first 6 ticks and 0 of 22,492 when followed.
3. **Launching. Passes the hard test; the route's bands are close.** A B in a ready opening launched every time (373, 334 and 263 used, 0 lapsed). The route's launch share: easy 66.6% (70-90, out), medium 75.0% (50-75, on the edge), hard 59.4% (30-55, out). First launch inside 30 s: **60.0%** (65, out); inside 60 s: 83.0% (90, out). Launches a match: 8.93 by him and 5.89 on him (in).
4. **Energy in reach.** The bolt (54,611 of 54,784 at 2 ticks, the rest within 2 to 6) and the flashes (at most 3 in 60 ticks, 20 apart) pass. **The blast row fails on a read I cannot isolate:** 17 of 385 clean blasts knocked back and 368 were cold (the follow-up gave a cold blast no knock-back of its own). The 17 read 0.03 to 3.5 bh, so my match on "the target within 3 ticks" is catching other knock-backs. A field that names a blast's own knock-back is needed from Encounter.

## Notes

- **The match length came back to its band.** Median 360.9 s on the floor of 360 to 480, p90 498.7 s, but the 10th percentile is 263.6 s against a floor of 300: the shortest matches are still too short. The first brink (267.7 s) is 2 s under its band and act 4 before the first brink (79.8%) is 0.2 points under 80. The limb-break shape did not move: 93% arms.
- **The X masher is now over its band (54%, band 35 to 50),** where it was 45% before the stick slice. It moved between 2e0f3b2c and b1b2ed6a, which is the follow-up tune and the stick slice together (the dig-in cap at two a match among them); I did not measure 14ae38c9 alone, so I cannot say which. The 6-tick masher wins 84% and the 10-tick 10%. Game Design's §14 rule "the masher's band comes first" applies.
- **The one-button maskers and the edges did not move:** Y 0%, B 100%, X over Y 100%, Y over B 98%, B over X 32.9%. Game Design's levers for those are not in this build.
- **The mixed blaster came into band (49%, band 30-50)** after the blast became an ender, and the bolt-only script wins 38% (in). The blast-heavy script and the slow blaster against the rush script read 100% and 100% (the slow blaster finished 32 of 40 matches: 8 ran to the cap).
- **The 68-unit hard row** (known fail): **3 of 5,274,066** strikes beyond 68 units, the longest 156.2, against 101 of 4,318,479 before. The rate fell by a factor of 40, but the longest rose from 120.9 to 156.2.
- **closing.step now passes:** 0 of 97,785 blows moved their attacker over 0.6 bh (the most 0.591), and `closing.d` passes (0 of 400 outside 0 to 4).
- **The zip's counter rate** is back in band (not listed as a failure); caught is 33.6% [30.2, 37.1], which fails on its interval.
- **Even mirror:** finishes 100%; first slot 42.5%, 44.5% (exact tie) and 47.5% (offset). Its brink to KO is 71.3 s live-tick (in) and **191.5 s and 180.8 s** on the two S.tick variants (45 to 90, out). The uneven mirror finishes 100%, the faster tapper wins 198 of 200 and its brink is 20.0 s.
- **burst.share: 58.4%** (35.6 against 60.9 damage a second, against a rival who never moves; band 70 to 80, out). After two harness fixes: the holder and the mash script now fly in (`approach=1`), and the pair results carry their `stats`. A burst is worth about 58% of a mash.
- **Perfect blocks at easy: 2.53 a minute** (band 0.5 to 2, out), medium and hard in.
- **Standing:** brunts (0.07 a minute), flights, the lock-break median, structures levelled at tier 3 (2.20, band 3 to 10, now out), mirror-hero biome share (40.7%).

## Harness changes in this batch (qa/, mine)

- Already committed (1c4aa274): the dead stick on live ticks and by direction, the drift latency by the fighter's own step, the per-match miss reset, the blast's own knock-back, the wind-up row per fighter, the holder's level on the press tick, `double.presser.max.*`.
- Uncommitted: `masher.js` (the pair results carry `stats`; the burst pair uses `approach=1`) and `players.gd` (`approach=1`: fly in to a brawl's distance).

---

# Baseline on the GDScript sim

Generated by `node qa/run-godot.js --matches=400 --scale=game`. Godot 4.7.2.stable.official.ed1daf0bf; clean export of commit b1b2ed6a; slices in the tree: S0 yes, S1 yes. Seeds 1..400 in every arm; cap 900 sim-seconds (S.T). Every number reproduces from the seeds: the digests are below.

| Arm | Digest |
| :--- | :--- |
| default | `2f7e51ddcc29d713` |
| swap | `407453e2b8cfb218` |
| mirror-villain | `6857ca3d8d49bdbe` |
| mirror-hero | `3fea413587516360` |
| default-flip | `c8e9319385d419c9` |
| swap-flip | `853327df4fbfa9c1` |
| mirror-villain-flip | `bf70683d50178489` |
| mirror-hero-flip | `8bb93cf4724b10b4` |

## Slice S0 re-test

PASS: the Protagonist 46.8% [43.3, 50.2] over both slots (47.3% from P1, 46.3% from P2), 400 matches per arm; the whole interval is at or above 42%. Pacing rows passing: 5; failing: 10.reach, 10.exPerMin, 10.end.launch, 10.end.separating, 10.end.continue, 10.longHaul.

## Bands (`docs/design/balance-targets.md`)

| Status | § | Measure | Value | Band | Note |
| :--- | :--- | :--- | :--- | :--- | :--- |
| PASS | §1 | Protagonist win rate, averaged over both slots (1v1 pairing) | 46.8% [43.3%, 50.2%] | 45.0% to 55.0% | 374 of 800 decided matches |
| PASS | §9 | The Protagonist at least 42% (the placeholder-balance target from slice S0) | 46.8% [43.3%, 50.2%] | 42.0% to 100.0% | the 45 to 55% band applies to the real roster |
| **FAIL** | §1 | mirror-villain: slot effect within ±3 points | +2.5 pts [-1.0 pts, +6.0 pts] | -3.0 pts to +3.0 pts | point inside the band, interval outside the widened band |
| **FAIL** | §1 | mirror-villain: spawn-side effect within ±3 points | +2.5 pts [-1.0 pts, +6.0 pts] | -3.0 pts to +3.0 pts | point inside the band, interval outside the widened band |
| PASS | §1 | mirror-hero: slot effect within ±3 points | +0.8 pts [-2.7 pts, +4.2 pts] | -3.0 pts to +3.0 pts |  |
| **FAIL** | §1 | mirror-hero: spawn-side effect within ±3 points | +2.3 pts [-1.2 pts, +5.7 pts] | -3.0 pts to +3.0 pts | point inside the band, interval outside the widened band |
| PASS | §2 | Match length median (game, 1v1) | 360.9 s | 360.0 s to 480.0 s |  |
| **FAIL** | §2 | Match length, 10th percentile | 263.6 s | at least 300.0 s |  |
| PASS | §2 | Match length, 90th percentile | 498.7 s | at most 600.0 s |  |
| PASS | §2 | Timeouts at the 900 s cap | 0.0% [0.0%, 1.0%] | at most 1.0% |  |
| PASS | §3 | A fighter reaches tier 3 before the KO | 100.0% [99.0%, 100.0%] | at least 70.0% |  |
| PASS | §3 | A fighter reaches tier 4 before the KO | 100.0% [99.0%, 100.0%] | at least 60.0% |  |
| PENDING | §3 | First transformation timing; the last 60 s has a clash or finisher |  |  | game scale: needs transformations (roster) and finishers (S2) |
| PASS | §4 | Civilians lost at the KO, mean, default arm | 19.09 | 12.00 to 30.00 | % |
| PASS | §4 | Worst pairing's mean civilians lost (default) | 19.09 | at most 55.00 | % |
| PASS | §4 | Matches losing 90% or more of civilians (default) | 0.0% [0.0%, 1.0%] | at most 10.0% |  |
| PASS | §4 | Matches losing 90% or more of civilians (swap) | 0.0% [0.0%, 1.0%] | at most 10.0% |  |
| PASS | §4 | Matches losing 90% or more of civilians (mirror-villain) | 0.0% [0.0%, 1.0%] | at most 10.0% |  |
| PASS | §4 | Matches losing 90% or more of civilians (mirror-hero) | 0.0% [0.0%, 1.0%] | at most 10.0% |  |
| PASS | §4 | Low-tier bleed: civilians lost per minute while both fighters are at tier 2 or below, % of population (default arm) | 0.16 | at most 4.00 | 2.7 min at low tier per match; includes every source the sim has |
| PASS | §4 | Structures lost at the KO, mean share of row-1 (front-row) structures | 29.45 | 25.00 to 50.00 | % |
| INFO | §4 | Structures lost, all rows (watch metric, not a gate; §21 band 15 to 40%) | 22.4% |  | rows 1, 2, 3 |
| INFO | §4 | Structures lost, row 1 | 29.4% |  |  |
| INFO | §4 | Structures lost, row 2 | 28.7% |  |  |
| INFO | §4 | Structures lost, row 3 | 0.0% |  |  |
| INFO | §4 | Structures wrecked at the KO (stage 3 or 4), all rows, mean share (default arm) | 31.4% |  | 400 matches |
| INFO | §4 | Structures wrecked at the KO, row 1 | 41.2% |  |  |
| INFO | §4 | Structures wrecked at the KO, row 2 | 40.5% |  |  |
| INFO | §4 | Structures wrecked at the KO, row 3 | 0.0% |  |  |
| PENDING | §4 | Civilians left at 4:00: at least 25% alive in at least 80% of matches |  |  | game scale: needs 7-minute matches (Wounds S2) |
| INFO | §4b | Matches with a 60 s window over the tier budget (2%, 4%, 8%, 15%): what the ramp will have to change (default arm) | 21.3% |  | the rolling-window test is pending the ramp World is building (skeleton C1) |
| INFO | §4b | Matches over the cumulative ceiling (10%, 30%, 60%, 90% by highest tier so far) (default arm) | 0.0% |  | the ceiling test is pending the cap World is building (skeleton C2) |
| INFO | §4b | Per-tier split of casualties by the higher tier when they happened (default arm) | tier 1 0%, tier 2 2%, tier 3 17%, tier 4 80% |  | skeleton C3 bands it once the ramp exists |
| PASS | §5 | No launch type above 45% (default): largest is SMASH ACROSS | 11.6% [10.8%, 12.4%] | at most 45.0% | match-clustered upper bound must be at most 47% (M1b re-banding, balance-targets 18) |
| PASS | §5 | Largest launch type's clustered upper bound at most 47% (default) | 12.4% | at most 47.0% |  |
| PASS | §5 | No launch type above 45% (swap): largest is SMASH ACROSS | 12.5% [11.6%, 13.3%] | at most 45.0% | match-clustered upper bound must be at most 47% (M1b re-banding, balance-targets 18) |
| PASS | §5 | Largest launch type's clustered upper bound at most 47% (swap) | 13.3% | at most 47.0% |  |
| PASS | §5 | No launch type above 45% (mirror-villain): largest is SMASH ACROSS | 20.4% [19.4%, 21.4%] | at most 45.0% | match-clustered upper bound must be at most 47% (M1b re-banding, balance-targets 18) |
| PASS | §5 | Largest launch type's clustered upper bound at most 47% (mirror-villain) | 21.4% | at most 47.0% |  |
| PASS | §5 | No launch type above 45% (mirror-hero): largest is SMASH ACROSS | 10.1% [9.3%, 11.0%] | at most 45.0% | match-clustered upper bound must be at most 47% (M1b re-banding, balance-targets 18) |
| PASS | §5 | Largest launch type's clustered upper bound at most 47% (mirror-hero) | 11.0% | at most 47.0% |  |
| PASS | §5 | At least 4 launch types at or above 5% (default arm) | 6.00 | at least 4.00 |  |
| **FAIL** | §5b | Share of all planner launches that are building brunts (4 to 10%; re-based at M1b) | 3.7% [3.2%, 4.2%] | 4.0% to 10.0% |  |
| **FAIL** | §5b | Brunts per minute (0.3 to 1.0, game-scale band; re-based at M1b) | 0.07 | 0.30 to 1.00 |  |
| INFO | §5b | Villain and hero mirror brunt rows | retired |  | retired on the testbed (balance-targets 18); measured per minute: villain mirror 0.06, hero mirror 0.04 |
| PASS | §5b | Launches that pick a building, out of those with a building candidate in reach (35 to 60% pooled) | 42.2% [37.5%, 47.1%] | 35.0% to 60.0% | 403 plans with a candidate; from launch_plan events |
| PENDING | §5b | Chains among brunts, chain lengths, the per-tier casualty budget for one chain (hard test), the launcher tier cap (hard test) |  |  | needs brunt-chain events (World, buildings-in-depth §4b); skeleton in qa/godot/pending-tests.js |
| PASS | §5c | How launches end: halted: the journey ends skidding or tumbling to a stop, with or without bounces first (40 to 60%, the largest class) (per launch) | 41.2% [39.8%, 42.7%] | 40.0% to 60.0% |  |
| PASS | §5c | How launches end: against a wall (a slope steeper than 0.8; 5 to 15%) (per launch) | 14.3% [13.4%, 15.3%] | 5.0% to 15.0% |  |
| **FAIL** | §5c | How launches end: slam: the journey ends in a crater (8 to 18%) (per launch) | 18.4% [17.3%, 19.4%] | 8.0% to 18.0% |  |
| PASS | §5c | How launches end: caught in the air (the follow-up before the journey ends; 15 to 30%) (per launch) | 15.0% [14.0%, 16.1%] | 15.0% to 30.0% |  |
| PASS | §5c | Halted as a share of journeys that end on the ground (halt, wall or slam; at least 55%) | 55.8% [54.2%, 57.4%] | 55.0% to 100.0% |  |
| PASS | §5c | Halted is the largest class (balance-targets 20) | halt 41.2%, wall 14.3%, slam 18.4%, caught 15.0%, water 5.8%, brunt 3.5% | halted largest |  |
| PASS | §5c | Launches with at least one bounce (20 to 40%, balance-targets 23; the boundary is 40 degrees) | 31.1% [29.8%, 32.4%] | 20.0% to 40.0% |  |
| PASS | §5c | First contacts: skids at least as common as bounces | skid or tumble 1540, bounce 745, slam 1015, stop 0 | skids at least bounces |  |
| PASS | §5c | How launches end: water (skim or splash first; 2 to 10%, re-based at §21) (per launch) | 5.8% [5.1%, 6.5%] | 2.0% to 10.0% |  |
| **FAIL** | §5c | How launches end: brunt (a building first; 4 to 10%) (per launch) | 3.5% [3.0%, 4.0%] | 4.0% to 10.0% |  |
| INFO | §5c | Planner launches with no contact and not caught (KO, the cap, launched again first), share of launches | 1.5% |  | a class of its own so the classes add up to 100% |
| INFO | §5c | Planner launches that landed at a stop (a contact under 350, no skid or tumble), share of launches | 0.2% |  | a class of its own; not banded |
| INFO | §5c | Landing mix over every launch event, beam and finisher launches included (not banded) | slide 46.8%, slam 23.5%, caught 9.2%, bounce 0.0%, water 7.4%, brunt 1.8%, none 2.8% |  |  |
| **FAIL** | §5c | Flights off a crater lip a minute, seen (in the air at least 10 ticks; 0.5 to 2.5) | 0.49 | 0.50 to 2.50 |  |
| **FAIL** | §5c | Flights off any terrain a minute, seen (lips, crests, cliffs, heaps; 1.5 to 5) | 0.76 | 1.50 to 5.00 |  |
| PASS | §5c | Journeys that reach the 4 s or 8-contact bound (at most 8%) | 0.0% | at most 8.0% |  |
| PASS | §5c | Journeys longer than 4,000 units (at most 20%; Camera chase rule covers them) | 17.2% | at most 20.0% |  |
| PASS | §5c | Bounces per bounced journey, mean (1.2 to 2.0) | 1.67 | 1.20 to 2.00 |  |
| PASS | §5c | Halted journeys with a tumble that is seen (tumble_end of 18 ticks or more; 30 to 60%) | 35.6% [33.4%, 37.9%] | 30.0% to 60.0% |  |
| PENDING | §5c | Early recoveries as a share of the chances, medium AI (20 to 40%) |  |  | switches on with World G5 (`tech_offer` when the chance opens, `tech` when taken) |
| INFO | §5c | Slides: mean length and trench width; slams per match; water skims per match | 2703 units, 297.3 wide; 19.0 slams; 1.6 skims |  |  |
| PENDING | §5c | Casualties from one slide at most 2% (tier 2 or below), 5% (tier 3), 10% (tier 4); 0 in open country; the planner declines launches over budget (hard tests) |  |  | needs casualties attributed per slide (a slide event with the population lost, or the predicted slide of the planner) and the predicted-vs-actual landing test from Encounter |
| INFO | §10 | Heavies landed and heavy clashes won per minute of match, both fighters (default; Game Design's estimates about 6 and 1.5) | 5.24 and 0.00 |  | per fighter PROTAGONIST/RIVAL: 2.61/2.64 landed; 0.00/0.00 clash wins (slot order) |
| INFO | §10 | Heavies landed and heavy clashes won per minute of match, both fighters (swap; Game Design's estimates about 6 and 1.5) | 5.19 and 0.00 |  | per fighter RIVAL/PROTAGONIST: 2.56/2.63 landed; 0.00/0.00 clash wins (slot order) |
| INFO | §10 | Heavies landed and heavy clashes won per minute of match, both fighters (mirror-villain; Game Design's estimates about 6 and 1.5) | 5.11 and 0.00 |  | per fighter RIVAL-A/RIVAL-B: 2.62/2.49 landed; 0.00/0.00 clash wins (slot order) |
| INFO | §10 | Heavies landed and heavy clashes won per minute of match, both fighters (mirror-hero; Game Design's estimates about 6 and 1.5) | 5.30 and 0.00 |  | per fighter PROTAGONIST-A/PROTAGONIST-B: 2.68/2.61 landed; 0.00/0.00 clash wins (slot order) |
| PASS | §15 | Structures levelled per minute at tier 1, % of all structures (at most 2%) | 0.02 | at most 2.00 | 604 match minutes at this tier |
| PASS | §15 | Structures levelled per minute at tier 2, % of all structures (at most 4%) | 0.25 | at most 4.00 | 448 match minutes at this tier |
| **FAIL** | §15 | Structures levelled per minute at tier 3, % of all structures (3 to 10%) | 2.20 | 3.00 to 10.00 | 539 match minutes at this tier |
| PASS | §15 | Structures levelled per minute at tier 4, % of all structures (6 to 20%) | 8.29 | 6.00 to 20.00 | 921 match minutes at this tier |
| PASS | §11 | Blasts as a share of match damage (10 to 25%, provisional) | 12.3% [12.1%, 12.5%] | 10.0% to 25.0% |  |
| PASS | §11 | Signatures (beams) as a share of match damage (at most 30%, provisional) | 6.7% [6.5%, 6.9%] | at most 30.0% |  |
| **FAIL** | §10 | Damaging melee strikes within 68 units of horizontal reach (hard test, 100%) | 3 of 5274066 strikes beyond 68 units; longest 156.2 | 100% within 68 | lights, heavies and guarded hits, at the damage event, every arm |
| PASS | §10 | A height difference beyond 68 units only on sloped ground (hard test) | 471 strikes with more than 68 units of height difference, 0 of them on flat ground; largest 170.0 | none on flat ground (slope at most 0.15, no ground step between the two) | the slope is read over 80 units at the victim; a ground step between the fighters of half the height difference or more explains it; 1576 follow-up blows on a buried fighter (the dive into the crater) are counted apart |
| PASS | §6 | No biome holds more than 40% of fight time (default): largest is desert | 36.0% | at most 40.0% |  |
| PASS | §6 | Every biome holds at least half its planet share or 3% of fight time, whichever is lower (default arm) | ocean 7.8%, village 12.7%, plains 4.6%, city 3.9%, forest 14.5%, desert 36.0%, mountains 20.5% | see rule |  |
| PASS | §6 | No biome holds more than 40% of fight time (swap): largest is desert | 34.3% | at most 40.0% |  |
| **FAIL** | §6 | No biome holds more than 40% of fight time (mirror-villain): largest is desert | 44.5% | at most 40.0% |  |
| **FAIL** | §6 | No biome holds more than 40% of fight time (mirror-hero): largest is desert | 40.7% | at most 40.0% |  |
| PASS | §6 | No beam variant above 40% of beams: largest is GLASS TRENCH | 39.2% | at most 40.0% |  |
| PASS | §6 | Every beam variant at least 3% of beams (one planet; FIELD SCAR at least 2%, §21) | HORIZON CLEAVE 6.5%, BOULEVARD RAZE 16.4%, FIRESTORM 13.7%, RIDGE BORE 20.2%, GLASS TRENCH 39.2%, FIELD SCAR 3.9% | at least 3.0% each (SCAR 2.0%) |  |
| PENDING | §6 | Location and variant bands over a fixed set of at least 20 seeded planets |  |  | the sim has one planet (W1: variable circumference / procedural planets) |
| INFO | §7 | Parries per 100 melee exchanges | retired |  | the parry window was replaced by the perfect block in step 3 (ADR 0008); the perfect-block rows below carry the band. Measured parries: 0.00 |
| PASS | §7 | Perfect blocks a minute, medium AI (1 to 4; Game Design, melee-press-feel 9f) | 2.55 | 1.00 to 4.00 |  |
| INFO | §7 | Perfect blocks per 100 melee exchanges, medium AI (the old basis, reported; 5 to 15 before the brawl) | 39.38 |  | a brawl is one exchange of many blows; the rows above and below read it a minute and per 100 blows |
| INFO | §7 brawl | Perfect blocks per 100 blows thrown in brawls (the brawl basis; proposed band to be set by Game Design) | 0.90 |  | 6394 perfect blocks over 712529 blows; the per-exchange row above reads 39.38 |
| INFO | §10 brawl | Brawls a minute, blows a minute, closes a minute (flurry staggers), heavy staggers a minute, trade breaks a minute | 2.7, 284.7, 1.1, 4.3, 1.6 |  | proposed basis for "exchanges started a minute": brawls and strings, not exchanges of the old kind |
| INFO | §10 brawl | Median brawl length and blows (B5: 6 to 12 s and 10 blows or more; the share of fight time in a brawl 45 to 60%) | 6.7 s and 78 blows; 40.4% of fight time |  | 6653 brawls in 400 matches (live ticks; 90th percentile 19.9 s) |
| PASS | §9f | Share of fight time in a brawl, the AI against itself (30 to 50%; until the zip the demo target is 25%) | 40.4% | 30.0% to 50.0% |  |
| INFO | §10 brawl | How brawls end, as shares of brawls (the basis for "knock-backs" and "continues": a brawl continues until it ends; the 25 to 35% and 40 to 50% bands read against launch decisions) | signature 45.2%, launch 21.4%, knockback 16.4%, idle 11.4%, break 5.5%, double 0.2% |  | 6653 brawl endings |
| INFO | §2c | Zips a minute, and by kind | 0.28 a minute (513 strikes, 199 heavies over 712) |  | 400 matches |
| PASS | §2c | Zips whose blow lands clean, against an opponent who answers (35 to 55%) | 47.1% [43.4%, 50.7%] | 35.0% to 55.0% |  |
| PASS | §2c | Zips countered by a tech or heavy strike (10 to 25%) | 22.8% [19.8%, 26.0%] | 10.0% to 25.0% |  |
| **FAIL** | §2c | Zips that end with the zipper caught (20 to 35%) | 33.6% [30.2%, 37.1%] | 20.0% to 35.0% | point inside the band, interval outside the widened band |
| PASS | §2c | Ki spent on zips, as a share of all ki spent (at most 25%) | 2.1% | at most 25.0% |  |
| INFO | §2c | Zips reported: blocked, dodged (a zip that completed and did no damage), stopped by a shot, outrun, knocked down, and every end | blocked 13.6%, dodged 7.7%, stopped by a shot 7.4%, outrun 4.4%, down 0.0%; ends {"caught":239,"done":227,"outrun":31,"countered":162,"shot":31,"stopped":22} |  | 712 zips in 400 matches |
| PASS | §2c | A zip costs exactly the table ki, paid at the press (hard test) | 712 of 712 on the table (read from the ki a tick later: within 0.5) | strike 20, heavy 30 | read as the ki the zipper held the tick before the cue less the ki after it (within 0.5, the regeneration of one tick); records made before the harness read the director line |
| PASS | §2c | A zip tell is the table ticks and its whole length is in the table range for the default exit (hard test; the ticks in reach are the zip.reach row) | 712 of 712 on the table | strike tell 6, whole 32 to 34; heavy tell 10, whole 52 to 54 (up to 12 more for a longer exit) | the tell and the whole length; the ticks in reach are read from the cues in the next row |
| PASS | §2c | The ticks in reach before and after the blow are exactly the table: strike 4 and 6 (8 before when held), heavy 12 and 10 (4 off a rushed tap, two at most) (hard test) | 483 played zips and 712 plans on the table | strike 4 and 6 (held 8 before); heavy 12 and 10 | the plan is read at the press; the played ticks at zip_out. A zip countered or caught before its blow has no zip_out and is not read. The zip away shapes (4 and 4, 6 and 8) are accepted |
| PASS | §2c | Travel is never under the floor, each way: at least max(4, ceil(distance in bh / 3)) ticks (Legal RL-076, a hard test) | 712 of 712 at or over the floor | at least max(4, ceil(bh / 3)) ticks | the way in is the cue n over the start distance; the way out is zip_out n over the path from the zipper to the exit point |
| PASS | §2c | No stick exit over 12.5 bh from the rival or inside the ground or a building; the home exit is exempt (hard test) | 104 exits checked (608 home) | at most 12.5 bh, never inside | inside is World blockedAt at the exit point with no margin |
| PASS | §2c | No brawl is announced during a zip unless the zipper is caught or countered (hard test) | 0 over 712 zips | never | a brawl_start while the zip is open whose text is not caught or countered |
| INFO | §2c | The dropped state: drop_start, drop_land and drop_end (reported; every start should land and end, apart from a KO in the air) | 0 starts, 0 lands, 0 ends |  | 400 matches |
| INFO | §7 second pass | Double hits a match, the AI against itself (reported; the band 0.5 to 2 is for a presser against the medium AI: the double.presser rows) | 0.03 |  | 400 matches; none is in order between AIs (no level trade lasts 240 ticks) |
| INFO | §7 second pass | Matches with at least one double hit, the AI against itself (reported) | 2.5% (10 of 400) |  | the band 35 to 65% is for a presser against the medium AI |
| PASS | §7 second pass | Never more than 4 double hits in one match (hard test) | the most in one match is 1 | at most 4 | 400 matches |
| PASS | §7 second pass | Every double_hit cue ends its brawl with the text double, and every double end follows a cue (hard test; a KO in the 8 ticks between may cost one) | 10 cues, 10 double ends | equal (within 2%) |  |
| PASS | §7 second pass | Every double hit comes from a trade level for 240 ticks (hard test: the cue's dur, the trade's length, is 240 to 244) | 10 of 10 at 240 to 244 | 240 to 244 | a hit freeze may add a tick or two |
| PASS | §7 second pass | Both fighters are hit by a double hit (hard test) | 10 of 10 hit both | both take damage on the landing tick | damage events on the landing tick and the next, by victim |
| INFO | §7 second pass | The double hit: damage to each and the separation 30 ticks after the landing (reported; the rule: 4 brawl lights each, thrown back 6 bh each way, so about 12 bh apart from the centre) | 37.0 and 40.5 damage; apart 0.8 bh at the throw, 8.9 bh after 30 ticks |  | 10 double hits |
| INFO | §7 second pass | Perfect blocks per 100 blows by strength (reported; held as bands after the first three-strength baseline: lights 0.5 to 1.5, mediums 2 to 6, heavies 6 to 15 at medium) | no perfect block carries its strength on this build (the stagger source) |  | 400 matches; the total per 100 blows is retired as a band |
| PASS | §5b | Energy blows as a share of the AI's brawl blows (5 to 15%) | 8.5% | 5.0% to 15.0% |  |
| PASS | §1 second pass | The AI winds up or charges a medium or a heavy, a minute of brawl, per fighter (4 to 10; an AI-against-AI match has two fighters, so the total is counted twice: 13.9 in all) | 6.93 | 4.00 to 10.00 |  |
| PASS | §7 | Chains per 100 melee exchanges (10 to 30, agency pass 14; strings now come from the presses) | 15.57 | 10.00 to 30.00 |  |
| PASS | §7 | Pursuit slip rate (escape gamble) | 48.4% [46.4%, 50.5%] | 35.0% to 65.0% |  |
| PASS | §7 | Beam escape rate against an ESCAPE defender | 28.1% [23.4%, 33.5%] | 20.0% to 50.0% |  |
| PENDING | §7 | Fixed-stance round robin: no forced stance above 55%, each stance below 45% against some other |  |  | needs the stance probe of stance-matrix.md §6 (two role-neutral fighters, one stance forced): not in the sim yet |
| INFO | §8 | Hides and ambushes | retired |  | hiding is removed from the base game and kept for a future stealth fighter (balance-targets §8); the rows return with that fighter (canHide) |
| PENDING | §13 | Signatures fired per match (2 to 4, median 3) | today 11.0 (median) | 2 to 4 | pending Q4: the 120 s signature cooldown is not in the sim yet |
| PASS | §8 | Beam clashes: share of signatures fired that end in a CLASH (30 to 60%; re-based at G0) | 41.2% [39.6%, 42.7%] | 30.0% to 60.0% |  |
| PASS | §1c | No lock break longer than 4 s, all arms (hard test) | longest 4.02 s (swap seed 162 from 565.3 s); 0 over 4 s of 7263 | at most 4 s | GB-008: sim/director/launch.gd:316 and sim/core/fighter.gd:319 clear `hidden` with no regainLock, so no `found` is emitted and the episode stays open |
| PASS | §1c | Lock breaks per match (1 to 4) | 2.62 | 1.00 to 4.00 |  |
| **FAIL** | §1c | Median lock-break length (2 to 3 s) | 1.4 s | 2.0 s to 3.0 s |  |
| PASS | §1c | No lock break longer than 4 s (hard test) | longest 4.02 s over 1048 breaks | at most 4 s | episodes are read from searching and found events; a hunt sweep with no lock loss can lengthen one |
| PASS | §1c | Never within 6 s of the same fighters last one (hard test) | shortest gap 6.88 s over 520 | at least 6 s |  |
| INFO | §1c | Attacks refused for lost lock (lock_lost) per match | 0.17 |  |  |
| PASS | §8 | Brink to KO, median (45 to 90 s) | 74.2 s | 45.0 s to 90.0 s |  |
| **FAIL** | §8 | First brink, median (4:30 to 7:00) | 267.7 s | 270.0 s to 420.0 s |  |
| PASS | §8 | Finisher survival rate (25 to 40%) | 32.1% [28.4%, 36.0%] | 25.0% to 40.0% |  |
| PASS | §8 | Rallies per match (0.3 to 0.7) | 0.41 | 0.30 to 0.70 |  |
| PASS | §8 | Region breaks per match (1.5 to 2.5) | 2.25 | 1.50 to 2.50 |  |
| **FAIL** | §8 | Limb breaks per match (0.3 to 0.5) | 0.22 | 0.30 to 0.50 |  |
| **FAIL** | §8 | Arms share of limb breaks (35 to 65%; legs is the rest) | 93.1% | 35.0% to 65.0% |  |
| PASS | §8 | Second breath: battered wear recovered through it, as a share of all battered wear taken (at most 25%) | 21.7% | at most 25.0% |  |
| INFO | §10 k | Damage per minute to the loser (input to the k retune: k_new = k_old x rate before / rate after) | 1739.8 |  | volleys and beam-clash chip count once Encounter Q4 lands, so k absorbs them; median length target 6 to 8 min, p10 at least 5:00, timeouts at most 1% |
| PENDING | §8 | Blitz rate: 2 to 6 a minute in Tense and Frenzied acts |  |  | needs a `blitz` fx event and the act (mood) per event (Encounter Q4) |
| PENDING | §8 | Comebacks 15 to 35% of matches; lead changes median at least 2 |  |  | needs the brink and region stages (Wounds S1, S2) |
| **FAIL** | §9 | Mood: Calm share of match time (20 to 40%, re-based for the brawl, spec-wounds §9) | 41.9% | 20.0% to 40.0% |  |
| PASS | §9 | Mood: Tense share of match time (40 to 65%, re-based for the brawl, spec-wounds §9) | 54.9% | 40.0% to 65.0% |  |
| **FAIL** | §9 | Mood: Frenzied share of match time (5 to 20%) | 3.1% | 5.0% to 20.0% |  |
| PASS | §9 | Calm share of act 1 (at least 60%) | 99.1% | at least 60.0% |  |
| **FAIL** | §9 | Frenzied share of act 4, the climax (at least 15%) | 8.3% | at least 15.0% |  |
| **FAIL** | §9 | Act 2 starts at, median (1:30 to 2:30) | 89.3 s | 90.0 s to 150.0 s |  |
| **FAIL** | §9 | Act 3 starts at, median (2:30 to 4:00) | 149.6 s | 150.0 s to 240.0 s |  |
| **FAIL** | §9 | Act 4 starts at, median (4:30 to 5:45) | 231.8 s | 270.0 s to 345.0 s |  |
| **FAIL** | §9 | Act 4 arrives before the first brink (at least 80% of matches with a brink) | 79.8% [75.5%, 83.4%] | at least 80.0% |  |
| PASS | §9 style | Style label entries per fighter per match, median (at most 3; AI play) | 1.00 | at most 3.00 |  |
| PASS | §9 style | Style label events per fighter per match, entries and endings, median (at most 5) | 2.00 | at most 5.00 |  |
| PASS | §9 style | Shortest label held (at least 12 s; a label cut off by the KO is not counted) | 30.0 s | at least 12.0 s |  |
| PASS | §9 style | Unlabelled share of match time, mean (at most 40%) | 18.5% | at most 40.0% |  |
| **FAIL** | §10 | Exchanges started per minute (15 to 28, agency pass 14) | 8.23 | 15.00 to 28.00 |  |
| INFO | §10 | Exchange length, request to release, median | retired |  | retired by the dynamic feel (G0 triage); the feel rows replace it. Measured: 1.37 s |
| INFO | §10 | Breathing room, release to the next request, median | retired |  | replaced by the feel row release to next request at most 1.0 s. Measured: 1.38 s |
| PASS | §10 | Matches with no gap over 10 s (a gap: no strike, blast, charge or taunt from either fighter) | 99.0% [97.5%, 99.6%] | at least 95.0% |  |
| **FAIL** | §10 | Exchanges that end in a launch, of those that reach a launch decision (18 to 30%, agency pass 14) | 32.1% [31.2%, 33.0%] | 18.0% to 30.0% |  |
| PASS | §10 | Exchanges that end in a knock-back, of those that reach a launch decision (25 to 35%, agency pass 14) | 28.1% [27.3%, 29.0%] | 25.0% to 35.0% |  |
| **FAIL** | §10 | Launches as a share of the exchanges that separate the fighters (a knock-back or a launch; 25 to 40%, around Orb 30) | 53.3% [52.1%, 54.5%] | 25.0% to 40.0% |  |
| **FAIL** | §10 | Exchanges after which the brawl continues (STAY), of those that reach a launch decision (40 to 50%) | 39.8% [38.8%, 40.7%] | 40.0% to 50.0% |  |
| INFO | §10 | Melee exchanges: reach a launch decision / of those launch, knock-back, stay | 49.7% reach one; 32.1% / 28.1% / 39.8% |  | the rest end with no launch decision (a light string that never reaches a launch beat) |
| INFO | §10 | Launches as a share of exchanges, planner launches over all exchanges (old row, band 40 to 65% retired by agency pass section 3) | 22.5% |  | the standing row is 10.end.launch |
| **FAIL** | §10 | Launches with at least 9,000 units of horizontal travel (1,500 x the launch traversal factor) | 29.9% | at least 30.0% |  |
| PASS | §10 | Launches that land in a different biome | 46.1% | at least 25.0% |  |
| PASS | §10 | Fight time underwater (both fighters) | 0.5% | at most 10.0% |  |
| PENDING | §10 | Strike spacing, wind-up width, hit-stop floors, gap-close flight |  |  | read from data and atoms, not from a batch: Combat and Controls own them (needs the event log of the composer) |
| PASS | §11 | Low-tier bleed with every living-destruction source included (same measure as §4) | 0.16 | at most 4.00 | % of population per minute |
| PENDING | §11 | Spreading fires: 0.5 to 3 in matches with 5% of fight time in forest or villages |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Forest burnt at the end among tier-3 matches: 15 to 60% of trees |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Cover-capable clouds 3 to 10 |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Real slides 0.5 to 2; at most 1 peak collapse |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Quakes in 30 to 70% of tier-4 matches, at most 2; rifts at most 1 |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Lava events 1 to 3 in tier-4 matches |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| PENDING | §11 | Hazard share of all wear at most 15% |  |  | no hazard events in the sim yet (living destruction LD1 to LD3, docs/design/living-destruction-numbers.md) |
| **FAIL** | §7 | Perfect blocks a minute, easy AI (0.5 to 2; Game Design, melee-press-feel 9f) | 2.53 | 0.5 to 2 | 100 default-arm matches at easy; point estimate; per 100 blows 0.93 |
| INFO | §7 | Perfect blocks per 100 melee exchanges, easy AI (the old basis, reported; 3 to 8 before the brawl) | 35.50 |  | 100 default-arm matches at easy |
| PASS | §7 | Perfect blocks a minute, hard AI (2 to 5.5; Game Design, melee-press-feel 9f) | 5.18 | 2 to 5.5 | 100 default-arm matches at hard; point estimate; per 100 blows 3.75 |
| INFO | §7 | Perfect blocks per 100 melee exchanges, hard AI (the old basis, reported; 12 to 20 before the brawl) | 50.28 |  | 100 default-arm matches at hard |

## Masher stage rows (`qa/godot/masher-only.js`, 58 jobs)

| Status | Id | Measure | Value | Band | Note |
| :--- | :--- | :--- | :--- | :--- | :--- |
| PASS | masher.easy | A scripted masher (light every 8 S.ticks, takes forms) wins against the easy AI | 92.0% (92 of 100) | at least 60% | 100 matches, 0 timed out, median 162.2 s; point estimate only; per match: launches by the masher 3.76, of which air catches 0.18; launches on the masher 5.89, air catches 0.45 |
| **FAIL** | masher.medium | A scripted masher (light every 8 S.ticks, takes forms) wins against the medium AI | 54.0% (54 of 100) | 35 to 50% | 100 matches, 0 timed out, median 181.2 s; point estimate only; per match: launches by the masher 3.1, of which air catches 0.41; launches on the masher 7.07, air catches 0.61 |
| PASS | masher.hard | A scripted masher (light every 8 S.ticks, takes forms) wins against the hard AI | 0.0% (0 of 100) | at most 15% | 100 matches, 0 timed out, median 198.2 s; point estimate only; per match: launches by the masher 1.8, of which air catches 0.3; launches on the masher 16.1, air catches 1.51 |
| INFO | masher.noforms.easy | A scripted masher (light every 8 S.ticks, no forms) wins against the easy AI | 82.0% (82 of 100) | (at least 60% if forms are taken) | 100 matches, 0 timed out, median 166.3 s; point estimate only; a beginner who never transforms fights at tier 1 (Game Design to rule); per match: launches by the masher 3.1, of which air catches 0.22; launches on the masher 5.98, air catches 0.45 |
| INFO | masher.noforms.medium | A scripted masher (light every 8 S.ticks, no forms) wins against the medium AI | 25.0% (25 of 100) | (35 to 50% if forms are taken) | 100 matches, 0 timed out, median 179 s; point estimate only; a beginner who never transforms fights at tier 1 (Game Design to rule); per match: launches by the masher 1.92, of which air catches 0.21; launches on the masher 8.2, air catches 0.95 |
| INFO | masher.noforms.hard | A scripted masher (light every 8 S.ticks, no forms) wins against the hard AI | 0.0% (0 of 100) | (at most 15% if forms are taken) | 100 matches, 0 timed out, median 197.7 s; point estimate only; a beginner who never transforms fights at tier 1 (Game Design to rule); per match: launches by the masher 1.41, of which air catches 0.25; launches on the masher 16.77, air catches 1.82 |
| INFO | masher.medium.g6 | A scripted masher (light every 6 S.ticks, takes forms) wins against the medium AI | 84.0% (84 of 100) | 35 to 50% | 100 matches, 0 timed out, median 176.6 s; point estimate only; per match: launches by the masher 3.45, of which air catches 0.2; launches on the masher 6.81, air catches 0.43 |
| INFO | masher.medium.g10 | A scripted masher (light every 10 S.ticks, takes forms) wins against the medium AI | 10.0% (10 of 100) | 35 to 50% | 100 matches, 0 timed out, median 175.6 s; point estimate only; per match: launches by the masher 1.83, of which air catches 0.09; launches on the masher 8.35, air catches 0.64 |
| PASS | masher.bolt.finish | A bolt-only player (energy held, a bolt every 8 ticks) finishes the match against a melee masher before the cap (agency pass 16: at least 95%) | 100.0% (40 of 40; 0 ran to the cap) | at least 95% | median 115.1 s; point estimate |
| PASS | masher.bolt.medium | A bolt-only player wins against the medium AI (agency pass 16: 20 to 40%) | 38.0% (38 of 100) | 20 to 40% | 100 matches, 0 ran to the cap; point estimate |
| **FAIL** | masher.blast.rush | A blast-heavy timed script (a bolt about every 14 ticks) against a rush-heavy timed script (agency pass 15.6: 40 to 60%, and at least 95% of matches finish) | 100.0% (40 of 40); 100% finished | 40 to 60%, finish at least 95% | 40 matches, 0 ran to the cap; point estimate |
| **FAIL** | masher.blast.rushslow | The slow blaster (L L and a tapped H, one press every 24 ticks) against a rush-heavy timed script: at least 95% of matches finish before the cap (slice 12 is meant to fix this; 40 to 60% for the win share) | 100.0% (32 of 32); 80% finished | 40 to 60%, finish at least 95% | 40 matches, 8 ran to the cap; point estimate |
| INFO | masher.zip.medium | A player who only zip strikes (LT then a light, in the mid band) against the medium AI (reported) | 1.0% (1 of 100); 891 zips in 100 matches, ends {"caught":93,"countered":153,"done":442,"outrun":12,"shot":68,"stopped":123} | reported | 100 matches, 0 ran to the cap |
| PASS | masher.blast.medium | A mixed blaster (a bolt about every 14 ticks, a tapped heavy now and then) wins against the medium AI (agency pass section 22: 30 to 50%) | 49.0% (49 of 100) | 30 to 50% | 100 matches, 0 ran to the cap; point estimate |
| INFO | masher.blast.slowmedium | The slow blaster (L L and a tapped H, one press every 24 ticks) wins against the medium AI (reported; the band of the mixed blaster, 30 to 50%, is the reference) | 4.0% (4 of 99) | (25 to 45%) | 100 matches, 1 ran to the cap; point estimate |
| INFO | c1.drift.one | How far a held stick moves a brawl, after its ramp: one fighter holds east, the other none (reported, bh a second; the design is 0.4 of free-flight speed for one stick and 0.8 for two) | 2.411 bh a second along the stick; 1184 drifts | reported | largest step 0.05 bh a tick |
| **FAIL** | c1.centre.latency | The centre moves at all within 2 live ticks of a stick (hard test; it answers on the tick after the stick is first read, small at first; the striking state, a lights mash) | 99.9% of 1184 drifts moved within 2 live ticks; histogram {"1":334,"2":849,"999":1} (999 means it never moved) | at most 2 ticks | 1184 drifts; read from DirBrawl.centre velocity when it has one, else from a step over 0.15 units; the other states (charging, guarding, reeling) are for the C2 slices |
| PASS | c1.centre.step.one | The nudge never moves the pair more than 0.3 bh in a tick (hard test, read on the centre's speed, every tick of every brawl in this run: one stick; the pair's middle jumping because a strike placed its attacker is reported beside it) | 0 of 328911 brawl ticks over; the fastest 0.064 bh a tick. Reported: the middle moved over 0.3 bh on 0 of 264591 ticks, the largest 0.278 bh | at most 0.3 bh a tick | 60 matches |
| **FAIL** | c1.dead | No live tick of a brawl with a dead stick, outside a knock-back and its kind (hard test; states reached: striking and mashing, staggered, reeling; the wind-up, charge and guard states come with C2a and C2b) [a lights masher holding east against a rival with no stick] | 655 dead ticks of 318922 held LIVE ticks (0.2%); a further 121896 held ticks fell in a hit freeze and are not counted; by direction {"east":"655 of 318922"}; by state {"locked":655}; by cause {"ground":367,"other":287,"stun":1} | none | 60 matches; before C1 this is the lock itself (every held tick of a locked fighter is dead; 12,369 of 15,323 on 53d13b55 in a 2-match smoke); a fighter against a building face or the ground also stops, which this read cannot tell from a dead stick: look at the states first |
| **FAIL** | c1.dead.ai | No live tick of a brawl with a dead stick, outside a knock-back and its kind (hard test; states reached: striking and mashing, staggered, reeling; the wind-up, charge and guard states come with C2a and C2b) [a presser holding toward against the medium AI] | 1546 dead ticks of 371251 held LIVE ticks (0.4%); a further 186750 held ticks fell in a hit freeze and are not counted; by direction {"toward":"1546 of 371251"}; by state {"locked":1546}; by cause {"building":601,"ground":234,"other":654,"stun":57} | none | 60 matches; before C1 this is the lock itself (every held tick of a locked fighter is dead; 12,369 of 15,323 on 53d13b55 in a 2-match smoke); a fighter against a building face or the ground also stops, which this read cannot tell from a dead stick: look at the states first |
| PASS | c1.aihold | The medium AI holds its own stick against a player's held stick on under 25% of the ticks he holds it (DirBrawl.stick) | 20.6% (5286 of 25650 ticks) | under 25% | 433 drifts against the AI |
| PASS | c1.aistick | A held stick against the medium AI moves the brawl at least 0.7 as far as against a rival who holds no stick (the AI holds against it on under 25% of the ticks: that read needs the AIs stick on a cue) | 0.95 (2.291 bh a second against the medium AI, 2.411 against a rival with no stick) | at least 0.7 | 433 drifts against the AI and 1184 against the script; point estimates |
| INFO | c1.drift.both | How far a held stick moves a brawl, after its ramp: both hold east (reported, bh a second; the design is 0.4 of free-flight speed for one stick and 0.8 for two) | 4.562 bh a second along the stick; 2390 drifts | reported | largest step 0.097 bh a tick |
| PASS | c1.centre.step.both | The nudge never moves the pair more than 0.3 bh in a tick (hard test, read on the centre's speed, every tick of every brawl in this run: two sticks; the pair's middle jumping because a strike placed its attacker is reported beside it) | 0 of 329233 brawl ticks over; the fastest 0.097 bh a tick. Reported: the middle moved over 0.3 bh on 0 of 264871 ticks, the largest 0.279 bh | at most 0.3 bh a tick | 60 matches |
| PASS | c1.walk.both | Both fighters hold away within 45 degrees: the brawl ends walk, never sooner than 12 ticks after the later stick (hard test; free, nobody decisive) | 16036 walk ends in 16036 brawls where both sticks were away (100%); 0 came under 12 ticks after the later stick or the jab; the shortest was 14 ticks and the longest 20 | never under 12 ticks; the walk must happen | 60 matches; the other ends of those brawls: {"break":43} |
| PASS | c1.walk.jab | A blow thrown by either fighter in the 12 ticks starts the count again: the end comes at least 12 ticks after the blow press (hard test) | 12033 walk ends in 12041 brawls where both sticks were away (100%); 0 came under 12 ticks after the later stick or the jab; the shortest was 21 ticks and the longest 22 | never under 12 ticks; the walk must happen | 60 matches; the other ends of those brawls: {"break":30} |
| PASS | c1.walk.guard | The 12 ticks count while either guards: both walk with guards held, and the brawl still ends walk, never early (hard test) | 16011 walk ends in 16011 brawls where both sticks were away (100%); 0 came under 12 ticks after the later stick or the jab; the shortest was 14 ticks and the longest 22 | never under 12 ticks; the walk must happen | 60 matches; the other ends of those brawls: {"break":42} |
| PASS | c1.walk.held | The 12 ticks do not count while an attack button is held: one fighter holds the light button while both hold away, and no walk end comes (hard test) | 0 walk ends in 60 matches (7260 brawls; 7200 with both sticks away) | none | a brawl that ends for any other reason is not counted |
| PASS | c1.walk.one | One fighter alone cannot end a brawl by walking: the other keeps mashing, and no walk end comes (hard test) | 0 walk ends in 60 matches (134 brawls; 0 with both sticks away) | none | a brawl that ends for any other reason is not counted |
| PENDING | zip.drop.bolt | A real bolt that reaches the zipper on the way out drops him: zip_end down, then drop_start, drop_land, drop_end, and the state dropped between (hard test) | no bolt reached a zipper on the way out in 100 matches (168 zips; ends {"done":47,"shot":121}): a coverage gap, not a pass | every down is a drop | the turret presses a bolt on each tick of the way out and after the blow, with chance 50% |
| PASS | zip.drop | A shot reported on the way out (DirZip.shot, the way the module check does) drops the zipper: zip_end down, then drop_start, drop_land, drop_end, and the state dropped between (hard test) | 178 zips ended down; 178 drop_start, 3 drop_land, 178 drop_end; the state was not dropped at 0 starts and still dropped at 0 ends | one drop_start and one drop_end for every down, the state dropped between; drop_land at most one each (a drop that began on the ground may have no land: reported) | 100 matches, 178 zips; ends {"down":178} |
| PASS | double.presser.max.lights | Never more than 4 double hits in a match for a steady presser against the medium AI (hard test; X every 8 ticks, stick toward) | the most in one match is 2 (mean 0.70) | at most 4 | 100 matches |
| PASS | double.presser.lights | Double hits against the medium AI by a lights-only presser (stick toward): a match, and matches with at least one (0.5 to 2; 35 to 65%) | 0.70 a match; 58.0% of matches (58 of 100); 70 double hits | 0.5 to 2; 35 to 65% | 100 matches; measured on C1 at 0.3 and 0.2, tuned on C2a by the AI's digIn; the trade length on the cue is the double.trade240 row |
| PASS | double.presser.max.mix | Never more than 4 double hits in a match for a steady presser against the medium AI (hard test; L L H, stick toward) | the most in one match is 1 (mean 0.03) | at most 4 | 100 matches |
| **FAIL** | double.presser.mix | Double hits against the medium AI by a mixing presser (L L H, stick toward): a match, and matches with at least one (0.5 to 2; 35 to 65%) | 0.03 a match; 3.0% of matches (3 of 100); 3 double hits | 0.5 to 2; 35 to 65% | 100 matches; measured on C1 at 0.3 and 0.2, tuned on C2a by the AI's digIn; the trade length on the cue is the double.trade240 row |
| **FAIL** | masher.str-y | a Y masher (a medium every 12 ticks) against the medium AI (20 to 50%: no single button mashed should beat medium more than half the time, and none should be shut out) | 0.0% (0 of 100); 0 ran to the cap | 20 to 50% | 100 matches; blows {"blast":27,"bolt":4871,"heavy":1492,"light":62938,"medium":41658,"release":1} |
| **FAIL** | masher.str-b | a B masher (a heavy every 30 ticks) against the medium AI (20 to 50%: no single button mashed should beat medium more than half the time, and none should be shut out) | 100.0% (100 of 100); 0 ran to the cap | 20 to 50% | 100 matches; blows {"blast":14,"bolt":2960,"heavy":15521,"light":26187,"medium":3859,"release":2} |
| PASS | closing.d | A blow lands d ticks later than its own time, d from 0 to 4 (2 ticks a bh of gap, at most 4): the cue's landing tick less the press tick, less the wind-up (hard test; the exact formula is checked when the gap's definition is confirmed) | 0 of 400 outside 0 to 4; the largest d 4 | 0 to 4 ticks | samples [wind-up, ticks to landing, gap bh]: [[2,6,2.51],[12,12,0.77],[28,28,0.77],[12,12,0.77],[28,28,0.77],[12,12,0.77]] |
| PASS | closing.step | No blow moves its attacker more than 0.6 bh in a tick (hard test from C2t; reported before it) | 0 of 97785 blows moved their attacker over 0.6 bh in the tick; the most 0.591 bh | at most 0.6 bh a tick | 100 matches |
| INFO | masher.str-alt | the alternator (X, Y, B in turn, a press every 12 ticks) against the medium AI (reported; the X masher's 35 to 50% is kept) | 72.0% (72 of 100); 0 ran to the cap | reported | 100 matches; blows {"blast":19,"bolt":5266,"heavy":14971,"light":57733,"medium":20433} |
| INFO | masher.str-holdx | the player who only holds X (60 ticks down, 8 up) against the medium AI (reported; the X masher's 35 to 50% is kept) | 0.0% (0 of 100); 0 ran to the cap | reported | 100 matches; blows {"blast":26,"bolt":5528,"heavy":1263,"light":127228,"medium":978,"release":10} |
| INFO | masher.str-x10b | the 10-tick tapper with B (X X B) against the medium AI (reported; the X masher's 35 to 50% is kept) | 100.0% (100 of 100); 0 ran to the cap | reported | 100 matches; blows {"blast":17,"bolt":3973,"heavy":16240,"light":59381,"medium":4252,"release":1} |
| **FAIL** | flurry.xy | The X flurry beats the Y flurry (it lands twice as many blows) (60 to 90%: two fixed rhythms give nearly the same result every time, and a lock at 100% leaves the loser nothing) | 100.0% (100 of 100) | 60 to 90% | 100 matches, the second player on a seeded offset of 0 to 7 ticks; point estimate (about ±10 points) |
| **FAIL** | flurry.yb | The Y flurry beats the B flurry (a medium lands inside the 20 ticks in which a heavy can be stopped) (60 to 90%: two fixed rhythms give nearly the same result every time, and a lock at 100% leaves the loser nothing) | 98.0% (98 of 100) | 60 to 90% | 100 matches, the second player on a seeded offset of 0 to 7 ticks; point estimate (about ±10 points) |
| **FAIL** | flurry.bx | The B flurry beats the X flurry (lights do not stop a heavy) (60 to 90%: two fixed rhythms give nearly the same result every time, and a lock at 100% leaves the loser nothing) | 32.9% (25 of 76) | 60 to 90% | 100 matches, the second player on a seeded offset of 0 to 7 ticks; point estimate (about ±10 points) |
| **FAIL** | route.easy | The launcher's route launches in 70 to 90% of the brawls it is tried in against the easy AI (launches by the route's player over brawls) | 66.6% (703 launches in 1055 brawls); route player wins 86.0% | 70 to 90% | 100 matches; an approximation: launches, not brawls with a launch |
| PASS | route.every.easy | From a stagger of 12 ticks or more a tapped B lands and launches, every time (hard test), against the easy AI | 373 launchers used and 0 lapsed by the route's player; 703 launches by him | none lapsed, a launch for each | 565 launcher_open cues in 100 matches |
| PASS | route.medium | The launcher's route launches in 50 to 75% of the brawls it is tried in against the medium AI (launches by the route's player over brawls) | 75.0% (893 launches in 1191 brawls); route player wins 15.0% | 50 to 75% | 100 matches; an approximation: launches, not brawls with a launch |
| PASS | route.every.medium | From a stagger of 12 ticks or more a tapped B lands and launches, every time (hard test), against the medium AI | 334 launchers used and 0 lapsed by the route's player; 893 launches by him | none lapsed, a launch for each | 688 launcher_open cues in 100 matches |
| **FAIL** | route.first30 | A first launch inside 30 s of the first brawl, in at least 65% of matches at medium (a first launch needs a close, and how often a masher earns one is the brawl's own texture) | 60.0% of 100 matches (100 had a launch at all) | at least 65% | a launch by the route's player |
| **FAIL** | route.first60 | A first launch inside 60 s of the first brawl, in at least 90% of matches at medium | 83.0% of 100 matches | at least 90% | a launch by the route's player |
| PASS | route.perMatch | Launches a match at medium: by the route's player (4 to 10), and on him (4 to 8); collateral is reported beside it (the arms' rows) | 8.93 by him, 5.89 on him | 4 to 10; 4 to 8 | 100 matches; point estimates |
| **FAIL** | route.hard | The launcher's route launches in 30 to 55% of the brawls it is tried in against the hard AI (launches by the route's player over brawls) | 59.4% (1531 launches in 2578 brawls); route player wins 0.0% | 30 to 55% | 100 matches; an approximation: launches, not brawls with a launch |
| PASS | route.every.hard | From a stagger of 12 ticks or more a tapped B lands and launches, every time (hard test), against the hard AI | 263 launchers used and 0 lapsed by the route's player; 1531 launches by him | none lapsed, a launch for each | 491 launcher_open cues in 100 matches |
| PASS | give.lat.b-free | A fighter with his hands down moves within 2 ticks of his stick while the rival winds up (hard test) | the slowest first step came 2 ticks after the stick (10021 wind-ups; -1 means he never moved) | at most 2 ticks | 60 matches |
| PASS | give.out.b | Out of a tapped heavy that is not followed, every time, when he starts by tick 16 (hard test: the blow ends as a miss with the text gave_ground) | 7379 of 7379 gave ground when he started by tick 16; later starts: 358 of 2582 (reported) | every time | miss texts {"gave_ground":7737} |
| PASS | give.lat.b-follow | A fighter with his hands down moves within 2 ticks of his stick while the rival winds up (hard test) | the slowest first step came 1 ticks after the stick (7453 wind-ups; -1 means he never moved) | at most 2 ticks | 60 matches |
| PASS | give.followed.b | Out of a tapped heavy that is followed from its first tick: never (hard test) | 0 of 7382 gave ground | none | miss texts {"reach":1} |
| PASS | give.lat.y-free | A fighter with his hands down moves within 2 ticks of his stick while the rival winds up (hard test) | the slowest first step came 2 ticks after the stick (21038 wind-ups; -1 means he never moved) | at most 2 ticks | 60 matches |
| INFO | give.medium.free | Out of a tapped medium: only from its first 6 ticks, and never when followed (reported) | 6380 of 6403 gave ground when he started in the first 6 ticks; later starts 161 of 14635 | reported | miss texts {"gave_ground":6541} |
| **FAIL** | give.lat.y-follow | A fighter with his hands down moves within 2 ticks of his stick while the rival winds up (hard test) | the slowest first step came 3 ticks after the stick (22492 wind-ups; -1 means he never moved) | at most 2 ticks | 60 matches |
| INFO | give.medium.followed | Out of a tapped medium that is followed: only from its first 6 ticks, and never when followed (reported) | 0 of 6850 gave ground when he started in the first 6 ticks; later starts 0 of 15642 | reported | miss texts {} |
| PASS | energy.bolt | A point-blank bolt lands 2 ticks after its press, plus the closing rule's d (0 to 4) when it was pressed from a gap (hard test: the announced contact tick less the press tick) | 54611 of 54784 announced at exactly 2 ticks, 54784 within 2 to 6 ({"blast:12":18,"bolt:2":54611,"bolt:3":61,"bolt:4":39,"bolt:5":34,"bolt:6":39}) | 2 (in reach), up to 6 (from a gap) | 60 matches |
| PASS | energy.flash | No more than three full flashes in any second, and one blow in 20 ticks at most may take one (hard test; a mashed RB + X) | 22833 full flashes; the most in 60 ticks 3; the shortest gap 20 ticks | at most 3 in 60 ticks, 20 ticks apart | 60 matches; sources {"blast:hit":10,"bolt:armour":697,"bolt:guard":10464,"bolt:hit":43287} |
| **FAIL** | energy.blast | A clean blast's own knock-back is 4 bh (hard test: the knock-back of its target within 3 ticks; since the follow-up a cold blast has none of its own and knocks back only as a string's ender) | 17 of 385 clean blasts knocked back, 17 off 4 bh by more than 0.25 (range 0.03 to 3.5); the other 368 were cold | 4 bh, within 0.25 | 729 blasts pressed; sources {"blast:guard":175,"blast:hit":385,"bolt:hit":2154} |
| **FAIL** | burst.share | The burst (a held X) against a mash (X every 8 ticks), damage a second against a rival who never moves: 70 to 80%, never over | 58.4% (35.6 against 60.9 damage a second; 3690 bursts, 0 of eight blows) | 70 to 80% | 30 matches each; damage per match over the match's median length, a rough read |
| PASS | masher.blur.blind | The perfect blur locks on a blind 8-tick masher: share of five-blow strings against the medium AI (agency pass 20) | 11.5% (163 of 1423 strings) | at most 20% | 100 matches; the script wins 0%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes |
| **FAIL** | masher.blur.contact | The perfect blur locks on a script that presses on every contact and follows the links: share of five-blow strings against the medium AI (agency pass 20) | 11.6% (197 of 1704 strings) | at least 80% | 100 matches; the script wins 0%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes |
| PASS | masher.blur.m10 | The perfect blur locks on a blind metronome every 10 ticks: share of five-blow strings against the medium AI (agency pass 20) | 5.6% (99 of 1769 strings) | at most 20% (assumed ceiling) | 100 matches; the script wins 0%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes |
| PASS | masher.blur.m12 | The perfect blur locks on a blind metronome every 12 ticks: share of five-blow strings against the medium AI (agency pass 20) | 3.9% (69 of 1770 strings) | at most 20% (assumed ceiling) | 100 matches; the script wins 0%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes |
| PASS | masher.blur.m14 | The perfect blur locks on a blind metronome every 14 ticks: share of five-blow strings against the medium AI (agency pass 20) | 4.6% (81 of 1779 strings) | at most 20% (assumed ceiling) | 100 matches; the script wins 0%; metronome rows are reported and never fail the build (Controls measured the cause, a press inside a hit-stop is graded just after the blow, and the fix is parked with Orb); measured live as blur_locked cues over exchanges with five or more landed light strikes |
| PASS | masher.mirror | Two lights-only players (mashers who take their forms) finish the match before the cap | 100.0% (200 of 200; 0 ran to the cap) | at least 95% | median 205.9 s; point estimate |
| PASS | masher.brink | Lights-only mirror: brink to KO, median (read against the overall 45 to 90 s: the 25 to 50 s band was derived when a level trade ended in a draw, and that rule is gone) | 71.3 s | 45 to 90 s | 200 matches that ended in a KO |
| INFO | masher.brinkcloses | Lights-only mirror: share of closes made by the fighter on the brink, while only one of them is on it (reported, not banded: melee-press-feel 9e) | 6.5% (2 of 31 closes) | reported | 668 closes in 200 matches |
| PASS | masher.firstslot | Lights-only mirror: matches won from the first slot (40 to 60%, read on 200 matches) | 42.5% (85 of 200); first 60 seeds 47% of 60, the next 140 41% of 140 | 40 to 60% | point estimate; the interval at 200 matches is about +-7 points; the split is Encounter's (35% on the first 60 seeds, 67% on the other 140): a slot effect that moves with the seed range is the thing to look at; PENDING under 100 decided matches |
| INFO | masher.tradelimit | A trade breaks at its limit or on the tick a lead of 2 appears after it (reported; no bound but the double hit at 240 ticks) | 671 breaks; 0 before the limit; lateness in ticks: 95th percentile 2, longest 2 | reported | the old hard test (never early, at most 4 late) is retired: a lead appears whenever the other fighter stops landing |
| INFO | masher.breakclose | A close follows a trade break within 24 ticks, and 4 more for a hit-stop (reported: 85 to 95% expected) | 100.0% of 671 breaks (0 took longer) | reported (85 to 95%) | counted on S.tick from the trade_break event to the next flurry close or brawl_end |
| INFO | masher.closes | Lights-only mirror: brawls, blows and closes (reported) | 8.6 brawls a minute, 0.9 closes a minute, 0 heavy staggers; blows {"light":313453}; ends {"break":380,"double":5848} | reported | 200 matches |
| PASS | masher.mirror.tick | Two lights-only players (mashers who take their forms) finish the match before the cap (taps on S.tick, both on the same ticks: the exact tie) | 100.0% (200 of 200; 0 ran to the cap) | at least 95% | median 309.1 s; point estimate |
| **FAIL** | masher.brink.tick | Lights-only mirror: brink to KO, median (read against the overall 45 to 90 s: the 25 to 50 s band was derived when a level trade ended in a draw, and that rule is gone) (taps on S.tick, both on the same ticks: the exact tie) | 191.5 s | 45 to 90 s | 200 matches that ended in a KO |
| INFO | masher.brinkcloses.tick | Lights-only mirror: share of closes made by the fighter on the brink, while only one of them is on it (reported, not banded: melee-press-feel 9e) (taps on S.tick, both on the same ticks: the exact tie) | 8.1% (12 of 148 closes) | reported | 8359 closes in 200 matches |
| INFO | masher.firstslot.tick | Lights-only mirror: matches won from the first slot (40 to 60%, read on 200 matches) (taps on S.tick, both on the same ticks: the exact tie) | 44.5% (89 of 200); first 60 seeds 48% of 60, the next 140 43% of 140 | reported (the exact tie; the banded row is the offset mirror) | point estimate; the interval at 200 matches is about +-7 points; the split is Encounter's (35% on the first 60 seeds, 67% on the other 140): a slot effect that moves with the seed range is the thing to look at; PENDING under 100 decided matches |
| INFO | masher.tradelimit.tick | A trade breaks at its limit or on the tick a lead of 2 appears after it (reported; no bound but the double hit at 240 ticks) (taps on S.tick, both on the same ticks: the exact tie) | 8372 breaks; 0 before the limit; lateness in ticks: 95th percentile 4, longest 7 | reported | the old hard test (never early, at most 4 late) is retired: a lead appears whenever the other fighter stops landing |
| INFO | masher.breakclose.tick | A close follows a trade break within 24 ticks, and 4 more for a hit-stop (reported: 85 to 95% expected) (taps on S.tick, both on the same ticks: the exact tie) | 100.0% of 8372 breaks (3 took longer) | reported (85 to 95%) | counted on S.tick from the trade_break event to the next flurry close or brawl_end |
| INFO | masher.closes.tick | Lights-only mirror: brawls, blows and closes (reported) (taps on S.tick, both on the same ticks: the exact tie) | 7.7 brawls a minute, 7.1 closes a minute, 0 heavy staggers; blows {"light":776278}; ends {"break":389,"double":8516} | reported | 200 matches |
| PASS | masher.mirror.tickoff | Two lights-only players (mashers who take their forms) finish the match before the cap (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 100.0% (200 of 200; 0 ran to the cap) | at least 95% | median 300.7 s; point estimate |
| **FAIL** | masher.brink.tickoff | Lights-only mirror: brink to KO, median (read against the overall 45 to 90 s: the 25 to 50 s band was derived when a level trade ended in a draw, and that rule is gone) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 180.8 s | 45 to 90 s | 200 matches that ended in a KO |
| INFO | masher.brinkcloses.tickoff | Lights-only mirror: share of closes made by the fighter on the brink, while only one of them is on it (reported, not banded: melee-press-feel 9e) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 6.3% (9 of 142 closes) | reported | 8246 closes in 200 matches |
| PASS | masher.firstslot.tickoff | Lights-only mirror: matches won from the first slot (40 to 60%, read on 200 matches) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 47.5% (95 of 200); first 60 seeds 47% of 60, the next 140 48% of 140 | 40 to 60% | point estimate; the interval at 200 matches is about +-7 points; the split is Encounter's (35% on the first 60 seeds, 67% on the other 140): a slot effect that moves with the seed range is the thing to look at; PENDING under 100 decided matches |
| INFO | masher.tradelimit.tickoff | A trade breaks at its limit or on the tick a lead of 2 appears after it (reported; no bound but the double hit at 240 ticks) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 8267 breaks; 0 before the limit; lateness in ticks: 95th percentile 4, longest 7 | reported | the old hard test (never early, at most 4 late) is retired: a lead appears whenever the other fighter stops landing |
| INFO | masher.breakclose.tickoff | A close follows a trade break within 24 ticks, and 4 more for a hit-stop (reported: 85 to 95% expected) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 100.0% of 8267 breaks (1 took longer) | reported (85 to 95%) | counted on S.tick from the trade_break event to the next flurry close or brawl_end |
| INFO | masher.closes.tickoff | Lights-only mirror: brawls, blows and closes (reported) (taps on S.tick, the second player starting on a seeded offset of 0 to 7 ticks) | 7.6 brawls a minute, 7.1 closes a minute, 0 heavy staggers; blows {"light":764099}; ends {"break":383,"double":8370} | reported | 200 matches |
| INFO | masher.fastslow | A faster masher against a slower one (6 ticks against 12): closes a minute, and who wins (reported, as the cost of tapping slowly) | closes a minute: 43.1 for the 6-tick tapper, 0 for the 12-tick tapper; the 6-tick tapper wins 200 of 200 | reported | 200 matches; closes are flurry staggers; the clock is S.tick |
| PASS | masher.uneven.finish | An uneven mirror (8 ticks against 10) finishes before the cap (an 8-tick tapper against a 10-tick tapper) | 100.0% (200 of 200; 0 ran to the cap) | at least 95% | median 108.4 s; point estimate |
| PASS | masher.uneven.faster | The faster tapper (8 ticks) wins the uneven mirror (an 8-tick tapper against a 10-tick tapper) | 99.0% (198 of 200) | at least 80% | 200 matches; point estimate |
| INFO | masher.uneven.brink | Uneven mirror: brink to KO, median (reported) (an 8-tick tapper against a 10-tick tapper) | 20.0 s | reported | 200 matches that ended in a KO |
| PENDING | masher.expert | An expert script (guards, punishes with a heavy, perfect-blocks heavies and enders) wins against the medium AI (at most 15%) |  | at most 15% | needs the expert script: it reads the rival tells (Encounter scratch build has one, not in the tree) |

## Acceptance tests

| Status | ID | Spec | Test | Detail |
| :--- | :--- | :--- | :--- | :--- |
| PASS | W1 | spec-wounds §5.1 | Determinism: the same seed gives an identical record and event log, whatever the job count | 6 seeds, 1 and 3 jobs |
| PASS | W2 | spec-wounds §5.2 | No KO without a finisher: 100% of KOs follow the loser's brink_enter and a finisher_start | 400 KOs |
| **FAIL** | W3 | spec-wounds §5.3 | Length and chapters: 1.5 to 2.5 region breaks a match (rebased); first brink median 4:30 to 7:00; length median 6:00 to 8:00, p90 at most 10:00, p99 at most 12:00 | first brink median 268 s |
| PASS | W4 | spec-wounds §5.4 | No loops: 0.3 to 0.7 rallies per match (rebased); no region rallied twice; finisher survival 0 from 11:00 (relaxed for the third Rally at M1b, balance-targets 18; the sim enforces the 11:00 rule) | 0.41 rallies per match |
| **FAIL** | W5 | spec-wounds §5.5 | Spread: no region above 45% of all wear; arms take 35 to 65% of limb breaks (the old first-broken shares are retired: the brink is the core) | arms take 93% of limb breaks (35 to 65%) |
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
| PASS | C1 | §4b rolling budget | Rolling 60 s casualty budget by the higher tier: 2%, 4%, 8%, 15% of the starting population. No borrowing at tier 1 or 2; at tier 3 and above a set piece may borrow its own per-event budget | tier 3+ windows over budget (set-piece borrowing, to be bounded by per-event budgets): 16893 |
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
