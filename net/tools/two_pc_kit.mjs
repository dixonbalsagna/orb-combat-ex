// Makes the two-PC kit (docs/net/two-pc-check.md): a folder to copy to each PC, with Godot's console build, the game logic and data, and two double-click files. Nothing is installed, and nothing touches the network.
//   node net/tools/two_pc_kit.mjs --out=FOLDER --godot=PATH\Godot_v4.7.2-stable_win64_console.exe --build=NAME [--root=PROJECT] [--ticks=3600]
import { cpSync, copyFileSync, existsSync, mkdirSync, readdirSync, writeFileSync } from 'node:fs';
import { basename, dirname, join, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const a = Object.fromEntries(process.argv.slice(2).map((s) => { const [k, ...v] = s.replace(/^--/, '').split('='); return [k, v.join('=')]; }));
if (!a.out || !a.godot || !a.build) { console.error('--out, --godot and --build are required'); process.exit(2); }
if (!/^[A-Za-z0-9._-]+$/.test(a.build)) { console.error('--build: letters, digits, dot, dash and underscore only'); process.exit(2); }
const root = resolve(a.root || join(dirname(fileURLToPath(import.meta.url)), '..', '..'));
const out = resolve(a.out);
const ticks = String(parseInt(a.ticks || '3600', 10));
if (out === root || out.startsWith(root + sep)) { console.error('--out must be outside the project'); process.exit(2); }
if (existsSync(out) && readdirSync(out).length > 0) { console.error(`${out} is not empty`); process.exit(2); }
if (!existsSync(join(root, '.godot', 'global_script_class_cache.cfg'))) { console.error('run godot --headless --path . --import first'); process.exit(2); }

const game = join(out, 'game');
mkdirSync(join(game, '.godot'), { recursive: true });
for (const d of ['sim', 'data', 'net']) cpSync(join(root, d), join(game, d), { recursive: true });
copyFileSync(join(root, 'project.godot'), join(game, 'project.godot'));
for (const f of ['global_script_class_cache.cfg', 'uid_cache.bin']) copyFileSync(join(root, '.godot', f), join(game, '.godot', f));
mkdirSync(join(out, 'godot'));
const con = resolve(a.godot);
copyFileSync(con, join(out, 'godot', basename(con)));
const main = con.replace(/_console\.exe$/i, '.exe');
copyFileSync(main, join(out, 'godot', basename(main)));

const exe = `godot\\${basename(con)}`;
const lines = (l) => l.join('\r\n') + '\r\n';
writeFileSync(join(out, 'run-on-this-pc.cmd'), lines([
  '@echo off',
  'rem The two-PC check: plays one match and a rematch with no picture and writes this PC\'s report next to this file. No network.',
  'cd /d "%~dp0"',
  'echo Playing a match with no picture. This takes a minute or two. Nothing goes over the network.',
  `start "" /belownormal /wait /b "${exe}" --headless --path game --script res://net/tools/two_pc_check.gd -- --out="%~dp0report-%RANDOM%.txt" --build=${a.build} --ticks=${ticks} --timeout=900`,
  'if errorlevel 1 (echo It did not finish. Tell the EP.) else (echo Done. The report is the file named report- next to this one.)',
  'pause',
]));
writeFileSync(join(out, 'compare-two-reports.cmd'), lines([
  '@echo off',
  'rem Put both PCs\' reports next to this file and run it.',
  'cd /d "%~dp0"',
  'set A=',
  'set B=',
  'set N=0',
  'for %%f in (report-*.txt) do set /a N+=1',
  'if not "%N%"=="2" (echo Need exactly two report files here, and found %N%.& pause & exit /b 2)',
  'for %%f in (report-*.txt) do (if not defined A (set "A=%~dp0%%f") else if not defined B set "B=%~dp0%%f")',
  `"${exe}" --headless --path game --script res://net/tools/two_pc_check.gd -- --compare="%A%,%B%"`,
  'pause',
]));
console.log(`kit in ${out}, build ${a.build}, ${ticks} ticks`);
