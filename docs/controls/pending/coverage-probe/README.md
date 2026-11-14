# coverage-probe (park, on HEAD 51b840f5): A-CONTROLS-06, the moveset coverage probe

Controls, 2026-11-14, sprint A1 wave 2. A scripted pad presses every cell of the move table (101 per fighter) in a live match through the real hub, reads the build's own data, and says per cell: outcome, same as an earlier cell, refused (said) or nothing (silent). Design, the way to run it and how to add a cell: `docs/controls/coverage-probe.md`. Records: `docs/controls/runs/51b840f5/` (CD-22).

## Apply

`git -c core.autocrlf=false -c core.eol=lf apply docs/controls/pending/coverage-probe/coverage-probe.patch`: three new files in Controls' path, `sim/input/tools/coverage_probe.gd` (+ `.uid`) and `sim/input/tools/coverage_cells.json`. No existing file changes, nothing in the sim, no grant, no switch, no schema.

## Tested

- First reading on the kept 9 November build's own tree, both fighters: `coverage-kept-6a30b4c9-reading.txt`. Per fighter 101 cells, 5 with no outcome (3 silent, 2 refused with a word), 32 repeats (43 or 44 counting the same move). Two readings are byte-identical.
- Control: the same probe on the kept data with main's old `timing.json` (pad switches off) reads 10 of 101 cells differently and the "Charging" refusals are gone (`coverage-control-old-timing.txt`). So the probe sees the pad.
- The probe also runs on main plus the pad group (a quick cell run there, `data` hash differs from the kept build's as the other groups are not on yet).
- `lint-determinism` ok; validator 321 files, 0 errors; the patch applies on a clean `git archive` of HEAD and reproduces the tested files byte for byte.
- It needs one Godot job and about 100 s for both fighters, below normal priority.

## Waiting on others

- **Combat (through the EP):** the `by_design` sentences for the cells that are empty on purpose, and any cell the table has that the file lacks (acceptance item 5). Until then the five silent or refused cells and the repeats read as "unexplained", which is the honest reading.
- **Tools, a CI step** (the reading is wanted on every build from A2): run `coverage_probe.gd` against the packed build (`--main-pack`) and save the output; fail only on a SCRIPT ERROR (the count is a reading, not a gate until A4's table).
