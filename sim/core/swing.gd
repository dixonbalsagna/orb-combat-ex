class_name SimSwing
extends RefCounted
## The turntable (Game Design's ring-any-angle/game-design.md, the rate law; Camera's curve, camera.md sections 2 and 5; docs/architecture/field-ground.md): the world swings round the fighters by turning the
## sim's line, S.frame, about a pivot on it. Fighters, gaps and velocities stay on the line; only the ground under them moves. The director asks (Encounter's DirSwing) and the core runs: no score here, no
## draws, no planning. Only on a field world (S.frame); with anything else this is never called and a match is the same to the bit. Runs on live ticks only: nothing moves in a hit-stop, a pause or the intro.
##
## The angle at a tick is a closed form of the swing's plan and its own clock `tau`, so frameAt(n) lands on it with nothing accumulated. The rate law slows the clock, never the curve's shape: a tick moves
## tau by 1, or by less where the sweep limits or the rise backstop ask, so a slowed swing comes down the same curve.
## Plan kinds:
##   RAMPED  a rate rising over `in` ticks, held, falling over `out`: a launch, a chase, a form's pause, a brawl; and a rest, which is a ramp with no rise
##   BLOW    a small swing with a blow to hide its start: fast start, soft landing (1 - (1 - u)^3)
##   SMOOTH  a small swing with nothing to cause it: smootherstep, since a fast start would read as a jerk
## left and deg are signed: above 0 the heading turns toward the camera (toward heading x point, Rendering's sd), as CamPlaces.turned turns.
## The rate never jumps: an ask on a running swing starts its ramp from the rate it's at, and a reversal, or a small swing, first eases the running one to rest and waits there (next*).
## A match's motion (setup.swing, "full", "slow" or "off"; Accessibility's swing-motion.md): slow caps every peak at slowRate; off refuses every ask. A setup value, so it's in the match key and the replay; a lobby crosses two players' by strongest().

const HASHED: Array = ["layK", "layC", "active", "rate", "left", "way", "cause", "n", "restT", "pivotHeld", "pivotX", "age", "clamps", "kind", "deg", "ticks", "rampIn", "rampOut", "ptick", "r0", "cruise", "tau", "motion", "nextDeg", "nextCause", "nextRate", "nextBlow", "nextHeld", "nextX", "nextRest"]
const RAMPED: int = 0
const BLOW: int = 1
const SMOOTH: int = 2

static var ticks: int = 0   # swing ticks stepped, for tools; never a sim input


static func data() -> Dictionary:
	return SimField.data()


## Start or replace the swing. deg: signed degrees to turn. cause: "launch", "chase", "form", "brawl" or "small". Optional rate: a peak in deg/s under the cause's. Optional blow: a small swing's cause is a blow. Optional pivotX: a
## strip x held as one planet point until rest. Optional restBy: ticks from now by which it is at rest (the angle gives way, as a flight has only so much time). False if it can't run now: no field world, or a beam in the air.
static func ask(S: SimState, a: Dictionary) -> bool:
	if S.frame == null or S.swing == null or S.swing.motion == "off" or S.beams.size() > 0 or float(a.get("deg", 0.0)) == 0.0:
		return false
	var sw = S.swing
	var deg: float = float(a.deg)
	var cause: String = String(a.get("cause", "launch"))
	var way: float = 1.0 if deg > 0.0 else -1.0
	var moving: bool = sw.active and sw.rate > 0.0
	if moving and (way != sw.way or cause == "small" or sw.kind != RAMPED):   # a reversal, or a curve that starts from rest: the running one eases out, and this one waits
		sw.nextDeg = deg
		sw.nextCause = cause
		sw.nextRate = float(a.get("rate", 0.0))
		sw.nextBlow = a.get("blow", false) == true
		sw.nextHeld = a.has("pivotX")
		sw.nextX = float(a.get("pivotX", 0.0))
		sw.nextRest = S.tick + int(a.restBy) if a.has("restBy") else -1
		if sw.rampIn > 0.0 or sw.kind != RAMPED:   # not already easing out
			rest(S, int(data().causes.get(sw.cause, data().causes.launch).out))
		return true
	var r0: float = sw.rate / 60.0 if moving else 0.0
	sw.nextDeg = 0.0
	sw.active = true
	sw.way = way
	sw.cause = cause
	sw.n += 1
	sw.restT = S.tick + int(a.restBy) if a.has("restBy") else -1
	sw.pivotHeld = a.has("pivotX")
	sw.pivotX = float(a.get("pivotX", 0.0))
	sw.age = 0
	_plan(sw, absf(deg), cause, a.get("blow", false) == true, float(a.get("rate", 0.0)), r0)
	if a.has("restBy") and sw.ticks > float(a.restBy):
		_plan(sw, minf(absf(deg), mostFor(float(a.restBy) / 60.0, cause)), cause, a.get("blow", false) == true, float(a.get("rate", 0.0)), r0)
	sw.left = sw.way * sw.deg
	SimFx.swingEvent(S, "swing_start", cause, deg, int(ceil(sw.ticks)))
	return true


## The peak a swing of this size may run at by its cause: the cause's, the asker's, the size ceiling, the flash governor. Degrees a second.
static func peakFor(deg: float, cause: String, rate: float = 0.0) -> float:
	var d: Dictionary = data()
	var c: Dictionary = d.small if cause == "small" else d.causes.get(cause, d.causes.launch)
	var p: float = minf(float(c.peak), float(d.flashRate))
	if rate > 0.0:
		p = minf(p, rate)
	return minf(p, float(d.small.peak) * minf(1.0, sqrt(float(d.smallSize) / maxf(deg, 0.001))))


## This match's motion: setup.swing if it's one of the three, else the data's.
static func motionOf(setup: Dictionary) -> String:
	var m: String = String(setup.get("swing", data().motion))
	return m if m == "full" or m == "slow" or m == "off" else String(data().motion)


## The strongest of two players' motion settings: a lobby's answer (the sensitive player's need outranks the other's preference).
static func strongest(a: String, b: String) -> String:
	if a == "off" or b == "off":
		return "off"
	return "slow" if a == "slow" or b == "slow" else "full"


## r0: the rate it's at now, degrees a tick: the ramp starts there.
static func _plan(sw, deg: float, cause: String, blow: bool, rate: float, r0: float = 0.0) -> void:
	var d: Dictionary = data()
	var ptick: float = peakFor(deg, cause, rate) / 60.0
	if sw.motion == "slow":
		ptick = minf(ptick, float(d.slowRate) / 60.0)
	sw.tau = 0.0
	sw.deg = deg
	sw.r0 = r0
	if cause == "small":
		sw.kind = BLOW if blow else SMOOTH
		sw.ticks = maxf(float(d.small.floorTicks), (float(d.small.blowShape) if blow else float(d.small.smoothShape)) * deg / ptick)
		return
	var c: Dictionary = d.causes.get(cause, d.causes.launch)
	var i: float = float(c["in"])
	var o: float = float(c["out"])
	sw.kind = RAMPED
	sw.rampIn = i
	sw.rampOut = o
	var ramped: float = 0.5 * (r0 + ptick) * i + 0.5 * ptick * o
	if deg < ramped:   # too short to reach its rate: the ramps alone, at the rate that makes the angle
		var p2: float = (2.0 * deg - r0 * i) / (i + o)
		sw.cruise = 0.0
		if p2 >= 0.0:
			sw.ptick = p2
			sw.ticks = i + o
		else:   # moving too fast to rise at all: only the way out
			sw.rampIn = 0.0
			sw.rampOut = 2.0 * deg / r0
			sw.ptick = r0
			sw.ticks = sw.rampOut
		return
	sw.ptick = ptick
	sw.cruise = (deg - ramped) / ptick
	sw.ticks = i + sw.cruise + o


## The largest swing a flight of flightS seconds has time for, resting by its landing: about the cause's rate less 15 degrees at a launch's (Camera's). Degrees.
static func mostFor(flightS: float, cause: String = "launch") -> float:
	var d: Dictionary = data()
	var c: Dictionary = d.causes.get(cause, d.causes.launch)
	var ptick: float = minf(float(c.peak), float(d.flashRate)) / 60.0
	var both: float = float(c["in"]) + float(c["out"])
	var t: float = flightS * 60.0
	if t <= both:
		return ptick * 0.5 * both * t / both * t / both
	return ptick * (t - 0.5 * both)


## The angle the plan has reached by its clock t, 0 to its size.
static func at(sw, t: float) -> float:
	if t <= 0.0:
		return 0.0
	if t >= sw.ticks:
		return sw.deg
	if sw.kind == BLOW:
		var v: float = 1.0 - t / sw.ticks
		return sw.deg * (1.0 - v * v * v)
	if sw.kind == SMOOTH:
		var u: float = t / sw.ticks
		return sw.deg * u * u * u * (u * (u * 6.0 - 15.0) + 10.0)
	if t < sw.rampIn:
		var ui: float = t / sw.rampIn
		return sw.r0 * t + (sw.ptick - sw.r0) * sw.rampIn * ui * ui * ui * (1.0 - 0.5 * ui)   # the integral of smoothstep, from the rate it started at
	if t < sw.rampIn + sw.cruise:
		return 0.5 * (sw.r0 + sw.ptick) * sw.rampIn + sw.ptick * (t - sw.rampIn)
	var w: float = (sw.ticks - t) / sw.rampOut
	return sw.deg - sw.ptick * sw.rampOut * w * w * w * (1.0 - 0.5 * w)


## Is the world turning this tick? `S.swing` holds its numbers through a hit-stop, a pause and the intro, when the sim is frozen: rate and left are then stale, and this is false.
static func movingNow(S: SimState) -> bool:
	return S.swing != null and S.swing.active and S.pause.left <= 0 and S.dirS.stop <= 0.0


## Ease to rest in `ticks_` ticks from the rate it is at now: a ramp with no rise. The angle to go becomes what that ease covers.
static func rest(S: SimState, ticks_: int) -> void:
	var sw = S.swing
	if sw == null or not sw.active:
		return
	var o: float = float(maxi(1, ticks_))
	var r: float = sw.rate / 60.0   # the rate it is really at: the law may have it under the plan's
	if r <= 0.0:
		o = 1.0   # not moving yet: nothing to ease
	sw.kind = RAMPED
	sw.rampIn = 0.0
	sw.rampOut = o
	sw.cruise = 0.0
	sw.ptick = r
	sw.ticks = o
	sw.deg = 0.5 * r * o
	sw.tau = 0.0
	sw.left = sw.way * sw.deg
	sw.restT = -1


## The rate law now, no ease: the moment a fighter becomes standing (Game Design 11, an early landing). The tick does this by itself; for a director's own landing.
static func clampNow(S: SimState) -> void:
	var sw = S.swing
	if sw == null or not sw.active:
		return
	var lim: float = _limit(S, _pivot(S))
	if sw.rate > lim:
		sw.rate = lim
		sw.clamps += 1


## On the ground, or on the water's floor (Game Design's table: the floor counts).
static func _standing(S: SimState, f) -> bool:
	return f.state != "launched" and f.y <= SimFighter.floorFor(S, f, f.x, f.z) + 1.0


## Game Design's pivot: a standing fighter if exactly one stands, the midpoint if both or neither; a swing with an arrival keeps its point until it rests.
static func _pivot(S: SimState) -> float:
	var sw = S.swing
	if sw.pivotHeld:
		return sw.pivotX
	var a = S.fighters[0]
	var b = S.fighters[1]
	var ga: bool = _standing(S, a)
	var gb: bool = _standing(S, b)
	if ga and not gb:
		return a.x
	if gb and not ga:
		return b.x
	return SimWrap.wrap(a.x + SimWrap.sdx(a.x, b.x) * 0.5)


## The rate in deg/s the sweep limits allow at this pivot: the limit over the distance, for each of the pair (the bodies past the pair don't slow it).
static func _limit(S: SimState, px: float) -> float:
	var d: Dictionary = data()
	if d.get("limitOff", false) == true:
		return 1.0e9
	var lim: float = 1.0e9
	for k in range(2):
		var f = S.fighters[k]
		var r: float = absf(SimWrap.sdx(px, f.x))
		if r > 1.0:
			lim = minf(lim, (float(d.standingLimit) if _standing(S, f) else float(d.airborneLimit)) / r * 180.0 / SimMathx.PI)
	return lim


## One live tick, before the fighters act: the clock moves by what the law allows, and the line turns about the pivot by what the plan says for that clock.
static func tick(S: SimState) -> void:
	var sw = S.swing
	if sw == null or S.frame == null:
		return
	if not sw.active:
		_anchorAtRest(S)
		if sw.layK >= 0:
			_layMarks(S)
		return
	sw.layK = -1   # a swing again: the line is moving, and its rest lays them from the start
	ticks += 1
	sw.age += 1
	if S.beams.size() > 0 and (sw.rampIn > 0.0 or sw.kind != RAMPED):   # a beam: to rest, on a launch's way out (a rest already running has no ramp in)
		rest(S, int(data().causes.launch.out))
	elif sw.restT >= 0 and sw.ticks - sw.tau > float(sw.restT - S.tick + 1):   # the law slowed it, and it's due at rest sooner than the plan ends (this tick counts: an ask's tick numbers restBy from the one before its first)
		rest(S, maxi(1, sw.restT - S.tick + 1))
	var px: float = _pivot(S)
	var deg1: float = at(sw, sw.tau + 1.0) - at(sw, sw.tau)   # the plan's next tick, degrees
	var want: float = deg1 * 60.0
	var lim: float = _limit(S, px)
	var k: float = 1.0
	if want > lim:
		if sw.rate > lim:
			sw.clamps += 1   # a law that fell below the running rate: a fighter has just become standing; at once (Game Design 11)
		k = lim / want
	k = _riseBackstop(S, px, deg1, k)
	var nt: float = sw.tau + k
	var deg: float = at(sw, nt) - at(sw, sw.tau)
	var limTick: float = lim / 60.0
	if deg > limTick:   # on a falling curve a shorter step has a steeper mean than the plan's next tick: bring it down to the law
		for it in range(3):
			k *= limTick / deg
			nt = sw.tau + k
			deg = at(sw, nt) - at(sw, sw.tau)
			if deg <= limTick:
				break
	sw.tau = nt
	sw.rate = deg * 60.0
	sw.left = sw.way * (sw.deg - at(sw, nt))
	if deg != 0.0:
		var sa: bool = _standing(S, S.fighters[0])
		var sb: bool = _standing(S, S.fighters[1])
		_applyTurn(S.frame, px, deg * sw.way)
		if sa:   # standing, he stays on the ground as it moves under him, down as well as up: a free fighter has no gravity, so ground turned out from under him would leave him hanging, airborne by the law, and the swing would run at full speed that way only
			S.fighters[0].y = SimFighter.floorFor(S, S.fighters[0], S.fighters[0].x, S.fighters[0].z)
		if sb:
			S.fighters[1].y = SimFighter.floorFor(S, S.fighters[1], S.fighters[1].x, S.fighters[1].z)
	if sw.tau >= sw.ticks:
		_stop(S)
		return
	_poses(S, false)


## Turn a frame about the point at strip px, by deg, and put x0 there: the same line elsewhere, seen from the pivot.
static func _applyTurn(fr, px: float, deg: float) -> void:
	var a: float = SimWrap.sdx(fr.x0, px) / SimField.R
	var c: float = SimDetMath.cos(a)
	var s: float = SimDetMath.sin(a)
	var mx: float = fr.px * c + fr.tx * s
	var my: float = fr.py * c + fr.ty * s
	var mz: float = fr.pz * c + fr.tz * s
	var hx: float = fr.tx * c - fr.px * s
	var hy: float = fr.ty * c - fr.py * s
	var hz: float = fr.tz * c - fr.pz * s
	var rad: float = deg * SimMathx.PI / 180.0
	var dc: float = SimDetMath.cos(rad)
	var ds: float = SimDetMath.sin(rad)
	var kx: float = hy * mz - hz * my   # toward the camera: heading x point
	var ky: float = hz * mx - hx * mz
	var kz: float = hx * my - hy * mx
	var tx: float = hx * dc + kx * ds
	var ty: float = hy * dc + ky * ds
	var tz: float = hz * dc + kz * ds
	# Keep them unit and square, or a long match's rounding drifts the line off the sphere.
	var nm: float = sqrt(mx * mx + my * my + mz * mz)
	mx /= nm; my /= nm; mz /= nm
	var dd: float = tx * mx + ty * my + tz * mz
	tx -= dd * mx; ty -= dd * my; tz -= dd * mz
	var nt: float = sqrt(tx * tx + ty * ty + tz * tz)
	fr.px = mx; fr.py = my; fr.pz = mz
	fr.tx = tx / nt; fr.ty = ty / nt; fr.tz = tz / nt
	fr.x0 = px


static func _stop(S: SimState) -> void:
	var sw = S.swing
	sw.active = false
	sw.rate = 0.0
	sw.left = 0.0
	sw.pivotHeld = false
	sw.restT = -1
	SimFx.swingEvent(S, "swing_rest", sw.cause, 0.0, sw.age)
	_poses(S, true)
	_layBegin(S)
	if sw.nextDeg != 0.0:   # what waited for this rest
		var a: Dictionary = {"deg": sw.nextDeg, "cause": sw.nextCause, "rate": sw.nextRate, "blow": sw.nextBlow}
		if sw.nextHeld:
			a["pivotX"] = sw.nextX
		if sw.nextRest >= 0:
			a["restBy"] = maxi(1, sw.nextRest - S.tick)
		sw.nextDeg = 0.0
		ask(S, a)


## The strip's cracks and scorch, from the planet's records, under the line where it came to rest (World's layCracks and layScorch, a slice a tick: 4,800 columns of look-ups are more than a tick has). Outward from the pair, so what's in view is right first: layPerTick columns a tick. Only when the store holds any. S.crack and S.scorch are hashed, and this writes them on the same tick on every peer; layK and layC are in the hash and the snapshot.
static func _layBegin(S: SimState) -> void:
	var sw = S.swing
	sw.layK = -1
	for i in range(S.storeN):
		var kind: int = int(S.store[i * WorldStore.STRIDE])
		if kind == WorldStore.KIND_CRACK or kind == WorldStore.KIND_SCORCH:
			sw.layK = 0
			var a = S.fighters[0]
			sw.layC = int(floor(SimWrap.wrap(a.x + SimWrap.sdx(a.x, S.fighters[1].x) * 0.5) / SimConst.COL))
			return


static func _layMarks(S: SimState) -> void:
	var sw = S.swing
	var nc: int = SimConst.NC
	var half: int = nc / 2
	var n: int = int(data().layPerTick)
	var k: int = sw.layK
	var end: int = mini(k + (n + 1) / 2, half + 1)
	while k < end:
		_layCol(S, posmod(sw.layC + k, nc))
		if k > 0 and k < half:
			_layCol(S, posmod(sw.layC - k, nc))
		k += 1
	sw.layK = k if k <= half else -1


static func _layCol(S: SimState, c: int) -> void:
	SimField.pointIn(S.frame, (float(c) + 0.5) * SimConst.COL)
	var qx: float = SimField.ox
	var qy: float = SimField.oy
	var qz: float = SimField.oz
	S.crack[c] = WorldStore.crackAt(S, qx, qy, qz)
	S.scorch[c] = WorldStore.scorchAt(S, qx, qy, qz)[0]


## Section 4's backstop: a standing fighter's ground rises at most riseMax a tick: read the ground one tick ahead under him and slow the clock. Two reads a standing body.
static func _riseBackstop(S: SimState, px: float, deg1: float, k: float) -> float:
	var d: Dictionary = data()
	if deg1 <= 0.0 or d.get("limitOff", false) == true:
		return k
	var riseMax: float = float(d.riseMax)
	var out: float = k
	var ahead = S.frame.copy()
	_applyTurn(ahead, px, deg1 * k * S.swing.way)
	for j in range(2):
		var f = S.fighters[j]
		if not _standing(S, f):
			continue
		var rise: float = absf(SimField.groundIn(S, ahead, f.x, false) - SimField.groundIn(S, S.frame, f.x, false))
		if rise > riseMax:
			out = minf(out, k * riseMax / rise)
	return out


## The line's seam stays far from the fight at rest: past an eighth of the arena from x0, x0 moves to the pair's midpoint. The same line, so nothing anyone reads changes.
static func _anchorAtRest(S: SimState) -> void:
	var fr = S.frame
	var a = S.fighters[0]
	if absf(SimWrap.sdx(fr.x0, a.x)) > SimConst.W * 0.125:
		_applyTurn(fr, SimWrap.wrap(a.x + SimWrap.sdx(a.x, S.fighters[1].x) * 0.5), 0.0)


## ===================================================================== for the planners
## Where the running swing's asked curve puts the line n ticks ahead, with today's pivot: a new frame; writes nothing. The law may slow the real one, not move where it ends. With no swing, the frame as it is.
static func frameAt(S: SimState, n: int):
	var fr = S.frame.copy()
	var sw = S.swing
	if sw == null or not sw.active or n <= 0:
		return fr
	var px: float = _pivot(S)
	_applyTurn(fr, px, (at(sw, sw.tau + float(n)) - at(sw, sw.tau)) * sw.way)
	var rem: float = sw.ticks - sw.tau
	if sw.nextDeg != 0.0 and float(n) > rem:   # and what waits for this rest, on its own curve
		var nx = SimState.Swing.new()
		nx.motion = sw.motion
		_plan(nx, absf(sw.nextDeg), sw.nextCause, sw.nextBlow, sw.nextRate)
		_applyTurn(fr, px, at(nx, float(n) - rem) * (1.0 if sw.nextDeg > 0.0 else -1.0))
	return fr


## ===================================================================== the buildings' poses
## Poses from their planet points: on a swing tick, the list below; all at rest, and at a launch plan's start (poseAll: its candidates reach 10,400). Past the list a stale pose is read only by the crowd's shelter and evacuation, which count people, not places. A pose crossing an index bucket moves it between copies of the two buckets (Performance's incremental index, identical to a whole buildIndex: the index is shared by snapshots, so no bucket is written in place).
static func _poses(S: SimState, all: bool) -> void:
	var n: int = S.bX.size()
	if n == 0 or S.bDir.size() != n * 3:
		return
	_poseThese(S, range(n) if all else _poseList(S))


static func _poseThese(S: SimState, list) -> void:
	var buckets: int = WorldStructures.BUCKETS
	var bw: float = SimConst.W / 128.0
	var moved: bool = false
	for i in list:
		var x0: float = S.bX[i]
		SimField.strip(S, S.bDir[i * 3], S.bDir[i * 3 + 1], S.bDir[i * 3 + 2])
		S.bX[i] = SimField.sx
		S.bZ[i] = SimField.sz
		var k0: int = mini(int(SimWrap.wrap(x0) / bw), buckets - 1)
		var k1: int = mini(int(SimWrap.wrap(SimField.sx) / bw), buckets - 1)
		if k0 != k1:
			if not moved:
				S.bIdx = S.bIdx.duplicate()   # the outer array only
				moved = true
			_rebucket(S, i, k0, k1)


## The buildings a swing tick poses, by planet distance (Performance's test: a stored pose is stale past the reach, so a building swinging in would never be found by it): within poseReach of the pivot, poseBody of each of the
## pair (a sent body flies far from the pivot, and its contacts read the buildings it meets) and poseShot of a shot, and a sent body's aimed building however far. Laid again when the pivot crosses 500 units, and every 8 swing
## ticks, since a far body's point moves with the turn. It lives in the state, as a snapshot's copy, because a pose is read by the sim: a memo outside the state would answer from another timeline after a rollback.
static func _poseList(S: SimState) -> PackedInt32Array:
	var d: Dictionary = data()
	var sw = S.swing
	var px: float = _pivot(S)
	var key: int = int(floor(SimWrap.wrap(px) / float(d.poseStep)))
	if key == S.bListKey and sw.age % int(d.poseEvery) != 1 and S.bListN == sw.n:
		return S.bList
	S.bListKey = key
	S.bListN = sw.n
	var fr = S.frame
	var cx := PackedFloat64Array()
	var cc := PackedFloat64Array()
	_centre(fr, px, float(d.poseReach), cx, cc)
	_centre(fr, S.fighters[0].x, float(d.poseBody), cx, cc)
	_centre(fr, S.fighters[1].x, float(d.poseBody), cx, cc)
	for sh in S.shots:
		_centre(fr, sh.x, float(d.poseShot), cx, cc)
	var nc: int = cc.size()
	var out := PackedInt32Array()
	var q: PackedFloat64Array = S.bDir
	var n: int = S.bX.size()
	for i in range(n):
		var ax: float = q[i * 3]
		var ay: float = q[i * 3 + 1]
		var az: float = q[i * 3 + 2]
		for c in range(nc):
			if ax * cx[c * 3] + ay * cx[c * 3 + 1] + az * cx[c * 3 + 2] >= cc[c]:
				out.append(i)
				break
	for k in range(2):
		var ab: int = int(S.fighters[k].aimB)
		if ab >= 0 and ab < n and not out.has(ab):
			out.append(ab)   # the building a sent body flies at: its edge is read each tick, however far
	S.bList = out
	return out


## A centre of the list: its direction, and the cosine of its reach.
static func _centre(fr, x: float, reach: float, cx: PackedFloat64Array, cc: PackedFloat64Array) -> void:
	SimField.pointIn(fr, x)
	cx.append(SimField.ox)
	cx.append(SimField.oy)
	cx.append(SimField.oz)
	cc.append(SimDetMath.cos(reach / SimField.R))


## A plan's narrower pass: the buildings within posePlan of strip x by planet distance, posed in S.frame as it is now. It returns them, so a plan that swaps S.frame for frameAt's can put the same ones back with posesOf when it swaps back. Everything past the reach keeps its pose, and a rest poses them all (DirSwing's _planOn and _planOff; a launch plan's candidates).
static func posesNear(S: SimState, x: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var n: int = S.bX.size()
	if n == 0 or S.bDir.size() != n * 3:
		return out
	SimField.pointIn(S.frame, x)
	var qx: float = SimField.ox
	var qy: float = SimField.oy
	var qz: float = SimField.oz
	var c: float = SimDetMath.cos(float(data().posePlan) / SimField.R)
	var q: PackedFloat64Array = S.bDir
	for i in range(n):
		if q[i * 3] * qx + q[i * 3 + 1] * qy + q[i * 3 + 2] * qz >= c:
			out.append(i)
	posesOf(S, out)
	return out


## These buildings, posed in S.frame as it is now.
static func posesOf(S: SimState, list: PackedInt32Array) -> void:
	_poseThese(S, list)


## A building that crossed from bucket k0 to k1: both copied, then written. A bucket stays in ascending index order, as buildIndex makes it, so near() returns the same list in the same order.
static func _rebucket(S: SimState, i: int, k0: int, k1: int) -> void:
	var a: PackedInt32Array = S.bIdx[k0].duplicate()
	var p: int = a.find(i)
	if p >= 0:
		a.remove_at(p)
	S.bIdx[k0] = a
	var b: PackedInt32Array = S.bIdx[k1].duplicate()
	b.insert(b.bsearch(i), i)
	S.bIdx[k1] = b
