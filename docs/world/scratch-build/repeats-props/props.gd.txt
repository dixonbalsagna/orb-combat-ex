class_name WorldProps
## The throwable objects' hold points (docs/world/prop-hold-points.md; data/biomes/props.json). Animation's grip on a prop (throwables-sizing.md T1) reads a hand's place as
## a world point, the way it reads a body region: the class's hold point in the prop's own frame, turned and placed. A pure function of the prop's state; the prop itself
## (S.props, World's option B in docs/world/cars-plan.md) is not built yet, so nothing in the sim calls this and no golden can move.
##
## The prop's frame: the origin on the ground under its centre, x along its length with the front at +x, y up, z across (positive toward the camera). `facing` -1 mirrors
## it (the object turned about); `turn` is its rotation about the depth axis through the middle of its box, in radians, counter-clockwise seen side-on (a tumbling object).

const PATH: String = "res://data/biomes/props.json"
const SCHEMA: String = "biomes.props/1"
const SLOTS: Array = ["frame", "underside_l", "underside_r", "top", "end_a", "end_b"]
static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_errors.append("props.json: cannot open " + PATH)
		return
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("props.json: not a %s object" % SCHEMA)
		return
	if j.get("slots", []) != SLOTS:
		_errors.append("props.json: slots are %s" % str(SLOTS))
	var cl = j.get("classes", {})
	if not (cl is Dictionary) or cl.is_empty():
		_errors.append("props.json: classes is a non-empty object")
		return
	for k in cl:
		var c = cl[k]
		if not (c is Dictionary):
			_errors.append("props.json: class %s is an object" % k)
			continue
		for key in ["length", "height", "depth"]:
			if not (c.get(key) is float or c.get(key) is int) or float(c.get(key)) <= 0.0:
				_errors.append("props.json: %s.%s is a number above 0" % [k, key])
		var h = c.get("holds", {})
		for sl in SLOTS:
			var p = h.get(sl) if h is Dictionary else null
			if not (p is Array) or p.size() != 3:
				_errors.append("props.json: %s.holds.%s is [x, y, z]" % [k, sl])
	_d = cl
	var hs := SimHash.Hasher.new()
	hs.text("biomes.props")
	FighterData._canon(hs, j)
	_hash = hs.hex()


static func classes() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


## The data's hash. Not folded into a replay's data hash yet: nothing in the sim reads it.
static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash


static func has(cls: String) -> bool:
	return classes().has(cls)


## A hold point in the prop's own frame ([x, y, z]), or [] for an unknown class or slot.
static func local(cls: String, slot: String) -> Array:
	var c = classes().get(cls)
	if c == null or not c.holds.has(slot):
		return []
	var p: Array = c.holds[slot]
	return [float(p[0]), float(p[1]), float(p[2])]


## The world point of a hold point, for a prop of class cls with its ground centre at (x, y, z), turned by `turn` radians about the middle of its box, facing +1 or -1.
## x is wrapped (the planet's seam). [] for an unknown class or slot.
static func holdPoint(cls: String, slot: String, x: float, y: float, z: float, turn: float = 0.0, facing: float = 1.0) -> Array:
	var p: Array = local(cls, slot)
	if p.is_empty():
		return []
	var hmid: float = float(classes()[cls].height) * 0.5
	var lx: float = p[0] * (-1.0 if facing < 0.0 else 1.0)
	var ly: float = p[1] - hmid
	var cs: float = SimDetMath.cos(turn)
	var sn: float = SimDetMath.sin(turn)
	return [SimWrap.wrap(x + lx * cs - ly * sn), y + hmid + lx * sn + ly * cs, z + p[2]]


## All six hold points of one prop, by slot name (the view's read each tick).
static func holdPoints(cls: String, x: float, y: float, z: float, turn: float = 0.0, facing: float = 1.0) -> Dictionary:
	var out: Dictionary = {}
	for sl in SLOTS:
		out[sl] = holdPoint(cls, sl, x, y, z, turn, facing)
	return out
