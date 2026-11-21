# Park: desync-fdmg, the digest reads floor damage (Netcode, 2026-11-20; for GW1b)

The second half of the stand-in's "known gap" (`docs/ep/proposals/memory-under-the-model.md`). The cheap desync digest (`net/desync.gd`) didn't read a building's floor damage; SimHash does (one value a floor, allocated on the building's first local hit). Two peers that differed only in a floor's damage would have agreed on the digest until the building's hp, floors, people or wear moved.

| File | Change |
| :--- | :--- |
| `net/desync.gd` | `NetDesync._fdmg`: each building's floor damage goes into the digest as SimHash takes it: the index, the array's size and its values, only where it isn't empty. So a match with no floor damage digests exactly as before. Both the bound path (`S.bFdmg`) and the record path. `NetDesync.fdmgBlind` is a test switch (the control) |
| `net/tools/desync_check.gd` | A new injection, `building_fdmg`: one more point on the first standing building's lowest floor. It's written as the world writes floors (`sim/world/blast.gd _floors`): a new array, one value a floor, because a snapshot shares the old one. Every run must detect it. Control (`--negative-control`): with `fdmgBlind`, the digest as it was, the check must report the same injection as missed |

`desync-fdmg.patch`, sha1 12bf1ab81ea3da346cfceedfa481b417c857deed. **It applies after `gw1a-pins` and `desync-marks`** (its lines sit next to desync-marks'), checked in turn on HEAD 5ae9ef68 (and f102ef15, no change to sim, data or net).

Runs: `docs/net/runs/5ae9ef68/desync-fdmg/` (CD-22).
