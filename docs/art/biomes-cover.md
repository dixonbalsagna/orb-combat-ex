# Biome cover: the 35 silhouettes with triangle counts

Owner: Art Director. 2026-10-24. **Generated** by `art/concepts/biomes/covers.mjs` (`node art/concepts/biomes/gen.mjs cover`). The sheet is `art/concepts/biomes/cover-sheet.svg` and `cover-sheet.png` (the PNG is 1:1: 1 unit = 1.147 px, so a fighter of 75 units is 86 px, the game's fight size). Counts are of the flat mesh the drawing needs: every polygon fanned (n minus 2), every thin line a quad (2 per segment); the keyline is a stroke (Rendering's outline), not geometry. Charred is the burned state: a black trunk with bare branches for a tree, stubs and ash for grass, a darkening for rock (the same mesh).

| Shape | Biomes | Height (units) | Height (px at fight size) | Triangles, clean | Triangles, charred |
|---|---|---|---|---|---|
| stack | ocean | 120 to 260 | 138 to 298 | 15 | 15 |
| whitecap | ocean | 10 to 22 | 11 to 25 | 3 | 3 |
| tree | plains, forest, wetland | 130 to 340 | 149 to 390 | 17 | 14 |
| tuft | plains, forest, savanna, tundra, taiga, highland | 10 to 50 | 11 to 57 | 7 | 7 |
| boulder | plains, forest, desert, mountains, jungle, savanna, tundra, taiga, beach, highland, volcanic | 22 to 110 | 25 to 126 | 5 | 5 |
| shrub | plains, forest, tundra, taiga | 20 to 60 | 23 to 69 | 7 | 7 |
| fir | forest, mountains | 160 to 380 | 183 to 436 | 12 | 16 |
| cactus | desert | 90 to 170 | 103 to 195 | 16 | 2 |
| scrub | desert | 24 to 50 | 28 to 57 | 7 | 7 |
| mesa | desert | 160 to 240 | 183 to 275 | 14 | 14 |
| scree | mountains, highland | 20 to 50 | 23 to 57 | 9 | 9 |
| snowpatch | mountains, ice_sheet, tundra, taiga | 8 to 16 | 9 to 18 | 3 | 3 |
| icespire | ice_sheet, sea_ice | 60 to 160 | 69 to 183 | 12 | 12 |
| crevasse | ice_sheet | 10 to 14 | 11 to 16 | 3 | 3 |
| nunatak | ice_sheet | 120 to 200 | 138 to 229 | 7 | 7 |
| berg | sea_ice | 90 to 220 | 103 to 252 | 8 | 8 |
| floeblock | sea_ice | 14 to 30 | 16 to 34 | 4 | 4 |
| jungletree | jungle | 250 to 380 | 287 to 436 | 34 | 16 |
| fern | jungle | 50 to 110 | 57 to 126 | 12 | 7 |
| flower | jungle | 30 to 50 | 34 to 57 | 12 | 4 |
| acacia | savanna | 120 to 200 | 138 to 229 | 13 | 12 |
| termite | savanna | 50 to 90 | 57 to 103 | 6 | 6 |
| krummholz | tundra, highland | 30 to 90 | 34 to 103 | 10 | 10 |
| spruce | taiga | 220 to 360 | 252 to 413 | 17 | 16 |
| reed | wetland | 60 to 120 | 69 to 138 | 14 | 11 |
| mangrove | wetland | 120 to 200 | 138 to 229 | 30 | 10 |
| pool | wetland | 6 to 8 | 7 to 9 | 4 | 0 |
| palm | beach | 150 to 240 | 172 to 275 | 18 | 2 |
| dunegrass | beach | 20 to 40 | 23 to 46 | 6 | 7 |
| driftwood | beach | 14 to 20 | 16 to 23 | 4 | 4 |
| tor | highland | 90 to 190 | 103 to 218 | 44 | 44 |
| heath | highland | 18 to 40 | 21 to 46 | 12 | 8 |
| basaltcol | volcanic | 80 to 170 | 92 to 195 | 25 | 25 |
| vent | volcanic | 40 to 70 | 46 to 80 | 25 | 25 |
| lavaflow | volcanic | 10 to 14 | 11 to 16 | 4 | 4 |

**Totals:** all 35 clean shapes 439 triangles, charred 347. A strip of 1,200 units carries about 30 shapes (the cover densities in the data), so about 376 triangles of cover per strip on average, before the ground. The heaviest: tor (44), jungletree (34), mangrove (30), basaltcol (25).

**What Rendering builds:** each shape as one flat mesh of a few facets with three face colours (lit, mid, shade) from the biome palette; the charred version as a second small mesh swapped in by the burn state; a tree's canopy is 8 fan triangles.
