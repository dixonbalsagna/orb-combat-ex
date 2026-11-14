# Netcode run, 2026-11-14: gw1a-pins (CD-22)

Two trees, at most two Godot processes at a time. No socket was opened and no `enet_check` ran. The profile path is written `<user>`.
- **`gw1a/`:** a copy of the EP's GW1a stack (main b869cdad plus every GW1a park, its class cache with it), with `docs/net/pending/gw1a-pins/gw1a-pins.patch` applied after the "before" runs.
- **`main/`:** a scratch `git archive` of main b869cdad (sim, data, net, docs/net, project.godot) with the patch; the class cache came from a headless import.
- Both trees include B1 (f70afd08). HEAD moved to 41768933 with no change to sim, data or net.

| File | What it is |
| :--- | :--- |
| `gates.txt` | Every line through `node tools/gate.mjs`: the EP's three failures reproduced on GW1a before the pins, then 9 lines on GW1a and 9 on main with them. All exit 0 with 0 SCRIPT ERROR lines |
| `gw1a/before-*.txt` | The three failures: lan_check's power control, word_check's off row (1 of 646), desync's fighter_x healed |
| `gw1a/word-probe.txt` | A scratch probe (not in the repo), with every Controls switch off and the stick off. A word handed in never changes the cheap digest. SimHash differs through `act.dirI[610]` (60 against 0) and the unpacked stick fields |
| `gw1a/*.txt`, `main/*.txt` | With the pins, on each tree: `lan_check` and its control, `word_check` and its control, `desync_check` (default, lan and p120; `--setup=lan`, seeds 1 and 2) and their controls, `rollback_check --right-stick` |

What they read:
- **GW1a:** word_check 646 of 646. desync (default) 14 runs and (lan setup) 28 runs, 0 failures. `fighter_hp` is caught at every turn at tick 240, first field `S.fighters[1].hp`. The controls caught 5 of 5 and 10 of 10. lan_check's power control is caught with `"power": false`. rollback with the right stick: 1,800 comparisons, 0 failures.
- **Main:** word_check 623 of 623. desync's default setup keeps the ulp of x, caught to the bit (first field `S.fighters[1].x`, bits ...ab9 against ...ab8). Everything else passes as on GW1a.
