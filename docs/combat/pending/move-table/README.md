# move-table: Combat's notes on the coverage probe's cells (S4)

Combat, 2026-11-14, for Controls' `docs/controls/pending/coverage-probe/` (A-CONTROLS-06). Paper only.

`coverage_cells.json` is Controls' 101 cells unchanged, with:
- `by_design` filled where a design page already says the cell is empty or shared on purpose. The probe prints it on a cell with no outcome (see below).
- `combat`: own, by_design, proposed, gap_alpha or gap_probe.
- `proposed`: a share Combat proposes and Game Design has to write into the design page before it counts as by design.
- `note`: why, and the item in `../../move-table-s4.md`.
- **15 new cells** at the end, marked `added_by`. They need four layers added to the probe's baseline list (`brawl`, `brawlLT`, `brawlLB`, `air`), one line in `_fighter`.

**To use it:** Controls replaces their `sim/input/tools/coverage_cells.json` with this file, or copies the `by_design` fields across. The probe ignores the other fields. Tried on the kept 9 November build with the four layers added: all 116 cells read cleanly, and the first 101 count as before.

**One thing for Controls:** the probe prints `by_design` only on a cell with no outcome. All 23 of mine are repeats, and the empty cells (LB + A, RT + stick) are real gaps, so nothing prints today. X-03's count needs repeats marked as well, so the probe should print `by_design` on a `SAME AS` or `SAME MOVE AS` line too.
