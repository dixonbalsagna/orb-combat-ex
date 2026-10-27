// Origin: derived colours of the biome look bible (the far land's value ladder, the orbit colours). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-23.
import { BIOMES } from './spec.mjs';
import { mix } from './draw.mjs';
import { dE00 } from '../sky/colour.mjs';

// the far land: each ridge is the biome's far base hazed toward its horizon, nearest first lightest-last (a value ladder)
// the two ices are authored: hazed from a pale base their three ridges were 1.7 to 1.9 CIEDE2000 apart (no read as steps); these are 6 to 8 apart like the other biomes, the nearest ridge 12 to 13 from the horizon, the farthest sinking into the haze (2026-10-27, Rendering's w3 look gate)
const PUSHED = { ice_sheet: ['#9cb0c0', '#bccad6', '#d8e2e8'], sea_ice: ['#90a8bb', '#b0c2d0', '#d0dbe4'] };
export function ladder(b) { if (PUSHED[b.id]) return PUSHED[b.id]; const base = ['peaks', 'mesas', 'cones'].includes(b.far.kind) ? b.pal.r[1] : ['shelf', 'floesfar'].includes(b.far.kind) ? b.pal.g[0] : mix(b.pal.v[1], b.pal.r[1], 0.25); return [0.26, 0.44, 0.6].map(k => mix(base, b.pal.sky[1], k)); }

// the orbit colour: what the biome reads as from far away. Authored per biome (a blend of its ground and its green or white cover), then 12 percent toward the atmosphere blue.
// Seen from orbit the fifteen must stay apart (a minimum pairwise CIEDE2000 is measured in gen.mjs and reported in the doc).
const ORBIT_BASE = {
  ocean: '#1f5a88', beach: '#dccf9c', plains: '#7db04f', savanna: '#a89c48', forest: '#2f7038', jungle: '#2f9048', wetland: '#4f8a78', desert: '#e2b472', mountains: '#8a8478', volcanic: '#46424e', tundra: '#a0a78a', taiga: '#3c6654', highland: '#8e7a78', ice_sheet: '#ebe8e2', sea_ice: '#bccbd8',
};
export function orbitHex(id) { return mix(ORBIT_BASE[id], '#a8cdee', id === 'ice_sheet' || id === 'sea_ice' ? 0.08 : 0.12); }
export function orbitSeparation() { const ids = Object.keys(BIOMES); let min = [99, '']; for (let i = 0; i < ids.length; i++) for (let j = i + 1; j < ids.length; j++) { const d = dE00(orbitHex(ids[i]), orbitHex(ids[j])); if (d < min[0]) min = [d, `${ids[i]} / ${ids[j]}`]; } return { min: +min[0].toFixed(1), pair: min[1] }; }
