// How big a window of the screen changes at the moments of a source's flashes: reads a clip's analysis (analyse-frames.js --json, which carries the largest window count per
// tick) and a headless run's register log (flash_worst.gd), and reports, for each granted flash of the source, the largest window count within a few ticks after it,
// against the area threshold. It answers "does the body's white on a hit reach the area test?" with measured pixels.
//
//   node tools/flash/hit-windows.js <analysis.json> <flash-run.json> [--source body_hit] [--after 8]
//
// windowByTick holds a number only for ticks where the pooled change was at least an eighth of the threshold; a tick with none is under that (reported as "under 1/8").
'use strict';
const fs = require('fs');
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 ? argv[i + 1] : d; };
const files = argv.filter((a, i) => !a.startsWith('--') && !['--source', '--after'].includes(argv[i - 1]));
if (files.length < 2) { console.error('usage: node tools/flash/hit-windows.js <analysis.json> <flash-run.json> [--source body_hit] [--after 8]'); process.exit(2); }
const res = JSON.parse(fs.readFileSync(files[0], 'utf8'))[0].result;
const run = JSON.parse(fs.readFileSync(files[1], 'utf8'));
const src = opt('--source', 'body_hit'), after = Number(opt('--after', 8));
const thr = res.thresholdPx, by = res.general.windowByTick;
const ticks = run.rows.filter((r) => r[2] === src && r[3] === true).map((r) => r[1]);
let best = 0, bestAt = -1, over = 0;
for (const t of ticks) {
  let m = 0;
  for (let k = t - 1; k <= t + after; k++) m = Math.max(m, by[k] || 0);
  if (m > best) { best = m; bestAt = t; }
  if (m >= thr) over++;
}
console.log(JSON.stringify({ source: src, granted: ticks.length, thresholdPx: thr, largestWindowPxAfterAGrant: best, atTick: bestAt, ofThreshold: best / thr, grantsWithAWindowAtOrOverThreshold: over, note: best === 0 ? 'under 1/8 of the threshold at every grant' : undefined }));
