// Origin: the biome strip renderer (deterministic, no randomness beyond a seeded generator, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-23. Human direction: Orb, via the EP.
// A scene is drawn in WORLD UNITS (a fighter is 75 units tall) with y up; sx, sy map to the sheet. Everything is a flat polygon with a thin keyline: lit, mid and shade faces, no gradients, no blur, no fades.
import { BIOMES } from './spec.mjs';
import { WORLD, tinted } from '../sky/world.mjs';
import { skyAt, KEYS } from '../sky/keys.mjs';

// ---------------------------------------------------------------------------------------------------------------- colour and number helpers
const h2r = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
const r2h = a => '#' + a.map(v => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, '0')).join('');
export const mix = (a, b, t) => { const A = h2r(a), B = h2r(b); return r2h(A.map((v, i) => v + (B[i] - v) * t)); };
export const dark = (h, t) => mix(h, '#0c0a14', t);
export const lite = (h, t) => mix(h, '#fff6e0', t);
export function rng(seed) { let s = seed >>> 0; return () => { s = (s + 0x6d2b79f5) >>> 0; let t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const F = n => (Math.round(n * 10) / 10).toString();
const KEY = '#0a0d14';
const smoothstep = (a, b, x) => { const t = Math.max(0, Math.min(1, (x - a) / (b - a))); return t * t * (3 - 2 * t); };
const lerp = (a, b, t) => a + (b - a) * t;

// ---------------------------------------------------------------------------------------------------------------- the scene frame
// win: the world window (wx0 left, width ww in units, wh height in units); S px per unit; the panel is at (px, py) on the sheet
export class Frame {
  constructor({ px = 0, py = 0, S = 1, wx0 = 0, ww = 1200, wh = 450 }) { Object.assign(this, { px, py, S, wx0, ww, wh }); this.out = []; this.W = ww * S; this.H = wh * S; this.layer = 'none'; this.tint = null; }
  col(c) { return this.tint && this.layer !== 'none' && c !== KEY && /^#[0-9a-f]{6}$/i.test(c) ? tinted(c, this.tint[this.layer]) : c; }
  X(x) { return this.px + (x - this.wx0) * this.S; }
  Y(y) { return this.py + this.H - y * this.S; }
  pt(p) { return `${F(this.X(p[0]))},${F(this.Y(p[1]))}`; }
  poly(pts, fill0, { key = true, op = 1, sw = 1.1 } = {}) { const fill = this.col(fill0); this.out.push(`<polygon points="${pts.map(p => this.pt(p)).join(' ')}" fill="${fill}"${key ? ` stroke="${KEY}" stroke-width="${sw}" stroke-linejoin="round"` : ` stroke="${fill}" stroke-width="0.7" stroke-linejoin="round"`}${op < 1 ? ` opacity="${op}"` : ''}/>`); }
  line(pts, stroke0, w = 1.2) { const stroke = this.col(stroke0); this.out.push(`<polyline points="${pts.map(p => this.pt(p)).join(' ')}" fill="none" stroke="${stroke}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`); }
  rect(x0, y0, x1, y1, fill, key = false) { this.poly([[x0, y0], [x1, y0], [x1, y1], [x0, y1]], fill, { key }); }
  svg() { return this.out.join(''); }
}

// a faceted fan around a centre: each triangle is coloured by the direction it faces (lit upper left, shade lower right)
export function fan(f, c, verts, [lit, mid, sh], { key = true } = {}) {
  const n = verts.length;
  for (let i = 0; i < n; i++) {
    const a = verts[i], b = verts[(i + 1) % n], mx = (a[0] + b[0]) / 2 - c[0], my = (a[1] + b[1]) / 2 - c[1], ang = (Math.atan2(my, mx) * 180 / Math.PI + 360) % 360;
    const col = ang > 95 && ang < 200 ? lit : ang >= 200 && ang < 255 ? mid : ang >= 255 || ang < 40 ? sh : mid;
    f.poly([c, a, b], col, { key, sw: 0.7 });
  }
  // the outline once, over the fan
  f.out.push(`<polygon points="${verts.map(p => f.pt(p)).join(' ')}" fill="none" stroke="${KEY}" stroke-width="1.1" stroke-linejoin="round"/>`);
}
const blob = (c, rx, ry, n, rnd, jit = 0.18, rot = 0) => Array.from({ length: n }, (_, i) => { const a = i / n * Math.PI * 2 + rot, k = 1 + (rnd() - 0.5) * 2 * jit; return [c[0] + Math.cos(a) * rx * k, c[1] + Math.sin(a) * ry * k]; });

// ---------------------------------------------------------------------------------------------------------------- ground profiles
// a profile is a function x -> height in units above the strip's ground line (0). seeded per scene so the same strip draws the same.
export function profileFn(kind, amp, wave, seed, extra = {}) {
  const r = rng(seed), ph = [r() * 6.28, r() * 6.28, r() * 6.28, r() * 6.28], tau = Math.PI * 2;
  const knots = Array.from({ length: 64 }, () => r());
  const cones = [r() * 800 + 200, r() * 800 + 1100];
  const sin3 = x => 0.6 * Math.sin(x / wave * tau + ph[0]) + 0.3 * Math.sin(x / (wave * 0.47) * tau + ph[1]) + 0.1 * Math.sin(x / (wave * 0.21) * tau + ph[2]);
  switch (kind) {
    case 'swell': return x => amp * (0.55 * Math.sin(x / wave * tau + ph[0]) + 0.3 * Math.sin(x / (wave * 0.4) * tau + ph[1]) + 0.15 * Math.sin(x / (wave * 0.17) * tau + ph[2]));
    case 'flat': return x => amp * (0.5 * Math.sin(x / wave * tau + ph[0]) + 0.5 * Math.sin(x / (wave * 0.37) * tau + ph[1]));
    case 'dunes': return x => { const t = ((x / wave + ph[0] / tau) % 1 + 1) % 1, saw = t < 0.72 ? t / 0.72 : (1 - t) / 0.28; return amp * (saw * saw * (3 - 2 * saw) * 0.8 + 0.2 * Math.sin(x / (wave * 0.31) * tau + ph[1])); };
    case 'jagged': return x => { const u = x / (wave / 3), i = Math.floor(u), t = u - i, a = knots[((i % 64) + 64) % 64], b = knots[(((i + 1) % 64) + 64) % 64]; return amp * (Math.pow(lerp(a, b, t), 1.3) * 1.15 - 0.15) + amp * 0.08 * Math.sin(x / 60 + ph[3]); };
    case 'cones': return x => { let h = 0; for (const c of cones) { const d = Math.abs(x - c); h = Math.max(h, d < 300 ? amp * (1 - d / 300) ** 1.2 - (d < 40 ? (40 - d) * 0.9 : 0) : 0); } return h + amp * 0.12 * sin3(x); };
    case 'hummock': return x => amp * (0.5 + 0.5 * Math.abs(Math.sin(x / wave * 2 * Math.PI + ph[0]))) * 0.8 + amp * 0.2 * Math.sin(x / (wave * 0.3) * tau + ph[1]);
    case 'sheet': return x => amp * (0.5 * Math.sin(x / wave * tau + ph[0]) + 0.25 * Math.sin(x / (wave * 0.33) * tau + ph[1]));
    case 'shore': { const sx = extra.shoreX ?? 420; return x => { const t = smoothstep(sx - 220, sx + 160, x); return lerp(-70, 0, t) * (x < sx ? 1 : 0) + (x >= sx ? amp * (0.4 + 0.6 * (x - sx) / 700) + amp * 0.35 * Math.sin(x / wave * tau + ph[0]) : 0); }; }
    case 'floes': return x => { const u = x / wave + ph[0]; const t = u - Math.floor(u), id = Math.floor(u); const w = 0.35 + 0.5 * knots[((id % 64) + 64) % 64]; return t < w ? amp * 0.6 : -120; };
    default: return x => amp * sin3(x);
  }
}
export const FAR = {
  hills: (x, a, ph, w) => a * (0.5 + 0.3 * Math.sin(x / (w * 0.9) + ph) + 0.2 * Math.sin(x / (w * 0.37) + ph * 2)),
  low: (x, a, ph, w) => a * (0.55 + 0.25 * Math.sin(x / (w * 0.7) + ph) + 0.2 * Math.sin(x / (w * 0.2) + ph * 3)),
  peaks: (x, a, ph, w) => a * Math.max(0.05, Math.abs(Math.sin(x / (w * 0.55) + ph)) ** 1.8 * 0.8 + 0.18 * Math.abs(Math.sin(x / (w * 0.21) + ph * 2))),
  mesas: (x, a, ph, w) => { const s = Math.sin(x / (w * 0.8) + ph); return a * (s > 0.25 ? 0.85 : s > -0.2 ? 0.45 + (s + 0.2) * 0.4 : 0.2) + (s > 0.25 ? 0 : 6 * Math.sin(x / 40)); },
  cones: (x, a, ph, w) => { const u = ((x / (w * 1.2) + ph) % 1 + 1) % 1, d = Math.abs(u - 0.5) * 2; return a * Math.max(0.12, 1 - d * 1.15) * (d < 0.06 ? 0.85 : 1); },
  floesfar: (x, a, ph, w) => (Math.sin(x / (w * 0.5) + ph) > -0.1 ? a * (0.5 + 0.5 * Math.abs(Math.sin(x / 37 + ph))) : 0),
  shelf: (x, a, ph, w) => a * (0.5 + (Math.sin(x / (w * 1.3) + ph) > 0.2 ? 0.16 : 0) + 0.06 * Math.sin(x / 90 + ph)),
  none: () => 0,
};

// ---------------------------------------------------------------------------------------------------------------- cover: the silhouettes
// each draws at (x, y) with height h; c: { f, pal, state ('clean' | 'scorched' | 'burned'), rnd, S }. Colours come from the palette; scorched darkens them, burned strips them.
const col3 = (p, k, st) => { const t = st === 'scorched' ? 0.5 : 0; return p[k].map(c => t ? mix(c, '#241c16', t) : c); };
const CHAR = ['#4a4038', '#2c2622', '#1c1814'];
function charredTree(c, x, y, h, branches = 4) {
  const { f, rnd } = c, w = Math.max(3, h * 0.035);
  f.poly([[x - w, y], [x + w, y], [x + w * 0.55, y + h * 0.7], [x - w * 0.55, y + h * 0.7]], CHAR[1]);
  f.poly([[x - w, y], [x - w * 0.2, y], [x - w * 0.1, y + h * 0.68], [x - w * 0.55, y + h * 0.7]], CHAR[0], { key: false });
  for (let i = 0; i < branches; i++) { const t = 0.35 + rnd() * 0.4, s = rnd() < 0.5 ? -1 : 1, bx = x + s * w * 0.4, by = y + h * t, L = h * (0.14 + rnd() * 0.14); f.line([[bx, by], [bx + s * L, by + L * (0.7 + rnd() * 0.4)]], CHAR[1], Math.max(1.4, w * 0.7)); }
}
function stubs(c, x, y, h, n = 6, spread = 36) { const { f, rnd } = c; for (let i = 0; i < n; i++) { const bx = x + (rnd() - 0.5) * spread, s = (rnd() - 0.5) * 6; f.poly([[bx - 2, y], [bx + 2, y], [bx + s, y + Math.max(5, h * (0.1 + rnd() * 0.14))]], CHAR[1], { key: false }); } f.poly([[x - spread * 0.5, y], [x + spread * 0.5, y], [x + spread * 0.3, y + 4], [x - spread * 0.3, y + 5]], '#5a554f', { key: false }); }

export const COVER = {
  tree(c, x, y, h) {
    const { f, pal, state, rnd } = c; if (state === 'burned') return charredTree(c, x, y, h * 0.9, 5);
    const v = col3(pal, 'v', state), tw = h * 0.035;
    f.poly([[x - tw * 1.3, y], [x + tw * 1.3, y], [x + tw * 0.8, y + h * 0.5], [x - tw * 0.8, y + h * 0.5]], state === 'scorched' ? CHAR[1] : pal.t);
    fan(f, [x, y + h * 0.7], blob([x, y + h * 0.7], h * 0.3, h * 0.3, 8, rnd, 0.16), v);
    if (rnd() < 0.5) fan(f, [x + h * 0.14, y + h * 0.88], blob([x + h * 0.14, y + h * 0.88], h * 0.18, h * 0.16, 7, rnd, 0.16), v);
  },
  fir(c, x, y, h) {
    const { f, pal, state } = c; if (state === 'burned') return charredTree(c, x, y, h * 0.95, 6);
    const v = col3(pal, 'v', state), n = 5, bw = h * 0.2; f.poly([[x - 3, y], [x + 3, y], [x + 2.4, y + h * 0.2], [x - 2.4, y + h * 0.2]], pal.t);
    for (let i = 0; i < n; i++) { const t0 = 0.12 + i * 0.17, t1 = t0 + 0.34, w = bw * (1 - i * 0.17), by = y + h * t0, ty = y + h * Math.min(1, t1); f.poly([[x - w, by], [x, ty], [x, by]], v[0]); f.poly([[x, by], [x, ty], [x + w, by]], v[2]); }
    if (c.snow) for (let i = 0; i < n; i++) { const t0 = 0.12 + i * 0.17, w = bw * (1 - i * 0.17) * 0.5, by = y + h * (t0 + 0.17); f.poly([[x - w, by], [x, y + h * Math.min(1, t0 + 0.34)], [x + w, by]], c.pal.acc, { key: false }); }
  },
  spruce(c, x, y, h) { COVER.fir({ ...c, snow: true }, x, y, h * 1.05); },
  acacia(c, x, y, h) {
    const { f, pal, state, rnd } = c; if (state === 'burned') return charredTree(c, x, y, h * 0.8, 4);
    const v = col3(pal, 'v', state), tw = h * 0.03, tr = state === 'scorched' ? CHAR[1] : pal.t;
    f.poly([[x - tw * 1.4, y], [x + tw * 1.4, y], [x + tw * 0.7, y + h * 0.55], [x - tw * 0.7, y + h * 0.55]], tr);
    f.poly([[x - tw * 0.7, y + h * 0.5], [x - h * 0.28, y + h * 0.78], [x - h * 0.24, y + h * 0.8], [x, y + h * 0.58]], tr, { key: false }); f.poly([[x + tw * 0.7, y + h * 0.5], [x + h * 0.3, y + h * 0.76], [x + h * 0.26, y + h * 0.78], [x, y + h * 0.58]], tr, { key: false });
    fan(f, [x, y + h * 0.84], [[x - h * 0.55, y + h * 0.8], [x - h * 0.36, y + h * 0.93], [x, y + h * 0.99], [x + h * 0.38, y + h * 0.93], [x + h * 0.58, y + h * 0.8], [x + h * 0.3, y + h * 0.74], [x - h * 0.28, y + h * 0.74]], v);
  },
  jungletree(c, x, y, h) {
    const { f, pal, state, rnd } = c; if (state === 'burned') return charredTree(c, x, y, h * 0.85, 6);
    const v = col3(pal, 'v', state), v2 = col3(pal, 'v2', state), tw = h * 0.04;
    f.poly([[x - tw * 3, y], [x - tw, y + h * 0.18], [x + tw, y + h * 0.18], [x + tw * 3, y]], state === 'scorched' ? CHAR[1] : mix(pal.t, '#000000', 0.12));
    f.poly([[x - tw, y + h * 0.1], [x + tw, y + h * 0.1], [x + tw * 0.8, y + h * 0.78], [x - tw * 0.8, y + h * 0.78]], state === 'scorched' ? CHAR[1] : pal.t);
    for (const [dx, dy, s] of [[-h * 0.2, 0.74, 0.26], [h * 0.22, 0.78, 0.24], [0, 0.88, 0.3]]) fan(f, [x + dx, y + h * dy], blob([x + dx, y + h * dy], h * s, h * s * 0.7, 8, rnd, 0.14), v);
    for (let i = 0; i < 3; i++) { const lx = x + (i - 1) * h * 0.18; f.line([[lx, y + h * 0.7], [lx + 3 * (i - 1), y + h * 0.3]], v2[1], 1.6); }
  },
  fern(c, x, y, h) {
    const { f, pal, state, rnd } = c; if (state === 'burned') return stubs(c, x, y, h, 5, 40);
    const v = col3(pal, 'v2', state);
    for (let i = 0; i < 6; i++) { const a = (i / 5 - 0.5) * 2.2 + (rnd() - 0.5) * 0.2, L = h * (0.7 + rnd() * 0.3), ex = x + Math.sin(a) * L * 0.9, ey = y + Math.cos(a) * L * 0.8, mx = x + Math.sin(a) * L * 0.4, my = y + Math.cos(a) * L * 0.7 + L * 0.2; f.poly([[x, y], [mx - 3, my], [ex, ey], [mx + 3, my - 2]], i % 2 ? v[0] : v[1], { sw: 0.8 }); }
  },
  flower(c, x, y, h) {
    const { f, pal, state } = c; if (state !== 'clean') return stubs(c, x, y, h * 0.5, 2, 14);
    f.line([[x, y], [x, y + h]], pal.v[2], 2); const cx = x, cy = y + h; fan(f, [cx, cy], Array.from({ length: 10 }, (_, i) => { const a = i / 10 * Math.PI * 2; return [cx + Math.cos(a) * h * (i % 2 ? 0.24 : 0.4), cy + Math.sin(a) * h * (i % 2 ? 0.24 : 0.4)]; }), [lite(pal.acc, 0.25), pal.acc, dark(pal.acc, 0.25)]);
  },
  palm(c, x, y, h) {
    const { f, pal, state, rnd } = c; const lean = (rnd() - 0.5) * h * 0.3;
    if (state === 'burned') { f.poly([[x - 4, y], [x + 4, y], [x + lean + 2, y + h * 0.85], [x + lean - 2, y + h * 0.85]], CHAR[1]); return; }
    const v = col3(pal, 'v', state), tr = state === 'scorched' ? CHAR[1] : pal.t;
    f.poly([[x - 5, y], [x + 5, y], [x + lean + 3, y + h * 0.85], [x + lean - 3, y + h * 0.85]], tr); f.poly([[x - 5, y], [x - 1, y], [x + lean, y + h * 0.85], [x + lean - 3, y + h * 0.85]], lite(tr, 0.12), { key: false });
    const tx = x + lean, ty = y + h * 0.85;
    for (let i = 0; i < 7; i++) { const a = (i / 6 - 0.5) * 3.0, L = h * 0.42, ex = tx + Math.sin(a) * L, ey = ty + Math.cos(a) * L * 0.2 - Math.abs(Math.sin(a)) * L * 0.45, mx = tx + Math.sin(a) * L * 0.55, my = ty + Math.cos(a) * L * 0.35 + L * 0.1; f.poly([[tx, ty], [mx, my + 5], [ex, ey], [mx, my - 3]], [v[0], v[1], v[2]][i % 3], { sw: 0.8 }); }
  },
  mangrove(c, x, y, h) {
    const { f, pal, state, rnd } = c; if (state === 'burned') { charredTree(c, x, y + h * 0.15, h * 0.6, 3); return; }
    const v = col3(pal, 'v', state), tr = state === 'scorched' ? CHAR[1] : pal.t;
    for (let i = 0; i < 5; i++) { const s = (i - 2) * h * 0.14; f.line([[x + s * 0.2, y + h * 0.35], [x + s * 0.9, y + h * 0.18], [x + s, y]], tr, 2.4); }
    f.poly([[x - 5, y + h * 0.3], [x + 5, y + h * 0.3], [x + 3.5, y + h * 0.6], [x - 3.5, y + h * 0.6]], tr);
    fan(f, [x, y + h * 0.75], blob([x, y + h * 0.75], h * 0.32, h * 0.22, 8, rnd, 0.16), v);
  },
  reed(c, x, y, h) {
    const { f, pal, state, rnd } = c; if (state === 'burned') return stubs(c, x, y, h, 9, 44);
    const v = col3(pal, 'v2', state);
    for (let i = 0; i < 8; i++) { const bx = x + (i - 4) * 5 + (rnd() - 0.5) * 4, hh = h * (0.7 + rnd() * 0.5), lean = (rnd() - 0.5) * h * 0.2; f.poly([[bx - 2.2, y], [bx + 2.2, y], [bx + lean, y + hh]], [v[0], v[1], v[2]][i % 3], { sw: 0.7 }); if (i % 3 === 0) f.poly([[bx + lean - 2, y + hh - 9], [bx + lean + 2, y + hh - 9], [bx + lean + 1.4, y + hh + 6], [bx + lean - 1.4, y + hh + 6]], dark(v[2], 0.3), { sw: 0.7 }); }
  },
  pool(c, x, y, h) { const { f, pal, state } = c; if (state === 'burned') return; const w = 90 + (c.rnd() * 60); f.poly([[x - w, y + 0.5], [x - w * 0.5, y - h], [x + w * 0.5, y - h * 1.1], [x + w, y + 0.5]], pal.w[0], { sw: 0.9 }); f.line([[x - w * 0.6, y + 0.8], [x + w * 0.6, y + 0.8]], pal.acc, 1.4); },
  cactus(c, x, y, h) {
    const { f, pal, state } = c; if (state === 'burned') { f.poly([[x - 6, y], [x + 6, y], [x + 5, y + h * 0.9], [x - 5, y + h * 0.9]], CHAR[1]); return; }
    const v = col3(pal, 'v', state), w = Math.max(6, h * 0.075);
    f.poly([[x - w, y], [x, y], [x, y + h * 0.95], [x - w * 0.5, y + h]], v[0]); f.poly([[x, y], [x + w, y], [x + w * 0.5, y + h], [x, y + h * 0.95]], v[2]);
    for (const s of [-1, 1]) { const ay = y + h * (s < 0 ? 0.45 : 0.6), ax = x + s * h * 0.28; f.poly([[x, ay - 5], [ax - s * w * 0.2, ay - 5], [ax - s * w * 0.2, ay + h * 0.3], [ax + s * w * 1.1, ay + h * 0.3], [ax + s * w * 1.1, ay - 5], [ax + s * w * 0.9, ay - 11], [ax - s * w * 0.5, ay - 11], [x + s * w * 0.4, ay + 8]], s < 0 ? v[0] : v[2], { sw: 0.9 }); }
  },
  scrub(c, x, y, h) { const { f, pal, state, rnd } = c; if (state === 'burned') return stubs(c, x, y, h, 5, 44); const v = col3(pal, 'v2', state); for (let i = 0; i < 7; i++) { const bx = x + (i - 3) * h * 0.2, lean = (i - 3) * h * 0.16 + (rnd() - 0.5) * 6; f.poly([[bx - 4, y], [bx + 4, y], [bx + lean, y + h * (0.7 + rnd() * 0.5)]], [v[0], v[1], v[2]][i % 3], { sw: 0.8 }); } },
  shrub(c, x, y, h) { const { f, pal, state, rnd } = c; if (state === 'burned') return stubs(c, x, y, h, 5, 40); const v = col3(pal, 'v', state); fan(f, [x, y + h * 0.4], blob([x, y + h * 0.4], h * 0.7, h * 0.4, 7, rnd, 0.15), v); },
  tuft(c, x, y, h) { const { f, pal, state, rnd } = c; if (state === 'burned') return stubs(c, x, y, h, 5, 26); const v = col3(pal, 'v2', state); for (let i = 0; i < 7; i++) { const bx = x + (i - 3) * 3.2, lean = (i - 3) * h * 0.1 + (rnd() - 0.5) * 6; f.poly([[bx - 1.8, y], [bx + 1.8, y], [bx + lean, y + h * (0.7 + rnd() * 0.5)]], [v[0], v[1], v[2]][i % 3], { key: false }); } },
  dunegrass(c, x, y, h) { const { f, pal, state, rnd } = c; if (state === 'burned') return stubs(c, x, y, h, 5, 26); const v = col3(pal, 'v2', state); for (let i = 0; i < 6; i++) { const bx = x + (i - 3) * 3, lean = (i - 3) * h * 0.22; f.poly([[bx - 1.4, y], [bx + 1.4, y], [bx + lean, y + h * (0.8 + rnd() * 0.4)]], [v[0], v[1]][i % 2], { key: false }); } },
  krummholz(c, x, y, h) { const { f, pal, state, rnd } = c; if (state === 'burned') return charredTree(c, x, y, h, 3); const v = col3(pal, 'v', state); f.poly([[x - 3, y], [x + 3, y], [x + 8, y + h * 0.45], [x + 3, y + h * 0.5]], pal.t); for (const dx of [0.4, 0.9, 1.3]) fan(f, [x + h * dx * 0.5, y + h * (0.5 + dx * 0.05)], blob([x + h * dx * 0.5, y + h * (0.5 + dx * 0.05)], h * 0.34, h * 0.2, 7, rnd, 0.14), v); f.poly([[x + h * 0.1, y + h * 0.66], [x + h * 0.55, y + h * 0.74], [x + h * 0.7, y + h * 0.64]], pal.acc, { key: false }); },
  boulder(c, x, y, h) { const { f, pal, rnd } = c; const r = col3(pal, 'r', c.state === 'burned' ? 'scorched' : c.state); fan(f, [x, y + h * 0.4], [[x - h * 0.95, y], [x - h * 0.7, y + h * 0.7], [x - h * 0.1, y + h * 0.95], [x + h * 0.6, y + h * 0.75], [x + h * 0.95, y]], r); },
  tor(c, x, y, h) {
    const { f, pal, state } = c; const r = col3(pal, 'r', state === 'burned' ? 'scorched' : state), w = h * 0.34;
    // stacked weathered blocks, each a little wider or narrower than the one below, a skirt of fallen blocks
    const blocks = [[-w * 0.95, w * 0.95, 0, 0.34], [-w * 0.75, w * 0.88, 0.34, 0.62], [-w * 0.55, w * 0.62, 0.62, 0.84], [-w * 0.4, w * 0.45, 0.84, 1.0]];
    for (const [x0, x1, t0, t1] of blocks) { f.poly([[x + x0, y + h * t0], [x + x0 - 3, y + h * (t0 + t1) / 2], [x + x0 + 4, y + h * t1], [x + x1 - 2, y + h * t1 - 3], [x + x1 + 3, y + h * (t0 + t1) / 2], [x + x1, y + h * t0]], r[1]); f.poly([[x + (x0 + x1) * 0.25, y + h * t0], [x + (x0 + x1) * 0.25 + 4, y + h * t1], [x + x1 - 2, y + h * t1 - 3], [x + x1 + 3, y + h * (t0 + t1) / 2], [x + x1, y + h * t0]], r[2], { sw: 0.8 }); f.line([[x + x0 + 6, y + h * t1 - 2], [x + x1 - 8, y + h * t1 - 1]], r[0], 1.2); }
    for (const dx of [-w * 1.3, w * 1.25]) fan(f, [x + dx, y + h * 0.07], [[x + dx - h * 0.1, y], [x + dx - h * 0.06, y + h * 0.12], [x + dx + h * 0.05, y + h * 0.14], [x + dx + h * 0.1, y]], r);
  },
  heath(c, x, y, h) {
    const { f, pal, state, rnd } = c; if (state === 'burned') return stubs(c, x, y, h, 6, 46);
    const v = col3(pal, 'v', state), dots = col3(pal, 'v2', state);
    fan(f, [x, y + h * 0.35], blob([x, y + h * 0.35], h * 1.05, h * 0.5, 8, rnd, 0.16), v);
    for (let i = 0; i < 4; i++) { const bx = x + (rnd() - 0.5) * h * 1.4, by = y + h * (0.45 + rnd() * 0.3); f.poly([[bx - 2, by], [bx, by + 3], [bx + 2, by]], lite(v[0], 0.25), { key: false }); }
  },
  scree(c, x, y, h) { const { f, pal, rnd } = c; const r = col3(pal, 'r', c.state === 'burned' ? 'scorched' : c.state); for (let i = 0; i < 9; i++) { const bx = x + (i - 4) * 14 + (rnd() - 0.5) * 6, s = 5 + rnd() * h * 0.5; f.poly([[bx - s, y], [bx - s * 0.2, y + s * 0.9], [bx + s * 0.8, y]], r[i % 3], { sw: 0.8 }); } },
  mesa(c, x, y, h) { const { f, pal, state } = c; const r = col3(pal, 'r', state === 'burned' ? 'scorched' : state), bands = 5, w = h * 0.34; f.poly([[x - w * 2.3, y], [x - w * 0.95, y + h * 0.3], [x + w * 0.95, y + h * 0.3], [x + w * 2.3, y]], mix(r[1], pal.g[1], 0.35)); for (let i = 0; i < bands; i++) { const t0 = 0.3 + i * 0.14, t1 = t0 + 0.14, w0 = w * (1 - (t0 - 0.3) * 0.2), w1 = w * (1 - (t1 - 0.3) * 0.2); f.poly([[x - w0, y + h * t0], [x - w1, y + h * Math.min(1, t1)], [x + w1, y + h * Math.min(1, t1)], [x + w0, y + h * t0]], i % 2 ? r[1] : r[0], { sw: 0.9 }); } f.poly([[x + w * 0.1, y + h * 0.3], [x + w * 0.1, y + h], [x + w * 0.86, y + h], [x + w, y + h * 0.3]], r[2], { sw: 0.9, op: 0.45 }); },
  stack(c, x, y, h) { const { f, pal, rnd } = c; const r = pal.r, w = h * 0.2, V = [[x - w * 1.5, y - 10], [x - w * 1.2, y + h * 0.4], [x - w * 0.8, y + h * 0.82], [x - w * 0.1, y + h], [x + w * 0.7, y + h * 0.9], [x + w * 1.0, y + h * 0.5], [x + w * 1.5, y - 10]]; f.poly(V, r[1]); f.poly([V[3], V[4], V[5], V[6], [x + w * 0.1, y - 10]], r[2], { sw: 0.9 }); f.poly([V[0], V[1], V[2], V[3], [x - w * 0.1, y + h * 0.4]], r[0], { sw: 0.9, op: 0.9 }); f.line([[x - w * 1.3, y + h * 0.35], [x + w * 1.1, y + h * 0.4]], r[2], 1.1); f.line([[x - w * 0.9, y + h * 0.68], [x + w * 0.8, y + h * 0.72]], r[2], 1.1); },
  basaltcol(c, x, y, h) { const { f, pal, rnd } = c; const r = pal.r; for (let i = 0; i < 5; i++) { const cx = x + (i - 2) * 16, hh = h * (0.55 + 0.45 * (1 - Math.abs(i - 2) / 2.4)) * (0.85 + rnd() * 0.2); f.poly([[cx - 7, y], [cx - 7, y + hh], [cx, y + hh + 4], [cx + 7, y + hh], [cx + 7, y]], i % 2 ? r[1] : r[0], { sw: 0.9 }); f.poly([[cx, y], [cx, y + hh + 4], [cx + 7, y + hh], [cx + 7, y]], r[2], { sw: 0.8, key: false }); } },
  vent(c, x, y, h) { const { f, pal, rnd } = c; const r = pal.r; f.poly([[x - h * 0.8, y], [x - h * 0.15, y + h * 0.7], [x + h * 0.15, y + h * 0.7], [x + h * 0.8, y]], r[1]); f.poly([[x, y], [x, y + h * 0.7], [x + h * 0.15, y + h * 0.7], [x + h * 0.8, y]], r[2], { sw: 0.8 }); for (let i = 0; i < 3; i++) fan(f, [x + i * 6, y + h * (0.9 + i * 0.5)], blob([x + i * 6, y + h * (0.9 + i * 0.5)], h * (0.3 + i * 0.12), h * (0.22 + i * 0.08), 7, rnd, 0.14), [lite(pal.v2[0], 0.2), pal.v2[0], pal.v2[1]]); },
  lavaflow(c, x, y, h) { const { f, pal } = c; const w = 180 + c.rnd() * 80; f.poly([[x - w, y], [x - w * 0.5, y + h], [x + w * 0.5, y + h * 1.1], [x + w, y]], '#7a3220', { sw: 0.9 }); f.poly([[x - w * 0.6, y + h * 0.5], [x - w * 0.2, y + h * 0.9], [x + w * 0.35, y + h * 0.95], [x + w * 0.7, y + h * 0.4]], pal.acc, { key: false }); },
  icespire(c, x, y, h) { const { f, pal, rnd } = c; for (const [dx, k] of [[-h * 0.22, 0.7], [0, 1], [h * 0.2, 0.55]]) { const hh = h * k, w = h * 0.14 * (0.8 + k * 0.4); f.poly([[x + dx - w, y], [x + dx - w * 0.5, y + hh * 0.8], [x + dx, y + hh], [x + dx, y]], pal.g[0], { sw: 0.9 }); f.poly([[x + dx, y], [x + dx, y + hh], [x + dx + w * 0.6, y + hh * 0.75], [x + dx + w, y]], pal.g[2], { sw: 0.9 }); } },
  crevasse(c, x, y, h) { const { f, pal } = c; const w = 14 + c.rnd() * 10; f.poly([[x - w, y + 0.6], [x - w * 0.3, y - h * 3], [x + w * 0.2, y - h * 5], [x + w * 0.5, y - h * 2.8], [x + w, y + 0.6]], '#1b3350', { sw: 0.9 }); },
  nunatak(c, x, y, h) { const { f, pal } = c; const r = pal.r; f.poly([[x - h * 0.7, y], [x - h * 0.25, y + h * 0.7], [x, y + h], [x + h * 0.3, y + h * 0.65], [x + h * 0.8, y]], r[1]); f.poly([[x, y], [x, y + h], [x + h * 0.3, y + h * 0.65], [x + h * 0.8, y]], r[2], { sw: 0.8 }); f.poly([[x - h * 0.2, y + h * 0.75], [x, y + h], [x + h * 0.2, y + h * 0.78], [x, y + h * 0.7]], pal.g[0], { sw: 0.8 }); },
  snowpatch(c, x, y, h) { const { f, pal } = c; const w = 50 + c.rnd() * 70; f.poly([[x - w, y], [x - w * 0.5, y + h], [x + w * 0.4, y + h * 1.1], [x + w, y]], pal.acc, { sw: 0.8 }); f.poly([[x + w * 0.1, y + 1], [x + w * 0.4, y + h * 1.1], [x + w, y]], mix(pal.acc, '#485765', 0.35), { key: false }); },
  berg(c, x, y, h) { const { f, pal, rnd } = c; const w = h * 0.9; f.poly([[x - w, y], [x - w * 0.7, y + h * 0.45], [x - w * 0.2, y + h], [x + w * 0.15, y + h * 0.7], [x + w * 0.6, y + h * 0.85], [x + w, y]], '#e6e6e0'); f.poly([[x + w * 0.1, y], [x + w * 0.15, y + h * 0.7], [x + w * 0.6, y + h * 0.85], [x + w, y]], '#485765', { sw: 0.9 }); f.poly([[x - w, y], [x + w, y], [x + w * 0.7, y - h * 0.4], [x - w * 0.5, y - h * 0.45]], '#3a7893', { sw: 0.9, op: 0.9 }); },
  floeblock(c, x, y, h) { const { f, pal } = c; const w = h * 1.1; f.poly([[x - w, y], [x - w, y + h], [x + w * 0.6, y + h], [x + w * 0.6, y]], pal.g[0]); f.poly([[x + w * 0.6, y], [x + w * 0.6, y + h], [x + w, y + h * 0.7], [x + w, y]], pal.g[2], { sw: 0.9 }); },
  termite(c, x, y, h) { const { f, pal } = c; f.poly([[x - h * 0.5, y], [x - h * 0.3, y + h * 0.6], [x - h * 0.08, y + h], [x + h * 0.1, y + h * 0.95], [x + h * 0.32, y + h * 0.55], [x + h * 0.5, y]], mix(pal.sub, '#ffffff', 0.1)); f.poly([[x + h * 0.04, y], [x + h * 0.1, y + h * 0.95], [x + h * 0.32, y + h * 0.55], [x + h * 0.5, y]], dark(pal.sub, 0.25), { sw: 0.8 }); },
  driftwood(c, x, y, h) { const { f, pal } = c; const L = 70 + c.rnd() * 40; f.poly([[x - L, y + 1], [x - L * 0.9, y + h], [x + L * 0.8, y + h * 1.1], [x + L, y + 3]], mix(pal.t, '#d8d0c0', 0.35)); f.line([[x - L * 0.3, y + h], [x - L * 0.2, y + h * 2.4]], mix(pal.t, '#d8d0c0', 0.35), 2.2); },
  whitecap(c, x, y, h) { const { f, pal } = c; const L = 26 + c.rnd() * 50; f.poly([[x - L, y], [x - L * 0.3, y + h * 0.9], [x + L * 0.1, y + h * 0.3], [x + L * 0.5, y + h], [x + L, y]], pal.acc, { sw: 0.7 }); },
  foam(c, x, y, h) { COVER.whitecap(c, x, y, 6); },
  skull() {},
};

// ---------------------------------------------------------------------------------------------------------------- the strip scene
// opts: id (biome), mix (for transitions: { a, b, x0, x1 }), state, seed, damage: { x0, x1 } (the span), crater: { x, R }, S, ww, wh, px, py
const SCAR = { desert: ['#1f3d38', '#bfe0d8'], beach: ['#1f3d38', '#bfe0d8'], ice_sheet: ['#485765', '#5f8aa2'], sea_ice: ['#485765', '#5f8aa2'], volcanic: ['#8a868e', '#dc6a26'] };
export function scene(o) {
  const S = o.S ?? 1.2, ww = o.ww ?? 1200, wh = o.wh ?? 460, f = new Frame({ px: o.px ?? 0, py: o.py ?? 0, S, wx0: o.wx0 ?? 0, ww, wh });
  const keyDef = o.key ? KEYS.find(k => k.id === o.key) : null, bands = keyDef ? skyAt(keyDef.phase).bands : null; if (keyDef) f.tint = WORLD[keyDef.id];
  const A = BIOMES[o.id ?? o.mix.a], B = o.mix ? BIOMES[o.mix.b] : A, pal = A.pal, state = o.state ?? 'clean', seed = o.seed ?? 7, G = 118;   // the ground line, in units from the panel's bottom
  const mixAt = x => { if (!o.mix) return 0; const t = (x - o.mix.x0) / (o.mix.x1 - o.mix.x0); return t <= 0 ? 0 : t >= 1 ? 1 : (Math.floor(t * 5) + 0.5) / 5; };   // stepped, never a fade
  const smoothT = x => { if (!o.mix) return 0; return smoothstep(o.mix.x0, o.mix.x1, x); };
  const palAt = (x, k, i) => mix(A.pal[k][i], B.pal[k][i], mixAt(x));
  const skyZ = bands ? bands.top : mix(A.pal.sky[0], B.pal.sky[0], o.mix ? 0.5 : 0), skyH = bands ? bands.horizon : mix(A.pal.sky[1], B.pal.sky[1], o.mix ? 0.5 : 0);
  // sky: four hard bands
  const hz = 262;
  [[0, 1], [0.33, 0.75], [0.66, 0.5], [1, 0.25]].forEach(([t, k], i, arr) => { const y0 = hz + (wh - hz) * (i / 4), y1 = hz + (wh - hz) * ((i + 1) / 4); f.rect(f.wx0, y0 - (i ? 0 : 400), f.wx0 + ww, y1, bands ? [bands.horizon, bands.lower, bands.upper, bands.top][i] : mix(skyH, skyZ, [0, 0.33, 0.66, 1][i])); });
  f.layer = 'ground';
  // far land: three ridges, a value ladder toward the haze, each ridge cut into lit and shade facets
  const pa = profileFn(A.profile.kind, A.profile.amp, A.profile.wave, seed + 1), pb = profileFn(B.profile.kind, B.profile.amp, B.profile.wave, seed + 2);
  const farBase = b => b.far.kind === 'peaks' || b.far.kind === 'mesas' || b.far.kind === 'cones' ? b.pal.r[1] : b.far.kind === 'shelf' ? b.pal.g[0] : mix(b.pal.v[1], b.pal.r[1], 0.25);
  const hazeC = skyH, noFar = A.far.kind === 'none' && B.far.kind === 'none';
  const seaPlaneFull = () => { f.layer = 'water'; const bio = [A, B].find(b => b.profile.kind === 'floes') ?? [A, B].find(b => b.profile.kind === 'shore') ?? A; const wc = bio.pal.w[1]; [[0.5, 0], [0.3, 1], [0.14, 2]].forEach(([k_, k]) => { const lo = hz - 48 * (k + 1), hi = hz - 48 * k; f.poly([[f.wx0 - 80, lo], [f.wx0 + ww + 80, lo], [f.wx0 + ww + 80, hi], [f.wx0 - 80, hi]], mix(wc, hazeC, k_), { key: false }); }); f.poly([[f.wx0 - 80, G - 4], [f.wx0 + ww + 80, G - 4], [f.wx0 + ww + 80, hz - 144], [f.wx0 - 80, hz - 144]], mix(wc, hazeC, 0.02), { key: false }); f.layer = 'ground'; };
  const bandsOf = () => o.mix ? [[f.wx0 - 80, o.mix.x0, 0], ...Array.from({ length: 5 }, (_, q) => [o.mix.x0 + (o.mix.x1 - o.mix.x0) * q / 5, o.mix.x0 + (o.mix.x1 - o.mix.x0) * (q + 1) / 5, (q + 0.5) / 5]), [o.mix.x1, f.wx0 + ww + 80, 1]] : [[f.wx0 - 80, f.wx0 + ww + 80, 0]];
  const coast = [A, B].some(b => b.profile.kind === 'shore' || b.profile.kind === 'floes'), floesOnly = [A, B].every(b => b.profile.kind === 'floes' || b.profile.kind === 'swell') && [A, B].some(b => b.profile.kind === 'floes'), landFrom = coast && !floesOnly ? 260 : -1e9, landK = x => coast ? smoothstep(landFrom, landFrom + 380, x) : 1;
  if (coast) seaPlaneFull();
  if (!noFar) [[0.6, 1.0], [0.42, 0.8], [0.26, 0.62]].forEach(([haze, amp], i) => {
    const ph = 1.3 + i * 2.1, w = 420 + i * 120, base0 = floesOnly ? hz - 12 - i * 5 : hz - 64 + i * 26, stepX = 66, farBot = floesOnly ? base0 - 3 : coast ? hz - 150 : 0;
    const hAt = x => { const t = smoothT(x), ka = FAR[A.far.kind] ?? FAR.none, kb = FAR[B.far.kind] ?? FAR.none; return lerp(hz - 150, base0 + lerp(A.far.kind === 'none' ? 0 : ka(x, A.far.amp * amp, ph, w), B.far.kind === 'none' ? 0 : kb(x, B.far.amp * amp, ph, w), t) * 0.8, landK(x)); };
    for (let x = f.wx0 - 80; x < f.wx0 + ww + 80; x += stepX) {
      const x1 = x + stepX, y0 = hAt(x), y1 = hAt(x1), tm = mixAt(x + stepX / 2), base = mix(farBase(A), farBase(B), tm), col = mix(base, hazeC, haze), sl = y1 - y0;
      f.poly([[x, farBot], [x, y0], [x1, y1], [x1, farBot]], sl > 5 ? lite(col, 0.07) : sl < -5 ? dark(col, 0.1) : col, { key: false });
      const capKind = ['peaks', 'cones'].includes((tm < 0.5 ? A : B).far.kind) && (tm < 0.5 ? A : B).id !== 'volcanic' && (tm < 0.5 ? A : B).name !== 'Volcanic ground', th = base0 + (tm < 0.5 ? A : B).far.amp * amp * 0.8 * 0.5;
      if (capKind && (y0 > th || y1 > th)) f.poly([[x, Math.max(y0, th)], [x1, Math.max(y1, th)], [x1, Math.min(th, y1)], [x, Math.min(th, y0)]], mix(sl > 5 ? '#f2f6f8' : '#b8c8d6', hazeC, haze * 0.7), { key: false });
    }
  });
  // the mid land: a hazed hill line under the near strip's cover
  if (!(o.id === 'ocean') && !floesOnly && !(o.id === 'sea_ice')) {
    const midY = x => G + 26 + 0.8 * lerp(pa(x * 0.8 + 300), pb(x * 0.8 + 300), smoothT(x));
    for (let x = f.wx0 - 80; x < f.wx0 + ww + 80; x += 48) { const x1 = x + 48, tm = mixAt(x + 24); if (coast && x1 < landFrom) continue; f.poly([[x, 0], [x, coast ? G - 6 + (midY(x) - G + 6) * landK(x) : midY(x)], [x1, coast ? G - 6 + (midY(x1) - G + 6) * landK(x1) : midY(x1)], [x1, 0]], mix(mix(A.pal.g[1], B.pal.g[1], tm), hazeC, 0.22), { key: false }); }
  }
  // the sea plane: stepped bands from the waterline to the horizon, lighter toward the haze (a visible horizon: one hard step to the sky)
  const seaBiome = x => (BIOMES[o.id ?? (mixAt(x) < 0.5 ? o.mix.a : o.mix.b)]);
  const seaPlane = (x0, x1, yWater, bio) => { f.layer = 'water'; const wc = bio.pal.w[1]; [[0.5, 0], [0.3, 1], [0.14, 2]].forEach(([hz_, k]) => { const ya = hz - 48 * (k + 1) + 48, yb = hz - 48 * k; const lo = Math.max(yWater, hz - 48 * (k + 1)), hi = hz - 48 * k; if (hi <= yWater) return; f.poly([[x0, lo], [x1, lo], [x1, hi], [x0, hi]], mix(wc, hazeC, hz_), { key: false }); }); };
  if (o.id === 'ocean') seaPlane(f.wx0 - 80, f.wx0 + ww + 80, 0, A);
  f.layer = o.id === 'ocean' ? 'water' : 'ground';
  // the near ground: profile with the crater carved in, facets coloured by slope
  const R = o.crater ? o.crater.R : 0, cx = o.crater ? o.crater.x : 0, depth = R * 0.26, rimH = depth * 0.5;
  const craterAt = x => { if (!o.crater) return 0; const u = Math.abs(x - cx) / R; if (u < 1) return -depth * (1 - u * u) ** 2 + (u > 0.7 ? rimH * smoothstep(0.7, 1, u) : 0); if (u < 2) return rimH * (1 - smoothstep(1, 2, u)); return 0; };
  const prof = x => { const t = smoothT(x); return lerp(pa(x), pb(x), t) + craterAt(x); };
  const isWaterBiome = id => id === 'ocean';
  const ocean = (o.id === 'ocean');
  const step = 16, pts = []; for (let x = f.wx0 - 40; x <= f.wx0 + ww + 40; x += step) pts.push([x, G + prof(x)]);
  const inBowl = x => o.crater && Math.abs(x - cx) < R * 0.95;
  const burnSpan = (o.damage && o.damage.kind === 'burned') ? o.damage : null, scarSpan = (o.damage && o.damage.kind === 'scorched') ? o.damage : null;
  const gcol = (x, i) => { let c = palAt(x, 'g', i); if (inBowl(x) && !ocean) c = [mix(A.pal.sub, '#ffffff', 0.14), A.pal.sub, dark(A.pal.sub, 0.3)][i]; if (burnSpan && x >= burnSpan.x0 && x <= burnSpan.x1) c = mix(c, ['#6a655f', '#4a4642', '#2c2a28'][i], 0.78); return c; };
  const skin = 34;
  for (let i = 0; i < pts.length - 1; i++) {
    const [x0, y0] = pts[i], [x1, y1] = pts[i + 1], sl = (y1 - y0) / step, xm = (x0 + x1) / 2;
    const idx = sl > 0.12 ? 0 : sl < -0.12 ? 2 : 1;
    f.poly([[x0, y0], [x1, y1], [x1, y1 - skin], [x0, y0 - skin]], gcol(xm, idx), { key: false });
    // below the skin: the subsoil band (stepped) and the body of the ground
    f.poly([[x0, y0 - skin], [x1, y1 - skin], [x1, 0], [x0, 0]], ocean ? mix(A.pal.g[2], A.pal.sub, 0.5) : mix(palAt(xm, 'g', 2), A.pal.sub, 0.45), { key: false });
  }
  // the keyline along the surface
  f.line(pts.map(p => p), KEY, 1.6);
  // strata lines for rock biomes
  if (['desert', 'mountains', 'volcanic'].includes(o.id)) for (let k = 1; k <= 3; k++) { const yy = k * 26; f.line([[f.wx0, yy], [f.wx0 + ww, yy + 4 * Math.sin(k)]], mix(A.pal.g[2], '#000000', 0.25), 1); }
  // a beam's scar along the surface (a glassy band on sand, slate on ice, a black char band elsewhere); on open water a steam line
  if (scarSpan) {
    const [fillc, edge] = SCAR[o.id ?? A.id] ?? ['#221c18', '#4a4036'];
    if (ocean) { for (let x = scarSpan.x0; x < scarSpan.x1; x += 70) { const y = G + prof(x); f.poly([[x, y + 2], [x + 18, y + 20 + (x % 3) * 4], [x + 40, y + 8], [x + 60, y + 2]], '#cfdde6', { sw: 0.8 }); } }
    else { const top = [], bot = []; for (let x = scarSpan.x0; x <= scarSpan.x1; x += 16) { top.push([x, G + prof(x) + 1]); bot.push([x, G + prof(x) - 13 - 3 * Math.sin(x * 0.07)]); } f.poly([...top, ...bot.reverse()], fillc, { key: false }); f.line(top, edge, 1.6); }
  }
  f.layer = 'water';
  // water in the lows: the sea surface for beach and sea ice, and wetland pools drawn as cover
  const waterId = (x) => { const bsel = mixAt(x) < 0.5 ? A : B; return bsel; };
  const needsWater = ['beach', 'sea_ice'].includes(o.id) || (o.mix && (['beach', 'sea_ice'].includes(o.mix.a) || ['beach', 'sea_ice'].includes(o.mix.b)));
  if (needsWater) {
    for (let x = f.wx0 - 80; x < f.wx0 + ww + 80; x += 48) { if (G + prof(x + 24) < G - 6 && G + prof(x) < G - 6 || (o.mix && false)) seaPlane(x, x + 48, G, waterId(x + 24)); }
    const wl = G; const wpts = []; for (let x = f.wx0 - 40; x <= f.wx0 + ww + 40; x += step) wpts.push(x);
    for (let i = 0; i < wpts.length - 1; i++) { const x0 = wpts[i], x1 = wpts[i + 1], xm = (x0 + x1) / 2, y0 = G + prof(x0), y1 = G + prof(x1); if (y0 >= wl && y1 >= wl) continue; const bsel = waterId(xm); f.poly([[x0, Math.max(wl, 0)], [x1, wl], [x1, Math.min(y1, wl) - 0.01], [x0, Math.min(y0, wl) - 0.01]], bsel.pal.w[0], { key: false }); }
    // a deep step under the shallows
    for (let i = 0; i < wpts.length - 1; i++) { const x0 = wpts[i], x1 = wpts[i + 1], y0 = G + prof(x0), y1 = G + prof(x1); if (y0 >= wl - 30 && y1 >= wl - 30) continue; f.poly([[x0, wl - 30], [x1, wl - 30], [x1, Math.min(y1, wl - 30)], [x0, Math.min(y0, wl - 30)]], waterId((x0 + x1) / 2).pal.w[1], { key: false }); }
    f.line([[f.wx0, wl], [f.wx0 + ww, wl]], A.pal.acc, 1.2);
  }
  f.layer = 'trees';
  // cover: back to front (the small ones in the mid land first, then the strip's own)
  const rnd = rng(seed + 11);
  const placeCover = (biome, x0, x1, scale, yAt, filterFn) => {
    const items = [];
    for (const cv of biome.cover) {
      const nPer = cv.n * ((x1 - x0) / 1200);
      let n = Math.floor(nPer) + (rnd() < nPer - Math.floor(nPer) ? 1 : 0);
      for (let i = 0; i < n; i++) { const x = x0 + rnd() * (x1 - x0), h = (cv.h[0] + rnd() * (cv.h[1] - cv.h[0])) * scale; if (filterFn && !filterFn(x, cv.k)) continue; items.push({ k: cv.k, x, h, z: rnd() }); }
    }
    return items.sort((a, b) => a.z - b.z);
  };
  const drawItem = (it, yBase, biome, stt) => { const fn = COVER[it.k]; if (!fn) return; const c = { f, pal: biome.pal, state: stt, rnd: rng(Math.floor(it.x * 7) + seed), S }; fn(c, it.x, yBase, it.h); };
  const inCrater = x => o.crater && Math.abs(x - cx) < R * 1.25;
  const stateAt = x => { if (burnSpan && x >= burnSpan.x0 && x <= burnSpan.x1) return 'burned'; if (scarSpan && x >= scarSpan.x0 && x <= scarSpan.x1) return 'scorched'; return state === 'burned' || state === 'scorched' ? 'clean' : 'clean'; };
  const biomeAt = x => (mixAt(x) < 0.5 ? A : B);
  const eco = o.mix ? o.mix.eco : [];
  // the mid land cover: small and hazed (drawn first, behind the ground line's cover)
  if (!ocean) {
    const miniItems = placeCover(A, f.wx0, f.wx0 + ww, 0.42, null, null).concat(o.mix ? placeCover(B, f.wx0, f.wx0 + ww, 0.42, null, null) : []).filter(it => !o.mix || (biomeAt(it.x) === (it.fromB ? B : A)));
    for (const it of miniItems.filter(i => i.z < 0.9)) { if (o.mix) { const bsel = biomeAt(it.x); if (!bsel.cover.some(c => c.k === it.k)) continue; } const y = G + 28 + 0.8 * lerp(pa(it.x * 0.8 + 300), pb(it.x * 0.8 + 300), smoothT(it.x)); drawItem(it, y, biomeAt(it.x), 'clean'); }
    // haze over the mid cover by a flat translucent band is not allowed (no fades): the mid land is already hazed in its own colours
  }
  // the near cover on the strip
  let items = [];
  if (o.mix) {
    const zA = placeCover(A, f.wx0, f.wx0 + ww, 1, null, x => mixAt(x) < 0.5 || rnd() < 0.5 - mixAt(x) * 0.0), zB = placeCover(B, f.wx0, f.wx0 + ww, 1, null, x => mixAt(x) >= 0.5 || rnd() < 0.18);
    items = zA.filter(it => rnd() > mixAt(it.x) * 0.95).map(it => ({ ...it, b: A })).concat(zB.filter(it => rnd() > (1 - mixAt(it.x)) * 0.95).map(it => ({ ...it, b: B })));
    for (const k of eco) { const cv = A.cover.find(c => c.k === k) ?? B.cover.find(c => c.k === k); const h0 = cv ? cv.h : [60, 120]; for (let i = 0; i < 3; i++) { const x = o.mix.x0 + (o.mix.x1 - o.mix.x0) * (0.15 + 0.7 * rnd()); items.push({ k, x, h: h0[0] + rnd() * (h0[1] - h0[0]), z: rnd(), b: mixAt(x) < 0.5 ? A : B }); } }
    items.sort((a, b) => a.z - b.z);
  } else items = placeCover(A, f.wx0, f.wx0 + ww, 1, null, null).map(it => ({ ...it, b: A }));
  const waterAtGround = x => needsWater && (G + prof(x)) < G - 6;
  for (const it of items) {
    if (inCrater(it.x) || waterAtGround(it.x)) continue;
    if (it.k === 'crevasse' && false) continue;
    const y = G + prof(it.x); drawItem(it, y, it.b ?? A, stateAt(it.x));
  }
  if (o.crater && !ocean) { const rr = rng(seed + 99); for (let i = 0; i < 14; i++) { const side = i % 2 ? 1 : -1, x = cx + side * (R * (0.85 + rr() * 1.0)), y = G + prof(x), sz = 5 + rr() * 11; f.poly([[x - sz, y], [x - sz * 0.3, y + sz * 1.1], [x + sz * 0.9, y + sz * 0.4], [x + sz, y]], [A.pal.sub, A.pal.g[2], A.pal.r[1]][i % 3], { sw: 0.8 }); } }
  if (burnSpan) { const rr = rng(seed + 55); for (let i = 0; i < 18; i++) { const x = burnSpan.x0 + rr() * (burnSpan.x1 - burnSpan.x0), y = G + prof(x), sz = 4 + rr() * 7; f.poly([[x - sz, y], [x, y + sz * 0.8], [x + sz, y]], '#5a554f', { sw: 0.6 }); } }
  return { f, G, prof, scarSpan, burnSpan, A, B, ocean, pts };
}
