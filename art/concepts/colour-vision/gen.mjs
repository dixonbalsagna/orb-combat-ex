// Origin: procedural sheet and data writer for the colour-vision presets (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-06. Human direction: Orb, via the EP (docs/ep/vision.md, 2026-10-06: "some accessibility options for colorblind").
// Run from the repo root:  node art/concepts/colour-vision/gen.mjs
// Writes colour-vision-presets.svg here and data/art/colour-vision.json. The default look does not change: a preset only remaps the two lane colours (the auras).

import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dE00, simulate, hsl, toLab, MACHADO } from '../sky/colour.mjs';
import { KEYS, moodSky } from '../sky/keys.mjs';
import { text, rect, paras, header, BG, F, still, SIM_DEFS } from '../sky/draw.mjs';
import { CUES, HUD_CUES, DEFAULT_LANES, cuesFor, FRESH } from './cues.mjs';
import { scoreOne, FAMILY } from './search.mjs';
import { MARKS, patternData } from './marks.mjs';

const OUT = dirname(fileURLToPath(import.meta.url)), ROOT = join(OUT, '..', '..', '..');
const KINDS = ['protan', 'deutan', 'tritan'];
const NAME = { protan: 'Protan (no red cones: reds look dark, red and green confuse)', deutan: 'Deutan (no green cones: red and green confuse)', tritan: 'Tritan (no blue cones: blue and green, yellow and violet confuse)' };
const ORIGIN = '<!-- Origin: procedural colour-vision sheet written by art/concepts/colour-vision/gen.mjs (deterministic, no external images or fonts), Art Director session (Claude, claude-sonnet-5-5), 2026-10-06; prompt record art/prompts/ART-0017-dynamic-sky-and-colour-vision.md -->' + String.fromCharCode(10);

// the presets: the first round's pair, revised only where UI's own wound sets (ui/data/colour_vision.json, with "fresh" now the neutral #dfe6f0) put a lane colour too close to a mark
const PRESET = {
  protan: { P: '#30a6a6', A: '#6b0bcb', how: 'the first round\'s pair with the Protagonist\'s aura darkened a little (#46b9b9 to #30a6a6): it sat 13 from UI\'s neutral "fresh" mark, now 18.5' },
  deutan: { P: '#35b6ab', A: '#5b0bcb', how: 'unchanged: it clears UI\'s marks (18.3 and 32.3)' },
  tritan: { P: '#9c90d5', A: '#6b0bcb', how: 'a revised pair (was #b7aaf8 and #7243d0): the first Protagonist aura sat 13.5 from UI\'s neutral "fresh" mark, now 20.4' },
};
function metrics(P, A, kind) {
  const p = scoreOne(P, kind), a = scoreOne(A, kind);
  return { between: dE00(p.x, a.x), P: { cue: p.dCue, cueName: p.wc, hl: p.dHL, all: p.dSky }, A: { cue: a.dCue, cueName: a.wc, hl: a.dHL, all: a.dSky } };
}
const MET = { default: {} };
for (const k of ['default', ...KINDS]) { MET.default[k] = metrics(DEFAULT_LANES.protagonist.aura, DEFAULT_LANES.rival.aura, k); }
for (const k of KINDS) MET[k] = metrics(PRESET[k].P, PRESET[k].A, k);

function uiSets() {
  const out = {};
  for (const k of KINDS) {
    const set = cuesFor(k), keep = ['wound fresh', 'wound bruised', 'wound battered', 'wound broken'], e = keep.map(n => [n, set[n]]);
    let mn = 99, w = '';
    for (let i = 0; i < e.length; i++) for (let j = i + 1; j < e.length; j++) { const d = dE00(simulate(e[i][1], k), simulate(e[j][1], k)); if (d < mn) { mn = d; w = `${e[i][0]} / ${e[j][0]}`; } }
    out[k] = { stage_set: Object.fromEntries(e), weakest_pair_dE00: +mn.toFixed(1), weakest_pair: w, internal_vs_fresh_dE00: +dE00(simulate(set['wound internal'], k), simulate(FRESH, k)).toFixed(1) };
  }
  return { fresh: FRESH, confirmed: 'UI\'s stage sets are confirmed: every pair is 20 or more apart under its own vision (Art\'s check: protan 26.1, deutan 20.9, tritan 22.0; UI reported 26.1, 19.9, 22.0)', per_preset: out };
}
function writeData() {
  const d = {
    version: 1,
    note: 'Colour-vision presets for the two launch fighters (docs/art/colour-vision.md). Written by art/concepts/colour-vision/gen.mjs; do not edit by hand. The default look is unchanged: a preset remaps only the two lane colours (the auras). The body colour (col) pair is 48 or more apart (CIEDE2000) under every preset, so it is not remapped. UI owns the setting and the cue remap; Tools adds the schema.',
    simulation: { model: 'Machado, Oliveira and Fernandes 2009, severity 1.0, applied in linear RGB', matrices: MACHADO },
    default: { protagonist: DEFAULT_LANES.protagonist, rival: DEFAULT_LANES.rival },
    presets: Object.fromEntries(KINDS.map(k => [k, { protagonist: { col: DEFAULT_LANES.protagonist.col, aura: PRESET[k].P }, rival: { col: DEFAULT_LANES.rival.col, aura: PRESET[k].A }, chosen_by: PRESET[k].how, measured_dE00_under_this_vision: { between_the_two: +MET[k].between.toFixed(1), protagonist: { to_wound_and_guard_marks: +MET[k].P.cue.toFixed(1), nearest_mark: MET[k].P.cueName, to_sky_near_the_fighters: +MET[k].P.hl.toFixed(1), to_any_sky_band: +MET[k].P.all.toFixed(1) }, rival: { to_wound_and_guard_marks: +MET[k].A.cue.toFixed(1), nearest_mark: MET[k].A.cueName, to_sky_near_the_fighters: +MET[k].A.hl.toFixed(1), to_any_sky_band: +MET[k].A.all.toFixed(1) } } }])),
    _non_colour_marks: MARKS,
    _biome_patterns: { note: 'A pattern per biome on the planet strip (colour only today), 12 by 12 tiles; ink is the base colour moved 0.2 in OKLab lightness away from the middle. Sheet: art/concepts/colour-vision/biome-patterns.svg.', ...patternData() },
    _ui_wound_sets: uiSets(),
    _guard_cue: { colour: '#5aaaff', stays_in_every_preset: true, why: 'the defensive stance colour is not remapped by any preset, and every preset aura is at least ' + Math.min(...KINDS.flatMap(k => [scoreOne(PRESET[k].P, k), scoreOne(PRESET[k].A, k)].map(x => { const g = dE00(simulate('#5aaaff', k), x.x); return g; }))).toFixed(0) + ' from it under its own vision (CIEDE2000)' },
    cue_set: { wound_and_guard_marks: CUES, hud_chips_for_ui_to_check: HUD_CUES, source: 'ui/core/ui_look.gd (2026-10-06)' },
    hue_families: FAMILY,
    rule_for_future_fighters: [
      'Give every fighter a lane colour and an aura colour in a hue family agreed with Legal (the Anti-hero\'s is violet, hue 260 to 320; never white, red, orange, gold or yellow for an aura).',
      'Any two fighters that can meet must stay at CIEDE2000 of 25 or more apart by default and 20 or more apart under each of protan, deutan and tritan; a lightness gap of at least 25 L* between them is the surest way to get there.',
      'Each lane colour must stay at 20 or more (default) and 14 or more (simulated) from the wound and guard marks and from the sky near the fighters (the horizon and lower bands of every key and mood extreme in data/art/sky.json).',
      'Never carry meaning in colour alone: the aura is always drawn with a dark keyline, and each fighter has a non-colour mark (a ring pattern or a chip shape) so a fighter is told apart with the colour turned off.',
      'Every new fighter ships a protan, deutan and tritan triple, found by art/concepts/colour-vision/search.mjs in the fighter\'s own hue family and checked with art/concepts/colour-vision/check.mjs; Art approves it before it enters data/art/colour-vision.json.',
    ],
  };
  writeFileSync(join(ROOT, 'data', 'art', 'colour-vision.json'), JSON.stringify(d, null, 2) + '\n');
}

function sheet() {
  const rowH = 400, W = 1800, H = 124 + 3 * rowH + 440;
  let b = rect(0, 0, W, H, '#dcd8e6') + header('Colour-blind options: the two fighters\' lane colours for each preset', 'Orb (2026-10-06): colour-blind options yes, stylistic palette changes no. The default look does not change. A preset remaps only the lane colours (the auras) so the two fighters stay apart from each other, from the sky and from the wound and guard marks. Every picture on the right is shown through the simulated vision. Working labels, pending Legal review.', W);
  KINDS.forEach((k, r) => {
    const y0 = 124 + r * rowH, m = MET[k], d = MET.default[k], P = PRESET[k];
    b += rect(24, y0, W - 48, rowH - 10, BG, 'stroke="#1b1428" stroke-opacity="0.2"') + text(40, y0 + 26, NAME[k], { size: 16, weight: 700 });
    // swatches: default and preset, as designed and as seen
    const sw = (x, y, c, lab) => rect(x, y, 56, 40, c, 'stroke="#1b1428" stroke-opacity="0.45"') + text(x, y + 56, lab, { size: 10, op: 0.8 }) + text(x, y + 68, c, { size: 10, weight: 600 });
    b += text(40, y0 + 56, 'Protagonist aura', { size: 12, weight: 700 }) + sw(40, y0 + 64, DEFAULT_LANES.protagonist.aura, 'default') + sw(120, y0 + 64, simulate(DEFAULT_LANES.protagonist.aura, k), 'default, seen') + sw(200, y0 + 64, P.P, 'preset') + sw(280, y0 + 64, simulate(P.P, k), 'preset, seen');
    b += text(40, y0 + 160, 'Rival aura', { size: 12, weight: 700 }) + sw(40, y0 + 168, DEFAULT_LANES.rival.aura, 'default') + sw(120, y0 + 168, simulate(DEFAULT_LANES.rival.aura, k), 'default, seen') + sw(200, y0 + 168, P.A, 'preset') + sw(280, y0 + 168, simulate(P.A, k), 'preset, seen');
    // the cue marks as seen
    b += text(40, y0 + 264, 'The wound and guard marks, as seen:', { size: 11, weight: 700 });
    Object.entries(CUES).forEach(([n, c], i) => { b += rect(40 + i * 54, y0 + 272, 48, 24, simulate(c, k), 'stroke="#1b1428" stroke-opacity="0.45"') + text(40 + i * 54, y0 + 310, n.replace('wound ', ''), { size: 9, op: 0.75 }); });
    // the numbers
    b += text(360, y0 + 46, 'CIEDE2000 under this vision', { size: 11, weight: 700 }) + text(360, y0 + 60, '(green: clear; red: close)', { size: 10, op: 0.7 });
    const cell = (x, y, t, bad) => rect(x, y, 54, 20, bad ? '#d4423a' : '#2f6f4f', 'opacity="0.85"') + text(x + 27, y + 14, t, { size: 11, weight: 700, fill: '#fff', anchor: 'middle' });
    ['', 'between the two', 'Protagonist to marks', 'Rival to marks', 'Protagonist to sky', 'Rival to sky'].forEach((h, i) => { if (h) b += text(414 + (i - 1) * 58, y0 + 84, h, { size: 8.5, weight: 700, op: 0.8 }).replace('<text', '<text transform="rotate(-28 ' + F(414 + (i - 1) * 58) + ' ' + F(y0 + 84) + ')"'); });
    [['default', d], ['preset', m]].forEach(([lab, q], j) => { const y = y0 + 96 + j * 28; b += text(340, y + 14, lab, { size: 12, weight: 700 }); [q.between, q.P.cue, q.A.cue, q.P.hl, q.A.hl].forEach((v, i) => { b += cell(400 + i * 58, y, v.toFixed(0), v < (i === 0 ? 25 : 14)); }); });
    b += paras(340, y0 + 168, `${P.how}. The weakest mark for the preset Protagonist is ${m.P.cueName} (${m.P.cue.toFixed(1)}); for the rival ${m.A.cueName} (${m.A.cue.toFixed(1)}); the marks are UI's own set for this preset. Default: the Protagonist's aura is ${d.P.cue.toFixed(0)} from ${d.P.cueName} and the rival's ${d.A.cue.toFixed(0)} from ${d.A.cueName}.`, 52, 11, 14, { op: 0.9 });
    // the stills through the simulation
    const skies = [['Sunset', KEYS[2].bands], ['Noon', KEYS[0].bands], ['Night', KEYS[3].bands]];
    b += text(700, y0 + 46, 'Through the simulated vision: default colours, then the preset, over three skies', { size: 11, weight: 700 });
    skies.forEach(([nm, bands], i) => { [['default', DEFAULT_LANES.protagonist.aura, DEFAULT_LANES.rival.aura], ['preset', P.P, P.A]].forEach(([lab, ap, aa], j) => { const x = 700 + (i * 2 + j) * 180, y = y0 + 54; b += `<g filter="url(#sim-${k})">${still(x, y, 174, 150, bands, ap, aa, { stars: nm === 'Night' ? 1 : 0 })}</g>` + text(x + 2, y + 164, `${nm}, ${lab}`, { size: 10.5, weight: 600 }); }); });
    b += text(700, y0 + 240, 'The same preset as designed (typical vision), for the people who build and check it:', { size: 11, weight: 700 });
    skies.forEach(([nm, bands], i) => { b += still(700 + i * 180, y0 + 248, 174, 100, bands, P.P, P.A, { stars: nm === 'Night' ? 1 : 0 }) + text(702 + i * 180, y0 + 360, nm, { size: 10, op: 0.75 }); });
    b += paras(1250, y0 + 262, `The Protagonist's preset aura is ${P.P} (hue ${hsl(P.P)[0]}) and the rival's ${P.A} (hue ${hsl(P.A)[0]}): each stays inside its own hue family (the Protagonist cool, the rival violet), and the pair is split mostly by lightness, the one thing every kind of colour blindness still sees.`, 60, 11, 14, { op: 0.9 });
  });
  const y = 124 + 3 * rowH;
  b += text(24, y + 14, 'What this does not solve, and the rule for future fighters', { size: 15, weight: 700 });
  b += paras(24, y + 36, 'Honest limits. The wound marks and the guard are mostly pale and cool (cyan, blue, light blue), so a lane colour that is also cool lands near them for some viewers; under protan vision the best any lane in its own hue family reaches is about 14 from the marks and the sky. Two things carry the rest. First, the dark keyline (#0a0d14) round every aura, which reads on any sky for every viewer. Second, the shapes: the wound stages are shapes as well as tints (docs/design/damage-model.md), and the fighters differ in silhouette. The standing conflict in the first round (the Protagonist\'s aura was exactly the "fresh" wound colour) is fixed: UI made "fresh" the neutral #dfe6f0. One thing is left: "internal" (#bfeeff) is near "fresh" (only 4 to 14 apart under the simulations); give it a shape (a double ring) rather than a hue.', 230, 12, 16, { op: 0.9 });
  b += text(24, y + 148, 'The rule for future fighters', { size: 14, weight: 700 });
  ['Give every fighter a lane colour and an aura colour in a hue family agreed with Legal; any two fighters that can meet stay at CIEDE2000 of 25 or more apart by default and 20 or more under each simulation (a lightness gap of 25 L* or more is the surest way).', 'Each lane colour stays at 20 or more (default) and 14 or more (simulated) from the wound and guard marks and from the sky near the fighters (the horizon and lower bands in data/art/sky.json).', 'Never colour alone: the aura keeps its dark keyline, and each fighter has a non-colour mark (a ring pattern or a chip shape).', 'Every new fighter ships a protan, deutan and tritan triple found by search.mjs in the fighter\'s hue family and checked with check.mjs (node art/concepts/colour-vision/check.mjs #hex #hex ...), approved by Art before it enters data/art/colour-vision.json.'].forEach((t, i) => { b += paras(24, y + 170 + i * 34, `${i + 1}. ${t}`, 230, 12, 15, { op: 0.9 }); });
  b += text(24, y + 320, 'Data: data/art/colour-vision.json (presets, measured numbers, the cue set and the rule). The simulation is Machado, Oliveira and Fernandes (2009), severity 1.0, in linear RGB; the SVG filters on this sheet use the same matrices. UI owns the setting and the cue remap; Tools adds the schema.', { size: 12, weight: 600 });
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${SIM_DEFS}${b}</svg>`;
}

writeData();
writeFileSync(join(OUT, 'colour-vision-presets.svg'), ORIGIN + sheet());
console.log('wrote colour-vision-presets.svg and data/art/colour-vision.json');
for (const k of KINDS) console.log(k, PRESET[k].P, PRESET[k].A, 'between', MET[k].between.toFixed(1), '| P marks', MET[k].P.cue.toFixed(1), 'sky', MET[k].P.hl.toFixed(1), '| A marks', MET[k].A.cue.toFixed(1), 'sky', MET[k].A.hl.toFixed(1), '|', PRESET[k].how);
