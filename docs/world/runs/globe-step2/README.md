# Runs: terrain step 2 (World, 2026-11-09), park `docs/world/pending/globe-step2/` on HEAD 20713b02

CD-22. A clean export of HEAD, the park's patches applied by edit in a scratch tree, one Godot job at a time at below-normal priority (the full World run was three jobs at most with the audit and parity beside it). Logs are the verdict lines and the tails.

| File | What |
| :--- | :--- |
| `globe-check-passes.txt` | `GLOBE: 0 check(s) failed`, 67 ok lines |
| `NEGATIVE-CONTROL-1-shaft-cap-reads-no-relief.txt` | the shaft cap made blind to relief: 6 FAIL lines (20 hits dig 915 and 893 deep, 10 base hits reach 600) |
| `NEGATIVE-CONTROL-2-groove-takes-the-lower-over-a-rim.txt` | a groove over a rim the old way (the lower of the two): 1 FAIL (a 37-unit cliff in 8 units, the new form 9) |
| `NEGATIVE-CONTROL-3-every-hole-finds-a-source.txt` | every hole finds the sea: 3 FAIL (the inland hole holds water, the strip reads it, the chain test) |
| `NEGATIVE-CONTROL-4-a-superseded-record-is-read.txt` | a superseded record read as live: 2 FAIL |
| `checks-verdicts.txt` | the verdict line of every one of the 86 World checks on the re-cut tree (step_check's timing line failed once under load and passes alone) |
| `parity-passes-golden-unmoved.txt` | parity with the golden as it is on main: passes (9 matches, 174,798 ticks identical) |
| `globe-audit-40-seeds-grooves-off-as-shipped.txt`, `-grooves-on.txt` | the ported terrain audit, 40 AI matches: as shipped (groove settling off) 14 matches over 6 steps, every one a slide trench; with it on, 0 steps in all |
| `chase_rush_check-HEAD-alone-passes.txt`, `-with-groove-settling-FAILS-4.txt`, `-recut-passes.txt` | Camera's check on HEAD alone, on the first cut (4 rows over the jolt limit) and on the re-cut |
| `gates.log` | 19 sim, render and net gates, final tree |
| `lint-determinism.txt`, `validate-ratchet-screen-verify.txt` | the lint (self-test 91 checks, tree clean), validate (self-test 10,093 of 10,093), ratchet 365, content screen 0, world-checks --verify |
