# X-06 landing read on GW1b's main bce578a7: the two Medium exit cells, and the drift cells (QA, run 2026-11-22)

**What it measures.** Game Design's one-read exit for X-06: the kit at Medium at least 25%, the charge pad at Medium at most 55%, and the order (kit beats each one-note pad; every pad better at Easy than at Medium). 40 matches a cell, seeds 1 to 40, Wilson 95% intervals (a smoke at this size: ±12 to 15 points). Then the drift cells the EP asked for, to see whether main itself moved the kit.

**Tree and data.** Clean export of main **bce578a7** (GW1b landed), diffs from `docs/director/pending/x06-bands/` in the README's order (`x06-medium` ccea61aa, `x06-hold-answer` 9a8b3f47 with Medium by repetition `{windowTicks 300, byCount [0, 0.4, 0.9]}` and Easy 0.65, schema 9658f575; all applied clean). `qa/godot/orbs_player.gd --solo`, QA's planet settings (planet 7, touch 3, generation 3, 4,800 columns, energy model on, travel 1.5, no intro; the same as every X-06 read, so the numbers compare). Jobs 2 at below-normal priority.

## The two exit cells (all three diffs, Medium)

| Pad | Won | Rate (Wilson 95%) | Exit | Reading |
| :--- | ---: | :--- | :--- | :--- |
| B charge only | 20 of 40 | **50.0%** (35.2 to 64.8) | at most 55% | **PASS** by the point; the interval reaches 64.8 |
| Whole kit | 4 of 40 | **10.0%** (4.0 to 23.1) | at least 25% | **FAIL** |

The charge pad's full charges (1,905): 140 met nothing, 542 perfect-blocked, 59 guarded, 1,164 hit. The kit's full charges (263): 7 met nothing, 78 perfect-blocked, 34 guarded, 144 hit; the answer barely fires on the kit, as Game Design meant. Pace probe on the kit cell (`--pace`): slot 0 a person and `paceMatch` on in 100% of 93,575 samples, mean gap given to the computer 15.1 ticks.

## The drift cells (Medium kit, 40 each, bce578a7)

| Tree | Kit won | Rate (Wilson 95%) | Data hash |
| :--- | ---: | :--- | :--- |
| (b) no diffs at all (main alone) | 2 of 40 | **5.0%** (1.4 to 16.5) | b5d0c49f9ae5d79c |
| (a) `x06-medium.diff` alone | 4 of 40 | **10.0%** (4.0 to 23.1) | 8d54e137a4cbcb3c |
| all three diffs (the exit cell above) | 4 of 40 | **10.0%** (4.0 to 23.1) | |
| *for comparison, 7b69eafc, `x06-medium.diff` alone* | 13 of 40 | 32.5% (20.1 to 48.0) | d0fb306483a0ac6b |

**Reading.** Main alone is already at 5.0% on the GW1b main, and the candidate alone is 10.0%: the same as all three diffs. **The hold answer, with its repetition cut, costs the kit nothing here (10.0% with it, 10.0% without).** The kit's drop from 32.5% to 10.0% for the candidate alone is between 7b69eafc and bce578a7, so it is main's (GW1b's landing: planet, travel, whatever moved with it), not the diffs'. The difference for the candidate alone, 32.5% against 10.0%, is 22.5 points (Newcombe 4.5 to 39.1): not a noise gap. This read cannot say which of GW1b's changes moved it.

**What this cannot say.** 40 a cell; a number here is not a target and QA tuned nothing. Whether the kit's 25% floor can be reached on this main is a question about the main, not the diffs. Records: `docs/qa/runs/bce578a7/x06-landing-lines.txt`.

## The order check (all five pads at Easy and Medium, all three diffs, bce578a7, 40 each)

| Pad | Easy | Medium |
| :--- | :--- | :--- |
| Whole kit | 26 of 40, 65.0% (49.5 to 77.9) | 4 of 40, 10.0% (4.0 to 23.1) |
| Strike only | 7 of 40, 17.5% (8.7 to 32.0) | 0 of 40, 0.0% (0 to 8.8) |
| X masher | 18 of 40, 45.0% (30.7 to 60.2) | 5 of 40, 12.5% (5.5 to 26.1) |
| Beams only | 18 of 40, 45.0% (30.7 to 60.2) | 0 of 40, 0.0% (0 to 8.8) |
| B charge only | 9 of 40, 22.5% (12.3 to 37.5) | 20 of 40, 50.0% (35.2 to 64.8) |

| Exit line | Result |
| :--- | :--- |
| Charge at Medium at most 55% | **PASS** by the point (50.0%; interval reaches 64.8) |
| Kit at Medium at least 25% | **FAIL** (10.0%) |
| No one-note pad above 80% at Easy | PASS (highest 45.0%) |
| Kit beats each one-note pad at Easy | PASS (ahead by 47.5, 20.0, 20.0 and 42.5 points) |
| Kit beats each one-note pad at Medium | **FAIL** (the masher 12.5% is a tie within noise, Newcombe -17.4 to 12.3; the charge pad 50.0% is clearly ahead, -56.0 to -20.3) |
| Every pad does better at Easy than at Medium | **FAIL for the charge pad**: 22.5% at Easy against 50.0% at Medium (the other four pass) |

**Reading.** The Easy cells moved too against 7b69eafc (kit 72.5% to 65.0%, strike 45.0% to 17.5%, charge 57.5% to 22.5%; the masher 40.0% to 45.0% and beams 52.5% to 45.0% are unchanged to within noise), so GW1b's main moved Easy as well. The charge pad is now harder at Easy (22.5%, the same hold-answer chance 0.65) than at Medium (50.0%, repetition: the first hold 0, the second 0.4, the third 0.9): at Medium a charge pad's early holds go unanswered, which is what the order line catches. Records: `docs/qa/runs/bce578a7/x06-landing-lines.txt`, `x06-landing-order-table.md`.
