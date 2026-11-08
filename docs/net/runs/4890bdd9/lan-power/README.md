# Netcode run, 2026-11-08: the LAN round with the energy model on (lan-power) (CD-22)

A scratch tree of **4890bdd9** (`git archive` of sim, data, net, docs/net and project.godot; its class cache from an import of that tree) with `docs/net/pending/lan-power/lan-power.patch` (sha1 c57e3867e3e8) applied. No socket opened; no `enet_check`.

| File | What it is |
| :--- | :--- |
| `gates.txt` | One line per run: exit code, the error-line count of its stderr ("resources still in use at exit" is one; lan_check's negative controls add their bad slot's) and its verdict. **All pass.** `a07` failed once, before the `lan` setup's fighter injection became a whole unit: an ulp of x heals on the planet, so that injection tested nothing. It was re-run as `c01` and `d01` |
| `check-lines.txt` | Which file is which run: `tag|script|arguments` |
| `checks/*.txt` | Each run's whole stdout |

What it shows:
- **`lan_check`** (`a01`): NetLan's own three setups, SETUP, SETUP2 and SETUP2X, start both PCs with the energy model on and travel 1.50, and 300 ticks stay in step on each. Every earlier row (the view, CD-10, the tuning) still passes, 0 failed.
- **Its control** (`b01`): a LAN setup without its power word is caught with the model off (travel 2.00), and every other control is caught as before.
- **`rollback_check`**, 0 failures in each:
  - `--setup=power`: 1,800 comparisons;
  - `--setup=lan` (NetLan.SETUP exactly): 1,800;
  - `--setup=fights2` (NetLan.SETUP2, now with the model on): 1,800;
  - `--setup=together --near=150`, seeds 1 and 2 (NetLan.SETUP2X): 7,200.
  - Each control passes.
- **`desync_check`**, each control passes:
  - default: 18 checkpoints;
  - `--setup=lan`: 36 checkpoints, the whole-unit fighter injection detected on both seeds;
  - `--setup=together`: 36.
- **`two_pc_check`**: the self-test (default and together) and its control pass.
