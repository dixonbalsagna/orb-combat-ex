# Main at 0ca6f670 measured, in part: the eleventh-round rows, the masher stage and four arms (QA, 2026-10-16)

**This is a partial baseline, written from what had finished when the batch was stopped for the machine-wide quiet window (2026-10-16, 19:28).** No new run was made for this document. The EP's ruling is that main has moved (Encounter's window 1 at 9d0530dc changes play in 11 golden cases), so the batch was not resumed; the full baseline is to be run on 9d0530dc or newer, after Tools' record run. What exists for 0ca6f670 is below, and what does not is listed.

| | |
| :--- | :--- |
| Build | **0ca6f670** (tuning window 4d922632, the training dummy and one-versus-many stage 1 06b0200e, Camera's launch follow, the sky). A clean `git archive` of the commit with my harness overlaid, uncommitted at the time (disclosure): `qa/godot/players.gd` (the `newcomer` kind), `masher.js` (the eleventh-round jobs and rows), `selftest.js`, and the two new probes `ret.gd` and `charge.gd` (first version of `charge.gd`). The arms and the masher stage's older jobs use the harness as committed |
| Engine | Godot 4.7.2, headless, `--jobs=3`, below-normal priority, wall cap 1,800 s a match, budget 8 hours a job |
| Eleventh-round jobs | 9 jobs, 12:17 to 12:59: the newcomer (easy, medium; 100 matches each), the return from a launch (striker, guarder, idle; 60 matches each), the charge probe (heavies at easy, medium, hard; a held Y at medium; 60 matches each). **None invalid** |
| Masher stage | 70 jobs, 12:59 to 17:29. **None invalid** (no wall cap, no budget stop, no short job). 61 jobs of the earlier stage plus the 9 above |
| Arms | **4 of 8 at 400** (seeds 1 to 400): default 1,757 s, swap 1,821, mirror-villain 1,495, mirror-hero 1,625. The fifth (default-flip) was stopped at about a third. **Not run:** the four flip arms, the level runs, the crossing start, the feel probe, the tests. The finished arms are kept per arm (`g0ca6.<arm>.json`) |
| Machine | Other sessions' Godot jobs were running throughout (CPU 65 to 73% when the batch started). The sim is deterministic by seed, so load matters only through a wall cap or a budget stop, and none fired |
| Rows | The masher rows were **re-evaluated offline** from the saved jobs with the current `masher.js` (Game Design's twelfth-round bands: perfect blocks 2 to 5% at medium; the route's 80% and 0 to 25 points). The arms were evaluated offline with the current `bands.js`: 181 rows, 102 pass, 13 fail, 44 reported, 22 pending (rows that need an arm or a run that did not happen are PENDING, not guessed) |

## The eleventh-round rows (Orb's playtest)

| Row | Read | Band | |
| :--- | :--- | :--- | :--- |
| **A scripted newcomer launches within 60 s of the first brawl**, medium AI (X every 10 ticks; B within 0 to 20 ticks of his run reaching the close) | **88.0% of 100 matches** (all 100 launched at some point); inside 30 s **71.0%**; he launches 9.51 times a match, is launched 1.36 times, and wins 2.0% | at least 90% | **out by 2 points** |
| ... against the easy AI | 88.0% inside 60 s; inside 30 s 61.0%; wins 56.0% | reported | |
| **The returning opponent's first blows after a launch land unanswered**, striker (X every 8 ticks from 15 ticks after the approach starts) | **333 of 347 (96.0%)**; 14 landed first by the player; 64 of the 347 first blows came from range | reported (Encounter on main 775968bc: 97%; its parked fix 41%) | the parked fix is not on this build |
| ... guarder (guard held, a fresh press at the cue and after each wind-up) | 55 of 363 (15.2%); 225 guarded, 81 perfect | reported | |
| ... a player pressing nothing | 328 of 332 (98.8%) | reported | |
| **Charged heavies the AI perfect-blocks**, of those let go | easy **7.0%** (124 of 1,782), medium **8.7%** (191 of 2,200), hard **7.6%** (139 of 1,819) | medium 2 to 5% (the twelfth round; it was 5 to 15%) | **medium out**; no rise by level |
| Charged mediums | 0 let go in 60 matches: **a medium has no charge on this build** (`brawl.gd`: "a medium has no charge yet") | | pending |
| The AI never reacts to a release: no fresh guard press on a release tick or in the 14 ticks after it, before the blow lands (hard test) | 0 and 0 over 5,801 releases | none | in. The test cannot see the stale mark (below) |
| **No stale mark** (a perfect block whose press came more than 14 ticks before the blow landed) | pending: this run used the first version of `charge.gd`, which does not count it. 166 of the 191 medium blocks came from a press before the release | none | **pending**; read on the next baseline |
| Charges answered by level; the rate by hold length | pending (the same reason) | rises easy to hard; reported | pending |
| The route against medium: at most 80% on 200 matches; 0 to 25 points over its masher | 61% against the masher's 50% (+11 points) on 100 matches (seeds 1 to 100) | at most 80%; 0 to 25 | **pending**: the 200-match reading needs seeds 101 to 200, not run. On 100 matches both would pass |
| Beam struggle: more surges win; the point crosses; won from behind (of struggles with a winner); a masher equals not pressing; 2 ticks off the pulse overwhelms medium (75%); 3 ticks late still wins (90%); the pulse hit rate | stubs | | PENDING until Encounter's window |

**Reading of the charge rows.** Orb felt the AI perfect-blocked every charge; on main it perfect-blocks 7 to 9%, and the share does not rise with the level. Encounter's finding is that the AI's press is made at the wind-up's end and its mark stays however long the player holds, so a block does not depend on the release. Both are consistent with these numbers: no press comes after a release (so the first hard test passes), and the rate is flat across levels. The stale-mark row is the one that tells a guess from a mark.

## Main against the chain (3198301f): nothing moved

The masher stage and the four arms were compared row by row with the 3198301f baseline (`chain-3198301f.md`). **Play is unchanged within noise.**
- **Masher stage (109 rows common to both):** the route against its masher is the same, 61% against 50%. The nine cells, the flurries, the giver rows, the energy rows and the mirrors read the same or within a few points: Y mashed 34 to 32%, B mashed 11 to 12%, mixed 11 to 9%, double hits 1.18 to 1.17 a match (68% of matches), the blast's knock-back mark 399 to 415 of about 2,700, the blur rows within 3 points. One status change: **B held 11% to 18%, now in its 15 to 45 band** (the holder script, so "script, not cell" still stands).
- **Arms (default, swap, mirror-villain, mirror-hero only, so the pooled rows differ in kind from the eight-arm run):** match length median 426.9 s (431.8), 10th percentile 307.7 s (321.3; still above 300), 90th 577.2 s; civilians 20.87 (21.17); first-row structures lost 36.4% (37.9%); win rate 50.1% [46.7, 53.6] (48.9%); brink to KO 73.9 s (73.1); limb breaks 0.33 (0.36); act 4 before the first brink 87.8% (89.8%); perfect blocks at medium 2.91 a minute (2.88). Two status changes, both at an edge: building brunts as a share of launches 4.2% to 3.9% (band 4 to 10, now out by 0.1) and zips countered 24.8% to 23.8% (now in).
- **The failing arm rows are the same set:** brunts a minute 0.07, brunts 3.6 to 3.9% of launches, slam endings 18.4%, caught in the air 13.9%, flights off terrain 0.75, lock-break median 1.5 s, exchanges started a minute 7.61, exchanges ending in a launch 36.7%, launches over 9,000 units 29.5%, the mirror biome shares (41.8, 40.2%), and **the building share by care: 43.9% against at least 80%** (446 plans; the stick is not in the event, so the row reads every plan with a candidate in reach).
- **Partings a match by kind:** launch 4.28, knock-back 0.01, throw 0, shove 0, double hit 0.06; the other endings: signature 9.52, idle 2.27, break 1.05.

## Not measured, and what each waits for

| Row | Waits for |
| :--- | :--- |
| Perfect blocks by level and the order row; the crossing start (bodies into buildings, wall slams); feel; tests; the flip and mirror slot-and-spawn rows | the full baseline on 9d0530dc or newer |
| The stale mark, the answers by level, the rate by hold length; the route on 200 matches | the same run, with the twelfth-round jobs (`charge.gd` second version; seeds 101 to 200) |
| Beam struggle (seven rows) | Encounter's window |
| Charged mediums | a build in which a medium charges |
| The gauge, the wider window, the 30 s rest: the newcomer row is their "before" (88%) | Encounter's build of the eleventh round |
| The route rows as they are now | **they will change shape**: Game Design is redesigning the launcher (a launch from anywhere in a string, no rest). The route and newcomer results are kept as data in the saved jobs, so the rows can be re-read against a new definition |

## Harness (qa/, mine, uncommitted)

- `players.gd`: the `newcomer` kind (X on a slow clock; B within a seeded 0 to `react` ticks of his run filling); the gauge read `Pl.gauge_full`; the route statistics count the newcomer.
- `masher.js`: `_runProbe`, the newcomer, return and charge jobs, `elevenRows` (the twelfth-round bands, the answers, the stale-mark test, the rate by hold length, the route on 200 matches and the new beam stubs), the two extra route jobs on seeds 101 to 200 (`rb-medium`, `xb-medium`).
- `charge.gd` (second version: charges begun, answers, stale marks, the rate by hold length) and `ret.gd`: QA's own versions of Encounter's probes, with the wall cap and the validity fields.
- `selftest.js`: 22 of 22.
- Saved in my scratch: `m0ca6.json` (the 70 jobs), `g0ca6.<arm>.json` (the four arms).
