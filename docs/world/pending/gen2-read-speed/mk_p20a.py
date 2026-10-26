"""Window 20 (World, 2026-10-26), step a: the gen 2 column read, faster and the same to the last bit.   python mk_p20a.py <root>
 - sim/world/planet.gd: _fbm written out over _vn (one call and one dictionary read fewer an octave)
 - sim/world/land.gd: _terms returns the zero it would compute for any point whose nearest plate leads the second by more than the plate edges' reach, and remembers a ball around such a point inside which that holds"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def planet(s):
    a = s.index("static func _fbm(R: float")
    b = s.index("static func _ss(a: float)")
    new = '''## Octaves of _vn at the planet's scale, normalised to [0, 1). _vn is written out inside the octave loop (the same arithmetic in the same order, so the same bits): a call an octave and a dictionary read a call were
## a third of the cost of a column of the ring (window 20).
static func _fbm(R: float, px: float, py: float, pz: float, scale: float, oct: int, s: int) -> float:
	var sum: float = 0.0
	var amp: float = 0.5
	var tot: float = 0.0
	var k: float = R / scale
	var slots: Dictionary = _vcSlot
	for o in range(maxi(1, oct - _octOff)):
		var x: float = px * k
		var y: float = py * k
		var z: float = pz * k
		var fx: float = floor(x)
		var fy: float = floor(y)
		var fz: float = floor(z)
		var ix: int = int(fx)
		var iy: int = int(fy)
		var iz: int = int(fz)
		var tx: float = x - fx
		var ty: float = y - fy
		var tz: float = z - fz
		tx = tx * tx * (3.0 - 2.0 * tx)
		ty = ty * ty * (3.0 - 2.0 * ty)
		tz = tz * tz * (3.0 - 2.0 * tz)
		var sd: int = s + o * 101
		var slot: int = slots.get(sd, -1)
		if slot < 0:
			slot = _vcNew(sd)
		var kb: int = slot * 3
		if _vcKey[kb] != ix or _vcKey[kb + 1] != iy or _vcKey[kb + 2] != iz:
			_vcFill(slot, ix, iy, iz, sd)
		var vb: int = slot * 8
		var c000: float = _vcVal[vb]
		var a: float = c000 + (_vcVal[vb + 1] - c000) * tx
		var c010: float = _vcVal[vb + 2]
		var b: float = c010 + (_vcVal[vb + 3] - c010) * tx
		var c001: float = _vcVal[vb + 4]
		var c: float = c001 + (_vcVal[vb + 5] - c001) * tx
		var c011: float = _vcVal[vb + 6]
		var d: float = c011 + (_vcVal[vb + 7] - c011) * tx
		var e: float = a + (b - a) * ty
		var f: float = c + (d - c) * ty
		sum += amp * (e + (f - e) * tz)
		tot += amp
		amp *= 0.5
		k *= 2.0
	return sum / tot


'''
    return s[:a] + new + s[b:]


def land(s):
    s = rep(s, '''static var _dk := PackedFloat64Array()
''', '''static var _dk := PackedFloat64Array()
static var _zP = null        # the planet and the ball (centre, squared radius) round a point where no plate edge reaches: _terms is 0 for every point inside it (derived data, a memo of what _terms would return)
static var _zx: float = 0.0
static var _zy: float = 0.0
static var _zz: float = 0.0
static var _zR2: float = -1.0
''')
    return rep(s, '''static func _terms(P: WorldPlanet.Planet, px: float, py: float, pz: float) -> void:
	var pl: Plates = platesOf(P)
	var n: int = pl.n
	if _dk.size() != n:
		_dk.resize(n)
	var b1: float = -2.0
	for i in range(n):
		var d: float = px * pl.cx[i] + py * pl.cy[i] + pz * pl.cz[i]
		_dk[i] = d
		if d > b1:
			b1 = d
	var wr: float = K_R_WIDTH
	var wf: float = K_F_WIDTH
	var wm: float = wr if wr > wf else wf
	var cut: float = 2.5 * wm
	var wg: float = 0.5 * wm
	var reach: float = 2.5 * wg
	_rA = 0.0
	_rB = 0.0
''', '''static func _terms(P: WorldPlanet.Planet, px: float, py: float, pz: float) -> void:
	if _zP == P:   # inside a ball round a point where no edge reaches (below): nothing to add, as the full read would find
		var zx: float = px - _zx
		var zy: float = py - _zy
		var zz: float = pz - _zz
		if zx * zx + zy * zy + zz * zz < _zR2:
			_rA = 0.0
			_rB = 0.0
			return
	var pl: Plates = platesOf(P)
	var n: int = pl.n
	if _dk.size() != n:
		_dk.resize(n)
	var cx: PackedFloat64Array = pl.cx
	var cy: PackedFloat64Array = pl.cy
	var cz: PackedFloat64Array = pl.cz
	var b1: float = -2.0
	var b2: float = -2.0
	for i in range(n):
		var d: float = px * cx[i] + py * cy[i] + pz * cz[i]
		_dk[i] = d
		if d > b1:
			b2 = b1
			b1 = d
		elif d > b2:
			b2 = d
	var wr: float = K_R_WIDTH
	var wf: float = K_F_WIDTH
	var wm: float = wr if wr > wf else wf
	var cut: float = 2.5 * wm
	var wg: float = 0.5 * wm
	var reach: float = 2.5 * wg
	_rA = 0.0
	_rB = 0.0
	# Where the nearest plate leads the second by more than cut + the wobble (which is more than reach), no pair of plates passes the tests below (a plate but the nearest is farther than reach from it, and the
	# nearest is farther than cut + wobble from every other): the sums are 0 and the wobble is not read. Every dot product moves by at most the distance the point moves, so the lead falls by at most twice
	# that: inside a ball of 0.45 of the spare lead round this point it is the same 0 (a little under half, for the float rounding).
	var thr: float = cut + K_WOB_AMP
	if b1 - b2 > thr + 1.0e-9:
		var rr: float = 0.45 * (b1 - b2 - thr)
		_zP = P
		_zx = px
		_zy = py
		_zz = pz
		_zR2 = rr * rr
		return
''')


rw(R, 'sim/world/planet.gd', planet)
rw(R, 'sim/world/land.gd', land)
print('p20 step a applied')
