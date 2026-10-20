class_name SimCata
extends RefCounted
## The catastrophe tier's sky (run-mode.md section 3.2; docs/architecture/run-core.md section 6): the blast cloud's cue
## and the world's ash. A blast cloud (a tier-5 detonation: the catastrophe tier's own window calls blastCloud) sends the
## blast_cloud cue, with where it lands, its size and the tick it lands, and raises the ash over the planet by perCloud,
## at most max, over riseTicks (at least 120 s: Legal c05). The ash is S.cata's, in thousandths, and has no rule effect,
## by design: the views read it through ash(S), read-only (VFX's sky and light, Rendering's backdrop). S.cata is null
## until a blast cloud, and hashed only once it is not, so a match without one is the same to the bit. Nothing calls
## blastCloud until the catastrophe tier is built. data/fight/catastrophe.json.

const FILE: String = "res://data/fight/catastrophe.json"

static var _d = null
static var _errors: Array = []
static var perCloud: int = 0      # thousandths
static var ashMax: int = 1000     # thousandths
static var riseTicks: int = 7200
static var radius: float = 0.0


static func _ensure() -> void:
	if _d != null:
		return
	_errors = []
	var j = FighterData._load(FILE, "fight/catastrophe.json") if FileAccess.file_exists(FILE) else null
	if not (j is Dictionary):
		_err("missing, or not an object")
		_d = {}
		return
	_d = j
	var a = j.get("ash", {})
	var c = j.get("cloud", {})
	if not (a is Dictionary) or not (c is Dictionary):
		_err("ash and cloud must be objects")
		return
	perCloud = _whole("ash.perCloud", a.get("perCloud"), 0, 1000)
	ashMax = _whole("ash.max", a.get("max"), 0, 1000)
	riseTicks = _whole("ash.riseTicks (7,200 or more: 120 s, Legal c05)", a.get("riseTicks"), 7200, 1000000)
	var r = c.get("radius")
	if not (r is float or r is int) or float(r) <= 0.0 or float(r) > 100000.0:
		_err("cloud.radius: a number above 0, at most 100,000")
		r = 0.0
	radius = float(r)


static func errors() -> Array:
	_ensure()
	return _errors


## The ash over the planet, 0 to 1, for the views (read-only; 0 before any blast cloud).
static func ash(S: SimState) -> float:
	return float(S.cata.ash) / 1000.0 if S.cata != null else 0.0


## A blast cloud by f (or none) landing at x, y on tick n: the cue for VFX, Audio and Camera, and the ash's rise.
static func blastCloud(S: SimState, f, x: float, y: float, n: int) -> void:
	_ensure()
	SimFx.blastCloud(S, f, x, y, radius, n)
	if S.cata == null:
		S.cata = SimState.CataState.new()
	S.cata.ashFrom = S.cata.ash
	S.cata.ashTo = mini(ashMax, maxi(S.cata.ash, S.cata.ashTo) + perCloud)
	S.cata.ashLeft = riseTicks


## Each live tick while the ash rises (SimCore.step): straight-line from where the cloud found it to its target, to the
## nearest thousandth, landing on the target on the last tick.
static func tick(S: SimState) -> void:
	var c = S.cata
	c.ashLeft -= 1
	c.ash = c.ashTo - int(SimMathx.jround(float(c.ashTo - c.ashFrom) * float(c.ashLeft) / float(riseTicks)))


static func _whole(where: String, x, lo: int, hi: int) -> int:
	if not (x is float or x is int) or float(x) != floor(float(x)) or int(x) < lo or int(x) > hi:
		_err(where + ": a whole number from %d to %d" % [lo, hi])
		return lo
	return int(x)


static func _err(msg: String) -> void:
	_errors.append("fight/catastrophe.json: " + msg)
	if not FighterData.quiet:
		push_error("SimCata: fight/catastrophe.json: " + msg)
