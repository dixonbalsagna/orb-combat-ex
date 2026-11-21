# The cityHold city read, for Orb's private build (QA, run 2026-11-20)

**What it measures.** Whether Encounter's and World's cityHold fix (the building holds a sent fighter instead of throwing him back; the fight is not frozen; his depth is not pulled home through the air) does what it says over seeded AI-v-AI city matches, and whether it costs anything: buildings fallen, building hits, **throw-backs** (the ping-pong), **fight freezes**, **how the fighter returns to the fight line**, match length and bystanders. The result decides whether Orb gets a private build to try it.

**Tool.** `qa/godot/records.gd` (new counters `cityHits` and `pauseTicks`: every `building_hit` of a body, with the body's velocity one tick before, whether its velocity flipped against its way at 10% of its speed or more within 40 ticks, the longest held clock (hit-stop) within 40 ticks, the ticks until its depth was within a tenth of the depth it was hit at, and whether it was still launched then) through `qa/godot/run-arm.js --start=town`, read by `qa/godot/city-hold.js`.

**Trees (two copies of the GW1a final tree, the EP's `s423`, imported).** *cityHold off:* the tree as it is (today's values: `wallRebound` 0.25, `wallStop` 1.0, `wallDepthHold` 0, `lodgeHold` "world", `repeatMarks` 0) plus Encounter's air grant, which is inert while `wallDepthHold` is 0. *cityHold on:* the same tree with **World's five numbers** (`lodgeHold` "body", `wallRebound` 0, `wallStop` 0, `wallDepthHold` 1, `repeatMarks` 2: `docs/world/pending/wall-hold-on/wall-hold-data.diff`), **Encounter's wall-hold-air** (`grant-world-holdair.patch`, the one line in `WorldBrunt.stepZ`) and its check script. **World's wall-hold-pins and wall-hold-split diffs did not apply to this tree** (it has neither the split nor globe-step2), so the original data row was used: the crater repeat key `repeatCraters` does not exist in it, and the planet matches here do not read the old crater repeat; the pins only re-pin four check scripts and change no behaviour. **Settings:** AI v AI at easy, whole ring (gen 3, 4,800 columns, planets 3,7,11,13,17,19,23,25,37,31, touches 0 to 3), the energy model on, travel 1.5, **a start in a town** (`--start=town`: both fighters in a first-ring place of three buildings or more), seeds 1 to 60 in each arm, `--jobs=2`, below normal priority.

**Command** (each tree):

```
QA_PLANET="gen=3;planets=3,7,11,13,17,19,23,25,37,31;touches=0,1,2,3;cols=4800;power=1;travel=1.5;level=easy" QA_GODOT_ROOT=<tree> node qa/godot/run-arm.js --count=60 --jobs=2 --start=town --out=<records.json>
node qa/godot/city-hold.js "cityHold off=<records.json>" "cityHold on=<records.json>"
```

**Result** (60 matches an arm; Wilson 95% for shares, bootstrap 95% for means and medians; table `docs/qa/runs/gw1a-s423/cityhold-city-table.md`):

| Measure | cityHold off | cityHold on |
| :--- | :--- | :--- |
| Hits where the body was **thrown back** (velocity flipped) | **44.1%** (35.8 to 52.8), 56 of 127 | **2.0%** (0.7 to 5.6), 3 of 153 |
| Throw-backs a match | 0.93 (0.68 to 1.18) | 0.05 (0.00 to 0.12) |
| Hits followed by a **fight freeze** of 10 ticks or more | **92.9%** (87.1 to 96.2) | **27.5%** (21.0 to 35.0) |
| Longest freeze after a hit, ticks (median / p90 / max) | 30 / 38 / 38 | 8 / 19 / 19 |
| Depth **home while still in the air** | **76.0%** (67.8 to 82.6) | **4.8%** (2.2 to 10.1) |
| Ticks until the depth was home (median / p90; hits 100 or more off the line) | 75 / 117 | 159 / 300 |
| Buildings fallen a match | 133.4 (117.7 to 149.7) | 137.3 (122.5 to 152.9) |
| Building hits a match | 2.1 (1.7 to 2.6) | 2.5 (1.8 to 3.4) |
| Match length, median s (95%) | 670 (667 to 674) | 668 (665 to 672) |
| Bystanders: the highest casualty share any match reached; civilians lost | 0 in 60 matches; 0.00% | 0 in 60 matches; 0.00% |

**What it says.**
- **The ping-pong is gone as far as this read can see:** throw-backs fall from 44% of building hits to 2%, and the fight freeze after a wall hit from 93% of hits (a median 30 ticks) to 27% (median 8; what remains is the other outcomes' hit-stop, collapses and punches).
- **The mid-air pull home is gone:** from 76% of hits to 4.8% the fighter's depth gets home while he is still in the air. He is slower to get back to the line, on the ground (median 159 ticks against 75; the 90th percentile hits the 300-tick limit).
- **It costs nothing visible in the match:** buildings fallen (133 against 137), building hits (2.1 against 2.5) and match length (670 against 668 s) read the same inside their intervals. Nobody was lost in any of the 120 matches (the casualty share stayed 0), and the scatter events are the same (85 and 87 a match).
- **The three that remain throw-backs** (3 of 153) and the freezes that remain are not wall rebounds as built: QA has not opened them.

**Limits.** The throw-back is an estimate from the body's velocity one tick before the hit (a flip at 10% of its speed or more within 40 ticks); AI v AI at easy from a town start, not a person's play and not the in-air chain; the count of hits per match is small (2 to 3), so the matches give 127 and 153 hits. Encounter's bounce count was not available; this read does not use it. The first run of this read (2026-11-20) counted no freeze and no throw-back because it looked at the set-piece pause, not the held clock, and its throw-back threshold equalled the rebound's own 25%; both were fixed and the arms rerun (the numbers above are the rerun).
