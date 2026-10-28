class_name DirCalm
## The calm-moment turn, the director's part (docs/director/calm-turn.md; Game Design's rulings-2026-10-19b.md section 1
## with 1e, and rulings-2026-10-22.md 5a; the EP's rulings of 2026-10-22: no ring read on the swap tick, the warm rate at
## most 32; World's WorldEpoch, docs/world/calm-turn-world.md). Behind data/director/interrupts.json calmTurn.enabled
## (false) and World's own switch (rings.json turn.on, or setup.arena.turn): with either off nothing here runs.
##  - The ask. At a pausing form step (DirExchange._transforms: a full or a short pause; a live one freezes nothing) the
##    pivot is the pair's midpoint exactly as the pause starts, and nothing moves under it, so one ring is warmed and only
##    a bearing that keeps the ground rule there is taken. At a launch's send the pivot is predicted (between the
##    landing's rest and the launcher), so the chosen ring and World's smallest bearing's (the fallback) are warmed.
##  - The warm-up is the sim's (World's tick reads k columns of each ring a tick; no host call). choose passes k and the
##    fallback: the ring's columns over the ticks to the moment (Rendering's rule), within the budget of warmCols to
##    warmColsMax (32) a tick shared by the rings (a landing's two at most 16 each, a form step's one up to 32). When that
##    is not enough by the moment, the pick waits, warming, for a later moment: a pick still waiting is kept at a new send
##    or pause whose pair keeps its ground rule (its warm work kept), and only otherwise cancelled for a new ask.
##  - The ground rule (5a; World's moveMax): a turn moves the ground under each fighter at most moveMax units (his
##    distance from the pivot times the sine of the angle). The hold needs a read ring whose angle keeps it where they
##    stand ("ground" otherwise); World's tick swaps to the largest such.
##  - The hold (WorldEpoch.tick's second argument, each live tick): the warm read done, the ground rule, the director's
##    part of calm (no exchange, approach, beam clash, taunt, flip or counter-rush, no attack waiting in either queue, no
##    open finisher), and a moment: the first formTicks live ticks after a pausing form step's pause, or a fighter at rest
##    from a send within landedTicks with both down or set (under setSpeed). World adds its own check and swaps.
##  - The pick: each place a candidate brings into view scores by its kind (score); a tie goes to the smaller bearing.
## State: two f.act.dirI slots after DirPress's (the tick each came to rest, Game Design's 7b), written only while the
## calm turn is on; otherwise it reads the match and World's epoch, and writes only through World's ask, choose and cancel.
## Not here: a set piece's cutaway as a moment (World's calm refuses an open set piece).


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("calmTurn", {})


static func on(S: SimState) -> bool:
	return bool(cfg().get("enabled", false)) and S.epoch != null


## A gen 2 planet's slower read (Game Design's rulings-2026-10-26 item 28; docs/architecture/calm-turn-read.md): a
## pick's rings are read gen2Cols columns a tick in all (calmTurn.warmColsGen2), so no tick hitches on a slow device.
## A gen 1 planet's pick is as it always was, its k each ring's.
static func gen2(S: SimState) -> bool:
	return (int(S.planetGen) if int(S.planetGen) > 0 else int(WorldClimate.data().get("gen", 1))) >= 2


static func gen2Cols() -> int:
	return maxi(1, int(cfg().get("warmColsGen2", 12)))


## Whether World reads a pick's k as the total a tick across its rings: its turn.warmTotal, on a gen 2 planet only.
static func totalK(S: SimState) -> bool:
	return gen2(S) and int(WorldEpoch.data().get("warmTotal", 0)) == 1


const CM_WAS: int = 0    # his state at the director's last tick: 0 other, 1 launched, 2 down
const CM_REST: int = 1   # the live tick he came to rest (his journey's end: down after the slide, or out of a flight
                         # into the water), plus 1; 0 none
const CM_SP: int = 2     # the live tick a set piece of his ended (a beam struggle, a clash exchange: rulings-2026-10-23 3), plus 1
const CM_N: int = 3


## A beam struggle starts (DirBeam.startClash): its end is coming, due at its exchange's end. World is asked now, about
## the pair as it stands, so the ring is warm by then (the smallest bearing: the loser is blown away at its end).
static func atSetPiece(S: SimState, ex, due: int) -> void:
	if not on(S) or ex == null:
		return
	var A = ex.A
	var D = ex.D
	var margin: float = float(cfg().get("predictMargin", 1500.0))
	if S.epoch.next != null and _keeps(S, [A.x, D.x], margin):
		return   # the pick waiting keeps the ground rule here: it may take this moment
	if not _clear(S):
		return
	var side: int = 1 if SimWrap.sdx(A.x, D.x) >= 0.0 else -1
	_ask(S, A, D, "setpiece", SimWrap.wrap(A.x + 0.5 * SimWrap.sdx(A.x, D.x)), side, due, 1.0e9)   # (a spread no bearing fits: the smallest, one ring)


## An exchange ended (DirExchange.endEx): a set piece's end (a beam struggle, a clash exchange) opens a moment.
static func onSetPieceEnd(S: SimState, ex) -> void:
	if not on(S) or ex == null:
		return
	if ex.kind != "sig" and not String(ex.tag).contains("CLASH"):
		return
	for f in [ex.A, ex.D]:
		_s(f, CM_SP, DirBrawl._now(S) + 1)


static func _base() -> int:
	if _baseAt < 0:
		_baseAt = DirRecoil._base() + DirRecoil.RC_N   # after the recoil flips' (the chain's front holds the mash run's and the press wait's)
	return _baseAt   # a constant: the chain is walked once


static var _baseAt: int = -1


static func _g(f, k: int) -> int:
	var i: int = _base() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	var b: int = _base()
	if f.act.dirI.size() < b + CM_N:   # sized: every part before this one is (it follows DirGrapple.END)
		DirGrapple._size(f)
		if f.act.dirI.size() < b + CM_N:
			f.act.dirI.resize(b + CM_N)
	f.act.dirI[b + k] = v


## Once a live tick (DirExchange.dirUpdate), while the calm turn is on: the tick each fighter comes to rest (Game Design's
## 7b: a landing's moment starts at the end of his journey, the slide's end, not at his first contact).
static func tick(S: SimState) -> void:
	if not on(S):
		return
	for f in S.fighters:
		var d: int = 2 if f.state == "down" else (1 if f.state == "launched" else 0)
		var was: int = _g(f, CM_WAS)
		if (d == 2 and was != 2) or (was == 1 and d == 0):
			_s(f, CM_REST, DirBrawl._now(S) + 1)   # down, or out of his flight (a water landing counts)
		if d != was:
			_s(f, CM_WAS, d)


## A pausing form step (DirExchange._transforms, at its pause's request; pz: SimPause.request's answer): a moment.
static func atPause(S: SimState, f, pz: Dictionary) -> void:
	if not on(S) or int(pz.get("version", SimPause.LIVE)) == SimPause.LIVE or int(pz.get("ticks", 0)) <= 0:
		return
	var lead: int = int(pz.ticks)
	if S.epoch.next != null and _groundFits(S) and S.tick - int(S.epoch.next.get("tick", S.tick)) + lead >= warmTicks(S):
		return   # the pick waiting keeps the ground rule here and is warm by the pause's end: it takes this moment
	var cols: int = int(S.epoch.ring.get("cols", SimConst.NC))
	if int(ceil(float(cols) / float(lead))) > (gen2Cols() if gen2(S) else int(cfg().get("warmColsMax", 32))):
		return   # a new ring can't be warm by the pause's end: the next moment (on gen 2 the ready tell began the warm)
	var o = SimRoster.opp(S, f)
	var spread: float = 0.5 * absf(SimWrap.sdx(f.x, o.x))
	if spread * _sinDeg(_leastDeg()) > _moveMax():
		return   # not even World's smallest turn keeps the ground under them here
	if not _clear(S):
		return
	var side: int = 1 if SimWrap.sdx(f.x, o.x) >= 0.0 else -1
	_ask(S, f, o, "form", SimWrap.wrap(f.x + 0.5 * SimWrap.sdx(f.x, o.x)), side, S.tick + lead, spread)


## A form step is ready (SimFx.transformReady, its ready tell), on a gen 2 planet: the warm begins here, the earliest
## moment the choice is known (Game Design's rulings-2026-10-26 item 28), since at gen2Cols a tick a ring takes longer
## than a pause. The pivot is predicted (the pair's midpoint now: they may move before the step), so World's smallest
## bearing is warmed as the fallback, as a landing's. A pick already waiting is kept. The moment is the step's pause, or
## a later one (the waiting rule).
static func atReady(S: SimState, f) -> void:
	if not on(S) or not gen2(S) or S.epoch.next != null:
		return
	var o = SimRoster.opp(S, f)
	if o == null:
		return
	var spread: float = 0.5 * absf(SimWrap.sdx(f.x, o.x)) + float(cfg().get("predictMargin", 1500.0))
	var side: int = 1 if SimWrap.sdx(f.x, o.x) >= 0.0 else -1
	var cols: int = int(S.epoch.ring.get("cols", SimConst.NC))
	var due: int = S.tick + int(ceil(float(cols) / float(maxi(1, gen2Cols() / 2)))) + _prep()   # read at K in all, two rings
	_ask(S, f, o, "ready", SimWrap.wrap(f.x + 0.5 * SimWrap.sdx(f.x, o.x)), side, due, spread)


## A launch is sent (DirMelee.launchBeat, after doLaunch): the moment after its landing is coming.
static func atSend(S: SimState, att, tgt, best: Dictionary) -> void:
	if not on(S) or tgt.launchSpecial or String(best.get("name", "")) == "KNOCK BACK":
		return
	var p = best.get("p")
	var rest: float = float(p.get("x", tgt.x)) if p is Dictionary else tgt.x   # where he comes to rest (the planner's estimate, his slide in it)
	var margin: float = float(cfg().get("predictMargin", 1500.0))
	if S.epoch.next != null and _keeps(S, [rest, att.x], margin):
		return   # the pick waiting keeps the ground rule at this landing: its warm read goes on, for this moment or a later one
	if not _clear(S):
		return
	var mid: float = SimWrap.wrap(rest + 0.5 * SimWrap.sdx(rest, att.x))   # the pair's midpoint at the landing: the launcher where he stands
	var ux: float = float(best.get("ux", 0.0))   # the send's way along the ring: the side the fight was pushed
	var side: int = (1 if ux > 0.0 else -1) if ux != 0.0 else (1 if SimWrap.sdx(att.x, tgt.x) >= 0.0 else -1)
	var due: int = S.tick + int(round(float(p.get("t", 1.0)) * DirData.TICKS_PER_SEC)) if p is Dictionary else S.tick
	_ask(S, att, tgt, "landed", mid, side, due, 0.5 * absf(SimWrap.sdx(rest, att.x)) + margin)


## A pick still waiting gives way to a new ask (World's cancel). False when it can't.
static func _clear(S: SimState) -> bool:
	if S.epoch.next == null:
		return true
	var cn := Callable(WorldEpoch, "cancel")
	if not cn.is_valid():
		return false
	cn.call(S)
	return true


## Ask World for the turns on a side, and pick the best for a fighter `spread` from the pivot.
static func _ask(S: SimState, a, b, why: String, mid: float, side: int, due: int, spread: float) -> void:
	var cands: Array = WorldEpoch.ask(S, why, mid, side, due)
	if cands.is_empty():
		return
	var i: int = pick(S, cands, a, spread, why != "form")
	if i < 0:
		return   # a form step: no bearing keeps the ground under them within moveMax, so no turn at this moment
	var fb: float = 0.0 if why == "form" else _leastDeg()   # a form pick's pivot is exact: one ring
	var rings: int = 2 if fb > 0.0 and fb < absf(float(cands[i].bearing)) - 0.0001 else 1
	var k: int = _rate(int(cands[i].spec.get("cols", SimConst.NC)), due - S.tick - (_prep() - 1), rings)   # read by the moment less World's preparation
	if gen2(S):   # gen 2: K a tick in all, whatever the lead (the total when World shares it, else each ring's share)
		k = gen2Cols() if totalK(S) else maxi(1, gen2Cols() / rings)
	WorldEpoch.choose(S, i, k, fb)   # the sim reads k columns of each ring a tick (World's tick; on gen 2 with warmTotal, k in all)
	SimFx.cue(S, a, "calm_turn", "asked", why)
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(b))
	e.n = due
	e.x = mid
	e.amount = float(cands[i].bearing)
	e.k = float(k)
	e.dur = fb


## World's candidates on a side: the index of the best scoring one whose bearing keeps the ground under a fighter
## `spread` from the pivot within moveMax (a tie: the smaller bearing); when none does, the smallest bearing if
## `orLeast` (a landing: the hold decides with where they stand), else -1.
static func pick(S: SimState, cands: Array, by, spread: float, orLeast: bool = true) -> int:
	var sc: Dictionary = cfg().get("score", {})
	var gm: float = _moveMax()
	var best: int = -1
	var bestS: float = -INF
	var least: int = 0
	for k in range(cands.size()):
		if absf(float(cands[k].bearing)) < absf(float(cands[least].bearing)):
			least = k
		if spread * _sinDeg(absf(float(cands[k].bearing))) > gm:
			continue
		var s: float = 0.0
		for pl in cands[k].places:
			var kind: String = String(pl.get("kind", ""))
			var owner: int = int(pl.get("owner", -1))
			if owner >= 0 and owner != S.fighters.find(by):
				s += float(sc.get("rivalHome", 5.0))
			elif owner >= 0:
				s += float(sc.get("ownHome", 2.0))
			else:
				s += float(sc.get(kind, 0.0))
		if best < 0 or s > bestS + 0.0001 or (absf(s - bestS) <= 0.0001 and absf(float(cands[k].bearing)) < absf(float(cands[best].bearing))):
			bestS = s
			best = k
	if best >= 0 or not orLeast:
		return best
	return least


static var _PI: float = SimMathx.PI   # the sim's own pi: no engine trig in the sim


## The sine of an angle in degrees: the sim's own (SimDetMath), as World's turn uses.
static func _sinDeg(deg: float) -> float:
	return SimDetMath.sin(deg * _PI / 180.0)


## World's ground rule (rings.json turn): the most the ground under a fighter may move at a turn.
static func _moveMax() -> float:
	return float(WorldEpoch.data().get("moveMax", 300.0))


## World's smallest bearing (rings.json turn.bearings), in degrees.
static func _leastDeg() -> float:
	var least: float = 90.0
	for b in WorldEpoch.data().get("bearings", []):
		least = minf(least, absf(float(b)))
	return least


## The waiting pick's fallback angle (degrees; World keeps it as choose set it): 0 none.
static func fallbackDeg(S: SimState) -> float:
	return float(S.epoch.next.get("fb", 0.0))


## The waiting pick keeps World's ground rule for bodies at xs, each `margin` further off: at its angle or the fallback's.
static func _keeps(S: SimState, xs: Array, margin: float = 0.0) -> bool:
	var pv: float = float(int(S.epoch.next.pc)) * SimConst.COL
	var smax: float = 0.0
	for x in xs:
		smax = maxf(smax, absf(SimWrap.sdx(float(x), pv)) + margin)
	var gm: float = _moveMax()
	if smax * _sinDeg(absf(float(S.epoch.next.get("bearing", 0.0)))) <= gm:
		return true
	var fb: float = fallbackDeg(S)
	return fb > 0.0 and smax * _sinDeg(fb) <= gm


## ... where the fighters stand, at an angle World has read (World's tick swaps to the largest warm one that keeps it).
static func _groundFits(S: SimState) -> bool:
	var pv: float = float(int(S.epoch.next.pc)) * SimConst.COL
	var smax: float = 0.0
	for f in S.fighters:
		smax = maxf(smax, absf(SimWrap.sdx(f.x, pv)))
	for a in WorldEpoch.warmAngles(S):
		if absf(float(a)) >= float(WorldEpoch.data().get("minDeg", 2.0)) - 0.0001 and smax * _sinDeg(absf(float(a))) <= _moveMax():
			return true
	return false


## The columns of each ring the sim reads a tick for a pick (Rendering's rule, the EP's budget): the ring's columns over
## the ticks to the moment, the budget warmCols to warmColsMax a tick shared by its rings (a landing's two: at most 16
## each; a form step's one: up to 32). choose passes it to World.
static func _rate(cols: int, lead: int, rings: int) -> int:
	var lo: int = maxi(1, int(cfg().get("warmCols", 16)) / rings)
	var hi: int = maxi(lo, int(cfg().get("warmColsMax", 32)) / rings)
	return clampi(int(ceil(float(cols) / float(maxi(1, lead)))), lo, hi)


## The waiting pick's rate (columns of each ring a tick: World keeps it as choose set it; on gen 2 with World's
## warmTotal it is the total, and each ring reads its share).
static func warmRate(S: SimState) -> int:
	var k: int = maxi(1, int(S.epoch.next.get("k", int(cfg().get("warmColsMax", 32)))))
	if totalK(S) and S.epoch.warm.size() > 1:
		return maxi(1, k / S.epoch.warm.size())
	return k


## The ticks the sim needs to read the waiting pick's rings at that rate, from the pick (each ring k columns a tick),
## and World's preparation after the reading (a ring is warm prepTicks after it is read: ade02e47).
static func warmTicks(S: SimState) -> int:
	var nx: Dictionary = S.epoch.next
	var cols: int = int(nx.spec.get("cols", SimConst.NC)) if nx.get("spec") is Dictionary else SimConst.NC
	return int(ceil(float(cols) / float(warmRate(S)))) + _prep() - 1


## World's preparation ticks (WorldEpoch.data().prepTicks), at least 1.
static func _prep() -> int:
	return maxi(1, int(WorldEpoch.data().get("prepTicks", 1)))


## A pausing form step's pause ended within formTicks live ticks: a moment, under the step's own camera.
static func _afterForm(S: SimState) -> bool:
	var p = S.pause
	return p.left == 0 and p.kind == SimPause.TRANSFORM and p.version != SimPause.LIVE and p.sinceEnd <= int(cfg().get("formTicks", 30))


## WorldEpoch.tick's hold, each live tick. With the director's calm turn off (calmTurn.enabled false) the director takes
## no part and holds nothing back: World's own calm decides, as before the hold existed (a turn World's own checks decide).
static func hold(S: SimState) -> bool:
	if not bool(cfg().get("enabled", false)):
		return true
	return why(S) == ""


## Why the hold is off now ("" when it holds): for the hold, and for the probes.
static func why(S: SimState) -> String:
	if not on(S) or S.epoch.next == null or S.game.ko != null:
		return "none"
	if WorldEpoch.warmAngles(S).is_empty():
		return "warming"
	if not _groundFits(S):
		return "ground"
	if S.dirS.ex != null:
		return "exchange"
	if DirBands.who(S) >= 0:
		return "approach"
	if S.game.clash != null:
		return "beam clash"
	var c: Dictionary = cfg()
	var form: bool = _afterForm(S)
	var settle: int = int(c.get("landedTicks", 45))
	var now: int = DirBrawl._now(S)
	var setV: float = float(c.get("setSpeed", 60.0))
	var landed: bool = false
	var still: bool = true
	for f in S.fighters:
		if DirBands.taunting(f) or DirRecoil.flipping(S, f) or DirRecoil.due(S, f):
			return "taunt or flip"
		if not SimAct.peek(f).is_empty():
			return "queued"   # an attack waiting: a turn never swallows a press
		if f.brink and f.brinkOpen:
			return "brink"   # a finisher may start
		var down: bool = f.state == "down"
		var set: bool = f.state == "free" and f.rush == null and SimDetMath.hypot(f.vx, f.vy) < setV
		if not (down or set):
			still = false
		if _g(f, CM_REST) > 0 and now - (_g(f, CM_REST) - 1) <= settle:
			landed = true   # he came to rest (his journey's end) within landedTicks live ticks (7b)
		if _g(f, CM_SP) > 0 and now - (_g(f, CM_SP) - 1) <= settle:
			landed = true   # a set piece of his ended within landedTicks (rulings-2026-10-23 3)
	if form:
		return ""   # the form step's moment: the burst may still be carrying the rival
	if not still:
		return "moving"
	return "" if landed else "no moment"
