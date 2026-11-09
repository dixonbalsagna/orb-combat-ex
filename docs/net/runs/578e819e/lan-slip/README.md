# Netcode run, 2026-11-09: lan-slip (CD-22)

The tree was a scratch `git archive` of HEAD 592a807b (sim, data, net, docs/net, project.godot), with `dash-slip.patch` and `grant-netcode-slip.patch` applied, then `docs/net/pending/lan-slip/lan-slip.patch`. HEAD 578e819e changes nothing in sim, data or net. The class cache came from a headless import. No socket was opened and no `enet_check` ran. The profile path is written `<user>`.

| File | What it is |
| :--- | :--- |
| `gates.txt`, `checks/*.txt` | 6 lines through `node tools/gate.mjs`, all exit 0 with 0 SCRIPT ERROR lines: `lan_check --ticks=1200` and its control; `desync_check --setup=lan` (seeds 1 and 2) and its control; `rollback_check --setup=lan`; `desync_check --setup=together` |

What the rows read:
- **`lan_check`'s setup row** (`checks/a01_lan_check.txt`): SETUP, SETUP2 and SETUP2X all start with the energy model, the dash and the slip on, travel 1.50, and 300 ticks stay in step.
- **The new control** (`checks/b01_lan_check.txt`): a LAN setup with `"slip": false` is caught (its model, dash and slip read false).
- **`desync_check` and `rollback_check`'s `lan` setup** is NetLan's SETUP, so these play with the slip on, through the digest's new brake fields: 36 checkpoints matched, 1,800 confirmed-tick hash comparisons, 0 failures; the control caught 10 of 10 breaks.
- **`together`** is SETUP2X, also with the slip on: 36 checkpoints matched.
