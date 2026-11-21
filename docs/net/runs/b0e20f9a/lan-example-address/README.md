# Netcode run, 2026-11-21: lan-example-address (CD-22)

The tree was a scratch `git archive` of HEAD b0e20f9a (sim, data, net, docs/net, project.godot) with `docs/net/pending/lan-example-address/lan-example-address.patch`. The class cache came from a headless import. No socket was opened and no `enet_check` ran. `lan_check.gd` is unchanged on cb8d7934. The profile path is written `<user>`.

| File | What it is |
| :--- | :--- |
| `gates.txt`, `checks/*.txt` | `lan_check --ticks=1200` and its `--negative-control` through `node tools/gate.mjs`: both exit 0 with 0 SCRIPT ERROR lines, 0 checks failed |

The address rows pass on the example values: the /24 of `192.168.1.20` is `192.168.1.`, and the filter lets in only that /24 (not `192.168.2.7`, not `192.168.11.7`, not `203.0.113.5`). `lan_check` prints a row only when it fails, and `checks/a01_lan_check.txt` ends with 0 failed.
