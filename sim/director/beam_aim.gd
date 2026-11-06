class_name DirBeamAim
extends RefCounted
## A beam fires where the stick aims (docs/controls/beam-aim-feel.md; behind beamPlays.front.aim.enabled, off). RB and the right stick only: the
## signature is aimed at him, always (beam-answers.md).
##  - While he charges, his aim is the stick's sector (rsAim, 0 to 31, 0 is right and counter-clockwise), for the arm and the beam's elevation in
##    the view: aimDeg, and the cue beam_aim each time it moves.
##  - The throw takes rsAim on the release edge; with nothing there (0 is also right), the last aim he held.
##  - Within assistDeg of the line to him it's a shot at him, as today: it can be answered, and it reaches him. Wider than that it goes where it
##    was aimed and misses him: it carves what it crosses, the exchange ends at once, and the cue beam_wide says so.
## State: integers on f.act.dirI after DirChaseTap's.

const B_AIM: int = 0     # the sector he's aiming now, plus 1; 0 none
const B_THROW: int = 1   # the sector thrown, plus 1; 0 none
const B_N: int = 2

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirBeamPlay.frontCfg().get("aim", {})


static func on() -> bool:
	return DirBeamPlay.stationary() and (bool(cfg().get("enabled", false)) if _force < 0 else _force == 1)


static func _b() -> int:
	return DirChaseTap._b() + DirChaseTap.T_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + B_N:
		f.act.dirI.resize(_b() + B_N)
	f.act.dirI[_b() + k] = v


## Each live tick of a beam's hold (DirStick.tick): the aim follows the stick.
static func holding(S: SimState, f, i) -> void:
	if not on() or not i.rsHeld or (int(i.rsMask) & DirStick.LT) != 0:
		return
	var a: int = int(i.rsAim) + 1
	if a != _g(f, B_AIM):
		_s(f, B_AIM, a)
		SimFx.cue(S, f, "beam_aim", "", str(a - 1))


## The hold's let go (DirStick._beamGo): the aim the throw takes.
static func thrown(f, i) -> void:
	if not on():
		return
	var a: int = (int(i.rsAim) + 1) if (i.rsRelease and int(i.rsAim) != 0) else _g(f, B_AIM)
	_s(f, B_THROW, a)
	_s(f, B_AIM, 0)


## His aim in degrees while he holds a beam (0 is toward +x on the screen, counter-clockwise), or NAN when he isn't aiming: for the arm and the
## beam's elevation in the view.
static func aimDeg(f) -> float:
	var a: int = _g(f, B_AIM)
	return NAN if a == 0 else float(a - 1) * 11.25


## At the beam's fire (DirBeamPlay.fire): the direction it was thrown, or [] for a shot at him (none thrown, or within assistDeg of him). The
## throw is used once.
static func wide(S: SimState, A, ox: float, oy: float, tx: float, ty: float) -> Array:
	if not on():
		return []
	var a: int = _g(A, B_THROW)
	_s(A, B_THROW, 0)
	if a == 0:
		return []
	var deg: float = float(a - 1) * 11.25
	var r: float = deg * SimMathx.PI / 180.0
	var ux: float = SimDetMath.cos(r)
	var uy: float = SimDetMath.sin(r)
	var dx: float = SimWrap.sdx(ox, tx)
	var dy: float = ty - oy
	var L: float = SimDamage.jor(SimDetMath.hypot(dx, dy), 1.0)
	var cosOff: float = (ux * dx + uy * dy) / L
	if cosOff >= SimDetMath.cos(float(cfg().assistDeg) * SimMathx.PI / 180.0):
		return []   # near enough: at him
	return [ux, uy]
