// Origin: the polar outposts (a remote research station and a mining camp), as concept art and data (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-18. Human direction: Orb, via the EP (a remote research station on the ice caps, and a mining camp). Buildings only, no characters.
// Run from the repo root:  node art/concepts/world/outposts.mjs   -> data/art/outposts.json, art/concepts/world/polar-outposts.svg
// Built only from World's existing shapes (prisms and stacks of prisms, no curves: the round things are octagons), in the polar palette (data/art/polar.json): the cladding is a weathered timber
// and a steel grey, mid in value so it reads on the white and on the slate; the only light is the city's lit window colour, steady. City and environment art: it may be public.
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { WORLD, tinted, dE00 } from '../sky/world.mjs';
import { KEYS, skyAt } from '../sky/keys.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const F = n => n.toFixed(1);
const POLAR = JSON.parse(await import('node:fs').then(m => m.readFileSync(join(ROOT, 'data', 'art', 'polar.json'), 'utf8')));
const SNOW = POLAR.biomes.ice_sheet.lit, SLATE = POLAR.biomes.ice_sheet.dark, WATER = POLAR.biomes.polar_water.deep, ROCK = POLAR.biomes.ice_sheet.rock;
const LIT = '#f3cf86';   // the city's lit window colour (data/art/sky.json windows)
export const TONES = {
  timber: { lit: '#8d7d6a', mid: '#7a6a58', dark: '#554a40' },   // weathered cladding
  steel: { lit: '#8a949f', mid: '#737d88', dark: '#4f5862' },
  roof: '#33302e', soot: '#2f2a2a', rock: ROCK, container: '#6e5646', glass: '#2c3550',
};
export const OUTPOSTS = {
  research_station: {
    name: 'The research station', size_units: [760, 220], shapes: { main_module: 'slab on posts', sleeping_modules: 'shed x2', link: 'block', generator: 'block with a chimney', mast: 'mast', drums: 'chimney x5 (octagonal)', ramp: 'a wedge (lean)' },
    what: 'a small cluster raised on posts above the snow: one long main module, two sleeping modules, a generator house with a stack, an instrument mast and a row of fuel drums, joined by a corridor and a snow ramp. Dark roofs, weathered timber walls, a few steady lit windows.',
    parts: 14, estimate_triangles: 360,
  },
  mining_camp: {
    name: 'The mining camp', size_units: [900, 260], shapes: { headframe: 'crane (an A-frame with a wheel)', bunker: 'warehouse', conveyor: 'a lean prism on posts', stockpile: 'stepped block', containers: 'block x3 (two stacked)', tanks: 'chimney x3 (octagonal, short)', heater: 'shed with a chimney' },
    what: 'a headframe over a shaft, an ore bunker with a conveyor to a stockpile of dark rock, a stack of containers, three fuel tanks and a heater shed with a flue. Steel and rusted-brown containers, soot and rock; the heaps are the darkest, biggest shapes on the white.',
    parts: 16, estimate_triangles: 420,
  },
};

const poly = (pts, fill, extra = '') => `<polygon points="${pts.map(([x, y]) => `${F(x)},${F(y)}`).join(' ')}" fill="${fill}" ${extra}/>`;
const rect = (x, y, w, h, fill, extra = '') => `<rect x="${F(x)}" y="${F(y)}" width="${F(w)}" height="${F(h)}" fill="${fill}" ${extra}/>`;
const oct = (cx, cy, r, fill) => poly(Array.from({ length: 8 }, (_, i) => [cx + Math.cos((i + 0.5) / 8 * Math.PI * 2) * r, cy + Math.sin((i + 0.5) / 8 * Math.PI * 2) * r]), fill, 'stroke="#0a0d14" stroke-width="1" stroke-opacity="0.5"');
const text = (x, y, t, { size = 12, weight = 400, fill = '#1b1428', anchor = 'start', op = 1 } = {}) => `<text x="${F(x)}" y="${F(y)}" font-family="'Segoe UI', system-ui, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${op}">${String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;')}</text>`;
const line = (pts, stroke, w) => `<polyline points="${pts.map(([x, y]) => `${F(x)},${F(y)}`).join(' ')}" fill="none" stroke="${stroke}" stroke-width="${w}" stroke-linejoin="round"/>`;
const ink = 'stroke="#0a0d14" stroke-width="1" stroke-opacity="0.55"';

// each builder draws at ground y = 0 with x from 0, in units, then is scaled; (win) is the share of windows lit
function station(win) {
  const T = TONES; let s = '';
  const posts = (x0, w, h) => { let o = ''; for (let i = 0; i <= Math.max(2, Math.round(w / 80)); i++) o += rect(x0 + i * (w - 10) / Math.max(2, Math.round(w / 80)), -h, 10, h, T.steel.dark, ink); return o; };
  const module_ = (x0, w, h, stilt, roofShed) => {
    let o = posts(x0, w, stilt) + rect(x0, -stilt - h, w, h, T.timber.mid, ink) + rect(x0 + w * 0.88, -stilt - h, w * 0.12, h, T.timber.dark) + rect(x0, -stilt - h, w * 0.05, h, T.timber.lit);
    o += roofShed ? poly([[x0 - 6, -stilt - h], [x0 + w + 6, -stilt - h], [x0 + w + 6, -stilt - h - 12], [x0 - 6, -stilt - h - 24]], T.roof, ink) : rect(x0 - 6, -stilt - h - 10, w + 12, 10, T.roof, ink);
    const n = Math.max(2, Math.floor(w / 46)); for (let i = 0; i < n; i++) { const lit = ((i * 7 + x0) % 10) / 10 < win; o += rect(x0 + 14 + i * ((w - 40) / n), -stilt - h * 0.72, 20, 18, lit ? LIT : T.glass, 'opacity="0.95"'); }
    return o;
  };
  s += module_(250, 270, 64, 50, false);                 // the main module
  s += module_(40, 120, 56, 40, true) + module_(540, 110, 56, 40, true);   // two sleeping modules (shed roofs)
  s += rect(160, -80, 90, 24, T.steel.mid, ink) + rect(160, -60, 90, 4, T.steel.dark);
  s += rect(520, -80, 20, 24, T.steel.mid, ink);          // the link to the far module
  // the generator house, with its stack
  s += rect(670, -60, 90, 60, T.steel.mid, ink) + rect(670, -60, 90, 10, T.roof) + rect(742, -60, 18, 60, T.steel.dark);
  s += rect(690, -170, 16, 110, T.steel.dark, ink) + poly([[684, -170], [712, -170], [708, -182], [688, -182]], T.roof);
  // the instrument mast with a cross yard and stays
  s += rect(612, -230, 8, 230, T.steel.dark, ink) + rect(590, -214, 52, 6, T.steel.dark) + rect(598, -170, 36, 5, T.steel.dark) + line([[616, -230], [560, 0]], T.steel.mid, 1.4) + line([[616, -230], [676, 0]], T.steel.mid, 1.4);
  // the ramp to the main door
  s += poly([[190, 0], [250, -50], [250, 0]], SNOW, ink);
  // fuel drums
  for (let i = 0; i < 5; i++) s += poly([[20 + i * 26, 0], [20 + i * 26, -26], [34 + i * 26, -30], [44 + i * 26, -26], [44 + i * 26, 0]], T.container, ink);
  return s;
}
function camp(win) {
  const T = TONES; let s = '';
  // the stockpile: stepped heaps of dark rock
  s += poly([[470, 0], [470, -34], [520, -34], [520, -62], [580, -62], [580, -86], [650, -86], [650, -62], [720, -62], [720, -34], [790, -34], [790, 0]], T.rock, ink) + poly([[650, -86], [720, -62], [720, 0], [650, 0]], T.soot, 'opacity="0.35"');
  // the ore bunker (a warehouse with a shallow gable)
  s += rect(250, -90, 220, 90, T.steel.mid, ink) + poly([[244, -90], [476, -90], [360, -112]], T.roof, ink) + rect(250, -22, 60, 22, T.timber.dark, ink);
  for (let i = 0; i < 4; i++) s += rect(272 + i * 46, -70, 22, 14, ((i * 3) % 4) / 4 < win ? LIT : T.glass);
  // the conveyor from the bunker up to the stockpile, on posts
  s += poly([[470, -78], [575, -150], [575, -138], [470, -66]], T.steel.dark, ink);
  for (const x of [500, 535, 570]) s += rect(x, -(78 + (x - 470) * 0.69) + 8, 6, 78 + (x - 470) * 0.69 - 8, T.steel.dark);
  // the headframe: an A-frame with a wheel, over the shaft
  s += poly([[40, 0], [78, -210], [92, -210], [130, 0], [118, 0], [85, -178], [52, 0]], T.steel.dark, ink) + rect(52, -92, 66, 8, T.steel.dark) + rect(66, -150, 38, 6, T.steel.dark) + oct(85, -222, 26, T.steel.mid) + oct(85, -222, 9, T.roof) + rect(60, -26, 50, 26, T.roof, ink);
  // the containers, two and one stacked
  s += rect(160, -50, 120, 50, T.container, ink) + rect(160, -100, 120, 50, T.steel.mid, ink);
  for (let i = 1; i < 4; i++) s += rect(160 + i * 30, -50, 2, 50, T.timber.dark, 'opacity="0.7"') + rect(160 + i * 30, -100, 2, 50, T.steel.dark, 'opacity="0.6"');
  // the fuel tanks (octagonal, short) and the heater shed with its flue
  for (let i = 0; i < 3; i++) s += poly([[820 + i * 34 - 15, 0], [820 + i * 34 + 15, 0], [820 + i * 34 + 15, -56], [820 + i * 34 + 11, -64], [820 + i * 34 - 11, -64], [820 + i * 34 - 15, -56]], T.steel.lit, ink);
  s += rect(930, -60, 90, 60, T.timber.mid, ink) + poly([[924, -60], [1026, -60], [975, -78]], T.roof, ink) + rect(1000, -130, 14, 70, T.steel.dark, ink) + poly([[996, -130], [1018, -130], [1014, -140], [1000, -140]], T.roof);
  return s;
}
const SCENES = [['research_station', station, 'noon', 0.0, 0.0], ['research_station', station, 'night', 0.58, 0.6], ['mining_camp', camp, 'noon', 0.0, 0.0], ['mining_camp', camp, 'night', 0.58, 0.6]];

// ---- measures: the cladding and roofs against the polar ground tones at every key (worst dE00, with each key's ground tint on the ground)
function worst(hex, grounds, skipNight) { let w = [99, '']; for (const k of KEYS) { if (skipNight && k.id === 'night') continue; for (const [n, g] of grounds) { const d = dE00(tinted(hex, WORLD[k.id].buildings), tinted(g, WORLD[k.id].ground)); if (d < w[0]) w = [d, `${n}/${k.id}`]; } } return +w[0].toFixed(1); }
const measured = Object.fromEntries(Object.entries({ timber_mid: TONES.timber.mid, steel_mid: TONES.steel.mid, roof: TONES.roof, container: TONES.container, rock: TONES.rock }).map(([n, h]) => [n, { vs_white_every_key: worst(h, [['white', SNOW]], false), vs_slate_by_day: worst(h, [['slate', SLATE]], true), vs_slate_at_night: worst(h, [['slate', SLATE]], false) }]));
writeFileSync(join(ROOT, 'data', 'art', 'outposts.json'), JSON.stringify({ version: 1, note: 'The polar outposts (docs/art/polar-outposts.md): a research station and a mining camp, buildings only, built from World\'s existing shapes in the polar palette. Written by art/concepts/world/outposts.mjs; do not edit by hand. Proposals pending Legal; Tools adds the schema.', tones: TONES, lit_window: LIT, outposts: OUTPOSTS, measured_against_the_ice_dE00: measured, measured_note: 'against the warm white at every key; against the slate at every key but night. At night everything is dark and a dark building on slate ground is dark on dark: it stands against the sky, not the ground.' }, null, 2) + '\n');

function sheet() {
  const W = 1800, SW = 880, SH = 420, S = 0.92; let b = '';
  const H = 120 + 2 * (SH + 70) + 200;
  b += rect(0, 0, W, H, '#dcd8e6') + rect(0, 0, W, 104, '#1b1428') + text(30, 46, 'The polar outposts: a research station and a mining camp', { size: 30, weight: 700, fill: '#f4f0fa' });
  b += text(30, 74, 'Buildings only, no characters; built from World\'s own shapes in the polar palette: weathered timber and steel, dark roofs, the one warm light steady. Concept art, working labels, pending Legal; city and environment art, so it may be public.', { size: 13, fill: '#cfc6e6' });
  SCENES.forEach(([id, draw, key, phase, win], i) => {
    const x0 = 24 + (i % 2) * (SW + 8), y0 = 124 + Math.floor(i / 2) * (SH + 70), bands = skyAt(phase).bands, T = WORLD[key];
    b += text(x0, y0 - 8, `${OUTPOSTS[id].name}, ${key === 'noon' ? 'noon' : 'night: the lit windows'}`, { size: 14, weight: 700 });
    b += `<defs><linearGradient id="g${i}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${bands.top}"/><stop offset="0.5" stop-color="${bands.upper}"/><stop offset="0.85" stop-color="${bands.lower}"/><stop offset="1" stop-color="${bands.horizon}"/></linearGradient><clipPath id="c${i}"><rect x="${x0}" y="${y0}" width="${SW}" height="${SH}"/></clipPath></defs><g clip-path="url(#c${i})">`;
    const gy = y0 + SH * 0.78;
    b += rect(x0, y0, SW, SH, `url(#g${i})`) + rect(x0, gy, SW, SH - SH * 0.78, tinted(SNOW, T.ground));
    b += poly([[x0 + SW * 0.62, gy], [x0 + SW, gy - 6], [x0 + SW, y0 + SH], [x0 + SW * 0.72, y0 + SH]], tinted(SLATE, T.ground), 'opacity="0.9"');
    b += `<g transform="translate(${F(x0 + 36)} ${F(gy)}) scale(${S})">${draw(win)}</g>`;
    // a scale bar: one fighter's height, 75 units
    b += rect(x0 + 12, gy - 75 * S, 4, 75 * S, '#0a0d14', 'opacity="0.7"') + text(x0 + 22, gy - 75 * S + 8, '75 units: a fighter', { size: 10.5, fill: key === 'noon' ? '#0a0d14' : '#e8e8e8' });
    b += '</g>';
  });
  const y = 124 + 2 * (SH + 70) - 10;
  b += text(30, y + 14, 'What they are made of', { size: 15, weight: 700 });
  const lines = [
    `Research station: ${OUTPOSTS.research_station.what} About ${OUTPOSTS.research_station.parts} parts, ${OUTPOSTS.research_station.estimate_triangles} triangles (estimate), 760 units wide; World's shapes: a slab on posts, two sheds, a block with a chimney, a mast, five octagonal drums.`,
    `Mining camp: ${OUTPOSTS.mining_camp.what} About ${OUTPOSTS.mining_camp.parts} parts, ${OUTPOSTS.mining_camp.estimate_triangles} triangles (estimate), 900 units wide; World's shapes: a crane, a warehouse, a stepped block, containers, octagonal tanks, a shed with a chimney.`,
    `Against the ice (world-light tint applied): the walls (timber and containers) sit ${Math.min(measured.timber_mid.vs_white_every_key, measured.container.vs_white_every_key)} or more from the white at every key and ${Math.min(measured.timber_mid.vs_slate_by_day, measured.container.vs_slate_by_day)} or more from the slate by day; the steel (posts, tanks, small parts) is ${Math.min(measured.steel_mid.vs_white_every_key, measured.steel_mid.vs_slate_by_day)} from both, and the roofs are ${measured.roof.vs_white_every_key} from the white (they stand against the sky, not the slate). At night everything is dark and the base melts into the slate: a building stands against the sky, not the ground. Nothing is orange (fire's), teal or mid blue; the warm window light is the city's, steady.`,
  ];
  lines.forEach((l, i) => { const w = l.split(' '); let cur = '', row = 0; for (const t of w) { if ((cur + ' ' + t).length > 230) { b += text(30, y + 36 + (i * 3 + row) * 15, cur, { size: 12 }); cur = t; row++; } else cur = (cur + ' ' + t).trim(); } b += text(30, y + 36 + (i * 3 + row) * 15, cur, { size: 12 }); });
  writeFileSync(join(ROOT, 'art', 'concepts', 'world', 'polar-outposts.svg'), `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">${b}</svg>`);
  return H;
}
console.log('wrote data/art/outposts.json and polar-outposts.svg, height', sheet(), JSON.stringify(measured));
