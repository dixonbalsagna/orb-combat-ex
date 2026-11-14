# coverage-probe (park, on HEAD 51b840f5; re-parked 2026-11-14 with Combat's cells): A-CONTROLS-06, the moveset coverage probe

Controls, sprint A1 wave 2. A scripted pad presses every cell of the move table (116: Combat's S4 file) in a live match through the real hub, reads the build's own data, and says per cell: outcome, same as an earlier cell, same move, refused (said) or nothing (silent), with Combat's `by_design` and `proposed` on every line and X-03's `EXPLAINED` count. Design, the way to run it and how to add a cell: `docs/controls/coverage-probe.md`. Records: `docs/controls/runs/51b840f5/` (CD-22).

## Apply

`git -c core.autocrlf=false -c core.eol=lf apply docs/controls/pending/coverage-probe/coverage-probe.patch`: three new files in Controls' path, `sim/input/tools/coverage_probe.gd` (+ `.uid`) and `sim/input/tools/coverage_cells.json` (Combat's cells, `docs/combat/pending/move-table/coverage_cells.json`, the same 116 cells in one line each). No existing file changes, nothing in the sim, no grant, no switch, no schema. If Combat's file changes, replace the json.

## What changed since the first park

- Combat's cells file (116) in place of mine (101); the layers `brawl`, `brawlLT`, `brawlLB` and `air` are read from the cells, so the baseline list is gone from the code.
- `by_design` (and `proposed`) print on every line; `EXPLAINED` lines count no outcome and repeats by design, proposed and unexplained.
- Combat's three traps: both fighters stand on the floor (the grounded down flick now reads `scythe_sweep`, the air one `spike_heel`); the joining A press no longer opens a taunt; a clinch the opening makes is waited out (`--dist=100` reads a blow).
- Two things found while fixing them: the air layer's pre starts at tick -70, so the first tick is now -80; and an air cell needs the foe at the fighter's height, or the lunge only brings him down to a foe on the floor and the blow is the grounded one.

## Tested

- Reading on the kept 9 November build's own tree, both fighters: per fighter 116 cells, 5 with no outcome (3 silent, 2 refused with a word; none explained), 37 repeats (48 or 49 counting the same move; 22 by design, 19 proposed, 7 or 8 unexplained). Two readings byte-identical (`coverage-kept-6a30b4c9-reading.txt`).
- Control: kept data with main's old `timing.json` reads 11 of 116 cells differently (`coverage-control-old-timing.txt`).
- Lint ok; validator 321 files, 0 errors; the patch applies on a clean `git archive` of HEAD and reproduces the tested files byte for byte; the cells equal Combat's file cell for cell.

## Waiting on others

- **Combat / Game Design:** the 5 unexplained no-outcome cells (LB + A three ways: Combat's question for Orb; the stick under RT: "Charging" is a refusal) and the 7 or 8 unexplained repeats; the 19 proposed shares need Game Design's page.
- **Tools, a CI step** (the reading is wanted on every build from A2): run `coverage_probe.gd` against the packed build (`--main-pack`) and save the output; fail only on a SCRIPT ERROR (the count is a reading, not a gate until A4's table).
