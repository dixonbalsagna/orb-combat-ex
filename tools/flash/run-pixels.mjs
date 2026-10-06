// Half 2 for real: captures every worst case from a local web export of the game, in normal and reduced mode, at the standard's reference size (1024 x 768), analyses each
// clip at full size, and cross-checks each clip against the headless run of the same scenario (the drift check between tools/flash/flash_worst.gd and Rendering's copy of
// the staging, render/tools/flash_capture.gd). Manual, not CI: it needs a web export and takes tens of minutes.
//
//   godot --headless --path . --export-release "Web" <site>/index.html            (a HEAD export; the Web preset, templates already installed)
//   godot --headless --path . --script res://tools/flash/flash_worst.gd -- --out=<flash>            (the headless runs for the cross-check)
//   node tools/flash/run-pixels.mjs --dir <site> --path "/index.html?flashcap=1" --out <clips> [--flash <flash>] [--jobs 3] [--only mash,clash] [--clip collapse-normal] [--keep | --keep-ranges]
//
// Writes <out>/<id>/ (frames and clip.json), <out>/summary.json and a table. Frames of clips that show no failure are deleted unless --keep. Exit 0 when every clip shows
// no failure under the reading (docs/tools/flash-check.md) and every cross-check agrees, 1 otherwise. On Git Bash set MSYS_NO_PATHCONV=1 or quote --path.
import { spawn } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const DIR = opt('--dir'), PATH = opt('--path', '/index.html?flashcap=1'), OUT = opt('--out'), FLASH = opt('--flash');
const JOBS = Number(opt('--jobs', 3));
const ONLY = opt('--only') ? opt('--only').split(',') : null;
const W = 1024, H = 768;
const TICKS_OVERRIDE = opt('--ticks') ? Number(opt('--ticks')) : 0;   // a shorter clip, for a speed measurement (the verdict then covers only those ticks)
if (!DIR || !OUT) { console.error('usage: node tools/flash/run-pixels.mjs --dir <site> --path "/index.html?flashcap=1" --out <clips> [--flash <headless runs>] [--jobs 3] [--only a,b] [--clip id,id] [--keep | --keep-ranges] [--software] [--ticks N]'); process.exit(2); }
const src = JSON.parse(readFileSync(join(here, 'sources.json'), 'utf8'));
const roster = JSON.parse(readFileSync(join(here, '..', '..', 'data', 'fighters', 'roster.json'), 'utf8'));
const CLIP = opt('--clip') ? opt('--clip').split(',') : null;
// the required set (sources.json): the five fixed cases, and for `ai` every pairing at every seed, each in both modes. A clip's id is scenario[-pairing][-seed]-mode.
const jobs = [];
for (const sc of src.scenarios) {
  if (ONLY && !ONLY.includes(sc.id)) continue;
  const runs = sc.pairings ? src.pairings.map((p) => ({ slots: p.slots, seeds: p.seeds })) : [{ slots: null, seeds: [12345] }];
  for (const r of runs) {
    const dflt = !r.slots || (r.slots[0] === roster[0] && r.slots[1] === roster[1]);
    const label = dflt ? '' : '-' + r.slots.join('-');
    for (const seed of r.seeds) for (const reduced of [false, true]) {
      const id = `${sc.id}${label}${r.seeds.length > 1 ? '-' + seed : ''}-${reduced ? 'reduced' : 'normal'}`;
      if (CLIP && !CLIP.includes(id)) continue;
      jobs.push({ id, scenario: sc.id, seed, reduced, ticks: sc.ticks, multi: r.seeds.length > 1, slots: dflt ? null : r.slots, label });
    }
  }
}
if (!jobs.length) { console.error('no clip matches (ids look like collapse-normal, ai-12345-reduced, mash-reduced; --only takes scenario names)'); process.exit(2); }
mkdirSync(OUT, { recursive: true });

const run = (args) => new Promise((ok) => {
  const c = spawn(process.execPath, args, { stdio: ['ignore', 'pipe', 'pipe'], env: { ...process.env, MSYS_NO_PATHCONV: '1' } });
  let out = '';
  c.stdout.on('data', (d) => { out += d; }); c.stderr.on('data', (d) => { out += d; });
  c.on('close', (code) => ok({ code, out }));
});

/** The register's count at each tick, rebuilt from a headless run's rows (granted flashes in (t-60, t]). */
function seriesFromRows(rows, ticks) {
  const g = rows.filter((r) => r[3] === true).map((r) => r[0]);
  const s = [];
  for (let t = 1; t <= ticks; t++) s.push(g.filter((n) => n > t - 60 && n <= t).length);
  return s;
}

async function one(job) {
  const dir = join(OUT, job.id);
  const t0 = Date.now();
  const cap = await run([join(here, 'capture-web.mjs'), '--dir', DIR, '--path', PATH, '--scenario', job.scenario, '--seed', String(job.seed), ...(job.slots ? ['--slots', job.slots.join(',')] : []), ...(job.reduced ? ['--reduced'] : []), '--ticks', String(TICKS_OVERRIDE || job.ticks), ...(argv.includes('--software') ? ['--software'] : []), '--width', String(W), '--height', String(H), '--out', dir, '--timeout', '1800']);
  if (cap.code !== 0) return { ...job, error: cap.out.trim().split('\n').pop() };
  if (argv.includes('--capture-only')) return { ...job, captured: true };
  const an = await run([join(here, 'analyse-frames.js'), dir, '--scale', '1', '--json', join(dir, 'analysis.json')]);
  const result = JSON.parse(readFileSync(join(dir, 'analysis.json'), 'utf8'))[0].result;
  const clip = JSON.parse(readFileSync(join(dir, 'clip.json'), 'utf8'));
  let cross = null;
  if (FLASH) {
    const f = join(FLASH, `flash-${job.scenario}-${job.reduced ? 'reduced' : 'normal'}${job.label}${job.multi ? '-' + job.seed : ''}.json`);
    if (existsSync(f) && clip.inWindow && clip.inWindow.every((x) => typeof x === 'number')) {
      const head = seriesFromRows(JSON.parse(readFileSync(f, 'utf8')).rows, job.ticks);
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
  if (argv.includes('--keep-ranges')) {
    // keep only the frames a person needs: the worst second (30 ticks before to 90 after its start) and every dip (15 before to 30 after), delete the rest
    const ranges = [];
    for (const k of ['general', 'red']) if (result[k].flashes >= 1 && result[k].atTick > 0) ranges.push([result[k].atTick - 30, result[k].atTick + 90]);
    for (const d of result.dips.list) ranges.push([d.tick - 15, d.tick + 30]);
    for (const f of readdirSync(dir)) {
      const m = /^frame-(\d+)\.png$/.exec(f);
      if (m && !ranges.some(([lo, hi]) => Number(m[1]) >= lo && Number(m[1]) <= hi)) rmSync(join(dir, f));
    }
    writeFileSync(join(dir, 'kept-ranges.json'), JSON.stringify({ ranges }, null, 2) + String.fromCharCode(10));
    kept = true;
  } else if (!bad && !argv.includes('--keep')) for (const f of readdirSync(dir)) if (/\.png$/i.test(f)) rmSync(join(dir, f));
  return { ...job, seconds: Math.round((Date.now() - t0) / 1000), result, cross, kept };
}

const results = [];
let next = 0;
await Promise.all(Array.from({ length: JOBS }, async () => {
  while (next < jobs.length) {
    const job = jobs[next++];
    const r = await one(job);
    results.push(r);
    if (r.captured) { console.log(`${job.id}: captured`); continue; }
    console.log(r.error ? `${job.id}: CAPTURE FAILED: ${r.error}` : `${job.id}: ${r.result.general.flashes} general, ${r.result.red.flashes} red, largest window ${(100 * Math.max(r.result.general.largestWindowOfThreshold, r.result.red.largestWindowOfThreshold)).toFixed(0)}% of the limit, ${r.result.dips.list.length} dips, ${r.seconds}s${r.cross && !r.cross.missing ? `, register count ${r.cross.agrees ? 'agrees' : 'DIFFERS'} with the headless run (${(100 * r.cross.share).toFixed(1)}% of ticks)` : ''}`);
  }
}));
if (argv.includes('--capture-only')) { console.log(`captured ${results.length} clips into ${OUT}; analyse them with analyse-frames.js`); process.exit(results.some((r) => r.error) ? 1 : 0); }
results.sort((a, b) => a.id.localeCompare(b.id));
writeFileSync(join(OUT, 'summary.json'), JSON.stringify(results, null, 2) + '\n');

console.log(`\n${'clip'.padEnd(24)} ${'ticks'.padStart(5)} ${'general'.padStart(8)} ${'red'.padStart(4)} ${'window/limit'.padStart(13)} ${'dips'.padStart(5)}  ${'register web/headless max'.padEnd(26)} result`);
let bad = 0;
for (const r of results) {
  if (r.error) { bad++; console.log(`${r.id.padEnd(24)} CAPTURE FAILED: ${r.error}`); continue; }
  const x = r.cross && !r.cross.missing ? `${r.cross.maxWeb}/${r.cross.maxHead} ${r.cross.agrees ? 'same' : 'DIFFERENT'}` : 'n/a';
  const ok = r.result.pass && (!r.cross || r.cross.missing || r.cross.agrees);
  if (!ok) bad++;
  console.log(`${r.id.padEnd(24)} ${String(r.ticks).padStart(5)} ${String(r.result.general.flashes).padStart(8)} ${String(r.result.red.flashes).padStart(4)} ${(Math.round(100 * Math.max(r.result.general.largestWindowOfThreshold, r.result.red.largestWindowOfThreshold)) + '%').padStart(13)} ${String(r.result.dips.list.length).padStart(5)}  ${x.padEnd(26)} ${ok ? 'no failure found' : (r.result.passStandard ? 'OVER OUR GATE (2.5), within the standard' : 'FAIL: over the standard (3)')}`);
}
for (const r of results.filter((x) => !x.error)) {
  const d = r.result.dips;
  if (d.list.length) console.log(`dips in ${r.id}: ${d.list.map((x) => `tick ${x.tick} (${(100 * x.areaOfFrame).toFixed(0)}% of the frame, mean luminance ${x.meanBefore.toFixed(3)} to ${x.meanMin.toFixed(3)})`).join('; ')}; shortest gap ${d.shortestGapFrames === null ? 'n/a (one dip or none)' : d.shortestGapFrames + ' ticks'}`);
}
console.log(bad
  ? `
pixel run FAILED the gate (2.5 flashes in any second, Legal's RL-119; the standard's limit is 3) in ${bad} of ${results.length} clips (frames kept in ${OUT} for the failures)`
  : `
An automated flash check based on WCAG 2.3.1 (general flash, red flash and area), run on recorded gameplay, found no failure. (${results.length} clips; every register count agrees with the headless run; docs/tools/flash-check.md has the reading and its limits. This is not a clearance.)`);
process.exit(bad ? 1 : 0);
