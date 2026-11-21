# Parked: a replay of the default world names its planet (the companion to World's a-world-01)

Simulation, 2026-11-14, sprint A1. **It applies after B1's `../replay-build/` and World's `globe-step2` and `a-world-01`** (`docs/world/pending/`), and lands with a-world-01's one line in GW1b. As shipped (`world.json` in arena mode) it's a no-op: **the golden is byte-identical.**

## The gap it closes

World's line in `SimCore.beginMatch` plays the data's default world for a setup that names no planet. Once that default is a planet:
- the recorder stored the setup it was given (no planet), and the header's data hash covered neither the planet's data nor `world.json`. Change either, and an old replay plays a different world and fails mid-match instead of being refused;
- the LAN handshake compares the same hash, so two PCs with different planet data would pass it.

## The fix

- `SimReplay.header` stores the setup with the default applied (`WorldDefault.apply(setup, seed, true)`, exactly as `beginMatch` applies it). So a replay names its planet and plays the same world whatever `world.json` later says.
- `SimReplay.dataHash` applies the same default (the fixed planet, which never draws). So a setup with no planet key folds the planet's data.
- **Parity's new row** ("a replay of the default world names its planet"), with World's mode switched to "planet" in memory:
  - a 30-tick match whose setup names no planet records a header that names the planet;
  - its data hash is the planet's, not the arena's;
  - it plays back after the mode is put back to the arena.
  - In arena mode the header and the hash are as given.

## Apply

**GW1b step 3:** on main (b0e20f9a, with replay-build landed in B1), after World's `a-world-01.diff` and `grant-simulation-sim.patch` (steps 1 and 2). Checked on 2026-11-20: it applies there, without globe-step2. `git -c core.autocrlf=false apply replay-world.patch`.

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `replay-world.patch` | `sim/core/replay.gd`, `sim/core/tools/parity.gd` | 9e80651d10e2857f30c6329c1d0f879e85a57877 | 905f585b30e0 |

## Proof

On 8ad6286a with B1 and World's two parks applied (records in `docs/sim/runs/8ad6286a/replay-world/`):
- **Golden byte-identical** (arena mode as shipped). Parity through `gate.mjs`: exit 0, no SCRIPT ERROR lines, the new row ok.
- World's `WORLDDEFAULT` check: 0 failed. `replay_xproc` and `lan_check` (the LAN save's header): pass.
- Rendering's 15: all pass. Lint, ratchet 365.
- Without this patch the row's first test fails by construction: the header stores the caller's setup, which names no planet.
