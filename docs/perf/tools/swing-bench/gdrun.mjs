// usage: node gdrun.mjs <tree> <out> <timeoutSec> <script res path> [user args...]
import { spawn } from 'node:child_process';
import { closeSync, openSync, writeFileSync } from 'node:fs';
import { constants as osConstants, setPriority } from 'node:os';
const [tree, out, tmo, script, ...rest] = process.argv.slice(2);
const godot = 'C:/Users/itsha/AppData/Local/Programs/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe';
const fd = openSync(out, 'w');
const child = spawn(godot, ['--headless', '--path', tree, '--script', script, '--', ...rest], { stdio: ['ignore', fd, fd], windowsHide: true });
writeFileSync(out + '.pid', String(child.pid));
try { setPriority(child.pid, osConstants.priority.PRIORITY_BELOW_NORMAL); } catch { /* gone */ }
const timer = setTimeout(() => { try { child.kill(); } catch { /* gone */ } }, Number(tmo) * 1000);
const code = await new Promise((ok) => child.on('close', (c) => ok(c)));
clearTimeout(timer); closeSync(fd);
console.log('exited', code);
