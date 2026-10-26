class_name WorldSites
extends RefCounted
## Planet generation 2's placement and transitions (docs/world/planet-gen2.md, window 4; data/biomes/sites.json). Two parts, both only for a gen 2 planet:
##  - score: how good a candidate place is by its climate and its coast, added to the stored planet's own score (spacing, height) in WorldPlanet._tryPlace. A city wants a harbour (some sea round it, not
##    an islet) and a fertile biome; no place stands on ice, in the sea, on volcanic ground or on a high range.
##  - blend: a ring's fine biomes meet in a ragged band, not a ruled line: a column near the border of a different biome of the set takes it by a keyed draw whose chance falls with the distance.
## float64, + - * / sqrt and the sim's sin and cos only; every draw is SimRng.keyed (stateless), so the same ring blends the same however it was read.

const PATH := "res://data/biomes/sites.json"
const SCHEMA := "biomes.sites/1"

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""
static var _w := [PackedFloat64Array(), PackedFloat64Array()]   # per kind (city, town), the weight of each fine biome
static var _inset := PackedByteArray()                           # per fine biome: 1 if it blends at its borders
static var K_REJECT: float = -50.0
static var K_SCALE: float = 1.0
static var _maxB := [0.0, 0.0]   # per kind: the most the score can add (the largest weight and the coast bonus, times the scale)
static var K_DIRS: int = 8
static var K_REACH := [4500.0, 2500.0]
static var K_LOW: int = 1
static var K_HIGH: int = 5
static var K_BONUS := [4.0, 1.5]
static var K_PEN := [-2.0, -0.5]
static var K_E_W: int = 48
static var K_E_MAX: float = 0.5
static var K_E_CELL: int = 6
static var K_E_SEED: int = 0
static var _cs := PackedFloat64Array()
static var _sn := PackedFloat64Array()


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
		_errors.append("sites.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("sites.json: not a %s object" % SCHEMA)
		return
	for k in ["sites", "ecotones"]:
		if not j.has(k):
			_errors.append("sites.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	var fine: Array = WorldClimate.data().get("fine", [])
	var wc := PackedFloat64Array()
	var wt := PackedFloat64Array()
	for g in fine:
		var nm: String = String(g.name)
		if not j.sites.weights.has(nm) or j.sites.weights[nm].size() != 2:
			_errors.append("sites.json: sites.weights needs [city, town] for %s" % nm)
			wc.append(0.0)
			wt.append(0.0)
		else:
			wc.append(float(j.sites.weights[nm][0]))
			wt.append(float(j.sites.weights[nm][1]))
	var inset := PackedByteArray()
	inset.resize(fine.size())
	for nm in j.ecotones.biomes:
		var idx: int = -1
		for k in range(fine.size()):
			if String(fine[k].name) == String(nm):
				idx = k
		if idx < 0:
			_errors.append("sites.json: ecotones.biomes names %s, which climate.json does not have" % str(nm))
		else:
			inset[idx] = 1
	var co: Dictionary = j.sites.coast
	if int(co.dirs) < 3 or int(co.low) > int(co.high) or int(co.high) > int(co.dirs):
		_errors.append("sites.json: coast needs dirs of at least 3 and 0 <= low <= high <= dirs")
	if int(j.ecotones.width) < 1 or int(j.ecotones.cell) < 1 or float(j.ecotones.max) < 0.0 or float(j.ecotones.max) > 1.0:
		_errors.append("sites.json: ecotones needs width and cell of at least 1 and max in [0, 1]")
	if not _errors.is_empty():
		return
	_d = j
	_hash = str(text.hash())
	_w = [wc, wt]
	_inset = inset
	K_REJECT = float(j.sites.reject)
	K_SCALE = float(j.sites.scale)
	K_DIRS = int(co.dirs)
	K_REACH = [float(co.reach[0]), float(co.reach[1])]
	K_LOW = int(co.low)
	K_HIGH = int(co.high)
	K_BONUS = [float(co.bonus[0]), float(co.bonus[1])]
	K_PEN = [float(co.penalty[0]), float(co.penalty[1])]
	K_E_W = int(j.ecotones.width)
	K_E_MAX = float(j.ecotones.max)
	K_E_CELL = int(j.ecotones.cell)
	K_E_SEED = int(j.ecotones.seed)
	for kd in range(2):
		var mw: float = -1.0e9
		for v in _w[kd]:
			if v > K_REJECT and v > mw:
				mw = v
		_maxB[kd] = maxf(0.0, (mw + maxf(0.0, K_BONUS[kd])) * K_SCALE)
	_cs.resize(K_DIRS)
	_sn.resize(K_DIRS)
	for k in range(K_DIRS):
		var a: float = SimMathx.TAU * float(k) / float(K_DIRS)
		_cs[k] = SimDetMath.cos(a)
		_sn[k] = SimDetMath.sin(a)


## The most a gen 2 candidate's score can add to the stored planet's (for _tryPlace: a candidate whose stored score plus this cannot beat the best so far is not scored).
static func maxBonus(kind: int) -> float:
	if not _loaded:
		_load()
	return _maxB[kind]


## How many of the ring of directions round a point, `reach` units out, are in the sea (the stored ground below sea level there).
static func seaDirs(P: WorldPlanet.Planet, px: float, py: float, pz: float, reach: float) -> int:
	# a frame at the point: t1 along the ground, t2 across it
	var ax: float = 0.0
	var ay: float = 1.0
	var az: float = 0.0
	if absf(py) > 0.9:
		ax = 1.0
		ay = 0.0
	var t1x: float = py * az - pz * ay
	var t1y: float = pz * ax - px * az
	var t1z: float = px * ay - py * ax
	var tl: float = sqrt(t1x * t1x + t1y * t1y + t1z * t1z)
	t1x /= tl
	t1y /= tl
	t1z /= tl
	var t2x: float = py * t1z - pz * t1y
	var t2y: float = pz * t1x - px * t1z
	var t2z: float = px * t1y - py * t1x
	var a: float = reach / P.R
	var ca: float = SimDetMath.cos(a)
	var sa: float = SimDetMath.sin(a)
	var n: int = 0
	for k in range(K_DIRS):
		var dx: float = _cs[k] * t1x + _sn[k] * t2x
		var dy: float = _cs[k] * t1y + _sn[k] * t2y
		var dz: float = _cs[k] * t1z + _sn[k] * t2z
		if WorldPlanet.ground(P, px * ca + dx * sa, py * ca + dy * sa, pz * ca + dz * sa) < 0.0:
			n += 1
	return n


## The score a gen 2 planet adds to a candidate place of `kind` (WorldPlanet.KIND_CITY or KIND_TOWN) at the unit point p, whose stored ground is h: the biome's weight plus the coast term; at most `reject` (-1e9
## here) when the candidate is impossible (the sea, ice, volcanic ground, a high range).
static func score(P: WorldPlanet.Planet, kind: int, px: float, py: float, pz: float, need: float = -1.0e18) -> float:
	if not _loaded:
		_load()
	WorldPlanet.surfAt(P, px, py, pz)
	if P.outH < 0.0:
		return -1.0e9
	var f: int = P.outF if P.outF >= 0 else P.outB
	var w: float = _w[kind][f]
	if w <= K_REJECT:
		return -1.0e9
	if (w + maxf(0.0, K_BONUS[kind])) * K_SCALE <= need:
		return -1.0e9   # even with the coast's best the candidate cannot beat the best so far: the eight ground reads are not made
	var n: int = seaDirs(P, px, py, pz, K_REACH[kind])
	if n > 0:
		w += K_BONUS[kind] if (n >= K_LOW and n <= K_HIGH) else K_PEN[kind]
	return w * K_SCALE


static func _fnv(id: String) -> int:
	var h: int = 0x811c9dc5
	for i in range(id.length()):
		h = SimRng.imul((h ^ id.unicode_at(i)) & SimRng.MASK, 0x01000193)
	return h


## The ragged border: a gen 2 slice's fine biomes (and the stored ones, by alias) blended where two biomes of the set meet. Runs of one biome are found on the circle; a column takes the biome of the
## nearer neighbouring run with a chance that falls from `max` next to the border to 0 at `width` columns, two keyed draws, one to each `cell` columns and one to each four cells, averaged, so the patches are not single columns and they cluster.
static func blend(P: WorldPlanet.Planet, S: WorldPlanet.Slice) -> void:
	var ctx: Dictionary = blendBegin(P, S)
	if not ctx.is_empty():
		blendStep(S, ctx, 1 << 40)


## The start of a stepped blend ({} when there is nothing to blend): the runs are visited in order from the first border, as blend always did, a few columns a blendStep.
static func blendBegin(P: WorldPlanet.Planet, S: WorldPlanet.Slice) -> Dictionary:
	if not _loaded:
		_load()
	var n: int = S.fine.size()
	if n == 0 or K_E_W <= 0 or K_E_MAX <= 0.0:
		return {}
	var fine: PackedByteArray = S.fine
	var s0: int = -1
	for i in range(n):
		if fine[i] != fine[(i + n - 1) % n]:
			s0 = i
			break
	if s0 < 0:
		return {}   # one biome all the way round
	var seed: int = (P.seed + K_E_SEED) & 0xFFFFFFFF
	return {"n": n, "s0": s0, "fine": fine, "out": fine.duplicate(),
		"x1": SimRng._fmix((seed ^ _fnv("ecotone")) & SimRng.MASK),   # SimRng.keyed(seed, key, n) is _fmix(x ^ imul(n, 0x9E3779B1)) with x = _fmix(seed ^ fnv(key)): the first half, once
		"x2": SimRng._fmix((seed ^ _fnv("ecotone.big")) & SimRng.MASK),
		"i": 0, "k": -1, "rl": 0, "f": 0, "prev": 0, "next": 0, "pOk": false, "nOk": false}


## Up to `units` more columns of the blend (a column of an active run is one unit, a run that is not active a sixteenth of its length); true when the slice's fine and stored biomes are the blended ones.
static func blendStep(S: WorldPlanet.Slice, ctx: Dictionary, units: int) -> bool:
	var n: int = ctx.n
	var s0: int = ctx.s0
	var fine: PackedByteArray = ctx.fine
	var out: PackedByteArray = ctx.out
	var x1: int = ctx.x1
	var x2: int = ctx.x2
	var left: int = units
	while int(ctx.i) < n and left > 0:
		var i: int = ctx.i
		if int(ctx.k) < 0:
			var a: int = (s0 + i) % n
			var f: int = fine[a]
			var rl: int = 1
			while i + rl < n and fine[(s0 + i + rl) % n] == f:
				rl += 1
			var prev: int = fine[(a + n - 1) % n]
			var next: int = fine[(s0 + i + rl) % n]
			var act: bool = false
			var pOk: bool = false
			var nOk: bool = false
			if f < _inset.size() and _inset[f] == 1:
				pOk = prev < _inset.size() and _inset[prev] == 1 and prev != f
				nOk = next < _inset.size() and _inset[next] == 1 and next != f
				act = pOk or nOk
			if not act:
				ctx.i = i + rl
				left -= maxi(1, rl / 16)
				continue
			ctx.rl = rl
			ctx.f = f
			ctx.prev = prev
			ctx.next = next
			ctx.pOk = pOk
			ctx.nOk = nOk
			ctx.k = 0
		var rl2: int = ctx.rl
		var pOk2: bool = ctx.pOk
		var nOk2: bool = ctx.nOk
		var prev2: int = ctx.prev
		var next2: int = ctx.next
		var k0: int = ctx.k
		var kend: int = mini(rl2, k0 + left)
		for k in range(k0, kend):
			var dl: int = k + 1
			var dr: int = rl2 - k
			var g: int = -1
			var d: int = 0
			if pOk2 and (not nOk2 or dl <= dr):
				g = prev2
				d = dl
			elif nOk2:
				g = next2
				d = dr
			if g < 0 or d > K_E_W:
				continue
			var p: float = K_E_MAX * (1.0 - float(d - 1) / float(K_E_W))
			var col: int = (s0 + i + k) % n
			var u: float = 0.5 * (float(SimRng._fmix(x1 ^ SimRng.imul((col / K_E_CELL) & SimRng.MASK, 0x9E3779B1))) + float(SimRng._fmix(x2 ^ SimRng.imul((col / (4 * K_E_CELL)) & SimRng.MASK, 0x9E3779B1)))) / 4294967296.0   # two scales, so the patches cluster
			if u < p:
				out[col] = g
		left -= kend - k0
		ctx.k = kend
		if kend >= rl2:
			ctx.i = i + rl2
			ctx.k = -1
	if int(ctx.i) < n:
		return false
	for c in range(n):
		if out[c] != fine[c]:
			S.biomes[c] = WorldClimate.aliasOf(int(out[c]))
	S.fine = out
	return true
