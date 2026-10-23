// Origin: the biome look bible's sheets and data (deterministic, no randomness beyond seeded generators, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-23. Human direction: Orb, via the EP ("pour resources into improving our planet generation, biomes, fighter animations").
// Run from the repo root:  node art/concepts/biomes/gen.mjs
//   -> art/concepts/biomes/biome-<id>.svg (13), biomes-sheet.svg, orbit.svg, data/art/biomes.json, docs/art/biomes-pages.md
// No characters are drawn: a neutral grey scale figure (75 units, a fighter's height) stands in. Biomes only, so these may be shown to Orb and anyone else.
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { BIOMES, PAIRS, neighboursOf } from './spec.mjs';
import { scene, mix, Frame } from './draw.mjs';
import { plumePanel } from './plume.mjs';
import { measureBiome } from './measure.mjs';
import { cvBiome, KINDS as CVK } from './cv.mjs';
import { coverSheet } from './covers.mjs';
import { writeCoverDoc } from './coverdoc.mjs';

const OUT = dirname(fileURLToPath(import.meta.url)), ROOT = join(OUT, '..', '..', '..');
const F = n => (Math.round(n * 100) / 100).toString();
const INK = '#1b1428', BG = '#e8e5ee';
const esc = t => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const FONT = "font-family=\"'Segoe UI', system-ui, -apple-system, Helvetica, Arial, sans-serif\"";
export const text = (x, y, t, { size = 12, weight = 400, fill = INK, anchor = 'start', op = 1 } = {}) => `<text x="${F(x)}" y="${F(y)}" ${FONT} font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${op}">${esc(t)}</text>`;
export const rect = (x, y, w, h, fill, extra = '') => `<rect x="${F(x)}" y="${F(y)}" width="${F(w)}" height="${F(h)}" fill="${fill}" ${extra}/>`;
export const wrap = (t, n) => { const w = t.split(' '), out = []; let line = ''; for (const x of w) { if ((line + ' ' + x).trim().length > n) { out.push(line.trim()); line = x; } else line += ' ' + x; } if (line.trim()) out.push(line.trim()); return out; };
export const paras = (x, y, t, n, size = 12, gap = 15, o = {}) => wrap(t, n).map((l, i) => text(x, y + i * gap, l, { size, ...o })).join('');
let cid = 0;
const clipped = (x, y, w, h, inner) => { const id = 'k' + cid++; return `<clipPath id="${id}"><rect x="${F(x)}" y="${F(y)}" width="${F(w)}" height="${F(h)}"/></clipPath><g clip-path="url(#${id})">${inner}</g>${`<rect x="${F(x)}" y="${F(y)}" width="${F(w)}" height="${F(h)}" fill="none" stroke="#1b1428" stroke-opacity="0.35"/>`}`; };

import { ladder, orbitHex, orbitSeparation } from './derive.mjs';

// ---------------------------------------------------------------------------------------------------------------- a neutral scale figure (no character art)
function scaleFigure(f, x, y, label) {
  const g = '#8b8794', k = '#0a0d14';
  f.poly([[x - 8, y], [x - 8, y + 44], [x - 11, y + 62], [x + 11, y + 62], [x + 8, y + 44], [x + 8, y]], g, { sw: 1.1 });
  const c = [x, y + 69]; f.poly(Array.from({ length: 10 }, (_, i) => [c[0] + Math.cos(i / 10 * 6.283) * 7, c[1] + Math.sin(i / 10 * 6.283) * 7]), g, { sw: 1.1 });
  f.line([[x + 22, y], [x + 22, y + 76]], '#1b1428', 1); f.line([[x + 18, y], [x + 26, y]], '#1b1428', 1); f.line([[x + 18, y + 76], [x + 26, y + 76]], '#1b1428', 1);
}

// ---------------------------------------------------------------------------------------------------------------- one biome's sheet
function swatch(x, y, w, hex, label, o = {}) { return rect(x, y, w, 30, hex, 'stroke="#1b1428" stroke-opacity="0.35"') + text(x + w / 2, y + 44, label, { size: 9.5, anchor: 'middle', op: 0.75 }) + text(x + w / 2, y + 56, hex, { size: 9, anchor: 'middle', op: 0.6 }); }
function biomeSheet(id) {
  const b = BIOMES[id], W = 1600, X0 = 24; let s = '', y = 0;
  s += rect(0, 0, W, 90, INK) + text(30, 44, `${b.order}. ${b.name}`, { size: 32, weight: 700, fill: '#f4f0fa' }) + text(30, 72, b.line, { size: 14, fill: '#cfc6e6' });
  y = 110;
  // A. the main strip
  const S = 1.2, ww = 1200, wh = 460, sc = scene({ id, px: X0, py: y, S, ww, wh, seed: 7 });
  scaleFigure(sc.f, 470, sc.G + sc.prof(470), ''); scaleFigure(sc.f, 650, sc.G + sc.prof(650), '');
  s += text(X0, y - 8, 'A. At fight distance, noon: the ground profile, the cover silhouettes, the far land as a value ladder. The two grey figures are 75 units tall (a fighter): scale only, no character art.', { size: 12, weight: 700 });
  s += clipped(X0, y, ww * S, wh * S, sc.f.svg());
  y += wh * S + 22;
  // palette
  const p = b.pal, L = ladder(b), itemsAll = [['ground lit', p.g[0]], ['ground mid', p.g[1]], ['ground shade', p.g[2]], ['subsoil', p.sub], ['rock lit', p.r[0]], ['rock mid', p.r[1]], ['rock shade', p.r[2]], ['veg lit', p.v[0]], ['veg mid', p.v[1]], ['veg dark', p.v[2]], ['secondary', p.v2[1]], ['trunk', p.t], ['water shallow', p.w[0]], ['water deep', p.w[1]], ['accent', p.acc], ['sky top', p.sky[0]], ['sky horizon', p.sky[1]], ['far 1', L[2]], ['far 2', L[1]], ['far 3', L[0]], ['from orbit', orbitHex(id)]];
  const items = id === 'ocean' ? itemsAll.filter(([l]) => !/^(veg|secondary|trunk|far)/.test(l)) : itemsAll;
  s += text(X0, y, 'Palette at noon (the world-light tint per sky key multiplies it; lit, mid and shade are the three faces of one surface; the far ladder is each ridge hazed toward the horizon)', { size: 12, weight: 700 });
  items.forEach(([lab, hex], i) => { s += swatch(X0 + (i % 11) * 140, y + 12 + Math.floor(i / 11) * 70, 128, hex, lab); });
  y += 12 + 2 * 70 + 24;
  // readability
  const rows = measureBiome(b), worstA = Math.min(...rows.map(r => r.aura)), worstB = Math.min(...rows.filter(r => /ground|rock|vegetation|secondary/.test(r.name)).map(r => r.bodyP));
  s += text(X0, y, `Readability (docs/art/dynamic-sky.md section 6): worst aura against any tone ${worstA.toFixed(1)} CIEDE2000 (rule: 20 or more), worst Protagonist or rival body against ground, rock or vegetation ${worstB.toFixed(1)} (rule: 15 or more), over every sky key with the world-light tint.`, { size: 11, op: 0.8 });
  y += 30;
  // B. damage
  s += text(X0, y, 'B. What the fight leaves: scorched (a beam along the ground), cratered (an impact), burned (fire on what grows)', { size: 12, weight: 700 }); y += 10;
  const dw = 560, dh = 400, dS = 0.84, PW = dw * dS, PH = dh * dS;
  const modes = [['Scorched', { damage: { kind: 'scorched', x0: 80, x1: 500 } }, b.damage.scorch], ['Cratered', { crater: { x: 290, R: 150 } }, b.damage.crater], ['Burned', { damage: { kind: 'burned', x0: 60, x1: 520 } }, b.damage.burned]];
  modes.forEach(([lab, opt, note], i) => { const x = X0 + i * (PW + 12), sc2 = scene({ id, px: x, py: y, S: dS, ww: dw, wh: dh, wx0: 200, seed: 7, ...opt, ...(opt.crater ? { crater: { x: 490, R: 150 } } : {}), ...(opt.damage ? { damage: { ...opt.damage, x0: opt.damage.x0 + 200, x1: opt.damage.x1 + 200 } } : {}) }); s += clipped(x, y, PW, PH, sc2.f.svg()) + text(x + 8, y + PH + 16, lab, { size: 13, weight: 700 }) + paras(x + 8, y + PH + 32, note, 74, 11, 14, { op: 0.9 }); });
  y += PH + 32 + 14 * 5 + 18;
  // C. destruction
  s += text(X0, y, `C. Destruction in ${b.name.toLowerCase()}: the impact at three moments (burst, peak, settle). ${b.destruction}`, { size: 12, weight: 700 }); y += 10;
  for (let i = 0; i < 3; i++) { const x = X0 + i * (PW + 12) * 1.0; s += clipped(x, y, 560 * 0.84, 420 * 0.84, plumePanel(id, i, x, y, 0.84)) + text(x + 8, y + 420 * 0.84 + 16, ['burst (0.1 s)', 'peak (0.5 s)', 'settle (1.2 s)'][i], { size: 12, weight: 700 }); }
  y += 420 * 0.84 + 40;
  // D. transitions
  const nb = neighboursOf(id);
  s += text(X0, y, 'D. Where it meets its neighbours (hard steps in colour, never a fade; the cover mixes over about a third of the width)', { size: 12, weight: 700 }); y += 10;
  const tw = 1000, th = 330, tS = 0.46, TW = tw * tS, TH = th * tS;
  nb.forEach((n, i) => { const x = X0 + (i % 3) * (TW + 20), yy = y + Math.floor(i / 3) * (TH + 84); const sc3 = scene({ id: null, mix: { a: id, b: n.other, x0: 330, x1: 690, eco: n.eco }, px: x, py: yy, S: tS, ww: tw, wh: th, wx0: 0, seed: 21 }); s += clipped(x, yy, TW, TH, sc3.f.svg()) + text(x + 4, yy + TH + 14, `${b.name} to ${BIOMES[n.other].name}`, { size: 11.5, weight: 700 }) + paras(x + 4, yy + TH + 28, n.note, 80, 10.5, 13, { op: 0.88 }); });
  y += Math.ceil(nb.length / 3) * (TH + 84) + 10;
  return { svg: `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${y}" viewBox="0 0 ${W} ${y}">${rect(0, 0, W, y, '#dcd8e6')}${s}</svg>`, rows };
}

// ---------------------------------------------------------------------------------------------------------------- all biomes side by side
function allSheet() {
  const W = 1860, PW = 600, PH = 230, X0 = 24, ids = Object.keys(BIOMES); let s = rect(0, 0, W, 104, INK) + text(30, 46, 'Thirteen biomes side by side, at fight distance, noon', { size: 30, weight: 700, fill: '#f4f0fa' });
  s += paras(30, 70, 'Each panel is one 1,200-unit stretch of ground at the same scale, with a 75-unit grey figure for scale. Flat faceted colours with a keyline; the far land is a value ladder toward the haze; no gradients, no blur. Below each: ground, rock, vegetation, water and sky horizon. Concept art for Rendering and VFX; no character art.', 260, 12, 15, { fill: '#cfc6e6' });
  ids.forEach((id, i) => {
    const b = BIOMES[id], x = X0 + (i % 3) * (PW + 12), y = 124 + Math.floor(i / 3) * (PH + 70), sc = scene({ id, px: x, py: y, S: 0.5, ww: 1200, wh: 460, seed: 7 });
    scaleFigure(sc.f, 520, sc.G + sc.prof(520), '');
    s += clipped(x, y, PW, PH, sc.f.svg()) + text(x + 4, y + PH + 16, `${b.order}. ${b.name}`, { size: 14, weight: 700 });
    [['g', b.pal.g[1]], ['r', b.pal.r[1]], ['v', b.pal.v[1]], ['w', b.pal.w[1]], ['sky', b.pal.sky[1]], ['acc', b.pal.acc]].forEach(([n, hex], j) => { s += rect(x + 4 + j * 36, y + PH + 24, 32, 18, hex, 'stroke="#1b1428" stroke-opacity="0.35"'); });
    s += paras(x + 4 + 6 * 36 + 8, y + PH + 34, b.line, 62, 10.5, 13, { op: 0.8 });
  });
  const H = 124 + Math.ceil(ids.length / 3) * (PH + 70) + 10;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${rect(0, 0, W, H, '#dcd8e6')}${s}</svg>`;
}



// ---------------------------------------------------------------------------------------------------------------- the light keys: each biome under golden, sunset, dawn and night with the world-light tints
import { WORLD, tinted, dE00 } from '../sky/world.mjs';
import { KEYS, skyAt } from '../sky/keys.mjs';
import { tonesOf } from './measure.mjs';
const LAN = { aura: ['#8fd6ff', '#9a80d8'], body: ['#3d8fdc', '#a52a2a'] };
function atKey(b, key) { let a = 99, bd = 99; for (const [name, hex, layer] of tonesOf(b)) { const g = tinted(hex, WORLD[key][layer]); for (const c of LAN.aura) a = Math.min(a, dE00(c, g)); if (/ground|rock|vegetation|secondary/.test(name)) for (const c of LAN.body) bd = Math.min(bd, dE00(c, g)); } return [a, bd]; }
function keySheet(key) {
  const k = KEYS.find(q => q.id === key), W = 1860, PW = 600, PH = 230, X0 = 24, ids = Object.keys(BIOMES), NOTES = { golden: 'late afternoon: amber climbs from the horizon', sunset: 'the current look of the build: indigo, violet, coral, peach', dawn: 'teal into rose into apricot, cooler and greener than the sunset', night: 'blue-black with a cold rim; the ground about a tenth of noon with a cool lift' };
  let s = rect(0, 0, W, 104, INK) + text(30, 46, `Thirteen biomes at ${key}: the world-light tints on the ground, trees and water`, { size: 30, weight: 700, fill: '#f4f0fa' });
  s += paras(30, 70, `The sky is the game's ${key} key (${NOTES[key]}); each biome's ground, rock, vegetation and water take that key's world-light multiply (data/art/sky.json), and the keyline stays. The fighters' auras and bodies are never dimmed: under each panel, the worst aura and body distance to any of that biome's tones at this key (rule 20 and 15). Same strips, same seeds as the noon sheet.`, 260, 12, 15, { fill: '#cfc6e6' });
  ids.forEach((id, i) => {
    const b = BIOMES[id], x = X0 + (i % 3) * (PW + 12), y = 124 + Math.floor(i / 3) * (PH + 62), sc = scene({ id, px: x, py: y, S: 0.5, ww: 1200, wh: 460, seed: 7, key });
    scaleFigure(sc.f, 520, sc.G + sc.prof(520), '');
    const [a, bd] = atKey(b, key);
    s += clipped(x, y, PW, PH, sc.f.svg()) + text(x + 4, y + PH + 16, `${b.order}. ${b.name}`, { size: 14, weight: 700 }) + text(x + PW - 4, y + PH + 16, `aura ${a.toFixed(1)}, body ${bd.toFixed(1)}`, { size: 11, anchor: 'end', op: 0.75 });
  });
  const H = 124 + Math.ceil(ids.length / 3) * (PH + 62) + 10;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${rect(0, 0, W, H, '#dcd8e6')}${s}</svg>`;
}
export function keyNumbers() { const out = {}; for (const key of ['golden', 'sunset', 'dawn', 'night']) { out[key] = {}; for (const [id, b] of Object.entries(BIOMES)) { const [a, bd] = atKey(b, key); out[key][id] = { aura: +a.toFixed(1), body: +bd.toFixed(1) }; } } return out; }

// ---------------------------------------------------------------------------------------------------------------- the data and the generated pages
const SCARS = { desert: ['#1f3d38', '#bfe0d8'], beach: ['#1f3d38', '#bfe0d8'], ice: ['#485765', '#5f8aa2'], seaice: ['#485765', '#5f8aa2'], volcanic: ['#8a868e', '#dc6a26'] };
export function writeData() {
  const out = { version: 1, note: 'The biome look bible as data (docs/art/biomes.md, docs/art/biomes-pages.md). Written by art/concepts/biomes/gen.mjs; do not edit by hand. Noon colours: the world-light tint per key (data/art/sky.json) multiplies them. Proposals pending Orb, Rendering and VFX; Tools adds the schema.', rules: { faces: 'lit, mid and shade are the three faces of one surface; flat colours with the keyline (#0a0d14); no gradients, no blur, no fades', readability: 'an aura stays 20 or more CIEDE2000 from every ground, rock, vegetation and water tone and a body 15 or more from ground, rock and vegetation, at every sky key with the world-light tint (the rival coat and the sea are advisory)', far_land: 'three ridges, each hazed toward the horizon: far1 nearest and darkest', orbit: 'the colour a biome reads as from far away, 12 percent toward the atmosphere blue (8 for ice)' }, orbit_separation: orbitSeparation(), _cover_set: coverSheet().table, biomes: {}, pairs: PAIRS.map(([a, b, eco, note]) => ({ a, b, eco, note })) };
  for (const [id, b] of Object.entries(BIOMES)) {
    const rows = measureBiome(b), L = ladder(b);
    out.biomes[id] = { name: b.name, order: b.order, line: b.line, palette: { ground: b.pal.g, subsoil: b.pal.sub, rock: b.pal.r, vegetation: b.pal.v, secondary: b.pal.v2, trunk: b.pal.t, water: { shallow: b.pal.w[0], deep: b.pal.w[1] }, accent: b.pal.acc, sky_noon: { top: b.pal.sky[0], horizon: b.pal.sky[1] } }, far_ladder: { far1: L[2], far2: L[1], far3: L[0] }, orbit: orbitHex(id), profile: b.profile, far_land: b.far, cover: b.cover.filter(c => c.n > 0), plume: b.plume, scar: { fill: (SCARS[id] ?? ['#221c18', '#4a4036'])[0], edge: (SCARS[id] ?? ['#221c18', '#4a4036'])[1] }, damage: b.damage, destruction: b.destruction, neighbours: neighboursOf(id).map(n => ({ id: n.other, eco: n.eco, note: n.note })), _colour_vision: (() => { const cr = cvBiome(b); const worst = {}; for (const k of CVK) worst[k] = Math.min(...cr.map(r => r.w[k].aura)); return { rule: 'the preset lane auras (data/art/colour-vision.json) under each vision stay 14 or more CIEDE2000 from every tone at every sky key', worst_aura_dE00: worst, failing_tones: cr.filter(r => !r.ok).map(r => ({ tone: r.name, hex: r.hex })) }; })(), readability: { worst_aura_dE00: Math.min(...rows.map(r => r.aura)), worst_body_dE00: Math.min(...rows.filter(r => /ground|rock|vegetation|secondary/.test(r.name)).map(r => r.bodyP)) }, ...(b.note ? { note: b.note } : {}) };
  }
  writeFileSync(join(ROOT, 'data', 'art', 'biomes.json'), JSON.stringify(out, null, 2) + '\n');
  return out;
}

export function writePages() {
  let md = '# Biome pages: the thirteen biomes, one by one\n\nOwner: Art Director. 2026-10-23. **Generated** by `art/concepts/biomes/gen.mjs` from `art/concepts/biomes/spec.mjs`; do not edit by hand (edit the spec and regenerate). The bible and its rules are `docs/art/biomes.md`; the numbers as data are `data/art/biomes.json`; the pictures are `art/concepts/biomes/biome-<id>.svg`, `biomes-sheet.svg` and `orbit.svg`. Concept art, working labels; biomes only, no character art, so these may be shown freely.\n\n';
  for (const [id, b] of Object.entries(BIOMES)) {
    const p = b.pal, L = ladder(b), rows = measureBiome(b);
    md += `## ${b.order}. ${b.name}\n\n${b.line[0].toUpperCase() + b.line.slice(1)}. Sheet: \`art/concepts/biomes/biome-${id}.svg\`.\n\n`;
    md += `| Part | Lit | Mid | Shade |\n|---|---|---|---|\n| Ground | ${p.g[0]} | ${p.g[1]} | ${p.g[2]} |\n| Rock | ${p.r[0]} | ${p.r[1]} | ${p.r[2]} |\n| Vegetation | ${p.v[0]} | ${p.v[1]} | ${p.v[2]} |\n\n`;
    md += `Subsoil (what a crater shows) ${p.sub}; secondary cover ${p.v2[1]}; trunk ${p.t}; water shallow ${p.w[0]}, deep ${p.w[1]}; accent ${p.acc}; sky at noon ${p.sky[0]} (top) to ${p.sky[1]} (horizon); far land ${L[2]}, ${L[1]}, ${L[0]}; from orbit ${orbitHex(id)}.\n\n`;
    md += `**Ground profile:** ${b.profile.kind}, amplitude ${b.profile.amp} units over about ${b.profile.wave}; far land: ${b.far.kind}. **Cover:** ${b.cover.filter(c => c.n > 0).map(c => `${c.k} (${c.n} per 1,200 units, ${c.h[0]} to ${c.h[1]} units tall)`).join('; ')}.\n\n`;
    md += `**Scorched:** ${b.damage.scorch}.\n\n**Cratered:** ${b.damage.crater}.\n\n**Burned:** ${b.damage.burned}.\n\n**Destruction:** ${b.destruction}\n\n`;
    md += `**Readability:** worst aura ${Math.min(...rows.map(r => r.aura)).toFixed(1)} CIEDE2000 (rule 20), worst body against ground, rock or vegetation ${Math.min(...rows.filter(r => /ground|rock|vegetation|secondary/.test(r.name)).map(r => r.bodyP)).toFixed(1)} (rule 15).\n\n`;
    if (b.note) md += `**Note:** ${b.note}.\n\n`;
    md += `**Transitions:**\n` + neighboursOf(id).map(n => `- to ${BIOMES[n.other].name}: ${n.note}`).join('\n') + '\n\n';
  }
  writeFileSync(join(ROOT, 'docs', 'art', 'biomes-pages.md'), md);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const only = process.argv[2];
  const results = {};
  for (const id of Object.keys(BIOMES)) { if (only && only !== id && only !== 'all') continue; const r = biomeSheet(id); writeFileSync(join(OUT, `biome-${id}.svg`), r.svg); results[id] = r.rows; console.log('wrote biome-' + id + '.svg'); }
  if (!only || only === 'all' || only === 'sheet') { writeFileSync(join(OUT, 'biomes-sheet.svg'), allSheet()); console.log('wrote biomes-sheet.svg'); }
  if (!only || only === 'all' || only === 'keys') { for (const key of ['golden', 'sunset', 'dawn', 'night']) { writeFileSync(join(OUT, `biomes-${key}.svg`), keySheet(key)); console.log('wrote biomes-' + key + '.svg'); } }
  if (!only || only === 'all' || only === 'cover') { const r = coverSheet(); writeFileSync(join(OUT, 'cover-sheet.svg'), r.svg); writeCoverDoc(); console.log('wrote cover-sheet.svg and docs/art/biomes-cover.md'); }
  if (!only || only === 'all' || only === 'data') { writeData(); writePages(); console.log('wrote data/art/biomes.json and docs/art/biomes-pages.md'); }
  if (!only || only === 'all' || only === 'orbit') { const { orbitSheet } = await import('./orbit.mjs'); writeFileSync(join(OUT, 'orbit.svg'), orbitSheet()); console.log('wrote orbit.svg'); }
}
