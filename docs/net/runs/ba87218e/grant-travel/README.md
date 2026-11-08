# Netcode run, 2026-11-07: review of Simulation's grant to net/desync.gd (power-travel) (CD-22)

A scratch tree of HEAD **ba87218e** (`git archive` of sim, data, net, project.godot) with `docs/architecture/pending/power-travel/power-travel.patch` and `grant-netcode-travel.patch` (sha1 94382305096c, sha256 809a6d8e6733) applied. `lan-n4.patch` (285001cf7bc8) applies together with both (check only): it doesn't touch `net/desync.gd`. No socket opened; no `enet_check`.

| File | What it is |
| :--- | :--- |
| `g01_zz_travel_probe.txt` | The probe (`zz_travel_probe.gd.txt`, a scratch script). With the energy model on, a setup's travel 1.25 against the data's 2.0 gives a different checkpoint digest, and a different SimHash with it. The same match gives the same digest. With the model off, travel changes neither. 0 failed |
| `g02_desync_check.txt`, `g03_desync_check.txt` | `desync_check -- --seeds=1 --ticks=600 --profiles=lan,p120` and its `--negative-control`: pass, 18 checkpoints matched |
| `r01_rollback_check.txt`, `r02_rollback_check.txt` | `rollback_check -- --setup=power --seeds=1 --ticks=300 --profiles=lan,p120,far` and its `--negative-control`: pass, 1,800 comparisons, 0 failures |

Reading: the line puts `S.powerTravel` in the digest beside `S.powerFlat`, under the same `S.powerOn`, as `hash.gd` does in power-travel.patch. A desync report's replay carries the whole setup (`NetDesync.replayOf`), so a "travel" key needs nothing else in `net/`. Approved.
