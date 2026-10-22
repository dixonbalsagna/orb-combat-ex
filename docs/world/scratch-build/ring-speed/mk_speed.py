"""Ring-read speed (World, scratch): the exact planet read made cheaper.   python mk_speed.py <root>
 - WorldPlanet._vn: the 8 lattice corners of the cell last read at a noise (one slot per seed) are kept, so a column in the same cell as the one before reads no hash; a new cell hashes 14 times, not 24 (the shared
   parts of the corner hashes once). Pure memo outside the sim state: the same numbers, bit for bit."""
import sys
from mk_wbc_lib import rw, rep
R = sys.argv[1].rstrip('/') + '/'


def planet(s):
    i = s.index('static func _vn(x: float, y: float, z: float, s: int) -> float:')
    j = s.index('static func _fbm(')
    new = '''## The lattice corners of the cell last read at each noise (a slot a seed; the planet read walks a ring column by column, 32 units at a time, so most columns are in the cell of the one before): derived data
## outside the sim state, a pure memo of _lat, so the numbers are the hash's own.
static var _vcSlot: Dictionary = {}
static var _vcKey := PackedInt64Array()    # ix, iy, iz of each slot's cell
static var _vcVal := PackedFloat64Array()  # its 8 corners: c000 c100 c010 c110 c001 c101 c011 c111


static func _vcNew(s: int) -> int:
	if _vcSlot.size() >= 4096:
		_vcSlot.clear()
		_vcKey.resize(0)
		_vcVal.resize(0)
	var slot: int = _vcSlot.size()
	_vcSlot[s] = slot
	_vcKey.resize((slot + 1) * 3)
	_vcVal.resize((slot + 1) * 8)
	_vcKey[slot * 3] = -4611686018427387904   # no cell yet
	return slot


## The 8 corner values of the cell (ix, iy, iz): _lat of each corner, the hash of the shared prefixes done once (14 hashes, not 24).
static func _vcFill(slot: int, ix: int, iy: int, iz: int, s: int) -> void:
	var mx0: int = ix & MASK
	var mx1: int = (ix + 1) & MASK
	var my0: int = iy & MASK
	var my1: int = (iy + 1) & MASK
	var mz0: int = iz & MASK
	var mz1: int = (iz + 1) & MASK
	var a0: int = _fm(s ^ mx0)
	var a1: int = _fm(s ^ mx1)
	var b00: int = _fm(a0 ^ my0)
	var b10: int = _fm(a1 ^ my0)
	var b01: int = _fm(a0 ^ my1)
	var b11: int = _fm(a1 ^ my1)
	var vb: int = slot * 8
	_vcVal[vb] = float(_fm(b00 ^ mz0)) / 4294967296.0
	_vcVal[vb + 1] = float(_fm(b10 ^ mz0)) / 4294967296.0
	_vcVal[vb + 2] = float(_fm(b01 ^ mz0)) / 4294967296.0
	_vcVal[vb + 3] = float(_fm(b11 ^ mz0)) / 4294967296.0
	_vcVal[vb + 4] = float(_fm(b00 ^ mz1)) / 4294967296.0
	_vcVal[vb + 5] = float(_fm(b10 ^ mz1)) / 4294967296.0
	_vcVal[vb + 6] = float(_fm(b01 ^ mz1)) / 4294967296.0
	_vcVal[vb + 7] = float(_fm(b11 ^ mz1)) / 4294967296.0
	var kb: int = slot * 3
	_vcKey[kb] = ix
	_vcKey[kb + 1] = iy
	_vcKey[kb + 2] = iz


static func _vn(x: float, y: float, z: float, s: int) -> float:
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
	var slot: int = _vcSlot.get(s, -1)
	if slot < 0:
		slot = _vcNew(s)
	var kb: int = slot * 3
	if _vcKey[kb] != ix or _vcKey[kb + 1] != iy or _vcKey[kb + 2] != iz:
		_vcFill(slot, ix, iy, iz, s)
	var vb: int = slot * 8
	var c000: float = _vcVal[vb]
	var c100: float = _vcVal[vb + 1]
	var c010: float = _vcVal[vb + 2]
	var c110: float = _vcVal[vb + 3]
	var c001: float = _vcVal[vb + 4]
	var c101: float = _vcVal[vb + 5]
	var c011: float = _vcVal[vb + 6]
	var c111: float = _vcVal[vb + 7]
	var a: float = c000 + (c100 - c000) * tx
	var b: float = c010 + (c110 - c010) * tx
	var c: float = c001 + (c101 - c001) * tx
	var d: float = c011 + (c111 - c011) * tx
	var e: float = a + (b - a) * ty
	var f: float = c + (d - c) * ty
	return e + (f - e) * tz


'''
    return s[:i] + new + s[j:]


rw(R, 'sim/world/planet.gd', planet)
print('ring-read speed applied')
