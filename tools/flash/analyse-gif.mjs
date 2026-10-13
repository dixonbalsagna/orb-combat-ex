// The flash check for an animated GIF, under the combined rule (docs/tools/flash-check.md): the GIF is decoded with tools/flash/gif.mjs (no dependency), laid out on a 60-ticks-a-second
// timeline as a browser would show it (each frame held for its delay, a delay under 20 ms shown as 100 ms), the start of the clip appended again so the loop's seam is analysed
// too, shrunk to at most 640 px wide, and run through tools/flash/wcag.js. The clip is taken as the WHOLE frame: on a phone it fills the screen, so its changes are measured against a
// field the size of the clip, which is stricter than the same clip in a column of a desktop page.
//
//   node tools/flash/analyse-gif.mjs <file.gif> [--json out.json]        exit 0 on PASS, 1 on OVER GATE or FAIL, 2 on a file that cannot be analysed
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { decodeGif, timeline } from './gif.mjs';

const require = createRequire(import.meta.url);
const W = require('./wcag.js');
const V = require('./verdict.js');
const MAX_WIDTH = 640;
const SEAM_TICKS = 121;   // a second of warm-up and the two-second cross-check's memory, so the loop's seam is inside the counted frames

/** Analyse a GIF file (a Buffer or a path). Returns { result (wcag.analyse), width, height, ticks, seconds, frames, loop }. */
export function analyseGif(file) {
  const gif = decodeGif(Buffer.isBuffer(file) ? file : readFileSync(file));
  if (gif.frames.length < 2) throw new Error('a GIF with one frame does not move: nothing to analyse');
  const ticks = timeline(gif.frames, 60, SEAM_TICKS);
  const shrink = Math.max(1, Math.ceil(gif.width / MAX_WIDTH));
  const w = Math.floor(gif.width / shrink), h = Math.floor(gif.height / shrink);
  const cache = new Map();
  const frame = (i) => {
    if (cache.has(i)) return cache.get(i);
    const src = gif.frames[i].rgba;
    const data = new Uint8Array(w * h * 4);
    const n = shrink * shrink;
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
      let r = 0, g = 0, b = 0;
      for (let j = 0; j < shrink; j++) for (let k = 0; k < shrink; k++) { const q = ((y * shrink + j) * gif.width + (x * shrink + k)) * 4; r += src[q]; g += src[q + 1]; b += src[q + 2]; }
      const d = (y * w + x) * 4;
      data[d] = Math.round(r / n); data[d + 1] = Math.round(g / n); data[d + 2] = Math.round(b / n); data[d + 3] = 255;
    }
    const out = { w, h, data };
    if (cache.size > 4) cache.delete(cache.keys().next().value);
    cache.set(i, out);
    return out;
  };
  const result = W.analyse((t) => frame(ticks[t]), { count: ticks.length });
  return { result, width: w, height: h, ticks: ticks.length - SEAM_TICKS, seconds: (ticks.length - SEAM_TICKS) / 60, frames: gif.frames.length, loop: gif.loop };
}

function main(argv) {
  const file = argv.find((a, i) => !a.startsWith('--') && argv[i - 1] !== '--json');
  if (!file) { console.error('usage: node tools/flash/analyse-gif.mjs <file.gif> [--json out.json]'); return 2; }
  let a;
  try { a = analyseGif(file); } catch (e) { console.error(`${file}: ${e.message}`); return 2; }
  const j = argv.indexOf('--json');
  if (j >= 0) writeFileSync(argv[j + 1], JSON.stringify(a, null, 2) + '\n');
  console.log(`${'clip'.padEnd(30)} ${'frames'.padStart(6)} ${'seconds'.padStart(8)} ${'size'.padStart(9)} ${V.HEADER}`);
  console.log(`${file.split(/[\\/]/).pop().padEnd(30)} ${String(a.frames).padStart(6)} ${a.seconds.toFixed(1).padStart(8)} ${(a.width + 'x' + a.height).padStart(9)} ${V.columns(a.result)}`);
  console.log(a.result.pass ? 'An automated flash check based on WCAG 2.3.1 (general flash, red flash and area), run on this clip as a loop filling the screen, found no failure. This is not a clearance.' : 'This clip is not PASS under the combined rule.');
  return a.result.pass ? 0 : 1;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) process.exit(main(process.argv.slice(2)));
