// Origin: shared drawing helpers for the sky and colour-vision sheets (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-06. Human direction: Orb, via the EP.

import { drawFigure, POSE0, PAL } from '../refine/figures.mjs';
import { hero, rival } from '../refine/approved.mjs';
import { svgMatrix } from './colour.mjs';

export const F = n => Number(n).toFixed(2);
const esc = t => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const FONT = "font-family=\"'Segoe UI', system-ui, -apple-system, Helvetica, Arial, sans-serif\"";
export const text = (x, y, t, { size = 14, weight = 400, fill = '#1b1428', anchor = 'start', op = 1 } = {}) => `<text x="${F(x)}" y="${F(y)}" ${FONT} font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${op}">${esc(t)}</text>`;
export const rect = (x, y, w, h, fill, extra = '') => `<rect x="${F(x)}" y="${F(y)}" width="${F(w)}" height="${F(h)}" fill="${fill}" ${extra}/>`;
export const wrap = (t, n) => { const w = t.split(' '), out = []; let line = ''; for (const x of w) { if ((line + ' ' + x).trim().length > n) { out.push(line.trim()); line = x; } else line += ' ' + x; } if (line.trim()) out.push(line.trim()); return out; };
export const paras = (x, y, t, n, size = 12, gap = 15, o = {}) => wrap(t, n).map((l, i) => text(x, y + i * gap, l, { size, ...o })).join('');
export const header = (title, sub, W) => rect(0, 0, W, 104, '#1b1428') + text(30, 46, title, { size: 30, weight: 700, fill: '#f4f0fa' }) + paras(30, 72, sub, 210, 14, 18, { fill: '#cfc6e6' });
export const BG = '#e8e5ee';

// the colour-vision filters (Machado et al. 2009, severity 1.0, in linear RGB), for the simulated panels
export const SIM_DEFS = ['protan', 'deutan', 'tritan'].map(k => `<filter id="sim-${k}" color-interpolation-filters="linearRGB"><feColorMatrix type="matrix" values="${svgMatrix(k)}"/></filter>`).join('');

let gid = 0;
// the game's sky: four bands, anchored to the horizon (look.gd: lower at 0.12, upper at 0.55, top at 1.45 half-screens above it), as a vertical gradient over the sky's height
export function skyPanel(x, y, w, h, bands, o = {}) {
  const id = `sk${gid++}`, hy = y + h * (o.horizonAt ?? 0.64), sh = hy - y, st = [[0, bands.top], [1 - 0.55 / 1.45, bands.upper], [1 - 0.12 / 1.45, bands.lower], [1, bands.horizon]];
  let b = `<defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1">${st.map(([o_, c]) => `<stop offset="${F(o_)}" stop-color="${c}"/>`).join('')}</linearGradient><clipPath id="c${id}"><rect x="${F(x)}" y="${F(y)}" width="${w}" height="${h}"/></clipPath></defs>`;
  b += `<g clip-path="url(#c${id})">` + rect(x, y, w, sh, `url(#${id})`, 'shape-rendering="crispEdges"');
  if (o.plain) return b + '</g>';
  if (o.stars) for (let i = 0; i < 46; i++) { const sx = x + ((i * 97) % 211) / 211 * w, sy = y + ((i * 53) % 97) / 97 * sh * 0.8; b += `<circle cx="${F(sx)}" cy="${F(sy)}" r="${i % 5 === 0 ? 1.3 : 0.8}" fill="#e9eefc" opacity="${F(0.7 * o.stars)}"/>`; }
  // a burning town: an ember glow on the horizon, wide and low
  if (o.glow) b += `<defs><radialGradient id="g${id}" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#d9603c" stop-opacity="${F(0.75 * o.glow)}"/><stop offset="1" stop-color="#d9603c" stop-opacity="0"/></radialGradient></defs>` + `<ellipse cx="${F(x + w * (o.glowAt ?? 0.5))}" cy="${F(hy)}" rx="${F(w * 0.3)}" ry="${F(sh * 0.5)}" fill="url(#g${id})"/>`;
  // the ground: a dark band with a skyline
  b += rect(x, hy, w, h - sh, o.ground ?? '#262a35');
  for (let i = 0; i < 12; i++) { const bx = x + i * w / 12 + 4, bh = 8 + ((i * 37) % 23); b += rect(bx, hy - bh, w / 12 - 6, bh, o.skyline ?? '#20232d'); }
  return b + '</g>';
}
// a fighter with the aura as a thin ring and a dark keyline outside it (an assumption about how the aura reads; Rendering's own aura is the truth)
export function auraFigure(kind, x, ground, s, aura, flip = false) {
  const id = `au${gid++}`, concept = kind === 'P' ? hero({ yaw: 0 }) : rival({ yaw: 0 }, 'clear'), pal = kind === 'P' ? PAL.P : PAL.A, pose = POSE0(kind);
  const flat = drawFigure({ concept, pal, pose, flat: true, bg: BG, x, ground, s }), col = drawFigure({ concept, pal, pose, flat: false, bg: BG, x, ground, s });
  const defs = `<defs><filter id="${id}k" x="-30%" y="-30%" width="160%" height="160%"><feMorphology in="SourceAlpha" operator="dilate" radius="${F(0.045 * 100 * s / 1.5 + 1.2)}" result="d"/><feFlood flood-color="#0a0d14"/><feComposite in2="d" operator="in"/></filter>` +
    `<filter id="${id}a" x="-30%" y="-30%" width="160%" height="160%"><feMorphology in="SourceAlpha" operator="dilate" radius="${F(0.04 * 100 * s / 1.5 + 0.6)}" result="d"/><feFlood flood-color="${aura}"/><feComposite in2="d" operator="in"/></filter></defs>`;
  const g = `${defs}<g filter="url(#${id}k)">${flat}</g><g filter="url(#${id}a)">${flat}</g>${col}`;
  return flip ? `<g transform="translate(${F(2 * x)} 0) scale(-1 1)">${g}</g>` : g;
}
// a still: the sky, the two fighters facing each other, each in the aura colour given
export function still(x, y, w, h, bands, aurP, aurA, o = {}) {
  const hy = y + h * 0.64, g = hy + h * 0.2, s = h / 190;
  return skyPanel(x, y, w, h, bands, o) + auraFigure('P', x + w * 0.34, g, s, aurP) + auraFigure('A', x + w * 0.68, g, s, aurA, true);
}
export const WRAP = inner => inner;

// ---------------------------------------------------------------------------------------------------------- the world's light, for the scenes
// a multiply-and-add tint as an SVG filter: colour = colour times mul, plus add, in linear light (the filter says so)
export function tintFilter(id, mul, add = [0, 0, 0]) {
  return `<filter id="${id}" x="-5%" y="-5%" width="110%" height="110%" color-interpolation-filters="linearRGB"><feColorMatrix type="matrix" values="${mul[0]} 0 0 0 ${add[0]}  0 ${mul[1]} 0 0 ${add[1]}  0 0 ${mul[2]} 0 ${add[2]}  0 0 0 1 0"/></filter>`;
}
let tid = 0;
const tintG = (inner, t) => { if (!t) return `<g>${inner}</g>`; const id = `tn${tid++}`; return `<defs>${tintFilter(id, t.mul, t.add)}</defs><g filter="url(#${id})">${inner}</g>`; };
const hash = n => { const v = Math.sin(n * 12.9898) * 43758.5453; return v - Math.floor(v); };
// a fighter whose body takes the body tint while the aura and its keyline do not
export function auraFigureT(kind, x, ground, s, aura, flip, bodyT) {
  const id = `at${gid++}`, concept = kind === 'P' ? hero({ yaw: 0 }) : rival({ yaw: 0 }, 'clear'), pal = kind === 'P' ? PAL.P : PAL.A, pose = POSE0(kind);
  const flat = drawFigure({ concept, pal, pose, flat: true, bg: BG, x, ground, s }), col = drawFigure({ concept, pal, pose, flat: false, bg: BG, x, ground, s });
  const defs = `<defs><filter id="${id}k" x="-30%" y="-30%" width="160%" height="160%"><feMorphology in="SourceAlpha" operator="dilate" radius="${F(0.045 * 100 * s / 1.5 + 1.2)}" result="d"/><feFlood flood-color="#0a0d14"/><feComposite in2="d" operator="in"/></filter>` +
    `<filter id="${id}a" x="-30%" y="-30%" width="160%" height="160%"><feMorphology in="SourceAlpha" operator="dilate" radius="${F(0.04 * 100 * s / 1.5 + 0.6)}" result="d"/><feFlood flood-color="${aura}"/><feComposite in2="d" operator="in"/></filter></defs>`;
  const g = `${defs}<g filter="url(#${id}k)">${flat}</g><g filter="url(#${id}a)">${flat}</g>${tintG(col, bodyT)}`;
  return flip ? `<g transform="translate(${F(2 * x)} 0) scale(-1 1)">${g}</g>` : g;
}
// a scene: the sky, a skyline of towers and houses with windows, trees, sand and a lake, and the two fighters. T is { ground, buildings, trees, water, bodies } tints
// ({ mul, add } in linear light) or null for the world as it is today; lit is the share of windows lit; glass the window glass colour; glow draws a town's glow behind the skyline.
export function worldScene(x, y, w, h, bands, o = {}) {
  const T = o.T ?? {}, hy = y + h * 0.56, id = `ws${gid++}`;
  let b = `<defs><clipPath id="${id}"><rect x="${F(x)}" y="${F(y)}" width="${w}" height="${h}"/></clipPath></defs><g clip-path="url(#${id})">`;
  b += skyPanel(x, y, w, h, bands, { plain: true, horizonAt: 0.56 });
  if (o.stars) for (let i = 0; i < 40; i++) b += `<circle cx="${F(x + hash(i + 1) * w)}" cy="${F(y + hash(i + 50) * (hy - y) * 0.8)}" r="${i % 5 === 0 ? 1.2 : 0.7}" fill="#e9eefc" opacity="${F(0.7 * o.stars)}"/>`;
  if (o.glow) b += `<defs><radialGradient id="${id}g" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#d9603c" stop-opacity="${F(0.7 * o.glow)}"/><stop offset="1" stop-color="#d9603c" stop-opacity="0"/></radialGradient></defs><ellipse cx="${F(x + w * 0.62)}" cy="${F(hy)}" rx="${F(w * 0.2)}" ry="${F(h * 0.28)}" fill="url(#${id}g)"/>`;
  // buildings: towers and houses along the horizon (a tint group), windows after (not dimmed)
  let bl = '', win = '';
  const bx = [[0.30, 0.34, 0.06, 'tower'], [0.37, 0.24, 0.05, 'tower'], [0.46, 0.1, 0.06, 'house'], [0.54, 0.31, 0.055, 'tower'], [0.62, 0.11, 0.06, 'house'], [0.70, 0.2, 0.05, 'tower'], [0.77, 0.1, 0.06, 'house'], [0.85, 0.27, 0.06, 'tower'], [0.93, 0.1, 0.06, 'house']];
  bx.forEach(([fx, fh, fw, kind], i) => {
    const px = x + fx * w, pw = fw * w, ph = fh * h, py = hy - ph;
    bl += rect(px, py, pw, ph, kind === 'tower' ? '#565e70' : '#a67c52', 'stroke="#0a0d14" stroke-width="1"');
    if (kind === 'house') bl += `<polygon points="${F(px - 2)},${F(py)} ${F(px + pw / 2)},${F(py - ph * 0.5)} ${F(px + pw + 2)},${F(py)}" fill="#7a3b2e" stroke="#0a0d14" stroke-width="1"/>`;
    const cols = Math.max(2, Math.floor(pw / 7)), rows = Math.max(1, Math.floor(ph / 9));
    for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) { const lit = hash(i * 31 + r * 7 + c * 3 + 1) < (o.lit ?? 0.3); win += rect(px + 3 + c * (pw - 6) / cols, py + 4 + r * 9, Math.max(2, (pw - 6) / cols - 2), 5, lit ? '#f3cf86' : (o.glass ?? '#2c3550')); }
  });
  b += tintG(bl, T.buildings) + win;
  // trees (a tint group)
  let tr = ''; for (let i = 0; i < 9; i++) { const tx = x + (0.05 + i * 0.033) * w; tr += `<ellipse cx="${F(tx)}" cy="${F(hy - 6)}" rx="6" ry="9" fill="${i % 2 ? '#2f6b35' : '#1f4a26'}" stroke="#0a0d14" stroke-width="0.8"/>`; }
  b += tintG(tr, T.trees);
  // sand, and a lake in the lower left (a tint group each)
  b += tintG(rect(x, hy, w, y + h - hy, '#cfa85c') + `<polygon points="${F(x + w * 0.0)},${F(hy + 14)} ${F(x + w * 0.26)},${F(hy + 14)} ${F(x + w * 0.2)},${F(y + h)} ${F(x)},${F(y + h)}" fill="#a98544" opacity="0.5"/>`, T.ground);
  b += tintG(`<ellipse cx="${F(x + w * 0.12)}" cy="${F(hy + 26)}" rx="${F(w * 0.12)}" ry="9" fill="#1e6eaf" stroke="#0a0d14" stroke-width="0.8"/>`, T.water);
  // the fighters: the auras and keylines are never dimmed, the bodies take the body tint
  const g = y + h * 0.9, s = h / 150;
  b += auraFigureT('P', x + w * 0.2, g, s, '#8fd6ff', false, T.bodies) + auraFigureT('A', x + w * 0.4, g, s, '#9a80d8', true, T.bodies);
  return b + '</g>';
}
