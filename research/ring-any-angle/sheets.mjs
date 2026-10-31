// Pictures for research.md, from the same drawing as the page: the moments round one large ask, on the worlds compared, with the
// scripted fight's inputs. Node, no browser. Each sheet is four ticks of one world, stacked.
//   node research/ring-any-angle/sheets.mjs [out dir]
import { readFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { Img } from '../planet-gen/lib/img.mjs';
import { surf } from '../planet-gen/gen/base.mjs';
import { sin, cos, atan2f, R } from '../planet-gen/lib/det.mjs';

const code = readFileSync(new URL('./sim.js', import.meta.url), 'utf8') + readFileSync(new URL('./draw.js', import.meta.url), 'utf8');
const { RAA, RAD } = new Function('surf', 'sin', 'cos', 'atan2f', 'R', code + '\nreturn { RAA, RAD };')(surf, sin, cos, atan2f, R);
const OUT = process.argv[2] || 'docs/world/ring-any-angle/img'; mkdirSync(OUT, { recursive: true });
const W = RAD.W, H = RAD.H, hex = (s) => [parseInt(s.slice(1, 3), 16), parseInt(s.slice(3, 5), 16), parseInt(s.slice(5, 7), 16)];
function makeR(img, oy) {
  const cache = new Map(), rgb = (c) => { let v = cache.get(c); if (!v) { v = hex(c); cache.set(c, v); } return v; };
  return {
    clear(c) { img.fill(0, oy, W, H, rgb(c)); },
    text(x, y, str, size, c) { img.text(Math.round(x), Math.round(y) + oy, str, 1, rgb(c)); },
    poly(p, c) {
      const n = p.length / 2; if (n < 3) return; let y0 = Infinity, y1 = -Infinity;
      for (let i = 1; i < p.length; i += 2) { if (p[i] < y0) y0 = p[i]; if (p[i] > y1) y1 = p[i]; }
      if (!(y1 >= y0)) return; const col = rgb(c), ya = Math.max(0, Math.ceil(y0 - 0.5)), yb = Math.min(H - 1, Math.floor(y1 - 0.5)), xs = [];
      for (let y = ya; y <= yb; y++) { const sy = y + 0.5; xs.length = 0;
        for (let i = 0, j = n - 1; i < n; j = i++) { const yi = p[2 * i + 1], yj = p[2 * j + 1]; if ((yi > sy) !== (yj > sy)) xs.push(p[2 * i] + (sy - yi) / (yj - yi) * (p[2 * j] - p[2 * i])); }
        xs.sort((u, v) => u - v);
        for (let k = 0; k + 1 < xs.length; k += 2) { const xa = Math.max(0, Math.ceil(xs[k] - 0.5)), xb = Math.min(W - 1, Math.floor(xs[k + 1] - 0.5)); for (let x = xa; x <= xb; x++) { const o = ((y + oy) * W + x) * 3; img.d[o] = col[0]; img.d[o + 1] = col[1]; img.d[o + 2] = col[2]; } } }
    } };
}
// a send with a 90-degree ask on its first tick, then a flight: one fight for every world
const script = RAA.genLaunch(90), ticks = [58, 100, 170, 300];
for (const key of ['A-fast', 'D3', 'E']) {
  RAA.clearMemo(); const run = RAA.mkRun(key), img = new Img(W, (H + 4) * ticks.length, [255, 255, 255]);
  script.forEach((w, i) => { run.tick(w); const k = ticks.indexOf(i); if (k >= 0) { RAD.draw(run, makeR(img, k * (H + 4)), 'TICK ' + i + ' (THE ASK IS AT 60)'); } });
  img.save(join(OUT, 'launch-90-' + key + '.png')); console.log('saved', key);
}
