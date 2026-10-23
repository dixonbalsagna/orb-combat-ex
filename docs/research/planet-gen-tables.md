# Planet generation: the tables

Research & Prototyping, 2026-10-23. Written by `research/planet-gen/tables.mjs` from `research/planet-gen/stats/*.json`; the study is `planet-gen.md`. Shares are of the planet's land, area-weighted from a 1,024 x 512 equirect sample. A dash is under 0.1%.

## 1. Each biome's share of land, per seed

### Today (WorldPlanet)

| Biome | Seed 7 | Seed 11 | Seed 23 | Seed 42 | Seed 101 | Seed 2026 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Land, % of the planet** | **58.4** | **80.7** | **53.6** | **81.4** | **58** | **67.4** |
| Temperate forest | 29.4 | 40.2 | 26.4 | 32.9 | 38.6 | 37.7 |
| Grassland | 34.8 | 23.4 | 33.2 | 21.7 | 38.2 | 30.1 |
| Mountain rock | 11.9 | 21.5 | 4.0 | 27.7 | 3.6 | 9.6 |
| Hot desert | 13.4 | 6.6 | 25.4 | 10.1 | 9.0 | 13.1 |
| Ice sheet | 10.6 | 8.3 | 11.0 | 7.6 | 10.6 | 9.5 |
| Lakes, % of the planet | - | - | - | - | - | - |

### A: climate table

| Biome | Seed 7 | Seed 11 | Seed 23 | Seed 42 | Seed 101 | Seed 2026 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Land, % of the planet** | **61.3** | **84** | **58.5** | **86** | **66.5** | **70** |
| Ice sheet | 15.0 | 12.6 | 14.0 | 16.3 | 16.2 | 18.1 |
| Grassland | 11.7 | 16.4 | 10.8 | 18.1 | 10.5 | 10.4 |
| Savanna | 10.9 | 10.2 | 20.0 | 2.9 | 14.1 | 16.3 |
| Temperate forest | 11.2 | 8.9 | 9.4 | 18.6 | 10.6 | 6.5 |
| Tropical dry forest | 10.2 | 7.9 | 10.6 | 1.6 | 9.4 | 10.3 |
| Shrubland | 8.5 | 7.3 | 7.4 | 7.7 | 9.3 | 9.1 |
| Hot desert | 8.5 | 6.7 | 7.5 | 4.6 | 8.4 | 8.1 |
| Boreal forest | 5.7 | 6.6 | 5.0 | 7.6 | 7.1 | 4.9 |
| Alpine | 5.2 | 10.6 | 2.8 | 11.6 | 0.9 | 5.2 |
| Beach and coast | 4.5 | 1.0 | 5.9 | 0.7 | 5.7 | 3.7 |
| Snowcap | 1.6 | 4.2 | 1.7 | 4.1 | - | 2.3 |
| Tundra | 1.7 | 2.9 | 2.3 | 2.6 | 3.0 | 0.8 |
| Cold steppe | 2.3 | 4.0 | 1.3 | 3.4 | 0.7 | 0.5 |
| Wetland | 0.9 | - | 0.8 | - | 0.8 | 2.5 |
| Tropical rainforest | 1.5 | 0.2 | 0.3 | - | 2.1 | 0.7 |
| Temperate rainforest | 0.7 | 0.5 | 0.2 | 0.1 | 1.0 | 0.4 |
| Lakes, % of the planet | - | - | - | - | - | - |

### B: plates and climate

| Biome | Seed 7 | Seed 11 | Seed 23 | Seed 42 | Seed 101 | Seed 2026 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Land, % of the planet** | **52.4** | **57.8** | **46** | **46.4** | **59.6** | **54.8** |
| Temperate forest | 16.2 | 13.5 | 15.5 | 17.3 | 15.1 | 15.2 |
| Ice sheet | 13.2 | 14.5 | 14.8 | 21.1 | 14.3 | 14.5 |
| Grassland | 13.8 | 15.3 | 13.9 | 18.4 | 12.8 | 16.0 |
| Shrubland | 9.9 | 9.9 | 8.5 | 6.9 | 5.8 | 9.6 |
| Tropical dry forest | 8.6 | 9.8 | 8.7 | 3.2 | 10.9 | 6.7 |
| Temperate rainforest | 7.5 | 6.6 | 7.2 | 7.9 | 8.9 | 7.2 |
| Savanna | 8.7 | 10.1 | 8.1 | 2.9 | 6.2 | 8.3 |
| Boreal forest | 4.2 | 5.1 | 5.1 | 4.9 | 5.5 | 7.7 |
| Tropical rainforest | 3.6 | 3.3 | 8.4 | 4.0 | 6.3 | 2.7 |
| Hot desert | 6.5 | 4.0 | 1.5 | 1.6 | 3.9 | 4.0 |
| Alpine | 2.7 | 3.0 | 3.1 | 4.4 | 4.6 | 2.3 |
| Tundra | 1.0 | 1.5 | 3.1 | 3.2 | 2.4 | 3.1 |
| Cold steppe | 1.1 | 2.0 | 0.2 | 1.3 | 2.1 | 0.7 |
| Snowcap | 0.7 | 0.9 | 0.9 | 1.1 | 0.8 | 0.7 |
| Volcanic field | 1.8 | 0.3 | 0.3 | 1.4 | - | 1.0 |
| Beach and coast | 0.3 | 0.2 | 0.2 | 0.2 | 0.2 | 0.2 |
| Wetland | 0.2 | - | 0.4 | 0.2 | 0.2 | 0.1 |
| Lakes, % of the planet | - | - | - | - | - | - |

### C: erosion on B

| Biome | Seed 7 | Seed 11 | Seed 23 | Seed 42 | Seed 101 | Seed 2026 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Land, % of the planet** | **50.8** | **55.8** | **43.7** | **45** | **56.5** | **53.9** |
| Ice sheet | 13.4 | 14.8 | 15.3 | 21.3 | 14.8 | 14.5 |
| Temperate forest | 16.2 | 13.2 | 15.4 | 17.1 | 14.7 | 15.1 |
| Grassland | 14.2 | 15.5 | 14.4 | 18.0 | 13.0 | 16.0 |
| Shrubland | 10.1 | 10.2 | 8.9 | 7.1 | 6.1 | 9.7 |
| Temperate rainforest | 7.1 | 6.4 | 7.2 | 7.8 | 9.0 | 7.0 |
| Tropical dry forest | 7.4 | 9.5 | 8.4 | 3.3 | 8.9 | 6.3 |
| Savanna | 8.6 | 9.8 | 6.9 | 2.6 | 6.3 | 8.3 |
| Boreal forest | 4.3 | 4.3 | 5.2 | 4.6 | 5.5 | 7.7 |
| Tropical rainforest | 3.7 | 3.4 | 7.7 | 4.2 | 6.6 | 2.7 |
| Hot desert | 6.7 | 4.1 | 1.6 | 1.7 | 4.1 | 4.1 |
| Alpine | 2.7 | 3.1 | 3.1 | 4.4 | 4.6 | 2.2 |
| Tundra | 1.1 | 1.6 | 3.3 | 3.2 | 2.5 | 3.2 |
| Cold steppe | 1.1 | 2.0 | 0.1 | 1.3 | 2.2 | 0.7 |
| Volcanic field | 1.9 | 0.3 | 0.3 | 1.5 | - | 1.1 |
| Snowcap | 0.6 | 0.9 | 0.9 | 1.0 | 0.9 | 0.7 |
| Beach and coast | 0.5 | 0.3 | 0.5 | 0.5 | 0.4 | 0.5 |
| Wetland | 0.3 | 0.1 | 0.5 | 0.2 | 0.3 | 0.1 |
| Badlands | 0.2 | 0.3 | 0.2 | 0.2 | 0.1 | 0.2 |
| Lakes, % of the planet | 1.6 | 2.2 | 2.4 | 1.5 | 3.2 | 1.1 |

### C on A: erosion on today's ground

| Biome | Seed 7 | Seed 11 | Seed 23 | Seed 42 | Seed 101 | Seed 2026 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Land, % of the planet** | **61.2** | **83.6** | **58.5** | **83.1** | **66.2** | **70** |
| Ice sheet | 14.9 | 12.5 | 13.9 | 16.7 | 16.2 | 18.0 |
| Grassland | 11.6 | 16.4 | 10.6 | 18.1 | 10.5 | 10.4 |
| Savanna | 10.7 | 10.3 | 19.9 | 2.8 | 14.1 | 16.3 |
| Temperate forest | 11.0 | 8.7 | 9.2 | 17.6 | 10.5 | 6.5 |
| Shrubland | 8.5 | 7.4 | 7.4 | 7.9 | 9.4 | 9.0 |
| Tropical dry forest | 10.2 | 8.0 | 10.5 | 0.7 | 9.3 | 10.2 |
| Hot desert | 8.6 | 6.7 | 7.5 | 4.8 | 8.4 | 8.0 |
| Boreal forest | 5.8 | 6.4 | 5.0 | 7.8 | 6.8 | 5.0 |
| Alpine | 5.1 | 10.6 | 2.8 | 11.8 | 0.9 | 5.1 |
| Beach and coast | 5.1 | 1.2 | 6.6 | 1.0 | 6.4 | 4.3 |
| Snowcap | 1.5 | 4.1 | 1.7 | 4.2 | - | 2.3 |
| Tundra | 1.7 | 2.9 | 2.3 | 2.6 | 3.0 | 0.8 |
| Cold steppe | 2.3 | 4.0 | 1.3 | 3.6 | 0.7 | 0.5 |
| Wetland | 0.9 | - | 0.8 | - | 0.8 | 2.5 |
| Tropical rainforest | 1.4 | 0.1 | 0.3 | - | 2.0 | 0.6 |
| Temperate rainforest | 0.6 | 0.5 | 0.2 | 0.1 | 1.0 | 0.3 |
| Badlands | - | - | - | 0.1 | - | - |
| Lakes, % of the planet | 0.1 | 0.4 | - | 2.9 | 0.2 | 0.1 |

## 2. The fight read: what the 4,800-column ring crosses

Each seed's ring is the first of 16 seeded great circles that holds half land and three biomes of 8% or more on 96 samples (WorldPlanet's minimum without the places); "no" means none did and the one with the most land is shown. Biomes: of the ring's land, those of 1% or more. Changes: columns where the biome differs from the one before. Longest: the longest single-biome stretch.

### Today (WorldPlanet)

| Seed | Ring | Met | Land % | Biomes | Changes | Coasts | Longest (units) | Mountain % | Rivers | Lakes | Heights | The ring's land, by share |
| ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- | :--- |
| 7 | 2 | yes | 68 | 4 | 15 | 6 | 27,872 | 0.2 | 0 | 0 | -381 to 3,209 | Grassland 33.7, Hot desert 26.7, Temperate forest 26.2, Ice sheet 13.1 |
| 11 | 1 | yes | 74.8 | 4 | 16 | 6 | 26,464 | 6.5 | 0 | 0 | -392 to 6,039 | Temperate forest 54, Grassland 20, Ice sheet 17.3, Mountain rock 8.7 |
| 23 | 1 | yes | 52.6 | 4 | 18 | 6 | 23,072 | 4.5 | 0 | 0 | -392 to 4,416 | Grassland 44.8, Hot desert 26, Temperate forest 20.6, Mountain rock 8.6 |
| 42 | 0 | yes | 67.8 | 5 | 23 | 6 | 22,368 | 21.1 | 0 | 0 | -378 to 5,585 | Mountain rock 31.2, Ice sheet 21.5, Hot desert 21, Grassland 14, Temperate forest 12.3 |
| 101 | 1 | yes | 54.7 | 3 | 14 | 8 | 31,936 | 0 | 0 | 0 | -320 to 1,311 | Temperate forest 50, Grassland 31.4, Hot desert 18.7 |
| 2026 | 0 | yes | 68.3 | 3 | 17 | 6 | 25,120 | 0 | 0 | 0 | -397 to 2,577 | Grassland 49, Temperate forest 30.8, Hot desert 20.1 |

### A: climate table

| Seed | Ring | Met | Land % | Biomes | Changes | Coasts | Longest (units) | Mountain % | Rivers | Lakes | Heights | The ring's land, by share |
| ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- | :--- |
| 7 | 1 | yes | 58.8 | 10 | 47 | 8 | 25,408 | 4.1 | 0 | 0 | -3,339 to 4,547 | Boreal forest 20.5, Grassland 16.3, Temperate forest 15.7, Hot desert 13.1, Shrubland 11.6, Savanna 8.3, Alpine 7.1, Beach and coast 5.2, Temperate rainforest 1.2, Cold steppe 1.1 |
| 11 | 0 | yes | 81.5 | 13 | 47 | 2 | 14,592 | 12.3 | 0 | 0 | -2,912 to 5,923 | Ice sheet 21.8, Alpine 13.1, Temperate forest 12.2, Tundra 8.5, Grassland 8.1, Shrubland 7.5, Boreal forest 7.5, Tropical dry forest 5.7, Savanna 4.8, Cold steppe 4.6, Hot desert 2.3, Snowcap 1.9, Tropical rainforest 1.9 |
| 23 | 1 | yes | 64.9 | 11 | 37 | 4 | 14,112 | 6 | 0 | 0 | -3,353 to 4,416 | Tundra 15.7, Savanna 15.3, Shrubland 12.9, Grassland 11.7, Hot desert 10.6, Boreal forest 7.9, Temperate forest 7.9, Beach and coast 6.7, Alpine 6, Snowcap 3.2, Cold steppe 1.8 |
| 42 | 0 | yes | 75.3 | 10 | 40 | 4 | 20,448 | 14.3 | 0 | 0 | -2,962 to 5,585 | Ice sheet 29.9, Temperate forest 18.1, Alpine 14, Boreal forest 11, Grassland 10.9, Snowcap 5, Tundra 3, Shrubland 2.8, Cold steppe 2.6, Hot desert 2 |
| 101 | 0 | yes | 72.4 | 9 | 46 | 8 | 19,424 | 0 | 0 | 0 | -1,764 to 1,836 | Shrubland 18.8, Grassland 17.8, Tropical dry forest 16.3, Temperate forest 15.5, Savanna 12.6, Hot desert 5.4, Beach and coast 5.3, Wetland 4.4, Tropical rainforest 3.8 |
| 2026 | 0 | yes | 77.8 | 14 | 54 | 4 | 16,864 | 2.5 | 0 | 0 | -3,087 to 2,954 | Savanna 18.5, Ice sheet 13.4, Grassland 11.1, Temperate forest 9.9, Hot desert 8, Shrubland 7.2, Tropical dry forest 7, Boreal forest 6.8, Wetland 5.7, Alpine 3.3, Tropical rainforest 2.9, Beach and coast 2.7, Tundra 2, Temperate rainforest 1.6 |

### B: plates and climate

| Seed | Ring | Met | Land % | Biomes | Changes | Coasts | Longest (units) | Mountain % | Rivers | Lakes | Heights | The ring's land, by share |
| ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- | :--- |
| 7 | 3 | yes | 59.8 | 11 | 84 | 10 | 21,760 | 2.3 | 0 | 0 | -5,465 to 4,483 | Ice sheet 21.8, Temperate forest 18, Savanna 11.8, Temperate rainforest 11.5, Grassland 10.6, Shrubland 7, Tropical dry forest 5, Boreal forest 4.6, Alpine 3.5, Hot desert 2.5, Volcanic field 1.5 |
| 11 | 1 | yes | 73.8 | 12 | 85 | 10 | 14,720 | 7.4 | 0 | 0 | -8,477 to 9,871 | Ice sheet 23, Temperate forest 14.7, Grassland 13.5, Tropical dry forest 11.8, Boreal forest 10.5, Alpine 7.9, Shrubland 6, Cold steppe 3, Tundra 2.9, Snowcap 2.2, Hot desert 2, Temperate rainforest 1.7 |
| 23 | 2 | yes | 60.9 | 7 | 64 | 10 | 26,496 | 0.5 | 0 | 0 | -3,243 to 7,265 | Savanna 30.9, Tropical rainforest 27.8, Tropical dry forest 14.8, Temperate rainforest 9.5, Temperate forest 9, Grassland 4.1, Wetland 1.8 |
| 42 | 15 | no | 71 | 11 | 70 | 6 | 20,224 | 3.8 | 0 | 0 | -4,634 to 8,986 | Temperate forest 40.4, Grassland 27.2, Ice sheet 7, Shrubland 5.8, Temperate rainforest 4.9, Alpine 4, Savanna 2.7, Tropical dry forest 1.9, Tropical rainforest 1.8, Snowcap 1.3, Boreal forest 1.1 |
| 101 | 0 | yes | 62.3 | 10 | 65 | 8 | 25,312 | 3.2 | 0 | 0 | -3,659 to 3,678 | Temperate forest 27.6, Temperate rainforest 16, Tropical dry forest 13.7, Grassland 13.7, Boreal forest 8.1, Shrubland 5.9, Savanna 4.8, Alpine 4.4, Cold steppe 2.2, Hot desert 1.5 |
| 2026 | 2 | yes | 75.8 | 12 | 80 | 12 | 16,256 | 3.2 | 0 | 0 | -8,281 to 3,696 | Ice sheet 22.9, Grassland 17.4, Boreal forest 11.1, Savanna 10.1, Shrubland 9.2, Temperate forest 7.7, Tropical dry forest 5.6, Hot desert 4.7, Alpine 3.4, Tundra 2.4, Temperate rainforest 2.2, Tropical rainforest 1.5 |

### C: erosion on B

| Seed | Ring | Met | Land % | Biomes | Changes | Coasts | Longest (units) | Mountain % | Rivers | Lakes | Heights | The ring's land, by share |
| ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- | :--- |
| 7 | 10 | yes | 54.4 | 10 | 65 | 14 | 29,312 | 1.6 | 8 | 2 | -7,910 to 5,224 | Ice sheet 25.9, Temperate forest 18, Grassland 14.2, Savanna 10.1, Boreal forest 9.2, Hot desert 6.3, Shrubland 5.6, Temperate rainforest 3.1, Alpine 2.9, Tundra 2 |
| 11 | 1 | yes | 69.7 | 12 | 96 | 16 | 14,656 | 6.9 | 14 | 3 | -8,477 to 8,896 | Ice sheet 23.8, Temperate forest 16.1, Grassland 15.1, Boreal forest 11, Alpine 7.7, Tropical dry forest 7.6, Shrubland 6.2, Cold steppe 3.3, Tundra 3.3, Snowcap 2.2, Hot desert 2.2, Temperate rainforest 1.4 |
| 23 | 0 | yes | 53.9 | 12 | 80 | 14 | 34,048 | 1.2 | 8 | 4 | -5,318 to 6,545 | Ice sheet 22.2, Temperate forest 17.6, Grassland 14.5, Temperate rainforest 11.9, Boreal forest 8.2, Savanna 6.8, Tundra 4.3, Shrubland 3.3, Wetland 2.9, Volcanic field 2.7, Tropical rainforest 2.7, Alpine 1.7 |
| 42 | 15 | no | 68.7 | 12 | 79 | 8 | 20,192 | 3.9 | 3 | 1 | -4,634 to 8,769 | Temperate forest 40.3, Grassland 25.7, Ice sheet 7.1, Shrubland 6.3, Temperate rainforest 4.4, Alpine 4.3, Savanna 2.9, Tropical dry forest 2.4, Tropical rainforest 1.9, Snowcap 1.4, Boreal forest 1.2, Volcanic field 1 |
| 101 | 4 | yes | 63.9 | 9 | 53 | 8 | 49,600 | 1.8 | 13 | 2 | -3,401 to 4,335 | Shrubland 23.5, Savanna 22.2, Temperate forest 15.9, Grassland 13.3, Hot desert 11.3, Tropical dry forest 3.8, Tropical rainforest 3.2, Cold steppe 3, Alpine 2.3 |
| 2026 | 2 | yes | 72.5 | 13 | 95 | 20 | 16,256 | 3 | 11 | 5 | -8,281 to 3,638 | Ice sheet 24, Grassland 17.6, Shrubland 9.6, Boreal forest 9.5, Savanna 9.3, Temperate forest 8.3, Tropical dry forest 5.5, Hot desert 4.9, Alpine 3.4, Tundra 2.4, Tropical rainforest 1.8, Temperate rainforest 1.7, Volcanic field 1 |

### C on A: erosion on today's ground

| Seed | Ring | Met | Land % | Biomes | Changes | Coasts | Longest (units) | Mountain % | Rivers | Lakes | Heights | The ring's land, by share |
| ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- | :--- |
| 7 | 1 | yes | 58.8 | 10 | 49 | 8 | 25,408 | 4.1 | 13 | 0 | -3,339 to 4,545 | Boreal forest 20.3, Grassland 15.8, Temperate forest 14.9, Hot desert 13.1, Shrubland 11.6, Savanna 8.8, Alpine 7, Beach and coast 6.3, Cold steppe 1.1, Temperate rainforest 1.1 |
| 11 | 0 | yes | 80.4 | 13 | 55 | 6 | 14,464 | 12.1 | 14 | 2 | -2,912 to 5,916 | Ice sheet 21.8, Alpine 13.2, Temperate forest 12.4, Tundra 8.6, Shrubland 8, Grassland 7.7, Boreal forest 6.5, Tropical dry forest 6.3, Savanna 5.1, Cold steppe 4.7, Hot desert 2.3, Snowcap 1.9, Tropical rainforest 1.3 |
| 23 | 1 | yes | 64.9 | 11 | 36 | 4 | 14,112 | 5.9 | 6 | 0 | -3,353 to 4,405 | Savanna 15.8, Tundra 15.5, Shrubland 12.9, Grassland 11.6, Hot desert 10.6, Boreal forest 8.1, Temperate forest 7.8, Beach and coast 6.8, Alpine 6, Snowcap 3.1, Cold steppe 1.8 |
| 42 | 0 | yes | 73.3 | 10 | 42 | 6 | 20,448 | 14.2 | 8 | 1 | -2,962 to 5,571 | Ice sheet 30.5, Temperate forest 18.1, Alpine 14.2, Boreal forest 11.3, Grassland 9.1, Snowcap 5.2, Tundra 3.1, Cold steppe 2.8, Shrubland 2.4, Hot desert 2.1 |
| 101 | 0 | yes | 72.4 | 9 | 46 | 8 | 19,424 | 0 | 26 | 0 | -1,764 to 1,800 | Shrubland 18.8, Grassland 17.7, Tropical dry forest 16.5, Temperate forest 15.2, Savanna 12.5, Beach and coast 6.1, Hot desert 5.4, Wetland 4.2, Tropical rainforest 3.7 |
| 2026 | 0 | yes | 77.8 | 14 | 58 | 4 | 16,864 | 2.4 | 16 | 0 | -3,087 to 2,947 | Savanna 17.7, Ice sheet 13.4, Grassland 11.1, Temperate forest 10, Hot desert 8, Shrubland 7.1, Tropical dry forest 7.1, Boreal forest 6.8, Wetland 5.4, Beach and coast 3.9, Tropical rainforest 3.1, Alpine 3.1, Tundra 2.1, Temperate rainforest 1.2 |

## 3. Cost per seed (JS, this PC)

Ring: the 4,800 columns read cold (the climate memo emptied), best of 5. Today: WorldPlanet's function on the same ring in the same run. Set-up: the per-planet work before the first read (approach C's grid).

| Approach | Seed 7 | Seed 11 | Seed 23 | Seed 42 | Seed 101 | Seed 2026 | Median |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Today (WorldPlanet): ring, times today | 1 | 1.08 | 0.87 | 1.22 | 0.92 | 1.01 | 1.0 |
| A: climate table: ring, times today | 3.05 | 3.47 | 2.96 | 2.83 | 3.73 | 3.92 | 3.3 |
| B: plates and climate: ring, times today | 5.72 | 4.63 | 7.8 | 7.17 | 8.01 | 6.29 | 6.7 |
| C: erosion on B: ring, times today | 4.9 | 5.11 | 6.87 | 7.3 | 9.07 | 5.9 | 6.4 |
| C: erosion on B: set-up, ms | 599 | 505 | 466 | 511 | 554 | 611 | 533 |
| C on A: erosion on today's ground: ring, times today | 4.11 | 3.72 | 3.13 | 2.71 | 5.46 | 4.16 | 3.9 |
| C on A: erosion on today's ground: set-up, ms | 335 | 387 | 310 | 421 | 370 | 426 | 379 |
