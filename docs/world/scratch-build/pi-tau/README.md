# World's PI and TAU to SimMathx.PI and SimMathx.TAU (2026-10-23): parked, not applied

Tools' determinism lint (`node tools/lint-determinism.mjs`) flagged 19 bare `PI` uses in World's files; this swaps each for `SimMathx.PI` (Simulation's constant, from its bits; a parity check pins it equal to the engine's, so every value is the same bits). `pi-tau.diff` (4 files, 19 lines): `sim/world/contact.gd` (1), `planet.gd` (10), `ringpick.gd` (7), `terrain.gd` (1). `mk_pi.py` makes it. No `TAU` use of World's was flagged.

- **Lint:** World's files read 0 hits. The 5 left (`sim/director/beamplay.gd`, `launch.gd`, `zip.gd`) are Animation's and the director's.
- **Proof** (clean export of HEAD plus the patch): all 15 World checks 0 failed (`planet_check` and `planet_world_check`, the planet vectors, among them), `run-all` 5 of 5 (golden unchanged), Rendering's 15 gates; applies before or after `used-rings.diff`.
