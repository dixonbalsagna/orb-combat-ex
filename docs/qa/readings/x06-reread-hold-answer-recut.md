# X-06 re-read at the re-cut chances: Easy and Medium, five pads, judged by Game Design's scripted A1 exit (QA, run 2026-11-22)

**What it measures.** Game Design's scripted X-06 exit (`docs/design/gauntlet-plan.md` section 10), not the human bands: no one-note pad above 80% at Easy or 55% at Medium; the kit beats each one-note pad at each level; every pad does better at Easy than at Medium; the kit at Medium at least 25%. 40 matches a cell, seeds 1 to 40, Wilson 95% intervals (a smoke at this size: about 12 to 15 points either side).

**Tree and data.** Clean export of main **7b69eafc** with the three `docs/director/pending/x06-bands/` diffs in the README's order (hold-answer re-cut 78d52931: `holdAnswer` Easy 0.65, Medium 0.5, Hard 0.95; all three applied clean). Data hash `16957372f8bae4c6`. Planet 7, touch 3, generation 3, 4,800 columns, energy model on, travel 1.5, no intro. `qa/godot/orbs_player.gd --solo`, jobs 2, below normal.

| Pad | Easy | Medium |
| :--- | :--- | :--- |
| Whole kit | 29/40, **72.5%** (57.2 to 83.9) | 4/40, **10.0%** (4.0 to 23.1) |
| Strike only | 18/40, 45.0% (30.7 to 60.2) | 0/40, 0.0% (0 to 8.8) |
| X masher | 16/40, 40.0% (26.3 to 55.4) | 6/40, 15.0% (7.1 to 29.1) |
| Beams only | 21/40, 52.5% (37.5 to 67.1) | 0/40, 0.0% (0 to 8.8) |
| B charge only | 23/40, 57.5% (42.2 to 71.5) | 20/40, **50.0%** (35.2 to 64.8) |

| Exit line | Result |
| :--- | :--- |
| 1. No one-note pad above 80% at Easy | **PASS** (highest: charge 57.5%; was 95%) |
| 2. No one-note pad above 55% at Medium | **PASS** (highest: charge 50.0%, interval reaches 64.8; was 2.5%) |
| 3. Kit beats each one-note pad, Easy | **PASS** (ahead of strike 27.5, masher 32.5, beams 20.0, charge 15.0 points) |
| 3. Kit beats each one-note pad, Medium | **FAIL**: kit 10.0% is under the masher (15.0%; Newcombe difference -20.3 to 10.3, a tie within the noise) and far under the charge pad (50.0%; -56.0 to -20.3) |
| 4. Every pad does better at Easy than at Medium | **PASS** (all five) |
| 5. Kit at Medium at least 25% | **FAIL**: 4 of 40, 10.0% (4.0 to 23.1); the interval's top is under 25 |

**Reading.** The 0.5 at Medium opens the charge pad again (2.5% to 50.0%, ceiling met with room) and the 0.65 at Easy brings the charge pad under 80% (95% to 57.5%), but **the Medium kit did not recover: 10.0%, against 32.5% with the candidate alone (17a8dd6c) and 12.5% at 0.8.** The kit at Medium is not moved by the hold-answer chance in this range; something else in the hold answer or the re-cut sits on it. Medium full charges (two chunks, 1,964): 155 met nothing, 532 perfect-blocked, 75 guarded, 1,202 hit (at the earlier 0.8 read: 183 and 177 of 813). The charge pad still wins half the matches by hitting 61% of its full charges, while the kit, which charges as one of five things, loses 36 of 40.

**Not a verdict.** 40 a cell; QA tuned nothing. Records: `docs/qa/runs/7b69eafc/x06-reread-table.md` and `x06-reread-lines.txt`.

## Isolation of the Medium kit (2026-11-22, EP's order; same tree 7b69eafc, Medium, kit pad, 40 matches, seeds 1 to 40)

| Tree | Kit won | Rate (Wilson 95%) | Data hash |
| :--- | ---: | :--- | :--- |
| (a) `x06-medium.diff` alone (re-cut ccea61aa; no hold answer) | 13 of 40 | **32.5%** (20.1 to 48.0) | d0fb306483a0ac6b |
| (b) all three diffs, Medium `holdAnswer` 0 (scratch data edit) | 11 of 40 | **27.5%** (16.1 to 42.8) | 8a8ce675137c5697 |
| All three diffs, Medium `holdAnswer` 0.5 (the read above) | 4 of 40 | 10.0% (4.0 to 23.1) | 16957372f8bae4c6 |

The re-cut alone reproduces the 32.5% of 17a8dd6c. With the hold answer present at 0.5 the kit falls to 10.0%; with the answer's chance at 0 it is 27.5%. So **the hold answer itself takes the kit down, not the candidate and not the 0.5 versus 0.8 choice** (0.8 gave 12.5%). The difference between 27.5% and 10.0% is 17.5 points (Newcombe 0.1 to 33.9): borderline at 40 a cell.

**The `noHuman` suspect: cleared.** `orbs_player.gd --pace` samples every tenth tick whether `DirPace` sees slot 0 as a person (no `ai`, an `input`), whether `paceMatch` is on, whether slot 0's recent gap reads (two or more attack presses in 3 seconds), and the gap `DirPace.gap` gives a computer drawn at 8 against him. Over 97,609 samples (a) and 97,124 (b): slot 0 a person in 100%, `paceMatch` on in 100%, the gap read in 98.4%, and the computer's mean gap 15.1 ticks (not 8, and not `noHuman`). The pad is a person to pace matching; Medium plays at the pad's pace, as Easy does. Records: `docs/qa/runs/7b69eafc/x06-isolation-lines.txt`.

## Medium hold-answer chance 0.25 (2026-11-22, EP's order; scratch data edit on 7b69eafc, all three diffs, kit and charge pads, 40 each)

| Medium `holdAnswer` | Kit | B charge only | Full charges the charge pad threw |
| :--- | :--- | :--- | :--- |
| 0 | 11 of 40, 27.5% (16.1 to 42.8) | not read | |
| **0.25** | **7 of 40, 17.5%** (8.7 to 32.0) | **39 of 40, 97.5%** (87.1 to 99.6) | 2,239: 74 met nothing, 606 perfect-blocked, 64 guarded, 1,495 hit |
| 0.5 | 4 of 40, 10.0% (4.0 to 23.1) | 20 of 40, 50.0% (35.2 to 64.8) | 1,964: 155 met nothing, 532 perfect-blocked, 75 guarded, 1,202 hit |
| 0.8 (b04de5d5) | 5 of 40, 12.5% (5.5 to 26.1) | 1 of 40, 2.5% (0.4 to 12.9) | 813 |

**The EP's test (kit at least 25% and the charge pad at most 55%): not met at 0.25.** The kit is 17.5% (under 25) and the charge pad 97.5% (the exploit is open again). The two trade against each other along this knob: the chance that holds the charge pad to 55% or under (0.5) leaves the kit at 10%, and the chance that lifts the kit (0 to 0.25) leaves the charge pad at 97% or so. No value of this one knob in 0, 0.25, 0.5, 0.8 passes both at 40 a cell. Records: `docs/qa/runs/7b69eafc/x06-isolation-lines.txt`.
