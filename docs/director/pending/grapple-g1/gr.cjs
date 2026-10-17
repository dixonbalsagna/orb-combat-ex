// gr.cjs: the grapple's director side, slice G1 (docs/director/grapple-director.md; Game Design's docs/design/grapple.md),
// behind a switch (grapple.enabled, false): with it off, play is the same to the bit.
//   node gr.cjs <checkout root> [--check]
// Copies files/sim/director/pulse.gd and grapple.gd (DirPulse, DirGrapple) and their .uid files into the checkout, then hooks them in:
//   sim/director/brawl.gd: X, Y and B in a tell or a clinch are spent (takes); the grapple's tick before the brawl's;
//     no boost-out and no walk-out in a clinch; a blow that lands in a catch's tell stops it; a brawl's end ends the
//     clinch; the AI's brawl input gives way to the grapple's.
//   sim/director/interrupt.gd: a fighter in a catch or a clinch has no guard press, context, reversal or dodge (only the
//     burst breaks it); A in a brawl is the grapple's, not an empty press; the AI weighs no perfect block in one.
//   data/director/interrupts.json: the grapple block (Game Design's section 8, the keys G1 reads).
//   data/director/ai.json: brawl.grapple by level (catch, pummel, tech).
//   tools/schemas/director-interrupts.schema.json and director-ai.schema.json (Tools'): the same keys.
// Every anchor is exact text; the script stops at the first missing. --check reads every anchor and writes nothing.
// It goes with or without the launcher window (la.cjs) and the levers (window 2), in any order.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node gr.cjs <checkout root> [--check]');
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
  fn(rep, t);
  if (rel.endsWith('.json')) JSON.parse(t);
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
for (const f of ['pulse.gd', 'grapple.gd', 'pulse.gd.uid', 'grapple.gd.uid']) {   // the .uid files are the ones the gates ran with
  const to = path.join(root, 'sim/director', f);
  if (fs.existsSync(to)) throw new Error('sim/director/' + f + ' exists already');
  if (!check) fs.copyFileSync(path.join(__dirname, 'files/sim/director', f), to);
  console.log('sim/director/' + f + (check ? ': new (checked)' : ': new'));
}

edit('sim/director/brawl.gd', rep => {
  rep('\tif ex.branch != "" or ex.cancel or _setPiece(ex):\n\t\treturn true   # a set piece is playing: the press is spent\n',
      '\tif ex.branch != "" or ex.cancel or _setPiece(ex):\n\t\treturn true   # a set piece is playing: the press is spent\n' +
      '\tif DirGrapple.takes(S, f, kind):\n\t\treturn true   # a catch\'s tell or a clinch: X, Y and B are spent (vicious blows are G2\'s)\n');
  rep('\tvar said: bool = ex.tag != "ZIP"   # a zip\'s ticks in reach were never announced as a brawl: nothing ends\n',
      '\tDirGrapple.over(S, ex, why)   # a catch or a clinch ends with the brawl\n' +
      '\tvar said: bool = ex.tag != "ZIP"   # a zip\'s ticks in reach were never announced as a brawl: nothing ends\n');
  rep('\tvar c: Dictionary = cfg()\n\tvar now: int = _now(S)\n\t_inTick = true\n',
      '\tvar c: Dictionary = cfg()\n\tvar now: int = _now(S)\n' +
      '\tDirGrapple.tick(S, ex)   # the catch, the clinch and their exits (DirGrapple)\n' +
      '\tif S.dirS.ex != ex or ex.branch != "":\n\t\treturn\n' +
      '\t_inTick = true\n');
  rep('\t\tif ex.t > SimConst.DT * 1.5 and f.input.sprint and f.stunTicks <= 0 and not sureAgainst(ex, f)',
      '\t\tif ex.t > SimConst.DT * 1.5 and f.input.sprint and f.stunTicks <= 0 and not DirGrapple.holds(f) and not sureAgainst(ex, f)');
  rep('\tif not quiet(ex) and _g(ex.A, DBL_AT) == 0 and ex.t > SimConst.DT * 1.5 and _parting(S, ex):\n',
      '\tif not quiet(ex) and not DirGrapple.holds(ex.A) and _g(ex.A, DBL_AT) == 0 and ex.t > SimConst.DT * 1.5 and _parting(S, ex):\n');
  rep('\tif armour:\n\t\tif energy != "":\n\t\t\t_eLand(S, ex, f, o, energy, "armour")\n',
      '\tif DirGrapple.telling(o):\n\t\tDirGrapple.stopped(S, ex, o)   # a blow that lands in a catch\'s tell stops it: blows beat grabs\n' +
      '\tif armour:\n\t\tif energy != "":\n\t\t\t_eLand(S, ex, f, o, energy, "armour")\n');
  rep('\tif _g(ex.A, DBL_AT) > 0:\n\t\treturn   # the double hit is on its way: nothing it presses counts\n',
      '\tif _g(ex.A, DBL_AT) > 0:\n\t\treturn   # the double hit is on its way: nothing it presses counts\n' +
      '\tif DirGrapple.aiInput(S, ex, f, o, i):\n\t\treturn   # a catch\'s tell or a clinch is the grapple\'s, or it catches now\n');
});

edit('sim/director/interrupt.gd', rep => {
  rep('\tvar order: Array = [ex.D, ex.A] if ex != null else S.fighters\n\tfor f in order:\n\t\tif _human(f) and f.input.guardPress:\n\t\t\tguardPress(S, f)\n\tfor f in order:\n\t\tif f.input.context and f.stunTicks <= 0',
      '\tvar order: Array = [ex.D, ex.A] if ex != null else S.fighters\n' +
      '\tvar fr: Array = DirGrapple.freeOf(S, order)   # in a catch or a clinch his presses are the grapple\'s, and only a burst breaks it\n' +
      '\tfor f in fr:\n\t\tif _human(f) and f.input.guardPress:\n\t\t\tguardPress(S, f)\n\tfor f in fr:\n\t\tif f.input.context and f.stunTicks <= 0');
  rep('\tfor f in order:\n\t\tif not _human(f):\n\t\t\tcontinue\n\t\tvar cell: String = ""\n',
      '\tfor f in fr:\n\t\tif not _human(f):\n\t\t\tcontinue\n\t\tvar cell: String = ""\n');
  rep('\t\telif f.input.context and not f.input.guard and f.act.mode != 1:\n',
      '\t\telif f.input.context and not f.input.guard and f.act.mode != 1 and not DirGrapple.takesA(S, f):   # in a brawl, A is the grapple\'s\n');
  rep('\tfor f in order:\n\t\tif not taken and _human(f) and f.input.context and f.input.guard:\n',
      '\tfor f in fr:\n\t\tif not taken and _human(f) and f.input.context and f.input.guard:\n');
  rep('\tfor f in order:\n\t\tif not taken and _human(f) and f.input.dodge:\n',
      '\tfor f in fr:\n\t\tif not taken and _human(f) and f.input.dodge:\n');
  rep('\tfor f in [ex.D, ex.A]:\n\t\tif f.ai == null or f.stunTicks > 0:\n\t\t\tcontinue\n\t\tvar b = _windowBeat(S, ex, f)\n',
      '\tfor f in [ex.D, ex.A]:\n\t\tif f.ai == null or f.stunTicks > 0 or DirGrapple.holds(f):\n\t\t\tcontinue\n\t\tvar b = _windowBeat(S, ex, f)\n');
});

const NOTE = "The grapple's director side, slice G1 (sim/director/grapple.gd; Game Design's docs/design/grapple.md; docs/director/grapple-director.md). enabled: false, A in a brawl is as before (an empty press). catch: tell, the ticks from A's press in a brawl to its landing (a blow that lands on him in them stops it); tech, the caught fighter's A within this many ticks of the landing breaks it; whiffOpen, a catch out of reach leaves him open this long. clinch: max ticks from the tie-up; a pulse every `pulse` ticks; an A inside `window` of one claims it, sharp inside `sharp`; the grip runs from -grip to grip; leadGuard, the catcher's lead on a rival who guards, winds or charges; partBh, both part this far past striking distance at the time and the tech; pushBh and pushFirstMove, the push-off's parting and the pusher's first move; aiOffsets, the AI's pummels off the pulse (never sharp). throw: acrossBh, a throw across is a knock-back this long; upBh and upOpen, a throw up lifts him this far and he is open this long; bury, a throw down to the ground buries him this long (both openings). lockout: the ticks a grab is refused after each attempt, and for both after a clinch ends with nobody thrown; noRegrab: a thrown fighter can't be grabbed for this long. G2 adds Game Design's vicious, damage, wear, lead and pin, brace, braceRest and carry.";
edit('data/director/interrupts.json', rep => {
  rep('\n  "zip": {\n',
      '\n  "grapple": {\n' +
      '    "_note": ' + JSON.stringify(NOTE) + ',\n' +
      '    "enabled": false,\n' +
      '    "catch": {"tell": 10, "tech": 8, "whiffOpen": 20},\n' +
      '    "clinch": {"max": 90, "pulse": 20, "window": 4, "sharp": 2, "grip": 2, "leadGuard": 1, "partBh": 1.5, "pushBh": 3, "pushFirstMove": 20, "aiOffsets": [-4, -3, 3, 4]},\n' +
      '    "throw": {"acrossBh": 8, "upBh": 4, "upOpen": 16, "bury": 20},\n' +
      '    "lockout": 90,\n' +
      '    "noRegrab": 120\n' +
      '  },\n  "zip": {\n');
});

edit('data/director/ai.json', rep => {
  rep('"perfectMul": 0.21, ', '"grapple": {"catch": 0.02, "pummel": 0.4, "tech": 0.15}, "perfectMul": 0.21, ');
  rep('"perfectMul": 0.15, ', '"grapple": {"catch": 0.04, "pummel": 0.65, "tech": 0.3}, "perfectMul": 0.15, ');
  rep('"perfectMul": 0.45, ', '"grapple": {"catch": 0.06, "pummel": 0.85, "tech": 0.45}, "perfectMul": 0.45, ');
});

{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  if (s.properties.grapple) throw new Error('director-interrupts schema: grapple exists already');
  const num = d => ({ type: 'number', minimum: 0, description: d });
  const int = d => ({ type: 'integer', minimum: 0, description: d });
  const obj = (d, p) => ({ type: 'object', description: d, properties: p, required: Object.keys(p), additionalProperties: false });
  s.properties.grapple = {
    type: 'object', description: "The grapple's director side (sim/director/grapple.gd): the catch, the clinch, the throws, the lockout.",
    properties: {
      _note: { type: 'string' },
      enabled: { type: 'boolean', description: 'False: A in a brawl is as before.' },
      catch: obj('The catch.', { tell: int("Ticks from A's press to the catch's landing."), tech: int("The caught fighter's A within this many ticks of the landing breaks it."), whiffOpen: int('A catch out of reach leaves him open this long.') }),
      clinch: obj('The clinch.', {
        max: int('Its length at most, from the tie-up.'), pulse: int('A pulse every this many ticks.'), window: int('An A inside this many ticks of a pulse claims it.'),
        sharp: int('... and is sharp inside this many.'), grip: int('The grip runs from minus this to this.'), leadGuard: int("The catcher's lead on a rival who guards, winds or charges."),
        partBh: num('Both part this far past striking distance, in body heights, at the time and the tech.'), pushBh: num("The push-off's parting, in body heights."),
        pushFirstMove: int("The pusher's first move, in ticks."), aiOffsets: { type: 'array', items: { type: 'integer' }, minItems: 1, description: "The AI's pummels this far off the pulse (never sharp)." } }),
      throw: obj('The throws.', { acrossBh: num('A throw across: a knock-back this long, in body heights.'), upBh: num('A throw up lifts him this far, in body heights.'), upOpen: int('... and he is open this long.'), bury: int('A throw down to the ground buries him this long.') }),
      lockout: int('A grab is refused this long after each attempt, and for both after a clinch ends with nobody thrown.'),
      noRegrab: int("A thrown fighter can't be grabbed for this long.")
    },
    required: ['enabled', 'catch', 'clinch', 'throw', 'lockout', 'noRegrab'], additionalProperties: false
  };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: grapple' + (check ? ' (checked)' : ''));
}
{
  const sp = path.join(root, 'tools/schemas/director-ai.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  for (const k of ['easy', 'medium', 'hard']) {
    const b = s.properties.levels.properties[k].properties.brawl;
    if (!b || !b.properties) throw new Error('director-ai schema: no brawl block for ' + k);
    const sh = d => ({ type: 'number', minimum: 0, maximum: 1, description: d });
    b.properties.grapple = { type: 'object', description: "The AI's grapple (sim/director/grapple.gd).", properties: {
      catch: sh('The share of a rival\'s guards (each 30 ticks of one) and seen heavy wind-ups it catches.'),
      pummel: sh('The share of pulses it pummels on.'),
      tech: sh('The share of catches it techs.') }, required: ['catch', 'pummel', 'tech'], additionalProperties: false };
  }
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-ai.schema.json: brawl.grapple' + (check ? ' (checked)' : ''));
}
