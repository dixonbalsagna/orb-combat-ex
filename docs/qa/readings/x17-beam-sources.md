# X-17: beams started by any input other than the right stick or RT + B (QA first reading; rerun 2026-11-20)

**What it measures.** For each beam a human slot starts, what started it: the stick beam (RB and the right stick, thrown on the release), RT + B, or **anything else** (B alone, B with the dodge held, a face-button combination, a stale queued signature). The aim is 0 "other", and it must pass from A2.

**Tool.** `qa/godot/x17_count.gd` (replays saved play files; each "other" is listed with the last 12 ticks of buttons) and, for scripted matches, the source count in `qa/godot/orbs_player.gd`. A stick beam is a `beam_stage` cue within 5 ticks before the charge (the first version used 2 ticks and missed stick beams whose charge follows the stage cue by 3).

**Command.**

```
godot --headless --path <the build's tree> --script res://qa/godot/x17_count.gd -- <play file.json> [<play file.json> ...]
```

**Results** (records `docs/qa/runs/6a30b4c9/x17-first-reading.txt`; each file on its own build's tree, nothing patched):

| Files | Stick | RT + B | **Other** |
| :--- | ---: | ---: | ---: |
| Orb's 1625 and 1646, build 6a30b4c9 | 7 | 1 | **0** |
| Orb's 1714 and 1726, build 1931a0f8 | 8 | 0 | **6** |
| 20 scripted matches (orbs_player, both slots, 6a30b4c9) | 549 | 0 | **0** |

**What it says.** **On the played build (6a30b4c9) the count is 0, in Orb's two files and in the scripted set: it passes.** On the earlier build 1931a0f8 it found 6: ticks 3326 and 8096 of the 1714 file (the two QA had traced: B alone, and B with the dodge held) and four in the 1726 file, all B pressed with the dodge held (ticks 3808, 7246, 11488 and 14987); the bNoBeam switch (commit 6eec6a75) is what closed them. The 1726 file's four were not in the earlier replay report; they match Orb's note that beams were firing without the stick. The aim of 0 is met on 6a30b4c9; the tool is to be run on every candidate.

**Limit.** Only a human slot is counted (the computer's beams are its own). The "RT + B" class reads RT held at the charge, so a B pressed while RT is held counts there; whether that press is allowed is the interim rule's question (the stray-beams park and `bNoBeamKeepRt`), not this count's.
