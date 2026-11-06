class_name DirBeam
## Signature beams: the twin of beam.js (planBeam and its beat ops, startClash, fireBeam, sampleBeam, beamStep).


## Plans a signature from Combat's data (DirData).
static func planBeam(S: SimState, ex) -> void:
	var out: String = DirData.planBeam(S, ex)
	_setLoser(S, ex, out)


static func _setLoser(S: SimState, ex, out: String) -> void:
	if out == "HIT" or out == "GUARD":
		ex.loser = S.fighters.find(ex.D)
	elif out == "DODGE" or out == "ESCAPE":
		ex.loser = S.fighters.find(ex.A)


## Beat "beamCharge": the attacker rises above the defender and charges.
static func opBeamCharge(S: SimState, ex, args) -> void:
	var A = ex.A
	var D = ex.D
	var still: bool = DirBeamPlay.stationary()
	if not still or A.beamCharge == null:   # (a stick's hold has been charging already)
		A.beamCharge = S.T
	DirBeamPlay.chargeCue(S, ex, true)
	SimFx.banner(S, A.sigName.to_upper(), A.aura, 1.1)
	if still:
		A.vx = 0.0
		A.vy = 0.0
	else:
		var r := SimState.Rush.new()
		r.py = SimMathx.jmin(SimConst.CEILING - 200.0, D.y + args.rise)
		r.px = DirBeamPlay.standoffX(S, A, D, r.py)
		r.end = S.T + 0.55
		A.rush = r
	SimFx.ring(S, A.x, A.y + 40.0, 260.0, A.aura, 0.8, 10.0)
	# Step 2b: an AI defender may answer the beam, by the same rule as a player: its own signature (45 ki and the cooldown
	# over), or else a heavy blast (40 ki). How often is its difficulty (control-rules.md §10); the press comes in the tell.
	var answers: bool = false
	if DirData.beamAtFire() and D.ai != null:
		var canSig: bool = (D.ki >= 45.0 and S.T >= D.sigReadyT) or SimFighter.sigFree(D)   # the last stand answers free
		if (canSig or D.ki >= 40.0) and S.rng.next() < float(DirAI.lv().beamAnswer):
			answers = true
			DirExchange.schedule(ex, ex.t + S.rng.range_(0.15, 0.6), "press", {"who": "D", "sig": canSig, "blast": not canSig})
	DirBeamPlay.aiPlan(S, ex, answers)   # the beam plays: its perfect block and its look, its dodge, its wade, a late answer


## True while f is one of the two fighters of a live clash (the beam struggle). The host and the input layer read it
## (docs/controls/tech-and-pulse-input.md): clash presses are the clash's, and the Simple layout fires on press.
## Game Design's provisional signature limit (agency-pass.md section 5; interrupts.json `signature`): with the switch on,
## a signature recharges in cooldownSec (not the fighter's own sigCooldown) and does damageMul of its damage, because
## there will be several times as many. Off, or in a profile without the perfect block, both are as they were.
static func sigCooldown(f) -> float:
	var sg: Dictionary = DirInterrupt.data().get("signature", {})
	return float(sg.cooldownSec) if DirInterrupt.on() and sg.get("provisional", false) else f.sigCooldown


static func sigDamageMul() -> float:
	var sg: Dictionary = DirInterrupt.data().get("signature", {})
	return float(sg.damageMul) if DirInterrupt.on() and sg.get("provisional", false) else 1.0


static func inClash(S: SimState, f) -> bool:
	return S.game.clash != null and (S.game.clash.A == f or S.game.clash.D == f)


## Beat "beamFire": fire, or start a beam clash; the outcome was decided when the beam was planned.
static func opBeamFire(S: SimState, ex, args) -> void:
	var A = ex.A
	var D = ex.D
	var out: String = args.out
	var variant: String = args.variant
	var dist: float = args.dist
	A.beamCharge = null
	DirBeamPlay.chargeCue(S, ex, false)
	if S.game.ko != null:
		return
	var dAdd: float = 0.0
	var answered: bool = false
	if out == "":
		# Step 2b: the outcome is decided now, from what the defender did during the tell (DirData.beamOutcome).
		var answer: String = _answer(S, D)
		if answer == "none" and DirBeamPlay.on():
			DirBeamPlay.fire(S, ex, args)   # the beam plays: it leaves now, and the outcome is read when it reaches him
			return
		var res: Dictionary = DirData.beamOutcome(S, ex, dist, answer, args.get("perfect", false))
		out = res.out
		dAdd = res.dAdd
		answered = true
		ex.branch = out
		ex.tag += " → " + out
		_setLoser(S, ex, out)
		SimEvents.feed(S, A.sigName + " → " + out, "the defender's answer: " + answer)
		SimFx.beamOutcome(S, A, D, out)
	var len: float = SimMathx.jmin(4200.0 * SimConst.WS, dist + float(A.ld.beamOvershoot[_tierIx(A)]) * SimConst.WS)   # the tier gate: was 2000 + 400 x tier
	var ox: float = A.x
	var oy: float = A.y + 38.0
	var aimY: float = D.y + 36.0
	if out == "CLASH":
		if not answered:
			D.ki -= 40.0   # the old profiles' automatic clash; an answering request has paid its own cost
		startClash(S, ex, variant, dAdd)
		return
	var dxs: float = SimWrap.sdx(ox, D.x)
	var dyy: float = aimY - oy
	var L: float = SimDamage.jor(SimDetMath.hypot(dxs, dyy), 1.0)
	var ux: float = dxs / L
	var uy: float = dyy / L
	fireBeam(S, A, ox, oy, ux, uy, len, variant)
	var reach: float = SimMathx.jmin(0.2, dist / len * 0.22)
	if out == "DEFLECT":
		DirInterrupt.deflect(S, D)   # step 3: a perfect block of the fire beat; the beam is turned aside
	elif out == "HIT" or out == "GUARD":
		DirExchange.schedule(ex, ex.t + reach, "beamImpact", {"out": out, "ux": ux, "uy": uy})
	elif out == "DODGE":
		DirExchange.schedule(ex, ex.t + 0.02, "beamDodge")
	else:
		DirExchange.schedule(ex, ex.t + 0.02, "beamEscape")
	DirExchange.schedule(ex, ex.t + 0.9, "nop")
	DirCamIntent.exchange(S, ex, "beam:" + out)   # the camera-intent feed: the beam's plan, its outcome known


## The defender's answer to a beam, taken from its queue at the fire beat (stance-matrix.md §7.2): its own signature
## (45 ki, the cooldown over), or a heavy energy attack with 40 ki. The request is spent and its cost paid here. A light
## blast or a physical attack is no answer: the beam goes through.
static func _answer(S: SimState, D) -> String:
	var q: Array = D.act.queue
	for k in range(q.size()):
		if int(q[k][0]) == SimAct.SIG and ((D.ki >= 45.0 and S.T >= D.sigReadyT) or SimFighter.sigFree(D)):
			q.remove_at(k)
			if SimFighter.sigFree(D):
				SimFighter.lastStandUse(S, D)   # the last stand: no cost, and the window closes
			else:
				D.ki -= 45.0
			D.sigReadyT = S.T + sigCooldown(D)
			return "signature"
	for k in range(q.size()):
		if int(q[k][0]) == SimAct.HEAVY and int(q[k][1]) == 1 and D.ki >= 40.0:
			q.remove_at(k)
			D.ki -= 40.0
			return "heavy_blast"
	return "none"


## Beat "beamImpact": the beam connects (HIT) or is blocked (GUARD).
static func opBeamImpact(S: SimState, ex, args) -> void:
	var A = ex.A
	var D = ex.D
	var out: String = args.out
	if S.game.ko != null:
		return
	# Biomes W2: the row's twist (sigvariants.json `twist`) lands on the aftermath, so its impact waits for the carve.
	var tw: Dictionary = DirSigAfter.twistFor(S, A, out)
	if not tw.is_empty() and DirSigAfter.waiting(S, A) and int(args.get("wait", 0)) < DirSigAfter.WAIT_MAX:
		var a2: Dictionary = args.duplicate()
		a2["wait"] = int(args.get("wait", 0)) + 1
		DirExchange.schedule(ex, ex.t + SimConst.DT, "beamImpact", a2)
		return
	if D.state == "locked":
		D.state = "free"
	SimDamage.hit(S, ex, A, D, (200.0 if out == "GUARD" else 230.0) * sigDamageMul(), {"ignoreStance": out != "GUARD", "stop": 0.14, "shake": 16.0, "big": true})
	_blast(S, A, D.x, D.y + 30.0, 60.0 + A.tier * 30.0)
	if S.game.ko == null:
		D.state = "locked"
		var force: float = 1300.0 if out == "GUARD" else 2600.0
		var kind: String = String(tw.get("kind", ""))
		var twisted: bool = false
		if kind == "under":
			twisted = DirSigAfter.under(S, A, D)
		elif kind == "wall":
			twisted = DirSigAfter.wall(S, A, D, tw, args.ux, force)
		if not twisted:
			DirLaunch.doLaunch(S, A, D, {"ux": args.ux, "uy": args.uy * 0.6 + 0.12}, force, true)
			if kind == "skate":
				DirSigAfter.skate(S, A, D, tw)
		DirExchange.decisive(S, ex, A, D, "beam")


const DODGE_DRIFT_X: float = 420.0   # the dodger's drift after the beam dodge, units per second
const DODGE_DRIFT_Y: float = 180.0


## Beat "beamDodge".
static func opBeamDodge(S: SimState, ex, _args) -> void:
	var D = ex.D
	SimFx.afterimage(S, D)
	D.y += 300.0
	# CC-005: freed at the dodge, drifting up and away from the beam (it hung locked for 0.9 s). No draw.
	D.state = "free"
	D.vx = SimMathx.jsign(SimWrap.sdx(ex.A.x, D.x)) * DODGE_DRIFT_X
	D.vy = DODGE_DRIFT_Y
	SimFx.banner(S, "DODGED", "#9fe0ff", 0.7)


## Beat "beamEscape".
static func opBeamEscape(S: SimState, ex, _args) -> void:
	var A = ex.A
	var D = ex.D
	SimFx.afterimage(S, D)
	D.state = "free"
	D.vx = SimMathx.jsign(SimWrap.sdx(A.x, D.x)) * 1600.0
	D.vy = S.rng.range_(-100.0, 300.0)
	SimFx.banner(S, "ESCAPED", "#9fe0b0", 0.7)


## beam.js startClash sc(f): one draw per call, attacker first.
static func _clashScore(S: SimState, f) -> float:
	return f.tier * 10.0 + f.ki * 0.35 + S.rng.range_(0.0, 16.0) + (f.menace * f.md.menaceBeam if f.hasMenace else 0.0) + DirExchange.flowEdge(f)   # D1b: meters.json beam_power; section 22: his flow


## dAdd: added to the defender's score (an answering heavy blast clashes at -10).
static func startClash(S: SimState, ex, variant: String, dAdd: float = 0.0) -> void:
	if struggleOn():
		_startStruggle(S, ex, variant, dAdd)
		return
	var A = ex.A
	var D = ex.D
	var aw: bool = _clashScore(S, A) > _clashScore(S, D) + dAdd
	var c := SimState.Clash.new()
	c.A = A
	c.D = D
	c.t0 = S.T
	c.dur = 1.6
	c.aw = aw
	S.game.clash = c
	DirCalm.atSetPiece(S, ex, S.tick + int(round((c.dur + 1.0) * DirData.TICKS_PER_SEC)))   # (rulings-2026-10-23 3: its end is a calm moment; ask now)
	SimFx.banner(S, "BEAM CLASH", "#ffffff", 1.2)
	DirExchange.schedule(ex, ex.t + 1.6, "clashResolve", {"aw": aw, "variant": variant})
	DirExchange.schedule(ex, ex.t + 2.6, "nop")
	DirCamIntent.exchange(S, ex, "clash")   # the camera-intent feed: the beam clash's plan


# ---------------------------------------------------------------- the beam struggle (rule-of-cool.md section 2, 2026-10-16)

static func _bs() -> Dictionary:
	return DirInterrupt.data().get("beamStruggle", {})


static func struggleOn() -> bool:
	return bool(_bs().get("enabled", false))


## A fighter's power for the head start: tier, ki, menace and flow, as the old score had them, with no draw.
static func _power(f) -> float:
	return f.tier * 10.0 + f.ki * 0.35 + (f.menace * f.md.menaceBeam if f.hasMenace else 0.0) + DirExchange.flowEdge(f)


## The beam struggle: a tug of war on the pulse. The meeting point (S.game.clash.mid, 0 at A's hands, 1 at D's) starts in
## the middle, moved toward the weaker side by state (headMax of the line at most; dAdd is the defender's, as before).
## Every pulseTicks a pulse. It ends when the point reaches a fighter, when one lets go, or on time after the last pulse.
## The AI's presses are drawn here, one keyed draw a pulse: it hits its level's share, never inside sharpTicks of the
## pulse, and never lets go.
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
	c.mid = clampf(0.5 + head + DirBeamPlay.meetShift(), 0.0, 1.0)   # a fire-back starts where the fronts meet
	S.game.clash = c
	DirCalm.atSetPiece(S, ex, S.tick + endTicks + int(round(DirData.TICKS_PER_SEC)))   # (rulings-2026-10-23 3: its end is a calm moment; ask now)
	SimFx.banner(S, "BEAM STRUGGLE", "#ffffff", 1.2)
	var st := {"t0": ex.t, "mid": c.mid, "head": head, "surgesA": 0, "surgesD": 0, "straysA": 0, "straysD": 0, "voidA": false, "voidD": false,
		"claimA": [], "claimD": [], "aiA": [], "aiD": [], "prevA": DirGrapple._bits(A.input), "prevD": DirGrapple._bits(D.input), "letGo": ""}
	var offs: Array = bs.aiOffsets
	var hit: float = float(bs.aiHit.get(DirAI.level if DirAI.level != "" else String(DirAI.skill().level), bs.aiHit.medium))
	for side in ["A", "D"]:
		if (A if side == "A" else D).ai == null:
			continue
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
	DirCamIntent.exchange(S, ex, "clash")   # the camera-intent feed: the struggle's plan


## A cue of the struggle: actor, target, text, and the meeting point after it in x and amount.
static func _cue(S: SimState, f, o, name: String, text: String, mid: float, source: String = ""):
	SimFx.cue(S, f, name, text, source)
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(o)) if o != null else -1.0
	e.x = mid
	e.amount = mid
	return e


## The struggle's end, for VFX's shockwave and World's crater (beamStruggle.endEvent; Orb's note): the cue beam_clash_end. text the
## outcome (win: overwhelmed or run out on his side; break: he let go; draw: they detonated), x, y, z the meeting point in the world,
## amount the point (0 at A's hands to 1 at D's), energy the clash's (both beams' damage at the pair's mean tier), winner and loser
## their slots (-1 at a draw), n the surges it took, source the ending as beam_end names it (time, overwhelmed, letgo, detonate). Called
## once for any ending. Off, nothing is emitted. (World's struggle-meeting-point call goes here, ahead of the switch: its own.)
static func _clashEnd(S: SimState, A, D, W, L, outcome: String, how: String, mid: float, st: Dictionary) -> void:
	if not bool(_bs().get("endEvent", false)):
		return
	SimFx.cue(S, W if W != null else A, "beam_clash_end", outcome, how)
	var e = S.out.fx[S.out.fx.size() - 1]
	e.x = SimWrap.wrap(A.x + SimWrap.sdx(A.x, D.x) * mid)
	e.y = A.y + 38.0 + (D.y - A.y) * mid
	e.z = A.z + (D.z - A.z) * mid
	e.amount = mid
	e.energy = 2.0 * 260.0 * sigDamageMul() * (float(A.tier) + float(D.tier)) * 0.5
	e.winner = float(S.fighters.find(W)) if W != null else -1.0
	e.loser = float(S.fighters.find(L)) if L != null else -1.0
	e.n = int(st.surgesA) + int(st.surgesD)


static func _struggleBeat(ex):
	for b in ex.beats:
		if not b.done and b.op == "clashResolve" and b.args != null and b.args.has("bs"):
			return b
	return null


## Once a tick in a struggle (DirExchange's tick): the pulse's cue, the presses, and its end. A player's press is read
## from his intent by Controls' reader, so every layout surges and lets go as docs/controls/struggle-input.md says.
static func clashTick(S: SimState, ex) -> void:
	if S.game.clash == null:
		return
	var rb = _struggleBeat(ex)
	if rb == null:
		return
	var st: Dictionary = rb.args.bs
	var bs: Dictionary = _bs()
	var rel: int = int(round((ex.t - float(st.t0)) * DirData.TICKS_PER_SEC))
	var pt: int = int(bs.pulseTicks)
	if rel > 0 and rel % pt == 0 and rel / pt <= int(bs.pulses):
		var e = _cue(S, ex.A, ex.D, "beam_pulse", "", float(st.mid))
		e.k = rel / pt   # the pulse, 1 to pulses
		e.n = S.tick
	for side in ["A", "D"]:
		var f = ex.A if side == "A" else ex.D
		if f.ai != null:
			if (st["ai" + side] as Array).has(rel):
				_press(S, ex, f, side, rel, st, bs)
			continue
		var what: String = SimPressRead.struggle_press(DirGrapple._bitsIntent(int(st["prev" + side])), f.input) if rel > 0 else "none"   # a press on the tick it starts was for what came before
		st["prev" + side] = DirGrapple._bits(f.input)
		if what == "letgo":
			_letGo(S, ex, f, side, rel - DirBrawl._waited(f), st, bs)
		elif what == "surge":
			_press(S, ex, f, side, rel - DirBrawl._waited(f), st, bs)
	var mid: float = float(st.mid)
	if mid >= 1.0 or mid <= 0.0 or st.letGo != "" or rel >= pt * int(bs.pulses) + int(bs.surgeTicks):
		rb.t = ex.t   # it ends: the resolve beat runs on the next tick


## The pulse a press at rel answers, or 0: the nearest, if it is within surgeTicks.
static func _pulseOf(rel: int, bs: Dictionary) -> int:
	var pt: int = int(bs.pulseTicks)
	var k: int = int(round(float(rel) / float(pt)))
	return k if k >= 1 and k <= int(bs.pulses) and absi(rel - k * pt) <= int(bs.surgeTicks) else 0


## One press of X, Y or B. The first in a pulse's window is a surge toward the rival, sharp within sharpTicks, and near
## his own hands (comebackZone) times comebackMul. A press off the pulse, or a second press in a window, is a stray: it
## moves nothing and voids his next surge, so a masher does as well as a fighter who doesn't press, and no worse.
static func _press(S: SimState, ex, f, side: String, rel: int, st: Dictionary, bs: Dictionary) -> void:
	var o = ex.D if side == "A" else ex.A
	var k: int = _pulseOf(rel, bs)
	var claim: Array = st["claim" + side]
	var was: float = float(st.mid)
	if k == 0 or claim.has(k):
		st["void" + side] = true
		st["strays" + side] = int(st["strays" + side]) + 1
		_cue(S, f, o, "beam_stray", "", was).k = k
		return
	claim.append(k)
	if st["void" + side]:
		st["void" + side] = false
		_cue(S, f, o, "beam_stray", "void", was).k = k
		return
	var sharp: bool = absi(rel - k * int(bs.pulseTicks)) <= int(bs.sharpTicks)
	var amt: float = float(bs.sharp) if sharp else float(bs.surge)
	if (was if side == "A" else 1.0 - was) <= float(bs.comebackZone):
		amt *= float(bs.comebackMul)   # the comeback: a surge from close to his own hands pushes harder
	var mid: float = clampf(was + (amt if side == "A" else -amt), 0.0, 1.0)
	st.mid = mid
	S.game.clash.mid = mid
	st["surges" + side] = int(st["surges" + side]) + 1
	_cue(S, f, o, "beam_surge", "sharp" if sharp else "surge", mid).k = k


## A press of A, the gamble for the side that is losing. On the pulse he slips aside (the resolve beat plays it). Off it
## he is caught letting go, and the point is at him.
static func _letGo(S: SimState, ex, f, side: String, rel: int, st: Dictionary, bs: Dictionary) -> void:
	if st.letGo != "":
		return
	if _pulseOf(rel, bs) != 0:
		st.letGo = side
		return
	var mid: float = 0.0 if side == "A" else 1.0
	st.mid = mid
	S.game.clash.mid = mid


## The struggle's end (the clashResolve beat with its state). The point at a fighter: he is overwhelmed, taking the
## winner's beam and part of his own, launched along the beam's line, which carves what is there. A let-go on the pulse:
## the rival's beam carries on past him and carves, and he takes a share of it with no launch. On time within drawBand of
## the middle: the beams detonate where they meet, both are thrown back and take a share of the other's beam, and the
## ground there craters by the higher tier. On time further over: the side it is on takes a share, with no launch.
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
	var slip: bool = st.letGo != ""
	if slip or mid >= 1.0 or mid <= 0.0:
		var Wn = (D if st.letGo == "A" else A) if slip else (A if mid >= 1.0 else D)
		var Ls = A if Wn == D else D
		var dxs: float = SimWrap.sdx(Wn.x, Ls.x)
		var dyy: float = (Ls.y + 36.0) - (Wn.y + 38.0)
		var L: float = SimDamage.jor(SimDetMath.hypot(dxs, dyy), 1.0)
		var ux: float = dxs / L
		var uy: float = dyy / L
		var len: float = SimMathx.jmin(4200.0 * SimConst.WS, L + float(Wn.ld.beamOvershoot[_tierIx(Wn)]) * SimConst.WS)
		fireBeam(S, Wn, Wn.x, Wn.y + 38.0, ux, uy, len, String(args.variant))
		if slip:
			SimFx.afterimage(S, Ls)
			SimDamage.hit(S, ex, Wn, Ls, beam * float(bs.timeLoss.share), {"ignoreStance": true, "stop": 0.12, "shake": 12.0, "big": true})
			_cue(S, Wn, Ls, "beam_end", "time", mid, "letgo")
			_clashEnd(S, A, D, Wn, Ls, "break", "letgo", mid, st)
			SimEvents.feed(S, Ls.name + " LETS GO", "he slips aside and the beam carries on past him")
			if S.game.ko == null:
				DirExchange.decisive(S, ex, Wn, Ls, "beam_clash")
		else:
			var ov: Dictionary = bs.overwhelm
			Ls.state = "locked"
			SimDamage.hit(S, ex, Wn, Ls, beam * (float(ov.winnerBeam) + float(ov.ownBeam)), {"ignoreStance": true, "stop": 0.16, "shake": 18.0, "big": true})
			_blast(S, Wn, Ls.x, Ls.y + 30.0, (70.0 + Wn.tier * 32.0) * SimConst.WS)
			_cue(S, Wn, Ls, "beam_end", "overwhelmed", mid)
			_clashEnd(S, A, D, Wn, Ls, "win", "overwhelmed", mid, st)
			SimEvents.feed(S, Ls.name + " OVERWHELMED", "the meeting point reached him")
			if S.game.ko == null:
				var aim: float = Wn.input.my * float(ov.stickUy) if Wn.ai == null else 0.0   # up or down aims the overwhelm
				DirLaunch.doLaunch(S, Wn, Ls, {"ux": ux, "uy": uy * 0.6 + 0.12 + aim}, 2600.0, true)
				DirExchange.decisive(S, ex, Wn, Ls, "beam_clash")
	elif absf(mid - 0.5) <= float(bs.drawBand):
		var hi = A if A.tier >= D.tier else D
		_blast(S, hi, SimWrap.wrap(A.x + SimWrap.sdx(A.x, D.x) * mid), A.y + 38.0 + (D.y - A.y) * mid - 8.0, (70.0 + hi.tier * 32.0) * SimConst.WS)
		var share: float = float(bs.detonate.otherBeam)
		SimDamage.hit(S, ex, D, A, beam * share, {"ignoreStance": true, "stop": 0.16, "shake": 18.0, "big": true})
		if S.game.ko == null:
			SimDamage.hit(S, ex, A, D, beam * share, {"ignoreStance": true, "stop": 0.16, "shake": 18.0, "big": true})
		if S.game.ko == null:
			DirLaunch.knockBack(S, D, A)
			DirLaunch.knockBack(S, A, D)
		ex.loser = -1
		_cue(S, null, null, "beam_end", "detonate", mid)
		_clashEnd(S, A, D, null, null, "draw", "detonate", mid, st)
		SimEvents.feed(S, "THE BEAMS DETONATE", "the struggle ran out in the middle")
	else:
		var Wn2 = A if mid > 0.5 else D
		var Ls2 = D if mid > 0.5 else A
		SimDamage.hit(S, ex, Wn2, Ls2, beam * float(bs.timeLoss.share), {"ignoreStance": true, "stop": 0.12, "shake": 12.0, "big": true})
		_cue(S, Wn2, Ls2, "beam_end", "time", mid)
		_clashEnd(S, A, D, Wn2, Ls2, "win", "time", mid, st)
		SimEvents.feed(S, Ls2.name + " GIVES WAY", "the struggle ran out on his side")
		if S.game.ko == null:
			DirExchange.decisive(S, ex, Wn2, Ls2, "beam_clash")
	DirExchange.schedule(ex, ex.t + 1.0, "nop")


## Beat "clashResolve": the clash winner's beam overpowers the loser.
static func opClashResolve(S: SimState, ex, args) -> void:
	if args.has("bs"):
		_resolveStruggle(S, ex, args)
		return
	var A = ex.A
	var D = ex.D
	var variant: String = args.variant
	var Wn = A if args.aw else D
	var Ls = D if args.aw else A
	S.game.clash = null
	if S.game.ko != null:
		return
	var dxs: float = SimWrap.sdx(Wn.x, Ls.x)
	var dyy: float = (Ls.y + 36.0) - (Wn.y + 38.0)
	var L: float = SimDamage.jor(SimDetMath.hypot(dxs, dyy), 1.0)
	var ux: float = dxs / L
	var uy: float = dyy / L
	var len: float = SimMathx.jmin(4200.0 * SimConst.WS, L + float(Wn.ld.beamOvershoot[_tierIx(Wn)]) * SimConst.WS)
	fireBeam(S, Wn, Wn.x, Wn.y + 38.0, ux, uy, len, variant)
	Ls.state = "locked"
	SimDamage.hit(S, ex, Wn, Ls, 260.0 * sigDamageMul(), {"ignoreStance": true, "stop": 0.16, "shake": 18.0, "big": true})
	_blast(S, Wn, Ls.x, Ls.y + 30.0, (70.0 + Wn.tier * 32.0) * SimConst.WS)
	if S.game.ko == null:
		DirLaunch.doLaunch(S, Wn, Ls, {"ux": ux, "uy": uy * 0.6 + 0.12}, 2600.0, true)
		DirExchange.decisive(S, ex, Wn, Ls, "beam_clash")


## Past its cap a beam leaves each further building standing at this share of its hp, scorched, so the path still reads.
const BEAM_KEEP: float = 0.25


static func _tierIx(f) -> int:
	return clampi(int(f.tier) - 1, 0, 3)


## A blast that belongs to A's beam (its impact, or a clash's end): the beam's structure factor and what is left of its
## cap apply, and the buildings it levels count against the beam. With no live beam of A, the gate is taken from A's tier.
static func _blast(S: SimState, A, x: float, y: float, r: float) -> void:
	var bm = null
	for b in S.beams:
		if b.A == A:
			bm = b
	if bm == null:
		WorldStructures.explode(S, x, y, r, A, float(A.ld.beamStructure[_tierIx(A)]), maxi(1, int(SimMathx.jround(float(A.ld.beamLevelCapShare[_tierIx(A)]) * WorldStructures.ringCount(S)))), BEAM_KEEP)
		return
	bm.levelled += WorldStructures.explode(S, x, y, r, A, bm.sf, maxi(0, bm.cap - bm.levelled), BEAM_KEEP)


static func fireBeam(S: SimState, A, ox: float, oy: float, ux: float, uy: float, len: float, variant: String) -> void:
	var b := SimState.Beam.new()
	b.A = A; b.ox = ox; b.oy = oy; b.ux = ux; b.uy = uy; b.len = len
	b.p = 0.0; b.t = 0.0; b.life = 0.95; b.w = 24.0 + A.tier * 9.0; b.variant = variant; b.col = A.aura
	b.pw = WorldCrater.beamPower(A)
	# The tier gate (balance-targets.md §15), fixed at fire time from the firer's ladder: how hard the beam bites
	# structures, and how many buildings it may level (a share of all of them, at least one). The bite is times the
	# variant's structMul (data/combat/sigvariants.json), for the whole beam.
	b.sf = float(A.ld.beamStructure[_tierIx(A)]) * float(DirData.sigByName(variant).get("structMul", 1.0))
	b.cap = maxi(1, int(SimMathx.jround(float(A.ld.beamLevelCapShare[_tierIx(A)]) * WorldStructures.ringCount(S))))
	S.beams.append(b)
	if DirInterrupt.on():
		DirInterrupt.si(A, DirInterrupt.BEAM_TRAVEL, 0)   # a beam at its own speed, unless DirBeamPlay.fire says otherwise
	SimFx.shake(S, 14.0, ox)


static func sampleBeam(S: SimState, b, s: float) -> void:
	SimField.far()
	_sampleBeamRead(S, b, s)
	SimField.near()


static func _sampleBeamRead(S: SimState, b, s: float) -> void:
	var A = b.A
	var P: float = b.pw   # the beam-power scalar (world/crater.gd): tier and charge; it equals the tier mid-band
	var x: float = SimWrap.wrap(b.ox + b.ux * s)
	var y: float = b.oy + b.uy * s
	var g: float = WorldTerrain.groundY(S, x)
	# The variant's row (data/combat/sigvariants.json): its groove factors, structure radius, trees and looks.
	var vr: Dictionary = DirData.sigByName(b.variant)
	var fx: Dictionary = vr.get("fx", {})
	var sc: Array = vr.get("scorch", [1.0, 1.0])
	var pm: Array = DirSigAfter.persMul(S, A, x)   # biomes W2: the personality term near people ([1, 1] off)
	if pm[0] != 1.0:
		sc = [sc[0], float(sc[1]) * pm[0]]
	if y < g + WorldCrater.beamReach(P):
		# Scorch: a groove carved to a target depth along the ground, not a crater per sample (sim quirk 7 is gone).
		WorldCrater.scorch(S, x, P, b.variant, A, NAN, sc)
		if not b.struck and b.uy <= -WorldCrater.BEAM_STRIKE_SLOPE:
			b.struck = true   # a steep beam digs one strike crater where it first meets the ground
			WorldCrater.dig(S, x, WorldCrater.beamStrikeEnergy(P), A, "beam", 0.0, 1.0, true)
		SimFx.dust(S, x, g + 8.0, 1, String(fx.get("dust", "#9b8f7e")))
		if fx.has("sparks"):
			SimFx.spark(S, x, g + 6.0, int(fx.sparks.n), String(fx.sparks.col), float(fx.sparks.speed))
	b.levelled += WorldStructures.damageArea(S, x, y, (26.0 + P * 8.0) * SimConst.WS * float(vr.get("areaMul", 1.0)) * pm[0], (110.0 + P * 75.0) * b.sf * pm[1], A, false, 0.0, maxi(0, b.cap - b.levelled), BEAM_KEEP, 1.0, String(vr.get("trees", "area")))
	if y < WorldWater.seaTop(S, x) + 30.0:
		SimFx.beamSplash(S, x)   # the consumer rolls the prototype's 60% splash
	if fx.has("fire") and y < g + float(fx.fire.withinAbove) * SimConst.WS:
		SimFx.fire(S, x, g, 1)


static func beamStep(S: SimState, dt: float) -> void:
	for i in range(S.beams.size() - 1, -1, -1):
		var b = S.beams[i]
		b.t += dt
		var np: float = SimMathx.jmin(1.0, b.t / 0.22)
		var tv: int = DirBeamPlay.travel(S, b)
		if tv > 0:
			np = DirBeamPlay.front(b, tv)   # the beam plays: it reaches the defender at a set tick, at any distance
		var s0: float = b.p * b.len
		var s1: float = np * b.len
		if b.stopAt >= 0.0:
			s1 = minf(s1, b.stopAt)   # 2v2: it stopped on an enemy of the other fight (SimCross.beams)
		var was: float = b.p
		b.p = np
		var s: float = s0
		while s < s1:
			sampleBeam(S, b, s)
			s += 36.0 * SimConst.WS
		if was < 1.0 and np >= 1.0:
			DirSigAfter.carved(S, b)   # biomes W2: the path is carved; its row's aftermath is laid on the groove
		if b.t > b.life:
			if tv > 0:
				DirInterrupt.si(b.A, DirInterrupt.BEAM_TRAVEL, 0)
			S.beams.remove_at(i)
	DirSigAfter.craterShapes(S)   # biomes W2: crater_shape for the shaped craters dug this tick
