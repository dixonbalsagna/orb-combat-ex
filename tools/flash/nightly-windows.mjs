// The window each clip is read at in the runner's nightly (Tools, 2026-11-14; the EP's decision: a runner cannot read a whole clip, so each clip is read as a window at its worst moment).
//   node tools/flash/nightly-windows.mjs <clip id> [--ticks N]     prints the run-pixels options for that clip: "--skip S --ticks T" (or "--ticks T" when it starts at tick 1)
//   node tools/flash/nightly-windows.mjs <clip id> --cap-seconds   prints the clip's time cap in seconds (capMin, default defaultCapMin or 45): a window's skipped ticks cost time too
//   node tools/flash/nightly-windows.mjs --check                   the data file's own check (exit 1 on a problem)
// The data is tools/flash/nightly-windows.json: { defaultTicks, clips: { "<id>": { skip, ticks, from: "<how the moment was found>" } } }. A clip with no entry is read from tick 1 for defaultTicks (the speed trial's way).
// `skip` is run-pixels.mjs's own option: ticks run without a picture before the clip (the clip is then --ticks long from tick skip + 1). The window is a window: its verdict covers only those ticks, and the
// full reading stays a local run (docs/tools/flash-nightly.md). Node built-ins only.
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const FILE = join(HERE, 'nightly-windows.json');
const WARMUP = 60;   // the analyser's memory frames (wcag.js H): the first 60 frames of a clip count no change

/** The window of a clip: { skip, ticks, from }. `override` (a positive number of ticks) replaces the ticks and keeps the start. Pure. */
export function windowOf(data, id, override = 0) {
  const e = (data.clips && data.clips[id]) || null;
  const ticks = override > 0 ? override : (e ? e.ticks : data.defaultTicks);
  return { skip: e ? e.skip : 0, ticks, capMin: e && e.capMin ? e.capMin : (data.defaultCapMin || 45), from: e ? e.from : 'no entry: from tick 1' };
}

/** The options text for run-pixels. Pure. */
export function optionsOf(w) { return (w.skip > 0 ? `--skip ${w.skip} ` : '') + `--ticks ${w.ticks}`; }

/** Problems with the data (empty when fine). Pure. clipLength: the length of a full clip in ticks. */
export function problems(data, clipLength = 1500) {
  const out = [];
  if (!(data.defaultTicks > 0)) out.push('defaultTicks is not a positive number');
  if (data.defaultTicks <= WARMUP + 1) out.push(`defaultTicks ${data.defaultTicks} is not more than ${WARMUP + 1}`);
  for (const [id, e] of Object.entries(data.clips || {})) {
    if (!Number.isInteger(e.skip) || e.skip < 0) out.push(`${id}: skip is not a whole number of ticks, 0 or more`);
    if (!Number.isInteger(e.ticks) || e.ticks <= 0) out.push(`${id}: ticks is not a positive whole number`);
    if (e.skip + e.ticks > clipLength) out.push(`${id}: skip ${e.skip} + ticks ${e.ticks} runs past the ${clipLength} ticks of a clip`);
    if (!e.from || typeof e.from !== 'string') out.push(`${id}: no "from" (how the moment was found)`);
    // the analyser counts no change in its first 60 frames (the warm-up of the one-second memory): a window of 61 ticks or fewer has nothing to read (wcag.js: "need more than H + 1 frames"; run 43580079641 collapse)
    if (Number.isInteger(e.ticks) && e.ticks <= WARMUP + 1) out.push(`${id}: ticks ${e.ticks} is not more than the ${WARMUP + 1} frames the analyser needs (the first ${WARMUP} are warm-up and count no change)`);
    if (e.capMin !== undefined && !(Number.isInteger(e.capMin) && e.capMin >= 10 && e.capMin <= 240)) out.push(`${id}: capMin is not a whole number of minutes from 10 to 240`);
  }
  return out;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const argv = process.argv.slice(2);
  const data = JSON.parse(readFileSync(FILE, 'utf8'));
  if (argv.includes('--check')) {
    const p = problems(data);
    for (const x of p) console.error('nightly-windows: ' + x);
    console.log(p.length ? `nightly-windows: ${p.length} problem(s)` : `nightly-windows ok: ${Object.keys(data.clips || {}).length} clip window(s), default ${data.defaultTicks} ticks`);
    process.exit(p.length ? 1 : 0);
  }
  const id = argv.find((a) => !a.startsWith('--'));
  if (!id) { console.error('usage: node tools/flash/nightly-windows.mjs <clip id> [--ticks N] | --check'); process.exit(2); }
  const i = argv.indexOf('--ticks');
  const w = windowOf(data, id, i >= 0 ? Number(argv[i + 1]) : 0);
  if (argv.includes('--cap-seconds')) { console.log(String(w.capMin * 60)); process.exit(0); }
  console.error(`[nightly-windows] ${id}: ${w.ticks} ticks from tick ${w.skip + 1} (${w.from})`);
  console.log(optionsOf(w));
}
void pathToFileURL;
