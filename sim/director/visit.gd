class_name DirVisit
extends RefCounted
## A town is a visit (game-design.md section 15's addendum): a launch from a town it hasn't used lands inside it until 2 sends; after
## them the town is marked down a while, so the fight goes on; a place with buildings on the line is a real landing, the carry
## solved to reach it. Every term reads standing buildings. Off, no slot is sized and every term is 0.

const V_SENDS: int = 0   # sends into a building in the town the fight is in
const V_SENT: int = 1    # the live tick of the last, plus 1
const V_N: int = 2

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirLaunch.data().get("town", {}).get("visit", {})


static func on() -> bool:
	return bool(cfg().get("enabled", false)) if _force < 0 else _force == 1


static func _b() -> int:
	return DirStick._b() + DirStick.ST_N


static func _g(S: SimState, k: int) -> int:
	var d: PackedInt32Array = S.fighters[0].act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(S: SimState, k: int, v: int) -> void:
	var f = S.fighters[0]
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + V_N:
		f.act.dirI.resize(_b() + V_N)
	f.act.dirI[_b() + k] = v


static func inTown(D) -> bool:
	return (DirLaunch.data().get("town", {}).get("biomes", []) as Array).has(WorldBiomes.biomeAt(D.x))


## A standing building near x, on the line and in the fight's depth.
static func _built(S: SimState, x: float) -> bool:
	var near: float = float(cfg().near)
	for bi in WorldStructures.near(S, x, near):
		var b = S.buildings[bi]
		if b.alive and absf(SimWrap.sdx(x, b.x)) <= near and float(b.z) <= WorldBrunt.BR_Z_FRONT and -float(b.z) <= WorldBrunt.BR_Z_BACK:
			return true
	return false


## A send into a building.
static func sent(S: SimState) -> void:
	if on():
		_s(S, V_SENDS, _g(S, V_SENDS) + 1)
		_s(S, V_SENT, DirBrawl._now(S) + 1)


static func _sinceSent(S: SimState) -> float:
	return float(DirBrawl._now(S) - maxi(0, _g(S, V_SENT) - 1)) / DirData.TICKS_PER_SEC


## What a landing at x costs, from where D is. Out of a town there's nothing to leave.
static func cost(S: SimState, D, x: float) -> float:
	if not on() or not inTown(D):
		return 0.0
	var v: Dictionary = cfg()
	var sends: int = _g(S, V_SENDS)
	if sends < int(v.sends):
		return -float(v.leave) if not _built(S, x) else 0.0
	if _sinceSent(S) < float(v.markSec):
		return -float(v.mark) if _built(S, x) else 0.0
	return 0.0


## Before a plan: a fight that's out of its town starts its next one's count; each place with buildings on the line, ahead, inside
## his tier's reach, is one more candidate, with its carry solved.
static func offer(S: SimState, A, D, c: Array, force: float, tierF: float, f: float, longOnly: bool, fresh: bool) -> void:
	if not on():
		return
	if _g(S, V_SENDS) > 0 and not inTown(D):
		_s(S, V_SENDS, 0)
	if S.frame == null or longOnly or fresh:
		return   # fresh scales each candidate's force after this, so a carry solved here would land short
	var v: Dictionary = cfg()
	var maxD: float = float(v.reach[clampi(int(A.tier) - 1, 0, 3)])
	var fr: Dictionary = DirSwing._frame(S, D.x)
	var dry: float = _sinceSent(S) - float(v.drySec)
	var bonus: float = float(v.dry) * clampf(dry / float(v.dryRampSec), 0.0, 1.0)
	var uy: float = DirLaunch.ACROSS_UY
	var trav: float = WorldSlide.launchTravel(f, uy)
	var ahead: Array = []
	for pl in DirSwing.places(S, DirSwing._planet(S), fr, maxD):
		if float(pl.d) >= float(v.minD) and absf(DirSwing._turnFor(float(pl.phi), 1 if f > 0.0 else -1)) <= float(v.cone):
			ahead.append(pl)
	if ahead.is_empty():
		return
	ahead.sort_custom(func(p, q): return float(p.d) < float(q.d) or (float(p.d) == float(q.d) and int(p.id) < int(q.id)))
	# One flight a plan, at the plain force: chooseLaunch flies each candidate again with its solved fm.
	var t0: float = maxf(float(DirLaunch.predictFlight(S, D.x, D.y, WorldSlide.launchVX(f, uy, force * tierF), uy * force * tierF, trav).travel), 1.0)
	for i in range(mini(ahead.size(), int(v.places))):
		var fm: float = clampf(SimDetMath.pow(float(ahead[i].d) / t0, float(v.solvePow)), 0.05, DirLaunch.HAUL_FM_MAX)   # this arc's carry goes with force to about 1.3
		c.append({"name": "SMASH ACROSS", "ux": f, "uy": uy, "fm": fm, "arrive": int(ahead[i].id), "s": float(v.arrive) + bonus})
