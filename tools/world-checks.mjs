// World's check scripts for CI (the world job in .github/workflows/ci.yml): which sim/world/tools/*.gd scripts run, read from tools/world-checks.json.
//   node tools/world-checks.mjs --verify    every script in sim/world/tools/ is classified (run, or left out with a reason), and nothing listed is missing; exit 1 otherwise
//   node tools/world-checks.mjs --list      the names to run, one per line (what the CI loop reads)
//   node tools/world-checks.mjs --run       runs each through tools/gate.mjs --verdict (GODOT in the environment, or "godot" on the path), keeps going after a failure, names the failures, exit 1 if any
//   --list and --run take --shard K/N (1-based): only every N-th check of the list, from the K-th (the CI world job runs three shards in parallel, 2026-11-22: the 90 checks added up to 32 minutes in one step on GW1b).
// A check that is slow or flaky is moved to "leaveOut" here with its reason, never dropped from the file.
import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

/** The checks of shard k of n (1-based): the k-th, the (k+n)-th ... of the list, so n shards together run every check exactly once. Null for a shard that is not 1 <= k <= n. Pure. */
export function shardOf(run, k, n) {
  if (!Number.isInteger(k) || !Number.isInteger(n) || n < 1 || k < 1 || k > n) return null;
  return run.filter((_, i) => i % n === k - 1);
}
const dir = join(root, 'sim', 'world', 'tools');

/** Problems with the classification against the scripts on disk (an array of strings; empty when it holds). `list` and `files` override the file and the folder listing (a test). */
export function verifyProblems(list = JSON.parse(readFileSync(join(root, 'tools', 'world-checks.json'), 'utf8')), files = readdirSync(dir)) {
  const out = [];
  const scripts = files.filter((f) => f.endsWith('.gd')).map((f) => f.slice(0, -3));
  const run = list.run || [], left = Object.keys(list.leaveOut || {});
  for (const n of scripts) {
    if (!run.includes(n) && !left.includes(n)) out.push(`sim/world/tools/${n}.gd is in neither "run" nor "leaveOut" of tools/world-checks.json: a check goes in "run", a probe or soak in "leaveOut" with its reason`);
  }
  for (const n of [...run, ...left]) if (!scripts.includes(n)) out.push(`tools/world-checks.json names ${n}, which is not in sim/world/tools/`);
  for (const n of run) if (left.includes(n)) out.push(`${n} is in both "run" and "leaveOut"`);
  for (const [n, why] of Object.entries(list.leaveOut || {})) if (!String(why).trim()) out.push(`leaveOut "${n}" has no reason`);
  const dup = run.filter((n, i) => run.indexOf(n) !== i);
  for (const n of dup) out.push(`${n} is listed twice in "run"`);
  return out;
}

if (process.argv[1] && resolve(process.argv[1]) === resolve(import.meta.filename)) {
  const a = process.argv[2];
  const list = JSON.parse(readFileSync(join(root, 'tools', 'world-checks.json'), 'utf8'));
  let todo = list.run;
  const si = process.argv.indexOf('--shard');
  if (si >= 0) {
    const mm = /^(\d+)\/(\d+)$/.exec(process.argv[si + 1] || '');
    const part = mm ? shardOf(list.run, Number(mm[1]), Number(mm[2])) : null;
    if (!part) { console.error('world-checks: --shard wants K/N with 1 <= K <= N, for example --shard 2/3'); process.exit(2); }
    todo = part;
  }
  if (a === '--list') { console.log(todo.join('\n')); process.exit(0); }
  const bad = verifyProblems(list);
  for (const m of bad) console.error(`world-checks: ${m}`);
  if (a === '--verify' || bad.length) { if (!bad.length) console.log(`world-checks: ok, ${list.run.length} checks run in CI, ${Object.keys(list.leaveOut).length} scripts left out with a reason`); process.exit(bad.length ? 1 : 0); }
  if (a === '--run') {
    const godot = process.env.GODOT || 'godot';
    const failed = [];
    for (const n of todo) {
      console.log(`::group::${n}`);
      const r = spawnSync(process.execPath, [join(root, 'tools', 'gate.mjs'), '--verdict', '--', godot, '--headless', '--path', root, '--script', `res://sim/world/tools/${n}.gd`], { stdio: 'inherit', cwd: root });
      console.log('::endgroup::');
      if (r.status !== 0) { failed.push(n); console.log(`::error::World check ${n} failed (exit ${r.status})`); }
    }
    if (failed.length) { console.error(`world-checks: ${failed.length} of ${todo.length} failed: ${failed.join(', ')}`); process.exit(1); }
    console.log(`world-checks: all ${todo.length} passed`);
    process.exit(0);
  }
  console.error('usage: node tools/world-checks.mjs --verify | --list | --run');
  process.exit(2);
}
