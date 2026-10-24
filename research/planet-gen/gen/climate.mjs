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
  riseLattice: false,                  // true: the windward rise reads the lattice too (each corner keeps its march's first
                                       // upwind height), so a column reads no height upwind: about 1.6 octaves a column
                                       // fewer, but the boost changes (0.1 to 0.3% of the map's pixels)
  band: [[0.0, 1.0], [0.17, 0.85], [0.34, 0.38], [0.47, 0.14], [0.6, 0.45], [0.75, 0.8], [0.87, 0.55], [0.95, 0.3], [1.0, 0.2]],
  windEdges: [0.5, 0.866], windBlend: 0.05,   // |y| of 30 and 60 degrees; the bands' winds are blended across +-0.05
  tEq: 28.0, t2: 30.0, t4: 18.0,       // sea-level temperature = tEq - t2 y^2 - t4 y^4 (deg C): 19 at 30 degrees, -5 at 60, -20 at the pole
  lapse: 6.0 / 1000.0,                 // deg C a unit of height (a range of 4,000 units is 24 degrees colder at its top)
  tNoise: 6.0, tNoiseScale: 14000.0, pNoise: 0.35, pNoiseScale: 9000.0,
  ditherScale: 5000.0, ditherOct: 3, ditherT: 4.0, ditherP: 0.45,   // ragged ecotones instead of contour lines (2 octaves
                                                                    // visibly smooths them)
  beltScale: 10000.0, beltAmp: 0.13,   // the climate belts meander (|y| is read with this much noise): wide enough to break up the zonal stripes
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
  // the rise into p from the last upwind step (for the windward boost). hp is the height at p. The height one step
  // upwind is left in nearH.
  const qx = new Float64Array(P.K + 1), qy = new Float64Array(P.K + 1), qz = new Float64Array(P.K + 1);   // the march's path
  let nearH = 0.0;
  function moisture(seed, px, py, pz, hp, u) {
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
    nearH = hPrev;
    return [m, rise0];
  }

  // The climate belts meander: |y| read with a little noise.
  function belt(seed, px, py, pz) {
    const a = Math.abs(py + (fbm(px, py, pz, P.beltScale, 2, seed + P.sBelt) - 0.5) * 2.0 * P.beltAmp);
    return a > 1.0 ? 1.0 : a;
  }

  // The air's moisture arriving at p (both winds blended across a band edge) and the rise into p. nearH is left at the
  // height one step upwind in the band's own wind (riseInto's).
  function arrive(seed, px, py, pz, hp, a) {
    const [e0, e1] = P.windEdges, bw = P.windBlend;
    let u0 = 1.0, u1 = 1.0, t = 0.0;     // the wind each side of the nearest band edge, and the blend
    if (a < e0 - bw) { u0 = 1.0; t = 0.0; }
    else if (a < e0 + bw) { u0 = 1.0; u1 = -1.0; t = ss((a - (e0 - bw)) / (2.0 * bw)); }
    else if (a < e1 - bw) { u0 = -1.0; t = 0.0; }
    else if (a < e1 + bw) { u0 = -1.0; u1 = 1.0; t = ss((a - (e1 - bw)) / (2.0 * bw)); }
    else { u0 = 1.0; t = 0.0; }
    let [m, rise0] = moisture(seed, px, py, pz, hp, u0);
    const near0 = nearH;
    if (t > 0.0) {
      const [m1, r1] = moisture(seed, px, py, pz, hp, u1);
      m = m + (m1 - m) * t; rise0 = rise0 + (r1 - rise0) * t;
      if (a < (a < e0 + bw ? e0 : e1)) nearH = near0;   // the band's own wind is u0 below the edge, u1 above it
    }
    return [m, rise0];
  }

  // The lattice: a corner's moisture is arrive() at the corner's direction, memoised per seed (a pure memo: the same
  // numbers cold or warm). A slice walks corners in order, so it marches about one corner for every eight columns.
  // The memo is a flat array over the lattice's cube (NaN: not marched yet), emptied when the seed changes; the last
  // cell's eight corners are kept, since neighbouring columns mostly share a cell (about 47 columns to a cell).
  const kL = P.latticeCell > 0.0 ? R / P.latticeCell : 0.0, kMax = Math.floor(kL) + 2, nL = 2 * kMax + 1;
  const memo = P.latticeCell > 0.0 ? new Float64Array(nL * nL * nL).fill(NaN) : null;
  const memoH = P.riseLattice && memo ? new Float64Array(nL * nL * nL) : null;   // a corner's height one step upwind
  let memoSeed = null, marches = 0, lastSeed = null, lx = 0, ly = 0, lz = 0, latH = 0.0;
  const lc = new Float64Array(8), lh = new Float64Array(8);
  function forget() { memoSeed = null; lastSeed = null; }   // the next read empties the memo
  // Corner j of the cell (lc[j], and lh[j] with riseLattice).
  function corner(seed, ix, iy, iz, k, j) {
    const i = ((ix + kMax) * nL + iy + kMax) * nL + iz + kMax;
    if (memo[i] !== memo[i]) {
      const d = unit3(ix / k, iy / k, iz / k);
      memo[i] = arrive(seed, d[0], d[1], d[2], 0.0, belt(seed, d[0], d[1], d[2]))[0];   // m does not read the corner's height
      if (memoH) memoH[i] = nearH;
      marches++;
    }
    lc[j] = memo[i];
    if (memoH) lh[j] = memoH[i];
  }
  function tri(c, tx, ty, tz) {
    const c000 = c[0], c100 = c[1], c010 = c[2], c110 = c[3], c001 = c[4], c101 = c[5], c011 = c[6], c111 = c[7];
    const a0 = c000 + (c100 - c000) * tx, b0 = c010 + (c110 - c010) * tx, c0 = c001 + (c101 - c001) * tx, d0 = c011 + (c111 - c011) * tx;
    const e = a0 + (b0 - a0) * ty, f = c0 + (d0 - c0) * ty;
    return e + (f - e) * tz;
  }
  function latticeM(seed, px, py, pz) {
    const k = R / P.latticeCell, x = px * k, y = py * k, z = pz * k;
    const fx = Math.floor(x), fy = Math.floor(y), fz = Math.floor(z), ix = fx | 0, iy = fy | 0, iz = fz | 0;
    const tx = x - fx, ty = y - fy, tz = z - fz;
    if (seed !== lastSeed || ix !== lx || iy !== ly || iz !== lz) {
      if (seed !== memoSeed) { memo.fill(NaN); memoSeed = seed; }
      corner(seed, ix, iy, iz, k, 0); corner(seed, ix + 1, iy, iz, k, 1);
      corner(seed, ix, iy + 1, iz, k, 2); corner(seed, ix + 1, iy + 1, iz, k, 3);
      corner(seed, ix, iy, iz + 1, k, 4); corner(seed, ix + 1, iy, iz + 1, k, 5);
      corner(seed, ix, iy + 1, iz + 1, k, 6); corner(seed, ix + 1, iy + 1, iz + 1, k, 7);
      lastSeed = seed; lx = ix; ly = iy; lz = iz;
    }
    if (memoH) latH = tri(lh, tx, ty, tz);   // the upwind height, blended like the moisture (riseLattice)
    return tri(lc, tx, ty, tz);
  }
  // The rise into p from one step upwind, in the band's wind (the windward boost). With riseLattice the upwind height
  // is the lattice's blend (latticeM must have read p first).
  function riseInto(seed, px, py, pz, hp, a) {
    if (P.riseLattice && P.latticeCell > 0.0) { const r = hp - (latH > 0.0 ? latH : 0.0); return r > 0.0 ? r : 0.0; }
    const u = a < P.windEdges[0] ? 1.0 : (a < P.windEdges[1] ? -1.0 : 1.0);
    const e = east(px, py, pz), d = P.step / R;
    const q = unit3(px + e[0] * u * d, py + e[1] * u * d, pz + e[2] * u * d);
    const hq = marchFn(seed, q[0], q[1], q[2]);
    const r = hp - (hq > 0.0 ? hq : 0.0);
    return r > 0.0 ? r : 0.0;
  }

  // Precipitation (mm a year) at p, height hp; precipAt takes the belt's |y| (a) when the caller has it.
  function precip(seed, px, py, pz, hp) { return precipAt(seed, px, py, pz, hp, belt(seed, px, py, pz)); }
  function precipAt(seed, px, py, pz, hp, a) {
    let m, rise0;
    if (P.latticeCell > 0.0) { m = latticeM(seed, px, py, pz); rise0 = riseInto(seed, px, py, pz, hp, a); }
    else [m, rise0] = arrive(seed, px, py, pz, hp, a);
    let boost = rise0 * P.oroGain;
    if (boost > 1.5) boost = 1.5;
    return rain(a, m, boost, fbm(px, py, pz, P.pNoiseScale, 2, seed + P.sP));
  }
  // The rain from the belt's |y|, the arriving moisture, the windward boost and the noise n. Every factor is positive,
  // so it rises with m, the boost and n, and float rounding keeps that (sample's bounds lean on it).
  function rain(a, m, boost, n) {
    return P.pMax * bandAt(P, a) * (P.pFloor + (1.0 - P.pFloor) * m) * (1.0 + boost) * (1.0 - P.pNoise * 0.5 + P.pNoise * n);
  }

  function seaLevelT(seed, px, py, pz) { return seaLevelTAt(seed, px, py, pz, belt(seed, px, py, pz)); }
  function seaLevelTAt(seed, px, py, pz, a) {
    return seaT(a) + (fbm(px, py, pz, P.tNoiseScale, 2, seed + P.sT) - 0.5) * P.tNoise;
  }

  // The rules that read only the temperature and the height (-1: none applies, the rain decides). At a given height
  // each answer holds one interval of T (the rules are T below a bound, in order, then T above 0).
  function coldBiome(h, T) {
    if (T < P.iceT) return B.ICE_SHEET;
    if (T < P.snowT && h > P.snowH) return B.SNOW;
    if (T < P.alpineT && h > P.alpineH) return B.ALPINE;
    if (h < P.beachH && T > 0.0) return B.BEACH;
    return -1;
  }
  // The table's row for T (rows.length past the last: grassland) and a row's band for the rain Pr (bands.length: none).
  function rowOf(T) { let r = 0; while (r < rows.length && !(T < rows[r][0])) r++; return r; }
  function bandOf(bands, Pr) { let i = 0; while (i < bands.length && !(Pr < bands[i][0])) i++; return i; }
  // The land biome for any T in [lo, hi] when the rain cannot change it: one cold rule holds across the range, or the
  // range sits in a row with a single band and is too cold for wetland. -1: the rain decides.
  function dryBiome(h, lo, hi) {
    const c = coldBiome(h, lo);
    if (c !== coldBiome(h, hi)) return -1;
    if (c >= 0) return c;
    if (hi > P.wetT) return -1;
    const r = rowOf(lo);
    return r === rowOf(hi) && r < rows.length && rows[r][1].length === 1 ? rows[r][1][0][1] : -1;
  }
  // The biome when the sea-level temperature is known only to lie in [tLo, tHi] and the dither is not drawn (it moves
  // T by at most ditherT). -1: not settled. The bounds are computed in the order the real T is, and every step of it
  // is monotone, so float rounding keeps them bounds.
  function settle(h, tLo, tHi) {
    if (h < 0.0) {
      if (tLo - P.ditherT >= P.seaIceT) return h > P.shelf ? B.SEA : B.DEEP;
      if (tHi + P.ditherT < P.seaIceT) return B.SEA_ICE;
      return -1;
    }
    const lap = P.lapse * h;
    return dryBiome(h, tLo - lap - P.ditherT, tHi - lap + P.ditherT);
  }
  // The land biome for a rain known to lie in [lo, hi] (T exact, no cold rule holds): the wetland rule and the row's
  // band, read as classifyLand does. -1: the rain's exact value matters.
  function wetBiome(seed, px, py, pz, h, T, lo, hi) {
    if (h < P.wetH && T > P.wetT && hi > P.wetP) {
      if (!(lo > P.wetP)) return -1;
      if (fbm(px, py, pz, P.wetScale, 2, seed + P.sWet) > P.wetNoise) return B.WETLAND;
    }
    const r = rowOf(T);
    if (r === rows.length) return B.GRASSLAND;
    const bands = rows[r][1], i = bandOf(bands, lo);
    return i === bandOf(bands, hi) && i < bands.length ? bands[i][1] : -1;
  }
  function classifyLand(seed, px, py, pz, h, T, Pr) {
    const bc = coldBiome(h, T);
    if (bc >= 0) return bc;
    if (h < P.wetH && Pr > P.wetP && T > P.wetT && fbm(px, py, pz, P.wetScale, 2, seed + P.sWet) > P.wetNoise) return B.WETLAND;
    for (const [tMax, bands] of rows) if (T < tMax) {
      for (const [pMax, b] of bands) if (Pr < pMax) return b;
    }
    return B.GRASSLAND;
  }

  // The biome at p for a known height h (the ordinary ground: WorldPlanet's polar logic wraps it, gen/index.mjs).
  function biome(seed, px, py, pz, h) { return sample(seed, px, py, pz, h, false)[1]; }

  // The whole surface at p: [height, biome, T, P]. hOverride classifies a known height (approach C's eroded ground).
  // full (the default when a height is passed in, as approach C does, whose rules read T and P) fills T and P on all
  // land and T on all water. Otherwise only the height and the biome are certain: each noise is drawn only while it can
  // still change the biome. |y| alone bounds the belt (its meander is at most beltAmp); then the belt is read; then the
  // sea-level noise (at most half tNoise either way); then the dither (at most ditherT); on land the rain then needs
  // the moisture lattice, and the windward rise and the rain's noise only where the rain's bounds straddle a border
  // of the table. T is NaN where the biome settled before it was known, and P is 0 where the rain was not needed.
  function sample(seed, px, py, pz, hOverride, full = hOverride !== undefined) {
    const h = hOverride === undefined ? heightFn(seed, px, py, pz) : hOverride;
    const hn = 0.5 * P.tNoise;
    let b = -1;
    if (!full) {
      const ay = Math.abs(py), aLo = ay - P.beltAmp > 0.0 ? ay - P.beltAmp : 0.0;
      b = settle(h, seaT(ay + P.beltAmp) - hn, seaT(aLo) + hn);
      if (b >= 0) return [h, b, NaN, 0.0];
    }
    const a = belt(seed, px, py, pz);   // read once: the temperature and the rain both use it
    if (!full) {
      b = settle(h, seaT(a) - hn, seaT(a) + hn);
      if (b >= 0) return [h, b, NaN, 0.0];
    }
    const Tsl = seaLevelTAt(seed, px, py, pz, a);
    // on water T is Tsl and the dither only decides the sea ice, so where it cannot it is skipped in either mode
    if (h < 0.0 || !full) {
      b = settle(h, Tsl, Tsl);
      if (b >= 0) return [h, b, h < 0.0 ? Tsl : NaN, 0.0];
    }
    const dz = fbm(px, py, pz, P.ditherScale, P.ditherOct, seed + P.sDither) - 0.5;
    if (h < 0.0) {
      if (Tsl + dz * 2.0 * P.ditherT < P.seaIceT) return [h, B.SEA_ICE, Tsl, 0.0];
      return [h, h > P.shelf ? B.SEA : B.DEEP, Tsl, 0.0];
    }
    const T = Tsl - P.lapse * h + dz * 2.0 * P.ditherT, wet = 1.0 + dz * 2.0 * P.ditherP;
    if (full || P.latticeCell <= 0.0) {
      const Pr = precipAt(seed, px, py, pz, h, a) * wet;
      return [h, classifyLand(seed, px, py, pz, h, T, Pr), T, Pr];
    }
    b = dryBiome(h, T, T);
    if (b >= 0) return [h, b, T, 0.0];   // the rain cannot change it: not computed (the march, the rise, the noise)
    // the rain with the moisture known: the rise is at most the height itself (so the boost at most h * oroGain) and
    // the noise lies in [0, 1)
    const m = latticeM(seed, px, py, pz);
    let bLo = 0.0, bHi = h * P.oroGain;
    if (P.riseLattice) { bLo = riseInto(seed, px, py, pz, h, a) * P.oroGain; bHi = bLo; }   // no height read: exact
    if (bLo > 1.5) bLo = 1.5;
    if (bHi > 1.5) bHi = 1.5;
    b = wetBiome(seed, px, py, pz, h, T, rain(a, m, bLo, 0.0) * wet, rain(a, m, bHi, 1.0) * wet);
    if (b >= 0) return [h, b, T, 0.0];
    let boost = P.riseLattice ? bLo : riseInto(seed, px, py, pz, h, a) * P.oroGain;
    if (boost > 1.5) boost = 1.5;
    const Pr = rain(a, m, boost, fbm(px, py, pz, P.pNoiseScale, 2, seed + P.sP)) * wet;
    return [h, classifyLand(seed, px, py, pz, h, T, Pr), T, Pr];
  }

  return { sample, biome, precip, seaLevelT, classifyLand, params: P, marchCount: () => marches, forget };
}
