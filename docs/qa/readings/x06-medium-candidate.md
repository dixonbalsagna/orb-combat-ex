# X-06: Encounter's Medium candidate, measured with five pads (QA, run 2026-11-21)

**What it measures.** Encounter's data-only candidate `docs/director/pending/x06-bands/x06-medium.diff` (sha1 6fe839ae: Medium matches the player's pace as Easy does, `paceMatch`; Medium perfect-blocks a full charge at 0.3, `perfectVsHeavy`), against the targets of Game Design's gauntlet-plan section 9: the whole-kit pad inside 35 to 55% at Medium; each one-note pad 20 to 55% (none hopeless, none the best way to play: the charge exploit under 55%); stick-only within 10 points of the masher.

**Tool.** `qa/godot/orbs_player.gd --solo` (one pad against the computer; five pads: **strike** strikes and the LB guard only, **masher** X every 8 ticks, **beams** only a stick beam every 120 ticks, **charge** B held 50 ticks and let go, **kit** strikes, guard, a beam every 420, X taps every 14 to 26 ticks and a B charge every 300 to 390), run in two chunks by `qa/godot/run-chunks.js`.

**Tree.** Main **17a8dd6c** exported clean, imported, with the candidate applied (`m17on`), and main 17a8dd6c alone (`m17base`) for two comparison cells. Planet 7, touch 3, generation 3, 4,800 columns, the energy model on, travel 1.5, the computer at Medium; **40 matches a cell, seeds 1 to 40** (40 is Game Design's sample: the intervals are wide, ±12 to 15 points); jobs 2, below normal.

**Command** (each pad; `--mode=masher --beamevery=0`, `--mode=beams --beamevery=120`, `--mode=charge --beamevery=0`, `--mode=kit`, and `--beamevery=0` for strike):

```
QA_PLANET="gen=3;planets=7;touches=3;cols=4800;power=1;travel=1.5;level=medium" node qa/godot/run-chunks.js --root=<tree> --script=res://qa/godot/orbs_player.gd --total=40 --chunks=2 --base=1 --out=<prefix> -- --solo <pad args>
```

**Result, candidate on** (Wilson 95%; records `docs/qa/runs/17a8dd6c/x06-medium-candidate-five-pads.md` and `-lines.txt`):

| Pad at Medium | Won of 40 | Win rate | 95% interval | Target | Reading |
| :--- | ---: | ---: | :--- | :--- | :--- |
| Strike-only | 0 | 0.0% | 0.0 to 8.8% | 20 to 55% | **below** |
| X masher | 6 | 15.0% | 7.1 to 29.1% | 20 to 55% | below by the point; the interval reaches 20 |
| Beams only | 0 | 0.0% | 0.0 to 8.8% | 20 to 55% | **below** |
| B charge only | 40 | **100.0%** | 91.2 to 100.0% | under 55% | **above: the exploit is not closed** |
| Whole kit | 13 | 32.5% | 20.1 to 48.0% | 35 to 55% | below by 2.5 points; the interval crosses the band |

Stick-only against the masher: 0.0% against 15.0%, **15.0 points** (target: within 10).

**Against main alone** (same tree and seeds, two cells): the whole kit **0 of 40 (0.0%, 0 to 8.8%) becomes 13 of 40 (32.5%)** with the candidate; the charge pad is **40 of 40 either way**, though the candidate does raise Medium's perfect block against full charges from **14.8% (265 of 1,796) to 30.0% (649 of 2,164)**, as built, the same as Hard's 28.4% (A-AI-10).

**What it says.** The candidate does the pace part: the whole kit goes from 0% to 32.5%, within 3 points of the band's floor with an interval that crosses it. It does not close the charge exploit: with the computer perfect-blocking 30% of full charges the charge pad still wins every match (40 of 40), where at Hard (28.4% blocks) the same pad wins 14 of 60. So the charge pad's win at Medium is not the perfect-block rate; something else in Medium's level (its damage, its own attacks, its guard) lets full charges through. Strike-only and beams-only are at 0 of 40 and the masher at 15%, under the 20% floor; stick-only is 15 points under the masher.

**Limits.** 40 matches a cell; one cadence per pad; the five pads are one script's idea of each style; baseline cells only for the charge pad and the whole kit.
