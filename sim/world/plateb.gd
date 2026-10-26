class_name WorldPlateB
extends RefCounted
## Planet generation 2, approach B: Research's plate-lite ground (research/planet-gen/gen/plates.mjs, docs/research/planet-gen.md section 2), ported number for number (window 12). Read only when land.json's b.enabled
## is true; with it off nothing here runs and the window 3 landforms (land.gd) are the ground, bit for bit.
##
## A few seeded plates (an Euler pole each, continental or oceanic), each made of one or more Voronoi cells found per point as the nearest cell centres to a noise-warped point. At each edge the plates' relative
## motion decides the landform: a range, a trench and an arc of islands, a mid-ocean ridge, a rift valley in offset segments; hotspots leave island chains. The crust (continent or ocean floor) is a noise levelled per
## planet to a land share, so coasts wander inside the plates. A pure function of the seed and the point, float64, + - * / sqrt floor and the planet's own noise and keyed draws only (the draws are Research's
## det.mjs `draw`, the same integers), so the JS reference (research/planet-gen) and this agree to the last digits (b_check.gd compares them on a dump).
##
## It replaces the whole ground of a gen 2 planet (land.gd's ranges, rifts, shoreline, plateaus and canyons are not applied; B has its own coast noise, rift segments and old ranges). The stored planet's polar zone
## (planet.gd surfAt: the pack sea in the north, the ice sheet in the south) still applies past its edge; B's own fades bring its landforms down before it (northFade, southFade in the data).

const PATH := "res://data/biomes/plates-b.json"
const SCHEMA := "biomes.plates-b/1"
const MASK := 0xFFFFFFFF
const PAIRS := [[0, 1, 2], [0, 2, 1], [1, 2, 0]]   # the pairs among the three nearest cells, and each pair's rival

static var _loaded: bool = false
static var _errors: Array = []
static var _hash: String = ""
static var K: Prm = null

class Prm extends RefCounted:
	## Research's PB (research/planet-gen/gen/plates.mjs), one member a number, set from plates-b.json by name (a member the file lacks keeps the default written here).
	var plates: int = 14
	var contArea: float = 0.55
	var minSpeed: float = 0.35
	var areaPts: int = 2000
	var sArea: int = 3250
	var landShare: float = 0.6
	var minSep: float = 0.82
	var sepTries: int = 24
	var cells: int = 30
	var cellSep: float = 0.9
	var warpScale: float = 16000.0
	var warpOct: int = 2
	var warpAmp: float = 0.2
	var crustScale: float = 24000.0
	var crustOct: int = 3
	var crustBias: float = 0.2
	var shelfW: float = 0.1
	var crustOctM: int = 2
	var southShelf: float = 3.0
	var contH: float = 250.0
	var contRelief: float = 900.0
	var oceanH: float = -2200.0
	var oceanRelief: float = 600.0
	var abyssH: float = 260.0
	var coastScale: float = 4000.0
	var coastAmp: float = 0.35
	var alongScale: float = 13000.0
	var alongOct: int = 1
	var interiorScale: float = 9000.0
	var interiorOct: int = 2
	var interiorH: float = 1300.0
	var oldScale: float = 15000.0
	var oldOct: int = 2
	var oldH: float = 2600.0
	var oldW: float = 0.28
	var oldRel: float = 0.3
	var oldRelW: float = 0.3
	var oldLo: float = 0.85
	var blendW: float = 0.3
	var blendWig: float = 0.6
	var bw: float = 0.11
	var edgeWiggle: float = 0.09
	var edgeWiggle2: float = 0.02
	var segMin: float = 0.4
	var junctionW: float = 0.05
	var capW: float = 0.05
	var capThrough: float = 0.03
	var capShort: float = -0.06
	var domW: float = 0.15
	var capRound: float = 0.7
	var capJit: float = 0.04
	var junctionEase: float = 0.5
	var quadW: float = 0.03
	var typeW: float = 0.2
	var vRef: float = 0.6
	var rangeH: float = 8000.0
	var arcH: float = 3000.0
	var trenchH: float = 2600.0
	var ridgeH: float = 1300.0
	var riftH: float = 1500.0
	var shoulderH: float = 900.0
	var apron: float = 0.3
	var coreW: float = 0.85
	var crestLo: float = 0.25
	var peakLo: float = 0.25
	var peakW: float = 0.6
	var knee: float = 4500.0
	var upCap: float = 9000.0
	var riftOpen: float = 0.42
	var riftOpenW: float = 0.22
	var riftSeg: float = 0.3
	var riftLap: float = 0.08
	var riftOff: float = 0.4
	var riftW: float = 0.32
	var islSp: float = 0.12
	var islR: float = 0.26
	var islGap: float = 0.3
	var islStretch: float = 1.6
	var islShape: float = 0.3
	var islTop: float = 1000.0
	var platH: float = 0.6
	var reliefScale: float = 3500.0
	var reliefOct: int = 3
	var peakScale: float = 1300.0
	var peakOct: int = 2
	var hotspots: int = 4
	var chain: int = 6
	var chainStep: float = 0.07
	var hotR: float = 0.035
	var hotH: float = 2600.0
	var hotSize: float = 0.6
	var hotShape: float = 0.7
	var hotStretch: float = 1.7
	var hotActive: int = 2
	var northFade: float = 0.48
	var northFadeW: float = 0.27
	var southFade: float = 0.58
	var southFadeW: float = 0.3
	var southCut: float = 0.85
	var volcPatch: float = 0.42
	var volcPatchW: float = 0.12
	var volcGain: float = 2.4
	var detailScale: float = 1800.0
	var detailOct: int = 2
	var detailAmp: float = 140.0
	var detailRamp: float = 150.0
	var volcanic: float = 0.55
	var sPlate: int = 3000
	var sPole: int = 3100
	var sType: int = 3200
	var sWarp: int = 3300
	var sCrust: int = 3400
	var sRelief: int = 3500
	var sIsland: int = 3600
	var sHot: int = 3700
	var sDetail: int = 3800
	var sWidth: int = 3900
	var sInterior: int = 3950
	var sOld: int = 3970
	var sRift: int = 3980


## One planet's plates: the cells, their plates' motion and crust bias, the crust level, the hotspot chains and the per-pair edge table (Research's makePlates result), flat arrays, plus the scratch one ground read uses.
class State extends RefCounted:
	var seed: int = 0
	var cells: int = 0
	var cf := PackedFloat64Array()      # centres, x y z per cell
	var bf := PackedFloat64Array()      # each cell's plate bias
	var plate := PackedInt32Array()     # each cell's plate
	var bias := PackedFloat64Array()    # (same as bf; kept for the call sites that index it)
	var lift: float = 0.0
	var hot := PackedFloat64Array()     # 9 a hotspot island: x y z, height, radius, volcanic, then the direction along the chain
	var hotB := PackedFloat64Array()    # 4 a chain: x y z of its first island, and the square of its reach
	var pe := PackedFloat64Array()      # 9 a pair of cells a < b at (a * cells + b) * 9: edge normal, edge axis, a's motion less b's
	var dots := PackedFloat64Array()
	var volc: float = 0.0               # the volcanic score of the last ground read (0 to 1), a side output
	var ids := PackedInt32Array()
	var ex := PackedFloat64Array()
	var hold := PackedFloat64Array()
	var pa := PackedInt32Array()
	var pb := PackedInt32Array()
	var sg := PackedFloat64Array()
	var cv := PackedFloat64Array()
	var ready := PackedInt32Array()


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
	K = null
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		_errors.append("plates-b.json: cannot open " + PATH)
		return
	var text: String = f.get_as_text()
	var j = JSON.parse_string(text)
	if not (j is Dictionary) or j.get("schema", "") != SCHEMA or not (j.get("params") is Dictionary):
		_errors.append("plates-b.json: not a %s object with params" % SCHEMA)
		return
	var k := Prm.new()
	for key in j.params.keys():
		if not (key in k):
			_errors.append("plates-b.json: no parameter " + str(key))
			continue
		var cur = k.get(key)
		k.set(key, int(j.params[key]) if cur is int else float(j.params[key]))
	if k.cells < k.plates or k.plates < 3 or k.cells * k.cells * 9 > 200000 or k.areaPts < 100 or k.landShare <= 0.0 or k.landShare >= 1.0:
		_errors.append("plates-b.json: cells at least plates, plates at least 3, areaPts at least 100, landShare in (0, 1)")
	if k.typeW <= 0.0 or k.quadW <= 0.0 or k.capW <= 0.0 or k.junctionW <= 0.0 or k.domW <= 0.0 or k.vRef <= 0.0 or k.bw <= 0.0 or k.blendW <= 0.0 or k.islSp <= 0.0 or k.riftSeg <= 0.0:
		_errors.append("plates-b.json: widths, quadW, vRef and spacings are above 0")
	if not _errors.is_empty():
		return
	K = k
	_hash = str(text.hash())


## Research's det.mjs `draw`: a keyed draw in [0, 1) from integers only (seed, a stream number, an index).
static func draw(seed: int, stream: int, n: int) -> float:
	return float(WorldPlanet._fm(WorldPlanet._fm((seed ^ ((stream * 0x9E3779B1) & MASK)) & MASK) ^ ((n * 0x85ebca6b) & MASK))) / 4294967296.0


## det.mjs `randUnit`: a seeded unit vector by rejection in the cube.
static func _randUnit(seed: int, stream: int, n: int) -> Array:
	for k in range(64):
		var x: float = draw(seed, stream, n * 64 + k * 3) * 2.0 - 1.0
		var y: float = draw(seed, stream, n * 64 + k * 3 + 1) * 2.0 - 1.0
		var z: float = draw(seed, stream, n * 64 + k * 3 + 2) * 2.0 - 1.0
		var q: float = x * x + y * y + z * z
		if q > 0.01 and q <= 1.0:
			var l: float = sqrt(q)
			return [x / l, y / l, z / l]
	return [0.0, 1.0, 0.0]


static func _nearest(c: Array, from: int, to: int, p: Array) -> int:
	var bi: int = from
	var bd: float = -2.0
	for i in range(from, to):
		var d: float = p[0] * c[i][0] + p[1] * c[i][1] + p[2] * c[i][2]
		if d > bd:
			bd = d
			bi = i
	return bi


static func _cmpAsc(a: Array, b: Array) -> bool:
	return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1])


static func _cmpDesc(a: Array, b: Array) -> bool:
	return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1])


## The plates of a planet: made once, kept on the planet (P.platesB). Research's makePlates.
static func stateOf(P: WorldPlanet.Planet) -> State:
	if P.platesB != null:
		return P.platesB
	if not _loaded:
		_load()
	var S: State = _make(P.seed, P.R)
	P.platesB = S
	return S


static func _make(seed: int, R: float) -> State:
	var Pm: Prm = K
	var nc: int = Pm.cells
	var c: Array = []
	var plate: Array = []
	for i in range(nc):
		var sep: float = Pm.minSep if i < Pm.plates else Pm.cellSep
		var ci: Array = _randUnit(seed, Pm.sPlate, i)
		for t in range(1, Pm.sepTries + 1):
			var ok: bool = true
			for j in range(i):
				if ci[0] * c[j][0] + ci[1] * c[j][1] + ci[2] * c[j][2] > sep:
					ok = false
					break
			if ok:
				break
			ci = _randUnit(seed, Pm.sPlate, i + 64 * t)
		c.append(ci)
		plate.append(i if i < Pm.plates else _nearest(c, 0, Pm.plates, ci))
	var pw: Array = []
	for i in range(Pm.plates):
		var pole: Array = _randUnit(seed, Pm.sPole, i)
		var sp: float = Pm.minSpeed + (1.0 - Pm.minSpeed) * draw(seed, Pm.sPole + 1, i)
		pw.append([pole[0] * sp, pole[1] * sp, pole[2] * sp])
	var area: Array = []
	for i in range(Pm.plates):
		area.append(0.0)
	var under: Array = []
	var cn: Array = []
	for k in range(Pm.areaPts):
		var p: Array = _randUnit(seed, Pm.sArea, k)
		var pi: int = plate[_nearest(c, 0, nc, p)]
		area[pi] += 1.0 / float(Pm.areaPts)
		under.append(pi)
		cn.append((WorldPlanet._fbm(R, p[0], p[1], p[2], Pm.crustScale, Pm.crustOct, seed + Pm.sCrust) - 0.5) * 2.0)
	var rank: Array = []
	for i in range(Pm.plates):
		rank.append([draw(seed, Pm.sType, i), i])
	rank.sort_custom(_cmpAsc)
	var cum: float = 0.0
	var pbias: Array = []
	for i in range(Pm.plates):
		pbias.append(-Pm.crustBias)
	for r in rank:
		var i: int = r[1]
		if cum + area[i] * 0.5 <= Pm.contArea:
			pbias[i] = Pm.crustBias
			cum += area[i]
	var cvs: Array = []
	for k in range(Pm.areaPts):
		cvs.append([cn[k] + pbias[under[k]], k])
	cvs.sort_custom(_cmpDesc)
	var lift: float = -float(cvs[int(floor(Pm.landShare * float(Pm.areaPts)))][0])
	var w: Array = []
	var bias: Array = []
	for i in range(nc):
		w.append(pw[plate[i]])
		bias.append(pbias[plate[i]])
	# hotspots: a point and a chain of older, lower islands carried off along its plate's motion
	var hot := PackedFloat64Array()
	for k in range(Pm.hotspots):
		var p: Array = _randUnit(seed, Pm.sHot, k)
		var hh: float = 0.6 + 0.4 * draw(seed, Pm.sHot + 1, k)
		for j in range(Pm.chain):
			var size: float = 1.0 - Pm.hotSize * 0.5 + Pm.hotSize * draw(seed, Pm.sHot + 3, k * 16 + j)
			var o: Array = w[_nearest(c, 0, nc, p)]
			var v: Array = [o[1] * p[2] - o[2] * p[1], o[2] * p[0] - o[0] * p[2], o[0] * p[1] - o[1] * p[0]]
			var vl: float = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
			if vl == 0.0:
				vl = 1.0
			hot.append(p[0])
			hot.append(p[1])
			hot.append(p[2])
			hot.append(hh * (1.0 - float(j) / float(Pm.chain + 1)))
			hot.append(Pm.hotR * size)
			hot.append(1.2 if j < Pm.hotActive else 0.0)
			hot.append(v[0] / vl)
			hot.append(v[1] / vl)
			hot.append(v[2] / vl)
			var st: float = Pm.chainStep * (0.7 + 0.6 * draw(seed, Pm.sHot + 2, k * 16 + j))
			var nx: float = p[0] + v[0] / vl * st
			var ny: float = p[1] + v[1] / vl * st
			var nz: float = p[2] + v[2] / vl * st
			var nl: float = sqrt(nx * nx + ny * ny + nz * nz)
			p = [nx / nl, ny / nl, nz / nl]
	var hotB := PackedFloat64Array()
	for k in range(Pm.hotspots):
		var b0: int = k * Pm.chain * 9
		var r: float = 0.0
		for j in range(Pm.chain):
			var b1: int = (k * Pm.chain + j) * 9
			var dx: float = hot[b1] - hot[b0]
			var dy: float = hot[b1 + 1] - hot[b0 + 1]
			var dz: float = hot[b1 + 2] - hot[b0 + 2]
			var e: float = sqrt(dx * dx + dy * dy + dz * dz) + Pm.hotStretch * hot[b1 + 4] * (1.0 + Pm.hotShape) + 1.0e-6
			if e > r:
				r = e
		hotB.append(hot[b0])
		hotB.append(hot[b0 + 1])
		hotB.append(hot[b0 + 2])
		hotB.append(r * r)
	var pe := PackedFloat64Array()
	pe.resize(nc * nc * 9)
	pe.fill(0.0)
	for a in range(nc):
		for b in range(a + 1, nc):
			var ca: Array = c[a]
			var cb: Array = c[b]
			var o: int = (a * nc + b) * 9
			var dx: float = cb[0] - ca[0]
			var dy: float = cb[1] - ca[1]
			var dz: float = cb[2] - ca[2]
			var dl: float = sqrt(dx * dx + dy * dy + dz * dz)
			var ex: float = ca[1] * cb[2] - ca[2] * cb[1]
			var ey: float = ca[2] * cb[0] - ca[0] * cb[2]
			var ez: float = ca[0] * cb[1] - ca[1] * cb[0]
			var el: float = sqrt(ex * ex + ey * ey + ez * ez)
			pe[o] = dx / dl
			pe[o + 1] = dy / dl
			pe[o + 2] = dz / dl
			pe[o + 3] = ex / el
			pe[o + 4] = ey / el
			pe[o + 5] = ez / el
			pe[o + 6] = w[a][0] - w[b][0]
			pe[o + 7] = w[a][1] - w[b][1]
			pe[o + 8] = w[a][2] - w[b][2]
	var S := State.new()
	S.seed = seed
	S.cells = nc
	S.cf.resize(nc * 3)
	S.bf.resize(nc)
	S.bias.resize(nc)
	S.plate.resize(nc)
	for i in range(nc):
		S.cf[3 * i] = c[i][0]
		S.cf[3 * i + 1] = c[i][1]
		S.cf[3 * i + 2] = c[i][2]
		S.bf[i] = bias[i]
		S.bias[i] = bias[i]
		S.plate[i] = plate[i]
	S.lift = lift
	S.hot = hot
	S.hotB = hotB
	S.pe = pe
	S.dots.resize(nc)
	S.ids.resize(3)
	S.ex.resize(3)
	S.hold.resize(3)
	S.pa.resize(3)
	S.pb.resize(3)
	S.sg.resize(3)
	S.cv.resize(3)
	S.ready.resize(3)
	return S


static func _bump(t: float) -> float:
	var a: float = -t if t < 0.0 else t
	return 0.0 if a >= 1.0 else WorldPlanet._ss(1.0 - a)


static func _frac(v: float) -> float:
	return v - floor(v)


## Ridged noise built octave by octave (Research's `ridged`).
static func _ridged(R: float, px: float, py: float, pz: float, scale: float, oct: int, s: int) -> float:
	var sum: float = 0.0
	var amp: float = 0.5
	var tot: float = 0.0
	var sc: float = scale
	for o in range(oct):
		var r: float = 1.0 - absf(2.0 * WorldPlanet._fbm(R, px, py, pz, sc, 1, s + o * 101) - 1.0)
		sum += amp * r * r
		tot += amp
		amp *= 0.5
		sc *= 0.5
	return sum / tot


## The along-edge coordinate of q on the edge between cells a and b (a < b).
static func _sAlong(S: State, a: int, b: int, qx: float, qy: float, qz: float) -> float:
	var o: int = (a * S.cells + b) * 9
	return qx * S.pe[o + 3] + qy * S.pe[o + 4] + qz * S.pe[o + 5]


## How fast cells a and b (a < b) close on each other across their edge at q, over vRef (negative: they part).
static func _closing(S: State, a: int, b: int, qx: float, qy: float, qz: float) -> float:
	var o: int = (a * S.cells + b) * 9
	var pe: PackedFloat64Array = S.pe
	var dq: float = qx * pe[o] + qy * pe[o + 1] + qz * pe[o + 2]
	var bx: float = pe[o] - qx * dq
	var by: float = pe[o + 1] - qy * dq
	var bz: float = pe[o + 2] - qz * dq
	var wx: float = pe[o + 6]
	var wy: float = pe[o + 7]
	var wz: float = pe[o + 8]
	var rvx: float = wy * qz - wz * qy
	var rvy: float = wz * qx - wx * qz
	var rvz: float = wx * qy - wy * qx
	return (rvx * bx + rvy * by + rvz * bz) / (sqrt(bx * bx + by * by + bz * bz) * K.vRef)


## Islands strung along the edge between cells a and b (an island arc).
static func _beads(S: State, a: int, b: int, s: float, x: float, xc: float, wr: float, dn: float) -> float:
	var Pm: Prm = K
	var t: float = s / Pm.islSp
	var jf: float = floor(t)
	var r1: float = draw(S.seed, Pm.sIsland + 1, (a * S.cells + b) * 64 + (int(jf) & 63))
	if r1 < Pm.islGap:
		return 0.0
	var uc: float = 0.5 + 0.3 * (_frac(r1 * 64.0) - 0.5)
	var la: float = Pm.islR * (0.5 + 0.5 * _frac(r1 * 4096.0)) * (1.0 + Pm.islShape * (dn - 0.5) * 2.0)
	var du: float = (t - jf - uc) / la
	var dx: float = (x - xc) * wr * Pm.islStretch / (la * Pm.islSp)
	return (0.85 + 0.15 * r1) * WorldPlanet._ss(1.5 - 1.5 * sqrt(du * du + dx * dx))


## Pair j's strength at a junction: how fast its plates close or part, held as the pair keeps its place (0: no pair).
static func _strength(S: State, j: int) -> float:
	if S.pa[j] < 0:
		return 0.0
	var cvj: float = S.cv[j]
	return (-cvj if cvj < 0.0 else cvj) * S.hold[PAIRS[j][0]] * S.hold[PAIRS[j][1]]


## The ground at a point of the unit sphere: Research's plateGround (the full read, not the climate march's coarse one). Sets State.volc as a side output.
static func ground(P: WorldPlanet.Planet, px: float, py: float, pz: float) -> float:
	var S: State = P.platesB if P.platesB != null else stateOf(P)
	var Pm: Prm = K
	var R: float = P.R
	var seed: int = S.seed
	var n: int = S.cells
	var qx0: float = px + Pm.warpAmp * (WorldPlanet._fbm(R, px, py, pz, Pm.warpScale, Pm.warpOct, seed + Pm.sWarp) - 0.5) * 2.0
	var qy0: float = py + Pm.warpAmp * (WorldPlanet._fbm(R, px, py, pz, Pm.warpScale, Pm.warpOct, seed + Pm.sWarp + 17) - 0.5) * 2.0
	var qz0: float = pz + Pm.warpAmp * (WorldPlanet._fbm(R, px, py, pz, Pm.warpScale, Pm.warpOct, seed + Pm.sWarp + 31) - 0.5) * 2.0
	var ql: float = sqrt(qx0 * qx0 + qy0 * qy0 + qz0 * qz0)
	var qx: float = qx0 / ql
	var qy: float = qy0 / ql
	var qz: float = qz0 / ql
	# the four nearest cells (the fourth only says how near the third is to losing its place)
	var i1: int = 0
	var i2: int = 0
	var i3: int = 0
	var d1: float = -9.0
	var d2: float = -9.0
	var d3: float = -9.0
	var d4: float = -9.0
	var cf: PackedFloat64Array = S.cf
	var dots: PackedFloat64Array = S.dots
	for i in range(n):
		var d: float = qx * cf[3 * i] + qy * cf[3 * i + 1] + qz * cf[3 * i + 2]
		dots[i] = d
		if d > d1:
			d4 = d3
			i3 = i2
			d3 = d2
			i2 = i1
			d2 = d1
			i1 = i
			d1 = d
		elif d > d2:
			d4 = d3
			i3 = i2
			d3 = d2
			i2 = i
			d2 = d
		elif d > d3:
			d4 = d3
			i3 = i
			d3 = d
		elif d > d4:
			d4 = d
	var ids: PackedInt32Array = S.ids
	ids[0] = i1
	ids[1] = i2
	ids[2] = i3
	var ex: PackedFloat64Array = S.ex
	ex[0] = 0.0
	ex[1] = d1 - d2
	ex[2] = d1 - d3
	var e4: float = d1 - d4
	var hold: PackedFloat64Array = S.hold
	hold[0] = WorldPlanet._ss(e4 / Pm.quadW)
	hold[1] = WorldPlanet._ss((e4 - ex[1]) / Pm.quadW)
	hold[2] = WorldPlanet._ss((e4 - ex[2]) / Pm.quadW)
	# the polar fades: landforms fade toward the north before the stored planet's pack sea and toward the south before its ice sheet (plain y here; the stored polar edge wobbles by its own noise)
	var yy: float = py
	var nF: float = 1.0 - WorldPlanet._ss((yy - Pm.northFade) / Pm.northFadeW)
	var sF: float = WorldPlanet._ss((-yy - Pm.southFade) / Pm.southFadeW)
	var polar: float = nF * (1.0 - Pm.southCut * sF)
	var polarD: float = nF * (1.0 - sF)
	var rel: float = WorldPlanet._fbm(R, px, py, pz, Pm.interiorScale, Pm.interiorOct, seed + Pm.sInterior)
	# crust: one noise, the plates' biases blended near their shared edges over a width that swells and narrows with the relief
	var bl: float = Pm.blendW * (1.0 + (rel - 0.5) * 2.0 * Pm.blendWig)
	var bw: float = 0.0
	var bs: float = 0.0
	for i in range(n):
		var e: float = d1 - dots[i]
		if e < bl:
			var g: float = WorldPlanet._ss(1.0 - e / bl)
			bw += g
			bs += S.bf[i] * g
	var noise: float = (WorldPlanet._fbm(R, qx, qy, qz, Pm.crustScale, Pm.crustOct, seed + Pm.sCrust) - 0.5) * 2.0 + S.lift
	var coastN: float = WorldPlanet._fbm(R, px, py, pz, Pm.coastScale, 2, seed + Pm.sCrust + 9)
	noise += (coastN - 0.5) * Pm.coastAmp
	var crust: float = noise + bs / bw
	var sw: float = Pm.shelfW * (1.0 + Pm.southShelf * sF)
	var land: float = WorldPlanet._ss((crust + sw) / (2.0 * sw))
	var h: float = Pm.oceanH + noise * Pm.oceanRelief + (Pm.contH + crust * Pm.contRelief - Pm.oceanH - noise * Pm.oceanRelief) * land
	var oldv: float = 0.0
	h += land * (rel - 0.38) * Pm.interiorH + (1.0 - land) * (rel - 0.5) * 2.0 * Pm.abyssH
	if land > 0.0 and rel > Pm.oldRel:
		var t: float = (2.0 * WorldPlanet._fbm(R, (qx - 4.0 * qy + 8.0 * qz) / 9.0, (8.0 * qx + 4.0 * qy + qz) / 9.0, (-4.0 * qx + 7.0 * qy + 4.0 * qz) / 9.0, Pm.oldScale, Pm.oldOct, seed + Pm.sOld) - 1.0) / Pm.oldW
		var u: float = t * t
		var old: float = 1.0 - u if u < 1.0 else 0.0
		oldv = land * old * old * Pm.oldH * WorldPlanet._ss((rel - Pm.oldRel) / Pm.oldRelW) * polar
	var widthMul: float = 0.7 + 0.6 * rel
	# boundary landforms: each pair of different plates among the three nearest cells, ordered by index, and the signed distance to its edge
	var pa: PackedInt32Array = S.pa
	var pb: PackedInt32Array = S.pb
	var sg: PackedFloat64Array = S.sg
	var cv: PackedFloat64Array = S.cv
	var ready: PackedInt32Array = S.ready
	for k in range(3):
		pa[k] = -1
		pb[k] = 0
		sg[k] = 0.0
		cv[k] = 0.0
		ready[k] = 0
	for k in range(3):
		var a: int = ids[PAIRS[k][0]]
		var b: int = ids[PAIRS[k][1]]
		if S.plate[a] == S.plate[b]:
			continue
		if a > b:
			var tt: int = a
			a = b
			b = tt
		var o: int = (a * n + b) * 9
		pa[k] = a
		pb[k] = b
		sg[k] = -(qx * S.pe[o] + qy * S.pe[o + 1] + qz * S.pe[o + 2])
	var up: float = 0.0
	var apr: float = 0.0
	var crest: float = 0.0
	var down: float = 0.0
	var volc: float = 0.0
	var gsum: float = 0.0
	var isles: float = 0.0
	var wig: float = (rel - 0.5) * 2.0 * Pm.edgeWiggle + (coastN - 0.5) * 2.0 * Pm.edgeWiggle2
	var wr: float = Pm.bw * widthMul
	var sea: float = 1.0 - land
	var along: float = -1.0
	var dn: float = -1.0
	for k in range(3):
		if pa[k] < 0:
			continue
		var ka: int = PAIRS[k][0]
		var kb: int = PAIRS[k][1]
		var kc: int = PAIRS[k][2]
		var a: int = pa[k]
		var b: int = pb[k]
		var c: int = ids[kc]
		var x: float = (sg[k] + wig) / wr
		if x > 1.2 or x < -1.2:
			continue
		var g: float
		if S.plate[c] == S.plate[a] or S.plate[c] == S.plate[b]:
			var lead: float = ex[kc] - (ex[ka] if ex[ka] > ex[kb] else ex[kb])
			g = WorldPlanet._ss(0.5 + lead / (2.0 * Pm.junctionW))
		else:
			# a triple junction J: the landform keeps its width to a blunt end there. The two stronger arms reach just past J and join; the weakest stops short
			var o: int = (a * n + b) * 9
			var nx: float = S.pe[o]
			var ny: float = S.pe[o + 1]
			var nz: float = S.pe[o + 2]
			var cax: float = cf[3 * a]
			var cay: float = cf[3 * a + 1]
			var caz: float = cf[3 * a + 2]
			var ux: float = -nx
			var uy: float = -ny
			var uz: float = -nz
			var vx: float = cax - cf[3 * c]
			var vy: float = cay - cf[3 * c + 1]
			var vz: float = caz - cf[3 * c + 2]
			var jx: float = uy * vz - uz * vy
			var jy: float = uz * vx - ux * vz
			var jz: float = ux * vy - uy * vx
			var jl: float = sqrt(jx * jx + jy * jy + jz * jz)
			var js: float = -1.0 / jl if jx * cax + jy * cay + jz * caz < 0.0 else 1.0 / jl
			jx *= js
			jy *= js
			jz *= js
			var tx: float = ny * jz - nz * jy
			var ty: float = nz * jx - nx * jz
			var tz: float = nx * jy - ny * jx
			var s: float = (-1.0 if tx * vx + ty * vy + tz * vz < 0.0 else 1.0) * (qx * tx + qy * ty + qz * tz)
			for j in range(3):
				if pa[j] >= 0 and ready[j] == 0:
					cv[j] = _closing(S, pa[j], pb[j], qx, qy, qz)
					ready[j] = 1
			var o1: float = _strength(S, (k + 1) % 3)
			var o2: float = _strength(S, (k + 2) % 3)
			var weak: float = WorldPlanet._ss(0.5 + ((o1 if o1 < o2 else o2) - _strength(S, k)) / Pm.domW)
			if along < 0.0:
				along = WorldPlanet._fbm(R, px, py, pz, Pm.alongScale, Pm.alongOct, seed + Pm.sWidth + 5)
			var reach: float = Pm.capThrough + (Pm.capShort - Pm.capThrough) * weak + (along - 0.5) * 2.0 * Pm.capJit - Pm.capRound * wr * x * x
			g = WorldPlanet._ss((s + reach) / Pm.capW)
		var gate: float = (1.0 - hold[kc] * (1.0 - g)) * hold[ka] * hold[kb]
		if gate <= 0.0:
			continue
		gsum += gate * _bump(x / 1.1)
		var tA: float = WorldPlanet._ss(0.5 + (noise + S.bias[a]) / Pm.typeW)
		var tB: float = WorldPlanet._ss(0.5 + (noise + S.bias[b]) / Pm.typeW)
		if along < 0.0:
			along = WorldPlanet._fbm(R, px, py, pz, Pm.alongScale, Pm.alongOct, seed + Pm.sWidth + 5)
		if ready[k] == 0:
			cv[k] = _closing(S, a, b, qx, qy, qz)
			ready[k] = 1
		var conv: float = cv[k]
		if conv > 0.0:
			var kk: float = WorldPlanet._ss(conv) * gate * (Pm.segMin + (1.0 - Pm.segMin) * WorldPlanet._ss((along - 0.2) / 0.5))
			var cc: float = tA * tB
			var ab: float = tA * (1.0 - tB)
			var ba: float = (1.0 - tA) * tB
			var oo: float = (1.0 - tA) * (1.0 - tB)
			if cc > 0.0:
				apr += Pm.rangeH * kk * cc * Pm.apron * _bump(x)
				crest += Pm.rangeH * kk * cc * (1.0 - Pm.apron) * _bump(x / Pm.coreW)
			var sa: float = 0.0
			var sDone: bool = false
			for m in range(3):
				var w: float = ab if m == 0 else (ba if m == 1 else oo)
				var xt: float = 0.16 if m == 1 else -0.16
				var xa: float = 0.6 if m == 0 else (-0.6 if m == 1 else 0.5)
				if w <= 0.0:
					continue
				down += Pm.trenchH * kk * w * sea * _bump((x - xt) / 0.2)
				var belt: float = _bump((x - xa) / 0.45)
				if belt <= 0.0:
					continue
				up += Pm.arcH * kk * w * (belt * land + Pm.platH * belt * sea)
				volc += kk * w * belt * land
				if sea > 0.0:
					if not sDone:
						sa = _sAlong(S, a, b, qx, qy, qz)
						sDone = true
					if dn < 0.0:
						dn = WorldPlanet._fbm(R, px, py, pz, Pm.detailScale, Pm.detailOct, seed + Pm.sDetail)
					var isl: float = WorldPlanet._ss(2.0 * kk) * w * sea * _beads(S, a, b, sa, x, xa, wr, dn)
					isles += isl
					volc += isl
		elif conv < 0.0:
			var kk2: float = WorldPlanet._ss(-conv) * gate
			var oo2: float = (1.0 - tA) * (1.0 - tB)
			up += Pm.ridgeH * kk2 * oo2 * _bump(x / 0.8)
			var kr: float = kk2 * (1.0 - oo2) * WorldPlanet._ss((along - Pm.riftOpen) / Pm.riftOpenW)
			if kr > 0.0:
				var s2: float = _sAlong(S, a, b, qx, qy, qz)
				for f in range(2):
					var t2: float = s2 / Pm.riftSeg + 0.5 * float(f)
					var jf: float = floor(t2)
					var r: float = draw(seed, Pm.sRift, ((a * n + b) * 2 + f) * 64 + (int(jf) & 63))
					var u2: float = t2 - jf - 0.5
					var dep: float = kr * WorldPlanet._ss((0.25 + Pm.riftLap - (-u2 if u2 < 0.0 else u2)) / (2.0 * Pm.riftLap)) * (0.55 + 0.45 * _frac(r * 4096.0))
					var xr: float = x - (r - 0.5) * 2.0 * Pm.riftOff
					var side: float = -1.0 if _frac(r * 64.0) < 0.5 else 1.0
					down += Pm.riftH * dep * _bump(xr / Pm.riftW)
					var tb: float = side * xr
					up += Pm.shoulderH * dep * (0.6 + 0.8 * along) * WorldPlanet._ss((tb - 0.15) / 0.25) * (1.0 - WorldPlanet._ss((tb - 0.4) / 0.4))
					volc += 0.7 * dep * _bump(xr / 0.22)
	# where arms overlap their landforms are averaged, not stacked
	var ge: float = gsum - 1.0
	var E: float = Pm.junctionEase
	var norm: float = 1.0 / (1.0 if ge <= 0.0 else (1.0 + ge * ge / (2.0 * E) if ge < E else gsum - E * 0.5))
	up *= norm * polar
	apr *= norm * polar
	volc *= norm * polar
	isles *= norm * polar
	crest *= norm * polarD
	down *= norm * polarD
	# hotspot chains
	var depth: float = -h - 100.0 if h < -200.0 else (h * h / 400.0 if h < 0.0 else 0.0)
	var hot: float = 0.0
	var HT: PackedFloat64Array = S.hot
	var HB: PackedFloat64Array = S.hotB
	for k in range(Pm.hotspots):
		var bx: float = px - HB[4 * k]
		var by: float = py - HB[4 * k + 1]
		var bz: float = pz - HB[4 * k + 2]
		if bx * bx + by * by + bz * bz >= HB[4 * k + 3]:
			continue
		for j in range(k * Pm.chain, (k + 1) * Pm.chain):
			var o: int = j * 9
			var ddx: float = px - HT[o]
			var ddy: float = py - HT[o + 1]
			var ddz: float = pz - HT[o + 2]
			var dc: float = ddx * HT[o + 6] + ddy * HT[o + 7] + ddz * HT[o + 8]
			var dd2: float = ddx * ddx + ddy * ddy + ddz * ddz - (1.0 - 1.0 / (Pm.hotStretch * Pm.hotStretch)) * dc * dc
			var rr: float = HT[o + 4] * (1.0 + Pm.hotShape)
			if dd2 < rr * rr:
				var d: float = sqrt(dd2 if dd2 > 0.0 else 0.0)
				if dn < 0.0:
					dn = WorldPlanet._fbm(R, px, py, pz, Pm.detailScale, Pm.detailOct, seed + Pm.sDetail)
				var v: float = HT[o + 3] * WorldPlanet._ss(1.0 - d / (HT[o + 4] * (1.0 + Pm.hotShape * (dn - 0.5) * 2.0))) * (1.0 - land * 0.85) * polar
				hot += v * (Pm.hotH + depth)
				volc += v * HT[o + 5]
	var lift: float = up + apr + crest
	var rough: float = 0.5
	if lift > 0.0 or volc > 0.0 or hot > 0.0:
		rough = WorldPlanet._fbm(R, px, py, pz, Pm.reliefScale, Pm.reliefOct, seed + Pm.sRelief)
		volc *= Pm.volcGain * WorldPlanet._ss((rough - Pm.volcPatch) / Pm.volcPatchW)
	if lift > 0.0 or oldv > 0.0:
		var peaks: float = _ridged(R, (px - 4.0 * py + 8.0 * pz) / 9.0, (8.0 * px + 4.0 * py + pz) / 9.0, (-4.0 * px + 7.0 * py + 4.0 * pz) / 9.0, Pm.peakScale, Pm.peakOct, seed + Pm.sRelief + 7)
		var pk: float = WorldPlanet._ss((peaks - Pm.peakLo) / Pm.peakW)
		lift = up * (0.25 + 1.5 * rough) * (0.75 + 0.5 * pk) + apr * (0.5 + rough) + crest * (Pm.crestLo + (1.0 - Pm.crestLo) * pk) * (0.6 + 0.8 * rough) + oldv * (Pm.oldLo + (1.0 - Pm.oldLo) * pk)
	if lift > Pm.knee:
		var e5: float = lift - Pm.knee
		lift = Pm.knee + e5 / (1.0 + e5 / (Pm.upCap - Pm.knee))
	h += lift + hot * (0.75 + 0.5 * rough) - down
	if isles > 0.0:
		var dd: float = -h - 100.0 if h < -200.0 else (h * h / 400.0 if h < 0.0 else 0.0)
		h += isles * (Pm.islTop + dd)
	if h > 0.0:
		if dn < 0.0:
			dn = WorldPlanet._fbm(R, px, py, pz, Pm.detailScale, Pm.detailOct, seed + Pm.sDetail)
		h += (dn - 0.5) * 2.0 * Pm.detailAmp * WorldPlanet._ss(h / Pm.detailRamp)
	S.volc = 1.0 if volc > 1.0 else volc
	return h
