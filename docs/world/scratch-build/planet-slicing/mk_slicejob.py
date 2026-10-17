"""WorldPlanet time-sliced loading (World, scratch, parked): the places, the pick and the slice read as jobs a host steps a few work units at a time.
python mk_slicejob.py <root>      (root: an export of main's HEAD with planet window 1)"""
import sys
from mk_wbc_lib import rw, rep

R = sys.argv[1].rstrip('/') + '/'


def planet(s):
    # ---- evalCircle in pieces a job can take one sample at a time
    a = s.index("static func evalCircle(")
    b = s.index("static func meets(")
    s = s[:a] + '''static func _evalCounts(P: Planet, circ: Dictionary, standing: PackedByteArray) -> Array:
	var c: Dictionary = P.c
	var n: Array = circ.n
	var cities: int = 0
	var towns: int = 0
	for i in range(P.n):
		if standing.size() > 0 and standing[i] == 0:
			continue
		var d: float = P.R * asinf(n[0] * P.px[i] + n[1] * P.py[i] + n[2] * P.pz[i])
		var reach: float = (c.cityReach if P.kind[i] == KIND_CITY else c.townReach) * P.rad[i]
		if absf(d) < reach:
			if P.kind[i] == KIND_CITY:
				cities += 1
			else:
				towns += 1
	return [cities, towns]


## Sample k of cnt along the circle: its biome counted into seen.
static func _evalSample(P: Planet, circ: Dictionary, k: int, cnt: int, seen: Array) -> void:
	var u: Array = circ.u
	var v: Array = circ.v
	var ang: float = float(k) / float(cnt) * 2.0 * PI
	var co: float = SimDetMath.cos(ang)
	var si: float = SimDetMath.sin(ang)
	surfAt(P, u[0] * co + v[0] * si, u[1] * co + v[1] * si, u[2] * co + v[2] * si)
	seen[P.outB] += 1


static func _evalFinish(c: Dictionary, cities: int, towns: int, seen: Array, cnt: int) -> Dictionary:
	var kinds: int = 0
	for s in seen:
		if float(s) / float(cnt) >= c.biomeShare:
			kinds += 1
	var land: float = 1.0 - float(seen[BIO_OCEAN] + seen[BIO_SEA_ICE]) / float(cnt)
	var ice: float = float(seen[BIO_ICE_SHEET] + seen[BIO_SEA_ICE]) / float(cnt)
	return {"cities": cities, "towns": towns, "biomes": kinds, "land": land, "ice": ice, "seen": seen}


static func _evalSkipped(cities: int, towns: int) -> Dictionary:
	return {"cities": cities, "towns": towns, "biomes": 0, "land": 0.0, "ice": 0.0, "seen": [], "skipped": true}   # the counts already fail: no surface is read


## What the circle (normal n, frame u v) holds. standing: PackedByteArray of 1 for a place that has not fallen (empty: all stand). Returns a dictionary.
static func evalCircle(P: Planet, circ: Dictionary, standing: PackedByteArray, minCities: int = 0, minTowns: int = 0) -> Dictionary:
	var c: Dictionary = P.c
	var ct: Array = _evalCounts(P, circ, standing)
	if ct[0] < minCities or ct[1] < minTowns:
		return _evalSkipped(ct[0], ct[1])
	var seen := [0, 0, 0, 0, 0, 0, 0]
	var cnt: int = int(c.samples)
	for k in range(cnt):
		_evalSample(P, circ, k, cnt, seen)
	return _evalFinish(c, ct[0], ct[1], seen, cnt)


''' + s[b:]
    # ---- the Slice gains a flag
    s = rep(s, '''	var T: Array = []
	var seed: int = 0
''', '''	var T: Array = []
	var seed: int = 0
	var provisional: bool = false             # a job is still filling it in: the heights are the coarse read (every 8th column, the rest interpolated) until it is false
''')
    # ---- a place search by candidates
    a = s.index("static func _tryPlace(")
    b = s.index("## The places of a planet: first as picture A")
    keep = s[s.index("static func _addPlace("):b]   # _addPlace and _finishPeople stay as the stored-places patch made them
    s = s[:a] + '''## One candidate of a place search: a random point from the stream, kept in acc = [best point or null, its score] if it is the best so far. The search is a loop of these,
## so a job can take them a few at a time and give the same places.
static func _candidate(P: Planet, r: SimRng, radius: float, polar: bool, acc: Array) -> void:
	var c: Dictionary = P.c
	var p: Array = _randUnit(r)
	var h: float = ground(P, p[0], p[1], p[2])
	if h < c.placeHMin or h > c.placeHMax or (polar and absf(p[1]) > c.placeYMax):
		return
	var dmin: float = 1.0e9
	for i in range(P.n):
		var g: float = _arc(P, p, P.px[i], P.py[i], P.pz[i]) - P.rad[i] - radius
		if g < dmin:
			dmin = g
	if dmin < c.placeGap:
		return
	var sc: float = dmin * c.scoreGap - absf(h - c.scoreH0) * c.scoreHW + r.next()
	if sc > acc[1]:
		acc[1] = sc
		acc[0] = p


static func _tryPlace(P: Planet, r: SimRng, kind: int, radius: float, tries: int, polar: bool) -> bool:
	var acc: Array = [null, -1.0e9]
	for k in range(tries):
		_candidate(P, r, radius, polar, acc)
	if acc[0] != null:
		_addPlace(P, kind, acc[0], radius)
		return true
	return false


## After the first pass: the places that fell inside a polar cap are dropped; returns how many of each kind to place again.
static func _filterPolar(P: Planet) -> Array:
	var c: Dictionary = P.c
	var kept := PackedInt32Array()
	var dropped := [0, 0]
	for i in range(P.n):
		if absf(P.py[i]) > c.placeYMax:
			dropped[P.kind[i]] += 1
		else:
			kept.append(i)
	var kind2 := PackedByteArray()
	var px2 := PackedFloat64Array()
	var py2 := PackedFloat64Array()
	var pz2 := PackedFloat64Array()
	var rad2 := PackedFloat64Array()
	for i in kept:
		kind2.append(P.kind[i])
		px2.append(P.px[i])
		py2.append(P.py[i])
		pz2.append(P.pz[i])
		rad2.append(P.rad[i])
	P.kind = kind2
	P.px = px2
	P.py = py2
	P.pz = pz2
	P.rad = rad2
	P.n = kept.size()
	return dropped


''' + keep + s[b:]
    # ---- _placeAll uses the helpers
    a = s.index("static func _placeAll(P: Planet) -> void:")
    b = s.index("## The people of a place at full, by weight")
    s = s[:a] + '''static func _placeAll(P: Planet) -> void:
	var c: Dictionary = P.c
	var r := SimRng.new(P.seed * int(c.placeSeedMul) + 1)
	for k in range(int(c.cities)):
		_tryPlace(P, r, KIND_CITY, c.cityRadius, int(c.cityTries), false)
	for k in range(int(c.towns)):
		_tryPlace(P, r, KIND_TOWN, c.townRadius, int(c.townTries), false)
	var dropped: Array = _filterPolar(P)
	var r2 := SimRng.new(P.seed * int(c.placeSeedMul) + 2)
	for k in range(dropped[KIND_CITY]):
		_tryPlace(P, r2, KIND_CITY, c.cityRadius, int(c.replaceTries), true)
	for k in range(dropped[KIND_TOWN]):
		_tryPlace(P, r2, KIND_TOWN, c.townRadius, int(c.replaceTries), true)
	_finishPeople(P)


''' + s[b:]
    # ---- readSlice: the column and the held places are functions the job shares
    a = s.index("	var u: Array = circ.u\n	var v: Array = circ.v\n	for i in range(nc):\n		var ang: float = float(i - TOUCH_COL)")
    b = s.index("	return S\n", a)
    s = s[:a] + '''	var u: Array = circ.u
	var v: Array = circ.v
	for i in range(nc):
		_columnInto(P, c, u, v, i, S, false, 0.0, 0)
	_heldInto(P, S, circ, standing)
''' + s[b:]
    a = s.index("## Reads the circle as columns.")
    s = s[:a] + '''## One column of a slice: the point on the circle, the surface there (or the base read already made for it, bh and bb), then the fine relief (ordinary land, and a quarter of
## it on an ice sheet). The whole read and the job both call this, so they give the same bits.
static func _columnInto(P: Planet, c: Dictionary, u: Array, v: Array, i: int, S: Slice, hasBase: bool, bh: float, bb: int) -> void:
	var ang: float = float(i - TOUCH_COL) * SimConst.COL / P.R
	var co: float = SimDetMath.cos(ang)
	var si: float = SimDetMath.sin(ang)
	var qx: float = u[0] * co + v[0] * si
	var qy: float = u[1] * co + v[1] * si
	var qz: float = u[2] * co + v[2] * si
	var h: float
	var b: int
	if hasBase:
		h = bh
		b = bb
	else:
		surfAt(P, qx, qy, qz)
		h = P.outH
		b = P.outB
	if b >= BIO_PLAINS and b <= BIO_MOUNTAINS:
		h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp
	elif b == BIO_ICE_SHEET and h > 100.0:
		h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp * c.detailSheet
	S.heights[i] = h
	S.biomes[i] = b


## The places a circle passes, with their nearest column (our own atan2) and lateral offset (our own asin).
static func _heldInto(P: Planet, S: Slice, circ: Dictionary, standing: PackedByteArray) -> void:
	var c: Dictionary = P.c
	var nc: int = SimConst.NC
	var u: Array = circ.u
	var v: Array = circ.v
	var n: Array = circ.n
	for i in range(P.n):
		var lat: float = P.R * asinf(n[0] * P.px[i] + n[1] * P.py[i] + n[2] * P.pz[i])
		var reach: float = (c.cityReach if P.kind[i] == KIND_CITY else c.townReach) * P.rad[i]
		if absf(lat) >= reach:
			continue
		var along: float = atan2f(P.px[i] * v[0] + P.py[i] * v[1] + P.pz[i] * v[2], P.px[i] * u[0] + P.py[i] * u[1] + P.pz[i] * u[2])
		var col: int = TOUCH_COL + int(floor(along * P.R / SimConst.COL + 0.5))
		col = ((col % nc) + nc) % nc
		var half: float = sqrt(maxf(0.0, P.rad[i] * P.rad[i] - lat * lat))
		S.held.append({"id": i, "kind": int(P.kind[i]), "col": col, "d": lat, "half": half, "r": P.rad[i],
			"standing": standing.size() == 0 or standing[i] != 0})


''' + s[a:]
    # ---- sliceFor: the memo key and store are functions the job shares
    a = s.index("static func sliceFor(")
    b = s.index("## A hash of what the read produced")
    s = s[:a] + '''static func sliceKey(seed: int, touch: int, standing: PackedByteArray, relaxed: bool) -> String:
	return "%d/%d/%s/%d/%s" % [seed, touch, str(standing.hex_encode()), 1 if relaxed else 0, dataHash()]


static func _storeSlice(key: String, S: Slice) -> void:
	if _slices.size() > 4:
		_slices.clear()
	_slices[key] = S


static func sliceFor(seed: int, touch: int, standing: PackedByteArray = PackedByteArray(), relaxed: bool = false) -> Slice:
	var key: String = sliceKey(seed, touch, standing, relaxed)
	if _slices.has(key):
		return _slices[key]
	var P: Planet = make(seed)
	var r: Dictionary = pick(P, touch, standing, relaxed)
	if not r.ok:
		return null
	var S: Slice = readSlice(P, r.circle, r.T, standing)
	_storeSlice(key, S)
	return S


''' + s[b:]
    s = s.rstrip('\n') + '\n' + JOBS
    return s


JOBS = '''

## ===================================================================== time-sliced loading (the host paces it; the module owns no clock)
## The planet, the pick and the slice read cost 0.7 to 1.4 s in the browser on a fast PC and 7 to 14 s on a slow phone (docs/perf/audit-2026-10-16.md), which would freeze
## the page. Each is a job that a host steps a few work units at a time until its frame budget (about 4 ms) is used. A work unit is about 0.12 ms on this PC (native): a
## column of the slice, a place candidate, a picker candidate's counts or one of its 96 surface samples is 1. **A job's result never depends on how it is stepped** (the same bits as the whole call,
## tested for chunk sizes of 1 to 1,000): the host's clock only decides how many units go in a frame, and the sim starts only when `done` is true. A skipped intro must not
## skip the load: `finishNow()` does the rest in one call (a headless run, a replay, a skip).
const COARSE_STRIDE: int = 8


## The columns nearest the touch-down first: T, then T+1, T-1, T+2, T-2 ... each column once.
static func columnOrder(nc: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.append(TOUCH_COL)
	for d in range(1, nc / 2 + 1):
		var a: int = (TOUCH_COL + d) % nc
		var b: int = ((TOUCH_COL - d) % nc + nc) % nc
		out.append(a)
		if b != a:
			out.append(b)
	return out


class PlaceJob extends RefCounted:
	var P: WorldPlanet.Planet
	var done: bool = false
	var phase: int = 0            # 0 the first pass, 1 the places that fell in a cap placed again
	var r: SimRng
	var spec: Array = []          # [kind, count, radius, tries, polar]
	var si: int = 0
	var k: int = 0
	var cand: int = 0
	var acc: Array = [null, -1.0e9]
	var used: int = 0
	var total: int = 0            # the first pass's candidates: the progress denominator

	func _init(seed: int) -> void:
		if WorldPlanet._planets.has(seed) or not WorldPlanet.storyFor(seed).is_empty():
			P = WorldPlanet.make(seed)   # memoised, or a story planet: its places are stored, there is nothing to place
			done = true
			return
		var c: Dictionary = WorldPlanet.cfg()
		P = WorldPlanet.Planet.new()
		P.seed = seed
		P.c = c
		P.L = float(SimConst.NC) * SimConst.COL
		P.R = P.L / (2.0 * PI)
		r = SimRng.new(seed * int(c.placeSeedMul) + 1)
		spec = [[WorldPlanet.KIND_CITY, int(c.cities), c.cityRadius, int(c.cityTries), false], [WorldPlanet.KIND_TOWN, int(c.towns), c.townRadius, int(c.townTries), false]]
		total = int(c.cities) * int(c.cityTries) + int(c.towns) * int(c.townTries) + 4 * int(c.replaceTries)

	func step(units: int) -> int:
		var left: int = units
		while left > 0 and not done:
			if si >= spec.size():
				_endPhase()
				continue
			var sp: Array = spec[si]
			if k >= sp[1]:
				si += 1
				k = 0
				cand = 0
				continue
			WorldPlanet._candidate(P, r, sp[2], sp[4], acc)
			cand += 1
			left -= 1
			used += 1
			if cand >= sp[3]:
				if acc[0] != null:
					WorldPlanet._addPlace(P, sp[0], acc[0], sp[2])
				acc = [null, -1.0e9]
				cand = 0
				k += 1
		return units - left

	func _endPhase() -> void:
		if phase == 0:
			var dropped: Array = WorldPlanet._filterPolar(P)
			var c: Dictionary = P.c
			r = SimRng.new(P.seed * int(c.placeSeedMul) + 2)
			spec = [[WorldPlanet.KIND_CITY, dropped[0], c.cityRadius, int(c.replaceTries), true], [WorldPlanet.KIND_TOWN, dropped[1], c.townRadius, int(c.replaceTries), true]]
			si = 0
			k = 0
			cand = 0
			phase = 1
		else:
			WorldPlanet._finishPeople(P)
			WorldPlanet._register(P)
			done = true

	func progress() -> float:
		return 1.0 if done else minf(0.99, float(used) / float(maxi(1, total)))


class PickJob extends RefCounted:
	var P: WorldPlanet.Planet
	var touch: int
	var standing: PackedByteArray
	var relaxed: bool
	var either: bool
	var T: Array = []
	var cand: Array = []
	var idx: int = 0              # the next candidate
	var tried: int = 0
	var rel: Dictionary = {}
	var done: bool = false
	var result: Dictionary = {}
	var cur: Dictionary = {}      # the candidate being sampled
	var curCounts: Array = []
	var curSeen: Array = []
	var curK: int = 0
	var cnt: int = 0
	var needC: int = 0
	var needT: int = 0

	## either: the offers' rule (strict if any candidate meets it, else the first that meets the relaxed one); else the plain pick with `relaxed`.
	func _init(planet: WorldPlanet.Planet, touch_: int, standing_: PackedByteArray, relaxed_: bool, either_: bool) -> void:
		P = planet
		touch = touch_
		standing = standing_
		relaxed = relaxed_
		either = either_
		T = WorldPlanet.touchPoint(P, touch)
		cand = WorldPlanet.candidates(P, T, touch, standing)
		var c: Dictionary = P.c
		cnt = int(c.samples)
		needC = int(c.relaxCities) if relaxed else int(c.minCities)
		needT = int(c.relaxTowns) if relaxed else int(c.minTowns)
		if either:
			needC = mini(int(c.relaxCities), int(c.minCities))
			needT = mini(int(c.relaxTowns), int(c.minTowns))

	## One unit is one candidate's counts or one of its surface samples (96 of them when the counts could pass): the same work as evalCircle, a piece at a time.
	func step(units: int) -> int:
		var left: int = units
		while left > 0 and not done:
			if cur.is_empty():
				if idx >= cand.size():
					_finish()
					continue
				cur = cand[idx]
				idx += 1
				tried += 1
				curCounts = WorldPlanet._evalCounts(P, cur, standing)
				left -= 1
				if curCounts[0] < needC or curCounts[1] < needT:
					_judge(WorldPlanet._evalSkipped(curCounts[0], curCounts[1]))
				else:
					curSeen = [0, 0, 0, 0, 0, 0, 0]
					curK = 0
				continue
			WorldPlanet._evalSample(P, cur, curK, cnt, curSeen)
			curK += 1
			left -= 1
			if curK >= cnt:
				_judge(WorldPlanet._evalFinish(P.c, curCounts[0], curCounts[1], curSeen, cnt))
		return units - maxi(0, left)

	func _judge(e: Dictionary) -> void:
		var c: Dictionary = P.c
		var circ: Dictionary = cur
		cur = {}
		if either:
			if WorldPlanet.meets(c, e, false):
				result = {"ok": true, "relaxed": false, "circle": circ, "tried": tried, "eval": e, "T": T, "index": tried - 1}
				done = true
			elif rel.is_empty() and WorldPlanet.meets(c, e, true):
				rel = {"ok": true, "relaxed": true, "circle": circ, "tried": tried, "eval": e, "T": T, "index": tried - 1}
		elif WorldPlanet.meets(c, e, relaxed):
			result = {"ok": true, "circle": circ, "tried": tried, "eval": e, "T": T, "index": tried - 1}
			done = true

	func _finish() -> void:
		if either and not rel.is_empty():
			result = rel
		elif either:
			result = {"ok": false, "relaxed": false, "circle": {}, "tried": tried, "eval": {}, "T": T, "index": -1}
		else:
			result = {"ok": false, "circle": {}, "tried": tried, "eval": {}, "T": T, "index": -1}
		done = true

	func progress() -> float:
		return 1.0 if done else minf(0.99, float(idx) / float(maxi(1, cand.size())))


class SliceJob extends RefCounted:
	var P: WorldPlanet.Planet
	var circ: Dictionary
	var standing: PackedByteArray
	var S: WorldPlanet.Slice
	var key: String = ""
	var done: bool = false
	var phase: int = 0            # 0 the coarse read, 1 the full read filling in
	var pos: int = 0
	var order := PackedInt32Array()
	var coarse := PackedInt32Array()
	var baseH := PackedFloat64Array()
	var haveBase := PackedByteArray()
	var nc: int = 0
	var stride: int = 1

	func _init(planet: WorldPlanet.Planet, circ_: Dictionary, T: Array, standing_: PackedByteArray, key_: String = "") -> void:
		P = planet
		circ = circ_
		standing = standing_
		key = key_
		nc = SimConst.NC
		stride = WorldPlanet.COARSE_STRIDE if nc % WorldPlanet.COARSE_STRIDE == 0 else 1
		S = WorldPlanet.Slice.new()
		S.seed = P.seed
		S.circ = circ
		S.T = T
		S.provisional = true
		S.heights.resize(nc)
		S.biomes.resize(nc)
		baseH.resize(nc)
		haveBase.resize(nc)
		order = WorldPlanet.columnOrder(nc)
		for i in order:
			if i % stride == 0:
				coarse.append(i)

	func step(units: int) -> int:
		var left: int = units
		var u: Array = circ.u
		var v: Array = circ.v
		var c: Dictionary = P.c
		while left > 0 and not done:
			if phase == 0:
				if pos >= coarse.size():
					_interpolate()
					phase = 1
					pos = 0
					left -= 8
					continue
				var i: int = coarse[pos]
				pos += 1
				left -= 1
				var ang: float = float(i - WorldPlanet.TOUCH_COL) * SimConst.COL / P.R
				var co: float = SimDetMath.cos(ang)
				var si: float = SimDetMath.sin(ang)
				WorldPlanet.surfAt(P, u[0] * co + v[0] * si, u[1] * co + v[1] * si, u[2] * co + v[2] * si)
				baseH[i] = P.outH
				haveBase[i] = 1
				S.heights[i] = P.outH
				S.biomes[i] = P.outB
			else:
				if pos >= order.size():
					_finish()
					continue
				var j: int = order[pos]
				pos += 1
				left -= 1
				if haveBase[j] == 1:
					WorldPlanet._columnInto(P, c, u, v, j, S, true, baseH[j], S.biomes[j])
				else:
					WorldPlanet._columnInto(P, c, u, v, j, S, false, 0.0, 0)
		return units - maxi(0, left)

	## The columns between the coarse ones: heights on a straight line between their neighbours, the biome of the nearer. Provisional: every one is replaced in phase 1.
	func _interpolate() -> void:
		for i in range(nc):
			if haveBase[i] == 1:
				continue
			var a: int = (i / stride) * stride
			var b: int = (a + stride) % nc
			var t: float = float(i - a) / float(stride)
			S.heights[i] = baseH[a] + (baseH[b] - baseH[a]) * t
			S.biomes[i] = S.biomes[a] if t < 0.5 else S.biomes[b]

	func _finish() -> void:
		WorldPlanet._heldInto(P, S, circ, standing)
		S.provisional = false
		if key != "":
			WorldPlanet._storeSlice(key, S)
		done = true

	func progress() -> float:
		if done:
			return 1.0
		if phase == 0:
			return 0.1 * float(pos) / float(maxi(1, coarse.size()))
		return 0.1 + 0.9 * float(pos) / float(maxi(1, order.size()))


## The whole load for a touch-down: the planet's places, the pick, the slice. `slice` is the provisional slice from the pick onward (coarse, then filling in), the final one
## when `done`; `ok` is false when no circle met the minimum.
class LoadJob extends RefCounted:
	var seed: int
	var touch: int
	var standing: PackedByteArray
	var relaxed: bool
	var stage: int = 0            # 0 the planet, 1 the pick, 2 the slice, 3 done
	var placeJob: WorldPlanet.PlaceJob
	var pickJob: WorldPlanet.PickJob
	var sliceJob: WorldPlanet.SliceJob
	var slice: WorldPlanet.Slice = null
	var key: String = ""
	var ok: bool = true
	var done: bool = false

	func _init(seed_: int, touch_: int, standing_: PackedByteArray, relaxed_: bool) -> void:
		seed = seed_
		touch = touch_
		standing = standing_
		relaxed = relaxed_
		key = WorldPlanet.sliceKey(seed, touch, standing, relaxed)
		if WorldPlanet._slices.has(key):
			slice = WorldPlanet._slices[key]
			stage = 3
			done = true
			return
		placeJob = WorldPlanet.PlaceJob.new(seed)

	func step(units: int) -> int:
		var left: int = units
		while left > 0 and not done:
			if stage == 0:
				left -= placeJob.step(left)
				if placeJob.done:
					pickJob = WorldPlanet.PickJob.new(placeJob.P, touch, standing, relaxed, false)
					stage = 1
			elif stage == 1:
				left -= pickJob.step(left)
				if pickJob.done:
					if not pickJob.result.ok:
						ok = false
						stage = 3
						done = true
					else:
						sliceJob = WorldPlanet.SliceJob.new(placeJob.P, pickJob.result.circle, pickJob.result.T, standing, key)
						slice = sliceJob.S
						stage = 2
			elif stage == 2:
				left -= sliceJob.step(left)
				if sliceJob.done:
					stage = 3
					done = true
		return units - maxi(0, left)

	## Does what is left in one call: for a skipped intro, a replay, a headless run. The result is the same bits.
	func finishNow() -> void:
		while not done:
			step(1000000)

	func progress() -> float:
		if done:
			return 1.0
		if stage == 0:
			return 0.25 * placeJob.progress()
		if stage == 1:
			return 0.25 + 0.05 * pickJob.progress()
		return 0.3 + 0.7 * sliceJob.progress()

	func stageName() -> String:
		return ["the planet", "the slice's circle", "the ground", "ready"][stage]


static func beginLoad(seed: int, touch: int, standing: PackedByteArray = PackedByteArray(), relaxed: bool = false) -> LoadJob:
	return LoadJob.new(seed, touch, standing, relaxed)
'''

rw(R, 'sim/world/planet.gd', planet)
print('slice jobs applied')
