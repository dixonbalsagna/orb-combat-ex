// Origin: the destruction plumes of the biome look bible: three still frames per biome (burst, peak, settle), flat faceted polygons only (no blur, no fades). Deterministic.
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-23.
import { rng, mix, lite, dark, fan, scene } from './draw.mjs';
import { BIOMES } from './spec.mjs';

const blob = (c, rx, ry, n, rnd, jit = 0.2, rot = 0) => Array.from({ length: n }, (_, i) => { const a = i / n * Math.PI * 2 + rot, k = 1 + (rnd() - 0.5) * 2 * jit; return [c[0] + Math.cos(a) * rx * k, c[1] + Math.sin(a) * ry * k]; });
const puff = (f, c, r, cols, rnd, flat = 1) => fan(f, c, blob(c, r, r * flat, 8, rnd, 0.2), cols);
// a shard: a small kite, rotated
function shard(f, x, y, s, rot, col, key = true) { const c = Math.cos(rot), d = Math.sin(rot), P = (a, b) => [x + a * c - b * d, y + a * d + b * c]; f.poly([P(-s, 0), P(0, s * 0.45), P(s * 1.4, 0), P(0, -s * 0.35)], col, { sw: 0.8, key }); }
function chunk(f, x, y, s, col, rnd) { f.poly(blob([x, y], s, s * 0.8, 5, rnd, 0.3), col, { sw: 0.8 }); }

// frames: 0 burst, 1 peak, 2 settle. x0, y0: the impact point on the ground (world units); the plume spec comes from the biome.
export function drawPlume(f, id, frame, x0, y0, sky) {
  const b = BIOMES[id], P = b.plume, rnd = rng(1000 + frame * 17 + id.length), kinds = { 0: 0.3, 1: 1.0, 2: 0.7 }, k = kinds[frame];
  const fade = frame === 2 ? 0.28 : frame === 0 ? 0 : 0.08;
  const cols = P.cols.map(c => mix(c, sky, fade));
  const H = P.h * k, W = P.w * (frame === 2 ? 1.25 : frame === 1 ? 1.0 : 0.55), kind = P.kind;
  // the burst flash: a pale faceted star (one still frame, never lit white)
  if (frame === 0) { const R = 48 + (P.h > 320 ? 14 : 0), pts = Array.from({ length: 12 }, (_, i) => { const a = i / 12 * Math.PI * 2, rr = i % 2 ? R * 0.42 : R; return [x0 + Math.cos(a) * rr, y0 + 22 + Math.sin(a) * rr * 0.9]; }); f.poly(pts, mix(P.cols[0], '#fff2d0', 0.4), { sw: 0.9 }); }
  // the column or the spread
  if (kind === 'water') {
    const n = 7; for (let i = 0; i < n; i++) { const t0 = i / n, t1 = (i + 1) / n, w0 = W * (0.36 - 0.18 * t0) + (rnd() - 0.5) * 8, w1 = W * (0.36 - 0.18 * t1) + (rnd() - 0.5) * 8, y_0 = y0 + H * t0 * 0.85, y_1 = y0 + H * t1 * 0.85; f.poly([[x0 - w0, y_0], [x0 - w1, y_1], [x0, y_1 + 6], [x0, y_0]], cols[0], { sw: 0.9 }); f.poly([[x0, y_0], [x0, y_1 + 6], [x0 + w1, y_1], [x0 + w0, y_0]], cols[2], { sw: 0.9 }); }
    for (let q = 0; q < 5; q++) puff(f, [x0 + (q - 2) * W * 0.17, y0 + H * (0.86 + 0.06 * (q % 2))], W * 0.2, cols, rnd, 0.7);
    if (P.ring && frame > 0) { const rr = W * (frame === 1 ? 0.8 : 1.3); f.poly([[x0 - rr, y0 + 1], [x0 - rr * 0.6, y0 + 14], [x0 + rr * 0.6, y0 + 14], [x0 + rr, y0 + 1], [x0 + rr * 0.55, y0 + 7], [x0 - rr * 0.55, y0 + 7]], cols[0], { sw: 0.9 }); }
  } else if (kind === 'mud') {
    for (let i = 0; i < 9 * k + 3; i++) { const a = Math.PI * (0.12 + 0.76 * rnd()), v = H * (0.6 + rnd() * 0.5), tt = 0.5 + 0.5 * k, x = x0 + Math.cos(a) * v * tt * 0.9, y = y0 + 6 + Math.sin(a) * v * tt - 0.6 * v * tt * tt * (frame === 2 ? 0.5 : 0); chunk(f, x, y, 7 + rnd() * 11, [cols[1], cols[2], cols[0]][i % 3], rnd); }
    for (let i = 0; i < 4; i++) puff(f, [x0 + (i - 1.5) * W * 0.2, y0 + 16 + rnd() * 10], W * (0.14 + rnd() * 0.08), cols, rnd, 0.6);
  } else if (kind === 'rock') {
    for (let i = 0; i < 4; i++) puff(f, [x0 + (i - 1.5) * W * 0.18, y0 + H * (0.15 + 0.2 * i) * 0.6], W * (0.2 + 0.06 * i), cols.map(c => mix(c, sky, 0.18)), rnd, 0.9);
  } else {
    // dust, sand, dirt, snow, ash, leaf: a billowing column. Big overlapping puffs, a stem that widens into a bulb, a skirt along the ground; the high puffs are drawn first so the low ones sit in front.
    const n = kind === 'ash' ? 11 : 13, list = [];
    for (let i = 0; i < n; i++) {
      const t = i / (n - 1), bulb = kind === 'ash' ? (t > 0.72 ? 1.5 : 0.7) : 0.5 + 0.95 * Math.sin(Math.PI * Math.min(1, t * 0.9 + 0.06)) ** 1.5;
      list.push({ x: x0 + (rnd() - 0.5) * W * 0.22 * (1 - t * 0.3) + Math.sin(t * 5 + frame) * W * 0.05, y: y0 + 16 + H * t * 0.92, r: W * 0.15 * bulb * (0.85 + 0.3 * rnd()), t });
    }
    if (kind !== 'ash') for (let q = 0; q < 6; q++) { const t = 0.55 + 0.3 * rnd(), s = q % 2 ? 1 : -1; list.push({ x: x0 + s * W * (0.18 + 0.12 * rnd()), y: y0 + 16 + H * t * 0.92, r: W * (0.1 + 0.07 * rnd()), t }); }
    for (let q = 0; q < 6; q++) { const s = q % 2 ? 1 : -1; list.push({ x: x0 + s * W * (0.24 + 0.16 * (q >> 1)) * (frame === 2 ? 1.5 : 1), y: y0 + 12 + rnd() * 6, r: W * (0.13 - 0.02 * (q >> 1)), t: 0 }); }
    list.sort((p, q) => q.t - p.t).forEach(pf => puff(f, [pf.x, pf.y], pf.r, pf.t > 0.5 ? cols : cols.map(c => mix(c, sky, 0.08)), rnd, kind === 'ash' ? 0.92 : 0.8));
  }
  // ejecta: arcs by time
  const ej = P.ej, tt = frame === 0 ? 0.18 : frame === 1 ? 0.55 : 1.15, nE = frame === 0 ? 8 : 14;
  for (let i = 0; i < nE; i++) {
    const a = Math.PI * (0.1 + 0.8 * rnd()), v = (P.h * 1.4) * (0.4 + rnd() * 0.7), x = x0 + Math.cos(a) * v * tt * 0.8, y = Math.max(y0 + 2, y0 + 10 + Math.sin(a) * v * tt - 260 * tt * tt * (frame === 2 ? 1.3 : 1));
    const col = ej[i % ej.length], s = 5 + rnd() * 9;
    if (kind === 'leaf' || kind === 'water' || kind === 'snow') shard(f, x, y, s, rnd() * 6, col); else if (kind === 'rock' || kind === 'dirt' || kind === 'mud') chunk(f, x, y, s * 0.9, col, rnd); else shard(f, x, y, s * 0.7, rnd() * 6, col);
  }
  if (P.embers) for (let i = 0; i < 7; i++) { const x = x0 + (rnd() - 0.5) * W * 1.3, y = y0 + 30 + rnd() * H * 0.9, s = 3 + rnd() * 3; f.poly([[x - s, y - s], [x + s, y - s], [x + s, y + s], [x - s, y + s]], b.pal.acc, { sw: 0.6 }); }
  if (P.steam && frame > 0) for (let i = 0; i < 3; i++) puff(f, [x0 + W * (0.5 + 0.12 * i) * (i % 2 ? 1 : -1), y0 + 30 + i * 36 * k], 18 + i * 6, ['#e8eeee', '#c4d0d2', '#98a8ac'], rnd, 0.8);
  if (P.wet && frame === 2) { f.poly([[x0 - W * 0.6, y0 + 0.5], [x0 - W * 0.4, y0 + 7], [x0 + W * 0.4, y0 + 7], [x0 + W * 0.6, y0 + 0.5]], '#9a8658', { sw: 0.8 }); }
  // landed debris on settle
  if (frame === 2) for (let i = 0; i < 9; i++) { const x = x0 + (rnd() - 0.5) * W * 2.1, s = 3 + rnd() * 6; chunk(f, x, y0 + 2 + s * 0.4, s, [P.ej[0], P.cols[2], P.ej[P.ej.length - 1]][i % 3], rnd); }
}

// one frame as a panel: the biome's ground at the impact, a flat sky, a crater (grown by frame) and the plume
export function plumePanel(id, frame, px, py, S = 0.86) {
  const b = BIOMES[id];
  const R = frame === 0 ? 0 : frame === 1 ? 90 : 130;
  const s = scene({ id, px, py, S, ww: 560, wh: 420, wx0: 0, seed: 31, crater: R ? { x: 280, R } : null });
  const y0 = s.G + s.prof(280) - (R ? R * 0.26 * 0.7 : 0);
  drawPlume(s.f, id, frame, 280, y0, b.pal.sky[1]);
  const cid = 'pc' + id + frame + Math.round(px) + Math.round(py);
  return `<clipPath id="${cid}"><rect x="${px}" y="${py}" width="${(560 * S).toFixed(1)}" height="${(420 * S).toFixed(1)}"/></clipPath><g clip-path="url(#${cid})">${s.f.svg()}</g>`;
}
