# X-16: a defender who steps out of a beam's line, at three ranges (QA, first reading 2026-11-14, tool fixed and rerun 2026-11-20)

**What it measures.** Whether a defender can avoid a stick beam by moving out of its line, at 300, 2,500 and 6,000 units. The criterion is expected to FAIL until the beam is rebuilt in A3.

**Tool.** `qa/godot/x16_sidestep.gd`: a scripted attacker on the real input hub holds RB, leans the right stick toward the foe for 50 ticks and lets go to fire; a scripted defender (a raw intent on slot 1) answers from the moment the beam's window opens by moving straight up with the left stick for up to 40 ticks, no dodge tap and no guard. One seeded match a trial, run to the beam's outcome. PASS needs the beam avoided (DODGE, ESCAPE or DEFLECT) in at least 80% of the beams thrown at every range, and a range where no beam could be thrown counts as FAIL.

**Command.**

```
QA_PLANET="gen=3;planets=7;touches=3;cols=4800;power=1;travel=1.5" godot --headless --path <tree copy with qa/godot/qa_planet.gd> --script res://qa/godot/x16_sidestep.gd -- 20 1 [--ranges=300,2500,6000] [--sidestep=40] [--debug]
```

**Tree.** Build 6a30b4c9's own packed data, nothing patched. 20 trials a range, seeds 1 to 20.

**Result.** **FAIL. 20 of 20 beams hit at each of the three ranges; the defender's height did not change in any trial (median climb 0).** A debug trial shows why: the target is `locked` from the moment the beam is thrown (the beam's stage) until it arrives and he is launched, so a sidestep cannot start (at 2,500 units: thrown tick 87, window 94 to 151, hit at 151). That is the finding the A3 rebuild answers: today a defender in a beam's window has the dodge tap and the guard and nothing else.

**The tool's earlier fault, fixed.** The first reading (2026-11-14) threw no beam at 300 units: the test bound its pad to slot 0 with an X press, which started a lunge and a brawl at that range, so the stick hold became a strike. It binds with a guard press now, and a beam is thrown at all three ranges. The tool also reports the attacker's stick refusals per range (none in this run).

**Record.** `docs/qa/runs/6a30b4c9/x16-first-reading.txt`.
