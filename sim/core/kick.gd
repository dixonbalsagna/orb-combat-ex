class_name SimKick
extends RefCounted
## The kick and the coin turn (docs/design/rule-of-cool-map.md section 5, research/rule-of-cool/pitches.md section 2; the core's side: docs/architecture/kick.md):
## flat-out flight leaves on the press: `instant` of top speed on the first tick, and the rest over `climbTicks`. A stick flip at speed brakes, plants and kicks the other
## way. That part is free. The overspeed, its own switch and off (Orb asked for the response, not this): above top speed by where he's going: toward the rival, always; away,
## only beyond charge range and not just after a zip; none on the third kick inside 3 s. The plant is no invulnerability: nothing here touches a hit.
##
## The switch is data/fight/kick.json "enabled" (off), which SimCore.newMatch copies into S.kickOn unless the setup has its own "kick". Off, nothing here runs: no kick
## state is hashed, no event is sent, and the file is not in a replay's data hash. A setup's "instant" and "climbTicks" try other values for a match (Orb's pad; Tools' page words).
## No draw from S.rng anywhere here.

const FILE: String = "res://data/fight/kick.json"
## The kick state the gameplay hash reads, only while S.kickOn (hash.gd).
const HASHED: Array = ["t", "turn", "off", "t1", "t2", "no"]

static var _d = null
static var _hash: String = ""
static var _errors: Array = []
static var on_: bool = false
static var stickOn: float = 0.5
static var startBelow: float = 0.5
static var instant: float = 0.8
static var climbTicks: int = 8
static var overOn: bool = false
static var topShare: float = 1.35
static var hold: int = 8
static var ease: int = 28
static var turnAbove: float = 0.5
static var brakeTicks: int = 5
static var brake: float = 0.55
static var plantTicks: int = 3
static var hop: float = 180.0
static var chargeRange: float = 6000.0
static var repeatTicks: int = 180
static var afterZip: int = 30


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	var h := SimHash.Hasher.new()
	var j = FighterData._load(FILE, "fight/kick.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary):
		_errors.append("fight/kick.json: missing, or not an object")
		_d = {}
		_hash = h.hex()
		return
	_d = j
	h.text("fight/kick.json")
	FighterData._canon(h, j)
	_hash = h.hex()
	on_ = j.get("enabled") == true
	stickOn = float(j.stickOn)
	startBelow = float(j.startBelow)
	instant = float(j.instant)
	climbTicks = int(j.climbTicks)
	overOn = j.overspeed.enabled == true
	topShare = float(j.overspeed.topShare)
	hold = int(j.overspeed.hold)
	ease = int(j.overspeed.ease)
	chargeRange = float(j.overspeed.chargeRange)
	repeatTicks = int(j.overspeed.repeatTicks)
	afterZip = int(j.overspeed.afterZip)
	turnAbove = float(j.turn.above)
	brakeTicks = int(j.turn.brakeTicks)
	brake = float(j.turn.brake)
	plantTicks = int(j.turn.plantTicks)
	hop = float(j.turn.hop)


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


## Each fighter's kick state for a new match (SimCore.newMatch), while the kick is on.
static func setup(S: SimState, setup_: Dictionary = {}) -> void:
	_ensure()
	for f in S.fighters:
		f.kik = SimState.KickState.new() if S.kickOn else null
	S.kickInstant = clampf(float(setup_.get("instant", instant)), 0.0, 1.0)
	S.kickClimb = clampi(int(setup_.get("climbTicks", climbTicks)), 0, 120)


## Each live tick, before his state moves him: a kick or a turn ends when his own flight does, and a zip takes the overspeed away for a while after it.
static func note(_S: SimState, f, flying: bool) -> void:
	var k = f.kik
	if not flying:
		k.t = 0
		k.turn = 0
	if SimDir.zipping(f):
		k.off = afterZip


## His flight this tick, in place of the plain lag toward the stick. lag is that lag's share a tick; sp his top speed.
static func move(S: SimState, f, i: SimIntent, sp: float, lag: float) -> void:
	var k = f.kik
	if k.off > 0:
		k.off -= 1
	var flying: bool = i.dash and SimDetMath.hypot(i.mx, i.my) > stickOn
	if k.turn == 0 and flying and i.mx * f.vx < 0.0 and absf(i.mx) > stickOn and absf(f.vx) > turnAbove * sp:
		k.turn = brakeTicks + plantTicks
		k.t = 0
	if k.turn > 0:
		k.turn -= 1
		if k.turn >= plantTicks:
			f.vx *= brake
		else:
			if k.turn == plantTicks - 1:
				f.vy = hop
				SimFx.coinPlant(S, f)
			f.vx = 0.0
		f.vy += (i.my * sp * 0.85 - f.vy) * lag
		if k.turn == 0 and flying:
			_start(S, f, i)
		return
	if k.t == 0 and flying and SimDetMath.hypot(f.vx, f.vy) < startBelow * sp:
		_start(S, f, i)
	if k.t > 0 and not flying:
		k.t = 0
	if k.t == 0:
		f.vx += (i.mx * sp - f.vx) * lag
		f.vy += (i.my * sp * 0.85 - f.vy) * lag
		return
	var share: float = _share(S, k.t, _over(S, f, i))
	f.vx = i.mx * sp * share
	f.vy = i.my * sp * 0.85 * share
	k.t += 1
	if k.t > S.kickClimb + 1 + (hold + ease if overOn else 0):
		k.t = 0


## His share of top speed on a kick's tick t, from 1: instant, then the climb to top, or with the overspeed on and allowed to its share, held, then eased back to top.
static func _share(S: SimState, t: int, over: bool) -> float:
	var top: float = topShare if over else 1.0
	if t <= S.kickClimb:
		return S.kickInstant + (top - S.kickInstant) * float(t - 1) / float(S.kickClimb)
	var e: float = clampf(float(t - S.kickClimb - 1 - hold) / float(ease), 0.0, 1.0)
	return top + (1.0 - top) * e * e * (3.0 - 2.0 * e)


## A kick begins: the third inside repeatTicks has no overspeed.
static func _start(S: SimState, f, i: SimIntent) -> void:
	var k = f.kik
	k.no = k.t2 >= 0 and S.tick - k.t2 <= repeatTicks
	k.t2 = k.t1
	k.t1 = S.tick
	k.t = 1
	SimFx.kick(S, f, _over(S, f, i))


## May this tick's kick go over top speed?
static func _over(S: SimState, f, i: SimIntent) -> bool:
	var k = f.kik
	if not overOn or k.no:
		return false
	var o = SimRoster.opp(S, f)
	var dx: float = SimWrap.sdx(f.x, o.x)
	var dy: float = o.y - f.y
	if i.mx * dx + i.my * dy > 0.0:
		return true   # an attack closes
	if k.off > 0:
		return false   # no stacking with what got him away
	return SimDetMath.hypot(dx, dy) > chargeRange   # beyond charge range nobody's escaping anybody
