# Biome rendering (Rendering, 2026-10-23)

Orb's priority (2026-10-23): "pour resources into improving our planet generation, biomes, fighter animations". Art's biome look bible is the brief (`docs/art/biomes.md`, `data/art/biomes.json`, `art/concepts/biomes/`): flat faceted colours, lit, mid and shade faces, no gradients; transitions in hard steps. This page covers what the render builds of it, window by window.

## Window 1: the ground in Art's facets

**The palette** (`render/core/biome_look.gd`, `RenderBiomeLook`): a 32 by 12 texture made once from Art's data.
- **A column per biome:** World's fine biomes by id (`data/biomes/climate.json` "fine": 0 ocean to 14 volcanic), then the render's own city (15) and village (16).
- **Each fine biome is Art's entry under its name.** Until Art's data carries every fine name, it falls back to Art's older name (ice, seaice) or to the biome's stored alias (World's fallback).
- **The city and the village** are the render's own colours as the mid face, with Art's `lite` and `dark` for the others.
- **A row per tone:**
  - the ground's lit, mid and shade faces;
  - the rock's;
  - the subsoil's (Art's crater inside: `lite` 0.14, the subsoil, `dark` 0.3);
  - a beam's scar band and its edge;
  - whether the rock carries strata lines (desert, mountains, volcanic, highland).
- **The render's band biomes map onto it** by name (`id_of`): today's five stored biomes, the city and the village. The fine id reaches the band when World's window 2 plumbs it into the match.

**The facets** (`terrain.gdshader`):
- **The tone.** A point of the ground takes its biome's lit, mid or shade tone by its normal against the sun (`FACET_SUN`: upper left, a little toward the viewer). It is lit past `FACET_SLOPE` (0.05) more light than flat ground, shade past it less, and mid on the flat.
  - This is Art's rule along the strip (rising to the right is lit), and a slope in depth takes the light as well, so a hillside facing the camera is not one flat slab.
  - The normal is the ground's own, smooth across the mesh, so a tone's edge follows the ground's shape as a clean contour. A first cut used each triangle's own face, and a fine crater bowl broke into sawteeth.
- **Rock.** It comes in by steepness, in Art's five hard bands from `ROCK_SLOPE.x` (0.45 rise over run) to `.y` (1.25), so the green and the rock meet along the slope's contour, stepped.
  - In a rocky biome (mountains from 900 units, highland from 700) the rock starts at gentler slopes the higher it is, down to `ROCK_HIGH` (0.15) of that at twice the height. A mountain stays green only at its foot, and only where the foot is gentle.
  - A first cut turned all ground above a height to rock: one flat green slab cut by a straight line (the EP's look call).
- **Strata.** Thin dark lines every `STRATA_H` (220) units of height run on rock that carries them (desert, mountains, volcanic, highland), where the rock's bands dominate. They leave out where they would crowd closer than a few pixels.
- **Depth.** The band's value steps by depth in three hard steps (`DEPTH_STEP`: 1.1 at the front to 0.94 at the back), so open flat ground (a desert) still reads near and far. The tones themselves are the light. The far land keeps its own colour and shading until window 3 makes it Art's ladder.
- **Hard edges elsewhere too:**
  - snow on the peaks starts at a height;
  - a crater's rim rubble comes in two steps;
  - the sea floor, the streets and the snow take `TONE_K` for their facets.

**Borders** (`ground_field.gd` `zone_rows`, rows 21 to 23): Art's transition, a zone a third of the 1,200-unit window wide (`BIOME_ZONE` 360 units).
- **Each column in a zone** carries the palette ids of the biomes either side of its nearest border, and where that border lies.
- **The shader steps the colour across the zone in five hard bands,** 10, 30, 50, 70 and 90 percent of the way to the other biome.
- **Cost:** a pass over the borders, well under a millisecond at a new world.

**Damage** (Art's grammar):
- **A crater's inside** is the subsoil's tone, not the surface's.
- **A beam's scar** is a flat band in the biome's scar colour where the burn passes `SCAR_BAND.y` (0.3), with an edge rim of `SCAR_BAND.x` (1.5) pixels inside it in the edge colour: glassy green-black with a pale edge on sand, slate on ice, black char elsewhere.
  - A faded scar narrows and goes.
  - A first cut drew the edge wherever the burn was faint, and an old scar became a wide pale band across a desert.
- The burned state (ash grey ground, black trees) waits for a fire in the sim and for window 2's cover.

**The cost on old GPUs** (Performance's bench, 2026-10-23; the split, 2026-10-25):
- **As first parked,** window 1 tripled the integrated Radeon's frame time: the AI match went from 6.5 / 11.3 to 21.2 / 48.3 ms (p50 / p95), with the same draws and primitives.
- **Not the cause.** The shader was split into compile-time variants and timed on the Radeon. Removing the palette reads, the branches, or the derivatives inside them changed nothing. Even the fragment as it was before window 1 kept the cost.
- **The cause.** The border zone's biome ids were `flat` varyings. ANGLE's D3D11 path emulates GL's provoking vertex for flat varyings by rewriting each draw's index buffer, every frame. Passing them as plain varyings cut the frame time to a third.
- **Now** each pixel reads its own column's zone from the ground field (rows 21 to 23) and steps it there:
  - the desert runs at 7.0 / 8.8 ms and the AI match at 6.8 / 11.0 ms, back to before window 1;
  - the look is the same except that the zone's five bands sit at their exact place along the strip. A triangle across a zone's edge used to take the zone from one of its vertices.
- **Rule: no `flat` varyings in a shader.** They cost the old-GPU tier on every draw.

**Checked:**
- the shaders parse headless and the palette builds;
- the 19 render gates and `split_sweep`;
- stills against d3f1ca0e and main (`img/biomes-w1-d3f1ca0e.png`): the desert, three mountain scenes, the city-beam crater, planet 7.

## Window 2: the cover

Art's cover silhouettes (`docs/art/biomes-cover.md`) grow on the band's ground behind the fighter plane.
- **The shapes** (`render/core/cover_meshes.gd`, `RenderCoverMeshes`): ported from Art's `draw.mjs` to flat meshes in the strip's plane.
  - There are 33 kinds, clean and charred: 405 and 303 triangles, matching Art's counts except the mesa (22 for 14: its shaded half is cut out as a band).
  - A vertex carries a palette slot (vegetation, secondary and rock, each lit, mid and shade; trunk; accent; char; ash; water; the ices' white and slate) and a tone step (Art's `lite` and `dark`). The colours are the palette's cover rows for the biome it grows in (`RenderBiomeLook`, rows 12 to 27), so one mesh serves every biome.
  - A shape stands as Art's sheet draws it (`height_scale`, `ground_line`).
- **Where they grow** (`render/core/cover_view.gd`, `CoverView`):
  - **Counts.** Each 1,200-unit strip carries, in each depth span of `COVER_LAYERS` (260 to 1,700 units behind the fighter plane), Art's count of each of its biome's covers, at Art's heights, mirrored at random.
  - **Borders.** Across a border's zone a shape takes the neighbour's cover by the zone's band share, and `COVER_ECO` (a quarter) of the zone's shapes are the pair's ecotone covers (Art's `neighbours`).
  - **Water.** A water column carries only what stands or floats in the sea (stacks, whitecaps, floes, bergs).
  - **None** on a building's footprint (`COVER_BUILDING_PAD`), in the city or the village, or in front of the fighter plane.
  - **Made once a world,** seeded by the world: the hand-made world grows about 1,350 shapes in 7 ms, planet 7's ring about 800 in 3 ms.
  - **Drawing.** One MultiMesh per kind in each quarter of the arena's length (`COVER_CHUNKS`), so the frustum leaves out what is off the screen. A pane's copies draw them, a second pane its source's.
- **On the ground** (`render/shaders/cover.gdshader`):
  - each shape's foot reads the ground under it as the terrain draws it, so it rises and falls with the ground;
  - what floats sits at the water's level;
  - a shape inside a crater is gone (Art: the cover inside a crater is removed);
  - hazed as the ground is, and lit by the world light as the trees are.
- **On** (`RenderLook.COVER_ON`); main's `--nocover` turns it off.
- **Not yet:**
  - the charred swap by the burn state (the damage window);
  - Art's newer kinds (tor, heath);
  - the cover in front of the fighter plane and in the far land.
- **Two traps in the Compatibility renderer, both met here:**
  - a MultiMesh without `use_colors` hands the shader black for `COLOR`, so every shape drew in the palette's first column and slot. The instances carry white, and the vertex colour comes through;
  - the instances stand at height 0 in their transforms and the shader lifts them to the ground, so the frustum culled the mountains' cover with the box at sea level. Each span's MultiMesh carries a `custom_aabb` over its ground (`COVER_BOX_PAD`).
- **The EP's watch point on window 1:** a step more rock on the mountains (from 900 units, highland from 700, down to `ROCK_HIGH` 0.15).

**Checked:**
- the shaders parse headless; the cover builds on the hand-made world and on planet 7;
- the 19 render gates and `split_sweep`;
- stills against d3f1ca0e and window 1 (`img/biomes-w2-d3f1ca0e.png`): the desert (two scenes), three mountain scenes, the city-beam scene, planet 7.

## Window 3: the far land and the sky (after)

Art's three-ridge value ladder for the far land, replacing the haze band, and the sky's tint per biome.
