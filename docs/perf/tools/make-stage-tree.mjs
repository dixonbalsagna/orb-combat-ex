// A SCRATCH project tree of a revision for the stage timers: the private preview's tree (tools/preview: its switches on, its ?planet=N entry) plus hook-stages.mjs, imported by headless Godot.
// Reads the repository (git archive) and writes only under --out. Opens no window.
//   node docs/perf/tools/make-stage-tree.mjs --out <dir> [--rev main] [--off water,floor | --off all] [--no-hook] [--no-import]
import { spawn, spawnSync } from 'node:child_process';
import { closeSync, existsSync, openSync, readFileSync, writeFileSync } from 'node:fs';
import { constants as osConstants, setPriority } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { exportRevision } from '../../../tools/flash/head-export.mjs';
import { SWITCHES, flip, patchMain, resolve as resolveSwitches } from '../../../tools/preview/switches.mjs';

const HERE = fileURLToPath(new URL('.', import.meta.url));
const REPO = resolve(HERE, '..', '..', '..');
const a = process.argv.slice(2);
const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
const out = opt('--out');
if (!out) { console.error('usage: node make-stage-tree.mjs --out <dir> [--rev main] [--off ids] [--no-hook] [--no-import]'); process.exit(2); }
const tree = resolve(out);
const off = a.flatMap((x, i) => (x === '--off' && i + 1 < a.length ? [a[i + 1]] : []));
const r = resolveSwitches(off);
if (r.unknown.length) throw new Error(`unknown switch ${r.unknown.join(', ')}`);
const sha = spawnSync('git', ['rev-parse', '--verify', `${opt('--rev', 'main')}^{commit}`], { cwd: REPO, encoding: 'utf8' }).stdout.trim();
if (!sha) throw new Error('no such revision');
if (existsSync(tree)) throw new Error(`${tree} exists; give a new folder (this script deletes nothing)`);
const ex = exportRevision(REPO, tree, sha);
if (!ex.ok) throw new Error(ex.message);
writeFileSync(join(tree, 'build_info.json'), `${JSON.stringify({ commit: sha.slice(0, 7), date: 'scratch' })}\n`);
for (const sw of SWITCHES) {
  if (!r.active.includes(sw.id)) continue;
  const f = join(tree, ...sw.file.split('/'));
  writeFileSync(f, flip(readFileSync(f, 'utf8'), sw).text);
}
const mainFile = join(tree, 'render', 'core', 'main.gd');
writeFileSync(mainFile, patchMain(readFileSync(mainFile, 'utf8')));
if (!a.includes('--no-hook')) {
  const h = spawnSync(process.execPath, [join(HERE, 'scratch-hooks', 'hook-stages.mjs'), tree], { encoding: 'utf8' });
  process.stdout.write(h.stdout); process.stderr.write(h.stderr);
  if (h.status !== 0) process.exit(1);
  const k = spawnSync(process.execPath, [join(HERE, 'scratch-hooks', 'hook-script.mjs'), tree], { encoding: 'utf8' });
  process.stdout.write(k.stdout); process.stderr.write(k.stderr);
  if (k.status !== 0) process.exit(1);
}
console.log(`tree of ${sha.slice(0, 8)} at ${tree}; switches on: ${r.active.join(', ') || '(none)'}`);
if (!a.includes('--no-import')) {
  const godot = process.env.GODOT || join(process.env.LOCALAPPDATA || '', 'Programs', 'Godot', '4.7.2', 'Godot_v4.7.2-stable_win64_console.exe');
  const log = `${tree}.import.log`;
  const fd = openSync(log, 'w');
  const child = spawn(godot, ['--headless', '--path', tree, '--import'], { stdio: ['ignore', fd, fd], windowsHide: true });
  try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
  const timer = setTimeout(() => { try { child.kill(); } catch { /* gone */ } }, 25 * 60 * 1000);
  const code = await new Promise((ok) => child.on('close', (c) => ok(c)));
  clearTimeout(timer); closeSync(fd);
  console.log(`import exited ${code}; log ${log}`);
}
