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
  if (o.glow) b += `<defs><radialGradient id="g${id}" cx="0.5" cy="1" r="0.5"><stop offset="0" stop-color="#d9603c" stop-opacity="${F(0.75 * o.glow)}"/><stop offset="1" stop-color="#d9603c" stop-opacity="0"/></radialGradient></defs>` + `<ellipse cx="${F(x + w * (o.glowAt ?? 0.5))}" cy="${F(hy)}" rx="${F(w * 0.3)}" ry="${F(sh * 0.5)}" fill="url(#g${id})"/>`;
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
