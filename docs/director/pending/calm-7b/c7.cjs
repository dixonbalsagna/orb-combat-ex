// c7.cjs: a landing's calm moment starts at the end of his journey (Game Design's rulings-2026-10-22.md 7b): the window is
// landedTicks (45) live ticks from the tick he came to rest (down: the slide's end, journey_end), with both set and nothing
// in flight. It was the fighter's state clock, which the journey's end starts part way after a slide, and a returning
// fighter's. On main's calm turn (a06f6920), after 7a (pr2.cjs: DirCalm's slots follow DirPress's). The record is written
// only while the calm turn is on (calmTurn.enabled and World's turn), so the golden doesn't move.
//   node c7.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node c7.cjs <checkout root> [--check]');
const check = opts.includes('--check');
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
if (!check && !fs.existsSync(path.join(root, 'sim/director/press.gd'))) throw new Error('7a (pr2.cjs) first: DirCalm\'s slots follow DirPress\'s');
edit('sim/director/calm.gd', rep => {
  rep('## Stateless: it reads the match and World\'s epoch, and writes only through World\'s ask, choose and cancel.\n',
      '## State: two f.act.dirI slots after DirPress\'s (the tick each came to rest, Game Design\'s 7b), written only while the\n' +
      '## calm turn is on; otherwise it reads the match and World\'s epoch, and writes only through World\'s ask, choose and cancel.\n');
  rep('static func on(S: SimState) -> bool:\n\treturn bool(cfg().get("enabled", false)) and S.epoch != null\n',
      'static func on(S: SimState) -> bool:\n\treturn bool(cfg().get("enabled", false)) and S.epoch != null\n\n\n' +
      'const CM_WAS: int = 0    # his state at the director\'s last tick: 0 other, 1 launched, 2 down\n' +
      'const CM_REST: int = 1   # the live tick he came to rest (his journey\'s end: down after the slide, or out of a flight\n' +
      '                         # into the water), plus 1; 0 none\n' +
      'const CM_N: int = 2\n\n\n' +
      'static func _base() -> int:\n\treturn DirPress._base() + DirPress.PR_N\n\n\n' +
      'static func _g(f, k: int) -> int:\n\tvar i: int = _base() + k\n\treturn f.act.dirI[i] if i < f.act.dirI.size() else 0\n\n\n' +
      'static func _s(f, k: int, v: int) -> void:\n\tDirGrapple._size(f)\n\tif f.act.dirI.size() < _base() + CM_N:\n\t\tf.act.dirI.resize(_base() + CM_N)\n\tf.act.dirI[_base() + k] = v\n\n\n' +
      '## Once a live tick (DirExchange.dirUpdate), while the calm turn is on: the tick each fighter comes to rest (Game Design\'s\n' +
      '## 7b: a landing\'s moment starts at the end of his journey, the slide\'s end, not at his first contact).\n' +
      'static func tick(S: SimState) -> void:\n' +
      '\tif not on(S):\n\t\treturn\n' +
      '\tfor f in S.fighters:\n' +
      '\t\tvar d: int = 2 if f.state == "down" else (1 if f.state == "launched" else 0)\n' +
      '\t\tvar was: int = _g(f, CM_WAS)\n' +
      '\t\tif (d == 2 and was != 2) or (was == 1 and d == 0):\n\t\t\t_s(f, CM_REST, DirBrawl._now(S) + 1)   # down, or out of his flight (a water landing counts)\n' +
      '\t\tif d != was:\n\t\t\t_s(f, CM_WAS, d)\n');
  rep('\tvar settle: float = float(c.get("landedTicks", 45)) * SimConst.DT\n',
      '\tvar settle: int = int(c.get("landedTicks", 45))\n\tvar now: int = DirBrawl._now(S)\n');
  rep('\t\tif f.stateT <= settle and (down or DirBrawl.returning(S, f)):\n\t\t\tlanded = true   # he came to rest from a send within the settle\n',
      '\t\tif _g(f, CM_REST) > 0 and now - (_g(f, CM_REST) - 1) <= settle:\n\t\t\tlanded = true   # he came to rest (his journey\'s end) within landedTicks live ticks (7b)\n');
});
edit('sim/director/exchange.gd', rep => {
  rep('\tDirWindows.afterTick(S)   # 4c: a freeze that starts now leaves every open window its live ticks (hit-stop by weight only)\n',
      '\tDirWindows.afterTick(S)   # 4c: a freeze that starts now leaves every open window its live ticks (hit-stop by weight only)\n' +
      '\tDirCalm.tick(S)   # 7b: the calm turn notes when each fighter came to rest\n');
});
