# X-06 final read: five pads at Easy, Medium and Hard on main b04de5d5 with Encounter's three x06-bands diffs (QA, run 2026-11-22)

**What it measures.** The X-06 bands on the tree Encounter parked: whole kit Easy 60 to 80%, Medium 35 to 55%, Hard 10 to 30%; every one-note pad at least 20% at Medium; charge-only at most 80% Easy and 55% Medium; stick-only within 10 points of the masher. 40 matches a cell, seeds 1 to 40, Wilson 95% intervals (`docs/qa/sample-size.md`: at 40 a cell this is a smoke, about 12 to 15 points either side).

**Tree and data.** Clean export of main **b04de5d5** with `x06-medium.diff`, `x06-hold-answer.diff` and `x06-hold-answer-schema.diff` applied in the README's order (all three applied clean). QA's `qa/godot/orbs_player.gd --solo` is main's own. Data hash `c88d5a15e514ceab`. Planet 7, touch 3, generation 3, 4,800 columns, energy model on, travel 1.5, no intro; jobs 2 at below-normal priority.

**Pads** (one pad on slot 0 against the computer): strike (strikes and guard), masher (X every 8 ticks), beams (a stick beam every 120 ticks), charge (B held 50 ticks), kit (strikes, guard, a beam every 420, X taps, B charges).

| Pad | Easy | Medium | Hard |
| :--- | :--- | :--- | :--- |
| Whole kit | **32 of 40, 80.0%** (65.2 to 89.5); band 60 to 80: point on the top edge | **5 of 40, 12.5%** (5.5 to 26.1); band 35 to 55: **below** | **0 of 40** (0 to 8.8); band 10 to 30: **below** |
| Strike only | 18 of 40, 45.0% (30.7 to 60.2) | **0 of 40** (0 to 8.8); floor 20: **below** | 0 of 40 |
| X masher | 16 of 40, 40.0% (26.3 to 55.4) | **6 of 40, 15.0%** (7.1 to 29.1); floor 20: below by the point, interval reaches it | 0 of 40 |
| Beams only | 21 of 40, 52.5% (37.5 to 67.1) | **0 of 40** (0 to 8.8); floor 20: **below** | 0 of 40 |
| B charge only | 38 of 40, **95.0%** (83.5 to 98.6); ceiling 80: **above** | **1 of 40, 2.5%** (0.4 to 12.9); floor 20: **below**; ceiling 55: met | 0 of 40 |

Stick-only against the masher: Easy 45.0% to 40.0% (gap 5.0, inside 10); Medium 0.0% to 15.0% (gap 15.0, outside 10, the intervals overlap); Hard 0 to 0.

**Reading.**
- **The Medium charge cell is 1 of 40, as Encounter's sanity read warned (0 of 20).** The exploit is closed (it was 40 of 40) but the pad is now hopeless, under the 20% floor. Of 813 full charges in the cell, 183 met nothing (the computer's dodge) and 177 were perfect-blocked; 421 still hit, and the pad still loses (its hits 2,509 to the computer's 19,194).
- **Every Medium cell is under its band.** The whole kit is 12.5% against 35 to 55%. Candidate alone gave 32.5% (QA, 17a8dd6c); the hold answer takes the kit down with the charge pad, since the kit charges B too.
- **Hard is 0 of 40 everywhere**, including the kit (band 10 to 30; the interval's top, 8.8, is under the band).
- **Easy**: the whole kit is on the top edge (80.0%, interval 65 to 89); the charge pad is above its 80% ceiling (95.0%). No Easy change was parked.
- At Medium the stick-only versus masher gap is 15.0 points (Newcombe 95% for the difference, 3.2 to 29.1), so it is outside the 10-point target and the interval stays above zero; the masher's extra wins are X-only pressure the stick pad does not have.

**Not a verdict.** These are 40-match cells; a number here is not a target and QA tuned nothing. Records: `docs/qa/runs/b04de5d5/x06-final-read-table.md` and `x06-final-read-lines.txt` (every chunk's `ORBS` line).
