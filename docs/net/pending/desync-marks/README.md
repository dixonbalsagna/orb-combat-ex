# Park: desync-marks, the digest reads building memory (Netcode, 2026-11-20; for GW1b)

The stand-in's memory page (`docs/ep/proposals/memory-under-the-model.md`, "a known gap") found that the cheap desync digest (`net/desync.gd`) reads each building's hp, floors, people, wear and whether it stands, but not its marks. SimHash has them (`sim/core/hash.gd`: a building's marks, only where they aren't 0). Once building memory is on (the wall-hold window, `brunt.json` repeatMarks above 0), two peers that differ only in a mark would agree on the digest until a later send at that building changed something it reads.

| File | Change |
| :--- | :--- |
| `net/desync.gd` | Each building's marks go into the digest as SimHash takes them: the building's index and its marks, only where the marks aren't 0. So a match without marks digests exactly as before. Both the bound path (`S.bMarks`) and the record path. `NetDesync.marksBlind` is a test switch (the control) |
| `net/tools/desync_check.gd` | A new injection, `building_marks` (the first standing building's marks plus 1), which every run must detect. Control (`--negative-control`): with `marksBlind`, the digest as it was, the check must report the same injection as missed |

`desync-marks.patch`, sha1 6fe3d7a82919e123484551cc0c5a779c2e286069. **It applies after `docs/net/pending/gw1a-pins/`** (its context includes gw1a-pins' lines in `desync_check.gd`), checked in turn on HEAD dbe17b79 (and 3bd3bd92, no change to sim, data or net).

**Not in it (the same page names it):** floor damage (`bFdmg`) isn't in the digest either. SimHash reads it per building. Say if it should follow in the same way.

Runs: `docs/net/runs/dbe17b79/desync-marks/` (CD-22).
