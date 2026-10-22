# Parked: the scorch and the heat on their own (Rendering, 2026-10-22)

**Base:** HEAD fc364a7d. Every check ran on copies of the commit, never on the tree.

**Apply** from the project root: `git -c core.autocrlf=false apply docs/rendering/pending/2026-10-22h/batch.diff`. Then delete this folder.

## What it changes

A fight's fires change the ground's scorch and heat every tick, and the whole ground texture (about 400 KB at 4,800 columns) was uploaded each time. Now the scorch and the heat are their own small texture, uploaded when they change. The whole field is uploaded only when the ground's shape, water or cracks change.

| File | Change |
| :--- | :--- |
| `render/core/ground_field.gd` | `himg` / `htex` (two rows), `_upload_hot`, the uploads split; `row_bytes()` answers the scorch and heat rows from it |
| `render/shaders/ground.gdshaderinc` | `uniform sampler2D hot`, `gh()`; the grooves' width reads the scorch from it |
| `render/shaders/terrain.gdshader` | the char and the glow read `gh()` |
| `render/core/planet_view.gd` | the terrain and water materials get `hot` |
| `docs/rendering/geometry-and-warmup.md` | "The scorch and the heat on their own" |

## Checked

- **The look:**
  - pixel-identical, seed 4, at ticks 250, 280, 500 and 1,500 (reduced) and 250 and 1,180 (normal);
  - a control with `hot` unbound changes 258 pixels at 1,180 (normal), so the scorch and heat are on screen there and the split draws them exactly;
  - side-by-side: `docs/rendering/img/heat-split-1180.png`, uncommitted.
- **The cost** (ticks 240 to 400 after the first crater):
  - natively, the whole field is uploaded on 23 frames, not 57, and the uploads' mean goes from 0.108 to 0.041 ms a frame;
  - on the web at x4, four runs on a shared machine sit within their noise. The earlier timing build that cut these uploads measured about 1 ms a frame at x4.
- **Gates:** `gates9` (17 checks, `ground_check` among them, reading the rows through `row_bytes()`) and `cue_check` pass, with 0 script errors.
