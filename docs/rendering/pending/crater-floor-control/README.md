# The crater floor's tone off: a scratch switch for VFX's flash control (never lands)

Rendering, 2026-11-14, at the EP's word. VFX suspects the worst second of the clash clip: a blast opens a bright orange-gold crater floor over about a third of a pane in 3 ticks (ticks 1074 to 1077, decaying over 35). `crater_floor_off.scratch.patch` (sha1 99cbbdf6, one line of `render/shaders/terrain.gdshaderinc`, applies on main 4f06e7a3) is for a scratch build only.

## What it does

With Art's crater look on (the default after `look-recut/`), a crater's floor takes the biome's warm tone (`biome_tone(..., 8)`) in flat stripes. That's the orange-gold. The patch skips that branch, so the floor takes the inner wall's tone instead: the same earth by facing, darker. Nothing else changes: the walls, the lip, the rubble and the bowl's shape and opening are as shipped.

## How to use it

Apply it to a scratch tree with the GW1a look stack (Camera, A-CODE-03, `look-recut/`), export, and run the clip against the same stack without it. If the reading drops, the fix is mine with the look gate: the floor's tone, and how fast it comes up. The look doesn't change until then.

## Why the tone alone may not be the whole of it

The floor appears as the bowl opens (`RenderLook.TILE_BOWL_OPEN`, a quarter second) and as a fresh dig fades in (`v_new`). Three ticks may be the sim's dig itself rather than the opening. If the control shows the tone isn't the cause, those come next.
