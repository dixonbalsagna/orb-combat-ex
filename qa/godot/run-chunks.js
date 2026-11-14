#!/usr/bin/env node
// Runs one Godot script as parallel chunks of matches at below-normal priority and keeps each chunk's output (QA, sprint A1).
//   node qa/godot/run-chunks.js --root=<tree> --script=res://tools/feel/gauntlet.gd --total=200 --chunks=3 --base=1 --out=<prefix> -- <script args after the two positional numbers, e.g. --arm=orbs --level=easy --capsec=900>
// Chunk k plays matches base + offset .. +size-1 (positional <matches> <baseSeed>), so chunks never share a seed; each chunk's stdout lines go to <prefix>_<k>.out. At most --chunks Godot processes run at once; each child is set to below-normal priority and the run exits when
// every child has. The env (QA_PLANET) is inherited. Stops only its own children, by pid, on SIGINT.
const { spawn } = require('child_process');
const fs = require('fs'), os = require('os'), path = require('path');
const arg = (k, d) => { const a = process.argv.slice(2).find(x => x.startsWith('--' + k + '=')); return a ? a.slice(k.length + 3) : d; };
const dd = process.argv.indexOf('--');
const extra = dd >= 0 ? process.argv.slice(dd + 1) : [];
const root = path.resolve(arg('root', '.')), script = arg('script', ''), total = parseInt(arg('total', '60'), 10), chunks = parseInt(arg('chunks', '3'), 10), base = parseInt(arg('base', '1'), 10), out = arg('out', 'chunk');
const GODOT = process.env.GODOT || path.join(process.env.LOCALAPPDATA || '', 'Programs', 'Godot', '4.7.2', 'Godot_v4.7.2-stable_win64_console.exe');
const per = Math.floor(total / chunks), rem = total % chunks;
let off = 0; const kids = []; let left = chunks;
for (let k = 0; k < chunks; k++) {
  const n = per + (k < rem ? 1 : 0), seed = base + off; off += n;
  const o = fs.createWriteStream(`${out}_${k}.out`);
  const c = spawn(GODOT, ['--headless', '--path', root, '--script', script, '--', String(n), String(seed), ...extra], { stdio: ['ignore', 'pipe', 'pipe'] });
  try { os.setPriority(c.pid, os.constants.priority.PRIORITY_BELOW_NORMAL); } catch (e) { /* stays at the priority it has */ }
  kids.push(c);
  c.stdout.on('data', d => { for (const l of String(d).split('\n')) if (/^(GAUNTLET|STICKPLAY|RECORDS|SCRIPT ERROR|ERROR)/.test(l)) o.write(l + '\n'); });
  c.stderr.on('data', d => { for (const l of String(d).split('\n')) if (/SCRIPT ERROR/.test(l)) o.write(l + '\n'); });
  c.on('exit', code => { o.write(`EXIT ${code} matches ${n} seed ${seed}\n`); o.end(); if (--left === 0) process.exit(0); });
}
process.on('SIGINT', () => { for (const c of kids) { try { c.kill(); } catch (e) { /* done */ } } process.exit(1); });
