class_name SimFlight
extends RefCounted
## A launch's flight on a curve (Game Design's fight-feel.md section 1; rulings-2026-10-19.md 1 and 19b 4d; Research's
## cinematic-storytelling.md recommendation 9; docs/architecture/feel-core.md). Behind data/fight/flight.json (off): with
## it off, every match, replay and checkpoint is the same to the bit.
##
## The curve paces the body along the path the launch gave it. The path is the one the launch planner chose (the same
## gravity, drag, contacts and buildings), so where a launch goes and where it lands do not change: only how fast he
## travels along it. Each live tick of the first leg (from the send to the first contact) his physics steps by
## dt x k, where k makes his speed on screen the curve's share of the send's peak:
##   the kick       a ramp from 0 to the peak over `ramp` ticks (no one-tick jump), then the peak for `hold`
##   the glide      eased (smoothstep) from the peak to `glide` of it by tick `easeTo`, then held
##   the arrival    when his contact is `arriveTicks` ahead (the ground, the water or the building he is aimed at, by
##                  his course), a ramp from where the curve is to `arrive` of the peak over those ticks
## k is held between kMin and kMax: near the top of a steep send, where his physics speed is small, he slows into the
## apex rather than leaping through it. A knock-back's slide on the feet and a set piece's send are not paced. The
## first leg ends at his first contact, a slide, a building struck, water or the air brake; from there his journey's
## own physics runs as today. At the brake his velocity takes the speed he shows, so the brake starts from it.
## The flight cue (SimFx.flight) tells the camera each phase: kick, glide, arrive and end.

const FILE: String = "res://data/fight/flight.json"
const HASHED: Array = ["n", "t", "peak", "on", "arr", "from", "k"]

static var _d = null
static var _hash: String = ""
static var _errors: Array = []
static var on_: bool = false
static var ramp: int = 5
static var hold: int = 3
static var easeTo: int = 30
static var glide: float = 0.4
static var arrive: float = 0.6
static var arriveTicks: int = 10
static var kMin: float = 0.05
static var kMax: float = 3.0


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	var h := SimHash.Hasher.new()
	var j = FighterData._load(FILE, "fight/flight.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary):
		_err("missing, or not an object")
		_d = {}
		_hash = h.hex()
		return
	_d = j
	h.text("fight/flight.json")
	FighterData._canon(h, j)
	_hash = h.hex()
	if not (j.get("enabled") is bool):
		_err("enabled must be true or false")
	on_ = j.get("enabled") == true
	var c = j.get("curve", {})
	if not (c is Dictionary):
		_err("curve must be an object")
		c = {}
	ramp = _int("curve.ramp", c.get("ramp"), 1, 60)
	hold = _int("curve.hold", c.get("hold"), 0, 60)
	easeTo = _int("curve.easeTo", c.get("easeTo"), ramp + hold + 1, 600)
	glide = _num("curve.glide", c.get("glide"), 0.05, 1.0)
	arrive = _num("curve.arrive", c.get("arrive"), 0.05, 1.5)
	arriveTicks = _int("curve.arriveTicks", c.get("arriveTicks"), 1, 120)
	var k = j.get("pace", {})
	if not (k is Dictionary):
		_err("pace must be an object")
		k = {}
	kMin = _num("pace.kMin", k.get("kMin"), 0.01, 1.0)
	kMax = _num("pace.kMax", k.get("kMax"), 1.0, 10.0)


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


## Each fighter's flight state for a new match (SimCore.newMatch), while the curve is on.
static func setup(S: SimState) -> void:
	_ensure()
	for f in S.fighters:
		f.flt = SimState.FlightState.new() if S.flightOn else null
		if f.flt != null:
			f.flt.n = f.launchN


## The curve's share of the peak at live tick t after the send, before any arrival.
static func curve(t: int) -> float:
	if t <= ramp:
		return float(t) / float(ramp)
	if t <= ramp + hold:
		return 1.0
	if t >= easeTo:
		return glide
	var u: float = float(t - ramp - hold) / float(easeTo - ramp - hold)
	return 1.0 + (glide - 1.0) * u * u * (3.0 - 2.0 * u)


## The share of the peak he shows now: the curve, or the arrival's ramp once it has started.
static func level(p) -> float:
	if p.arr < 0:
		return curve(p.t)
	return p.from + (arrive - p.from) * SimMathx.jmin(1.0, float(p.t - p.arr) / float(arriveTicks))


## Each live tick of a launched fighter while the curve is on (SimFighter.stepLaunched, first): the dt his flight's
## physics steps by this tick. A new send (his launch number moved) starts the curve.
static func pace(S: SimState, f, dt: float) -> float:
	var p = f.flt
	if f.launchN != p.n:   # a new send
		if p.on:
			_end(S, f, "send")   # sent again in the first leg (a juggle): that leg is over
		p.n = f.launchN
		p.t = 0
		p.peak = SimDetMath.hypot(f.vx, f.vy)
		p.on = p.peak > 0.0 and not f.launchSpecial and not f.slideFeet
		p.arr = -1
		p.from = 0.0
		p.k = 1.0
	if not p.on:
		return dt
	if f.jContacts > 0 or f.slide > 0.0 or f.interior != null or f.flightHits > 0 or f.wet:
		_end(S, f, "contact")   # the first leg is over: his journey's own physics from here
		return dt
	if S.brakeOn and f.brk != null and f.brk.on:
		f.vx *= p.k   # the brake takes over from the speed he shows
		f.vy *= p.k
		_end(S, f, "brake")
		return dt
	p.t += 1
	var c: float = level(p)
	if p.arr < 0 and p.t > ramp + hold and toContact(S, f, c * p.peak) <= float(arriveTicks):
		p.arr = p.t
		p.from = c
		SimFx.flight(S, f, "arrive", c * p.peak, p.t)
	var v: float = SimDetMath.hypot(f.vx, f.vy)
	p.k = SimMathx.jclamp(c * p.peak / v, kMin, kMax) if v > 0.0 else kMax
	if p.t == 1:
		SimFx.flight(S, f, "kick", p.peak, p.t)
	elif p.t == easeTo and p.arr < 0:
		SimFx.flight(S, f, "glide", c * p.peak, p.t)
	return dt * p.k


## After his launched step (SimFighter.stepFighter): a contact this tick ends the first leg, told on the same tick
## (the contact may have ended his flight, so pace would not see it).
static func settle(S: SimState, f) -> void:
	var p = f.flt
	if p != null and p.on and (f.state != "launched" or f.jContacts > 0 or f.slide > 0.0 or f.interior != null or f.flightHits > 0 or f.wet):
		_end(S, f, "contact")


static func _end(S: SimState, f, why: String) -> void:
	var p = f.flt
	p.on = false
	SimFx.flight(S, f, "end", level(p) * p.peak, p.t, why)


## Live ticks until his course meets the ground, the water or the building he is aimed at, at the speed he shows:
## his course is marched a tick at a time in his velocity's direction, at most arriveTicks + 1 ticks ahead (the ground
## and the water); the aimed building's face is met on a straight line. A large number when none is that near.
static func toContact(S: SimState, f, shown: float) -> float:
	var v: float = SimDetMath.hypot(f.vx, f.vy)
	if v <= 0.0 or shown <= 0.0:
		return 1.0e9
	var ux: float = f.vx / v
	var uy: float = f.vy / v
	var perTick: float = shown * SimConst.DT
	var best: float = 1.0e9
	var x: float = f.x
	var y: float = f.y
	for n in range(1, arriveTicks + 2):
		x = SimWrap.wrap(x + ux * perTick)
		y += uy * perTick
		if y <= _floor(S, x):
			best = float(n)
			break
	if f.aimB >= 0 and f.aimB < S.buildings.size():
		var b = S.buildings[f.aimB]
		var dx: float = SimWrap.sdx(f.x, b.x)
		if b.alive and dx * ux > 0.0 and ux != 0.0:
			best = SimMathx.jmin(best, SimMathx.jmax(0.0, absf(dx) - b.w * 0.5) / (absf(ux) * perTick))
	return best


static func _floor(S: SimState, x: float) -> float:
	return SimMathx.jmax(WorldTerrain.groundY(S, x), WorldWater.surfaceAt(S, x))


static func _int(where: String, x, lo: int, hi: int) -> int:
	if not (x is float or x is int) or float(x) != floor(float(x)) or int(x) < lo or int(x) > hi:
		_err(where + ": a whole number from %d to %d" % [lo, hi])
		return lo
	return int(x)


static func _num(where: String, x, lo: float, hi: float) -> float:
	if not (x is float or x is int) or float(x) < lo or float(x) > hi:
		_err(where + ": a number from %s to %s" % [str(lo), str(hi)])
		return lo
	return float(x)


static func _err(msg: String) -> void:
	_errors.append("fight/flight.json: " + msg)
	if not FighterData.quiet:
		push_error("SimFlight: fight/flight.json: " + msg)
