// hw.cjs: the director's hits name their weight for Simulation's hit-stop by weight (rulings-2026-10-19b 4a;
// docs/architecture/feel-core.md §2 and §5), and the send holds a launch's stop. Only while hit-stop by weight is on
// (S.hitstopOn; data/fight/hitstop.json, off): a beat's options are hashed, so off nothing is written. And the duplicate
// air sense goes (Simulation: data/fight/brake.json airSense is the one source).
//   node hw.cjs <checkout root> [--check]
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node hw.cjs <checkout root> [--check]');
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
if (!fs.existsSync(path.join(root, 'sim/core/hitstop.gd'))) throw new Error('Simulation\'s hit-stop by weight first');
edit('sim/director/melee.gd', rep => {
  rep('\tDirBrawl.powerCue(S, att, tgt, lkind, (lpow * kf) if lpow >= 0.0 else 1.0)\n',
      '\tDirBrawl.powerCue(S, att, tgt, lkind, (lpow * kf) if lpow >= 0.0 else 1.0)\n' +
      '\tholdSend(S, longOnly, (lpow * kf) if lpow >= 0.0 else 1.0)   # hit-stop by weight: the send holds a launch\'s stop\n');
  rep('## Beat "slip": the escaping defender breaks away from the pursuit.\n',
      '## Hit-stop by weight (Simulation\'s SimHitstop; rulings-2026-10-19b 4a): the weight a hit names for the table. Only\n' +
      '## while it is on: a hit\'s options are often a beat\'s, and a beat is hashed.\n' +
      'static func weigh(S: SimState, o, w: String) -> void:\n' +
      '\tif S.hitstopOn and o is Dictionary and not o.has("weight"):\n' +
      '\t\to["weight"] = w\n\n\n' +
      '## The send holds a launch\'s stop (14), a full launch\'s (16: launch anywhere\'s full power), or a set piece\'s\n' +
      '## decisive one (a break or finisher launch). Only while hit-stop by weight is on.\n' +
      'static func holdSend(S: SimState, special: bool, power: float) -> void:\n' +
      '\tif not S.hitstopOn:\n\t\treturn\n' +
      '\tif special:\n\t\tSimHitstop.hold(S, "decisive")\n' +
      '\telif DirBrawl.anywhere() and power >= float(DirBrawl.la().get("full", 0.8)) - 0.0005:\n\t\tSimHitstop.hold(S, "launch_full")\n' +
      '\telse:\n\t\tSimHitstop.hold(S, "launch")\n\n\n' +
      '## Beat "slip": the escaping defender breaks away from the pursuit.\n');
});
edit('sim/director/brawl.gd', rep => {
  rep('\telse:\n\t\tDirMelee.strike(S, ex, f, o, dmg, a.o)\n\t_inTick = was\n',
      '\telse:\n\t\tDirMelee.weigh(S, a.o, weightOf(a))   # hit-stop by weight: the blow names its weight\n\t\tDirMelee.strike(S, ex, f, o, dmg, a.o)\n\t_inTick = was\n');
  rep('\tSimDamage.hit(S, null, f, o, dmg, {"kind": "blast", "shot": power, "form": "brawl_medium" if blast else "brawl_light", "stop": float(a.o.get("stop", 0.0)), "shake": 7.0 if blast else 3.0})\n',
      '\tvar so := {"kind": "blast", "shot": power, "form": "brawl_medium" if blast else "brawl_light", "stop": float(a.o.get("stop", 0.0)), "shake": 7.0 if blast else 3.0}\n' +
      '\tDirMelee.weigh(S, so, "medium" if blast else "light")   # hit-stop by weight: a blast a medium\'s, a bolt a light\'s\n' +
      '\tSimDamage.hit(S, null, f, o, dmg, so)\n');
  rep('## A blow put on f\'s line by rule and not by a press (a zip\'s blow; the heavy a rival pressed before the zipper\n',
      '## The weight a brawl blow names for hit-stop by weight (rulings-2026-10-19b 4a): a bolt a light\'s and a blast a\n' +
      '## medium\'s; the double hit a heavy\'s (it held a heavy\'s stop); a heavy, a medium; the close a launch\'s (the table\'s\n' +
      '## "a launch or a close"); a mashed, flurry or held-pace light a mashed light\'s; a tapped light a light\'s.\n' +
      'static func weightOf(a: Dictionary) -> String:\n' +
      '\tif a.has("energy"):\n\t\treturn "medium" if String(a.energy) == "blast" else "light"\n' +
      '\tif bool(a.get("double", false)):\n\t\treturn "heavy"\n' +
      '\tvar bk: int = int(a.get("bk", LIGHT))\n' +
      '\tif bk == BIG:\n\t\treturn "heavy"\n' +
      '\tif bk == MEDIUM:\n\t\treturn "medium"\n' +
      '\tif bool(a.get("closing", false)):\n\t\treturn "launch"\n' +
      '\tif bk == FLURRY or bool(a.get("floor", false)):\n\t\treturn "light_mash"\n' +
      '\treturn "light"\n\n\n' +
      '## A blow put on f\'s line by rule and not by a press (a zip\'s blow; the heavy a rival pressed before the zipper\n');
});
edit('sim/director/exchange.gd', rep => {
  rep('\t\t\telse:\n\t\t\t\tDirMelee.strike(S, ex, A if a.a == "A" else D, A if a.d == "A" else D, DirBrawl.worth(S, ex, b, a.dmg), a.o)   # outside a brawl a blow is worth its form\n',
      '\t\t\telse:\n\t\t\t\tDirMelee.weigh(S, a.o, "heavy" if (a.o is Dictionary and (String(a.o.get("class", "")) == "heavy" or String(a.o.get("class", "")) == "ender")) else "light")   # hit-stop by weight\n' +
      '\t\t\t\tDirMelee.strike(S, ex, A if a.a == "A" else D, A if a.d == "A" else D, DirBrawl.worth(S, ex, b, a.dmg), a.o)   # outside a brawl a blow is worth its form\n');
  rep('\t\t\tDirMelee.strike(S, ex, A, D, DirBrawl.worth(S, ex, b, 52.0 + ex.combo * 7.0), {"noParry": true, "ignoreStance": true, "big": true, "stop": 0.08})   # with the brawl on, a link\'s blow is one brawl light\n',
      '\t\t\tvar lo := {"noParry": true, "ignoreStance": true, "big": true, "stop": 0.08}\n' +
      '\t\t\tDirMelee.weigh(S, lo, "light")   # hit-stop by weight: a link\'s blow is a light\'s\n' +
      '\t\t\tDirMelee.strike(S, ex, A, D, DirBrawl.worth(S, ex, b, 52.0 + ex.combo * 7.0), lo)   # with the brawl on, a link\'s blow is one brawl light\n');
  rep('\tDirMelee.strike(S, ex, W, L, float(a.dmg), a.o)\n\tvar ln: Dictionary = a.launch\n',
      '\tvar fo = a.o\n' +
      '\tif S.hitstopOn:\n\t\tfo = (a.o as Dictionary).duplicate() if a.o is Dictionary else {}\n\t\tDirMelee.weigh(S, fo, "decisive")   # hit-stop by weight: the finisher\'s last blow is decisive\n' +
      '\tDirMelee.strike(S, ex, W, L, float(a.dmg), fo)\n\tvar ln: Dictionary = a.launch\n');
});
edit('sim/director/grapple.gd', rep => {
  rep('\t\t"ignoreStance": true, "noParry": true, "weighed": true, "throw": true}\n\tDirMelee.strike(S, ex, f, o, w * DirBrawl._unit(), o2)\n',
      '\t\t"ignoreStance": true, "noParry": true, "weighed": true, "throw": true}\n\tDirMelee.weigh(S, o2, "heavy")   # hit-stop by weight: a throw is a heavy\'s\n\tDirMelee.strike(S, ex, f, o, w * DirBrawl._unit(), o2)\n');
});
edit('data/director/interrupts.json', rep => {
  rep('"fresh": {"windowS": 60, "factor": 0.75, "general": 0.9, "floor": 0.4, "airSense": 0.25, "preferW": 12, "destruction": false},',
      '"fresh": {"windowS": 60, "factor": 0.75, "general": 0.9, "floor": 0.4, "preferW": 12, "destruction": false},');
  rep('; the planner takes preferW off a candidate for each mark of its kind; airSense is for the flight\'s recovery (Simulation\'s, when granted).',
      '; the planner takes preferW off a candidate for each mark of its kind (the brake\'s air sense is Simulation\'s, data/fight/brake.json).');
});
{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const f = s.properties.brawl.properties.launcher.properties.anywhere.properties.fresh;
  if (!f.properties.airSense) throw new Error('director-interrupts schema: fresh.airSense is gone already');
  delete f.properties.airSense;
  if (Array.isArray(f.required)) f.required = f.required.filter(k => k !== 'airSense');
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: fresh.airSense removed' + (check ? ' (checked)' : ''));
}
