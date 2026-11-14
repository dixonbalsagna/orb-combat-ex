# Netcode run, 2026-11-14: lan-stamp, a LAN save names its build (A-NET-05) (CD-22)

Two trees. No socket was opened, no firewall file was run, and no `enet_check` ran. HEAD moved from fcd6706c to 97df40b8 with no change to sim, data, net or `stack-preview.mjs`. The profile path is written `<user>`.
- **The checks:** a scratch `git archive` of HEAD fcd6706c (sim, data, net, docs/net, project.godot), with Simulation's `replay-build.patch` and `grant-netcode-build.patch`, then `docs/net/pending/lan-stamp/lan-stamp.patch`. The class cache came from a headless import.
- **The kit:** Tools' stack tree of HEAD 681aa09a (`stack-preview.mjs` tree-only, which now writes the page stamp), with `replay-build.patch` and this park's net/.

| File | What it is |
| :--- | :--- |
| `gates.txt`, `checks/*.txt` | 6 lines through `node tools/gate.mjs`, all exit 0 with 0 SCRIPT ERROR lines: `lan_check --ticks=1200` and its control, `word_check` (623 checks) and its control, `desync_check` and its control |
| `kit-and-verify.txt` | The kit without `--build`, two `--lan-loop` rows that save at tick 600, the stamp read back from the exe, the folder's `tree/` and both saved files, and `blackbox-verify` of the files |

What it shows:
- **`lan_check`'s A-NET-05 rows** (`checks/a01_lan_check.txt`), on a stamped build (the kit's stamp standing in for `build_info.json`):
  - both PCs' files carry the stamp as `build` and its id as the replay's `build`;
  - the file names keep the commit's first 8 (`lan-6a30b4c9-main-...`, `lan-6a30b4c9-old-...`);
  - both files play back.
- **A foreign LAN save,** written to disk with another build's id and loaded back:
  - `SimReplay.play` refuses it as `build` before its first tick, with both ids (`6eec6a75-62e1fea3` against `6a30b4c9-6627cb9d`), as a solo replay is;
  - `SimReplay.refusal` agrees;
  - the desync report's re-run (`NetDesync.replayState`) refuses it too;
  - a save with no stamp is refused by the stamped build.
- **The control** (`checks/b01_lan_check.txt`): with `SimReplay.blindBuild` (the build check left out), the same foreign file plays to its last tick (582 of 582). So the refusal is the build id's alone.
- **The kit, end to end:**
  - The page stamp `{"commit":"681aa09","date":"2026-11-14","stack":1,"id":"681aa09a-a156d7d7"}` became `{..., "lan":true, "built":"2026-11-14T08:40:43.839Z", "id":"681aa09a-a156d7d7"}` in the exe and in the folder's `tree/`, byte for byte the same.
  - `tree/` holds the exported sim, data, net, project and class cache, read-only.
  - Both saved files name `681aa09a`, with the stamp as `build` and the id in the replay.
  - `blackbox-verify` gives BLACKBOX OK on the folder's `tree/` for both. On a copy of `tree/` whose id is `681aa09a-00000000` it gives `reason=build firstBadTick=-1`.
