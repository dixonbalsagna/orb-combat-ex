// Origin: the city's cars: four silhouettes (sedan, van, bus, bike) and a wreck state, as concept art and data (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-18. Human direction: Orb, via the EP (cars as scenery and as something a fighter can throw).
// Run from the repo root:  node art/concepts/city/cars.mjs   -> data/art/vehicles.json, art/concepts/city/cars.svg
// Faceted like the rest: prisms and chamfers, the wheels octagons. The paints are the city tints' own walls (data/art/city-looks.json: low chroma, off the fighters' lane hues, no orange or yellow
// (fire's), no mid blue (the sea's), no blood red); the glass is the tint's dark glass. Side-on, facing right, the ground at y = 0, sizes in world units (a fighter is 75). City art: it may be public.
import { writeFileSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { dE00 } from '../sky/colour.mjs';
import { drawFigure } from '../refine/figures.mjs';
import { hero } from '../refine/approved.mjs';
import { PAL } from '../shared/marks.mjs';
import { FIGHTERS } from '../directions/fighters.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const CITY = JSON.parse(readFileSync(join(ROOT, 'data', 'art', 'city-looks.json'), 'utf8'));
const F = n => n.toFixed(1);
const LIT = '#f3cf86', TYRE = '#26262a', HUB = '#8d96a1', SOOT = '#2f2a2a';
const poly = (pts, fill, extra = '') => `<polygon points="${pts.map(([x, y]) => `${F(x)},${F(y)}`).join(' ')}" fill="${fill}" stroke="#0a0d14" stroke-width="1" stroke-opacity="0.55" ${extra}/>`;
const rect = (x, y, w, h, fill, extra = '') => poly([[x, y], [x + w, y], [x + w, y + h], [x, y + h]], fill, extra);
const oct = (cx, cy, r, fill) => poly(Array.from({ length: 8 }, (_, i) => [cx + Math.cos((i + 0.5) / 8 * Math.PI * 2) * r, cy + Math.sin((i + 0.5) / 8 * Math.PI * 2) * r]), fill);
const wheel = (cx, r, o = {}) => `<g transform="translate(${F(cx)} ${F(-r + (o.up ?? 0))}) rotate(${o.rot ?? 0})">${oct(0, 0, r, TYRE)}${oct(0, 0, r * 0.5, HUB)}</g>`;
const tilt = (g, deg, cx, cy) => `<g transform="rotate(${deg} ${F(cx)} ${F(cy)})">${g}</g>`;
const shade = (c, k) => { const n = parseInt(c.slice(1), 16), f = v => Math.max(0, Math.min(255, Math.round(v * k))); return '#' + [(n >> 16) & 255, (n >> 8) & 255, n & 255].map(f).map(v => v.toString(16).padStart(2, '0')).join(''); };

// ---- the four vehicles: p = {body, dark, glass}; w = 0 whole, 1 wrecked
export const VEHICLES = {
  sedan: { name: 'Sedan', length: 193, height: 62, wheel_r: 14, mass_class: 3, throw_tier: 1, hit_box: [193, 62], draw(p, w) {
    const top = w ? -46 : -62, ride = w ? 6 : 0;
    let s = poly([[0, -12], [193, -12], [193, -30], [176, -38], [142, -38], [118, top], [64, top], [34, -38], [8, -38], [0, -30]], p.body);   // body and cabin in one outline
    s += poly([[0, -12], [193, -12], [193, -20], [0, -20]], shade(p.body, 0.78));
    s += w ? poly([[42, -38], [66, top + 2], [112, top + 2], [136, -38]], SOOT, 'opacity="0.75"') : poly([[42, -38], [68, top + 4], [114, top + 4], [138, -38]], p.glass) + rect(88, top + 4, 3, -top - 42, p.body);
    s += rect(186, -30, 7, 6, w ? SOOT : LIT) + rect(0, -28, 6, 5, SOOT);
    s += wheel(40, 14) + (w ? wheel(153, 14, { up: 9, rot: 14 }) : wheel(153, 14));
    if (w) s += poly([[150, -38], [176, -38], [193, -30], [180, -26], [150, -30]], SOOT, 'opacity="0.55"') + poly([[0, -12], [193, -12], [193, -17], [0, -17]], SOOT, 'opacity="0.5"');
    return w ? tilt(s, -7, 193, -12) : s;
  } },
  van: { name: 'Van', length: 223, height: 86, wheel_r: 17, mass_class: 4, throw_tier: 1, hit_box: [223, 86], draw(p, w) {
    const top = w ? -66 : -86;
    let s = poly([[0, -14], [223, -14], [223, -44], [200, -60], [176, top], [0, top]], p.body);
    s += poly([[0, -14], [223, -14], [223, -22], [0, -22]], shade(p.body, 0.78));
    s += w ? poly([[182, -56], [198, -56], [214, -44], [182, -44]], SOOT, 'opacity="0.75"') : poly([[180, top + 6], [196, -58], [214, -46], [180, -46]], p.glass);
    s += w ? '' : rect(120, top + 12, 40, 18, p.glass) + rect(70, top + 12, 40, 18, p.glass);
    s += rect(216, -36, 7, 6, w ? SOOT : LIT) + rect(0, -38, 6, 5, SOOT);
    s += wheel(48, 17) + (w ? wheel(178, 17, { up: 10, rot: 20 }) : wheel(178, 17));
    if (w) s += poly([[0, top], [176, top], [160, top + 14], [0, top + 10]], SOOT, 'opacity="0.55"') + poly([[0, -14], [223, -14], [223, -20], [0, -20]], SOOT, 'opacity="0.5"');
    return w ? tilt(s, -9, 223, -14) : s;
  } },
  bus: { name: 'Bus', length: 516, height: 137, wheel_r: 22, mass_class: 8, throw_tier: 2, hit_box: [516, 137], draw(p, w) {
    const top = w ? -104 : -126;
    let s = poly([[0, -22], [516, -22], [516, -86], [500, -110], [492, top], [8, top], [0, -112]], p.body);
    s += poly([[0, -22], [516, -22], [516, -32], [0, -32]], shade(p.body, 0.78));
    for (let i = 0; i < 8; i++) s += w ? rect(30 + i * 52, top + 14, 40, 30, SOOT, 'opacity="0.75"') : rect(30 + i * 52, top + 14, 40, 30, p.glass);
    s += w ? '' : poly([[458, top + 12], [500, -108], [510, -88], [458, -88]], p.glass) + rect(400, -92, 38, 70, shade(p.glass, 1.2));   // windscreen and the door
    s += rect(8, top - 8, 90, 8, shade(p.body, 0.85)) + rect(508, -52, 8, 7, w ? SOOT : LIT);
    s += wheel(84, 22) + (w ? wheel(430, 22, { up: 14, rot: 18 }) : wheel(430, 22));
    if (w) s += poly([[0, top], [492, top], [470, top + 18], [0, top + 12]], SOOT, 'opacity="0.55"') + poly([[0, -22], [516, -22], [516, -30], [0, -30]], SOOT, 'opacity="0.5"');
    return w ? tilt(s, -6, 516, -22) : s;
  } },
  bike: { name: 'Bike', length: 90, height: 56, wheel_r: 15, mass_class: 1, throw_tier: 1, hit_box: [90, 56], draw(p, w) {
    let s = '';
    if (!w) {
      s += wheel(15, 15) + wheel(77, 15);
      s += poly([[15, -15], [40, -34], [58, -34], [77, -15], [64, -15], [50, -26], [34, -24], [26, -15]], p.dark) + poly([[34, -40], [58, -40], [58, -30], [34, -30]], p.body) + poly([[18, -34], [34, -36], [34, -28], [18, -26]], shade(p.body, 0.7));
      s += poly([[64, -50], [74, -56], [78, -52], [70, -46]], p.dark) + poly([[66, -46], [72, -46], [80, -16], [74, -16]], p.dark) + rect(78, -44, 5, 4, LIT);
    } else {
      s += wheel(14, 15, { up: 0, rot: 12 }) + `<g transform="translate(46 0) rotate(-62 0 -15)">${wheel(0, 15)}</g>`;   // the front wheel off, on its side
      s += poly([[16, -15], [38, -22], [56, -16], [50, -12], [36, -14], [24, -12]], p.dark) + poly([[34, -26], [56, -22], [54, -14], [34, -18]], p.body) + poly([[60, -12], [86, -10], [86, -6], [60, -8]], p.dark);
      s += poly([[16, -15], [38, -22], [56, -16]], SOOT, 'opacity="0.45"');
    }
    return s;
  } },
};
const PAINTS = [['downtown', 3, 'sage'], ['downtown', 0, 'steel'], ['mid_rise', 0, 'buff'], ['mid_rise', 4, 'slate'], ['downtown', 4, 'sandstone'], ['downtown', 2, 'graphite']].map(([look, i]) => {
  const t = CITY.looks[look][i]; return { id: t.id, name: t.name, body: t.wall.light, dark: t.wall.shadow, glass: t.glass.dark };
});
const LANES = { protagonist: '#8fd6ff', rival: '#9a80d8', empress: '#3c7d1c', cyborg: '#47d7a7', dummy: '#c6bade' };
const paintCheck = PAINTS.map(p => { let w = [99, '']; for (const [n, c] of Object.entries(LANES)) { const d = dE00(p.body, c); if (d < w[0]) w = [d, n]; } return { id: p.id, body: p.body, nearest_lane: w[1], dE00: +w[0].toFixed(1) }; });
writeFileSync(join(ROOT, 'data', 'art', 'vehicles.json'), JSON.stringify({ version: 1, note: 'The city\'s cars (docs/art/cars.md): four silhouettes and a wreck state, side-on, in world units (a fighter is 75), painted in the city tints. Written by art/concepts/city/cars.mjs; do not edit by hand. throw_tier follows Game Design\'s throwables ruling (rule-of-cool.md: tier 1 lifts a bike, sedan or van, tier 2 a bus); mass_class is Art\'s suggestion for Combat, not a rule. Proposals pending Legal; Tools adds the schema.', vehicles: Object.fromEntries(Object.entries(VEHICLES).map(([k, v]) => [k, { name: v.name, length: v.length, height: v.height, wheel_radius: v.wheel_r, hit_box: v.hit_box, mass_class: v.mass_class, throw_tier: v.throw_tier }])), paints: PAINTS.map(p => ({ id: p.id, name: p.name, body: p.body, dark: p.dark, glass: p.glass })), lit: LIT, tyre: TYRE, soot: SOOT, wreck: { rules: 'the same silhouette lower and askew: the roof crushed by about a quarter, the body tilted 6 to 9 degrees about the front axle, one wheel off or sprung (the bike: the front wheel off), the glass out (soot-dark, never see-through), the lights dark, a soot band along the roof and the sill; no flame, no smoke in the art (VFX\'s if wanted), no people', throw: 'seen thrown it tumbles as a flat box: the long side is the read at 46 px, so no part sticks out further than a quarter of its length' }, paint_vs_lane_colours: paintCheck }, null, 2) + '\n');

// ---- the sheet
const text = (x, y, t, { size = 12, weight = 400, fill = '#1b1428', anchor = 'start', op = 1 } = {}) => `<text x="${F(x)}" y="${F(y)}" font-family="'Segoe UI', system-ui, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${op}">${String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;')}</text>`;
const flatP = (x, g, s) => drawFigure({ concept: hero({ yaw: 0 }), pal: PAL.P, pose: FIGHTERS.P.poses.base, flat: true, bg: '#e8e5ee', x, ground: g, s });
function sheet() {
  const W = 1800, BG = '#e8e5ee'; let b = '';
  const H = 1500;
  b += `<rect width="${W}" height="${H}" fill="#dcd8e6"/><rect width="${W}" height="104" fill="#1b1428"/>` + text(30, 46, 'The city\'s cars: sedan, van, bus, bike, and a wreck', { size: 30, weight: 700, fill: '#f4f0fa' });
  b += text(30, 74, 'Faceted side-on silhouettes in the city\'s own paints, each whole and wrecked; scenery, and something a fighter can throw. Concept art, working labels, pending Legal; city art, so it may be public.', { size: 13, fill: '#cfc6e6' });
  // row 1: whole and wrecked, at 1.3 px a unit, with the paints
  const S = 0.74; let y = 150;
  b += text(30, y - 18, 'Whole and wrecked (0.74 pixels to a unit; the bar on the left is a fighter, 75 units)', { size: 14, weight: 700 });
  b += `<rect x="24" y="${y - 6}" width="${W - 48}" height="310" fill="${BG}" stroke="#1b1428" stroke-opacity="0.2"/>`;
  let x = 60; const gy = y + 250;
  b += `<rect x="30" y="${F(gy - 75 * S)}" width="4" height="${F(75 * S)}" fill="#0a0d14" opacity="0.7"/>`;
  Object.entries(VEHICLES).forEach(([k, v], i) => {
    const p = PAINTS[(i * 2 + 1) % 6], p2 = PAINTS[(i * 2 + 2) % 6];
    b += `<g transform="translate(${F(x)} ${F(gy)}) scale(${S})">${v.draw(p, 0)}</g>` + text(x, gy + 34, `${v.name} (${v.length} by ${v.height})`, { size: 11.5, weight: 700 });
    x += v.length * S + 18;
    b += `<g transform="translate(${F(x)} ${F(gy)}) scale(${S})">${v.draw(p2, 1)}</g>` + text(x, gy + 34, `${v.name}, wrecked`, { size: 11.5, op: 0.8 });
    x += v.length * S + 34;
  });
  // row 2: the paints
  y = 540; b += text(30, y - 8, 'The paints (the city tints\' walls; the nearest lane colour is far in every case)', { size: 14, weight: 700 });
  PAINTS.forEach((p, i) => { const px = 30 + i * 290; b += `<g transform="translate(${px} ${y + 70}) scale(0.62)">${VEHICLES.sedan.draw(p, 0)}</g>` + text(px, y + 100, p.name, { size: 11.5, weight: 700 }) + text(px, y + 114, `${p.body}; nearest lane ${paintCheck[i].nearest_lane} at ${paintCheck[i].dE00}`, { size: 10.5, op: 0.7 }); });
  // row 3: thrown, at fight size and 46 px, with a flat fighter for scale
  y = 720; b += text(30, y - 8, 'Thrown: the tumble at fight size (86 px a fighter) and at 46 px, with a flat fighter for scale', { size: 14, weight: 700 });
  b += `<rect x="24" y="${y}" width="${W - 48}" height="420" fill="${BG}" stroke="#1b1428" stroke-opacity="0.2"/>`;
  let tx = 50;
  const flat = (v, deg, sc, cx, cy) => `<g transform="translate(${F(cx)} ${F(cy)}) rotate(${deg}) translate(${F(-v.length * sc / 2)} ${F(v.height * sc / 2)}) scale(${sc})">${v.draw(PAINTS[0], 0).replace(/fill="#[0-9a-fA-F]{6}"/g, 'fill="#000"').replace(/stroke="#0a0d14"/g, 'stroke="#000"')}</g>`;
  Object.entries(VEHICLES).forEach(([k, v], i) => {
    const deg = [-30, 24, -9, 38][i], w86 = v.length * 0.86;
    b += flatP(tx + 24, y + 170, 0.86) + flat(v, deg, 0.86, tx + 70 + w86 / 2, y + 105) + text(tx, y + 194, `${v.name}, thrown, at fight size`, { size: 11, op: 0.75 });
    b += flatP(tx + 24, y + 380, 0.46) + flat(v, deg, 0.46, tx + 60 + v.length * 0.23, y + 335) + text(tx, y + 404, 'and at 46 px', { size: 11, op: 0.75 });
    tx += 60 + w86 + 70;
  });
  // notes
  const ny = 1180; b += text(30, ny, 'What they are', { size: 15, weight: 700 });
  const lines = [
    'Sizes are real-world lengths at the game\'s scale (a fighter is 75 units, about 1.75 m): the sedan 193 by 62, the van 223 by 86, the bus 516 by 137, the bike 90 by 56. Wheels are octagons (radius 14, 17, 22, 15). Each car is about 10 rigid parts: body, cabin, glass, two wheels, lights, a sill band; the bus 14; the bike 8. About 120, 150, 260 and 90 triangles (estimates).',
    'Paints: six, the walls of the city\'s tints (low chroma, in the same family as the buildings, so a street of cars reads as part of the city and never as a fighter); the glass is the tint\'s dark glass; the lights are the city\'s one lit colour, small and steady, and go dark in the wreck. Nothing is orange or yellow (a taxi would be fire\'s colour), mid blue (the sea\'s) or a saturated red (blood\'s). The lane colours are far from every paint except the training dummy\'s pale lavender-grey ring, which sits near a light grey car: the dummy is told apart by his keyline.',
    'The wreck: the same silhouette made lower and askew (the roof crushed by about a quarter, the body tilted 6 to 9 degrees, one wheel off or sprung, the bike\'s front wheel off), the glass out and soot-dark, the lights dark, a soot band along the roof and the sill. No flame or smoke in the art, and no people in or around a car. A thrown car that lands becomes the wreck.',
    'For Combat: Art suggests mass classes (bike 1, sedan 3, van 4, bus 8) and the first tier that can throw each (tier 1 lifts the bike, the sedan and the van, tier 2 lifts the bus: the throwables ruling in rule-of-cool.md, as the props data has it), with the hit box the car\'s own size; the tiers follow the ruling; the mass classes are suggestions in `data/art/vehicles.json`, not rules.',
  ];
  let yy = ny + 22; lines.forEach(l => { const ws = l.split(' '); let cur = ''; for (const t of ws) { if ((cur + ' ' + t).length > 232) { b += text(30, yy, cur, { size: 12 }); yy += 15; cur = t; } else cur = (cur + ' ' + t).trim(); } b += text(30, yy, cur, { size: 12 }); yy += 21; });
  writeFileSync(join(ROOT, 'art', 'concepts', 'city', 'cars.svg'), `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">${b}</svg>`);
  return H;
}
console.log('wrote data/art/vehicles.json and cars.svg, height', sheet(), JSON.stringify(paintCheck.map(p => [p.id, p.nearest_lane, p.dE00])));
