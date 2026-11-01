class_name DirFollow
extends RefCounted
## A far press follows him (docs/design/rule-of-cool-map.md row 42). On the globe nearly every send lands past the far band's edge, so
## the first thing anyone does after a launch, pressing again, would only taunt. For `ticks` after a send or knock-back he threw, a far tap
## flies him after the target, at the far band's own price. After that, a far tap is the taunt again. Off, no slot is sized.

const F_AT: int = 0   # the tick of his last send, plus 1
const F_N: int = 1

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirBands.data().get("follow", {})


static func on() -> bool:
	return bool(cfg().get("enabled", false)) if _force < 0 else _force == 1


static func _b() -> int:
	return DirEnding._b() + DirEnding.E_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + F_N:
		f.act.dirI.resize(_b() + F_N)
	f.act.dirI[_b() + k] = v


## He's just sent someone (DirLaunch.doLaunch).
static func sent(S: SimState, att) -> void:
	if on() and att != null:
		_s(att, F_AT, S.tick + 1)


## His flight has run out with the one he sent still in the air: he stays with him, and the exchange starts when he's down.
static func keepOn(S: SimState, f) -> bool:
	if not on() or f.rush == null:
		return false
	var o = f.rush.tgt
	return o != null and o.state == "launched" and o.launchBy == f


## True while A's far press flies after the one he sent.
static func due(S: SimState, A) -> bool:
	if not on():
		return false
	var at: int = _g(A, F_AT)
	return at > 0 and S.tick - (at - 1) <= int(cfg().ticks)
