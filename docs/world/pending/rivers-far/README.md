# Rivers on the far land: World's side (parked, window 17; behind `rivers.json` `enabled`, off)

World and Environment, 2026-10-26. `rivers-far.diff` (sha1 f1b34b3fd4cf, 2 files) is a git-apply diff on main with the rivers diff applied. Render-only data: nothing in the sim reads it, no Rendering file is touched, no golden can move.

- `sim/world/farmap.gd`: `WorldFarMap.rivers`, a layer like `sites` (one byte a texel: 0 none, 1 to 3 the river's size: flow under 4 times the river line, under 16 times, more), made from the planet's flow field when the rivers are on and the planet is gen 2, and `river(qx, qy, qz)` to read it. Each river segment (a river cell's centre to its receiver's) is walked at a third of a texel; a few milliseconds. With the rivers off the layer is all 0.
- `sim/world/tools/rivers_check.gd`: one more check (811 texels marked for 602 river cells on planet 7 at n = 128; every river cell's texel among them; sizes 1 to 3; nothing with the switch off; the same twice).
- Rendering's far land can draw a ribbon (or a darker blue-green strip) on the texels it marks, sized by the class: its call; the layer is the same flow field the ring's rivers come from, so a far river runs into the ring's river where the ring crosses it.
- Proof: rivers_check, farmap_check, far_check and farsites_check pass; determinism lint clean.
