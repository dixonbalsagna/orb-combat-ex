# Parked: a replay of a sized planet plays anywhere (support for World's five planet sizes)

Simulation, 2026-11-14, sprint A1 (the EP's order 5: support World on the five planet sizes). **It applies after World's `globe-step2`, `a-world-01` and `planet-sizes`** (`docs/world/pending/`), because it reads `WorldPlanetSize`. It applies with or without `../replay-build/` (checked both ways). Medium is byte for byte as before: the golden doesn't move.

## The fault, found with World's park applied

`SimReplay.dataHash` takes a gen-3 planet's field hashes (`SimField.dataHash`, `SimField.keyHash`) at whatever size the host's static (`SimConst.PLANET_NC`, a per-match static with World's park) last held.
- A replay of a match on a big or a tiny planet, played by a host that last played medium (a fresh process, or after any medium match), was **refused as "data" before its first tick**.
- The LAN handshake compares the same hash, so two PCs on different static sizes would disagree the same way.
- Before the fix, on World's stack (`size_replay_probe`): big and tiny were both refused, and each header taken again at medium differed.

## The fix

- `dataHash` binds the setup's own size (`WorldPlanetSize.colsOf(setup)`) around the planet's part of the header, and puts the host's static back after. So a header is made, and checked, at the match's own size.
- **The size table is in the header** when a setup names a size (`planetSize`), so a replay recorded before a change to `sizes.json` is refused as "data", not played on a different planet. A setup that names none (medium) hashes exactly as before.
- **Parity's new row:** a replay of 60 ticks on a tiny planet, played by a host bound to medium, plays to its last tick. Its header is the same taken at either static. A changed size table refuses it. The host's static is as it was.

## Apply

After World's three parks (in their order): `git -c core.autocrlf=false apply replay-sizes.patch`.

| Patch | Files | sha1 | sha256 starts |
| :--- | :--- | :--- | :--- |
| `replay-sizes.patch` | `sim/core/replay.gd`, `sim/core/tools/parity.gd` | 400168aefded76ecff477c7fb021ae880432034f | 5e02e088b442 |

## Proof

On bf6c4538 with World's three parks applied (records in `docs/sim/runs/bf6c4538/replay-sizes/`):
- **Golden unchanged.** Parity through `gate.mjs`: exit 0, no SCRIPT ERROR lines, golden check passed, the new row ok.
- World's `SIZES` check: 0 failed. `replay_xproc`: pass.
- `size_replay_probe`: big and tiny play back with the static at medium; each header is the same at either static. Before the fix both failed, which is the negative control.
- Rendering's 15 on the same tree: RGATES_LINE.
