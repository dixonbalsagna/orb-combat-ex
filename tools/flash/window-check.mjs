// Does each nightly window still hold the thing it is there to read? (Tools, 2026-11-26; the EP's yes after the clash windows read no clash for five nights.)
//   node tools/flash/window-check.mjs <folder of flash_worst.gd run files> [--windows <file>]
// The nightly reads each clip only in a window of ticks (tools/flash/nightly-windows.json). When the game changes, the moment moves and the window goes on reading whatever is there: a low reading then means
// nothing. flash_worst.gd records the tick of each such event ("marks"); this reads them. Each window names what it `holds` ("beam_outcome:CLASH", "beam_outcome" for any outcome, "building_fall",
// "shot_hit", "sig"), and each named event must happen in the part of the window that counts: after the clip's first 60 frames, which count no change (wcag.js H). A missing run file, a window that names
// nothing and a run with no marks are failures, never passes. It reads the headless run, not the pixels: it says the event is there, not that the window is its worst moment (that is a local full reading).
// Exit 0 every window holds, 1 one does not (each is named), 2 usage. Node built-ins only.
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
export const WARMUP = 60;   // wcag.js H: the first 60 frames of a clip count no change

/** The headless run file of a nightly clip id: { file } (a night clip reads its base scene's run). Pure. */
export function runFileOf(id, sources) {
  const m = /^(.*)-(normal|reduced)$/.exec(id);
  if (!m) return null;
  const night = (sources.nightClips || []).find((n) => n.id === m[1]);
  return `flash-${night ? night.base : m[1]}-${m[2]}.json`;
}

/** The ticks of a held event in a run's marks; "beam_outcome" takes every outcome. Pure. */
export function ticksOf(marks, held) {
  return Object.entries(marks || {}).filter(([k]) => k === held || k.startsWith(held + ':')).flatMap(([, v]) => v).sort((a, b) => a - b);
}

/** Problems with one clip's window against its run (empty when it holds). `w` = the window's entry, `run` the run file's content or null. Pure. */
export function windowProblems(id, w, run) {
  if (!Array.isArray(w.holds) || !w.holds.length) return [`${id}: the window names nothing it holds ("holds" in tools/flash/nightly-windows.json)`];
  if (!run) return [`${id}: the headless run file is missing: nothing was read`];
  if (!run.marks) return [`${id}: the run has no event marks (an older flash_worst.gd)`];
  const from = w.skip + WARMUP + 1, to = w.skip + w.ticks;
  const out = [];
  for (const held of w.holds) {
    const all = ticksOf(run.marks, held);
    if (!all.some((t) => t >= from && t <= to)) {
      const uniq = [...new Set(all)];
      out.push(`${id}: no ${held} in the counted part of its window (ticks ${from} to ${to}); in the whole run it happens at ${uniq.length ? uniq.slice(0, 12).join(', ') + (uniq.length > 12 ? ', ...' : '') : 'no tick at all'}`);
    }
  }
  return out;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const a = process.argv.slice(2);
  const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
  const folder = a.find((x, i) => !x.startsWith('--') && a[i - 1] !== '--windows');
  if (!folder) { console.error('usage: node tools/flash/window-check.mjs <folder of flash_worst run files> [--windows <file>]'); process.exit(2); }
  const windows = JSON.parse(readFileSync(resolve(opt('--windows', join(HERE, 'nightly-windows.json'))), 'utf8')).clips;
  const sources = JSON.parse(readFileSync(join(HERE, 'sources.json'), 'utf8'));
  let bad = 0;
  for (const [id, w] of Object.entries(windows)) {
    const f = runFileOf(id, sources);
    const path = f ? join(resolve(folder), f) : null;
    const run = path && existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : null;
    const p = windowProblems(id, w, run);
    for (const x of p) console.log('FAIL ' + x);
    if (!p.length) console.log(`ok   ${id}: ${w.holds.join(', ')} in ticks ${w.skip + WARMUP + 1} to ${w.skip + w.ticks}`);
    bad += p.length ? 1 : 0;
  }
  console.log(bad ? `window check FAILED: ${bad} of ${Object.keys(windows).length} nightly windows do not hold what they are there to read` : `window check ok: all ${Object.keys(windows).length} nightly windows hold their event`);
  process.exit(bad ? 1 : 0);
}
