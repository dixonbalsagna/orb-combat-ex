// Origin: a search helper for the energy lanes (deterministic). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-24.
// Run: node art/concepts/energy/search.mjs hues   -> for every hue, the main colour with the most readability headroom over the 15 biomes (default 20, simulated 14).
import { toOklab, fromOklab, simulate, dE00, hex2rgb } from '../sky/colour.mjs';
import { WORLD, tinted } from '../sky/world.mjs';
import { KEYS } from '../sky/keys.mjs';
import { BIOMES } from '../biomes/spec.mjs';
import { tonesOf } from '../biomes/measure.mjs';
import { redShare } from './lanes.mjs';

export const VIS = ['default', 'protan', 'deutan', 'tritan'], NEED = { default: 20, protan: 14, deutan: 14, tritan: 14 };
const SIM = Object.fromEntries(VIS.map(v => [v, []]));
const seen = new Set();
for (const [id, b] of Object.entries(BIOMES)) for (const [name, hex, layer] of tonesOf(b)) for (const k of KEYS) { const c = tinted(hex, WORLD[k.id][layer]); if (seen.has(c)) continue; seen.add(c); for (const v of VIS) SIM[v].push(simulate(c, v)); }
export const headroom = hex => { const r = {}; for (const v of VIS) { const m = simulate(hex, v); let lo = 99; for (const t of SIM[v]) { const d = dE00(m, t); if (d < lo) lo = d; } r[v] = lo; } return r; };
export const score = r => Math.min(...VIS.map(v => r[v] / NEED[v]));
export const inGamut = ([L, a, b]) => { const c = fromOklab([L, a, b]); const back = toOklab(c); return Math.hypot(back[1] - a, back[2] - b) < 0.004 && L > 0.05; };
export function bestAt(hue, Ls = [0.5, 0.95], Cs = [0.06, 0.3], opts = {}) {
  let best = null;
  for (let L = Ls[0]; L <= Ls[1] + 1e-6; L += 0.03) for (let C = Cs[0]; C <= Cs[1] + 1e-6; C += 0.02) {
    const lab = [L, C * Math.cos(hue * Math.PI / 180), C * Math.sin(hue * Math.PI / 180)]; if (!inGamut(lab)) continue;
    const hex = fromOklab(lab), rs = redShare(hex); if (rs.linear >= 0.78 || rs.stored >= 0.78) continue;
    if (opts.ok && !opts.ok(hex)) continue;
    const r = headroom(hex), s = score(r); if (!best || s > best.s) best = { hex, s, r, L, C };
  }
  return best;
}
if (process.argv[2] === 'hues') for (let h = 0; h < 360; h += 10) { const b = bestAt(h); if (b) console.log(String(h).padStart(3), b.hex, 'score', b.s.toFixed(2), VIS.map(v => v[0] + b.r[v].toFixed(1)).join(' '), 'L', b.L.toFixed(2), 'C', b.C.toFixed(2)); }
if (process.argv[2] === 'band') { const [h0, h1, l0, l1, c0, c1] = process.argv.slice(3).map(Number); for (let h = h0; h <= h1; h += 5) { const b = bestAt(h, [l0, l1], [c0, c1]); if (b) console.log(String(h).padStart(3), b.hex, 'score', b.s.toFixed(2), VIS.map(v => v[0] + b.r[v].toFixed(1)).join(' '), 'L', b.L.toFixed(2), 'C', b.C.toFixed(2)); } }
