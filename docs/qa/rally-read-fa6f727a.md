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

## Second addendum (2026-10-26): the short-match autopsy (EP brief; GD 10-26 item 34)

The aim: find which part of launch anywhere's own flow drives the short tail, so GD's lever aims at the cause. Same build (fa6f727a), same overlay (anywhere, answer, water, rally on; linkWorth 1.0), seeds 1 to 200, `--jobs=3`, below-normal priority. Two arms: **on** (the main arm) and **off** (the sixth arm: anywhere, answer, water and rally all off). The saved records had no launch timeline or damage context, so both arms were **re-run with an autopsy capture** in a scratch copy of `records.gd` (not in the repo): damage by victim and context, every launch with the sent body's HP, every launcher thrown with the opening's reason and the target's HP, every pop with the popped body's HP, and the KO tick. **The re-run reproduces the earlier p10 to the digit** (290.8 and 347.7), so it is the same matches. A third run (pops off, launchers on) tests the finding. Compared: the 20 shortest matches of each arm, all 200, and the 20 longest.

### Damage by source, as a share of the loser's damage taken (and per match-second)

| Source | On: shortest 20 | On: all 200 | On: longest 20 | Off: shortest 20 | Off: all 200 | Off: longest 20 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Brawl blows (the exchange) | **80.7%** (32.9/s) | 76.0% (25.3/s) | 72.3% (20.9/s) | 78.7% (28.9/s) | 74.0% (21.9/s) | 69.7% (17.5/s) |
| Energy (beams, blasts) | 14.2% (5.8/s) | 17.2% (5.7/s) | 18.7% (5.4/s) | 16.2% (6.0/s) | 19.5% (5.8/s) | 23.2% (5.8/s) |
| Landings (full launch) | 1.7% | 2.4% | 3.4% | not applicable (no power cue) | | |
| Landings (other) | 0.7% | 0.6% | 0.4% | 3.5% | 4.4% | 4.8% |
| Launcher blow (the B that launches, 14 ticks) | 0.8% | 0.8% | 0.8% | 0.3% | 0.3% | 0.3% |
| Rally link (60 ticks after a link) | 0.3% | 0.6% | 0.9% | 0 | 0 | 0 |
| Pop (while popped) | 0.2% | 0.2% | 0.2% | 0 | 0 | 0 |
| Other (zips, the rest) | 1.3% | 2.1% | 3.2% | 1.4% | 1.8% | 2.0% |

Wear and the world's own damage are not damage events in these records (the world's share here is the landings rows). The answer's counter-launch has no cue of its own, so it is not separable; the "answer off" arm of the first addendum bounds it at about 4 s of p10.

**What it says:** launch anywhere's own damage (launcher blows, pops, rally links, landings) is **under 4% of what the loser takes**, in the short matches and the long ones. The loser is killed by the **brawl**: 73 to 81% of his damage. The short tail is a brawl-rate tail: the loser's brawl damage per second is 32.9 in the shortest 20 against 20.9 in the longest (a factor of 1.6) in the on arm, and 28.9 against 17.5 in the off arm (1.65). What launch anywhere does is lift the brawl rate overall: 25.3/s against 21.9/s (+15%) with energy unchanged (5.7 against 5.8).

### Launches, their spacing and the anywhere flow

| | On: shortest 20 | On: all | On: longest 20 | Off: shortest 20 | Off: all | Off: longest 20 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Launches taken by the loser a match | 9.2 | 16.6 | 28.2 | 10.9 | 15.9 | 20.9 |
| All launches a match (both) | 13.8 | 29.8 | 52.5 | 17.4 | 28.1 | 39.2 |
| Launchers thrown a match (B in an opening) | 9.7 | 10.6 | 12.8 | 2.2 | 3.0 | 3.1 |
| Pops a match (up) | 11.1 | 12.3 | 14.7 | 0 | 0 | 0 |
| Gap between the loser's launches, median | 14.6 s | **11.3 s** | 6.6 s | 26.7 s | **27.0 s** | 28.2 s |
| Gaps under 2 s (a re-launch before he recovered) | 20.1% | **33.8%** | 40.8% | 3.5% | **3.4%** | 5.0% |
| Gaps under 5 s | 35.4% | 42.3% | 48.7% | 18.2% | 12.6% | 11.3% |

With anywhere on, the launchers thrown rise from 3 to 10.6 a match and 12 pops a match appear (the pop drops the body up and back down in reach, the brawl holding). The total number of launches does not change (29.8 against 28.1). What changes is their **spacing**: a third of the on arm's launches on the loser come within 2 s of the last one (3.4% off). **But that is not what separates short matches from long ones inside the on arm:** the shortest 20 have the fewest launches (9.2 against 28.2) and the fewest quick re-launches (20.1% against 40.8%). So a re-launch before recovery is not what kills fast; it is a product of long matches, where there is more play.

Launcher openings (anywhere on, a match): perfect block 3.88, flurry 4.10, daze 1.27, guard break 1.20, counter 0.13. The off arm has 1.3 perfect-block and 1.3 flurry openings (the brink launcher mostly). Most launchers are thrown from a string or a perfect block. The pop is a landing for most of them: 12.2 pops that come back down ("land") and 7.5 techs a match.

### KOs and the first anywhere action

- **KOs on or within 2 s of an anywhere action (a launcher thrown or a pop on the loser): 0 of 200, and 0 of the shortest 20, in both arms.** The median time from the last anywhere action to the KO is 108 s in the on arm (77 s in the shortest 20) and 243 s in the off arm. A KO lands within 2 s of *a* launch in 200 of 200 matches in both arms, because the game ends on the brink launch and the finisher; that is the game's own KO route, not the anywhere flow.
- **HP at the first anywhere action:** median 0.66 of the body's HP, at 23 s into the match (shortest 20: 0.63 at 27 s); only 13% of matches have it under 10% HP. In the off arm the first launcher comes at 66 s at median 0 HP (52% under 10%): there it is the brink launcher. So with anywhere on, the flow begins at the start of the fight, at nearly full HP, and runs all match.

### The test: pops off, launchers on (`brawl.launcher.anywhere.pop.enabled` false), 200 matches

| Arm | Median | p10 (95% interval) | p90 | Rallies a match |
| :--- | :--- | :--- | :--- | :--- |
| On (main) | 392.7 | 290.8 (278.9 to 305.0) | 519.1 | 4.86 |
| **Pops off** | **671.8** | **610.9** (594.6 to 629.0) | **756.5** | **13.38** |
| Off (anywhere off) | 456.2 | 347.7 (332.9 to 371.7) | 593.0 | not applicable |

**One line:** the short tail is driven by the pop and its hold of the brawl, not by launch damage: the anywhere flow supplies under 4% of the loser's damage, but it keeps the two fighters in reach (12 pops a match, a launch every 11 s against 27 s), lifting the brawl's damage rate by 15%, and switching only the pops off swings the median from 393 s to 672 s (p90 757 s, over its 600 s ceiling), so the pop carries more length than the whole of launch anywhere does. A lever for p10 should be a **partial pop** (fewer pops a match, or a pop that costs the popper a recovery), not the launches' pay.

Caveats. One run of 200 on each arm; the pop-off arm is one reading and overshoots, so it locates the driver but not the dose. The damage contexts are windows (a launcher blow 14 ticks, a rally link 60 ticks, a pop until its cue's end), so a blow struck in a window counts to the window. The answer's counter-launch is not separable. The autopsy capture lives in a scratch copy of `records.gd`; I can land it in `qa/godot/records.gd` if the EP wants the fields kept.

### The autopsy in the repo (2026-10-26)

`qa/godot/records.gd` now carries the capture, **off by default**: the field `at` is written only when `QA_AUTOPSY=1` is set in the environment (the child Godot processes inherit it), so normal runs keep their record shape. Checked on real runs of 2 matches: without the flag no record has `at`; with it every record does; the records are otherwise byte-identical and the sim hashes are the same. The analysis is `qa/godot/autopsy.js`:

```
QA_AUTOPSY=1 node qa/godot/run-arm.js --count=200 --out=<records.json>
node qa/godot/autopsy.js <records.json> [N=20]
```

Self-test 31 of 31 (new case: damage shares, launch spacing, KO near an anywhere action, the HP at the first one, matches without the field skipped); `node qa/run-all.js` all 7 passed.

## Third addendum (2026-10-27): the pop's full line, in steps (GD rulings 10-26 item 42)

**Build:** clean `git archive` of **b474baac** (rally-tune2 741c8483 and `rally.linkWorth` 0.8 as on main), with the working copy of `qa/godot/` laid over it (the committed harness plus the uncommitted autopsy flag, `QA_AUTOPSY=1`, which changes no sim figure). Overlay, disclosed: `brawl.launcher.anywhere.enabled`, `answer.enabled`, `water.enabled` and `rally.enabled` true; `linkWorth` left at 0.8. Seeds 1 to 200 (100 for the newcomer and masher jobs), `--jobs=3`, below-normal priority, 781 to 803 s a run, no job invalid. One lever per arm, one arm at a time. Arm 3 was run because arm 2's p10 was under 300.

| | Arm 0: HEAD | Arm 1: pop.full 0.76 | Arm 2: pop.full 0.72 | Arm 3: 0.72 + stringPoints 3 |
| :--- | :--- | :--- | :--- | :--- |
| p10 (95% bootstrap interval) | **284.0** (270.4 to 303.0) | **277.7** (267.6 to 302.5) | **296.6** (278.9 to 319.5) | **305.6** (283.3 to 319.9) |
| Median (360 to 480) | 366.5 | 389.2 | 398.6 | 396.6 |
| p90 (at most 600) | 489.7 | 532.2 | 544.3 | 540.9 |
| Rallies a match (3 to 10) | 4.36 | 5.62 | 6.00 | 5.91 |
| Full launches, L16 (6 to 12) | 6.94 | 8.68 | 9.13 | 9.13 |
| Links a rally, median (2 to 4) | 2 (last hands 1) | 2 (1) | 2 (1) | 2 (1) |
| Rallies that turn (15 to 40%) | 18.5% | 19.0% | 17.8% | 18.7% |
| Rally time (at most 25%) | 5.6% | 6.9% | 7.4% | 7.2% |
| Pops a match | 12.0 | 11.6 | 11.5 | 11.8 |
| Newcomer v medium (L17, 10 to 50%) | 14% | 19% | 24% | 28% |
| Newcomer v easy (L17, 50 to 95%) | 74% | 94% | 93% | **96%** (over the band by 1) |
| Masher easy / medium / hard (60+; 35 to 50; at most 15) | 98 / 44 / 1 | 98 / 39 / 0 | 99 / 46 / 0 | 99 / 42 / 0 |

The first-launch rows (first60, thrown60, landed120) read 100% at both levels in every arm.

**Reading:** p10 climbs with the steps, 284 → 278 → 297 → 306, but arm 1 is inside the noise of arm 0 (the intervals overlap by 30 s) and **arm 3 is the only arm at 300 or above, with an interval of 283 to 320 that straddles it**. The pops a match hardly move (12.0 to 11.8): the lever does not remove pops, it turns the late-string repeat pops into sends (as GD intended), so full launches (L16) rise 6.9 → 9.1, rallies 4.4 → 5.9, and the launch gap in the shortest 20 matches grows 12.6 s → 18.9 s. The loser's brawl damage per second falls 8% overall (26.3 → 24.2) and 6% in the shortest 20 (33.5 → 31.6). The cost shows in L17: the newcomer wins more at both levels (medium 14 → 28%, still inside 10 to 50; **easy 74 → 96%, one point over its 95% band, within the ±5 point noise of 100 matches**: arms 1 and 2 read 94 and 93).

**Against the stop rule** (the first arm with p10 at least 300 and everything else in band): **arm 3 is the first with p10 at 300 or more (305.6)**, and every row is in band but `newcomer.wins.easy` at 96% against its 95% ceiling. p90 is 541 (under 600), L16 9.13, the median 397. If the easy newcomer's ceiling is held strictly, the next lever is easy's answer share (rulings item 20), not the pop. A longer read, at 200 matches for the newcomer, would put its error near ±3.5 points.
