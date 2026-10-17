// Origin: the city looks' palettes and facade types, as data and one sheet (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-16. Human direction: Orb, via the EP (homework 4: the towers are "a bunch of dark grid lines" up close).
// Run from the repo root:  node art/concepts/city/gen.mjs   -> data/art/city-looks.json, art/concepts/city/city-palettes.svg
// The one rule (Rendering, building.gdshader 7b): on downtown and mid_rise a pane may differ from its wall by at most 0.085 of relative luminance, or the stripes flip on every shake of the camera.
// So the variety here is HUE and CHROMA at equal luminance, never value: each tint's glass sits within 0.07 of its wall's mid tone, and fins, bases and cornices likewise.
// Buildings stay off the fighters' lane hues (cyan, violet, green, mint), off blood red and fire's orange, and off mid blue (the sea's): every chroma is low and the hues are warm and neutral greys.
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { toOklab, fromOklab, luminance, lchOf, toLin, fromLin, dE00 } from '../sky/colour.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const F = n => n.toFixed(2);
// the colour of a given hue and chroma (OKLCH) at a given relative luminance, by bisection on OKLab lightness
function solve(lum, C, hDeg) {
  const h = hDeg * Math.PI / 180, a = C * Math.cos(h), b = C * Math.sin(h);
  let lo = 0, hi = 1, best = '#000000';
  for (let i = 0; i < 40; i++) { const L = (lo + hi) / 2; best = fromOklab([L, a, b]); if (luminance(best) > lum) hi = L; else lo = L; }
  return best;
}
// the wall's three tones as relative luminances (downtown's today: #b8c0cc, #7f8896, #4a5261 are 0.52, 0.25, 0.09; mid_rise a step lighter)
const WALL_LUM = { downtown: { light: 0.50, mid: 0.24, shadow: 0.09 }, mid_rise: { light: 0.58, mid: 0.30, shadow: 0.12 } };
const BUDGET = 0.085, GLASS_STEP = 0.04;   // w05 (Legal, RL-144): the budget holds BETWEEN NEIGHBOURING ELEMENTS too: every tone is within 0.04 of the wall's mid, so no two differ by more than 0.08
// as the render masses it (Rendering, building.gdshader 7b): every tone times lum(shadow)/lum(mid) in linear light. In OKLab that scales L, a and b alike, so the hue holds and the chroma falls to about 0.72 of the wall's.
const massOf = (hex, look) => { const k = WALL_LUM[look].shadow / WALL_LUM[look].mid; return fromLin(toLin(hex).map(c => c * k)); };
// what a viewer calls it at that tone (OKLCH of the massed colour); 'olive' and 'brown' are the two the EP and Rendering flagged
const readAs = hex => { const [, C, h] = lchOf(hex); if (C < 0.010) return 'grey'; if (h < 20 || h >= 350) return 'rose'; if (h < 45) return 'brick'; if (h < 75) return 'brown'; if (h < 130) return 'olive'; if (h < 190) return 'pine'; if (h < 250) return 'slate'; if (h < 300) return 'blue-grey'; return 'plum'; };
// the tints: wall (hue, chroma), glass (hue, chroma), trim (hue, chroma). Hue and chroma only: the luminances come from the look.
// Re-cut 2026-10-17 (EP brief; Rendering's docs/rendering/city-variety.md): the render masses a tower in the look's SHADOW tone, so every tone is scaled by lum(shadow)/lum(mid) in linear light
// (a third of its brightness, about 0.72 of its chroma). The old warm tints (hue 55 to 95, chroma 0.014 to 0.035) came out at chroma 0.01 to 0.026 there and read as brown and olive.
// Now: no wall or glass between hue 45 and 130 (where dark reads olive or mud), chroma lifted so the MASSED wall keeps 0.023 or more, and the warm family is brick and rose, not buff and cream.
const TINTS = {
  downtown: [
    { id: 'steel', name: 'Steel and plum glass', wall: [255, 0.030], glass: [325, 0.030], trim: [255, 0.020] },
    { id: 'brick', name: 'Brick and teal glass', wall: [32, 0.055], glass: [205, 0.040], trim: [32, 0.035] },
    { id: 'graphite', name: 'Graphite and teal glass', wall: [270, 0.006], glass: [195, 0.030], trim: [270, 0.004] },
    { id: 'pine', name: 'Pine and plum glass', wall: [170, 0.035], glass: [340, 0.035], trim: [170, 0.022] },
    { id: 'plum', name: 'Plum and teal glass', wall: [335, 0.045], glass: [190, 0.035], trim: [335, 0.028] },
    { id: 'teal', name: 'Teal slate and rose glass', wall: [210, 0.035], glass: [15, 0.030], trim: [210, 0.022] },
  ],
  mid_rise: [
    { id: 'terracotta', name: 'Terracotta and teal glass', wall: [35, 0.065], glass: [215, 0.040], trim: [35, 0.040] },
    { id: 'rose', name: 'Dusty rose and teal glass', wall: [8, 0.045], glass: [200, 0.035], trim: [8, 0.030] },
    { id: 'concrete', name: 'Pale concrete and plum glass', wall: [250, 0.008], glass: [325, 0.030], trim: [250, 0.006] },
    { id: 'spruce', name: 'Spruce and plum glass', wall: [165, 0.040], glass: [345, 0.035], trim: [165, 0.025] },
    { id: 'mauve', name: 'Mauve and teal glass', wall: [330, 0.050], glass: [195, 0.035], trim: [330, 0.030] },
    { id: 'slateblue', name: 'Slate blue and rose glass', wall: [250, 0.040], glass: [15, 0.030], trim: [250, 0.026] },
  ],
};
// the facade types: parameters in shares of a floor cell, every tone given as an offset in relative luminance from the wall's mid tone (never more than the budget)
const FACADES = {
  ribbon: { name: 'Ribbon windows', what: 'continuous horizontal bands of glass between thin piers; today\'s downtown and mid_rise rhythm', pane_h: 0.55, pier_w: 0.05, spandrel: { h: 0.45, lum_offset: -0.02 }, fits: 'downtown shafts under 40 floors; mid_rise_east' },
  punched: { name: 'Punched windows with spandrels', what: 'separate panes in a regular grid with a darker band under each row: reads as stone or brick, a heavier and older building', pane_w: 0.38, pane_h: 0.5, spandrel: { h: 0.3, lum_offset: -0.03 }, fits: 'mid_rise_west; the older downtown towers' },
  fins: { name: 'Vertical fins', what: 'tall glass between projecting fins one pane apart: a strongly vertical read, the tallest shafts', pane_w: 0.78, fin: { w: 0.14, pitch: 0.25, lum_offset: -0.03, sun_side_offset: 0.03 }, fits: 'downtown shafts of 40 floors or more; a few mid_rise slabs' },
};
const BASE_CROWN = {
  base: { floors: 1.6, note: 'a tall lobby storey under the shaft, in the wall\'s mid tone less 0.03 (never darker: its join with the shaft is a long edge), with the trim as a lintel line and no ribbon: punched panes only', wall_lum_offset: -0.03 },
  crown: { floors: 2, note: 'the top two floors set back 6 percent each side, a cornice band in the trim tone (wall mid plus 0.03), panes at the tint\'s bright glass; lit panes are Rendering\'s and are not raised (a flash change)', setback: 0.06, cornice_lum_offset: 0.03 },
};
const DISTRICTS = {
  downtown: { look: 'downtown', facade_weights: { ribbon: 0.40, punched: 0.25, fins: 0.35 }, tint_weights: { steel: 0.2, brick: 0.15, graphite: 0.2, pine: 0.15, plum: 0.15, teal: 0.15 }, rule: 'fins on shafts of 40 floors or more, punched on stepped and crown towers, ribbon elsewhere' },
  mid_rise_west: { look: 'mid_rise', facade_weights: { punched: 0.55, ribbon: 0.30, fins: 0.15 }, tint_weights: { terracotta: 0.3, rose: 0.2, concrete: 0.15, spruce: 0.15, mauve: 0.1, slateblue: 0.1 }, rule: 'older: brick, rose and terracotta tints, punched windows' },
  mid_rise_east: { look: 'mid_rise', facade_weights: { ribbon: 0.55, fins: 0.25, punched: 0.20 }, tint_weights: { concrete: 0.3, slateblue: 0.25, spruce: 0.15, mauve: 0.1, rose: 0.1, terracotta: 0.1 }, rule: 'newer: pale concrete and cool tints, ribbon windows' },
};

// ---- build the data
const out = { version: 1, note: 'The city looks\' palettes and facade types (docs/art/city-facades.md). Written by art/concepts/city/gen.mjs; do not edit by hand. Variety is hue and chroma at equal luminance: on downtown and mid_rise a pane may differ from its wall by at most 0.085 of relative luminance (render/core/look.gd PATTERN_BUDGET), and between any two neighbouring tones (glass against fin, spandrel against glass, cornice against shaft: Legal w05): every tone is within 0.04 of the mid tone of the wall, so no two differ by more than 0.08. Proposals pending Legal and Orb; Tools adds the schema.', budget: BUDGET, glass_step: GLASS_STEP, looks: {}, facades: FACADES, base_and_crown: BASE_CROWN, districts: DISTRICTS };
const checks = [], massChecks = [];
for (const look of ['downtown', 'mid_rise']) {
  out.looks[look] = TINTS[look].map(t => {
    const L = WALL_LUM[look], wl = solve(L.light, t.wall[1], t.wall[0]), wm = solve(L.mid, t.wall[1], t.wall[0]), ws = solve(L.shadow, t.wall[1], t.wall[0]);
    const gd = solve(L.mid - GLASS_STEP, t.glass[1], t.glass[0]), gb = solve(L.mid + GLASS_STEP, t.glass[1], t.glass[0]);
    const trim = solve(L.mid + 0.03, t.trim[1], t.trim[0]), spandrelRibbon = solve(L.mid - 0.02, t.wall[1], t.wall[0]), spandrel = solve(L.mid - 0.03, t.wall[1], t.wall[0]), fin = solve(L.mid - 0.03, t.wall[1], t.wall[0]), finSun = solve(L.mid + 0.03, t.wall[1], t.wall[0]), base = solve(L.mid - 0.03, t.wall[1], t.wall[0]);
    const tones = { wall: wm, glass_dark: gd, glass_bright: gb, spandrel_ribbon: spandrelRibbon, spandrel_punched: spandrel, fin, fin_sun: finSun, trim, cornice: trim, base }, names = Object.keys(tones);
    let worst = 0, worstPair = '';
    for (let i = 0; i < names.length; i++) for (let j = i + 1; j < names.length; j++) { const d = Math.abs(luminance(tones[names[i]]) - luminance(tones[names[j]])); if (d > worst) { worst = d; worstPair = `${names[i]} / ${names[j]}`; } }
    const d1 = Math.abs(luminance(gd) - luminance(wm)), d2 = Math.abs(luminance(gb) - luminance(wm)), hueGap = Math.abs(((t.glass[0] - t.wall[0] + 540) % 360) - 180);
    const mass = { scale: +(L.shadow / L.mid).toFixed(3), wall: massOf(wm, look), glass_dark: massOf(gd, look), glass_bright: massOf(gb, look), trim: massOf(trim, look) };
    mass.read_as = { wall: readAs(mass.wall), glass: readAs(mass.glass_dark) }; mass.wall_chroma = +lchOf(mass.wall)[1].toFixed(3);
    massChecks.push({ look, id: t.id, mass });
    checks.push({ look, id: t.id, glass_dark_vs_wall: d1, glass_bright_vs_wall: d2, hue_gap: hueGap, max_pair: worst, worst_pair: worstPair });
    return { id: t.id, name: t.name, wall: { light: wl, mid: wm, shadow: ws }, glass: { dark: gd, bright: gb }, trim, spandrel, fin, _spandrel_ribbon: spandrelRibbon, _fin_sun: finSun, _cornice: trim, _base: base, oklch: { wall: t.wall, glass: t.glass }, measured: { glass_dark_vs_wall_mid: +d1.toFixed(3), glass_bright_vs_wall_mid: +d2.toFixed(3),  hue_gap_wall_to_glass_deg: Math.round(hueGap) }, _as_massed: mass, _neighbours: { max_difference_between_any_two_tones: +worst.toFixed(3), worst_pair: worstPair, cap: BUDGET } };
  });
}
const flagged = massChecks.filter(m => ['olive', 'brown'].includes(m.mass.read_as.wall) || ['olive', 'brown'].includes(m.mass.read_as.glass));
const closest = {};
for (const look of ['downtown', 'mid_rise']) { const ms = massChecks.filter(m => m.look === look); let min = 99, pair = ''; for (let i = 0; i < ms.length; i++) for (let j = i + 1; j < ms.length; j++) { const d = dE00(ms[i].mass.wall, ms[j].mass.wall); if (d < min) { min = d; pair = ms[i].id + ' / ' + ms[j].id; } } closest[look] = { pair, dE00: +min.toFixed(1) }; }
out._mass_summary = { rule: 'tones scaled by lum(shadow)/lum(mid) in linear light (building.gdshader 7b)', closest_walls_as_massed: closest, none_read_olive_or_brown: flagged.length === 0 };
writeFileSync(join(ROOT, 'data', 'art', 'city-looks.json'), JSON.stringify(out, null, 2) + '\n');
const bad = checks.filter(c => c.glass_dark_vs_wall > BUDGET || c.glass_bright_vs_wall > BUDGET || c.max_pair > BUDGET);

// ---- the sheet: a street of today's towers against a street of the proposed ones, for each look, and the tints with their numbers
const text = (x, y, t, { size = 12, weight = 400, fill = '#1b1428', anchor = 'start', op = 1 } = {}) => `<text x="${F(x)}" y="${F(y)}" font-family="'Segoe UI', system-ui, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${op}">${String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;')}</text>`;
const rect = (x, y, w, h, fill, extra = '') => `<rect x="${F(x)}" y="${F(y)}" width="${F(w)}" height="${F(h)}" fill="${fill}" ${extra}/>`;
const hash = n => { let x = Math.imul(n ^ 0x9e3779b9, 0x85ebca6b); x ^= x >>> 13; x = Math.imul(x, 0xc2b2ae35); x ^= x >>> 16; return (x >>> 0) / 4294967296; };
const mixc = (a, b, t) => { const A = toOklab(a), B = toOklab(b); return fromOklab(A.map((v, i) => v + (B[i] - v) * t)); };
const clampPane = (wall, glass) => { const d = Math.abs(luminance(glass) - luminance(wall)); return mixc(wall, glass, Math.min(1, BUDGET / Math.max(d, 1e-4))); };   // what the shader does
function tower({ x, y, w, h, t, facade, today, look, seed }) {
  // y is the ground; h the height; floors of 14 px
  const FL = 14, wall = today ? today.wall : t.wall.mid, shade = today ? today.shadow : t.wall.shadow, light = today ? today.light : t.wall.light;
  const gd = today ? today.gd : t.glass.dark, gb = today ? today.gb : t.glass.bright;
  const top = y - h; let s = rect(x, top, w, h, wall) + rect(x + w * 0.86, top, w * 0.14, h, shade) + rect(x, top, w * 0.05, h, light);
  const floors = Math.floor(h / FL), cell = w * 0.86;
  const pane = (px, py, pw, ph, lit) => rect(px, py, pw, ph, lit ? '#f3cf86' : clampPane(wall, hash(seed + px * 7 + py) > 0.82 ? gb : gd));
  const baseF = today ? 0 : 1, crownF = today ? 0 : 2;
  for (let f = 0; f < floors; f++) {
    const fy = y - (f + 1) * FL, inBase = f < baseF, inCrown = f >= floors - crownF;
    if (today) { for (let k = 0; k < 3; k++) s += pane(x + 3 + k * (cell / 3), fy + 3, cell / 3 - 2, FL - 6, hash(seed + f * 3 + k) > 0.94); continue; }
    if (inBase) { s += rect(x, fy, w, FL, mixc(wall, '#000000', 0.12)); for (let k = 0; k < 3; k++) s += pane(x + 4 + k * (cell / 3), fy + 3, cell / 3 - 8, FL - 6, false); continue; }
    if (inCrown) { s += rect(x + w * 0.06, fy, w * 0.88, FL, wall) + rect(x + w * 0.06, fy, w * 0.88, 2, t.trim); for (let k = 0; k < 3; k++) s += pane(x + w * 0.06 + 3 + k * (cell / 3), fy + 4, cell / 3 - 4, FL - 6, false); continue; }
    if (facade === 'ribbon') { s += rect(x + 2, fy + 2, cell - 2, FL * 0.55, clampPane(wall, f % 5 === 0 ? gb : gd)); s += rect(x + 2, fy + 2 + FL * 0.55, cell - 2, FL * 0.45 - 2, t.spandrel); }
    else if (facade === 'punched') { for (let k = 0; k < 4; k++) s += pane(x + 3 + k * (cell / 4), fy + 2, cell / 4 * 0.5, FL * 0.5, hash(seed + f * 4 + k) > 0.95); s += rect(x + 1, fy + FL * 0.62, cell, FL * 0.3, t.spandrel); }
    else { s += rect(x + 2, fy + 1, cell - 2, FL - 2, clampPane(wall, f % 4 === 0 ? gb : gd)); for (let k = 0; k <= 4; k++) s += rect(x + 2 + k * ((cell - 6) / 4), fy, 3, FL, t.fin); }
  }
  return s;
}
function sheet() {
  const W = 1800, H = 1560; let b = rect(0, 0, W, H, '#dcd8e6') + rect(0, 0, W, 100, '#1b1428') + text(30, 44, 'The city\'s towers up close: palettes and facade types', { size: 30, weight: 700, fill: '#f4f0fa' }) + text(30, 70, 'Variety by hue and chroma at equal luminance: every pane, fin, spandrel, base and cornice is within 0.04 of its wall, so any two neighbouring elements differ by at most 0.08 of relative luminance (Rendering\'s contrast budget 0.085; Legal\'s w05). Concept art, working labels, pending Legal.', { size: 13, fill: '#cfc6e6' });
  let y0 = 118;
  for (const look of ['downtown', 'mid_rise']) {
    const tints = out.looks[look], TODAY = look === 'downtown' ? { wall: '#7f8896', shadow: '#4a5261', light: '#b8c0cc', gd: '#2c4a63', gb: '#6aa0c0' } : { wall: '#929aa7', shadow: '#5a6270', light: '#c6cdd7', gd: '#2c4a63', gb: '#6aa0c0' };
    b += rect(24, y0, W - 48, 700, '#e8e5ee', 'stroke="#1b1428" stroke-opacity="0.2"') + text(40, y0 + 30, look === 'downtown' ? 'downtown' : 'mid_rise', { size: 20, weight: 700 });
    b += text(40, y0 + 54, 'today: one grey and one glass, every tower the same grid', { size: 12, weight: 700, op: 0.7 });
    let x = 40; for (let i = 0; i < 10; i++) { const w = 70 + (i * 37 % 40), h = (look === 'downtown' ? 150 : 100) + (i * 53 % 80); b += tower({ x, y: y0 + 300, w, h, today: TODAY, look, seed: i * 31 }); x += w + 14; }
    b += text(40, y0 + 330, 'proposed: six tints and three facade types, with a lobby storey and a set-back crown', { size: 12, weight: 700, op: 0.7 });
    x = 40; const types = ['ribbon', 'punched', 'fins'];
    for (let i = 0; i < 10; i++) { const w = 70 + (i * 37 % 40), h = (look === 'downtown' ? 150 : 100) + (i * 53 % 80); b += tower({ x, y: y0 + 600, w, h, t: tints[(i * 5 + 1) % 6], facade: types[(i * 7 + (look === 'mid_rise' ? 1 : 0)) % 3], look, seed: i * 31 + 7 }); x += w + 14; }
    // the tints
    tints.forEach((t, i) => {
      const tx = 1140 + (i % 3) * 218, ty = y0 + 50 + Math.floor(i / 3) * 140;
      b += text(tx, ty, t.name, { size: 12, weight: 700 });
      [['wall', t.wall.light], ['', t.wall.mid], ['', t.wall.shadow], ['glass', t.glass.dark], ['', t.glass.bright], ['trim', t.trim]].forEach(([lab, c], j) => { b += rect(tx + j * 33, ty + 8, 30, 30, c, 'stroke="#1b1428" stroke-opacity="0.3" stroke-width="0.8"'); });
      b += text(tx, ty + 58, `neighbours at most ${t._neighbours.max_difference_between_any_two_tones.toFixed(3)} (cap 0.085)`, { size: 10.5, op: 0.75 }) + text(tx, ty + 72, `hue gap ${t.measured.hue_gap_wall_to_glass_deg} deg`, { size: 10.5, op: 0.6 });
      const m = t._as_massed;
      [m.wall, m.glass_dark, m.glass_bright, m.trim].forEach((c, j) => { b += rect(tx + j * 33, ty + 80, 30, 22, c, 'stroke="#1b1428" stroke-opacity="0.3" stroke-width="0.8"'); });
      b += text(tx, ty + 116, `massed x${m.scale}: wall ${m.read_as.wall}, glass ${m.read_as.glass}`, { size: 9.5, weight: 700, op: 0.75 });
    });
    y0 += 716;
  }
  b += text(40, y0 + 6, 'Facade types: ribbon (bands and thin piers), punched (panes with spandrels: stone and brick), fins (tall glass between projecting fins). Which district takes which is in data/art/city-looks.json "districts". Every tone is within 0.04 of its wall, so any two neighbours are at most 0.08 apart (Legal\'s w05).', { size: 12.5 });
  writeFileSync(join(ROOT, 'art', 'concepts', 'city', 'city-palettes.svg'), `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">${b}</svg>`);
}
sheet();
console.log('as massed: olive/brown flagged', flagged.length, JSON.stringify(closest), '|', 'wrote data/art/city-looks.json and city-palettes.svg;', checks.length, 'tints; over budget:', Math.max(...checks.map(c => c.max_pair)).toFixed(3), 'over budget:', bad.length);
