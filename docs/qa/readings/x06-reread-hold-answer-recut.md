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
