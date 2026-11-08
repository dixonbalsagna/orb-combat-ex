# Netcode run, 2026-11-07: lan-n4 re-cut with Camera's partner rule (CD-22)

Run on a scratch tree of HEAD **ea398601**: `git archive` of sim, data, net, docs/net and project.godot, with `docs/net/pending/lan-n4/lan-n4.patch` applied (sha1 285001cf7bc8). The full gate of the first cut is in `../d41ce393/`. This re-cut changes only the partner rule: `net/lan.gd`, `lan_check`'s partner row, the kit's `partnerAt` line and the docs' wording.

Camera's rule: a PC whose player is out shows his partner's fight 2 sim ticks after the tick on which his fight's KO clock first reads `CamParams.WRECK_AT` (1.8, on the fight's own slowed clock). No extra seconds.

| File | What it is |
| :--- | :--- |
| `gates.txt` | `lan_check --ticks=1200` and its `--negative-control`: both exit 0, 0 failed |
| `checks/v01_lan_check.txt` | `lan_check` (it holds the view rows). With the first player out at tick 100, his fight's KO clock first reads 1.8 at tick 461, and his PC shows his partner's fight from tick 463, on lan and p120. The view rows with a hitching second PC and pauses: 0 frames off its own fight. CD-10's rows unchanged |
| `checks/n01_lan_check.txt` | Its negative control: every control caught, as in the first cut |
