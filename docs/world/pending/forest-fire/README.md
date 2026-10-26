# Fires in the forests (parked, window 18; behind `data/biomes/fire.json` `enabled`, off)

World and Environment, 2026-10-26. `forest-fire.diff` (sha1 791c8c0ac975, 12 files) is a git-apply diff on main (00607309). Design, the cue for Rendering and VFX, numbers: `../../forest-fire.md`. **Off by default:** the trees, the golden and every replay are as they were; with it on, nothing runs when no tree burns. No Simulation line, no new event, no Rendering file.

- New: `sim/world/fire.gd` (`WorldFire`), `data/biomes/fire.json`, `sim/world/tools/fire_check.gd` (14 checks), Tools' `biomes-fire.schema.json` (granted), a map rule and three invalid cases.
- Edited (World's): `structures.gd` (`damageArea` lights the trees just beyond the felled ring), `water.gd` (`step` runs the burning), `contact.gd` (the data hash carries fire.json while on), `gen2_soak.gd` (`--fire`).
- Proof (scratch export of main plus this): all 45 World tools, lint, validate and the Tools self-test (9151/9151), run-all 5 of 5 with the golden unchanged, and the 12-match gen 2 soak with B off, with B on and with the fires on, all reproducible.
