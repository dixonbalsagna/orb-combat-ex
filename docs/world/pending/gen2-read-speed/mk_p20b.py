"""Window 20 (World, 2026-10-26), step b: the gen 2 column read without the dictionary reads.   python mk_p20b.py <root>   (after mk_p20a.py)
 - sim/world/climate.gd: the climate data's numbers kept as typed statics (made when the file is loaded), climateAt / plain read them; the same arithmetic in the same order
 - sim/world/planet.gd: readColumns reads the planet's numbers once a call, and a gen 2 planet on the stored continents takes the ground and the polar edge inline (no surfAt, no ground call)"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def climate(s):
    s = rep(s, '''static var curGen: int = 0   # 0: the data's gen; a tool or a match's setup sets it (useGen)
''', '''static var curGen: int = 0   # 0: the data's gen; a tool or a match's setup sets it (useGen)
# The data's numbers the column read uses, as typed statics (made by _cache when the file is loaded; the data is never changed after): a dictionary read of each, a column, was a fifth of the read (window 20).
static var _kJitScale: float = 0.0
static var _kJitSeed: int = 0
static var _kJit: float = 0.0
static var _kEq: float = 0.0
static var _kPow: float = 1.0
static var _kLapse: float = 0.0
static var _kHScale: float = 1.0
static var _kNScale: float = 0.0
static var _kNOct: int = 1
static var _kNAmp: float = 0.0
static var _kTSeed: int = 0
static var _kWBand: float = 0.0
static var _kWAdv: float = 0.0
static var _kBias: float = 0.0
static var _kMScale: float = 0.0
static var _kMOct: int = 1
static var _kMSeed: int = 0
static var _kWNoise: float = 0.0
static var _kVHMin: float = 0.0
static var _kVScale: float = 0.0
static var _kVOct: int = 1
static var _kVSeed: int = 0
static var _kVAbove: float = 0.0
static var _kBeachH: float = 0.0
static var _kHighB: float = 0.0
static var _kHighH: float = 0.0
static var _kWetMoist: float = 0.0
static var _kWetH: float = 0.0
static var _kWetTemp: float = 0.0
static var _kTE := PackedFloat64Array()
static var _kME := PackedFloat64Array()
static var _kTab := PackedInt32Array()
static var _kNM: int = 1
static var _cT: float = 0.0   # climateAt's answer, for plain (which would build an Array to read two numbers)
static var _cM: float = 0.0
''')
    s = rep(s, '''	_alias.resize(j.fine.size())
	for k in range(j.fine.size()):
		_alias[k] = int(j.fine[k].alias)
''', '''	_alias.resize(j.fine.size())
	for k in range(j.fine.size()):
		_alias[k] = int(j.fine[k].alias)
	_cache(j)


static func _cache(j: Dictionary) -> void:
	var tp: Dictionary = j.temp
	var mp: Dictionary = j.moist
	_kJitScale = float(tp.jitScale)
	_kJitSeed = int(tp.jitSeed)
	_kJit = float(tp.jit)
	_kEq = float(tp.eq)
	_kPow = float(tp.pow)
	_kLapse = float(tp.lapse)
	_kHScale = float(tp.hScale)
	_kNScale = float(tp.noiseScale)
	_kNOct = int(tp.noiseOct)
	_kNAmp = float(tp.noiseAmp)
	_kTSeed = int(tp.seed)
	_kWBand = float(mp.wBand)
	_kWAdv = float(mp.wAdv)
	_kBias = float(mp.bias)
	_kMScale = float(mp.noiseScale)
	_kMOct = int(mp.noiseOct)
	_kMSeed = int(mp.seed)
	_kWNoise = float(mp.wNoise)
	var vc: Dictionary = j.volcanic
	_kVHMin = float(vc.hMin)
	_kVScale = float(vc.scale)
	_kVOct = int(vc.oct)
	_kVSeed = int(vc.seed)
	_kVAbove = float(vc.above)
	_kBeachH = float(j.coast.beachH)
	_kHighB = float(j.b.highlandH)
	_kHighH = float(j.highland.h)
	_kWetMoist = float(j.wetland.moistMin)
	_kWetH = float(j.wetland.hMax)
	_kWetTemp = float(j.wetland.tempMin)
	_kTE.resize(j.tempEdges.size())
	for k in range(j.tempEdges.size()):
		_kTE[k] = float(j.tempEdges[k])
	_kME.resize(j.moistEdges.size())
	for k in range(j.moistEdges.size()):
		_kME[k] = float(j.moistEdges[k])
	_kNM = j.moistEdges.size() + 1
	_kTab.resize((j.tempEdges.size() + 1) * _kNM)
	for ti in range(j.tempEdges.size() + 1):
		for mi in range(_kNM):
			_kTab[ti * _kNM + mi] = int(j.table[ti][mi])
''')
    a = s.index("## The temperature (about 0 to 1) and moisture (0 to 1) at a point of height h.")
    new = '''## The temperature (about 0 to 1) and moisture (0 to 1) at a point of height h.
static func climateAt(P: WorldPlanet.Planet, px: float, py: float, pz: float, h: float) -> Array:
	_climTM(P, px, py, pz, h)
	return [_cT, _cM]


## climateAt's arithmetic, its two numbers left in _cT and _cM.
static func _climTM(P: WorldPlanet.Planet, px: float, py: float, pz: float, h: float) -> void:
	if not _loaded:
		_load()
	# the latitude wobbles by up to jit (a slow noise), so the belts of climate are wavy and not ruled lines
	var yj: float = SimMathx.jclamp(py + (WorldPlanet._fbm(P.R, px, py, pz, _kJitScale, 2, P.seed + _kJitSeed) - 0.5) * 2.0 * _kJit, -1.0, 1.0)
	var cl: float = sqrt(maxf(0.0, 1.0 - yj * yj))
	var T: float = _kEq * SimDetMath.pow(cl, _kPow) - _kLapse * maxf(h, 0.0) / _kHScale
	T += (WorldPlanet._fbm(P.R, px, py, pz, _kNScale, _kNOct, P.seed + _kTSeed) - 0.5) * 2.0 * _kNAmp
	var G: Grid = gridOf(P)
	var M: float = _kWBand * bandWet(yj) + _kWAdv * advAt(G, px, py, pz)
	M += _kBias
	M += (WorldPlanet._fbm(P.R, px, py, pz, _kMScale, _kMOct, P.seed + _kMSeed) - 0.5) * 2.0 * _kWNoise
	_cT = T
	_cM = SimMathx.jclamp(M, 0.0, 1.0)


## The fine biome of ordinary land at a point of height h (sea and ice are the surface function's); sets P.outF and returns the stored biome it reads as.
static func plain(P: WorldPlanet.Planet, px: float, py: float, pz: float, h: float) -> int:
	if h < 0.0:
		P.outF = F_OCEAN
		return WorldPlanet.BIO_OCEAN
	if not _loaded:
		_load()
	var onB: bool = WorldLand.plateB()   # Research's B plates: their volcanic score makes the volcanic fields, in place of the noise (window 13)
	var bv: bool = onB and WorldPlateB.volcAt(P, px, py, pz) > WorldPlateB.K.volcanic
	var above: float = P.c.mountainAbove
	if h > above and not bv:
		P.outF = F_MOUNTAINS
		return WorldPlanet.BIO_MOUNTAINS
	_climTM(P, px, py, pz, h)
	var T: float = _cT
	var M: float = _cM
	var fine: int
	if bv and T >= _kTE[0] and h >= _kBeachH:   # not too cold for it, and not a beach (Research's notCold)
		fine = F_VOLCANIC
	elif h > above:
		fine = F_MOUNTAINS
	elif not onB and h >= _kVHMin and WorldPlanet._fbm(P.R, px, py, pz, _kVScale, _kVOct, P.seed + _kVSeed) > _kVAbove:
		fine = F_VOLCANIC
	elif h >= (_kHighB if onB else _kHighH):
		fine = F_HIGHLAND
	elif h < _kBeachH:
		fine = F_BEACH
	elif M >= _kWetMoist and h < _kWetH and T >= _kWetTemp:
		fine = F_WETLAND
	else:
		var ti: int = 0
		for e in _kTE:
			if T >= e:
				ti += 1
		var mi: int = 0
		for e in _kME:
			if M >= e:
				mi += 1
		fine = _kTab[ti * _kNM + mi]
	P.outF = fine
	return _alias[fine]
'''
    return s[:a] + new


def planet(s):
    a = s.index("## Columns i0 up to i1 (exclusive) of the slice.")
    b = s.index("## The places the line holds, with their nearest column and lateral offset.")
    new = '''## Columns i0 up to i1 (exclusive) of the slice. The planet's numbers are read once a call, and a gen 2 planet on the stored continents takes surfAt's ordinary-ground path (the continents, the plates' shape, the
## polar edge, the climate's biome) written out here, the same arithmetic in the same order; where a column is in the polar zone surfAt itself is called (window 20).
static func readColumns(P: Planet, S: Slice, i0: int, i1: int) -> void:
	var c: Dictionary = P.c
	var circ: Dictionary = S.circ
	var u: Array = circ.u
	var v: Array = circ.v
	var small: bool = circ.has("st")
	var stf: float = circ.get("st", 1.0)
	var ct: float = circ.get("ct", 0.0)
	var ca: Array = circ.get("c", u)
	var tc: int = touchCol()
	var fine2: bool = P.gen >= 2
	var fast: bool = fine2 and not WorldLand.plateB()
	var R: float = P.R
	var sd0: int = P.seed
	var u0: float = u[0]
	var u1: float = u[1]
	var u2: float = u[2]
	var v0: float = v[0]
	var v1: float = v[1]
	var v2: float = v[2]
	var ca0: float = ca[0]
	var ca1: float = ca[1]
	var ca2: float = ca[2]
	var contScale: float = c.contScale
	var contOct: int = int(c.contOct)
	var seaShift: float = c.seaShift
	var hMul: float = c.hMul
	var rangeFrom: float = c.rangeFrom
	var reliefScale: float = c.reliefScale
	var reliefOct: int = int(c.reliefOct)
	var sRelief: int = int(c.sRelief)
	var rangeMul: float = c.rangeMul
	var reliefBase: float = c.reliefBase
	var keepV: float = WorldLand.keep()
	var polarY0: float = c.polarY
	var detailScale: float = c.detailScale
	var detailOct: int = int(c.detailOct)
	var dseed: int = sd0 + int(c.sDetail)
	var detailAmp: float = c.detailAmp
	var detailSheet: float = c.detailSheet
	for i in range(i0, i1):
		var ang: float = float(i - tc) * SimConst.COL / (R * stf)
		var co: float = SimDetMath.cos(ang)
		var si: float = SimDetMath.sin(ang)
		var qx: float = u0 * co + v0 * si
		var qy: float = u1 * co + v1 * si
		var qz: float = u2 * co + v2 * si
		if small:
			qx = ca0 * ct + stf * qx
			qy = ca1 * ct + stf * qy
			qz = ca2 * ct + stf * qz
		var done: bool = false
		if fast:
			var e: float = (_fbm(R, qx, qy, qz, contScale, contOct, sd0) - 0.5) * 2.0
			var g: float = (e + seaShift) * hMul
			if e > rangeFrom:
				var m: float = _fbm(R, qx, qy, qz, reliefScale, reliefOct, sd0 + sRelief)
				g += (e - rangeFrom) * rangeMul * (reliefBase + m) * keepV
			g = WorldLand.shape(P, qx, qy, qz, g)
			if absf(qy) < polarY0 + WorldLand.polarWob(P, qx, qy, qz):
				P.outF = -1
				P.outH = g
				P.outB = WorldClimate.plain(P, qx, qy, qz, g)
				done = true
		if not done:
			surfAt(P, qx, qy, qz)
		var h: float = P.outH
		var b: int = P.outB
		if b >= BIO_PLAINS and b <= BIO_MOUNTAINS:
			h += (_fbm(R, qx, qy, qz, detailScale, detailOct, dseed) - 0.5) * detailAmp
		elif b == BIO_ICE_SHEET and h > 100.0:
			h += (_fbm(R, qx, qy, qz, detailScale, detailOct, dseed) - 0.5) * detailAmp * detailSheet
		S.heights[i] = h
		S.biomes[i] = b
		if fine2:
			S.fine[i] = P.outF if P.outF >= 0 else b


'''
    return s[:a] + new + s[b:]


rw(R, 'sim/world/climate.gd', climate)
rw(R, 'sim/world/planet.gd', planet)
print('p20 step b applied')
