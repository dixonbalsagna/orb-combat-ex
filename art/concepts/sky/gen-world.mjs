// Origin: procedural sheet writer for the world's light and the town glow (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-07. Human direction: Orb, via the EP.
// Run from the repo root:  node art/concepts/sky/gen-world.mjs   (writes world-light.svg, world-light-numbers.svg and sky-glow.svg here)

import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { fromLin, luminance, dE00 } from './colour.mjs';
import { KEYS, BANDS, skyAt, moodSky, START, BUDGET, starsAfterRuin } from './keys.mjs';
import { WORLD, WORLD_MOOD, WINDOWS, LAYERS, NEVER_DIMMED, SCREEN_W, BASE_LUM, layerLum, checks, lumsAll, slewAll } from './world.mjs';
import { text, rect, paras, header, BG, F, skyPanel, worldScene } from './draw.mjs';

const OUT = dirname(fileURLToPath(import.meta.url));
const ORIGIN = '<!-- Origin: procedural world-light sheet written by art/concepts/sky/gen-world.mjs (deterministic, no external images or fonts), Art Director session (Claude, claude-sonnet-5-5), 2026-10-07; prompt record art/prompts/ART-0018-world-light-and-lane-marks.md -->' + String.fromCharCode(10);
const wrapSvg = (w, h, inner) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${inner}</svg>`;
const mulT = (a, b) => ({ mul: a.mul.map((v, i) => v * b[i]), add: a.add });
const stateTints = (keyId, mood) => { const t = WORLD[keyId], m = mood ? { frenzy: WORLD_MOOD.frenzy, ruin: WORLD_MOOD.ruin }[mood] : null; const out = {}; for (const L of ['ground', 'buildings', 'trees', 'water', 'bodies']) out[L] = m ? mulT(t[L], m[L]) : t[L]; return out; };
const both = (keyId) => { const t = WORLD[keyId], out = {}; for (const L of ['ground', 'buildings', 'trees', 'water', 'bodies']) { const a = WORLD_MOOD.frenzy[L], b = WORLD_MOOD.ruin[L]; out[L] = { mul: t[L].mul.map((v, i) => v * a[i] * b[i]), add: t[L].add }; } return out; };

// ---------------------------------------------------------------------------------------------------------- sheet 1: the scenes
function scenes() {
  const W = 1800, pw = 580, ph = 200, H = 124 + KEYS.length * (ph + 30) + 250;
  let b = rect(0, 0, W, H, '#dcd8e6') + header('The world\'s light: the world takes the sky\'s key', 'Rendering\'s still showed a daylit ground and daylit buildings under the night sky because only the sky\'s bands change. Left: the game as built (sky only). Middle: the world lit by the key. Right: the key with the fight frenzied and the world wrecked. The auras and lane colours never dim and the bodies dim least. Working labels, pending Legal review.', W);
  [['As built: the sky changes alone', 24], ['Directed: the world takes the key', 24 + pw + 8], ['Directed, frenzied and wrecked', 24 + 2 * (pw + 8)]].forEach(([t, x]) => { b += text(x, 138, t, { size: 13, weight: 700 }); });
  KEYS.forEach((k, r) => {
    const y = 148 + r * (ph + 30), calm = k.bands, wreck = moodSky(k.bands, { frenzy: 1, ruin: 1, reach: k.glow_reach });
    b += worldScene(24, y, pw, ph, calm, { stars: k.stars, lit: 0.3 });
    b += worldScene(24 + pw + 8, y, pw, ph, calm, { stars: k.stars, T: stateTints(k.id, null), lit: WINDOWS.lit_share[k.id], glass: k.id === 'night' ? WINDOWS.glass_night : WINDOWS.glass });
    b += worldScene(24 + 2 * (pw + 8), y, pw, ph, wreck, { stars: starsAfterRuin(k.stars, 1), T: both(k.id), lit: WINDOWS.lit_share[k.id] * 0.85, glass: k.id === 'night' ? WINDOWS.glass_night : WINDOWS.glass });
    b += text(24, y + ph + 16, `${k.id[0].toUpperCase() + k.id.slice(1)}: windows lit ${Math.round(WINDOWS.lit_share[k.id] * 100)}% (3 in 10 as built)`, { size: 11.5, weight: 600, op: 0.85 });
  });
  const y = 148 + KEYS.length * (ph + 30);
  b += text(24, y + 10, 'What changes, and what never does', { size: 15, weight: 700 });
  b += paras(24, y + 34, 'A multiply tint per layer (ground, buildings, trees, water, civilians, bodies), in linear light, and for the night a small additive lift so the dark ground is cool, not brown. The tints blend with the same phase, hold and ease as the sky. Windows come on with the dark (3 in 10 lit as built, 6 in 10 at night) and keep their lit colour; the aura rings, the lane colours, the HUD, flashes, particles and the keyline are never dimmed. The sunset is the one key where the start of a match changes: its world takes a gentle warm tint (about a fifth darker, a little more red than blue), which Orb should see once; a strength knob scales every tint toward 1 if he prefers the start exactly as it was.', 230, 12, 16, { op: 0.9 });
  b += paras(24, y + 118, 'The numbers are on world-light-numbers.svg and in data/art/sky.json under _world_light. In these mock scenes the bodies are the approved concept figures; the readability numbers use the game\'s own body colours (the Protagonist #3d8fdc, the rival #a52a2a).', 230, 12, 16, { op: 0.9, weight: 600 });
  return wrapSvg(W, H, b);
}

// ---------------------------------------------------------------------------------------------------------- sheet 2: the numbers
function numbers() {
  const W = 1800, H = 1500, C = checks();
  let b = rect(0, 0, W, H, '#dcd8e6') + header('The world\'s light: the numbers', 'Per layer and key: a multiplier in linear light (the swatch shows the multiplier as a grey-to-colour tint) and, for the night, a small additive lift. The same hard limit as the sky applies: nothing changes fast. Working labels.', W);
  const cw = 270, x0 = 150;
  b += text(24, 142, 'Tints (mul R G B, in linear light; luminance factor in brackets)', { size: 15, weight: 700 });
  LAYERS.forEach((L, j) => { b += text(x0 + j * cw, 166, L, { size: 12.5, weight: 700 }); });
  KEYS.forEach((k, r) => {
    const y = 176 + r * 62; b += text(24, y + 30, k.id, { size: 13, weight: 700 });
    LAYERS.forEach((L, j) => { const t = WORLD[k.id][L], f = 0.2126 * t.mul[0] + 0.7152 * t.mul[1] + 0.0722 * t.mul[2]; b += rect(x0 + j * cw, y, 40, 40, fromLin(t.mul.map(v => Math.min(1, v))), 'stroke="#1b1428" stroke-opacity="0.4"') + text(x0 + j * cw + 48, y + 14, `${t.mul.join(' ')}`, { size: 10.5, weight: 600 }) + text(x0 + j * cw + 48, y + 28, `(${f.toFixed(2)})${t.add.some(v => v) ? ' add ' + t.add.join(' ') : ''}`, { size: 10, op: 0.75 }); });
  });
  // the mood
  let y = 176 + KEYS.length * 62 + 14;
  b += text(24, y, 'The mood on the same layers (a further multiplier): frenzy, ruin, and a burning town\'s firelight', { size: 15, weight: 700 });
  [['frenzy', WORLD_MOOD.frenzy], ['ruin', WORLD_MOOD.ruin]].forEach(([n, m], i) => { b += text(24, y + 26 + i * 22, n, { size: 12, weight: 700 }) + text(120, y + 26 + i * 22, LAYERS.map(L => `${L} ${m[L].join(' ')}`).join('   '), { size: 10.5, op: 0.85 }); });
  b += text(24, y + 74, 'firelight', { size: 12, weight: 700 }) + text(120, y + 74, `a warm multiply ${WORLD_MOOD.firelight.multiply.join(' ')} on ${WORLD_MOOD.firelight.applies_to.join(', ')} within ${WORLD_MOOD.firelight.radius} body units of a burning town, falling off linearly, at strength ${WORLD_MOOD.firelight.strength} at glow 1`, { size: 10.5, op: 0.85 });
  // windows
  y += 106;
  b += text(24, y, 'Lit windows (cheap: the windows exist; only the share lit changes, and the lit colour never dims)', { size: 15, weight: 700 });
  KEYS.forEach((k, i) => { b += rect(24 + i * 200, y + 14, 180, 14, '#2c3550') + rect(24 + i * 200, y + 14, 180 * WINDOWS.lit_share[k.id], 14, WINDOWS.lit_colour) + text(24 + i * 200, y + 44, `${k.id}: ${Math.round(WINDOWS.lit_share[k.id] * 100)}% lit`, { size: 11, weight: 600 }); });
  b += paras(24, y + 66, WINDOWS.note + `. Window glass ${WINDOWS.glass} by day, ${WINDOWS.glass_night} at night; lit ${WINDOWS.lit_colour}.`, 230, 11.5, 15, { op: 0.9 });
  // readability
  y += 112;
  b += text(24, y, 'The fighters stay readable at every key (CIEDE2000, over the 7 biomes and calm, frenzied and wrecked)', { size: 15, weight: 700 });
  b += text(24, y + 22, 'key', { size: 11, weight: 700 }) + text(150, y + 22, 'body against the tinted ground', { size: 11, weight: 700 }) + text(520, y + 22, 'aura against the tinted ground (never dimmed)', { size: 11, weight: 700 });
  KEYS.forEach((k, i) => { const d = C.by_key[k.id], yy = y + 44 + i * 22; b += text(24, yy, k.id, { size: 12, weight: 600 }) + text(150, yy, `${d.body_vs_ground[0].toFixed(1)}  (${d.body_vs_ground[1]} on ${d.body_vs_ground[2]}, ${d.body_vs_ground[3]})`, { size: 12 }) + text(520, yy, `${d.aura_vs_ground[0].toFixed(1)}  (${d.aura_vs_ground[1]} on ${d.aura_vs_ground[2]}, ${d.aura_vs_ground[3]})`, { size: 12 }); });
  b += paras(24, y + 44 + 5 * 22 + 8, 'The rule: bodies 15 or more and auras 20 or more from the tinted ground at every key and mood, which is no worse than today\'s noon (body 15.1, aura 20.8, where the game is unchanged). The bodies dim about half as much as the ground at night (luminance factor 0.55 against 0.11), so a fighter stands out of a dark world; the keyline and the aura carry the rest.', 230, 12, 16, { op: 0.9 });
  // rate
  y += 44 + 5 * 22 + 66;
  const R = { lap: 0, mean: 0, part: 0 };
  let q = 0, t = 0, tr = 0; const dt = 1 / 30; while (tr < 1 && t < 2000) { const n = slewAll(q, (q + 0.3) % 1, dt); let dd = n - q; if (dd < -0.5) dd += 1; tr += dd; q = n; t += dt; } R.lap = Math.round(t);
  let p = START.phase, tt = 0, tgt = START.phase; const h = []; for (let i = 0; i < 60 * 180; i++) { tt += 1 / 60; const dir = (Math.floor(tt / 3) % 2 === 0) ? 1 : -1; tgt = (tgt + dir * 0.25 / 60 + 1) % 1; p = slewAll(p, tgt, 1 / 60); const l = lumsAll(p); h.push([l.mean, ...Object.values(l.parts)]); }
  for (let i = 60; i < h.length; i++) { R.mean = Math.max(R.mean, Math.abs(h[i][0] - h[i - 60][0])); for (let j = 1; j < h[i].length; j++) R.part = Math.max(R.part, Math.abs(h[i][j] - h[i - 60][j])); }
  b += text(24, y, 'Nothing fast: the rate, now with the world in it', { size: 15, weight: 700 });
  b += paras(24, y + 24, `The same hard limit, extended: no sky band and no world layer changes in relative luminance faster than ${BUDGET.place.band} a second (place and time; ${BUDGET.total.band} with the mood), and the screen's mean (the sky weighted ${SCREEN_W.sky}, each layer by its share: ground ${SCREEN_W.ground}, buildings ${SCREEN_W.buildings}, trees ${SCREEN_W.trees}, water ${SCREEN_W.water}, civilians ${SCREEN_W.civilians}, bodies ${SCREEN_W.bodies}) no faster than ${BUDGET.place.mean} (${BUDGET.total.mean} with the mood). The layers' base luminances are ground ${BASE_LUM.ground.toFixed(3)}, buildings ${BASE_LUM.buildings.toFixed(3)}, trees ${BASE_LUM.trees.toFixed(3)}, water ${BASE_LUM.water.toFixed(3)}, bodies ${BASE_LUM.bodies.toFixed(3)}. The shown phase follows the target through slewAll (world.mjs): the sky's slew with the layers in it. Measured: a lap at the limit takes ${R.lap} seconds (the world adds no time: the sky's horizon band is the slowest part); the stress test (the target flying round at a quarter of a lap a second and reversing every 3 s, 3 minutes) never moved the screen's mean by more than ${R.mean.toFixed(4)} or any band or layer by more than ${R.part.toFixed(4)} in any second. The mood's world multipliers ease at the same minimum durations as the sky's (frenzy 30 s, ruin 120 s, glow 50 s); the ruin multiplier on the ground is about 0.25 of its luminance over 120 s.`, 230, 12, 16, { op: 0.9 });
  b += text(24, y + 190, 'What Rendering needs', { size: 15, weight: 700 });
  b += paras(24, y + 212, 'Per layer two uniforms (a vec3 multiplier and a vec3 lift), mixed on the shown phase like the sky; one uniform for the window lit share and the night glass colour; the mood multipliers per layer; firelight as a vec3 and a strength per burning town. All cheap. Said plainly about needing more: a multiply (with the small night lift) is enough for this look; I do not need a shading model, a light direction or per-pixel emissives. If the terrain shader multiplies in sRGB rather than linear, convert: the numbers here are linear multipliers.', 230, 12, 16, { op: 0.9 });
  return wrapSvg(W, H, b);
}

// ---------------------------------------------------------------------------------------------------------- sheet 3: the town glow and what burning means
function glowSheet() {
  const W = 1800, H = 1240, pw = 436, ph = 250;
  let b = rect(0, 0, W, H, '#dcd8e6') + header('The town glow: larger and higher, and what "burning" should mean', 'Rendering: the glow was very faint at the size drawn (a third of the horizon band) and the town\'s own buildings hid it from inside. It is not a far-off speck: it should show over the town\'s rooflines. And it should die down: there is no burning state in the sim today. Working labels, pending Legal review.', W);
  const panel = (x, y, bands, directed, inTown, label) => {
    let s = skyPanel(x, y, pw, ph, bands, { plain: true, horizonAt: 0.6 });
    const hy = y + ph * 0.6, rx = directed ? pw * 0.2 : pw * 0.11, ry = directed ? ph * 0.30 : ph * 0.03, a = directed ? 0.75 : 0.5;
    s += `<defs><radialGradient id="gl${x}${y}" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#d9603c" stop-opacity="${a}"/><stop offset="1" stop-color="#d9603c" stop-opacity="0"/></radialGradient></defs><ellipse cx="${F(x + pw * 0.5)}" cy="${F(hy)}" rx="${F(rx)}" ry="${F(ry)}" fill="url(#gl${x}${y})"/>`;
    // the ground, and from inside the town, tall buildings across the middle of the screen
    s += rect(x, hy, pw, y + ph - hy, '#262a35');
    if (inTown) { [[0.1, 0.5, 0.12], [0.26, 0.38, 0.1], [0.38, 0.55, 0.14], [0.58, 0.52, 0.13], [0.74, 0.4, 0.1], [0.86, 0.48, 0.12]].forEach(([fx, fh, fw]) => { s += rect(x + fx * pw, hy - fh * ph * 0.6, fw * pw, fh * ph * 0.6 + 40, directed ? '#4d4a54' : '#3a3d4a', 'stroke="#0a0d14" stroke-width="1"'); }); if (directed) s += `<rect x="${F(x)}" y="${F(hy - 40)}" width="${pw}" height="80" fill="#d9603c" opacity="0.12"/>`; }
    else for (let i = 0; i < 14; i++) s += rect(x + i * pw / 14 + 2, hy - 6 - ((i * 37) % 17), pw / 14 - 4, 6 + ((i * 37) % 17), '#20232d');
    return `<g clip-path="url(#cp${x}${y})"><defs><clipPath id="cp${x}${y}"><rect x="${x}" y="${y}" width="${pw}" height="${ph}"/></clipPath></defs>${s}</g>` + text(x + 4, y + ph + 16, label, { size: 12, weight: 700 });
  };
  const dusk = skyAt(0.44).bands, night = KEYS[3].bands, sunset = KEYS[2].bands;
  b += text(24, 136, 'From an open horizon (the glow over a town at a distance)', { size: 15, weight: 700 });
  b += panel(24, 148, sunset, false, false, 'Sunset, as built (a third of the horizon band tall)') + panel(24 + pw + 8, 148, sunset, true, false, 'Sunset, directed: wider and rising to 0.55 half screens') + panel(24 + 2 * (pw + 8), 148, night, false, false, 'Night, as built') + panel(24 + 3 * (pw + 8), 148, night, true, false, 'Night, directed');
  b += text(24, 148 + ph + 56, 'From inside the town (the buildings stand in front of the horizon)', { size: 15, weight: 700 });
  b += panel(24, 148 + ph + 68, dusk, false, true, 'Dusk, as built: the buildings hide it') + panel(24 + pw + 8, 148 + ph + 68, dusk, true, true, 'Dusk, directed: it rises over the rooflines, and the town takes firelight') + panel(24 + 2 * (pw + 8), 148 + ph + 68, night, false, true, 'Night, as built') + panel(24 + 3 * (pw + 8), 148 + ph + 68, night, true, true, 'Night, directed');
  let y = 148 + 2 * ph + 130;
  b += text(24, y, 'The direction', { size: 15, weight: 700 });
  b += paras(24, y + 22, 'Larger and higher, not left as a far-off cue. The glow is about 0.30 of the screen wide (gaussian) and rises to 0.55 half screens above the horizon, so it shows above the rooflines from the ground as well as from outside; the horizon band takes 45% ember, the lower band 22% and the upper band 8% at its centre (the last two scaled by the key\'s glow_reach: none at noon, half at golden, full from the sunset on, because ember mixed into noon\'s blue turns it slate, close to the rival\'s violet). A far-off town is the same glow smaller by distance (down to 0.12 of the screen). The town itself takes firelight: ground, buildings and trees within 1800 body units get a warm multiply (1.0 0.86 0.68) at up to 35%, falling off linearly, so from inside the town it is the town that is lit. Smoke and ash are VFX, not the sky. The numbers are in data/art/sky.json (_town_glow, mood._amounts, _world_light.mood.firelight).', 230, 12, 16, { op: 0.9 });
  // the burning state
  y += 130;
  b += text(24, y, 'What "burning" should mean (for World and Simulation: Art says what the picture needs)', { size: 15, weight: 700 });
  const cx = 24, cy = y + 24, cw = 700, ch = 120;
  b += rect(cx, cy, cw, ch, BG, 'stroke="#1b1428" stroke-opacity="0.25"');
  const T = 150, xs = t => cx + 10 + t / T * (cw - 20), ys = v => cy + ch - 10 - v * (ch - 24);
  // a building's fire: rise 10 s, hold to 70 s, fall 30 s; and the town's glow lagging at the 50 s mood rate
  const fire = t => t < 10 ? t / 10 : t < 70 ? 1 : t < 100 ? 1 - (t - 70) / 30 : 0;
  let g = 0, gp = '', fp = ''; for (let t = 0; t <= T; t += 1) { const d = fire(t) - g; g += Math.max(-1 / 50, Math.min(1 / 50, d)); fp += `${F(xs(t))},${F(ys(fire(t)))} `; gp += `${F(xs(t))},${F(ys(g))} `; }
  b += `<polyline points="${fp}" fill="none" stroke="#d9603c" stroke-width="2.5"/><polyline points="${gp}" fill="none" stroke="#6b3fa8" stroke-width="2.5" stroke-dasharray="6 4"/>` + text(cx + 6, cy - 6, 'a building\'s fire (orange) and the town\'s glow, eased at the mood rate (violet, dashed)', { size: 10.5, op: 0.85 }) + text(xs(0), cy + ch + 14, '0 s', { size: 10 }) + text(xs(10), cy + ch + 14, '10 s', { size: 10 }) + text(xs(70), cy + ch + 14, '70 s', { size: 10 }) + text(xs(100), cy + ch + 14, '100 s', { size: 10 });
  b += paras(760, y + 28, 'A building burns when it reaches damage stage 2 or worse from energy (a beam, an explosion or a mine), not from a plain blow. Its fire goes from 0 to 1 over 10 seconds, holds while it burns (60 seconds at most, and 90 seconds after the last energy damage to it), then falls to 0 over 30 seconds: it burns out. A town glows by the share of its buildings on fire (half of them is a full glow); the glow rises and falls at the mood rate, so it lags the fire by design (it never jumps). When the fire is out the town stays wrecked: ruin keeps its smoke tint and the glow is gone. Nothing here is a flash: every change takes tens of seconds.', 130, 12, 16, { op: 0.9 });
  return wrapSvg(W, H, b);
}

writeFileSync(join(OUT, 'world-light.svg'), ORIGIN + scenes());
writeFileSync(join(OUT, 'world-light-numbers.svg'), ORIGIN + numbers());
writeFileSync(join(OUT, 'sky-glow.svg'), ORIGIN + glowSheet());
console.log('wrote world-light.svg, world-light-numbers.svg, sky-glow.svg');
