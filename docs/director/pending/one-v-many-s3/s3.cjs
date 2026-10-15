// s3.cjs <checkout root>: one versus many, stage 3, after s2.cjs (which copies ring.gd: stage 3's DirRing has the
// interjection, the step in on a tag and the guards' rules). Every anchor is exact text; it stops at the first missing.
//   sim/director/brawl.gd      a beat of the ring (args.a "X") lands in DirRing.landX; a guard's landed blow builds no
//                              run (so he never closes on the one); a guard's launcher is never ready (his B is the
//                              hammer); a guard's charged heavy, and any send or knock-back of his, staggers instead
//   sim/director/interrupt.gd  the perfect block's window reads no staleness for a ring beat
//   data/director/interrupts.json  brawl.ring: the step in and the interjection
//   tools/schemas/director-interrupts.schema.json  the same keys (optional, for Tools)
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b) => {
    const n = t.split(a).length - 1;
    if (n !== 1) throw new Error(rel + ': expected 1 match, got ' + n + ' for: ' + a.slice(0, 80));
    t = t.replace(a, () => b);
  };
  fn(rep);
  if (rel.endsWith('.json')) JSON.parse(t);
  fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + ': ok');
}
if (!fs.readFileSync(path.join(root, 'sim/director/ring.gd'), 'utf8').includes('static func landX')) throw new Error('ring.gd is not stage 3 (run s2.cjs with stage 3\'s ring.gd first)');
edit('sim/director/brawl.gd', rep => {
  rep('static func contact(S: SimState, ex, b) -> void:\n\tvar a = b.args\n',
      'static func contact(S: SimState, ex, b) -> void:\n\tvar a = b.args\n' +
      '\tif String(a.get("a", "")) == "X":\n\t\tDirRing.landX(S, ex, b)   # one versus many: a blow the director granted to a ring guard\n\t\treturn\n');
  rep('\treturn _g(f, LINE) == 0 and S.tick >= _g(f, FREE_AT) and _now(S) >= _g(f, REEL_AT) and f.stunTicks <= 0\n',
      '\treturn _g(f, LINE) == 0 and S.tick >= _g(f, FREE_AT) and _now(S) >= _g(f, REEL_AT) and f.stunTicks <= 0 and not DirRing.holds(S, f)   # (one versus many: a partner\'s line waits for an interjection)\n');
  rep('\t\tif t >= int(fl.doubleTicks) and not quiet(ex) and ex.A.stunTicks <= 0 and ex.D.stunTicks <= 0 and ex.A.rush == null and ex.D.rush == null:\n',
      '\t\tif t >= int(fl.doubleTicks) and not quiet(ex) and ex.A.stunTicks <= 0 and ex.D.stunTicks <= 0 and ex.A.rush == null and ex.D.rush == null and not DirRing.interjecting(S):   # (an interjection in flight, or just landed, holds the double hit)\n');
  rep('static func _burstTick(S: SimState, ex, f, now: int) -> void:\n\tvar x: int = _g(f, X_LIVE)\n\tif x <= 0:\n\t\treturn\n',
      'static func _burstTick(S: SimState, ex, f, now: int) -> void:\n\tvar x: int = _g(f, X_LIVE)\n\tif x <= 0:\n\t\treturn\n\tif DirRing.holds(S, f):\n\t\treturn   # one versus many: a held X\'s burst pauses while the ring holds his line for an interjection\n');
  rep('\tif o.stunTicks <= 0 or bool(c.flurry.staggeredAddsRun):\n',
      '\tif (o.stunTicks <= 0 or bool(c.flurry.staggeredAddsRun)) and not DirRing.isGuard(S, f):   # a guard\'s blows build no run against him\n');
  rep('static func launcherReady(S: SimState, f) -> bool:\n',
      'static func launcherReady(S: SimState, f) -> bool:\n\tif DirRing.isGuard(S, f):\n\t\treturn false   # a guard never launches the one: in an opening his B is the hammer\n');
  rep('\tif bool(a.get("charged", false)):\n\t\tif float(a.get("charge", 0.0)) >= 1.0:\n\t\t\t_send(',
      '\tif bool(a.get("charged", false)) and DirRing.isGuard(S, f):\n\t\t_stagger(S, ex, f, o, int(c.heavy.staggerTicks), "heavy")   # a guard\'s charged heavy staggers him where he stands: no send\n\t\treturn\n' +
      '\tif bool(a.get("charged", false)):\n\t\tif float(a.get("charge", 0.0)) >= 1.0:\n\t\t\t_send(');
  rep('static func _send(S: SimState, ex, f, o, aim: int, why: String, mul: float) -> void:\n',
      'static func _send(S: SimState, ex, f, o, aim: int, why: String, mul: float) -> void:\n\tif DirRing.isGuard(S, f):\n\t\t_stagger(S, ex, f, o, int(cfg().heavy.staggerTicks), "heavy")   # a guard sends nobody\n\t\treturn\n');
  rep('static func _knock(S: SimState, ex, f, o, bh: float, aim: int, half: bool = false) -> void:\n',
      'static func _knock(S: SimState, ex, f, o, bh: float, aim: int, half: bool = false) -> void:\n\tif DirRing.isGuard(S, f):\n\t\t_stagger(S, ex, f, o, int(cfg().heavy.staggerTicks), "heavy")   # ... nor knocks anyone back\n\t\treturn\n');
});
edit('sim/director/exchange.gd', rep => {
  rep('static func _start(S: SimState, A, kind: String) -> int:\n\tif S.dirS.ex != null or S.game.ko != null:\n\t\treturn WAIT\n',
      'static func _start(S: SimState, A, kind: String) -> int:\n\tif S.dirS.ex != null or S.game.ko != null:\n\t\treturn WAIT\n\tif DirRing.holds(S, A):\n\t\treturn WAIT   # one versus many: a partner\'s line waits for an interjection, a new brawl\'s first blow too\n');
});
edit('sim/director/melee.gd', rep => {
  rep('\tvar ends: String = String(args.get("ends", "")) if args != null else ""\n',
      '\tvar ends: String = String(args.get("ends", "")) if args != null else ""\n' +
      '\tif DirRing.isGuard(S, att) and tgt == S.fighters[0]:\n' +
      '\t\t# One versus many: a guard sends nobody. His win in a planned exchange leaves the one in reach.\n' +
      '\t\tDirInterrupt.si(ex.A, DirInterrupt.LAST_END, DirInterrupt.END_STAY)\n' +
      '\t\tSimFx.launchPlan(S, att, tgt, "", "STAY")\n' +
      '\t\tSimEvents.feed(S, "STAYS IN REACH", "a guard sends nobody")\n' +
      '\t\treturn\n');
});
edit('sim/director/launch.gd', rep => {
  rep('static func knock(S: SimState, att, tgt, mul: float = 1.0, ox: float = NAN) -> void:\n',
      'static func knock(S: SimState, att, tgt, mul: float = 1.0, ox: float = NAN) -> void:\n\tif DirRing.isGuard(S, att) and tgt == S.fighters[0]:\n\t\treturn   # one versus many: a guard knocks nobody back\n');
  rep('static func knockBack(S: SimState, att, tgt) -> void:\n',
      'static func knockBack(S: SimState, att, tgt) -> void:\n\tif DirRing.isGuard(S, att) and tgt == S.fighters[0]:\n\t\treturn\n');
  rep('static func doLaunch(S: SimState, att, tgt, plan: Dictionary, force: float, special: bool = false) -> void:\n',
      'static func doLaunch(S: SimState, att, tgt, plan: Dictionary, force: float, special: bool = false) -> void:\n\tif DirRing.isGuard(S, att) and tgt == S.fighters[0]:\n\t\treturn   # one versus many: a guard launches nobody\n');
});
edit('sim/director/blast.gd', rep => {
  rep('static func _fire(S: SimState, f, weight: int, charge: float) -> void:\n',
      'static func _fire(S: SimState, f, weight: int, charge: float) -> void:\n\tif DirRing.inRing(S, f):\n\t\tDirInterrupt.si(f, DirInterrupt.BLAST_REQ, 0)   # one versus many: a guard in the ring never fires; what he queued as partner is dropped\n\t\treturn\n');
  rep('static func layMine(S: SimState, f) -> void:\n',
      'static func layMine(S: SimState, f) -> void:\n\tif DirRing.inRing(S, f):\n\t\treturn\n');
});
edit('sim/director/bury.gd', rep => {
  rep('static func fireBlast(S: SimState, A, D) -> void:\n',
      'static func fireBlast(S: SimState, A, D) -> void:\n\tif DirRing.inRing(S, A):\n\t\treturn   # one versus many: a guard in the ring never fires\n');
});
edit('sim/director/interrupt.gd', rep => {
  rep('\t\tw += float(_staleWindow(ex.A if b.args.a == "A" else ex.D))\n',
      '\t\tw += float(_staleWindow(ex.A if b.args.a == "A" else ex.D)) if String(b.args.a) != "X" else 0.0   # (a ring beat: no staleness)\n');
});
edit('data/director/interrupts.json', rep => {
  rep('"stepInTicks": 45, ',
      '"stepInTicks": 45, "tagStepTicks": 12, "tagStepBh": 0.3, "tagStepSpeed": 4000.0, ' +
      '"interject": {"enabled": true, "everyS": 1.5, "clearTicks": 8, "windTicks": 10, "inTicksMax": 12, "speed": 4000.0, "kinds": ["light"], "worthMul": 0.5, "reelTicks": 2}, ');
});
const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
const r = s.properties.brawl.properties.ring;
if (!r) throw new Error('s2.cjs first: no brawl.ring in the schema');
const int = d => ({ type: 'integer', minimum: 0, description: d });
const num = d => ({ type: 'number', minimum: 0, description: d });
r.properties.tagStepTicks = int('A guard made the partner by a tag steps in for at most this many live ticks.');
r.properties.tagStepBh = num('... to this far past striking distance, in body heights.');
r.properties.tagStepSpeed = num('... at this speed, units a second.');
r.properties.interject = {
  type: 'object',
  properties: {
    enabled: { type: 'boolean', description: 'One blow from the ring, granted on an opening the one gave (stage 3).' },
    everyS: num('At most one in this many seconds.'),
    clearTicks: int("Never within this many live ticks of a blow of the partner's, either side."),
    windTicks: int('Its wind-up in sight this many live ticks (8 at least).'),
    inTicksMax: int('The granted guard moves in for at most this many live ticks.'),
    speed: num('... at this speed, units a second.'),
    kinds: { type: 'array', items: { type: 'string', enum: ['light', 'medium'] }, description: 'What it may be: a light or a medium.' },
    worthMul: num("Its worth, as a share of a principal's blow of its strength."),
    reelTicks: int('He reels at most this long from it.')
  },
  additionalProperties: false,
  patternProperties: { '^_': true },
  description: "The interjection (Game Design's empress-guards.md section 5)."
};
fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
console.log('tools/schemas/director-interrupts.schema.json: ring.interject');
