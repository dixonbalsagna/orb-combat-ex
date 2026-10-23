// The deterministic toolkit every generator here uses: the planet module's integer lattice hash and value noise
// (sim/world/planet.gd _fm, _lat, _vn, _fbm, the same expressions in the same order), keyed draws, sphere helpers.
// Arithmetic is + - * / sqrt floor on float64, the sim's own sin cos pow (sim/core/detmath.js), and 32-bit integer
// hashing, so World can port any of it to GDScript bit-exact (planet.gd shows the GDScript side of each primitive).
import { sin, cos, pow } from '../../../sim/core/detmath.js';
import { createRng, next } from '../../../sim/core/rng.js';

export { sin, cos, pow, createRng, next };
export const PI = Math.PI;                      // the same double as SimMathx.PI (built from its bits)
export const NC = 4800, COL = 32.0;             // SimConst.PLANET_NC, SimConst.COL
export const L = NC * COL;                      // 153,600 units round
export const R = L / (2.0 * PI);                // planet.gd make(): P.R = P.L / (2.0 * PI)

// planet.gd _fm: the MurmurHash3 finaliser on 32 bits (GDScript writes the two products out in 16-bit halves).
export function fm(x) {
  x >>>= 0;
  x ^= x >>> 16; x = Math.imul(x, 0x85ebca6b) >>> 0;
  x ^= x >>> 13; x = Math.imul(x, 0xc2b2ae35) >>> 0;
  x ^= x >>> 16;
  return x >>> 0;
}

// planet.gd _lat: the lattice value at an integer corner, in [0, 1).
export function lat(ix, iy, iz, s) {
  return fm((fm((fm((s ^ ix) >>> 0) ^ iy) >>> 0) ^ iz) >>> 0) / 4294967296.0;
}

// A keyed draw in [0, 1) from integers only (seed, a stream number, an index): no state, so adding a draw never shifts another.
export function draw(seed, stream, n) {
  return fm((fm((seed ^ Math.imul(stream, 0x9E3779B1)) >>> 0) ^ Math.imul(n, 0x85ebca6b)) >>> 0) / 4294967296.0;
}

// planet.gd _vn: trilinear value noise with a smoothstep fade. The corner cache of the GDScript is a memo only; this
// recomputes the corners, which gives the same numbers.
export function vn(x, y, z, s) {
  const fx = Math.floor(x), fy = Math.floor(y), fz = Math.floor(z);
  const ix = fx | 0, iy = fy | 0, iz = fz | 0;
  let tx = x - fx, ty = y - fy, tz = z - fz;
  tx = tx * tx * (3.0 - 2.0 * tx);
  ty = ty * ty * (3.0 - 2.0 * ty);
  tz = tz * tz * (3.0 - 2.0 * tz);
  const a0 = fm((s ^ ix) >>> 0), a1 = fm((s ^ (ix + 1)) >>> 0);
  const b00 = fm((a0 ^ iy) >>> 0), b10 = fm((a1 ^ iy) >>> 0), b01 = fm((a0 ^ (iy + 1)) >>> 0), b11 = fm((a1 ^ (iy + 1)) >>> 0);
  const c000 = fm((b00 ^ iz) >>> 0) / 4294967296.0, c100 = fm((b10 ^ iz) >>> 0) / 4294967296.0;
  const c010 = fm((b01 ^ iz) >>> 0) / 4294967296.0, c110 = fm((b11 ^ iz) >>> 0) / 4294967296.0;
  const c001 = fm((b00 ^ (iz + 1)) >>> 0) / 4294967296.0, c101 = fm((b10 ^ (iz + 1)) >>> 0) / 4294967296.0;
  const c011 = fm((b01 ^ (iz + 1)) >>> 0) / 4294967296.0, c111 = fm((b11 ^ (iz + 1)) >>> 0) / 4294967296.0;
  const a = c000 + (c100 - c000) * tx;
  const b = c010 + (c110 - c010) * tx;
  const c = c001 + (c101 - c001) * tx;
  const d = c011 + (c111 - c011) * tx;
  const e = a + (b - a) * ty;
  const f = c + (d - c) * ty;
  return e + (f - e) * tz;
}

// planet.gd _fbm: octaves of vn at the planet's scale, normalised to [0, 1). p is a unit vector.
export let OCT_COUNT = 0;                        // octaves evaluated, for the cost counts
export function fbm(px, py, pz, scale, oct, s) {
  let sum = 0.0, amp = 0.5, tot = 0.0, k = R / scale;
  for (let o = 0; o < oct; o++) {
    sum += amp * vn(px * k, py * k, pz * k, s + o * 101);
    tot += amp;
    amp *= 0.5;
    k *= 2.0;
  }
  OCT_COUNT += oct;
  return sum / tot;
}
export function resetOct() { OCT_COUNT = 0; }

// planet.gd _ss: clamped smoothstep.
export function ss(a) {
  let t = a;
  if (t < 0.0) t = 0.0;
  if (t > 1.0) t = 1.0;
  return t * t * (3.0 - 2.0 * t);
}
export function clamp01(a) { return a < 0.0 ? 0.0 : (a > 1.0 ? 1.0 : a); }
export function mix(a, b, t) { return a + (b - a) * t; }

// planet.gd atanf, atan2f, asinf: the series with + - * / only.
const TAN_PI_8 = Math.sqrt(2.0) - 1.0;
export function atanf(x) {
  let a = Math.abs(x);
  const inv = a > 1.0;
  if (inv) a = 1.0 / a;
  let off = 0.0;
  if (a > TAN_PI_8) { a = (a - 1.0) / (a + 1.0); off = PI / 4.0; }
  const a2 = a * a;
  let s = a, t = a;
  for (let k = 1; k < 12; k++) { t = -t * a2; s += t / (2 * k + 1); }
  let r = off + s;
  if (inv) r = PI / 2.0 - r;
  return x < 0.0 ? -r : r;
}
export function atan2f(y, x) {
  if (x > 0.0) return atanf(y / x);
  if (x < 0.0) return y >= 0.0 ? atanf(y / x) + PI : atanf(y / x) - PI;
  if (y > 0.0) return PI / 2.0;
  if (y < 0.0) return -PI / 2.0;
  return 0.0;
}
export function asinf(x) {
  const c = x > 1.0 ? 1.0 : (x < -1.0 ? -1.0 : x);
  return atan2f(c, Math.sqrt(1.0 - c * c));
}

// Sphere helpers. World's frame: y is up (the poles), east at a point is norm(Y x p) = norm(z, 0, -x) (planet-module.md section 5).
export function unit3(x, y, z) { const l = Math.sqrt(x * x + y * y + z * z); return [x / l, y / l, z / l]; }
export function east(px, py, pz) {
  const l = Math.sqrt(pz * pz + px * px);
  if (l < 1e-12) return [1.0, 0.0, 0.0];
  return [pz / l, 0.0, -px / l];
}
// A seeded unit vector by rejection in the cube (sqrt only).
export function randUnit(seed, stream, n) {
  for (let k = 0; k < 64; k++) {
    const x = draw(seed, stream, n * 64 + k * 3) * 2 - 1, y = draw(seed, stream, n * 64 + k * 3 + 1) * 2 - 1, z = draw(seed, stream, n * 64 + k * 3 + 2) * 2 - 1;
    const q = x * x + y * y + z * z;
    if (q > 0.01 && q <= 1.0) { const l = Math.sqrt(q); return [x / l, y / l, z / l]; }
  }
  return [0.0, 1.0, 0.0];
}
// Lon and lat (radians) to a unit vector in World's frame (east is norm(Y x p)); for the renderer and the ring.
export function lonlat(lon, la) {
  const c = cos(la);
  return [c * cos(lon), sin(la), -c * sin(lon)];
}
