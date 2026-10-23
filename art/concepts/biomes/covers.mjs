// Origin: the cover silhouette sheet at true pixel size, with triangle counts (deterministic). Written by the Art Director session (Claude, claude-sonnet-5-5), 2026-10-24.
// For Rendering: every cover shape of the biome look bible, clean and charred, drawn at 1 unit = 1.147 px (a fighter is 75 units = 86 px, the game's fight size), so a silhouette is judged at the size it will be seen.
// The triangle count is of the flat mesh the drawing needs: every polygon triangulated as a fan (n - 2), a thin line as a quad (2 per segment); the keyline is a stroke (Rendering's outline), not geometry.
import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { BIOMES } from './spec.mjs';
import { COVER, Frame, mix, rng } from './draw.mjs';

const OUT = dirname(fileURLToPath(import.meta.url));
export const PX = 86 / 75;   // pixels per unit at fight size
const F = n => (Math.round(n * 10) / 10).toString();
const esc = t => String(t).replace(/&/g, '&amp;').replace(/</g, '&lt;');
const FONT = "font-family=\"'Segoe UI', system-ui, Arial, sans-serif\"";
const text = (x, y, t, { size = 11, weight = 400, fill = '#1b1428', anchor = 'start', op = 1 } = {}) => `<text x="${F(x)}" y="${F(y)}" ${FONT} font-size="${size}" font-weight="${weight}" fill="${fill}" text-anchor="${anchor}" opacity="${op}">${esc(t)}</text>`;
const rect = (x, y, w, h, fill, extra = '') => `<rect x="${F(x)}" y="${F(y)}" width="${F(w)}" height="${F(h)}" fill="${fill}" ${extra}/>`;

// the triangle count of a Frame's output: polygons with a fill (n - 2 each), polylines (2 per segment); outline-only polygons (fill none) do not count
export function triCount(svg) {
  let t = 0;
  for (const m of svg.matchAll(/<polygon points="([^"]+)" fill="([^"]+)"/g)) { if (m[2] === 'none') continue; t += Math.max(0, m[1].trim().split(/\s+/).length - 2); }
  for (const m of svg.matchAll(/<polyline points="([^"]+)"/g)) t += 2 * Math.max(0, m[1].trim().split(/\s+/).length - 1);
  return t;
}
const kinds = () => { const m = new Map(); for (const [id, b] of Object.entries(BIOMES)) for (const c of b.cover) if (c.n > 0) { if (!m.has(c.k)) m.set(c.k, { k: c.k, biomes: [], h: [c.h[0], c.h[1]], first: id }); const e = m.get(c.k); e.biomes.push(id); e.h = [Math.min(e.h[0], c.h[0]), Math.max(e.h[1], c.h[1])]; } return [...m.values()]; };

// draw one kind in one state into a cell; returns { svg, tris }
export function drawKind(kind, state, h, id) {
  const b = BIOMES[id], f = new Frame({ px: 0, py: 0, S: PX, wx0: -150, ww: 300, wh: Math.max(60, h * 1.15 + 20) });
  const fn = COVER[kind]; if (!fn) return { f, tris: 0 };
  fn({ f, pal: b.pal, state, rnd: rng(1234), S: PX }, 0, 8, h);
  const svg = f.svg();
  return { f, svg, tris: triCount(svg) };
}
export function coverTable() {
  return kinds().map(e => { const h = Math.round((e.h[0] + e.h[1]) / 2), c = drawKind(e.k, 'clean', h, e.first), x = drawKind(e.k, 'burned', h, e.first); return { kind: e.k, biomes: e.biomes, height_range_u: e.h, typical_height_u: h, typical_height_px: Math.round(h * PX), width_px: null, tris_clean: c.tris, tris_charred: x.tris }; });
}

export function coverSheet() {
  const ks = kinds(), CW = 700, COLS = 3, PADX = 20; let s = '', y = 120;
  const rows = []; for (let i = 0; i < ks.length; i += COLS) rows.push(ks.slice(i, i + COLS));
  s += rect(0, 0, COLS * CW, 104, '#1b1428') + text(30, 46, 'Cover silhouettes at true pixel size, clean and charred', { size: 30, weight: 700, fill: '#f4f0fa' });
  s += text(30, 70, `1 unit = ${PX.toFixed(3)} px: a fighter is 75 units, 86 px (the grey figure at each row's left). Each shape at the middle of its height range; the left is clean, the right charred (burned: a black trunk and branches, or stubs and ash). Flat faces, a keyline stroke (not geometry).`, { size: 12, fill: '#cfc6e6' });
  s += text(30, 90, 'Triangles are of the flat mesh: every polygon fanned, every thin line a quad. The tools that draw this: art/concepts/biomes/covers.mjs. Concept art for Rendering; no character art.', { size: 12, fill: '#cfc6e6' });
  const table = [];
  for (const row of rows) {
    const items = row.map(e => { const h = Math.round((e.h[0] + e.h[1]) / 2), c = drawKind(e.k, 'clean', h, e.first), x = drawKind(e.k, 'burned', h, e.first); return { e, h, c, x }; });
    const hpx = Math.max(...items.map(i => i.h * PX)), rowH = Math.max(120, hpx + 78);
    s += rect(0, y - 8, COLS * CW, rowH, '#e8e5ee', 'stroke="#1b1428" stroke-opacity="0.15"');
    // the scale figure
    const gy = y + hpx + 14, sx = 18, g = '#8b8794';
    s += `<polygon points="${sx - 6},${gy} ${sx - 6},${gy - 38} ${sx - 9},${gy - 53} ${sx + 9},${gy - 53} ${sx + 6},${gy - 38} ${sx + 6},${gy}" fill="${g}" stroke="#0a0d14" stroke-width="1"/><circle cx="${sx}" cy="${gy - 59}" r="6" fill="${g}" stroke="#0a0d14" stroke-width="1"/>` + text(sx, gy + 14, '86 px', { size: 9, anchor: 'middle', op: 0.6 });
    items.forEach((it, i) => {
      const x0 = i * CW + 44, cellW = CW - 54, half = cellW / 2;
      for (const [j, st] of [[0, it.c], [1, it.x]]) {
        const ox = x0 + j * half + half / 2, f = st.f;
        // re-draw into a positioned frame: translate the frame's output (origin at its own 0,0) to the sheet
        const dx = ox - (f.W / 2), dy = gy - (f.H - 8 * PX);
        s += `<g transform="translate(${F(dx)} ${F(dy)})">${st.svg ?? ''}</g>`;
        s += `<line x1="${F(x0 + j * half + 8)}" y1="${F(gy)}" x2="${F(x0 + j * half + half - 8)}" y2="${F(gy)}" stroke="#1b1428" stroke-opacity="0.3"/>`;
        s += text(ox, gy + 14, `${j ? 'charred' : 'clean'}: ${st.tris} tris`, { size: 10, anchor: 'middle', op: 0.75 });
      }
      s += text(x0, y + 8, it.e.k, { size: 13, weight: 700 }) + text(x0 + cellW, y + 8, `${Math.round(it.e.h[0] * PX)} to ${Math.round(it.e.h[1] * PX)} px (${it.e.h[0]} to ${it.e.h[1]} u)`, { size: 10, anchor: 'end', op: 0.7 }) + text(x0, y + 22, it.e.biomes.join(', '), { size: 9.5, op: 0.6 });
      table.push({ kind: it.e.k, biomes: it.e.biomes, height_range_u: it.e.h, height_range_px: [Math.round(it.e.h[0] * PX), Math.round(it.e.h[1] * PX)], tris_clean: it.c.tris, tris_charred: it.x.tris });
    });
    y += rowH + 4;
  }
  const W = COLS * CW, H = y + 16;
  return { svg: `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${rect(0, 0, W, H, '#dcd8e6')}${s}</svg>`, table };
}
if (process.argv[1] === fileURLToPath(import.meta.url)) { const r = coverSheet(); writeFileSync(join(OUT, 'cover-sheet.svg'), r.svg); console.log('wrote cover-sheet.svg;', r.table.length, 'kinds;', r.table.map(t => `${t.kind} ${t.tris_clean}/${t.tris_charred}`).join(', ')); }
