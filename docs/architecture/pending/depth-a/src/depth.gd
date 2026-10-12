class_name SimDepth
## Fighters in depth: the core's numbers (data/combat/depth.json; docs/architecture/depth-core.md). `enabled` is the one
## switch: SimCore.newMatch copies it into S.depthOn unless the match's setup has its own "depth". The rest is read only
## with depth on, where a fighter's depth is integrated (SimFighter.stepDepth) and where he meets a building
## (SimFighter.contact). The band, the streets and the body's half extents are World's (WorldLanes,
## data/biomes/lanes.json), read once here.

const PATH: String = "res://data/combat/depth.json"
const SCHEMA: String = "combat.depth/1"
const BH: float = 75.0     # a fighter height, in units
const SKIN: float = 0.01   # units left between a body and a face it stopped at, so a later step along the face starts clear of it
## The causes of depth a director may add (SimFighter.addDepth). capExempt in the data names the ones the cap does not hold.
const CAUSES: Array = ["push", "carry", "home", "magnet", "shove", "sidestep", "giveGround"]

static var _loaded: bool = false
static var _hash: String = ""
static var _errors: Array = []
static var _on: bool = false
static var cap: float = 0.0          # the most a drift in depth moves a fighter, units a second
static var margin: float = 0.0       # his centre keeps this far from a standing building's face, units
static var exempt: Dictionary = {}   # cause -> true: the causes the cap does not hold
static var rx: float = 0.0           # the half extents a fighter outside a flight is swept with: the body's, and at least the margin in x and z
static var ry: float = 0.0
static var rz: float = 0.0
static var zFront: float = 0.0       # the band: nobody's centre passes these
static var zBack: float = 0.0
static var lanes: Array = []         # the street lanes as [top, bottom] in units, front to back


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	_errors = []
	var j = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (j is Dictionary):
		_err("data/combat/depth.json is missing or not valid JSON")
		j = {}
	var h := SimHash.Hasher.new()
	h.text("depth")
	FighterData._canon(h, j)
	_hash = h.hex()
	if j.get("schema", "") != SCHEMA:
		_err("schema: expected " + SCHEMA + ", got " + str(j.get("schema", "")))
	var on = j.get("enabled", false)
	if not (on is bool):
		_err("enabled: must be true or false, got " + str(on))
	_on = on is bool and on
	cap = _num("maxBhPerSec", j.get("maxBhPerSec"), false) * BH
	margin = _num("faceMarginBh", j.get("faceMarginBh"), true) * BH
	exempt = {}
	var ce = j.get("capExempt", [])
	if not (ce is Array):
		_err("capExempt: must be a list of causes")
		ce = []
	for c in ce:
		if not CAUSES.has(c):
			_err("capExempt: unknown cause " + str(c) + " (the causes are " + ", ".join(CAUSES) + ")")
		else:
			exempt[c] = true
	var body: Array = WorldLanes.body()
	rx = maxf(float(body[0]), margin)
	ry = float(body[1])
	rz = maxf(float(body[2]), margin)
	var lim: Array = WorldLanes.limits()
	zFront = float(lim[0])
	zBack = float(lim[1])
	if zFront <= zBack:   # no lane table: the band the core held before it had one
		zFront = SimConst.Z_FRONT
		zBack = SimConst.Z_BACK
	lanes = WorldLanes.streets()


## The data's switch. A match's setup may set its own ("depth": true or false).
static func enabled() -> bool:
	_ensure()
	return _on


static func dataHash() -> String:
	_ensure()
	return _hash


static func errors() -> Array:
	_ensure()
	return _errors


## True when the cap does not hold this cause (capExempt in the data).
static func isExempt(cause: String) -> bool:
	_ensure()
	return exempt.has(cause)


## True when a body at depth za and at depth zb is, both times, inside one street lane with its half depth and the
## margin to spare. World builds nothing in a street lane, so a step between two such depths can meet no building and
## needs no sweep.
static func clearStreet(za: float, zb: float) -> bool:
	for l in lanes:
		var hi: float = float(l[0]) - rz - SKIN
		var lo: float = float(l[1]) + rz + SKIN
		if za >= lo and za <= hi and zb >= lo and zb <= hi:
			return true
	return false


static func _err(msg: String) -> void:
	_errors.append(msg)
	push_error("SimDepth: " + msg)


## A number of the data, in fighter heights: above 0, or 0 and above when zero is allowed.
static func _num(where: String, x, zero: bool) -> float:
	if not (x is float or x is int) or float(x) < 0.0 or (float(x) == 0.0 and not zero):
		_err(where + ": must be a number " + ("of 0 or more" if zero else "above 0") + ", got " + str(x))
		return 0.0
	return float(x)
