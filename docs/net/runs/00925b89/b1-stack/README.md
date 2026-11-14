# Netcode run, 2026-11-14: the B1 stack, replay-build re-cut + lan-stamp + lan-hash (CD-22)

This is Simulation's re-cut of replay-build (`replay-build.patch` 73b9862a, one `SimReplay.header()` for every writer; `grant-netcode-build.patch` 3cd1b355; Tools' grant withdrawn), then `docs/net/pending/lan-stamp/lan-stamp.patch` (5d7f7be0) and `lan-hash.patch` (29146f1a), each applied in turn on HEAD 00925b89. Neither of my patches needed a re-cut. HEAD moved to f1f91f45 with no change to sim, data, net or the replay-build park. No socket was opened and no `enet_check` ran. The profile path is written `<user>`.
- **The checks:** a scratch `git archive` of sim, data, net, docs/net and project.godot with the four patches. The class cache came from a headless import.
- **The kit:** Tools' stack tree of HEAD (page stamp `{"commit":"00925b8","date":"2026-11-14","stack":1,"id":"00925b89-fbb7b255"}`) with the four patches.

| File | What it is |
| :--- | :--- |
| `gates.txt`, `checks/*.txt` | 7 lines through `node tools/gate.mjs`, all exit 0 with 0 SCRIPT ERROR lines: `lan_check` and its control, `word_check` (623) and its control, `rollback_check --ai`, `desync_check`, `transport_check` |
| `kit-and-verify.txt` | The kit with no `--build`, two `--lan-loop` rows that save at tick 600, both saved files, and `blackbox-verify` |

What it shows:
- **The netcode grant:** the LAN save's replay is `SimReplay.header()`'s. It carries the build id (`00925b89-fbb7b255`) with the rest, and `replayState` refuses through `SimReplay.refusal` (`lan_check`'s A-NET-05 rows: a foreign LAN save is refused as `build` before tick 1, by `play`, `refusal` and `replayState`). Godot writes the file with sorted keys, so the header's order can't change a file.
- **lan-stamp and the stand-in's finding 1:** the kit's stamp keeps the page's id, with `lan` and `built` beside it.
  - Both saves verify BLACKBOX OK on the folder's `tree/`.
  - The main PC's save verifies BLACKBOX OK on that tree carrying **the page's own stamp file**. That's the check the kept page and Tools' verifier make, so a LAN save plays there.
  - On a tree with another id it's refused (`reason=build firstBadTick=-1`).
- **lan-hash:** on p120, the old path ran SimHash in the frame 43 times for 19 checkpoints, 27.3 ms each in 1v1 and 55.4 ms in 2v2 together on this shared machine (indicative). The fix ran 0. Both PCs' saved replays are byte for byte the same both ways. Control: a hash of the present state is caught.
- **The other control:** with the build check left out, the foreign LAN save plays to its last tick (582 of 582).
