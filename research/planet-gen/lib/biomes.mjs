// The master biome list every approach draws from (ids are this prototype's, not the game's). WATER marks the ones that
// are not land, for the land shares. Colours are picture colours only.
export const BIOMES = [
  // id, key, name, rgb, water
  [0, 'DEEP', 'Deep ocean', [22, 48, 102], 1],
  [1, 'SEA', 'Shallow sea', [40, 96, 160], 1],
  [2, 'SEA_ICE', 'Sea ice', [214, 228, 238], 1],
  [3, 'BEACH', 'Beach and coast', [224, 208, 152], 0],
  [4, 'ICE_SHEET', 'Ice sheet', [238, 244, 250], 0],
  [5, 'TUNDRA', 'Tundra', [146, 156, 128], 0],
  [6, 'BOREAL', 'Boreal forest', [50, 88, 68], 0],
  [7, 'STEPPE', 'Cold steppe', [176, 170, 120], 0],
  [8, 'GRASSLAND', 'Grassland', [136, 172, 78], 0],
  [9, 'SHRUBLAND', 'Shrubland', [164, 150, 92], 0],
  [10, 'TEMP_FOREST', 'Temperate forest', [62, 124, 54], 0],
  [11, 'TEMP_RAIN', 'Temperate rainforest', [32, 96, 62], 0],
  [12, 'DESERT', 'Hot desert', [230, 196, 128], 0],
  [13, 'SAVANNA', 'Savanna', [192, 180, 88], 0],
  [14, 'TROP_SEASONAL', 'Tropical dry forest', [112, 148, 48], 0],
  [15, 'TROP_RAIN', 'Tropical rainforest', [26, 108, 40], 0],
  [16, 'WETLAND', 'Wetland', [78, 118, 98], 0],
  [17, 'ALPINE', 'Alpine', [136, 126, 112], 0],
  [18, 'SNOW', 'Snowcap', [250, 250, 252], 0],
  [19, 'VOLCANIC', 'Volcanic field', [72, 58, 60], 0],
  [20, 'RIVER', 'River', [64, 128, 206], 1],
  [21, 'LAKE', 'Lake', [56, 112, 178], 1],
  [22, 'BADLANDS', 'Badlands', [184, 112, 72], 0],
  [23, 'ROCK', 'Mountain rock', [128, 118, 108], 0],
];
export const B = Object.fromEntries(BIOMES.map((b) => [b[1], b[0]]));
export const COLOR = BIOMES.map((b) => b[3]);
export const NAME = BIOMES.map((b) => b[2]);
export const IS_WATER = BIOMES.map((b) => b[4] === 1);
// Today's 7 biomes (WorldPlanet) in this list's colours.
export const FROM_BASE = [B.SEA, B.GRASSLAND, B.TEMP_FOREST, B.DESERT, B.ROCK, B.ICE_SHEET, B.SEA_ICE];
