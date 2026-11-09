# Netcode run, 2026-11-09: the LAN folder from Monday's build (orb-lan-6eec6a75) (CD-22)

From Tools' kept build `homework/Files/builds/orb-first-play-6eec6a75-62e1fea3` (main 6eec6a75, stack key e52187541626). It holds lan-save, its hook, `"dash": true` in NetLan's setups, and UI's report-this. The game's tree is Tools' own builder's (`stack-preview.mjs` tree-only at 6eec6a75). Its sim, data, net and project.godot equal the kept tree/ byte for byte, and main's net/ equals the build's. Then the LAN kit with an export. No socket was opened and no firewall file was run; no `enet_check`.

| File | What it is |
| :--- | :--- |
| `lan-loop-rows.txt` | The built game run headless with `--lan-loop`: 9 rows (1v1, 2v2 apart, 2v2 together; host and join; lan and p120). All exit 0, no script errors, every check matched. The deepest rollback was 7 |
| `pck-vs-page.txt` | Every packed file against the page's `index.pck`: 1,381 the same, 13 differ, 26 net/tools checks only on the page |

The 13 differences:
- **The kit's changes:**
  - `main.gdc`: the LAN start, `partnerAt`, UI's report hook, the save at window close, the F9 / View + RB fallback;
  - `sim_host.gdc`, `audio_coop.gdc`, `meteor.gdc`, `build_info.json`;
  - `features.json` differs only in `lock_reduce_flashing` true (Legal RL-230); `report_this`, `save_match` and `brink_mark` are on in it, as on the page.
- **The export's own bytes:** 5 scenes, the class and uid caches.
- **No data file differs.**

The folder (129 MB, exe sha1 725aaca59569) holds:
- the eight shortcuts and the two firewall scripts;
- `READ ME FIRST.txt`: RL-253's WHO PLAYS line, checked by the kit, and step 10, what's saved and where;
- `saved\`, with a short note: the game writes `lan-6eec6a75-<main|old>-<time>-<reason>.json` there;
- `Make my report folder.cmd`, from Tools' `lan-report.mjs --write-cmd`;
- `tree/`: read-only, the page's tree byte for byte; a saved match plays back on it.
