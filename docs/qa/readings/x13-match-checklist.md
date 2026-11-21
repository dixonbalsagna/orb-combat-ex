# X-13: the Alpha match checklist, first reading (QA; tool rebuilt and rerun 2026-11-20)

**What it measures.** The criterion X-13 (`docs/ep/alpha/alpha-audit-specification.md` line 180): in one normal match of 6 to 8 minutes, ten things show up at least once: **a lap of the globe, each stance used, a beam aimed and dodged by moving off its line, both signatures on Orb's inputs, a launch, the gravity well's pull, a crater, a building damaged, bystanders scattering, and a transformation.** Read from the match's event feed, on scripted matches and on Orb's saved play files.

**The earlier tool was the wrong one.** The first version (`qa/godot/pillars.js`) checked the seven design pillars of CLAUDE.md, not these ten items. It stays as a separate, informational read (`pillars-seven-design-pillars-reading.md` in `docs/qa/runs/6a30b4c9/`) and is no longer called X-13.

**Tool.** `qa/godot/checklist_core.gd` (the test of each of the ten items is stated at its top) with two drivers: `qa/godot/checklist.gd` (replays saved play files on the tree each was built from) and `qa/godot/orbs_player.gd` (scripted matches: Orb's scheme on both slots, which prints the checklist per match). It only reads.

**Commands.**

```
godot --headless --path <the build's tree> --script res://qa/godot/checklist.gd -- <play file.json> [<play file.json> ...]
QA_PLANET="gen=3;planets=7;touches=3;cols=4800;power=1;travel=1.5" node qa/godot/run-chunks.js --root=<tree> --script=res://qa/godot/orbs_player.gd --total=20 --chunks=2 --base=1 --out=<prefix> -- --arm=default
```

**Results** (records `docs/qa/runs/6a30b4c9/x13-first-reading.txt`, `x13-scripted-matches.txt`; builds' own trees, nothing patched):

| Item | Orb's 1646 play (6a30b4c9, 5.4 min, won) | Orb's 1625 play (0.6 min, cut short) | 20 scripted matches (both slots on Orb's scheme, about 11.7 min each) |
| :--- | :--- | :--- | :--- |
| Lap of the globe | not seen | not seen | 0 of 20 |
| Each stance used | seen (none, LB, RB, RT, LT, by the end of the play) | not seen (none, LT) | 0 of 20 (the pad uses LB and RB only) |
| Beam dodged by moving off its line | not seen | not seen | 0 of 20 |
| Both signatures on Orb's inputs | not seen: slot 0 threw 8 (7 stick, 1 RT + B), slot 1 is the computer | not seen | **20 of 20** (260 and 277 stick beams) |
| A launch | seen, tick 826 | seen, tick 1624 | 20 of 20, median first tick 953 |
| The gravity well's pull | not seen: no such event in this build | same | 0 of 20: no such event |
| A crater | seen, tick 36 | seen, tick 36 | 20 of 20, median 1,282 |
| A building damaged | seen, tick 1,000 | not seen | 20 of 20, median 910 |
| Bystanders scattering | seen, tick 1,000 | seen, tick 959 | 20 of 20, median 598 |
| A transformation | seen, tick 9,453 | not seen | 0 of 20 |
| **Seen** | **6 of 10** | 3 of 10 | 5 of 10 in every match |

Orb's earlier files (build 1931a0f8 on its own tree): `x13-first-reading.txt` has them (1714: 3.7 min; 1726: 5.1 min, with a beam dodged by a deflect after the target moved, tick 15,078).

**What it says.** **Three of the ten are in no play yet:** the lap (no match was long or fast enough: the scripted matches run 11.7 minutes and still show no lap), the beam dodged by moving off its line (the target is locked while a beam is on its way, X-16), and the gravity well (no event exists). **"Both signatures" needs two human slots:** only the scripted two-pad matches show it; in Orb's plays the second fighter is the computer. **Stances and the transformation** are in Orb's 1646 play but not in the scripted pad's matches (it does not use RT or LT and takes no form). Orb's own 1646 play shows six of ten. The criterion's 6 to 8 minutes is not what the scripted pad plays: its matches last 11.7 minutes against 5.4 for Orb's 1646.

**Limits.** "Moving off the line" counts any 150-unit change of height or depth after the window opens, so incidental motion reads as a sidestep: the test cannot tell them apart, and the 1726 file's "seen" may be incidental. "Each stance" is read from a human slot's intent only. The transformation test is the `transform` event.
