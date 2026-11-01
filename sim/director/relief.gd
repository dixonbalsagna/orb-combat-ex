class_name DirRelief
extends RefCounted
## One factor on the hero AI's mark-down on a building send (game-design.md section 15, lever 5; docs/legal/review-log.md RL-219).
## The trigger is a count of sends and nothing else: a fighter with care makes under `share` of the match's building sends.
## The factor is the same for an occupied building and an empty one, and it never goes under the data's floor, so the mark-down
## stays. The AI only: a player's stick is untouched. Off, no slot is sized.

const R_SENDS: int = 0   # this fighter's building sends
const R_FIRED: int = 1   # how many times the relief has come on for him
const R_ON: int = 2      # 1 while it's on, so a firing counts once
const R_N: int = 3


static func _b() -> int:
	return DirStick._b() + DirStick.ST_N + 32   # clear of DirVisit's and Combat's DirMixed's, whichever lands first


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + R_N:
		f.act.dirI.resize(_b() + R_N)
	f.act.dirI[_b() + k] = v


static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirLaunch.data().get("relief", {})


static func on() -> bool:
	return bool(cfg().get("enabled", false)) if _force < 0 else _force == 1


## A send into a building (a launch's, or a knock-back's at a wall).
static func sent(att) -> void:
	if on():
		_s(att, R_SENDS, _g(att, R_SENDS) + 1)


## How many times it has come on for this fighter, for QA's row.
static func fired(f) -> int:
	return _g(f, R_FIRED)


## The factor on A's mark-down now: 1 unless he's an AI with care, and short of his share of the sends.
static func factor(S: SimState, A) -> float:
	if not on() or A.ai == null or float(A.care) <= 0.0:
		return 1.0
	var c: Dictionary = cfg()
	var total: int = 0
	for f in S.fighters:
		total += _g(f, R_SENDS)
	var short: bool = total >= int(c.minSends) and float(_g(A, R_SENDS)) < float(c.share) * float(total)
	if short != (_g(A, R_ON) == 1):
		_s(A, R_ON, 1 if short else 0)
		if short:
			_s(A, R_FIRED, _g(A, R_FIRED) + 1)
	return maxf(float(c.scale), float(c.floor)) if short else 1.0
