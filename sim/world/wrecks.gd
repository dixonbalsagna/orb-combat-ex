class_name WorldWrecks
extends RefCounted
## The liftable wreck (Game Design 23d section 8 item 20, the Cyborg's Wreck Toss; Legal RL-183 and ln04; data/biomes/wrecks.json). A wreck is a building that has fallen (not alive) and has not been
## hurled yet. `pick` is the query Encounter calls when the pick-up press comes: the nearest wreck within reach (2 body heights, to the wreck's box) that the fighter's tier can lift, that is empty (a fallen
## building holds no one: its people are gone) and with nothing living near it (no living civilian in a building within `nearBh` of its edge). It returns the wreck's id and mass. `burst` is the other
## half: when the hurled wreck lands, the scrap damages structures by the brunt ladder's tier factor, and the wreck is spent. Pure functions of the state, no draw. The only state it writes is the spent
## mark on the wreck's building (`marks`, hashed when not 0: a dead building is never struck again, so brunt's repeat marks never read it) and the structures' own damage.

const PATH := "res://data/biomes/wrecks.json"
const SCHEMA := "biomes.wrecks/1"
const BH: float = 75.0
const TAKEN: int = -1000   # Building.marks of a wreck that has been hurled

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""
static var K_REACH: float = 2.0
static var K_NEAR: float = 3.0
static var K_FIGHTERS: bool = false
static var K_FILL: float = 0.12
static var K_MIN: float = 0.2
static var K_LIFT := PackedFloat64Array()
static var K_B_SPEED: float = 900.0
static var K_B_REF: float = 2.0
static var K_B_SMIN: float = 0.5
static var K_B_SMAX: float = 2.0
static var K_B_R: float = 1.6
static var K_B_RMIN: float = 1.0
static var K_B_RMAX: float = 3.5


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_errors.append("wrecks.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("wrecks.json: not a %s object" % SCHEMA)
		return
	for k in ["reachBh", "nearBh", "fighters", "fill", "minWreckMass", "tierLift", "burst"]:
		if not j.has(k):
			_errors.append("wrecks.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	var lift := PackedFloat64Array()
	for v in j.tierLift:
		lift.append(float(v))
	if lift.size() < 4:
		_errors.append("wrecks.json: tierLift has an entry for each of the four tiers")
	for i in range(1, lift.size()):
		if lift[i] < lift[i - 1]:
			_errors.append("wrecks.json: tierLift does not fall as the tier rises")
	var b: Dictionary = j.burst
	if float(j.reachBh) <= 0.0 or float(j.fill) <= 0.0 or float(b.wreckMassRef) <= 0.0 or float(b.scaleMin) > float(b.scaleMax) or float(b.radiusMinBh) > float(b.radiusMaxBh):
		_errors.append("wrecks.json: reachBh, fill and wreckMassRef above 0, scaleMin within scaleMax, radiusMinBh within radiusMaxBh")
	if not _errors.is_empty():
		return
	_d = j
	_hash = str(text.hash())
	K_REACH = float(j.reachBh)
	K_NEAR = float(j.nearBh)
	K_FIGHTERS = bool(j.fighters)
	K_FILL = float(j.fill)
	K_MIN = float(j.minWreckMass)
	K_LIFT = lift
	K_B_SPEED = float(b.speed)
	K_B_REF = float(b.wreckMassRef)
	K_B_SMIN = float(b.scaleMin)
	K_B_SMAX = float(b.scaleMax)
	K_B_R = float(b.radiusBh)
	K_B_RMIN = float(b.radiusMinBh)
	K_B_RMAX = float(b.radiusMaxBh)


## The wreckMass of a fallen building's wreck: its box in cubic body heights, times the data's fill. The wreck's own unit: not the car classes' mass (bike 1, sedan 3, van 4, bus 8), which are Art's.
static func wreckMass(b) -> float:
	if not _loaded:
		_load()
	return K_FILL * b.w * maxf(b.d, 1.0) * b.h / (BH * BH * BH)


## The heaviest wreck a tier (1 to 4) lifts.
static func lift(tier: float) -> float:
	if not _loaded:
		_load()
	return K_LIFT[clampi(int(tier), 1, K_LIFT.size()) - 1]


## Is building b a wreck that can still be hurled: fallen, and not already spent?
static func isWreck(b) -> bool:
	return not b.alive and b.marks != TAKEN


## Is the wreck of building b empty? A fallen building's people are gone (WorldStructures.damageBuilding sets popAlive 0 as it falls); the check is the rule's own, kept so a change there cannot make a wreck hold anyone.
static func empty(b) -> bool:
	return b.popAlive <= 0.0


## The living civilians near building b's wreck (Legal RL-186: any living civilian within `nearBh` of the wreck's edge, in a building or in the open): the people in the standing buildings whose edge is within it (the
## sim holds people as counts per building and Rendering draws them on the building's street side, within its x extent, so the street in front of a building is the building's), and the people a district flight is
## putting on the street (WorldCollateral: after a heavy event, while the budget is spent, the buildings within EVAC_R of it empty at EVAC_RATE for EVAC_ACTIVE_S): while it runs, those who are still to leave
## within reach of the wreck count. With the data's `fighters` set, a fighter within that distance counts as one more (the default: no, they are combatants).
static func livingNear(S: SimState, b) -> float:
	if not _loaded:
		_load()
	var r: float = K_NEAR * BH
	var s: float = 0.0
	for bi in WorldStructures.near(S, b.x, r + b.w * 0.5):
		var o = S.buildings[bi]
		if o == b or not o.alive or o.popAlive <= 0.0:
			continue
		var gap: float = absf(SimWrap.sdx(b.x, o.x)) - (b.w + o.w) * 0.5
		if gap < r:
			s += o.popAlive
	s += _fleeingNear(S, b, r)
	if K_FIGHTERS:
		for f in S.fighters:
			if absf(SimWrap.sdx(b.x, f.x)) - b.w * 0.5 < r:
				s += 1.0
	return s


## The people in a district flight that is running, if the wreck is within reach of where they would be: the flight's buildings are those within EVAC_R of the latest heavy event, and its people are on the
## street from the moment they leave a building (WorldCollateral.flight) until they are sheltered or gone, which the sim does not follow person by person, so while the flight runs those who may still leave count.
static func _fleeingNear(S: SimState, b, r: float) -> float:
	var w = S.world
	if w.heavyX < 0.0 or S.T - w.heavyT > WorldCollateral.EVAC_ACTIVE_S or not WorldCollateral.isOver(S):
		return 0.0
	if absf(SimWrap.sdx(b.x, w.heavyX)) - b.w * 0.5 > WorldCollateral.EVAC_R + r:
		return 0.0
	var n: float = 0.0
	for bi in WorldStructures.near(S, w.heavyX, WorldCollateral.EVAC_R):
		var o = S.buildings[bi]
		if not o.alive or o.popAlive <= 0.0:
			continue
		if absf(SimWrap.sdx(w.heavyX, o.x)) - o.w * 0.5 > WorldCollateral.EVAC_R:
			continue
		n += minf(o.popAlive, maxf(0.0, WorldCollateral.FLIGHT_MAX * o.pop - o.fled))
	return n


## The distance from the point (x, y, z) to the wreck's box: along x past its width, across depth past its footprint (when the world has depth), and up from the ground it lies on.
static func distTo(S: SimState, b, x: float, y: float, z: float) -> float:
	var dx: float = maxf(0.0, absf(SimWrap.sdx(x, b.x)) - b.w * 0.5)
	var dz: float = maxf(0.0, absf(z - b.z) - b.d * 0.5) if S.depthOn else 0.0
	var dy: float = maxf(0.0, y - WorldStructures.baseY(S, b))
	return sqrt(dx * dx + dy * dy + dz * dz)


## The wrecks Encounter may offer at a point (x, y, z): the ones within reach of it, as {id, mass, dist, ok (lifted by maxMass, empty, nothing living near), why}, nearest first (ties to the lower id). maxMass is the lift to test against (`lift(tier)`).
static func within(S: SimState, x: float, y: float, z: float, maxMass: float) -> Array:
	if not _loaded:
		_load()
	var reach: float = K_REACH * BH
	var out: Array = []
	for bi in WorldStructures.near(S, x, reach):
		var b = S.buildings[bi]
		if not isWreck(b):
			continue
		var d: float = distTo(S, b, x, y, z)
		if d > reach:
			continue
		var m: float = wreckMass(b)
		var why: String = ""
		if m < K_MIN:
			why = "small"
		elif m > maxMass:
			why = "heavy"
		elif not empty(b):
			why = "occupied"
		elif livingNear(S, b) > 0.0:
			why = "living"
		out.append({"id": bi, "wreckMass": m, "dist": d, "ok": why == "", "why": why})
	out.sort_custom(func(a, c): return a.dist < c.dist or (a.dist == c.dist and a.id < c.id))
	return out


## The query: the nearest wreck within 2 body heights of (x, y, z) that a lift of maxMass can carry, that is empty with nothing living near it. {} when there is none; else {id, mass, x, y (the ground it
## lies on), z, w, h, d, dist}. Encounter calls it with the thrower's position and his tier's lift (`lift(tier)`, or his own number).
static func pick(S: SimState, x: float, y: float, z: float, maxMass: float) -> Dictionary:
	for c in within(S, x, y, z, maxMass):
		if c.ok:
			var b = S.buildings[c.id]
			return {"id": c.id, "wreckMass": c.wreckMass, "x": b.x, "y": WorldStructures.baseY(S, b), "z": b.z, "w": b.w, "h": b.h, "d": b.d, "dist": c.dist}
	return {}


## The scrap: wreck `id` (a pick's id) is hurled and lands at (x, y). It is spent, and the structures near the landing take its damage by the brunt ladder's tier factor (speed x the tier's factor x bruntMul,
## scaled by the wreck's mass), over a radius that grows with the mass. `cause` is the thrower (his tier is the ladder's). Returns the number of structures levelled, or -1 for an id that is not a wreck.
static func burst(S: SimState, id: int, x: float, y: float, tier: float, cause) -> int:
	if not _loaded:
		_load()
	if id < 0 or id >= S.buildings.size() or not isWreck(S.buildings[id]):
		return -1
	var b = S.buildings[id]
	b.marks = TAKEN
	var sc: float = sqrt(wreckMass(b) / K_B_REF)
	var dmg: float = K_B_SPEED * float(WorldBrunt.cfg().tierFactor[WorldBrunt.tierIx(tier, false)]) * float(WorldBrunt.cfg().bruntMul) * clampf(sc, K_B_SMIN, K_B_SMAX)
	var r: float = clampf(K_B_R * BH * sc, K_B_RMIN * BH, K_B_RMAX * BH)
	SimFx.debris(S, x, y + BH * 0.3, 14, "#8a8f98", 520.0)
	SimFx.dust(S, x, y, 5, "#a89f92")
	SimFx.shake(S, 6.0, x)
	return WorldStructures.damageArea(S, x, y, r, dmg, cause)
