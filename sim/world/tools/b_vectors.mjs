// World, window 12: the JS reference for sim/world/tools/b_check.gd: Research's makePlates and plateGround (research/planet-gen/gen/plates.mjs, unchanged) at seeded points, written as JSON that b_check.gd compares with the GDScript port.
//   node sim/world/tools/b_vectors.mjs > sim/world/tools/b_vectors.json
// The points are drawn with det.mjs randUnit(seed, 9999, k) and kept where the polar fade reads plain y (-0.4 <= y <= 0.3: poles.mjs's warp is not applied by the port, which has the stored polar edge).
import { makePlates, plateGround } from '../../../research/planet-gen/gen/plates.mjs';
import { randUnit } from '../../../research/planet-gen/lib/det.mjs';
const out = { _about: 'JS reference for b_check.gd (made by b_vectors.mjs from research/planet-gen/gen/plates.mjs): per seed the crust lift, the cells\' plates and the first cell centre, and h and volc at the points randUnit(seed, 9999, k) with -0.4 <= y <= 0.3, in order.', seeds: [] };
for (const seed of [3, 7, 123456]) {
  const S = makePlates(seed);
  const pts = [];
  for (let k = 0; pts.length < 240 && k < 100000; k++) {
    const p = randUnit(seed, 9999, k);
    if (p[1] < -0.4 || p[1] > 0.3) continue;
    const h = plateGround(S, p[0], p[1], p[2]);
    pts.push([k, h, S.volc]);
  }
  out.seeds.push({ seed, lift: S.lift, plate: S.plate, c0: S.c[0], hot0: S.hot[0], pts });
}
console.log(JSON.stringify(out));
