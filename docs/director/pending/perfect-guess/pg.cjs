// pg.cjs <checkout root> [--check]: the AI's perfect block against a charged heavy, by guessing (Game Design's eleventh
// round, docs/design/brawl-second-pass.md, item 3: "the AI never reacts to a release").
//   - As a heavy's charge starts, the AI it is aimed at decides once whether to try (its level's brawl.chargeGuess:
//     0.1, 0.3, 0.5) and picks the live tick of its guard press across the charge (brawl.heavy.charge.guessTicks, as
//     the charge's own count from its wind-up). Both are keyed draws: the sim's stream is untouched.
//   - It presses on that tick if he still holds the charge; a release before it drops the guess. So no AI press
//     against a charge ever follows its release.
//   - At the release the blow's perfect-block mark is judged afresh. On main a mark made as the heavy's wind-up ended
//     (the AI's reaction to the visible wind-up) stayed on the blow however long he then held it: the AI knew. Now a
//     press counts only if it came before the release and falls inside the perfect window when the blow lands (the
//     heavy's window and early tolerance, 14 ticks): for the AI its guess alone; for a player his last fresh guard
//     press, free of the lockout. A player may guess too.
//   - The charged blow is never weighed by the AI's reaction (DirInterrupt._aiBlocks), and the AI's guard press after
//     a release never marks it (DirInterrupt.guardPress).
// Works on main, or on main with the return fix (the two new slots go at END, whatever END is).
// Every anchor is exact text; the script stops at the first missing. --check reads every anchor and writes nothing.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node pg.cjs <checkout root> [--check]');
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
  t = fn(rep, t) || t;
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}

edit('sim/director/brawl.gd', (rep, t0) => {
  const m = t0.match(/\nconst END: int = BASE \+ (\d+)\n/g);
  if (!m || m.length !== 1) throw new Error('brawl.gd: no single END slot');
  const n = Number(/(\d+)/.exec(m[0])[1]);
  rep(`const END: int = BASE + ${n}\n`,
      `const GUESS_AT: int = BASE + ${n}   # the live tick the AI's guessed guard press against his rival's charge is due; 0 none\n` +
      `const GUESS_P: int = BASE + ${n + 1}    # S.tick of that press, once made, until the release; 0 none\n` +
      `const END: int = BASE + ${n + 2}\n`);
  rep('\t\t\t_repiece(S, ex, f, 2, "heavyHeld")   # it is a charge from here: its piece is the held cell\'s\n',
      '\t\t\t_repiece(S, ex, f, 2, "heavyHeld")   # it is a charge from here: its piece is the held cell\'s\n' +
      '\t\t\t_guessCharge(S, ex, f)   # the AI it is aimed at guesses the release (the eleventh round)\n');
  rep('\tif kind == BIG and _g(f, CHG) > 0:\n',
      '\tif kind == BIG and _g(f, CHG) > 0:\n' +
      '\t\t_guessTick(S, ex, f, now)\n');
  rep('\t\t\tb.args["charged"] = true\n',
      '\t\t\tb.args["charged"] = true\n' +
      '\t\t\tb.args.o["weighed"] = true   # the AI never reacts to a release: it guessed, or it didn\'t\n' +
      '\t\t\tb.args.o["perfect"] = _guessed(S, o, lead)   # judged again at the release: a mark made as the wind-up ended, before he held on, does not carry over\n' +
      '\t\t\t_s(o, GUESS_AT, 0)\n' +
      '\t\t\t_s(o, GUESS_P, 0)\n');
  rep('## His parked wound blow goes: it lands `lead` live ticks from now.',
      '## The AI against a charge (brawl-second-pass.md, the eleventh round, item 3): it never reacts to the release. As\n' +
      '## f\'s charge starts, the AI it is aimed at decides once whether to try (its level\'s brawl.chargeGuess) and picks the\n' +
      '## live tick of its guard press across the charge (charge.guessTicks, counted as the charge\'s n). Keyed draws.\n' +
      'static func _guessCharge(S: SimState, ex, f) -> void:\n' +
      '\tvar o = ex.D if f == ex.A else ex.A\n' +
      '\t_s(o, GUESS_AT, 0)\n' +
      '\t_s(o, GUESS_P, 0)\n' +
      '\tif o.ai == null:\n' +
      '\t\treturn\n' +
      '\tvar share: float = float(DirAI.lv().get("brawl", {}).get("chargeGuess", 0.0))\n' +
      '\tvar key: int = S.tick * 8 + S.fighters.find(o)\n' +
      '\tif share <= 0.0 or SimRng.keyed(int(S.game.seed), "ai.chargeGuess", key) >= share:\n' +
      '\t\treturn\n' +
      '\tvar gt: Array = cfg().heavy.charge.get("guessTicks", [33, 70])\n' +
      '\tvar span: int = maxi(1, int(gt[1]) - int(gt[0]) + 1)\n' +
      '\tvar t: int = int(gt[0]) + mini(span - 1, int(SimRng.keyed(int(S.game.seed), "ai.chargeGuessAt", key) * float(span)))\n' +
      '\t_s(o, GUESS_AT, _g(f, HOLD_AT) + t)\n\n\n' +
      '## The AI\'s guessed guard press comes due while f still holds the charge: it presses, and the tick is kept for the\n' +
      '## release to judge.\n' +
      'static func _guessTick(S: SimState, ex, f, now: int) -> void:\n' +
      '\tvar o = ex.D if f == ex.A else ex.A\n' +
      '\tvar at: int = _g(o, GUESS_AT)\n' +
      '\tif at <= 0 or now < at:\n' +
      '\t\treturn\n' +
      '\t_s(o, GUESS_AT, 0)\n' +
      '\tif o.stunTicks <= 0:\n' +
      '\t\t_s(o, GUESS_P, S.tick)\n' +
      '\t\tDirInterrupt.guardPress(S, o)\n\n\n' +
      '## True when o pressed guard before f\'s release, inside the perfect window when the blow lands lead ticks from now.\n' +
      '## The AI\'s only press that counts is its guess (its shares are its tries; its stance\'s other presses never perfect-\n' +
      '## block a charge). A player\'s is his last fresh guard press, free of the lockout: a player may guess too.\n' +
      'static func _guessed(S: SimState, o, lead: int) -> bool:\n' +
      '\tvar at: int = _g(o, GUESS_P) if o.ai != null else DirInterrupt.gi(o, DirInterrupt.GUARD_AT)\n' +
      '\tif at <= 0 or at > S.tick:\n' +
      '\t\treturn false\n' +
      '\tif o.ai == null and DirInterrupt.gi(o, DirInterrupt.PB_LOCK) > at:\n' +
      '\t\treturn false\n' +
      '\treturn float(S.tick + lead - at) <= DirInterrupt._window(o, "heavy", false) + 0.5\n\n\n' +
      '## His parked wound blow goes: it lands `lead` live ticks from now.');
});

edit('data/director/ai.json', rep => {
  rep('"perfectMul": 0.21, ', '"chargeGuess": 0.1, "perfectMul": 0.21, ');
  rep('"perfectMul": 0.15, ', '"chargeGuess": 0.3, "perfectMul": 0.15, ');
  rep('"perfectMul": 0.45, ', '"chargeGuess": 0.5, "perfectMul": 0.45, ');
});

edit('sim/director/interrupt.gd', rep => {
  rep('\tif b.op == "beamFire":\n\t\tb.args["perfect"] = true\n',
      '\tif f.ai != null and b.op == "strike" and bool(b.args.get("charged", false)):\n' +
      '\t\treturn false   # the AI never perfect-blocks a released charge: only its guess before the release counts (DirBrawl._guessed)\n' +
      '\tif b.op == "beamFire":\n\t\tb.args["perfect"] = true\n');
});

edit('data/director/interrupts.json', rep => {
  rep('        "aiReleaseTicks": 8\n      }', '        "aiReleaseTicks": 8,\n        "guessTicks": [33, 70]\n      }');
});

// the schemas (Tools'): the two new keys
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  for (const k of ['easy', 'medium', 'hard']) {
    const b = s.properties.levels.properties[k].properties.brawl;
    if (!b || !b.properties) throw new Error('director-ai schema: no brawl block for ' + k);
    b.properties.chargeGuess = { type: 'number', minimum: 0, maximum: 1, description: "The share of a rival's charged heavies the AI tries to perfect-block, by guessing the release (it never reacts to it)." };
  }
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: chargeGuess' + (check ? ' (checked)' : ''));
}
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const c = s.properties.brawl.properties.heavy.properties.charge;
  if (!c || !c.properties) throw new Error('director-interrupts schema: no heavy.charge');
  c.properties.guessTicks = { type: 'array', items: { type: 'integer', minimum: 0 }, minItems: 2, maxItems: 2, description: "The span, in the charge's own live ticks from its wind-up, across which the AI picks the tick of its guessed guard press." };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: heavy.charge.guessTicks' + (check ? ' (checked)' : ''));
}
