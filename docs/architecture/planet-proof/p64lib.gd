extends RefCounted
# Scratch (Simulation): World's planet function under the sim's rules (float64 scalars, SimDetMath, SimRng.imul), the
# same expressions in the same order as planet.mjs, and World's prototype as it is (planet_lib.gd: Vector3, which is
# float32 in a standard Godot build). Writes gd64.txt and gdv3.txt in the folder given, one line a point as planet.mjs.
# Usage: godot --headless --path <export> --script res://zplanet/planet64.gd -- <out dir>
const L: float = 153600.0
const R: float = L / (2.0 * PI)
const SEED: int = 7


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


func fbm(px: float, py: float, pz: float, scale: float, oct: int, s: int) -> float:
	var sum: float = 0.0
	var amp: float = 0.5
	var tot: float = 0.0
	var k: float = R / scale
	for o in range(oct):
		sum += amp * vn(px * k, py * k, pz * k, s + o * 101)
		tot += amp
		amp *= 0.5
		k *= 2.0
	return sum / tot


func elev(px: float, py: float, pz: float) -> float:
	var c: float = fbm(px, py, pz, 30000.0, 4, SEED)
	var m: float = fbm(px, py, pz, 9000.0, 3, SEED + 5000)
	var e: float = (c - 0.5) * 2.0
	var h: float = (e + 0.15) * 1300.0
	if e > 0.12:
		h += (e - 0.12) * 16000.0 * (0.35 + m)
	return h


func biome(px: float, py: float, pz: float, h: float) -> int:
	if h < 0.0:
		return 0
	if h > 3200.0:
		return 4
	var w: float = fbm(px, py, pz, 20000.0, 3, SEED + 9000)
	var t: float = 1.0 - absf(py) * 0.8 + (fbm(px, py, pz, 12000.0, 2, SEED + 13000) - 0.5) * 0.5
	if w < 0.42 and t > 0.45:
		return 3
	if w > 0.55:
		return 2
	return 1


func rnd(k: int) -> float:
	return float(fm(fm(k) ^ 0x5bd1e995)) / 4294967296.0


func unit(a: float, b: float) -> Array:
	var z: float = -1.0 + 2.0 * a
	var ang: float = 2.0 * PI * b
	var q: float = sqrt(1.0 - z * z)
	return [q * SimDetMath.cos(ang), z, q * SimDetMath.sin(ang)]


func circle(j: int) -> Dictionary:
	var T: Array = unit(rnd(4 * j), rnd(4 * j + 1))
	var C: Array = unit(rnd(4 * j + 2), rnd(4 * j + 3))
	var nx: float = T[1] * C[2] - T[2] * C[1]
	var ny: float = T[2] * C[0] - T[0] * C[2]
	var nz: float = T[0] * C[1] - T[1] * C[0]
	var len: float = sqrt(nx * nx + ny * ny + nz * nz)
	nx = nx / len
	ny = ny / len
	nz = nz / len
	var v: Array = [ny * T[2] - nz * T[1], nz * T[0] - nx * T[2], nx * T[1] - ny * T[0]]
	return {"u": T, "v": v, "T": T, "C": C}


func point(c: Dictionary, i: int) -> Array:
	var ang: float = (32.0 * float(i)) / R
	var co: float = SimDetMath.cos(ang)
	var si: float = SimDetMath.sin(ang)
	return [c.u[0] * co + c.v[0] * si, c.u[1] * co + c.v[1] * si, c.u[2] * co + c.v[2] * si]


func hx(x: float) -> String:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_double(0, x)
	return b.hex_encode()
