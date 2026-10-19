// l2.cjs: launch anywhere, round 2 (Game Design's rulings of 2026-10-18, docs/design/rulings-2026-10-18.md section 1;
// Orb's homework 30 on launches; Combat's asks of 1e7e34aa), on main with launch anywhere (f4e8269c). Behind the same
// switch, brawl.launcher.anywhere.enabled (false), except the data hash's line, which reads Combat's enders file only
// when it exists (not on main yet): so with the switch off and no file, play and the golden are main's to the bit.
//   node l2.cjs <checkout root> [--check]
//   1a An answerable launcher's armour takes one light: a second light that lands in its wind-up stops it. A hard one
//      keeps full armour against lights, and a sure one is armoured outright.
//   1b The full line: anywhere.full 0.7 (it was 0.8).
//   Orb: the destruction a launch does doesn't fall with repetition. Freshness shortens the flight (the force) and the
//      power a launch counts at the send; the power World's building ladder reads (tgt.launchPower) is the launcher's
//      own, before freshness (anywhere.fresh.destruction false; true puts freshness back on it).
//   Combat: (a) data/combat/enders.json in the director's data hash when it exists; (b) the AI aims its launchers by its
//      personality (anywhere.aiAim): the hero up or across, away from people, the Anti-hero across or down; (c) the
//      re-chamber's tell: a launch on the enders' step 3 or 4 winds rechamber.ticks longer (the file's own number).
// Every anchor is exact text; the script stops at the first missing. --check reads every anchor and writes nothing.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node l2.cjs <checkout root> [--check]');
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
{
  const b = fs.readFileSync(path.join(root, 'sim/director/brawl.gd'), 'utf8');
  if (!b.includes('static func anywhere()')) throw new Error('launch anywhere first (f4e8269c)');
  if (b.includes('const LA_SAFE: int')) throw new Error('round 2 is in already');
}

edit('sim/director/brawl.gd', rep => {
  rep('const LA_N: int = 26\n',
      'const LA_SAFE: int = 26   # the launcher on his line: its safety (1 sure, 2 hard, 3 answerable)\n' +
      'const LA_LHIT: int = 27   # ... and the lights its armour has taken (an answerable one takes one)\n' +
      'const LA_N: int = 28\n');
  rep('\t\t\targs["safety"] = safety\n',
      '\t\t\targs["safety"] = safety\n\t\t\t_ls(f, LA_SAFE, safety)\n\t\t\t_ls(f, LA_LHIT, 0)\n');
  // 1a the armour against lights: an answerable launcher's takes one
  rep('\tif oWinding and oKind == BIG and (_g(o, FLAV) == 0 or (_g(o, FLAV) == 2 and anywhere())) and not special:   # launch anywhere: the launcher is armoured against lights too\n\t\tif not wound:\n\t\t\tarmour = true\n\t\t\tdmg *= float(c.heavy.armour.lightMul)\n',
      '\tvar laStop: bool = false   # launch anywhere: a second light into an answerable launcher\'s wind-up stops it (2026-10-18, 1a)\n' +
      '\tif oWinding and oKind == BIG and (_g(o, FLAV) == 0 or (_g(o, FLAV) == 2 and anywhere())) and not special:   # launch anywhere: the launcher is armoured against lights too\n' +
      '\t\tif not wound and _g(o, FLAV) == 2 and _lg(o, LA_SAFE) == 3 and _lg(o, LA_LHIT) >= 1:\n' +
      '\t\t\tlaStop = true   # its armour has taken its one light\n' +
      '\t\telif not wound:\n\t\t\tarmour = true\n\t\t\tdmg *= float(c.heavy.armour.lightMul)\n' +
      '\t\t\tif _g(o, FLAV) == 2:\n\t\t\t\t_ls(o, LA_LHIT, _lg(o, LA_LHIT) + 1)\n');
  rep('\tif wound and oWinding and _g(o, LINE) != 0:\n',
      '\tif (wound or laStop) and oWinding and _g(o, LINE) != 0:\n');
  // Combat (c): the re-chamber's tell
  rep('\t\tif ep != "":\n\t\t\tpiece = ep   # Combat\'s enders: the launch that follows his last blow\'s family and path\n',
      '\t\tif ep != "":\n\t\t\tpiece = ep   # Combat\'s enders: the launch that follows his last blow\'s family and path\n' +
      '\t\t\tvar rc: Dictionary = _enders().get("rechamber", {})\n' +
      '\t\t\tif not rc.is_empty() and _enderStep >= int(rc.get("fromStep", 3)):\n' +
      '\t\t\t\tlead += int(rc.get("ticks", 0))   # the re-chamber\'s tell: a launch that doesn\'t follow his last blow\'s path winds longer, so the reset reads\n' +
      '\t\t\t\tif _g(f, HOLD_AT) > 0:\n\t\t\t\t\t_s(f, HOLD_AT, _g(f, HOLD_AT) + int(rc.get("ticks", 0)))   # ... and its wind-up counts from the reset\n');
  rep('\treturn pick[mini(pick.size() - 1, int(SimRng.keyed(int(S.game.seed), "brawl.ender", S.dirS.exN * 64 + _g(f, BLOWS)) * float(pick.size())))]\n',
      '\t_enderStep = best\n' +
      '\treturn pick[mini(pick.size() - 1, int(SimRng.keyed(int(S.game.seed), "brawl.ender", S.dirS.exN * 64 + _g(f, BLOWS)) * float(pick.size())))]\n');
  rep('static func _ender(S: SimState, f, aim: int) -> String:\n',
      '## The step of the last ender picked (Combat\'s 1 to 5), for the re-chamber\'s tell. Not state: read at once.\n' +
      'static var _enderStep: int = 0\n\n' +
      'static func _ender(S: SimState, f, aim: int) -> String:\n\t_enderStep = 0\n');
  // Combat (b): the AI aims its launchers by its personality
  rep('\tif anywhere() and _aiLaunchInString(S, f, c):\n\t\t_s(f, AI_RIP, 0)\n\t\t_s(f, AI_GUARD, 0)\n\t\t_s(f, AI_LEFT, 0)\n\t\t_aiPress(S, f, i, 2, bl, true)\n',
      '\tif anywhere() and _aiLaunchInString(S, f, c):\n\t\t_s(f, AI_RIP, 0)\n\t\t_s(f, AI_GUARD, 0)\n\t\t_s(f, AI_LEFT, 0)\n\t\t_aiAim(S, f, o, i)\n\t\t_aiPress(S, f, i, 2, bl, true)\n');
  rep('\t\t\t_aiPress(S, f, i, 2, bl, true)\n',
      '\t\t\tif anywhere():\n\t\t\t\t_aiAim(S, f, o, i)\n\t\t\t_aiPress(S, f, i, 2, bl, true)\n');
  rep('## Combat\'s enders (docs/combat/launch-enders.md), loaded once from res://data/combat/enders.json when it exists.\n',
`## launch anywhere: the AI aims its launcher by its personality (Combat's launch-enders.md section 3, the
## fighter-pipeline's identity): the hero up or across, and across weighs less where people are along the line; the
## Anti-hero across or down, into buildings and the ground. A keyed draw by anywhere.aiAim's weights, its care's sign
## choosing the set, or its role while its care is 0 (hero; villain or rival). A reference fighter doesn't aim (the
## planner's pick).
static func _aiAim(S: SimState, f, o, i: SimIntent) -> void:
	var aw: Dictionary = la().get("aiAim", {})
	if aw.is_empty():
		return
	var pers: String = "hero" if f.care > 0.0 else ("villain" if f.care < 0.0 else "")
	if pers == "":
		var dd = FighterData.def(f.id)
		var role: String = String(dd.get("role", "")) if dd is Dictionary else ""
		pers = "hero" if role == "hero" else ("villain" if (role == "villain" or role == "rival") else "")
	if pers == "":
		return
	var w: Dictionary = aw.get(pers, {})
	var side: float = 1.0 if SimWrap.sdx(f.x, o.x) >= 0.0 else -1.0
	var wu: float = float(w.get("up", 0.0))
	var wa: float = float(w.get("across", 0.0))
	var wd: float = float(w.get("down", 0.0))
	if pers == "hero":
		var land: float = SimWrap.wrap(o.x + side * float(aw.get("popAtBh", 8.0)) * DirInterrupt.BH)
		wa *= 1.0 - clampf(float(WorldStructures.popNear(S, land, float(aw.get("popR", 3.0)) * DirInterrupt.BH)) / maxf(0.001, WorldStructures.popNearRef(S)), 0.0, 1.0)
	var tot: float = wu + wa + wd
	if tot <= 0.0:
		return
	var x: float = SimRng.keyed(int(S.game.seed), "brawl.aiAim", S.tick * 2 + S.fighters.find(f)) * tot
	if x < wu:
		i.mx = 0.0
		i.my = 1.0
	elif x < wu + wa:
		i.mx = side
		i.my = 0.0
	else:
		i.mx = 0.0
		i.my = -1.0


## Combat's enders (docs/combat/launch-enders.md), loaded once from res://data/combat/enders.json when it exists.
`);
});

edit('sim/director/melee.gd', rep => {
  // Orb: destruction doesn't fall with repetition (freshness shortens the flight, not what it breaks)
  rep('tgt.launchPower = lpow * DirBrawl.freshMul(S, tgt, 4)',
      'tgt.launchPower = lpow * (DirBrawl.freshMul(S, tgt, 4) if DirBrawl.freshHurts() else 1.0)');
  rep('tgt.launchPower = lpow * kf', 'tgt.launchPower = lpow * (kf if DirBrawl.freshHurts() else 1.0)');
});
edit('sim/director/brawl.gd', rep => {
  rep('## Each launch marks its kind on the fighter it sends (DirMelee.launchBeat): the oldest of that kind\'s four marks goes.\n',
      '## Orb (homework 30): "each time you launch an opponent against something, the more destroyed it will be". So with\n' +
      '## anywhere.fresh.destruction false, freshness shortens the flight and the power counted at the send, and the power\n' +
      '## World\'s building ladder reads is the launcher\'s own.\n' +
      'static func freshHurts() -> bool:\n\treturn bool(la().get("fresh", {}).get("destruction", false))\n\n\n' +
      '## Each launch marks its kind on the fighter it sends (DirMelee.launchBeat): the oldest of that kind\'s four marks goes.\n');
});

edit('sim/director/data.gd', rep => {
  rep('\th.text(DirRecipe.dataText())   # data/director/alchemy.json and Combat\'s data/combat/recipes.json\n',
      '\th.text(DirRecipe.dataText())   # data/director/alchemy.json and Combat\'s data/combat/recipes.json\n' +
      '\tif FileAccess.file_exists("res://data/combat/enders.json"):\n' +
      '\t\th.text(FileAccess.get_file_as_string("res://data/combat/enders.json"))   # Combat\'s launch enders (launch anywhere\'s pick), once they land\n');
});

edit('data/director/interrupts.json', rep => {
  rep('"fresh": {"windowS": 60, "factor": 0.75, "general": 0.9, "floor": 0.4, "airSense": 0.25, "preferW": 12}',
      '"fresh": {"windowS": 60, "factor": 0.75, "general": 0.9, "floor": 0.4, "airSense": 0.25, "preferW": 12, "destruction": false}');
  rep('"full": 0.8', '"full": 0.7,\n        "aiAim": {"hero": {"up": 1.0, "across": 0.6, "down": 0.2}, "villain": {"up": 0.3, "across": 1.0, "down": 0.8}, "popAtBh": 8, "popR": 3}');
  rep('The launcher is armoured against lights, and only a sure one holds his stagger.',
      'The launcher is armoured against lights (an answerable one takes one light, and a second in its wind-up stops it: 2026-10-18), and only a sure one holds his stagger. fresh.destruction false: freshness never lowers the power World\'s building ladder reads (Orb, homework 30). aiAim: the AI\'s launcher aim by its personality, up, across and down weights for the hero (care above 0, or the hero role at care 0; across less where people are popAtBh body heights along the line, within popR) and the Anti-hero (care below 0, or a villain or rival role).');
});

{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const a = s.properties.brawl.properties.launcher.properties.anywhere;
  if (!a || !a.properties || !a.properties.fresh) throw new Error('director-interrupts schema: no brawl.launcher.anywhere');
  const num = d => ({ type: 'number', minimum: 0, description: d });
  a.properties.fresh.properties.destruction = { type: 'boolean', description: "False: freshness never lowers the power World's building ladder reads." };
  const set = d => ({ type: 'object', description: d, properties: { up: num('Up.'), across: num('Across.'), down: num('Down.') }, additionalProperties: false });
  a.properties.aiAim = { type: 'object', description: "The AI's launcher aim by its personality.", properties: {
    hero: set('Care above 0.'), villain: set('Care below 0.'), popAtBh: num('Where the hero looks for people along the line, in body heights.'), popR: num('... within this many.') },
    additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: anywhere.fresh.destruction, anywhere.aiAim' + (check ? ' (checked)' : ''));
}
