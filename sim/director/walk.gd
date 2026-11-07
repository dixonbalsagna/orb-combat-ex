class_name DirWalk
extends RefCounted
## Walk him to the wall (docs/design/rule-of-cool-map.md row 2): a player's left stick, leaned toward a standing building during a
## string, adds to each landed blow's carry, up to 1 body height, toward it. The building is read once a string. A knock-back or B
## then reaches further for it. Worth doesn't move. It reads standing buildings only. Off, no slot is sized.

const W_TGT: int = 0    # the building, plus 1
const W_STR: int = 1    # the string it was read for: the exchange's number, plus 1, and the way he leans
const W_N: int = 2      # blows carried toward it
const W_SZ: int = 3

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirLaunch.data().get("walk", {})


static func on() -> bool:
	return bool(cfg().get("enabled", false)) if _force < 0 else _force == 1


static func _b() -> int:
	return DirRelief._b() + DirRelief.R_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + W_SZ:
		f.act.dirI.resize(_b() + W_SZ)
	f.act.dirI[_b() + k] = v


## The nearest standing building that way, within reach along the line and in the fight's depth band.
static func _read(S: SimState, x: float, z: float, side: float) -> int:
	var reach: float = float(cfg().reach)
	var best: int = -1
	var bd: float = 1.0e18
	for bi in WorldStructures.near(S, x, reach):
		var b = S.buildings[bi]
		if not b.alive or WorldSettle.noTarget(b.landmark):
			continue
		if S.frame == null and WorldSettle.enabled() and b.row != 1.0 and b.row != 2.0:
			continue
		var dx: float = SimWrap.sdx(x, b.x) * side
		var d: float = dx - b.w * 0.5
		var dz: float = float(b.z) - z
		if dx > 0.0 and d <= reach and d < bd and dz <= WorldBrunt.BR_Z_FRONT and -dz <= WorldBrunt.BR_Z_BACK:
			bd = d
			best = bi
	return best


## A blow of his landed. The stick is read as the blow lands, so a lean at any point of a string counts from there.
static func landed(S: SimState, ex, f, o) -> void:
	if not on() or (f.ai != null and not aiOn()):
		return
	var c: Dictionary = cfg()
	var mx: float = float(f.input.mx)
	if absf(mx) < float(c.lean):
		return
	var side: float = signf(mx)
	var key: int = (S.dirS.exN + 1) * 2 + (1 if side > 0.0 else 0)
	if _g(f, W_STR) != key:
		_s(f, W_STR, key)
		_s(f, W_N, 0)
		_s(f, W_TGT, _read(S, o.x, float(o.z), side) + 1)
	var t: int = _g(f, W_TGT) - 1
	if t < 0 or not S.buildings[t].alive:
		return
	var b = S.buildings[t]
	var gap: float = SimWrap.sdx(o.x, b.x) * side - b.w * 0.5
	var step: float = minf(float(c.bhStep) * DirInterrupt.BH, gap - float(c.stopShort))
	if step <= 0.0:
		_s(f, W_N, _g(f, W_N) + 1)   # he's there: the lean still counts
		return
	var A = ex.A
	var n: int = int(DirBrawl.cfg().carryTicks)
	var v: float = step / ((float(n) + 1.0) * 0.5 * SimConst.DT)
	var left: int = DirBrawl._g(A, DirBrawl.CARRY_N)
	var keep: float = float(DirBrawl._g(A, DirBrawl.CARRY_X)) / 16.0 * (float(left) / maxf(1.0, float(n)))
	DirBrawl._s(A, DirBrawl.CARRY_X, int(round((keep + side * v) * 16.0)))
	DirBrawl._s(A, DirBrawl.CARRY_Y, 0)
	DirBrawl._s(A, DirBrawl.CARRY_N, n)
	_s(f, W_N, _g(f, W_N) + 1)


## The computer leans for the wall push too (walk.ai; Game Design's addendum of 2026-11-06, section 1), with the same stick a player has: once a
## string, by its personality's share, when a standing building stands beyond its rival in reach, it holds its left stick toward him for the
## string. The string's draw and its building are kept where a player's are (W_STR, W_TGT), so landed reads the lean as his.
## walk.reachWalked (off): a walked knock-back skips the knock's care roll, and B counts the walked building among its candidates. Both can
## read people (the care term moves with SimForms' witness branch, and bruntScore reads who is inside), so they wait on Orb's hold (RL-247).
static func reachWalked() -> bool:
	return on() and bool(cfg().get("reachWalked", false))


static func aiOn() -> bool:
	return on() and bool(cfg().get("ai", {}).get("enabled", false))


## Each tick of the computer's brawl input (DirBrawl.aiInput): its lean, if this string has one.
static func aiLean(S: SimState, f, o, i) -> void:
	if not aiOn() or f.ai == null:
		return
	var side: float = 1.0 if SimWrap.sdx(f.x, o.x) >= 0.0 else -1.0
	var key: int = (S.dirS.exN + 1) * 2 + (1 if side > 0.0 else 0)
	if _g(f, W_STR) != key:
		_s(f, W_STR, key)
		_s(f, W_N, 0)
		var share: float = float(cfg().ai.get(DirLaunch._persOf(f), 0.0))
		var lean: bool = share > 0.0 and SimRng.keyed(int(S.game.seed), "walk.ai", key * 4 + S.fighters.find(f)) < share
		_s(f, W_TGT, (_read(S, o.x, float(o.z), side) + 1) if lean else 0)
	if _g(f, W_TGT) > 0:
		i.mx = side   # toward him: the building is beyond him


## How far a knock-back of his reaches for the building he has walked him to, and which: [] when he hasn't, by this string's blows.
static func wall(S: SimState, att, side: float) -> Array:
	if not on() or (att.ai != null and not aiOn()) or _g(att, W_N) < 1 or _g(att, W_STR) % 2 != (1 if side > 0.0 else 0):
		return []
	var t: int = _g(att, W_TGT) - 1
	if t < 0 or not S.buildings[t].alive:
		return []
	return [t, float(cfg().sendReach)]
