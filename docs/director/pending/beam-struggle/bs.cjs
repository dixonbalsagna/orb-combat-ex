// bs.cjs <checkout root> [--check]: the beam struggle as a tug of war on the pulse (Game Design, rule-of-cool.md section
// 2, 2026-10-16, after Orb: "nothing I pressed during it could affect the outcome"). Every number is data
// (interrupts.json beamStruggle); with enabled false the clash is exactly today's.
//   sim/director/beam.gd       the struggle: its start (a head start from state, no draw), the AI's presses drawn at the
//                              start (keyed), the pulse, surges and strays, the comeback, and its three ends
//   sim/director/exchange.gd   a player's clash press is scored (requestAttack); the struggle's tick (the exchange tick)
//   data/director/interrupts.json, its schema (Tools')   beamStruggle
// GRANTS, first, as patches in this folder (not Encounter's files; the meeting point is one field the director writes
// and the views read). The script refuses until Clash.mid is there.
//   grant-simulation.patch     sim/core/state.gd Clash.mid; sim/core/hash.gd mid hashed while a struggle holds it (a
//                              clash with no struggle hashes as today); sim/core/sim.gd the clash's sparks at mid
//   grant-rendering.patch      render/core/beam_view.gd the beams meet at mid
// Every anchor is exact text; the script stops at the first missing. --check reads every anchor and writes nothing.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const opts = process.argv.slice(3);
for (const o of opts) if (o !== '--check') throw new Error('unknown option: ' + o);
if (!root || root.startsWith('--')) throw new Error('usage: node bs.cjs <checkout root> [--check]');
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

// The grants come first: the director writes S.game.clash.mid, so Simulation's field must be there.
{
  const st = fs.readFileSync(path.join(root, 'sim/core/state.gd'), 'utf8').replace(/\r\n/g, '\n');
  if (!st.includes('\n\tvar mid: float = -1.0')) throw new Error('the grants first: grant-simulation.patch (Clash.mid is not in sim/core/state.gd) and grant-rendering.patch');
}

edit('sim/director/exchange.gd', rep => {
  rep('\tif DirBeam.inClash(S, A):\n\t\treturn\n',
      '\tif DirBeam.inClash(S, A):\n\t\tDirBeam.clashPress(S, A)   # in a beam struggle a player\'s press is scored on the pulse\n\t\treturn\n');
  rep('\t_struggleTick(S, ex)\n',
      '\t_struggleTick(S, ex)\n' +
      '\tDirBeam.clashTick(S, ex)   # the beam struggle: its pulses, the AI\'s presses, its end\n');
});

edit('sim/director/beam.gd', rep => {
  rep('static func startClash(S: SimState, ex, variant: String, dAdd: float = 0.0) -> void:\n\tvar A = ex.A\n',
      'static func startClash(S: SimState, ex, variant: String, dAdd: float = 0.0) -> void:\n' +
      '\tif bool(_bs().get("enabled", false)):\n' +
      '\t\t_startStruggle(S, ex, variant, dAdd)\n' +
      '\t\treturn\n' +
      '\tvar A = ex.A\n');
  rep('## Beat "clashResolve": the clash winner\'s beam overpowers the loser.\nstatic func opClashResolve(S: SimState, ex, args) -> void:\n',
`# ---------------------------------------------------------------- the beam struggle (rule-of-cool.md section 2, 2026-10-16)

static func _bs() -> Dictionary:
	return DirInterrupt.data().get("beamStruggle", {})


## A fighter's power for the head start: tier, ki, menace and flow, as the old score had them, with no draw.
static func _power(f) -> float:
	return f.tier * 10.0 + f.ki * 0.35 + (f.menace * f.md.menaceBeam if f.hasMenace else 0.0) + DirExchange.flowEdge(f)


## The beam struggle: a tug of war on the pulse. The meeting point (S.game.clash.mid, 0 at A's hands, 1 at D's)
## starts in the middle, moved toward the weaker side by state (headMax of the line at most; dAdd is the defender's,
## as before). Every pulseTicks a pulse; a face button pressed on it is a surge toward the rival, off it a stray. It
## ends when the point reaches a fighter, or on time after the last pulse. The AI's presses are drawn here, one keyed
## draw a pulse: it hits its level's share, never inside sharpTicks of the pulse.
static func _startStruggle(S: SimState, ex, variant: String, dAdd: float) -> void:
	var bs: Dictionary = _bs()
	var A = ex.A
	var D = ex.D
	var head: float = clampf((_power(A) - _power(D) - dAdd) * float(bs.headPerPoint), -float(bs.headMax), float(bs.headMax))
	var n: int = int(bs.pulses)
	var pt: int = int(bs.pulseTicks)
	var endTicks: int = n * pt + int(bs.surgeTicks) + 1
	var c := SimState.Clash.new()
	c.A = A
	c.D = D
	c.t0 = S.T
	c.dur = float(endTicks) / DirData.TICKS_PER_SEC
	c.aw = head >= 0.0
	c.mid = 0.5 + head
	S.game.clash = c
	SimFx.banner(S, "BEAM STRUGGLE", "#ffffff", 1.2)
	var st := {"t0": ex.t, "mid": c.mid, "head": head, "surgesA": 0, "surgesD": 0, "straysA": 0, "straysD": 0,
		"lastA": -99, "lastD": -99, "claimA": [], "claimD": [], "aiA": [], "aiD": [], "minMid": c.mid, "maxMid": c.mid, "crossed": false}
	var offs: Array = bs.get("aiOffsets", [-3, -2, 2, 3])
	for side in ["A", "D"]:
		var f = A if side == "A" else D
		if f.ai == null:
			continue
		var hit: float = float(bs.aiHit.get(String(DirAI.level), bs.aiHit.get("medium", 0.65)))
		var at: Array = []
		for k in range(1, n + 1):
			var key: int = (S.tick * 32 + k) * 2 + (0 if side == "A" else 1)
			if SimRng.keyed(int(S.game.seed), "beam.struggle.hit", key) < hit:
				var j: int = mini(offs.size() - 1, int(SimRng.keyed(int(S.game.seed), "beam.struggle.at", key) * float(offs.size())))
				at.append(k * pt + int(offs[j]))
		st["ai" + side] = at
	DirExchange.schedule(ex, ex.t + c.dur, "clashResolve", {"aw": c.aw, "variant": variant, "bs": st})
	var e = _cue(S, A, D, "beam_struggle", "start", c.mid)
	e.n = S.tick + endTicks


## A cue of the struggle: actor, target, text, and x the meeting point after it.
static func _cue(S: SimState, f, o, name: String, text: String, mid: float):
	SimFx.cue(S, f, name, text, "")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(o)) if o != null else -1.0
	e.x = mid
	return e


static func _struggleBeat(ex):
	for b in ex.beats:
		if not b.done and b.op == "clashResolve" and b.args != null and b.args.has("bs"):
			return b
	return null


## The ticks since the struggle began, on the exchange's clock.
static func _rel(ex, st: Dictionary) -> int:
	return int(round((ex.t - float(st.t0)) * DirData.TICKS_PER_SEC))


## Once a tick in a struggle (DirExchange's tick): the pulse's cue, the AI's presses, and its end.
static func clashTick(S: SimState, ex) -> void:
	if S.game.clash == null:
		return
	var rb = _struggleBeat(ex)
	if rb == null:
		return
	var st: Dictionary = rb.args.bs
	var bs: Dictionary = _bs()
	var rel: int = _rel(ex, st)
	var pt: int = int(bs.pulseTicks)
	if rel > 0 and rel % pt == 0 and rel / pt <= int(bs.pulses):
		var e = _cue(S, ex.A, ex.D, "beam_pulse", "", float(st.mid))
		e.k = rel / pt   # the pulse, 1 to pulses
		e.n = S.tick
	for side in ["A", "D"]:
		var f = ex.A if side == "A" else ex.D
		if f.ai != null and (st["ai" + side] as Array).has(rel):
			_press(S, ex, rb, f, side, rel)
	var mid: float = float(st.mid)
	if mid >= 1.0 or mid <= 0.0 or rel >= pt * int(bs.pulses) + int(bs.surgeTicks):
		rb.t = ex.t   # it ends: the resolve beat runs on the next tick


## A face button a player presses in a struggle (DirExchange.requestAttack). The AI's own presses are spent unscored:
## its struggle presses were drawn at the start.
static func clashPress(S: SimState, f) -> void:
	var ex = S.dirS.ex
	if ex == null or f.ai != null:
		return
	var rb = _struggleBeat(ex)
	if rb == null:
		return
	var side: String = "A" if f == ex.A else ("D" if f == ex.D else "")
	if side != "":
		_press(S, ex, rb, f, side, _rel(ex, rb.args.bs))


## One press, scored: on a pulse (within surgeTicks, not yet his) a surge toward the rival, sharp within sharpTicks;
## near his own hands (comebackZone) times comebackMul. Anything else is a stray, a half step back toward himself.
static func _press(S: SimState, ex, rb, f, side: String, rel: int) -> void:
	var st: Dictionary = rb.args.bs
	var bs: Dictionary = _bs()
	if rel == int(st["last" + side]):
		return   # one press a tick
	st["last" + side] = rel
	var pt: int = int(bs.pulseTicks)
	var k: int = int(round(float(rel) / float(pt)))
	var d: int = absi(rel - k * pt)
	var claim: Array = st["claim" + side]
	var toward: float = 1.0 if side == "A" else -1.0   # A pushes the point toward D's hands, D toward A's
	var was: float = float(st.mid)
	var mid: float = was
	var o = ex.D if side == "A" else ex.A
	var name: String = "beam_stray"
	var text: String = ""
	if k >= 1 and k <= int(bs.pulses) and d <= int(bs.surgeTicks) and not claim.has(k):
		claim.append(k)
		var sharp: bool = d <= int(bs.sharpTicks)
		var amt: float = float(bs.sharp) if sharp else float(bs.surge)
		if (was if side == "A" else 1.0 - was) <= float(bs.comebackZone):
			amt *= float(bs.comebackMul)   # the comeback: a surge from close to his own hands pushes harder
		mid = was + toward * amt
		st["surges" + side] = int(st["surges" + side]) + 1
		name = "beam_surge"
		text = "sharp" if sharp else "surge"
	else:
		mid = was - toward * float(bs.stray)
		st["strays" + side] = int(st["strays" + side]) + 1
	mid = clampf(mid, 0.0, 1.0)
	if (was - 0.5) * (mid - 0.5) < 0.0:
		st.crossed = true
	st.mid = mid
	st.minMid = minf(float(st.minMid), mid)
	st.maxMid = maxf(float(st.maxMid), mid)
	S.game.clash.mid = mid
	var e = _cue(S, f, o, name, text, mid)
	e.k = k


## The struggle's end (the clashResolve beat with its state). The point at a fighter: he is overwhelmed, taking the
## winner's beam and part of his own, launched along the beam's line, which carves what is there. On time within
## drawBand of the middle: the beams detonate where they meet, both are thrown back and take a share of the other's
## beam, and the ground there craters by the higher tier. On time further over: the side it is on loses a share of
## the beam, with no launch.
static func _resolveStruggle(S: SimState, ex, args) -> void:
	var A = ex.A
	var D = ex.D
	var st: Dictionary = args.bs
	var bs: Dictionary = _bs()
	var mid: float = float(st.mid)
	S.game.clash = null
	if S.game.ko != null:
		return
	var beam: float = 260.0 * sigDamageMul()
	var dxm: float = SimWrap.sdx(A.x, D.x)
	var mx: float = SimWrap.wrap(A.x + dxm * mid)
	var my: float = A.y + 38.0 + (D.y - A.y) * mid
	if mid >= 1.0 or mid <= 0.0:
		var Wn = A if mid >= 1.0 else D
		var Ls = D if mid >= 1.0 else A
		var ov: Dictionary = bs.overwhelm
		var dxs: float = SimWrap.sdx(Wn.x, Ls.x)
		var dyy: float = (Ls.y + 36.0) - (Wn.y + 38.0)
		var L: float = SimDamage.jor(SimDetMath.hypot(dxs, dyy), 1.0)
		var ux: float = dxs / L
		var uy: float = dyy / L
		var len: float = SimMathx.jmin(4200.0 * SimConst.WS, L + float(Wn.ld.beamOvershoot[_tierIx(Wn)]) * SimConst.WS)
		fireBeam(S, Wn, Wn.x, Wn.y + 38.0, ux, uy, len, String(args.variant))
		Ls.state = "locked"
		SimDamage.hit(S, ex, Wn, Ls, beam * (float(ov.winnerBeam) + float(ov.ownBeam)), {"ignoreStance": true, "stop": 0.16, "shake": 18.0, "big": true})
		_blast(S, Wn, Ls.x, Ls.y + 30.0, (70.0 + Wn.tier * 32.0) * SimConst.WS)
		_cue(S, Wn, Ls, "beam_end", "overwhelmed", mid)
		SimEvents.feed(S, Ls.name + " OVERWHELMED", "the meeting point reached him")
		if S.game.ko == null:
			DirLaunch.doLaunch(S, Wn, Ls, {"ux": ux, "uy": uy * 0.6 + 0.12}, 2600.0, true)
			DirExchange.decisive(S, ex, Wn, Ls, "beam_clash")
	elif absf(mid - 0.5) <= float(bs.drawBand):
		var hi = A if A.tier >= D.tier else D
		_blast(S, hi, mx, my - 8.0, (70.0 + hi.tier * 32.0) * SimConst.WS)
		var share: float = float(bs.detonate.otherBeam)
		SimDamage.hit(S, ex, D, A, beam * share, {"ignoreStance": true, "stop": 0.16, "shake": 18.0, "big": true})
		if S.game.ko == null:
			SimDamage.hit(S, ex, A, D, beam * share, {"ignoreStance": true, "stop": 0.16, "shake": 18.0, "big": true})
		if S.game.ko == null:
			DirLaunch.knockBack(S, D, A)
			DirLaunch.knockBack(S, A, D)
		ex.loser = -1
		_cue(S, null, null, "beam_end", "detonate", mid)
		SimEvents.feed(S, "THE BEAMS DETONATE", "the struggle ran out in the middle")
	else:
		var Wn2 = A if mid > 0.5 else D
		var Ls2 = D if mid > 0.5 else A
		SimDamage.hit(S, ex, Wn2, Ls2, beam * float(bs.timeLoss.share), {"ignoreStance": true, "stop": 0.12, "shake": 12.0, "big": true})
		_cue(S, Wn2, Ls2, "beam_end", "time", mid)
		SimEvents.feed(S, Ls2.name + " GIVES WAY", "the struggle ran out on his side")
		if S.game.ko == null:
			DirExchange.decisive(S, ex, Wn2, Ls2, "beam_clash")
	DirExchange.schedule(ex, ex.t + 1.0, "nop")


## Beat "clashResolve": the clash winner's beam overpowers the loser.
static func opClashResolve(S: SimState, ex, args) -> void:
	if args.has("bs"):
		_resolveStruggle(S, ex, args)
		return
`);
});

edit('data/director/interrupts.json', rep => {
  rep('\n  "beamPlays": {',
      '\n  "beamStruggle": {"enabled": true, "pulseTicks": 20, "pulses": 15, "surgeTicks": 4, "sharpTicks": 1, "surge": 0.10, "sharp": 0.15, "stray": 0.05, "comebackZone": 0.25, "comebackMul": 1.5, "headPerPoint": 0.005, "headMax": 0.15, "drawBand": 0.10, "aiHit": {"easy": 0.40, "medium": 0.65, "hard": 0.85}, "aiOffsets": [-3, -2, 2, 3], "overwhelm": {"winnerBeam": 1.0, "ownBeam": 0.5}, "detonate": {"otherBeam": 0.25}, "timeLoss": {"share": 0.5}, "_note": "The beam struggle as a tug of war on the pulse (rule-of-cool.md section 2, 2026-10-16; sim/director/beam.gd). The meeting point starts in the middle, moved toward the weaker side by state: headPerPoint of the line for each point of power (tier x 10, ki x 0.35, menace, flow), headMax at most. Every pulseTicks a pulse, pulses of them. Any face button within surgeTicks of a pulse is a surge, the point moving surge of the line toward the rival (sharp within sharpTicks); a press off the pulse is a stray, the point moving stray back toward himself. Within comebackZone of his own hands a surge is times comebackMul. The AI hits aiHit of the pulses by level, pressing aiOffsets ticks off it (never within sharpTicks). The point at a fighter: he is overwhelmed (overwhelm: shares of the winner\'s beam and his own; launched). On time within drawBand of the middle: the beams detonate (detonate.otherBeam each). On time further over: the side it is on loses timeLoss.share of the beam, no launch. enabled false: the clash as before."},\n  "beamPlays": {');
});

{
  const sp = path.join(root, 'tools/schemas/director-interrupts.schema.json');
  const s = JSON.parse(fs.readFileSync(sp, 'utf8'));
  const num = d => ({ type: 'number', minimum: 0, description: d });
  const int = d => ({ type: 'integer', minimum: 0, description: d });
  s.properties.beamStruggle = {
    type: 'object',
    properties: {
      enabled: { type: 'boolean', description: 'The beam struggle as a tug of war on the pulse; false: the clash as before.' },
      pulseTicks: int('Ticks between pulses.'), pulses: int('Pulses in a struggle.'),
      surgeTicks: int('A press within this many ticks of a pulse is a surge.'), sharpTicks: int('... within this many, a sharp surge.'),
      surge: num('A surge moves the meeting point this share of the line toward the rival.'), sharp: num('... a sharp surge, this share.'),
      stray: num('A press off the pulse moves it this share back toward himself.'),
      comebackZone: num('Within this share of the line from his own hands ...'), comebackMul: num('... a surge is times this.'),
      headPerPoint: num('The head start, a share of the line for each point of power between them.'), headMax: num('... at most this share.'),
      drawBand: num('On time, within this share of the middle: the beams detonate.'),
      aiHit: { type: 'object', additionalProperties: num('The share of pulses the AI hits at this level.'), description: 'By AI level.' },
      aiOffsets: { type: 'array', items: { type: 'integer' }, description: 'The ticks off the pulse the AI presses, one drawn a pulse.' },
      overwhelm: { type: 'object', properties: { winnerBeam: num("The overwhelmed fighter takes this share of the winner's beam ..."), ownBeam: num('... and this share of his own.') }, additionalProperties: false },
      detonate: { type: 'object', properties: { otherBeam: num("On a detonation each takes this share of the other's beam.") }, additionalProperties: false },
      timeLoss: { type: 'object', properties: { share: num('On time, the side the point is on takes this share of the beam.') }, additionalProperties: false }
    },
    additionalProperties: false,
    patternProperties: { '^_': true },
    description: 'The beam struggle (rule-of-cool.md section 2).'
  };
  if (!check) fs.writeFileSync(sp, JSON.stringify(s, null, 2) + '\n');
  console.log('tools/schemas/director-interrupts.schema.json: beamStruggle' + (check ? ' (checked)' : ''));
}
