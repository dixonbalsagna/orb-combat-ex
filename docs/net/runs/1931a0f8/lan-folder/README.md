# Netcode run, 2026-11-08: the LAN folder from build 1 (orb-lan-1931a0f8) (CD-22)

From Tools' kept build `homework/Files/builds/orb-first-play-1931a0f8-7a5a2d2c` (main 1931a0f8, stack key 552fe843e0ab). The game's tree is Tools' own builder's (`stack-preview.mjs` tree-only at 1931a0f8). Its sim, data, net and project.godot equal the kept tree/ byte for byte, and main's net/ equals the build's. Then the LAN kit with an export (`net/tools/lan_kit.mjs`). No socket was opened and no firewall file was run; no `enet_check`.

| File | What it is |
| :--- | :--- |
| `lan-loop-rows.txt` | The built game run headless with `--lan-loop` (the other PC simulated in-process): 9 rows (1v1, 2v2 apart, 2v2 together; host and join; lan and p120). All exit 0, no script errors, every check matched. The view is "his own" fight, and the deepest rollback 7 (within the LAN lead of 8) |
| `pck-vs-page.txt` | Every packed file against the page's `index.pck`: 1,369 the same, 13 differ, 26 net/tools checks only on the page |

The 13 differences:
- **The kit's changes:** `main.gdc` (the LAN start and `partnerAt`), `sim_host.gdc` (the LAN step, the pause, `view()`), `audio_coop.gdc` (on for 2v2 together only), `meteor.gdc` (the page's "loud"), `features.json` (only `lock_reduce_flashing`: true, Legal RL-230) and `build_info.json` ({"commit":"1931a0f8-7a5a2d2c","lan":true}).
- **The export's own bytes:** 5 scenes, the class and uid caches.
- **No data file differs:** the energy model (on in NetLan's setups, travel 1.5) comes from `net/lan.gd`.

The folder (129 MB, exe sha1 517e574ec704) holds the eight shortcuts, the two firewall scripts, `READ ME FIRST.txt` (RL-253's WHO PLAYS line, checked by the kit, and lan-words' lines) and `tree/` (read-only, the page's tree byte for byte).
