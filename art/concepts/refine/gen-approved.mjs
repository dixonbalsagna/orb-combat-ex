// Origin: procedural sheet writer for the approved launch-pair looks (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-04. Human direction: Orb, via the EP.
// Run from the repo root:  node art/concepts/refine/gen-approved.mjs
// Writes rival-glare-c.svg, approved-rival-turnaround.svg, approved-protagonist-turnaround.svg, approved-rival-faces.svg, approved-protagonist-faces.svg.
// Approved by Orb (2026-10-04): the Protagonist (broad body, dark plated fists, short swept tuft); the rival (slim, long tail, flat coat plates, glasses frame C); the glare hides his eyes completely.

import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { makeCtx, figure } from '../anti-hero/kit.mjs';
import { portrait, H } from '../closeups/engine.mjs';
import * as FA from './faces.mjs';
import { FRAMES, glassedFace, profileGlasses, INK, APPROVED } from './glasses.mjs';
import { drawFigure, POSE0, PAL } from './figures.mjs';
import { hero, rival } from './approved.mjs';

const OUT = dirname(fileURLToPath(import.meta.url));
const F = n => n.toFixed(2);
const esc = t => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const FONT = "font-family=\"'Segoe UI', system-ui, -apple-system, Helvetica, Arial, sans-serif\"";
const text = (x, y, t, { size = 14, weight = 400, fill = '#1b1428', anchor = 'start', op = 1 } = {}) => `<text x="${F(x)}" y="${F(y)}" ${FONT} font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${op}">${esc(t)}</text>`;
const rect = (x, y, w, h, fill, extra = '') => `<rect x="${F(x)}" y="${F(y)}" width="${F(w)}" height="${F(h)}" fill="${fill}" ${extra}/>`;
const wrap = (t, n) => { const w = t.split(' '), out = []; let line = ''; for (const x of w) { if ((line + ' ' + x).trim().length > n) { out.push(line.trim()); line = x; } else line += ' ' + x; } if (line.trim()) out.push(line.trim()); return out; };
const paras = (x, y, t, n, size = 12, gap = 15, o = {}) => wrap(t, n).map((l, i) => text(x, y + i * gap, l, { size, ...o })).join('');
const header = (title, sub, W) => rect(0, 0, W, 104, '#1b1428') + text(30, 46, title, { size: 30, weight: 700, fill: '#f4f0fa' }) + paras(30, 72, sub, 210, 14, 18, { fill: '#cfc6e6' });
const BG = '#e8e5ee';
const FILTERS = '<defs><filter id="grey"><feColorMatrix type="saturate" values="0"/></filter></defs>';
let uid = 0;
const ALLX = ['neutral', 'smirk', 'strain', 'hurt', 'laugh', 'contempt', 'shock', 'grief'];
const NEUTRAL_UP = { lean: 0, head: 0, nearArm: [10, 8], farArm: [-10, -8], nearLeg: [3, 1], farLeg: [-3, -1], handNear: 'fist', handFar: 'fist' };

const rface = (state, x, y, size, o = {}, extra = '') => `<svg x="${F(x)}" y="${F(y)}" width="${size}" height="${size}" viewBox="0 0 512 512" overflow="hidden" ${extra}>${portrait('X', 'A', o.expr ?? 'neutral', `a${uid++}`, { draw: glassedFace(APPROVED, state, o.stage ?? 0, o.t ?? 0.4, o.amount ?? 1) })}</svg>`;
const pface = (expr, x, y, size, extra = '') => `<svg x="${F(x)}" y="${F(y)}" width="${size}" height="${size}" viewBox="0 0 512 512" overflow="hidden" ${extra}>${portrait('X', 'P', expr, `a${uid++}`, { draw: FA.refined })}</svg>`;
const fig = (c, pal, pose, x, g, s, flat = false) => drawFigure({ concept: c, pal, pose, flat, bg: BG, x, ground: g, s });

// one view of an approved fighter, like the earlier turnarounds: front, three-quarter, side, back
function view(fk, o, x, ground, px, state = 'clear') {
  const s = px / 100, pal = PAL[fk], ctx = makeCtx({ flat: !!o.flat, pal, swMul: px < 80 ? 1 : 1.3, faceless: false });
  const c = fk === 'P' ? hero(o) : rival(o, state);
  const st = { yaw: o.yaw, face: o.face ?? null, state: 'neutral', sway: c.sway ?? 4, expression: 'neutral', open: 0, forms: 6, wear: 0, hairLoose: false, bg: BG };
  const { svg, sk } = figure(ctx, c, o.pose ?? NEUTRAL_UP, st, { yaw: o.yaw, back: !!o.back, armSpread: o.spread ? 7 : 0, legSpread: o.spread ? 3 : 0 });
  const fl = o.flip ? ` transform="translate(${F(x)} 0) scale(-1 1) translate(${F(-x)} 0)"` : '';
  return { svg: `<g${fl}><g transform="translate(${F(x)} ${F(ground)}) scale(${F(s)} ${F(-s)})">${svg}</g></g>`, sk, s };
}
const VIEWS = [['Front', { yaw: 90, face: 'front', spread: true }, 250], ['Three-quarter right', { yaw: 32 }, 650], ['Side', { yaw: 0 }, 1050], ['Back', { yaw: 90, face: 'back', back: true, spread: true }, 1450]];

// ---------------------------------------------------------------------------------------------------------------- colour maths for the glare
const hex = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
const toHsl = ([r, g, b]) => { r /= 255; g /= 255; b /= 255; const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, d = mx - mn; let h = 0, s = 0; if (d) { s = d / (1 - Math.abs(2 * l - 1)); h = mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4; h *= 60; if (h < 0) h += 360; } return [Math.round(h), Math.round(s * 100), Math.round(l * 100)]; };
const mix = (a, b, t) => a.map((v, i) => Math.round(v + (b[i] - v) * t));
const hx = a => '#' + a.map(v => v.toString(16).padStart(2, '0')).join('');

// is every point of the eye shapes under the lens? (the check behind "the eyes are hidden completely")
function coverage() {
  const lens = FRAMES[APPROVED].lens.map(([x, y]) => [x * 1.12 + 68, y * 1.28 - 36]);
  const inside = (p, poly) => { let c = false; for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) { const [xi, yi] = poly[i], [xj, yj] = poly[j]; if (((yi > p[1]) !== (yj > p[1])) && (p[0] < (xj - xi) * (p[1] - yi) / (yj - yi) + xi)) c = !c; } return c; };
  let tot = 0, ok = 0;
  for (const o of [0.12, 0.4, 0.68, 0.88, 1.0]) for (const [x, y] of H.eyeShape('blade', 50, o)) { tot++; if (inside([x + 62, y - 36], lens)) ok++; }
  return `${ok} of ${tot}`;
}

// ---------------------------------------------------------------------------------------------------------------- 1. the glare for frame C
function glareSheet() {
  const W = 1800, H0 = 1560;
  let b = rect(0, 0, W, H0, '#dcd8e6') + header('The rival\'s glare: frame C, eyes fully hidden', 'Approved by Orb (2026-10-04): glasses frame C, the bare wedge; when the glare is on it hides his eyes completely. To Legal\'s rules (RL-066, RL-068): one hard-edged pale-violet wedge, never white, held 0.4 s at most. No masks. Working labels.', W);
  // timeline
  b += text(24, 136, 'The glare in time: a quick attack, a hold of 0.4 s at most, a release (one slow fade in and out, no strobing)', { size: 15, weight: 700 });
  [[0, '0 ms: clear'], [0.35, '40 ms'], [0.75, '80 ms'], [1, '120 ms: full, eyes hidden'], [1, 'hold: 0.4 s at most'], [0.5, 'release 80 ms'], [0, 'clear again at about 0.7 s']].forEach(([a, lab], i) => {
    const x = 24 + i * 254;
    b += rface(a === 0 ? 'clear' : 'glare', x, 150, 244, { expr: 'smirk', amount: a || 1 }) + text(x + 6, 150 + 262, lab, { size: 12, weight: 600, op: 0.85 });
  });
  // close-up and gameplay size
  b += text(24, 460, 'Close-up, then gameplay size (the figure is about 100 px tall): clear and glare', { size: 15, weight: 700 });
  b += rface('clear', 24, 474, 300, { expr: 'neutral' }) + rface('glare', 332, 474, 300, { expr: 'smirk' });
  const rv = (state, x) => fig(rival({ yaw: 0 }, state), PAL.A, POSE0('A'), x, 800, 1.0);
  b += rv('clear', 740) + rv('glare', 890) + text(680, 830, 'gameplay size (100 px)', { size: 11, op: 0.65 });
  b += fig(rival({ yaw: 0 }, 'clear'), PAL.A, POSE0('A'), 1040, 800, 0.5) + fig(rival({ yaw: 0 }, 'glare'), PAL.A, POSE0('A'), 1090, 800, 0.5) + text(1010, 830, '50 px', { size: 11, op: 0.65 });
  const crop = (state, x, y) => `<svg x="${F(x)}" y="${F(y)}" width="180" height="120" viewBox="${F(18 * 6 - 90)} ${F(-69 * 6 - 60)} 180 120" overflow="hidden">${rect(18 * 6 - 90, -69 * 6 - 60, 180, 120, '#f3f0f8')}${fig(rival({ yaw: 0 }, state), PAL.A, POSE0('A'), 0, 0, 6)}</svg>`;
  b += crop('clear', 1180, 480) + crop('glare', 1370, 480) + text(1180, 614, 'the head enlarged 6 times: lens clear, then glare (the eye is gone)', { size: 11, op: 0.65 });
  b += paras(1180, 640, 'At gameplay size the glare is a pale violet bar across the face where the eye was: one clear change at one place. At the close-up size the lens is fully opaque with one hard-edged wedge.', 50, 12, 15, { op: 0.9 });
  // small sizes
  b += text(24, 860, 'Small sizes: 72, 24 and the 12 px band, in colour and in grey (the violet stays visible; nothing reads as white)', { size: 15, weight: 700 });
  const band = (state, x, y, h, extra = '') => { const id = `a${uid++}`; return `<svg x="${F(x)}" y="${F(y)}" width="${F(h * 4.46)}" height="${h}" viewBox="96 226 330 74" overflow="hidden" ${extra}><clipPath id="bc-${id}"><rect x="96" y="226" width="330" height="74"/></clipPath><g clip-path="url(#bc-${id})">${portrait('X', 'A', 'smirk', id, { draw: glassedFace(APPROVED, state, 0, 0.4, 1) })}</g></svg>`; };
  b += rface('clear', 24, 876, 72) + rface('glare', 104, 876, 72, { expr: 'smirk' }) + `<g filter="url(#grey)">${rface('clear', 184, 876, 72)}${rface('glare', 264, 876, 72, { expr: 'smirk' })}</g>`;
  b += rface('clear', 360, 900, 24) + rface('glare', 392, 900, 24, { expr: 'smirk' }) + `<g filter="url(#grey)">${rface('clear', 424, 900, 24)}${rface('glare', 456, 900, 24, { expr: 'smirk' })}</g>`;
  b += band('clear', 500, 880, 12) + band('glare', 560, 880, 12) + band('clear', 500, 900, 12, 'filter="url(#grey)"') + band('glare', 560, 900, 12, 'filter="url(#grey)"');
  // the colour numbers
  const G = hex('#c0a0ee'), GH = hex('#d8c2f8'), TINT = hex('#2f2358'), WHITE = [255, 255, 255];
  const cov = 0.3, mean = mix(G, GH, cov);
  b += text(24, 1000, 'The colour, checked', { size: 15, weight: 700 });
  [[G, 'glare lens'], [GH, 'the wedge'], [mean, 'the lens as one mean tint (about 30% wedge)'], [TINT, 'clear lens tint'], [WHITE, 'white, for comparison (never used)']].forEach(([c, lab], i) => {
    const hsl = toHsl(c), x = 24 + i * 340;
    b += rect(x, 1014, 60, 40, hx(c), 'stroke="#1b1428" stroke-opacity="0.4"') + text(x + 70, 1030, `${lab}`, { size: 11.5, weight: 600 }) + text(x + 70, 1046, `${hx(c)}  hue ${hsl[0]}, saturation ${hsl[1]}%, lightness ${hsl[2]}%`, { size: 11, op: 0.8 });
  });
  b += paras(24, 1086, `The glare stays in his violet (hue ${toHsl(G)[0]} to ${toHsl(GH)[0]}), at saturation ${toHsl(G)[1]} to ${toHsl(GH)[1]} percent and lightness ${toHsl(G)[2]} to ${toHsl(GH)[2]} percent: bright, but 20 points of lightness under white and clearly coloured, so at 24 px the mean tint is ${hx(mean)}, not white. It is never gold, orange, red or white (RL-066).`, 230, 12, 16, { op: 0.9 });
  // the eyes
  b += text(24, 1150, 'The eyes are fully hidden', { size: 15, weight: 700 });
  b += paras(24, 1172, `Checked in code, not by eye: sampling the outline of his eye at five openness values (from shut to the widest shock), ${coverage()} of the points lie under the opaque lens, so no eye shows when the glare is on. To get all of them, frame C's lens is about 7 percent taller than the first drawing of it (the shape and the thin rim are unchanged). The glare is also opaque on the far lens, and the lens sits in front of the eyes, so the render order is: face, eyes, lens.`, 230, 12, 16, { op: 0.9 });
  // rules
  b += text(24, 1262, 'Rules for VFX and Animation (RL-066, RL-068)', { size: 15, weight: 700 });
  ['A quick attack (about 120 ms), a hold of 0.4 s at most, a release (about 80 ms). One glare in any 3 s at most; key moments only: reading a move, pride, a taunt, the seal break. Never every exchange.', 'The glare is one hard-edged wedge in the pale violet, never white, gold, orange or red; no disc and no star; it counts as no mark under the stacking rule when it is not at a transformation break and has no shouted form name.', 'One slow fade in and out, no strobing (photosensitivity); with reduced motion it is a held tint with no sweep. The glasses themselves are never a display: no readout or scan bar on a lens.', 'Gesture: a nudge at the temple arm, or with the back of the forearm plate. The glare fires on the nudge. Never one finger at the bridge; never folded or steepled hands before the face.'].forEach((t, i) => { b += paras(24, 1284 + i * 40, t, 230, 12, 15, { op: 0.9 }); });
  b += text(24, 1470, 'Legal screen of this sheet: pending. The question left for Orb: none for the glare (decided); the glasses always on, or only for the taunt and the seal break, is still open.', { size: 12, weight: 600 });
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H0}" viewBox="0 0 ${W} ${H0}">${FILTERS}${b}</svg>`;
}

// ---------------------------------------------------------------------------------------------------------------- 2. the turnarounds
function turnaround(fk) {
  const isP = fk === 'P', W = 1800, px = 400, g = 640, H0 = isP ? 1230 : 1700;
  let b = rect(0, 0, W, H0, '#dcd8e6') + header(isP ? 'The Protagonist: turnaround (approved by Orb)' : 'The rival: turnaround (approved by Orb)', isP ? 'Front, three-quarter, side and back at the approved design: a broad body, dark plated fists, a short swept tuft. No mask. Concept art from the figure kit; pending Legal review.' : 'Front, three-quarter, side and back at the approved design: slim, a long tail, flat coat plates, glasses frame C (the bare wedge). No mask. Concept art from the figure kit; pending Legal review.', W);
  b += rect(24, 124, W - 48, 580, BG, 'stroke="#1b1428" stroke-opacity="0.2"');
  VIEWS.forEach(([cap, o, x]) => { const d = view(fk, o, x, g, px); b += d.svg + text(x, g + 30, cap, { size: 14, weight: 600, anchor: 'middle' }); });
  // the pose in play, flat, and the read-apart
  b += rect(24, 720, 900, 470, BG, 'stroke="#1b1428" stroke-opacity="0.2"') + text(40, 746, 'The stance in play, at gameplay size and flat black', { size: 15, weight: 700 });
  const pose = POSE0(fk), c = isP ? hero({ yaw: 0 }) : rival({ yaw: 0 }, 'clear');
  b += fig(c, PAL[fk], pose, 140, 1050, 2.8) + fig(c, PAL[fk], pose, 360, 1050, 2.8, true) + fig(c, PAL[fk], pose, 560, 1050, 1.0) + fig(c, PAL[fk], pose, 640, 1050, 1.0, true) + fig(c, PAL[fk], pose, 720, 1050, 0.5, true) + fig(c, PAL[fk], pose, 770, 1050, 0.25, true);
  b += text(540, 1090, '100 px, flat, 50 px, 25 px', { size: 11, op: 0.65 });
  // notes
  const notes = isP
    ? ['Build: broad (torso and limbs about 20 and 14 percent wider than the first Protagonist), round masses.', 'Fists: solid, dark and plated in the value of his tunic and wraps, with two plate lines; never a pale disc or a ball of light. Shoulders: dark plated rounds.', 'Hair: a short swept tuft along the crown that sweeps back; never a curl on the forehead. Teal, with the temple arc.', 'Belt: the wide light belt with the round knot at the back stays (his one light accent at the waist).', 'Face: unmasked, refined (heavier lids, an angled brow); the close-ups are in approved-protagonist-faces.svg.']
    : ['Build: slim (torso and limbs about 8 and 6 percent narrower than the first rival), long and straight.', 'Tail: one long tapering tail from the crown to the knee; from the back it falls straight down the centre of the back.', 'Coat plates: three flat, straight-edged plates hanging from the belt at the front; flat plates, not wings and not a pack. The drum unit on his back is the original figure\'s and unchanged.', 'Glasses: frame C, the bare wedge (see the callouts below); the cheek slash is his one lit mark.', 'Face: unmasked, refined; the close-ups, with the glare, are in approved-rival-faces.svg and rival-glare-c.svg.'];
  b += text(960, 746, 'Parts and rules', { size: 15, weight: 700 });
  notes.forEach((t, i) => { b += paras(960, 770 + i * 50, t, 100, 12, 15, { op: 0.9 }); });
  const pal = PAL[fk], sw = [['skin', pal.skin.mid], ['hair', pal.hair.mid], ['base (tunic, limbs)', pal.base.mid], ['base shadow', pal.base.shadow], ['gear (wraps, belt)', pal.gear.mid], ['accent', pal.accent.mid]];
  sw.forEach(([n, c], i) => { b += rect(960 + (i % 3) * 270, 1030 + Math.floor(i / 3) * 44, 34, 30, c, 'stroke="#1b1428" stroke-opacity="0.4"') + text(1002 + (i % 3) * 270, 1050 + Math.floor(i / 3) * 44, `${n} ${c}`, { size: 11, op: 0.85 }); });
  b += paras(960, 1140, isP ? 'For Animation and Rendering: the plated fists are meshes of the same value as the sleeves and wraps (no emissive, no light), so a fist is never read as a light ball; the tuft is a swept hair chain pointing back, no forehead curl.' : 'For Animation and Rendering: the coat plates are three rigid flat plates on the belt (no cloth physics, no wing shape); the tail is the one cosmetic chain, hanging from the crown.', 80, 12, 15, { op: 0.9, weight: 600 });
  if (!isP) b += glassesCallouts(1210);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H0}" viewBox="0 0 ${W} ${H0}">${FILTERS}${b}</svg>`;
}

// the glasses' attachment points and thickness, called out on the head in profile and from the front, for Animation and Rendering
function glassesCallouts(y0) {
  let b = rect(24, y0, 1752, 470, BG, 'stroke="#1b1428" stroke-opacity="0.2"') + text(40, y0 + 26, 'The glasses: attachment points and thickness (for Animation and Rendering). Head units: the head is about 16.6 high and 11 wide; the body is 100.', { size: 15, weight: 700 });
  const s = 22, ox = 200, gy = y0 + 20 + 17 * s + 40;   // the head enlarged 22 times, in profile
  const c = rival({ yaw: 0 }, 'clear'), ctx = makeCtx({ flat: false, pal: PAL.A, swMul: 1.3, faceless: false });
  const st = { yaw: 0, face: null, state: 'neutral', sway: 4, expression: 'neutral', open: 0, forms: 6, wear: 0, hairLoose: false, bg: BG };
  const { svg, sk } = figure(ctx, c, NEUTRAL_UP, st, { yaw: 0 });
  // place the head: HB maps to (ox + 60, gy - 0), scale s
  const hbx = sk.HB.x, hby = sk.HB.y, tx = ox + 80 - hbx * s, ty = gy + hby * s;
  b += `<svg x="40" y="${y0 + 40}" width="520" height="410" viewBox="0 0 520 410" overflow="hidden">${rect(0, 0, 520, 410, '#f3f0f8')}<g transform="translate(${F(tx - 40)} ${F(ty - (y0 + 40))}) scale(${s} ${-s})">${svg}</g></svg>`;
  const P = (x, y) => { const p = sk.Hd(x, y); return [40 + (tx - 40) + p.x * s, y0 + 40 + (ty - (y0 + 40)) - p.y * s]; };
  const marks = [['1', 'nose pad / bridge', 7.0, 10.2, 360, 60], ['2', 'lens centre', 4.2, 10.0, 360, 160], ['3', 'temple hinge', 1.2, 9.9, 360, 255], ['4', 'ear (end of the arm)', -3.6, 9.2, 360, 340]];
  marks.forEach(([n, , hx_, hy_, lx, ly]) => { const [px_, py_] = P(hx_, hy_); b += `<line x1="${F(px_)}" y1="${F(py_)}" x2="${F(40 + lx)}" y2="${F(y0 + 40 + ly)}" stroke="#6b3fa8" stroke-width="1.6"/><circle cx="${F(px_)}" cy="${F(py_)}" r="4" fill="#6b3fa8"/><circle cx="${F(40 + lx)}" cy="${F(y0 + 40 + ly)}" r="11" fill="#6b3fa8"/>` + text(40 + lx, y0 + 40 + ly + 4, n, { size: 12, weight: 700, anchor: 'middle', fill: '#f4f0fa' }); });
  // the front view: the lenses and the dimensions
  const fx = 620, fy = y0 + 40;
  b += `<svg x="${fx}" y="${fy}" width="400" height="410" viewBox="0 0 400 410" overflow="hidden">${rect(0, 0, 400, 410, '#f3f0f8')}</svg>`;
  b += `<svg x="${fx + 20}" y="${fy + 30}" width="360" height="360" viewBox="0 0 512 512" overflow="hidden">${portrait('X', 'A', 'neutral', `a${uid++}`, { draw: glassedFace(APPROVED, 'clear', 0, 0.4, 1) })}</svg>`;
  b += text(fx + 10, fy + 20, 'from the front (the close-up)', { size: 11, op: 0.7 });
  // the table
  const rows = [
    ['Socket / origin', 'a child of the head bone. Either `att_head_brow` with an offset 1.0 down and 0.5 forward, or a new `att_glasses` (a 15th socket): Animation\'s call. Origin: the nose bridge, on the front surface of the face.'],
    ['1 nose pad (bridge)', 'head-local (7.0, 10.2) in profile, on the centre line: the bridge bar is 1.0 wide and 0.35 high, 0.5 forward of the face.'],
    ['2 lens centre', 'head-local (4.2, 10.0) in profile; from the front each lens is centred 3.1 to the side of the centre line, 6.2 wide and 3.0 high, 0.5 in front of the face (so it always covers the eye).'],
    ['3 temple hinge', 'head-local (1.2, 9.9): the outer corner of the lens; the arm is a bar 0.25 thick that runs back 4.8 to the ear.'],
    ['4 ear (end of the arm)', 'head-local (-3.6, 9.2): the arm ends over the ear and does not clip the hair; a nudge gesture targets point 3.'],
    ['Thickness', 'rim 0.18 (thin, even, no lit line); arm 0.25; bridge 0.35; lens a single plane 0.1 thick. Overall the glasses are about 12.4 wide against a head 11 wide (0.8 overhang each side) and 0.6 deep.'],
    ['Budget', 'frame and arms 40 triangles at most; lenses 2 quads (8 triangles). One lens material slot with one scalar, `glare` 0 to 1: 0 = the dark violet tint (alpha 0.46), 1 = opaque pale violet #c0a0ee with one wedge #d8c2f8; never white.'],
  ];
  rows.forEach(([a, t], i) => { b += text(1050, y0 + 62 + i * 58, a, { size: 12, weight: 700 }) + paras(1050, y0 + 78 + i * 58, t, 78, 11, 13.5, { op: 0.9 }); });
  return b;
}

// ---------------------------------------------------------------------------------------------------------------- 3. the close-up sets
function facesSheet(fk) {
  const isP = fk === 'P', W = 1800, ps = 200, H0 = isP ? 640 : 1130;
  let b = rect(0, 0, W, H0, '#dcd8e6') + header(isP ? 'The Protagonist: close-up face set (approved by Orb)' : 'The rival: close-up face set, glasses clear and glare (approved by Orb)', isP ? 'Eight expressions at 200 px and in grey at 100 px: unmasked, with heavier lids, an angled brow and the short swept tuft. No mask. Pending Legal review.' : 'Eight expressions with frame C clear (eyes dimly visible) and with the glare on (eyes fully hidden, the mouth carries the face), at 200 px, and the damage stages. No mask. Pending Legal review.', W);
  const row = (label, y, fn) => { b += text(24, y + 14, label, { size: 14, weight: 700 }); ALLX.forEach((e, i) => { b += fn(e, 24 + i * 221, y + 22) + text(24 + i * 221 + 4, y + 22 + ps + 14, e, { size: 11, weight: 600, op: 0.8 }); }); };
  if (isP) {
    row('Protagonist', 124, (e, x, y) => pface(e, x, y, ps));
    ALLX.forEach((e, i) => { b += pface(e, 24 + i * 221 + 50, 124 + 22 + ps + 24, 100, 'filter="url(#grey)"'); });
    b += paras(24, 124 + 22 + ps + 150, 'Signature: the laugh. Dark plated fists and the swept tuft are body features (see the turnaround); the face carries the heavier lids and the angled brow. The tuft here is the short swept one, never a curl on the forehead.', 230, 12, 16, { op: 0.9 });
  } else {
    row('Glasses clear (frame C)', 124, (e, x, y) => rface('clear', x, y, ps, { expr: e }));
    row('Glare on (eyes hidden completely)', 124 + 262, (e, x, y) => rface('glare', x, y, ps, { expr: e }));
    b += text(24, 124 + 262 * 2 + 14, 'Damage stages with the glare on, neutral: fresh, scuffed, torn, ruined (frame C bends, a lens cracks and a shard goes from a corner; the eyes stay covered)', { size: 13, weight: 700 });
    [0, 1, 2, 3].forEach(st => { b += rface('clear', 24 + st * 440, 124 + 262 * 2 + 28, 200, { stage: st }) + rface('glare', 24 + st * 440 + 210, 124 + 262 * 2 + 28, 200, { stage: st, expr: 'smirk' }); });
    b += paras(24, 124 + 262 * 2 + 250, 'Signature: the contempt, and the smirk under the glare. With the glare on the eyes are gone, so the mouth and the head tilt are the whole expression: keep those strong. A cracked lens and glasses knocked off are allowed by Legal and count as no mark.', 230, 12, 16, { op: 0.9 });
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H0}" viewBox="0 0 ${W} ${H0}">${FILTERS}${b}</svg>`;
}

const ORIGIN = '<!-- Origin: procedural approved-look sheet written by art/concepts/refine/gen-approved.mjs (deterministic, no external images or fonts), Art Director session (Claude, claude-sonnet-5-5), 2026-10-04; prompt record art/prompts/ART-0016-approved-launch-pair.md -->' + String.fromCharCode(10);
writeFileSync(join(OUT, 'rival-glare-c.svg'), ORIGIN + glareSheet());
writeFileSync(join(OUT, 'approved-rival-turnaround.svg'), ORIGIN + turnaround('A'));
writeFileSync(join(OUT, 'approved-protagonist-turnaround.svg'), ORIGIN + turnaround('P'));
writeFileSync(join(OUT, 'approved-rival-faces.svg'), ORIGIN + facesSheet('A'));
writeFileSync(join(OUT, 'approved-protagonist-faces.svg'), ORIGIN + facesSheet('P'));
console.log('wrote the approved-look sheets');
