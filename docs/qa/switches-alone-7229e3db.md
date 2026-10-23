# The switches read one at a time, launch anywhere off: main 7229e3db (QA)

The EP's brief of 2026-10-24: read the rows that wait on a switch that is on main, each with only its own switch on and launch anywhere off, so that no launch storm is in the numbers: recoil flips, the calm turn, the wall kick and the chase. Plants and frozen time stay PENDING (neither has a self-contained switch).

| | |
| :--- | :--- |
| Build | **main 7229e3db** (includes World's ade02e47), four clean `git archive` scratch exports with my harness overlaid (uncommitted at the time: `records.gd`, `bands.js`, `masher.js`, `selftest.js`, the new `calm.gd` and `run-arm.js`) |
| Switches | One in each export, in the scratch copy of `data/director/interrupts.json`: `recoilFlip.enabled` (flips), `chase.enabled` (chase), `wallKick.enabled` (kick). The calm turn is turned on in memory by `calm.gd`. **Launch anywhere stays off in all four.** Nothing else is on |
| Run | 14:02 to 14:51, `--jobs=3`, headless, below-normal priority. The driver pauses a phase while the machine's CPU is over 80% (it did not need to). **No job invalid** (no wall cap, no budget stop) |

## 1. Recoil flips alone (AI v AI, 200 matches)

| Row | Read | Band | |
| :--- | :--- | :--- | :--- |
| Flips a minute, both fighters | **1.12** (1,631 flips) | 1.2 to 6 in AI play | **FAIL, just under** (Encounter reads 1.37 on its probe) |
| Counter-rush follow-ups | 745 for 1,631 flips (**45.7%**), 0.51 a minute | reported | |
| Flourishes (a knock-back over 3 bh, no press) | 371 (0.25 a minute) | reported | |
| Match length median / launches a match | 431.5 s / 12.8 | 360-480 / | in; unchanged from main |

With no launch storm the flip rate is 1.12 a minute, almost the same as in the storm (1.11). The window opens on the knock-backs that exist; the heavy recoil (1a) is the lever Game Design named, and it is waiting.

## 2. The chase of a launch (AI v AI, 200 matches)

| Row | Read | Band | |
| :--- | :--- | :--- | :--- |
| Chases a match, the AI chasing a launch it threw | **2.96** (593 chases) | 1 to 4 | **PASS** |
| Of them, the share that catch the body | **74.4%** (441 catches; 122 landings first; 30 stopped) | at least 60% | **PASS** |
| Match length median | 443.7 s | 360-480 | in |

## 3. The wall kick (AI v AI from a city start, 150 matches)

A default start is not in town, so both fighters start in a city (the seed picks the spot; Encounter's probe does the same). Wall slams are then common.

| Row | Read | Band | |
| :--- | :--- | :--- | :--- |
| Wall kicks a match | **0.26** (39 kicks, all rush, 0 push) | 1 to 4 | **FAIL, far under** |
| Wall slams a match (beside it) | 1.61 (241) | | the kicks are **16% of the slams** |
| Match length median | 451.1 s | 360-480 | in |

The kick needs the AI to arm on its level's share (15, 35 and 55%) at a send that meets a face that holds at 1,500 u/s or more, and not sooner than its reaction time after the send. At medium (35%) the expected ceiling is about 0.5 a match even if every slam were eligible; the band of 1 to 4 a match is out of reach from a city start unless the shares or the eligible slams rise. I did not read a player's kick.

## 4. The calm turn (the three rings, 30 matches a ring, planet 7)

| Ring | Turns a match | Band | Turns (by moment) |
| :--- | :--- | :--- | :--- |
| **Whole** (4,800 columns) | **0.77** (23 turns) | 0.8 to 3 | **FAIL by 0.03** (about one turn in 30 matches). At landings 13, at a form step 10 |
| **Half** (2,400) | **1.33** (40 turns) | 1 to 3 | **PASS** |
| **Close** (1,200) | **1.13** (34 turns) | 1 to 3 | **PASS** |

**Hard (no swap with an exchange, an approach, a queued action or a body in motion; none on a cold ring; none over World's ground rule): bad 0, cold 0, over ground 0 in all three rings.** The most ground moved under a fighter was 398, 427 and 424 units in the Whole, Half and Close rings. Encounter's earlier reads, on 10 matches a ring: Whole 0.6, Half 1.2, Close 1.1. The Whole ring is a hair under its floor on 30 matches; the interval is wide.

## 5. Not read

Plants and glances, frozen time, the press to the wind-up (no self-contained switch); wall kick by a player; chase by a player; the heavy recoil (1a); the Whole ring on more than 30 matches.

## Harness (uncommitted)

`qa/godot/records.gd` (the cues `chase`, `wall_kick`, `counter_rush`, `calm_turn` in the cue texts; `--start=city`), `bands.js` (chase and wall kick rows), `masher.js` (the calm jobs and rows), new `calm.gd` (QA's copy of Encounter's calm-turn probe) and `run-arm.js` (one arm with its rows), and `selftest.js` (27 of 27). Saved jobs in my scratch: `gR.json`, `gH.json`, `gK.json`, `mN.json`.
