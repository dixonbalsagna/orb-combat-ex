# Netcode run, 2026-11-08: the saved LAN match and "report this" (lan-save) (CD-22)

On a scratch tree of HEAD **9dfea2a3** (`git archive` of sim, data, net, docs/net and project.godot; class cache from an import). Since then, HEAD c7b0414b changes nothing in sim, data, net or `render/core/main.gd`. The tree had `docs/net/pending/lan-save/lan-save.patch` applied, as it stood before the `"dash"` word was added; the dash is gated in `../../c7b0414b/power-dash/`. No socket was opened; no `enet_check`. The profile path is written `<user>`.

| File | What it is |
| :--- | :--- |
| `gates.txt`, `checks/*.txt` | 14 lines through `node tools/gate.mjs`, all exit 0 with 0 SCRIPT ERROR lines: `lan_check` and its control, `desync_check` default and together, `rollback_check --takeover=150` and `--drop=150`, `two_pc_check --self-test --setup=together`, `transport_check`, each with its negative control |
| `export-rows-and-verify.txt` | The LAN kit with an export, on a full stack tree of HEAD with this patch's net/. The 9 `--lan-loop` rows pass. Three more rows save at tick 1500 (`--lan-save`, `--lan-save-at`). The 1v1 host row also saved by itself at "The match is over" and on the end card's pause. Every saved file through Tools' `blackbox-verify.mjs` on the kit's tree: 5 of 5 BLACKBOX OK, 1,497 to 11,493 ticks. This run used the file name before the commit was added to it |
| `bpop-7200.txt`, `zz_bpop_probe.gd.txt` | QA's rollback-pop hypothesis, a first look before the EP set it aside for tonight. On p120, with the second PC hitching: 2,175 rollbacks, 7 buildings fell, and the drawn state never showed a building standing again or its hp going up. On lan: 0 rollbacks, 9 fell, 0 flips. A small sample; the longer run was stopped at the EP's pace rule |

What `lan_check`'s new rows read (`checks/a01_lan_check.txt`, `checks/b01_lan_check.txt`):
- **Both PCs' saved files play back** through `SimReplay.play` to every checkpoint, and the final hash where present: 1v1 lan (19 checkpoints, finals 2), 1v1 p120 (19), 2v2 together p120 (19), and together with the second PC gone (18; its seat a toggle on slot 2).
- The two PCs saved the same inputs and toggles.
- The joiner's file, which holds fight 1, plays back too, so the checkpoint hash doesn't depend on which fight a PC shows.
- **Negative controls:**
  - one input made another real one gives "checkpoint" on both files;
  - the gone seat's toggle on the session's index (the old mapping) gives "checkpoint".
