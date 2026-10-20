// grant_world.cjs: World's part of recoil flips, for World's OK (sim/world/contact.gd is World's). A flip cuts a
// knock-back's skid short: World ends the journey where he is, recording the slide so far (its trench, its wear) and
// saying so on journey_end (kind "recoil"), and he is free in the air of his flip. brakeEnd takes the kind; the air
// brake's call is unchanged.
//   node grant_world.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node grant_world.cjs <checkout root> [--check]');
const check = opts.includes('--check');
const rel = 'sim/world/contact.gd';
const p = path.join(root, rel);
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
const rep = (a, b) => {
  const n = t.split(a).length - 1;
  if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 90));
  t = t.replace(a, () => b);
};
if (t.includes('static func recoilEnd')) throw new Error(rel + ': recoilEnd exists already');
rep('static func brakeEnd(S: SimState, f) -> void:\n',
    'static func brakeEnd(S: SimState, f, kind: String = "brake") -> void:\n');
rep('\tje.kind = "brake"\n', '\tje.kind = kind\n');
rep('\tWorldBrunt.endFlight(S, f)\n\n\nstatic func _record(S: SimState, f, by) -> void:\n',
    '\tWorldBrunt.endFlight(S, f)\n\n\n' +
    '## A recoil flip (sim/director/recoil.gd; Game Design\'s rulings-2026-10-19.md 2a) cuts a knock-back\'s skid short:\n' +
    '## the slide so far is paid and recorded as a skid\'s end would be, and the journey ends where he is, as the brake\'s\n' +
    '## does (journey_end kind "recoil"). He is free, at rest: the director carries him through his flip.\n' +
    'static func recoilEnd(S: SimState, f) -> void:\n' +
    '\tvar by = f.launchBy\n' +
    '\tif by != null:\n' +
    '\t\tif f.slideAcc > 0.0:\n\t\t\t_pay(S, f, by, f.slideAcc)\n\t\t\tf.slideAcc = 0.0\n' +
    '\t\tif f.slideEvt != 0.0:\n\t\t\t_record(S, f, by)\n' +
    '\tf.vx = 0.0\n\tf.vy = 0.0\n' +
    '\tbrakeEnd(S, f, "recoil")\n\n\n' +
    'static func _record(S: SimState, f, by) -> void:\n');
if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log(rel + (check ? ': anchors ok' : ': recoilEnd, brakeEnd(kind)'));
