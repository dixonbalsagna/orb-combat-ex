// rt.cjs: Game Design's rulings-2026-10-26 items 29 and 30, on the rally as landed (../rally/). Under rally.enabled
// (false on main), so the golden doesn't move.
//   29  the AI's link share in its own rally: easy 0.75, medium 0.9, hard 0.95 (the tech stays)
//   30  a surer counter-rush: after an air tech of a rally link, the defender's next blow inside his counter window
//       (DirRecoil.due), or the counter-rush he flew in with, is the counter-rush; it lands on the chaser through his
//       guard (a perfect block is still his answer), and the rally stays open while it is on its way (turnTicks from
//       his press), so landing it on the chaser in the air is the turn. The AI's counter share is the recoil flip's
//       (0.5, 0.7, 0.9), as it was. What counts as a turn is unchanged.
//   32  on a neutral stick every link's send goes across or up, as the opening's does (22b): the planner's pick for a
//       link (the spike aside, the deliberate down link) leaves the down candidates out, and Plate Chase's line with no
//       stick, along his flight, is laid flat when his flight is going down. A held-down stick still wins.
//   Camera's grant (docs/camera/pending/rally/director-19-rally-grab-kind.patch, one line of render/camera/split_rig.gd):
//       a grab in flight arrives as `energy_grab`, so the rally's held shot size takes that kind too.
//   33  each link deals rally.linkWorth (0.8) of its blow's damage (the opening send and the sell unchanged): with 32 in,
//       the length's p10 still read under 300 (288.0 s)
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
  // 32: no neutral-stick down send for any link (the spike aside)
  rep('static func clearNoDown() -> void:\n\t_noDown = false\n',
      'static func clearNoDown() -> void:\n\t_noDown = false\n\n\n' +
      '## 10-26 item 32: set around the planner\'s pick for a link\'s send (DirChase._catch): on a neutral stick it goes across\n' +
      '## or up, as the opening\'s does; a held-down stick still wins, and the spike is the deliberate down link.\n' +
      'static func linkNoDown(tilt: int, kind: String) -> void:\n' +
      '\t_noDown = on() and tilt == 0 and kind != "spike"\n');
  rep('\telse:\n\t\tvar vl: float = maxf(SimDetMath.hypot(D.vx, D.vy), 0.001)\n\t\tux = D.vx / vl\n\t\tuy = D.vy / vl\n',
      '\telse:\n\t\tvar vl: float = maxf(SimDetMath.hypot(D.vx, D.vy), 0.001)\n\t\tux = D.vx / vl\n\t\tuy = D.vy / vl\n' +
      '\t\tif uy < -0.3:\n\t\t\tux = SimMathx.jsign(D.vx) if D.vx != 0.0 else float(A.face)\n\t\t\tuy = 0.0   # 10-26 item 32: on a neutral stick a link\'s send is never down (his flight laid flat)\n');
});
edit('sim/director/chase.gd', rep => {
  rep('\t\tr = DirLaunch.chooseLaunch(S, A, D, force, false, "", tilt, true)\n',
      '\t\tDirRally.linkNoDown(tilt, kind)   # 10-26 item 32: on a neutral stick no link\'s send is down (the spike aside)\n' +
      '\t\tr = DirLaunch.chooseLaunch(S, A, D, force, false, "", tilt, true)\n' +
      '\t\tDirRally.clearNoDown()\n');
});
// 33 (the length's p10 still under 300 with 32 in): each link deals linkWorth (0.8) of its blow's damage; the opening
// send and the sell are unchanged
edit('sim/director/rally.gd', rep => {
  rep('## The choreographer\'s variety for the planner\'s candidates in a rally',
      '## 10-26 item 33: a link\'s blow deals rally.linkWorth of its damage (the opening send and the sell are not links).\n' +
      'static func linkWorth(S: SimState, A, D) -> float:\n' +
      '\treturn float(cfg().get("linkWorth", 1.0)) if _owner(S, A, D) else 1.0\n\n\n' +
      '## The choreographer\'s variety for the planner\'s candidates in a rally');
});
edit('sim/director/chase.gd', rep => {
  rep('\tvar dmg: float = float(DirZip.cfg().get("heavy", {}).get("damage", 132.0)) if heavy else float(DirBrawl.cfg().get("light", {}).get("damage", 26.0))\n',
      '\tvar dmg: float = float(DirZip.cfg().get("heavy", {}).get("damage", 132.0)) if heavy else float(DirBrawl.cfg().get("light", {}).get("damage", 26.0))\n' +
      '\tdmg *= DirRally.linkWorth(S, A, D)   # 10-26 item 33: a link deals its share of the blow\n');
});
edit('data/director/interrupts.json', rep => {
  rep('    "queueTicks": 12,\n', '    "queueTicks": 12,\n    "linkWorth": 0.8,\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const r = s.properties.rally;
  if (!r || !r.properties) throw new Error('director-interrupts schema: no rally');
  if (r.properties.linkWorth) throw new Error('director-interrupts schema: rally.linkWorth exists already');
  r.properties.linkWorth = { type: 'number', minimum: 0, maximum: 1, description: 'Game Design 10-26 item 33: the share of its blow\'s damage a rally link deals (the opening send and the sell are not links).' };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: rally.linkWorth' + (check ? ' (checked)' : ''));
}
// Camera's one-line grant (docs/camera/pending/rally/director-19-rally-grab-kind.patch): a grab in flight is `energy_grab`
edit('render/camera/split_rig.gd', rep => {
  rep('\tif _rally_kind == "grab":\n', '\tif _rally_kind == "grab" or _rally_kind == "energy_grab":\n');
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
