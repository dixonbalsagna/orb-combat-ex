# Park: hash-check-strip (VFX, 2026-11-14): must land AFTER Rendering's globe-default

One line in `render/vfx/tools/hash_check.gd`: `main.strip_ground = true` before the scene enters the tree, as Rendering pins the old strip ground in its own checks (A-RENDER-01's classing run).

**Why:** with Rendering's globe-default applied, VFX's `hash_check` fails on every VFX run from tick 60 (`DIFFERS: first at tick 60`) and the scene prints `SCRIPT ERROR: Out of bounds get index '60'` at `render/core/planet_view.gd:1541` (`_tile_foot_slice`, called from `tile_ground.gd:193`). It fails the same way with and without World's planet patch, so it is the globe ground in the headless scene, not the meteor. With the pin, `hash_check` passes: seeds 12345, 4 and 7 to tick 3,600, six ways, in 259 s on the stack (main 067baa03 + globe-default + crater-look-default + meteor-default).

**Order:** it uses `strip_ground`, which exists only after globe-default (`render/core/main.gd`), so it lands after it; before it, the line is an unknown property and the check stops. The patch is text-clean on today's main.

**What it does not do:** it does not test the globe ground. The scene error on the globe ground is Rendering's to fix (the foot slice's index runs past its array in this scene), and once it is fixed this pin should come out so the VFX hash gate runs on the ground Orb plays. Flagged under NEEDS FROM EP.
