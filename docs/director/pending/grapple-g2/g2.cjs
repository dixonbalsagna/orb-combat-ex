// g2.cjs: the grapple, slice G2 (Game Design's re-ruling of 2026-10-17, docs/design/grapple.md section 9 and section 6),
// on top of G1 (pending/grapple-g1/gr.cjs). Behind G1's switch (grapple.enabled, false): with it off, play is the same
// to the bit.
//   node g2.cjs <checkout root> [--check]
//   1 The tie-break: when both pummel one pulse, the one nearer the pulse by the tick takes the step; the same number of
//     ticks off moves nothing (it was: sharp against not sharp).
//   2 The time: at clinch.max both part clinch.partBh; the grip's leader takes a clinch.timeFirstMove first move, and
//     the brawl lets go. At even, nobody does, and the brawl goes on (as in G1).
//   3 The AI's throw: down, up or across, drawn by what each hands it and by its care (throw.ai): down buries him and
//     up opens him in the air (both hand it a launch, so they weigh less while it lacks the launcher's ki); across sends
//     him along the line, weighed by its care and the people where he would land (the hero away from people, the
//     Anti-hero towards them). Keyed draws.
// Every anchor is exact text; the script stops at the first missing. --check reads every anchor and writes nothing.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node g2.cjs <checkout root> [--check]');
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
if (!fs.existsSync(path.join(root, 'sim/director/grapple.gd'))) throw new Error('the grapple G1 first (pending/grapple-g1/gr.cjs)');
if (fs.readFileSync(path.join(root, 'sim/director/grapple.gd'), 'utf8').includes('static func _aiThrowQ')) throw new Error('G2 is in already');

edit('sim/director/grapple.gd', rep => {
  rep('## Not in G1: vicious blows',
      '## G2 (Game Design, 2026-10-17): a tie on a pulse goes to the one nearer it by the tick; at the time the grip\'s leader\n' +
      '## takes a first move and the brawl lets go; the AI varies its throws by what each hands it and by its care.\n' +
      '## Not in G1: vicious blows');
  // 1 the tie-break by the tick
  rep('\tif va and vd:\n\t\tstep = 0 if sa == sd else (1 if sa else -1)\n',
      '\tif va and vd:\n' +
      '\t\tvar oa: int = _g(A, CLAIM_OFF)\n\t\tvar od: int = _g(D, CLAIM_OFF)\n' +
      '\t\tstep = 0 if oa == od else (1 if oa < od else -1)   # G2: the one nearer the pulse by the tick takes the step\n');
  // 2 the time: the leader's first move
  rep('\tif S.tick - t0 >= int(c.max):\n\t\t_part(S, ex, ex.A, ex.D, "time", float(c.partBh))\n',
      '\tif S.tick - t0 >= int(c.max):\n' +
      '\t\tvar g: int = _g(ex.A, GRIP)\n' +
      '\t\tif g == 0:\n\t\t\t_part(S, ex, ex.A, ex.D, "time", float(c.partBh))   # even: nobody has the first move, and the brawl goes on\n' +
      '\t\telse:\n\t\t\t_timeLead(S, ex, ex.A if g > 0 else ex.D, ex.D if g > 0 else ex.A)\n');
  // 3 the AI's throw, by what each hands it and by its care
  rep('\t_s(f, CLAIM_Q, DirBrawl._quarter(f, o) if f.ai == null else 3)   # the AI throws down (G1)\n',
      '\t_s(f, CLAIM_Q, DirBrawl._quarter(f, o) if f.ai == null else _aiThrowQ(S, f, o, k))   # G2: the AI\'s throw by what it hands it and its care\n');
  rep('## f pushes off: both apart, the brawl lets go, and he has the first move.\n',
`## G2: the time with a leader: both part clinch.partBh, the leader takes the first move (clinch.timeFirstMove ticks
## before the other may start an approach), and the brawl lets go. The lockout starts for both: nobody was thrown.
static func _timeLead(S: SimState, ex, lead, back) -> void:
	var c: Dictionary = cfg()
	_end(S, lead, back)
	_lockBoth(S, lead, back)
	_apart(lead, back, float(c.clinch.partBh))
	DirBrawl._s(back, DirBrawl.MOVE_AT, S.tick + int(c.clinch.get("timeFirstMove", 20)))
	_cue(S, lead, back, "grapple_end", "time_lead")
	SimEvents.feed(S, "CLINCH ENDS", "time: " + lead.name + " won the grip, and the first move is his")
	DirBrawl.end(S, ex, "clinch_time")


## G2: the AI's throw, should this pummel be its throw: down (the bury: an opening on the ground), up (open in the air)
## or across (sent along the line: the brawl ends). Down and up hand it a launch, so they weigh half while it lacks the
## launcher's ki. Across is weighed by its care against the people where he would land: the hero (care above 0) away
## from them, the Anti-hero (below 0) towards them. A keyed draw by the tie-up, the pulse and the slot.
static func _aiThrowQ(S: SimState, f, o, k: int) -> int:
	var tw: Dictionary = cfg().throw.get("ai", {})
	if tw.is_empty():
		return 3
	var cash: float = 1.0 if f.ki >= float(DirBrawl.cfg().launcher.ki) else 0.5
	var wd: float = float(tw.down) * cash
	var wu: float = float(tw.up) * cash
	var side: float = 1.0 if SimWrap.sdx(f.x, o.x) >= 0.0 else -1.0
	var land: float = SimWrap.wrap(o.x + side * float(cfg().throw.acrossBh) * DirInterrupt.BH)
	var pop: float = clampf(float(WorldStructures.popNear(S, land, float(tw.get("popR", 3.0)) * DirInterrupt.BH)) / maxf(0.001, WorldStructures.popNearRef(S)), 0.0, 1.0)
	var wa: float = maxf(0.05, float(tw.across) * (1.0 + (-float(f.care)) * float(tw.get("careW", 1.0)) * pop))
	var x: float = SimRng.keyed(int(S.game.seed), "grapple.throw", _g(f, T0) * 8 + k * 2 + S.fighters.find(f)) * (wd + wu + wa)
	if x < wd:
		return 3
	if x < wd + wu:
		return 1
	return 2


## f pushes off: both apart, the brawl lets go, and he has the first move.
`);
});

edit('data/director/interrupts.json', rep => {
  rep('"pushFirstMove": 20, "aiOffsets": [-4, -3, 3, 4]},\n',
      '"pushFirstMove": 20, "timeFirstMove": 20, "aiOffsets": [-4, -3, 3, 4]},\n');
  rep('    "throw": {"acrossBh": 8, "upBh": 4, "upOpen": 16, "bury": 20},\n',
      '    "throw": {"acrossBh": 8, "upBh": 4, "upOpen": 16, "bury": 20, "ai": {"down": 1.0, "up": 0.7, "across": 0.7, "careW": 1.5, "popR": 3}},\n');
  rep(' G2 adds Game Design\'s vicious, damage, wear, lead and pin, brace, braceRest and carry."',
      ' G2: when both pummel one pulse the one nearer it by the tick takes the step; clinch.timeFirstMove, the grip\'s leader\'s first move at the time (the brawl lets go; at even it goes on); throw.ai, the AI\'s throw weights: down and up (halved while it lacks the launcher\'s ki), across scaled by 1 + (-care) x careW x the people within popR body heights of where he would land (over the planet reference, WorldStructures.popNearRef). Later slices add Game Design\'s vicious, damage, wear, lead and pin, brace, braceRest and carry."');
});

{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const g = s.properties.grapple;
  if (!g || !g.properties || !g.properties.clinch || !g.properties.throw) throw new Error('director-interrupts schema: no grapple (G1 first)');
  const num = d => ({ type: 'number', minimum: 0, description: d });
  g.properties.clinch.properties.timeFirstMove = { type: 'integer', minimum: 0, description: "The grip's leader's first move at the time, in ticks." };
  g.properties.throw.properties.ai = { type: 'object', description: "The AI's throw weights (G2).", properties: {
    down: num('Down: the bury.'), up: num('Up: open in the air.'), across: num('Across: sent along the line.'),
    careW: num('Across is scaled by 1 + (-care) x this x the people where he would land.'), popR: num('... within this many body heights of where he would land.') },
    required: ['down', 'up', 'across'], additionalProperties: false };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: grapple.clinch.timeFirstMove, grapple.throw.ai' + (check ? ' (checked)' : ''));
}
