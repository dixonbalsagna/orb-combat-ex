# Netcode run, 2026-11-08: review of Simulation's power-dash grant to net/desync.gd, with the dash on in NetLan's setups (CD-22)

A scratch tree of HEAD **c7b0414b** (`git archive` of sim, data, net, docs/net and project.godot; class cache from an import). Applied:
- `docs/architecture/pending/power-dash/power-dash.patch` (sha1 fbbba074…);
- `grant-netcode-dash.patch` (sha1 46980ee2f967…);
- `docs/net/pending/lan-save/lan-save.patch` (sha1 db4afbd3ccca), which puts `"dash": true` beside `"power": true` and `"travel": 1.5` in NetLan's three setups.

Every line went through `node tools/gate.mjs`. No `enet_check`. The profile path is written `<user>`.

| File | Line | Result |
| :--- | :--- | :--- |
| `a01_lan_check.txt`, `b01_lan_check.txt` | `lan_check.gd -- --ticks=1200`, and with `--negative-control` | 0 failed, no SCRIPT ERROR. NetLan's SETUP, SETUP2 and SETUP2X start both PCs with the model and the dash on (`S.dashOn`) and travel 1.50, in step |
| `a02`, `b02` | `desync_check.gd -- --setup=lan --seeds=1,2` (NetLan.SETUP, the dash on), and its control | 36 checkpoints matched; control 10 caught |
| `a03`, `b03` | `rollback_check.gd -- --setup=lan`, and its control | 1,800 comparisons, 0 failures; control 4 caught |
| `a04`, `b04` | `rollback_check.gd -- --setup=together --near=150 --seeds=1,2` (NetLan.SETUP2X), and its control | 7,200 comparisons, 0 failures; control 4 caught |
| `a05`, `b05` | `desync_check.gd -- --setup=together`, and its control | 36 matched; control 10 caught |

Reading: the grant appends `1.0` to the checkpoint digest when `S.dashOn`, inside `S.powerOn`, exactly as power-dash's `hash.gd` does. Approved.
