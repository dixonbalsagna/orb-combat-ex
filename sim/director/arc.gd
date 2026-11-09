class_name DirArc
extends RefCounted
## The meteor launch and tier 4's high launch: one authored curve, not physics (docs/design/rule-of-cool-map.md section 2;
## docs/world/ring-any-angle/meteor-arc.md). His place comes from the send's point, its side, the landing's ground and his live ticks,
## so there's no gravity to step and no forecast to run. A hit-stop doesn't advance it. From the crest on, terrain is the landing, and
## he goes on as an ordinary body into the ground, so the crater and the wear are the ground contact's, at a speed that's data. The
## curve's shape and every row's height, carry and time are data. Off, no slot is sized and step returns false.

const A_ROW: int = 0    # his row, plus 1; 0 not on a curve
const A_AGE: int = 1    # live ticks on it
const A_X0: int = 2     # where it began, x 16
const A_G0: int = 3     # the ground there, x 16
const A_GL: int = 4     # the ground at the landing, x 16
const A_SIDE: int = 5   # the way he goes, 1 or -1, plus 2
const A_USED: int = 6   # on the first fighter: the match's planet-scale launches
const A_LAST: int = 7   # ... and the live tick of the last, plus 1
const A_LASTB: int = 8  # the building he last went through, plus 1
const A_BANK: int = 10  # the live tick his banked charge runs out, on him who stunned: ignition
const A_BAT: int = 11   # the live tick the strike that banked it landed
const A_METEORS: int = 12   # on the first fighter: the match's meteors, so far
const A_N: int = 13

const ROWS: Array = ["meteor", "high"]
const NAMES: Array = ["METEOR", "HIGH ARC"]

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on
static var _through := Callable(WorldBrunt, "through")   # World's pass-through (docs/world/building-pass-through.md), once it's there


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirLaunch.data().get("arc", {})


static func on() -> bool:
	return bool(cfg().get("enabled", false)) if _force < 0 else _force == 1


static func _b() -> int:
	return DirWalk._b() + DirWalk.W_SZ


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + A_N:
		f.act.dirI.resize(_b() + A_N)
	f.act.dirI[_b() + k] = v


## Someone's on a curve: no swing during the shot (DirSwing.restRule).
static func flying(S: SimState) -> bool:
	if not on():
		return false
	for f in S.fighters:
		if _g(f, A_ROW) != 0 and f.state == "launched":
			return true
	return false


static func _row(i: int) -> Dictionary:
	return cfg().rows[ROWS[i]]


## Ignition (rule-of-cool-map.md row 5): a level 3 upward stick stun, with both at tier 4, banks charge for as long as the stun lasts.
static func bank(S: SimState, f, o, stun: int) -> void:
	if on() and minf(float(f.tier), float(o.tier)) >= 4.0:
		_s(f, A_BANK, DirBrawl._now(S) + stun)
		_s(f, A_BAT, DirBrawl._now(S))


## Inside a banked stun?
static func banked(S: SimState, f) -> bool:
	return on() and _g(f, A_BANK) > DirBrawl._now(S)


## The tick its strike landed: B's hold counts from there, so the stick's hold is what pays for it.
static func bankedAt(f) -> int:
	return _g(f, A_BAT)


## The ticks B takes to its flash: the data's, or the banked mark inside a banked stun. ch: the brawl's charge block.
static func fullTicks(S: SimState, f, ch: Dictionary) -> int:
	if on() and _g(f, A_BANK) > DirBrawl._now(S):
		return mini(int(ch.fullTicks), int(cfg().bankFull))
	return int(ch.fullTicks)


## How full B's charge is at n ticks held: from the data's fromTicks to its flash, or in a banked stun plainly to the banked mark, which comes before fromTicks.
static func chargeShare(S: SimState, f, ch: Dictionary, n: int) -> float:
	if banked(S, f):
		return clampf(float(n) / float(cfg().bankFull), 0.0, 1.0)
	return clampf(float(n - int(ch.fromTicks)) / maxf(1.0, float(int(ch.fullTicks) - int(ch.fromTicks))), 0.0, 1.0)


## The meteor's own bowl (docs/world/meteor-crater.md), and a blast over it, since a bowl alone lowers a tower and leaves it standing. It stands
## in for the ground contact's dig: he's marked as having hopped, so that doesn't dig too. Over water there's the ordinary splash.
static func _impact(S: SimState, f, c: Dictionary, g: float) -> void:
	var by = f.launchBy
	var tier: float = float(by.tier) if by != null else 4.0
	var n: int = S.craters.size()
	WorldCrater.dig(S, f.x, WorldCrater.impactEnergy(float(c.landSpeed), tier, S), by, "impact", 0.0, 1.0, false, f.z, PackedFloat64Array(), true)
	f.hopped = true
	if S.craters.size() > n:
		_blast(S, f.x, f.z, float(S.craters[S.craters.size() - 1].r), by, c)


## What stands in the bowl goes, by its plan distance, nearest in the index first, up to tier 4's share of all structures (a beam's own cap;
## game-design.md section 12). Past that, it's left at blastKeep of its health.
static func _blast(S: SimState, x: float, z: float, r: float, by, c: Dictionary) -> void:
	var share: float = float(by.ld.beamLevelCapShare[3]) if by != null and by.ld != null else 1.0
	var cap: int = maxi(1, int(SimMathx.jround(share * float(WorldStructures.ringCount(S)))))
	var levelled: int = 0
	S.world.fallTick = -1.0
	SimField.far()
	for b in S.buildings:   # every one: near() only knows those on the fight's own line, and this happens once a match
		if not b.alive or WorldSettle.noTarget(b.landmark) or SimDetMath.hypot(SimWrap.sdx(x, b.x), float(b.z) - z) > r:   # RL-242: a landmark barred by c09 (school, hospital, place of worship) is out of every blast and fall
			continue
		var lost0: float = S.world.structuresLost
		WorldStructures.damageBuilding(S, b, float(b.maxhp) * 2.0, by, "implode", x, 0.0, false, float(c.blastKeep) if levelled >= cap else 0.0)
		if S.world.structuresLost > lost0:
			levelled += 1
	SimField.near()
	if S.world.fallFold > 0.0:
		SimFx.buildingFall(S, -1, x, 0.0, 0.0, 0.0, "implode", 0.0, x, 0.0, S.world.fallFold)
		S.world.fallFold = 0.0


## How a ring smaller than the whole scales the curve, so the angle round holds.
static func _scale() -> float:
	return SimConst.W / float(cfg().wholeRing)


## Along the ground, 0 to 1, at t of the flight (0 to 1): slowest at the apex, quickest at both ends.
static func along(t: float, apexTime: float, apexU: float) -> float:
	var q: float = 1.0 - t / apexTime if t < apexTime else (t - apexTime) / (1.0 - apexTime)
	var a: float = SimMathx.PI * 0.25 * q
	var e: float = SimDetMath.sin(a) / SimDetMath.cos(a)
	return apexU * (1.0 - e) if t < apexTime else apexU + (1.0 - apexU) * e


## Its height over the line from the ground at the send to the ground at the landing.
static func rise(u: float, h: float, skew: float) -> float:
	var w: float = u - skew * u * (1.0 - u)
	return 4.0 * h * w * (1.0 - w)


## What this blow has earned: a row, or -1 (rule-of-cool-map.md row 5; game-design.md section 12). a: the strike's args.
static func earned(S: SimState, f, o, a: Dictionary) -> int:
	var c: Dictionary = cfg()
	if float(a.get("charge", 0.0)) < 1.0 or minf(float(f.tier), float(o.tier)) < 4.0:
		return -1
	if _forms(f) < int(c.minForms) or _forms(o) < int(c.minForms):
		return -1
	var first = S.fighters[0]
	if _g(first, A_USED) >= int(c.budget):
		return -1
	var last: int = _g(first, A_LAST)
	if last > 0 and float(DirBrawl._now(S) - (last - 1)) / DirData.TICKS_PER_SEC < float(c.gapSec):
		return -1
	var called: bool = weak(o) or _g(f, A_BANK) > DirBrawl._now(S) or (bool(c.firstMeteor) and _g(first, A_USED) == 0)   # firstMeteor: the match's first is the meteor, whatever he's doing
	return 0 if called and _g(first, A_METEORS) < int(c.meteorBudget) else 1


## His transformations. A fighter with no form ladder in this match isn't held to the count: the tier is all there is to read.
static func _forms(f) -> int:
	return SimForms.level(f) if f.fd != null else 99


## Stunned (a stagger, a daze or a stick stun), past his first brink, or with a broken region. Nothing about who's near.
static func weak(o) -> bool:
	if o.stunTicks > 0 or SimWounds.brinkProgress(o) >= 1.0:
		return true
	for r in range(o.stage.size()):
		if SimWounds.broken(o, r):
			return true
	return false


## DirBrawl._bigLanded, for a heavy charged to full. True when it went up the curve.
static func heavyFull(S: SimState, ex, f, o, a: Dictionary) -> bool:
	if not on():
		return false
	var row: int = earned(S, f, o, a)
	if row < 0:
		return false
	send(S, f, o, row, sideFor(S, f, o, row, int(a.get("aim", 0))))
	DirInterrupt.si(ex.A, DirInterrupt.LAST_END, DirInterrupt.END_LAUNCH)
	DirBrawl.end(S, ex, "launch")
	return true


## The side a full heavy's curve goes: the punch's way, and back past him with the stick away (aim 4). With no side from the stick
## (none, up or down) and launch.json sideFromBlowOnly on, it keeps the punch's way: only the stick picks the side (Game Design's overnight
## ruling (a); Orb's second Sunday play: the first meteor went the opposite way of the punch). Off: the landing score's better arrival.
static func sideFor(S: SimState, f, o, row: int, aim: int) -> float:
	var side: float = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(f.x, o.x)), f.face)
	if aim == 4:
		return -side   # the stick picks the side
	if aim != 2 and not DirLaunch.sideFromBlowOnly() and landingScore(S, o, row, -side) > landingScore(S, o, row, side):
		return -side   # sideFromBlowOnly off, no side from the stick: the better arrival
	return side


## What a landing that way is worth: standing buildings near it, and water or open ground, read from the bake. Never who's there (RL-213).
static func landingScore(S: SimState, o, row: int, side: float) -> float:
	var c: Dictionary = cfg().landing
	var land: float = SimWrap.wrap(o.x + side * float(_row(row).d) * _scale())
	SimField.far()
	var s: float = 0.0
	if WorldWater.surfaceAt(S, land) > WorldTerrain.groundY(S, land):
		s += float(c.water)
	else:
		s += float(c.ground)
	var n: int = 0
	var near: float = float(c.near)
	for bi in WorldStructures.near(S, land, near):
		var b = S.buildings[bi]
		if b.alive and absf(SimWrap.sdx(land, b.x)) <= near and float(b.z) <= WorldBrunt.BR_Z_FRONT and -float(b.z) <= WorldBrunt.BR_Z_BACK:
			n += 1
	SimField.near()
	return s + float(c.perBuilding) * minf(float(n), float(c.buildingCap))


## Where the curve he's on comes down, the way it's going, and the live ticks till then.
static func landing(o) -> Dictionary:
	var r: Dictionary = _row(_g(o, A_ROW) - 1)
	var side: float = float(_g(o, A_SIDE) - 2)
	return {"x": SimWrap.wrap(float(_g(o, A_X0)) / 16.0 + side * float(r.d) * _scale()), "y": float(_g(o, A_GL)) / 16.0, "side": side, "ticks": _ticks(r) - _g(o, A_AGE)}


## Puts him on the curve, and tells the view where he'll land.
static func send(S: SimState, f, o, row: int, side: float) -> void:
	var r: Dictionary = _row(row)
	var ks: float = _scale()
	var land: float = SimWrap.wrap(o.x + side * float(r.d) * ks)
	SimField.far()
	var gl: float = maxf(WorldTerrain.groundY(S, land), WorldWater.surfaceAt(S, land))
	SimField.near()
	DirLaunch.doLaunch(S, f, o, {"name": NAMES[row], "ux": side, "uy": 1.0}, 1.0, false)
	o.launchT = 1.0
	var total: int = _ticks(r)
	var u1: float = along(1.0 / float(total), float(r.apex), float(cfg().apexU))
	o.vx = side * float(r.d) * ks * u1 / SimConst.DT
	o.vy = (rise(u1, float(r.h) * ks, float(cfg().skew)) + (gl - float(o.y)) * u1) / SimConst.DT
	if S.brakeOn and o.brk != null:
		o.brk.n = o.launchN   # the core's brake holds off until the curve lets it: from the end of the hang
		o.brk.t = 0
		o.brk.marks = 0
		o.brk.told = false
		o.brk.no = true
	_s(o, A_ROW, row + 1)
	_s(o, A_AGE, 0)
	_s(o, A_X0, int(round(float(o.x) * 16.0)))
	_s(o, A_G0, int(round(float(o.y) * 16.0)))
	_s(o, A_GL, int(round(gl * 16.0)))
	_s(o, A_SIDE, int(side) + 2)
	_s(o, A_LASTB, 0)
	var first = S.fighters[0]
	_s(first, A_USED, _g(first, A_USED) + 1)
	if row == 0:
		_s(first, A_METEORS, _g(first, A_METEORS) + 1)
	_s(first, A_LAST, DirBrawl._now(S) + 1)
	SimFx.launchPlan(S, f, o, "", NAMES[row])
	SimFx.cue(S, o, "arc_send", ROWS[row], "")
	var e = S.out.fx[S.out.fx.size() - 1]
	e.x = land      # where he'll land, for the view's tiles
	e.y = gl
	e.amount = float(r.h) * ks
	e.n = S.tick + _ticks(r)


static func _ticks(r: Dictionary) -> int:
	return int(round(float(r.sec) * DirData.TICKS_PER_SEC))


## A tick of a launched fighter (SimFighter.stepLaunched, first). True when the curve moved him.
static func step(S: SimState, f, dt: float) -> bool:
	if DirChaseTap.hangStep(S, f, dt):
		return true   # a catch's hang paces him (DirChaseTap): this is the core's hook for a launched body
	if not on() or _g(f, A_ROW) == 0:
		return false
	if dt <= 0.0:
		return true
	var c: Dictionary = cfg()
	var row: int = _g(f, A_ROW) - 1
	var r: Dictionary = _row(row)
	var ks: float = _scale()
	var total: int = _ticks(r)
	var age: int = mini(_g(f, A_AGE) + 1, total)
	_s(f, A_AGE, age)
	var side: float = float(_g(f, A_SIDE) - 2)
	var x0: float = float(_g(f, A_X0)) / 16.0
	var g0: float = float(_g(f, A_G0)) / 16.0
	var gl: float = float(_g(f, A_GL)) / 16.0
	var apexTime: float = float(r.apex)
	var t: float = float(age) / float(total)
	var u: float = along(t, apexTime, float(c.apexU))
	var nx: float = SimWrap.wrap(x0 + side * float(r.d) * ks * u)
	var ny: float = g0 + (gl - g0) * u + rise(u, float(r.h) * ks, float(c.skew))
	f.vx = SimWrap.sdx(f.x, nx) / dt
	f.vy = (ny - f.y) / dt
	f.x = nx
	f.y = ny
	f.stateT += dt
	SimFighter.spin(S, f, dt, SimFighter.SPIN_AIR)
	WorldBrunt.stepZ(S, f, dt)
	if t >= apexTime:
		_towers(S, f, c)
		if S.brakeOn and t >= float(c.brakeFrom) and (int(f.input.stanceMask) & 8) != 0:
			_s(f, A_ROW, 0)   # the brake leaves the curve on its heading, at its own price
			f.brk.no = false
			f.brk.v0 = SimBrake.speed(f)
			f.brk.at = 0
			return false
		var g: float = maxf(WorldTerrain.groundY(S, nx), WorldWater.surfaceAt(S, nx))
		if ny <= g or age >= total:
			_land(S, f, c, side, g, row == 0)
			return false   # an ordinary body now: the ground contact takes this tick
	return true


## He goes through a building he meets on the way down, and stays on the curve.
static func _towers(S: SimState, f, c: Dictionary) -> void:
	for bi in WorldStructures.near(S, f.x, 40.0):
		var b = S.buildings[bi]
		if not b.alive or _g(f, A_LASTB) == bi + 1 or WorldSettle.noTarget(b.landmark):
			continue
		if absf(SimWrap.sdx(f.x, b.x)) > b.w * 0.5 or absf(float(b.z) - float(f.z)) > b.d * 0.5:
			continue
		if f.y > WorldStructures.baseY(S, b) + WorldStructures.curH(b):
			continue
		_s(f, A_LASTB, bi + 1)
		if _through.is_valid():
			_through.call(S, f, b, f.y, SimWrap.wrap(b.x - signf(f.vx) * b.w * 0.5), signf(f.vx))
		else:
			WorldStructures.damageBuilding(S, b, float(b.maxhp) * float(c.towerShare), f.launchBy, "burst", f.x, 0.0)


## The landing's speed is data, so the crater is capped and doesn't read the curve's. It can't end a match by itself.
static func _land(S: SimState, f, c: Dictionary, side: float, g: float, meteor: bool) -> void:
	_s(f, A_ROW, 0)
	if meteor and not WorldTerrain.seaAt(S, f.x):
		_impact(S, f, c, g)
	var sp: float = float(c.landSpeed)
	f.launchT = 1.0
	f.vx = side * float(c.landVx)
	f.vy = -sp
	f.y = g + 1.0
	f.hp = maxf(f.hp, float(c.hpFloor))
