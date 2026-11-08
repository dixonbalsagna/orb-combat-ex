# Netcode run, 2026-11-08: the LAN folder from build 2 (orb-lan-091dfac9) (CD-22)

From Tools' kept build `homework/Files/builds/orb-first-play-091dfac9-a34be195` (main 091dfac9, stack key 6cfbc482cfc5; it holds lan-power, lan-words and lan-slot). The game's tree is Tools' own builder's (`stack-preview.mjs` tree-only at 091dfac9). Its sim, data, net and project.godot equal the kept tree/ byte for byte, and main's net/ equals the build's. Then the LAN kit with an export. No socket was opened and no firewall file was run; no `enet_check`.

| File | What it is |
| :--- | :--- |
| `lan-loop-rows.txt` | The built game run headless with `--lan-loop` (the other PC simulated in-process): 9 rows (1v1, 2v2 apart, 2v2 together; host and join; lan and p120). All exit 0, no script errors, every check matched. The deepest rollback was 9, within the LAN lead of 8 and a save |
| `pck-vs-page.txt` | Every packed file against the page's `index.pck`: 1,369 the same, 13 differ, 26 net/tools checks only on the page |

The 13 differences:
- **The kit's changes:** `main.gdc`, `sim_host.gdc`, `audio_coop.gdc` (Audio's brink call, on for 2v2 together only), `meteor.gdc` and `build_info.json`. `features.json` differs only in `lock_reduce_flashing` true (Legal RL-230); `brink_mark` and `outside_words` are on in it, as on the page.
- **The export's own bytes:** 5 scenes, the class and uid caches.
- **No data file differs.** The energy model (travel 1.5) comes from `net/lan.gd`, and the computers play ai.json's own level, Medium.

The folder (129 MB, exe sha1 711b13592f6d) holds the eight shortcuts, the two firewall scripts, `READ ME FIRST.txt` (RL-253's WHO PLAYS line, checked by the kit, and lan-words' lines) and `tree/` (read-only, the page's tree byte for byte).
