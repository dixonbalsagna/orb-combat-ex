# Parked: the ground by band (Rendering, 2026-10-22)

**Base:** HEAD 0d702b70. Every check ran on copies of the commit, never on the tree.

**Apply** from the project root: `git -c core.autocrlf=false apply docs/rendering/pending/2026-10-22f/batch.diff`. Then delete this folder.

## What it changes

The ground and water are one mesh per run (one stride on one side of the fighter plane; the finest run spans both sides) and per chunk. So the frustum culls each band on its own:
- a chunk whose back rows reach the wide horizon no longer draws its fine rows too;
- the rows in front of the fighter plane, behind the camera, are no longer drawn;
- the coarsest runs are cut into chunks of 1,280 columns, not one mesh a ring.

Same vertices, same shaders.

| File | Change |
| :--- | :--- |
| `render/core/planet_view.gd` | `_make_ground_meshes`: one mesh per run and chunk, the finest run's chunks first (`near_chunks()`), the far water always shown as before |
| `render/core/look.gd` | `FAR_CHUNK_COLS` 1,280 |
| `docs/rendering/geometry-and-warmup.md`, `docs/rendering/README.md` | "The ground by band": why, the measurements, what is left |

## Checked

- **Frame time** (the AI match on the integrated Radeon, 6,000 frames, Performance's frame-bench; every run valid):

  | Build | p95 | Frames over 16.7 ms | Over 25 ms | Median triangles |
  | :--- | :--- | :--- | :--- | :--- |
  | main | 23.5 to 23.9 ms | 812 to 837 | 116 to 162 | 359 k |
  | this | 17.6 to 18.0 ms | 349 to 388 | 40 to 55 | 140 k |

  The median frame goes from 9.8 to 7.5 to 8.1 ms. Draw calls go from 108 to 118.
- **Left:** one very wide shot at the match's end (about 7,800 units across) still runs at 19 ms; with the ground cut it is 7 ms, and Camera's strip is not it. A stride that coarsens with the zoom would take it. It needs a look decision, since it would pop where it switches.
- **The look** (seed 4, reduced):
  - pixel-identical at ticks 500, 4,000 and 5,500;
  - at tick 2,000, 136 pixels differ, 127 of them by 1 or 2 levels and at most by 14, on a translucent effect at a fighter's side: the blending order of see-through draws with the water's far mesh in chunks.
  - No side-by-side was made: nothing reads differently.
- **Gates:** `gates9` (17 checks, `ground_check` and `seam_sweep` among them, with the new layout) and `cue_check` pass, with 0 script errors.
