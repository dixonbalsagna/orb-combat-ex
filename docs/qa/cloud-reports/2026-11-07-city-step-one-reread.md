# City step one, the re-reads after Game Design's rulings (QA, 2026-11-07)

EP brief of 2026-11-06 after Game Design's addendum (`docs/world/ring-any-angle/game-design.md`, "2026-11-06: QA's city step one read", and `docs/design/press-decides.md`). Same build and method as `2026-11-06-city-step-one.md`: HEAD with the page's switches flipped, World's places-reached park and `plans.farPeople` on, whole ring `QA_PLANET=gen=3;planets=3,7,11,13,17,19,23,25,37,31;touches=0,1,2,3;cols=4800`, 60 matches an arm on seeds 1 to 60, AI v AI at the default level, `--jobs=3`, below-normal priority (the machine was 20 to 95% loaded by other sessions; every run is a deterministic sim, so load changes the time, not the numbers). Intervals are 95% bootstraps. A result is a test result, never a target (RL-247).

## 1. Sends into a building (any start 3 to 6; a start in town 4 to 8)

| | Any start | Start in town | Start in town, town visit on | Band |
| :--- | ---: | ---: | ---: | :--- |
| Sends a match | **3.95** (3.43 to 4.47) | **3.68** (3.20 to 4.22) | **3.48** (3.03 to 3.95) | 3 to 6 from any start; 4 to 8 from a start in town |
| Verdict | **in band** | below 4, but the interval holds 4: not told from the floor | **below the floor** (the interval's top is 3.95) | |

- **A start in town is a new mode, `--start=town`** (`records.gd`): both fighters start in a first-ring place of three buildings or more, the seed picking which. **The old `--start=crossing` does nothing on a planet ring:** 59 of 60 matches were identical to no start, so it cannot read this band; a note is in `records.gd`.
- A town start moves the match (lengths and structures differ from the any-start arm) but not the sends: the fight leaves the town in its first launches. Match length stays in band with it (median 484 s, p10 348, p90 613).
- The town visit does not help the count: any start 3.95 to 3.60 (earlier read), town start 3.68 to 3.48. As in the first read, it does not raise sends.

## 2. Visits and "near", by the new definitions

Visited: a place counts once a fighter was within 1,500 units (true ground distance over the building's footprint, depth included) of one of its buildings as it fell. **One caveat on the test:** the sim does not label which blow broke a building, so "by contact" is read as "a fighter that close when it fell"; a blast thrown from a fighter that close counts, one thrown from further does not (as ruled). Near: the pair's midpoint within 1,500 units of a standing building's footprint by true distance (x wrapped, depth z, which does not wrap), no more than 1,500 above its top, sampled twice a second.

| | Any start | Start in town | Town start, visit on | Band |
| :--- | ---: | ---: | ---: | :--- |
| **Places visited a match** | **4.52** (4.13 to 4.93) | **4.52** (3.98 to 5.05) | **4.38** (3.85 to 4.93) | 2 to 4 |
| Matches under 2 places | 1 of 60 | 3 of 60 | 4 of 60 | the fault if under |
| Building falls with no fighter within 1,500 units | 70.4 a match | 77.7 | 72.8 | information |
| **Time near a building, %** | **40.1** (35.9 to 44.3) | **40.1** (36.7 to 43.2) | **40.4** (37.1 to 43.7) | 20 to 35 |
| The older along-the-line sample (for the record) | 57.6 | | | |

- **The new definition takes near from 57.6 to 40.1%, as Game Design expected, and it is still over 35** (the any-start interval's floor, 35.9, is above it).
- **Visits read 4.5 against 2 to 4:** over the band's top, not in the fault range (few matches under 2).
- **Game Design's rule for this case applies:** over 4 is information unless time near is over too, and it is. **Sends read about 4 (3.95) in the any-start arm,** so the fight is near buildings and is not converting them into sends: the lever is sends that aim for buildings and the wall push, as ruled.
- **Seven in ten falls happen with no fighter within 1,500 units** (beams, blasts from range, collapses of a stack): destruction here is mostly not by contact.
- Open sea 18.8% of fight time (any start), 23.1% (town start), 19.2% (town start, visit on): under the 25% cap in all three.

## 3. The masher on medium, 300 matches

**149 wins of 300: 49.7% (95% interval 44.0 to 55.3).** The band is 35 to 50, so the **point is inside the band** at its top edge, and the interval spans the line. Game Design's rule: it moves the AI's answer only if it is over 50 on 300; it is not. Match length 226.9 s median, no timeouts. Job `level:medium:forms:8`, HEAD with the page switches, slice world `gen=2; cols=2400`, one process of 300 matches (about 58 minutes).

**The stick-only row, same batch (medium, 60 matches each):** the X mash wins **16 of 60 (26.7%, interval 17 to 39)** and the stick-only pad wins **0 of 60 (0 to 6)**. The gap is about 27 points against a band within 10 (the first read had 20). An answer that keys on a repeated button, as ruled, should not change the stick-only row; it reads far under the X mash with or without it. Easy was not rerun.

## 4. The civilians-removed split

Same seeds; people on against every person removed (`civilians=0`, World's park, applied to the scratch tree: **the first pass of these arms ran without it, produced matches identical to people-on, and was discarded**). The row is big swings a match (a `swing_start` that is not a nudge or a jolt and over 15 degrees; band 6 to 12 a match), the difference over matches of on minus removed, interval a paired bootstrap over seeds; it stands within 1.

| Pair | Big swings, people on | Big swings, people removed | Difference (95% interval) | Within 1 |
| :--- | ---: | ---: | :--- | :--- |
| Baseline (the timing switch off, which is its default) | 11.25 | 9.88 | **+1.37** (0.48 to 2.27) | **no** |
| **The hero's lure off in both arms** | 9.05 | 9.12 | **-0.07** (-0.95 to 0.82) | yes |
| The hero's lure off, and the direction's care and anguish terms zero | 9.05 | 9.05 | +0.00 (-0.88 to 0.85) | yes |

By cause a match, on / removed. **Baseline:** brawl 4.98 / 4.43, chase 4.17 / 3.53, form 0.93 / 1.18, launch 1.17 / 0.73. **Lure off:** brawl 4.72 / 4.68, chase 2.67 / 2.75, form 1.03 / 1.17, launch 0.63 / 0.52.

- **The gap goes with the lure.** With the hero's lure off in both arms the difference is -0.07, inside 1. By Game Design's rule that is the grandfathered term (it reads people under RL-214), and **it goes to Legal through the EP.** It is not a swing term reading people. With the lure on, the extra swings sit in brawl, chase and launch causes together (+0.55, +0.64, +0.44), because the removed run's fights go elsewhere.
- **The timing switch was already off.** `data/director/swing.json` `tension.enabled` is false at HEAD and is not touched by the page's switch list, so every read, including the +1.87 of 2026-11-02 and this +1.37, has it off. The baseline pair is the timing-off pair; a separate run would be the same matches. (Turning it on is a different question and was not asked.)
- **The direction's people terms add nothing to the count once the lure is off** (the third row equals the second).
- The lure itself is a large swing source: turning it off takes people-on swings from 11.25 to 9.05 a match (the band is 6 to 12; both inside).
- **How the lure and direction switches were made:** the repo has no data switch for the hero's lure or for the direction's care terms, so they are two env-gated lines in a scratch copy of `sim/director/location.gd` (`roam` returns 0 for the hero when `QA_LURE=off`) and `sim/director/swing.gd` (`cfg()` zeroes `direction.care` and `.anguish` when `QA_DIRZERO=1`). **Nothing was applied to the repo.** A repeat run in a real build needs Encounter to offer the lure as data.
- Correction to the first report: its "swings a match" row counted swings of 30 degrees or more (5.7 for the any-start arm); the swing rows' own count is over 15 degrees (11.25 here, band 6 to 12).

## Tools (all in `qa/`)

- `qa/godot/records.gd`: `--start=town`; per-match `visited` and `fallsFar`; `nearN2` and `nearHit2` (the new near definition); the older along-the-line near is kept beside it.
- `qa/godot/clean-rows.js`: near and visited use the new definitions (the old sample is reported in the note); the sends band is 3 to 6, or 4 to 8 when every match starts in town.
- `qa/godot/civless-pair.js` (new): the pair table above with a paired bootstrap and the by-cause counts.
- Records in the scratchpad: `d_base.json`, `e_basenc.json`, `e_lure.json`, `e_lurenc.json`, `e_lured.json`, `e_lurednc.json`, `e_town.json`, `e_townv.json`; masher `gm300.json`; stick cells `xr_medium_*.out`.

## Open, with owners

| Item | Owner |
| :--- | :--- |
| The civilians-removed gap sits with the hero's lure (RL-214's grandfathered term): rule on it | Legal, through the EP |
| Time near is 40% (over 35) and visits 4.5 (over 4) with sends about 4: the fight is near buildings and not converting | Game Design, Encounter (sends that aim for buildings; the wall push) |
| Sends from a town start 3.5 to 3.7 against 4 to 8: the fight leaves the town in its first launches | Game Design, Encounter |
| Stick-only against the X mash: 27 points against a band within 10 | Encounter; Game Design if the band should move |
| A data switch for the hero's lure and the direction's care terms, to repeat the split in a real build | Encounter |
| `--start=crossing` is a no-op on a planet ring | Tools or World, if the crossing start should place a planet match |
