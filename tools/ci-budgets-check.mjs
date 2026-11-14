// The written time budget of every CI job (A-TOOLS-08, Tools, 2026-11-14).
//
//   node tools/ci-budgets-check.mjs [--runs 3]        ci.yml against tools/ci-budgets.json; with --runs N also the last N successful runs of GitHub (needs the `gh` command)
//   node tools/ci-budgets-check.mjs --self-test
//
// The file check (CI runs it): every job of .github/workflows/ci.yml has an entry in tools/ci-budgets.json, the entry's limit is the job's timeout-minutes, the budget is at most two thirds of the limit
// (rounded up), no entry names a job that is not there. The runs check (by hand, or the EP's two-day read): each of the last N successful runs of the CI workflow, every job's minutes against its budget. Exit 1 on
// any problem, 2 on a bad call. Node built-ins only.
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(fileURLToPath(new URL('.', import.meta.url)), '..');

/** { id -> timeout-minutes } of the jobs of a workflow's text (no YAML library: a job is a two-space key under `jobs:`, its timeout a line of four spaces). Pure. */
export function jobTimeouts(yamlText) {
  const out = {};
  let inJobs = false, cur = null;
  for (const l of yamlText.replace(/\r\n/g, '\n').split('\n')) {
    if (/^jobs:\s*$/.test(l)) { inJobs = true; continue; }
    if (!inJobs) continue;
    if (/^\S/.test(l) && !/^\s*#/.test(l)) break;   // the next top-level key ends the jobs
    const j = /^  ([A-Za-z0-9_-]+):\s*$/.exec(l);
    if (j) { cur = j[1]; out[cur] = null; continue; }
    const t = /^    timeout-minutes:\s*(\d+)/.exec(l);
    if (t && cur) out[cur] = Number(t[1]);
  }
  return out;
}

/** The problems of the file check, from the workflow's timeouts and the budgets file's jobs. Pure. */
export function fileProblems(timeouts, budgets) {
  const out = [];
  for (const [id, lim] of Object.entries(timeouts)) {
    const b = budgets[id];
    if (!b) { out.push(`job ${id} has no entry in tools/ci-budgets.json (a job needs a written budget)`); continue; }
    if (lim === null) out.push(`job ${id} has no timeout-minutes in ci.yml`);
    else if (b.limitMin !== lim) out.push(`job ${id}: ci.yml says ${lim} minutes, tools/ci-budgets.json says ${b.limitMin}`);
    if (typeof b.budgetMin !== 'number' || !(b.budgetMin > 0)) out.push(`job ${id}: the budget is not a number of minutes`);
    else if (lim !== null && b.budgetMin > Math.ceil((lim * 2) / 3)) out.push(`job ${id}: the budget of ${b.budgetMin} minutes is above two thirds of the limit of ${lim} (${Math.ceil((lim * 2) / 3)})`);
  }
  for (const id of Object.keys(budgets)) if (!(id in timeouts)) out.push(`tools/ci-budgets.json names job ${id}, which ci.yml does not have`);
  return out;
}

/** The problems of the runs check, from runs ([{ id, jobs: [{ name, minutes }] }]) and the jobs' titles by id. A job whose title is not known is skipped. Pure. */
export function runProblems(runs, budgets, titleToId) {
  const out = [];
  for (const r of runs) for (const j of r.jobs) {
    const id = titleToId(j.name);
    if (!id || !budgets[id]) continue;
    if (j.minutes > budgets[id].budgetMin) out.push(`run ${r.id}: job ${id} took ${j.minutes} minutes, over its budget of ${budgets[id].budgetMin}`);
  }
  return out;
}

function selfTest() {
  let n = 0, bad = 0;
  const check = (name, ok, extra) => { n++; if (!ok) { bad++; console.log(`  FAIL ${name}${extra ? ': ' + extra : ''}`); } };
  const y = 'name: CI\non:\n  push:\n    branches: [main]\njobs:\n  a:\n    name: A\n    timeout-minutes: 45   # a note\n    steps:\n      - run: x\n  b-c:\n    timeout-minutes: 15\n  nolim:\n    name: x\nenv:\n  K: v\n';
  const t = jobTimeouts(y);
  check('the jobs and their timeouts are read (a trailing note is ignored, a job with none is null, a later top-level key ends the jobs)', JSON.stringify(t) === JSON.stringify({ a: 45, 'b-c': 15, nolim: null }), JSON.stringify(t));
  const ok = { a: { limitMin: 45, budgetMin: 30 }, 'b-c': { limitMin: 15, budgetMin: 10 }, nolim: { limitMin: 10, budgetMin: 6 } };
  check('a budget file that agrees has no problem but the missing timeout', JSON.stringify(fileProblems(t, ok)) === JSON.stringify(['job nolim has no timeout-minutes in ci.yml']));
  check('a job without an entry is a problem', fileProblems({ x: 5 }, {}).some((p) => /job x has no entry/.test(p)));
  check('a limit that differs from ci.yml is a problem', fileProblems({ a: 45 }, { a: { limitMin: 30, budgetMin: 20 } }).some((p) => /says 45 minutes.*says 30/.test(p)));
  check('a budget above two thirds of the limit is a problem; exactly two thirds is not', fileProblems({ a: 45 }, { a: { limitMin: 45, budgetMin: 31 } }).some((p) => /above two thirds/.test(p)) && fileProblems({ a: 45 }, { a: { limitMin: 45, budgetMin: 30 } }).length === 0);
  check('an entry for a job that is gone is a problem', fileProblems({}, { gone: { limitMin: 5, budgetMin: 3 } }).some((p) => /does not have/.test(p)));
  const runs = [{ id: 1, jobs: [{ name: 'Flash count (worst cases)', minutes: 28 }, { name: 'Godot headless checks 1 of 3 (x)', minutes: 41 }, { name: 'Unknown job', minutes: 99 }] }];
  const title = (nm) => (/^Flash/.test(nm) ? 'flash' : /^Godot headless checks 1/.test(nm) ? 'godot-parity' : null);
  const rp = runProblems(runs, { flash: { budgetMin: 30 }, 'godot-parity': { budgetMin: 30 } }, title);
  check('the runs check names a job over its budget, with its run, and skips an unknown title', rp.length === 1 && /run 1: job godot-parity took 41 minutes, over its budget of 30/.test(rp[0]), JSON.stringify(rp));
  console.log(bad ? `ci-budgets self-test: ${bad} of ${n} FAILED` : `ci-budgets self-test ok: ${n} checks`);
  process.exitCode = bad ? 1 : 0;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const a = process.argv.slice(2);
  if (a.includes('--self-test')) selfTest();
  else {
    try {
      const budgets = JSON.parse(readFileSync(join(ROOT, 'tools', 'ci-budgets.json'), 'utf8')).jobs;
      const yaml = readFileSync(join(ROOT, '.github', 'workflows', 'ci.yml'), 'utf8');
      const problems = fileProblems(jobTimeouts(yaml), budgets);
      const ri = a.indexOf('--runs');
      if (ri >= 0) {
        const n = Number(a[ri + 1] || 3);
        const ids = JSON.parse(execFileSync('gh', ['run', 'list', '--workflow', 'ci.yml', '--status', 'success', '--limit', String(n), '--json', 'databaseId'], { encoding: 'utf8' })).map((x) => x.databaseId);
        // the job titles in ci.yml: `name:` under each job id
        const titles = new Map();
        let cur = null, inJobs = false;
        for (const l of yaml.split('\n')) { if (/^jobs:/.test(l)) { inJobs = true; continue; } const j = /^  ([A-Za-z0-9_-]+):\s*$/.exec(l); if (inJobs && j) { cur = j[1]; continue; } const nm = /^    name:\s*(.*)$/.exec(l); if (inJobs && nm && cur && !titles.has(cur)) titles.set(cur, nm[1].replace(/^['"]|['"]$/g, '')); }
        const titleToId = (name) => { for (const [id, t] of titles) if (name === t) return id; return null; };
        const runs = ids.map((id) => ({ id, jobs: JSON.parse(execFileSync('gh', ['run', 'view', String(id), '--json', 'jobs'], { encoding: 'utf8' })).jobs.map((j) => ({ name: j.name, minutes: Math.round((Date.parse(j.completedAt) - Date.parse(j.startedAt)) / 60000) })) }));
        for (const r of runs) console.log(`run ${r.id}: ` + r.jobs.map((j) => `${titleToId(j.name) || j.name.slice(0, 20)} ${j.minutes}`).join(', '));
        problems.push(...runProblems(runs, budgets, titleToId));
      }
      for (const p of problems) console.log(`ci-budgets: ${p}`);
      console.log(problems.length ? `ci-budgets: ${problems.length} problem(s)` : 'ci-budgets ok: every job has a written budget within two thirds of its limit' + (ri >= 0 ? ', and the runs read are inside them' : ''));
      process.exitCode = problems.length ? 1 : 0;
    } catch (e) { console.error(`ci-budgets: ${e.message}`); process.exitCode = 2; }
  }
}
