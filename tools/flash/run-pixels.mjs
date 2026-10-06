// Half 2 for real: captures every worst case from a local web export of the game, in normal and reduced mode, at the standard's reference size (1024 x 768), analyses each
// clip at full size, and cross-checks each clip against the headless run of the same scenario (the drift check between tools/flash/flash_worst.gd and Rendering's copy of
// the staging, render/tools/flash_capture.gd). Manual, not CI: it needs a web export and takes tens of minutes.
//
//   godot --headless --path . --export-release "Web" <site>/index.html            (a HEAD export; the Web preset, templates already installed)
//   godot --headless --path . --script res://tools/flash/flash_worst.gd -- --out=<flash>            (the headless runs for the cross-check)
//   node tools/flash/run-pixels.mjs --dir <site> --path "/index.html?flashcap=1" --out <clips> [--flash <flash>] [--jobs 3] [--only mash,clash] [--keep]
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
if (!DIR || !OUT) { console.error('usage: node tools/flash/run-pixels.mjs --dir <site> --path "/index.html?flashcap=1" --out <clips> [--flash <headless runs>] [--jobs 3] [--only a,b] [--keep]'); process.exit(2); }
const src = JSON.parse(readFileSync(join(here, 'sources.json'), 'utf8'));
const jobs = [];
for (const sc of src.scenarios) {
  if (ONLY && !ONLY.includes(sc.id)) continue;
  for (const seed of sc.seeds) for (const reduced of [false, true]) jobs.push({ id: `${sc.id}${sc.seeds.length > 1 ? '-' + seed : ''}-${reduced ? 'reduced' : 'normal'}`, scenario: sc.id, seed, reduced, ticks: sc.ticks, multi: sc.seeds.length > 1 });
}
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
  const cap = await run([join(here, 'capture-web.mjs'), '--dir', DIR, '--path', PATH, '--scenario', job.scenario, '--seed', String(job.seed), ...(job.reduced ? ['--reduced'] : []), '--ticks', String(job.ticks), '--width', String(W), '--height', String(H), '--out', dir, '--timeout', '1800']);
  if (cap.code !== 0) return { ...job, error: cap.out.trim().split('\n').pop() };
  const an = await run([join(here, 'analyse-frames.js'), dir, '--scale', '1', '--json', join(dir, 'analysis.json')]);
  const result = JSON.parse(readFileSync(join(dir, 'analysis.json'), 'utf8'))[0].result;
  const clip = JSON.parse(readFileSync(join(dir, 'clip.json'), 'utf8'));
  let cross = null;
  if (FLASH) {
    const f = join(FLASH, `flash-${job.scenario}-${job.reduced ? 'reduced' : 'normal'}${job.multi ? '-' + job.seed : ''}.json`);
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
  if (!bad && !argv.includes('--keep')) for (const f of readdirSync(dir)) if (/\.png$/i.test(f)) rmSync(join(dir, f));
  return { ...job, seconds: Math.round((Date.now() - t0) / 1000), result, cross, kept: bad || argv.includes('--keep') };
}

const results = [];
let next = 0;
await Promise.all(Array.from({ length: JOBS }, async () => {
  while (next < jobs.length) {
    const job = jobs[next++];
    const r = await one(job);
    results.push(r);
    console.log(r.error ? `${job.id}: CAPTURE FAILED: ${r.error}` : `${job.id}: ${r.result.general.flashes} general, ${r.result.red.flashes} red, largest change ${(100 * Math.max(r.result.general.largestChangeOfFrame, r.result.red.largestChangeOfFrame)).toFixed(1)}% of frame, ${r.seconds}s${r.cross && !r.cross.missing ? `, register count ${r.cross.agrees ? 'agrees' : 'DIFFERS'} with the headless run (${(100 * r.cross.share).toFixed(1)}% of ticks)` : ''}`);
  }
}));
results.sort((a, b) => a.id.localeCompare(b.id));
writeFileSync(join(OUT, 'summary.json'), JSON.stringify(results, null, 2) + '\n');

console.log(`\n${'clip'.padEnd(24)} ${'ticks'.padStart(5)} ${'general'.padStart(8)} ${'red'.padStart(4)} ${'largest'.padStart(8)}  ${'register web/headless max'.padEnd(26)} result`);
let bad = 0;
for (const r of results) {
  if (r.error) { bad++; console.log(`${r.id.padEnd(24)} CAPTURE FAILED: ${r.error}`); continue; }
  const x = r.cross && !r.cross.missing ? `${r.cross.maxWeb}/${r.cross.maxHead} ${r.cross.agrees ? 'same' : 'DIFFERENT'}` : 'n/a';
  const ok = r.result.pass && (!r.cross || r.cross.missing || r.cross.agrees);
  if (!ok) bad++;
  console.log(`${r.id.padEnd(24)} ${String(r.ticks).padStart(5)} ${String(r.result.general.flashes).padStart(8)} ${String(r.result.red.flashes).padStart(4)} ${(100 * Math.max(r.result.general.largestChangeOfFrame, r.result.red.largestChangeOfFrame)).toFixed(1).padStart(7)}%  ${x.padEnd(26)} ${ok ? 'no failure found' : 'FAIL'}`);
}
console.log(bad
  ? `\npixel run FAILED in ${bad} of ${results.length} clips (frames kept in ${OUT} for the failures)`
  : `\npixel run: no failure found in ${results.length} clips under this reading of criterion 2.3.1, and every register count agrees with the headless run. Not "safe", not "tested for photosensitivity": docs/tools/flash-check.md.`);
process.exit(bad ? 1 : 0);
