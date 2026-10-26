# Parked: biome rendering, window 2, the cover (Rendering, 2026-10-23)

**Base:** HEAD plus 22k, Camera's `pane-visible-half-plane.patch`, 22l, 22m and 22n (the order they apply in; the chain is clean on 671d850e).

**Apply last**, from the project root: `git -c core.autocrlf=false apply docs/rendering/pending/2026-10-23o/batch.diff`. Then delete this folder.

## What it changes

Art's cover (`docs/art/biomes.md` section 8, item 1.3 and the cover's half of 1.4; `docs/art/biomes-cover.md`). On, for Orb's eye; main's `--nocover` turns it off. Details in `docs/rendering/biomes.md`.
- **The shapes** (`render/core/cover_meshes.gd`, new): Art's 33 silhouettes from `draw.mjs` as flat meshes in the strip's plane, clean and charred.
  - Each vertex carries a palette slot and a tone step.
  - The colours are new cover rows in the palette (`biome_look.gd`, rows 12 to 27), so one mesh serves every biome.
- **Where they grow** (`render/core/cover_view.gd`, new):
  - Art's counts per 1,200-unit strip, 260 to 1,700 units behind the fighter plane, at Art's heights.
  - Across a border's zone a shape takes the neighbour's cover by the zone's band share, and a quarter are the pair's ecotone covers.
  - Water carries only what floats or stands in the sea.
  - None on a building's footprint, in the city or the village.
  - Made once a world and seeded by it. One MultiMesh per kind per quarter of the arena, each with a box over its ground for the frustum.
- **On the ground** (`render/shaders/cover.gdshader`, new):
  - each foot reads the ground as the terrain draws it, so a shape rises and falls with it;
  - what floats sits at the water's level;
  - a shape inside a crater is gone;
  - hazed as the ground is, and lit by the world light as the trees are.
- **The EP's watch point on window 1:** a step more rock on the mountains (from 900 units, highland from 700, `ROCK_HIGH` 0.15).

| File | Change |
| :--- | :--- |
| `render/core/cover_meshes.gd` (+ `.uid`, new) | `RenderCoverMeshes`: Art's silhouettes as meshes |
| `render/core/cover_view.gd` (+ `.uid`, new) | `CoverView`: where the cover grows, the MultiMeshes |
| `render/shaders/cover.gdshader` (+ `.uid`, new) | the foot on the ground, gone in a crater, the palette, the haze |
| `render/core/biome_look.gd` | the cover rows (`COVER_ROW` 12, 28 rows), `data`, `entry`, `name_of`; `ROCK_ABOVE` 900 and 700 |
| `render/core/look.gd` | `COVER_ON`, `COVER_LAYERS`, `COVER_CHUNKS`, `COVER_ECO`, `COVER_BUILDING_PAD`, `COVER_BOX_PAD`; `ROCK_HIGH` 0.15 |
| `render/core/planet_view.gd` | the cover's material and nodes in each copy, its camera x, the world light |
| `render/core/main.gd` | `--nocover` |
| `docs/rendering/biomes.md`, `docs/rendering/README.md` | window 2 and what was checked |

## Checked

- **Gates:** the 19 render gates and `split_sweep` pass on HEAD plus the chain and this park, with 0 script or shader errors.
- **Headless:** the shaders parse; the cover builds on the hand-made world and on planet 7 (counts and times in `biomes.md`).
- **Stills:** `docs/rendering/img/biomes-w2-d3f1ca0e.png` (uncommitted).
  - d3f1ca0e, then window 1 against this park.
  - Seed 4, reduced, through Tools' launcher.
- **Wrong first cuts, both fixed:**
  - without `use_colors` the MultiMesh handed the shader black for the vertex colour, so every shape drew in one slot;
  - the frustum culled the mountains' cover, its box at sea level while the shader lifts the shapes to the ground.
- **The side-by-side:** the desert (1,940 and 600), three mountain scenes (2,400, 3,600, 4,800), the city-beam scene (250, no cover in the city), planet 7 (3,000).
