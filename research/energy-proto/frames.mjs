// Saves frames of one clip at chosen ticks, side by side, for a close look: node research/energy-proto/frames.mjs C10 150,220,400 out.png
import { readFileSync } from 'node:fs';
import { Img } from '../planet-gen/lib/img.mjs';
const src = readFileSync('docs/ep/prototypes/energy-v1.html', 'utf8');
const a = src.indexOf('// ==== ENERGY SIM (no DOM) ===='), b = src.indexOf('// ==== PAGE (DOM) ====');
const E = new Function(src.slice(a, b) + '\nreturn E;')();
const [clipN, ticksArg, out] = process.argv.slice(2), ticks = ticksArg.split(',').map(Number);
const ci = E.CLIPS.findIndex((c) => c.n === clipN), run = E.newRun(ci, 'demo'), W = E.W, H = E.H, shots = [];
const hex = (s) => [parseInt(s.slice(1, 3), 16), parseInt(s.slice(3, 5), 16), parseInt(s.slice(5, 7), 16)];
function R(img) { return { clear(c) { img.fill(0, 0, W, H, hex(c)); }, poly(p, c) { const n = p.length / 2; if (n < 3) return; let y0 = 1e9, y1 = -1e9; for (let i = 1; i < p.length; i += 2) { y0 = Math.min(y0, p[i]); y1 = Math.max(y1, p[i]); } const col = hex(c), xs = []; for (let y = Math.max(0, Math.ceil(y0 - 0.5)); y <= Math.min(H - 1, Math.floor(y1 - 0.5)); y++) { const s = y + 0.5; xs.length = 0; for (let i = 0, j = n - 1; i < n; j = i++) { const yi = p[2 * i + 1], yj = p[2 * j + 1]; if ((yi > s) !== (yj > s)) xs.push(p[2 * i] + (s - yi) / (yj - yi) * (p[2 * j] - p[2 * i])); } xs.sort((u, v) => u - v); for (let k = 0; k + 1 < xs.length; k += 2) for (let x = Math.max(0, Math.ceil(xs[k] - 0.5)); x <= Math.min(W - 1, Math.floor(xs[k + 1] - 0.5)); x++) img.set(x, y, col); } } }; }
const maxT = Math.max(...ticks);
for (let t = 0; t <= maxT; t++) { E.stepRun(run); if (ticks.includes(run.t)) { const img = new Img(W, H, null); E.draw(run, R(img)); img.text(8, H - 18, `T ${run.t}`, 2, [30, 30, 30]); shots.push(img.shrink(2)); } }
const sheet = new Img(shots[0].w * Math.min(3, shots.length), shots[0].h * Math.ceil(shots.length / 3), [24, 26, 34]);
shots.forEach((im, k) => sheet.blit(im, (k % 3) * im.w, Math.floor(k / 3) * im.h));
sheet.save(out); console.log('saved', out);
