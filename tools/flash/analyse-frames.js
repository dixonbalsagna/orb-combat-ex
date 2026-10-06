// Half 2 of the photosensitivity check: the pixels. Runs the WCAG 2.2 criterion 2.3.1 analyser (tools/flash/wcag.js) over captured frames, one PNG per tick.
//
//   node tools/flash/analyse-frames.js <clip dir | folder of clip dirs> [--fps 60] [--scale N] [--area-share 0.25] [--json out.json] [--dips] [--allow-short]
//
// A clip is a folder of PNGs named so that they sort in play order (frame-000001.png ...), one per sim tick (so 60 a second), optionally with clip.json
// ({ "scenario": "mash", "reduced": false, "fps": 60 }) beside them, which tools/flash/capture-web.mjs writes. A folder whose subfolders are clips analyses each.
// --scale N box-averages N x N pixels first (default: the smallest factor that brings the width to 640 or under); the area window and its threshold are fractions of the frame, so they
// scale with it. Exit 0 when every clip shows no more than 3 general and 3 red flashes in any second under this reading, 1 when one does, 2 on bad input.
//
// What a pass means, and does not: docs/tools/flash-check.md. It is NOT a recognised analyser (Harding / PEAT); a pass is worded only as Legal's sentence printed below.
'use strict';
const fs = require('fs');
const path = require('path');
const W = require('./wcag.js');

function listClips(root) {
  const pngs = (d) => fs.readdirSync(d).filter((f) => /\.png$/i.test(f)).sort();
  if (pngs(root).length) return [{ dir: root, files: pngs(root) }];
  return fs.readdirSync(root, { withFileTypes: true }).filter((e) => e.isDirectory()).map((e) => path.join(root, e.name)).sort()
    .map((d) => ({ dir: d, files: pngs(d) })).filter((c) => c.files.length);
}

/** A frame box-averaged by `s` (s = 1 leaves it alone). */
function shrink(fr, s) {
  if (s <= 1) return fr;
  const w = Math.floor(fr.w / s), h = Math.floor(fr.h / s);
  const out = new Uint8Array(w * h * 4);
  const n = s * s;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    let r = 0, g = 0, b = 0;
    for (let j = 0; j < s; j++) for (let i = 0; i < s; i++) { const p = ((y * s + j) * fr.w + (x * s + i)) * 4; r += fr.data[p]; g += fr.data[p + 1]; b += fr.data[p + 2]; }
    const q = (y * w + x) * 4;
    out[q] = Math.round(r / n); out[q + 1] = Math.round(g / n); out[q + 2] = Math.round(b / n); out[q + 3] = 255;
  }
  return { w, h, data: out };
}

function main(argv) {
  const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
  const flagsWithValue = new Set(['--fps', '--scale', '--area-share', '--json']);
  const args = argv.filter((a, i) => !a.startsWith('--') && !flagsWithValue.has(argv[i - 1]));
  if (!args.length) { console.error('usage: node tools/flash/analyse-frames.js <clip dir | folder of clip dirs> [--fps 60] [--scale N] [--area-share 0.25] [--json out.json] [--dips] [--allow-short]'); return 2; }
  if (!fs.existsSync(args[0])) { console.error(`no such folder: ${args[0]}`); return 2; }
  const clips = listClips(args[0]);
  if (!clips.length) { console.error('no PNG frames found'); return 2; }
  const report = [];
  let bad = 0;
  console.log(`${'clip'.padEnd(26)} ${'frames'.padStart(6)} ${'size'.padStart(9)} ${'general'.padStart(8)} ${'red'.padStart(5)} ${'largest window'.padStart(15)} ${'dips'.padStart(5)}  result`);
  for (const c of clips) {
    let meta = {};
    try { meta = JSON.parse(fs.readFileSync(path.join(c.dir, 'clip.json'), 'utf8')); } catch { /* optional */ }
    const fps = Number(opt('--fps', meta.fps || 60));
    const first = W.decodePng(fs.readFileSync(path.join(c.dir, c.files[0])));
    const scale = Number(opt('--scale', Math.max(1, Math.ceil(first.w / 640))));
    const opts = { fps, count: c.files.length };
    if (opt('--area-share')) opts.areaShare = Number(opt('--area-share'));
    if (c.files.length < fps && !argv.includes('--allow-short')) { console.error(`${c.dir}: ${c.files.length} frames is under one second at ${fps} fps; a clip must hold at least a second (--allow-short to analyse anyway)`); return 2; }
    const get = (i) => shrink(i === 0 ? first : W.decodePng(fs.readFileSync(path.join(c.dir, c.files[i]))), scale);
    let r;
    try { r = W.analyse(get, opts); } catch (e) { console.error(`${c.dir}: ${e.message}`); return 2; }
    const name = path.basename(c.dir) + (meta.reduced ? ' (reduced)' : '');
    const big = `${(100 * Math.max(r.general.largestWindowOfThreshold, r.red.largestWindowOfThreshold)).toFixed(0)}% of limit`;
    if (!r.pass) bad++;
    console.log(`${name.padEnd(26)} ${String(r.frames).padStart(6)} ${(r.width + 'x' + r.height).padStart(9)} ${String(r.general.flashes).padStart(8)} ${String(r.red.flashes).padStart(5)} ${big.padStart(15)} ${String(r.dips.list.length).padStart(5)}  ${r.pass ? 'no failure found' : 'FAIL: more than ' + r.params.maxFlashes + ' flashes in a second' + (r.general.flashes > r.params.maxFlashes ? ` (general, from tick ${r.general.atTick})` : '') + (r.red.flashes > r.params.maxFlashes ? ` (red, from tick ${r.red.atTick})` : '')}`);
    if (argv.includes('--dips')) for (const d of r.dips.list) console.log(`    dip at tick ${d.tick}: ${(100 * d.areaOfFrame).toFixed(0)}% of the frame, mean luminance ${d.meanBefore.toFixed(3)} to ${d.meanMin.toFixed(3)} (depth ${d.drop.toFixed(3)})`);
    report.push({ clip: c.dir, meta, scale, result: r });
  }
  const out = opt('--json');
  if (out) fs.writeFileSync(out, JSON.stringify(report, null, 2) + '\n');
  console.log(bad
    ? `
frame analysis FAILED in ${bad} of ${clips.length} clips under this reading of criterion 2.3.1`
    : `
An automated flash check based on WCAG 2.3.1 (general flash, red flash and area), run on recorded gameplay, found no failure. (${clips.length} clip${clips.length === 1 ? '' : 's'}; the reading and what it cannot see: docs/tools/flash-check.md. This is not a clearance.)`);
  return bad ? 1 : 0;
}

if (require.main === module) process.exit(main(process.argv.slice(2)));
module.exports = { listClips, shrink, main };
