# Parked: biome rendering, window 1, the ground in Art's facets (Rendering, 2026-10-23)

**Base:** HEAD plus 22k, Camera's `pane-visible-half-plane.patch`, 22l and 22m (the order they apply in; the chain is clean on 2c1b7c3c).

**Apply last**, from the project root: `git -c core.autocrlf=false apply docs/rendering/pending/2026-10-23n/batch.diff`. Then delete this folder.

## What it changes

Art's biome look bible (`docs/art/biomes.md` section 8, items 1.1, 1.4 and 1.5), on the band's ground. Not behind a switch: it is the ground's look, for Orb's eye. Details in `docs/rendering/biomes.md`.
- **The palette** (`render/core/biome_look.gd`): a 32 by 12 texture made once from `data/art/biomes.json`.
  - The columns are World's fine biome ids (0 ocean to 14 volcanic), then the city and the village.
  - Each fine biome uses Art's entry under its name, else Art's older name, else the stored alias.
  - The rows: ground, rock and subsoil, each lit, mid and shade; the scar band and its edge; the strata flag and the rock-above height.
- **Facets:**
  - Each point takes its biome's lit, mid or shade tone by its normal against the sun (upper left, a little toward the viewer). Art's rule along the strip, and a slope in depth takes the light too.
  - The normal is the smooth ground's, so a tone's edge is a clean contour.
  - Rock comes in by steepness in Art's five hard bands (0.45 to 1.25 rise over run). In a rocky biome it starts at gentler slopes the higher it is (mountains from 1,200 units, highland from 900), so a mountain is green only at a gentle foot.
  - Strata lines run every 220 units on rock that has them.
  - The band's value steps by depth in three hard steps (1.1 at the front to 0.94 at the back).
- **Borders** (`ground_field.gd` `zone_rows`, three new ground rows): a 360-unit zone stepped in five hard bands (10 to 90 percent).
- **Damage:**
  - a crater's inside is the subsoil;
  - a beam's scar is a flat band in the biome's scar colour with a 1.5-pixel edge rim; a faded scar narrows and goes;
  - rim rubble comes in two steps;
  - snow starts hard at a height.
- The far land keeps its own colour and shading (window 3).

| File | Change |
| :--- | :--- |
| `render/core/biome_look.gd` (+ `.uid`, new) | `RenderBiomeLook`: the palette from Art's data, keyed by World's fine ids |
| `render/core/ground_field.gd` | rows 21 to 23 (`ROW_ZONE_A`, `_B`, `_X`), `zone_rows` |
| `render/shaders/ground.gdshaderinc` | `biome_pal`, `biome_zone`, `biome_tone` |
| `render/shaders/terrain.gdshader` | the facets, rock and strata, the zone's bands, the subsoil, the scar, hard snow and rim |
| `render/core/planet_view.gd` | the palette and the numbers on the terrain material |
| `render/core/look.gd` | `FACET_SLOPE`, `FACET_SUN`, `ROCK_SLOPE`, `ROCK_HIGH`, `DEPTH_STEP`, `STRATA_H`, `BIOME_ZONE`, `SCAR_BAND`, `TONE_K` |
| `docs/rendering/biomes.md` (new), `docs/rendering/README.md` | the windows and what was checked |

## Checked

- **Gates:** the 19 render gates and `split_sweep` pass on HEAD plus all four parks, with 0 script or shader errors.
- **Headless:** the shaders parse; 120 of 4,800 columns of the hand-made world lie in a border zone; the zone rows take 0.5 ms natively.
- **Stills:** `docs/rendering/img/biomes-w1-d3f1ca0e.png` (uncommitted).
  - d3f1ca0e, then main against this park (the scenes below).
  - Seed 4, reduced, through Tools' launcher.
- **Wrong first cuts, all fixed:**
  - tones by each triangle's own face turned a crater's bowl to sawteeth;
  - a scar's edge drawn wherever the burn was faint laid a wide pale band across the desert;
  - strata every 60 units ruled a cliff like paper.
- **The EP's look call (2026-10-23), fixed and re-shot:**
  - a mountain's green foot was one flat lime slab cut by a straight line (rock by a height alone, tone by the slope along the strip only). Now: green only where gentle, rock in five bands by steepness, light from the normal;
  - the desert read as one colour; it now takes the hard step by depth.
- **The side-by-side:** the desert (1,940), three mountain scenes (2,400, 3,600, 4,800), the city-beam crater (250), planet 7 (3,000).
