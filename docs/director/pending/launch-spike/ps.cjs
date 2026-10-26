// ps.cjs: Game Design's rulings-2026-10-23c items 9 to 11, on the pop (../launch-pop/pp.cjs). Only with
// anywhere.pop.enabled (under launch anywhere's switch, false on main), so the golden doesn't move.
//   9   a popped fighter is in a juggle, not an opening: a launcher at him is never sure (nor while he lands from it), and
//       never a send. B at him is the spike: down into the ground under him in pop.spike.fallTicks (6), its crater (an
//       impact at pop.spike.speed), and the ground's recovery (a tech, or pop.spike.recoverTicks: 21, 0.35 s); the brawl
//       goes on. No aim, no journey, no freshness mark, no wary window, no pay. Cue "pop" "spike"; its landing "land", amount 1
//   10  anywhere.landPay 1.0 to 0.5 and anywhere.worth 5 to 4
//   11  a teched pop landing is a recoil flip (with recoilFlip on): the backflip, and the counter-rush within its 20 ticks
//   12  the pop's rise is a reel: from its apex (pop.freeAt 12; pop.ticks 24, so the apex is at 12) he is free in the air to
//       guard, perfect-block and strike, and comes down with the pop; no landing reel (pop.landReel 0) and no burst out.
//       While one of them is popped, a blow's reach and its closing are by the horizontal gap (_gapDist)
//   node ps.cjs <checkout root> [--check]     (after ../launch-pop/pp.cjs)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node ps.cjs <checkout root> [--check]');
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
if (!fs.readFileSync(path.join(root, 'sim/director/brawl.gd'), 'utf8').includes('static func _popTick(S: SimState) -> void:')) throw new Error('../launch-pop/pp.cjs first (DirBrawl._pop, _popTick)');
edit('sim/director/brawl.gd', rep => {
  rep('const LA_POP_BURST: int = 38   # ... 1 the AI will burst out after pop.burstAfter\nconst LA_N: int = 39\n',
      'const LA_POP_BURST: int = 38   # ... 1 the AI will burst out after pop.burstAfter\n' +
      'const LA_POP_SPK: int = 39     # 1 while his coming down is a spike\'s (23c 9): its landing digs a crater\n' +
      'const LA_POP_STUN: int = 40    # S.tick his juggle\'s stun ends (the pop and its landing, or the spike and its recovery): no opening before it\n' +
      'const LA_N: int = 41\n');
  // 9: B at a popped fighter is the spike
  rep('\t\t\tif pp < float(popCfg().get("full", 0.8)):\n\t\t\t\t_pop(S, ex, f, o, pp)',
      '\t\t\tif popOn() and _lg(o, LA_POP_UNTIL) > S.tick:\n' +
      '\t\t\t\t_spike(S, ex, f, o)   # 23c 9: B at a popped fighter is the spike, never a send\n' +
      '\t\t\telif pp < float(popCfg().get("full", 0.8)):\n\t\t\t\t_pop(S, ex, f, o, pp)');
  rep('static func _safety(S: SimState, f, o) -> int:\n\tif o.stunTicks > 0:\n\t\treturn 1\n',
      'static func _safety(S: SimState, f, o) -> int:\n\tif o.stunTicks > 0 and not (popOn() and S.tick < _lg(o, LA_POP_STUN)):\n' +
      '\t\treturn 1   # (a juggle\'s stun is no opening: 23c 9)\n');
  // 12: the pop's rise is a reel; from the apex (pop.freeAt) he is free in the air, and comes down with the pop
  rep('\to.stunTicks = maxi(o.stunTicks, ticks + reel)\n',
      '\tvar free: int = int(pc.get("freeAt", 0))\n' +
      '\tvar stun: int = mini(free, ticks) if (free > 0 and not again) else ticks + reel   # 23c 12: free from the apex, guard, perfect block and strike in the air\n' +
      '\to.stunTicks = maxi(o.stunTicks, stun)\n');
  rep('\t_ls(o, LA_POP_UNTIL, S.tick + ticks)\n\t_ls(o, LA_POP_TECH, 0)\n\t_ls(o, LA_POP_BURST, 0)\n',
      '\t_ls(o, LA_POP_UNTIL, S.tick + ticks)\n\t_ls(o, LA_POP_TECH, 0)\n\t_ls(o, LA_POP_BURST, 0)\n' +
      '\t_ls(o, LA_POP_STUN, S.tick + stun)\n\t_ls(o, LA_POP_SPK, 0)\n');
  rep('\t\tif at >= 0 and S.tick - at >= int(pc.get("burstAfter", 12)) and f.rush != null and float(f.rush.arc) != 0.0:\n',
      '\t\tif int(pc.get("freeAt", 0)) <= 0 and at >= 0 and S.tick - at >= int(pc.get("burstAfter", 12)) and f.rush != null and float(f.rush.arc) != 0.0:   # (free from the apex, he strikes instead: 23c 12)\n');
  // a blow either way while one of them is popped: its reach and its closing by the horizontal gap (the attacker steps up
  // to his height as it lands), so a launcher's 14 ticks aren't stretched by the height (why no spike landed in 1,492 pops)
  rep('\tvar far: float = (absf(SimWrap.sdx(f.x, o.x)) if _lg(o, LA_POP_UNTIL) > S.tick else DirBands.dist(f, o))',
      '\tvar far: float = (absf(SimWrap.sdx(f.x, o.x)) if (_lg(o, LA_POP_UNTIL) > S.tick or _lg(f, LA_POP_UNTIL) > S.tick) else DirBands.dist(f, o))');
  rep('static func _closeTicks(f, o) -> int:\n\tvar gi: Dictionary = cfg().give\n\tvar gap: float = (DirBands.dist(f, o) - float(DirData.contact().reach)) / DirInterrupt.BH\n',
      'static func _closeTicks(f, o) -> int:\n\tvar gi: Dictionary = cfg().give\n\tvar gap: float = (_gapDist(f, o) - float(DirData.contact().reach)) / DirInterrupt.BH\n');
  rep('\tvar gapBh: float = maxf(0.0, (DirBands.dist(f, o) - float(DirData.contact().reach)) / DirInterrupt.BH)\n',
      '\tvar gapBh: float = maxf(0.0, (_gapDist(f, o) - float(DirData.contact().reach)) / DirInterrupt.BH)\n');
  rep('## f moves toward striking distance from o, on his own side and at o\'s height:',
      '## The gap a blow closes: the pair\'s distance, or the horizontal gap while one of them is popped (23c 12: he is struck\n' +
      '## and strikes at his height, and the striker steps up to it as the blow lands).\n' +
      'static func _gapDist(f, o) -> float:\n' +
      '\tif popOn() and (_lg(o, LA_POP_UNTIL) > 0 or _lg(f, LA_POP_UNTIL) > 0):\n\t\treturn absf(SimWrap.sdx(f.x, o.x))\n' +
      '\treturn DirBands.dist(f, o)\n\n\n' +
      '## f moves toward striking distance from o, on his own side and at o\'s height:');
  // the landing: a spike's digs its crater; the tech of a pop's landing is a recoil flip (11)
  rep('\t\t\tvar le = _ev(S, f, "pop", "land")\n\t\t\tle.n = 1 if landedSet else 0\n',
      '\t\t\tvar spk: bool = _lg(f, LA_POP_SPK) == 1\n' +
      '\t\t\tif spk:\n' +
      '\t\t\t\t_ls(f, LA_POP_SPK, 0)\n' +
      '\t\t\t\tvar by = SimRoster.opp(S, f)\n' +
      '\t\t\t\tWorldCrater.dig(S, f.x, WorldCrater.impactEnergy(float(popCfg().get("spike", {}).get("speed", 1800.0)), float(by.tier)), by, "impact", 0.0, 1.0, false)   # the spike\'s crater, under him\n' +
      '\t\t\tif landedSet:\n\t\t\t\t_ls(f, LA_POP_STUN, S.tick)\n' +
      '\t\t\tvar le = _ev(S, f, "pop", "land")\n\t\t\tle.n = 1 if landedSet else 0\n\t\t\tle.amount = 1.0 if spk else 0.0\n');
  rep('\t\t\t\t_ls(f, LA_POP_TECH, 2)\n\t\t\t\tf.stunTicks = mini(f.stunTicks, until - S.tick)\n\t\t\t\t_ev(S, f, "pop", "tech")\n',
      '\t\t\t\t_ls(f, LA_POP_TECH, 2)\n\t\t\t\tf.stunTicks = mini(f.stunTicks, until - S.tick)\n\t\t\t\t_ev(S, f, "pop", "tech")\n' +
      '\t\t\t\tif _lg(f, LA_POP_SPK) == 0 and DirRecoil.popFlip(S, f, SimRoster.opp(S, f)):\n' +
      '\t\t\t\t\tvar fl: int = int(DirRecoil.cfg().get("flipTicks", 12))\n' +
      '\t\t\t\t\t_ls(f, LA_POP_UNTIL, S.tick + fl)   # 23c 11: a teched pop landing is a recoil flip: he backflips out and lands set\n' +
      '\t\t\t\t\tf.stunTicks = fl\n');
  rep('## Each tick (laTick): a popped fighter\'s tech',
      '## f spikes a popped o (23c 9): down into the ground under him in spike.fallTicks, where his landing digs a crater and\n' +
      '## he recovers in spike.recoverTicks unless he techs it. The brawl goes on. No aim, journey, freshness mark, wary window\n' +
      '## or pay; his blow on its way is lost. Cue "pop": spike.\n' +
      'static func _spike(S: SimState, ex, f, o) -> void:\n' +
      '\tvar sc: Dictionary = popCfg().get("spike", {})\n' +
      '\tvar fall: int = int(sc.get("fallTicks", 6))\n' +
      '\tvar rec: int = int(sc.get("recoverTicks", 21))\n' +
      '\t_drop(S, ex, o)\n' +
      '\tvar r := SimState.Rush.new()\n' +
      '\tr.px = o.x\n' +
      '\tr.py = WorldTerrain.groundY(S, o.x)\n' +
      '\tr.pz = o.z\n' +
      '\tr.end = S.T + float(fall) * SimConst.DT\n' +
      '\to.rush = r\n' +
      '\to.vx = 0.0\n\to.vy = 0.0\n' +
      '\to.stunTicks = maxi(o.stunTicks, fall + rec)\n' +
      '\t_ls(o, LA_POP_UNTIL, S.tick + fall)\n' +
      '\t_ls(o, LA_POP_STUN, S.tick + fall + rec)\n' +
      '\t_ls(o, LA_POP_SPK, 1)\n' +
      '\t_ls(o, LA_POP_TECH, 0)\n' +
      '\t_ls(o, LA_POP_BURST, 0)\n' +
      '\tif o.ai != null and SimRng.keyed(int(S.game.seed), "spike.tech", S.tick * 4 + S.fighters.find(o)) < float(DirAI.lv().get("brawl", {}).get("recoil", {}).get("flip", 0.0)):\n' +
      '\t\t_ls(o, LA_POP_TECH, 1)\n' +
      '\tvar e = _ev(S, o, "pop", "spike")\n' +
      '\te.target = float(S.fighters.find(f))\n' +
      '\te.n = S.tick + fall\n' +
      '\te.dur = float(fall)\n' +
      '\te.x = o.x\n' +
      '\tSimEvents.feed(S, o.name + " IS SPIKED", "a launcher at a popped fighter slams him into the ground under him: the brawl goes on")\n\n\n' +
      '## Each tick (laTick): a popped fighter\'s tech');
});
edit('sim/director/recoil.gd', rep => {
  rep('## While he is in the air of his flip: his presses wait for the landing.\n',
      '## Game Design\'s 23c 11: a teched pop landing (DirBrawl._popTick) is a recoil flip: the same backflip away from o,\n' +
      '## landing set where it ends, and the counter-rush within counterTicks after it. Inside the brawl (kind 4, locked).\n' +
      '## False with recoil flips off: then the tech is the tech alone.\n' +
      'static func popFlip(S: SimState, f, o) -> bool:\n' +
      '\tif not on() or not f.act.v2:\n\t\treturn false\n' +
      '\tvar c: Dictionary = cfg()\n' +
      '\tvar dir: float = _away(o, f)\n' +
      '\tvar ticks: int = int(c.flipTicks)\n' +
      '\tvar travel: float = float(c.flipBh) * BH\n' +
      '\tvar base: float = f.rush.py if f.rush != null else f.y\n' +
      '\tvar so := Callable(WorldContact, "slideObstacle")\n' +
      '\tif so.is_valid():\n' +
      '\t\tvar ob = so.call(S, f.x, f.z, dir, travel)\n' +
      '\t\tif ob is Dictionary and ob.get("hit", false):\n' +
      '\t\t\ttravel = maxf(0.0, float(ob.d) - DirLaunch.BUMP_SHORT)\n' +
      '\tvar r := SimState.Rush.new()\n' +
      '\tr.px = SimWrap.wrap(f.x + dir * travel)\n' +
      '\tr.py = maxf(base, WorldTerrain.groundY(S, r.px))\n' +
      '\tr.pz = f.z\n' +
      '\tr.end = S.T + float(ticks) * SimConst.DT\n' +
      '\tr.arc = float(c.arcBh) * BH * dir\n' +
      '\tf.rush = r\n' +
      '\tf.vx = 0.0\n\tf.vy = 0.0\n' +
      '\tf.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(f.x, o.x)), f.face)\n' +
      '\tDirBrawl.recoilFree(f)\n' +
      '\t_s(f, RC_LEFT, 0)\n\t_s(f, RC_AI, 0)\n\t_s(f, RC_KIND, 4)\n' +
      '\t_s(f, RC_AIR, ticks)\n' +
      '\t_cue(S, f, o, "flip", "backflip", f.x, f.y, r.px, S.tick + ticks, ticks, true)\n' +
      '\tSimEvents.feed(S, f.name + " RECOIL FLIP", "out of the pop\'s landing: he lands set in " + str(ticks) + ", and his next blow within " + str(int(c.counterTicks)) + " is a counter-rush")\n' +
      '\treturn true\n\n\n' +
      '## While he is in the air of his flip: his presses wait for the landing.\n');
});
edit('data/director/interrupts.json', rep => {
  rep('        "worth": 5,\n        "landPay": 1.0,\n', '        "worth": 4,\n        "landPay": 0.5,\n');
  rep('"stringPoints": 2, "_note": "Game Design', '"stringPoints": 2, "freeAt": 12, "spike": {"fallTicks": 6, "recoverTicks": 21, "speed": 1800}, "_note": "Game Design');
  rep('"pop": {"enabled": true, "full": 0.8, "bh": [1.5, 3.0], "ticks": 30, "landReel": 8,', '"pop": {"enabled": true, "full": 0.8, "bh": [1.5, 3.0], "ticks": 24, "landReel": 0,');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const pop = s.properties.brawl.properties.launcher.properties.anywhere.properties.pop;
  if (!pop) throw new Error('director-interrupts schema: no anywhere.pop (../launch-pop first)');
  if (pop.properties.spike) throw new Error('director-interrupts schema: anywhere.pop.spike exists already');
  pop.properties.freeAt = { type: 'integer', minimum: 0, description: 'Game Design\'s 23c 12: ticks after the pop at which he is free in the air (its apex); 0: stunned to the landing and landReel after it.' };
  pop.properties.spike = { type: 'object', additionalProperties: false, required: ['fallTicks', 'recoverTicks', 'speed'],
    description: 'Game Design\'s 23c 9: B at a popped fighter spikes him into the ground under him: down in fallTicks, a crater as an impact at speed, and recoverTicks of recovery unless he techs it.',
    properties: { fallTicks: { type: 'integer', minimum: 1 }, recoverTicks: { type: 'integer', minimum: 0 }, speed: { type: 'number', minimum: 0 } } };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: anywhere.pop.spike' + (check ? ' (checked)' : ''));
}
