# A-AI-10: the computer's perfect-block rate against charged attacks, on the played build (QA, run 2026-11-20, before Encounter re-cuts it)

**What it measures.** How often the computer perfect-blocks a heavy that has been charged to full, at Easy, Medium and Hard, on the kept 9 November build's own packed data, so Encounter's re-cut can be compared against it.

**Tool.** `qa/godot/orbs_player.gd --solo --mode=charge`: one pad on the real input hub against the computer; it walks at the foe with the left stick and **holds B (the heavy, the only blow that charges) for 50 ticks, lets go, waits 40 to 60 ticks, and repeats**; it does nothing else (no guard, no strike, no beam, no other button). **The pairing** (`_pair` in the script): each `blow` cue of slot 0 with the text `release` is a charged heavy (the share of the charge is in the cue: 1.0 or more is a full charge); it waits for what the computer did to it from its release to its landing plus 12 ticks: a **perfect block** (the cue `stagger:perfect_block` whose actor is the pad's fighter: his blow was turned), a **guard** (damage of kind `guard` on the computer), a **hit** (any other damage by the pad on the computer) or nothing. Run in two chunks by `qa/godot/run-chunks.js`.

**Command.**

```
QA_PLANET="gen=3;planets=7;touches=3;cols=4800;power=1;travel=1.5;level=easy|medium|hard" node qa/godot/run-chunks.js --root=<tree> --script=res://qa/godot/orbs_player.gd --total=60 --chunks=2 --base=1 --out=<prefix> -- --solo --mode=charge --beamevery=0
```

**Tree and settings.** Build 6a30b4c9's own data, nothing patched (data hash `90c61a45b1011721` for Orb's play-file setup); planet 7, touch 3, generation 3, 4,800 columns, the energy model on, travel 1.5; 60 matches a level, seeds 1 to 60; below normal priority, two Godot processes.

**Result** (Wilson 95% intervals; table `docs/qa/runs/6a30b4c9/a-ai-10-perfect-block-table.md`, lines `a-ai-10-perfect-block-lines.txt`):

| Level | Charged heavies thrown | Perfect-blocked | **Perfect-block rate** | Guarded | Hit | Nothing |
| :--- | ---: | ---: | :--- | ---: | ---: | ---: |
| Easy | 2,203 | 94 | **4.3%** (3.5 to 5.2) | 106 | 1,995 | 8 |
| Medium | 2,564 | 388 | **15.1%** (13.8 to 16.6) | 245 | 1,882 | 49 |
| Hard | 2,495 | 709 | **28.4%** (26.7 to 30.2) | 102 | 1,587 | 97 |

Partial charges (a release below full charge, taps included): 15 of 354 at Easy, 101 of 825 at Medium, 170 of 716 at Hard perfect-blocked.

**What it says.** The computer perfect-blocks a fully charged heavy 4.3% of the time at Easy, 15.1% at Medium and 28.4% at Hard: it blocks far less than one in six at Medium, and 72% of charged heavies still hit at Hard (63% hit at Hard counting the guarded). Easy and Medium almost never answer the charge.

**A finding that follows: the pad that only charges B wins.** Against the same computer this pad won **60 of 60 at Easy, 60 of 60 at Medium and 14 of 60 at Hard (23.3%, 14.4 to 35.9%)**. So at Medium a charged-heavy pad is at 100%, where Orb's stick-and-guard pad wins 6 of 100 and the masher 8%: the Medium cliff of X-06 depends on what the pad plays, and the computer's weakness is the charged heavy (its perfect block, 15%). Hard sits inside the proposed 10 to 30% band for this pad.

**Limits.** One pad, one cadence (a release every 90 to 110 ticks); the computer's block depends on what it was doing when the heavy came, and a person times charges differently. "Partial" includes taps (a release at charge share 0). The `none` rows are blows that landed on nothing within the window (the computer got away).
