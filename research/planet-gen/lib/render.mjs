// Pictures and measures (rendering only: it calls a generator and never feeds one). Equirect maps with hillshade, an
// orthographic globe, the fight ring's strip, the ring picker and the shares.
import { Img } from './img.mjs';
import { COLOR, IS_WATER, B, NAME } from './biomes.mjs';
import { R, NC, COL, sin, cos, randUnit, unit3 } from './det.mjs';

// Sample a generator over an equirect grid. sample(px, py, pz) returns [h, biome, flag?] (flag 1: a river).
export function sampleMap(sample, W, H) {
  const h = new Float32Array(W * H), b = new Uint8Array(W * H), f = new Uint8Array(W * H);
  for (let y = 0; y < H; y++) {
    const la = Math.PI / 2 - (y + 0.5) / H * Math.PI, cl = Math.cos(la), sl = Math.sin(la);
    for (let x = 0; x < W; x++) {
      const lo = (x + 0.5) / W * 2 * Math.PI - Math.PI;
      const r = sample(cl * Math.cos(lo), sl, -cl * Math.sin(lo));
      const i = y * W + x; h[i] = r[0]; b[i] = r[1]; f[i] = r[2] ? 1 : 0;
    }
  }
  return { W, H, h, b, f };
}

const DEEPC = [16, 38, 86], SHALLOWC = [52, 112, 170];
export function colorMap(M, { exag = 3.0, rivers = true } = {}) {
  const { W, H, h, b, f } = M;
  const img = new Img(W, H, null);
  const L = [-0.55, 0.55, 0.63], lz = L[2];
  for (let y = 0; y < H; y++) {
    const la = Math.PI / 2 - (y + 0.5) / H * Math.PI;
    const dx = 2 * Math.PI * R / W * Math.max(0.05, Math.cos(la)), dy = Math.PI * R / H;
    for (let x = 0; x < W; x++) {
      const i = y * W + x, bi = b[i];
      const xl = (x + W - 1) % W, xr = (x + 1) % W, yu = Math.max(0, y - 1), yd = Math.min(H - 1, y + 1);
      const hx = (Math.max(0, h[y * W + xr]) - Math.max(0, h[y * W + xl])) / (2 * dx);
      const hy = (Math.max(0, h[yu * W + x]) - Math.max(0, h[yd * W + x])) / (2 * dy);
      const nx = -exag * hx, ny = -exag * hy, nl = Math.sqrt(nx * nx + ny * ny + 1);
      let s = (nx * L[0] + ny * L[1] + lz) / nl / lz;
      s = Math.min(1.35, Math.max(0.35, s));
      let c;
      if (bi === B.DEEP || bi === B.SEA) {
        const t = Math.min(1, Math.max(0, -h[i] / 2200));
        c = [SHALLOWC[0] + (DEEPC[0] - SHALLOWC[0]) * t, SHALLOWC[1] + (DEEPC[1] - SHALLOWC[1]) * t, SHALLOWC[2] + (DEEPC[2] - SHALLOWC[2]) * t];
        s = 1.0;
      } else if (bi === B.RIVER || bi === B.LAKE) { c = COLOR[bi]; s = 1.0; }
      else c = COLOR[bi];
      const k = bi === B.SEA_ICE ? 1.0 : s;
      img.set(x, y, [Math.min(255, c[0] * k), Math.min(255, c[1] * k), Math.min(255, c[2] * k)]);
      if (rivers && f[i] && !IS_WATER[bi]) img.set(x, y, COLOR[B.RIVER]);
    }
  }
  return img;
}

// Point to equirect pixel.
export function toPix(p, W, H) {
  const lo = Math.atan2(-p[2], p[0]), la = Math.asin(Math.max(-1, Math.min(1, p[1])));
  return [((lo + Math.PI) / (2 * Math.PI)) * W, ((Math.PI / 2 - la) / Math.PI) * H];
}

export function drawRingOnMap(img, ring, color = [255, 255, 255]) {
  for (let i = 0; i < NC; i += 6) {
    const p = ringPoint(ring, i), [x, y] = toPix(p, img.w, img.h);
    img.set(x, y, color);
  }
  const t = ringPoint(ring, NC / 2), [tx, ty] = toPix(t, img.w, img.h);
  for (let d = -3; d <= 3; d++) { img.set(tx + d, ty, [255, 60, 60]); img.set(tx, ty + d, [255, 60, 60]); }
}

// Orthographic globe from a coloured equirect, centred on (lon0, lat0) radians.
export function globe(eqImg, size, lon0, lat0, ring) {
  const out = new Img(size, size, [8, 10, 18]);
  const c = [Math.cos(lat0) * Math.cos(lon0), Math.sin(lat0), -Math.cos(lat0) * Math.sin(lon0)];
  const el = Math.sqrt(c[2] * c[2] + c[0] * c[0]), e = [c[2] / el, 0, -c[0] / el];
  const n = [c[1] * e[2] - c[2] * e[1], c[2] * e[0] - c[0] * e[2], c[0] * e[1] - c[1] * e[0]];
  const rad = size / 2 - 6, W = eqImg.w, H = eqImg.h;
  const Ld = unit3(-0.5, 0.45, 0.74);
  for (let py = 0; py < size; py++) for (let px = 0; px < size; px++) {
    const u = (px + 0.5 - size / 2) / rad, v = -(py + 0.5 - size / 2) / rad, q = u * u + v * v;
    if (q > 1) {
      const g = Math.max(0, 1 - (Math.sqrt(q) - 1) * 18);
      if (g > 0) out.set(px, py, [8 + 60 * g, 10 + 110 * g, 18 + 190 * g]);
      continue;
    }
    const z = Math.sqrt(1 - q);
    const w = [c[0] * z + e[0] * u + n[0] * v, c[1] * z + e[1] * u + n[1] * v, c[2] * z + e[2] * u + n[2] * v];
    const [fx, fy] = toPix(w, W, H);
    const x0 = Math.floor(fx - 0.5), y0 = Math.floor(fy - 0.5), tx = fx - 0.5 - x0, ty = fy - 0.5 - y0;
    const col = [0, 0, 0];
    for (const [dx, dy, wt] of [[0, 0, (1 - tx) * (1 - ty)], [1, 0, tx * (1 - ty)], [0, 1, (1 - tx) * ty], [1, 1, tx * ty]]) {
      const X = (x0 + dx + W) % W, Y = Math.min(H - 1, Math.max(0, y0 + dy)), k = eqImg.get(X, Y);
      col[0] += k[0] * wt; col[1] += k[1] * wt; col[2] += k[2] * wt;
    }
    const lam = Math.max(0, u * Ld[0] + v * Ld[1] + z * Ld[2]);
    const s = 0.28 + 0.85 * lam, rim = Math.pow(1 - z, 3) * 0.55;
    out.set(px, py, [Math.min(255, col[0] * s + 90 * rim), Math.min(255, col[1] * s + 150 * rim), Math.min(255, col[2] * s + 230 * rim)]);
  }
  if (ring) for (let i = 0; i < NC; i += 4) {
    const p = ringPoint(ring, i), z = p[0] * c[0] + p[1] * c[1] + p[2] * c[2];
    if (z <= 0.02) continue;
    const u = p[0] * e[0] + p[1] * e[1] + p[2] * e[2], v = p[0] * n[0] + p[1] * n[1] + p[2] * n[2];
    out.blend(size / 2 + u * rad, size / 2 - v * rad, [255, 255, 255], 0.85);
  }
  return out;
}

// ---- the fight ring: a great circle of 4,800 columns of 32 units, the touch-down at the middle column (as readSlice).
export function makeRing(seed, k) {
  const n = randUnit(seed, 7000, k), t = randUnit(seed, 7001, k);
  const d = t[0] * n[0] + t[1] * n[1] + t[2] * n[2];
  const u = unit3(t[0] - n[0] * d, t[1] - n[1] * d, t[2] - n[2] * d);
  const v = [n[1] * u[2] - n[2] * u[1], n[2] * u[0] - n[0] * u[2], n[0] * u[1] - n[1] * u[0]];
  return { k, n, u, v };
}
export function ringPoint(ring, i) {
  const a = (i - NC / 2) * COL / R, co = cos(a), si = sin(a), u = ring.u, v = ring.v;
  return [u[0] * co + v[0] * si, u[1] * co + v[1] * si, u[2] * co + v[2] * si];
}
// The picker, like WorldPlanet's minimum (half land, three biomes of 8% or more), on 96 samples; candidates 0..15.
// The touch-down is on land, as WorldPlanet's (touchLand: redrawn until on land): each candidate is turned along its own
// circle to the land column nearest its middle (not sea, not an ice sheet), searched every 8 columns.
function landTouch(ring, sample) {
  for (let d = 0; d <= NC / 2; d += 8) for (const i of d ? [NC / 2 + d, NC / 2 - d] : [NC / 2]) {
    const p = ringPoint(ring, i % NC), r = sample(p[0], p[1], p[2]);
    if (!IS_WATER[r[1]] && r[1] !== B.ICE_SHEET) {
      const n = ring.n, v = [n[1] * p[2] - n[2] * p[1], n[2] * p[0] - n[0] * p[2], n[0] * p[1] - n[1] * p[0]];
      return { ...ring, u: p, v };
    }
  }
  return ring;
}
export function pickRing(seed, sample) {
  let best = null;
  for (let k = 0; k < 16; k++) {
    const ring = landTouch(makeRing(seed, k), sample), cnt = new Map();
    let land = 0;
    for (let s = 0; s < 96; s++) {
      const p = ringPoint(ring, Math.floor(s * NC / 96)), r = sample(p[0], p[1], p[2]);
      if (!IS_WATER[r[1]]) { land++; cnt.set(r[1], (cnt.get(r[1]) || 0) + 1); }
    }
    const big = [...cnt.values()].filter((c) => c >= 0.08 * 96).length;
    const ok = land >= 48 && big >= 3;
    if (ok) return { ring, k, ok: true };
    if (!best || land > best.land) best = { ring, k, ok: false, land };
  }
  return best;
}
export function readRing(ring, sample) {
  const h = new Float32Array(NC), b = new Uint8Array(NC), f = new Uint8Array(NC);
  for (let i = 0; i < NC; i++) {
    const p = ringPoint(ring, i), r = sample(p[0], p[1], p[2]);
    h[i] = r[0]; b[i] = r[1]; f[i] = r[2] ? 1 : 0;
  }
  return { h, b, f };
}

// What the ring crosses.
export function ringStats(S) {
  const { h, b, f } = S;
  let land = 0, changes = 0, coasts = 0, longest = 0, run = 1, mount = 0, rivers = 0, lakes = 0, hMax = -1e9, hMin = 1e9;
  const cnt = new Map();
  for (let i = 0; i < NC; i++) {
    const bi = b[i], w = IS_WATER[bi], j = (i + NC - 1) % NC;
    if (!w) { land++; cnt.set(bi, (cnt.get(bi) || 0) + 1); }
    if (bi === B.ALPINE || bi === B.SNOW || bi === B.ROCK) mount++;
    if (bi !== b[j]) { changes++; if (i > 0) { longest = Math.max(longest, run); } run = 1; } else run++;
    if (IS_WATER[b[j]] !== w && bi !== B.RIVER && b[j] !== B.RIVER) coasts++;
    if ((bi === B.RIVER || f[i]) && !(b[j] === B.RIVER || f[j])) rivers++;
    if (bi === B.LAKE && b[j] !== B.LAKE) lakes++;
    hMax = Math.max(hMax, h[i]); hMin = Math.min(hMin, h[i]);
  }
  longest = Math.max(longest, run);
  const biomes = [...cnt.entries()].filter(([, c]) => c >= 0.01 * land).sort((a, c) => c[1] - a[1]).map(([k, c]) => [NAME[k], +(100 * c / Math.max(1, land)).toFixed(1)]);
  return { landPct: +(100 * land / NC).toFixed(1), biomes, distinct: biomes.length, changes, coasts, longestCols: longest, longestUnits: longest * COL,
    mountainPct: +(100 * mount / NC).toFixed(1), rivers, lakes, hMax: Math.round(hMax), hMin: Math.round(hMin) };
}

// Area-weighted shares from an equirect sample.
export function mapStats(M) {
  const { W, H, b } = M;
  const area = new Float64Array(64);
  let land = 0, tot = 0;
  for (let y = 0; y < H; y++) {
    const w = Math.cos(Math.PI / 2 - (y + 0.5) / H * Math.PI);
    for (let x = 0; x < W; x++) { const bi = b[y * W + x]; area[bi] += w; tot += w; if (!IS_WATER[bi]) land += w; }
  }
  const shares = [];
  for (let k = 0; k < 64; k++) if (area[k] > 0 && !IS_WATER[k]) shares.push([NAME[k], +(100 * area[k] / land).toFixed(1)]);
  shares.sort((a, c) => c[1] - a[1]);
  const waterKinds = {}; for (let k = 0; k < 64; k++) if (area[k] > 0 && IS_WATER[k]) waterKinds[NAME[k]] = +(100 * area[k] / tot).toFixed(1);
  return { landPct: +(100 * land / tot).toFixed(1), landBiomes: shares, landBiomesOver1: shares.filter((s) => s[1] >= 1).length, water: waterKinds };
}

// The ring as a side view: elevation (vertical exaggeration) coloured by biome, sea and rivers, a biome band under it.
export function ringStrip(S, label, { W = 1600, H = 250 } = {}) {
  const img = new Img(W, H, null);
  const top = 26, band = 22, base = H - band, sky = [[150, 190, 230], [215, 230, 245]];
  for (let y = 0; y < H; y++) { const t = y / H; img.fill(0, y, W, 1, [sky[0][0] + (sky[1][0] - sky[0][0]) * t, sky[0][1] + (sky[1][1] - sky[0][1]) * t, sky[0][2] + (sky[1][2] - sky[0][2]) * t]); }
  // a square-root height scale, so the hills a fight crosses show next to the ranges
  const f = (v) => (v < 0 ? -Math.sqrt(-v) : Math.sqrt(v)), hTop = 8000, hBot = -3000;
  const yOf = (hh) => top + (f(hTop) - f(hh)) / (f(hTop) - f(hBot)) * (base - top), sea = yOf(0);
  for (let x = 0; x < W; x++) {
    const i0 = Math.floor(x * NC / W), i1 = Math.floor((x + 1) * NC / W);
    let hm = -1e9, bi = 0, river = false;
    for (let i = i0; i < i1; i++) { if (S.h[i] > hm) { hm = S.h[i]; bi = S.b[i]; } if (S.f[i] || S.b[i] === B.RIVER) river = true; }
    const yg = yOf(hm);
    if (hm < 0) img.fill(x, sea, 1, Math.max(0, yg - sea), [40, 96, 160]);
    const c = IS_WATER[bi] && bi !== B.SEA_ICE ? [96, 84, 72] : COLOR[bi];
    for (let y = Math.floor(yg); y < base; y++) { const d = (y - yg) / 40; img.set(x, y, [c[0] * Math.max(0.55, 1 - d * 0.15), c[1] * Math.max(0.55, 1 - d * 0.15), c[2] * Math.max(0.55, 1 - d * 0.15)]); }
    if (river) img.fill(x, Math.floor(yg) - 3, 1, 4, COLOR[B.RIVER]);
    if (bi === B.LAKE) img.fill(x, Math.floor(yg) - 2, 1, 3, COLOR[B.LAKE]);
    img.fill(x, H - band, 1, band, river ? COLOR[B.RIVER] : COLOR[bi]);
  }
  img.fill(W / 2, top, 1, base - top, [255, 60, 60]);
  img.fill(0, 0, W, 20, [20, 22, 30]);
  img.text(6, 3, label, 2, [235, 235, 235]);
  return img;
}

// River lines for an erosion grid, over a coloured equirect: each run's polyline, the same one riverAt reads. Antialiased
// (a pixel's coverage from its distance to the nearest segment, so a bend smaller than a pixel still shows), 1 px wide or
// 2 px for a big river, and not over lakes (a pixel already in the lake's colour keeps it).
export function drawRivers(img, E, polarY = 0.72, skipAt = null) {
  const W = img.w, H = img.h, P = E.P, col = COLOR[B.RIVER], lk = COLOR[B.LAKE], K = E.K, sp = E.sp;
  const cov = new Float32Array(W * H);
  for (let s = 0; s < E.runs; s++) {
    const c = E.sc[s];
    if (Math.abs(E.dir[c * 3 + 1]) > polarY) continue;
    if (skipAt) { const o = (s * (K + 1) + (K >> 1)) * 3; if (skipAt(sp[o], sp[o + 1], sp[o + 2])) continue; }   // frozen
    const rw = E.sflow[s] > 8 * P.riverFlow ? 1.0 : 0.5;
    for (let k = 0, o = s * (K + 1) * 3; k < K; k++, o += 3) {
      const [x0, y0] = toPix([sp[o], sp[o + 1], sp[o + 2]], W, H), [x1, y1] = toPix([sp[o + 3], sp[o + 4], sp[o + 5]], W, H);
      if (Math.abs(x1 - x0) > W / 2) continue;
      const dx = x1 - x0, dy = y1 - y0, dd = dx * dx + dy * dy;
      const xa = Math.floor(Math.min(x0, x1) - rw - 1), xb = Math.floor(Math.max(x0, x1) + rw + 1);
      const ya = Math.max(0, Math.floor(Math.min(y0, y1) - rw - 1)), yb = Math.min(H - 1, Math.floor(Math.max(y0, y1) + rw + 1));
      for (let y = ya; y <= yb; y++) for (let x = xa; x <= xb; x++) {
        const px = x + 0.5 - x0, py = y + 0.5 - y0;
        let t = dd > 0 ? (px * dx + py * dy) / dd : 0; if (t < 0) t = 0; if (t > 1) t = 1;
        const ex = px - dx * t, ey = py - dy * t, a = rw + 0.5 - Math.sqrt(ex * ex + ey * ey);
        if (a <= 0) continue;
        const i = y * W + ((x % W) + W) % W;
        if (a > cov[i]) cov[i] = a > 1 ? 1 : a;
      }
    }
  }
  for (let i = 0; i < W * H; i++) {
    if (!(cov[i] > 0)) continue;
    const x = i % W, y = (i - x) / W, k = img.get(x, y);
    if (k[0] === lk[0] && k[1] === lk[1] && k[2] === lk[2]) continue;
    img.blend(x, y, col, cov[i]);
  }
}
