// Origin: the planet-from-orbit colour study of the biome look bible: a faceted sphere coloured by the fifteen biomes, three views and a flat map (deterministic, seeded; no blur, no gradients).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-23. The terrain here is a stand-in (a smooth sum of waves, not World's planet function): the study is about COLOUR and the READ of the biomes from far away, not the shapes of the continents.
import { BIOMES } from './spec.mjs';
import { mix, lite, dark, rng } from './draw.mjs';
import { orbitHex } from './derive.mjs';

const F = n => (Math.round(n * 10) / 10).toString();
// a smooth field on the sphere: a sum of waves along random directions
function field(seed, n = 9) { const r = rng(seed), W = Array.from({ length: n }, () => { const v = [r() - 0.5, r() - 0.5, r() - 0.5], l = Math.hypot(...v) || 1, k = 1.6 + r() * 3.2; return { v: v.map(x => x / l * k), ph: r() * 6.28, a: 0.4 + r() * 0.6 }; }); const tot = W.reduce((s, w) => s + w.a, 0); return p => W.reduce((s, w) => s + w.a * Math.sin(w.v[0] * p[0] + w.v[1] * p[1] + w.v[2] * p[2] + w.ph), 0) / tot; }
const E = field(11, 14), M = field(23, 10), T = field(37, 6), V = field(53, 6);
const norm = a => { const l = Math.hypot(...a); return a.map(x => x / l); };
const hot = [norm([0.6, 0.2, 0.77]), norm([-0.8, 0.1, 0.55]), norm([0.1, -0.35, -0.93])];
const SEA = 0.02;   // elevation of the shore (about a third of the sphere is land)
export function biomeAt(p) {
  const e = E(p), lat = Math.asin(p[1]) * 180 / Math.PI, al = Math.abs(lat), m = (M(p) + 1) / 2, tn = T(p) * 0.08;
  const heat = Math.pow(Math.max(0, 1 - al / 82), 1.15) + tn - 0.28 * Math.max(0, e - SEA - 0.2);
  if (e < SEA) return al > 66 && heat < 0.28 ? 'sea_ice' : 'ocean';
  if (heat < 0.14) return 'ice_sheet';
  if (hot.some(h => p[0] * h[0] + p[1] * h[1] + p[2] * h[2] > 0.992) && e > SEA + 0.04) return 'volcanic';
  if (e > SEA + 0.34) return heat < 0.3 ? 'ice_sheet' : 'mountains';
  if (e > SEA + 0.24 && heat >= 0.3) return 'highland';
  if (heat < 0.3) return m < 0.46 ? 'tundra' : 'taiga';
  if (heat < 0.42 && m > 0.5) return 'taiga';
  if (e < SEA + 0.016 && heat > 0.32) return 'beach';
  if (e < SEA + 0.09 && m > 0.56 && heat > 0.36) return 'wetland';
  if (heat > 0.68) return m < 0.44 ? 'desert' : m < 0.53 ? 'savanna' : 'jungle';
  if (heat > 0.5) return m < 0.4 ? 'desert' : m < 0.48 ? 'savanna' : m < 0.55 ? 'plains' : 'forest';
  return m < 0.5 ? 'plains' : 'forest';
}
const ORBIT = Object.fromEntries(Object.keys(BIOMES).map(id => [id, orbitHex(id)]));
const GROUND = Object.fromEntries(Object.keys(BIOMES).map(id => [id, id === 'ocean' ? BIOMES[id].pal.w[1] : BIOMES[id].pal.g[1]]));
const rotY = (p, a) => [p[0] * Math.cos(a) + p[2] * Math.sin(a), p[1], -p[0] * Math.sin(a) + p[2] * Math.cos(a)];
const rotX = (p, a) => [p[0], p[1] * Math.cos(a) - p[2] * Math.sin(a), p[1] * Math.sin(a) + p[2] * Math.cos(a)];
const toWorld = (lat, lon) => [Math.cos(lat) * Math.sin(lon), Math.sin(lat), Math.cos(lat) * Math.cos(lon)];
// the planet disc in view space (x right, y up, z toward the viewer): returns the SVG
export function disc(cx, cy, R, { lon0 = 0, tilt = 0.3, sun = [-0.55, 0.35, 0.75], step = 4, stars = true, seed = 5 } = {}) {
  const L = norm(sun), r = rng(seed); let s = '';
  if (stars) for (let i = 0; i < 70; i++) { const x = cx + (r() - 0.5) * R * 3.2, y = cy + (r() - 0.5) * R * 3.0, q = 1 + r() * 1.8; if (Math.hypot(x - cx, y - cy) < R * 1.12) continue; s += `<polygon points="${F(x)},${F(y - q)} ${F(x + q)},${F(y)} ${F(x)},${F(y + q)} ${F(x - q)},${F(y)}" fill="#cfd8ea" opacity="${(0.4 + r() * 0.5).toFixed(2)}"/>`; }
  // the atmosphere: thin crisp arcs, hard steps (a bright rim on the lit side, a dim one elsewhere)
  for (let i = 0; i < 72; i++) { const a0 = i / 72 * 6.2832, a1 = (i + 1.05) / 72 * 6.2832, am = (a0 + a1) / 2, nl = Math.cos(am) * L[0] + Math.sin(am) * L[1]; const c = nl > 0.55 ? '#cfe8ff' : nl > 0.15 ? '#8fc0f0' : nl > -0.25 ? '#4f78b0' : '#2a3e66', w = nl > 0.55 ? 9 : nl > 0.15 ? 6 : 3.5; const P = (a, rr) => `${F(cx + Math.cos(a) * rr)},${F(cy - Math.sin(a) * rr)}`; s += `<polygon points="${P(a0, R)} ${P(a1, R)} ${P(a1, R + w)} ${P(a0, R + w)}" fill="${c}" stroke="${c}" stroke-width="0.6"/>`; }
  const quads = [], dl = step * Math.PI / 180;
  for (let la = -90; la < 90; la += step) for (let lo = 0; lo < 360; lo += step) {
    const lat0 = la * Math.PI / 180, lon0r = lo * Math.PI / 180, cs = toWorld(lat0 + dl / 2, lon0r + dl / 2);
    const rot = p => rotX(rotY(p, lon0 + 0), tilt), vc = rot(cs);
    if (vc[2] < -0.02) continue;
    const corners = [[0, 0], [dl, 0], [dl, dl], [0, dl]].map(([a, b]) => rot(toWorld(lat0 + a, lon0r + b)));
    quads.push({ z: vc[2], c: cs, v: vc, pts: corners.map(q => `${F(cx + q[0] * R)},${F(cy - q[1] * R)}`).join(' ') });
  }
  quads.sort((a, b) => a.z - b.z);
  for (const q of quads) {
    const id = biomeAt(q.c), base = ORBIT[id], d = q.v[0] * L[0] + q.v[1] * L[1] + q.v[2] * L[2];
    const col = d > 0.7 ? lite(base, 0.1) : d > 0.4 ? base : d > 0.12 ? dark(base, 0.22) : mix(dark(base, 0.62), '#10204a', 0.45);
    s += `<polygon points="${q.pts}" fill="${col}" stroke="${col}" stroke-width="0.6"/>`;
  }
  s += `<circle cx="${F(cx)}" cy="${F(cy)}" r="${F(R)}" fill="none" stroke="#0a0d14" stroke-width="1.2"/>`;
  return s;
}
export function orbitSheet() {
  const W = 1800, ids = Object.keys(BIOMES); let s = '';
  const text = (x, y, t, { size = 12, weight = 400, fill = '#1b1428', anchor = 'start', op = 1 } = {}) => `<text x="${F(x)}" y="${F(y)}" font-family="'Segoe UI', system-ui, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${op}">${t.replace(/&/g, '&amp;')}</text>`;
  s += `<rect x="0" y="0" width="${W}" height="104" fill="#1b1428"/>` + text(30, 46, 'The planet from orbit: a colour study', { size: 30, weight: 700, fill: '#f4f0fa' }) + text(30, 72, 'Three views of a stand-in planet coloured by the fifteen biomes (the terrain is a smooth stand-in, not World\'s planet function: this study is about colour and read, not continents). Hard steps in light, a thin crisp atmosphere rim, no blur and no fade.', { size: 12, fill: '#cfc6e6' }) + text(30, 90, 'From orbit every biome is its ground colour mixed 14 to 16 percent toward the atmosphere blue, and a land biome is a blend of its ground and its vegetation by how much of it is green; ice and sea ice are warm-white, the sea its deep blue.', { size: 12, fill: '#cfc6e6' });
  const y0 = 124, views = [['Day side', { lon0: -0.4, tilt: 0.28, sun: [-0.55, 0.35, 0.75] }], ['The pole', { lon0: 0.6, tilt: 1.15, sun: [-0.4, 0.75, 0.5] }], ['The terminator', { lon0: 2.2, tilt: 0.15, sun: [0.95, 0.12, 0.28] }]];
  views.forEach(([name, o], i) => { const x = 24 + i * 592; s += `<rect x="${x}" y="${y0}" width="580" height="560" fill="#05070f" stroke="#1b1428" stroke-opacity="0.4"/>` + disc(x + 290, y0 + 285, 205, { ...o, seed: 5 + i }) + text(x + 12, y0 + 26, name, { size: 15, weight: 700, fill: '#e6ecf8' }); });
  // the flat map
  const my = y0 + 590; s += text(24, my + 4, 'The same planet flattened (each cell is 4 degrees), with each biome\'s ground colour', { size: 14, weight: 700 });
  const cw = 8, ch = 8; for (let la = -90; la < 90; la += 4) for (let lo = 0; lo < 360; lo += 4) { const id = biomeAt(toWorld((la + 2) * Math.PI / 180, (lo + 2) * Math.PI / 180)); s += `<rect x="${24 + lo * 2}" y="${my + 14 + (88 - la) * 2 - 8}" width="8.2" height="8.2" fill="${ORBIT[id]}"/>`; }
  // legend: ground and orbit colour pairs
  const lx = 24 + 720 + 40; ids.forEach((id, i) => { const x = lx + (i % 3) * 330, y = my + 20 + Math.floor(i / 3) * 52; s += `<rect x="${x}" y="${y}" width="34" height="26" fill="${GROUND[id]}" stroke="#1b1428" stroke-opacity="0.4"/><rect x="${x + 34}" y="${y}" width="34" height="26" fill="${ORBIT[id]}" stroke="#1b1428" stroke-opacity="0.4"/>` + text(x + 76, y + 12, BIOMES[id].name, { size: 12, weight: 700 }) + text(x + 76, y + 25, `ground ${GROUND[id]}, orbit ${ORBIT[id]}`, { size: 9.5, op: 0.7 }); });
  s += text(24, my + 14 + 180 * 2 * 0.95 + 20, 'Legend pairs: the left swatch is the biome seen from the ground, the right from orbit.', { size: 11, op: 0.7 });
  const H = my + 14 + 180 * 2 * 0.95 + 44;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${Math.round(H)}" viewBox="0 0 ${W} ${Math.round(H)}"><rect width="${W}" height="${Math.round(H)}" fill="#dcd8e6"/>${s}</svg>`;
}
