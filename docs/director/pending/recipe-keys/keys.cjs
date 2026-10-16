// keys.cjs <checkout root> mash|interject [--check]: Combat's two recipe keys read by the director
// (docs/combat/split-and-pieces.md sections 1 and 3). Every anchor is exact text; it stops at the first missing one.
//   mash       sim/director/brawl.gd: a mashed medium or heavy draws on the recipes' mediumMash or heavyMash (the grind,
//              the advance), else the tap's cell. Lands with Combat's recipes.split.json and Tools' two schema keys.
//   interject  sim/director/ring.gd (stage 3 of one versus many): the ring beat carries a piece from the recipes'
//              interject (a light) or interjectMedium (a medium; interject when there is none). Lands after stage 3.
// --check: reads every anchor and writes nothing.
const fs = require('fs');
const path = require('path');
const args = process.argv.slice(2);
const root = args[0];
const steps = args.slice(1).filter(a => !a.startsWith('--'));
const flags = args.slice(1).filter(a => a.startsWith('--'));
for (const fl of flags) if (fl !== '--check') throw new Error('unknown option: ' + fl);
for (const s of steps) if (s !== 'mash' && s !== 'interject') throw new Error('unknown step: ' + s + ' (mash or interject)');
if (!root || steps.length === 0) throw new Error('usage: node keys.cjs <root> mash|interject [--check]');
const check = flags.includes('--check');
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
  if (!check) fs.writeFileSync(p, crlf ? t.replace(/\n/g, '\r\n') : t);
  console.log(rel + (check ? ': anchors ok' : ': ok'));
}
if (steps.includes('mash')) {
  edit('sim/director/brawl.gd', rep => {
    rep('\tvar cell: String = "launcher" if lau else (("blast" if st == 1 else "bolt") if energy else ("heavy" if st == 2 else ("medium" if st == 1 else ("burstFloor" if floor else ("lightToward" if toward else ("flurry" if kind == FLURRY else "light"))))))\n',
        '\tvar cell: String = "launcher" if lau else (("blast" if st == 1 else "bolt") if energy else ("heavy" if st == 2 else ("medium" if st == 1 else ("burstFloor" if floor else ("lightToward" if toward else ("flurry" if kind == FLURRY else "light"))))))\n' +
        '\tif inFl and wound and not energy and not lau:\n' +
        '\t\tcell = _mashCell(cell)   # a mashed medium or heavy: the grind or the advance, when Combat\'s recipes name it\n');
    rep('## A cell\'s piece, by the recipes\' fallback (docs/combat/brawl-hook.md parts 5 and 6).',
        '## A mashed medium\'s or heavy\'s cell (docs/combat/split-and-pieces.md section 1): mediumMash or heavyMash when\n' +
        '## Combat\'s recipes name it, else the tap\'s, so recipes with no mash key throw as they did.\n' +
        'static func _mashCell(cell: String) -> String:\n' +
        '\tvar named = DirRecipe.rec().get("brawl", {}) if DirRecipe.on() else {}\n' +
        '\tvar m: String = cell + "Mash"\n' +
        '\treturn m if (named is Dictionary and named.has(m)) else cell\n\n\n' +
        '## A cell\'s piece, by the recipes\' fallback (docs/combat/brawl-hook.md parts 5 and 6).');
  });
}
if (steps.includes('interject')) {
  const rg = path.join(root, 'sim/director/ring.gd');
  if (!fs.existsSync(rg) || !fs.readFileSync(rg, 'utf8').includes('static func landX')) throw new Error('interject: ring.gd is not stage 3 (one versus many, stages 1 to 3 first)');
  edit('sim/director/ring.gd', rep => {
    rep('\t\t"closing": false, "charge": 0.0, "hand": "r", "ender": false, "interject": true}\n',
        '\t\t"closing": false, "charge": 0.0, "hand": "r", "ender": false, "interject": true}\n' +
        '\tvar piece: String = _piece(S, g, kind)\n' +
        '\tif piece != "":\n' +
        '\t\targs["piece"] = piece\n');
    rep('## The granted blow, as a beat of the partner\'s brawl: it lands lead live ticks from now.',
        '## The ring beat\'s piece (docs/combat/split-and-pieces.md section 3): from the recipes\' interject (a light) or\n' +
        '## interjectMedium (a medium; interject when there is none), under the brawl\'s own rules. "" when the recipes name\n' +
        '## neither: the renderer plays the strength\'s default, as before.\n' +
        'static func _piece(S: SimState, g, kind: int) -> String:\n' +
        '\tvar named = DirRecipe.rec().get("brawl", {}) if DirRecipe.on() else {}\n' +
        '\tif not (named is Dictionary):\n' +
        '\t\treturn ""\n' +
        '\tvar cell: String = "interjectMedium" if (kind == DirBrawl.MEDIUM and named.has("interjectMedium")) else "interject"\n' +
        '\tif not named.has(cell):\n' +
        '\t\treturn ""\n' +
        '\treturn DirBrawl._cellPiece(S, g, cell, String(named[cell]), "")\n\n\n' +
        '## The granted blow, as a beat of the partner\'s brawl: it lands lead live ticks from now.');
    // the wind-up cue names its cell, as the brawl's do: x a light, y a medium (the agreed cue list)
    rep('\tvar e = DirBrawl._ev(S, g, "windup", "interject", "")\n',
        '\tvar e = DirBrawl._ev(S, g, "windup", "interject", "y" if kind == DirBrawl.MEDIUM else "x")\n');
  });
}
