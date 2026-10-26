// rl.cjs: the daze, the sell and the rally (Game Design's rulings-2026-10-23d, Orb's answer to the early B), behind
// data/director/interrupts.json rally.enabled (false), so the golden doesn't move. A new DirRally (sim/director/rally.gd)
// and its hooks in the director's own files. Apply after ../launch-spike/ and ../water-surface/ (DirRally's slots follow
// DirWater's; the dazed B is read before the pop and the spike).
//   node rl.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node rl.cjs <checkout root> [--check]');
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
if (!fs.existsSync(path.join(root, 'sim/director/water.gd'))) throw new Error('../water-surface/ first (DirRally\'s slots follow DirWater\'s)');
if (!fs.readFileSync(path.join(root, 'sim/director/brawl.gd'), 'utf8').includes('static func _spike(')) throw new Error('../launch-spike/ first');
if (fs.existsSync(path.join(root, 'sim/director/rally.gd'))) throw new Error('sim/director/rally.gd exists already');
for (const f of ['rally.gd', 'rally.gd.uid']) {
  const from = path.join(__dirname, 'files/sim/director', f);
  if (!fs.existsSync(from)) { if (f.endsWith('.uid')) continue; throw new Error('missing ' + from); }
  if (!check) fs.copyFileSync(from, path.join(root, 'sim/director', f));
  console.log('sim/director/' + f + (check ? ': present' : ': copied'));
}
const ON = '\treturn DirInterrupt.on() and bool(cfg().get("enabled", false))\n';
const ON_R = '\treturn DirInterrupt.on() and (bool(cfg().get("enabled", false)) or DirRally.on())   # (on with the rally: 23d)\n';
edit('sim/director/brawl.gd', rep => {
  rep('static func _send(S: SimState, ex, f, o, aim: int, why: String, mul: float) -> void:',
      'static func _send(S: SimState, ex, f, o, aim: int, why: String, mul: float, extra: Dictionary = {}) -> void:');
  rep('\tvar la: Dictionary = {"forced": true, "tilt": tilt, "why": why}\n',
      '\tvar la: Dictionary = {"forced": true, "tilt": tilt, "why": why}\n\tla.merge(extra, true)   # (23d: the sell\'s send is sold and decisive)\n');
  rep('\t\t\tvar pp: float = _popPower(S, f, o, int(a.get("aim", 0))) if (popOn() and a.has("power")) else 9.0\n',
      '\t\t\tif DirRally.dazed(S, o):\n' +
      '\t\t\t\tif a.has("power"):\n\t\t\t\t\t_ls(f, LA_POW, 1000)   # 23d 5: B at a dazed fighter is the sure launcher at full power, whatever the string\n' +
      '\t\t\t\t_send(S, ex, f, o, int(a.get("aim", 0)), "the sell\'s send", float(c.launcher.flightMul), {"sold": true, "decisive": true})\n' +
      '\t\t\t\tif a.has("power"):\n\t\t\t\t\t_ls(f, LA_POW, 0)\n' +
      '\t\t\t\treturn\n' +
      '\t\t\tvar pp: float = _popPower(S, f, o, int(a.get("aim", 0))) if (popOn() and a.has("power")) else 9.0\n');
  rep('var lau: bool = st == 2 and not paid and (lcOpen or (any and _linked(S, f, p)))',
      'var lau: bool = st == 2 and not paid and (lcOpen or DirRally.dazed(S, o) or (any and _linked(S, f, p)))');
  rep('\t\t\t_stagger(S, ex, f, o, int(c.heavy.staggerTicks), "", true)   # a broken guard is an opening\n',
      '\t\t\tif not (DirRally.breakDazes(a) and DirRally.daze(S, ex, f, o, "guard_break")):   # 10-26 items 23, 24: only a charged blow or a tapped heavy outside a string dazes\n\t\t\t\t_stagger(S, ex, f, o, int(c.heavy.staggerTicks), "", true)   # a broken guard is an opening (23d 1: with the rally on, a daze)\n');
  rep('\t\t\t_send(S, ex, f, o, int(a.get("aim", 0)), "a heavy charged to full", 1.0)\n',
      '\t\t\tif not DirRally.daze(S, ex, f, o, "charged_heavy"):   # 23d 1: with the rally on, a clean full charge dazes\n\t\t\t\t_send(S, ex, f, o, int(a.get("aim", 0)), "a heavy charged to full", 1.0)\n');
  rep('\t\t_s(f, OPEN_UNTIL, _now(S) + open)\n',
      '\t\t_s(f, OPEN_UNTIL, _now(S) + open)\n\t\tif kind == BIG:\n\t\t\tDirRally.whiffed(S, f, open)   # 23d 1: a heavy\'s whiff, punished in it, dazes him\n');
  rep('\tif kind == BIG:\n\t\t_bigLanded(S, ex, f, o, a)\n\t\treturn\n',
      '\tif DirRally.whiffPunish(S, ex, f, o, a):\n\t\treturn   # 23d 1: his heavy\'s whiff, punished: a daze in place of the reel\n' +
      '\tif kind == BIG:\n\t\t_bigLanded(S, ex, f, o, a)\n\t\treturn\n');
  rep('\t# The launcher: a tap of B while the stagger it caused holds the window open, at its level\'s share.\n\tif anywhere() and _aiLaunchInString(S, f, c):\n',
      '\tif DirRally.aiSell(S, ex, f, o, i, bl):\n\t\treturn   # 10-26 item 10: at a dazed rival it sells its mediums before B\n' +
      '\t# The launcher: a tap of B while the stagger it caused holds the window open, at its level\'s share.\n\tif anywhere() and _aiLaunchInString(S, f, c):\n');
  rep('\t_s(f, STRING_N, _g(f, STRING_N) + 1)\n\tif anywhere():\n\t\t_ls(f, LA_LINK, S.tick)',
      '\tif DirRally.turn(S, ex, f, o, a):\n\t\treturn   # 23d 10: his counter-rush lands on the chaser in the air: a full send, and the rally is his\n' +
      '\t_s(f, STRING_N, _g(f, STRING_N) + 1)\n\tif anywhere():\n\t\t_ls(f, LA_LINK, S.tick)');
  rep('\t\tDirMelee.weigh(S, a.o, DirMash.name(S, f, weightOf(a)))',
      '\t\tDirMelee.weigh(S, a.o, DirRally.sellWeight(S, f, o, a, DirMash.name(S, f, weightOf(a))))');
  rep('\to["turned"] = true\n\ta.stunTicks = maxi(a.stunTicks, n)\n',
      '\to["turned"] = true\n\tif not (DirRally.pbDazes(a) and DirRally.daze(S, ex, d, a, "perfect_block")):   # 23d 1 (10-26 items 23, 25): a perfect block that turns a charged blow or an ender dazes the one it turned; a launcher keeps its reversal\n\t\ta.stunTicks = maxi(a.stunTicks, n)\n');
});
edit('sim/director/interrupt.gd', rep => {
  rep('if f.ki < float(c.ki) or f.act.burstCool > 0 or f.state == "launched" or (f.state == "down" and not DirBury.canBurst(f)):',
      'if f.ki < float(c.ki) or f.act.burstCool > 0 or (f.state == "launched" and not DirRally.burstInFlight(S, f)) or DirRally.burstHeld(S, f) or (f.state == "down" and not DirBury.canBurst(f)):');
  rep('\tDirBury.burstOut(S, f)   # a buried fighter\'s burst throws him out of his crater\n',
      '\tDirBury.burstOut(S, f)   # a buried fighter\'s burst throws him out of his crater\n\tDirRally.burstOut(S, f)   # 23d: it breaks his daze, and ends a rally\'s flight\n');
});
edit('sim/director/recoil.gd', rep => {
  rep(ON, ON_R);
  rep('\t_s(f, RC_CR, 0)\n\t_s(f, RC_AIC, 0)\n\tvar e = _ev(S, f, "counter_rush")\n',
      '\t_s(f, RC_CR, 0)\n\t_s(f, RC_AIC, 0)\n\tDirRally.markCounter(S, f)   # 23d 10: the turn, if it lands on the chaser in the air\n\tvar e = _ev(S, f, "counter_rush")\n');
});
edit('sim/director/wallkick.gd', rep => {
  rep(ON, ON_R);
  rep('static func atWall(S: SimState, f, b, edge: float, dir: float, spN: float) -> bool:\n\tif not on() or _g(f, WK_ARM) != f.launchN + 1:\n\t\treturn false\n',
      'static func atWall(S: SimState, f, b, edge: float, dir: float, spN: float) -> bool:\n' +
      '\tvar k: bool = _atWall(S, f, b, edge, dir, spN)\n' +
      '\tDirRally.worldLink(S, f, "face")   # 10-26 item 22(a): a face met in a rally\'s flight is a world link\n' +
      '\tif not k:\n\t\tDirRally.slammed(S, f)   # 23d 1: a wall slam dazes him once he is up (with the rally on)\n' +
      '\treturn k\n\n\n' +
      'static func _atWall(S: SimState, f, b, edge: float, dir: float, spN: float) -> bool:\n\tif not on() or _g(f, WK_ARM) != f.launchN + 1:\n\t\treturn false\n');
});
edit('sim/director/chase.gd', rep => {
  rep(ON, ON_R);
  rep('\t\tif A.state != "free" or S.game.ko != null or S.dirS.ex != null or DirBrawl._now(S) - (_g(A, CH_ON) - 1) > int(c.get("maxTicks", 120)):\n',
      '\t\tif A.state != "free" or S.game.ko != null or S.dirS.ex != null or (DirBrawl._now(S) - (_g(A, CH_ON) - 1) > int(c.get("maxTicks", 120)) and not DirRally._owner(S, A, D)):\n');
  rep('\t\tif tl > 0 and tl < n:\n\t\t\tr.off = DirBands._endOff(',
      '\t\tif tl > 0 and tl < n and DirRally._owner(S, A, D):\n\t\t\tn = maxi(1, tl - 1)   # 10-26 item 22(e): a rally\'s chase always arrives, at him before his landing\n\t\t\tr.off = 0.0\n\t\telif tl > 0 and tl < n:\n\t\t\tr.off = DirBands._endOff(');
  rep('\tif not on() or A.ai != null or kind == "sig":\n\t\treturn false\n',
      '\tif not on() or A.ai != null:\n\t\treturn false\n\tif kind == "sig":\n\t\treturn _spikePress(S, A)   # 23d 6: B from above him in a rally is the spike\n');
  rep('static func _begin(S: SimState, A, D, heavy: bool) -> void:\n\tA.ki -= _price(heavy)\n\t_s(A, CH_ON, DirBrawl._now(S) + 1)\n\t_s(A, CH_W, 2 if heavy else 1)\n',
      'static func _begin(S: SimState, A, D, heavy: bool, spike: bool = false) -> void:\n\tif not spike:\n\t\tA.ki -= _price(heavy)   # (the rally\'s spike is a B: no zip price)\n\t_s(A, CH_ON, DirBrawl._now(S) + 1)\n\t_s(A, CH_W, 3 if spike else (2 if heavy else 1))\n\tDirRally.commitStick(S, A, D)   # the stick\'s class, read once at the commit (Controls\' rule)\n');
  rep('## The AI (DirAI.aiInput, before the approach cap):',
      '## A player\'s B (kind "sig"): in a rally of his, with his rival in flight and him above, the spike link (23d 6): a\n' +
      '## chase whose catch slams him straight down. Pressed during a chase, it makes that chase\'s catch the spike. False\n' +
      '## otherwise: B is what it always was.\n' +
      'static func _spikePress(S: SimState, A) -> bool:\n' +
      '\tif not DirRally.on() or not DirBrawl.isB(A, "sig"):\n\t\treturn false\n' +
      '\tvar D = SimRoster.opp(S, A)\n' +
      '\tif not DirRally._owner(S, A, D) or D.state != "launched" or D.launchBy != A:\n\t\treturn false\n' +
      '\tif chasing(A):\n\t\t_s(A, CH_W, 3)\n\t\tDirBrawl._ev(S, A, "press_ack", "spike", "b").n = S.tick\n\t\treturn true\n' +
      '\tif A.state != "free" or A.stunTicks > 0 or S.dirS.ex != null or S.game.ko != null or A.y <= D.y + float(DirRally.cfg().get("spikeAboveBh", 0.5)) * DirInterrupt.BH:\n\t\treturn false\n' +
      '\t_begin(S, A, D, false, true)\n\treturn true\n\n\n' +
      '## A link press that waited for his first free tick (DirRally.queues; 10-26 item 7): its chase starts now. k: 1 X,\n' +
      '## 2 Y, 3 B.\n' +
      'static func startQueued(S: SimState, A, D, k: int) -> void:\n' +
      '\tif k == 3:\n\t\t_spikePress(S, A)\n\t\treturn\n' +
      '\tif chasing(A) or D.state != "launched" or D.launchBy != A or D.launchSpecial:\n\t\treturn\n' +
      '\tvar heavy: bool = k == 2\n' +
      '\tif A.ki < _price(heavy):\n\t\tDirBrawl._ev(S, A, "press_ack", "chase_no_ki", DirBrawl._cell("heavy" if heavy else "light")).n = S.tick\n\t\treturn\n' +
      '\t_begin(S, A, D, heavy)\n\n\n' +
      '## The AI (DirAI.aiInput, before the approach cap):');
  rep('\t\t\t_s(f, CH_AT, S.tick + int(DirAI.skill().get("reactTicks", 14)) + 1)\n',
      '\t\t\tvar rt: int = int(DirAI.skill().get("reactTicks", 14))\n' +
      '\t\t\tif DirRally._owner(S, f, o):\n\t\t\t\trt = maxi(0, rt - DirRally.sinceSend(S, f))   # 10-26 item 7: in a rally its reaction runs from the send, not from when it was free\n' +
      '\t\t\t_s(f, CH_AT, S.tick + rt + 1)\n');
  rep('\t\tif _sky(S, o):\n\t\t\tsh *= float(cfg().get("skyMul", 1.0))\n',
      '\t\tif _sky(S, o):\n\t\t\tsh *= float(cfg().get("skyMul", 1.0))\n' +
      '\t\tif DirRally._owner(S, f, o):\n\t\t\tsh = float(DirRally._ai().get("link", sh))   # 23d: in a rally of its own, its level\'s link share\n');
  rep('static func _catch(S: SimState, A, D) -> void:\n\tvar c: Dictionary = cfg()\n\tvar heavy: bool = _g(A, CH_W) == 2\n',
      'static func _catch(S: SimState, A, D) -> void:\n\tvar c: Dictionary = cfg()\n' +
      '\tvar kind: String = DirRally.linkKind(S, A, D, _g(A, CH_W) == 3, _g(A, CH_W) == 2) if DirRally.on() else "chase"   # 23d 6, 17 to 19: the link\'s kind\n' +
      '\tif DirRally.on() and DirRally.teched(S, A, D, kind):\n\t\tA.rush = null\n\t\t_end(S, A, D, "teched")\n\t\treturn   # 23d 8: he teched its arrival\n' +
      '\tvar heavy: bool = _g(A, CH_W) == 2 or kind == "spike"\n');
  rep('\tvar r: Dictionary = DirLaunch.chooseLaunch(S, A, D, force, false, "", _tilt(A), true)\n',
      '\tvar tilt: int = _tilt(A)\n' +
      '\tif kind == "spike":\n\t\ttilt = 5   # straight down\n' +
      '\telif kind == "palm_turn":\n\t\ttilt = DirRally.palmTilt(A)   # the Protagonist\'s open palm turns him across his flight (23d item 21)\n' +
      '\telif kind == "overtake":\n' +
      '\t\ttilt = 7 if D.vx > 0.0 else 3   # back the way he came: the zip passes him and meets him head-on\n' +
      '\t\tA.x = SimWrap.wrap(D.x + SimMathx.jsign(D.vx) * float(c.get("catchBh", 1.5)) * DirInterrupt.BH)\n' +
      '\t\tA.face = -SimMathx.jsign(D.vx)\n' +
      '\tvar r: Dictionary\n' +
      '\tif kind == "plate_chase":\n\t\tvar pl: Dictionary = DirRally.plateLine(S, A, D)   # the Rival\'s exact line, with no bend (23d item 19)\n\t\tr = {"best": pl, "top": [pl], "all": [pl]}\n' +
      '\telse:\n\t\tr = DirLaunch.chooseLaunch(S, A, D, force, false, "", tilt, true)\n');
  rep('\t\tDirBrawl.markKind(S, D, lkind)\n\t_end(S, A, D, "catch")\n',
      '\t\tDirBrawl.markKind(S, D, lkind)\n\t\tDirRally.onLink(S, A, D, kind, r.best)   # 23d 6: a rally\'s link\n\t_end(S, A, D, "catch")\n');
});
edit('sim/director/launch.gd', rep => {
  rep('\t\tif k.name == S.dirS.lastLaunch2:\n\t\t\tk.s -= REPEAT_2\n',
      '\t\tif k.name == S.dirS.lastLaunch2:\n\t\t\tk.s -= REPEAT_2\n\t\tk.s += DirRally.variety(S, A, k)   # 23d 13: a rally\'s variety (0 outside one)\n');
});
edit('sim/director/melee.gd', rep => {
  rep('\tvar r: Dictionary = DirLaunch.chooseLaunch(S, att, tgt, force, longOnly, String(args.get("sends", "")) if args != null else "", tilt, forced or (gate.get("enabled", false) and not DirData.contact().is_empty()), lpow >= 0.0)\n',
      '\tDirRally.openNoDown(S, att, tgt, lpow, longOnly, tilt)   # 10-26 item 22(b): a rally\'s opening send is never down on a neutral stick\n' +
      '\tvar r: Dictionary = DirLaunch.chooseLaunch(S, att, tgt, force, longOnly, String(args.get("sends", "")) if args != null else "", tilt, forced or (gate.get("enabled", false) and not DirData.contact().is_empty()), lpow >= 0.0)\n' +
      '\tDirRally.clearNoDown()\n');
  rep('\t\tDirBrawl.paySend(tgt, lpow * kf)   # 9a: a launcher\'s send pays on its journey (after the send: its launch number)\n',
      '\t\tDirBrawl.paySend(tgt, lpow * kf)   # 9a: a launcher\'s send pays on its journey (after the send: its launch number)\n\tDirRally.onSend(S, att, tgt, (lpow * kf) if lpow >= 0.0 else -1.0, args, r.best)   # 23d 6: a full send opens a rally\n');
  rep('\tholdSend(S, longOnly, (lpow * kf) if lpow >= 0.0 else 1.0)',
      '\tholdSend(S, longOnly or (args != null and bool(args.get("decisive", false))), (lpow * kf) if lpow >= 0.0 else 1.0)');
});
edit('sim/director/ai.gd', rep => {
  rep('\tvar st: float = a.st\n',
      '\tif a.st == 3.0 and DirRally.noEscape(S, f):\n\t\ta.st = 0.0   # 10-26 item 22(d): no Escape for the attacker while his rally runs, nor for its body while sent\n\tvar st: float = a.st\n');
});
edit('sim/director/exchange.gd', rep => {
  rep('\tif DirBrawl.takes(S, A, kind):\n\t\treturn   # a brawl is on and he is in it: the press is a blow on his own line, never a request\n',
      '\tif DirRally.queues(S, A, kind):\n\t\treturn   # 10-26 item 7: a link press while his rally\'s send still holds him waits for his first free tick\n' +
      '\tif DirBrawl.takes(S, A, kind):\n\t\treturn   # a brawl is on and he is in it: the press is a blow on his own line, never a request\n');
  rep('\tDirWater.tick(S)   # a drop into the water surfaces within water.surfaceTicks (rulings-2026-10-26 row 6)\n',
      '\tDirWater.tick(S)   # a drop into the water surfaces within water.surfaceTicks (rulings-2026-10-26 row 6)\n\tDirRally.tick(S)   # 23d: the daze, and each rally\'s end\n');
});
const RALLY = {
  enabled: false,
  daze: { ticks: 40, shave: 3, shaveEvery: 6, burstAfter: 12 },
  waryTicks: 120,
  sell: { weight: 'launch', bLeftTicks: 8 },
  tech: { fresh: 4, earlier: 6, repeat: 8, autoAt: 3 },
  read: { leanMin: 0.6, sectorDeg: 45 },
  own: { palm_turn: { fighter: 'PROTAGONIST', base: 'overtake' }, plate_chase: { fighter: 'RIVAL', base: 'chase' } },
  endTicks: 20,
  queueTicks: 12,
  turnTicks: 60,
  airBh: 1.0,
  spikeAboveBh: 0.5,
  _note: "Game Design's rulings-2026-10-23d with its section 8 (sim/director/rally.gd, DirRally): the daze (daze.ticks; each press of his shaves daze.shave, at most one every daze.shaveEvery; RT's burst breaks it after daze.burstAfter), wary for waryTicks after a rally ends on him; the sell (a landed medium or heavy at a dazed fighter holds the sell.weight hit-stop); the rally: a full send opens it; its links are the chase strike, the overtake, the spike (from spikeAboveBh above him) and the fighters' own links this build has (own: each one's fighter); the stick's class is read once at the chase's commit, on a lean of read.leanMin, back or across within read.sectorDeg; the defender techs a link's arrival with a guard press within tech.fresh (a kind new to the rally), tech.earlier (used before) or tech.repeat (the same as the last) ticks, and the autoAt-th of one kind by itself; a teched link gives the counter-rush, and landing it on the chaser in the air (over airBh) within turnTicks is the turn. It ends endTicks after he lands with no link. The choreographer's scoring is data/director/rally.json. Game Design 10-26: a perfect block dazes only when it turns a heavy, a charged blow or an ender, and a heavy whiff only when a medium, a heavy or a perfect follow-up punishes it; the sold blows are mediums, and the AI sells its level's rally.sells of them before B, pressing B with sell.bLeftTicks of the daze left; each send frees its attacker after its hit-stop, and a link press made while he is still held waits up to queueTicks. A special launch (a signature, a finisher, a break launch) opens no rally. On, it turns on the chase, the recoil flips and the wall kick too.",
};
edit('data/director/interrupts.json', rep => {
  rep('(sim/director/water.gd, DirWater)."\n  }\n}',
      '(sim/director/water.gd, DirWater)."\n  },\n  "rally": ' + JSON.stringify(RALLY, null, 2).replace(/\n/g, '\n  ') + '\n}');
});
const AIR = { easy: { link: 0.6, sells: 0, tech: 0.08, techEarlier: 0.2, techRepeat: 0.4, dazeMash: 0.2, dazeBurst: 0.05, airBurst: 0.03 },
  medium: { link: 0.75, sells: 2, tech: 0.15, techEarlier: 0.3, techRepeat: 0.55, dazeMash: 0.4, dazeBurst: 0.15, airBurst: 0.06 },
  hard: { link: 0.9, sells: 2, tech: 0.2, techEarlier: 0.45, techRepeat: 0.7, dazeMash: 0.6, dazeBurst: 0.3, airBurst: 0.1 } };
edit('data/director/ai.json', rep => {
  for (const [share, lv] of [['0.1', 'easy'], ['0.25', 'medium'], ['0.4', 'hard']])
    rep('"chaseShare": ' + share + '\n', '"chaseShare": ' + share + ',\n      "rally": ' + JSON.stringify(AIR[lv]).replace(/,/g, ', ').replace(/:/g, ': ') + '\n');
});
// Combat's scoring (docs/combat/pending/rally/rally.scoring.json, director.rally/1) lands as Encounter's data, with its
// draft schema (Tools') and the schema map's row (Tools')
{
  const src = path.join(__dirname, 'data/director/rally.json');
  const to = path.join(root, 'data/director/rally.json');
  if (fs.existsSync(to)) throw new Error('data/director/rally.json exists already');
  JSON.parse(fs.readFileSync(src, 'utf8'));
  if (!check) fs.copyFileSync(src, to);
  console.log('data/director/rally.json' + (check ? ': present' : ': copied'));
  const ss = path.join(__dirname, 'tools/schemas/director-rally.schema.json');
  const st = path.join(root, 'tools/schemas/director-rally.schema.json');
  if (fs.existsSync(st)) throw new Error('tools/schemas/director-rally.schema.json exists already');
  JSON.parse(fs.readFileSync(ss, 'utf8'));
  if (!check) fs.copyFileSync(ss, st);
  console.log('tools/schemas/director-rally.schema.json' + (check ? ': present' : ': copied'));
}
// Tools' self-test reads data/director/ from tools/fixtures/virtual, and wants a valid document and three invalid cases
// for every mapped schema (tools/lib/selftest.js, section 5)
{
  const vt = path.join(root, 'tools/fixtures/virtual/data/director/rally.json');
  if (fs.existsSync(vt)) throw new Error('tools/fixtures/virtual/data/director/rally.json exists already');
  if (!check) fs.copyFileSync(path.join(__dirname, 'data/director/rally.json'), vt);
  console.log('tools/fixtures/virtual/data/director/rally.json' + (check ? ': present' : ': copied'));
  const cp = path.join(root, 'tools/fixtures/cases.json');
  const cj = JSON.parse(fs.readFileSync(cp, 'utf8'));
  if (cj.cases.some(c => c.schema === 'director-rally.schema.json')) throw new Error('cases.json: director-rally cases exist already');
  const F = 'data/director/rally.json', SC = 'director-rally.schema.json';
  cj.cases.push(
    { id: 'director-rally-valid', schema: SC, mutate: [{ file: F, set: { '/variety/kindNew': 22 } }], expect: null },
    { id: 'director-rally-key-required', schema: SC, mutate: [{ file: F, del: ['/variety'] }], expect: { rule: 'required', pointer: '' } },
    { id: 'director-rally-unknown-key', schema: SC, mutate: [{ file: F, set: { '/extra': 1 } }], expect: { rule: 'additionalProperties', pointer: '/extra' } },
    { id: 'director-rally-variety-type', schema: SC, mutate: [{ file: F, set: { '/variety/kindNew': 'high' } }], expect: { rule: 'type', pointer: '/variety/kindNew' } },
    { id: 'director-rally-underscore-key-ok', schema: SC, mutate: [{ file: F, set: { '/variety/_why': 'comment' } }], expect: null });
  if (!check) fs.writeFileSync(cp, JSON.stringify(cj, null, 2) + '\n');
  console.log('tools/fixtures/cases.json: director-rally x5' + (check ? ' (checked)' : ''));
}
edit('tools/schemas/map.json', rep => {
  rep('    {\n      "match": "data/director/launch.json",\n',
      '    {\n      "match": "data/director/rally.json",\n      "schema": "director-rally.schema.json"\n    },\n    {\n      "match": "data/director/launch.json",\n');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.rally) throw new Error('director-interrupts schema: rally exists already');
  const int0 = { type: 'integer', minimum: 0 }, num0 = { type: 'number', minimum: 0 };
  const obj = (props) => ({ type: 'object', additionalProperties: false, required: Object.keys(props).filter(k => k !== '_note'), properties: props });
  s.properties.rally = Object.assign(obj({ _note: { type: 'string' }, enabled: { type: 'boolean' },
    daze: obj({ ticks: int0, shave: int0, shaveEvery: { type: 'integer', minimum: 1 }, burstAfter: int0 }),
    waryTicks: int0, sell: obj({ weight: { type: 'string' }, bLeftTicks: int0 }),
    tech: obj({ fresh: int0, earlier: int0, repeat: int0, autoAt: { type: 'integer', minimum: 1 } }),
    read: obj({ leanMin: num0, sectorDeg: num0 }),
    own: { type: 'object', additionalProperties: obj({ fighter: { type: 'string', minLength: 1 }, base: { type: 'string', minLength: 1 } }) },
    endTicks: int0, queueTicks: int0, turnTicks: int0, airBh: num0, spikeAboveBh: num0 }),
    { description: 'The daze, the sell and the rally (Game Design\'s rulings-2026-10-23d; sim/director/rally.gd).' });
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: rally' + (check ? ' (checked)' : ''));
}
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  let n = 0;
  const walk = (o) => {
    if (!o || typeof o !== 'object') return;
    if (o.properties && o.properties.chaseShare && !o.properties.rally) {
      const sh = { type: 'number', minimum: 0, maximum: 1 };
      o.properties.rally = { type: 'object', additionalProperties: false, description: 'The AI in a rally (rulings-2026-10-23d): its share of chasing a body it sent in a rally of its own (in place of chaseShare), its tech shares at a link\'s arrival (a kind new to the rally, one used before, the same as the last), its daze mash (a shave every daze.shaveEvery) and burst out, its burst out of a link in flight. Its choice of link is the choreographer\'s scoring (data/director/rally.json).',
        required: ['link', 'sells', 'tech', 'techEarlier', 'techRepeat', 'dazeMash', 'dazeBurst', 'airBurst'],
        properties: { link: sh, sells: { type: 'integer', minimum: 0 }, tech: sh, techEarlier: sh, techRepeat: sh, dazeMash: sh, dazeBurst: sh, airBurst: sh } };
      n += 1;
    }
    for (const v of Object.values(o)) walk(v);
  };
  walk(s);
  if (n !== 3) throw new Error('director-ai schema: expected 3 levels with chaseShare, found ' + n);
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: rally x' + n + (check ? ' (checked)' : ''));
}
