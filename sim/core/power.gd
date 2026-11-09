class_name SimPower
extends RefCounted
## One energy model (docs/design/power-scale.md, Game Design), Simulation's part: how fast a send leaves, how far along the line it carries, and flat-out flight, from a fighter's level.
## The switch is data/fight/power.json "enabled" (off), which SimCore.newMatch copies into S.powerOn unless the setup has its own "power". With it off, nothing here changes a number.
## A setup's "flatOut" tries another base for flat-out flight, inside the data's range (Orb's slider, a page word), and its "travel" another factor along the line (launchTravel), inside the data's
## travel range (the page's ?travel= slider, x1.25 to x2). No draw from S.rng anywhere here, and a level is read from what's hashed.

const FILE: String = "res://data/fight/power.json"

static var _d = null
static var _hash: String = ""
static var _errors: Array = []
static var on_: bool = false
static var tierShare: float = 0.8
static var powerShare: float = 0.2
static var energyBase: float = 4.94
static var energyTop: float = 12.25
static var speedUnit: float = 900.0
static var flatOut: float = 5000.0
static var flatGrowth: float = 2.305
static var flatMin: float = 3500.0
static var flatMax: float = 7000.0
static var meteorSpeed: float = 7000.0         # what the meteor's and the high arc's curves count as for their crater, buildings and energy: their on-screen speed is pacing (Game Design)
static var launchTravel: float = 2.0
static var travelMin: float = 1.25             # a setup's "travel" is held to these (the page's slider)
static var travelMax: float = 2.0
static var trav: float = SimConst.TRAV_LAUNCH   # the match stepping now: its factor along the line (WorldSlide.launchTravel). A static, bound each step as the arena's are
static var popForce: float = 700.0
static var blind: float = 1.0                  # tests only: a send past what he has
static var blindTravel: bool = false           # tests only: a setup's "travel" left unread
static var dashOn_: bool = false               # power.json's dash: LT held is fast at any range (Game Design's overnight-2026-11-08.md (c))
static var dashAnyRange: bool = true           # (the dash's response, firstTickMin and fullByTicks, is the kick's: kick.json)
static var blindDash: bool = false             # tests only: the dash switch left unread
static var slipOn_: bool = false               # power.json's dash.slip: a dash let go before underTicks eases to the slip's speed (the EP's brief of 2026-11-09)
static var slipUnder: int = 6                  # ... a dash held fewer ticks than this is a tap
static var slipSpeed: float = 1125.0           # ... the slip's speed: Game Design's slip bound, 1.5 bh in 6 ticks
static var slipEase: int = 4                   # ... ticks from his speed on the release to the slip's
static var blindSlip: bool = false             # tests only: the slip switch left unread
## The slip's state on a fighter, hashed only while S.slipOn (hash.gd; net/desync.gd).
const SLIP_HASHED: Array = ["dashT", "slipT", "slipV"]
static var _shares: Dictionary = {}
static var lastShare: float = -1.0             # tests only: the share the last send asked for


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	var h := SimHash.Hasher.new()
	var j = FighterData._load(FILE, "fight/power.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary):
		_errors.append("fight/power.json: missing, or not an object")
		_d = {}
		_hash = h.hex()
		return
	_d = j
	h.text("fight/power.json")
	FighterData._canon(h, j)
	_hash = h.hex()
	on_ = j.get("enabled") == true
	tierShare = float(j.level.tierShare)
	powerShare = float(j.level.powerShare)
	energyBase = float(j.energy.base)
	energyTop = float(j.energy.topOverBase)
	speedUnit = float(j.speedUnit)
	flatOut = float(j.flight.flatOut)
	flatGrowth = float(j.flight.growth)
	flatMin = float(j.flight.min)
	flatMax = float(j.flight.max)
	meteorSpeed = float(j.meteorSpeed)
	launchTravel = float(j.launchTravel)
	var da: Dictionary = j.dash if j.get("dash") is Dictionary else {}
	dashOn_ = da.get("enabled") == true
	dashAnyRange = da.get("anyRange", true) == true
	var sl: Dictionary = da.slip if da.get("slip") is Dictionary else {}
	slipOn_ = sl.get("enabled") == true
	slipUnder = int(sl.get("underTicks", 6))
	slipSpeed = float(sl.get("speed", 1125.0))
	slipEase = maxi(1, int(sl.get("easeTicks", 4)))
	var tr: Dictionary = j.travel if j.get("travel") is Dictionary else {}
	travelMin = float(tr.get("min", launchTravel))
	travelMax = float(tr.get("max", launchTravel))
	popForce = float(j.popForce)
	_shares = {}
	_flat("", j.share)


## The share block's numbers, by their paths.
static func _flat(at: String, o: Dictionary) -> void:
	for k in o:
		if String(k).begins_with("_"):
			continue
		var v = o[k]
		if v is Dictionary:
			_flat(at + String(k) + ".", v)
		elif v is float or v is int:
			_shares[at + String(k)] = float(v)


static func enabled() -> bool:
	_ensure()
	return on_


static func dataHash() -> String:
	_ensure()
	return _hash


static func errors() -> Array:
	_ensure()
	return _errors


## newMatch: the match's switch, its flat-out base and its factor along the line.
static func setup(S: SimState, su: Dictionary) -> void:
	_ensure()
	S.powerOn = su.get("power", on_) == true
	S.powerFlat = clampf(float(su.get("flatOut", flatOut)), flatMin, flatMax) if S.powerOn else flatOut
	S.powerTravel = clampf(float(su.get("travel", launchTravel)), travelMin, travelMax) if S.powerOn and not blindTravel else launchTravel
	S.dashOn = S.powerOn and su.get("dash", dashOn_) == true and not blindDash
	S.slipOn = S.dashOn and su.get("slip", slipOn_) == true and not blindSlip
	bindStep(S)


## LT held, with the dash on (Game Design's overnight-2026-11-08.md (c)): its top speed is the level's flat out at any range.
static func dashAnyRangeOn(S: SimState) -> bool:
	return S.dashOn and dashAnyRange


## The slip's brake (the EP's brief of 2026-11-09; Game Design's overnight-2026-11-08.md (c): "a tapped LT is still the slip").
## Each live tick, before his state moves him: the dash's count and the brake end when his own free flight does.
static func slipNote(f, flying: bool) -> void:
	if not flying:
		f.dashT = 0
		f.slipT = 0


## His free flight this tick, once the stick has set his velocity; held is the intent's dash. Held, the dash's ticks count
## and any brake ends. Let go after fewer than slipUnder of them while faster than the slip's speed, his speed eases from
## what it is on that tick to the slip's over slipEase ticks, by a smoothstep: never in one step. Held slipUnder ticks or
## longer, nothing here touches him. It only caps: his direction is his own, and so is anything slower.
static func slip(f, held: bool) -> void:
	if held:
		f.slipT = 0
		f.dashT = mini(f.dashT + 1, slipUnder)
		return
	if f.dashT > 0 and f.dashT < slipUnder:
		var v0: float = SimDetMath.hypot(f.vx, f.vy)
		if v0 > slipSpeed:
			f.slipT = slipEase
			f.slipV = v0
	f.dashT = 0
	if f.slipT <= 0:
		return
	var e: float = float(slipEase - f.slipT + 1) / float(slipEase)
	var cap: float = f.slipV + (slipSpeed - f.slipV) * e * e * (3.0 - 2.0 * e)
	f.slipT -= 1
	var v: float = SimDetMath.hypot(f.vx, f.vy)
	if v > cap:
		var k: float = cap / v
		f.vx *= k
		f.vy *= k


## The slip's brake is easing him now (for Encounter's arrival, if it wants it).
static func slipping(f) -> bool:
	return f.slipT > 0


## This match is the one stepping.
static func bindStep(S: SimState) -> void:
	trav = S.powerTravel if S.powerOn else SimConst.TRAV_LAUNCH


## What a distance a plan was written for at x6 along the line comes to now: 1 with the switch off.
static func distScale() -> float:
	return trav / SimConst.TRAV_LAUNCH


## 0 at base with no power, 1 at the top with all of it.
static func level(f) -> float:
	return tierShare * (f.tier - 1.0) / 3.0 + powerShare * f.power / 100.0


static func energy(f) -> float:
	return energyBase * SimDetMath.pow(energyTop, level(f))


## The fastest send he has: all of his energy, share 1.
static func fullSpeed(f) -> float:
	return speedUnit * sqrt(energy(f))


## The speed a share of his energy buys.
static func speed(f, share_: float) -> float:
	lastShare = share_
	return speedUnit * sqrt(energy(f) * share_) * blind


## Combat's share by its path in the data's `share` block, "beam.guarded" or "launcher". A path that isn't there is the data's fault: it says so, and it's `unlisted`.
static func share(key: String) -> float:
	_ensure()
	if _shares.has(key):
		return float(_shares[key])
	if not _errors.has(key):
		_errors.append(key)
		push_error("SimPower: no share %s in data/fight/power.json" % key)
	return float(_shares.get("unlisted", 0.25))


## A launch beat's share by its template. A template with light and heavy rows reads the exchange's kind; one with no row (a style's) is `unlisted`, unless the beat is a small pop.
static func templateShare(tpl: String, kind: String, force: float) -> float:
	_ensure()
	if force <= popForce:
		return share("stylePop")
	var row: String = "templates." + tpl
	if _shares.has(row):
		return float(_shares[row])
	var sub_: String = row + "." + ("heavy" if kind == "heavy" else "light")
	return float(_shares[sub_]) if _shares.has(sub_) else share("unlisted")


## A share that lies between its row's least and most, by how far t is along.
static func shareBetween(key: String, t: float) -> float:
	var lo: float = share(key + ".least")
	return lo + (share(key + ".most") - lo) * clampf(t, 0.0, 1.0)


## A caller's send: its authored force with the switch off, the speed its share buys with it on.
static func sendForce(S: SimState, A, force: float, key: String) -> float:
	return speed(A, share(key)) if S.powerOn else force


## A send's force along (ux, uy). With the switch on the force already is the speed, and a plan's direction that isn't a unit (SMASH ACROSS is 1.05, a beam's up to 1.17) doesn't take it further.
## Off, the force itself: the callers keep their own products in their own order, so not a bit moves.
static func fit(S: SimState, force: float, ux: float, uy: float) -> float:
	return force / maxf(1.0, SimDetMath.hypot(ux, uy)) if S.powerOn else force


## A plan's force multiplier. A send can only spend what he has: with the switch on no multiplier takes it further.
static func fm(S: SimState, m: float) -> float:
	return 1.0 if S.powerOn else m


## Flat out, far from the rival: the base by level, for his build and with what his stance and wounds do to his speed. Close to the rival the dash is what it always was.
static func flatSpeed(S: SimState, f, close: float, ramp: float) -> float:
	var plain: float = 430.0 * f.spd * SimForms.speedMul(S, f) * 2.4
	var far: float = S.powerFlat * SimDetMath.pow(flatGrowth, level(f)) * f.spd * close / plain
	return close + (maxf(far, close) - close) * ramp
