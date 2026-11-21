# Netcode run, 2026-11-20: desync-fdmg (CD-22)

The tree was a scratch `git archive` of HEAD 5ae9ef68 (sim, data, net, docs/net, project.godot), with `docs/net/pending/gw1a-pins/gw1a-pins.patch`, `docs/net/pending/desync-marks/desync-marks.patch`, then `docs/net/pending/desync-fdmg/desync-fdmg.patch`. The class cache came from a headless import. At most two Godot processes; no socket was opened and no `enet_check` ran. HEAD moved to f102ef15 with no change to sim, data or net. The profile path is written `<user>`.

| File | What it is |
| :--- | :--- |
| `gates.txt`, `checks/*.txt` | 6 lines through `node tools/gate.mjs`, all exit 0 with 0 SCRIPT ERROR lines: `desync_check` (default setup, lan and p120; `--setup=lan`, seeds 1 and 2) and each one's control; `rollback_check` and its control |

What they read:
- **The new injection** (`checks/a01_desync_check.txt`, `a02`): `building_fdmg` is detected in every run. Both peers report a desync at the first checkpoint after it (240, agreed to 180), and the field walk finds `S.bFdmg[0]` (an array of the building's floors, 20 or 3, against none). `building_marks` is detected beside it. desync passes 18 and 36 runs, 0 failures.
- **The controls** (`checks/b01_desync_check.txt`, `b02`): with `NetDesync.fdmgBlind` (the digest without floor damage, as before), every floor-only divergence passes the digest and the check reports it as missed. The marks control still passes too: 9 and 18 breaks caught, 0 missed.
- **`rollback_check`** and its control pass unchanged: the digest is the same in a match with no floor damage or marks.
