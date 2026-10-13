// r2.cjs <copy root>: the nine cells, pass 2 (brawl-second-pass.md sections 3 and 15), on top of pass 1.
//  - A held Y is the charged medium: charged from medium.charge.fromTicks of its hold, full at fullTicks, it goes
//    landTicks after he lets go and by itself at maxTicks. Worth charge.worth's two ends, for charge.ki in all. No
//    armour: a medium or a heavier blow that lands on him ends it, and a light does not. Clean, he reels for
//    charge.reelTicks; at full it closes: he staggers for charge.staggerTicks as from a flurry's close, which is an
//    opening. It ends a heavy that is winding or charging, always.
//  - No blow of a held X (its burst, its floor pace) can be perfect-blocked.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
function edit(rel, fn) {
  const p = path.join(root, rel);
  let t = fs.readFileSync(p, 'utf8');
  const crlf = t.includes('\r\n');
  if (crlf) t = t.replace(/\r\n/g, '\n');
  const rep = (a, b, times) => {
    const n = t.split(a).length - 1;
    if (n !== (times || 1)) throw new Error(rel + ': expected ' + (times || 1) + ' match, got ' + n + ' for: ' + a.slice(0, 80));
    t = t.split(a).join(b);
  };
  fn(rep);
  fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + ': ok');
}
const L = (...lines) => lines.join('\n') + '\n';

edit('sim/director/brawl.gd', rep => {
  // ---- which wound blows charge
  rep('## The level of the button that throws a blow of that kind: X, Y or B.\n',
    L(
    '## Whether f\'s wound blow on its way is one that charges when its button is held: a heavy, or the fist\'s medium',
    '## (the blast and the launcher never do).',
    'static func _charges(f, kind: int) -> bool:',
    '\tif _g(f, FLAV) != 0:',
    '\t\treturn false',
    '\treturn kind == BIG or (kind == MEDIUM and cfg().medium.has("charge"))',
    '',
    '',
    '## The charge\'s numbers for a blow of that kind: heavy.charge, or medium.charge.',
    'static func _chg(kind: int) -> Dictionary:',
    '\treturn cfg().heavy.charge if kind == BIG else cfg().medium.charge',
    '',
    '') + '## The level of the button that throws a blow of that kind: X, Y or B.\n');
  // ---- the wind-up's read
  rep(L(
    '\tvar ch: Dictionary = cfg().heavy.charge',
    '\tvar share: float = clampf(float(n - int(ch.fromTicks)) / maxf(1.0, float(int(ch.fullTicks) - int(ch.fromTicks))), 0.0, 1.0) if (kind == BIG and _g(f, CHG) > 0) else 0.0'),
  L(
    '\tvar share: float = 0.0',
    '\tif _g(f, CHG) > 0 and _charges(f, kind):',
    '\t\tvar ch: Dictionary = _chg(kind)',
    '\t\tshare = clampf(float(n - int(ch.fromTicks)) / maxf(1.0, float(int(ch.fullTicks) - int(ch.fromTicks))), 0.0, 1.0)'));
  rep('## it began. left: the live ticks until it lands (-1 while he holds it past its end). armoured: a heavy\'s is, from its\n## first tick. charge: 0 before a heavy\'s charge begins, then its share of full (1 at the flash).\n',
      '## it began. left: the live ticks until it lands (-1 while he holds it past its end). armoured: a heavy\'s is, from its\n## first tick. charge: 0 before a charge begins (a heavy\'s, or a medium\'s), then its share of full (1 at the flash).\n');
  // ---- the button at the wind-up's end
  rep(L(
    '\tvar ch: Dictionary = c.heavy.charge',
    '\tif kind == BIG and _g(f, CHG) > 0:',
    '\t\tif _g(f, CHG) == 1 and n >= int(ch.fullTicks):',
    '\t\t\t_s(f, CHG, 2)',
    '\t\t\tvar fl = _ev(S, f, "charge_full", "", "b")',
    '\t\t\tfl.n = S.tick'),
  L(
    '\tvar chg: bool = _charges(f, kind)',
    '\tvar cell: String = "b" if kind == BIG else "y"',
    '\tvar ch: Dictionary = _chg(kind) if chg else c.heavy.charge',
    '\tif chg and _g(f, CHG) > 0:',
    '\t\tif _g(f, CHG) == 1 and n >= int(ch.fullTicks):',
    '\t\t\t_s(f, CHG, 2)',
    '\t\t\tvar fl = _ev(S, f, "charge_full", "", cell)',
    '\t\t\tfl.n = S.tick'));
  rep(L(
    '\t\tvar more: float = float(ch.ki) - float(c.heavy.ki)',
    '\t\tif kind == BIG and f.ki >= more:',
    '\t\t\tf.ki -= more   # the charge\'s price, over the tap\'s',
    '\t\t\t_s(f, CHG, 1)',
    '\t\t\tvar cs = _ev(S, f, "windup", "charge", "b")',
    '\t\t\tcs.n = S.tick + int(ch.fullTicks) - n   # the tick of its flash',
    '\t\t\t_repiece(S, ex, f, 2, "heavyHeld")   # it is a charge from here: its piece is the held cell\'s',
    '\t\telse:',
    '\t\t\t_letGo(S, ex, f, 0, -1.0)   # a medium has no charge yet, and a heavy he can\'t pay for: it goes by itself, a tap'),
  L(
    '\t\tvar more: float = float(ch.ki) - float(w.ki)',
    '\t\tif chg and f.ki >= more:',
    '\t\t\tf.ki -= more   # the charge\'s price, over the tap\'s',
    '\t\t\t_s(f, CHG, 1)',
    '\t\t\tvar cs = _ev(S, f, "windup", "charge", cell)',
    '\t\t\tcs.n = S.tick + int(ch.fullTicks) - n   # the tick of its flash',
    '\t\t\t_repiece(S, ex, f, 2 if kind == BIG else 1, "heavyHeld" if kind == BIG else "mediumHeld")   # it is a charge from here: its piece is the held cell\'s (the mediums that need a long wind-up are thrown only here)',
    '\t\telse:',
    '\t\t\t_letGo(S, ex, f, 0, -1.0)   # the blast has no charge, and a charge he can\'t pay for: it goes by itself, a tap'));
  rep('## decision point goes by itself, at a tap\'s strength, and so does the blast. A heavy still down there is charging:\n## full at charge.fullTicks, it goes charge.landTicks after he lets go, and by itself at charge.maxTicks. A launcher\n',
      '## decision point is charging, as a heavy is (the blast goes by itself, at a tap\'s strength): full at its\n## charge.fullTicks, it goes charge.landTicks after he lets go, and by itself at charge.maxTicks. A launcher\n');
  // ---- the release
  rep(L(
    '\t\tif charge >= 0.0:',
    '\t\t\tvar ch: Dictionary = c.heavy.charge',
    '\t\t\tb.args["charge"] = charge',
    '\t\t\tb.args["charged"] = true',
    '\t\t\tb.args["aim"] = _quarter(f, o)',
    '\t\t\tb.args["dmg"] = lerpf(float(ch.worth[0]), float(ch.worth[1]), charge) * _unit()',
    '\t\t\tif charge >= 1.0:'),
  L(
    '\t\tif charge >= 0.0:',
    '\t\t\tvar ch: Dictionary = _chg(_g(f, KIND))',
    '\t\t\tb.args["charge"] = charge',
    '\t\t\tb.args["charged"] = true',
    '\t\t\tb.args["aim"] = _quarter(f, o)',
    '\t\t\tb.args["dmg"] = lerpf(float(ch.worth[0]), float(ch.worth[1]), charge) * _unit()',
    '\t\t\tif charge >= 1.0 and _g(f, KIND) == BIG:'));
  rep('## His parked wound blow goes: it lands `lead` live ticks from now. charge: -1 for a tap; else the heavy\'s charge, 0 to\n',
      '## His parked wound blow goes: it lands `lead` live ticks from now. charge: -1 for a tap; else its charge, 0 to\n');
  // ---- the contact: a charged medium ends a heavy always, reels longer, and closes at full
  rep('\t\telif kind == MEDIUM and now - _g(o, HOLD_AT) >= int(c.heavy.armour.mediumUntilTicks):\n\t\t\tarmour = true\n',
      '\t\telif kind == MEDIUM and not bool(a.get("charged", false)) and now - _g(o, HOLD_AT) >= int(c.heavy.armour.mediumUntilTicks):\n\t\t\tarmour = true   # (a charged medium ends a heavy always: no armour holds it)\n');
  rep(L(
    '\tvar closing: bool = _closes(S, ex, f)',
    '\t_s(f, LL_AT, S.tick)',
    '\tif closing:'),
  L(
    '\tvar full: bool = kind == MEDIUM and bool(a.get("charged", false)) and float(a.get("charge", 0.0)) >= 1.0   # a medium charged to full closes, whatever his run and the rival\'s close guard',
    '\tvar closing: bool = full or _closes(S, ex, f)',
    '\t_s(f, LL_AT, S.tick)',
    '\tif closing:'));
  rep(L(
    '\t\t_stagger(S, ex, f, o, int(c.flurry.staggerTicks), "flurry", true)   # the close is an opening',
    '\t\tSimEvents.feed(S, f.name + " CLOSES", o.name + " staggers in place for " + str(int(c.flurry.staggerTicks)) + " ticks")'),
  L(
    '\t\tvar cst: int = int(c.medium.charge.staggerTicks) if full else int(c.flurry.staggerTicks)',
    '\t\t_stagger(S, ex, f, o, cst, "flurry", true)   # the close is an opening',
    '\t\tSimEvents.feed(S, f.name + " CLOSES", o.name + " staggers in place for " + str(cst) + " ticks" + (": a medium charged to full" if full else ""))'));
  rep('\tvar reel: int = (int(c.energy.reach.blast.reelTicks) if energy == "blast" else int(c.medium.reelTicks)) if kind == MEDIUM else ',
      '\tvar reel: int = (int(c.energy.reach.blast.reelTicks) if energy == "blast" else (int(c.medium.charge.reelTicks) if bool(a.get("charged", false)) else int(c.medium.reelTicks))) if kind == MEDIUM else ');
  // ---- a held X's blows can't be perfect-blocked
  rep(L(
    '\tif floor:',
    '\t\targs["floor"] = true   # a blow of a held X\'s floor pace'),
  L(
    '\tif floor:',
    '\t\targs["floor"] = true   # a blow of a held X\'s floor pace',
    '\t\to2["noPerfect"] = true   # no blow of a held X can be perfect-blocked (section 15): its rhythm changes with every blow',
    '\t\to2["weighed"] = true'));
  rep(L(
    '\tif bool(extra.get("double", false)):',
    '\t\to2["stop"] = float(int(c.hitstop.heavy)) / DirData.TICKS_PER_SEC   # the double hit\'s two blows hold the clock as a heavy does'),
  L(
    '\tif extra.has("burst"):',
    '\t\to2["noPerfect"] = true   # no blow of a held X can be perfect-blocked (section 15)',
    '\t\to2["weighed"] = true',
    '\tif bool(extra.get("double", false)):',
    '\t\to2["stop"] = float(int(c.hitstop.heavy)) / DirData.TICKS_PER_SEC   # the double hit\'s two blows hold the clock as a heavy does'));
});

edit('sim/director/interrupt.gd', rep => {
  rep(L(
    '\t\tif b.done or b.op != "strike" or b.args.d != role or b.args.o == null or b.args.get("sure", false):',
    '\t\t\tcontinue   # (a riposte and a reversal\'s heavy can\'t be blocked: melee-press-feel.md section 9f)'),
  L(
    '\t\tif b.done or b.op != "strike" or b.args.d != role or b.args.o == null or b.args.get("sure", false) or b.args.o.get("noPerfect", false):',
    '\t\t\tcontinue   # (a riposte and a reversal\'s heavy can\'t be blocked: melee-press-feel.md section 9f; a held X\'s blows have no window: brawl-second-pass.md section 15)'));
  rep(L(
    '\t\tif b.done or b.op != "strike" or b.args.d != role or b.args.o == null:',
    '\t\t\tcontinue',
    '\t\tif _window(f, String(b.args.o.get("class", "")), ex.kind == "heavy") < 0.0:'),
  L(
    '\t\tif b.done or b.op != "strike" or b.args.d != role or b.args.o == null or b.args.o.get("noPerfect", false):',
    '\t\t\tcontinue   # (a blow with no window is no wind-up to miss)',
    '\t\tif _window(f, String(b.args.o.get("class", "")), ex.kind == "heavy") < 0.0:'));
});

edit('data/director/interrupts.json', rep => {
  rep('      "guardChipMul": 2,\n      "reachBh": 0.5\n    },\n',
      '      "guardChipMul": 2,\n      "reachBh": 0.5,\n      "charge": {\n        "fromTicks": 16,\n        "fullTicks": 24,\n        "landTicks": 4,\n        "maxTicks": 40,\n        "worth": [3, 4],\n        "ki": 4,\n        "reelTicks": 10,\n        "staggerTicks": 12\n      }\n    },\n');
});
