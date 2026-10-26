# Window 12: Research's B plates behind `land.json` `b.enabled` (parked, off)

World and Environment, 2026-10-23. `gen2-w12.diff` (sha1 905383d912af, 16 files) is a git-apply diff. Applies after window 11 (order 2, 2b, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12). Design, fidelity and cost: `../../plates-b.md`.

**Off by default.** With `b.enabled` false, `WorldPlanet.ground` takes the path it took (one extra `P.gen >= 2 and WorldLand.plateB()` test) and `plateb.gd` never runs, so gen 1 and the parked gen 2 are bit for bit.

- New: `sim/world/plateb.gd` (WorldPlateB: Research's `makePlates` and `plateGround`, round 2), `data/biomes/plates-b.json` (Research's `PB`, made by `gen_b_params.mjs` from `plates.mjs`), `sim/world/tools/b_check.gd` with `b_vectors.json` (made by `b_vectors.mjs` from Research's own file), `tools/schemas/biomes-plates-b.schema.json` (Tools', granted).
- Edited: `sim/world/land.gd` (the switch, `plateB()`, `setB()` for tools, the data hash carries plates-b only while on), `sim/world/planet.gd` (`Planet.platesB`; `ground()` hands a gen 2 planet to B), `data/biomes/land.json` (`b.enabled`), `planet_map.gd` and `gen2_soak.gd` (a `--b` flag), Tools': `biomes-land.schema.json`, `map.json`, `cases.json` (three invalid cases).
- The makers (`mk_w12.py`, `mk_w12_map.py`) are for reference; the diff is the deliverable.
- Proof (scratch export of main plus 2 to 12): every World check (39) passes, `b_check` 0 failed, the 12-match gen 2 soak with B on is clean and reproducible (turns included), determinism lint, validator and its self-test pass.
