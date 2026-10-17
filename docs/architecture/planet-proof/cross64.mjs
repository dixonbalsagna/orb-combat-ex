// Scratch (Simulation): World's planet function (docs/world/scratch-build/planet-slice/planet_lib.gd) ported to the JS
// core's rules: float64 scalars, the frozen core's own sin and cos (sim/core/detmath.js), integer hash noise. Prints one
// line a point: the point's three coordinates, its elevation (each as the hex of its float64 bits) and its biome; then a
// hash of a full 4,800-column slice. Usage: node planet.mjs <repo root> > out.txt
import { pathToFileURL } from 'node:url';
import path from 'node:path';
const root = process.argv[2];
const { sin, cos } = await import(pathToFileURL(path.join(root, 'sim/core/detmath.js')).href);

const L = 153600.0;
const PI = Math.PI;
const R = L / (2.0 * PI);
const SEED = 7;

// SimRng.imul (rng.gd): x * y mod 2^32, unsigned; Math.imul is the same bits as a signed int
const imul = (x, y) => Math.imul(x, y) >>> 0;
function fm(x) {
  x = x >>> 0;
  x = (x ^ (x >>> 16)) >>> 0;
  x = imul(x, 0x85ebca6b);
  x = (x ^ (x >>> 13)) >>> 0;
  x = imul(x, 0xc2b2ae35);
  x = (x ^ (x >>> 16)) >>> 0;
  return x;
}
// GDScript ints are 64-bit: (ix & 0xFFFFFFFF) is the low 32 bits as an unsigned number; here ix >>> 0
const lat = (ix, iy, iz, s) => fm((fm((fm((s ^ (ix >>> 0)) >>> 0) ^ (iy >>> 0)) >>> 0) ^ (iz >>> 0)) >>> 0) / 4294967296.0;

function vn(x, y, z, s) {
  const fx = Math.floor(x), fy = Math.floor(y), fz = Math.floor(z);
  const ix = fx, iy = fy, iz = fz;   // |x| < 2^31 here: the int is exact
  let tx = x - fx, ty = y - fy, tz = z - fz;
  tx = tx * tx * (3.0 - 2.0 * tx);
  ty = ty * ty * (3.0 - 2.0 * ty);
  tz = tz * tz * (3.0 - 2.0 * tz);
  const c000 = lat(ix, iy, iz, s);
  const c100 = lat(ix + 1, iy, iz, s);
  const c010 = lat(ix, iy + 1, iz, s);
  const c110 = lat(ix + 1, iy + 1, iz, s);
  const c001 = lat(ix, iy, iz + 1, s);
  const c101 = lat(ix + 1, iy, iz + 1, s);
  const c011 = lat(ix, iy + 1, iz + 1, s);
  const c111 = lat(ix + 1, iy + 1, iz + 1, s);
  const a = c000 + (c100 - c000) * tx;
  const b = c010 + (c110 - c010) * tx;
  const c = c001 + (c101 - c001) * tx;
  const d = c011 + (c111 - c011) * tx;
  const e = a + (b - a) * ty;
  const f = c + (d - c) * ty;
  return e + (f - e) * tz;
}
function fbm(px, py, pz, scale, oct, s) {
  let sum = 0.0, amp = 0.5, tot = 0.0, k = R / scale;
  for (let o = 0; o < oct; o++) {
    sum += amp * vn(px * k, py * k, pz * k, s + o * 101);
    tot += amp;
    amp *= 0.5;
    k *= 2.0;
  }
  return sum / tot;
}
function elev(px, py, pz) {
  const c = fbm(px, py, pz, 30000.0, 4, SEED);
  const m = fbm(px, py, pz, 9000.0, 3, SEED + 5000);
  const e = (c - 0.5) * 2.0;
  let h = (e + 0.15) * 1300.0;
  if (e > 0.12) h += (e - 0.12) * 16000.0 * (0.35 + m);
  return h;
}
function biome(px, py, pz, h) {
  if (h < 0.0) return 0;
  if (h > 3200.0) return 4;
  const w = fbm(px, py, pz, 20000.0, 3, SEED + 9000);
  const t = 1.0 - Math.abs(py) * 0.8 + (fbm(px, py, pz, 12000.0, 2, SEED + 13000) - 0.5) * 0.5;
  if (w < 0.42 && t > 0.45) return 3;
  if (w > 0.55) return 2;
  return 1;
}


// World's crossing test in float64 scalars: the same point reached along two circles (Math.atan2 for the angle, a
// measurement only)
const rnd = (k) => fm((fm(k) ^ 0x5bd1e995) >>> 0) / 4294967296.0;
const unit = (a, b) => { const z = -1 + 2 * a, ang = 2 * PI * b, q = Math.sqrt(1 - z * z); return [q * cos(ang), z, q * sin(ang)]; };
const crs = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const nrm = (a) => { const l = Math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2]); return [a[0] / l, a[1] / l, a[2] / l]; };
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
let worstH = 0, worstP = 0, k = 50000;
for (let t = 0; t < 200; t++) {
  const nA = unit(rnd(k++), rnd(k++)), nB = unit(rnd(k++), rnd(k++));
  const uA = nrm(crs(nA, unit(rnd(k++), rnd(k++)))), vA = nrm(crs(nA, uA));
  const uB = nrm(crs(nB, unit(rnd(k++), rnd(k++)))), vB = nrm(crs(nB, uB));
  const X = nrm(crs(nA, nB));
  const a = Math.atan2(dot(X, vA), dot(X, uA)), b = Math.atan2(dot(X, vB), dot(X, uB));
  const qa = [0, 1, 2].map(i => uA[i] * cos(a) + vA[i] * sin(a)), qb = [0, 1, 2].map(i => uB[i] * cos(b) + vB[i] * sin(b));
  worstP = Math.max(worstP, ...[0, 1, 2].map(i => Math.abs(qa[i] - qb[i])));
  worstH = Math.max(worstH, Math.abs(elev(...qa) - elev(...qb)));
}
console.log(`float64: the same point from two circles, 200 crossings: largest elevation difference ${worstH.toExponential(3)} units; point ${worstP.toExponential(3)} of the radius (${(worstP * R).toExponential(3)} units)`);
