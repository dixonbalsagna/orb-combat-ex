class_name DirOutside
extends RefCounted
## 2v2: a blow from outside (Game Design's "Hits across fights" 1 and 2, docs/design/two-v-two.md), on Simulation's SimCross
## (docs/architecture/cross-fights.md). A press of his with no exchange of his own running, when an enemy of the other fight is in reach
## and nearer than his own rival (or his own is out), is a single blow from outside: he goes to him and it lands only on an opening (a
## stun, a stagger or a daze, the recovery after a blow of his own or a whiff). If he isn't open, he hovers in reach up to waitSec for
## one, and if none comes it's a whiff: he's open whiffTicks. One blow from outside an opening. It lands in the other fight on its clock,
## through SimDamage.hit (his guard answers it), and never sends, knocks back or stuns. What it does there is landed's.
## Behind interrupts.json outside.enabled, or a setup's "outside" for its match (S.stage.outside), only with SimCross on. State: integers on f.act.dirI after DirStanceCost's.

const O_KEY: int = 0    # the enemy he's going for: his starting slot, 1 to 4; 0 none
const O_UNTIL: int = 1  # the live tick his hover ends, plus 1
const O_DONE: int = 2   # 1 once his blow has landed on this opening: no second until the enemy's been shut a tick
const O_KIND: int = 3   # the blow: 1 the light, 2 the heavy
const O_WARN: int = 4   # a beam of the other fight has him first on its line: 1 told, 2 told and the AI answers with a dodge
const O_TEAM: int = 5   # on the one struck: the S.tick a blow from outside last landed on him, plus 1
const O_APART: int = 6  # on the match's first body: the S.tick the pairs went apart, plus 1; 0 while they're together
const O_BRINK: int = 7  # 1 once his brink's call has gone, for this brink
const O_N: int = 8

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("outside", {})


static func on(S: SimState) -> bool:
	return SimCross.on(S) and enabled(S)


## Blows from outside in this match: the tools' force, else the setup's "outside" (S.stage.outside, Simulation's), else
## interrupts.json's outside.enabled.
static func enabled(S: SimState) -> bool:
	if _force >= 0:
		return _force == 1
	var o: int = S.stage.outside if S.stage != null else -1
	return o == 1 if o >= 0 else bool(cfg().get("enabled", false))


static func _b() -> int:
	return DirStanceCost._b() + DirStanceCost.C_SZ


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + O_N:
		f.act.dirI.resize(_b() + O_N)
	f.act.dirI[_b() + k] = v


static func _reach() -> float:
	return float(cfg().get("reachBh", 3.0)) * DirInterrupt.BH


## His attack press (DirExchange._request): true when it's a blow from outside, and taken.
static func takes(S: SimState, A, kind: String) -> bool:
	if not on(S) or (kind != "light" and kind != "heavy") or A.state != "free":
		return false
	var ex = DirBrawl.exOf(S)
	if ex != null and (ex.A == A or ex.D == A):
		return false   # his own exchange takes it
	var over: bool = S.game.ko != null   # his fight is finished: his focus is across, however far, and a press pursues
	var D = focusAcross(S, A, SimConst.W * 0.5 if over else _reach())
	if D == null:
		return false
	var travel: int = int(ceil(DirBands.dist(A, D) / (float(DirChaseTap.cfg().get("maxSpeed", 20000.0)) * SimConst.DT))) if over else 0
	_s(A, O_KEY, int(String(D.keys).substr(1)))
	_s(A, O_UNTIL, DirBrawl._now(S) + travel + int(ceil(float(cfg().get("waitSec", 0.5)) * DirData.TICKS_PER_SEC)) + 1)
	_s(A, O_KIND, 2 if kind == "heavy" else 1)
	_toward(S, A, D)
	SimFx.cue(S, A, "outside", "start", String(D.keys))
	return true


## One stun a string, across a team (Game Design): while a blow from outside landed on him inside teamRestunTicks, he isn't free of the
## team's blows, so a partner's new string doesn't let the stick stun him again (DirBrawl, at a string's start).
static func holdsStun(S: SimState, o) -> bool:
	if not on(S):
		return false
	var at: int = _g(o, O_TEAM)
	return at > 0 and S.tick - (at - 1) <= int(cfg().get("teamRestunTicks", 24))


## The pairs' time apart, kept once, on the match's first body, in fight 0's tick.
static func _apartClock(S: SimState) -> void:
	var f = DirSwing._anchor(S)
	if SimStage.together(S):
		if _g(f, O_APART) != 0:
			_s(f, O_APART, 0)
	elif _g(f, O_APART) == 0:
		_s(f, O_APART, S.tick + 1)


## The sends that bring the fights together (Game Design): once the pairs have been apart join.afterSec, a send scores the way of the
## other fight, for everyone, computer fighters too: join.w for a landing a sixth of the loop nearer it, less for less, and the same
## against one that takes him away. Nothing while a team is two on one. lx is the candidate's landing (DirLaunch.chooseLaunch).
static func joinScore(S: SimState, A, D, lx: float) -> float:
	if not on(S) or S.game.ko != null:
		return 0.0
	var st = S.stage
	var at: int = _g(DirSwing._anchor(S), O_APART)
	var c: Dictionary = cfg().get("join", {})
	if at == 0 or float(S.tick - (at - 1)) < float(c.get("afterSec", 60.0)) * DirData.TICKS_PER_SEC:
		return 0.0
	var sum: float = 0.0
	var n: int = 0
	var x0: float = 0.0
	for i in range(st.fights.size()):
		if i == st.cur:
			continue
		var r = st.fights[i]
		if r.game != null and r.game.ko != null:
			return 0.0   # two on one: the fights have met
		for g in r.fighters:
			if n == 0:
				x0 = g.x
			sum += SimWrap.sdx(x0, g.x)   # (from the other fight's own first: an average from here splits across the half ring)
			n += 1
	if n == 0:
		return 0.0
	var mid: float = SimWrap.wrap(x0 + sum / float(n))
	var cap: float = SimConst.W / 6.0
	var gain: float = clampf(absf(SimWrap.sdx(D.x, mid)) - absf(SimWrap.sdx(lx, mid)), -cap, cap)
	return float(c.get("w", 8.0)) * gain / cap


## The brink's call: on his brink's first moment, the cue brink_call, once a brink (Audio's line, UI's map). It's the rescue's cue.
static func _call(S: SimState, f) -> void:
	if not f.brink:
		if _g(f, O_BRINK) != 0:
			_s(f, O_BRINK, 0)
		return
	if _g(f, O_BRINK) == 0:
		_s(f, O_BRINK, 1)
		SimFx.cue(S, f, "brink_call", String(f.keys), "")
		SimEvents.feed(S, f.name + " CALLS", "on the brink: his partner's cue to come")


## His partner, in the other fight: the one who started on his team's other slot (p1 and p3, p2 and p4); null for none.
static func partnerOf(S: SimState, f):
	var k: int = int(String(f.keys).substr(1))
	return SimCross.body(S, "p" + str(((k - 1 + 2) % 4) + 1))


## The AI's input (DirAI.aiInput, after aiAnswer): a computer fighter whose fight is finished flies to the other fight, at its nearest
## enemy; one whose partner in the other fight is on the brink drops his own fight and comes, flat out, at the one who has him there. In
## reach and on an opening, his press is a blow from outside. True when it took the tick.
static func aiRescue(S: SimState, f, i) -> bool:
	if not on(S) or f.state != "free":
		return false
	var ex = DirBrawl.exOf(S)
	if ex != null and (ex.A == f or ex.D == f):
		return false
	var X = null
	var best: float = INF
	if S.game.ko != null:
		if f.out:
			return false
		if SimCross.enemies(S, SimCross.team(f)).is_empty():
			return false
		if _g(f, O_KEY) == 0:
			i.light = true   # whoever finishes first flies to the other fight, with no input needed: the press pursues, as a player's does
		return true
	else:
		var P = partnerOf(S, f)
		if P == null or not P.brink or S.fighters.has(P):
			return false
		for g in SimCross.enemies(S, SimCross.team(f)):
			var d: float = absf(SimWrap.sdx(P.x, g.x))
			if d < best:
				best = d
				X = g
	if X == null:
		return false
	var dx: float = SimWrap.sdx(f.x, X.x)
	if absf(dx) > _reach() * 0.8:
		i.mx = signf(dx)
		i.dash = true
		i.my = clampf((X.y - f.y) / 400.0, -1.0, 1.0)
	elif open(S, X) and _g(f, O_KEY) == 0:
		i.light = true
	return true


## His focus, when it's across: the nearest enemy of the other fight within reach, if he's nearer than his own rival or his own fight
## is over; else null.
static func focusAcross(S: SimState, A, reach: float):
	var near: Array = SimCross.enemiesNear(S, A, reach)
	if near.is_empty():
		return null
	var D = near[0]
	var R = DirBrawl.rivalOf(S, A)
	if R != null and S.game.ko == null and DirBands.dist(A, R) <= DirBands.dist(A, D):
		return null   # his focus is his own rival
	return D


## A blast press with his focus across (DirBlast._fire): the enemy it's fired at, or null for his own rival as today.
static func shotAcross(S: SimState, A):
	if not on(S):
		return null
	var ex = DirBrawl.exOf(S)
	if ex != null and (ex.A == A or ex.D == A):
		return null
	return focusAcross(S, A, float(cfg().get("shotReachBh", 40.0)) * DirInterrupt.BH)


## He goes to him, beside him on this side, at the tap chase's speed.
static func _toward(S: SimState, A, D) -> void:
	var d: float = DirBands.dist(A, D)
	var r := SimState.Rush.new()
	r.tgt = D
	r.off = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(D.x, A.x)), -A.face) * float(DirData.contact().offset)
	var speed: float = float(DirChaseTap.cfg().get("maxSpeed", 20000.0))
	r.end = S.T + float(maxi(1, int(ceil(d / (speed * SimConst.DT))))) * SimConst.DT
	A.rush = r
	A.vx = 0.0
	A.vy = 0.0


## True while D is open: a stun, a stagger or a daze, or the recovery after a blow of his own or a whiff.
static func open(S: SimState, D) -> bool:
	return D.stunTicks > 0 or DirBrawl._g(D, DirBrawl.FREE_AT) > S.tick


## Once a live tick (DirExchange's update): each blow from outside on its way lands on an opening, waits, or whiffs.
static func tick(S: SimState, dt: float) -> void:
	if dt <= 0.0 or not on(S):
		return
	if S.stage.cur == 0:
		_apartClock(S)
	_beamStopped(S)
	for f in S.fighters:
		_warn(S, f)
		_call(S, f)
	for A in S.fighters:
		var key: int = _g(A, O_KEY)
		if key == 0:
			continue
		var D = SimCross.body(S, "p" + str(key))
		if D == null or A.state != "free" or D.state == "launched" or S.fighters.has(D):
			_s(A, O_KEY, 0)   # (gone, busy, or come into this fight: the rejoin)
			continue
		if not open(S, D):
			_s(A, O_DONE, 0)
		elif _g(A, O_DONE) == 0 and DirBands.dist(A, D) <= _reach():
			_hit(S, A, D)
			continue
		if DirBrawl._now(S) >= _g(A, O_UNTIL) - 1:
			_s(A, O_KEY, 0)
			DirBrawl._s(A, DirBrawl.FREE_AT, S.tick + int(cfg().get("whiffTicks", 20)))   # a whiff: he's open, as anyone is
			SimFx.cue(S, A, "outside", "whiff", String(D.keys))


## A beam of this fight's exchange stopped on an enemy of the other fight (SimCross.beams: b.stopAt): its own target takes no planned
## outcome, and the exchange ends. The one it stopped on took SimCross's hit in his own fight.
static func _beamStopped(S: SimState) -> void:
	var ex = DirBrawl.exOf(S)
	if ex == null or S.game.clash != null:
		return
	for b in S.beams:
		if b.A == ex.A and float(b.stopAt) >= 0.0:
			SimEvents.feed(S, "THE BEAM STOPS", ex.A.name + "'s beam met " + String(b.first) + " of the other fight first: " + ex.D.name + " is spared it")
			SimFx.cue(S, ex.A, "beam_stopped", String(b.first), "")
			DirExchange.endEx(S, ex)
			return


## Whoever is first on a beam's line from the other fight is told, once, from that moment (Game Design: diving onto the line gives you
## less time). The AI answers with a dodge at its level's aiDodge rate, drawn once a warning.
static func _warn(S: SimState, f) -> void:
	var b = SimCross.warned(S, f)
	if b == null:
		if _g(f, O_WARN) != 0:
			_s(f, O_WARN, 0)
		return
	if _g(f, O_WARN) != 0:
		return
	SimFx.cue(S, f, "beam_warn", String(b.A.keys) if b.A != null else "", "")
	var answers: bool = false
	if f.ai != null:
		var rates: Dictionary = cfg().get("aiDodge", {})
		var rate: float = float(rates.get(String(DirAI.skill().get("level", "medium")), 0.0))
		answers = SimRng.keyed(int(S.game.seed), "outside.warn", S.tick * 8 + S.fighters.find(f)) < rate
	_s(f, O_WARN, 2 if answers else 1)


## The AI's input (DirAI.aiInput, first): a warned AI that answers holds a dodge, and does nothing else that tick.
static func aiAnswer(S: SimState, f, i) -> bool:
	if not on(S) or _g(f, O_WARN) != 2:
		return false
	i.dodge = true
	return true


static func _hit(S: SimState, A, D) -> void:
	var heavy: bool = _g(A, O_KIND) == 2
	var dmg: float = float(DirZip.cfg().get("heavy", {}).get("damage", 132.0)) if heavy else float(DirBrawl.cfg().get("light", {}).get("damage", 26.0))
	dmg *= float(cfg().get("damageMul", 1.0))
	A.rush = null
	A.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(A.x, D.x)), A.face)
	SimCross.strike(S, A, D, dmg, {"kind": "outside", "weight": "heavy" if heavy else "light", "stop": 0.08 if heavy else 0.05, "shake": 9.0 if heavy else 5.0})
	_s(A, O_DONE, 1)
	_s(A, O_KEY, 0)
	SimFx.cue(S, A, "outside", "hit", String(D.keys))


## A blow from outside has landed on D, in his fight (SimCross._land, through SimDir.outsideLanded): on someone landing a finisher it
## breaks it, his victim free and still on the brink; on someone in a string it ends his string, his run with it (a blow he'd thrown
## still lands). Otherwise it's the damage and the hold, and the exchange runs on.
static func landed(S: SimState, A, D, _o: Dictionary) -> void:
	if not enabled(S):
		return
	SimFx.cue(S, D, "outside_hit", String(A.keys), "")
	_s(D, O_TEAM, S.tick + 1)
	var ex = DirBrawl.exOf(S)
	if ex == null or (ex.A != D and ex.D != D):
		return
	if ex.A == D and (ex.tpl == "finisher" or ex.branch == "finisher" or DirExchange.finisherPlanned(ex)):
		SimEvents.feed(S, "FINISHER BROKEN", A.name + "'s blow from outside breaks " + D.name + "'s finisher")
		SimFx.cue(S, D, "outside_hit", String(A.keys), "finisher")
		DirExchange.endEx(S, ex)
		return
	if DirBrawl.isBrawl(ex) and DirBrawl._g(D, DirBrawl.STR_ON) == 1:
		DirBrawl._strEnd(D)
