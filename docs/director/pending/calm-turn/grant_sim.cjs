// grant_sim.cjs: Simulation's lines for the calm-moment turn, for Simulation's OK (sim/core/sim.gd is Simulation's). After
// World's window 3 (e41118069cea: the sim warms the decided turn's rings in WorldEpoch.tick) and Encounter's ct.cjs:
//  - WorldEpoch.tick takes the director's hold (DirCalm.hold), so a decided turn swaps only on a calm moment, and never
//    while the director has something on.
//  - On a frozen tick (a pausing set piece's, or a hit-stop's) WorldEpoch.tick runs with no hold: it only warms (k more
//    columns of each ring), so the warm is k a SIM tick as World's design says, and a pausing form step's ring is read
//    under its pause (the form step's moment comes as the pause ends). Nothing runs with S.epoch null (the switches
//    off), so the golden doesn't move.
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
const rep = (a, b) => {
  const n = t.split(a).length - 1;
  if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 90));
  t = t.replace(a, () => b);
};
rep('\t\tWorldEpoch.tick(S)   # the calm-moment turn: swap when decided, held (Encounter\'s DirCalm.hold, once it exists) and calm\n',
    '\t\tWorldEpoch.tick(S, DirCalm.hold(S))   # the calm-moment turn: swap when decided, held (Encounter\'s DirCalm.hold) and calm\n');
rep('\tif SimPause.frozenTick(S):   # Q10: a pausing set piece is a run of frozen ticks, ahead of the hit-stop\n\t\tSimFx.tickMark(S, dt, true)\n\t\treturn false\n',
    '\tif SimPause.frozenTick(S):   # Q10: a pausing set piece is a run of frozen ticks, ahead of the hit-stop\n' +
    '\t\tif S.epoch != null:\n\t\t\tWorldEpoch.tick(S, false)   # the calm turn\'s warm runs under a pause too: no hold, so it only reads\n' +
    '\t\tSimFx.tickMark(S, dt, true)\n\t\treturn false\n');
rep('\t\tif S.hitstopOn:\n\t\t\tSimHitstop.frozen(S)   # the freeze budget counts every frozen tick of a hit-stop\n\t\tSimFx.tickMark(S, dt, true)\n\t\treturn false\n',
    '\t\tif S.hitstopOn:\n\t\t\tSimHitstop.frozen(S)   # the freeze budget counts every frozen tick of a hit-stop\n' +
    '\t\tif S.epoch != null:\n\t\t\tWorldEpoch.tick(S, false)   # ... and the calm turn\'s warm, as under a pause\n' +
    '\t\tSimFx.tickMark(S, dt, true)\n\t\treturn false\n');
if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log(rel + (check ? ': anchors ok' : ': WorldEpoch.tick takes DirCalm.hold, and warms on frozen ticks'));
