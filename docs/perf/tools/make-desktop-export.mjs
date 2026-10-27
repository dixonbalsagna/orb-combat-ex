// Builds a Windows Desktop release export (the "Windows Desktop" preset, Compatibility renderer, the installed release template) of one commit in a scratch folder, headless: a clean `git archive`,
// optional boot marks (scratch-hooks/hook-bootprof3.mjs --native: lines `BP <name> <ms>` on the console build's stdout), then --import and --export-release. Opens no window.
//   node docs/perf/tools/make-desktop-export.mjs --out <folder> [--rev <commit>] [--marks] [--godot <exe>]
// The result: <out>/win/orb-combat-ex.exe (and orb-combat-ex.console.exe, which the preset's console wrapper makes).
import { spawn, spawnSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { setPriority, constants } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..', '..');
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const OUT = opt('--out');
if (!OUT) { console.error('usage: node docs/perf/tools/make-desktop-export.mjs --out <folder> [--rev <commit>] [--marks] [--godot <exe>]'); process.exit(2); }
const REV = opt('--rev', 'HEAD'), MARKS = argv.includes('--marks');
const GODOT = opt('--godot', 'C:/Users/itsha/AppData/Local/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe');
const out = resolve(OUT);
const dir = join(out, 'src');
if (existsSync(join(dir, 'project.godot'))) { console.error('already there: ' + dir); process.exit(1); }
mkdirSync(dir, { recursive: true });
const r = spawnSync(`git -C "${repo}" archive ${REV} | tar -x`, { cwd: dir, shell: true, encoding: 'utf8' });
if (r.status) throw new Error('git archive failed: ' + r.stderr);
writeFileSync(join(out, 'REV.txt'), spawnSync('git', ['rev-parse', REV], { cwd: repo, encoding: 'utf8' }).stdout);
if (MARKS) {
  const h = spawnSync(process.execPath, [join(here, 'scratch-hooks', 'hook-bootprof3.mjs'), dir, '--native'], { encoding: 'utf8' });
  if (h.status) throw new Error('hook: ' + (h.stderr || h.stdout));
  console.log(h.stdout.trim());
}
function godot(args, log, limitS) {
  return new Promise((ok) => {
    const p = spawn(GODOT, args, { cwd: dir, windowsHide: true });
    try { setPriority(p.pid, constants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
    let text = '';
    p.stdout.on('data', (d) => { text += d; }); p.stderr.on('data', (d) => { text += d; });
    const t = setTimeout(() => { try { process.kill(p.pid); } catch { /* gone */ } }, limitS * 1000);
    p.on('exit', (c) => { clearTimeout(t); writeFileSync(log, text); ok(c); });
  });
}
const c1 = await godot(['--headless', '--path', '.', '--import'], join(out, 'import.log'), 1500);
mkdirSync(join(dir, 'build', 'win'), { recursive: true });
const c2 = await godot(['--headless', '--path', '.', '--export-release', 'Windows Desktop', 'build/win/orb-combat-ex.exe'], join(out, 'export.log'), 1500);
if (!existsSync(join(dir, 'build', 'win', 'orb-combat-ex.exe'))) { console.error(`export failed (import ${c1}, export ${c2}); see the logs in ${out}`); process.exit(1); }
cpSync(join(dir, 'build', 'win'), join(out, 'win'), { recursive: true });
console.log('built ' + join(out, 'win'));
