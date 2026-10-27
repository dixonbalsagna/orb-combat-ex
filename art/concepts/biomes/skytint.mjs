// Origin: how far a fixed per-planet sky tint from the dominant biome would move the horizon (deterministic). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-27.
import { readFileSync } from 'node:fs';
import { dE00, mixOklab } from '../sky/colour.mjs';
import { orbitHex } from './derive.mjs';
const d = JSON.parse(readFileSync(new URL('../../../data/art/biomes.json', import.meta.url), 'utf8'));
for (const [id, b] of Object.entries(d.biomes)) { const h = b.palette.sky_noon.horizon, o = orbitHex(id); console.log(id.padEnd(10), [0.06, 0.1, 0.15].map(k => k + ': ' + dE00(h, mixOklab(h, o, k)).toFixed(1)).join('  ')); }
