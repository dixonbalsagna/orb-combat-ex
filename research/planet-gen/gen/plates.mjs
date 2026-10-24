// Approach B: plate-lite. A few seeded plates (an Euler pole each, continental or oceanic), each made of one or more
// Voronoi cells, found per point as the nearest cell centres to a noise-warped point (a warped Voronoi on the sphere).
// Centres keep a minimum distance (no sliver plates, so no rows of parallel edges), and the extra cells join their
// nearest plate, so plate outlines bend at every cell corner instead of running as long great-circle arcs.
// At each boundary the plates' relative motion across it decides the landform:
//   converging continent-continent: a range (a crest belt on a foothill apron);  ocean under continent: a trench offshore
//   and a volcanic arc inland (a coastal range on land, a string of islands at sea);  ocean-ocean: a trench and an
//   island arc;  diverging ocean: a mid-ocean ridge;  diverging continent: a rift valley in offset segments, each with
//   one raised shoulder (a new sea where it is deep).  Hotspots leave island chains along the plate's motion.
// The crust (continent or ocean floor) is a low-frequency noise read at the warped point, with a small plate bias
// blended over every cell within reach (a width that varies with the relief), levelled per planet to a land share, so
// coastlines wander inside plates instead of tracing their edges. Ranges are a crest belt cut by a ridged noise into
// crests, saddles and spurs on a foothill apron; old worn ranges cross the interiors in pieces. The field is continuous
// everywhere: each side's type is a smooth weight, and a pair's landform keeps its width to a rounded end near a triple
// junction (the two stronger arms join there, the weakest stops short), bends with the outline at a corner of one
// plate's cells, and fades out before the third-nearest cell ties with the fourth. Where arms overlap they are
// averaged, not stacked. Landforms fade toward the poles in the poles' own coordinate (poles.mjs sinks the north and
// lifts the south). A pure function of the seed and the point (no grid); the set-up counts plate areas and the crust's
// level on 2,000 seeded points and tabulates each pair of cells' edge. The climate's upwind march (coarse) reads a
// cheaper ground: fewer octaves, no rifts, no junction ends.
import { fbm, ss, unit3, draw, randUnit } from '../lib/det.mjs';
import { PP } from './poles.mjs';

export const PB = {
  plates: 14, contArea: 0.55, minSpeed: 0.35,            // continental plates, in a seeded order, until they cover 55% of the sphere
  areaPts: 2000, sArea: 3250,                              // the plates' areas, counted on this many seeded points
  landShare: 0.6,                                          // the crust is levelled so this share of those points is land
  minSep: 0.82, sepTries: 24,                              // centres at least 35 degrees apart (dot below minSep): no sliver plates
  cells: 30, cellSep: 0.9,                                 // 16 more cells, 26 degrees from any other, each joins its nearest plate:
                                                           // plate outlines bend at every cell corner
  warpScale: 16000.0, warpOct: 2, warpAmp: 0.2,           // in unit-vector space (0.2 is about 4,900 units); never folds
  crustScale: 24000.0, crustOct: 3, crustBias: 0.2, shelfW: 0.10,   // a low bias: coasts wander inside plates; the coast
                                                           // noise below stands in for a fourth octave
  crustOctM: 2,                                            // the climate's upwind march reads two
  southShelf: 3.0,                                         // the shelf widens to 4 times toward the south pole: coasts buried
                                                           // under the ice sheet leave no hard outline
  contH: 250.0, contRelief: 900.0, oceanH: -2200.0, oceanRelief: 600.0, abyssH: 260.0,
  coastScale: 4000.0, coastAmp: 0.35,                     // bays and capes: enough to break the crust's long smooth contours
  alongScale: 13000.0, alongOct: 1,                        // the along-edge swell and rift openings: longer than a range is wide
  interiorScale: 9000.0, interiorOct: 2, interiorH: 1300.0, oldScale: 15000.0, oldOct: 2, oldH: 2600.0,   // the finer
                                                           // octaves would only repeat the detail and peaks noises
  oldW: 0.28,                                              // an old range's half-width, in the noise's distance from its 0.5 contour
  oldRel: 0.3, oldRelW: 0.3,                               // old ranges rise with the interior relief from 0.3, fully by 0.6: it
                                                           // cuts the crest network into pieces (no closed loops)
  oldLo: 0.85,                                             // and the peaks noise breaks their crests into worn summits, the cols
                                                           // at 85% (more reads as crumpled paper at map scale)
  blendW: 0.3,                                             // plate bias blended over this dot-product excess (wide: coasts do
                                                           // not trace plate edges)
  blendWig: 0.6,                                           // and that width varies by 60% with the interior relief
  bw: 0.11,                                                // boundary half-width (sin of the angle)
  edgeWiggle: 0.09,                                        // the landform's centre line wanders this far with the interior relief
  edgeWiggle2: 0.02,                                       // and this far with the coast noise (4,000): bends between corners; the
                                                           // two keep its slope under 0.8, so a band never folds into two
  segMin: 0.4,                                             // converging landforms swell and dip along the edge, down to this share
  junctionW: 0.05,                                         // at a corner of one plate's cells, the two cells' landforms blend
                                                           // over this lead
  capW: 0.05,                                              // at a triple junction an arm's end fades over this arc (radians)
  capThrough: 0.03, capShort: -0.06,                       // the two stronger arms reach this far past the junction and join;
                                                           // the weakest ends this far short of it
  domW: 0.15,                                              // the weakest arm is chosen over this much relative speed
  capRound: 0.7, capJit: 0.04,                             // an end is rounded (its sides 0.7 half-widths short of its tip) and
                                                           // wanders 0.04 rad along the edge with the along-edge noise
  junctionEase: 0.5,                                       // where arms overlap they are averaged, easing in over this much
  quadW: 0.03,                                             // ... and over this margin as the third plate ties with the fourth
  typeW: 0.2,                                              // a side turns from oceanic to continental over this crust value
  vRef: 0.6,                                               // relative speed for a full-size landform
  rangeH: 8000.0, arcH: 3000.0, trenchH: 2600.0, ridgeH: 1300.0, riftH: 1500.0, shoulderH: 900.0,
  apron: 0.3, coreW: 0.85,                                 // a range: a foothill apron the full width (30% of its height) and a
                                                           // crest belt 85% as wide
  crestLo: 0.25, peakLo: 0.25, peakW: 0.6,                 // in the belt the peaks noise (0.25 to 0.85, stretched) makes crests
                                                           // and valleys, the valleys at 25%
  knee: 4500.0, upCap: 9000.0,                             // uplift above the knee eases toward the cap: no lone tower
  riftOpen: 0.42, riftOpenW: 0.22,                         // a rift opens where the along-edge noise passes 0.42, fully by 0.64
  riftSeg: 0.3, riftLap: 0.08,                             // rift segments: two staggered rows of places 0.3 rad long; each
                                                           // place's valley runs half of it and overlaps the next by 2 x 0.08
  riftOff: 0.4, riftW: 0.32,                               // each valley offset by up to 0.4 half-widths (en echelon), 0.32 wide
  islSp: 0.12, islR: 0.26, islGap: 0.3,                    // arc islands: one per 0.12 rad of edge, half-length up to 0.26 of
                                                           // that, 30% of the places empty
  islStretch: 1.6, islShape: 0.3,                          // an island is 1.6 times longer than wide, its outline varied by 30%
                                                           // (at most 0.338 of a place from a centre 0.35 to 0.65 along it)
  islTop: 1000.0, platH: 0.6,                              // an island's peak above the sea (built up from the floor as it ends
                                                           // up), and the submarine arc under them, in arcH: a shallow ridge, so
                                                           // the islands rise from it with flanks no steeper than a range's
  reliefScale: 3500.0, reliefOct: 3,
  peakScale: 1300.0, peakOct: 2,                           // the peaks noise: crests about 3 degrees apart, spurs between
  hotspots: 4, chain: 6, chainStep: 0.07, hotR: 0.035, hotH: 2600.0,   // hotH: about the youngest island's peak above the sea
  hotSize: 0.6,                                            // an island's radius varies by this share of hotR
  hotShape: 0.7,                                           // and its outline by this share, with the detail noise
  hotStretch: 1.7,                                         // islands are this many times longer along the chain than across
  hotActive: 2,                                            // the youngest islands of a chain are volcanic, older ones are not
  northFade: 0.48, northFadeW: 0.27,                       // landforms fade out between these heights of the poles' own warped
                                                           // y, before the north sinks (no snowy spits in the polar sea)
  southFade: 0.58, southFadeW: 0.3, southCut: 0.85,        // and lose 85% toward the south pole (trenches and rifts all of it)
  volcPatch: 0.42, volcPatchW: 0.12,                       // volcanic fields only where the relief noise is above this: patches
  volcGain: 2.4,                                           // and the volcanic score scaled by this inside the patches
  detailScale: 1800.0, detailOct: 2, detailAmp: 140.0, detailRamp: 150.0,   // the detail fades in over the first 150 units of land
  volcanic: 0.55,                                          // the volcanic score above which land is a volcanic field
  sPlate: 3000, sPole: 3100, sType: 3200, sWarp: 3300, sCrust: 3400, sRelief: 3500, sIsland: 3600, sHot: 3700, sDetail: 3800,
  sWidth: 3900, sInterior: 3950, sOld: 3970, sRift: 3980,
};

// The nearest of the centres c[from..to) to p (ties to the lower index).
function nearest(c, from, to, p) {
  let bi = from, bd = -2;
  for (let i = from; i < to; i++) { const d = p[0] * c[i][0] + p[1] * c[i][1] + p[2] * c[i][2]; if (d > bd) { bd = d; bi = i; } }
  return bi;
}

export function makePlates(seed, P = PB) {
  const c = [], pw = [], pbias = [], plate = [];
  for (let i = 0; i < P.cells; i++) {
    // a centre that crowds an earlier one is drawn again (the first draw that keeps its distance, else the last); the
    // first cells are the plates' own centres, kept further apart
    const sep = i < P.plates ? P.minSep : P.cellSep;
    let ci = randUnit(seed, P.sPlate, i);
    for (let t = 1; t <= P.sepTries; t++) {
      let ok = true;
      for (let j = 0; j < i; j++) if (ci[0] * c[j][0] + ci[1] * c[j][1] + ci[2] * c[j][2] > sep) { ok = false; break; }
      if (ok) break;
      ci = randUnit(seed, P.sPlate, i + 64 * t);
    }
    c.push(ci);
    plate.push(i < P.plates ? i : nearest(c, 0, P.plates, ci));
  }
  for (let i = 0; i < P.plates; i++) {
    const pole = randUnit(seed, P.sPole, i), sp = P.minSpeed + (1 - P.minSpeed) * draw(seed, P.sPole + 1, i);
    pw.push([pole[0] * sp, pole[1] * sp, pole[2] * sp]);
  }
  // each plate's share of the sphere, counted on seeded points (nearest cell), and the crust noise there
  const area = pw.map(() => 0.0), under = [], cn = [];
  for (let k = 0; k < P.areaPts; k++) {
    const p = randUnit(seed, P.sArea, k), pi = plate[nearest(c, 0, P.cells, p)];
    area[pi] += 1.0 / P.areaPts;
    under.push(pi); cn.push((fbm(p[0], p[1], p[2], P.crustScale, P.crustOct, seed + P.sCrust) - 0.5) * 2.0);
  }
  // continental plates in a seeded order: a plate joins when at least half of it fits under contArea
  const rank = pw.map((_, i) => [draw(seed, P.sType, i), i]).sort((a, b) => a[0] - b[0] || a[1] - b[1]);
  let cum = 0.0;
  for (let i = 0; i < P.plates; i++) pbias.push(-P.crustBias);
  for (const [, i] of rank) if (cum + area[i] * 0.5 <= P.contArea) { pbias[i] = P.crustBias; cum += area[i]; }
  // the crust's level: lift it so landShare of the points' crust is above sea (every seed gets about as much land; read
  // unwarped here, which has the same spread)
  const cv = cn.map((v, k) => [v + pbias[under[k]], k]).sort((a, b) => b[0] - a[0] || a[1] - b[1]);
  const lift = -cv[Math.floor(P.landShare * P.areaPts)][0];
  // per cell: its plate's motion and bias
  const w = plate.map((i) => pw[i]), bias = plate.map((i) => pbias[i]);
  // hotspots: a point and a chain of older, lower islands carried off along its plate's motion
  const hot = [];
  for (let k = 0; k < P.hotspots; k++) {
    let p = randUnit(seed, P.sHot, k);
    const hh = 0.6 + 0.4 * draw(seed, P.sHot + 1, k);
    for (let j = 0; j < P.chain; j++) {
      const size = 1.0 - P.hotSize * 0.5 + P.hotSize * draw(seed, P.sHot + 3, k * 16 + j);
      // the plate under p: its velocity at p, stepped backwards
      const o = w[nearest(c, 0, P.cells, p)], v = [o[1] * p[2] - o[2] * p[1], o[2] * p[0] - o[0] * p[2], o[0] * p[1] - o[1] * p[0]];
      const vl = Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) || 1;
      hot.push([p[0], p[1], p[2], hh * (1 - j / (P.chain + 1)), P.hotR * size, j < P.hotActive ? 1.2 : 0.0, v[0] / vl, v[1] / vl, v[2] / vl]);
      const st = P.chainStep * (0.7 + 0.6 * draw(seed, P.sHot + 2, k * 16 + j));
      p = unit3(p[0] + v[0] / vl * st, p[1] + v[1] / vl * st, p[2] + v[2] / vl * st);   // older islands ride away with the plate
    }
  }
  // each chain's reach: a ball about its first island holding every island's farthest reach (an island's stretched
  // distance is at least its plain distance over hotStretch), so a point outside it skips the chain
  const hotB = [];
  for (let k = 0; k < P.hotspots; k++) {
    const t0 = hot[k * P.chain];
    let r = 0.0;
    for (let j = 0; j < P.chain; j++) {
      const t = hot[k * P.chain + j], dx = t[0] - t0[0], dy = t[1] - t0[1], dz = t[2] - t0[2];
      const e = Math.sqrt(dx * dx + dy * dy + dz * dz) + P.hotStretch * t[4] * (1.0 + P.hotShape) + 1e-6;
      if (e > r) r = e;
    }
    hotB.push([t0[0], t0[1], t0[2], r * r]);
  }
  // per pair of cells a < b (at (a * cells + b) * 9): the unit normal of their shared edge's plane, from a toward b; the
  // unit axis of that plane's great circle (for the along-edge coordinate); and a's motion less b's
  const pe = new Array(P.cells * P.cells * 9).fill(0.0);
  for (let a = 0; a < P.cells; a++) for (let b = a + 1; b < P.cells; b++) {
    const ca = c[a], cb = c[b], o = (a * P.cells + b) * 9;
    const dx = cb[0] - ca[0], dy = cb[1] - ca[1], dz = cb[2] - ca[2], dl = Math.sqrt(dx * dx + dy * dy + dz * dz);
    const ex = ca[1] * cb[2] - ca[2] * cb[1], ey = ca[2] * cb[0] - ca[0] * cb[2], ez = ca[0] * cb[1] - ca[1] * cb[0];
    const el = Math.sqrt(ex * ex + ey * ey + ez * ez);
    pe[o] = dx / dl; pe[o + 1] = dy / dl; pe[o + 2] = dz / dl; pe[o + 3] = ex / el; pe[o + 4] = ey / el; pe[o + 5] = ez / el;
    pe[o + 6] = w[a][0] - w[b][0]; pe[o + 7] = w[a][1] - w[b][1]; pe[o + 8] = w[a][2] - w[b][2];
  }
  // the centres again, flat (x, y, z per cell), and each cell's plate bias: the per-point loops read these
  const cf = new Float64Array(P.cells * 3), bf = new Float64Array(P.cells);
  for (let i = 0; i < P.cells; i++) { cf[3 * i] = c[i][0]; cf[3 * i + 1] = c[i][1]; cf[3 * i + 2] = c[i][2]; bf[i] = bias[i]; }
  // dots: scratch for one read's dot products with the centres (written before it is read on every call: not a memo)
  return { seed, P, c, cf, bf, w, bias, plate, lift, hot, hotB, pe, dots: new Float64Array(P.cells), volc: 0.0 };
}

function bump(t) { const a = t < 0 ? -t : t; return a >= 1.0 ? 0.0 : ss(1.0 - a); }
// More draws from one: a draw has 32 bits, and these read its lower 26 and 20 (multiplying by a power of 2 is exact).
function frac(v) { return v - Math.floor(v); }
// Ridged noise built octave by octave: each octave's value noise (fbm of one octave) folded to its own sharp crest
// lines and squared, so the finer octaves add spurs and gullies off the coarser crests instead of blobs.
function ridged(px, py, pz, scale, oct, s) {
  let sum = 0.0, amp = 0.5, tot = 0.0, sc = scale;
  for (let o = 0; o < oct; o++) {
    const r = 1.0 - Math.abs(2.0 * fbm(px, py, pz, sc, 1, s + o * 101) - 1.0);
    sum += amp * r * r; tot += amp; amp *= 0.5; sc *= 0.5;
  }
  return sum / tot;
}

// The along-edge coordinate of q on the edge between cells a and b (a < b): the sine of the arc from the edge's midpoint.
function sAlong(S, a, b, qx, qy, qz) {
  const o = (a * S.P.cells + b) * 9, pe = S.pe;
  return qx * pe[o + 3] + qy * pe[o + 4] + qz * pe[o + 5];
}

// How fast cells a and b (a < b) close on each other across their edge at q, over vRef (negative: they part).
function closing(S, a, b, qx, qy, qz) {
  const o = (a * S.P.cells + b) * 9, pe = S.pe;
  const dq = qx * pe[o] + qy * pe[o + 1] + qz * pe[o + 2];
  const bx = pe[o] - qx * dq, by = pe[o + 1] - qy * dq, bz = pe[o + 2] - qz * dq;   // across the edge, from a toward b
  const wx = pe[o + 6], wy = pe[o + 7], wz = pe[o + 8];
  const rvx = wy * qz - wz * qy, rvy = wz * qx - wx * qz, rvz = wx * qy - wy * qx;   // a's velocity less b's
  return (rvx * bx + rvy * by + rvz * bz) / (Math.sqrt(bx * bx + by * by + bz * bz) * S.P.vRef);
}

// Islands strung along the edge between cells a and b (an island arc): the edge is cut into places islSp long by the
// along-edge coordinate s, and each place holds one island or none, at a seeded spot and size that keep it inside its
// place, so the field is continuous where places meet. An island is longer along the arc than across, and its outline
// wanders with the detail noise dn. x and xc are across the edge in half-widths of wr radians.
function beads(S, a, b, s, x, xc, wr, dn) {
  const P = S.P, t = s / P.islSp, j = Math.floor(t), r1 = draw(S.seed, P.sIsland + 1, (a * P.cells + b) * 64 + (j & 63));
  if (r1 < P.islGap) return 0.0;
  const uc = 0.5 + 0.3 * (frac(r1 * 64.0) - 0.5);
  const la = P.islR * (0.5 + 0.5 * frac(r1 * 4096.0)) * (1.0 + P.islShape * (dn - 0.5) * 2.0);   // its half-length, in places
  const du = (t - j - uc) / la, dx = (x - xc) * wr * P.islStretch / (la * P.islSp);
  return (0.85 + 0.15 * r1) * ss(1.5 - 1.5 * Math.sqrt(du * du + dx * dx));   // a cone, flat-topped a third of the way in
}

const PAIRS = [[0, 1, 2], [0, 2, 1], [1, 2, 0]];       // the pairs among the three nearest cells, and each pair's rival

// Pair j's strength at a junction: how fast its plates close or part, held as the pair keeps its place (0: no pair).
function strength(pa, cv, hold, j) {
  return pa[j] < 0 ? 0.0 : (cv[j] < 0.0 ? -cv[j] : cv[j]) * hold[PAIRS[j][0]] * hold[PAIRS[j][1]];
}

// The ground at p. coarse: fewer octaves (the climate's upwind march). Sets S.volc (0..1) as a side output.
export function plateGround(S, px, py, pz, coarse = false) {
  const P = S.P, seed = S.seed, n = P.cells;
  const wo = coarse ? 1 : P.warpOct;
  const qx0 = px + P.warpAmp * (fbm(px, py, pz, P.warpScale, wo, seed + P.sWarp) - 0.5) * 2.0;
  const qy0 = py + P.warpAmp * (fbm(px, py, pz, P.warpScale, wo, seed + P.sWarp + 17) - 0.5) * 2.0;
  const qz0 = pz + P.warpAmp * (fbm(px, py, pz, P.warpScale, wo, seed + P.sWarp + 31) - 0.5) * 2.0;
  const q = unit3(qx0, qy0, qz0), qx = q[0], qy = q[1], qz = q[2];
  // the four nearest cells (the fourth only says how near the third is to losing its place)
  let i1 = 0, i2 = 0, i3 = 0, d1 = -9, d2 = -9, d3 = -9, d4 = -9;
  const cf = S.cf, dots = S.dots;
  for (let i = 0; i < n; i++) {
    const d = qx * cf[3 * i] + qy * cf[3 * i + 1] + qz * cf[3 * i + 2];
    dots[i] = d;
    if (d > d1) { d4 = d3; i3 = i2; d3 = d2; i2 = i1; d2 = d1; i1 = i; d1 = d; }
    else if (d > d2) { d4 = d3; i3 = i2; d3 = d2; i2 = i; d2 = d; }
    else if (d > d3) { d4 = d3; i3 = i; d3 = d; }
    else if (d > d4) d4 = d;
  }
  const ids = [i1, i2, i3], ex = [0.0, d1 - d2, d1 - d3], e4 = d1 - d4;
  // each cell's hold on its place among the three: 0 where it ties with the fourth, so nothing jumps when they swap
  const hold = [ss(e4 / P.quadW), ss((e4 - ex[1]) / P.quadW), ss((e4 - ex[2]) / P.quadW)];
  // the poles' own warped y (poles.mjs): landforms fade toward the north before it sinks and toward the south before
  // the ice sheet in the same coordinate, so nothing pokes through or notches the polar edge (the march: plain y). The
  // warp moves y by at most PP.warpAmp, so between the fades it cannot matter and is not read
  const yy = coarse || (py + PP.warpAmp <= P.northFade && -py + PP.warpAmp <= P.southFade) ? py
    : py + (fbm(px, py, pz, PP.warpScale, 2, seed + PP.s) - 0.5) * 2.0 * PP.warpAmp;
  const nF = 1.0 - ss((yy - P.northFade) / P.northFadeW), sF = ss((-yy - P.southFade) / P.southFadeW);
  const polar = nF * (1.0 - P.southCut * sF), polarD = nF * (1.0 - sF);
  // the interior relief (its first use: the blend below; the march reads it flat)
  const rel = coarse ? 0.5 : fbm(px, py, pz, P.interiorScale, P.interiorOct, seed + P.sInterior);
  // crust: one noise, the plates' biases blended near their shared edges, over a width that swells and narrows with the
  // relief (a blend of constant width draws coasts parallel to the plate edges). Every cell within the width takes part,
  // not only the three nearest: a cell dropping out of the three would draw a straight coast where it ties with the fourth
  const bl = P.blendW * (1.0 + (rel - 0.5) * 2.0 * P.blendWig);
  let bw = 0.0, bs = 0.0;
  for (let i = 0; i < n; i++) {
    const e = d1 - dots[i];
    if (e < bl) { const g = ss(1.0 - e / bl); bw += g; bs += S.bf[i] * g; }
  }
  let noise = (fbm(qx, qy, qz, P.crustScale, coarse ? P.crustOctM : P.crustOct, seed + P.sCrust) - 0.5) * 2.0 + S.lift;   // at the warped
                                                           // point too: its long contours bend with the plates
  let coastN = 0.5;
  if (!coarse) { coastN = fbm(px, py, pz, P.coastScale, 2, seed + P.sCrust + 9); noise += (coastN - 0.5) * P.coastAmp; }   // bays and capes
  const crust = noise + bs / bw, sw = P.shelfW * (1.0 + P.southShelf * sF);
  const land = ss((crust + sw) / (2.0 * sw));
  let h = P.oceanH + noise * P.oceanRelief + (P.contH + crust * P.contRelief - P.oceanH - noise * P.oceanRelief) * land;
  let widthMul = 1.0, oldv = 0.0;
  if (!coarse) {
    // continental interiors: rolling relief and old worn ranges (rounded ridges along a noise contour, read at the warped
    // point turned by a fixed rotation (an integer matrix over 9), so the crests line up with neither the noise lattice
    // nor the poles; textured below, with the boundary landforms)
    h += land * (rel - 0.38) * P.interiorH + (1.0 - land) * (rel - 0.5) * 2.0 * P.abyssH;
    if (land > 0.0 && rel > P.oldRel) {                   // (read only where it shows)
      const t = (2.0 * fbm((qx - 4.0 * qy + 8.0 * qz) / 9.0, (8.0 * qx + 4.0 * qy + qz) / 9.0, (-4.0 * qx + 7.0 * qy + 4.0 * qz) / 9.0,
        P.oldScale, P.oldOct, seed + P.sOld) - 1.0) / P.oldW, u = t * t;
      const old = u < 1.0 ? 1.0 - u : 0.0;                // a rounded crest, no knife edge
      oldv = land * old * old * P.oldH * ss((rel - P.oldRel) / P.oldRelW) * polar;
    }
    widthMul = 0.7 + 0.6 * rel;                            // boundary landforms widen and narrow with the same relief
  }
  // boundary landforms. First, each pair of different plates among the three nearest cells, ordered by index (so both
  // sides see the same pair), and the signed distance to its edge, positive on a's side. How fast the two close (cv) is
  // read only where needed (ready: 1)
  const pa = [-1, -1, -1], pb = [0, 0, 0], sg = [0.0, 0.0, 0.0], cv = [0.0, 0.0, 0.0], ready = [0, 0, 0];
  for (let k = 0; k < 3; k++) {
    let a = ids[PAIRS[k][0]], b = ids[PAIRS[k][1]];
    if (S.plate[a] === S.plate[b]) continue;              // two cells of one plate: no edge between them
    if (a > b) { const t = a; a = b; b = t; }
    const o = (a * n + b) * 9;
    pa[k] = a; pb[k] = b; sg[k] = -(qx * S.pe[o] + qy * S.pe[o + 1] + qz * S.pe[o + 2]);
  }
  let up = 0.0, apr = 0.0, crest = 0.0, down = 0.0, volc = 0.0, gsum = 0.0, isles = 0.0;
  const wig = (rel - 0.5) * 2.0 * P.edgeWiggle + (coastN - 0.5) * 2.0 * P.edgeWiggle2, wr = P.bw * widthMul;
  const sea = 1.0 - land;                                  // trenches only where the crust is ocean floor
  let along = -1.0;                                        // the along-edge noise, read once where a landform is live
  let dn = -1.0;                                           // the detail noise, read once where something needs it
  for (let k = 0; k < 3; k++) {
    if (pa[k] < 0) continue;
    const ka = PAIRS[k][0], kb = PAIRS[k][1], kc = PAIRS[k][2], a = pa[k], b = pb[k], c = ids[kc];
    const x = (sg[k] + wig) / wr;
    if (x > 1.2 || x < -1.2) continue;                    // every landform lies within 1.2 of its edge (a rift shoulder
                                                           // reaches 0.8 past its offset valley)
    let g;
    if (coarse || S.plate[c] === S.plate[a] || S.plate[c] === S.plate[b]) {
      // the rival is a cell of one of the two plates: the outline bends at that cell's corner and runs on, and the two
      // cells' landforms blend by the pair's lead over the rival (the march gates every junction so: cheaper, and it
      // only needs the heights' broad lie)
      const lead = ex[kc] - (ex[ka] > ex[kb] ? ex[ka] : ex[kb]);
      g = ss(0.5 + lead / (2.0 * P.junctionW));
    } else {
      // a triple junction J (the point of the edge as near the rival as a and b): the landform keeps its width to a
      // blunt end there. The two stronger arms reach just past J and join; the weakest stops short (a T, not three
      // spokes meeting at a point)
      const ca = S.c[a], cc = S.c[c], o = (a * n + b) * 9, nx = S.pe[o], ny = S.pe[o + 1], nz = S.pe[o + 2];
      const ux = -nx, uy = -ny, uz = -nz, vx = ca[0] - cc[0], vy = ca[1] - cc[1], vz = ca[2] - cc[2];
      let jx = uy * vz - uz * vy, jy = uz * vx - ux * vz, jz = ux * vy - uy * vx;
      const jl = Math.sqrt(jx * jx + jy * jy + jz * jz), js = jx * ca[0] + jy * ca[1] + jz * ca[2] < 0.0 ? -1.0 / jl : 1.0 / jl;
      jx *= js; jy *= js; jz *= js;
      const tx = ny * jz - nz * jy, ty = nz * jx - nx * jz, tz = nx * jy - ny * jx;   // along the edge at J
      const s = (tx * vx + ty * vy + tz * vz < 0.0 ? -1.0 : 1.0) * (qx * tx + qy * ty + qz * tz);   // from J, away from the rival
      // each pair's strength: how fast its two plates close or part, held as the pair keeps its place
      for (let j = 0; j < 3; j++) if (pa[j] >= 0 && ready[j] === 0) { cv[j] = closing(S, pa[j], pb[j], qx, qy, qz); ready[j] = 1; }
      const o1 = strength(pa, cv, hold, (k + 1) % 3), o2 = strength(pa, cv, hold, (k + 2) % 3);
      const weak = ss(0.5 + ((o1 < o2 ? o1 : o2) - strength(pa, cv, hold, k)) / P.domW);
      if (along < 0.0) along = coarse ? 0.5 : fbm(px, py, pz, P.alongScale, P.alongOct, seed + P.sWidth + 5);
      const reach = P.capThrough + (P.capShort - P.capThrough) * weak + (along - 0.5) * 2.0 * P.capJit - P.capRound * wr * x * x;
      g = ss((s + reach) / P.capW);
    }
    const gate = (1.0 - hold[kc] * (1.0 - g)) * hold[ka] * hold[kb];   // as the rival ties with the fourth, either form is 1
    if (gate <= 0.0) continue;
    gsum += gate * bump(x / 1.1);
    // each side's type as a weight (1: continental), so a landform blends into the next where the crust changes
    const tA = ss(0.5 + (noise + S.bias[a]) / P.typeW), tB = ss(0.5 + (noise + S.bias[b]) / P.typeW);
    if (along < 0.0) along = coarse ? 0.5 : fbm(px, py, pz, P.alongScale, P.alongOct, seed + P.sWidth + 5);
    if (ready[k] === 0) { cv[k] = closing(S, a, b, qx, qy, qz); ready[k] = 1; }
    const conv = cv[k];                                    // > 0: a and b close on each other
    if (conv > 0.0) {
      const kk = ss(conv) * gate * (P.segMin + (1.0 - P.segMin) * ss((along - 0.2) / 0.5));
      const cc = tA * tB, ab = tA * (1.0 - tB), ba = (1.0 - tA) * tB, oo = (1.0 - tA) * (1.0 - tB);
      if (cc > 0.0) {
        // two continents: a foothill apron the full width and a crest belt inside it (the peaks noise, below, cuts the
        // belt into crests and saddles with spurs off them)
        apr += P.rangeH * kk * cc * P.apron * bump(x);
        crest += P.rangeH * kk * cc * (1.0 - P.apron) * bump(x / P.coreW);
      }
      // ocean under continent (ab: b goes under a; ba: a under b) and ocean-ocean (b under a): the trench on the side
      // that sinks, the arc on the other: a volcanic belt where the crust is land, a submarine ridge with islands at sea
      let s = 0.0, sDone = false;
      for (let m = 0; m < 3; m++) {
        const w = m === 0 ? ab : (m === 1 ? ba : oo), xt = m === 1 ? 0.16 : -0.16, xa = m === 0 ? 0.6 : (m === 1 ? -0.6 : 0.5);
        if (w <= 0.0) continue;
        down += P.trenchH * kk * w * sea * bump((x - xt) / 0.2);
        const belt = bump((x - xa) / 0.45);
        if (belt <= 0.0) continue;
        up += P.arcH * kk * w * (belt * land + P.platH * belt * sea);
        volc += kk * w * belt * land;
        if (!coarse && sea > 0.0) {
          if (!sDone) { s = sAlong(S, a, b, qx, qy, qz); sDone = true; }
          if (dn < 0.0) dn = fbm(px, py, pz, P.detailScale, P.detailOct, seed + P.sDetail);
          const isl = ss(2.0 * kk) * w * sea * beads(S, a, b, s, x, xa, wr, dn);   // a volcano: its height hardly
          isles += isl; volc += isl;                       // depends on how fast the plates close
        }
      }
    } else if (conv < 0.0) {
      const kk = ss(-conv) * gate;
      const oo = (1.0 - tA) * (1.0 - tB);
      up += P.ridgeH * kk * oo * bump(x / 0.8);
      const kr = kk * (1.0 - oo) * ss((along - P.riftOpen) / P.riftOpenW);   // rifts open in stretches
      if (kr > 0.0 && !coarse) {                            // (the march skips rifts)
        // segments in two staggered rows whose weights sum to 1, each mostly alone with a short overlap: each valley offset
        // across the edge (en echelon), of its own depth, with one raised shoulder on a seeded side (a tilted block)
        const s = sAlong(S, a, b, qx, qy, qz);
        for (let f = 0; f < 2; f++) {
          const t = s / P.riftSeg + 0.5 * f, j = Math.floor(t), r = draw(seed, P.sRift, ((a * P.cells + b) * 2 + f) * 64 + (j & 63));
          const u = t - j - 0.5, dep = kr * ss((0.25 + P.riftLap - (u < 0.0 ? -u : u)) / (2.0 * P.riftLap)) * (0.55 + 0.45 * frac(r * 4096.0));
          const xr = x - (r - 0.5) * 2.0 * P.riftOff, side = frac(r * 64.0) < 0.5 ? -1.0 : 1.0;
          down += P.riftH * dep * bump(xr / P.riftW);
          const tb = side * xr;                            // the shoulder: steep toward the valley, a long gentle back slope
          up += P.shoulderH * dep * (0.6 + 0.8 * along) * ss((tb - 0.15) / 0.25) * (1.0 - ss((tb - 0.4) / 0.4));
          volc += 0.7 * dep * bump(xr / 0.22);
        }
      }
    }
  }
  // where arms overlap (a junction, or a weak arm's end against a strong one) their landforms are averaged, not stacked:
  // divided by a smooth max(1, gsum) that eases in over junctionEase (a hard max leaves a slope break along gsum = 1)
  const ge = gsum - 1.0, E = P.junctionEase;
  const norm = 1.0 / (ge <= 0.0 ? 1.0 : (ge < E ? 1.0 + ge * ge / (2.0 * E) : gsum - E * 0.5));
  up *= norm * polar; apr *= norm * polar; volc *= norm * polar; isles *= norm * polar;
  crest *= norm * polarD; down *= norm * polarD;           // the ice sheet keeps a little swell, but no crests or troughs
  // hotspot chains: islands of seeded sizes with ragged outlines, built up from the sea floor, so the young ones break
  // the surface and the old ones sink back to seamounts; only the youngest are volcanic
  const depth = h < -200.0 ? -h - 100.0 : (h < 0.0 ? h * h / 400.0 : 0.0);   // a smooth max(0, -h)
  let hot = 0.0;
  if (!coarse) for (let k = 0; k < P.hotspots; k++) {
    const b = S.hotB[k], bx = px - b[0], by = py - b[1], bz = pz - b[2];
    if (bx * bx + by * by + bz * bz >= b[3]) continue;    // out of this chain's reach
    for (let j = k * P.chain; j < (k + 1) * P.chain; j++) {
      const t = S.hot[j];
      const ddx = px - t[0], ddy = py - t[1], ddz = pz - t[2], dc = ddx * t[6] + ddy * t[7] + ddz * t[8];   // unwarped: chains keep
                                                           // their spacing
      const d2 = ddx * ddx + ddy * ddy + ddz * ddz - (1.0 - 1.0 / (P.hotStretch * P.hotStretch)) * dc * dc;   // shorter along the chain
      const rr = t[4] * (1.0 + P.hotShape);
      if (d2 < rr * rr) {
        const d = Math.sqrt(d2 > 0.0 ? d2 : 0.0);
        if (dn < 0.0) dn = fbm(px, py, pz, P.detailScale, P.detailOct, seed + P.sDetail);
        const v = t[3] * ss(1.0 - d / (t[4] * (1.0 + P.hotShape * (dn - 0.5) * 2.0))) * (1.0 - land * 0.85) * polar;
        hot += v * (P.hotH + depth); volc += v * t[5];
      }
    }
  }
  let lift = up + apr + crest, rough = 0.5;
  if (!coarse) {
    if (lift > 0.0 || volc > 0.0 || hot > 0.0) {
      rough = fbm(px, py, pz, P.reliefScale, P.reliefOct, seed + P.sRelief);
      volc *= P.volcGain * ss((rough - P.volcPatch) / P.volcPatchW);   // volcanic fields come in patches, not bands
    }
    if (lift > 0.0 || oldv > 0.0) {
      const peaks = ridged((px - 4.0 * py + 8.0 * pz) / 9.0, (8.0 * px + 4.0 * py + pz) / 9.0, (-4.0 * px + 7.0 * py + 4.0 * pz) / 9.0,
        P.peakScale, P.peakOct, seed + P.sRelief + 7);   // ridged too, so turned the same way
      const pk = ss((peaks - P.peakLo) / P.peakW);       // its crest lines, stretched to 0..1
      lift = up * (0.25 + 1.5 * rough) * (0.75 + 0.5 * pk) + apr * (0.5 + rough)
        + crest * (P.crestLo + (1.0 - P.crestLo) * pk) * (0.6 + 0.8 * rough) + oldv * (P.oldLo + (1.0 - P.oldLo) * pk);
    }
  }
  if (lift > P.knee) { const e = lift - P.knee; lift = P.knee + e / (1.0 + e / (P.upCap - P.knee)); }   // eased toward upCap
  h += lift + hot * (0.75 + 0.5 * rough) - down;
  if (isles > 0.0) {                                       // arc islands, built up from the floor as it ends up (the arc's
    const dd = h < -200.0 ? -h - 100.0 : (h < 0.0 ? h * h / 400.0 : 0.0);   // shallow ridge and the trench included)
    h += isles * (P.islTop + dd);
  }
  if (!coarse && h > 0.0) {
    if (dn < 0.0) dn = fbm(px, py, pz, P.detailScale, P.detailOct, seed + P.sDetail);
    h += (dn - 0.5) * 2.0 * P.detailAmp * ss(h / P.detailRamp);
  }
  S.volc = volc > 1.0 ? 1.0 : volc;
  return h;
}
