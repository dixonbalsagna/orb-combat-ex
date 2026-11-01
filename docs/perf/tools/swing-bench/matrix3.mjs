import { spawn } from 'node:child_process';
const S = process.argv[2];
const T = S + '/h/t8';
const gd = 'C:/Users/itsha/Documents/Claude Proj/Breakers-Like/docs/perf/tools/swing-bench/gdrun.mjs';
const cases = [];
for (const run of [1, 2, 3]) for (const seed of [77, 5]) for (const planet of [7, 12, 21]) for (const sw of ['on', 'off']) cases.push({ planet, seed, sw, run });
let i = 0;
async function worker() {
  while (i < cases.length) {
    const c = cases[i++];
    const base = `${S}/h/o3/p${c.planet}s${c.seed}${c.sw}.r${c.run}`;
    await new Promise((ok) => spawn('node', [gd, T, base + '.log', '900', 'res://sim/core/tools/stage_bench2.gd', `--planet=${c.planet}`, `--seed=${c.seed}`, `--swing=${c.sw}`, '--ticks=7200', '--reps=2', `--out=${base}.json`], { stdio: 'ignore' }).on('close', ok));
    console.log('done', JSON.stringify(c));
  }
}
await Promise.all([worker(), worker(), worker()]);
console.log('ALL DONE');
