// rt2.cjs: Game Design's rulings-2026-10-26 §2j items 35 and 37, on the rally tune as landed (22b76cb4). Under
// rally.enabled (false on main), so the golden doesn't move.
//   35  rally.linkWorth back to 1.0 (item 33 withdrawn; the key stays)
//   37  step 2: the counter-rush is as sure after the other two answers as after the air tech. The recoil flip when a
//       rally's body lands (23d item 9: a dodge tap in its first windowTicks; not built until now) opens, as a
//       knock-back skid's does; the wall kick's rush blow is the counter-rush too (it marks the turn, and lands on a
//       committed chaser through his guard, a perfect block aside); and the rally stays open while his answer is under
//       way (his flip in the air, his kick's push, his counter-rush). Step 3: the defending AI's counter-rush share in a
//       rally is its level's rally.counter (0.7, 0.85, 0.95), after any of the three answers.
//   node rt2.cjs <checkout root> [--check]     (on a main with ../rally-tune/)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node rt2.cjs <checkout root> [--check]');
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
if (!fs.readFileSync(path.join(root, 'sim/director/rally.gd'), 'utf8').includes('static func linkWorth')) throw new Error('../rally-tune/ first');
// 35
edit('data/director/interrupts.json', rep => {
  rep('    "linkWorth": 0.8,\n', '    "linkWorth": 1.0,\n');
});
// 37
edit('sim/director/rally.gd', rep => {
  rep('\tif cr >= 0 and _now(S) - cr <= int(cfg().get("turnTicks", 60)):\n\t\treturn true\n\treturn DirRecoil.due(S, f)\n',
      '\tif cr >= 0 and _now(S) - cr <= int(cfg().get("turnTicks", 60)):\n\t\treturn true\n' +
      '\treturn DirRecoil.due(S, f) or DirWallKick.due(S, f)   # (10-26 item 37: his wall kick\'s rush blow too)\n');
  rep('\tif DirRecoil.due(S, f):\n\t\tDirRecoil.counter(S, f)   # his window\'s blow is the counter-rush: it spends the window, with its cue\n',
      '\tif DirRecoil.due(S, f):\n\t\tDirRecoil.counter(S, f)   # his window\'s blow is the counter-rush: it spends the window, with its cue\n' +
      '\telif DirWallKick.due(S, f):\n\t\tDirWallKick.rushBlow(S, f)   # 10-26 item 37: his kick\'s rush blow is the counter-rush, as a flip\'s\n');
  rep('## His counter-rush was spent (DirRecoil.counter): the turn may follow when it lands.\n',
      '## 10-26 item 37: D\'s answer to f\'s rally is under way: his recoil flip in the air, his wall kick\'s push, or his\n' +
      '## counter-rush (counterLive). The rally stays open while it is.\n' +
      'static func answering(S: SimState, D, f) -> bool:\n' +
      '\treturn DirRecoil.flipping(S, D) or DirWallKick.pushing(S, D) or counterLive(S, D, f)\n\n\n' +
      '## 10-26 item 37(3): the defending AI\'s counter-rush share after an answer in a rally of the other\'s (its level\'s\n' +
      '## rally.counter), in place of the recoil flip\'s (brawl.recoil.counter). dflt outside a rally.\n' +
      'static func counterShare(S: SimState, f, dflt: float) -> float:\n' +
      '\tif not on() or f == null or not _owner(S, SimRoster.opp(S, f), f):\n\t\treturn dflt\n' +
      '\treturn float(_ai().get("counter", dflt))\n\n\n' +
      '## 23d item 9: a rally\'s body lands (World\'s land contact this tick: a skid, a tumble or a slam), and his recoil flip\'s\n' +
      '## window opens as a knock-back skid\'s does (DirRecoil.landed). 10-26 item 37: the counter-rush after the flip lands on\n' +
      '## a committed chaser, as after the air tech.\n' +
      'static func _landing(S: SimState, A, D) -> void:\n' +
      '\tvar di: int = S.fighters.find(D)\n' +
      '\tfor e in S.out.fx:\n' +
      '\t\tif int(e.tick) == S.tick and String(e.type) == "land" and int(e.actor) == di:\n' +
      '\t\t\tDirRecoil.landed(S, A, D)\n\t\t\treturn\n\n\n' +
      '## His counter-rush was spent (DirRecoil.counter): the turn may follow when it lands.\n');
  rep('\t\t\t_worldContacts(S, f, D)\n\t\t\t_s(f, RL_LAND, 0)\n',
      '\t\t\t_worldContacts(S, f, D)\n\t\t\t_landing(S, f, D)   # 23d item 9: his landing opens his recoil flip\'s window (10-26 item 37)\n\t\t\t_s(f, RL_LAND, 0)\n');
  rep('\t\telif now - ld > int(c.get("endTicks", 20)) and not DirChase.chasing(f):\n\t\t\tend(S, f, "landed")',
      '\t\telif now - ld > int(c.get("endTicks", 20)) and not DirChase.chasing(f) and not answering(S, D, f):\n\t\t\tend(S, f, "landed")   # (10-26 item 37: not while his answer is under way)');
});
edit('sim/director/recoil.gd', rep => {
  rep('S.tick * 4 + S.fighters.find(f)) < float(_ai().get("counter", 0.0)):\n',
      'S.tick * 4 + S.fighters.find(f)) < DirRally.counterShare(S, f, float(_ai().get("counter", 0.0))):   # (in a rally its rally.counter: 10-26 item 37)\n');
  rep('## He lands set: his counter-rush window opens, and the AI draws its press.\n',
      '## 23d item 9 (DirRally._landing): a rally\'s body lands, and his window opens as a knock-back skid\'s does (kind 1: a\n' +
      '## dodge tap in its first windowTicks flips him out of the journey), once a journey, with no flourish.\n' +
      'static func landed(S: SimState, att, tgt) -> void:\n' +
      '\tif not on() or (_g(tgt, RC_KIND) == 1 and _g(tgt, RC_LN) == tgt.launchN):\n\t\treturn\n' +
      '\tknocked(S, att, tgt, 0.0, 1, S.tick)\n\n\n' +
      '## He lands set: his counter-rush window opens, and the AI draws its press.\n');
});
edit('sim/director/wallkick.gd', rep => {
  rep('< float(DirRecoil._ai().get("counter", 0.0)):\n',
      '< DirRally.counterShare(S, f, float(DirRecoil._ai().get("counter", 0.0))):   # (in a rally its rally.counter: 10-26 item 37)\n');
  rep('\t_s(f, WK_CR, 0)\n\t_s(f, WK_AIC, 0)\n\tSimFx.cue(S, f, "counter_rush", "wall_kick", "")\n',
      '\t_s(f, WK_CR, 0)\n\t_s(f, WK_AIC, 0)\n\tDirRally.markCounter(S, f)   # 10-26 item 37: the turn, if it lands on the chaser in the air (as a flip\'s)\n' +
      '\tSimFx.cue(S, f, "counter_rush", "wall_kick", "")\n');
});
edit('data/director/ai.json', rep => {
  rep('"rally": {"link": 0.75, "sells": 0, ', '"rally": {"link": 0.75, "counter": 0.7, "sells": 0, ');
  rep('"rally": {"link": 0.9, "sells": 2, ', '"rally": {"link": 0.9, "counter": 0.85, "sells": 2, ');
  rep('"rally": {"link": 0.95, "sells": 2, ', '"rally": {"link": 0.95, "counter": 0.95, "sells": 2, ');
});
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  let n = 0;
  const walk = (o) => {
    if (!o || typeof o !== 'object') return;
    if (o.rally && o.rally.properties && o.rally.properties.link && o.rally.properties.airBurst) {
      if (o.rally.properties.counter) throw new Error('director-ai schema: rally.counter exists already');
      o.rally.properties.counter = { type: 'number', minimum: 0, maximum: 1, description: 'Game Design 10-26 item 37: the defending AI\'s counter-rush share after its answer (an air tech, a recoil flip, a wall kick) in a rally of the other\'s, in place of brawl.recoil.counter.' };
      n++;
    }
    for (const k of Object.keys(o)) walk(o[k]);
  };
  walk(s);
  if (n !== 3) throw new Error('director-ai schema: expected 3 rally blocks, got ' + n);
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: rally.counter x' + n + (check ? ' (checked)' : ''));
}
