# Wreck Toss: World's query for a liftable wreck (parked; GD 23d section 8 item 20)

World and Environment, 2026-10-25. `wreck-toss.diff` (sha1 a0ffbed95c0f, 8 files) is a git-apply diff, applied on the EP's gate tree (main plus windows 9 to 12 and the host diff, `wc198`). Design and numbers: `../../wreck-toss.md`. **Nothing in the sim calls it** until Encounter does: no golden moves, no hash line, no Simulation line.

- New: `sim/world/wrecks.gd` (`WorldWrecks`: `pick`, `within`, `burst`, `mass`, `lift`), `data/biomes/wrecks.json`, `sim/world/tools/wrecks_check.gd` (16 checks), `tools/schemas/biomes-wrecks.schema.json` (Tools', granted), a map rule and three invalid cases (`tools/schemas/map.json`, `tools/fixtures/cases.json`).
- Encounter calls `WorldWrecks.pick(S, x, y, z, maxMass)` on the pick-up press (`{}` or `{id, mass, x, y, z, w, h, d, dist}`), and `WorldWrecks.burst(S, id, landX, landY, tier, thrower)` when the hurled wreck lands.
- Proof (scratch export of the gate tree plus this and the campaign diff): all 42 World checks, lint, validate and its self-test (9068/9068), run-all 5 of 5 (golden unchanged), the 12-match gen 2 soak, the render gates (cull and outline rc=2: "needs a window", the same on main).
