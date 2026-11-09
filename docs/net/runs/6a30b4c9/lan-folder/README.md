# Netcode run, 2026-11-09: the LAN folder from Monday's polish batch (orb-lan-6a30b4c9) (CD-22)

Built from Tools' kept build `homework/Files/builds/orb-first-play-6a30b4c9-6627cb9d` (main 6a30b4c9, stack key 9d499ff0315f). That commit holds lan-slip (`"slip": true` in NetLan's setups), dash-slip and the digest grant.

The game's tree came from Tools' own builder (`stack-preview.mjs` tree-only at 6a30b4c9, the same stack key). Its sim, data, net and project.godot equal the kept tree/ byte for byte, and main's net/ equals the build's. In the page's data `switches.dashHandover` and `dash.slip.enabled` are both true, so both PCs play the page's slip and handover. Then came the LAN kit with an export (build name `6a30b4c9`; saved files are named by its first 8 characters). No socket was opened, no firewall file was run, and no `enet_check` ran.

| File | What it is |
| :--- | :--- |
| `lan-loop-rows.txt` | The built game run headless with `--lan-loop`: 9 rows (1v1, 2v2 apart, 2v2 together; host and join; lan and p120), three at a time. All exit 0, no script errors, every check matched. The deepest rollback was 8 |
| `pck-vs-page.txt` | Every packed file against the page's `index.pck`: 1,385 the same, 13 differ, 26 net/tools checks only on the page |

The 13 differences are the same as Monday's:
- **The kit's changes:**
  - `main.gdc`, `sim_host.gdc`, `audio_coop.gdc`, `meteor.gdc`, `build_info.json`;
  - `features.json` differs only in `lock_reduce_flashing` true (Legal RL-230); `report_this`, `save_match` and `brink_mark` are on, as on the page.
- **The export's own bytes:** 5 scenes, the class and uid caches.
- **No data file differs.**

The folder (126 MB, exe sha1 1e8cc72ae9fa) holds:
- the eight shortcuts and the two firewall scripts;
- `READ ME FIRST.txt`: RL-253's WHO PLAYS line (line 5), checked by the kit;
- `saved\`, with Monday's note;
- `Make my report folder.cmd`, from Tools' `lan-report.mjs --write-cmd` with 674f7a14's words (no hand rewording);
- `tree/`: read-only, Tools' kept tree copied whole (1,259 files, 0 differences).
