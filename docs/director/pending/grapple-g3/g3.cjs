// g3.cjs: the grapple's throw lands worth a heavy (Game Design, docs/design/rulings-2026-10-18.md 1c), on main with G1
// and G2. Behind the grapple's switch (grapple.enabled, false): with it off, play is the same to the bit.
//   node g3.cjs <checkout root> [--check]
// A throw (down, up, across, or the reversal's) lands worth grapple.throw.worth brawl lights (6: a heavy), a strike of
// the heavy class that ignores his stance and can't be perfect-blocked, before its bury, its opening in the air or its
// send across, whose landing does its own damage on top. A down throw's bury and a wall slam keep their openings.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node g3.cjs <checkout root> [--check]');
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
  const g = fs.readFileSync(path.join(root, 'sim/director/grapple.gd'), 'utf8');
  if (!g.includes('static func _aiThrowQ')) throw new Error('G2 first');
  if (g.includes('static func _throwHit')) throw new Error('the throw\'s worth is in already');
}

edit('sim/director/grapple.gd', rep => {
  rep('\t_end(S, f, o)\n\t_s(o, NOGRAB, S.tick + int(c.noRegrab))\n',
      '\t_end(S, f, o)\n\t_s(o, NOGRAB, S.tick + int(c.noRegrab))\n' +
      '\tif not _throwHit(S, ex, f, o):\n\t\treturn   # the throw\'s blow ended the exchange (a KO, a broken region\'s set piece)\n');
  rep('## f pushes off: both apart, the brawl lets go, and he has the first move.\n',
`## The throw's blow (Game Design, 2026-10-18 1c): worth throw.worth brawl lights, as a heavy, before what the throw
## hands the brawl (the bury, the opening in the air, the send across with its landing). False when it ended the exchange.
static func _throwHit(S: SimState, ex, f, o) -> bool:
	var w: float = float(cfg().throw.get("worth", 0.0))
	if w <= 0.0:
		return true
	var c: Dictionary = DirBrawl.cfg()
	var o2 := {"class": "heavy", "stop": float(int(c.hitstop.heavy)) / DirData.TICKS_PER_SEC, "big": true, "kb": float(c.recoil),
		"ignoreStance": true, "noParry": true, "weighed": true, "throw": true}
	DirMelee.strike(S, ex, f, o, w * DirBrawl._unit(), o2)
	if S.dirS.ex != ex or ex.cancel or ex.branch != "" or S.game.ko != null:
		return false
	if DirBrawl._setPiece(ex):
		DirBrawl.over(S, ex, "break")   # the throw broke a region: the break plays in this exchange
		return false
	return true


## f pushes off: both apart, the brawl lets go, and he has the first move.
`);
});

edit('data/director/interrupts.json', rep => {
  rep('    "throw": {"acrossBh": 8, "upBh": 4, "upOpen": 16, "bury": 20, "ai": {',
      '    "throw": {"acrossBh": 8, "upBh": 4, "upOpen": 16, "bury": 20, "worth": 6, "ai": {');
  rep(' Later slices add Game Design\'s vicious,', ' throw.worth: a throw lands worth this many brawl lights (a heavy), before what it hands the brawl (2026-10-18). Later slices add Game Design\'s vicious,');
});

{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const t = s.properties.grapple && s.properties.grapple.properties.throw;
  if (!t || !t.properties) throw new Error('director-interrupts schema: no grapple.throw');
  t.properties.worth = { type: 'number', minimum: 0, description: 'A throw lands worth this many brawl lights (a heavy), before what it hands the brawl.' };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: grapple.throw.worth' + (check ? ' (checked)' : ''));
}
