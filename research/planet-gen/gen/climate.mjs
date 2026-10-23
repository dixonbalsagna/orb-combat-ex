// Approach A: a temperature x moisture (Whittaker-style) table with prevailing winds and a rain shadow.
//   Temperature: by latitude (from |y|, no trig), a little noise, a lapse rate with height.
//   Moisture: march K steps upwind along the band's prevailing wind (easterlies, westerlies, polar easterlies);
//   the air recharges over warm sea, loses water over land and rains out on every rise, so the lee of a range is dry.
//   Precipitation is that moisture times a latitude band (wet equator, dry subtropics, wet mid-latitudes, dry poles)
//   and a windward boost. The table then picks the biome; height and cold add ice, snow, alpine; low and wet adds wetland.
// A pure function of the seed and a point, like WorldPlanet.surfAt (the moisture lattice is a memo, like the planet's
// corner cache). makeClimate takes the height function, so approach B and C reuse it on their own ground.
import { R, fbm, ss, clamp01, unit3, east } from '../lib/det.mjs';
import { B } from '../lib/biomes.mjs';

export const PA = {
  K: 10, step: 1800.0,                 // upwind samples and their spacing in units (a fetch of 18,000 units, 42 degrees of arc)
  m0: 0.55,                            // moisture arriving from beyond the fetch
  recharge: 0.32,                      // an ocean step moves the air this share toward saturation, times the sea's warmth
  landLoss: 0.07,                      // a land step loses this share
  oroLoss: 1.0 / 2600.0,               // a rise of h units loses h * oroLoss of what is left (at most 0.9)
  oroGain: 1.0 / 1800.0,               // windward boost at the point itself (at most 1.5)
  pMax: 3200.0,                        // mm a year at full moisture in the wettest band
  pFloor: 0.2,                         // the share that falls whatever the air brings (convection)
  coastRamp: 500.0, recycleY: 0.45,
  latticeCell: 1500.0,                 // moisture marched at the corners of a 3D lattice of this cell (units) and blended
                                       // trilinearly, like value noise. 0: march at every point
  band: [[0.0, 1.0], [0.17, 0.85], [0.34, 0.38], [0.47, 0.14], [0.6, 0.45], [0.75, 0.8], [0.87, 0.55], [0.95, 0.3], [1.0, 0.2]],
  windEdges: [0.5, 0.866], windBlend: 0.05,   // |y| of 30 and 60 degrees; the bands' winds are blended across +-0.05
  tEq: 28.0, t2: 30.0, t4: 18.0,       // sea-level temperature = tEq - t2 y^2 - t4 y^4 (deg C): 19 at 30 degrees, -5 at 60, -20 at the pole
  lapse: 6.0 / 1000.0,                 // deg C a unit of height (a range of 4,000 units is 24 degrees colder at its top)
  tNoise: 6.0, tNoiseScale: 14000.0, pNoise: 0.35, pNoiseScale: 9000.0,
  ditherScale: 5000.0, ditherT: 4.0, ditherP: 0.45,   // ragged ecotones instead of contour lines
  beltScale: 12000.0, beltAmp: 0.07,   // the climate belts meander (|y| is read with this much noise)
  shelf: -450.0, seaIceT: -6.0,
  iceT: -9.0, snowT: -5.0, snowH: 2200.0, alpineT: 2.0, alpineH: 1500.0,
  beachH: 30.0, wetH: 220.0, wetP: 1300.0, wetT: 2.0, wetNoise: 0.6, wetScale: 5000.0,
  // rows by temperature (deg C, upper bound), each a list of [precipitation upper bound (mm), biome]
  table: [
    [-5.0, [[1e9, 'TUNDRA']]],
    [3.0, [[250.0, 'STEPPE'], [1e9, 'BOREAL']]],
    [12.0, [[300.0, 'STEPPE'], [750.0, 'GRASSLAND'], [1800.0, 'TEMP_FOREST'], [1e9, 'TEMP_RAIN']]],
    [20.0, [[280.0, 'DESERT'], [550.0, 'SHRUBLAND'], [950.0, 'GRASSLAND'], [2100.0, 'TEMP_FOREST'], [1e9, 'TEMP_RAIN']]],
    [1e9, [[350.0, 'DESERT'], [1100.0, 'SAVANNA'], [2100.0, 'TROP_SEASONAL'], [1e9, 'TROP_RAIN']]],
  ],
  sT: 20011, sP: 20021, sDither: 20031, sWet: 20041, sBelt: 20051,   // noise streams (added to the seed)
};

function bandAt(P, a) {
  const t = P.band;
  for (let i = 1; i < t.length; i++) if (a <= t[i][0]) {
    const f = (a - t[i - 1][0]) / (t[i][0] - t[i - 1][0]);
    return t[i - 1][1] + (t[i][1] - t[i - 1][1]) * f;
  }
  return t[t.length - 1][1];
}

// heightFn gives the surface; marchFn (default the same) the cheaper height the upwind march reads.
export function makeClimate(heightFn, P = PA, marchFn = heightFn) {
  const rows = P.table.map(([tMax, bands]) => [tMax, bands.map(([pMax, key]) => [pMax, B[key]])]);
  const d = P.step / R;

  function seaT(a) { const a2 = a * a; return P.tEq - P.t2 * a2 - P.t4 * a2 * a2; }

  // The air's moisture on arrival at p, marching upwind with sign u (+1: the wind comes from the east). Returns m and
  // the rise into p from the last upwind step (for the windward boost). hp is the height at p.
  function moisture(seed, px, py, pz, hp, u) {
    const qx = new Float64Array(P.K + 1), qy = new Float64Array(P.K + 1), qz = new Float64Array(P.K + 1);
    qx[0] = px; qy[0] = py; qz[0] = pz;
    for (let k = 1; k <= P.K; k++) {
      const e = east(qx[k - 1], qy[k - 1], qz[k - 1]);
      const q = unit3(qx[k - 1] + e[0] * u * d, qy[k - 1] + e[1] * u * d, qz[k - 1] + e[2] * u * d);
      qx[k] = q[0]; qy[k] = q[1]; qz[k] = q[2];
    }
    let m = P.m0;
    let hPrev = marchFn(seed, qx[P.K], qy[P.K], qz[P.K]);
    for (let k = P.K; k >= 1; k--) {
      const h = k === P.K ? hPrev : marchFn(seed, qx[k], qy[k], qz[k]);
      // the share of open water under this step, smooth across the coast (a hard h < 0 test aliases into stripes
      // parallel to every coast, one step apart)
      const sea = ss(-h / P.coastRamp);
      const ak = Math.abs(qy[k]);
      const warm = clamp01((seaT(ak) + 4.0) / 30.0);
      m += (1.0 - m) * P.recharge * warm * sea;
      let rise = h - (hPrev > 0.0 ? hPrev : 0.0);
      if (rise < 0.0 || h < 0.0) rise = 0.0;
      let lose = rise * P.oroLoss;
      if (lose > 0.9) lose = 0.9;
      const recycle = ak < P.recycleY ? 0.5 + 0.5 * ak / P.recycleY : 1.0;   // tropical forests give back what rains on them
      m *= (1.0 - P.landLoss * recycle * (1.0 - sea)) * (1.0 - lose);
      hPrev = h;
    }
    let rise0 = hp - (hPrev > 0.0 ? hPrev : 0.0);
    if (rise0 < 0.0) rise0 = 0.0;
    return [m, rise0];
  }

  // The climate belts meander: |y| read with a little noise.
  function belt(seed, px, py, pz) {
    const a = Math.abs(py + (fbm(px, py, pz, P.beltScale, 2, seed + P.sBelt) - 0.5) * 2.0 * P.beltAmp);
    return a > 1.0 ? 1.0 : a;
  }

  // The air's moisture arriving at p (both winds blended across a band edge) and the rise into p.
  function arrive(seed, px, py, pz, hp, a) {
    const [e0, e1] = P.windEdges, bw = P.windBlend;
    let u0 = 1.0, u1 = 1.0, t = 0.0;     // the wind each side of the nearest band edge, and the blend
    if (a < e0 - bw) { u0 = 1.0; t = 0.0; }
    else if (a < e0 + bw) { u0 = 1.0; u1 = -1.0; t = ss((a - (e0 - bw)) / (2.0 * bw)); }
    else if (a < e1 - bw) { u0 = -1.0; t = 0.0; }
    else if (a < e1 + bw) { u0 = -1.0; u1 = 1.0; t = ss((a - (e1 - bw)) / (2.0 * bw)); }
    else { u0 = 1.0; t = 0.0; }
    let [m, rise0] = moisture(seed, px, py, pz, hp, u0);
    if (t > 0.0) {
      const [m1, r1] = moisture(seed, px, py, pz, hp, u1);
      m = m + (m1 - m) * t; rise0 = rise0 + (r1 - rise0) * t;
    }
    return [m, rise0];
  }

  // The lattice: a corner's moisture is arrive() at the corner's direction, memoised per seed (a pure memo: the same
  // numbers cold or warm). A slice walks corners in order, so it marches about one corner for every eight columns.
  const memo = new Map();
  let marches = 0;
  function cornerM(seed, ix, iy, iz, k) {
    const key = seed + ':' + ix + ':' + iy + ':' + iz;
    let v = memo.get(key);
    if (v === undefined) {
      const d = unit3(ix / k, iy / k, iz / k);
      v = arrive(seed, d[0], d[1], d[2], marchFn(seed, d[0], d[1], d[2]), belt(seed, d[0], d[1], d[2]))[0];
      marches++;
      if (memo.size > 400000) memo.clear();
      memo.set(key, v);
    }
    return v;
  }
  function latticeM(seed, px, py, pz) {
    const k = R / P.latticeCell, x = px * k, y = py * k, z = pz * k;
    const fx = Math.floor(x), fy = Math.floor(y), fz = Math.floor(z), ix = fx | 0, iy = fy | 0, iz = fz | 0;
    const tx = x - fx, ty = y - fy, tz = z - fz;
    const c000 = cornerM(seed, ix, iy, iz, k), c100 = cornerM(seed, ix + 1, iy, iz, k);
    const c010 = cornerM(seed, ix, iy + 1, iz, k), c110 = cornerM(seed, ix + 1, iy + 1, iz, k);
    const c001 = cornerM(seed, ix, iy, iz + 1, k), c101 = cornerM(seed, ix + 1, iy, iz + 1, k);
    const c011 = cornerM(seed, ix, iy + 1, iz + 1, k), c111 = cornerM(seed, ix + 1, iy + 1, iz + 1, k);
    const a0 = c000 + (c100 - c000) * tx, b0 = c010 + (c110 - c010) * tx, c0 = c001 + (c101 - c001) * tx, d0 = c011 + (c111 - c011) * tx;
    const e = a0 + (b0 - a0) * ty, f = c0 + (d0 - c0) * ty;
    return e + (f - e) * tz;
  }
  // The rise into p from one step upwind, in the band's wind (the windward boost).
  function riseInto(seed, px, py, pz, hp, a) {
    const u = a < P.windEdges[0] ? 1.0 : (a < P.windEdges[1] ? -1.0 : 1.0);
    const e = east(px, py, pz), d = P.step / R;
    const q = unit3(px + e[0] * u * d, py + e[1] * u * d, pz + e[2] * u * d);
    const hq = marchFn(seed, q[0], q[1], q[2]);
    const r = hp - (hq > 0.0 ? hq : 0.0);
    return r > 0.0 ? r : 0.0;
  }

  // Precipitation (mm a year) at p, height hp.
  function precip(seed, px, py, pz, hp) {
    const a = belt(seed, px, py, pz);
    let m, rise0;
    if (P.latticeCell > 0.0) { m = latticeM(seed, px, py, pz); rise0 = riseInto(seed, px, py, pz, hp, a); }
    else [m, rise0] = arrive(seed, px, py, pz, hp, a);
    let boost = rise0 * P.oroGain;
    if (boost > 1.5) boost = 1.5;
    const n = fbm(px, py, pz, P.pNoiseScale, 2, seed + P.sP);
    return P.pMax * bandAt(P, a) * (P.pFloor + (1.0 - P.pFloor) * m) * (1.0 + boost) * (1.0 - P.pNoise * 0.5 + P.pNoise * n);
  }

  function seaLevelT(seed, px, py, pz) {
    const a = belt(seed, px, py, pz);
    return seaT(a) + (fbm(px, py, pz, P.tNoiseScale, 2, seed + P.sT) - 0.5) * P.tNoise;
  }

  function classifyLand(seed, px, py, pz, h, T, Pr) {
    if (T < P.iceT) return B.ICE_SHEET;
    if (T < P.snowT && h > P.snowH) return B.SNOW;
    if (T < P.alpineT && h > P.alpineH) return B.ALPINE;
    if (h < P.beachH && T > 0.0) return B.BEACH;
    if (h < P.wetH && Pr > P.wetP && T > P.wetT && fbm(px, py, pz, P.wetScale, 2, seed + P.sWet) > P.wetNoise) return B.WETLAND;
    for (const [tMax, bands] of rows) if (T < tMax) {
      for (const [pMax, b] of bands) if (Pr < pMax) return b;
    }
    return B.GRASSLAND;
  }

  // The biome at p for a known height h (the ordinary ground: WorldPlanet's polar logic wraps it, gen/index.mjs).
  function biome(seed, px, py, pz, h) { return sample(seed, px, py, pz, h)[1]; }

  // The whole surface at p: [height, biome, T, P]. hOverride classifies a known height (approach C's eroded ground).
  function sample(seed, px, py, pz, hOverride) {
    const h = hOverride === undefined ? heightFn(seed, px, py, pz) : hOverride;
    let Tsl = seaLevelT(seed, px, py, pz);
    const dz = fbm(px, py, pz, P.ditherScale, 3, seed + P.sDither) - 0.5;
    if (h < 0.0) {
      if (Tsl + dz * 2.0 * P.ditherT < P.seaIceT) return [h, B.SEA_ICE, Tsl, 0.0];
      return [h, h > P.shelf ? B.SEA : B.DEEP, Tsl, 0.0];
    }
    let T = Tsl - P.lapse * h + dz * 2.0 * P.ditherT;
    let Pr = precip(seed, px, py, pz, h) * (1.0 + dz * 2.0 * P.ditherP);
    return [h, classifyLand(seed, px, py, pz, h, T, Pr), T, Pr];
  }

  return { sample, biome, precip, seaLevelT, classifyLand, params: P, marchCount: () => marches, forget: () => memo.clear() };
}
