# Biome effects (VFX, 2026-10-23)

Orb (2026-10-23): "pour resources into improving our planet generation, biomes, ..." and, through the EP, **every biome answers a fight in its own material, and has a light ambient life**. Three parts, in windows: (1) impact and landing debris by biome, (2) ambient life per biome, (3) beam and signature scars by biome. This page records them as they land. The language is Art's: docs/art/biomes.md section 5 (the plume language) and the numbers in data/art/biomes.json.

## Window 1: impacts and landings (render/vfx/biome.gd, data/vfx/biome.json)

An impact on the ground is drawn the same way in all fifteen biomes, in Art's plume language, and only the colour, the height and the ejecta change:

| Part | What it is |
| :--- | :--- |
| **Column** | a billowing stack of overlapping faceted puffs, the high ones made first so the low ones sit in front, lit at the top and shaded at the foot, as tall and wide as Art says (`plume.h`, `plume.w`) scaled by the causer's tier |
| **Burst star** | one flat pale star on the first frame, in the plume's own lit tone, never a flicker: it lives 0.025 s and asks the flash register (`biome_star`, a low-priority source: refused under Reduce flashing, and not made at an intro landing) |
| **Ejecta** | pieces on arcs by the plume's kind (below), in Art's two ejecta colours (`plume.ej`) |
| **Skirt** | a few low puffs spreading along the ground |
| **Landed debris** | a share of the chunks lands and stays two to four seconds more |
| **Extras by Art's flags** | `ring`: a flat ring on the ground (the sea ice's black water); `wet`: the beach's dark wet-sand ring; `steam`: grey puffs from the jungle's wet ground; `embers`: the volcanic ejecta include steady orange ember CHIPS (a chunk in Art's orange, never the pulsing ember bit) |

The colours, the heights and the widths are **read from Art's data by the fine biome's name** (World's fifteen ids: ocean, plains, forest, desert, mountains, ice_sheet, sea_ice, jungle, savanna, tundra, taiga, wetland, beach, highland, volcanic). A biome Art has no plume for (the villages, the city) adds nothing; the open ocean's `water` plume is the water effects' own (water.gd). `data/vfx/biome.json` holds how it is drawn and what each of Art's plume kinds throws:

| Plume kind | Biomes | Ejecta |
| :--- | :--- | :--- |
| dirt | plains | turf chunks and clods |
| leaf | forest, jungle | leaf diamonds (green and orange; the jungle's magenta petals), bark chunks, steam in the jungle |
| sand | desert, beach | sand chips in two sands and red ochre, long thin streaks skimming along the ground (the dune face slumping) |
| dust | savanna | red earth chips, tumbling straw |
| rock | mountains, highland | angular blocks, pale shards, scree sliding low |
| snow | ice sheet, sea ice, tundra, taiga | hexagonal crystals, shards of ice or dark soil clods |
| mud | wetland | dark globs on arcs, flung reed |
| ash | volcanic | black blocks, flakes, steady orange ember chips |

### Scaled by power (pillar 4)
Every count is multiplied by the **causer's tier** (`tier_k`: 0.7, 1.0, 1.45, 2.0 for tiers 1 to 4), by the event's speed share (a slow landing throws a fifth of a hard one), by quality (1, 0.7, 0.35), halved in reduced motion, and by 0.55 at the intro's landing. The column's size follows the same (`scale`: 0.3 at tier 1 and a slow landing to 1.2 at tier 4 and a hard one). A slam and the crater it digs in one tick make one column and one star, not two.

### Where it hooks and what it uses
- `earth.gd`, five calls: a landing (`slam` or `skid`), a bounce, leaving the ground, each skid sample, a crater's ejecta, a slide's end. The biome is made **first** so its plume has the pool's budget, then earth's own chunks and dust fill what is left.
- New pool pieces (`debris.gd`, `shard.gdshader`): four shapes (leaf, snow flake, ash flake, splinter) and a star in the same one draw call; `fleck()` (gravity and drag of its own), `star()`, `ring_tint()`, and chunks that **stay**. Leaves, flakes and ash sway as they fall and are gone a moment after they land.
- The pool keeps its drawn-area budget for puffs (a share of the flash register's area threshold, from the camera's scale). A plume puff counts by **how far its luminance is from the ground's** (Legal's fx07): a puff that steps 10% or more of relative luminance from the ground counts at **full weight**; under that it counts 0.3 to 1 (`puff_weight`, from Art's plume and ground colours). The burst star never repeats within a second. The column is drawn at the size that fits what is left, so at a close framing it is smaller in units but the same share of the screen.
- Randomness: the pool's cosmetic `vfx.dust` stream, a fixed number of draws a bit whatever the quality. Nothing is written to the sim.

### Honest limits
- **World's fine ids reach VFX through `S.fineCols`** (a byte a column, unhashed, from World's gen 2; `VfxBiome.key_at` reads it when it is non-empty, else the stored biome's name). Until a match is gen 2 (the default is the stored planet), it reads the seven stored names, so ice, jungle, savanna, tundra, taiga, wetland, beach, highland and volcanic cannot appear; `VfxBiome.override_biome` forces any of Art's fifteen for the checks and the pictures.
- At the camera's close framings the area budget keeps the column to about five to eight puffs; the plume reads fully at the middle and far framings. Whether the budget (and these weights) should be raised is Legal's and Tools' call, with the flash clips.
- The villages and the city have no plume of Art's, so their landings are as they were.
- Sizes of the ejecta were tuned by eye in the game's framing; Art's colours are exact.
- Not a Legal clearance. Legal wants a glance at the plumes: still frames, one burst star, steady embers (stills in homework/biome-fx/).
