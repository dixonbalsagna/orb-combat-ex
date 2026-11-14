# Netcode run, 2026-11-14: lan-hash, the checkpoint hashes leave the frame (CD-22)

The tree was a scratch `git archive` of HEAD 29a153f5 (sim, data, net, docs/net, project.godot), with Simulation's `replay-build.patch` and `grant-netcode-build.patch`, `docs/net/pending/lan-stamp/lan-stamp.patch`, then `docs/net/pending/lan-hash/lan-hash.patch`. The class cache came from a headless import. HEAD moved to 611c1c2b with no change to sim, data or net. No socket was opened and no `enet_check` ran. The profile path is written `<user>`.

| File | What it is |
| :--- | :--- |
| `gates.txt`, `checks/*.txt` | 5 lines through `node tools/gate.mjs`, all exit 0 with 0 SCRIPT ERROR lines: `lan_check --ticks=1200` and its control, `rollback_check --ai` (lan, p120, far), `desync_check`, `transport_check` |

What `lan_check`'s new rows read (`checks/a01_lan_check.txt`):
- **1v1 p120:** the old path ran SimHash in the frame 43 times for 19 checkpoints (both PCs: 38 would be one each, so 5 were rollback re-runs), 28.7 ms each on this machine. The fix ran 0 in the frame, and both PCs' saved replays are byte for byte the old path's.
- **2v2 together p120:** the same counts, 52.5 ms each (two fights hashed), 0 with the fix, and the replays the same.
- **The control** (`checks/b01_lan_check.txt`): with the hash taken from the present state when a checkpoint becomes final, the saved replays differ from the old path's (caught).
- The machine was shared, so the milliseconds are indicative, not a measurement. They show the order of the cost; the counts and the byte-for-byte result don't depend on the load.
- The rest of `lan_check` passes: saved matches play back, the stamp rows, CD-10, the setups.
