#!/usr/bin/env node
// Runs the audit's measurement matrix one run at a time (one guarded browser at a time), each through docs/perf/tools/frame-bench.mjs, and keeps every run's JSON.
// Node 24 built-ins only. Owner: Performance and Platform. Rerun the whole audit with one command once the machine is quiet:
//
//   node docs/perf/tools/audit-run.mjs --sites base=<site dir>,vfx=<site dir>,anim=<site dir>,both=<site dir> --out <folder> [--plan quick|ab|full] [--wait-quiet 600] [--repeat 3]
//
// --sites   a label for each built site (a folder holding play/index.html from a scratch export that carries the scratch hook)
// --plan    ab: every site, the three scenes, throttle 1 (CPU time per frame is the figure that survives a busy machine); quick: the three scenes of the brief on `base` only, throttle 1, 4 and 6; full: every site, every scene, throttle 1 and 4, plus the integrated GPU and the planet-slice read
// --wait-quiet S   before each run wait up to S seconds for the machine to go quiet (all processors under 45% for two reads in a row); when it does not, the run still happens and
//                  frame-bench marks it invalid. Never "pretend quiet".
// --repeat N  repeat each (site, scene, throttle) N times, interleaved by round, so a change of load shows as spread and not as a difference between sites.
import { spawnSync } from 'node:child_process';
import { cpus } from 'node:os';
import { mkdirSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const sites = Object.fromEntries((opt('--sites', '') || '').split(',').filter(Boolean).map((kv) => kv.split('=')));
const OUT = opt('--out');
const PLAN = opt('--plan', 'quick');
const WAIT = Number(opt('--wait-quiet', 0));
const REPEAT = Number(opt('--repeat', 1));
if (!OUT || !Object.keys(sites).length) { console.error('usage: node docs/perf/tools/audit-run.mjs --sites base=<dir>,... --out <folder> [--plan quick|ab|full] [--wait-quiet S] [--repeat N]'); process.exit(2); }
mkdirSync(resolve(OUT), { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const read = () => cpus().map((c) => { const t = c.times; return { total: t.user + t.nice + t.sys + t.idle + t.irq, idle: t.idle }; });
async function load(ms = 3000) { const a = read(); await sleep(ms); const b = read(); let t = 0, i = 0; b.forEach((x, k) => { t += x.total - a[k].total; i += x.idle - a[k].idle; }); return t > 0 ? 100 * (1 - i / t) : 0; }
async function waitQuiet() {
  if (!WAIT) return;
  const end = Date.now() + WAIT * 1000; let ok = 0;
  while (Date.now() < end) { const l = await load(); ok = l < 45 ? ok + 1 : 0; if (ok >= 2) return; }
  console.log(`  (the machine did not go quiet within ${WAIT} s; the run is marked by its own load check)`);
}

const SCENES = [
  { id: 'mashcity', name: 'city-brawl' },
  { id: 'signaturecity', name: 'beam-in-city' },
  { id: 'ring', name: 'ring3', slots: 'PROTAGONIST,RIVAL,RIVAL' },
];
const runs = [];
const labels = Object.keys(sites);
const throttles = PLAN === 'full' ? [1, 4] : PLAN === 'ab' ? [1] : [1, 4, 6];
const useLabels = (PLAN === 'full' || PLAN === 'ab') ? labels : labels.filter((l) => l === 'base').length ? ['base'] : [labels[0]];
for (let r = 0; r < REPEAT; r++) {
  // the order of the sites rotates from scene to scene and round to round, so a drift in the machine's load is spread over every site and not charged to the one that ran first
  for (const th of throttles) for (const [si, sc] of SCENES.entries()) { const k = (si + r) % useLabels.length; for (const l of [...useLabels.slice(k), ...useLabels.slice(0, k)]) runs.push({ l, sc, th, round: r }); }
}
if (PLAN === 'full') {
  for (const l of labels) runs.push({ l, sc: { id: 'ring', name: 'ring5', slots: 'PROTAGONIST,RIVAL,RIVAL,RIVAL,RIVAL' }, th: 1, round: 0 });
  for (const sc of SCENES) runs.push({ l: 'base', sc, th: 1, round: 0, igpu: true });
  for (const th of [1, 4, 6, 8]) runs.push({ l: 'base', slice: true, th, round: 0 });
  runs.push({ l: 'base', slice: true, th: 1, round: 0, igpu: true });
}
console.log(`${runs.length} runs, one at a time`);
for (const [n, r] of runs.entries()) {
  const tag = r.slice ? `slice-x${r.th}${r.igpu ? '-igpu' : ''}` : `${r.sc.name}-x${r.th}${r.igpu ? '-igpu' : ''}`;
  const file = join(resolve(OUT), `${r.l}__${tag}__r${r.round}.json`);
  if (existsSync(file)) { console.log(`[${n + 1}/${runs.length}] ${r.l} ${tag}: exists, skipped`); continue; }
  await waitQuiet();
  const args = [join(here, 'frame-bench.mjs'), '--site', sites[r.l], '--label', r.l, '--throttle', String(r.th), '--out', file, '--time-limit', r.slice ? '1800' : '900'];
  if (r.slice) args.push('--slice'); else { args.push('--scene', r.sc.id); if (r.sc.slots) args.push('--slots', r.sc.slots); }
  if (r.igpu) args.push('--igpu');
  const p = spawnSync(process.execPath, args, { encoding: 'utf8', timeout: (r.slice ? 2400 : 1200) * 1000 });
  console.log(`[${n + 1}/${runs.length}] ${(p.stdout || '').trim().split('\n').pop()}${p.status ? ' EXIT ' + p.status + ' ' + (p.stderr || '').slice(0, 200) : ''}`);
}
