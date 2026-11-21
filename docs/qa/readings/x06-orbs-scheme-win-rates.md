# X-06: win rates for a scripted player on Orb's scheme at Easy, Medium and Hard (QA first reading, run 2026-11-14; pad-or-game follow-up 2026-11-20)

**What it measures.** The proposed criterion X-06: a scripted player using Orb's scheme (right-stick attacks, LB guard) wins inside a band at each level: **Easy 60 to 80%, Medium 35 to 55%, Hard 10 to 30%**. How many matches a cell needs, and the interval method, are in `docs/qa/sample-size.md` (Wilson 95%).

**Tool.** Tools' `tools/feel/gauntlet.gd --arm=orbs`: one scripted pad on the real input hub plays slot 0 against the computer, whole seeded matches: a right-stick strike every 30 to 48 ticks, LB held from the foe's wind-up until contact, the left stick at the foe. It presses no face button and throws no beam. Run in chunks by `qa/godot/run-chunks.js`.

**Command.**

```
QA_PLANET="gen=3;planets=7;touches=3;cols=4800;power=1;travel=1.5" node qa/godot/run-chunks.js --root=<tree> --script=res://tools/feel/gauntlet.gd --total=200 --chunks=3 --base=1 --out=<prefix> -- --arm=orbs --level=easy|medium|hard --capsec=900
```

**Tree and data.** The kept 9 November build **6a30b4c9** (folder `6627cb9d70b784fa-ug+soundMoments+soundCarry-tb28ef5e9-e921fb3-sa90aad-p1aa485`), its own tree copied to scratch with nothing patched over sim or data; only `qa/godot/qa_planet.gd` and `tools/feel/gauntlet.gd` (main's) added. **Data hash `90c61a45b1011721`, equal to `data` in Orb's saved play file of that build** (`qa/godot/data_hash.gd`). Planet 7, touch 3, generation 3, 4,800 columns, the energy model on, travel 1.5, flat-out 5,000, no intro. Seeds 1 to 200 a cell (Easy 1 to 400).

**Result** (full report `docs/qa/runs/6a30b4c9/x06-first-reading.md`; the chunk lines `x06-gauntlet-lines.txt`, `x06-pad-or-game-lines.txt`):

| Level | Matches | Won | Win rate | 95% interval | Proposed band | Reading |
| :--- | ---: | ---: | ---: | :--- | :--- | :--- |
| Easy | 400 (first 200: 54.0%; next 200: 68.0%) | 244 | **61.0%** | 56.1 to 65.7% | 60 to 80% | on the lower edge: the point is in, the interval crosses it; the two seed halves differ by 14 points (4.8 to 23.6), so the interval is likely too narrow |
| Medium | 200 | 0 | **0.0%** | 0.0 to 1.9% | 35 to 55% | far outside |
| Hard | 200 | 0 | **0.0%** | 0.0 to 1.9% | 10 to 30% | far outside |

**Is the 0% the pad script or the game? Both.** The same build and seeds at Medium, 60 matches each: the X-masher (X only) wins 5 (8.3%, 3.6 to 18.1%), a beam pad (RB beams and X) wins 4 (6.7%, 2.6 to 15.9%), and the `orbs` pad 0 of 200. (1) The `orbs` script is the weakest pad: strikes and guard only, no beam, no face button; stick-only pads have lost to Medium in every reading QA has made. (2) The game is also hard at Medium for any scripted pad: the best two win under 10%, against a band of 35 to 55%; an earlier build gave the masher 49.7%. What a person who plays like Orb wins at Medium is not measured: Orb's own plays against Easy were won (three files), none against Medium.

**The single-pad player with the beam (2026-11-20, `orbs_player.gd --solo`, 100 matches each, seeds 1 to 100):** Easy **100 of 100** (96.3 to 100.0%) against a proposed 60 to 80%; Medium **6 of 100** (2.8 to 12.5%) against 35 to 55%. The beam is what makes Orb's scheme win at Easy (61% without it), and Medium is a cliff for the same pad. Details in `docs/qa/runs/6a30b4c9/x06-first-reading.md`.

**What a pad that only charges B does (A-AI-10, 2026-11-20, 60 matches each, same data):** Easy 60 of 60, **Medium 60 of 60**, Hard 14 of 60 (23.3%, 14.4 to 35.9%, inside the proposed 10 to 30%). The Medium cliff is not general: it is the stick-and-guard and masher pads that lose; a charged-heavy pad wins every Medium match, because the computer perfect-blocks only 15.1% of full charges there (`a-ai-10-perfect-block.md`).

**One plain line for RISKS.** Which pad you script decides the level: Orb's stick-and-guard pad wins 6 of 100 at Medium, the single pad with beams 6 of 100 (Easy 100 of 100), the charge-only pad 60 of 60 at Medium and 14 of 60 at Hard; no scripted pad sits in the Easy or Medium band, so the proposed bands cannot be judged without saying which player they are for.
