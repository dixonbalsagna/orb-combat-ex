// Origin: the beach shell, a small cover shape for World's `shell` prop (docs/world/props-w5.md: 0.4 to 0.9 fighter heights), drawn in the cover style of this folder. Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-29. Human direction: Orb, via the EP.
// Flat faceted polygons with the keyline, lit left and shade right, no gradients. Writes docs/art/shell-cover.svg (the sheet) and prints the triangle counts.
//   node art/concepts/biomes/shell.mjs
import { writeFileSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Frame } from './draw.mjs';
import { dE00 } from '../sky/colour.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '../../..');
const PX = 86 / 75;   // pixels per unit at fight size (as covers.mjs)
const F = n => (Math.round(n * 10) / 10).toString();
const FONT = "font-family=\"'Segoe UI', system-ui, Arial, sans-serif\"";
const text = (x, y, t, { size = 12, weight = 400, fill = '#1b1428', anchor = 'start' } = {}) => `<text x="${F(x)}" y="${F(y)}" ${FONT} font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}">${String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;')}</text>`;

// the triangle count of a Frame's output, as covers.mjs counts it: filled polygons (n - 2 each), polylines (2 per segment)
function triCount(svg) {
  let t = 0;
  for (const m of svg.matchAll(/<polygon points="([^"]+)" fill="([^"]+)"/g)) { if (m[2] === 'none') continue; t += Math.max(0, m[1].trim().split(/\s+/).length - 2); }
  for (const m of svg.matchAll(/<polyline points="([^"]+)"/g)) t += 2 * Math.max(0, m[1].trim().split(/\s+/).length - 1);
  return t;
}

// the shell's three tones (lit, mid, shade): rose pink, chosen against the beach tones and every energy lane colour (shellcheck.mjs)
export const SHELL = ['#e4bcc4', '#cc90a0', '#94626e'];
const KEY = '#0a0d14';
const lin = c => { c /= 255; return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; };
const rl = h => { const n = parseInt(h.slice(1), 16); return 0.2126 * lin(n >> 16 & 255) + 0.7152 * lin(n >> 8 & 255) + 0.0722 * lin(n & 255); };

// one scallop shell standing on its hinge, h units tall (the fan's radius), leaning lean degrees to the right
export function shell(f, x, y, h, lean = 8) {
  const L = lean * Math.PI / 180, hx = x, hy = y + h * 0.1;   // the hinge, a little above the foot (the ear sits below it)
  const ribs = 7, span = 126 * Math.PI / 180;
  const P = (r, a) => [hx + Math.sin(a + L) * r, hy + Math.cos(a + L) * r];
  // outer edge: a scallop, a lobe tip at each rib centre and a notch between (0.86 of the radius)
  const edge = [];
  for (let i = 0; i <= ribs; i++) {
    const a0 = -span / 2 + span * i / ribs;
    if (i > 0) edge.push(P(h * 0.93, a0 - span / ribs / 2));
    const k = i < ribs ? 1 : 1;
    edge.push(P(h * k, a0));
  }
  // the ear: the small flat base where the two halves meet
  f.poly([[hx - h * 0.2, y], [hx + h * 0.2, y], [hx + h * 0.12, hy + h * 0.06], [hx - h * 0.12, hy + h * 0.06]], SHELL[2]);
  // the fan: a triangle from the hinge to each pair of neighbouring edge points, tone by direction (lit left, mid centre, shade right)
  const tips = edge.filter((_, i) => i % 2 === 0), n = tips.length;
  for (let i = 0; i < edge.length - 1; i++) {
    const t = i / (edge.length - 2);
    const col = t < 0.34 ? SHELL[0] : t < 0.7 ? SHELL[1] : SHELL[2];
    f.poly([[hx, hy], edge[i], edge[i + 1]], col, { sw: 0.8 });
  }
  // the ribs: thin keyline strokes from the hinge to each lobe tip
  for (let i = 1; i < ribs; i++) f.line([[hx, hy], tips[i]], KEY, 0.8);
  // one growth line across the ribs, a third of the way out
  f.line(tips.map((t, i) => P(h * 0.62, -span / 2 + span * i / ribs)), KEY, 0.8);
  return n;
}

// the sheet: three sizes at fight size on a strip of beach sand, beside a fighter's height
const beach = JSON.parse(readFileSync(join(ROOT, 'data/art/biomes.json'), 'utf8')).biomes.beach.palette;
const sizes = [[30, 'smallest, 0.4 heights'], [48, 'middle, 0.64 heights'], [68, 'largest, 0.9 heights']];
const W = 1000, H = 430, groundY = 250;
let out = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"><rect width="${W}" height="${H}" fill="#dcd8e6"/><rect width="${W}" height="62" fill="#1b1428"/>`;
out += text(24, 28, 'The beach shell: a cover shape for World shell props', { size: 20, weight: 600, fill: '#fff' }) + text(24, 50, 'flat faceted rose pink, lit left, shade right, keyline; 0.4 to 0.9 fighter heights (30 to 68 units), shown at fight size (1 unit = 1.147 px)', { size: 12, fill: '#cfc7e0' });
const strip = new Frame({ px: 24, py: 90, S: PX, wx0: 0, ww: 820, wh: 150 });
strip.rect(0, 0, 820, 18, beach.ground[1]); strip.rect(0, 0, 820, 4, beach.ground[2]);
let tris = 0, svgShells = '';
sizes.forEach(([h], i) => { const f = new Frame({ px: 24, py: 90, S: PX, wx0: 0, ww: 820, wh: 150 }); const x = 140 + i * 210; shell(f, x, 18, h, [10, -6, 14][i]); svgShells += f.svg(); if (i === 1) tris = triCount(f.svg()); });
// a fighter's height: a plain bar, 75 units, beside the shells
const ruler = new Frame({ px: 24, py: 90, S: PX, wx0: 0, ww: 820, wh: 150 });
ruler.poly([[740, 18], [768, 18], [768, 93], [740, 93]], '#7d6f9c', { sw: 1.1 });
out += `<g>${strip.svg()}${svgShells}${ruler.svg()}</g>`;
out += text(24 + 140 * PX, 90 + 150 * PX + 26, sizes[0][1], { size: 11, anchor: 'middle' }) + text(24 + 350 * PX, 90 + 150 * PX + 26, sizes[1][1], { size: 11, anchor: 'middle' }) + text(24 + 560 * PX, 90 + 150 * PX + 26, sizes[2][1], { size: 11, anchor: 'middle' }) + text(24 + 754 * PX, 90 + 150 * PX + 26, 'a fighter, 75 units', { size: 11, anchor: 'middle' });
// tones
const gTones = [...beach.ground, ...beach.rock, beach.subsoil, beach.accent];
const near = h => Math.min(...gTones.map(g => dE00(h, g)));
out += text(24, 328, 'Tones (lit, mid, shade): ' + SHELL.join('  '), { size: 13, weight: 600 });
SHELL.forEach((h, i) => { out += `<rect x="${24 + i * 300}" y="340" width="130" height="34" fill="${h}" stroke="${KEY}" stroke-width="1.1"/>` + text(24 + i * 300 + 140, 355, `${h}, luminance ${rl(h).toFixed(2)}`, { size: 11, weight: 600 }) + text(24 + i * 300 + 140, 371, `${near(h).toFixed(1)} from the nearest beach tone`, { size: 10.5 }); });
out += text(24, 414, `Triangles at the middle size: ${tris} (the keyline is a stroke). Three faces by direction; seven ribs; a scalloped edge; one ear at the hinge.`, { size: 11 });
out += '</svg>';
writeFileSync(join(ROOT, 'docs/art/shell-cover.svg'), out);
console.log('wrote docs/art/shell-cover.svg; triangles at the middle size', tris);
