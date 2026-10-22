// stw.cjs: the director counts a stop's ticks as Simulation's hitstop2 core freezes them (a stop of n ticks freezes n
// with hit-stop by weight on: SimFx.stopTicks(stop, whole)). After hitstop2 (docs/architecture/pending/hitstop2).
//  - windows.gd (4c, only with hit-stop by weight on): the freeze ahead and the held window's tick, whole.
//  - camintent.gd (the launch cue's touchdown after the stop): whole with the switch on, as before with it off.
// brawl.gd's double hit (ceil of the stop in ticks) already counts n, the whole count, and stays as it is (off, the core
// freezes n + 1 for n of 3 or more, as it always has: the golden). Off, nothing changes.
//   node stw.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node stw.cjs <checkout root> [--check]');
const check = opts.includes('--check');
if (!fs.readFileSync(path.join(root, 'sim/core/fx.gd'), 'utf8').includes('static func stopTicks(stop: float, whole: bool = false)')) throw new Error('Simulation\'s hitstop2 first (SimFx.stopTicks takes whole)');
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 90));
    t = t.replace(a, () => b);
  };
  fn(rep);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
edit('sim/director/windows.gd', rep => {
  rep('\tvar frozen: int = SimFx.stopTicks(S.dirS.stop)   # the freeze that starts with the next tick, counted as the step will\n',
      '\tvar frozen: int = SimFx.stopTicks(S.dirS.stop, true)   # the freeze that starts with the next tick, counted as the step will (whole: hitstop2)\n');
  rep('\t\te.n = S.tick + SimFx.stopTicks(S.dirS.stop) + int(round((b.t - ex.t) * DirData.TICKS_PER_SEC))\n',
      '\t\te.n = S.tick + SimFx.stopTicks(S.dirS.stop, true) + int(round((b.t - ex.t) * DirData.TICKS_PER_SEC))\n');
});
edit('sim/director/camintent.gd', rep => {
  rep('\tvar held: int = SimFx.stopTicks(S.dirS.stop)   # the stop still to run: the flight starts after it\n',
      '\tvar held: int = SimFx.stopTicks(S.dirS.stop, S.hitstopOn)   # the stop still to run: the flight starts after it (whole with hit-stop by weight on)\n');
});
