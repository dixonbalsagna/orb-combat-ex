extends RefCounted
# World, paper-only prototype: a stored procedural planet, a great-circle slice, costs. Scratch, not the tree.
# Our own deterministic pieces only: SimRng.imul/fmix32 for the lattice hash, SimDetMath.sin/cos, sqrt (IEEE exact).

const L: float = 153600.0
const R: float = L / (2.0 * PI)
var seed: int = 7
var biome_names: Array = ["ocean", "plains", "forest", "desert", "mountains"]


func fm(x: int) -> int:
	x &= 0xFFFFFFFF
	x ^= x >> 16
	x = SimRng.imul(x, 0x85ebca6b)
	x ^= x >> 13
	x = SimRng.imul(x, 0xc2b2ae35)
	x ^= x >> 16
	return x & 0xFFFFFFFF


func lat(ix: int, iy: int, iz: int, s: int) -> float:
	return float(fm(fm(fm(s ^ (ix & 0xFFFFFFFF)) ^ (iy & 0xFFFFFFFF)) ^ (iz & 0xFFFFFFFF))) / 4294967296.0


func vn(x: float, y: float, z: float, s: int) -> float:
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
	var c000: float = lat(ix, iy, iz, s)
	var c100: float = lat(ix + 1, iy, iz, s)
	var c010: float = lat(ix, iy + 1, iz, s)
	var c110: float = lat(ix + 1, iy + 1, iz, s)
	var c001: float = lat(ix, iy, iz + 1, s)
	var c101: float = lat(ix + 1, iy, iz + 1, s)
	var c011: float = lat(ix, iy + 1, iz + 1, s)
	var c111: float = lat(ix + 1, iy + 1, iz + 1, s)
	var a: float = c000 + (c100 - c000) * tx
	var b: float = c010 + (c110 - c010) * tx
	var c: float = c001 + (c101 - c001) * tx
	var d: float = c011 + (c111 - c011) * tx
	var e: float = a + (b - a) * ty
	var f: float = c + (d - c) * ty
	return e + (f - e) * tz


func fbm(p: Vector3, scale: float, oct: int, s: int) -> float:
	var sum: float = 0.0
	var amp: float = 0.5
	var tot: float = 0.0
	var k: float = R / scale
	for o in range(oct):
		sum += amp * vn(p.x * k, p.y * k, p.z * k, s + o * 101)
		tot += amp
		amp *= 0.5
		k *= 2.0
	return sum / tot


## The planet as a pure function of the unit vector: elevation (units), biome index.
func elev(p: Vector3) -> float:
	var c: float = fbm(p, 30000.0, 4, seed)            # continents
	var m: float = fbm(p, 9000.0, 3, seed + 5000)      # relief
	var e: float = (c - 0.5) * 2.0
	var h: float = (e + 0.15) * 1300.0
	if e > 0.12:
		h += (e - 0.12) * 16000.0 * (0.35 + m)         # ranges on the high land
	return h


func biome(p: Vector3, h: float) -> int:
	if h < 0.0:
		return 0
	if h > 3200.0:
		return 4
	var w: float = fbm(p, 20000.0, 3, seed + 9000)
	var t: float = 1.0 - absf(p.y) * 0.8 + (fbm(p, 12000.0, 2, seed + 13000) - 0.5) * 0.5
	if w < 0.42 and t > 0.45:
		return 3
	if w > 0.55:
		return 2
	return 1


func rot(u: Vector3, v: Vector3, a: float) -> Vector3:
	return u * SimDetMath.cos(a) + v * SimDetMath.sin(a)


func randunit(r: SimRng) -> Vector3:
	var z: float = r.range_(-1.0, 1.0)
	var a: float = r.range_(0.0, 2.0 * PI)
	var q: float = sqrt(1.0 - z * z)
	return Vector3(q * SimDetMath.cos(a), z, q * SimDetMath.sin(a))


func arc(a: Vector3, b: Vector3) -> float:
	var d: float = clampf(a.dot(b), -1.0, 1.0)
	return R * acos(d)


