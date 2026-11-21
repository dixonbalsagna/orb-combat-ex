# Netcode run, 2026-11-21: gw1b-planet (CD-22)

| Folder or file | What it is |
| :--- | :--- |
| `gates.txt` | Every line through `node tools/gate.mjs`, in four parts: the two failures on a copy of the EP's GW1b stack s426 before the re-cut; all 45 of my CI lines on the copy with `docs/net/pending/gw1b-planet/gw1b-planet.patch`; the spectator control with the digest blinded to the director integers; the key lines on the arena |
| `gw1b/before-*.txt` | The failures: desync's director healed every time (default setup, the planet), the spectator flip missed on lan and p120 |
| `gw1b/c*.txt`, `d*.txt`, `e*.txt` | The 45 lines with the re-cut: every `res://net/tools` line in s426's ci.yml but `enet_check`. All exit 0, 0 SCRIPT ERROR |
| `gw1b/dirI-blind-x01_spectator_check.txt` | `NetDesync.dirIBlind` set on for one run, then back: the flip is missed again on all three profiles |
| `arena/*.txt` | Main e5306b02 with desync-marks, desync-fdmg and this park (no flip): desync and its control, the spectator control, rollback. All pass |
| `probes/flip-probe.txt` | Straight against flipped on the planet: SimHash differs from tick 310 to 580, the digest is the same at 360, 420, 480 and 540, and the field walk at 360 lists fighter 1's `act.dirI` only |
| `probes/director-probe.txt` | Five director changes after tick 207 on the planet, at 240: the cool-down and `dirI[14]` heal; the stop timer, the exchange count and `dirI[64]` persist, and the digest (with `dirI`) sees each |

Setup:
- **The GW1b copy:** a copy of s426 (its class cache with it), my patch applied by hand. The probes were scratch scripts in the copy only.
- **The arena:** a scratch `git archive` of e5306b02 (sim, data, net, docs/net, project.godot) with the three patches; the class cache came from a headless import.
- **Limits:** at most 3 Godot processes, below normal; no socket opened and no `enet_check`. The profile path is written `<user>`.
