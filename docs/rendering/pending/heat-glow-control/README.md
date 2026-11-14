# The ground's heat glow off: a scratch switch for VFX's next flash control (never lands)

Rendering, 2026-11-14, at the EP's word. VFX's clash controls (`docs/vfx/runs/e7d544ea/clash-controls-and-signature.txt`) found that the crater floor's warm tone isn't the cause (`crater-floor-control/` changed nothing), and VFX's blast pieces add little. The orange floor is still in frame 1081 with both off. By code, the suspect is the ground's heat glow.

`heat_glow_off.scratch.patch` (sha1 358fd474, one line of `render/shaders/terrain.gdshaderinc`) applies on main 4f06e7a3, on the GW1a look stack (`look-recut/`) and on `calm-tones/`. It's for a scratch build only.

## What it does

The ground's heat glow is the colour a fresh crater and a beam's groove take while hot (`v_heat`, from ImpactFx's heat row through the ground field). It's mixed in two terms, a tint toward `heat_lo`/`heat_hi`, and an added glow past heat 1, both scaled by `heat_gain`. Under reduced flashing `heat_gain` is `RenderLook.HEAT_CALM`.

The patch sets the shader's heat to 0, so both terms vanish, on the strip ground and the tile ground alike. Only this include draws the glow; `tile_vertex.gdshaderinc` only passes `v_heat` on. Everything else is as shipped: the crater's tones, the scar, the rubble, and the heat row itself, which VFX's own effects may read.

## How to use it

Apply it to a scratch tree with the GW1a look stack, export, and run the clip against the same stack without it. If the reading drops, the fix (the glow's strength and rise under reduced, or `HEAT_CALM`) is mine, with the look gate.
