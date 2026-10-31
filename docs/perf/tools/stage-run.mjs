// One headless Godot run of a stage-timer tree (docs/perf/tools/make-stage-tree.mjs): an AI match at a fixed 60 fps, as fast as the machine goes, one CSV row per frame (PerfT). No window, no GPU.
// Below-normal priority, a time limit, the machine's load read before and after (the row says if the run is valid), one Godot, gone when this ends. Owner: Performance and Platform.
//   node docs/perf/tools/stage-run.mjs --tree <dir> --out <csv> [--seed 4] [--frames 7200] [--planet 7] [--limit 1500]
import { spawn } from 'node:child_process';
import { closeSync, openSync, writeFileSync } from 'node:fs';
import { cpus, constants as osConstants, setPriority } from 'node:os';
import { join } from 'node:path';

const a = process.argv.slice(2);
const opt = (n, d) => { const i = a.indexOf(n); return i >= 0 && i + 1 < a.length ? a[i + 1] : d; };
const tree = opt('--tree'), out = opt('--out');
if (!tree || !out) { console.error('usage: node stage-run.mjs --tree <dir> --out <csv> [--seed 4] [--frames 7200] [--planet 7] [--script] [--limit 1500]'); process.exit(2); }
const godot = process.env.GODOT || join(process.env.LOCALAPPDATA || '', 'Programs', 'Godot', '4.7.2', 'Godot_v4.7.2-stable_win64_console.exe');
const seed = opt('--seed', '4'), frames = opt('--frames', '7200'), planet = opt('--planet', ''), limitS = Number(opt('--limit', 1500));

const snap = () => cpus().reduce((t, c) => ({ idle: t.idle + c.times.idle, all: t.all + c.times.user + c.times.nice + c.times.sys + c.times.irq + c.times.idle }), { idle: 0, all: 0 });
const load = async (ms = 1500) => { const s0 = snap(); await new Promise((r) => setTimeout(r, ms)); const s1 = snap(); return Math.round(100 * (1 - (s1.idle - s0.idle) / (s1.all - s0.all))); };

const before = await load();
const args = ['--headless', '--path', tree, '--fixed-fps', '60', '--resolution', `${opt('--width', 1280)}x${opt('--height', 720)}`, '--', `--seed=${seed}`, `--vpw=${opt("--width", 1280)}`, `--vph=${opt("--height", 720)}`, `--frames=${frames}`, '--bench', `--perfout=${out}`];
if (planet) args.push(`--planet=${planet}`);
if (a.includes('--script')) args.push('--script=1');
if (opt('--stress', '')) args.push(`--stress=${opt('--stress')}`);
if (opt('--arenacols', '')) args.push(`--arenacols=${opt('--arenacols')}`);   // a planet arena of N columns (hook-turn2.mjs)
if (opt('--extra', '')) for (const x of opt('--extra').split(',')) args.push(`--${x}`);   // the game's own switches, e.g. --extra vfx-quality=0,noclouds
if (a.includes('--ringcost')) args.push('--ringcost=1');   // the whole-ring probe (hook-ringcost.mjs)
if (a.includes('--turn')) args.push('--turn=1', `--turnk=${opt('--turnk', 32)}`, `--turnfb=${opt('--turnfb', 2.5)}`);   // World's calm-moment turn, staged at tick 10 (hook-turn2.mjs)   // a ground-level power-up every N frames (hook-script.mjs)   // the scripted first player (hook-script.mjs)
const logFile = `${out}.log`;
const fd = openSync(logFile, 'w');
const t0 = Date.now();
const child = spawn(godot, args, { stdio: ['ignore', fd, fd], windowsHide: true });
try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
console.log(`godot pid ${child.pid} (below-normal), seed ${seed}, ${frames} frames${planet ? `, planet ${planet}` : ', hand-made world'}, load before ${before}%`);
const timer = setTimeout(() => { try { child.kill(); } catch { /* gone */ } }, limitS * 1000);
const code = await new Promise((ok) => child.on('close', (c) => ok(c)));
clearTimeout(timer); closeSync(fd);
const after = await load();
const meta = { out, seed, frames, planet, exit: code, seconds: Math.round((Date.now() - t0) / 1000), loadBefore: before, loadAfter: after };
writeFileSync(`${out}.json`, JSON.stringify(meta));
console.log(JSON.stringify(meta));
process.exit(code === 0 ? 0 : 1);
