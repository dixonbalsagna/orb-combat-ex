// Today's planet (sim/world/planet.gd: ground, _plainBiome, surfAt with the ice), ported expression for expression so it
// reads the same bits as WorldPlanet; check-base.mjs proves it against sim/world/tools/planet_vectors.json. It is the
// reference every approach is compared with, and approach A reuses its ground().
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { R, fbm, ss, lat, pow } from '../lib/det.mjs';

const C = JSON.parse(readFileSync(fileURLToPath(new URL('../../../data/biomes/planet.json', import.meta.url)), 'utf8'));
export const CFG = C;
export const BIO = { OCEAN: 0, PLAINS: 1, FOREST: 2, DESERT: 3, MOUNTAINS: 4, ICE_SHEET: 5, SEA_ICE: 6 };

export function ground(seed, px, py, pz, contOct = C.contOct, reliefOct = C.reliefOct) {
  const e = (fbm(px, py, pz, C.contScale, contOct, seed) - 0.5) * 2.0;
  let h = (e + C.seaShift) * C.hMul;
  if (e > C.rangeFrom) {
    const m = fbm(px, py, pz, C.reliefScale, reliefOct, seed + C.sRelief);
    h += (e - C.rangeFrom) * C.rangeMul * (C.reliefBase + m);
  }
  return h;
}

function plainBiome(seed, px, py, pz, h) {
  if (h < 0.0) return BIO.OCEAN;
  if (h > C.mountainAbove) return BIO.MOUNTAINS;
  const w = fbm(px, py, pz, C.wetScale, C.wetOct, seed + C.sWet);
  const t = 1.0 - Math.abs(py) * C.tempLat + (fbm(px, py, pz, C.tempScale, C.tempOct, seed + C.sTemp) - 0.5) * C.tempNoise;
  if (w < C.desertWet && t > C.desertTemp) return BIO.DESERT;
  if (w > C.forestWet) return BIO.FOREST;
  return BIO.PLAINS;
}

// planet.gd _worley (the cell cache there is a memo; this recomputes, the same numbers).
function worley(px, py, pz, cell, s) {
  const k = R / cell;
  const qx = px * k, qy = py * k, qz = pz * k;
  const ix = Math.floor(qx) | 0, iy = Math.floor(qy) | 0, iz = Math.floor(qz) | 0;
  let best = 1.0e9, br = 0.0;
  for (let dx = -1; dx < 2; dx++) for (let dy = -1; dy < 2; dy++) for (let dz = -1; dz < 2; dz++) {
    const cx = ix + dx, cy = iy + dy, cz = iz + dz;
    const f0 = cx + lat(cx, cy, cz, s), f1 = cy + lat(cx, cy, cz, s + 11), f2 = cz + lat(cx, cy, cz, s + 23), f3 = lat(cx, cy, cz, s + 37);
    const d = Math.sqrt((f0 - qx) * (f0 - qx) + (f1 - qy) * (f1 - qy) + (f2 - qz) * (f2 - qz));
    if (d < best) { best = d; br = f3; }
  }
  return [best, br];
}

// planet.gd surfAt: [height, biome] at a unit vector. groundFn (default today's ground) lets an approach keep the
// canon poles (the north pack, the south sheet: planet-ice.md) over its own ground; plainFn picks the ordinary biomes.
export function surf(seed, px, py, pz, groundFn = ground, plainFn = plainBiome) {
  const s = seed, y = py;
  const base = groundFn(seed, px, py, pz);
  if (Math.abs(y) < C.polarY) return [base, plainFn(seed, px, py, pz, base)];
  if (y > 0.0) {
    const wN = ss((y - C.polarY) / C.blend);
    const sea = C.seaNorth + (fbm(px, py, pz, C.seaNoiseScale, C.seaNoiseOct, s + C.sSea) - 0.5) * C.seaNoiseAmp;
    const conc = (y - C.packEdgeY) / C.packWidth + (fbm(px, py, pz, C.packNoiseScale, C.packNoiseOct, s + C.sPackEdge) - 0.5) * C.packNoiseAmp;
    if (conc > C.packMin) {
      const [wd, wr] = worley(px, py, pz, C.floeCell, s + C.sFloe);
      let cc = conc;
      if (cc < 0.0) cc = 0.0;
      if (cc > 1.0) cc = 1.0;
      if (wr < pow(cc, C.floePow) * C.floeCap && wd < C.floeR0 + C.floeR1 * cc)
        return [(C.floeH0 + C.floeH1 * wr) * (C.floeThin0 + C.floeThin1 * cc), BIO.SEA_ICE];
    }
    if (conc > C.bergBandLo && conc < C.bergBandHi) {
      const [wd, wr] = worley(px, py, pz, C.bergCell, s + C.sBerg);
      let dm = Math.abs(conc - C.bergBandMid) * C.bergBandSlope;
      if (dm > 1.0) dm = 1.0;
      const rate = C.bergRate * (1.0 - dm);
      if (wr < rate && wd < C.bergRadius) return [C.bergH0 + C.bergH1 * (wr / (rate > 0.001 ? rate : 0.001)), BIO.SEA_ICE];
    }
    const h = base + (sea - base) * wN;
    return [h, wN >= 1.0 ? BIO.OCEAN : plainFn(seed, px, py, pz, h)];
  }
  const ys = -y;
  const wS = ss((ys - C.polarY) / C.blend);
  const seaS = C.seaSouth + (fbm(px, py, pz, C.seaNoiseScale, C.seaNoiseOct, s + C.sSea) - 0.5) * C.seaNoiseAmp;
  const m = (ys - C.southMaskY) / C.southWidth + (fbm(px, py, pz, C.southMaskScale, C.southMaskOct, s + C.sSouthMask) - 0.5) * C.southMaskAmp;
  if (m > 0.0) {
    const mm = m < C.domeMax ? m : C.domeMax;
    let h = C.domeBase + mm * C.domeMul + (fbm(px, py, pz, C.domeReliefScale, C.domeReliefOct, s + C.sSouthRelief) - 0.5) * C.domeReliefAmp;
    if (h < C.shelfH) h = C.shelfH;
    let b = BIO.ICE_SHEET;
    if (h > C.rockHeight && fbm(px, py, pz, C.rockScale, C.rockOct, s + C.sRock) > C.rockNoise) b = BIO.MOUNTAINS;
    return [h, b];
  }
  if (m > C.shelfFrom)
    return [C.shelfH + (fbm(px, py, pz, C.shelfNoiseScale, C.shelfNoiseOct, s + C.sShelf) - 0.5) * C.shelfNoiseAmp, BIO.ICE_SHEET];
  if (m > C.southBergFrom) {
    const [wd, wr] = worley(px, py, pz, C.bergCell, s + C.sBerg);
    if (wr < C.southBergRate && wd < C.bergRadius) return [C.bergH0 + C.bergH1 * (wr / C.southBergRate), BIO.SEA_ICE];
  }
  const h = base + (seaS - base) * wS;
  return [h, wS >= 1.0 ? BIO.OCEAN : plainFn(seed, px, py, pz, h)];
}

// A low-pass ground for the climate's upwind march: the continents and the ranges' broad shape, no single peaks (a peak
// sampled every 1,800 units would cast a thin shadow line along the wind).
export function groundCoarse(seed, px, py, pz) { return ground(seed, px, py, pz, 3, 1); }
