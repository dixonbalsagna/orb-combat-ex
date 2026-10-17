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

// the test points: ten touch-downs and ten second points from the hash, a great circle through each pair
const rnd = (k) => fm((fm(k) ^ 0x5bd1e995) >>> 0) / 4294967296.0;
function unit(a, b) {
  const z = -1.0 + 2.0 * a;
  const ang = 2.0 * PI * b;
  const q = Math.sqrt(1.0 - z * z);
  return [q * cos(ang), z, q * sin(ang)];
}
function circle(j) {
  const T = unit(rnd(4 * j), rnd(4 * j + 1));
  const C = unit(rnd(4 * j + 2), rnd(4 * j + 3));
  let nx = T[1] * C[2] - T[2] * C[1], ny = T[2] * C[0] - T[0] * C[2], nz = T[0] * C[1] - T[1] * C[0];
  const len = Math.sqrt(nx * nx + ny * ny + nz * nz);
  nx = nx / len; ny = ny / len; nz = nz / len;
  const vx = ny * T[2] - nz * T[1], vy = nz * T[0] - nx * T[2], vz = nx * T[1] - ny * T[0];
  return { u: T, v: [vx, vy, vz] };
}
function point(c, i) {
  const ang = (32.0 * i) / R;
  const co = cos(ang), si = sin(ang);
  return [c.u[0] * co + c.v[0] * si, c.u[1] * co + c.v[1] * si, c.u[2] * co + c.v[2] * si];
}
const dv = new DataView(new ArrayBuffer(8));
function hex(x) {
  dv.setFloat64(0, x, true);
  let s = '';
  for (let i = 0; i < 8; i++) s += dv.getUint8(i).toString(16).padStart(2, '0');
  return s;
}
const out = [];
for (let j = 0; j < 10; j++) {
  const c = circle(j);
  for (let k = 0; k < 100; k++) {
    const i = k * 48 + j * 4;
    const p = point(c, i);
    const h = elev(p[0], p[1], p[2]);
    out.push(`${j} ${i} ${hex(p[0])} ${hex(p[1])} ${hex(p[2])} ${hex(h)} ${biome(p[0], p[1], p[2], h)}`);
  }
}
// a full slice: 4,800 columns of the first circle, folded into one FNV-1a over the elevation bits and the biome
let fh = 0x811c9dc5;
const c0 = circle(0);
for (let i = 0; i < 4800; i++) {
  const p = point(c0, i);
  const h = elev(p[0], p[1], p[2]);
  const s = hex(h) + biome(p[0], p[1], p[2], h);
  for (let q = 0; q < s.length; q++) { fh = (fh ^ s.charCodeAt(q)) >>> 0; fh = imul(fh, 0x01000193); }
}
out.push(`slice ${fh.toString(16).padStart(8, '0')}`);
// the same slice stored as the core stores heights (float32, S.base): Math.fround, and the four bytes' hex
const dv4 = new DataView(new ArrayBuffer(4));
let f4 = 0x811c9dc5;
for (let i = 0; i < 4800; i++) {
  const p = point(c0, i);
  dv4.setFloat32(0, Math.fround(elev(p[0], p[1], p[2])), true);
  let s4 = '';
  for (let q = 0; q < 4; q++) s4 += dv4.getUint8(q).toString(16).padStart(2, '0');
  for (let q = 0; q < s4.length; q++) { f4 = (f4 ^ s4.charCodeAt(q)) >>> 0; f4 = imul(f4, 0x01000193); }
}
out.push(`slice32 ${f4.toString(16).padStart(8, '0')}`);
console.log(out.join('\n'));
