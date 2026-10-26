// rt.cjs: Game Design's rulings-2026-10-26 items 29 and 30, on the rally as landed (../rally/). Under rally.enabled
// (false on main), so the golden doesn't move.
//   29  the AI's link share in its own rally: easy 0.75, medium 0.9, hard 0.95 (the tech stays)
//   30  a surer counter-rush: after an air tech of a rally link, the defender's next blow inside his counter window
//       (DirRecoil.due), or the counter-rush he flew in with, is the counter-rush; it lands on the chaser through his
//       guard (a perfect block is still his answer), and the rally stays open while it is on its way (turnTicks from
//       his press), so landing it on the chaser in the air is the turn. The AI's counter share is the recoil flip's
//       (0.5, 0.7, 0.9), as it was. What counts as a turn is unchanged.
//   node rt.cjs <checkout root> [--check]     (on a main with ../rally/)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node rt.cjs <checkout root> [--check]');
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
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
if (!fs.existsSync(path.join(root, 'sim/director/rally.gd'))) throw new Error('../rally/ first');
edit('sim/director/rally.gd', rep => {
  rep('static func turn(S: SimState, ex, f, o, a) -> bool:\n\tif not on() or not _owner(S, o, f):\n\t\treturn false\n' +
      '\tvar cr: int = _g(f, RL_CRUSH) - 1\n\tif cr < 0 or _now(S) - cr > int(cfg().get("turnTicks", 60)):\n\t\treturn false\n',
      '## 10-26 item 30: f\'s blow on o is the counter-rush of o\'s rally: the one he flew in with (RL_CRUSH, within\n' +
      '## turnTicks of its press), or his next blow inside his counter window (DirRecoil.due: an air tech\'s, a wall kick\'s or\n' +
      '## a flip\'s). It lands on the chaser through his guard (DirBrawl.contact), a perfect block aside.\n' +
      'static func counterLive(S: SimState, f, o) -> bool:\n' +
      '\tif not on() or f == null or o == null or not _owner(S, o, f):\n\t\treturn false\n' +
      '\tvar cr: int = _g(f, RL_CRUSH) - 1\n' +
      '\tif cr >= 0 and _now(S) - cr <= int(cfg().get("turnTicks", 60)):\n\t\treturn true\n' +
      '\treturn DirRecoil.due(S, f)\n\n\n' +
      'static func turn(S: SimState, ex, f, o, a) -> bool:\n\tif not counterLive(S, f, o):\n\t\treturn false\n');
  rep('\t_s(f, RL_CRUSH, 0)\n\tDirBrawl._send(S, ex, f, o, 0, "the turn", 1.0)\n',
      '\t_s(f, RL_CRUSH, 0)\n\tif DirRecoil.due(S, f):\n\t\tDirRecoil.counter(S, f)   # his window\'s blow is the counter-rush: it spends the window, with its cue\n' +
      '\tDirBrawl._send(S, ex, f, o, 0, "the turn", 1.0)\n');
  rep('\t\tif tk >= 0:\n\t\t\tif now - tk > int(DirRecoil.cfg().get("counterTicks", 20)):\n\t\t\t\tend(S, f, "teched")\n\t\t\tcontinue\n',
      '\t\tif tk >= 0:\n\t\t\tif now - tk > int(DirRecoil.cfg().get("counterTicks", 20)) and not counterLive(S, D, f):\n\t\t\t\tend(S, f, "teched")   # (10-26 item 30: not while his counter-rush is on its way)\n\t\t\tcontinue\n');
});
edit('sim/director/brawl.gd', rep => {
  rep('\tif o.stance == 1.0 and (_g(o, LINE) != 0 or now < _g(o, OPEN_UNTIL) or o.stunTicks > 0):\n' +
      '\t\t# A fighter with a blow of his own on its way, open after a miss, or staggered is not guarding, whatever he holds.\n' +
      '\t\tif o == ex.A:\n\t\t\tex.sA = 0.0\n\t\telse:\n\t\t\tex.sD = 0.0\n',
      '\tif o.stance == 1.0 and (_g(o, LINE) != 0 or now < _g(o, OPEN_UNTIL) or o.stunTicks > 0 or DirRally.counterLive(S, f, o)):\n' +
      '\t\t# A fighter with a blow of his own on its way, open after a miss, or staggered is not guarding, whatever he holds;\n' +
      '\t\t# nor a rally\'s chaser against its counter-rush (10-26 item 30: he is committed to his arrival; a perfect block aside).\n' +
      '\t\tif o == ex.A:\n\t\t\tex.sA = 0.0\n\t\telse:\n\t\t\tex.sD = 0.0\n');
});
edit('data/director/ai.json', rep => {
  rep('"rally": {"link": 0.6, ', '"rally": {"link": 0.75, ');
  rep('"rally": {"link": 0.75, "sells": 2', '"rally": {"link": 0.9, "sells": 2');
  rep('"rally": {"link": 0.9, "sells": 2, "tech": 0.2', '"rally": {"link": 0.95, "sells": 2, "tech": 0.2');
});
