class_name DirStance
extends RefCounted
## The stances on a blow (docs/design/pad-first-press.md): the same worth and wind-up as ever, and one felt difference. LB + X, the check: his
## guard stays up through it. LB + Y, the push: he's shoved back. LT + X, the step strike: he moves through the blow and comes out past him.
## LT + Y, the circle (circle.enabled; press-decides.md section 4): he flies round the rival in one curve, over him or, with the stick down,
## under him, and the medium lands as he arrives on the far side. A light doesn't stop it; a heavy or a grab does. Its input waits for Orb's pick.
## They move bodies with the stick's own carry (DirStick). Combat's parked stance split gives the looks. Off, no slot is sized.

const S_CHECK: int = 0   # 1 while a check of his is on its way
const S_N: int = 1

const CHECK: int = 1
const PUSH: int = 2
const STEP: int = 3
const CIRCLE: int = 4

static var _force: int = -1   # tools: -1 the data's switch, 0 off, 1 on


static func setForce(v: int) -> void:
	_force = v


static func cfg() -> Dictionary:
	return DirInterrupt.data().get("stances", {})


static func on() -> bool:
	return DirStick.on() and (bool(cfg().get("enabled", false)) if _force < 0 else _force == 1)


static func _b() -> int:
	return DirDriver._b() + DirDriver.D_N


static func _g(f, k: int) -> int:
	var d: PackedInt32Array = f.act.dirI
	var i: int = _b() + k
	return d[i] if i < d.size() else 0


static func _s(f, k: int, v: int) -> void:
	DirPlane._size(f)
	if f.act.dirI.size() < _b() + S_N:
		f.act.dirI.resize(_b() + S_N)
	f.act.dirI[_b() + k] = v


## A blow goes on his line (DirBrawl._throw): st 0 X, 1 Y. What his left hand makes of it, in its args.
static func note(f, args: Dictionary, st: int) -> void:
	if not on() or args.has("stick") or st > 1:
		return
	var m: int = int(f.input.stanceMask)
	var kind: int = 0
	if (m & DirStick.LB) != 0:
		kind = CHECK if st == 0 else PUSH
	elif (m & DirStick.LT) != 0 and st == 0 and not DirZip.fsOn():   # (the flight strikes replace the LT lane and the circle)
		kind = STEP
	elif (m & DirStick.LT) != 0 and st == 1 and circleOn() and not args.has("energy") and not DirZip.fsOn():
		kind = CIRCLE
	if kind != 0:
		args["stanceBlow"] = kind
	_s(f, S_CHECK, 1 if kind == CHECK else 0)


static func circleOn() -> bool:
	return on() and bool(cfg().get("circle", {}).get("enabled", false))


## True while he's flying a circle: a light landing on him doesn't stop it.
static func circling(f) -> bool:
	return on() and _g(f, S_CHECK) == 2


## The circle's blow goes on his line (DirBrawl._throw): he sets off, and it lands as he arrives. Returns the live ticks to its contact.
static func circle(S: SimState, f, o, args: Dictionary, lead: int) -> int:
	if int(args.get("stanceBlow", 0)) != CIRCLE:
		return lead
	var c: Dictionary = cfg().circle
	var ticks: int = maxi(lead, int(c.ticks))
	var more: float = DirStanceCost.pay(S, f, c) - float(DirBrawl.cfg().medium.ki)
	if more > 0.0:
		f.ki = maxf(0.0, f.ki - more)
	var side: float = SimDamage.jor(SimMathx.jsign(SimWrap.sdx(o.x, f.x)), -f.face)   # his side of the rival
	var rise: float = float(c.riseBh) * DirInterrupt.BH
	var over: bool = float(f.input.my) >= -0.5 or o.y - rise < SimFighter.floorFor(S, o, o.x, o.z) + DirInterrupt.BH
	var r := SimState.Rush.new()
	r.tgt = o
	r.off = -side * float(DirData.contact().offset)
	r.arc = (1.0 if -side >= 0.0 else -1.0) * (rise if over else -rise)   # (Rush.arc bows to the mover's left: up when he travels toward +x)
	r.end = S.T + float(ticks) * SimConst.DT
	f.rush = r
	f.vx = 0.0
	f.vy = 0.0
	args["circle"] = true
	args["wind"] = true
	DirBrawl._s(f, DirBrawl.HOLD_AT, DirBrawl._now(S))
	DirBrawl._s(f, DirBrawl.CHG, 3)   # it lands as he arrives, whatever the button does
	_s(f, S_CHECK, 2)
	SimFx.cue(S, f, "stance_circle", "over" if over else "under", "")
	SimFx.rush(S, f, o, S.tick + ticks)
	return ticks


## His blow was lost on the way (DirBrawl._drop): he stops where he is.
static func dropped(f) -> void:
	if on() and _g(f, S_CHECK) == 2:
		_s(f, S_CHECK, 0)
		f.rush = null


## His blow has landed or gone (DirBrawl.contact).
static func done(f) -> void:
	if on() and _g(f, S_CHECK) != 0:
		_s(f, S_CHECK, 0)


## His guard holds through this blow's wind-up.
static func guardHolds(o) -> bool:
	return on() and _g(o, S_CHECK) == 1


## It landed clean.
static func landed(S: SimState, f, o, a) -> void:
	if not on():
		return
	var kind: int = int(a.get("stanceBlow", 0))
	if kind == PUSH:
		var side: float = signf(SimWrap.sdx(f.x, o.x))
		DirStick.carry(o, side * float(cfg().pushBh) * DirInterrupt.BH, 0.0)
		SimFx.cue(S, f, "stance_push", "", "")
	elif kind == STEP:
		var gap: float = SimWrap.sdx(f.x, o.x)
		DirStick.carry(f, gap + signf(gap) * float(cfg().stepPastBh) * DirInterrupt.BH, 0.0)
		SimFx.cue(S, f, "stance_step", "", "")
	elif kind == CHECK:
		SimFx.cue(S, f, "stance_check", "", "")
