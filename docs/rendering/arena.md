# The arena's length (Rendering, 2026-10-22)

World's shifting arena (`docs/world/shifting-arena-design.md`, window 1) plays a match on a ring of the planet: 4,800 columns for the great circle (153,600 units), 2,400 (76,800) or 1,200 (38,400). `SimConst.W`, `NC` and `HALF` are set per match, so the render follows them.

## What follows the arena's length

- **The ground is made again when the length changes.** `PlanetView.build` compares the length its ground was made for (`_built_nc`) with `SimConst.NC`. When they differ, it makes:
  - a new `GroundField` (its height texture, crater lists, far rows and water rows are sized by the length);
  - the ground and water meshes;
  - the materials that read them (`nc`, `world_w`, the textures).

  A second pane takes the first's, and panes are built first pane first. Before this, everything was made once for the 4,800-column planet at startup, and a shorter ring drew the wrong ground: the height texture failed to upload, the shaders wrapped at the wrong length, and copies a planet long overlapped.
- **The copies keep their reach in world units.** The ground and water are drawn `copies_each_side()` planets either side of the camera: `PLANET_COPIES` (2) whole-planet lengths, so 2 on the great circle, 4 on a ring of 2,400 and 8 on a ring of 1,200. The props reach one whole-planet length: 1, 2 and 4. Camera's zoom floor is untouched.
- **The ground chunks take a partial last chunk** when the length is not a multiple of `CHUNK_COLS` (320), so a ring of 2,400 or 1,200 has no missing strip and no overlap. A ring's length must be a multiple of the largest stride (8). World's 4,800, 2,400, 1,600, 1,200 and 600 all are.
- **ImpactFx's heat** is resized on a new match.

The far fog needs nothing. At play zooms the far horizon is 117,000 to 184,000 units wide (16:9 to 21:9), inside the copies' reach on every ring.

## Checked

- **A probe** (one game, rings of 1,200, 4,800, 2,400, 1,200 and 4,800 in turn): after each match the heat, the materials' `nc` and `world_w`, the near chunks, the ground's reach and the copies all follow the ring, with no image errors. Before this, each match on a short ring logged the height texture's size error.
- **Stills** (seed 4, Reduce flashing on as the demo has it):
  - `img/arena-1200-before-after.png`: the 1,200 ring before and after;
  - `img/arena-1200-d3f1ca0e.png` and `img/arena-2400-d3f1ca0e.png`: against d3f1ca0e.

  All uncommitted.
