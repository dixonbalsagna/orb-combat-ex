# Park: lan-slip (Netcode, 2026-11-09)

`"slip": true` in NetLan's three setups (`SETUP`, `SETUP2`, `SETUP2X`), so a LAN match plays Simulation's slip brake (`docs/architecture/pending/dash-slip/`) the way the page does once it's on. The EP's brief: apply only if Controls' probe says slip and `dashHandover` are both on.

| File | Change |
| :--- | :--- |
| `net/lan.gd` | `"slip": true` after `"dash": true` in the three setups |
| `net/tools/lan_check.gd` | The setup row also reads `S.slipOn == true` (with the model and the dash). New control: `SETUP` with `"slip": false` must be caught |
| `docs/net/lan-v1.md` | A paragraph on the slip and on `dashHandover` |

`lan-slip.patch`, sha1 06422cde9f7433ed6d927d78ed6181737424efdd. Apply it after the dash-slip stack, on HEAD 592a807b or 578e819e (no sim, data or net change between them):

`git -c core.autocrlf=false apply dash-slip.patch grant-netcode-slip.patch grant-tools-slip.patch lan-slip.patch`

It only touches files the grants leave alone, so it also applies on HEAD by itself. Don't land it without dash-slip, though: the `lan_check` setup row needs `S.slipOn`, and without it the row fails.

**`dashHandover`: nothing to add.** It isn't a setup word. It is `switches.dashHandover` in `data/input/timing.json`. Each PC's pad layout (`sim/input/layout.gd`) reads it when it turns the pad into the intent, and NetLan packs that intent and sends it. The LAN folder is built from the page's own tree (Tools' stack-preview), and every file is checked against the page's package. So the folder gets whatever value the page has, through the same switch. The dash bit that goes over the wire is the result, so two PCs can't desync on it.

Runs: `docs/net/runs/578e819e/lan-slip/` (CD-22).
