// The climate's lean path (each noise drawn only while it can still change the biome) must give the full path's height
// and biome to the bit: 20,000 random points a planet, A's climate and B's.
//   node research/planet-gen/check-lean.mjs
import { APPROACHES } from './gen/index.mjs';
import { randUnit } from './lib/det.mjs';

let bad = 0, n = 0;
for (const seed of [7, 23, 2026]) {
  for (const k of ['A', 'B']) {
    const st = APPROACHES[k].init(seed), clim = st.clim;
    for (let i = 0; i < 20000; i++) {
      const p = randUnit(seed * 31 + 7, 77, i);
      let lean, full;
      if (k === 'A') { lean = clim.sample(seed, p[0], p[1], p[2]); full = clim.sample(seed, p[0], p[1], p[2], undefined, true); }
      else { const h = st.g(seed, p[0], p[1], p[2]); lean = [h, clim.biome(seed, p[0], p[1], p[2], h)]; full = clim.sample(seed, p[0], p[1], p[2], h, true); }
      n++;
      if (!Object.is(lean[0], full[0]) || lean[1] !== full[1]) { bad++; if (bad < 5) console.log('MISMATCH', k, seed, p, lean.slice(0, 2), full.slice(0, 2)); }
    }
  }
}
console.log(`lean against full: ${n - bad} of ${n} points give the same height and biome`);
process.exit(bad ? 1 : 0);
