// grant_world.cjs: World's two lines for the director's calm turn, for World's OK (sim/world/epoch.gd, window 3, is
// World's). choose() records the pick's tick (DirCalm holds the swap for the host's warm read from it); cancel(S) drops a
// pending pick whose pair has moved off its pivot, so the director can ask again. Neither is hashed (the epoch hashes n,
// lastT and drift only), and nothing calls them with the switches off.
//   node grant_world.cjs <checkout root> [--check]   (after World's window 3)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node grant_world.cjs <checkout root> [--check]');
const check = opts.includes('--check');
const rel = 'sim/world/epoch.gd';
const p = path.join(root, rel);
if (!fs.existsSync(p)) throw new Error('World\'s window 3 first (sim/world/epoch.gd)');
let t = fs.readFileSync(p, 'utf8');
const crlf = t.includes('\r\n');
if (crlf) t = t.replace(/\r\n/g, '\n');
const rep = (a, b) => {
  const n = t.split(a).length - 1;
  if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 90));
  t = t.replace(a, () => b);
};
if (t.includes('static func cancel(')) throw new Error(rel + ': cancel exists already');
rep('\tE.next = {"spec": c.spec, "pc": E.ask.pc, "bearing": c.bearing, "drift": c.drift, "why": E.ask.why}\n\tE.ask = null\n\t_jobs.erase(S.worldId)\n',
    '\tE.next = {"spec": c.spec, "pc": E.ask.pc, "bearing": c.bearing, "drift": c.drift, "why": E.ask.why, "tick": S.tick, "due": E.ask.due}   # tick: the pick\'s; due: the moment it is for (the director paces the warm read by them)\n\tE.ask = null\n\t_jobs.erase(S.worldId)\n\n\n' +
    '## Encounter\'s cancel (DirCalm): a pending pick whose pair has moved off its pivot is dropped, so the director can ask again.\n' +
    'static func cancel(S: SimState) -> void:\n' +
    '\tvar E = S.epoch\n' +
    '\tif E == null:\n\t\treturn\n' +
    '\tE.next = null\n' +
    '\tE.ask = null\n' +
    '\t_jobs.erase(S.worldId)\n');
if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
console.log(rel + (check ? ': anchors ok' : ': the pick\'s tick, and cancel'));
