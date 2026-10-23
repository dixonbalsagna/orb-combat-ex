// The erosion grid's cost against its size (approach C), on two grounds, against today's 4,800-column slice read.
//   node research/planet-gen/costs.mjs [seed]
import { performance } from 'node:perf_hooks';
import { buildErosion, PC } from './gen/erosion.mjs';
import { makeClimate, PA } from './gen/climate.mjs';
import { makePlates, plateGround } from './gen/plates.mjs';
import { ground, groundCoarse, surf } from './gen/base.mjs';
import { withPoles } from './gen/poles.mjs';
import { sin, cos } from './lib/det.mjs';

const seed = Number(process.argv[2] || 7);
function todaySliceMs() {
  let best = 1e18;
  for (let r = 0; r < 3; r++) {
    const t0 = performance.now();
    for (let i = 0; i < 4800; i++) { const a = i * 6.283185307179586 / 4800; surf(seed, cos(a) * 0.8, 0.6, sin(a) * 0.8); }
    best = Math.min(best, performance.now() - t0);
  }
  return best;
}
const slice = todaySliceMs();
console.log(`today's slice (4,800 columns) in JS: ${slice.toFixed(2)} ms`);
const S = makePlates(seed);
const grounds = {
  plates: [withPoles((s, x, y, z) => plateGround(S, x, y, z)), withPoles((s, x, y, z) => plateGround(S, x, y, z, true))],
  today: [withPoles(ground), withPoles(groundCoarse)],
};
const rows = [];
for (const [name, [g, gm]] of Object.entries(grounds)) {
  for (const N of [32, 48, 64, 96, 128]) {
    const clim = makeClimate(g, PA, gm);
    const t0 = performance.now();
    const E = buildErosion((x, y, z) => g(seed, x, y, z), (x, y, z, h) => clim.precip(seed, x, y, z, h), { ...PC, N });
    const ms = performance.now() - t0;
    const r = { ground: name, N, cells: E.cells, cellUnits: Math.round(153600 / (4 * N)), ms: +ms.toFixed(0), slicesOfToday: +(ms / slice).toFixed(1), ...Object.fromEntries(Object.entries(E.t).map(([k, v]) => [k, +v.toFixed(0)])), riverCells: E.riverCells };
    rows.push(r);
    console.log(JSON.stringify(r));
  }
}
