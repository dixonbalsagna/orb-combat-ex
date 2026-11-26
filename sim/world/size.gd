class_name WorldPlanetSize
extends RefCounted
## The planet's size (A1; docs/world/planet-sizes.md; data/biomes/sizes.json). A match's setup names a size (planetSize); the sim binds it with SimConst.setPlanet at the top of the match. Pure reads of the data.
## Medium is today's planet: 4,800 columns, the arena the whole great circle, the bake every 512 units, byte for byte. A size changes the planet's length and the places on it; it never changes a column (32 units), a body or a speed.

const PATH := "res://data/biomes/sizes.json"
const SCHEMA := "biomes.sizes/1"

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _names: Array = []
static var heldOverride: bool = false   # tests and probes only: a size the data does not offer plays as named. The game never sets it (size_check proves nothing outside tools and tests does).
static var heldHits: int = 0   # how many times a setup named a size that is not offered (a count for the checks: not state, not hashed)


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	_names = []
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return   # no file: every planet is medium
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("sizes.json: not a %s object" % SCHEMA)
		return
	if not j.has("default") or not (j.get("sizes") is Dictionary) or not j.sizes.has(String(j.get("default", ""))):
		_errors.append("sizes.json: default names a size in sizes")
		return
	for k in j.sizes:
		var r = j.sizes[k]
		if not (r is Dictionary) or not r.has("cols") or not r.has("arenaCols") or not r.has("bakeStride") or not r.has("offered"):
			_errors.append("sizes.json: %s is {cols, arenaCols, bakeStride, offered}" % k)
			continue
		var cols: int = int(r.cols)
		if cols < 1280 or cols % 64 != 0:
			_errors.append("sizes.json: %s: cols is a multiple of 64 (a face edge, cols / 16 nodes of 128 units, is a multiple of 4 so the bake lines up)" % k)
		if int(r.arenaCols) < 600 or int(r.arenaCols) > cols or int(r.arenaCols) % 8 != 0:
			_errors.append("sizes.json: %s: arenaCols is 600 to cols, a multiple of 8" % k)
		if int(r.bakeStride) < 1 or (cols / 16) % int(r.bakeStride) != 0:
			_errors.append("sizes.json: %s: bakeStride divides the face edge's nodes (cols / 16)" % k)
	if not _errors.is_empty():
		return
	if int(j.sizes[String(j.default)].cols) != SimConst.PLANET_NC_MEDIUM:
		_errors.append("sizes.json: the default size is medium's 4,800 columns")
		return
	_d = j
	for k in j.sizes:
		_names.append(String(k))


## The size names, in the data's order (only the offered ones when `offered` is true: the menu's list, and the sizes a setup can play).
static func names(offered: bool = false) -> Array:
	if not _loaded:
		_load()
	var out: Array = []
	for k in _names:
		if not offered or bool(_d.sizes[k].offered):
			out.append(k)
	return out


## The name of the size of a setup: its planetSize when the setup names a planet (the hand-made world is always medium), the data has it and the data OFFERS it, else the default. A size the data has but does not offer (held) plays
## medium with an error, whoever names it (a replay, a setup constant, a probe): hidden means unreachable. heldOverride is the tests' and the probes' way in.
static func nameOf(setup: Dictionary) -> String:
	if not _loaded:
		_load()
	if _d.is_empty() or not setup.has("planet"):
		return "medium"
	var n: String = String(setup.get("planetSize", _d.default))
	if not _d.sizes.has(n):
		if not FighterData.quiet:
			push_error("SimCore.newMatch: setup.planetSize %s is not a size in sizes.json (%s); medium plays" % [n, str(_names)])
		return String(_d.default)
	if not bool(_d.sizes[n].offered) and not heldOverride:
		heldHits += 1
		if not FighterData.quiet:
			push_error("SimCore.newMatch: setup.planetSize %s is held (sizes.json offered is false); medium plays" % n)
		return String(_d.default)
	return n


## Whether a setup names a size the data has and does not offer (held): what nameOf would refuse, read from the data alone (no error, no override). For a replay's or a handshake's refusal line.
static func isHeld(setup: Dictionary) -> bool:
	if not _loaded:
		_load()
	if _d.is_empty() or not setup.has("planet") or not setup.has("planetSize"):
		return false
	var n: String = String(setup.planetSize)
	return _d.sizes.has(n) and not bool(_d.sizes[n].offered)


## The size table as a data hash reads it: sizes.json without `offered`. Which sizes a player can reach is not what a size is, so un-hiding one moves no hash (a replay's header and the handshake take this, not data()).
static func hashData() -> Dictionary:
	if not _loaded:
		_load()
	var out: Dictionary = _d.duplicate(true)
	if out.has("sizes"):
		for k in out.sizes:
			(out.sizes[k] as Dictionary).erase("offered")
	return out


static func colsOf(setup: Dictionary) -> int:
	if not _loaded:
		_load()
	if _d.is_empty():
		return SimConst.PLANET_NC_MEDIUM
	return int(_d.sizes[nameOf(setup)].cols)


## The longest ring a fight on this size is played on, in columns (the planet's own round up to big, the cap past it).
static func arenaCap(cols: int) -> int:
	if not _loaded:
		_load()
	for k in _names:
		if int(_d.sizes[k].cols) == cols:
			return int(_d.sizes[k].arenaCols)
	return cols


## The bake's spacing in 128-unit nodes for a planet of `cols` columns.
static func bakeStrideFor(cols: int) -> int:
	if not _loaded:
		_load()
	for k in _names:
		if int(_d.sizes[k].cols) == cols:
			return int(_d.sizes[k].bakeStride)
	return 4


## The planet.json numbers this size changes (the places: cities, towns and the ring's minimums), or {} for medium: merged over P.c when the planet is made.
static func placesFor(cols: int) -> Dictionary:
	if not _loaded:
		_load()
	for k in _names:
		if int(_d.sizes[k].cols) == cols:
			return _d.sizes[k].get("places", {})
	return {}


## The name of a size by its columns, or "" (a report, the HUD).
static func nameOfCols(cols: int) -> String:
	if not _loaded:
		_load()
	for k in _names:
		if int(_d.sizes[k].cols) == cols:
			return k
	return ""
