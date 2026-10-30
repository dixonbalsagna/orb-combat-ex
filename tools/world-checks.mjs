// World's check scripts for CI (the world job in .github/workflows/ci.yml): which sim/world/tools/*.gd scripts run, read from tools/world-checks.json.
//   node tools/world-checks.mjs --verify    every script in sim/world/tools/ is classified (run, or left out with a reason), and nothing listed is missing; exit 1 otherwise
//   node tools/world-checks.mjs --list      the names to run, one per line (what the CI loop reads)
//   node tools/world-checks.mjs --run       runs each through tools/gate.mjs --verdict (GODOT in the environment, or "godot" on the path), keeps going after a failure, names the failures, exit 1 if any
// A check that is slow or flaky is moved to "leaveOut" here with its reason, never dropped from the file.
import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
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
  if (a === '--list') { console.log(list.run.join('\n')); process.exit(0); }
  const bad = verifyProblems(list);
  for (const m of bad) console.error(`world-checks: ${m}`);
  if (a === '--verify' || bad.length) { if (!bad.length) console.log(`world-checks: ok, ${list.run.length} checks run in CI, ${Object.keys(list.leaveOut).length} scripts left out with a reason`); process.exit(bad.length ? 1 : 0); }
  if (a === '--run') {
    const godot = process.env.GODOT || 'godot';
    const failed = [];
    for (const n of list.run) {
      console.log(`::group::${n}`);
      const r = spawnSync(process.execPath, [join(root, 'tools', 'gate.mjs'), '--verdict', '--', godot, '--headless', '--path', root, '--script', `res://sim/world/tools/${n}.gd`], { stdio: 'inherit', cwd: root });
      console.log('::endgroup::');
      if (r.status !== 0) { failed.push(n); console.log(`::error::World check ${n} failed (exit ${r.status})`); }
    }
    if (failed.length) { console.error(`world-checks: ${failed.length} of ${list.run.length} failed: ${failed.join(', ')}`); process.exit(1); }
    console.log(`world-checks: all ${list.run.length} passed`);
    process.exit(0);
  }
  console.error('usage: node tools/world-checks.mjs --verify | --list | --run');
  process.exit(2);
}
