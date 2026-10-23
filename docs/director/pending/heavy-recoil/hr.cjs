// hr.cjs: Game Design's 1a (rulings-2026-10-22): a tapped heavy that lands clean in a brawl recoils him 1.5 bh as an
// 8-tick slide, in place of its stagger in place. It opens the recoil flip's window, and with no flip he reels 6 ticks
// at the slide's end. Behind data/director/interrupts.json recoilFlip.enabled (false on main) and its heavy.enabled:
// off, the heavy staggers as today and the golden doesn't move. On main with the recoil flips (DirRecoil).
//   node hr.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node hr.cjs <checkout root> [--check]');
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
if (!fs.existsSync(path.join(root, 'sim/director/recoil.gd'))) throw new Error('the recoil flips first (sim/director/recoil.gd)');
edit('sim/director/recoil.gd', rep => {
  rep('const RC_DIST: int = 7    # the knock-back\'s distance, in units\nconst RC_N: int = 8\n',
      'const RC_DIST: int = 7    # the knock-back\'s distance, in units\n' +
      'const RC_BSL: int = 8     # live ticks left in a heavy\'s recoil slide inside a brawl (Game Design\'s 1a); 0 none\n' +
      'const RC_N: int = 9\n');
  rep('\t\tif f.state != "free" or f.rush == null or f.rush.tgt != null:\n\t\t\t_s(f, RC_LEFT, 0)\n\t\t\treturn   # his slide or drift has ended, or an approach has taken its place\n',
      '\t\tif (f.state != "free" and not (kind == 4 and f.state == "locked")) or f.rush == null or f.rush.tgt != null:\n\t\t\t_s(f, RC_LEFT, 0)\n\t\t\treturn   # his slide or drift has ended, or an approach has taken its place\n');
  rep('\tf.rush = r\n\tf.vx = 0.0\n\tf.vy = 0.0\n\tf.state = "free"\n\tf.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(f.x, o.x)), f.face)\n\tDirBrawl.recoilFree(f)   # no first-move lock and no return: the counter-rush is his\n',
      '\tf.rush = r\n\tf.vx = 0.0\n\tf.vy = 0.0\n' +
      '\tif kind != 4:\n\t\tf.state = "free"   # (out of a heavy\'s recoil in a brawl he stays in it)\n' +
      '\t_s(f, RC_BSL, 0)   # a flip out of a heavy\'s recoil: no reel at its end\n' +
      '\tf.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(f.x, o.x)), f.face)\n\tDirBrawl.recoilFree(f)   # no first-move lock and no return: the counter-rush is his\n');
  rep('\t\tvar left: int = _g(f, RC_LEFT)\n\t\tif left <= 0:\n\t\t\tcontinue\n',
      '\t\tvar bsl: int = _g(f, RC_BSL)\n' +
      '\t\tif bsl > 0:\n' +
      '\t\t\t_s(f, RC_BSL, bsl - 1)\n' +
      '\t\t\tif bsl == 1:\n' +
      '\t\t\t\tDirBrawl._reel(S, f, int(cfg().get("heavy", {}).get("reelTicks", 6)))   # 1a: no flip, so he reels at the slide\'s end\n' +
      '\t\tvar left: int = _g(f, RC_LEFT)\n\t\tif left <= 0:\n\t\t\tcontinue\n');
  rep('## While he is in the air of his flip: his presses wait for the landing.\n',
      '## Game Design\'s 1a (rulings-2026-10-22): a tapped heavy that lands clean in a brawl (DirBrawl._bigLanded) recoils him\n' +
      '## heavy.bh body heights as a slide of heavy.ticks, in place of its stagger in place. His blow on its way is lost, as a\n' +
      '## stagger loses it. It opens the flip\'s window (kind 4: a slide inside the brawl, which holds: its pull rests while he\n' +
      '## slides, and brings them back after). With no flip he reels heavy.reelTicks at its end. A wall behind him shortens it.\n' +
      '## The recoil cue, text "exit", says so (Combat\'s exit by weight: a heavy\'s backflip, fitted to the slide).\n' +
      'static func heavyRecoil(S: SimState, ex, f, o) -> bool:\n' +
      '\tvar h: Dictionary = cfg().get("heavy", {})\n' +
      '\tif not on() or not bool(h.get("enabled", false)) or not o.act.v2:\n\t\treturn false\n' +
      '\tvar dist: float = float(h.get("bh", 1.5)) * BH\n' +
      '\tvar ticks: int = int(h.get("ticks", 8))\n' +
      '\tvar dir: float = _away(f, o)\n' +
      '\tvar g: float = WorldTerrain.groundY(S, o.x)\n' +
      '\tvar ground: bool = o.y - g <= float(DirLaunch.data().knockBack.groundWithinBh) * BH and not WorldTerrain.seaAt(S, o.x)\n' +
      '\tvar so := Callable(WorldContact, "slideObstacle")\n' +
      '\tif ground and so.is_valid():\n' +
      '\t\tvar ob = so.call(S, o.x, o.z, dir, dist)\n' +
      '\t\tif ob is Dictionary and ob.get("hit", false):\n' +
      '\t\t\tdist = maxf(0.0, float(ob.d) - DirLaunch.BUMP_SHORT)   # a wall behind him: the slide stops short of it\n' +
      '\tDirBrawl._drop(S, ex, o)\n' +
      '\tvar r := SimState.Rush.new()\n' +
      '\tr.px = SimWrap.wrap(o.x + dir * dist)\n' +
      '\tvar g2: float = WorldTerrain.groundY(S, r.px)\n' +
      '\tr.py = g2 if ground else maxf(o.y, g2)\n' +
      '\tr.pz = o.z\n' +
      '\tr.end = S.T + float(ticks) * SimConst.DT\n' +
      '\to.rush = r\n' +
      '\tknocked(S, f, o, dist, 4, S.tick + ticks)\n' +
      '\t_s(o, RC_BSL, ticks)\n' +
      '\t_cue(S, o, f, "exit", "backflip", o.x, o.y, r.px, S.tick + ticks, ticks, ground)\n' +
      '\tSimEvents.feed(S, o.name + " RECOILS", "a clean heavy sends him back " + str(snappedf(dist / BH, 0.1)) + " bh over " + str(ticks) + " ticks: a dodge tap flips him out")\n' +
      '\treturn true\n\n\n' +
      '## While he is in the air of his flip: his presses wait for the landing.\n');
});
edit('sim/director/brawl.gd', rep => {
  rep('\t\treturn\n\t_stagger(S, ex, f, o, int(c.heavy.staggerTicks), "heavy")\n\n\n## The burst (brawl-second-pass.md section 3)',
      '\t\treturn\n\tif DirRecoil.heavyRecoil(S, ex, f, o):\n\t\treturn   # Game Design\'s 1a: a clean tapped heavy recoils him 1.5 bh, in place of the stagger\n\t_stagger(S, ex, f, o, int(c.heavy.staggerTicks), "heavy")\n\n\n## The burst (brawl-second-pass.md section 3)');
  rep('\tvar d: int = _closeTicks(f, o)   # the gap it closes on the way: it lands this much later\n',
      '\tvar d: int = _closeTicks(f, o)   # the gap it closes on the way: it lands this much later\n' +
      '\tif d > 0 and DirRecoil.counter(S, f):\n\t\td = 0   # out of his recoil flip (Game Design\'s 1a): the counter-rush closes the gap at once\n');
});
edit('data/director/interrupts.json', rep => {
  rep('    "aiCounterTicks": [2, 8]\n  },\n',
      '    "aiCounterTicks": [2, 8],\n    "heavy": {"enabled": true, "bh": 1.5, "ticks": 8, "reelTicks": 6, "_note": "Game Design\'s 1a (rulings-2026-10-22): a tapped heavy that lands clean in a brawl recoils him bh body heights as a slide of ticks, in place of its stagger in place; it opens the flip\'s window, and with no flip he reels reelTicks at its end. Only with recoilFlip on."}\n  },\n');
});
// The sim's own pi (SimMathx.PI, on main from 74ee6b04) in place of the engine's PI, in the director's five uses and
// calm.gd's copy: the same double, so nothing moves (the parity lint's "no engine constants").
if (!fs.readFileSync(path.join(root, 'sim/core/mathx.gd'), 'utf8').includes('static var PI: float')) throw new Error('SimMathx.PI first (74ee6b04)');
edit('sim/director/beamplay.gd', rep => {
  rep('\tvar a: float = float(c.spreadDeg) * PI / 180.0\n', '\tvar a: float = float(c.spreadDeg) * SimMathx.PI / 180.0\n');
  rep('\tvar g: float = float(c.groundDeg) * PI / 180.0\n', '\tvar g: float = float(c.groundDeg) * SimMathx.PI / 180.0\n');
  rep('\t\tvar s: float = float(c.skyDeg) * PI / 180.0\n', '\t\tvar s: float = float(c.skyDeg) * SimMathx.PI / 180.0\n');
});
edit('sim/director/launch.gd', rep => {
  rep('\tvar a: float = (float(d.lowDeg) + (float(d.highDeg) - float(d.lowDeg)) * t) * PI / 180.0\n',
      '\tvar a: float = (float(d.lowDeg) + (float(d.highDeg) - float(d.lowDeg)) * t) * SimMathx.PI / 180.0\n');
});
edit('sim/director/zip.gd', rep => {
  rep('\t\t\tvar rad: float = float(b) * PI / 180.0\n', '\t\t\tvar rad: float = float(b) * SimMathx.PI / 180.0\n');
});
edit('sim/director/calm.gd', rep => {
  rep('static var _PI: float = SimMathx.f64("400921fb54442d18")   # pi from its bits: no engine trig in the sim\n',
      'static var _PI: float = SimMathx.PI   # the sim\'s own pi: no engine trig in the sim\n');
});
// Game Design's rulings-2026-10-23 §1: with 1a in, the AI's flips read under 1.5 a minute, so its flip shares rise from
// 20, 45 and 70% to 30, 60 and 85% (only with recoilFlip on).
edit('data/director/ai.json', rep => {
  rep('"recoil": {"flip": 0.2, "counter": 0.5}', '"recoil": {"flip": 0.3, "counter": 0.5}');
  rep('"recoil": {"flip": 0.45, "counter": 0.7}', '"recoil": {"flip": 0.6, "counter": 0.7}');
  rep('"recoil": {"flip": 0.7, "counter": 0.9}', '"recoil": {"flip": 0.85, "counter": 0.9}');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const rf = s.properties.recoilFlip;
  if (!rf) throw new Error('director-interrupts schema: no recoilFlip (the recoil flips first)');
  if (rf.properties.heavy) throw new Error('director-interrupts schema: recoilFlip.heavy exists already');
  rf.properties.heavy = { type: 'object', description: 'Game Design\'s 1a: a clean tapped heavy\'s recoil in a brawl.',
    properties: { _note: { type: 'string' }, enabled: { type: 'boolean', description: 'False: the heavy staggers in place, as before.' },
      bh: { type: 'number', minimum: 0, description: 'How far, in body heights.' },
      ticks: { type: 'integer', minimum: 1, description: 'The slide\'s live ticks.' },
      reelTicks: { type: 'integer', minimum: 0, description: 'With no flip, his reel at the slide\'s end.' } },
    required: ['enabled', 'bh', 'ticks', 'reelTicks'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: recoilFlip.heavy' + (check ? ' (checked)' : ''));
}
