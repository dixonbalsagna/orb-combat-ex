// hw2.cjs: the hit weights re-cut for Game Design's rulings-2026-10-22 5b table (mash or burst light 2, tapped light 3,
// medium 5, heavy 8, launch or close 12, full launch 14, decisive 20, KO 24; Simulation's table), on top of main's hit
// weights (7a79d0e0): a burst's light names a mashed light's, and a planned strike's weight follows its atom's class (a
// mid a medium's, where it was a light's). Only while hit-stop by weight is on (S.hitstopOn): off nothing is written,
// so the golden doesn't move.
//   node hw2.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node hw2.cjs <checkout root> [--check]');
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
edit('sim/director/brawl.gd', rep => {
  rep('## "a launch or a close"); a mashed, flurry or held-pace light a mashed light\'s; a tapped light a light\'s.\n',
      '## "a launch or a close"); a mashed, flurry, burst or held-pace light a mashed light\'s (5b: "mash or burst light"); a\n' +
      '## tapped light a light\'s.\n');
  rep('\tif bk == FLURRY or bool(a.get("floor", false)):\n',
      '\tif bk == FLURRY or bool(a.get("floor", false)) or bool(a.get("burst", false)):\n');
});
edit('sim/director/melee.gd', rep => {
  rep('\tif S.hitstopOn and o is Dictionary and not o.has("weight"):\n\t\to["weight"] = w\n\n\n',
      '\tif S.hitstopOn and o is Dictionary and not o.has("weight"):\n\t\to["weight"] = w\n\n\n' +
      '## A planned strike\'s weight by its atom\'s class (Game Design\'s 5b table): a heavy or an ender a heavy\'s, a mid a\n' +
      '## medium\'s, an opener (or none) a light\'s. The launch after an ender holds its own stop at the send (holdSend).\n' +
      'static func weightOfClass(o) -> String:\n' +
      '\tvar cls: String = String(o.get("class", "")) if o is Dictionary else ""\n' +
      '\tif cls == "heavy" or cls == "ender":\n\t\treturn "heavy"\n' +
      '\treturn "medium" if cls == "mid" else "light"\n\n\n');
});
edit('sim/director/exchange.gd', rep => {
  rep('DirMelee.weigh(S, a.o, "heavy" if (a.o is Dictionary and (String(a.o.get("class", "")) == "heavy" or String(a.o.get("class", "")) == "ender")) else "light")   # hit-stop by weight\n',
      'DirMelee.weigh(S, a.o, DirMelee.weightOfClass(a.o))   # hit-stop by weight: by the atom\'s class (5b)\n');
});
