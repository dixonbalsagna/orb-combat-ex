# Park: world_check pins the arena for GW1b (Audio and Music, 2026-11-21)

On the GW1b stack the default world is the round planet, and `audio/tools/world_check.gd` stages its spots on the hand-made arena's biomes (a desert, plains and forest spot, the fine-biome columns, a soil, a rubble heap, the water cues). The check printed 27 failing rows, not only the five first reported (the desert bed, the +4 dB high-up row, "desert: water (wanted sand)", "plains: water (wanted grass)", "forest: grass (wanted mud)"): every one is the same cause, a spot that reads the planet's ground where the check meant the arena's.

**Fix** (`world-check-arena.patch`, one line, applies to the GW1b stack with `git apply --check`): `WorldPin.arena()` at the top of `_run`, as World's checks do. The check's own planet section (planet 7, named in its set-up) is untouched and passes.

**Not a sound fault:** no sound or data changed; the world set is off in the data and stays off for Alpha. A spot on the planet reads the planet's ground and the set sounds that ground; the check just has to say which world it tests. A planet-staged re-cut of the rows (spots of the right biome on a planet) is a bigger job for after the flip, if wanted.

**Proof** (`docs/audio/runs/gw1b-recut/`): on a copy of the GW1b stack, `world_check` 27 failures before, 0 after (exit 0). On the same copy `moments`, `coop`, `host`, `brawl`, `carry`, `tug`, `tone`, `status`, `web_policy`, `beat`, `babble`, `warm` and `sets` checks all pass. Headless, one Godot process at a time.
