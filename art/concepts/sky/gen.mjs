// Origin: procedural sheet and data writer for the dynamic sky (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-06. Human direction: Orb, via the EP (docs/ep/vision.md, 2026-10-06).
// Run from the repo root:  node art/concepts/sky/gen.mjs
// Writes sky-keys.svg, sky-mood.svg, sky-stills.svg, sky-contrast.svg here, and data/art/sky.json (Art owns data/art/).
// The sky is directed inside the game's existing look: the sunset bands (render/core/look.gd SKY) are the key SUNSET and the sky at the start of a match.

import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { luminance, contrast, dE00, toLab } from './colour.mjs';
import { KEYS, BANDS, START, BLEND, WEIGHTS, BUDGET, skyAt, moodSky, meanLum, lumsAt, slewStep, EMBER, SMOKE, ASH, DEEP } from './keys.mjs';
import { text, rect, paras, header, BG, F, still, skyPanel, SIM_DEFS } from './draw.mjs';

const OUT = dirname(fileURLToPath(import.meta.url)), ROOT = join(OUT, '..', '..', '..');
const AURA = { P: '#8fd6ff', A: '#9a80d8' };
const ORIGIN = '<!-- Origin: procedural sky sheet written by art/concepts/sky/gen.mjs (deterministic, no external images or fonts), Art Director session (Claude, claude-sonnet-5-5), 2026-10-06; prompt record art/prompts/ART-0017-dynamic-sky-and-colour-vision.md -->' + String.fromCharCode(10);
const wrapSvg = (w, h, inner) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${inner}</svg>`;
const Lstar = h => toLab(h)[0].toFixed(0);

// ---------------------------------------------------------------------------------------------------------- the numbers we measure
const DRIFT = 0.0125;   // cycles a minute (an 80 minute cycle)
const MOOD_MIN_S = { frenzy: 30, ruin: 120, glow: 50 };   // the fastest a mood driver may go from 0 to 1
function traverse(from, to, dt = 1 / 30) {
  let cur = from, t = 0;
  while (t < 1200) { const d = ((to - cur + 1.5) % 1) - 0.5; if (Math.abs(d) < 5e-4) break; cur = slewStep(cur, to, dt); t += dt; }
  return t;
}
const segSeconds = KEYS.map((a, i) => { const b = KEYS[(i + 1) % KEYS.length]; return { from: a.id, to: b.id, s: traverse((a.phase + a.hold) % 1, (b.phase - b.hold + 1) % 1) }; });
const cycleSeconds = segSeconds.reduce((s, x) => s + x.s, 0);
function stress() {
  let p = START.phase, t = 0, tgt = START.phase; const dt = 1 / 60, hist = [];
  for (let i = 0; i < 60 * 180; i++) { t += dt; const dir = (Math.floor(t / 3) % 2 === 0) ? 1 : -1; tgt = (tgt + dir * 0.25 * dt + 1) % 1; p = slewStep(p, tgt, dt); const l = lumsAt(p); hist.push([BANDS.reduce((s, k) => s + WEIGHTS[k] * l[k], 0), ...BANDS.map(k => l[k])]); }
  let wm = 0, wb = 0, pairs = 0;
  for (let i = 60; i < hist.length; i++) { wm = Math.max(wm, Math.abs(hist[i][0] - hist[i - 60][0])); for (let j = 1; j < 5; j++) wb = Math.max(wb, Math.abs(hist[i][j] - hist[i - 60][j])); }
  return { mean: wm, band: wb, pairs };
}
const ST = stress();
function lapMin(P, A) { let wp = [99], wa = [99]; for (let i = 0; i < 4000; i++) { const ph = i / 4000, b = skyAt(ph).bands; for (const bd of BANDS) { const dp = dE00(P, b[bd]), da = dE00(A, b[bd]); if (dp < wp[0]) wp = [dp, ph, bd]; if (da < wa[0]) wa = [da, ph, bd]; } } return { P: wp, A: wa }; }
const LAP = lapMin(AURA.P, AURA.A);
const mlabel = m => Object.keys(m).length ? Object.entries(m).map(([k, v]) => `${k} ${v}`).join(' + ') : 'calm';
function moodMin(P, A) { let wp = [99], wa = [99]; for (const k of KEYS) for (const m of [{}, { frenzy: 1 }, { ruin: 1 }, { frenzy: 1, ruin: 1 }, { glow: 1 }, { frenzy: 1, ruin: 1, glow: 1 }, { ruin: 0.5 }, { frenzy: 0.5, glow: 0.5 }]) { const b = moodSky(k.bands, m); for (const bd of BANDS) { const dp = dE00(P, b[bd]), da = dE00(A, b[bd]); if (dp < wp[0]) wp = [dp, k.id, bd, mlabel(m)]; if (da < wa[0]) wa = [da, k.id, bd, mlabel(m)]; } } return { P: wp, A: wa }; }
const MOOD = moodMin(AURA.P, AURA.A);

// ---------------------------------------------------------------------------------------------------------- the data
function writeData() {
  const d = {
    version: 1,
    note: 'The dynamic sky, directed by Art (docs/art/dynamic-sky.md). Written by art/concepts/sky/gen.mjs from art/concepts/sky/keys.mjs; do not edit by hand. The sky stays inside the game\'s look: four bands, top to horizon, the way render/core/look.gd SKY has them. The key "sunset" IS the current look and the sky at the start of a match. Rendering builds the sky from this file; Tools adds the schema.',
    bands: BANDS,
    anchors_half_screens: { horizon: 0, lower: 0.12, upper: 0.55, top: 1.45 },
    start: START,
    keys: KEYS.map(k => ({ id: k.id, phase: k.phase, hold: k.hold, stars: k.stars, bands: k.bands, note: k.note })),
    blend: {
      space: 'oklab', ease: 'smoothstep', hold: 'each key holds its colours for `hold` of a lap, then blends to the next key',
      path: 'per transition and band: lab (straight in OKLab) or lch+ / lch- (round the hue wheel one way or the other, linear in lightness and chroma), chosen so no blend passes through a grey or violet that sits on a lane colour',
      transitions: KEYS.map((a, i) => ({ from: a.id, to: KEYS[(i + 1) % KEYS.length].id, ...BLEND[i] })),
    },
    place: { cycles_per_lap: 1, phase_of: 'fract(start.phase + (camera_x - spawn_x) / lap_length)', per_pane: true, note: 'Flying once round the planet runs the whole cycle: noon, golden, sunset, night, dawn, noon. In split view each pane uses its own camera\'s place; the time drift and the mood are shared.' },
    time: { cycles_per_minute: DRIFT, cycle_minutes: 1 / DRIFT, note: 'Added to the place phase. A match that stays in one place goes from the sunset towards night over about 20 minutes; minute 8 is about 0.1 of a cycle on.' },
    rate_limit: {
      unit: 'relative luminance (WCAG: 0 black to 1 white) per second',
      total: BUDGET.total, place_and_time: BUDGET.place, mood: BUDGET.mood,
      how: 'The shown phase follows the target phase through slewStep (art/concepts/sky/keys.mjs): each frame it moves as far as it can without any band changing faster than place_and_time.band or the weighted mean faster than place_and_time.mean. Mood drivers ease at the rates in mood.min_seconds_0_to_1.',
      weights: WEIGHTS,
      measured: { seconds_for_one_lap_at_the_limit: Math.round(cycleSeconds), stress_test_worst_1s_mean: +ST.mean.toFixed(4), stress_test_worst_1s_band: +ST.band.toFixed(4), stress_test: 'target phase flying round at 0.25 cycles a second and reversing every 3 seconds, 180 seconds' },
      fastest_allowed: 'no band 0.05 a second, the weighted mean 0.02 a second, all drivers together; a general flash (WCAG 2.3.1) needs an opposing pair of 0.10 or more inside a second, so the sky can never make one',
    },
    mood: {
      inputs: { frenzy: '0 to 1, the fight\'s mood (Encounter and Combat supply it; Art does not define how it is measured)', ruin: '0 to 1, the share of the world destroyed (structures down and people lost), never above 1', glow: '0 to 1 for each burning town in view, with its direction' },
      min_seconds_0_to_1: MOOD_MIN_S,
      colours: { ember: EMBER, smoke: SMOKE, ash: ASH, deep: DEEP },
      frenzy: 'top toward deep by 18%, upper toward the top by 25%, lower toward deep by 10%, horizon toward ember by 10%',
      ruin: 'horizon and lower toward smoke by 60%, upper by 40%, the top toward ash by 25%; stars thin to 30% at 1',
      glow: 'the horizon band toward ember by 35% in a wide low glow over the burning town (about 0.22 of the screen wide and a third of the horizon band tall); nothing above the lower band',
      order: 'frenzy, then ruin, then glow, each applied to the key\'s bands',
      never: ['nothing fast: every driver is rate limited as above', 'no pulsing, flicker or beat-sync, no reaction to a single hit (that is the VFX flashes\' job)', 'never white, never a lightning flash', 'never grey toward violet: ruin darkens and warms (smoke) instead of greying']
    },
    readability: {
      lane_colours: AURA, rule: 'The two aura colours stay at CIEDE2000 of 24 or more from every key\'s four bands, 20 or more at every blended place, and 24 or more at every mood extreme; the aura is always drawn with a dark keyline (#0a0d14) so it also reads where a bright horizon (L 0.5 to 0.8) would match it.',
      measured: { at_keys_and_mood_extremes_min_dE00: { protagonist: +MOOD.P[0].toFixed(1), rival: +MOOD.A[0].toFixed(1) }, round_the_lap_min_dE00: { protagonist: +LAP.P[0].toFixed(1), rival: +LAP.A[0].toFixed(1) } },
    },
  };
  writeFileSync(join(ROOT, 'data', 'art', 'sky.json'), JSON.stringify(d, null, 2) + '\n');
}

// ---------------------------------------------------------------------------------------------------------- sheet 1: the keys, the blend around the planet, the drift
function keysSheet() {
  const W = 1800, H = 1500;
  let b = rect(0, 0, W, H, '#dcd8e6') + header('The dynamic sky: the keys, the blend round the planet, the slow drift', 'Orb (2026-10-06): the sky is dynamic and changes colour, driven by where you are on the planet, the fight\'s mood and damage, and time passing. Inside the game\'s look: the sunset bands are the reference and the sky at the start of a match; the other keys extend them. Working labels, pending Legal review.', W);
  // 1. the five keys as swatch strips
  b += text(24, 136, '1. The keys (top to horizon). The sunset is the current look (render/core/look.gd SKY), unchanged.', { size: 15, weight: 700 });
  KEYS.forEach((k, i) => {
    const x0 = 24 + i * 354;
    b += rect(x0, 148, 346, 330, BG, 'stroke="#1b1428" stroke-opacity="0.2"') + text(x0 + 10, 170, `${k.id[0].toUpperCase() + k.id.slice(1)}${k.id === 'sunset' ? ' (the current look)' : ''}`, { size: 15, weight: 700 }) + text(x0 + 336, 170, `lap ${k.phase.toFixed(2)}`, { size: 11, anchor: 'end', op: 0.7 });
    b += skyPanel(x0 + 10, 180, 130, 160, k.bands, { stars: k.stars });
    BANDS.slice().reverse().forEach((bd, j) => { const y = 180 + j * 40, c = k.bands[bd]; b += rect(x0 + 150, y, 34, 34, c, 'stroke="#1b1428" stroke-opacity="0.4"') + text(x0 + 192, y + 14, `${bd} ${c}`, { size: 11.5, weight: 600 }) + text(x0 + 192, y + 29, `L* ${Lstar(c)}, relative lum. ${luminance(c).toFixed(2)}`, { size: 10.5, op: 0.7 }); });
    b += paras(x0 + 10, 362, k.note, 56, 11, 14, { op: 0.9 });
    b += text(x0 + 10, 462, `mean luminance ${meanLum(k.bands).toFixed(3)}, stars ${k.stars}`, { size: 10.5, op: 0.7 });
  });
  // 2. the blend round the planet
  b += text(24, 508, '2. Flying once round the planet runs the whole cycle: the sky tells you where you are (pillar 1)', { size: 15, weight: 700 });
  const px = 24, pw = 1752, N = 160;
  for (let i = 0; i < N; i++) { const ph = i / N, s = skyAt(ph); b += skyPanel(px + i * pw / N, 522, pw / N + 1.6, 170, s.bands, { plain: true, horizonAt: 0.7 }); }
  const hyP = 522 + 170 * 0.7; b += rect(px, hyP, pw, 170 - 170 * 0.7, '#262a35');
  for (let i = 0; i < 150; i++) { const bx = px + i * pw / 150 + 2, bh = 8 + ((i * 37) % 23); b += rect(bx, hyP - bh, pw / 150 - 3, bh, '#20232d'); }
  for (let i = 0; i < 260; i++) { const ph = (i * 0.61803) % 1, st = skyAt(ph).stars; if (st < 0.05) continue; b += `<circle cx="${F(px + ph * pw)}" cy="${F(522 + ((i * 53) % 97) / 97 * 170 * 0.6)}" r="${i % 5 === 0 ? 1.3 : 0.8}" fill="#e9eefc" opacity="${F(0.75 * st)}"/>`; }
  KEYS.forEach(k => { const x = px + k.phase * pw; b += `<line x1="${F(x)}" y1="522" x2="${F(x)}" y2="710" stroke="#1b1428" stroke-width="1.5"/>` + text(x + 4, 706, `${k.id} ${k.phase.toFixed(2)}`, { size: 11, weight: 700 }); });
  b += `<line x1="${F(px + START.phase * pw)}" y1="692" x2="${F(px + START.phase * pw)}" y2="716" stroke="#2f6f4f" stroke-width="4"/>` + text(px + START.phase * pw + 6, 722, 'a match starts here (the sunset)', { size: 11, weight: 700, fill: '#2f6f4f' });
  b += paras(24, 742, 'Phase of a place = fract(start phase + (camera x minus spawn x) / lap length): a full cycle per lap, so the same longitude is always the same time of day. Each key holds its colours for a little (the vertical lines are the keys), then blends to the next in OKLab with a smoothstep ease. Each band takes its own path: straight (lab) or round the hue wheel one way (lch+) or the other (lch-), chosen by search so no blend passes through a grey or a violet that would sit on a lane colour. In split view each pane uses its own camera\'s place.', 230, 12, 16, { op: 0.9 });
  b += text(24, 806, 'Blend path by transition and band', { size: 13, weight: 700 });
  KEYS.forEach((a, i) => { const nx = KEYS[(i + 1) % KEYS.length]; b += text(24 + i * 350, 826, `${a.id} to ${nx.id}`, { size: 12, weight: 600 }) + text(24 + i * 350, 842, BANDS.map(bd => `${bd} ${BLEND[i][bd]}`).join(', '), { size: 10.5, op: 0.8 }); });
  // 3. time drift
  b += text(24, 884, '3. Time: a slow drift on top of place. The same spot at minute 1 and minute 8 is not the same sky', { size: 15, weight: 700 });
  [0, 1, 2, 4, 8, 12, 20, 40].forEach((m, i) => {
    const ph = START.phase + DRIFT * m, s = skyAt(ph), x0 = 24 + i * 220;
    b += skyPanel(x0, 900, 208, 150, s.bands, { stars: s.stars }) + text(x0 + 4, 1070, `minute ${m}`, { size: 12, weight: 700 }) + text(x0 + 4, 1086, `phase +${(DRIFT * m).toFixed(3)}, mean lum. ${meanLum(s.bands).toFixed(2)}`, { size: 10.5, op: 0.7 });
  });
  b += paras(24, 1112, `The drift is ${DRIFT} of a cycle a minute (a full cycle in ${(1 / DRIFT).toFixed(0)} minutes). A fight that stays in one place goes from the sunset to deep dusk by minute 8 (about a tenth of a cycle on) and to night by about minute 20, then on toward dawn. At that rate the luminance changes by at most ${(DRIFT / 60 * 5.7).toFixed(4)} a second, a hundred times under the limit: it is never seen as a change, only as a different sky when you look again. It adds to the place phase and is shared by both panes.`, 230, 12, 16, { op: 0.9 });
  // 4. the rate limit
  b += text(24, 1204, '4. Nothing fast: the fastest allowed rate', { size: 15, weight: 700 });
  b += paras(24, 1226, `Relative luminance (WCAG: 0 black to 1 white). All drivers together: no band may change faster than ${BUDGET.total.band} a second and the weighted mean no faster than ${BUDGET.total.mean} a second. A general flash needs an opposing pair of 0.10 or more inside a second (docs/legal/photosensitivity-note.md), so at these rates the sky cannot make one, even with margin for the area and gamma readings. Place and time get ${BUDGET.place.band} per band and ${BUDGET.place.mean} for the mean; the mood drivers together get ${BUDGET.mood.band} and ${BUDGET.mood.mean}.`, 230, 12, 16, { op: 0.9 });
  b += paras(24, 1298, `How it is kept: the shown phase follows the target phase through slewStep (keys.mjs): each frame it moves as far as it can without breaking the budget, so flying round the planet at any speed (or back and forth) makes the sky catch up, never jump. Measured: running once round the whole cycle at the limit takes ${Math.round(cycleSeconds)} seconds (${segSeconds.map(s => `${s.from} to ${s.to} ${Math.round(s.s)} s`).join(', ')}); a stress test with the target phase flying round at 0.25 of a lap a second and reversing every 3 seconds for 3 minutes never changed the mean by more than ${ST.mean.toFixed(4)} or any band by more than ${ST.band.toFixed(4)} in any second.`, 230, 12, 16, { op: 0.9 });
  b += paras(24, 1376, 'The data is data/art/sky.json (keys, hold, blend paths, the start, the drift, the rate limits and the mood numbers); Tools adds its schema. Rendering needs from this sheet: the keys as data, the blend rules above, the slew step, and the stills (sky-stills.svg).', 230, 12, 16, { op: 0.9, weight: 600 });
  return wrapSvg(W, H, SIM_DEFS + b);
}

// ---------------------------------------------------------------------------------------------------------- sheet 2: mood and damage
function moodSheet() {
  const W = 1800, H = 1360, cols = [['calm', {}], ['frenzied', { frenzy: 1 }], ['wrecked (ruin 1)', { ruin: 1 }], ['frenzied and wrecked', { frenzy: 1, ruin: 1 }], ['a burning town (glow 1)', { glow: 1 }]];
  let b = rect(0, 0, W, H, '#dcd8e6') + header('The dynamic sky: the fight\'s mood and the world\'s damage', 'Frenzy, ruin and a burning town change the key\'s bands, slowly and never past the limits. Ruin darkens and warms the sky into smoke (never greys it toward the rival\'s violet); a burning town gives the horizon a low ember glow. Working labels, pending Legal review.', W);
  KEYS.forEach((k, r) => {
    const y0 = 124 + r * 168;
    b += text(24, y0 + 14, `${k.id[0].toUpperCase() + k.id.slice(1)}`, { size: 14, weight: 700 });
    cols.forEach(([lab, m], c) => { const x = 24 + c * 354, bands = moodSky(k.bands, m); b += skyPanel(x, y0 + 22, 342, 134, bands, { stars: k.stars * (1 - 0.7 * (m.ruin ?? 0)), glow: m.glow, glowAt: 0.55 }) + (r === 0 ? text(x + 4, 118, lab, { size: 12, weight: 600 }) : ''); });
  });
  const y = 124 + 5 * 168 + 10;
  b += text(24, y, 'What each driver does, and the rates (the fastest each may go from 0 to 1)', { size: 15, weight: 700 });
  const rows = [
    ['Frenzy (the fight\'s mood)', `the top deepens 18%, the upper band follows it, the lower deepens 10%, the horizon takes 10% ember (${EMBER}). Rises over at least ${MOOD_MIN_S.frenzy} s, falls over at least ${MOOD_MIN_S.frenzy} s.`],
    ['Ruin (the world is wrecked)', `smoke (${SMOKE}) into the horizon and lower bands by 60%, the upper by 40%, ash (${ASH}) into the top by 25%, the stars thinning to 30%. Rises over at least ${MOOD_MIN_S.ruin} s (two minutes for the full effect, which is how the world is wrecked anyway) and falls over at least ${MOOD_MIN_S.ruin} s if the world is mended.`],
    ['A burning town (glow)', `the horizon band takes up to 35% ember in a wide low glow (about 0.22 of the screen across, a third of the horizon band tall) over the direction of the town, nothing above the lower band. Rises over at least ${MOOD_MIN_S.glow} s, falls over at least ${MOOD_MIN_S.glow} s. Several towns add, capped at 1.`],
    ['Smoke and ash as shapes', 'none in the sky shader: a slow haze and falling ash are VFX particles at low contrast, never brighter than the sky behind them, drifting under 20 px a second.'],
  ];
  rows.forEach(([a, t], i) => { b += text(24, y + 26 + i * 52, a, { size: 12.5, weight: 700 }) + paras(260, y + 26 + i * 52, t, 190, 12, 15, { op: 0.9 }); });
  const y2 = y + 26 + 4 * 52 + 10;
  b += text(24, y2, 'What the sky must never do', { size: 15, weight: 700 });
  ['Nothing fast. Every driver is rate limited as above, and the sum of all drivers stays under the limits on sky-keys.svg (no band 0.05 a second, the mean 0.02).', 'No pulsing, flicker or beat-sync, and no reaction to a single hit: that is the VFX flashes\' job, and the flash limit applies to them.', 'Never white and never a lightning flash (Legal\'s earlier screen of the sky: nothing darkens or flashes in a reaction). The sky\'s own slow darkening under ruin is the one place the sky goes darker; it is slow by construction.', 'Never so close to a lane colour that it swallows it: at every key and every mood extreme both aura colours stay at CIEDE2000 of 24 or more from every band (the table on sky-contrast.svg).'].forEach((t, i) => { b += paras(24, y2 + 24 + i * 34, t, 230, 12, 15, { op: 0.9 }); });
  return wrapSvg(W, H, SIM_DEFS + b);
}

// ---------------------------------------------------------------------------------------------------------- sheet 3: stills, the two fighters over each key
function stillsSheet() {
  const W = 1800, H = 1330, cw = 436, ch = 290;
  let b = rect(0, 0, W, H, '#dcd8e6') + header('The dynamic sky: the two fighters over each key', 'The Protagonist (aura #8fd6ff) and the rival (aura #9a80d8) in the approved looks, with the aura as a thin ring and a dark keyline, over each key, and over the mood extremes. The aura ring is an assumption for this still; Rendering\'s own aura is the truth. Working labels.', W);
  const list = [...KEYS.map(k => [k.id[0].toUpperCase() + k.id.slice(1), k.bands, k.stars, {}]),
    ['Sunset, frenzied and wrecked', moodSky(KEYS[2].bands, { frenzy: 1, ruin: 1 }), 0.1, {}],
    ['Dusk with a burning town', moodSky(skyAt(0.44).bands, { glow: 1, frenzy: 0.5 }), 0.4, { glow: 1, glowAt: 0.8 }],
    ['Noon, wrecked', moodSky(KEYS[0].bands, { ruin: 1 }), 0, {}],
    ['Night, frenzied', moodSky(KEYS[3].bands, { frenzy: 1 }), 1, {}]];
  list.forEach(([name, bands, stars, o], i) => {
    const x = 24 + (i % 4) * (cw + 6), y = 124 + Math.floor(i / 4) * (ch + 56);
    b += still(x, y, cw, ch, bands, AURA.P, AURA.A, { stars, glow: o.glow, glowAt: o.glowAt }) + text(x + 4, y + ch + 18, name, { size: 12.5, weight: 700 });
    b += text(x + 4, y + ch + 34, BANDS.map(bd => `${bd} ${bands[bd]}`).join('  '), { size: 9.5, op: 0.65 });
  });
  b += paras(24, 124 + 3 * (ch + 56) + 4, 'What the stills show: the sky\'s four bands behind both fighters at every key; their lane colours stay readable (the dark keyline carries them where a bright horizon, such as the peach of the sunset or the cream of noon, matches the pale blue). The night is blue-black with no violet so the rival\'s violet is never swallowed; the sunset is today\'s look unchanged.', 230, 12, 16, { op: 0.9 });
  return wrapSvg(W, H, SIM_DEFS + b);
}

// ---------------------------------------------------------------------------------------------------------- sheet 4: contrast
function contrastSheet() {
  const W = 1800, H = 1020;
  let b = rect(0, 0, W, H, '#dcd8e6') + header('The dynamic sky: contrast with the lane colours', 'CIEDE2000 colour distance (dE) and WCAG contrast of each aura colour against each band of each key. dE of 24 or more is the rule at the keys; red cells are below 24. Working labels.', W);
  [['Protagonist aura #8fd6ff', AURA.P], ['Rival aura #9a80d8', AURA.A]].forEach(([nm, c], n) => {
    const x0 = 24 + n * 886;
    b += rect(x0, 124, 870, 420, BG, 'stroke="#1b1428" stroke-opacity="0.2"') + text(x0 + 12, 148, nm, { size: 15, weight: 700 }) + rect(x0 + 260, 132, 24, 22, c, 'stroke="#1b1428"');
    b += text(x0 + 150, 176, 'dE00 / WCAG contrast', { size: 11, op: 0.7 }) + BANDS.map((bd, j) => text(x0 + 200 + j * 160, 196, bd, { size: 12, weight: 700 })).join('');
    KEYS.forEach((k, r) => {
      const y = 214 + r * 56; b += text(x0 + 12, y + 22, k.id, { size: 13, weight: 600 });
      BANDS.forEach((bd, j) => { const d = dE00(c, k.bands[bd]), cr = contrast(c, k.bands[bd]); b += rect(x0 + 200 + j * 160, y, 150, 46, k.bands[bd]) + rect(x0 + 200 + j * 160, y + 30, 150, 16, d < 24 ? '#d4423a' : '#1b1428', 'opacity="0.75"') + text(x0 + 205 + j * 160, y + 43, `dE ${d.toFixed(0)}  contrast ${cr.toFixed(1)}`, { size: 10.5, weight: 700, fill: '#fff' }); });
    });
  });
  const y = 570;
  b += text(24, y, 'The worst cases, measured', { size: 15, weight: 700 });
  const lines = [
    `Round the whole lap (4000 places, calm): Protagonist ${LAP.P[0].toFixed(1)} (at lap ${LAP.P[1].toFixed(3)}, the ${LAP.P[2]} band); rival ${LAP.A[0].toFixed(1)} (at lap ${LAP.A[1].toFixed(3)}, the ${LAP.A[2]} band). The blend paths were chosen to keep these up (a straight blend dipped to 11 for the rival).`,
    `At every key and every mood extreme (frenzy, ruin, glow and their sums): Protagonist ${MOOD.P[0].toFixed(1)} (${MOOD.P[1]} ${MOOD.P[2]} ${MOOD.P[3]}); rival ${MOOD.A[0].toFixed(1)} (${MOOD.A[1]} ${MOOD.A[2]} ${MOOD.A[3]}).`,
    'WCAG contrast: the pale-blue aura (relative luminance 0.62) cannot reach 3 to 1 against the peach horizon of the sunset (0.55), the cream of noon or the apricot of dawn: the same is already true of today\'s sunset (1.1 to 1). So the rule is the dark keyline: every aura is drawn with a #0a0d14 keyline outside it, which is at least 10 to 1 against either aura colour. The sky keys keep the bands at the fighters\' height from matching the aura\'s hue as well as its lightness (dE 24 or more).',
    'Why the keys look as they do: the noon sky is a deep cerulean (not a pale blue) with a cream horizon, because a pale blue sky would swallow the Protagonist\'s pale blue; the night is blue-black with no violet, because a violet night would swallow the rival; the dawn is teal and rose, cooler and greener than the sunset; ruin goes to dark brown smoke, not grey, because grey-blue sits on the violet.',
  ];
  lines.forEach((t, i) => { b += paras(24, y + 24 + i * 62, t, 230, 12, 16, { op: 0.9 }); });
  return wrapSvg(W, H, SIM_DEFS + b);
}

writeData();
writeFileSync(join(OUT, 'sky-keys.svg'), ORIGIN + keysSheet());
writeFileSync(join(OUT, 'sky-mood.svg'), ORIGIN + moodSheet());
writeFileSync(join(OUT, 'sky-stills.svg'), ORIGIN + stillsSheet());
writeFileSync(join(OUT, 'sky-contrast.svg'), ORIGIN + contrastSheet());
console.log('wrote the sky sheets and data/art/sky.json; lap', Math.round(cycleSeconds), 's; stress', ST.mean.toFixed(4), ST.band.toFixed(4));
