// grant_sim.cjs: Simulation's line for the calm-moment turn, for Simulation's OK (sim/core/sim.gd is Simulation's). After
// World's window 3 and Encounter's ct.cjs: WorldEpoch.tick takes the director's hold (DirCalm.hold), so a decided turn
// swaps only on the moment after a landing, and never while the director has something on.
//   node grant_sim.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node grant_sim.cjs <checkout root> [--check]');
const check = opts.includes('--check');
const rel = 'sim/core/sim.gd';
const p = path.join(root, rel);
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
const a = '\t\tWorldEpoch.tick(S)   # the calm-moment turn: swap when decided, held (Encounter\'s DirCalm.hold, once it exists) and calm\n';
if (t.split(a).length !== 2) throw new Error(rel + ': WorldEpoch.tick anchor (World\'s window 3 first)');
t = t.replace(a, () => '\t\tWorldEpoch.tick(S, DirCalm.hold(S))   # the calm-moment turn: swap when decided, held (Encounter\'s DirCalm.hold) and calm\n');
if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log(rel + (check ? ': anchors ok' : ': WorldEpoch.tick takes DirCalm.hold'));
