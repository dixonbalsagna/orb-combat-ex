class_name DirStanceCost
extends RefCounted
## The circle's price (press-decides.md section 4): circle.ki, times circle.repeatMul for each one he flew inside circle.repeatSec. Off, no
## slot is sized. State: integers on f.act.dirI after DirBeamAim's.

const C_AT: int = 0   # the live tick of his last circle, plus 1
const C_N: int = 1    # circles in a row, each inside repeatSec of the one before
const C_SZ: int = 2


static func _b() -> int:
	return DirBeamAim._b() + DirBeamAim.B_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + C_SZ:
		f.act.dirI.resize(_b() + C_SZ)
	f.act.dirI[_b() + k] = v


## What this circle costs, and it's counted.
static func pay(S: SimState, f, c: Dictionary) -> float:
	var now: int = DirBrawl._now(S)
	var at: int = _g(f, C_AT)
	var n: int = _g(f, C_N) if (at > 0 and float(now - (at - 1)) <= float(c.repeatSec) * DirData.TICKS_PER_SEC) else 0
	_s(f, C_AT, now + 1)
	_s(f, C_N, n + 1)
	return float(c.ki) * SimDetMath.pow(float(c.repeatMul), float(n))
