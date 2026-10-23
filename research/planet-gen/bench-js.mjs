// The JS side of the GDScript ratio: today's surface over the same 4,800 points as gdbench/surf_bench.gd (a circle at
// y = 0.6), best of 3, and the same checksum (the GDScript run printed sum 2450021.215 for seed 7, 25877850.853 for 11).
//   node research/planet-gen/bench-js.mjs
import { performance } from 'node:perf_hooks';
import { surf } from './gen/base.mjs';
import { sin, cos } from './lib/det.mjs';

for (const seed of [7, 11]) {
  let best = 1e18, sum = 0;
  for (let rep = 0; rep < 3; rep++) {
    const t0 = performance.now();
    for (let i = 0; i < 4800; i++) {
      const a = i * 6.283185307179586 / 4800.0;
      sum += surf(seed, cos(a) * 0.8, 0.6, sin(a) * 0.8)[0];
    }
    best = Math.min(best, performance.now() - t0);
  }
  console.log(`JSBENCH seed ${seed}: ${(best * 1000 / 4800).toFixed(3)} us/col (${best.toFixed(2)} ms for 4800) sum ${sum.toFixed(3)}`);
}
