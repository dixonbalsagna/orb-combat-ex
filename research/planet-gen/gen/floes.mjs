// Today's floes and bergs (planet.gd surfAt, planet-ice.md) on the climate's sea ice: the pack's concentration comes
// from how cold the sea is instead of from latitude, so the pack edge follows the climate and frays into floes, open
// leads and bergs instead of ending in a flat white cap. The cellular noise and the floe test are WorldPlanet's, with
// its numbers (data/biomes/planet.json).
import { R, lat, pow, clamp01 } from '../lib/det.mjs';
import { CFG as C } from './base.mjs';
import { B } from '../lib/biomes.mjs';

export const PF = {
  packT: -6.0, packSpan: 9.0,     // the pack starts where the sea is colder than packT (deg C) and is solid packSpan below it
  bergT: -1.0,                    // bergs drift out to seas this cold
  deepFloor: -1200.0,             // floes only on a shallower sea (today's pack sea is -380): a slice holds one height a
                                  // column, so a floe over deep water would stand as a pillar; there the climate's own
                                  // answer stands (sea ice at the sea's depth)
};

// planet.gd _worley: the distance to the nearest feature point (in cells) and that cell's random.
function worley(px, py, pz, cell, s) {
  const k = R / cell, qx = px * k, qy = py * k, qz = pz * k;
  const ix = Math.floor(qx) | 0, iy = Math.floor(qy) | 0, iz = Math.floor(qz) | 0;
  let best = 1.0e9, br = 0.0;
  for (let dx = -1; dx < 2; dx++) for (let dy = -1; dy < 2; dy++) for (let dz = -1; dz < 2; dz++) {
    const cx = ix + dx, cy = iy + dy, cz = iz + dz;
    const f0 = cx + lat(cx, cy, cz, s), f1 = cy + lat(cx, cy, cz, s + 11), f2 = cz + lat(cx, cy, cz, s + 23);
    const d = Math.sqrt((f0 - qx) * (f0 - qx) + (f1 - qy) * (f1 - qy) + (f2 - qz) * (f2 - qz));
    if (d < best) { best = d; br = lat(cx, cy, cz, s + 37); }
  }
  return [best, br];
}

// A sea point (h < 0) with sea-level temperature tsl: [height, biome] with floes, leads and bergs, or null to keep it.
export function floes(seed, px, py, pz, h, tsl, P = PF) {
  if (tsl > P.bergT || h < P.deepFloor) return null;
  const conc = (P.packT - tsl) / P.packSpan;
  if (conc > C.packMin) {
    const [wd, wr] = worley(px, py, pz, C.floeCell, seed + C.sFloe);
    const cc = clamp01(conc);
    if (wr < pow(cc, C.floePow) * C.floeCap && wd < C.floeR0 + C.floeR1 * cc)
      return [(C.floeH0 + C.floeH1 * wr) * (C.floeThin0 + C.floeThin1 * cc), B.SEA_ICE];
  }
  if (conc > C.bergBandLo && conc < C.bergBandHi) {
    const [wd, wr] = worley(px, py, pz, C.bergCell, seed + C.sBerg);
    let dm = Math.abs(conc - C.bergBandMid) * C.bergBandSlope;
    if (dm > 1.0) dm = 1.0;
    const rate = C.bergRate * (1.0 - dm);
    if (wr < rate && wd < C.bergRadius) return [C.bergH0 + C.bergH1 * (wr / (rate > 0.001 ? rate : 0.001)), B.SEA_ICE];
  }
  return [h, h > -450.0 ? B.SEA : B.DEEP];   // open water between floes (a lead)
}
