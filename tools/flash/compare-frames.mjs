// A frame comparison of clips already captured, STANDARD template against CUSTOM template on the same commit (Legal's RL-199 item 1): every frame the two folders have in common is identical, or
// differs by no more than the noise of the capture. If any frame differs beyond noise, the flip needs the full flash set run on the custom build (docs/tools/site-template.md).
//
//   node tools/flash/compare-frames.mjs --standard <frames dir> --custom <frames dir> [--noise <frames dir>] [--tol 8] [--floor 0.001] [--json <file>] [--allow-different]
//   The folders are tools/flash/capture-web.mjs's (frame-000001.png ...; check-clip.mjs and run-pixels.mjs keep the worst second's frames the same way). Frames are matched by name.
//   --noise: a SECOND capture of the standard build (same commit, same clip): the standard-against-standard difference is what "noise" means here; without it the floor alone is the bound.
//   A pixel differs when any colour channel differs by more than --tol (of 255, default 8). A frame is identical when its bytes are; it is within noise when the fraction of differing pixels is at most
//   max(floor, 1.25 x the noise capture's worst frame); else it is beyond noise. Collapse is not byte-reproducible even standard against standard (Performance, 2026-10-28: at most 0.078% of pixels).
//   Two clips of different matches are refused (the same rule as side-by-side.mjs) unless --allow-different. Exit 0 when no frame is beyond noise, 1 when one is, 2 on bad input.
import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { readMatch, differences, matchText } from './clip-id.mjs';
const { decodePng } = createRequire(import.meta.url)('./wcag.js');

export const DEFAULT_TOL = 8;
export const DEFAULT_FLOOR = 0.001;   // 0.1% of the pixels: above Performance's measured 0.078% for standard against standard
export const NOISE_FACTOR = 1.25;

/** { diffPx, total, maxDiff, fraction } of two decoded images ({ w, h, data: RGBA }); sizes must match. */
export function compareImages(a, b, tol = DEFAULT_TOL) {
  if (a.w !== b.w || a.h !== b.h) return { diffPx: a.w * a.h, total: a.w * a.h, maxDiff: 255, fraction: 1, sizeDiffers: true };
  let diffPx = 0, maxDiff = 0;
  const n = a.w * a.h;
  for (let i = 0; i < n; i++) {
    const o = i * 4;
    const d = Math.max(Math.abs(a.data[o] - b.data[o]), Math.abs(a.data[o + 1] - b.data[o + 1]), Math.abs(a.data[o + 2] - b.data[o + 2]));
    if (d > maxDiff) maxDiff = d;
    if (d > tol) diffPx++;
  }
  return { diffPx, total: n, maxDiff, fraction: n ? diffPx / n : 0 };
}

const framesOf = (dir) => readdirSync(dir).filter((f) => /^frame-\d+\.png$/.test(f)).sort();

/** The per-frame results of two folders: [{ frame, identical, fraction, maxDiff }] over the frames they share. */
export function compareFolders(dirA, dirB, tol = DEFAULT_TOL) {
  const b = new Set(framesOf(dirB));
  const out = [];
  for (const f of framesOf(dirA)) {
    if (!b.has(f)) continue;
    const ba = readFileSync(join(dirA, f)), bb = readFileSync(join(dirB, f));
    if (ba.equals(bb)) { out.push({ frame: f, identical: true, fraction: 0, maxDiff: 0 }); continue; }
    const r = compareImages(decodePng(ba), decodePng(bb), tol);
    out.push({ frame: f, identical: false, fraction: r.fraction, maxDiff: r.maxDiff, sizeDiffers: !!r.sizeDiffers });
  }
  return out;
}

/** The verdict of a comparison: counts, the bound used and the frames beyond it. `noiseRows`: the standard-against-standard rows (or null). Pure. */
export function verdict(rows, noiseRows, floor = DEFAULT_FLOOR) {
  const noiseMax = noiseRows && noiseRows.length ? Math.max(...noiseRows.map((r) => r.fraction)) : 0;
  const limit = Math.max(floor, noiseMax * NOISE_FACTOR);
  const beyond = rows.filter((r) => !r.identical && (r.sizeDiffers || r.fraction > limit));
  const identical = rows.filter((r) => r.identical).length;
  return { frames: rows.length, identical, withinNoise: rows.length - identical - beyond.length, beyondNoise: beyond.length, limit, noiseMax, worst: rows.length ? Math.max(...rows.map((r) => r.fraction)) : 0, beyondFrames: beyond.slice(0, 20).map((r) => r.frame) };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const opt = (n, d) => { const i = args.indexOf(n); return i >= 0 ? args[i + 1] : d; };
  const S = opt('--standard'), C = opt('--custom');
  if (!S || !C || !existsSync(S) || !existsSync(C)) { console.error('usage: node tools/flash/compare-frames.mjs --standard <frames dir> --custom <frames dir> [--noise <frames dir>] [--tol 8] [--floor 0.001] [--json <file>] [--allow-different]'); process.exit(2); }
  const sides = [['standard', S], ['custom', C]].map(([which, dir]) => ({ which, ...readMatch(dir) }));
  for (const s of sides) console.log(s.match ? `${s.which}: ${matchText(s.match)}` : `${s.which}: no match record (clip.json)`);
  if (sides.every((s) => s.match)) {
    const diff = differences(sides[0].match, sides[1].match);
    if (diff.length && !args.includes('--allow-different')) { console.error(`compare-frames: REFUSED: the two clips are not the same match (${diff.join('; ')}): a frame difference between two matches says nothing about the template`); process.exit(2); }
  }
  const tol = Number(opt('--tol', DEFAULT_TOL)), floor = Number(opt('--floor', DEFAULT_FLOOR));
  const rows = compareFolders(S, C, tol);
  if (!rows.length) { console.error('compare-frames: the two folders share no frame-NNNNNN.png'); process.exit(2); }
  const noise = opt('--noise');
  const noiseRows = noise ? compareFolders(S, noise, tol) : null;
  const v = verdict(rows, noiseRows, floor);
  const report = { standard: resolve(S), custom: resolve(C), noise: noise ? resolve(noise) : null, tol, floor, ...v };
  if (opt('--json')) writeFileSync(opt('--json'), JSON.stringify(report, null, 2) + '\n');
  console.log(`compare-frames: ${v.frames} frames: ${v.identical} identical, ${v.withinNoise} within noise, ${v.beyondNoise} beyond (bound ${(v.limit * 100).toFixed(3)}% of pixels${noise ? `, from the noise capture's worst ${(v.noiseMax * 100).toFixed(3)}%` : ', the floor'}; worst frame ${(v.worst * 100).toFixed(3)}%)`);
  if (v.beyondNoise) { console.error(`compare-frames: BEYOND NOISE: ${v.beyondFrames.join(', ')}${v.beyondNoise > v.beyondFrames.length ? ', ...' : ''}: the flip needs the full flash set run on the custom build`); process.exit(1); }
}
