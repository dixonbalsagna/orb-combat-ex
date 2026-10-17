// Origin: the polar cold palette for World's ice (docs/world/planet-ice.md), as data and one sheet (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-17. Human direction: Orb, via the EP (homework 5: icecaps on both poles, a big icy landmass south, broken icebergs, floes, sea ice north).
// Run from the repo root:  node art/concepts/world/polar.mjs   -> data/art/polar.json, art/concepts/world/polar-palette.svg
// The finding that shapes it: a pale aura on a pale ground is the worst case in the game (the Protagonist's cyan on blue-white ice), and a MID tone between the white and the dark is the worst of all (every mid
// blue-grey measured 12 to 16 from an aura, under the rule's 20). So ice is two tones, lit and dark, with no mid blue-grey: a warm white and a cold slate, and the dark water.
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { WORLD, tinted, dE00 } from '../sky/world.mjs';
import { KEYS, skyAt } from '../sky/keys.mjs';
import { fromOklab } from '../sky/colour.mjs';
import { drawFigure } from '../refine/figures.mjs';
import { hero, rival } from '../refine/approved.mjs';
import { PAL } from '../shared/marks.mjs';
import { FIGHTERS } from '../directions/fighters.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const F = n => n.toFixed(2);
const oklch = (h, C, L) => { const r = h * Math.PI / 180; return fromOklab([L, C * Math.cos(r), C * Math.sin(r)]); };
const LANES = { protagonist: '#8fd6ff', rival: '#9a80d8', empress: '#3c7d1c', cyborg: '#47d7a7' }, BODY = { protagonist: '#3d8fdc', rival: '#a52a2a' };

// the palette: a tone is a hex; "role" says where Rendering uses it
const SLATE = oklch(245, 0.03, 0.45);
export const POLAR = {
  ice_sheet: { lit: '#ebe8e2', dark: SLATE, rock: '#7e766a', note: 'the south: land under a warm white; slopes that face the light are lit, slopes that face away and crevasses are the slate; rock peaks through in the mountains\' tone' },
  sea_ice: { floe_top: '#e3e4e0', floe_edge: SLATE, melt_rim: '#5f8aa2', note: 'the north: floes with a warm-white top and a slate edge, a thin rim of meltwater blue where the floe meets the sea' },
  iceberg: { face_lit: '#e6e6e0', face_dark: SLATE, under_water: '#3a7893', note: 'a berg is a lit face and a slate face; the part under the waterline, seen through the water, is the only blue' },
  polar_water: { deep: '#1b3f57', shallow: '#2f6a84', note: 'dark and cold, darker than the temperate sea (the sea owns mid blue): the gaps between floes are the darkest thing in the picture' },
  haze: 'distant ice fades to the sky\'s own horizon colour, as everywhere; no polar sky key is needed, the cold comes from the ground',
};
const TONES = { 'sheet lit': POLAR.ice_sheet.lit, 'slate (dark side)': SLATE, 'floe top': POLAR.sea_ice.floe_top, 'berg lit face': POLAR.iceberg.face_lit };
function measure(hex) {
  let a = [99, '', ''], b = [99, '', ''];
  for (const k of KEYS) { const g = tinted(hex, WORLD[k.id].ground); for (const [n, c] of Object.entries(LANES)) { const d = dE00(c, g); if (d < a[0]) a = [d, n, k.id]; } for (const [n, c] of Object.entries(BODY)) { const d = dE00(tinted(c, WORLD[k.id].bodies), g); if (d < b[0]) b = [d, n, k.id]; } }
  return { aura_vs_ground_worst: +a[0].toFixed(1), aura: a[1], aura_at: a[2], body_vs_ground_worst: +b[0].toFixed(1), body: b[1], body_at: b[2] };
}
const measured = Object.fromEntries(Object.entries(TONES).map(([n, h]) => [n, { hex: h, ...measure(h) }]));
writeFileSync(join(ROOT, 'data', 'art', 'polar.json'), JSON.stringify({ version: 1, note: 'The polar cold palette for World\'s ice biomes (docs/art/polar-palette.md). Written by art/concepts/world/polar.mjs; do not edit by hand. Ice is two tones, lit and dark, with no mid blue-grey: a mid tone was 12 to 16 from the fighters\' auras, under the rule\'s 20. Proposals pending Legal; Tools adds the schema.', biomes: { ice_sheet: POLAR.ice_sheet, sea_ice: POLAR.sea_ice, iceberg: POLAR.iceberg, polar_water: POLAR.polar_water }, haze: POLAR.haze, measured_over_every_key: measured, rule: 'aura against ground 20 or more, body against ground 15 or more (docs/art/dynamic-sky.md section 6), with the world-light ground tint of each key applied' }, null, 2) + '\n');

// ---- the sheet: for each key, a sky, a polar ground (a slate slope, a snow plain, floes in dark water) and the two fighters with their auras
const text = (x, y, t, { size = 12, weight = 400, fill = '#1b1428', anchor = 'start', op = 1 } = {}) => `<text x="${F(x)}" y="${F(y)}" font-family="'Segoe UI', system-ui, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${op}">${String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;')}</text>`;
const rect = (x, y, w, h, fill, extra = '') => `<rect x="${F(x)}" y="${F(y)}" width="${F(w)}" height="${F(h)}" fill="${fill}" ${extra}/>`;
function scene(x0, y0, W, H, keyId, phase) {
  const bands = skyAt(phase).bands, T = WORLD[keyId], g = h => tinted(h, T.ground), w = h => tinted(h, T.water);
  let s = `<defs><linearGradient id="sk${keyId}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${bands.top}"/><stop offset="0.45" stop-color="${bands.upper}"/><stop offset="0.8" stop-color="${bands.lower}"/><stop offset="1" stop-color="${bands.horizon}"/></linearGradient><clipPath id="cp${keyId}"><rect x="${x0}" y="${y0}" width="${W}" height="${H}"/></clipPath></defs><g clip-path="url(#cp${keyId})">`;
  const hy = y0 + H * 0.42;
  s += rect(x0, y0, W, hy - y0, `url(#sk${keyId})`);
  // far ice, hazed to the horizon colour
  s += `<polygon points="${x0},${hy} ${x0 + W * 0.18},${hy - 16} ${x0 + W * 0.34},${hy - 5} ${x0 + W * 0.52},${hy - 22} ${x0 + W * 0.7},${hy - 8} ${x0 + W * 0.86},${hy - 18} ${x0 + W},${hy - 4} ${x0 + W},${hy + 8} ${x0},${hy + 8}" fill="${bands.horizon}" opacity="0.9"/>`;
  s += rect(x0, hy, W, H - (hy - y0), w(POLAR.polar_water.deep));
  s += rect(x0, hy + 16, W, 10, w(POLAR.polar_water.shallow), 'opacity="0.6"');
  // floes: a lit top over a slate edge
  [[0.04, 0.2, 0.62], [0.3, 0.26, 0.7], [0.62, 0.34, 0.66]].forEach(([fx, fw, fy], i) => { const fx0 = x0 + W * fx, fy0 = y0 + H * fy, ww = W * fw; s += rect(fx0, fy0, ww, 10, g(POLAR.sea_ice.floe_top)) + rect(fx0, fy0 + 10, ww, 10, g(POLAR.sea_ice.floe_edge)) + rect(fx0, fy0 + 20, ww, 2.4, w(POLAR.sea_ice.melt_rim)); });
  // the near plain: a lit slope with a slate crevasse side
  const py = y0 + H * 0.74;
  s += `<polygon points="${x0},${py} ${x0 + W},${py - 14} ${x0 + W},${y0 + H} ${x0},${y0 + H}" fill="${g(POLAR.ice_sheet.lit)}"/><polygon points="${x0 + W * 0.58},${py - 8} ${x0 + W},${py - 14} ${x0 + W},${y0 + H} ${x0 + W * 0.7},${y0 + H}" fill="${g(POLAR.ice_sheet.dark)}"/>`;
  s += '</g>';
  return { s, py, g: g(POLAR.ice_sheet.lit) };
}
function sheet() {
  const W = 1800, SW = 586, SH = 300; let b = '';
  const keys = [['noon', 0.0], ['sunset', 0.32], ['night', 0.58], ['golden', 0.18], ['dawn', 0.84]];
  const H = 118 + 2 * (SH + 70) + 250;
  b += rect(0, 0, W, H, '#dcd8e6') + rect(0, 0, W, 104, '#1b1428') + text(30, 46, 'The polar cold palette: two tones of ice, dark water', { size: 30, weight: 700, fill: '#f4f0fa' });
  b += text(30, 74, 'A pale aura on a pale ground is the game\'s worst case, and every mid blue-grey measured 12 to 16 from an aura (rule: 20). So ice is a warm white and a cold slate with nothing in between. Concept art, working labels, pending Legal.', { size: 13, fill: '#cfc6e6' });
  keys.forEach(([k, ph], i) => {
    const x0 = 24 + (i % 3) * (SW + 8), y0 = 118 + Math.floor(i / 3) * (SH + 70);
    b += text(x0, y0 - 6, `${k} (the sky at place ${ph})`, { size: 13, weight: 700 });
    const sc = scene(x0, y0, SW, SH, k, ph); b += sc.s;
    const hp = hero({ yaw: 0 }), rv = rival({ yaw: 0 }, 'clear');
    const place = (c, pal, pose, x, aura) => { b += `<g opacity="1">${drawFigure({ concept: c, pal, pose, flat: true, bg: '#fff', x, ground: y0 + SH * 0.84, s: 1.3 }).replace(/#000/g, aura)}</g>`; };
    // the aura: the figure's flat shape in the lane colour, a little larger, behind the coloured figure
    const aura = (c, pal, pose, x, col) => `<g transform="translate(${F(x)} ${F(y0 + SH * 0.84)}) scale(1.36 -1.36)" style="filter:drop-shadow(0 0 0.8px ${col})"></g>`;
    b += drawFigure({ concept: hp, pal: PAL.P, pose: FIGHTERS.P.poses.base, x: x0 + SW * 0.32, ground: y0 + SH * 0.84, s: 1.3 }) + drawFigure({ concept: rv, pal: PAL.A, pose: FIGHTERS.A.poses.base, x: x0 + SW * 0.5, ground: y0 + SH * 0.84, s: 1.3 });
    b += `<circle cx="${F(x0 + SW * 0.32 + 6)}" cy="${F(y0 + SH * 0.84 - 52)}" r="62" fill="none" stroke="#0a0d14" stroke-width="4.4" opacity="0.9"/><circle cx="${F(x0 + SW * 0.32 + 6)}" cy="${F(y0 + SH * 0.84 - 52)}" r="62" fill="none" stroke="${LANES.protagonist}" stroke-width="2.4"/>`;
    b += `<circle cx="${F(x0 + SW * 0.5 + 4)}" cy="${F(y0 + SH * 0.84 - 48)}" r="58" fill="none" stroke="#0a0d14" stroke-width="4.4" opacity="0.9"/><circle cx="${F(x0 + SW * 0.5 + 4)}" cy="${F(y0 + SH * 0.84 - 48)}" r="58" fill="none" stroke="${LANES.rival}" stroke-width="2.4"/>`;
  });
  // the swatches and numbers
  const sy = 118 + 2 * (SH + 70) - 20, t0 = 24 + 2 * (SW + 8);
  const sw = (x, y, c, lab) => rect(x, y, 60, 40, c, 'stroke="#1b1428" stroke-opacity="0.4"') + text(x + 30, y + 54, lab, { size: 10.5, anchor: 'middle' }) + text(x + 30, y + 67, c, { size: 10, anchor: 'middle', op: 0.6 });
  b += text(24, sy - 6, 'The palette', { size: 16, weight: 700 });
  [['sheet lit', POLAR.ice_sheet.lit], ['slate', POLAR.ice_sheet.dark], ['floe top', POLAR.sea_ice.floe_top], ['melt rim', POLAR.sea_ice.melt_rim], ['berg lit', POLAR.iceberg.face_lit], ['berg under water', POLAR.iceberg.under_water], ['water deep', POLAR.polar_water.deep], ['water shallow', POLAR.polar_water.shallow], ['rock', POLAR.ice_sheet.rock]].forEach(([l, c], i) => { b += sw(24 + i * 76, sy + 10, c, l); });
  b += text(24, sy + 112, 'Measured over every key with the world-light ground tint (worst case, the lane or body that sits closest):', { size: 12, weight: 700 });
  Object.entries(measured).forEach(([n, m], i) => { b += text(24, sy + 132 + i * 18, `${n} ${m.hex}: the nearest aura ${m.aura_vs_ground_worst} (${m.aura}, ${m.aura_at}; rule 20); the nearest body ${m.body_vs_ground_worst} (${m.body}, ${m.body_at}; rule 15)`, { size: 11.5 }); });
  writeFileSync(join(ROOT, 'art', 'concepts', 'world', 'polar-palette.svg'), `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">${b}</svg>`);
  return H;
}
console.log('wrote data/art/polar.json and polar-palette.svg, height', sheet(), JSON.stringify(Object.fromEntries(Object.entries(measured).map(([n, m]) => [n, [m.aura_vs_ground_worst, m.body_vs_ground_worst]]))));
