class_name SimBrake
extends RefCounted
## The air brake (Game Design, docs/design/buildings.md section 7.2; the core's side: docs/architecture/brake-core.md):
## a sent fighter who holds the brake (the manoeuvre stance's bit, stanceMask 8: LT, or Guard on Simple and touch, which
## Controls' layouts put on that bit) slows at a fixed rate from a start window after the send, and has control back once
## his speed falls under a third of the send's. It costs ki while held, and works at half the rate with none. The
## air_brake event tells its start and its end, with the reason, the speed and the direction, for Animation's skid.
##
## The switch is data/fight/brake.json "enabled" (off), which SimCore.newMatch copies into S.brakeOn unless the setup has
## its own "brake". Off, nothing here runs: no brake state is hashed, no event is sent, and the file is not in a replay's
## data hash. No draw from S.rng anywhere here.

const FILE: String = "res://data/fight/brake.json"
const BIT: int = 8   # SimIntent.stanceMask: the manoeuvre stance's hold
## The brake state the gameplay hash reads, only while S.brakeOn (hash.gd).
const HASHED: Array = ["n", "t", "v0", "at", "no", "on", "marks", "told"]   # marks: the send kind's marks on him (air sense), the director's to set before his send; 0 until launch-anywhere

static var _d = null
static var _hash: String = ""
static var _errors: Array = []
static var on_: bool = false
static var minTicks: int = 8
static var maxTicks: int = 20
static var lowPower: float = 0.55
static var fullPower: float = 1.0
static var fullSpeed: float = 1.0
static var hardSpeed: float = 1.0
static var maxBrakeS: float = 0.6
static var controlDiv: float = 3.0
static var kiPerSec: float = 0.0
static var noKiMul: float = 0.5
static var airSense: float = 0.0
static var rate: float = 0.0   # derived: the hardest send brakes to a third of its speed in maxBrakeS


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	var h := SimHash.Hasher.new()
	var j = FighterData._load(FILE, "fight/brake.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary):
		_err("fight/brake.json: missing, or not an object")
		_d = {}
		_hash = h.hex()
		return
	_d = j
	h.text("fight/brake.json")
	FighterData._canon(h, j)
	_hash = h.hex()
	if not (j.get("enabled") is bool):
		_err("enabled must be true or false")
	on_ = j.get("enabled") == true
	var w = j.get("window", {})
	if not (w is Dictionary):
		_err("window must be an object")
		w = {}
	minTicks = _int("window.minTicks", w.get("minTicks"), 0)
	maxTicks = _int("window.maxTicks", w.get("maxTicks"), minTicks)
	lowPower = _num("window.lowPower", w.get("lowPower"), 0.0, 1.0)
	fullPower = _num("window.fullPower", w.get("fullPower"), lowPower, 2.0)
	if fullPower <= lowPower:
		_err("window.fullPower must be above lowPower")
		fullPower = lowPower + 1.0
	fullSpeed = _num("fullSpeed", j.get("fullSpeed"), 1.0, 100000.0)
	hardSpeed = _num("hardSpeed", j.get("hardSpeed"), 1.0, 100000.0)
	maxBrakeS = _num("maxBrakeS", j.get("maxBrakeS"), 0.05, 5.0)
	controlDiv = _num("controlDiv", j.get("controlDiv"), 1.0, 20.0)
	kiPerSec = _num("kiPerSec", j.get("kiPerSec"), 0.0, 100.0)
	noKiMul = _num("noKiMul", j.get("noKiMul"), 0.0, 1.0)
	airSense = _num("airSense", j.get("airSense"), 0.0, 1.0)
	rate = (1.0 - 1.0 / controlDiv) * hardSpeed / maxBrakeS


static func enabled() -> bool:
	_ensure()
	return on_


static func dataHash() -> String:
	_ensure()
	return _hash


static func errors() -> Array:
	_ensure()
	return _errors


## Tests only: read the file again on the next call.
static func reload() -> void:
	_d = null


## Each fighter's brake state for a new match (SimCore.newMatch), while the brake is on.
static func setup(S: SimState) -> void:
	_ensure()
	for f in S.fighters:
		f.brk = SimState.BrakeState.new() if S.brakeOn else null
		if f.brk != null:
			f.brk.n = f.launchN


## The send's own speed: its velocity with the launch's traversal factor divided out (as SimFighter.impact reads it).
static func speed(f) -> float:
	return SimDetMath.hypot(f.vx / f.launchT, f.vy)


## The send's power (launch-anywhere.md section 4): the launcher's, Fighter.launchPower, when the launch carries one;
## else (a knock-back, a throw, a blast's push, or any launch with no launcher's power) its own speed over a full launch's,
## at most 1.
static func power(f, v0: float) -> float:
	if float(f.launchPower) != 1.0:
		return float(f.launchPower)
	return SimMathx.jmin(1.0, v0 / fullSpeed)


## The start window for a send of power p (ticks after the send): straight-line from minTicks at lowPower or less to
## maxTicks at fullPower or more; air sense takes airSense off it for each mark of the send's kind on him (the sender's
## to set before the send).
static func window(p: float, marks: int) -> int:
	var k: float = SimMathx.jclamp((p - lowPower) / (fullPower - lowPower), 0.0, 1.0)
	var w: float = float(minTicks) + float(maxTicks - minTicks) * k
	w *= SimMathx.jmax(0.0, 1.0 - airSense * float(marks))
	return int(SimMathx.jround(w))


## Each live tick, every fighter while the brake is on (SimFighter.stepFighter, before his state's branch). A new send
## (his launch number moved) starts his window and ends a brake he was in (a hit). Held after the window, in the air, he
## brakes: his send's speed falls at the rate (half with no ki), ki drains, and under a third of the send's speed he has
## control back. Letting go ends it; so does the ground, water or a building (he is no longer in the air).
static func tick(S: SimState, f, dt: float) -> void:
	var b = f.brk
	if f.launchN != b.n:   # a new send
		if b.on:
			_end(S, f, "hit")
		b.n = f.launchN
		b.t = 0
		b.v0 = speed(f)
		b.at = window(power(f, b.v0), b.marks)
		b.marks = 0   # air sense: the sender sets the send kind's marks before each send, and they are spent here
		b.told = false
		b.no = f.launchSpecial   # a signature's, a finisher's or a break's send is a set piece: no brake (until the director marks finishers and crippling blows alone)
	if f.state != "launched":
		if b.on:
			_end(S, f, "ground")
		return
	b.t += 1
	var held: bool = (f.input.stanceMask & BIT) != 0
	var air: bool = f.slide == 0.0 and f.chainEvt == 0.0
	var can: bool = air and not b.no and b.t >= b.at and b.v0 > 0.0   # he could start it now
	if can and not b.told:   # the rising edge, once a send: Controls' brake_ready (one sharp tick), Audio, the HUD
		b.told = true
		_event(S, f, "ready", "window")
	if b.on:
		if not held:
			_end(S, f, "released")
			return
		if not air:
			_end(S, f, "ground")
			return
		var v: float = speed(f)
		var r: float = rate * (1.0 if f.ki > 0.0 else noKiMul)
		var nv: float = SimMathx.jmax(0.0, v - r * dt)
		var k: float = nv / v if v > 0.0 else 0.0
		f.vx *= k
		f.vy *= k
		f.ki = SimMathx.jmax(0.0, f.ki - kiPerSec * dt)
		if nv < b.v0 / controlDiv:
			_end(S, f, "speed")
			_control(S, f)
	elif held and can:
		b.on = true
		_event(S, f, "start", "held")


static func _end(S: SimState, f, why: String) -> void:
	f.brk.on = false
	_event(S, f, "end", why)


static func _event(S: SimState, f, phase: String, why: String) -> void:
	var v: float = speed(f) if f.state == "launched" else SimDetMath.hypot(f.vx, f.vy)
	var ux: float = 0.0
	var uy: float = 0.0
	if v > 0.0:
		ux = (f.vx / f.launchT if f.state == "launched" else f.vx) / v
		uy = f.vy / v
	SimFx.airBrake(S, f, phase, why, v, ux, uy)


## The brake's control back, for the director (Encounter's recoil flip with ground contact off): his flight ends where
## he is, with his own speed, as the brake ends it.
static func controlBack(S: SimState, f) -> void:
	_control(S, f)


## Control back in the air: his flight ends where he is, with his own speed (the traversal factor divided out of it).
## With ground contact on, World ends the journey (WorldContact.brakeEnd: its journey_end, kind "brake"); without it,
## as a landing in water ends a flight here.
static func _control(S: SimState, f) -> void:
	f.vx = f.vx / f.launchT
	f.launchT = 1.0
	f.launchPower = 1.0   # the flight is over: no launcher's power carried
	if S.contactOn:
		WorldContact.brakeEnd(S, f)
	else:
		f.state = "free"
		f.stateT = 0.0
		SimFighter.spin(S, f, SimConst.DT, SimFighter.SPIN_STOP)
		f.launchBy = null
		f.launchSpecial = false
		WorldBrunt.endFlight(S, f)


static func _num(where: String, x, lo: float, hi: float) -> float:
	if not (x is float or x is int) or float(x) < lo or float(x) > hi:
		_err(where + ": a number from %s to %s" % [str(lo), str(hi)])
		return lo
	return float(x)


static func _int(where: String, x, lo: int) -> int:
	if not (x is float or x is int) or float(x) != floor(float(x)) or float(x) < float(lo):
		_err(where + ": a whole number, %d or more" % lo)
		return lo
	return int(x)


static func _err(msg: String) -> void:
	_errors.append("fight/brake.json: " + msg)
	if not FighterData.quiet:
		push_error("SimBrake: fight/brake.json: " + msg)
