# A-COMBAT-05: stick beams that fire late after a new press, before and after Encounter's fix (QA, run 2026-11-14)

**What it measures.** Encounter's stray-beams acceptance 3 (park `docs/director/pending/stray-beams/`): how often a waiting stick beam fires after the player pressed something else, and the refusals beside it, with `ownMove.dropOnPress` off against on on one tree.

**Tools.** `qa/godot/stray_count.gd` (replays Orb's saved files; `--drop=0|1`), and for the scripted set `qa/godot/records.gd` with `QA_HUMAN=rbeam QA_FORCE="drop=0|1"` through `qa/godot/run-arm.js` (a scripted human holds RB and leans the right stick toward the foe, lets go, then mashes X; the counters are `strayFires`, `strayLate`, `strayGaps`, `strayRef` in each record).

**Tree.** Build 6a30b4c9's tree with the park's code hunks applied (its data hunk did not apply to that tree, so the key `ownMove.dropOnPress` is set at run time, `0` the old wait, `1` dropped by a new press). Orb's 1646 file replays faithfully up to the first press the rule changes; after that the world differs.

**Result.**

| | dropOnPress 0 | dropOnPress 1 |
| :--- | ---: | ---: |
| Orb's 1646 file: stick beams / late after a new press | 8 / 1 (tick 5220, 33 ticks after the release, Y at 5211) | 6 / 0 (the 5220 beam dropped at the Y, refused `replaced`; the match differs after) |
| Scripted set (60 matches v easy): stick beams | 235 | 221 |
| ... late after a new press | **30 (12.8%)**, median 53 ticks after the release | **1 (0.5%)** |
| ... refusals in all | 805 (soon 168, taken 466, close 156, late 13, ki 2) | 939 (replaced 99, soon 189, taken 474, close 174, ki 3) |

Dropping removes the late fires and shows as `replaced` refusals. Orb's 1625 file has no stick beam. Records: `docs/qa/runs/6a30b4c9/stray-beams-scripted-set.md`, `stray-beams-replay-orb-files.txt`, and the replay report `docs/qa/runs/6a30b4c9/README.md`.
