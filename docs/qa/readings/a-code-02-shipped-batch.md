# A-CODE-02: the QA batch once with the switches as shipped, for the new golden record (QA, run 2026-11-14)

**What it measures.** The rows QA's harness evaluates, on main with nothing flipped (the data as shipped), so that GW1a's changes can be compared against one saved record.

**Tool.** `qa/godot/run-arm.js` (records by `qa/godot/records.gd`, rows by `qa/godot/bands.js`). **Command:**

```
QA_PLANET="gen=3;planets=3,7,11,13,17,19,23,25,37,31;touches=0,1,2,3;cols=4800;level=easy" QA_GODOT_ROOT=<tree> node qa/godot/run-arm.js --count=60 --jobs=3 --out=<records.json> --md=<rows.md>
```

**Tree.** Main **cf909e93**, a clean `git archive` (sim, data, net, project.godot, qa, prototype/tools), imported once, nothing flipped, nothing patched; QA's working copies of the scripts laid over `qa/godot`. The computer at easy on both sides; whole ring; no energy model key and no travel key (main's own defaults); seeds 1 to 60; below normal priority.

**Result** (`docs/qa/runs/cf909e93/shipped-switches-rows.md`, 215 lines): 69 PASS, 33 FAIL, 45 INFO, 68 PENDING. Match length median 359.9 s (a FAIL by 0.1 s), p10 289.4 s (FAIL), p90 455.6 s (PASS). Several of the FAIL rows are bands later rulings retired (for example the civilian band, RL-257). The record is the point; the rows are tests, never targets.

**Repeat.** The same command on a later commit's clean export gives the comparison; the seeds and the settings are in the command.
