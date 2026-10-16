// ret.cjs <checkout root>: the return from a send (Orb, 2026-10-15: "they rushed back at me at full speed and got some
// cheap hits"). A fighter who comes free after a launch, a knock-back or a fall is returning, for bands.return.forTicks
// at most, until his first blow back is thrown.
//   - his approach back is readable: it lasts bands.return.minTicks at least, it crouches bands.return.windTicks before it
//     moves (a far approach too), and it says so: a cue "return" (text the approach's kind, target the rival, amount the
//     crouch, n the move), for Camera to catch him and for VFX and Animation to show him coming
//   - his first blow back has a tell: bands.return.firstWindTicks more to its contact, with a windup cue (text "return"),
//     so the defender has a window to strike first, to guard or to perfect-block. It is never a free hit on arrival.
// Every anchor is exact text; the script stops at the first missing. --check reads every anchor and writes nothing (two
// of its steps edit brawl.gd; with --check the second reads the file as it was).
// Usage: node ret.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node ret.cjs <checkout root> [--check]');
const check = opts.includes('--check');
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
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
edit('sim/director/brawl.gd', rep => {
  rep('const END: int = BASE + 98\n',
      'const RET_N: int = BASE + 98      # 1 while he is returning from a send: free again, his first blow back still to come (bands.return)\n' +
      'const RET_AT: int = BASE + 99     # the live tick he came free after the send\n' +
      'const END: int = BASE + 100\n');
  rep('\t\telif _g(f, SENT) == 1 and f.state == "free" and f.stunTicks <= 0:\n\t\t\t_s(f, SENT, 0)\n\t\t\t_s(f, MOVE_AT, S.tick + lock)\n',
      '\t\telif _g(f, SENT) == 1 and f.state == "free" and f.stunTicks <= 0:\n\t\t\t_s(f, SENT, 0)\n\t\t\t_s(f, MOVE_AT, S.tick + lock)\n' +
      '\t\t\tif bool(_rcfg().get("enabled", false)):\n\t\t\t\t_s(f, RET_N, 1)   # he is returning: his approach back and his first blow back are read (bands.return)\n\t\t\t\t_s(f, RET_AT, _now(S))\n');
  rep('## True while the first move is the rival\'s: f was sent, and is free for fewer than firstMove.lockTicks.\n',
      '## The return\'s numbers (data/director/interrupts.json bands.return).\nstatic func _rcfg() -> Dictionary:\n\treturn DirBands.data().get("return", {})\n\n\n' +
      '## True while f is returning from a send: free again after a launch, a knock-back or a fall, his first blow back still to\n## come, and for bands.return.forTicks at most.\nstatic func returning(S: SimState, f) -> bool:\n\tif _g(f, RET_N) != 1:\n\t\treturn false\n\tvar rc: Dictionary = _rcfg()\n\tif not bool(rc.get("enabled", false)) or _now(S) - _g(f, RET_AT) > int(rc.get("forTicks", 600)):\n\t\treturn false\n\treturn true\n\n\n' +
      '## True while the first move is the rival\'s: f was sent, and is free for fewer than firstMove.lockTicks.\n');
  rep('\tlead += d\n\t_s(f, CLOSE_N, d)\n',
      '\tlead += d\n' +
      '\tif returning(S, f):\n' +
      '\t\t# His first blow back from a send has a tell: the defender has a window to strike first, to guard or to perfect-block.\n' +
      '\t\tvar rw: int = int(_rcfg().get("firstWindTicks", 10))\n' +
      '\t\tlead += rw\n' +
      '\t\t_s(f, RET_N, 0)\n' +
      '\t\tvar rwe = _ev(S, f, "windup", "return", _cellOf(st))\n' +
      '\t\trwe.target = float(S.fighters.find(o))\n' +
      '\t\trwe.n = S.tick + lead\n' +
      '\t\trwe.dur = float(rw)\n' +
      '\t_s(f, CLOSE_N, d)\n');
});
edit('sim/director/brawl.gd', rep => {
  rep('## True while the first move is the rival\'s: f was sent, and is free for fewer than firstMove.lockTicks.\n',
      '## His first blow back from a send in a planned exchange (a far charge\'s arrival keeps its template): every beat of it\n## waits bands.return.firstWindTicks, and its window with it, and the windup cue (text "return") shows the tell.\nstatic func returnTell(S: SimState, ex, A, D) -> void:\n\tvar rw: int = int(_rcfg().get("firstWindTicks", 10))\n\tvar first: float = INF\n\tfor b in ex.beats:\n\t\tif not b.done:\n\t\t\tb.t += float(rw) / DirData.TICKS_PER_SEC\n\t\t\tif b.op == "strike" or b.op == "chainStrike":\n\t\t\t\tfirst = minf(first, b.t)\n\tif ex.windowStart >= 0.0:\n\t\tex.windowStart += float(rw) / DirData.TICKS_PER_SEC\n\t_s(A, RET_N, 0)\n\tvar e = _ev(S, A, "windup", "return", "")\n\te.target = float(S.fighters.find(D))\n\te.n = S.tick + (int(round((first - ex.t) * DirData.TICKS_PER_SEC)) if first < INF else rw)\n\te.dur = float(rw)\n\n\n' +
      '## True while the first move is the rival\'s: f was sent, and is free for fewer than firstMove.lockTicks.\n');
});
edit('sim/director/exchange.gd', rep => {
  rep('\tif kind != "sig" and not DirBury.followUp(S, A, SimRoster.opp(S, A)) and DirBands.farPressNow(S, A, KIND.find(kind), entry):\n',
      '\tif kind != "sig" and DirBands.meetReturn(S, A, KIND.find(kind), entry):\n\t\treturn   # his rival is on his way back from a send: they meet in the middle (bands.return)\n' +
      '\tif kind != "sig" and not DirBury.followUp(S, A, SimRoster.opp(S, A)) and DirBands.farPressNow(S, A, KIND.find(kind), entry):\n');
  rep('\t\tvar fav: String = DirMelee.planMelee(S, ex)\n',
      '\t\tvar fav: String = DirMelee.planMelee(S, ex)\n\t\tif DirBrawl.returning(S, A):\n\t\t\tDirBrawl.returnTell(S, ex, A, D)   # his first blow back from a send has a tell (bands.return)\n');
});
edit('sim/director/bands.gd', rep => {
  rep('\tvar wind: int = int(c.lunge.get("windupTicks", {}).get(_weightName(weight), 0)) if (b == MID and not charge) else 0\n',
      '\tvar wind: int = int(c.lunge.get("windupTicks", {}).get(_weightName(weight), 0)) if (b == MID and not charge) else 0\n' +
      '\tvar ret: bool = DirBrawl.returning(S, A)\n' +
      '\tif ret:\n' +
      '\t\t# His approach back from a send (bands.return): long enough to read, and a crouch before it moves.\n' +
      '\t\tvar rc: Dictionary = c.get("return", {})\n' +
      '\t\tn = maxi(n, int(rc.get("minTicks", 40)))\n' +
      '\t\twind = maxi(wind, int(rc.get("windTicks", 10)))\n');
  rep('## A\'s press from the far band (a v2 slot with no opening).',
      '## A press of R\'s while his rival is returning from a send (bands.return), on his approach back and past its crouch, at\n' +
      '## least return.meetMinTicks before he arrives: the two meet in the middle, a trade (a clash for a heavy), as a far\n' +
      '## taunt that is answered does. So his arrival is never a free hit on a fighter who acted. False when it doesn\'t apply.\n' +
      'static func meetReturn(S: SimState, R, weight: int, entry: int) -> bool:\n' +
      '\tif not on() or S.dirS.ex != null or S.game.ko != null:\n\t\treturn false\n' +
      '\tvar k: int = who(S)\n\tif k < 0:\n\t\treturn false\n' +
      '\tvar T = S.fighters[k]\n' +
      '\tif T == R or not DirBrawl.returning(S, T) or DirInterrupt.gi(T, DirInterrupt.APPR_WIND) > 0:\n\t\treturn false\n' +
      '\tif DirInterrupt.gi(T, DirInterrupt.APPR_LEFT) < int(data().get("return", {}).get("meetMinTicks", 8)):\n\t\treturn false   # he is all but there: the press waits, as any\n' +
      '\tif (R.state != "free" and R.state != "charging") or R.stunTicks > 0:\n\t\treturn false\n' +
      '\tvar tw: int = DirInterrupt.gi(T, DirInterrupt.APPR_REQ) & 3\n' +
      '\tDirInterrupt.si(T, DirInterrupt.APPR_LEFT, 0)\n\tDirInterrupt.si(T, DirInterrupt.APPR_WIND, 0)\n\tDirInterrupt.si(T, DirInterrupt.APPR_REQ, tw)\n\tT.rush = null\n' +
      '\tmeet(S, R, T, weight, entry, S.tick)\n' +
      '\tSimFx.cue(S, R, "return_met", "", "")\n' +
      '\treturn true\n\n\n' +
      '## A\'s press from the far band (a v2 slot with no opening).');
  rep('\tif charge or b == MID:\n\t\t_startCue(S, A, D, ("charge_" if charge else "lunge_") + _weightName(weight), "charge" if charge else "lunge", wind, n)\n',
      '\tif charge or b == MID:\n\t\t_startCue(S, A, D, ("charge_" if charge else "lunge_") + _weightName(weight), "charge" if charge else "lunge", wind, n)\n' +
      '\tif ret:\n\t\t_startCue(S, A, D, "return", "charge" if charge else ("lunge" if b == MID else "far"), wind, n)   # for Camera to catch him, and VFX and Animation to show him coming\n');
});
// the data: a key inside the bands block (it is one JSON line in the file)
{
  const p = path.join(root, 'data/director/interrupts.json');
  let t = fs.readFileSync(p, 'utf8');
  const a = '"engageBh": 2.5,';
  const b = '"engageBh":2.5,';
  const at = t.includes(a) ? a : (t.includes(b) ? b : null);
  if (!at || t.split(at).length !== 2) throw new Error('interrupts.json: no single engageBh');
  t = t.replace(at, () => at + ' "return": {"enabled": true, "minTicks": 40, "windTicks": 10, "firstWindTicks": 10, "forTicks": 600, "meetMinTicks": 8, "_note": "The return from a send (Orb, 2026-10-15). A fighter free again after a launch, a knock-back or a fall is returning for forTicks at most, until his first blow back. His approach back lasts minTicks at least and crouches windTicks before it moves; his first blow back lands firstWindTicks later than it would, with a windup cue (text return). A press of his rival on that approach, past the crouch and meetMinTicks or more before he arrives, meets it in the middle."},');
  JSON.parse(t);
  if (!check) fs.writeFileSync(p, t);
  console.log('data/director/interrupts.json: bands.return' + (check ? ' (anchor ok)' : ''));
}
const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
const bands = s.properties.bands;
if (!bands || !bands.properties) throw new Error('no bands in the schema');
const int = d => ({ type: 'integer', minimum: 0, description: d });
bands.properties.return = {
  type: 'object',
  properties: {
    enabled: { type: 'boolean', description: 'The return from a send: a readable approach back and a tell on the first blow back.' },
    minTicks: int('His approach back lasts this many live ticks at least.'),
    windTicks: int('... and crouches this many before it moves.'),
    firstWindTicks: int('His first blow back lands this many live ticks later than it would, with a windup cue.'),
    forTicks: int('He is returning for this many live ticks at most after he comes free.'),
    meetMinTicks: int('A press of his rival on his approach back, this many live ticks or more before he arrives, meets it in the middle.')
  },
  additionalProperties: false,
  patternProperties: { '^_': true },
  description: 'The return from a send (Orb, 2026-10-15).'
};
if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
console.log('tools/schemas/director-interrupts.schema.json: bands.return' + (check ? ' (checked)' : ''));
