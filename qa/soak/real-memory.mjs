// Real memory beside the census, over long matches (QA; qa/soak/real_probe.gd). The EDITOR build, headless, on a scratch copy of a commit; below normal; its data folders in scratch.
//   node qa/soak/real-memory.mjs --tree <imported scratch copy> --commit <rev> --seconds <limit> [--cap 600] [--final-match 2 | --final-after 3300] [--godot <exe>] --out <folder>
// --tree is `git archive <rev> | tar -x` with `godot --headless --path <tree> --import` run once. The only things added to it are the override.cfg, the probe, the census and the list of static names,
// all in <tree>/qa_scratch; override.cfg is removed again afterwards. The run ends itself after the final reading; --seconds is the limit after which it is stopped by its process id.
import { spawn, spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { setPriority, constants as osConstants } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { cleanPaths } from '../../tools/record-paths.mjs';
import { splitter } from './split-lines.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const tree = opt('--tree', null) && resolve(opt('--tree', null));
const out = opt('--out', null) && resolve(opt('--out', null));
const commit = opt('--commit', null);
if (!tree || !out || !commit || !existsSync(join(tree, 'project.godot'))) { console.error('real-memory: --tree <imported copy>, --commit <rev> and --out <folder> are needed'); process.exit(2); }
const godot = opt('--godot', process.env.GODOT || join(process.env.LOCALAPPDATA || '', 'Programs', 'Godot', '4.7.2', 'Godot_v4.7.2-stable_win64_console.exe'));
const limit = Number(opt('--seconds', 4200));
const scratch = join(tree, 'qa_scratch');
mkdirSync(scratch, { recursive: true });
for (const f of ['real_probe.gd', 'soak_census.gd']) copyFileSync(join(HERE, f), join(scratch, f));
const g = spawnSync('git', ['-C', join(HERE, '..', '..'), 'grep', '-E', '^static var [A-Za-z_0-9]+', commit, '--', 'sim', 'render', 'ui', 'audio'], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
const names = String(g.stdout || '').split('\n').map((l) => /^[^:]+:([^:]+):static var ([A-Za-z_0-9]+)/.exec(l)).filter((m) => m && !m[1].includes('/tools/')).map((m) => `res://${m[1]}|${m[2]}`);
if (!names.length) { console.error('real-memory: git grep found no static var at ' + commit); process.exit(1); }
const fwd = (p) => p.replace(/\\/g, '/');
writeFileSync(join(scratch, 'statics.txt'), names.join('\n') + '\n');
writeFileSync(join(tree, 'override.cfg'), `[autoload]\n\nRealProbe="*${fwd(join(scratch, 'real_probe.gd'))}"\n`);
mkdirSync(out, { recursive: true });
const data = join(out, 'userdata');
for (const k of ['appdata', 'localappdata']) mkdirSync(join(data, k), { recursive: true });
const args = ['--headless', '--path', tree, '--max-fps', '60', '--', '--frames=2000000000', `--rm-cap=${Number(opt('--cap', 600))}`, `--rm-names=${fwd(join(scratch, 'statics.txt'))}`,
  ...(opt('--final-match', null) ? [`--rm-final-match=${opt('--final-match', null)}`] : []), ...(opt('--final-after', null) ? [`--rm-final-after=${opt('--final-after', null)}`] : [])];
const child = spawn(godot, args, { env: { ...process.env, APPDATA: join(data, 'appdata'), LOCALAPPDATA: join(data, 'localappdata') }, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });
try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
const lines = [];
const streams = [child.stdout, child.stderr].map((s) => {
  const cut = splitter((l) => { lines.push(l); if (l.startsWith('RM ')) console.log(l.slice(0, 220)); });
  s.setEncoding('utf8'); s.on('data', (d) => cut.take(d)); return cut;
});
let hung = false;
const killTree = () => { try { spawnSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], { windowsHide: true }); } catch { /* gone */ } };
const timer = setTimeout(() => { hung = true; killTree(); }, limit * 1000);
for (const sig of ['SIGINT', 'SIGTERM']) process.on(sig, () => { killTree(); process.exit(1); });
const code = await new Promise((done) => { child.on('close', done); child.on('error', () => done(-1)); });
clearTimeout(timer);
for (const s of streams) s.end();
rmSync(join(tree, 'override.cfg'), { force: true });
writeFileSync(join(out, 'run.log'), cleanPaths(lines.join('\n')) + '\n');
const errors = lines.filter((l) => /SCRIPT ERROR|Parse Error/.test(l)).length;
console.log(`real-memory: exit ${code}${hung ? ' (stopped at the time limit)' : ''}; script errors ${errors}; ${lines.filter((l) => l.startsWith('RM ')).length} readings in ${join(out, 'run.log')}`);
process.exit(code === 0 && !hung && errors === 0 && lines.some((l) => l.startsWith('RM scene')) ? 0 : 1);
