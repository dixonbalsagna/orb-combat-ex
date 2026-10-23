// Approach B: plate-lite. A few seeded plates (a centre and an Euler pole each, continental or oceanic), found per point
// as the nearest centres to a noise-warped point (a warped Voronoi on the sphere: wiggly, never straight, boundaries).
// At each boundary the plates' relative motion across it decides the landform:
//   converging continent-continent: a high range;  ocean under continent: a trench offshore and a coastal volcanic range;
//   ocean-ocean: a trench and an island arc;  diverging ocean: a mid-ocean ridge;  diverging continent: a rift valley
//   with raised shoulders (a new sea where it is deep).  Hotspots leave island chains along the plate's motion.
// The crust (continent or ocean floor) is a low-frequency noise biased by the plate type, so coastlines do not follow
// plate edges. Every pair term is gated by how close the point is to that pair's shared edge, from dot products only,
// so the field is continuous across every boundary. A pure function of the seed and the point (no grid).
import { fbm, ss, unit3, draw, randUnit } from '../lib/det.mjs';

export const PB = {
  plates: 14, contShare: 0.57, minSpeed: 0.35,           // 8 of 14 plates carry continents
  warpScale: 14000.0, warpOct: 3, warpAmp: 0.3,           // in unit-vector space (0.3 is about 7,000 units)
  crustScale: 24000.0, crustOct: 4, crustBias: 0.34, shelfW: 0.10,
  contH: 250.0, contRelief: 900.0, oceanH: -2200.0, oceanRelief: 600.0, abyssH: 260.0,
  coastScale: 4000.0, coastAmp: 0.14, alongScale: 7000.0,
  interiorScale: 9000.0, interiorH: 1300.0, oldScale: 15000.0, oldH: 2200.0, widthScale: 8000.0,
  blendW: 0.10,                                            // plate bias blended over this dot-product excess
  bw: 0.11, gateW: 0.035,                                  // boundary half-width (sin of the angle) and the pair gate
  vRef: 0.9,                                               // relative speed for a full-size landform
  rangeH: 5600.0, arcH: 3000.0, trenchH: 2600.0, ridgeH: 1300.0, riftH: 1500.0, shoulderH: 900.0,
  reliefScale: 3500.0, reliefOct: 4, peakScale: 2500.0, islandScale: 3500.0,
  hotspots: 4, chain: 6, chainStep: 0.07, hotR: 0.035, hotH: 3000.0, sWidth: 3900, sInterior: 3950, sOld: 3970,
  detailScale: 1800.0, detailOct: 2, detailAmp: 140.0,
  volcanic: 0.55,                                          // the volcanic score above which land is a volcanic field
  sPlate: 3000, sPole: 3100, sType: 3200, sWarp: 3300, sCrust: 3400, sRelief: 3500, sIsland: 3600, sHot: 3700, sDetail: 3800,
};

export function makePlates(seed, P = PB) {
  const c = [], w = [], bias = [];
  for (let i = 0; i < P.plates; i++) {
    c.push(randUnit(seed, P.sPlate, i));
    const pole = randUnit(seed, P.sPole, i), sp = P.minSpeed + (1 - P.minSpeed) * draw(seed, P.sPole + 1, i);
    w.push([pole[0] * sp, pole[1] * sp, pole[2] * sp]);
  }
  // exactly round(contShare * plates) continental plates, chosen by a seeded order
  const rank = c.map((_, i) => [draw(seed, P.sType, i), i]).sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  const nCont = Math.round(P.contShare * P.plates);
  for (let i = 0; i < P.plates; i++) bias.push(0.0);
  rank.forEach(([, i], r) => { bias[i] = r < nCont ? P.crustBias : -P.crustBias; });
  // hotspots: a point and a chain of older, lower islands carried off along its plate's motion
  const hot = [];
  for (let k = 0; k < P.hotspots; k++) {
    let p = randUnit(seed, P.sHot, k);
    const hh = 0.6 + 0.4 * draw(seed, P.sHot + 1, k);
    for (let j = 0; j < P.chain; j++) {
      hot.push([p[0], p[1], p[2], hh * (1 - j / (P.chain + 1))]);
      // the plate under p: its velocity at p, stepped backwards
      let bi = 0, bd = -2;
      for (let i = 0; i < P.plates; i++) { const d = p[0] * c[i][0] + p[1] * c[i][1] + p[2] * c[i][2]; if (d > bd) { bd = d; bi = i; } }
      const o = w[bi], v = [o[1] * p[2] - o[2] * p[1], o[2] * p[0] - o[0] * p[2], o[0] * p[1] - o[1] * p[0]];
      const vl = Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) || 1;
      const st = P.chainStep * (0.7 + 0.6 * draw(seed, P.sHot + 2, k * 16 + j));
      p = unit3(p[0] + v[0] / vl * st, p[1] + v[1] / vl * st, p[2] + v[2] / vl * st);   // older islands ride away with the plate
    }
  }
  return { seed, P, c, w, bias, hot, volc: 0.0 };
}

function bump(t) { const a = t < 0 ? -t : t; return a >= 1.0 ? 0.0 : ss(1.0 - a); }

// The ground at p. coarse: fewer octaves (the climate's upwind march). Sets S.volc (0..1) as a side output.
export function plateGround(S, px, py, pz, coarse = false) {
  const P = S.P, seed = S.seed, n = P.plates;
  const wo = coarse ? 1 : P.warpOct;
  const qx0 = px + P.warpAmp * (fbm(px, py, pz, P.warpScale, wo, seed + P.sWarp) - 0.5) * 2.0;
  const qy0 = py + P.warpAmp * (fbm(px, py, pz, P.warpScale, wo, seed + P.sWarp + 17) - 0.5) * 2.0;
  const qz0 = pz + P.warpAmp * (fbm(px, py, pz, P.warpScale, wo, seed + P.sWarp + 31) - 0.5) * 2.0;
  const q = unit3(qx0, qy0, qz0), qx = q[0], qy = q[1], qz = q[2];
  // the three nearest plates
  let i1 = 0, i2 = 0, i3 = 0, d1 = -9, d2 = -9, d3 = -9;
  for (let i = 0; i < n; i++) {
    const d = qx * S.c[i][0] + qy * S.c[i][1] + qz * S.c[i][2];
    if (d > d1) { i3 = i2; d3 = d2; i2 = i1; d2 = d1; i1 = i; d1 = d; }
    else if (d > d2) { i3 = i2; d3 = d2; i2 = i; d2 = d; }
    else if (d > d3) { i3 = i; d3 = d; }
  }
  const ids = [i1, i2, i3], ex = [0.0, d1 - d2, d1 - d3];
  // crust: one noise, the plates' biases blended near their shared edges
  let bw = 1.0, bs = S.bias[i1];
  for (let k = 1; k < 3; k++) { const g = ss(1.0 - ex[k] / P.blendW); bw += g; bs += S.bias[ids[k]] * g; }
  let noise = (fbm(px, py, pz, P.crustScale, coarse ? 3 : P.crustOct, seed + P.sCrust) - 0.5) * 2.0;
  if (!coarse) noise += (fbm(px, py, pz, P.coastScale, 2, seed + P.sCrust + 9) - 0.5) * P.coastAmp;   // bays and capes
  const crust = noise + bs / bw;
  const land = ss((crust + P.shelfW) / (2.0 * P.shelfW));
  let h = P.oceanH + noise * P.oceanRelief + (P.contH + crust * P.contRelief - P.oceanH - noise * P.oceanRelief) * land;
  const widthMul = coarse ? 1.0 : 0.7 + 0.6 * fbm(px, py, pz, P.widthScale, 2, seed + P.sWidth);
  if (!coarse) {
    // continental interiors: rolling relief and old worn ranges (ridged noise: sinuous crests along a noise contour)
    const rel = fbm(px, py, pz, P.interiorScale, 4, seed + P.sInterior);
    const r = 1.0 - Math.abs(2.0 * fbm(px, py, pz, P.oldScale, 3, seed + P.sOld) - 1.0);
    const old = r > 0.72 ? (r - 0.72) / 0.28 : 0.0;
    h += land * ((rel - 0.38) * P.interiorH + old * old * P.oldH * rel * 1.6) + (1.0 - land) * (rel - 0.5) * 2.0 * P.abyssH;
  }
  // boundary landforms, the three pairs among the nearest plates
  let up = 0.0, down = 0.0, volc = 0.0;
  const pairs = [[0, 1], [0, 2], [1, 2]];
  for (const [ka, kb] of pairs) {
    const gate = ss(1.0 - Math.min(ex[ka], ex[kb]) / P.gateW);   // live only where a or b is (nearly) the nearest plate
    if (gate <= 0.0) continue;
    let a = ids[ka], b = ids[kb];
    if (a > b) { const t = a; a = b; b = t; }          // ordered by index, so both sides see the same pair
    const ca = S.c[a], cb = S.c[b];
    const dx = cb[0] - ca[0], dy = cb[1] - ca[1], dz = cb[2] - ca[2], dl = Math.sqrt(dx * dx + dy * dy + dz * dz);
    const sig = -(qx * dx + qy * dy + qz * dz) / dl;     // signed distance to the shared edge, positive on a's side
    const dq = qx * dx + qy * dy + qz * dz;
    const nb = unit3(dx - qx * dq, dy - qy * dq, dz - qz * dq);   // across the edge, from a toward b
    const wa = S.w[a], wb = S.w[b];
    const rvx = (wa[1] * qz - wa[2] * qy) - (wb[1] * qz - wb[2] * qy);
    const rvy = (wa[2] * qx - wa[0] * qz) - (wb[2] * qx - wb[0] * qz);
    const rvz = (wa[0] * qy - wa[1] * qx) - (wb[0] * qy - wb[1] * qx);
    const conv = (rvx * nb[0] + rvy * nb[1] + rvz * nb[2]) / P.vRef;   // > 0: a and b close on each other
    const contA = noise + S.bias[a] > 0.0, contB = noise + S.bias[b] > 0.0;
    const x = sig / (P.bw * widthMul);
    if (conv > 0.0) {
      const k = (conv > 1.0 ? 1.0 : conv) * gate;
      if (contA && contB) up += P.rangeH * k * bump(x);
      else if (contA !== contB) {
        const s = contB ? 1.0 : -1.0;                      // the oceanic side is +s * x
        down += P.trenchH * k * bump((s * x - 0.16) / 0.2);
        const arc = P.arcH * k * bump((s * x + 0.6) / 0.45);
        up += arc; volc += arc / P.arcH;
      } else {
        down += P.trenchH * k * bump((-x - 0.16) / 0.2);   // b goes under a: the trench on b's side
        const isl = ss((fbm(px, py, pz, P.islandScale, 2, seed + P.sIsland) - 0.42) / 0.16);
        const arc = P.arcH * 1.1 * k * bump((x - 0.5) / 0.35) * isl;
        up += arc; volc += arc / P.arcH;
      }
    } else if (conv < 0.0) {
      const k = (conv < -1.0 ? 1.0 : -conv) * gate;
      if (!contA && !contB) up += P.ridgeH * k * bump(x / 0.8);
      else {
        const along = coarse ? 0.6 : fbm(px, py, pz, P.alongScale, 2, seed + P.sWidth + 5);   // rifts open in segments
        const kk = k * ss((along - 0.3) / 0.4);
        down += P.riftH * kk * bump(x / 0.32);
        up += P.shoulderH * kk * (0.4 + along) * bump(((x < 0 ? -x : x) - 0.55) / 0.3);
        volc += 0.7 * kk * bump(x / 0.22);
      }
    }
  }
  // hotspot chains
  if (!coarse) for (const t of S.hot) {
    const ddx = qx - t[0], ddy = qy - t[1], ddz = qz - t[2], d = Math.sqrt(ddx * ddx + ddy * ddy + ddz * ddz);
    if (d < P.hotR) { const v = t[3] * ss(1.0 - d / P.hotR) * (1.0 - land * 0.85); up += P.hotH * v; volc += v * 1.2; }
  }
  let mul = 1.0;
  if (!coarse && up > 0.0) {
    const rough = fbm(px, py, pz, P.reliefScale, P.reliefOct, seed + P.sRelief);
    const peaks = 1.0 - Math.abs(2.0 * fbm(px, py, pz, P.peakScale, 3, seed + P.sRelief + 7) - 1.0);
    mul = (0.25 + 1.5 * rough) * (0.7 + 0.6 * peaks);
  }
  h += up * mul - down;
  if (!coarse && h > 0.0) h += (fbm(px, py, pz, P.detailScale, P.detailOct, seed + P.sDetail) - 0.5) * 2.0 * P.detailAmp;
  S.volc = volc > 1.0 ? 1.0 : volc;
  return h;
}
