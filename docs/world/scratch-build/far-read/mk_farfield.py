"""A render-only bulk far read (World, scratch): WorldPlanet.farField.   python mk_farfield.py <root>"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def planet(s):
    a = '''## The slice of an explicit ring (WorldRingPick: an axis, the columns, a touch-down), memoised outside the state like sliceFor's.'''
    new = '''## A block of the ground beside a ring, for a renderer's far land (window 2's slow drift and the far land at a turn): the height and biome at `ncols` columns of the ring, from column c0 every `stride`,
## each moved sideways by each of `depths` (farColumn's z). It is farColumn read in bulk and in a better order: depth by depth, so that consecutive samples are 32 x stride units apart and sit in the
## noise cell of the one before (the memo of _vn hits), a column's point and its way to the centre are worked out once, and a depth's rotation once. Index di * ncols + ci. Every sample is
## farColumn's own, bit for bit, where |z| <= coarseFrom (the default is everywhere). Past coarseFrom the read is COARSE, for a hazed far land: every noise has one octave fewer (the finest, an eighth to
## a sixteenth of its swing) and the surface detail is not added; heights are then off by up to a few hundred units in mountains and the odd biome border moves a column or two. About half the work, and
## nothing in the sim reads it. Returns {"h": heights (float64), "b": biomes}. A pure function of the planet and the ring.
static func farField(P: Planet, ring: Dictionary, c0: int, ncols: int, stride: int, depths: PackedFloat64Array, coarseFrom: float = 1.0e18) -> Dictionary:
	var c: Dictionary = P.c
	var m: Array = ring.get("c", ring.n)
	var px := PackedFloat64Array()
	var py := PackedFloat64Array()
	var pz := PackedFloat64Array()
	var tx := PackedFloat64Array()
	var ty := PackedFloat64Array()
	var tz := PackedFloat64Array()
	px.resize(ncols)
	py.resize(ncols)
	pz.resize(ncols)
	tx.resize(ncols)
	ty.resize(ncols)
	tz.resize(ncols)
	for ci in range(ncols):
		var p: Array = columnPoint(P, ring, c0 + ci * stride)
		px[ci] = p[0]
		py[ci] = p[1]
		pz[ci] = p[2]
		var d: float = m[0] * p[0] + m[1] * p[1] + m[2] * p[2]
		var t: Array = _unit([m[0] - p[0] * d, m[1] - p[1] * d, m[2] - p[2] * d])
		tx[ci] = t[0]
		ty[ci] = t[1]
		tz[ci] = t[2]
	var hs := PackedFloat64Array()
	var bs := PackedByteArray()
	hs.resize(ncols * depths.size())
	bs.resize(ncols * depths.size())
	var detSeed: int = P.seed + int(c.sDetail)
	for di in range(depths.size()):
		var z: float = depths[di]
		var co: float = 1.0
		var si: float = 0.0
		if z != 0.0:
			var a: float = z / P.R
			co = SimDetMath.cos(a)
			si = SimDetMath.sin(a)
		var detail: bool = absf(z) <= coarseFrom
		_octOff = 0 if detail else 1
		for ci in range(ncols):
			var qx: float = px[ci]
			var qy: float = py[ci]
			var qz: float = pz[ci]
			if z != 0.0:
				qx = px[ci] * co + tx[ci] * si
				qy = py[ci] * co + ty[ci] * si
				qz = pz[ci] * co + tz[ci] * si
			surfAt(P, qx, qy, qz)
			var h: float = P.outH
			var b: int = P.outB
			if detail:
				if b >= BIO_PLAINS and b <= BIO_MOUNTAINS:
					h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), detSeed) - 0.5) * c.detailAmp
				elif b == BIO_ICE_SHEET and h > 100.0:
					h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), detSeed) - 0.5) * c.detailAmp * c.detailSheet
			hs[di * ncols + ci] = h
			bs[di * ncols + ci] = b
	_octOff = 0
	return {"h": hs, "b": bs}


'''
    s = rep(s, a, new + a)
    s = rep(s, '''static func _fm(x: int) -> int:
	x &= MASK
	x ^= x >> 16
	x = SimRng.imul(x, 0x85ebca6b)
	x ^= x >> 13
	x = SimRng.imul(x, 0xc2b2ae35)
	x ^= x >> 16
	return x & MASK
''', '''static func _fm(x: int) -> int:   # SimRng.imul written out (one call, not three): the same bits
	x &= MASK
	x ^= x >> 16
	x = (x * 0xca6b + (((x * 0x85eb) & 0xFFFF) << 16)) & MASK
	x ^= x >> 13
	x = (x * 0xae35 + (((x * 0xc2b2) & 0xFFFF) << 16)) & MASK
	x ^= x >> 16
	return x & MASK
''')
    s = rep(s, '''	var k: float = R / scale
	for o in range(oct):
		sum += amp * _vn(px * k, py * k, pz * k, s + o * 101)''', '''	var k: float = R / scale
	for o in range(maxi(1, oct - _octOff)):
		sum += amp * _vn(px * k, py * k, pz * k, s + o * 101)''')
    s = rep(s, '''static func _fbm(R: float''', '''## Octaves left out of every _fbm, for farField's coarse read only (set and reset inside it); 0 everywhere else.
static var _octOff: int = 0


static func _fbm(R: float''')
    return s


rw(R, 'sim/world/planet.gd', planet)
print('farField applied')
