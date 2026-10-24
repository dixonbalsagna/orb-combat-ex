// Origin: a trial helper that scores candidate lane colours on the whole sprite (deterministic). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-24.
import { simulate, dE00 } from '../sky/colour.mjs';
import { WORLD, tinted } from '../sky/world.mjs';
import { KEYS } from '../sky/keys.mjs';
import { BIOMES } from '../biomes/spec.mjs';
import { tonesOf } from '../biomes/measure.mjs';
export const KEYLINE = '#0a0d14';
const T = []; for (const [id, b] of Object.entries(BIOMES)) for (const [name, hex, layer] of tonesOf(b)) for (const k of KEYS) T.push({ id, name, key: k.id, c: tinted(hex, WORLD[k.id][layer]) });
export function whole(parts, vision = 'default') { // parts: hex list; per tone the best-separated part wins
  const P = parts.map(h => simulate(h, vision)); const out = {};
  for (const t of T) { const s = simulate(t.c, vision); let best = 0; for (const p of P) best = Math.max(best, dE00(p, s)); if (!out[t.id] || best < out[t.id].min) out[t.id] = { min: +best.toFixed(1), at: t.name + ' ' + t.key }; }
  return out;
}
export function worst(parts, vision) { const r = whole(parts, vision); const e = Object.entries(r).sort((a, b) => a[1].min - b[1].min)[0]; return { min: e[1].min, id: e[0], at: e[1].at }; }
if (process.argv[2]) { const parts = process.argv.slice(2); for (const v of ['default', 'protan', 'deutan', 'tritan']) { const w = worst(parts, v); console.log(v.padEnd(7), w.min, w.id, w.at); } }
