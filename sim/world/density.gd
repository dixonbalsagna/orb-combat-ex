class_name WorldDensity
extends RefCounted
## How densely a gen 2 planet ring's places are built (docs/world/density.md; data/biomes/density.json; Game Design rulings-2026-10-28 item 1). A place is laid by its archetype's districts (Bellgate for a city, the
## outskirts village for a town), which stands about 38 structures on a Half ring. For a gen 2 ring the archetype is made denser before it is laid: the gaps between neighbours shorter, the houses a little narrower
## and the villages' back street built as well, so the same places stand more buildings. No site is added and no kind changes. A gen 1 ring, a gen 1 planet and the hand-made world never reach this (on() is false).

const PATH := "res://data/biomes/density.json"
const SCHEMA := "biomes.density/1"

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func errors() -> Array:
	if not _loaded:
		_load()
	return _errors


static func _load() -> void:
	_loaded = true
	_d = {}
	_errors = []
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_errors.append("density.json: cannot open " + PATH)
		return
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("density.json: not a %s object" % SCHEMA)
		return
	for k in ["enabled", "city", "town"]:
		if not j.has(k):
			_errors.append("density.json: %s is missing" % k)
			return
	for k in ["city", "town"]:
		var e = j[k]
		if not (e is Dictionary) or not e.has("gapMul") or not e.has("widthMul") or not e.has("rows"):
			_errors.append("density.json: %s needs gapMul, widthMul and rows" % k)
			return
	_d = j


## True for a gen 2 ring with the module on.
static func on() -> bool:
	return bool(data().get("enabled", false)) and WorldClimate.genNow() >= 2


## Makes settlement `sd` (an archetype's copy, which the caller owns) denser: kind "city" or "town".
static func apply(sd: Dictionary, kind: String) -> void:
	if not on():
		return
	var e: Dictionary = data()[kind]
	var gm: float = float(e.gapMul)
	var wm: float = float(e.widthMul)
	for dd in sd.districts:
		var g: Array = dd.gap_bh
		dd.gap_bh = [float(g[0]) * gm, float(g[1]) * gm]
		var w: Array = dd.width_bh
		dd.width_bh = [float(w[0]) * wm, float(w[1]) * wm]
		for kd in dd.kinds:
			if kd.has("width_bh"):
				var kw: Array = kd.width_bh
				kd.width_bh = [float(kw[0]) * wm, float(kw[1]) * wm]
		var rows: Array = []
		for r in dd.rows:
			rows.append(int(r))
		for r in e.rows:
			if not rows.has(int(r)):
				rows.append(int(r))
		rows.sort()
		dd.rows = rows
