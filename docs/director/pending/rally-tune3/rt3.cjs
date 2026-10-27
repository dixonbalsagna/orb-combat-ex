// rt3.cjs: Game Design's rulings-2026-10-26 §2j items 39 and 40, on the rally tune's second pass as landed (741c8483).
// Under rally.enabled (false on main), so the golden doesn't move. rally.linkWorth stays 0.8 (item 41).
//   39  the recoil flip "when he lands" comes only at the landing that would end his flight. A contact that carries the
//       flight on is not a landing: World tells a skip across water and a glance off a face as bounces, which never
//       opened it; a slam's hop (a spike's bounce off hard ground) is told as a land with the flight carried on in the
//       same tick, and no longer opens it.
//   40  the ki-wait as the rule: in its own rally the AI's link, drawn at its share, waits for the zip's price while
//       the body flies and starts the moment its ki allows (a draw made short of the price was dropped for good). A rally
//       that ends with the attacker short of the next link's ki ends "ki" (23d item 11), not "landed".
//   node rt3.cjs <checkout root> [--check]     (on a main with ../rally-tune2/)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node rt3.cjs <checkout root> [--check]');
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
if (!fs.readFileSync(path.join(root, 'sim/director/rally.gd'), 'utf8').includes('static func _landing')) throw new Error('../rally-tune2/ first');
edit('sim/director/rally.gd', rep => {
  // 40: the ends' line
  rep('##  - The ends (11): he lands and no link follows within endTicks (20); a teched link isn\'t turned within the\n',
      '##  - The ends (11): he lands and no link follows within endTicks (20), "ki" when the attacker is short of the next\n' +
      '##    link\'s price then (10-26 item 40), else "landed"; a teched link isn\'t turned within the\n');
  // 39
  rep('## 23d item 9: a rally\'s body lands (World\'s land contact this tick: a skid, a tumble or a slam), and his recoil flip\'s\n' +
      '## window opens as a knock-back skid\'s does (DirRecoil.landed). 10-26 item 37: the counter-rush after the flip lands on\n' +
      '## a committed chaser, as after the air tech.\n' +
      'static func _landing(S: SimState, A, D) -> void:\n' +
      '\tvar di: int = S.fighters.find(D)\n' +
      '\tfor e in S.out.fx:\n' +
      '\t\tif int(e.tick) == S.tick and String(e.type) == "land" and int(e.actor) == di:\n' +
      '\t\t\tDirRecoil.landed(S, A, D)\n\t\t\treturn\n',
      '## 23d item 9: a rally\'s body lands (World\'s land contact this tick: a skid, a tumble or a slam), and his recoil flip\'s\n' +
      '## window opens as a knock-back skid\'s does (DirRecoil.landed). 10-26 item 37: the counter-rush after the flip lands on\n' +
      '## a committed chaser, as after the air tech. 10-26 item 39: only at the landing that would end his flight. A contact\n' +
      '## that carries the flight on is a link, not a landing: a skip across water and a glance off a face are World\'s bounces\n' +
      '## (no land), and a slam\'s hop (a spike\'s bounce off hard ground) is a land his leaving the ground follows this tick.\n' +
      'static func _landing(S: SimState, A, D) -> void:\n' +
      '\tvar di: int = S.fighters.find(D)\n' +
      '\tvar down: bool = false\n' +
      '\tfor e in S.out.fx:\n' +
      '\t\tvar ty: String = String(e.type)\n' +
      '\t\tif (ty == "land" or ty == "left_ground") and int(e.tick) == S.tick and int(e.actor) == di:\n' +
      '\t\t\tdown = ty == "land"   # the tick\'s last contact decides: a land, or the flight carried on\n' +
      '\tif down:\n' +
      '\t\tDirRecoil.landed(S, A, D)\n');
  // 40
  rep('## 10-26 item 33: a link\'s blow deals rally.linkWorth of its damage',
      '## 10-26 item 40: the AI\'s link in its own rally, drawn at its share, waits for the zip\'s price while the body flies\n' +
      '## and starts the moment its ki allows (DirChase.steer), as a player presses. The rally ends when the attacker has no\n' +
      '## ki for the next link (23d item 11), not when the AI\'s one draw came too early.\n' +
      'static func waitsKi(S: SimState, A, D) -> bool:\n' +
      '\treturn on() and _owner(S, A, D)\n\n\n' +
      '## 10-26 item 33: a link\'s blow deals rally.linkWorth of its damage');
  rep('\t\t\tend(S, f, "landed")   # (10-26 item 37: not while his answer is under way)',
      '\t\t\tend(S, f, "ki" if f.ki < DirChase._price(false) else "landed")   # (10-26 item 37: not while his answer is under way; item 40: "ki" when he is short of the next link)');
});
edit('sim/director/chase.gd', rep => {
  rep('\t\tif f.ki >= _price(false) and SimRng.keyed(int(S.game.seed), "chase.ai", o.launchN * 4 + S.fighters.find(f)) < sh:\n',
      '\t\tif (f.ki >= _price(false) or DirRally.waitsKi(S, f, o)) and SimRng.keyed(int(S.game.seed), "chase.ai", o.launchN * 4 + S.fighters.find(f)) < sh:\n');
  rep('\t_s(f, CH_AT, 0)\n\tif f.ki < _price(false):\n\t\treturn false\n\t_begin(S, f, o, false)\n',
      '\tif f.ki < _price(false) and DirRally.waitsKi(S, f, o):\n\t\treturn false   # 10-26 item 40: in its own rally its drawn link waits for the ki while he flies\n' +
      '\t_s(f, CH_AT, 0)\n\tif f.ki < _price(false):\n\t\treturn false\n\t_begin(S, f, o, false)\n');
});
