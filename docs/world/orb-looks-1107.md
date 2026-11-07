# Orb's two looks from the morning play (World, 2026-11-07)

Build a8bc66e2 (page e80b8e3d), planet 7, black box `orb-first-play-20261107-1229`. Method: the match replayed on the build's own tree (`tree/` of the kept build, scratch copy, headless probe) and through Tools' clip launcher. No screenshot of Orb's is copied here.

## 1. Feet in the ground at the start: FOUND, Rendering's

- The opening is a first-meteor landing: two impact craters, one under each fighter (record 0 at tick ~36, record 1 at tick ~110; radius 196, depth 43.1, rim 14.4). Both are **live store records** (gen 3), so the sim's ground under each fighter is dug at once: F0 stands at 1217.5 (base 1264.0), F1 at 1260.8 (base 1312.3). He is 43 units (more than half a body, a body is 75) below the undug ground.
- **The match clock `S.T` is 0.00 for the whole opening** (checked every 20 ticks to 260). Both records are stamped `t = 0.00`.
- The tile ground opens a bowl by `o = clamp((cb_now - t) / TILE_BOWL_OPEN)` with `cb_now = S.T` (`tile_ground.gd` `_bowls`, `mat.cb_now`; `tile_read.gdshaderinc` `tile_bowls`). With `S.T` held at 0, `o` is 0 for the whole opening: **the bowl is never drawn while the fighters stand in it.** The body offset (`RenderTileField.keep_off`: drawn tile ground less `_sim_ground`) does not see store craters (`WorldField.applyRecords` is the places' records only), so nothing lifts him either.
- The same cause shows for 0.25 s after any crater under a fighter once the clock runs: the sim digs at once, the drawn bowl opens over `TILE_BOWL_OPEN`.
- Replay stills at ticks 150 to 300 at 960x540: flat drawn ground under both fighters, legs cut by it.
- **Fix, Rendering's:** the opening of a bowl must run on a clock that moves in the opening. Cleanest: in `_bowls`, stamp each record the first frame it is seen with the render's own clock (a record already in the store at the first frame counts as open) and set `cb_now` from that clock. No sim change, no hash change. Alternative on World's side (not recommended): stamp a record dug while the clock is held as `t = S.T - TILE_BOWL_OPEN`; that moves the store hash for every match with a held-clock crater and drops the opening for the landing.

## 2. The "ripples" crawling left: NOT PROVEN; where it is not, and the likeliest place

Not the sim:
- Ground height is a function of the planet point (`SimField.heightOf`, `WorldStore.heightDelta`): it cannot slide.
- Rubble is not it: at tick 8500 `S.rubble` holds 10 columns (sum 225 units) far from the fight.
- The match has 15 swings (tick 420, 969, 1727, 1889, 2030, 2788, 3319, 3799, 4079, 4970, 6017, 7284, 7735, 7784, 8246) and the frame's `x0` moves each time (e.g. 74084 to 68897; 69054 to 70838 to 74728). So the whole world turns under the pair; a feature fixed on the planet crosses the screen. The big special crater (record at t=48, x=74576, radius 2142, depth 556, rim 185) sits near the fight from tick ~3500, so a pair moving toward it makes it "crawl left" on screen. That part is camera and swing, correct.

What reads as ripples (a suspect, not shown on a still): the crater look's wall shading (`terrain.gdshaderinc`, `crater_look`) picks one of three tones from `floor(atan(v_dg.y, v_dg.x) / 45 degrees)`, the wall's facing in eight flat sides, from the vertex's own slope `v_dg`. On a wall as big as 2142 units drawn on a coarse level (64 to 512 unit cells), `v_dg` changes direction from triangle to triangle: a lozenge lattice. The lattice is tied to the mesh's vertices, and the mesh morphs toward its parent lattice with the camera's distance (`tile_node`, `mk`), so the facets slide as the camera moves. Rendering to measure: a still of the big crater at tick ~4300 with `--nearmode` / a finer level word, and with `craterlook` off. My replay stills at ticks 4200 to 4560 did not frame the patch (the clip camera differs from Orb's), so there is no picture of the patch from me.

World's side: nothing to park for either look. The one World-side option for look 1 is above.
