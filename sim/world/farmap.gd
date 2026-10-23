class_name WorldFarMap
extends RefCounted
## A cached height-and-biome map of one planet, for a renderer's far land (window 2's slow drift and the far land at a turn). Render-only: nothing in the sim reads it, and it holds no state of the sim's.
##
## The surface (WorldPlanet.surfAt, without the surface detail: the fine noise a hazed far land cannot show) is read once at the texels of an octahedral map, n x n of them (about 1.4 degrees a texel at 256:
## 65,000 reads, a second or so native, so it is built a few hundred texels a frame: step(count), done), and any far field is then a bilinear lookup of the heights and the nearest texel's biome,
## about a tenth of the exact read. An octahedral map has no pole and no seam to special-case (a direction q is q / (|qx| + |qy| + |qz|), folded when its y is below zero), and its texels are within a
## factor of two of equal area. The planet's y is the map's axis. A pure function of the planet and n: the same map every time.
##
##   var m := WorldFarMap.new(P)            P = WorldPlanet.make(seed); n = 256 by default
##   m.step(400)                            each frame until m.done
##   m.field(ring, c0, ncols, stride, depths)   the same block of ground WorldPlanet.farField returns ({"h", "b"}, index di * ncols + ci), read from the map
##   m.height(qx, qy, qz), m.biome(qx, qy, qz) one point (a unit vector)

var P: WorldPlanet.Planet
var n: int = 256
var hs := PackedFloat32Array()
var bs := PackedByteArray()
var next: int = 0
var done: bool = false
var sites := PackedByteArray()   # the settlements' layer, whole from the start: 0 none, 1 a town's ground, 2 a city's (each place's own radius, WorldPlanet's), as the map's texels see it


func _init(p: WorldPlanet.Planet, size: int = 256) -> void:
	P = p
	n = size
	hs.resize(n * n)
	bs.resize(n * n)
	sites.resize(n * n)
	sites.fill(0)
	_mark_sites()


## The settlements' layer: every texel whose centre lies within a place's radius of its centre (and the texel that holds the centre, however small the place) is its kind's; a city over a town.
## About 1.4 degrees (600 units) a texel at 256 against radii of 2,400 (a town) and 6,500 (a city) units.
func _mark_sites() -> void:
	var inv: float = 1.0 / float(n)
	for k in range(P.n):
		var kind: int = 2 if int(P.kind[k]) == WorldPlanet.KIND_CITY else 1
		var rad: float = float(P.rad[k])
		var cx: float = P.px[k]
		var cy: float = P.py[k]
		var cz: float = P.pz[k]
		var t: Vector2 = _uv(cx, cy, cz)
		var ci: int = int(floor(t.x + 0.5))
		var cj: int = int(floor(t.y + 0.5))
		var w: int = int(ceil(rad / (P.R * 1.77 * inv))) + 1   # a texel is at most about twice its mean angle (3.54 / n radians) across
		var chord: float = rad / P.R
		for j in range(maxi(0, cj - w), mini(n, cj + w + 1)):
			for i in range(maxi(0, ci - w), mini(n, ci + w + 1)):
				var d: Array = decode((float(i) + 0.5) * inv, (float(j) + 0.5) * inv)
				var dx: float = d[0] - cx
				var dy: float = d[1] - cy
				var dz: float = d[2] - cz
				if sqrt(dx * dx + dy * dy + dz * dz) <= chord:
					sites[j * n + i] = maxi(int(sites[j * n + i]), kind)
		if ci >= 0 and ci < n and cj >= 0 and cj < n:
			sites[cj * n + ci] = maxi(int(sites[cj * n + ci]), kind)


## The places beside a ring (WorldPlanet.farPlaces) within `maxLateral` units, for drawing a distant town or city where it stands.
func places(ring: Dictionary, maxLateral: float = 1.0e18) -> Array:
	return WorldPlanet.farPlaces(P, ring, maxLateral)


## The settlement under a unit vector: 0 none, 1 a town's ground, 2 a city's (the nearest texel's, as biome()).
func site(qx: float, qy: float, qz: float) -> int:
	var t: Vector2 = _uv(qx, qy, qz)
	return sites[_tex(int(floor(t.x + 0.5)), int(floor(t.y + 0.5)))]


## Read `count` more texels; true when the map is whole.
func step(count: int) -> bool:
	if done:
		return true
	var total: int = n * n
	var last: int = mini(total, next + count)
	var inv: float = 1.0 / float(n)
	for k in range(next, last):
		var d: Array = decode((float(k % n) + 0.5) * inv, (float(k / n) + 0.5) * inv)
		WorldPlanet.surfAt(P, d[0], d[1], d[2])
		hs[k] = P.outH
		bs[k] = P.outB
	next = last
	done = next >= total
	return done


## The unit vector at map coordinates (u, v) in [0, 1]: the octahedral decode about the y axis.
static func decode(u: float, v: float) -> Array:
	var fx: float = u * 2.0 - 1.0
	var fz: float = v * 2.0 - 1.0
	var fy: float = 1.0 - absf(fx) - absf(fz)
	if fy < 0.0:
		var ox: float = (1.0 - absf(fz)) * (1.0 if fx >= 0.0 else -1.0)
		var oz: float = (1.0 - absf(fx)) * (1.0 if fz >= 0.0 else -1.0)
		fx = ox
		fz = oz
	var l: float = sqrt(fx * fx + fy * fy + fz * fz)
	return [fx / l, fy / l, fz / l]


## The texel index at integer coordinates, mirrored across the map's edge (the octahedral map's border folds onto itself).
func _tex(i: int, j: int) -> int:
	if i < 0:
		i = 0
		j = n - 1 - j
	elif i >= n:
		i = n - 1
		j = n - 1 - j
	if j < 0:
		j = 0
		i = n - 1 - i
	elif j >= n:
		j = n - 1
		i = n - 1 - i
	return clampi(j, 0, n - 1) * n + clampi(i, 0, n - 1)


## Map coordinates, in texels, of a unit vector.
func _uv(qx: float, qy: float, qz: float) -> Vector2:
	var l: float = absf(qx) + absf(qy) + absf(qz)
	var px: float = qx / l
	var pz: float = qz / l
	if qy < 0.0:
		var ox: float = (1.0 - absf(pz)) * (1.0 if px >= 0.0 else -1.0)
		var oz: float = (1.0 - absf(px)) * (1.0 if pz >= 0.0 else -1.0)
		px = ox
		pz = oz
	return Vector2((px * 0.5 + 0.5) * float(n) - 0.5, (pz * 0.5 + 0.5) * float(n) - 0.5)


func height(qx: float, qy: float, qz: float) -> float:
	var t: Vector2 = _uv(qx, qy, qz)
	var i0: int = int(floor(t.x))
	var j0: int = int(floor(t.y))
	var fx: float = t.x - float(i0)
	var fz: float = t.y - float(j0)
	var a: float = hs[_tex(i0, j0)]
	var b: float = hs[_tex(i0 + 1, j0)]
	var c: float = hs[_tex(i0, j0 + 1)]
	var d: float = hs[_tex(i0 + 1, j0 + 1)]
	return (a + (b - a) * fx) + ((c + (d - c) * fx) - (a + (b - a) * fx)) * fz


func biome(qx: float, qy: float, qz: float) -> int:
	var t: Vector2 = _uv(qx, qy, qz)
	return bs[_tex(int(floor(t.x + 0.5)), int(floor(t.y + 0.5)))]


## WorldPlanet.farField's block of ground, read from the map (and "s", the settlement under each sample: 0 none, 1 town, 2 city): the height and biome at `ncols` columns of the ring from column c0 every `stride`, each moved sideways by each of `depths`. Index di * ncols + ci.
func field(ring: Dictionary, c0: int, ncols: int, stride: int, depths: PackedFloat64Array) -> Dictionary:
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
		var p: Array = WorldPlanet.columnPoint(P, ring, c0 + ci * stride)
		px[ci] = p[0]
		py[ci] = p[1]
		pz[ci] = p[2]
		var d: float = m[0] * p[0] + m[1] * p[1] + m[2] * p[2]
		var t: Array = WorldPlanet._unit([m[0] - p[0] * d, m[1] - p[1] * d, m[2] - p[2] * d])
		tx[ci] = t[0]
		ty[ci] = t[1]
		tz[ci] = t[2]
	var hout := PackedFloat64Array()
	var bout := PackedByteArray()
	var sout := PackedByteArray()
	hout.resize(ncols * depths.size())
	bout.resize(ncols * depths.size())
	sout.resize(ncols * depths.size())
	for di in range(depths.size()):
		var z: float = depths[di]
		var co: float = 1.0
		var si: float = 0.0
		if z != 0.0:
			var a: float = z / P.R
			co = SimDetMath.cos(a)
			si = SimDetMath.sin(a)
		for ci in range(ncols):
			var qx: float = px[ci] * co + tx[ci] * si
			var qy: float = py[ci] * co + ty[ci] * si
			var qz: float = pz[ci] * co + tz[ci] * si
			hout[di * ncols + ci] = height(qx, qy, qz)
			bout[di * ncols + ci] = biome(qx, qy, qz)
			sout[di * ncols + ci] = site(qx, qy, qz)
	return {"h": hout, "b": bout, "s": sout}
