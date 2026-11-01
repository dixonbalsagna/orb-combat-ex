#!/usr/bin/env node
// Builds the old-PC kit (Performance and Platform, 2026-11-01): ONE folder to copy to the old PC by USB stick, with ONE file to double-click in it (RUN-TEST.cmd).
//   node docs/perf/oldpc/kit/build-kit.mjs --site <the web build folder with index.html> --out <new empty folder> [--build <name for the two-PC check, default: the tree's short commit>] [--tree <a project tree with sim/ and data/, default: the repo>] [--godot-dir <folder with Godot_v4.7.2-stable_win64.exe and its _console.exe>]
// The folder holds: RUN-TEST.cmd (the batch file with PowerShell and the test page inside), game\ (the web build), project\ (sim/, data/, net/, project.godot, oldpc_sim.gd: no art, no audio; with net/tools/two_pc_check.gd in the tree, Netcode's two-PC check runs as part 1a),
// godot\ (the two Godot executables, copied from this PC; the editor install, not a download), README.txt. Nothing is fetched from the network.
import { execFileSync, spawnSync } from 'node:child_process';
import { copyFileSync, cpSync, existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(HERE, '..', '..', '..', '..');
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const SITE = opt('--site') && resolve(opt('--site'));
const OUT = opt('--out') && resolve(opt('--out'));
const TREE = resolve(opt('--tree', REPO));
const GODOT = resolve(opt('--godot-dir', 'C:/Users/itsha/AppData/Local/Programs/Godot/4.7.2'));
let BUILD = opt('--build', '');
if (!BUILD) { try { BUILD = execFileSync('git', ['-C', TREE, 'rev-parse', '--short', 'HEAD'], { encoding: 'utf8' }).trim(); } catch { BUILD = ''; } }
if (!/^[A-Za-z0-9._-]+$/.test(BUILD)) { console.error('--build <name> is required (letters, digits, dot, dash, underscore): both PCs must run ONE kit, and the two-PC check refuses reports of different builds'); process.exit(2); }
const die = (m) => { console.error(m); process.exit(2); };
if (!SITE || !existsSync(join(SITE, 'index.html'))) die('--site <folder with the game\'s index.html> is required');
if (!OUT) die('--out <new folder> is required');
if (existsSync(OUT) && readdirSync(OUT).length) die(`${OUT} is not empty`);
for (const d of ['sim', 'data', 'net']) if (!existsSync(join(TREE, d))) die(`${TREE} has no ${d}/`);
if (!existsSync(join(TREE, 'project.godot'))) die(`${TREE} has no project.godot`);
const exes = ['Godot_v4.7.2-stable_win64.exe', 'Godot_v4.7.2-stable_win64_console.exe'];
for (const e of exes) if (!existsSync(join(GODOT, e))) die(`${join(GODOT, e)} not found (--godot-dir)`);

mkdirSync(OUT, { recursive: true });
cpSync(SITE, join(OUT, 'game'), { recursive: true });
mkdirSync(join(OUT, 'project'));
for (const d of ['sim', 'data', 'net']) cpSync(join(TREE, d), join(OUT, 'project', d), { recursive: true, filter: (s) => !/[\\/]\.godot([\\/]|$)/.test(s) });
copyFileSync(join(TREE, 'project.godot'), join(OUT, 'project', 'project.godot'));
copyFileSync(join(HERE, 'oldpc_sim.gd'), join(OUT, 'project', 'oldpc_sim.gd'));
mkdirSync(join(OUT, 'godot'));
for (const e of exes) copyFileSync(join(GODOT, e), join(OUT, 'godot', e));

// Godot must import the project once so its class names are known (a fresh copy has no .godot folder); do it here, so the old PC does not have to (RUN-TEST.cmd does it too if the folder is missing).
const imp = spawnSync(join(OUT, 'godot', exes[1]), ['--headless', '--path', join(OUT, 'project'), '--import', '--quit'], { timeout: 600000, windowsHide: true, encoding: 'utf8' });
if (!existsSync(join(OUT, 'project', '.godot', 'global_script_class_cache.cfg'))) die(`Godot's import made no class cache (exit ${imp.status}): ${String(imp.stdout || '').slice(-400)}`);

const page = readFileSync(join(HERE, '..', 'page.html'), 'utf8').replace(/\r\n/g, '\n');
if (/^'@/m.test(page)) die('page.html has a line starting with \'@ (it would end the here-string)');
const tpl = readFileSync(join(HERE, 'run-test.template.cmd'), 'utf8').replace(/\r\n/g, '\n');
if (!tpl.includes('@@PAGE@@')) die('the template has no @@PAGE@@');
writeFileSync(join(OUT, 'RUN-TEST.cmd'), tpl.replace('@@BUILD@@', BUILD).replace('@@PAGE@@', () => page.replace(/\n$/, '')).replace(/\n/g, '\r\n'));

writeFileSync(join(OUT, 'README.txt'), [
  'Orb Combat EX - old PC test kit',
  '',
  '1. Copy this whole folder to the old PC (USB stick). Do not copy it to a shared or public place.',
  '2. Close games and other browser windows. Plug the PC in the wall. Only you watch the screen; no photos, screenshots or recordings.',
  '3. Double-click RUN-TEST.cmd and press Enter when it asks. The first part has no window and takes a minute or two.',
  '   The second part opens your browser: press Start, read the game\'s flashing-effects warning (Reduce flashing is there), click "I understand, start",',
  '   then leave the mouse and keyboard alone for two minutes.',
  '4. When it says Done, bring back the ONE file it names (oldpc-result-....json). Delete the folder afterwards if you like.',
  '',
  'It listens only on this PC (127.0.0.1), opens no network port, installs nothing and uploads nothing. It is a speed reading, not a flash reading.',
  'If you want it on the built-in graphics as well: move the monitor cable to the board\'s video port and run RUN-TEST.cmd a second time (the result file names the graphics it ran on).',
  '',
].join('\r\n'));

const size = (p) => { let n = 0; const w = (d) => { for (const e of readdirSync(d, { withFileTypes: true })) { const f = join(d, e.name); if (e.isDirectory()) w(f); else n += statSync(f).size; } }; w(p); return n; };
if (!existsSync(join(OUT, 'project', 'net', 'tools', 'two_pc_check.gd'))) console.log("NOTE: this tree has no net/tools/two_pc_check.gd (Netcode's docs/net/pending/two-pc-check is not applied): the kit will run the speed part only.");
console.log(`kit built in ${OUT}: ${(size(OUT) / 1048576).toFixed(0)} MB (game ${(size(join(OUT, 'game')) / 1048576).toFixed(0)}, project ${(size(join(OUT, 'project')) / 1048576).toFixed(0)}, godot ${(size(join(OUT, 'godot')) / 1048576).toFixed(0)})`);
