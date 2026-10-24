class_name WorldLakes
extends RefCounted
## Planet generation 2's lakes (docs/world/planet-gen2.md, window 5; data/biomes/lakes.json). A gen 2 match's ring is a line of ground heights; a valley in it that is walled on both sides holds a lake whose
## surface is flat at the lower of its two crests. `plan` finds them in the ground (after the settlements' platforms) and `apply` puts the water in S.water where the match starts; the water module's flow leaves
## inland water alone unless a crater opens a hole below sea level, so a lake stands until the ground under it is dug out. Pure functions of the ground, the settlements and the fine biomes; no draw.

const PATH := "res://data/biomes/lakes.json"
const SCHEMA := "biomes.lakes/1"

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""
static var _refuse := PackedByteArray()   # per fine biome: 1 if no lake stands in it
static var K_DEPTH: float = 40.0
static var K_WIDTH: int = 12
static var K_FLOOR: float = 5.0
static var K_MAXLEVEL: float = 3500.0
static var K_MARGIN: int = 10
static var K_SPAN: int = 480


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
		_errors.append("lakes.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("lakes.json: not a %s object" % SCHEMA)
		return
	for k in ["minDepth", "minWidth", "minFloor", "maxLevel", "margin", "maxSpan", "refuse"]:
		if not j.has(k):
			_errors.append("lakes.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	var fine: Array = WorldClimate.data().get("fine", [])
	var ref := PackedByteArray()
	ref.resize(fine.size())
	for nm in j.refuse:
		var idx: int = -1
		for k in range(fine.size()):
			if String(fine[k].name) == String(nm):
				idx = k
		if idx < 0:
			_errors.append("lakes.json: refuse names %s, which climate.json does not have" % str(nm))
		else:
			ref[idx] = 1
	if float(j.minDepth) <= 0.0 or int(j.minWidth) < 2 or int(j.maxSpan) < int(j.minWidth) or int(j.margin) < 0:
		_errors.append("lakes.json: minDepth above 0, minWidth at least 2, maxSpan at least minWidth, margin at least 0")
	if not _errors.is_empty():
		return
	_d = j
	_hash = str(text.hash())
	_refuse = ref
	K_DEPTH = float(j.minDepth)
	K_WIDTH = int(j.minWidth)
	K_FLOOR = float(j.minFloor)
	K_MAXLEVEL = float(j.maxLevel)
	K_MARGIN = int(j.margin)
	K_SPAN = int(j.maxSpan)


## The lakes of a ring: [[first column, last column, level]] in column order. `base` is the ground (after the platforms), `chords` the settlements' [id, kind, col0, col1], `fine` the fine biome of each
## column and `stored` the stored biome (7 and 8, a town's or a city's ground, are never a lake's floor).
static func plan(base: PackedFloat32Array, chords: Array, fine: PackedByteArray, stored: PackedByteArray) -> Array:
	if not _loaded:
		_load()
	var n: int = base.size()
	var lakes: Array = []
	var taken := PackedByteArray()
	taken.resize(n)
	for m in range(n):
		if taken[m] != 0:
			continue
		var b: float = base[m]
		if b < K_FLOOR:
			continue
		var l1: float = base[(m + n - 1) % n]
		var r1: float = base[(m + 1) % n]
		if not (b <= l1 and b <= r1 and (b < l1 or b < r1)):
			continue   # not a local minimum
		# climb to the crest on each side
		var cl: int = m
		var steps: int = 0
		while steps < K_SPAN and base[(cl + n - 1) % n] >= base[cl]:
			cl = (cl + n - 1) % n
			steps += 1
		var crestL: float = base[cl]
		var cr: int = m
		steps = 0
		while steps < K_SPAN and base[(cr + 1) % n] >= base[cr]:
			cr = (cr + 1) % n
			steps += 1
		var crestR: float = base[cr]
		var level: float = minf(crestL, crestR)
		if level - b < K_DEPTH or level > K_MAXLEVEL:
			continue
		# the water's extent: out from the minimum while the ground is under the level
		var lb: int = m
		var wl: int = 0
		while wl < K_SPAN and base[(lb + n - 1) % n] < level:
			lb = (lb + n - 1) % n
			wl += 1
		var rb: int = m
		var wr: int = 0
		while wr < K_SPAN and base[(rb + 1) % n] < level:
			rb = (rb + 1) % n
			wr += 1
		var width: int = wl + wr + 1
		if width < K_WIDTH or width >= n - 2 * K_MARGIN:
			continue
		var f: int = fine[m] if m < fine.size() else 0
		if f < _refuse.size() and _refuse[f] == 1:
			continue
		var bad: bool = false
		for k in range(width):
			var c: int = (lb + k) % n
			if stored[c] >= 7:
				bad = true
				break
		if bad:
			continue
		for ch in chords:
			# a settlement within margin columns of the water (on the ring)
			var c0: int = int(ch[2])
			var c1: int = int(ch[3])
			var lo: int = lb - K_MARGIN
			var hi: int = lb + width - 1 + K_MARGIN
			if _overlap(lo, hi, c0, c1, n):
				bad = true
				break
		if bad:
			continue
		for k in range(width):
			taken[(lb + k) % n] = 1
		lakes.append([lb, (lb + width - 1) % n, level, width])
	return lakes


## Do the columns lo to hi (which may run past either end of the ring) meet the columns c0 to c1?
static func _overlap(lo: int, hi: int, c0: int, c1: int, n: int) -> bool:
	for shift in [-n, 0, n]:
		if lo <= c1 + shift and hi >= c0 + shift:
			return true
	return false


## Is column c under the water of a planned lake?
static func inLake(lakes: Array, c: int, n: int) -> bool:
	for lk in lakes:
		var off: int = (c - int(lk[0]) + n) % n
		if off < int(lk[3]):
			return true
	return false


## The trees that do not stand in a lake: the same list without them.
static func dryTrees(trees: Array, lakes: Array, n: int) -> Array:
	if lakes.is_empty():
		return trees
	var out: Array = []
	for t in trees:
		var col: int = int(floor(SimWrap.wrap(t.x) / SimConst.COL)) % n
		if not inLake(lakes, col, n):
			out.append(t)
	return out


## The lakes whose every column the new ring takes (weight at least 0.5): the turn plants only these; a lake that reaches into the blend zone would stand on ground still changing.
static func onlyNew(lakes: Array, wt: PackedFloat32Array) -> Array:
	var n: int = wt.size()
	var out: Array = []
	for lk in lakes:
		var all: bool = true
		for k in range(int(lk[3])):
			if wt[(int(lk[0]) + k) % n] < 0.5:
				all = false
				break
		if all:
			out.append(lk)
	return out


## The lakes of the old ring the turn keeps: those whose every column is in the kept core (weight 0), where the ground does not change.
static func onlyKept(lakes: Array, wt: PackedFloat32Array) -> Array:
	var n: int = wt.size()
	var out: Array = []
	for lk in lakes:
		var all: bool = true
		for k in range(int(lk[3])):
			if wt[(int(lk[0]) + k) % n] > 0.0:
				all = false
				break
		if all:
			out.append(lk)
	return out


## Terrain changed round column c0 (half width cols): every lake column in the reach is refilled to its lake's flat level, as the sea's reservoir columns are, so a dug bed keeps a level surface and a berm
## does not raise the water. The lakes are S.planetRing["lakes"].
static func refill(S: SimState, c0: int, cols: int) -> void:
	var lakes: Array = S.planetRing.get("lakes", [])
	if lakes.is_empty():
		return
	var n: int = SimConst.NC
	var dfm: PackedFloat32Array = WorldTerrain.lowD(S)
	for lk in lakes:
		for k in range(-cols, cols + 1):
			var c: int = (c0 + k + n) % n
			var off: int = (c - int(lk[0]) + n) % n
			if off < int(lk[3]):
				S.water[c] = maxf(0.0, float(lk[2]) - (S.base[c] + dfm[c]))


## Put the water in S.water (after WorldWater.init has sized it): the depth from the valley floor to the lake's level. The surface (ground plus depth) is the flat level.
static func apply(S: SimState, lakes: Array) -> void:
	var n: int = SimConst.NC
	for lk in lakes:
		for k in range(int(lk[3])):
			var c: int = (int(lk[0]) + k) % n
			var d: float = float(lk[2]) - S.base[c]
			if d > 0.0:
				S.water[c] = d
