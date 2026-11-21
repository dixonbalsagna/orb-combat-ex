// The screen sweep (A-UI-09; docs/ui/screen-sweep.md): a still of every menu and HUD state at one screen size (1280 by 800, the Steam Deck's, by default), and for each the smallest text on it.
//   node ui/tools/sweep.mjs --dir <the demo's web export> --out <folder> [--godot <godot exe> --tree <project folder>] [--size 1280x800] [--floor 9] [--aim 12] [--skip-stills] [--only id,id]
// Two halves, one table:
//   the text half: ui/tools/screen_sweep.gd, run headless (at most one Godot process), draws each state with every line's size and rectangle kept and prints `SWEEP {json}` a state;
//   the picture half: one still a state through tools/machine/capture.mjs (Tools' launcher, one capture at a time, a time limit, below-normal priority), the page's query being the state's `query`.
// It writes <out>/sweep.json and <out>/sweep.md (a row a state: the still, the smallest text's size and line, the lines that went off the screen, a verdict). A state fails when its smallest text is under
// the floor (9 px) and is listed as "aim" when under 12 px; a clipped or small text is listed, not fixed (A1). Nothing here touches the game or the sim.
import { spawnSync } from 'node:child_process';
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';

const argv = process.argv.slice(2);
const opt = (n, d) => { const i = argv.indexOf(n); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : d; };
const has = (n) => argv.includes(n);
const DIR = opt('--dir'), OUT = opt('--out');
const TREE = opt('--tree', '.');
const GODOT = opt('--godot', process.env.GODOT || 'godot');
const SIZE = opt('--size', '1280x800');
const FLOOR = Number(opt('--floor', 9)), AIM = Number(opt('--aim', 12));
const ONLY = opt('--only', '') ? opt('--only').split(',') : null;
if (!OUT || (!DIR && !has('--skip-stills'))) { console.error('usage: node ui/tools/sweep.mjs --dir <the demo web export> --out <folder> [--godot <exe> --tree <project>] [--size 1280x800] [--skip-stills] [--only id,id]'); process.exit(2); }
const [W, H] = SIZE.split('x').map(Number);
mkdirSync(OUT, { recursive: true });

// The text half.
console.log(`sweep: the text pass at ${SIZE} (one headless Godot)`);
const g = spawnSync(GODOT, ['--headless', '--path', TREE, '--script', 'res://ui/tools/screen_sweep.gd', '--', `--size=${SIZE}`], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 });
const states = [];
for (const line of (g.stdout || '').split(/\r?\n/)) {
  if (line.startsWith('SWEEP ')) states.push(JSON.parse(line.slice(6)));
}
if (!(g.stdout || '').includes('SWEEP_DONE') || states.length === 0) { console.error('sweep: the text pass did not finish\n' + (g.stdout || '').slice(-1500) + (g.stderr || '').slice(-1500)); process.exit(1); }

// The picture half.
const capture = resolve(import.meta.dirname || '.', '..', '..', 'tools', 'machine', 'capture.mjs');
for (const s of states) {
  if (ONLY && !ONLY.includes(s.id)) { s.still = ''; continue; }
  s.still = '';
  if (has('--skip-stills')) continue;
  const png = join(OUT, `${s.id}-${SIZE}.png`);
  const r = spawnSync(process.execPath, [capture, 'still', '--dir', DIR, '--path', `/index.html?${s.query}`, '--out', png, '--width', String(W), '--height', String(H), '--wait-ms', '7000', '--session', 'ui-ux', '--purpose', 'look', '--time-limit', '120', '--quiet'], { encoding: 'utf8' });
  if (r.status === 0 && existsSync(png)) s.still = `${s.id}-${SIZE}.png`;
  else console.error(`sweep: no still for ${s.id}: ${(r.stderr || r.stdout || '').slice(0, 200)}`);
  console.log(`  ${s.id}: ${s.still || 'NO STILL'}  smallest text ${s.min_px} px`);
}

// The table.
const verdict = (s) => (s.lines === 0 ? 'no text' : s.min_px < FLOOR ? 'FAIL: under the floor' : s.min_px < AIM ? 'aim: under 12 px' : 'ok');
const rows = states.map((s) => ({ ...s, verdict: verdict(s) }));
writeFileSync(join(OUT, 'sweep.json'), JSON.stringify({ size: SIZE, floor: FLOOR, aim: AIM, states: rows }, null, 2));
const md = [`# Screen sweep at ${SIZE}`, '', `Floor ${FLOOR} px (fails), aim ${AIM} px. A clipped or small text is listed here and not fixed (A1). Stills through tools/machine/capture.mjs.`, '',
  '| State | Still | Lines | Smallest text | Its line | Off screen | Verdict |', '| :--- | :--- | ---: | ---: | :--- | ---: | :--- |',
  ...rows.map((s) => `| ${s.id} | ${s.still || '(none)'} | ${s.lines} | ${s.min_px} px | ${String(s.min_text).replace(/\|/g, '/')} | ${s.outside}${s.outside_first ? ' (' + String(s.outside_first).replace(/\|/g, '/') + ')' : ''} | ${s.verdict} |`), ''].join('\n');
writeFileSync(join(OUT, 'sweep.md'), md);
const fails = rows.filter((s) => s.verdict.startsWith('FAIL')).length, aims = rows.filter((s) => s.verdict.startsWith('aim')).length, clipped = rows.filter((s) => s.outside > 0).length;
console.log(`sweep: ${rows.length} states, ${fails} under the floor, ${aims} under the aim, ${clipped} with text off the screen; ${join(OUT, 'sweep.md')}`);
