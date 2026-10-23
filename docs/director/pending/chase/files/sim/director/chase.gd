class_name DirChase
## The chase of a launch is the zip (Game Design's rulings-2026-10-22.md 7c; brawl-second-pass.md section 16, "chasing your
## own launch": a zip at a launched rival that follows the body as drawn travel and lands a blow that sends him on,
## nudged by the stick). Behind data/director/interrupts.json chase.enabled (false: nothing runs, no slot is written, no
## cue is sent).
##  - Who: a player pressing X or Y with LT held while his own launch flies (DirExchange.requestAttack, before the zip's),
##    or the AI, at a send of its own, on its level's chaseShare (data/director/ai.json; times chase.skyMul when the send
##    goes up into open sky), no sooner than its reaction time after the send. Either pays the zip's ki (the strike's 20,
##    the heavy's 30); without it there is no chase.
##  - The flight: a rush at the body, re-aimed each live tick, at speedMul (1.25) times the sent body's speed and never
##    under minSpeed (1,900 u/s). The approach cap of 4d doesn't hold it (the camera rides with it).
##  - The catch: within catchBh of him while he flies, the zip's blow lands (the strike's or the heavy's damage) and sends
##    him on: the launch planner from where he is, at sendForce, the chaser's stick its tilt. The chaser is free again in
##    the air, and may chase again with the ki.
##  - Too late: when his landing comes before the catch would, the chase flies to his landing and arrives there with it,
##    for the first move. It ends there, or at maxTicks.
## The cue: SimFx.cue kind "chase", text start, catch, landing or stopped, target the sent fighter's slot, n his launch
## number, amount the chase's speed.
## State: f.act.dirI slots after the wall kick's (sized only when the switch is on).

const CH_SEEN: int = 0    # the AI: the rival's launch number it has drawn for, plus 1
const CH_AT: int = 1      # the AI: the live tick it may start, plus 1; 0 no chase drawn
const CH_ON: int = 2      # the live tick his chase started, plus 1; 0 none
const CH_W: int = 3       # the chase's blow: 1 the strike (X), 2 the heavy (Y)
const CH_N: int = 4
const TILT_X: Array = [0.0, 0.7071, 1.0, 0.7071, 0.0, -0.7071, -1.0, -0.7071]   # the launch planner's tilts, 1 up then clockwise
const TILT_Y: Array = [1.0, 0.7071, 0.0, -0.7071, -1.0, -0.7071, 0.0, 0.7071]


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("chase", {})


static func on() -> bool:
	return DirInterrupt.on() and bool(cfg().get("enabled", false))


static func _base() -> int:
	return DirWallKick._base() + DirWallKick.WK_N


static func _g(f, k: int) -> int:
	var i: int = _base() + k
	return f.act.dirI[i] if i < f.act.dirI.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirGrapple._size(f)
	if f.act.dirI.size() < _base() + CH_N:
		f.act.dirI.resize(_base() + CH_N)
	f.act.dirI[_base() + k] = v


## True while f is chasing.
static func chasing(f) -> bool:
	return on() and _g(f, CH_ON) > 0


## The zip's price for the chase's blow.
static func _price(heavy: bool) -> float:
	var z: Dictionary = DirZip.cfg()
	return float((z.get("heavy", {}) if heavy else z.get("strike", {})).get("ki", 30.0 if heavy else 20.0))


## A player's attack press (DirExchange.requestAttack, before the zip's): true when the chase takes it. LT with X or Y while
## his own launch flies starts it; a press during it is spent.
static func takes(S: SimState, A, kind: String) -> bool:
	if not on() or A.ai != null or kind == "sig":
		return false
	if chasing(A):
		DirBrawl._ev(S, A, "press_ack", "chase", DirBrawl._cell(kind)).n = S.tick
		return true
	var D = SimRoster.opp(S, A)
	if (A.input.stanceMask & DirZip.LT) == 0 or D.state != "launched" or D.launchBy != A or D.launchSpecial:
		return false
	if A.state != "free" or A.stunTicks > 0 or S.dirS.ex != null or S.game.ko != null:
		return false
	var heavy: bool = kind == "heavy"
	if A.ki < _price(heavy):
		DirBrawl._ev(S, A, "press_ack", "chase_no_ki", DirBrawl._cell(kind)).n = S.tick
		return true   # no ki, no chase (the press is spent: a launched rival has no other answer)
	_begin(S, A, D, heavy)
	return true


## The AI (DirAI.aiInput, before the approach cap): its draw at a send of its own, and its start. True while it chases
## (its rush moves it; the cap doesn't hold it).
static func steer(S: SimState, f, o, i: SimIntent) -> bool:
	if not on() or f.ai == null or o == null:
		return false
	if chasing(f):
		return true
	if o.state != "launched" or o.launchBy != f or o.launchSpecial:
		return false
	if _g(f, CH_SEEN) != o.launchN + 1:
		_s(f, CH_SEEN, o.launchN + 1)
		_s(f, CH_AT, 0)
		var sh: float = float(DirAI.lv().get("chaseShare", 0.0))
		if _sky(S, o):
			sh *= float(cfg().get("skyMul", 1.0))
		if f.ki >= _price(false) and SimRng.keyed(int(S.game.seed), "chase.ai", o.launchN * 4 + S.fighters.find(f)) < sh:
			_s(f, CH_AT, S.tick + int(DirAI.skill().get("reactTicks", 14)) + 1)
	if _g(f, CH_AT) == 0 or S.tick + 1 < _g(f, CH_AT) or f.state != "free" or f.rush != null or S.dirS.ex != null:
		return false
	_s(f, CH_AT, 0)
	if f.ki < _price(false):
		return false
	_begin(S, f, o, false)
	return true


static func _begin(S: SimState, A, D, heavy: bool) -> void:
	A.ki -= _price(heavy)
	_s(A, CH_ON, DirBrawl._now(S) + 1)
	_s(A, CH_W, 2 if heavy else 1)
	_cue(S, A, D, "start")
	SimEvents.feed(S, A.name + " CHASES", "a zip after " + D.name + "'s flight (" + str(int(_price(heavy))) + " ki): at " + str(int(_speed(D))) + " u/s")


## The chase's speed now: speedMul times the sent body's, never under minSpeed.
static func _speed(D) -> float:
	var c: Dictionary = cfg()
	return maxf(float(c.get("minSpeed", 1900.0)), float(c.get("speedMul", 1.25)) * SimDetMath.hypot(D.vx, D.vy))


## Once a live tick (DirExchange.dirUpdate): each chase is re-aimed, catches, or arrives at the landing.
static func tick(S: SimState) -> void:
	if not on():
		return
	var c: Dictionary = cfg()
	for A in S.fighters:
		if _g(A, CH_ON) <= 0:
			continue
		var D = SimRoster.opp(S, A)
		if A.state != "free" or S.game.ko != null or S.dirS.ex != null or DirBrawl._now(S) - (_g(A, CH_ON) - 1) > int(c.get("maxTicks", 120)):
			_end(S, A, D, "stopped")
			continue
		if D.state != "launched":
			if A.rush == null:
				_end(S, A, D, "landing")   # he came down before the catch: the chaser arrives at his landing, for the first move
			continue
		var d: float = DirBands.dist(A, D)
		if d <= float(c.get("catchBh", 1.5)) * DirInterrupt.BH:
			_catch(S, A, D)
			continue
		var v: float = _speed(D)
		var n: int = maxi(1, int(ceil(d / (v * SimConst.DT))))
		var land: Dictionary = DirLaunch.predictFlight(S, D.x, D.y, D.vx / maxf(D.launchT, 0.001), D.vy, D.launchT)   # (his vx carries the traversal factor)
		var tl: int = int(ceil(float(land.get("t", 99.0)) * DirData.TICKS_PER_SEC))
		var r := SimState.Rush.new()
		r.tgt = D
		if tl > 0 and tl < n:
			r.off = DirBands._endOff(S, D, SimMathx.jsign(SimWrap.sdx(D.x, A.x)) if SimWrap.sdx(D.x, A.x) != 0.0 else -D.face)   # beside him where he lands
			n = tl
		else:
			r.off = 0.0   # at him
		r.end = S.T + float(n) * SimConst.DT
		if S.depthOn:
			r.offZ = DirBrawl.arriveOff(S, D, r.off)
		A.rush = r
		A.vx = 0.0
		A.vy = 0.0


## The catch: the zip's blow lands and sends him on, the chaser's stick its tilt.
static func _catch(S: SimState, A, D) -> void:
	var c: Dictionary = cfg()
	var heavy: bool = _g(A, CH_W) == 2
	var dmg: float = float(DirZip.cfg().get("heavy", {}).get("damage", 132.0)) if heavy else float(DirBrawl.cfg().get("light", {}).get("damage", 26.0))
	A.rush = null
	A.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(A.x, D.x)), A.face)
	SimDamage.hit(S, null, A, D, dmg, {"kind": "zip", "ignoreStance": true, "noParry": true, "stop": 0.08 if heavy else 0.05, "shake": 9.0 if heavy else 5.0})
	if D.state != "launched" and D.state != "free" and D.state != "down":
		_end(S, A, D, "catch")
		return
	var force: float = float(c.get("sendForce", 1600.0))
	var plan: Dictionary = DirLaunch.chooseLaunch(S, A, D, force, false, "", _tilt(A), true)
	if not plan.is_empty():
		DirLaunch.doLaunch(S, A, D, plan, force)
	_end(S, A, D, "catch")


## The chaser's stick as the launch planner's tilt (1 up, then clockwise by eighths; 0 neutral). The AI leaves it to the
## planner.
static func _tilt(A) -> int:
	if A.ai != null:
		return 0
	var mx: float = A.input.mx
	var my: float = A.input.my
	if SimDetMath.hypot(mx, my) <= SimAct.awayDead:
		return 0
	var best: int = 0
	var bd: float = -INF
	for k in range(8):
		var dot: float = mx * float(TILT_X[k]) + my * float(TILT_Y[k])
		if dot > bd:
			bd = dot
			best = k + 1
	return best


## The send goes up into open sky: he rises faster than he travels, and no building stands over him.
static func _sky(S: SimState, o) -> bool:
	if o.vy <= absf(o.vx):
		return false
	for b in S.buildings:
		if b.alive and absf(SimWrap.sdx(o.x, b.x)) <= b.w * 0.5 and b.h + WorldTerrain.groundY(S, b.x) > o.y:
			return false
	return true


static func _end(S: SimState, A, D, why: String) -> void:
	_s(A, CH_ON, 0)
	if why == "stopped" and A.rush != null and A.rush.tgt == D:
		A.rush = null
	_cue(S, A, D, why)


static func _cue(S: SimState, A, D, text: String) -> void:
	SimFx.cue(S, A, "chase", text, "")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.target = float(S.fighters.find(D))
	e.n = D.launchN
	e.amount = _speed(D)
