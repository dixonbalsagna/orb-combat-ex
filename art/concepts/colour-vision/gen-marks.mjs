// Origin: procedural sheet writer for the fighters' non-colour marks and the biome patterns (deterministic, no randomness, no external images or fonts).
// Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-07. Human direction: Orb, via the EP.
// Run from the repo root:  node art/concepts/colour-vision/gen-marks.mjs   (writes fighter-marks.svg and biome-patterns.svg here)

import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { V, add, sub, mul, pts } from '../anti-hero/kit.mjs';
import { text, rect, paras, header, BG, F, SIM_DEFS, auraFigureT } from '../sky/draw.mjs';
import { drawFigure, POSE0, PAL } from '../refine/figures.mjs';
import { hero, rival } from '../refine/approved.mjs';
import { BIOME_COLOURS, PATTERNS, STRIP_ORDER, inkOf, MARKS } from './marks.mjs';

const OUT = dirname(fileURLToPath(import.meta.url));
const ORIGIN = '<!-- Origin: procedural marks sheet written by art/concepts/colour-vision/gen-marks.mjs (deterministic, no external images or fonts), Art Director session (Claude, claude-sonnet-5-5), 2026-10-07; prompt record art/prompts/ART-0018-world-light-and-lane-marks.md -->' + String.fromCharCode(10);
const wrapSvg = (w, h, inner) => `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><defs><filter id="grey"><feColorMatrix type="saturate" values="0"/></filter>${SIM_DEFS.replace(/^<filter/, '<filter')}</defs>${inner}</svg>`;
const SIMS = ['default', 'protan', 'deutan', 'tritan', 'grey'];
const filt = k => k === 'default' ? '' : k === 'grey' ? 'filter="url(#grey)"' : `filter="url(#sim-${k})"`;

// ---------------------------------------------------------------------------------------------------------------- the glyphs
const ringPts = (c, r0, r1, n = 20) => { const o = [], i = []; for (let k = 0; k <= n; k++) { const a = k / n * Math.PI * 2; o.push(V(c.x + Math.cos(a) * r0, c.y + Math.sin(a) * r0)); i.push(V(c.x + Math.cos(a) * r1, c.y + Math.sin(a) * r1)); } return [...o, ...i.reverse()]; };
// the figure with its decal: a ring at the Protagonist's near shoulder plate, a slash across the rival's near shoulder and upper arm
function decorated(kind, x, g, s, flat = false) {
  const c = kind === 'P' ? hero({ yaw: 0 }) : rival({ yaw: 0 }, 'clear'), prev = c.after;
  const decal = (ctx, sk) => {
    if (flat) return '';
    if (kind === 'P') { const S = add(sk.S, V(0.6, -0.4)); return ctx.poly(ringPts(S, 3.9, 2.3), '#c4ece6', { sw: 0.7 }); }
    const S = add(sk.S, mul(sub(sk.nearArm.E, sk.S), 0.5)); return ctx.poly([add(S, V(-4.4, -4.6)), add(S, V(-2.0, -4.6)), add(S, V(4.6, 4.2)), add(S, V(2.2, 4.2))], '#d9c4f8', { sw: 0.7 });
  };
  const concept = { ...c, after: (ctx, sk, st, cfg) => (prev ? prev(ctx, sk, st, cfg) : '') + decal(ctx, sk) };
  return drawFigure({ concept, pal: kind === 'P' ? PAL.P : PAL.A, pose: POSE0(kind), flat, bg: BG, x, ground: g, s });
}
// an aura ring (solid, or broken by a diagonal stripe mask) with the dark keyline
let mid = 0;
function auraMark(kind, x, g, s, colour, broken) {
  const id = `am${mid++}`, c = kind === 'P' ? hero({ yaw: 0 }) : rival({ yaw: 0 }, 'clear'), pal = kind === 'P' ? PAL.P : PAL.A;
  const flat = drawFigure({ concept: c, pal, pose: POSE0(kind), flat: true, bg: BG, x, ground: g, s });
  const defs = `<defs><filter id="${id}k" x="-30%" y="-30%" width="160%" height="160%"><feMorphology in="SourceAlpha" operator="dilate" radius="${F(0.045 * 100 * s / 1.5 + 1.2)}" result="d"/><feFlood flood-color="#0a0d14"/><feComposite in2="d" operator="in"/></filter><filter id="${id}a" x="-30%" y="-30%" width="160%" height="160%"><feMorphology in="SourceAlpha" operator="dilate" radius="${F(0.04 * 100 * s / 1.5 + 0.6)}" result="d"/><feFlood flood-color="${colour}"/><feComposite in2="d" operator="in"/></filter>` +
    `<pattern id="${id}p" width="10" height="10" patternUnits="userSpaceOnUse" patternTransform="rotate(40)"><rect width="6" height="10" fill="#fff"/></pattern><mask id="${id}m" maskUnits="userSpaceOnUse" x="${F(x - 90 * s)}" y="${F(g - 130 * s)}" width="${F(180 * s)}" height="${F(150 * s)}"><rect x="${F(x - 90 * s)}" y="${F(g - 130 * s)}" width="${F(180 * s)}" height="${F(150 * s)}" fill="url(#${id}p)"/></mask></defs>`;
  return `${defs}<g filter="url(#${id}k)">${flat}</g><g ${broken ? `mask="url(#${id}m)"` : ''}><g filter="url(#${id}a)">${flat}</g></g>`;
}
function marksSheet() {
  const W = 1800, H = 1010;
  let b = rect(0, 0, W, H, '#dcd8e6') + header('A mark that is not a colour: one per fighter', 'Never colour alone. Each fighter has a glyph: a ring (the Protagonist) and a slash (the rival), used on the body, on the aura, on the HUD chip and on the planet strip\'s marker, so a fighter is told apart with the colour turned off or confused. Shown in colour, in the three simulated visions and in grey. Working labels, pending Legal review.', W);
  // columns: the five visions; rows: the figures with decals at 100 px, the aura rings, the chips, the markers
  SIMS.forEach((k, i) => { b += text(24 + i * 350, 138, k === 'default' ? 'typical vision' : k === 'grey' ? 'greyscale' : k, { size: 14, weight: 700 }); });
  SIMS.forEach((k, i) => {
    const x0 = 24 + i * 350, f = filt(k);
    b += rect(x0, 150, 340, 250, BG, 'stroke="#1b1428" stroke-opacity="0.2"');
    b += `<g ${f}>` + decorated('P', x0 + 80, 380, 2.2) + decorated('A', x0 + 240, 380, 2.2) + '</g>';
    b += rect(x0, 410, 340, 190, BG, 'stroke="#1b1428" stroke-opacity="0.2"');
    b += `<g ${f}>` + auraMark('P', x0 + 80, 560, 1.2, '#8fd6ff', false) + auraMark('A', x0 + 190, 560, 1.2, '#9a80d8', true) + decorated('P', x0 + 80, 560, 1.2) + decorated('A', x0 + 190, 560, 1.2) + '</g>';
    // chips and strip markers
    b += rect(x0, 610, 340, 120, BG, 'stroke="#1b1428" stroke-opacity="0.2"');
    const chip = (cx, cy, kind, col) => kind === 'P'
      ? `<circle cx="${cx}" cy="${cy}" r="13" fill="${col}" stroke="#0a0d14" stroke-width="2"/><circle cx="${cx}" cy="${cy}" r="6" fill="none" stroke="#0a0d14" stroke-width="2.2"/>`
      : `<polygon points="${cx},${cy - 15} ${cx + 15},${cy} ${cx},${cy + 15} ${cx - 15},${cy}" fill="${col}" stroke="#0a0d14" stroke-width="2"/><line x1="${cx - 6}" y1="${cy + 7}" x2="${cx + 6}" y2="${cy - 7}" stroke="#0a0d14" stroke-width="2.6"/>`;
    b += `<g ${f}>${chip(x0 + 40, 650, 'P', '#8fd6ff')}${chip(x0 + 100, 650, 'A', '#9a80d8')}${chip(x0 + 40, 700, 'P', '#46b9b9')}${chip(x0 + 100, 700, 'A', '#6b0bcb')}</g>`;
    b += text(x0 + 150, 654, 'HUD chips (default,', { size: 10.5, op: 0.8 }) + text(x0 + 150, 668, 'then the protan preset)', { size: 10.5, op: 0.8 });
    // the strip marker
    b += `<g ${f}><rect x="${x0 + 150}" y="684" width="170" height="10" fill="#7c8e4b" stroke="#0a0d14"/>${chip(x0 + 190, 689, 'P', '#8fd6ff').replace(/r="13"/, 'r="9"').replace(/r="6"/, 'r="4"')}${chip(x0 + 270, 689, 'A', '#9a80d8').replace(/15/g, '11')}</g>` + text(x0 + 150, 716, 'the planet strip\'s markers', { size: 10.5, op: 0.8 });
  });
  b += text(24, 640 + 106, '', {});
  b += text(24, 770, 'What the marks are', { size: 15, weight: 700 });
  b += paras(24, 792, `Protagonist: a ring. ${MARKS.protagonist.body_decal.where}: ${MARKS.protagonist.body_decal.shape}, ${MARKS.protagonist.body_decal.ink}. Aura: ${MARKS.protagonist.aura_pattern}. HUD chip: ${MARKS.protagonist.hud_chip}. Planet strip marker: ${MARKS.protagonist.strip_marker}.`, 230, 12, 16, { op: 0.9 });
  b += paras(24, 826, `Rival: a slash. ${MARKS.rival.body_decal.where}: ${MARKS.rival.body_decal.shape}, ${MARKS.rival.body_decal.ink}. Aura: ${MARKS.rival.aura_pattern}. HUD chip: ${MARKS.rival.hud_chip}. Planet strip marker: ${MARKS.rival.strip_marker}.`, 230, 12, 16, { op: 0.9 });
  b += paras(24, 866, `The rule for future fighters: ${MARKS.rule} The glyphs come from the fighters\' own shape languages (the Protagonist\'s circles, the rival\'s blades), so they also belong to the silhouette. In the aura row the rival\'s ring is broken into dashes and the Protagonist\'s is solid, so the two are told apart in grey at 24 px. The figures here are the approved concept figures with the decal added; the decal sits on the shoulder plate, where a profile and a three-quarter view both show it (it is not on the chest, which a side view hides).`, 230, 12, 16, { op: 0.9 });
  b += paras(24, 944, 'Data: data/art/colour-vision.json under _non_colour_marks. UI owns the chips and the strip markers; Rendering the decal and the aura pattern (a dash mask on the aura ring).', 230, 12, 16, { op: 0.9, weight: 600 });
  return wrapSvg(W, H, b);
}

// ---------------------------------------------------------------------------------------------------------------- the biome patterns
function patternDefs() {
  return Object.entries(PATTERNS).map(([k, p]) => {
    const ink = inkOf(BIOME_COLOURS[k]);
    const body = p.circles ? p.circles.map(([cx, cy, r]) => `<circle cx="${cx}" cy="${cy}" r="${r}" fill="${ink}"/>`).join('') : p.mode === 'fill' ? `<path d="${p.d}" fill="${ink}"/>` : `<path d="${p.d}" fill="none" stroke="${ink}" stroke-width="${p.stroke}" stroke-linecap="round" stroke-linejoin="round"/>`;
    return `<pattern id="pat-${k}" width="${p.tile}" height="${p.tile}" patternUnits="userSpaceOnUse">${rect(0, 0, p.tile, p.tile, BIOME_COLOURS[k])}${body}</pattern>`;
  }).join('');
}
function stripOf(x, y, w, h, patterned, f) {
  let o = `<g ${f}>`, cx = x;
  STRIP_ORDER.forEach(([k, share]) => { const sw = w * share; o += rect(cx, y, sw, h, patterned ? `url(#pat-${k})` : BIOME_COLOURS[k]) + `<line x1="${F(cx)}" y1="${y}" x2="${F(cx)}" y2="${y + h}" stroke="#0a0d14" stroke-width="1"/>`; cx += sw; });
  return o + `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="none" stroke="#0a0d14" stroke-width="1.5"/></g>`;
}
function patternsSheet2() {
  const W = 1800, H = 1100, sx = 24, sw = 1752;
  let b = rect(0, 0, W, H, '#dcd8e6') + header('The planet strip: a pattern per biome', 'The strip is colour only today. Each of the seven biomes gets a pattern on a 12 by 12 tile in an ink that is the biome colour moved a fifth of the lightness scale away from the middle, so the pattern reads on the colour and in grey. Shown as it is, with patterns, and through each simulated vision and in grey. Working labels, pending Legal review.', W);
  b += `<defs>${patternDefs()}</defs>`;
  b += text(24, 136, 'The vocabulary (a tile enlarged 8 times, and at 1 time)', { size: 15, weight: 700 });
  Object.keys(PATTERNS).forEach((k, i) => {
    const x = 24 + i * 250;
    b += `<svg x="${x}" y="150" width="96" height="96" viewBox="0 0 12 12"><rect width="12" height="12" fill="url(#pat-${k})"/></svg><rect x="${x}" y="150" width="96" height="96" fill="none" stroke="#0a0d14"/>`;
    b += `<rect x="${x + 110}" y="150" width="60" height="30" fill="url(#pat-${k})" stroke="#0a0d14"/>` + text(x, 266, `${k}: ${PATTERNS[k].name}`, { size: 12, weight: 700 }) + text(x, 282, `base ${BIOME_COLOURS[k]}, ink ${inkOf(BIOME_COLOURS[k])}`, { size: 10, op: 0.75 });
  });
  b += text(24, 322, 'The strip, the biomes in the world\'s order, 36 px high', { size: 15, weight: 700 });
  b += stripOf(sx, 336, sw, 36, false, '') + text(sx, 388, 'as it is: colour only', { size: 11, weight: 600 }) + stripOf(sx, 400, sw, 36, true, '') + text(sx, 452, 'with patterns', { size: 11, weight: 600 });
  b += text(24, 490, 'Through the simulated visions and in grey: colour only (upper) and with patterns (lower)', { size: 15, weight: 700 });
  [['protan', 'protan'], ['deutan', 'deutan'], ['tritan', 'tritan'], ['grey', 'greyscale']].forEach(([k, lab], i) => {
    const y = 506 + i * 112;
    b += stripOf(sx, y, sw, 36, false, filt(k)) + stripOf(sx, y + 44, sw, 36, true, filt(k)) + text(sx, y + 96, lab, { size: 11, weight: 700 });
  });
  b += paras(24, 970, 'The patterns are shapes, so they survive every vision and grey: waves for the ocean, grass ticks for plains, a grid of squares for the city, roofs for villages, round crowns for forest, a stipple for desert, peaks for mountains. Forest (dense solid circles) and desert (sparse tiny dots) are the closest pair and still differ at 12 px by weight. UI draws the strip; the tile definitions (path or circles, stroke, ink) are in data/art/colour-vision.json under _biome_patterns.', 230, 12, 16, { op: 0.9 });
  return wrapSvg(W, H, b);
}

writeFileSync(join(OUT, 'fighter-marks.svg'), ORIGIN + marksSheet());
writeFileSync(join(OUT, 'biome-patterns.svg'), ORIGIN + patternsSheet2());
console.log('wrote fighter-marks.svg and biome-patterns.svg');
