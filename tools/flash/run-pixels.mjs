// Half 2 for real: captures every worst case from a local web export of the game, in normal and reduced mode, at two frame sizes (Legal RL-209: 960 x 540, the 16:9 primary, and 1024 x 768, the
// standard's reference), reads each capture at two scales (full size and the analyser's default for its width: four readings a clip, the WORST counts, tools/flash/readings.mjs), and cross-checks each clip against the headless run of the same scenario (the drift check between tools/flash/flash_worst.gd and Rendering's copy of
// the staging, render/tools/flash_capture.gd). Manual, not CI: it needs a web export and takes tens of minutes.
//
//   godot --headless --path . --export-release "Web" <site>/index.html            (a HEAD export; the Web preset, templates already installed)
//   godot --headless --path . --script res://tools/flash/flash_worst.gd -- --out=<flash>            (the headless runs for the cross-check)
//   node tools/flash/run-pixels.mjs --dir <site> --path "/index.html?flashcap=1" --out <clips> [--flash <flash>] [--jobs 3] [--only mash,clash] [--clip collapse-normal] [--keep | --keep-ranges] [--sizes 960x540,1024x768] [--all-readings]
//   --all-readings: read the AI-seed clips four times too (they are read at the first size and full size, and the rest only from a primary of 2.5, Legal 2026-10-30)
//
// Writes <out>/<id>/ (the first size's frames and clip.json; the other sizes' are <out>/<id>@<size>/), <out>/summary.json (result = the worst of the four readings, readings = each of them) and a table. Frames of clips that show no failure are deleted unless --keep. Exit 0 when every clip shows
// no failure under the reading (docs/tools/flash-check.md) and every cross-check agrees, 1 otherwise. On Git Bash set MSYS_NO_PATHCONV=1 or quote --path.
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { requiredClips } from './clips.mjs';
import { SIZES, parseSize, readClip } from './readings.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const V = createRequire(import.meta.url)('./verdict.js');
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = opt('--dir'), PATH = opt('--path', '/index.html?flashcap=1'), OUT = opt('--out'), FLASH = opt('--flash');
const JOBS = Number(opt('--jobs', 3));
// every capture browser runs on the same CPU_CAP percent of the machine's logical processors (tools/machine/browser.mjs: an affinity mask on the same cores for all of them, so the whole set
// together stays inside it), at below-normal priority, and is ended by its own guard at CLIP_TIMEOUT_S plus 5 minutes (docs/tools/machine-captures.md)
const CPU_CAP = Number(opt('--cpu-cap', 40));
const VARIANT = Number(opt('--variant', 0));   // a different run of every fixed scene (the pair set down VARIANT x 450 units further along the world): a sensitive clip's re-capture (RL-131)
const SKIP = Number(opt('--skip', 0));   // ticks run without a picture before every clip (a window of a match: the clip is --ticks long from tick skip + 1); needs the hook's skip
const CLIP_TIMEOUT_S = Number(opt('--clip-timeout', 3600));
const ONLY = opt('--only') ? opt('--only').split(',') : null;
const SIZE_LIST = (opt('--sizes') || SIZES.join(',')).split(',').map((s) => parseSize(s.trim()).text);   // the first is the primary: its folder keeps the clip's id (RL-209)
const TICKS_OVERRIDE = opt('--ticks') ? Number(opt('--ticks')) : 0;   // a shorter clip, for a speed measurement (the verdict then covers only those ticks)
if (!DIR || !OUT) { console.error('usage: node tools/flash/run-pixels.mjs --dir <site> --path "/index.html?flashcap=1" --out <clips> [--flash <headless runs>] [--jobs 3] [--only a,b] [--clip id,id] [--keep | --keep-ranges] [--software] [--budget] [--hold] [--merge-zoom] [--ticks N] [--skip N] [--variant N] [--seeds a,b,c] [--legacy-hook] [--cpu-cap 40] [--clip-timeout 3600] [--sizes 960x540,1024x768] [--all-readings]'); process.exit(2); }
const src = JSON.parse(readFileSync(join(here, 'sources.json'), 'utf8'));
const CLIP = opt('--clip') ? opt('--clip').split(',') : null;
// the required set (sources.json, tools/flash/clips.mjs): the five fixed cases, and for `ai` every pairing at every seed, each in both modes
let jobs = requiredClips(src).filter((j) => (!ONLY || ONLY.includes(j.scenario)) && (!CLIP || CLIP.includes(j.id)));
// --seeds 1001,1002: AI matches of those seeds (the default pair), each in both modes, in place of the required set (the interim's nightly seeds, tools/flash/nightly-seeds.mjs); ids ai-<seed>-normal and -reduced
if (argv.includes('--seeds') && !opt('--seeds')) { console.error('--seeds needs a list of seeds (an empty list would run the whole required set)'); process.exit(2); }
if (opt('--seeds')) {
  const ai = src.scenarios.find((s) => s.id === 'ai');
  jobs = opt('--seeds').split(',').map(Number).filter((n) => Number.isInteger(n) && n > 0).flatMap((seed) => [false, true].map((reduced) => ({ id: `ai-${seed}-${reduced ? 'reduced' : 'normal'}`, scenario: 'ai', seed, reduced, ticks: ai ? ai.ticks : 3600, multi: true, slots: null, label: '' })));
}
if (!jobs.length) { console.error('no clip matches (ids look like collapse-normal, ai-12345-reduced, mash-reduced; --only takes scenario names)'); process.exit(2); }
mkdirSync(OUT, { recursive: true });

// a child that has not finished by timeoutMs is ended (with its browser: the capture's own guard ends that too) and reported as a failure: nothing here waits forever (2026-10-12: a capture whose browser
// was stopped by hand kept this run waiting for 15 hours)
const run = (args, timeoutMs = 0) => new Promise((ok) => {
  const c = spawn(process.execPath, args, { stdio: ['ignore', 'pipe', 'pipe'], env: { ...process.env, MSYS_NO_PATHCONV: '1' } });
  let out = '';
  let timedOut = false;
  c.stdout.on('data', (d) => { out += d; }); c.stderr.on('data', (d) => { out += d; });
  const timer = timeoutMs > 0 ? setTimeout(() => { timedOut = true; out += `
[run-pixels] FAILED: no result in ${Math.round(timeoutMs / 1000)} s, ended`; try { if (process.platform === 'win32') spawnSync('taskkill', ['/PID', String(c.pid), '/T', '/F'], { stdio: 'ignore', timeout: 15000 }); else c.kill('SIGKILL'); } catch { /* gone */ } }, timeoutMs) : null;
  c.on('close', (code) => { if (timer) clearTimeout(timer); ok({ code: timedOut ? 1 : code, out }); });
});

/** The register's count at each tick, rebuilt from a headless run's rows (granted flashes in (t-60, t]). */
function seriesFromRows(rows, ticks, skip = 0) {
  const g = rows.filter((r) => r[3] === true).map((r) => r[0]);
  const s = [];
  for (let t = skip + 1; t <= skip + ticks; t++) s.push(g.filter((n) => n > t - 60 && n <= t).length);
  return s;
}

/** The frames to keep of one capture: the worst second (30 ticks before to 90 after its start) and every dip (15 before to 30 after), over the results read from it. */
function rangesOf(results) {
  const ranges = [];
  for (const result of results) {
    for (const k of ['general', 'red']) if (result[k].flashes >= 1 && result[k].atTick > 0) ranges.push([result[k].atTick - 30, result[k].atTick + 90]);
    for (const d of result.dips.list) ranges.push([d.tick - 15, d.tick + 30]);
  }
  return ranges;
}

async function one(job) {
  const t0 = Date.now();
  const dirFor = (size) => (size.text === SIZE_LIST[0] ? join(OUT, job.id) : join(OUT, `${job.id}@${size.text}`));
  const capture = async (j, size) => {
    const dir = dirFor(size);
    const cap = await run([join(here, 'capture-web.mjs'), '--dir', DIR, '--path', j.words ? `${PATH}${PATH.includes('?') ? '&' : '?'}${j.words}` : PATH, '--scenario', j.scenario, '--seed', String(j.seed), ...(j.slots ? ['--slots', j.slots.join(',')] : []), ...(j.reduced ? ['--reduced'] : []), ...(argv.includes('--legacy-hook') ? ['--legacy-hook'] : []), '--ticks', String(TICKS_OVERRIDE || j.ticks), ...(argv.includes('--software') ? ['--software'] : []), ...(argv.includes('--budget') ? ['--budget'] : []), ...(argv.includes('--hold') ? ['--hold'] : []), ...(argv.includes('--merge-zoom') ? ['--merge-zoom'] : []), ...(SKIP > 0 ? ['--skip', String(SKIP)] : []), ...(VARIANT !== 0 ? ['--variant', String(VARIANT)] : []), '--width', String(size.w), '--height', String(size.h), '--out', dir, '--timeout', String(CLIP_TIMEOUT_S), '--cpu-cap', String(CPU_CAP)], (CLIP_TIMEOUT_S + 900) * 1000);
    if (cap.code !== 0) throw new Error(cap.out.trim().split('\n').pop());
    return { dir, clip: JSON.parse(readFileSync(join(dir, 'clip.json'), 'utf8')) };
  };
  if (argv.includes('--capture-only')) {
    try { for (const s of SIZE_LIST) await capture(job, parseSize(s)); } catch (e) { return { ...job, error: e.message }; }
    return { ...job, captured: true };
  }
  const analyse = async (dir, scale) => {
    const json = join(dir, `analysis-s${scale}.json`);
    await run([join(here, 'analyse-frames.js'), dir, '--scale', String(scale), '--json', json]);
    return JSON.parse(readFileSync(json, 'utf8'))[0].result;
  };
  let read;   // the AI-seed clips are read at 16:9 full size first and the rest of the four only from a primary of 2.5 (Legal, 2026-10-30)
  try { read = await readClip({ job, sizes: SIZE_LIST, capture, analyse, staged: job.scenario === 'ai' && !argv.includes('--all-readings') }); } catch (e) { return { ...job, error: e.message }; }
  const result = read.result;
  const clip = read.captures[0].clip;   // the primary size's: the headless cross-check and the mode read-back are taken from it
  const dir = read.captures[0].dir;
  writeFileSync(join(dir, 'analysis.json'), JSON.stringify([{ clip: dir, meta: clip, scale: 'worst of ' + read.readings.length, result }], null, 2) + '\n');   // what margins.mjs reads: the worst reading's own numbers and worst second
  let cross = null;
  if (FLASH) {
    const f = join(FLASH, `flash-${job.scenario}-${job.reduced ? 'reduced' : 'normal'}${job.label}${job.multi ? '-' + job.seed : ''}.json`);
    if (existsSync(f) && clip.inWindow && clip.inWindow.every((x) => typeof x === 'number')) {
      const head = seriesFromRows(JSON.parse(readFileSync(f, 'utf8')).rows, job.ticks, SKIP);
      let best = null;
      for (const off of [-1, 0, 1]) {
        let same = 0, n = 0;
        for (let i = 0; i < job.ticks; i++) { const j = i + off; if (j < 0 || j >= job.ticks) continue; n++; if (clip.inWindow[j] === head[i]) same++; }
        if (!best || same / n > best.share) best = { offset: off, share: same / n };
      }
      const maxWeb = Math.max(...clip.inWindow), maxHead = Math.max(...head);
      cross = { share: best.share, offset: best.offset, maxWeb, maxHead, agrees: best.share >= 0.98 };
    } else cross = { missing: true };
  }
  const bad = !result.pass;
  let kept = bad || argv.includes('--keep');
  for (const cap of read.captures) {
    if (argv.includes('--keep-ranges')) {
      // keep only the frames a person needs, delete the rest
      const ranges = rangesOf(read.readings.filter((x) => x.size === cap.size).map((x) => x.result));
      for (const f of readdirSync(cap.dir)) {
        const m = /^frame-(\d+)\.png$/.exec(f);
        if (m && !ranges.some(([lo, hi]) => Number(m[1]) >= lo && Number(m[1]) <= hi)) rmSync(join(cap.dir, f));
      }
      writeFileSync(join(cap.dir, 'kept-ranges.json'), JSON.stringify({ ranges }, null, 2) + String.fromCharCode(10));
      kept = true;
    } else if (!bad && !argv.includes('--keep')) for (const f of readdirSync(cap.dir)) if (/\.png$/i.test(f)) rmSync(join(cap.dir, f));
  }
  const fps = Math.min(...read.captures.map((c) => c.clip.framesPerSecond).filter((x) => typeof x === 'number'));   // the slowest capture: a starved one voids the clip (RL-131)
  return { ...job, seconds: Math.round((Date.now() - t0) / 1000), result, readings: read.result.readings, sizes: SIZE_LIST, cross, kept, mode: clip.mode || null, probe: clip.probe || null,
    guard: { ...(clip.guard || {}), loadBefore: clip.loadBefore, loadAfter: clip.loadAfter, framesPerSecond: Number.isFinite(fps) ? fps : clip.framesPerSecond }, captures: read.captures.map((c) => ({ size: c.size, framesPerSecond: c.clip.framesPerSecond, loadBefore: c.clip.loadBefore, loadAfter: c.clip.loadAfter })) };
}

const results = [];
let next = 0;
await Promise.all(Array.from({ length: JOBS }, async () => {
  while (next < jobs.length) {
    const job = jobs[next++];
    const r = await one(job);
    results.push(r);
    if (r.captured) { console.log(`${job.id}: captured`); continue; }
    console.log(r.error ? `${job.id}: CAPTURE FAILED: ${r.error}` : `${job.id}: ${r.result.combined.verdict}, primary ${r.result.general.flashes} general ${r.result.red.flashes} red, area-15% ${r.result.combined.lower}, 2 s memory ${r.result.combined.stricter === null ? 'n/a' : r.result.combined.stricter}, ${r.result.dips.list.length} dips, ${r.seconds}s${r.result.worstOf > 1 ? `, worst of ${r.result.worstOf} readings (${r.result.worst.size} at scale ${r.result.worst.scale})` : ''}${r.cross && !r.cross.missing ? `, register count ${r.cross.agrees ? 'agrees' : 'DIFFERS'} with the headless run (${(100 * r.cross.share).toFixed(1)}% of ticks)` : ''}`);
  }
}));
if (argv.includes('--capture-only')) { console.log(`captured ${results.length} clips into ${OUT}; analyse them with analyse-frames.js`); process.exit(results.some((r) => r.error) ? 1 : 0); }
results.sort((a, b) => a.id.localeCompare(b.id));
writeFileSync(join(OUT, 'summary.json'), JSON.stringify(results, null, 2) + '\n');

console.log(`
${'clip'.padEnd(24)} ${'ticks'.padStart(5)} ${V.HEADER}  ${'register web/headless max'.padEnd(26)}`);
let bad = 0;
for (const r of results) {
  if (r.error) { bad++; console.log(`${r.id.padEnd(24)} CAPTURE FAILED: ${r.error}`); continue; }
  const x = r.cross && !r.cross.missing ? `${r.cross.maxWeb}/${r.cross.maxHead} ${r.cross.agrees ? 'same' : 'DIFFERENT'}` : 'n/a';
  const ok = r.result.pass && (!r.cross || r.cross.missing || r.cross.agrees);
  if (!ok) bad++;
  console.log(`${r.id.padEnd(24)} ${String(r.ticks).padStart(5)} ${V.columns(r.result)}  ${x}${ok ? '' : ' <-- NOT PASS'}`);
}
for (const r of results.filter((x) => !x.error)) {
  const d = r.result.dips;
  if (d.list.length) console.log(`dips in ${r.id}: ${d.list.map((x) => `tick ${x.tick} (${(100 * x.areaOfFrame).toFixed(0)}% of the frame, mean luminance ${x.meanBefore.toFixed(3)} to ${x.meanMin.toFixed(3)})`).join('; ')}; shortest gap ${d.shortestGapFrames === null ? 'n/a (one dip or none)' : d.shortestGapFrames + ' ticks'}`);
}
console.log(bad
  ? `
pixel run: ${bad} of ${results.length} clips are not PASS by the combined rule (Legal's RL-119 and RL-120: PASS is 2.5 or below on the primary reading and no sensitivity run over 3; frames kept in ${OUT} for them)`
  : `
An automated flash check based on WCAG 2.3.1 (general flash, red flash and area), run on recorded gameplay, found no failure. (${results.length} clips; every register count agrees with the headless run; docs/tools/flash-check.md has the reading and its limits. This is not a clearance.)`);
process.exit(bad ? 1 : 0);
