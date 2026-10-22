"""Shifting arena, window 2 (World's part): WorldPlanet.farColumn, a pure read of the planet's own ground beside the ring (docs/world/shifting-arena-design.md section 2).
python mk_far.py <root>     (root: HEAD with windows 0, 1 and 4 applied)"""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def planet(s):
    return rep(s, '''## The slice of an explicit ring''', '''## The ground beside a ring (window 2, the slow drift: Rendering's far land and sky read the planet's own ground, not a wander): the height and biome at column i of the ring, moved `z` units
## sideways over the surface (z positive toward the ring's centre, negative away from it, along the great circle through the column at right angles to the ring). At z = 0 it is the slice's
## own column, height and biome to the bit. Returns [height, biome]. A pure function of the planet and the ring: no state, no clock.
static func farColumn(P: Planet, ring: Dictionary, i: int, z: float) -> Array:
	var c: Dictionary = P.c
	var p: Array = columnPoint(P, ring, i)
	var qx: float = p[0]
	var qy: float = p[1]
	var qz: float = p[2]
	if z != 0.0:
		var m: Array = ring.get("c", ring.n)
		var d: float = m[0] * p[0] + m[1] * p[1] + m[2] * p[2]
		var t: Array = _unit([m[0] - p[0] * d, m[1] - p[1] * d, m[2] - p[2] * d])   # the way to the centre (for a great circle, towards its normal's side)
		var a: float = z / P.R
		var co: float = SimDetMath.cos(a)
		var si: float = SimDetMath.sin(a)
		qx = p[0] * co + t[0] * si
		qy = p[1] * co + t[1] * si
		qz = p[2] * co + t[2] * si
	surfAt(P, qx, qy, qz)
	var h: float = P.outH
	var b: int = P.outB
	if b >= BIO_PLAINS and b <= BIO_MOUNTAINS:
		h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp
	elif b == BIO_ICE_SHEET and h > 100.0:
		h += (_fbm(P.R, qx, qy, qz, c.detailScale, int(c.detailOct), P.seed + int(c.sDetail)) - 0.5) * c.detailAmp * c.detailSheet
	return [h, b]


## The slice of an explicit ring''')


rw(R, 'sim/world/planet.gd', planet)
print('farColumn applied')
