class_name WorldGround
extends RefCounted
## Planet generation 2's ground profiles (docs/world/planet-gen2.md, window 2; data/biomes/ground.json): what each fine biome does to a body (grip, absorb, rough, furrow: multipliers on contact.gd's
## own numbers), what stands on it (trees, laid per column from a keyed draw), where a fighter finds cover, and what dresses it (props, for the renderer). Everything here is read only when a match is on
## a gen 2 planet (WorldBiomes.fineCols is not empty); a gen 1 match never reaches it, so it is bit for bit what it was.
##
## Per-column draws are SimRng.keyed (a stateless draw from a seed, a key and the column), so a column's tree is the same whatever else changed: a turn of the arena keeps the old ring's trees where the
## ground is kept and lays the new ring's where it is new, with no stream to line up.

const PATH := "res://data/biomes/ground.json"
const SCHEMA := "biomes.ground/1"
const SURFACES: Array = ["soil", "sand", "rock"]   # the same order as contact.gd's SURF_NAMES, whose codes these are
const COVER_KINDS: Array = ["canopy", "ridge"]
const LOOKS: Array = ["paving", "rock", "soil", "sand", "rubble", "ice", "snow", "frost", "mud", "turf", "litter", "ash", "crust", "shingle", "ember"]   # the look classes: the five built and the nine of Combat's biome park, and the one a beam's glowing ember strip reads as (after.gd)

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""
static var _grip := PackedFloat64Array()
static var _absorb := PackedFloat64Array()
static var _rough := PackedFloat64Array()
static var _furrow := PackedFloat64Array()
static var _surf := PackedByteArray()
static var _look := PackedByteArray()
static var _trees: Array = []    # per fine biome: [p per column, h0, h1] in units, or null
static var _cover: Array = []    # per fine biome: {"kind", "low"} (low in units) or null
static var _minGround: float = 6.0


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


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
		_errors.append("ground.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("ground.json: not a %s object" % SCHEMA)
		return
	for k in ["trees", "grounds"]:
		if not j.has(k):
			_errors.append("ground.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	var fine: Array = WorldClimate.data().get("fine", [])
	if j.grounds.size() != fine.size():
		_errors.append("ground.json: grounds has %d entries and climate.json has %d fine biomes" % [j.grounds.size(), fine.size()])
		return
	for k in range(j.grounds.size()):
		var g: Dictionary = j.grounds[k]
		if int(g.id) != k or String(g.name) != String(fine[k].name):
			_errors.append("ground.json: grounds[%d] is %s (id %d), climate.json's fine[%d] is %s" % [k, g.name, int(g.id), k, fine[k].name])
		if not SURFACES.has(String(g.surface)):
			_errors.append("ground.json: %s: surface %s is not one of %s" % [g.name, g.surface, str(SURFACES)])
		if not LOOKS.has(String(g.look)):
			_errors.append("ground.json: %s: look %s is not one of %s" % [g.name, g.look, str(LOOKS)])
		for key in ["grip", "absorb", "rough", "furrow"]:
			var v: float = float(g[key])
			if v < 0.1 or v > 3.0 or (key == "rough" and v < 1.0):
				_errors.append("ground.json: %s: %s %s is outside %s to 3" % [g.name, key, str(v), "1" if key == "rough" else "0.1"])
		if g.trees != null:
			if g.trees.gap.size() != 2 or g.trees.h.size() != 2 or float(g.trees.gap[0]) <= 0.0 or float(g.trees.gap[0]) > float(g.trees.gap[1]) or float(g.trees.h[0]) <= 0.0 or float(g.trees.h[0]) > float(g.trees.h[1]):
				_errors.append("ground.json: %s: trees needs gap and h as [low, high], both above 0" % g.name)
		if g.cover != null:
			if not COVER_KINDS.has(String(g.cover.kind)) or float(g.cover.low) <= 0.0:
				_errors.append("ground.json: %s: cover needs a kind (%s) and a low above 0" % [g.name, str(COVER_KINDS)])
			elif String(g.cover.kind) == "canopy" and g.trees == null:
				_errors.append("ground.json: %s: canopy cover needs trees" % g.name)
		for p in g.props:
			if float(p.per) <= 0.0 or p.size.size() != 2 or float(p.size[0]) > float(p.size[1]):
				_errors.append("ground.json: %s: prop %s needs per above 0 and size as [low, high]" % [g.name, p.kind])
	if not _errors.is_empty():
		return
	_d = j
	_hash = str(text.hash())
	var WS: float = SimConst.WS
	var COL: float = SimConst.COL
	_minGround = float(j.trees.minGround)
	var n: int = j.grounds.size()
	_grip.resize(n)
	_absorb.resize(n)
	_rough.resize(n)
	_furrow.resize(n)
	_surf.resize(n)
	_look.resize(n)
	_trees = []
	_cover = []
	for k in range(n):
		var g: Dictionary = j.grounds[k]
		_grip[k] = float(g.grip)
		_absorb[k] = float(g.absorb)
		_rough[k] = float(g.rough)
		_furrow[k] = float(g.furrow)
		_surf[k] = SURFACES.find(String(g.surface))
		_look[k] = LOOKS.find(String(g.look))
		if g.trees == null:
			_trees.append(null)
		else:
			var mean: float = (float(g.trees.gap[0]) + float(g.trees.gap[1])) * 0.5 * WS   # a tree to every mean-gap of ground: a chance of COL / mean a column
			_trees.append([minf(1.0, COL / mean), float(g.trees.h[0]) * WS, float(g.trees.h[1]) * WS])
		_cover.append(null if g.cover == null else {"kind": String(g.cover.kind), "low": float(g.cover.low) * WS})


## The grip times the roughness of a fine biome's profile (an ice strip's brake in after.gd): 1 for a name ground.json does not know.
static func profileGrip(name: String) -> float:
	if not _loaded:
		_load()
	var fine: Array = WorldClimate.data().get("fine", [])
	for k in range(mini(fine.size(), _grip.size())):
		if String(fine[k].name) == name:
			return _grip[k] * _rough[k]
	return 1.0


## The ground's numbers per terrain column for a gen 2 match: {"grip", "absorb", "rough", "furrow"} (PackedFloat64Array, 1.0 on a settled column), "surf" (a code into SURFACES, 255 on a settled
## column, where contact.gd's own village and city rule stands) and "look" (a code into LOOKS, 255 likewise). `fine`: the fine biome of each column; `stored`: the stored biome (7 and 8 are a town's and a city's ground).
static func columns(fine: PackedByteArray, stored: PackedByteArray) -> Dictionary:
	if not _loaded:
		_load()
	var n: int = fine.size()
	var grip := PackedFloat64Array()
	var absorb := PackedFloat64Array()
	var rough := PackedFloat64Array()
	var furrow := PackedFloat64Array()
	var surf := PackedByteArray()
	var look := PackedByteArray()
	look.resize(n)
	grip.resize(n)
	absorb.resize(n)
	rough.resize(n)
	furrow.resize(n)
	surf.resize(n)
	for i in range(n):
		var f: int = fine[i]
		if int(stored[i]) >= 7 or f >= _grip.size():
			grip[i] = 1.0
			absorb[i] = 1.0
			rough[i] = 1.0
			furrow[i] = 1.0
			surf[i] = 255
			look[i] = 255
		else:
			grip[i] = _grip[f]
			absorb[i] = _absorb[f]
			rough[i] = _rough[f]
			furrow[i] = _furrow[f]
			surf[i] = _surf[f]
			look[i] = _look[f]
	return {"grip": grip, "absorb": absorb, "rough": rough, "furrow": furrow, "surf": surf, "look": look}


## True when the match being played has fine ground: a gen 2 planet's columns (the fine biomes parallel to the stored ones). False for the hand-made world and a gen 1 planet, whatever an earlier match left.
static func live() -> bool:
	return WorldBiomes.fineCols.size() > 0 and WorldBiomes.fineCols.size() == WorldBiomes.planetCols.size()


## The hiding on the natural ground at x: {"kind": "canopy" or "ridge", "low": units above the ground} or null. Null when the match has no fine ground (a gen 1 world) or the column is a town's or a city's.
static func coverOf(x: float):
	if not live():
		return null
	var fc: PackedByteArray = WorldBiomes.fineCols
	if not _loaded:
		_load()
	var col: int = int(floor(SimWrap.wrap(x) / SimConst.COL)) % fc.size()
	if int(WorldBiomes.planetCols[col]) >= 7 or int(fc[col]) >= _cover.size():
		return null
	return _cover[int(fc[col])]


## The name the cover finder (WorldCover.nearestCover) knows a column's hiding by: "ocean", "forest" for canopy, "mountains" for ridge, or "" for none.
static func coverName(x: float) -> String:
	var fc: PackedByteArray = WorldBiomes.fineCols
	var col: int = int(floor(SimWrap.wrap(x) / SimConst.COL)) % fc.size()
	if int(WorldBiomes.planetCols[col]) >= 7:
		return ""
	if int(fc[col]) == WorldClimate.F_OCEAN:
		return "ocean"
	var c = coverOf(x)
	if c == null:
		return ""
	return "forest" if String(c.kind) == "canopy" else "mountains"


## The trees of a ring: a tree in a treed column by its chance (COL over the mean gap), at a keyed place in the column, a keyed height. Dry ground only (`base`, the ground after the platforms), never on
## a town's or a city's. `seed`: the ring's slice hash. A pure function of its inputs; the trees come in column order.
static func layTrees(fine: PackedByteArray, stored: PackedByteArray, base: PackedFloat32Array, seed: int, wt: PackedFloat32Array = PackedFloat32Array()) -> Array:
	if not _loaded:
		_load()
	var out: Array = []
	var COL: float = SimConst.COL
	var useW: bool = wt.size() == fine.size()   # a turn lays only the columns it takes from the new ring (weight at least 0.5): the rest it would throw away
	# SimRng.keyed(seed, key, n) is _fmix(x ^ imul(n, 0x9E3779B1)) with x = _fmix(seed ^ fnv(key)): the first half once a key
	var xa: int = SimRng._fmix((seed ^ _fnv("ground.tree")) & SimRng.MASK)
	var xb: int = SimRng._fmix((seed ^ _fnv("ground.tree.x")) & SimRng.MASK)
	var xc: int = SimRng._fmix((seed ^ _fnv("ground.tree.h")) & SimRng.MASK)
	for i in range(fine.size()):
		var f: int = fine[i]
		if f >= _trees.size() or _trees[f] == null or int(stored[i]) >= 7 or base[i] < _minGround:
			continue
		if useW and wt[i] < 0.5:
			continue
		var t: Array = _trees[f]
		var m: int = SimRng.imul(i & SimRng.MASK, 0x9E3779B1)
		if float(SimRng._fmix(xa ^ m)) / 4294967296.0 >= float(t[0]):
			continue
		var tr := SimState.TreeState.new()
		tr.x = (float(i) + float(SimRng._fmix(xb ^ m)) / 4294967296.0) * COL
		tr.h = float(t[1]) + (float(t[2]) - float(t[1])) * float(SimRng._fmix(xc ^ m)) / 4294967296.0
		out.append(tr)
	return out


static func _fnv(id: String) -> int:
	var h: int = 0x811c9dc5
	for i in range(id.length()):
		h = SimRng.imul((h ^ id.unicode_at(i)) & SimRng.MASK, 0x01000193)
	return h


## The set dressing of columns i0 up to (not including) i1 for the renderer: [{"x", "kind", "size", "col"}] by a keyed draw per column and prop, on dry ground and never on a town's or a city's. A pure
## function of the columns, the ground and the seed; the sim never reads it.
static func propsIn(fine: PackedByteArray, stored: PackedByteArray, base: PackedFloat32Array, seed: int, i0: int, i1: int) -> Array:
	if not _loaded:
		_load()
	var out: Array = []
	var COL: float = SimConst.COL
	var n: int = fine.size()
	for i in range(maxi(i0, 0), mini(i1, n)):
		var f: int = fine[i]
		if f >= _d.grounds.size() or int(stored[i]) >= 7 or base[i] < _minGround:
			continue
		var props: Array = _d.grounds[f].props
		for k in range(props.size()):
			var p: Dictionary = props[k]
			if SimRng.keyed(seed, "ground.prop.%d" % k, i) >= minf(1.0, float(p.per) * COL / 1000.0):
				continue
			var u: float = SimRng.keyed(seed, "ground.prop.s%d" % k, i)
			out.append({"x": (float(i) + SimRng.keyed(seed, "ground.prop.x%d" % k, i)) * COL, "kind": String(p.kind), "size": float(p.size[0]) + (float(p.size[1]) - float(p.size[0])) * u, "col": i})
	return out
