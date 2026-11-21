# A-CODE-02: the QA batch once with the switches as shipped, for the new golden record (QA, 2026-11-14)

Tree: main **cf909e93**, exported clean (`git archive`), **nothing flipped** (the data as shipped: switches off where main has them off), nothing patched; QA's working scripts (`qa/godot/records.gd`, `qa_planet.gd` and the readers) laid over it. Run: `qa/godot/run-arm.js --count=60 --jobs=3`, the computer at easy on both sides, whole ring (`gen=3;planets=3,7,11,13,17,19,23,25,37,31;touches=0,1,2,3;cols=4800`, no energy model, no travel key: main's own defaults), seeds 1 to 60. Below normal priority. Output: `shipped-switches-rows.md` (the rows the harness evaluates, 215 lines).

**Counts of the rows:** 69 PASS, 33 FAIL, 45 INFO, 68 PENDING (no record fed them, or the build lacks the event). Match length median 359.9 s (a FAIL of 0.1 s under 360), p10 289.4 s (FAIL, under 300), p90 455.6 s (PASS). The FAIL rows are the harness's old bands (several are retired by later rulings, for example the civilian band, RL-257); the point of this run is the record: the rows and their values as main plays today, to compare against once GW1a changes main's switches.

Read: QA's rows are tests, never targets. The seed set is 1 to 60 and the batch is repeatable with the same command.
