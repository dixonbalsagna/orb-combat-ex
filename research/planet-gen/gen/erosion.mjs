// Approach C: erosion-lite on a coarse cube-sphere grid, built once per planet, then read per column.
//   1. Heights at the cell centres from the input ground, rain from the climate (approach A's precipitation).
//   2. Each pass: fill the depressions from the sea inward (priority flood, so every land cell drains; a deep fill is a
//      lake), route each cell to its steepest lower neighbour, accumulate the rain downstream (rivers), carve with an
//      implicit stream-power step (h = (h + F h_downstream) / (1 + F), F = K sqrt(flow) / distance: stable at any K),
//      then slump slopes steeper than the talus angle (a Jacobi pass, order-free).
//   3. Read: the input ground plus the bilinear carve at the point; a lake's level where the fill is deep; a river where
//      the flow is large (a channel cut into the column).
// Deterministic: the heap breaks ties by cell index, the Jacobi passes are order-free, the arithmetic is + - * / sqrt
// floor and the series atan (det.mjs). Grid cost is the planet's set-up; the read is a few lookups a column.
import { R, sin, cos, PI, atanf, unit3 } from '../lib/det.mjs';

export const PC = {
  N: 128,                     // cells along a cube face's edge: 6 N^2 cells (128: 98,304 cells of about 300 units)
  passes: 4, K: 0.06, eps: 0.05, talus: 1.1, slump: 0.22, thermal: 2,
  lakeMin: 90.0,              // a fill deeper than this (units) is a lake (shallower hollows drain or dry out)
  lakeRain: 700.0,            // ... where it rains at least this much (mm); drier basins stay dry hollows
  riverFlow: 60.0,            // flow (cells of 1,000 mm of rain) that makes a river
  carve0: 18.0, carve1: 7.0,  // a river's channel depth at the column: carve0 + carve1 * sqrt(flow / riverFlow)
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

// Build the grid for one planet. groundFn(px, py, pz) is the input height; rainFn(px, py, pz, h) the precipitation (mm).
export function buildErosion(groundFn, rainFn, P = PC) {
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
  return { P, N, n, dir, dh, lake, flow: Float32Array.from(flow), recv: Int32Array.from(recv), h: Float32Array.from(h), t, cells: n, riverCells: rivers };
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
