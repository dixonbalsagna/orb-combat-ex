extends RefCounted
# World, paper-only prototype: a stored procedural planet, a great-circle slice, costs. Scratch, not the tree.
# Our own deterministic pieces only: SimRng.imul/fmix32 for the lattice hash, SimDetMath.sin/cos, sqrt (IEEE exact).

const L: float = 153600.0
const R: float = L / (2.0 * PI)
var seed: int = 7
var biome_names: Array = ["ocean", "plains", "forest", "desert", "mountains", "ice sheet", "sea ice"]


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


func ss(a: float) -> float:
	var t: float = clampf(a, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Cellular noise on the sphere: the nearest jittered feature point among 27 cells; returns Vector2(distance in cells, that cell's random 0..1).
func worley(p: Vector3, cell: float, s: int) -> Vector2:
	var k: float = R / cell
	var qx: float = p.x * k
	var qy: float = p.y * k
	var qz: float = p.z * k
	var ix: int = int(floor(qx))
	var iy: int = int(floor(qy))
	var iz: int = int(floor(qz))
	var best: float = 1.0e9
	var br: float = 0.0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				var cx: int = ix + dx
				var cy: int = iy + dy
				var cz: int = iz + dz
				var fx: float = float(cx) + lat(cx, cy, cz, s)
				var fy: float = float(cy) + lat(cx, cy, cz, s + 11)
				var fz: float = float(cz) + lat(cx, cy, cz, s + 23)
				var d: float = sqrt((fx - qx) * (fx - qx) + (fy - qy) * (fy - qy) + (fz - qz) * (fz - qz))
				if d < best:
					best = d
					br = lat(cx, cy, cz, s + 37)
	return Vector2(best, br)


func ground(p: Vector3) -> float:
	var c: float = fbm(p, 30000.0, 4, seed)            # continents
	var m: float = fbm(p, 9000.0, 3, seed + 5000)      # relief
	var e: float = (c - 0.5) * 2.0
	var h: float = (e + 0.15) * 1300.0
	if e > 0.12:
		h += (e - 0.12) * 16000.0 * (0.35 + m)         # ranges on the high land
	return h


const ICE_SHEET: int = 5
const SEA_ICE: int = 6
const POLAR_Y: float = 0.72


## Surface at p: [height, biome], biome -1 meaning "the ordinary rule by height". Ice is a function of latitude (the y of the point), the sea
## (open water is below zero) and noise; no tables. North: no land, pack ice broken into floes that thin and part toward the edge, bergs beyond it.
## South: a continent under an ice sheet (a dome, rock peaks through it), a flat ice shelf at its coast, an ocean ring with bergs.
func surf(p: Vector3) -> Array:
	var y: float = p.y
	if absf(y) < POLAR_Y:
		return [ground(p), -1]
	var base: float = ground(p)
	if y > 0:
		var wN: float = ss((y - POLAR_Y) / 0.10)
		var sea: float = -380.0 + (fbm(p, 7000.0, 2, seed + 61) - 0.5) * 60.0
		var conc: float = (y - 0.88) / 0.10 + (fbm(p, 14000.0, 3, seed + 31) - 0.5) * 0.5   # 0 at the pack's edge, about 1.2 at the pole
		if conc > -0.05:
			var w: Vector2 = worley(p, 2200.0, seed + 71)
			var cc: float = clampf(conc, 0.0, 1.0)
			if w.y < pow(cc, 0.8) * 1.05 and w.x < 0.28 + 0.42 * cc:
				return [(10.0 + 28.0 * w.y) * (0.4 + 0.6 * cc), SEA_ICE]   # a floe: thinner toward the edge
		if conc > -0.3 and conc < 0.5:
			var b: Vector2 = worley(p, 1100.0, seed + 83)
			var rate: float = 0.12 * (1.0 - clampf(absf(conc - 0.1) * 1.6, 0.0, 1.0))
			if b.y < rate and b.x < 0.26:
				return [45.0 + 170.0 * (b.y / maxf(rate, 0.001)), SEA_ICE]   # an iceberg, 45 to 215 units
		return [lerpf(base, sea, wN), 0 if wN >= 1.0 else -1]
	var ys: float = -y
	var wS: float = ss((ys - POLAR_Y) / 0.10)
	var seaS: float = -330.0 + (fbm(p, 7000.0, 2, seed + 61) - 0.5) * 60.0
	var m: float = (ys - 0.91) / 0.07 + (fbm(p, 9000.0, 3, seed + 37) - 0.5) * 1.4
	if m > 0.0:
		var h: float = 180.0 + minf(m, 1.4) * 1500.0 + (fbm(p, 6000.0, 3, seed + 41) - 0.5) * 900.0
		if h > 1500.0 and fbm(p, 2500.0, 3, seed + 43) > 0.62:
			return [h, 4]                                                    # rock through the ice
		return [h, ICE_SHEET]
	if m > -0.55:
		return [36.0 + (fbm(p, 2500.0, 2, seed + 47) - 0.5) * 14.0, ICE_SHEET]   # the shelf: flat, floating, a cliff at its edge
	if m > -1.3:
		var b2: Vector2 = worley(p, 1100.0, seed + 83)
		if b2.y < 0.07 and b2.x < 0.26:
			return [45.0 + 170.0 * (b2.y / 0.07), SEA_ICE]
	return [lerpf(base, seaS, wS), 0 if wS >= 1.0 else -1]


func elev(p: Vector3) -> float:
	return surf(p)[0]


func biome(p: Vector3, h: float) -> int:
	var sv: Array = surf(p) if absf(p.y) >= POLAR_Y else [h, -1]
	if int(sv[1]) >= 0:
		return int(sv[1])
	return plain_biome(p, h)


func plain_biome(p: Vector3, h: float) -> int:
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


