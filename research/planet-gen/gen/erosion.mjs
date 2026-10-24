// Approach C: erosion-lite on a coarse cube-sphere grid, built once per planet, then read per column.
//   1. Heights at the cell centres from the input ground, rain from the climate (approach A's precipitation).
//   2. Each pass: fill the depressions from the sea inward (priority flood, so every land cell drains; a deep fill is a
//      lake), route each cell to its steepest lower neighbour, accumulate the rain downstream (rivers), carve with an
//      implicit stream-power step (h = (h + F h_downstream) / (1 + F), F = K sqrt(flow) / distance: stable at any K),
//      then slump slopes steeper than the talus angle (a Jacobi pass, order-free).
//   3. Rivers: each river cell's run to its receiver becomes a curve (Hermite through the cell centres, a node's tangent
//      from its main donor to its receiver) pushed sideways by a meander and a longer wander that run up from the mouth,
//      within a budget that keeps the channel on its valley floor, sampled into a short polyline. A run into the sea ends
//      at the coast. Every cell lists the river runs whose channel can reach it.
//   4. Read: the input ground plus the bilinear carve at the point; a lake's level where the fill is deep; a river where
//      the point is within a channel's half-width of a listed run's polyline (a channel cut into the column).
// Deterministic: the heap breaks ties by cell index, the Jacobi passes are order-free, the arithmetic is + - * / sqrt
// floor, the series atan and the sim's sin and smoothstep (det.mjs), the meanders' jitter and envelopes keyed draws.
// Grid cost is the planet's set-up; the read is a few lookups a column.
import { R, sin, cos, PI, atanf, unit3, draw, ss } from '../lib/det.mjs';

export const PC = {
  N: 128,                     // cells along a cube face's edge: 6 N^2 cells (128: 98,304 cells of about 300 units)
  passes: 4, K: 0.06, eps: 0.05, talus: 1.1, slump: 0.22, thermal: 2,
  lakeMin: 90.0,              // a fill deeper than this (units) is a lake (shallower hollows drain or dry out)
  lakeRain: 700.0,            // ... where it rains at least this much (mm); drier basins stay dry hollows
  riverFlow: 60.0,            // flow (cells of 1,000 mm of rain) that makes a river
  carve0: 18.0, carve1: 7.0,  // a river's channel depth at the column: carve0 + carve1 * sqrt(flow / riverFlow)
  width0: 14.0, width1: 9.0,  // its half-width (units): width0 + width1 * sqrt(flow / riverFlow)
  riverSteps: 8,              // polyline samples along a river's run from a cell centre to its receiver's
  bend: 0.45,                 // the meander and the wander together move the channel at most this share of a cell
  perch: 0.6,                 // ... and at most so far that the valley side rises this share of the channel's cut
  tight: 0.15,                // the curve's own corner cut (a share of a cell); a budget under it shrinks the node's tangent
  meanderW: 2.0,              // the meander's amplitude: this many half-widths (within what the wander leaves) ...
  meanderJit: 0.3,            // ... each node's cut by up to this share (a keyed draw) ...
  envL: 3.0,                  // ... times an envelope along the branch, keyed noise in 0..1 with a step of this many cells
  waveW: 22.0,                // the meander's wavelength: this many half-widths (about 11 channel widths) ...
  waveMax: 3.0,               // ... at most this many cells, so a wide river still bends
  waveJit: 0.5,               // each run's phase step varies by up to this share either way (a keyed draw)
  wlLo: 0.6, wlHi: 1.6,       // each branch's wavelengths (both waves) times a keyed factor in this range
  wanderA: 0.12,              // a second, longer wave on every river (its amplitude, a share of a cell) ...
  wanderS: 0.32,              // ... this much on a long straight run of the routing ...
  wanderL: 4.0,               // ... and its wavelength (cells), so a straight run of the routing bows as a whole ...
  wanderLo: 0.35,             // ... and an envelope from this to 1 (keyed noise along the branch, on the meander's lattice)
  straightCos: 0.95,          // a node whose routing turns less than this (cosine) is straight ...
  straightN: 2.0,             // ... and a run of 1 + this many straight nodes gets the full wanderS
  tribTan: 0.3,               // a tributary meets its main stem with at least this share of the stem's tangent
  mouthIt: 6,                 // bisection steps that find where a run into the sea crosses the coast
  stream: 7100,               // keyed-draw streams stream .. stream + 7 (mouth phases, amplitude, steps, envelopes, wavelengths)
};

// Face f: normal n, tangents u, v (u x v = n).
const FACES = [
  [[1, 0, 0], [0, 0, -1], [0, 1, 0]], [[-1, 0, 0], [0, 0, 1], [0, 1, 0]],
  [[0, 1, 0], [1, 0, 0], [0, 0, -1]], [[0, -1, 0], [1, 0, 0], [0, 0, 1]],
  [[0, 0, 1], [1, 0, 0], [0, 1, 0]], [[0, 0, -1], [-1, 0, 0], [0, 1, 0]],
];

function faceOf(px, py, pz) {
  const ax = Math.abs(px), ay = Math.abs(py), az = Math.abs(pz);
  if (ax >= ay && ax >= az) return px > 0 ? 0 : 1;
  if (ay >= az) return py > 0 ? 2 : 3;
  return pz > 0 ? 4 : 5;
}
// Continuous cell coordinates (0..N) on face f for a unit vector (equi-angular: a = atan(x) * 4 / pi).
function faceCoords(f, px, py, pz, N) {
  const F = FACES[f];
  const dn = px * F[0][0] + py * F[0][1] + pz * F[0][2];
  const x = (px * F[1][0] + py * F[1][1] + pz * F[1][2]) / dn, y = (px * F[2][0] + py * F[2][1] + pz * F[2][2]) / dn;
  return [(atanf(x) * 4.0 / PI + 1.0) * 0.5 * N, (atanf(y) * 4.0 / PI + 1.0) * 0.5 * N];
}
function cellDir(f, fi, fj, N) {
  const F = FACES[f];
  const a = ((fi + 0.5) / N * 2.0 - 1.0) * PI / 4.0, b = ((fj + 0.5) / N * 2.0 - 1.0) * PI / 4.0;
  const x = sin(a) / cos(a), y = sin(b) / cos(b);
  return unit3(F[0][0] + F[1][0] * x + F[2][0] * y, F[0][1] + F[1][1] * x + F[2][1] * y, F[0][2] + F[1][2] * x + F[2][2] * y);
}
function cellOf(px, py, pz, N) {
  const f = faceOf(px, py, pz), [u, v] = faceCoords(f, px, py, pz, N);
  const i = Math.min(N - 1, Math.max(0, Math.floor(u))), j = Math.min(N - 1, Math.max(0, Math.floor(v)));
  return (f * N + j) * N + i;
}

// A binary min-heap of (key, index), ties by index.
class Heap {
  constructor(n) { this.k = new Float64Array(n); this.v = new Int32Array(n); this.n = 0; }
  less(a, b) { return this.k[a] < this.k[b] || (this.k[a] === this.k[b] && this.v[a] < this.v[b]); }
  swap(a, b) { const k = this.k[a]; this.k[a] = this.k[b]; this.k[b] = k; const v = this.v[a]; this.v[a] = this.v[b]; this.v[b] = v; }
  push(key, val) {
    let i = this.n++; this.k[i] = key; this.v[i] = val;
    while (i > 0) { const p = (i - 1) >> 1; if (!this.less(i, p)) break; this.swap(i, p); i = p; }
  }
  pop() {
    const v = this.v[0]; this.n--;
    if (this.n > 0) {
      this.k[0] = this.k[this.n]; this.v[0] = this.v[this.n];
      let i = 0;
      for (;;) { const l = 2 * i + 1, r = l + 1; let m = i; if (l < this.n && this.less(l, m)) m = l; if (r < this.n && this.less(r, m)) m = r; if (m === i) break; this.swap(i, m); i = m; }
    }
    return v;
  }
}

// Build the grid for one planet. groundFn(px, py, pz) is the input height; rainFn(px, py, pz, h) the precipitation (mm);
// seed keys the meanders' draws.
export function buildErosion(groundFn, rainFn, P = PC, seed = 0) {
  const N = P.N, n = 6 * N * N, t = {};
  let t0 = performance.now();
  const dir = new Float64Array(n * 3);
  for (let f = 0; f < 6; f++) for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) {
    const c = (f * N + j) * N + i, d = cellDir(f, i, j, N);
    dir[c * 3] = d[0]; dir[c * 3 + 1] = d[1]; dir[c * 3 + 2] = d[2];
  }
  // 8 neighbours (7 at a cube corner): step on the face's plane, reproject, find the cell (works across face edges)
  const nb = new Int32Array(n * 8).fill(-1), nd = new Float64Array(n * 8);
  for (let f = 0; f < 6; f++) for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) {
    const c = (f * N + j) * N + i;
    let k = 0;
    for (let dj = -1; dj <= 1; dj++) for (let di = -1; di <= 1; di++) {
      if (!di && !dj) continue;
      let m;
      const ii = i + di, jj = j + dj;
      if (ii >= 0 && jj >= 0 && ii < N && jj < N) m = (f * N + jj) * N + ii;
      else { const d = cellDir(f, ii, jj, N); m = cellOf(d[0], d[1], d[2], N); }
      if (m === c) continue;
      let dup = false; for (let q = 0; q < k; q++) if (nb[c * 8 + q] === m) dup = true;
      if (dup) continue;
      nb[c * 8 + k] = m;
      const ex = dir[c * 3] - dir[m * 3], ey = dir[c * 3 + 1] - dir[m * 3 + 1], ez = dir[c * 3 + 2] - dir[m * 3 + 2];
      nd[c * 8 + k] = Math.sqrt(ex * ex + ey * ey + ez * ez) * R;
      k++;
    }
  }
  t.gridMs = performance.now() - t0; t0 = performance.now();
  const h0 = new Float64Array(n), rain = new Float64Array(n);
  for (let c = 0; c < n; c++) h0[c] = groundFn(dir[c * 3], dir[c * 3 + 1], dir[c * 3 + 2]);
  t.heightMs = performance.now() - t0; t0 = performance.now();
  for (let c = 0; c < n; c++) rain[c] = h0[c] >= 0 ? rainFn(dir[c * 3], dir[c * 3 + 1], dir[c * 3 + 2], h0[c]) : 0.0;
  t.rainMs = performance.now() - t0; t0 = performance.now();

  const h = Float64Array.from(h0), fill = new Float64Array(n), recv = new Int32Array(n), order = new Int32Array(n), flow = new Float64Array(n);
  const done = new Uint8Array(n), heap = new Heap(n * 2);
  let nOrder = 0;
  function route() {
    done.fill(0); heap.n = 0; nOrder = 0;
    for (let c = 0; c < n; c++) if (h[c] < 0.0) { fill[c] = h[c]; done[c] = 1; recv[c] = -1; }
    // seed the flood with the coast: every ocean cell that touches land, at sea level
    for (let c = 0; c < n; c++) if (done[c]) {
      for (let q = 0; q < 8; q++) { const m = nb[c * 8 + q]; if (m >= 0 && !done[m]) { heap.push(0.0, c); break; } }
    }
    // pop in rising order of the filled surface: that order is the drainage order (a receiver comes before its donors)
    while (heap.n) {
      const c = heap.pop();
      if (h[c] >= 0.0) order[nOrder++] = c;
      for (let q = 0; q < 8; q++) {
        const m = nb[c * 8 + q];
        if (m < 0 || done[m]) continue;
        done[m] = 1;
        const lo = (done[c] && h[c] < 0.0 ? 0.0 : fill[c]) + P.eps;
        fill[m] = h[m] > lo ? h[m] : lo;
        heap.push(fill[m], m);
      }
    }
    // receivers: the steepest lower neighbour on the filled surface (the sea counts as level 0)
    for (let o = 0; o < nOrder; o++) {
      const c = order[o];
      let best = -1, bs = 0.0;
      for (let q = 0; q < 8; q++) {
        const m = nb[c * 8 + q]; if (m < 0) continue;
        const fm = h[m] < 0.0 ? 0.0 : fill[m];
        const s = (fill[c] - fm) / nd[c * 8 + q];
        if (s > bs) { bs = s; best = m; }
      }
      recv[c] = best;
    }
    // flow: rain in cells of 1,000 mm, passed downstream from the highest cell
    for (let c = 0; c < n; c++) flow[c] = h[c] < 0.0 ? 0.0 : rain[c] / 1000.0;
    for (let o = nOrder - 1; o >= 0; o--) { const c = order[o], r = recv[c]; if (r >= 0 && h[r] >= 0.0) flow[r] += flow[c]; }
  }
  const dist = (c, m) => { for (let q = 0; q < 8; q++) if (nb[c * 8 + q] === m) return nd[c * 8 + q]; return 300.0; };
  const tmp = new Float64Array(n);
  for (let pass = 0; pass < P.passes; pass++) {
    route();
    // implicit stream power, from the sea upward (a cell's receiver is final before the cell)
    for (let o = 0; o < nOrder; o++) {
      const c = order[o], r = recv[c];
      if (r < 0 || fill[c] - h[c] > P.lakeMin) continue;
      const hr = h[r] < 0.0 ? 0.0 : (fill[r] - h[r] > P.lakeMin ? fill[r] : h[r]);
      if (h[c] <= hr) continue;
      const F = P.K * Math.sqrt(flow[c]) / dist(c, r) * 100.0;
      h[c] = (h[c] + F * hr) / (1.0 + F);
    }
    // thermal: material over the talus slope slides to lower neighbours (Jacobi: all moves from the same heights)
    for (let tp = 0; tp < P.thermal; tp++) {
      tmp.fill(0.0);
      for (let c = 0; c < n; c++) {
        if (h[c] < 0.0) continue;
        for (let q = 0; q < 8; q++) {
          const m = nb[c * 8 + q]; if (m < 0) continue;
          const ex = h[c] - h[m] - P.talus * nd[c * 8 + q];
          if (ex > 0.0) { const mv = ex * P.slump / 8.0; tmp[c] -= mv; tmp[m] += mv; }
        }
      }
      for (let c = 0; c < n; c++) h[c] += tmp[c];
    }
  }
  route();
  t.erodeMs = performance.now() - t0;
  const dh = new Float32Array(n), lake = new Float32Array(n);
  for (let c = 0; c < n; c++) { dh[c] = h[c] - h0[c]; lake[c] = h[c] >= 0.0 && fill[c] - h[c] > P.lakeMin && rain[c] > P.lakeRain ? fill[c] : -1e9; }
  let rivers = 0; for (let c = 0; c < n; c++) if (h[c] >= 0.0 && flow[c] >= P.riverFlow) rivers++;
  t0 = performance.now();
  const RP = riverPaths(P, N, n, dir, nb, nd, order, nOrder, recv, flow, h, seed, groundFn);
  t.riverMs = performance.now() - t0;
  return { P, N, n, dir, dh, lake, flow: Float32Array.from(flow), recv: Int32Array.from(recv), h: Float32Array.from(h), t, cells: n, riverCells: rivers, ...RP };
}

// The river runs. A run goes from a river cell m (land, flow over riverFlow, a receiver) to its receiver r. Its curve is
// Hermite through the two centres; a node's tangent is (receiver - main donor) / 2, the main donor being its largest-flow
// donor (ties by index), so a main stem is smooth through every node and a tributary meets it along the stem's tangent
// (scaled down when it comes in against it, at least tribTan). Two waves push the curve along the normal (position x
// tangent): the meander, its wavelength from the channel's width, and the wander, longer. A branch (a main stem up from
// its mouth or its junction) keys an envelope on the meander's amplitude (keyed noise along the branch, so some stretches
// run nearly straight and others swing) and a factor on both wavelengths. Each node has a lateral budget, bend of a cell,
// less where the grid's heights rise steeply across the flow, so the channel stays on its valley floor (a small budget
// shrinks the node's tangent too, so the curve cuts no corner up a valley side). The wander takes wanderA of a cell of
// it, up to wanderS on a long straight run of the routing, and the meander what is left. Each phase counts wavelengths
// up from the mouth (a tributary's from its junction; keyed jitter per run), so every node has one offset point that all
// its runs share and the channel is continuous along rivers, across confluences and over cube-face edges. A run into the
// sea ends where its routed step first goes under the sea, both tangents along the node's, its offset eased to nothing
// there. Each run is riverSteps + 1 samples on the sphere; the per-cell lists hold every run whose channel (its
// half-width around the polyline) can reach the cell: a box in face coordinates around each sample, wide enough for the
// half-width plus half a step at the grid's smallest cell spacing.
function riverPaths(P, N, n, dir, nb, nd, order, nOrder, recv, flow, h, seed, groundFn) {
  const K = P.riverSteps, cell = PI / 2.0 * R / N;
  const isRiver = (c) => c >= 0 && h[c] >= 0.0 && recv[c] >= 0 && flow[c] >= P.riverFlow;
  const half = (c) => P.width0 + P.width1 * Math.sqrt(flow[c] / P.riverFlow);
  const dist = (c, m) => { for (let q = 0; q < 8; q++) if (nb[c * 8 + q] === m) return nd[c * 8 + q]; return cell; };
  const frac = (x) => x - Math.floor(x);
  let cellMin = 1e9;
  for (let k = 0; k < n * 8; k++) if (nb[k] >= 0 && nd[k] < cellMin) cellMin = nd[k];
  // main donors
  const up = new Int32Array(n).fill(-1);
  for (let c = 0; c < n; c++) { const r = recv[c]; if (r >= 0 && h[c] >= 0.0 && (up[r] < 0 || flow[c] > flow[up[r]])) up[r] = c; }
  // straight nodes (the routing's two-step chords in and out turn less than straightCos there, so a regular staircase
  // of the 8 directions counts as straight), counted up the main stem (sources first)
  const straight = (c) => {
    let u = up[c], r = recv[c];
    if (u < 0) return true;
    if (up[u] >= 0) u = up[u];
    if (isRiver(r) && recv[r] >= 0) r = recv[r];
    const ax = dir[c * 3] - dir[u * 3], ay = dir[c * 3 + 1] - dir[u * 3 + 1], az = dir[c * 3 + 2] - dir[u * 3 + 2];
    const bx = dir[r * 3] - dir[c * 3], by = dir[r * 3 + 1] - dir[c * 3 + 1], bz = dir[r * 3 + 2] - dir[c * 3 + 2];
    const ab = ax * bx + ay * by + az * bz;
    return ab > 0.0 && ab * ab >= P.straightCos * P.straightCos * (ax * ax + ay * ay + az * az) * (bx * bx + by * by + bz * bz);
  };
  const sUp = new Int32Array(n), sDn = new Int32Array(n);
  for (let o = nOrder - 1; o >= 0; o--) { const c = order[o]; if (isRiver(c) && straight(c)) sUp[c] = (up[c] >= 0 ? sUp[up[c]] : 0) + 1; }
  // nodes, from the mouth upward (the drainage order puts a receiver before its donors): tangent, branch, budget,
  // amplitudes, the two phases and the offset point
  const tan = new Float64Array(n * 3), amp = new Float64Array(n), wam = new Float64Array(n), ph = new Float64Array(n), pw = new Float64Array(n), np = new Float64Array(n * 3);
  const bid = new Int32Array(n), bs = new Float64Array(n);
  const segOf = new Int32Array(n).fill(-1);
  let S = 0;
  for (let o = 0; o < nOrder; o++) {
    const c = order[o];
    if (!isRiver(c)) continue;
    const r = recv[c], u = up[c], rv = isRiver(r), cont = rv && up[r] === c, d = dist(c, r);
    for (let a = 0; a < 3; a++) tan[c * 3 + a] = u >= 0 ? (dir[r * 3 + a] - dir[u * 3 + a]) * 0.5 : dir[r * 3 + a] - dir[c * 3 + a];
    bid[c] = cont ? bid[r] : c; bs[c] = cont ? bs[r] + d : 0.0;
    if (sUp[c] > 0) sDn[c] = (cont ? sDn[r] : 0) + 1;
    const cx = dir[c * 3], cy = dir[c * 3 + 1], cz = dir[c * 3 + 2], tx = tan[c * 3], ty = tan[c * 3 + 1], tz = tan[c * 3 + 2];
    const nx = cy * tz - cz * ty, ny = cz * tx - cx * tz, nz = cx * ty - cy * tx, nl = Math.sqrt(nx * nx + ny * ny + nz * nz);
    // the budget: the steepest rise across the flow, to the neighbour nearest the normal on either side
    let lp = 0.0, sp1 = 0.0, lm = 0.0, sm1 = 0.0;
    for (let q = 0; q < 8; q++) {
      const m = nb[c * 8 + q]; if (m < 0 || nl <= 0.0) continue;
      const ex = dir[m * 3] - cx, ey = dir[m * 3 + 1] - cy, ez = dir[m * 3 + 2] - cz;
      const l = (ex * nx + ey * ny + ez * nz) / (nl * Math.sqrt(ex * ex + ey * ey + ez * ez));
      const rise = (h[m] > 0.0 ? h[m] : 0.0) - h[c];
      if (l > lp) { lp = l; sp1 = rise > 0.0 ? rise / (l * nd[c * 8 + q]) : 0.0; }
      if (-l > lm) { lm = -l; sm1 = rise > 0.0 ? rise / (-l * nd[c * 8 + q]) : 0.0; }
    }
    const hw = half(c), cut = P.carve0 + P.carve1 * Math.sqrt(flow[c] / P.riverFlow), steep = sp1 > sm1 ? sp1 : sm1;
    let B = P.bend * cell; if (steep * B > P.perch * cut) B = P.perch * cut / steep;
    if (B < P.tight * cell) { const k = B / (P.tight * cell); tan[c * 3] *= k; tan[c * 3 + 1] *= k; tan[c * 3 + 2] *= k; }
    // the two envelopes along the branch (keyed noise, smoothstep between lattice points envL cells apart)
    const eu = bs[c] / (P.envL * cell), ek = Math.floor(eu), es = ss(eu - ek), key = bid[c] * 1024;
    const e0 = draw(seed, P.stream + 5, key + (ek & 1023)), e1 = draw(seed, P.stream + 5, key + ((ek + 1) & 1023));
    const v0 = draw(seed, P.stream + 7, key + (ek & 1023)), v1 = draw(seed, P.stream + 7, key + ((ek + 1) & 1023));
    // the wander's share (more on a long straight run, times its envelope), then the meander's within what is left
    let st = (sUp[c] + sDn[c] - 2) / P.straightN; if (sUp[c] === 0 || st < 0.0) st = 0.0; if (st > 1.0) st = 1.0;
    let wa = (P.wanderA + (P.wanderS - P.wanderA) * st) * cell * (P.wanderLo + (1.0 - P.wanderLo) * (v0 + (v1 - v0) * es));
    if (wa > B) wa = B;
    let am = P.meanderW * hw; if (am > B - wa) am = B - wa;
    amp[c] = am * (e0 + (e1 - e0) * es) * (1.0 - P.meanderJit * draw(seed, P.stream + 1, c));
    wam[c] = wa;
    const wf = P.wlLo + (P.wlHi - P.wlLo) * draw(seed, P.stream + 6, bid[c]);
    let wl = P.waveW * hw; if (wl > P.waveMax * cell) wl = P.waveMax * cell;
    ph[c] = (rv ? ph[r] : draw(seed, P.stream, r)) + d / (wl * wf) * (1.0 + P.waveJit * (2.0 * draw(seed, P.stream + 2, c) - 1.0));
    pw[c] = (rv ? pw[r] : draw(seed, P.stream + 3, r)) + d / (P.wanderL * cell * wf) * (1.0 + P.waveJit * (2.0 * draw(seed, P.stream + 4, c) - 1.0));
    // the node's offset point
    const off = nl > 0.0 ? (amp[c] * sin(2.0 * PI * frac(ph[c])) + wam[c] * sin(2.0 * PI * frac(pw[c]))) / R / nl : 0.0;
    const p = unit3(cx + nx * off, cy + ny * off, cz + nz * off);
    np[c * 3] = p[0]; np[c * 3 + 1] = p[1]; np[c * 3 + 2] = p[2];
  }
  for (let c = 0; c < n; c++) if (isRiver(c)) segOf[c] = S++;
  // the runs, sampled
  const sc = new Int32Array(S), sp = new Float64Array(S * (K + 1) * 3), sflow = new Float64Array(S), sh2 = new Float64Array(S), sb = new Float64Array(S * 4);
  const pairs = [], mark = new Int32Array(n).fill(-1);
  for (let c = 0; c < n; c++) {
    const s = segOf[c]; if (s < 0) continue;
    const r = recv[c], rr = isRiver(r);
    sc[s] = c; sflow[s] = flow[c];
    const hw = half(c); sh2[s] = (hw / R) * (hw / R);
    const p0x = dir[c * 3], p0y = dir[c * 3 + 1], p0z = dir[c * 3 + 2];
    let p1x = dir[r * 3], p1y = dir[r * 3 + 1], p1z = dir[r * 3 + 2];
    let m0x = tan[c * 3], m0y = tan[c * 3 + 1], m0z = tan[c * 3 + 2];
    let m1x = p1x - p0x, m1y = p1y - p0y, m1z = p1z - p0z;
    if (rr) {
      let k = 1.0;
      if (up[r] !== c) {
        const tx = tan[r * 3], ty = tan[r * 3 + 1], tz = tan[r * 3 + 2];
        k = (m1x * tx + m1y * ty + m1z * tz) / Math.sqrt((m1x * m1x + m1y * m1y + m1z * m1z) * (tx * tx + ty * ty + tz * tz));
        if (k < P.tribTan) k = P.tribTan; if (k > 1.0) k = 1.0;
      }
      m1x = tan[r * 3] * k; m1y = tan[r * 3 + 1] * k; m1z = tan[r * 3 + 2] * k;
    } else if (h[r] < 0.0 && groundFn) {
      // the mouth: the run ends where the routed step first goes under the sea (bisection on the input ground), and
      // both its tangents follow the node's, so the channel meets the coast along its course without a hook
      let lo = 0.0, hi = 1.0;
      for (let it = 0; it < P.mouthIt; it++) {
        const t = (lo + hi) * 0.5, e = unit3(p0x + (p1x - p0x) * t, p0y + (p1y - p0y) * t, p0z + (p1z - p0z) * t);
        if (groundFn(e[0], e[1], e[2]) < 0.0) hi = t; else lo = t;
      }
      const e = unit3(p0x + (p1x - p0x) * hi, p0y + (p1y - p0y) * hi, p0z + (p1z - p0z) * hi);
      p1x = e[0]; p1y = e[1]; p1z = e[2];
      const l = Math.sqrt((p1x - p0x) * (p1x - p0x) + (p1y - p0y) * (p1y - p0y) + (p1z - p0z) * (p1z - p0z));
      const tl = Math.sqrt(m0x * m0x + m0y * m0y + m0z * m0z), k = tl > 0.0 ? l / tl : 0.0;
      m0x *= k; m0y *= k; m0z *= k; m1x = m0x; m1y = m0y; m1z = m0z;
    }
    const f0 = ph[c], f1 = rr ? ph[r] : draw(seed, P.stream, r), g0 = pw[c], g1 = rr ? pw[r] : draw(seed, P.stream + 3, r);
    const a0 = amp[c], a1 = rr ? amp[r] : amp[c], w0 = wam[c], w1 = rr ? wam[r] : wam[c];
    const o = s * (K + 1) * 3;
    for (let k = 0; k <= K; k++) {
      if (k === 0 || (k === K && rr)) {
        const m = k === 0 ? c : r, ok = o + k * 3;
        sp[ok] = np[m * 3]; sp[ok + 1] = np[m * 3 + 1]; sp[ok + 2] = np[m * 3 + 2];
        continue;
      }
      const t = k / K, t2 = t * t, t3 = t2 * t;
      const h00 = 2.0 * t3 - 3.0 * t2 + 1.0, h10 = t3 - 2.0 * t2 + t, h01 = -2.0 * t3 + 3.0 * t2, h11 = t3 - t2;
      const d00 = 6.0 * t2 - 6.0 * t, d10 = 3.0 * t2 - 4.0 * t + 1.0, d01 = -6.0 * t2 + 6.0 * t, d11 = 3.0 * t2 - 2.0 * t;
      const qx = h00 * p0x + h10 * m0x + h01 * p1x + h11 * m1x, qy = h00 * p0y + h10 * m0y + h01 * p1y + h11 * m1y, qz = h00 * p0z + h10 * m0z + h01 * p1z + h11 * m1z;
      const dx = d00 * p0x + d10 * m0x + d01 * p1x + d11 * m1x, dy = d00 * p0y + d10 * m0y + d01 * p1y + d11 * m1y, dz = d00 * p0z + d10 * m0z + d01 * p1z + d11 * m1z;
      let nx = qy * dz - qz * dy, ny = qz * dx - qx * dz, nz = qx * dy - qy * dx;
      const nl = Math.sqrt(nx * nx + ny * ny + nz * nz);
      let off = nl > 0.0 ? ((a0 + (a1 - a0) * t) * sin(2.0 * PI * frac(f0 + (f1 - f0) * t)) + (w0 + (w1 - w0) * t) * sin(2.0 * PI * frac(g0 + (g1 - g0) * t))) / R / nl : 0.0;
      if (!rr) off *= 1.0 - t;                     // a run into the sea (or a dead end) eases its offset to nothing
      const p = unit3(qx + nx * off, qy + ny * off, qz + nz * off);
      sp[o + k * 3] = p[0]; sp[o + k * 3 + 1] = p[1]; sp[o + k * 3 + 2] = p[2];
    }
    // a bounding sphere for the read's quick reject, and the cells the channel can reach
    let bx = 0.0, by = 0.0, bz = 0.0, lmax = 0.0;
    for (let k = 0; k <= K; k++) { bx += sp[o + k * 3]; by += sp[o + k * 3 + 1]; bz += sp[o + k * 3 + 2]; }
    bx /= K + 1; by /= K + 1; bz /= K + 1;
    let br = 0.0;
    for (let k = 0; k <= K; k++) {
      const ex = sp[o + k * 3] - bx, ey = sp[o + k * 3 + 1] - by, ez = sp[o + k * 3 + 2] - bz, e = ex * ex + ey * ey + ez * ez;
      if (e > br) br = e;
      if (k < K) {
        const lx = sp[o + k * 3 + 3] - sp[o + k * 3], ly = sp[o + k * 3 + 4] - sp[o + k * 3 + 1], lz = sp[o + k * 3 + 5] - sp[o + k * 3 + 2], l = lx * lx + ly * ly + lz * lz;
        if (l > lmax) lmax = l;
      }
    }
    br = Math.sqrt(br) + hw / R;
    sb[s * 4] = bx; sb[s * 4 + 1] = by; sb[s * 4 + 2] = bz; sb[s * 4 + 3] = br * br;
    const rad = (hw + Math.sqrt(lmax) * R * 0.5) / cellMin;
    for (let k = 0; k <= K; k++) {
      const x = sp[o + k * 3], y = sp[o + k * 3 + 1], z = sp[o + k * 3 + 2], f = faceOf(x, y, z), [u, v] = faceCoords(f, x, y, z, N);
      const i0 = Math.floor(u - rad), i1 = Math.floor(u + rad), j0 = Math.floor(v - rad), j1 = Math.floor(v + rad);
      for (let j = j0; j <= j1; j++) for (let i = i0; i <= i1; i++) {
        let m;
        if (i >= 0 && j >= 0 && i < N && j < N) m = (f * N + j) * N + i;
        else { const d = cellDir(f, i, j, N); m = cellOf(d[0], d[1], d[2], N); }
        if (mark[m] === s) continue;
        mark[m] = s; pairs.push(m, s);
      }
    }
  }
  // the per-cell lists (counting sort by cell; a cell's runs in run order)
  const rs = new Int32Array(n + 1), rl = new Int32Array(pairs.length / 2);
  for (let q = 0; q < pairs.length; q += 2) rs[pairs[q] + 1]++;
  for (let c = 0; c < n; c++) rs[c + 1] += rs[c];
  const fillAt = Int32Array.from(rs.subarray(0, n));
  for (let q = 0; q < pairs.length; q += 2) rl[fillAt[pairs[q]]++] = pairs[q + 1];
  return { K, runs: S, sc, sp, sflow, sh2, sb, rs, rl };
}

// The carve at p (bilinear on its face, clamped at the face's edge), the lake level and the river flow at p's cell.
export function readErosion(E, px, py, pz) {
  const N = E.N, f = faceOf(px, py, pz), [u, v] = faceCoords(f, px, py, pz, N);
  let fx = u - 0.5, fy = v - 0.5;
  if (fx < 0) fx = 0; if (fy < 0) fy = 0; if (fx > N - 1.001) fx = N - 1.001; if (fy > N - 1.001) fy = N - 1.001;
  const i = Math.floor(fx), j = Math.floor(fy), tx = fx - i, ty = fy - j, b = (f * N + j) * N + i;
  const d00 = E.dh[b], d10 = E.dh[b + 1], d01 = E.dh[b + N], d11 = E.dh[b + N + 1];
  const top = d00 + (d10 - d00) * tx, bot = d01 + (d11 - d01) * tx;
  const ci = Math.min(N - 1, Math.max(0, Math.floor(u))), cj = Math.min(N - 1, Math.max(0, Math.floor(v))), c = (f * N + cj) * N + ci;
  return [top + (bot - top) * ty, E.lake[c], E.flow[c], c];
}

// A river at p (in cell c): the largest flow of the runs listed for c whose polyline passes within the run's half-width.
export function riverAt(E, c, px, py, pz) {
  const a = E.rs[c], b = E.rs[c + 1];
  if (a === b) return 0;
  const K = E.K, sp = E.sp;
  let best = 0;
  for (let q = a; q < b; q++) {
    const s = E.rl[q], fs = E.sflow[s];
    if (fs <= best) continue;
    const cx = px - E.sb[s * 4], cy = py - E.sb[s * 4 + 1], cz = pz - E.sb[s * 4 + 2];
    if (cx * cx + cy * cy + cz * cz >= E.sb[s * 4 + 3]) continue;
    const h2 = E.sh2[s];
    for (let k = 0, o = s * (K + 1) * 3; k < K; k++, o += 3) {
      const ax = sp[o], ay = sp[o + 1], az = sp[o + 2];
      const bx = sp[o + 3] - ax, by = sp[o + 4] - ay, bz = sp[o + 5] - az, qx = px - ax, qy = py - ay, qz = pz - az;
      const bb = bx * bx + by * by + bz * bz;
      let t = bb > 0.0 ? (qx * bx + qy * by + qz * bz) / bb : 0.0; if (t < 0.0) t = 0.0; if (t > 1.0) t = 1.0;
      const ex = qx - bx * t, ey = qy - by * t, ez = qz - bz * t;
      if (ex * ex + ey * ey + ez * ez < h2) { best = fs; break; }
    }
  }
  return best;
}
