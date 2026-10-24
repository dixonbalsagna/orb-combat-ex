// A steadier per-column cost than run.mjs's: for each seed, the approach's fight ring and today's function on the same
// ring are read alternately (the approach cold: memos emptied), 7 pairs; the ratio is the median of the pairs. Also a
// fingerprint of what the ring reads (FNV-1a over the height bits, biome and flag of all 4,800 columns), so an
// optimisation can show it changed nothing. Octaves: the noise octaves a column reads (det.mjs OCT_COUNT), against today's.
//   node research/planet-gen/bench-ring.mjs <approach> [seeds, default 7,11,23,42,101,2026]
import { performance } from 'node:perf_hooks';
import { APPROACHES } from './gen/index.mjs';
import { pickRing, readRing } from './lib/render.mjs';
import { surf } from './gen/base.mjs';
import { FROM_BASE } from './lib/biomes.mjs';
import { NC, OCT_COUNT, resetOct } from './lib/det.mjs';

const key = process.argv[2], seeds = (process.argv[3] || '7,11,23,42,101,2026').split(',').map(Number);
const A = APPROACHES[key];
const f64 = new Float64Array(1), u32 = new Uint32Array(f64.buffer);
function fnv(S) {
  let h = 0x811c9dc5;
  const mix = (v) => { h ^= v & 0xff; h = Math.imul(h, 0x01000193); h ^= (v >>> 8) & 0xff; h = Math.imul(h, 0x01000193); h ^= (v >>> 16) & 0xff; h = Math.imul(h, 0x01000193); h ^= v >>> 24; h = Math.imul(h, 0x01000193); };
  for (let i = 0; i < NC; i++) { f64[0] = S.h[i]; mix(u32[0]); mix(u32[1]); mix(S.b[i]); mix(S.f[i]); }
  return (h >>> 0).toString(16).padStart(8, '0');
}
const med = (a) => { const s = [...a].sort((x, y) => x - y); return s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2; };
const ratios = [], octs = [];
for (const seed of seeds) {
  const st = A.init(seed), sample = (x, y, z) => A.sample(st, x, y, z);
  const today = (x, y, z) => { const r = surf(seed, x, y, z); return [r[0], FROM_BASE[r[1]], 0]; };
  const { ring, k } = pickRing(seed, sample);
  const forget = () => { if (st.clim && st.clim.forget) st.clim.forget(); };
  forget(); resetOct(); const fp = fnv(readRing(ring, sample)); const octA = OCT_COUNT / NC;
  resetOct(); readRing(ring, today); const octT = OCT_COUNT / NC; octs.push(octA / octT);
  const pairs = [];
  for (let r = 0; r < 7; r++) {
    let t0 = performance.now(); readRing(ring, today); const tt = performance.now() - t0;
    forget(); t0 = performance.now(); readRing(ring, sample); const ta = performance.now() - t0;
    pairs.push(ta / tt);
  }
  const m = med(pairs); ratios.push(m);
  console.log(`${key} seed ${seed} ring ${k}: ${m.toFixed(2)} times today per column (pairs ${pairs.map((p) => p.toFixed(2)).join(' ')})  octaves ${octA.toFixed(1)} (today ${octT.toFixed(1)})  fingerprint ${fp}`);
}
console.log(`${key}: median ${med(ratios).toFixed(2)} times today per column; octaves ${med(octs).toFixed(2)} times today's (the noise work, which scales to GDScript)`);
