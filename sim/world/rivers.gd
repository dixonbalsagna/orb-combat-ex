class_name WorldRivers
extends RefCounted
## Planet generation 2's rivers (docs/world/rivers.md, window 14; data/biomes/rivers.json, off by default). Cheap and cosmetic like the water: a river is a narrow, shallow, flat-surfaced channel where a fight ring
## crosses a line of drainage, never deep enough to hide in or to sink a body (it is waded), planted exactly as a window 5 lake is (an entry of S.planetRing["lakes"]: the water module keeps it level, the calm
## turn carries it, trees do not grow in it, a hole dug beside it fills from it).
##
## The flow field is routed on the climate grid the planet already has (192 by 96 cells, about 800 units a cell, equal area, heights from the ground itself): the depressions are filled from the sea inward
## (a priority flood: every land cell drains), each cell sends its runoff to the cell it was flooded from, and the runoff is added up downstream. Runoff is the carried moisture over a dry line on land that is not
## frozen; a cell whose flow passes `flow.river` is a river cell. A ring crossing a river's line (a segment from a river cell's centre to its receiver's) crosses it at a point found by geometry; the crossing is
## snapped to the lowest ground within `reach` columns of it on the ring (so the channel lies in the ring's own valley), widened by its flow, cut into the ground with a taper, and given a flat surface a little
## under the lower bank. Game Design's row 13 holds: of the crossings at most one is kept in any `gapUnits` (3,000), the strongest, so a river that runs along the ring (a comb of crossings) is one span.
## Pure functions of the planet, the ring and the data: no draw. Gen 2 only (the grid is gen 2's).

const PATH := "res://data/biomes/rivers.json"
const SCHEMA := "biomes.rivers/1"
const FLOW_COST: int = 5000   # a planet job's budget units the flow field costs (about 100 ms: a unit is about 20 microseconds)

static var _d: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""
static var K_ON: bool = false
static var K_DRY: float = 0.25
static var K_GAIN: float = 1.0
static var K_FROZEN: float = 0.16
static var K_RIVER: float = 12.0
static var K_REF: float = 60.0
static var K_MIN_COLS: int = 5
static var K_MAX_COLS: int = 24
static var K_W0: float = 4.0
static var K_W1: float = 3.0
static var K_D0: float = 20.0
static var K_D1: float = 10.0
static var K_DMAX: float = 70.0
static var K_FREE: float = 6.0
static var K_REACH: int = 14
static var K_BANK: int = 3
static var K_MARGIN: int = 10
static var K_FLOOR: float = 5.0
static var K_GAP: float = 3000.0
static var K_MAXN: int = 12
static var _refuse := PackedByteArray()


static func data() -> Dictionary:
	if not _loaded:
		_load()
	return _d


static func dataErrors() -> Array:
	if not _loaded:
		_load()
	return _errors


## The data's hash; the planet's data hash carries it only while the rivers are on.
static func dataHash() -> String:
	if not _loaded:
		_load()
	return _hash


## Are the rivers on (rivers.json enabled)?
static func enabled() -> bool:
	if not _loaded:
		_load()
	return K_ON


## For tools and checks: the switch for this process (the file is not touched).
static func setOn(on: bool) -> void:
	if not _loaded:
		_load()
	K_ON = on and _errors.is_empty()


static func _load() -> void:
	_loaded = true
	_errors = []
	_d = {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_errors.append("rivers.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA:
		_errors.append("rivers.json: not a %s object" % SCHEMA)
		return
	for k in ["enabled", "rain", "flow", "span", "spacing", "refuse"]:
		if not j.has(k):
			_errors.append("rivers.json: %s is missing" % k)
	if not _errors.is_empty():
		return
	var sp: Dictionary = j.span
	if int(sp.minCols) < 1 or int(sp.maxCols) < int(sp.minCols) or float(sp.maxDepth) <= 0.0 or float(sp.maxDepth) >= WorldWater.HIDE_MIN_DEPTH or float(j.flow.river) <= 0.0 or float(j.flow.ref) <= 0.0:
		_errors.append("rivers.json: span.minCols within maxCols, maxDepth above 0 and under the depth that hides a fighter, flow.river and flow.ref above 0")
	var fine: Array = WorldClimate.data().get("fine", [])
	var ref := PackedByteArray()
	ref.resize(maxi(fine.size(), 1))
	for nm in j.refuse:
		var found: bool = false
		for i in range(fine.size()):
			if fine[i].name == nm:
				ref[i] = 1
				found = true
		if not found:
			_errors.append("rivers.json: refuse names '%s', which is not a fine biome" % nm)
	if not _errors.is_empty():
		return
	_d = j
	_hash = str(text.hash())
	_refuse = ref
	K_ON = bool(j.enabled)
	K_DRY = float(j.rain.dry)
	K_GAIN = float(j.rain.gain)
	K_FROZEN = float(j.rain.frozenT)
	K_RIVER = float(j.flow.river)
	K_REF = float(j.flow.ref)
	K_MIN_COLS = int(sp.minCols)
	K_MAX_COLS = int(sp.maxCols)
	K_W0 = float(sp.width0)
	K_W1 = float(sp.width1)
	K_D0 = float(sp.depth0)
	K_D1 = float(sp.depth1)
	K_DMAX = float(sp.maxDepth)
	K_FREE = float(sp.freeboard)
	K_REACH = int(sp.reach)
	K_BANK = int(sp.bank)
	K_MARGIN = int(sp.margin)
	K_FLOOR = float(sp.floor)
	K_GAP = float(j.spacing.gapUnits)
	K_MAXN = int(j.spacing.maxPerRing)


# ===================================================================== the flow field

## The drainage of a planet's climate grid: for each cell the cell its runoff goes to (-1: the sea, or no way down), the flow it carries (runoff of all the cells that drain through it) and the order the cells
## were reached in the flood (a cell comes after its receiver). Made once a planet (`flowOf`).
class Flow extends RefCounted:
	var w: int = 0
	var h: int = 0
	var recv := PackedInt32Array()
	var flow := PackedFloat32Array()
	var order := PackedInt32Array()
	var px := PackedFloat64Array()
	var py := PackedFloat64Array()
	var pz := PackedFloat64Array()
	var rivers: int = 0
	var landCells: int = 0

	func _init(G: WorldClimate.Grid) -> void:
		w = G.w
		h = G.h
		var n: int = w * h
		recv.resize(n)
		recv.fill(-1)
		flow.resize(n)
		flow.fill(0.0)
		px.resize(n)
		py.resize(n)
		pz.resize(n)
		var d: Dictionary = WorldClimate.data()
		var mp: Dictionary = d.moist
		var tp: Dictionary = d.temp
		var cs := PackedFloat64Array()
		var sn := PackedFloat64Array()
		cs.resize(w)
		sn.resize(w)
		for k in range(w):
			var th: float = SimMathx.TAU * (float(k) + 0.5) / float(w)
			cs[k] = SimDetMath.cos(th)
			sn[k] = SimDetMath.sin(th)
		for r in range(h):
			var y: float = -1.0 + (float(r) + 0.5) * 2.0 / float(h)
			var c: float = sqrt(maxf(0.0, 1.0 - y * y))
			var band: float = float(mp.wBand) * WorldClimate.bandWet(y) + float(mp.bias)
			var tEq: float = float(tp.eq) * SimDetMath.pow(c, float(tp.pow))
			for k in range(w):
				var i: int = r * w + k
				px[i] = c * cs[k]
				py[i] = y
				pz[i] = c * sn[k]
				var ht: float = G.ht[i]
				if ht < 0.0:
					continue
				landCells += 1
				var T: float = tEq - float(tp.lapse) * ht / float(tp.hScale)
				if T < WorldRivers.K_FROZEN:
					continue
				var M: float = clampf(band + float(mp.wAdv) * G.adv[i], 0.0, 1.0)
				flow[i] = maxf(0.0, M - WorldRivers.K_DRY) * WorldRivers.K_GAIN
		# the priority flood from the sea inward: the lowest unvisited cell next (ties to the lower index), each neighbour reached takes it as its receiver
		var seen := PackedByteArray()
		seen.resize(n)
		var heapP := PackedFloat64Array()
		var heapI := PackedInt32Array()
		for i in range(n):
			if G.ht[i] < 0.0:
				seen[i] = 1
				_push(heapP, heapI, G.ht[i], i)
		var fill := PackedFloat64Array()
		fill.resize(n)
		for i in range(n):
			fill[i] = G.ht[i]
		var out := PackedInt32Array()
		while heapI.size() > 0:
			var cur: int = heapI[0]
			_pop(heapP, heapI)
			out.append(cur)
			var r0: int = cur / w
			var k0: int = cur - r0 * w
			for dr in range(-1, 2):
				var rr: int = r0 + dr
				if rr < 0 or rr >= h:
					continue
				for dk in range(-1, 2):
					if dr == 0 and dk == 0:
						continue
					var nb: int = rr * w + posmod(k0 + dk, w)
					if seen[nb] != 0:
						continue
					seen[nb] = 1
					recv[nb] = cur
					fill[nb] = maxf(G.ht[nb], fill[cur])
					_push(heapP, heapI, fill[nb], nb)
		order = out
		# a cell the flood did not raise (not in a filled pit) drains down its steepest way: the lowest neighbour by slope over the cell's own arc (a lat-lon cell is wide at the equator and narrow toward the
		# poles), so the rivers follow the land and not the flood's front. A strictly lower filled height is acyclic, and the flood's pop order (nondecreasing in filled height) still has every receiver first.
		var dlon: float = SimMathx.TAU / float(w)
		for i in range(n):
			if G.ht[i] < 0.0 or fill[i] > G.ht[i] + 1.0e-9:
				continue
			var r1: int = i / w
			var k1: int = i - r1 * w
			var cl: float = sqrt(maxf(1.0e-9, 1.0 - py[i] * py[i]))
			var bs: float = 0.0
			var bn: int = -1
			for dr in range(-1, 2):
				var rr: int = r1 + dr
				if rr < 0 or rr >= h:
					continue
				for dk in range(-1, 2):
					if dr == 0 and dk == 0:
						continue
					var nb: int = rr * w + posmod(k1 + dk, w)
					if fill[nb] >= fill[i]:
						continue
					var ax: float = dlon * cl * float(dk)
					var ay: float = (2.0 / float(h)) / cl * float(dr)
					var sl: float = (fill[i] - fill[nb]) / sqrt(ax * ax + ay * ay)
					if sl > bs or (sl == bs and bn >= 0 and nb < bn):
						bs = sl
						bn = nb
			if bn >= 0:
				recv[i] = bn
		# runoff added up downstream: a cell is reached after its receiver, so the reverse order visits every cell before its receiver
		for q in range(out.size() - 1, -1, -1):
			var i2: int = out[q]
			var rc: int = recv[i2]
			if rc >= 0 and G.ht[i2] >= 0.0:
				flow[rc] += flow[i2]
		for i in range(n):
			if G.ht[i] >= 0.0 and flow[i] >= WorldRivers.K_RIVER:
				rivers += 1

	static func _less(pa: float, ia: int, pb: float, ib: int) -> bool:
		return pa < pb or (pa == pb and ia < ib)

	static func _push(hp: PackedFloat64Array, hi: PackedInt32Array, p: float, i: int) -> void:
		hp.append(p)
		hi.append(i)
		var k: int = hi.size() - 1
		while k > 0:
			var up: int = (k - 1) / 2
			if _less(hp[k], hi[k], hp[up], hi[up]):
				var tp: float = hp[k]
				hp[k] = hp[up]
				hp[up] = tp
				var ti: int = hi[k]
				hi[k] = hi[up]
				hi[up] = ti
				k = up
			else:
				break

	static func _pop(hp: PackedFloat64Array, hi: PackedInt32Array) -> void:
		var last: int = hi.size() - 1
		hp[0] = hp[last]
		hi[0] = hi[last]
		hp.resize(last)
		hi.resize(last)
		var k: int = 0
		while true:
			var l: int = 2 * k + 1
			if l >= last:
				break
			var m: int = l
			if l + 1 < last and _less(hp[l + 1], hi[l + 1], hp[l], hi[l]):
				m = l + 1
			if _less(hp[m], hi[m], hp[k], hi[k]):
				var tp: float = hp[k]
				hp[k] = hp[m]
				hp[m] = tp
				var ti: int = hi[k]
				hi[k] = hi[m]
				hi[m] = ti
				k = m
			else:
				break


## The planet's flow field, made when first asked (gen 2 only: the grid is gen 2's; null for a gen 1 planet).
static func flowOf(P: WorldPlanet.Planet) -> Flow:
	if not _loaded:
		_load()
	if P.gen < 2:
		return null
	if P.flow == null:
		P.flow = Flow.new(WorldClimate.gridOf(P))
	return P.flow


# ===================================================================== the ring's crossings

## The places a ring crosses a river's line: [[column (a float, the ring's own columns), flow]], by geometry (the segment from a river cell's centre to its receiver's against the ring's circle).
static func crossings(P: WorldPlanet.Planet, spec: Dictionary, F: Flow) -> Array:
	var cols: int = int(spec.cols)
	var ring: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
	var c: Array = ring.c
	var ct: float = ring.ct
	var u: Array = ring.u
	var v: Array = ring.v
	var step: float = SimConst.COL / (P.R * float(ring.st))
	var mid: int = cols / 2
	var out: Array = []
	var G: WorldClimate.Grid = P.grid
	var f := PackedFloat64Array()
	f.resize(F.w * F.h)
	for i in range(f.size()):
		f[i] = c[0] * F.px[i] + c[1] * F.py[i] + c[2] * F.pz[i] - ct
	for i in range(f.size()):
		var rc: int = F.recv[i]
		if rc < 0 or G.ht[i] < 0.0 or F.flow[i] < K_RIVER:
			continue
		var fa: float = f[i]
		var fb: float = f[rc]
		if (fa > 0.0) == (fb > 0.0) or fa == fb:
			continue
		var t: float = fa / (fa - fb)
		var qx: float = F.px[i] + t * (F.px[rc] - F.px[i])
		var qy: float = F.py[i] + t * (F.py[rc] - F.py[i])
		var qz: float = F.pz[i] + t * (F.pz[rc] - F.pz[i])
		var ql: float = sqrt(qx * qx + qy * qy + qz * qz)
		qx /= ql
		qy /= ql
		qz /= ql
		var along: float = WorldPlanet.atan2f(qx * v[0] + qy * v[1] + qz * v[2], qx * u[0] + qy * u[1] + qz * u[2])
		out.append([float(mid) + along / step, F.flow[i]])
	return out


## A ring's rivers as lake entries [first column, last column, level, width, flow] (the water module and the turn treat them as lakes), in column order, from the ring's ground (`base`: after the platforms),
## the settlements' chords, the fine and stored biomes of its columns and the lakes already planned. The ground is not changed here (`carve` does it, for the entries kept).
static func plan(P: WorldPlanet.Planet, spec: Dictionary, base: PackedFloat32Array, chords: Array, fine: PackedByteArray, stored: PackedByteArray, lakes: Array) -> Array:
	if not _loaded:
		_load()
	var F: Flow = flowOf(P)
	if F == null:
		return []
	var n: int = base.size()
	var cand: Array = []
	for cr in crossings(P, spec, F):
		var c0: int = posmod(int(round(float(cr[0]))), n)
		var m: int = c0
		var bm: float = 1.0e18
		for off in range(-K_REACH, K_REACH + 1):
			var cc: int = posmod(c0 + off, n)
			if base[cc] < bm:
				bm = base[cc]
				m = cc
		if bm < K_FLOOR:
			continue
		var fl: float = float(cr[1])
		var W: int = clampi(int(round(K_W0 + K_W1 * sqrt(fl / K_REF))), K_MIN_COLS, K_MAX_COLS)
		var first: int = posmod(m - W / 2, n)
		var bad: bool = false
		for x in range(W):
			var cx: int = (first + x) % n
			if stored[cx] >= 7:
				bad = true
				break
		if bad:
			continue
		var fi: int = fine[m] if m < fine.size() else 0
		if fi < _refuse.size() and _refuse[fi] == 1:
			continue
		for ch in chords:
			if WorldLakes._overlap(first - K_MARGIN, first + W - 1 + K_MARGIN, int(ch[2]), int(ch[3]), n):
				bad = true
				break
		if bad:
			continue
		for lk in lakes:
			if WorldLakes._overlap(first, first + W - 1, int(lk[0]), int(lk[0]) + int(lk[3]) - 1, n):
				bad = true
				break
		if bad:
			continue
		var lb: float = base[posmod(first - K_BANK, n)]
		var rb: float = base[(first + W - 1 + K_BANK) % n]
		var level: float = minf(lb, rb) - K_FREE
		if level < K_FLOOR:
			continue
		cand.append({"m": m, "first": first, "W": W, "flow": fl, "level": level})
	cand.sort_custom(func(a, b): return a.flow > b.flow or (a.flow == b.flow and a.m < b.m))
	var gap: int = int(ceil(K_GAP / SimConst.COL))
	var keep: Array = []
	for cd in cand:
		if keep.size() >= K_MAXN:
			break
		var near: bool = false
		for k in keep:
			var d: int = absi(posmod(int(cd.m) - int(k.m) + n / 2, n) - n / 2)
			if d < gap:
				near = true
				break
		if near:
			continue
		keep.append(cd)
	keep.sort_custom(func(a, b): return a.first < b.first)
	var out: Array = []
	for k in keep:
		out.append([int(k.first), (int(k.first) + int(k.W) - 1) % n, float(k.level), int(k.W), float(k.flow)])
	return out


## The depth of a river's bed at the middle of its span, from the flow in the entry.
static func depthOf(flow: float) -> float:
	return minf(K_DMAX, K_D0 + K_D1 * sqrt(flow / K_REF))


## Cut the entries' channels into the ground `base`: the bed is the level less the depth in the middle of the span, easing up to the level at the edges (so a bank meets the water without a step); never raised.
static func carve(base: PackedFloat32Array, entries: Array) -> void:
	var n: int = base.size()
	for e in entries:
		var W: int = int(e[3])
		var d: float = depthOf(float(e[4]))
		var cf: float = float(W - 1) * 0.5
		for x in range(W):
			var u: float = absf(float(x) - cf) / (cf + 0.5)
			var p: float = 1.0
			if u > 0.5:
				var s: float = (u - 0.5) / 0.5
				p = 1.0 - s * s * (3.0 - 2.0 * s)
			var cx: int = (int(e[0]) + x) % n
			var bed: float = float(e[2]) - d * p
			if bed < base[cx]:
				base[cx] = bed
