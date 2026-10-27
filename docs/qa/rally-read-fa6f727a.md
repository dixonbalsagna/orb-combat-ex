# The full rally read and the p10 bisect: fa6f727a (QA, 2026-10-26)

GD 10-26 item 34 and the EP's brief. Clean `git archive` of **fa6f727a** (the tune 22b76cb4 and my four files), scratch data overlay, disclosed: `brawl.launcher.anywhere.enabled`, `brawl.launcher.anywhere.answer.enabled`, `water.enabled` and `rally.enabled` true, `rally.linkWorth` 1.0 (item 35 withdrew item 33). 200 matches, seeds 1 to 200, `--jobs=3`, below-normal priority, machine at about 1% load at the start, no job invalid (each run 727 to 812 s).

## The whole-match rows, five arms on the same seeds

| Arm | Median | p10 (95% bootstrap) | p90 | L16 full launches |
| :--- | :--- | :--- | :--- | :--- |
| Main: anywhere, answer, water, rally on | 392.7 | **290.8** (278.9 to 305.0) | 519.1 | 7.26 |
| Answer off | 380.9 | **295.3** (281.6 to 308.8) | 527.3 | 7.05 |
| Water off | 392.7 | **290.8** (278.9 to 305.0) | 519.1 | 7.26 |
| Rally off | 409.5 | **297.3** (281.7 to 319.6) | 531.3 | 9.14 |
| Answer, water and rally all off (anywhere on) | 408.0 | **294.9** (285.6 to 306.7) | 559.9 | 9.31 |
| Everything off, **launch anywhere off** | 456.2 | **347.7** (332.9 to 371.7) | 593.0 | not read (no cue) |

**Reading:** p10 is under 300 s in every arm with launch anywhere on, and none of the three parks restores it: the water switch changes nothing in these matches (identical to the digit to the main read, so it does not act in AI-v-AI play on this start), the answer is worth about 4 s, the rally about 6 s, and all three together about 4 s, all inside the interval. Turning launch anywhere itself off gives 347.7 s. The loss is launch anywhere's, so the lever family GD named (the launches' pay: `landPay` 0.5 to 0.35, `anywhere.worth` 4 to 3.5) is the right place. The median also falls from 456 to 393 to 408 with it on, and p90 stays inside 600 in every arm.

## The rally rows (main arm, 972 rallies in 200 matches)

| Row | Read | Band | |
| :--- | :--- | :--- | :--- |
| Links a rally, median (every link across both hands, the turn's send counted) | **2.00** (1,843 links in the last hands, 1.90 a rally) | 2 to 4 | PASS |
| Links a rally, last hands only | 1 | reported | INFO |
| Rallies that turn | **11.3%** (144 turns in 972 rallies) | 15 to 40% | **FAIL** |
| Rallies a match | 4.86 | 3 to 10 | PASS |
| Dazes a match | 5.67 (perfect block 589, charged heavy 327, guard break 179, wall slam 39) | 2 to 8 | PASS |
| Repeat links | 0.1% | at most 25% | PASS |
| Ended by repetition | 0.0% | at most 20% | PASS |
| Rally time of match time | 6.0% | at most 25% | PASS |
| Sells a daze | 1.54 | reported | INFO |

**The end-of-match carry risk:** none. Rallies opened 972 = entries 972; the 1,116 `rally_end` cues are 972 final ends and 144 turned ends, equal to the 144 `rally_turn` cues. Every rally in the 200 matches ended with a final end.

## L17 and the first-launch rows (the newcomer jobs, 100 matches each, main arm's data)

| Row | Read | Band | |
| :--- | :--- | :--- | :--- |
| `newcomer.wins.medium` (L17) | **7.0%** (7 of 100); 3.3 launches a match by him, 19.0 on him | 10 to 50% | **FAIL** (under the floor) |
| `newcomer.wins.easy` (L17) | 79.0% | 50 to 95% | PASS |
| `newcomer.first60` (medium; easy) | 100%; 100% | at least 75%; 90% | PASS |
| `newcomer.thrown60`, `newcomer.landed120` (both levels) | 100% each | at least 75% | PASS |

The newcomer jobs ran on the main arm only, not on the four bisect arms. 100 matches each (not the 200 the whole-match rows have).

## Addendum (2026-10-26): the pay levers and the newcomer drop (GD 10-26 items 34 and 38)

Same build (fa6f727a), same overlay (anywhere, answer, water, rally on; `rally.linkWorth` 1.0), same seeds 1 to 200, `--jobs=3`, below-normal priority. One lever at a time, each run on its own scratch copy. No run invalid (781 to 793 s). L17 on 100 matches each.

| Arm | Median | p10 (95% bootstrap) | p90 | L16 | Rallies a match | Links (median) | Turns | L17 medium | L17 easy |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Main (landPay 0.5, worth 4) | 392.7 | 290.8 (278.9 to 305.0) | 519.1 | 7.26 | 4.86 | 2 | 11.3% | 7% | 79% |
| **1. landPay 0.35** | 392.9 | **288.3** (281.0 to 305.1) | 518.6 | 7.29 | 4.83 | 2 | 10.8% | 14% | 88% |
| **2. landPay 0.35 + worth 3.5** | 377.0 | **278.8** (269.3 to 304.4) | 519.7 | 6.86 | 4.48 | 2 | 10.6% | 8% | 86% |

**Neither arm brings p10 to 300, so I stopped after arm 2 as ordered** (a pass needs p10 at least 300 with p90 at most 600; p90 is fine in all three). `landPay` 0.35 changes nothing measurable in the whole-match rows (p10 288.3 against 290.8, inside the interval); lowering `worth` as well moves p10 the wrong way (278.8) and the median down by 15 s. The pay levers do not recover the 23c reading, which agrees with the sixth arm: launch anywhere itself costs about 57 s of p10 (347.7 with it off), and the three parks are worth about 4 to 6 s between them.

**L17 against pay:** medium 7% → 14% → 8%, easy 79% → 88% → 86%. At 100 matches a share carries about ±7 points, so these are not distinguishable: **pay does not move the newcomer's 7%.**

**A harness fix found on the way:** one match of 200 in arm 2 had no launch_power cue at all (no launch), and `design.L16.ai` went PENDING because it required every record to have one. A match with none now counts 0. L16 re-reads from the saved records: arm 2 6.86 (PASS), arm 1 7.29, main 7.26. `qa/godot/bands.js` (sha1 58cb94794bc28d1783d86202001a7b11e7dd0368) carries it; selftest 30 of 30.

### The newcomer drop check (item 38, step 1)

Encounter's rally-tune park read the newcomer against medium at 16 of 100 and easy 83 of 100; the fa6f727a overlay read 7 and 79. The same overlay with **`rally.linkWorth` 0.8 reads 16 of 100 against medium and 83 of 100 against easy**, which is Encounter's figure to the match. So linkWorth is the whole difference: at 1.0 the newcomer loses 9 more matches of 100 (7 against 16). Nothing else differs, since the seeds (1 to 100), the runner (`masher-only.js`, newcomer pair jobs, lit trigger), the data (anywhere, answer, water and rally on) and the matching easy figure all agree. Step 2 (medium's `brawl.anywhere.launcher` 0.35 → 0.3, 0.25) is not run: it was to follow only if pay fixed p10, and pay did not.

One more note: every arm in this addendum was run with `linkWorth` 1.0, as briefed, while main still holds 0.8. A whole-match read at 0.8 is the one reading I have not made, and it is the state of main today.
