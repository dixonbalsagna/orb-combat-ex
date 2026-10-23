#!/usr/bin/env node
// The launch curve's framing row (fight-feel.md section 1, "QA's rows"): the sent body is inside the frame (or its pane) for at least 95% of a flight's ticks. The measure is Camera's: render/camera/tests/launch_probe.gd
// plays AI against AI through the real scene, headless, and reads the displayed picture on every tick of every flight. This runner starts it once a seed (3 at a time, below-normal priority), keeps each seed's RESULT line and
// the per-launch lines (--verbose), and prints the share of flight ticks the victim is inside the picture, for all launches and for the computer's victims (slot 1: the ones Orb meant).
//   QA_GODOT_ROOT=<scratch export> node qa/godot/inframe.js [--seeds=12] [--base=1] [--ticks=3600] [--jobs=3] [--out=<file.json>] [--md=<file.md>] [--probe-args="--bundle --reduced"]
// Run it in a scratch export with the feel switch on (data/fight/flight.json "enabled": true) for the launch curve; with it off the row reads the build as it is.
try { if (process.env.QA_PRIORITY !== 'normal') require('os').setPriority(0, require('os').constants.priority.PRIORITY_BELOW_NORMAL); } catch (e) { /* the run goes on at the priority it has */ }
const fs = require('fs'), { spawn } = require('child_process');
const { godot, guard, ROOT } = require('./godot');

const arg = (k, d) => { const a = process.argv.slice(2).find(x => x.startsWith('--' + k + '=')); return a ? a.slice(k.length + 3) : d; };
const seeds = parseInt(arg('seeds', '12'), 10), base = parseInt(arg('base', '1'), 10), ticks = parseInt(arg('ticks', '3600'), 10), jobs = parseInt(arg('jobs', '3'), 10);
const extra = arg('probe-args', '').split(' ').filter(Boolean);

function one(seed) {
  const g = godot();
  if (!g) return Promise.reject(new Error('Godot 4.7 not found'));
  return new Promise((resolve, reject) => {
    const p = guard(spawn(g.exe, ['--headless', '--path', ROOT, '--script', 'res://render/camera/tests/launch_probe.gd', '--', `--seed=${seed}`, `--ticks=${ticks}`, '--verbose', ...extra], { stdio: ['ignore', 'pipe', 'pipe'] }));
    let out = '';
    p.stdout.on('data', d => { out += d; }); p.stderr.on('data', d => { out += d; });
    p.on('error', reject);
    p.on('close', code => {
      const lines = out.split(/\r?\n/), res = lines.find(l => l.startsWith('RESULT'));
      if (code !== 0 || !res) return reject(new Error('launch_probe failed for seed ' + seed + ' (exit ' + code + ')\n' + out.slice(0, 1200)));
      const launches = lines.filter(l => l.startsWith('L {')).map(l => JSON.parse(l.slice(2)));
      const m = /sums=(\{[^}]*\})/.exec(res);
      resolve({ seed, result: res, sums: m ? JSON.parse(m[1]) : null, launches });
    });
  });
}

async function pool(tasks, k) {
  const out = new Array(tasks.length); let next = 0;
  await Promise.all(Array.from({ length: Math.min(k, tasks.length) }, async () => { while (next < tasks.length) { const i = next++; out[i] = await tasks[i](); } }));
  return out;
}

function rows(runs) {
  const L = runs.flatMap(r => r.launches), pct = x => (100 * x).toFixed(2) + '%';
  const share = ls => { const f = ls.reduce((a, x) => a + (x.flight || 0), 0), o = ls.reduce((a, x) => a + (x.f_off || 0), 0); return { f, o, s: f ? 1 - o / f : NaN, n: ls.length, longest: Math.max(0, ...ls.map(x => x.longest || 0)) }; };
  const all = share(L), pc = share(L.filter(x => x.v === 1));
  const secs = L.map(x => (x.flight || 0) / 60).filter(x => x > 0).sort((a, b) => a - b), q = p => secs.length ? secs[Math.min(secs.length - 1, Math.floor(secs.length * p))] : NaN;
  return [
    { id: 'frame.inflight', what: 'The sent body is inside the frame (or its pane) for at least 95% of a flight\'s ticks (Camera\'s measure, launch_probe.gd; AI against AI, every launch)', status: Number.isFinite(all.s) ? (all.s >= 0.95 ? 'PASS' : 'FAIL') : 'PENDING', value: Number.isFinite(all.s) ? `${pct(all.s)} (${all.o} off of ${all.f} flight ticks, ${all.n} launches in ${runs.length} seeds)` : 'no launch', band: 'at least 95%' },
    { id: 'frame.inflight.computer', what: '... for the computer\'s victims only (slot 1: the ones Orb meant)', status: Number.isFinite(pc.s) ? (pc.s >= 0.95 ? 'PASS' : 'FAIL') : 'PENDING', value: Number.isFinite(pc.s) ? `${pct(pc.s)} (${pc.o} off of ${pc.f} flight ticks, ${pc.n} launches; the longest run off ${pc.longest} ticks)` : 'no launch of slot 1', band: 'at least 95%' },
    { id: 'frame.flightlen', what: 'Flight length, all launches (reported; a full launch\'s flight is meant to run 1.0 to 1.6 s with the curve, and the probe does not tell a full launch)', status: 'INFO', value: secs.length ? `p10 ${q(0.1).toFixed(2)} s, median ${q(0.5).toFixed(2)} s, p90 ${q(0.9).toFixed(2)} s over ${secs.length} flights` : 'no launch', band: 'reported' }
  ];
}

(async () => {
  const t0 = Date.now(), ids = Array.from({ length: seeds }, (_, i) => base + i);
  const runs = await pool(ids.map(s => () => one(s)), jobs);
  const R = rows(runs), out = arg('out', ''), md = arg('md', '');
  if (out) fs.writeFileSync(out, JSON.stringify({ seeds: ids, ticks, runs }));
  const T = ['| Status | Id | Measure | Value | Band |', '| :--- | :--- | :--- | :--- | :--- |'];
  for (const r of R) T.push(`| ${r.status === 'FAIL' ? '**FAIL**' : r.status} | ${r.id} | ${r.what} | ${r.value} | ${r.band} |`);
  const text = T.join('\n') + '\n';
  if (md) fs.writeFileSync(md, text);
  console.log(text + `(${Math.round((Date.now() - t0) / 1000)} s, ${ids.length} seeds, ROOT ${ROOT})`);
})().catch(e => { console.error(e); process.exit(1); });

module.exports = { rows };
