# Netcode run, 2026-11-20: desync-marks (CD-22)

The tree was a scratch `git archive` of HEAD dbe17b79 (sim, data, net, docs/net, project.godot), with `docs/net/pending/gw1a-pins/gw1a-pins.patch`, then `docs/net/pending/desync-marks/desync-marks.patch`. The class cache came from a headless import. At most two Godot processes; no socket was opened and no `enet_check` ran. HEAD moved to 3bd3bd92 with no change to sim, data or net. The profile path is written `<user>`.

| File | What it is |
| :--- | :--- |
| `gates.txt`, `checks/*.txt` | 6 lines through `node tools/gate.mjs`, all exit 0 with 0 SCRIPT ERROR lines: `desync_check` (default setup, lan and p120; `--setup=lan`, seeds 1 and 2) and each one's control; `rollback_check` and its control |

What they read:
- **The new injection** (`checks/a01_desync_check.txt`, `a02`): `building_marks` is detected in every run. Both peers report a desync at the first checkpoint after it (240, agreed to 180), and the field walk's first field is `S.bMarks[0]` (1 against 0). desync passes 16 and 32 runs, 0 failures.
- **The control** (`checks/b01_desync_check.txt`, `b02`): with `NetDesync.marksBlind` (the digest without marks, as before), every marks-only divergence passes the digest, and the check reports it as missed, so each counts as caught: 7 and 14 breaks caught, 0 missed.
- **`rollback_check`** and its control pass unchanged: the digest is the same in a match with no marks.
