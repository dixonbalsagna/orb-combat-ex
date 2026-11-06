class_name DirChaseTap
extends RefCounted
## The chase after a launch, by a plain tap (docs/design/power-scale.md section 4). You don't float: the press that sends you after him is
## the blow, and it lands as you catch him. While the one he sent is in the air, a press outside reach is DirChase's chase, with no LT.
##  - The first tap of a send is free. Then the chase's price, times priceStep for each one after in that chain.
##  - A press during the rush picks the blow, the newest wins: X the strike, Y the heavy, B drives him down at Y's price. It never queues.
##  - After a send or the blow, a press inside nextTicks starts a chase, wherever he's got to. No press and he peels off.
##  - A catch holds him up: his flight from it takes at least minAirTicks, on the path the planner gave it, unless B drove him down.
##  - A tap that reaches his landing (he came down first, or the meteor's curve) lands as he gets up, an ordinary blow he can guard.
##  - A press made while the send still holds him goes on his first free tick, inside holdTicks. No press is silent.
## A knock-back isn't a send, and a stick strike never sends: neither starts one. The AI doesn't use this: it keeps chase.enabled's own route.
## Behind interrupts.json chase.tap.enabled (false: nothing here runs, and no slot is sized). State: integers on f.act.dirI after DirPhrase's.

const T_K: int = 0      # the chases of this chain so far
const T_LN: int = 1     # the launch number of the send this chain has reached, plus 1
const T_AT: int = 2     # the live tick of his last blow, plus 1
const T_CURVE: int = 3  # 1 while this chase flies to the landing of a curve
const T_LAND: int = 4   # the live tick the body's flight was last forecast to end, plus 1
const T_READ: int = 5   # the live tick of that forecast, plus 1
const T_HOLD: int = 6   # a press waiting for his first free tick: 1 X, 2 Y, 3 B, plus 4 x (its live tick + 1)
const T_PAID: int = 7   # what this chase has cost him, x 16
const T_KNOCK: int = 8  # 1 when his last launch was a knock-back
const T_RISE: int = 9   # on the chaser: the live tick his blow reached the landing, plus 1, while it waits for him to get up
const T_RISEW: int = 10 # ... and its blow: 1 the strike, 2 the heavy; plus 4 while he rushes to him, and T_RISE is then its arrival, plus 1
const T_HK: int = 11    # on the body sent: his hang's pace, x 4096 (0: none)
const T_HEND: int = 12  # ... the live tick it ends, plus 1
const T_HLN: int = 13   # ... and the launch number it's for, plus 1
const T_CT: int = 14    # on the chaser: the catch's carry, live ticks left
const T_CVX: int = 15   # ... the speed he caught him at, x 16
const T_CVY: int = 16
const T_N: int = 17

const X: int = 1
const Y: int = 2
const B: int = 3

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirChase.cfg().get("tap", {})


static func on() -> bool:
	return DirInterrupt.on() and (bool(cfg().get("enabled", false)) if _force < 0 else _force == 1)


static func _b() -> int:
	return DirPhrase._b() + DirPhrase.P_N_SLOTS


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + T_N:
		f.act.dirI.resize(_b() + T_N)
	f.act.dirI[_b() + k] = v


## His launch of someone (DirLaunch.doLaunch): whether it can be chased by a tap.
static func sent(S: SimState, att, plan: Dictionary) -> void:
	if on():
		var knock: bool = String(plan.get("name", "")) == "KNOCK BACK"
		_s(att, T_KNOCK, 1 if knock else 0)
		_s(att, T_AT, 0 if knock else DirBrawl._now(S) + 1)   # he's still in reach as it starts: a press now goes after him
		if not knock and att.ai == null:
			SimFx.cue(S, att, "chase_ready", "", "")   # a press now chases: for the hint (the rush itself is the cue "chase", text start)


## The one he sent, in the air, that a tap can go after; null if none.
static func _target(S: SimState, A):
	var D = DirBrawl.rivalOf(S, A)
	if D.state != "launched" or D.launchBy != A or D.launchSpecial or _g(A, T_KNOCK) == 1:
		return null
	return D


## X, Y or B, as this chase reads it; 0 for anything else. B is a bare B: with the energy family or RT held it's still what it was.
static func _pick(A, kind: String) -> int:
	if A.act.mode == 1:
		return 0
	if kind == "light":
		return X
	if kind == "heavy":
		return Y
	return B if DirBrawl.isB(A, kind) else 0


static func _rate(pick: int) -> float:
	return DirChase._price(pick != X)


## What the next chase of this chain costs, by the blow. The first of a send is free.
static func price(S: SimState, A, D, pick: int) -> float:
	var k: int = _g(A, T_K) if _g(A, T_LN) == D.launchN + 1 else 0
	if k == 0:
		return 0.0
	return _rate(pick) * SimDetMath.pow(float(cfg().priceStep), float(k - 1))


static func _nextOpen(S: SimState, A) -> bool:
	var at: int = _g(A, T_AT)
	return at > 0 and DirBrawl._now(S) - (at - 1) <= int(cfg().nextTicks)


## A stick strike outside reach while he's in the air: it can't reach him, and it never sends. It's refused, and says so.
static func refuses(S: SimState, f) -> bool:
	if not on() or f.ai != null:
		return false
	if DirChase.chasing(f):
		return true
	return _target(S, f) != null and DirBands.band(f, DirBrawl.rivalOf(S, f)) != DirBands.CLOSE


## A press he can't act on yet, while the send still holds him (DirExchange._request): it waits for his first free tick. The newest wins.
static func holds(S: SimState, A, kind: String) -> bool:
	if not on() or A.ai != null:
		return false
	if A.state == "free" and DirBrawl.exOf(S) == null and A.stunTicks <= 0:
		return false
	var pick: int = _pick(A, kind)
	if pick == 0 or _target(S, A) == null:
		return false
	_s(A, T_HOLD, pick + 4 * (DirBrawl._now(S) + 1))
	DirBrawl._ev(S, A, "press_ack", "chase_held", DirBrawl._cell(kind)).n = S.tick
	return true


## A player's attack press (DirChase.takes): true when this is the chase's.
static func takes(S: SimState, A, kind: String) -> bool:
	if DirChase.chasing(A):
		_during(S, A, kind)
		return true
	var pick: int = _pick(A, kind)
	if pick == 0 or A.state != "free" or A.stunTicks > 0 or DirBrawl.exOf(S) != null or S.game.ko != null:
		return false
	var D = _target(S, A)
	if D == null or (DirBands.band(A, D) == DirBands.CLOSE and not _nextOpen(S, A)):
		return false
	return _start(S, A, D, pick, kind)


static func _start(S: SimState, A, D, pick: int, kind: String) -> bool:
	var cost: float = price(S, A, D, pick)
	if A.ki < cost:
		DirBrawl._ev(S, A, "press_ack", "chase_no_ki", DirBrawl._cell(kind)).n = S.tick
		return true   # the press is spent, and says why
	var k: int = _g(A, T_K) if _g(A, T_LN) == D.launchN + 1 else 0
	_s(A, T_K, k + 1)
	_s(A, T_LN, D.launchN + 1)
	_s(A, T_PAID, int(round(cost * 16.0)))
	_s(A, T_AT, 0)
	_s(A, T_READ, 0)
	_s(A, T_HOLD, 0)
	DirChase.startTap(S, A, D, pick, cost)
	if DirArc.on() and DirArc._g(D, DirArc.A_ROW) > 0:
		_s(A, T_CURVE, 1)
		_toLanding(S, A, D)
	else:
		_s(A, T_CURVE, 0)
	return true


## A press during the rush picks the blow. A dearer blow pays the difference, and a cheaper one gives it back; a free chase stays free.
static func _during(S: SimState, A, kind: String) -> void:
	var pick: int = _pick(A, kind)
	if pick == 0 or _g(A, T_CURVE) == 1:
		DirBrawl._ev(S, A, "press_ack", "chase", DirBrawl._cell(kind)).n = S.tick
		return
	var paid: float = float(_g(A, T_PAID)) / 16.0
	var D = DirBrawl.rivalOf(S, A)
	var cost: float = 0.0
	if paid > 0.0:
		var k: int = _g(A, T_K) - 1
		cost = _rate(pick) * SimDetMath.pow(float(cfg().priceStep), float(k - 1))
	if A.ki + paid < cost:
		DirBrawl._ev(S, A, "press_ack", "chase_no_ki", DirBrawl._cell(kind)).n = S.tick
		return
	A.ki += paid - cost
	_s(A, T_PAID, int(round(cost * 16.0)))
	DirChase.setBlow(A, pick)
	DirBrawl._ev(S, A, "press_ack", "chase", DirBrawl._cell(kind)).n = S.tick


## Flies him to where the curve lands, arriving as it does, beside it.
static func _toLanding(S: SimState, A, D) -> void:
	var l: Dictionary = DirArc.landing(D)
	var r := SimState.Rush.new()
	r.px = SimWrap.wrap(float(l.x) - float(l.side) * float(DirChase.cfg().get("catchBh", 1.5)) * DirInterrupt.BH)
	r.py = float(l.y)
	r.end = S.T + float(maxi(1, int(l.ticks))) * SimConst.DT
	A.rush = r
	A.vx = 0.0
	A.vy = 0.0


## Once a live tick (DirChase.tick): a press that waited, and goes now or lapses.
static func tick(S: SimState) -> void:
	if not on():
		return
	for A in S.fighters:
		_carryStep(S, A)
		_rising(S, A)
		var h: int = _g(A, T_HOLD)
		if h == 0:
			continue
		var pick: int = h & 3
		var kind: String = ["", "light", "heavy", "sig"][pick]
		var D = _target(S, A)
		if D == null or DirChase.chasing(A):
			_s(A, T_HOLD, 0)
			continue
		if A.state == "free" and DirBrawl.exOf(S) == null and A.stunTicks <= 0:
			_s(A, T_HOLD, 0)
			_start(S, A, D, pick, kind)
		elif DirBrawl._now(S) - ((h >> 2) - 1) > int(cfg().holdTicks):
			_s(A, T_HOLD, 0)
			DirBrawl._ev(S, A, "press_ack", "chase_late", DirBrawl._cell(kind)).n = S.tick


## True while this chase flies to a curve's landing: it has no catch.
static func onCurve(A) -> bool:
	return _g(A, T_CURVE) == 1


## The live ticks till his flight ends, forecast every landReadTicks: a forecast is a walk of the flight, and this runs every tick of a chase.
static func landingIn(S: SimState, A, D) -> int:
	var now: int = DirBrawl._now(S)
	var at: int = _g(A, T_READ)
	if at == 0 or now - (at - 1) >= int(cfg().landReadTicks):
		var land: Dictionary = DirLaunch.predictFlight(S, D.x, D.y, D.vx / maxf(D.launchT, 0.001), D.vy, D.launchT)
		_s(A, T_READ, now + 1)
		_s(A, T_LAND, now + 1 + int(ceil(float(land.get("t", 99.0)) * DirData.TICKS_PER_SEC)))
	if _g(D, T_HK) != 0 and _g(D, T_HLN) == D.launchN + 1:
		return maxi(_g(A, T_LAND) - 1 - now, _g(D, T_HEND) - 1 - now)   # his hang lands him as it ends
	return _g(A, T_LAND) - 1 - now


## The catch's carry (Camera's read: the chaser went from 10,175 to 0 in one tick): he keeps the speed he caught him at and eases down
## over carryTicks. Called before the blow sends D on. His speed is this tick's step of the rush (the chase lays a new rush each tick,
## so its start is where he stood as the tick began); with no rush to read, D's own.
static func carry(S: SimState, A, D) -> void:
	var n: int = int(cfg().get("carryTicks", 0))
	if n <= 0:
		return
	var vx: float = float(D.vx)
	var vy: float = float(D.vy)
	var r = A.rush
	if r != null and float(r.dur) > 0.0:
		vx = SimWrap.sdx(float(r.x0), A.x) / SimConst.DT
		vy = (A.y - float(r.y0)) / SimConst.DT
	var v: float = SimDetMath.hypot(vx, vy)
	var most: float = float(cfg().maxSpeed)
	if v > most:
		vx *= most / v
		vy *= most / v
	_s(A, T_CT, n)
	_s(A, T_CVX, int(round(vx * 16.0)))
	_s(A, T_CVY, int(round(vy * 16.0)))


## Each live tick of the carry: the speed falls as (1 - t) squared, so it starts at his own and settles to nothing. A rush or a state
## that isn't free ends it.
static func _carryStep(S: SimState, A) -> void:
	var left: int = _g(A, T_CT)
	if left <= 0:
		return
	_s(A, T_CT, left - 1)
	if A.state != "free" or A.rush != null:
		_s(A, T_CT, 0)
		return
	var n: float = float(int(cfg().get("carryTicks", 1)))
	var k: float = float(left - 1) / n
	k *= k
	var dt: float = SimConst.DT
	A.x = SimWrap.wrap(A.x + float(_g(A, T_CVX)) / 16.0 * k * dt)
	A.y = maxf(A.y + float(_g(A, T_CVY)) / 16.0 * k * dt, SimFighter.floorFor(S, A, A.x, A.z))


## His blow has landed in the air.
static func caught(S: SimState, A, D) -> void:
	_s(A, T_AT, DirBrawl._now(S) + 1)
	_s(A, T_LN, D.launchN + 1)
	_s(A, T_PAID, 0)


## He came down before the catch, or this chase flew to a curve's landing: the blow waits for him to get up (_rising).
static func landed(S: SimState, A, D, heavy: bool) -> void:
	_s(A, T_PAID, 0)
	_s(A, T_CURVE, 0)
	if S.game.ko != null or A.state != "free":
		return
	_s(A, T_RISE, DirBrawl._now(S) + 1)
	_s(A, T_RISEW, 2 if heavy else 1)


## The blow that reached his landing lands as he gets up, an ordinary blow he can guard (power-scale.md, "a tap that reaches a landing":
## it replaces "for the first move", and stands in for the meteor's apex spike). If he got up out of reach (a crater's bounce carries him
## off), the chaser rushes to him, in riseRushTicks at most, and it lands as he arrives: the follow-up always hits something. It lapses after
## riseTicks, or if either is busy by then.
static func _rising(S: SimState, A) -> void:
	var at: int = _g(A, T_RISE)
	if at == 0:
		return
	var D = DirBrawl.rivalOf(S, A)
	var now: int = DirBrawl._now(S)
	var w: int = _g(A, T_RISEW)
	if S.game.ko != null or DirBrawl.exOf(S) != null or D.state == "launched" and (w & 4) != 0 or (A.state != "free" and A.rush == null) or now - (at - 1) > int(cfg().get("riseTicks", 60)):
		_s(A, T_RISE, 0)
		return
	if (w & 4) == 0 and (D.state == "launched" or D.embedT > 0):
		_s(A, T_RISE, now + 1)   # still coming down (a curve's chaser gets there first), or embedded: riseTicks counts from his get-up
		return
	if D.state != "free" or ((w & 4) != 0 and now < at - 1):
		return   # still down, or on the way to him
	var reach: float = 2.0 * float(DirChase.cfg().get("catchBh", 1.5)) * DirInterrupt.BH
	if DirBands.dist(A, D) > reach and (w & 4) == 0:
		var ticks: int = clampi(int(ceil(DirBands.dist(A, D) / (float(cfg().maxSpeed) * SimConst.DT))), 2, int(cfg().get("riseRushTicks", 20)))
		var r := SimState.Rush.new()
		r.tgt = D
		r.off = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(D.x, A.x)), -A.face) * float(DirData.contact().offset)
		r.end = S.T + float(ticks) * SimConst.DT
		A.rush = r
		A.vx = 0.0
		A.vy = 0.0
		_s(A, T_RISE, now + 1 + ticks)
		_s(A, T_RISEW, w | 4)
		return
	_s(A, T_RISE, 0)
	if DirBands.dist(A, D) > reach:
		return
	var heavy: bool = (w & 3) == 2
	var dmg: float = float(DirZip.cfg().get("heavy", {}).get("damage", 132.0)) if heavy else float(DirBrawl.cfg().get("light", {}).get("damage", 26.0))
	A.face = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(A.x, D.x)), A.face)
	SimDamage.hit(S, null, A, D, dmg, {"kind": "zip", "stop": 0.08 if heavy else 0.05, "shake": 9.0 if heavy else 5.0})
	DirChase._cue(S, A, D, "rise")


## After a catch's send (DirChase._catch): he stays up at least minAirTicks, unless B drove him down. It's a hit's hang, not more energy:
## his flight is paced along the path the planner gave it, so where he goes, what he hits and where he lands don't change.
static func hang(S: SimState, A, D, spike: bool) -> void:
	var n: int = int(cfg().get("minAirTicks", 0))
	if n <= 0 or spike or D.state != "launched":
		return
	var land: Dictionary = DirLaunch.predictFlight(S, D.x, D.y, D.vx / maxf(D.launchT, 0.001), D.vy, D.launchT)
	var phys: float = float(land.get("t", 99.0)) * DirData.TICKS_PER_SEC
	if phys >= float(n):
		return
	var pace: float = maxf(phys, 1.0) / float(n + 3)   # (3 to spare: a smaller step lands a hair sooner)
	var least: float = float(cfg().get("hangMinPace", 0.0))
	var ticks: int = n + 3
	if least > 0.0 and pace < least:
		pace = least   # Tools' film: no slower than this, so a short send hangs less than minAirTicks
		ticks = int(ceil(maxf(phys, 1.0) / pace)) + 1
	_s(D, T_HK, maxi(1, int(round(pace * 4096.0))))
	_s(D, T_HEND, DirBrawl._now(S) + ticks + 1)
	_s(D, T_HLN, D.launchN + 1)
	_s(A, T_READ, 0)   # the chaser's forecast reads the hang from now


static var _inHang: bool = false   # (while hangStep steps him: the core's hook calls back in)


## The core's hook for a launched body (DirArc.step, first): true when his hang stepped him, at its pace. A new send or its end clears it.
static func hangStep(S: SimState, f, dt: float) -> bool:
	if _inHang or dt <= 0.0 or not on():
		return false
	var hk: int = _g(f, T_HK)
	if hk == 0:
		return false
	if _g(f, T_HLN) != f.launchN + 1 or DirBrawl._now(S) >= _g(f, T_HEND) - 1:
		_s(f, T_HK, 0)
		return false
	_inHang = true
	SimFighter.stepLaunched(S, f, dt * float(hk) / 4096.0)
	_inHang = false
	return true
