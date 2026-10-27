// Origin: a measuring helper for the far-land ladder's step contrast (deterministic). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-27.
import { readFileSync } from 'node:fs';
import { dE00, lchOf } from '../sky/colour.mjs';
const d = JSON.parse(readFileSync(new URL('../../../data/art/biomes.json', import.meta.url), 'utf8'));
const rows = [];
for (const [id, b] of Object.entries(d.biomes)) { const f = b.far_ladder, h = b.palette?.sky_noon?.horizon; const g = b.palette?.ground?.[1];
  rows.push([id, f.far1, f.far2, f.far3, h, +dE00(f.far1, f.far2).toFixed(1), +dE00(f.far2, f.far3).toFixed(1), +dE00(f.far3, h).toFixed(1), +dE00(f.far1, g).toFixed(1), +lchOf(f.far1)[0].toFixed(2), +lchOf(f.far3)[0].toFixed(2)]); }
console.log('id far1 far2 far3 horizon | 1-2 2-3 3-sky 1-ground | L1 L3'); for (const r of rows) console.log(r.join(' '));
