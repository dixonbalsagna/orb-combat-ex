# A-QA-04: are the two fighters even, in each slot? (QA first reading, run 2026-11-14)

**What it measures.** Whether PROTAGONIST and RIVAL win equally often when each plays each slot, on the packed data of the kept 9 November build, with both fighters played by the same scripted player on Orb's scheme.

**Tool.** `qa/godot/orbs_player.gd` (two pads on the real input hub: a right-stick strike every 30 to 48 ticks, LB held from the foe's wind-up to contact, the left stick at the foe, and a right-stick beam every 420 ticks held 50, so both slots throw stick beams), run in chunks by `qa/godot/run-chunks.js`. Arms: `default` (PROTAGONIST slot 0, RIVAL slot 1) and `swap` (each fighter in the other's slot).

**Command** (from a tree copy of the build with `qa/godot/` laid over it; `QA_PLANET` is the setup of `qa/godot/qa_planet.gd`):

```
QA_PLANET="gen=3;planets=7;touches=3;cols=4800;power=1;travel=1.5" node qa/godot/run-chunks.js --root=<tree> --script=res://qa/godot/orbs_player.gd --total=100 --chunks=3 --base=1 --out=<prefix> -- --arm=default
(the same with --arm=swap)
```

**Tree and data.** Build 6a30b4c9 (folder `6627cb9d70b784fa-ug+soundMoments+soundCarry-tb28ef5e9-e921fb3-sa90aad-p1aa485`), nothing patched over its sim or data; data hash `90c61a45b1011721` for Orb's play-file setup (`qa/godot/data_hash.gd`). Seeds 1 to 100 in each arm, 100 matches each, 200 in all.

**Result** (Wilson 95% intervals; the table is `docs/qa/runs/6a30b4c9/balance-both-slots-table.md`):

| Reading | Matches | Won | Rate |
| :--- | ---: | ---: | :--- |
| PROTAGONIST wins over both slots | 200 | 110 | 55.0% (48.1 to 61.7) |
| RIVAL wins over both slots | 200 | 90 | 45.0% (38.3 to 51.9) |
| Slot 0 wins over both arms (a slot effect) | 200 | 100 | 50.0% (43.1 to 56.9) |

PROTAGONIST as slot 0 against as slot 1: 0.0 points (Newcombe 95%, -13.5 to 13.5). Draws 0, timeouts 0; each slot threw about 1,330 stick beams in each arm (2,670 in the default arm, 2,656 in the swap arm). Median match about 700 s.

**What it says.** The two fighters are even within the interval the sample allows: 55.0% for PROTAGONIST, with 50% inside the interval, and no slot effect. This tells the fighters apart only if the true gap is about 14 points or more (sample-size page).

**Records.** `docs/qa/runs/6a30b4c9/balance-both-slots-table.md`. The chunk output files hold one `ORBS` JSON line each and sit in the scratchpad.
