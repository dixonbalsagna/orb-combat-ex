# Does the ground's growth through a match cost the frame? World's side (2026-10-22, for Rendering; docs/perf/frame-pacing-2026-10-22.md)

Question (EP, Performance's finding): the integrated GPU's terrain primitives go 231 k to 808 k through an AI match; is the cost the heightfield's detail, or craters adding columns or vertices? Measured on HEAD e09dbbbf with the two scripts here (headless; `crater_growth.gd.txt` and `mesh_count.gd.txt`, copy to `sim/world/tools/` to run).

## Craters do not add columns or vertices

- **The terrain mesh is static.** `PlanetView._make_ground_meshes` lays the grid once from `ground_rows()` and the strides in `RenderLook.STRIDES`; heights come from the ground field's texture in the shader (`render/core/ground_field.gd`), so a crater changes texels, never the mesh.
- **The sim's marks stay small in an AI match** (`crater_growth.gd`, 7,200 ticks, three matches: the default world seeds 1 and 2, and planet 7 Whole): at most **15 crater records** (the list holds 400) covering at most **182 columns** of 4,800 (or 9,600); the most records over any one column is **5**, under the ground band's K of 6, so the six-crater sum never saturates; scorch at most 374 columns, rubble at most 25, cracks at most 35, slides at most 5.

| Tick | Craters (default seed 2) | Columns with one or more | Most over one column | Craters (planet 7) | Columns with one or more |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 2,400 | 4 | 44 | 3 | 3 | 24 |
| 4,800 | 9 | 111 | 5 | 11 | 164 |
| 7,200 | 10 | 169 | 5 | 15 | 182 |

At most 4 percent of the columns ever carry a crater, so the shader's crater loop runs on a few percent of columns, and a cap on crater records would change nothing in play.

## What does scale with the view: how many chunks the frustum keeps

`mesh_count.gd` counts the ground triangles per chunk, the way the layout does:

| Arena | Chunks | Near (stride 1) per chunk | Mid per chunk | All chunks | Far mesh, always drawn |
| :--- | ---: | ---: | ---: | ---: | ---: |
| Whole, 4,800 columns | 15 | 21,760 | 11,200 | 494,400 | 63,600 |
| Half, 2,400 | 8 | 20,400 | 10,500 | 247,200 | 31,800 |
| Close, 1,200 | 4 | 20,400 | 10,500 | 123,600 | 15,900 |

A chunk is culled by the frustum on x and z only (its box is tall), and every chunk that is in view draws **all** its rows, including its far rows that the fog hides. So the terrain's primitives are about 33,000 a visible chunk plus the 64,000 of the far mesh: the 386 k at tick 6,000 is about 10 chunks in view, the 231 k at tick 750 about 5. **The count follows how much of the ring the camera sees** (the framing, the camera's angle, how far apart the fighters are), not the craters, which is what Performance saw in the brawl (187 to 193 k, steady) and a "part of the world the camera is over". The ground mesh's primitives, not the craters, are the lever. Ideas for Rendering (nothing of World's is needed):
- a finer-to-coarser stride by distance along x from the camera, not only along z (a chunk far to the side of the view need not be drawn at stride 1: the near chunk is 21,760 triangles at stride 1, about 10,900 at stride 2 and 5,400 at stride 4);
- a per-chunk z extent that matches what the fog leaves visible, so far rows do not draw;
- logging `near_chunks()` and the visible chunk count with the primitive count in `frame-bench` would confirm this directly (I cannot count primitives headless).

I have not run the GPU; the chunk count is from the layout, the 386 k is Performance's. If a crater-heavy fight is wanted for a test, the sim can make one (a 20-crater, 40-percent-overlap scenario), but the data says the match does not make it.
