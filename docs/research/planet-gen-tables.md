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
| **Land, % of the planet** | **61.3** | **83.9** | **58.5** | **85.3** | **61.3** | **69.7** |
| Ice sheet | 14.8 | 13.8 | 14.0 | 17.0 | 10.6 | 18.4 |
| Grassland | 11.3 | 17.3 | 10.9 | 18.9 | 10.8 | 11.8 |
| Savanna | 11.3 | 11.1 | 19.5 | 3.3 | 15.2 | 16.1 |
| Temperate forest | 11.1 | 8.8 | 9.9 | 19.3 | 12.4 | 5.7 |
| Tropical dry forest | 10.2 | 7.5 | 11.2 | 1.7 | 10.6 | 10.0 |
| Shrubland | 8.3 | 7.2 | 7.5 | 7.2 | 10.2 | 9.8 |
| Hot desert | 8.5 | 6.5 | 7.1 | 4.6 | 9.1 | 8.0 |
| Alpine | 5.9 | 10.3 | 2.7 | 11.4 | 0.9 | 5.3 |
| Boreal forest | 5.7 | 5.6 | 4.8 | 6.8 | 6.5 | 4.5 |
| Beach and coast | 4.5 | 1.0 | 5.9 | 0.7 | 6.2 | 3.8 |
| Snowcap | 1.6 | 4.1 | 1.5 | 3.8 | - | 2.2 |
| Cold steppe | 2.0 | 3.8 | 1.2 | 3.2 | 0.8 | 0.4 |
| Tundra | 1.6 | 2.2 | 2.2 | 1.9 | 2.2 | 0.7 |
| Wetland | 1.0 | 0.1 | 0.9 | 0.1 | 1.0 | 2.5 |
| Tropical rainforest | 1.5 | 0.2 | 0.4 | - | 2.3 | 0.6 |
| Temperate rainforest | 0.7 | 0.5 | 0.2 | 0.2 | 1.2 | 0.3 |
| Lakes, % of the planet | - | - | - | - | - | - |

### B: plates and climate

| Biome | Seed 7 | Seed 11 | Seed 23 | Seed 42 | Seed 101 | Seed 2026 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Land, % of the planet** | **49.7** | **51.2** | **50.7** | **57.1** | **49.4** | **50.3** |
| Temperate forest | 20.4 | 11.0 | 16.3 | 18.4 | 18.0 | 15.1 |
| Grassland | 11.5 | 12.2 | 12.3 | 14.1 | 11.7 | 12.9 |
| Ice sheet | 11.9 | 13.4 | 11.7 | 11.1 | 10.6 | 12.4 |
| Temperate rainforest | 7.7 | 6.0 | 11.3 | 12.2 | 14.2 | 5.9 |
| Savanna | 6.9 | 11.7 | 8.9 | 5.0 | 10.8 | 12.3 |
| Tropical dry forest | 7.3 | 11.7 | 8.0 | 5.2 | 8.0 | 6.9 |
| Boreal forest | 6.9 | 5.4 | 9.6 | 7.4 | 4.4 | 5.7 |
| Shrubland | 6.2 | 8.4 | 6.2 | 5.4 | 4.2 | 8.1 |
| Hot desert | 6.2 | 7.3 | 2.9 | 4.8 | 6.4 | 8.1 |
| Tropical rainforest | 4.4 | 4.8 | 3.4 | 4.3 | 2.9 | 2.9 |
| Alpine | 4.4 | 1.7 | 3.0 | 5.3 | 4.4 | 3.3 |
| Tundra | 2.7 | 2.6 | 3.7 | 2.4 | 0.9 | 2.5 |
| Cold steppe | 1.1 | 2.4 | 1.3 | 1.9 | 1.8 | 1.7 |
| Snowcap | 0.8 | 0.6 | 0.3 | 0.9 | 0.4 | 1.0 |
| Beach and coast | 0.6 | 0.5 | 0.4 | 0.5 | 0.5 | 0.4 |
| Volcanic field | 0.6 | 0.2 | 0.6 | 0.7 | 0.1 | 0.6 |
| Wetland | 0.3 | 0.2 | 0.2 | 0.5 | 0.6 | 0.2 |
| Lakes, % of the planet | - | - | - | - | - | - |

### C: erosion on B

| Biome | Seed 7 | Seed 11 | Seed 23 | Seed 42 | Seed 101 | Seed 2026 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Land, % of the planet** | **49.1** | **50.8** | **49.1** | **56.5** | **49.2** | **50** |
| Temperate forest | 20.3 | 10.9 | 16.0 | 18.2 | 17.8 | 14.9 |
| Grassland | 11.5 | 12.2 | 12.7 | 14.2 | 11.7 | 12.8 |
| Ice sheet | 11.9 | 13.3 | 11.9 | 11.1 | 10.5 | 12.2 |
| Savanna | 7.1 | 11.5 | 9.2 | 5.1 | 11.0 | 12.5 |
| Temperate rainforest | 7.3 | 5.7 | 11.3 | 11.9 | 13.8 | 5.7 |
| Tropical dry forest | 7.6 | 11.6 | 7.7 | 5.1 | 8.2 | 7.0 |
| Shrubland | 6.3 | 8.4 | 6.4 | 5.5 | 4.1 | 8.1 |
| Boreal forest | 6.5 | 5.3 | 8.9 | 7.3 | 4.3 | 5.5 |
| Hot desert | 6.2 | 7.4 | 3.0 | 4.9 | 6.4 | 8.1 |
| Tropical rainforest | 4.5 | 4.8 | 3.6 | 4.3 | 2.9 | 2.9 |
| Alpine | 4.3 | 1.8 | 2.9 | 5.2 | 4.3 | 3.3 |
| Tundra | 2.7 | 2.6 | 3.2 | 2.4 | 0.9 | 2.5 |
| Cold steppe | 1.0 | 2.4 | 1.3 | 1.8 | 1.8 | 1.7 |
| Beach and coast | 1.0 | 0.7 | 0.6 | 0.8 | 0.8 | 0.7 |
| Snowcap | 0.8 | 0.6 | 0.3 | 0.9 | 0.4 | 1.0 |
| Volcanic field | 0.6 | 0.2 | 0.6 | 0.7 | 0.1 | 0.6 |
| Wetland | 0.3 | 0.3 | 0.3 | 0.6 | 0.7 | 0.2 |
| Badlands | 0.2 | 0.1 | 0.1 | 0.3 | 0.2 | 0.3 |
| Lakes, % of the planet | 0.7 | 0.4 | 1.6 | 0.6 | 0.2 | 0.3 |

### C on A: erosion on today's ground

| Biome | Seed 7 | Seed 11 | Seed 23 | Seed 42 | Seed 101 | Seed 2026 |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Land, % of the planet** | **61.2** | **83.6** | **58.5** | **82.4** | **61.1** | **69.6** |
| Ice sheet | 14.7 | 13.7 | 14.0 | 17.4 | 10.7 | 18.2 |
| Grassland | 11.2 | 17.3 | 10.8 | 18.9 | 10.7 | 11.6 |
| Savanna | 11.2 | 11.2 | 19.5 | 3.3 | 15.1 | 16.1 |
| Temperate forest | 11.0 | 8.7 | 9.8 | 18.3 | 12.1 | 5.7 |
| Shrubland | 8.3 | 7.3 | 7.4 | 7.4 | 10.2 | 9.8 |
| Tropical dry forest | 10.1 | 7.7 | 11.1 | 0.8 | 10.5 | 9.8 |
| Hot desert | 8.5 | 6.5 | 7.1 | 4.8 | 9.2 | 7.9 |
| Alpine | 5.8 | 10.3 | 2.7 | 11.7 | 0.9 | 5.2 |
| Boreal forest | 5.7 | 5.4 | 4.8 | 7.0 | 6.4 | 4.5 |
| Beach and coast | 5.1 | 1.2 | 6.6 | 1.0 | 7.0 | 4.4 |
| Snowcap | 1.6 | 4.1 | 1.5 | 3.8 | - | 2.2 |
| Cold steppe | 2.0 | 3.8 | 1.2 | 3.3 | 0.8 | 0.4 |
| Tundra | 1.6 | 2.2 | 2.2 | 1.9 | 2.2 | 0.7 |
| Wetland | 1.0 | 0.1 | 0.9 | 0.1 | 1.0 | 2.5 |
| Tropical rainforest | 1.5 | 0.1 | 0.3 | - | 2.2 | 0.5 |
| Temperate rainforest | 0.6 | 0.4 | 0.2 | 0.2 | 1.2 | 0.3 |
| Badlands | - | - | - | 0.1 | - | - |
| Lakes, % of the planet | 0.1 | 0.3 | - | 2.9 | 0.2 | 0.1 |

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
| 7 | 2 | yes | 74.7 | 11 | 34 | 2 | 29,856 | 0.6 | 0 | 0 | -1,948 to 4,319 | Tropical dry forest 19.8, Savanna 18.9, Ice sheet 18.2, Hot desert 9.7, Shrubland 7.3, Temperate forest 6.8, Boreal forest 5.8, Grassland 3.9, Tundra 3.6, Tropical rainforest 3.1, Beach and coast 1.2 |
| 11 | 0 | yes | 80.2 | 13 | 51 | 2 | 14,784 | 10.7 | 0 | 0 | -1,938 to 5,923 | Ice sheet 26.9, Temperate forest 12.9, Alpine 12.3, Shrubland 9, Grassland 8.2, Boreal forest 5.5, Tropical dry forest 5.4, Savanna 4.9, Cold steppe 4.5, Tundra 4.4, Hot desert 2.9, Tropical rainforest 1.9, Snowcap 1.1 |
| 23 | 2 | yes | 61.2 | 6 | 24 | 8 | 33,376 | 0 | 0 | 0 | -354 to 3,127 | Tropical dry forest 32.1, Savanna 25.5, Grassland 15.4, Temperate forest 11.2, Beach and coast 9.7, Wetland 6.1 |
| 42 | 0 | yes | 74.7 | 12 | 49 | 4 | 18,400 | 13.8 | 0 | 0 | -1,055 to 5,585 | Ice sheet 29.3, Temperate forest 22.7, Alpine 13, Grassland 12, Boreal forest 7.2, Snowcap 5.4, Tundra 3, Hot desert 1.9, Shrubland 1.5, Temperate rainforest 1.2, Cold steppe 1.1, Savanna 1.1 |
| 101 | 0 | yes | 72.4 | 9 | 47 | 8 | 19,424 | 0 | 0 | 0 | -1,678 to 1,836 | Temperate forest 19.4, Shrubland 18.6, Tropical dry forest 15.5, Savanna 14.4, Grassland 13.2, Beach and coast 5.3, Hot desert 5.2, Wetland 4.4, Tropical rainforest 3.8 |
| 2026 | 0 | yes | 77.8 | 14 | 52 | 4 | 31,136 | 3.5 | 0 | 0 | -1,647 to 2,954 | Savanna 19.4, Ice sheet 13.8, Grassland 12.1, Temperate forest 9, Hot desert 7.6, Shrubland 7.4, Wetland 6.2, Tropical dry forest 5.9, Boreal forest 5.5, Alpine 4.5, Tropical rainforest 2.8, Beach and coast 2.7, Tundra 1.8, Temperate rainforest 1.3 |

### B: plates and climate

| Seed | Ring | Met | Land % | Biomes | Changes | Coasts | Longest (units) | Mountain % | Rivers | Lakes | Heights | The ring's land, by share |
| ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- | :--- |
| 7 | 1 | yes | 53.8 | 11 | 83 | 10 | 19,360 | 5.1 | 0 | 0 | -4,062 to 7,059 | Temperate forest 29.5, Boreal forest 18.7, Grassland 15.7, Ice sheet 8.7, Snowcap 4.9, Alpine 4.6, Tundra 4.2, Shrubland 4, Cold steppe 3.6, Hot desert 3.3, Savanna 1.1 |
| 11 | 1 | yes | 60.7 | 11 | 76 | 10 | 20,960 | 0.4 | 0 | 0 | -2,379 to 5,562 | Ice sheet 22.5, Tropical dry forest 13.4, Grassland 13.4, Tropical rainforest 10.2, Savanna 8.4, Boreal forest 8, Shrubland 7.8, Temperate forest 6, Hot desert 4.1, Tundra 3.3, Temperate rainforest 1.9 |
| 23 | 2 | yes | 54.8 | 7 | 42 | 2 | 68,992 | 0 | 0 | 0 | -2,423 to 3,764 | Tropical dry forest 27.4, Temperate forest 23.7, Temperate rainforest 19.3, Savanna 16.6, Grassland 7, Tropical rainforest 3.8, Shrubland 2.1 |
| 42 | 1 | yes | 50.2 | 11 | 94 | 12 | 35,680 | 10.2 | 0 | 0 | -5,003 to 4,827 | Temperate forest 19.4, Alpine 16.9, Temperate rainforest 14.6, Grassland 12.4, Shrubland 8.8, Boreal forest 7, Savanna 4.9, Tropical dry forest 4.7, Hot desert 3.9, Snowcap 3.4, Cold steppe 1.4 |
| 101 | 10 | yes | 59.7 | 8 | 48 | 6 | 28,992 | 1.8 | 0 | 0 | -3,131 to 6,012 | Temperate rainforest 33.3, Tropical dry forest 30.2, Tropical rainforest 16, Savanna 10.9, Temperate forest 3.3, Alpine 2.5, Grassland 1.5, Beach and coast 1.2 |
| 2026 | 2 | yes | 57.5 | 13 | 64 | 6 | 17,824 | 0.5 | 0 | 0 | -4,128 to 3,489 | Ice sheet 20.2, Grassland 13.5, Hot desert 11.9, Savanna 7.9, Temperate forest 7.7, Tropical dry forest 7.5, Temperate rainforest 6.4, Cold steppe 5.1, Shrubland 4.6, Tropical rainforest 4.4, Boreal forest 4.2, Volcanic field 2.7, Tundra 2.6 |

### C: erosion on B

| Seed | Ring | Met | Land % | Biomes | Changes | Coasts | Longest (units) | Mountain % | Rivers | Lakes | Heights | The ring's land, by share |
| ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- | :--- |
| 7 | 1 | yes | 53.1 | 12 | 85 | 16 | 19,360 | 5.4 | 10 | 3 | -4,062 to 6,662 | Temperate forest 29.8, Boreal forest 17.9, Grassland 16.2, Ice sheet 8, Snowcap 5.6, Alpine 4.6, Shrubland 4, Tundra 3.9, Cold steppe 3.6, Hot desert 3.2, Beach and coast 1.2, Savanna 1.2 |
| 11 | 1 | yes | 59.9 | 11 | 77 | 12 | 20,864 | 0.6 | 16 | 1 | -2,379 to 5,230 | Ice sheet 22.7, Tropical dry forest 13.5, Grassland 13.2, Tropical rainforest 10.1, Boreal forest 8.3, Savanna 8.2, Shrubland 7.3, Temperate forest 5.8, Hot desert 4.1, Tundra 3.4, Temperate rainforest 1.6 |
| 23 | 2 | yes | 51.4 | 7 | 40 | 4 | 68,896 | 0 | 17 | 1 | -2,423 to 3,553 | Temperate forest 25.4, Tropical dry forest 23.2, Temperate rainforest 19.4, Savanna 18.2, Grassland 7.3, Tropical rainforest 4.2, Shrubland 2.3 |
| 42 | 3 | yes | 56 | 10 | 69 | 10 | 38,176 | 9.4 | 12 | 0 | -4,006 to 3,449 | Temperate forest 31.8, Temperate rainforest 19.4, Alpine 15.3, Grassland 12.7, Boreal forest 5.6, Shrubland 5.5, Volcanic field 2.6, Hot desert 2.4, Snowcap 1.5, Tropical dry forest 1.4 |
| 101 | 0 | yes | 56 | 9 | 54 | 6 | 30,496 | 1.7 | 9 | 0 | -3,604 to 4,788 | Temperate rainforest 28.1, Temperate forest 19.6, Grassland 14, Savanna 12.3, Cold steppe 8.4, Hot desert 7.8, Boreal forest 4.1, Alpine 2.9, Wetland 1 |
| 2026 | 2 | yes | 57.4 | 13 | 69 | 8 | 17,728 | 0.6 | 13 | 1 | -4,128 to 3,460 | Ice sheet 20.1, Grassland 13.5, Hot desert 12.1, Tropical dry forest 8.7, Savanna 8.1, Temperate forest 7.2, Temperate rainforest 6.2, Cold steppe 5, Shrubland 4.4, Boreal forest 4, Tropical rainforest 3.5, Volcanic field 2.7, Tundra 2.6 |

### C on A: erosion on today's ground

| Seed | Ring | Met | Land % | Biomes | Changes | Coasts | Longest (units) | Mountain % | Rivers | Lakes | Heights | The ring's land, by share |
| ---: | ---: | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | :--- | :--- |
| 7 | 1 | yes | 58.8 | 10 | 59 | 8 | 19,552 | 4 | 13 | 0 | -2,052 to 4,545 | Grassland 17.4, Temperate forest 15.1, Boreal forest 13.6, Hot desert 12.7, Savanna 11.9, Shrubland 10.4, Alpine 6.7, Beach and coast 6.3, Tundra 4.6, Temperate rainforest 1.4 |
| 11 | 0 | yes | 79.2 | 13 | 55 | 6 | 14,784 | 10.6 | 13 | 2 | -1,938 to 5,916 | Ice sheet 27.1, Temperate forest 13.1, Alpine 12.3, Shrubland 9.3, Grassland 8, Tropical dry forest 6, Savanna 5.2, Cold steppe 4.6, Tundra 4.6, Boreal forest 4.3, Hot desert 3, Tropical rainforest 1.4, Snowcap 1.1 |
| 23 | 2 | yes | 61.2 | 6 | 26 | 8 | 33,376 | 0 | 7 | 0 | -354 to 3,088 | Tropical dry forest 31.9, Savanna 25.7, Grassland 15.4, Temperate forest 10.9, Beach and coast 10, Wetland 6.1 |
| 42 | 0 | yes | 72.8 | 12 | 52 | 6 | 18,400 | 13.7 | 6 | 1 | -1,055 to 5,573 | Ice sheet 29.9, Temperate forest 22.7, Alpine 13.3, Grassland 10.3, Boreal forest 7.3, Snowcap 5.6, Tundra 3, Hot desert 1.9, Shrubland 1.5, Savanna 1.2, Cold steppe 1.1, Temperate rainforest 1.1 |
| 101 | 0 | yes | 72.4 | 9 | 48 | 8 | 19,424 | 0 | 27 | 0 | -1,678 to 1,798 | Temperate forest 19.1, Shrubland 18.6, Tropical dry forest 15.7, Savanna 14.2, Grassland 13.2, Beach and coast 6, Hot desert 5.2, Wetland 4.2, Tropical rainforest 3.7 |
| 2026 | 0 | yes | 77.8 | 14 | 56 | 4 | 31,136 | 3.3 | 18 | 0 | -1,647 to 2,946 | Savanna 18.4, Ice sheet 13.7, Grassland 12.1, Temperate forest 9.1, Hot desert 7.7, Shrubland 7.4, Tropical dry forest 6, Wetland 5.9, Boreal forest 5.4, Alpine 4.3, Beach and coast 4.1, Tropical rainforest 3.1, Tundra 1.9, Temperate rainforest 1 |

## 3. Cost per seed (JS, this PC)

Ring: the 4,800 columns read cold (the climate memo emptied), best of 5. Today: WorldPlanet's function on the same ring in the same run. Set-up: the per-planet work before the first read (approach C's grid).

| Approach | Seed 7 | Seed 11 | Seed 23 | Seed 42 | Seed 101 | Seed 2026 | Median |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Today (WorldPlanet): ring, times today | 1.01 | 1.07 | 1.1 | 0.85 | 1.01 | 1.39 | 1.0 |
| A: climate table: ring, times today | 2.04 | 1.82 | 2.1 | 1.59 | 2.73 | 1.48 | 1.9 |
| B: plates and climate: ring, times today | 3.99 | 3.81 | 6.94 | 4.45 | 9.43 | 3.14 | 4.2 |
| C: erosion on B: ring, times today | 5.29 | 4.04 | 4.32 | 7.04 | 7.19 | 3.59 | 4.8 |
| C: erosion on B: set-up, ms | 470 | 322 | 457 | 577 | 375 | 401 | 429 |
| C on A: erosion on today's ground: ring, times today | 2.31 | 2.22 | 2.67 | 1.72 | 3.79 | 2.2 | 2.3 |
| C on A: erosion on today's ground: set-up, ms | 275 | 366 | 253 | 413 | 262 | 363 | 319 |
