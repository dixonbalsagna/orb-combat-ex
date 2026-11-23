# Ice no brighter than the beam

Parked by Rendering, 2026-11-01. `ice.diff` stacks on `2026-11-01n-hole-depth-as-drawn/hole.diff`. Only with the tile ground's switch on.

**The fault.** A hard white ribbon along the shore behind the beam struggle, and a huge white hump under the fighters (`docs/tools/img/page-reel-minute/sheet-4.png` and `sheet-5.png`, ticks 3255 to 3585). It's the brightest thing in the shot.

**What it is.** The `ice_sheet` biome's ground. Read at tick 3361 on the reel's stack: hiding the ground mesh removes it, its biome id is 5, and its colour before the glow step is (255, 255, 248). Art's palette is `#ebe8e2`; the world's sunset light clips it. Ruled out by test: foam (each water white painted its own colour, ribbon unchanged), snow (the line is 6,720, the planet's highest land 6,113), VFX. Ticks 3540 to 3585 were not read for biome; the fix brings them down too, so it's the same ground.

**The change.** With tiles on, ground of World's fine ids 5 and 6 (ice sheet, sea ice) above the water is held to `RenderLook.TILE_ICE_CAP`, 0.68, in its brightest channel, after the world's light. Hue, hard edges and Art's palette stay. The ribbon reads (173, 171, 167). 0.68 is Rendering's number; it's one constant if Art wants another.

**Seen:** `docs/rendering/img/lookgate/white-shore-before-after.png`, reel's stack, ticks 3301, 3361, 3421, left before. `white-shore-hump-after.png`, ticks 3526, 3541, 3556, after only. Near water at (700, 520) on tick 3421 reads the same before and after, (61, 136, 197).

**Trap.** The setting lives in `terrain.gdshaderinc`, on purpose. Declared in `tile_read.gdshaderinc`, which the water shares, it made the near water vanish in two runs out of two; moved, the water came back. The reason isn't known.

**Not changed:** the width. That land is ice sheet on the map, so the hump stays as wide. Whether an ice sheet belongs on a shore beside sand and a town is World's question.

**Not checked:**
- The ids 5 and 6 are written in the shader, so a change to World's fine list wouldn't follow.
- Sea ice wasn't seen; only ice sheet came up in this reel.
- Other times of day weren't shot.

**Gates**, with all my diffs on 8ea982c5's render, sim and data: golden byte-identical; tile, lake water, cover water and sweep checks pass; off 13 stills 0 differ. The 20 render gates exit 0, but run without the tile word. Main has moved (111 files under render, sim, data, schemas and project.godot); the chain a to o applies on 77d0f696, apply check only.
