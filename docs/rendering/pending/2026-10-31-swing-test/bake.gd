extends SceneTree
# SCRATCH (docs/world/ring-any-angle/rendering.md, section 6): planet 7's ground as cube-sphere tiles for the swing test, in res://swing/.
# Levels: width 38,400 / 2^L along a face. L0, L1 the whole planet; L2 to L4 along the flight. L4's even vertices are L3's nodes; its odd ones are
# their mean plus a small deterministic detail, which is what near ground at 150 units would be.
const N: int = 33
const R: float = 153600.0 / (2.0 * PI)
const FACES: Array = [
	[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
	[Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
	[Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)],
	[Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
	[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
	[Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0)],
]
var P
var reads: int = 0
var hs := PackedFloat32Array()
var cs := PackedByteArray()
var table: Array = []
var pal: Dictionary = {}
var craters: Array = []


static func dir_of(f: int, L: int, i: int, j: int, a: float, b: float) -> Vector3:
	var size: float = 2.0 / float(1 << L)
	var s: float = -1.0 + (float(i) + a) * size
	var t: float = -1.0 + (float(j) + b) * size
	var fc: Array = FACES[f]
	return ((fc[0] as Vector3) + (fc[1] as Vector3) * tan(s * PI / 4.0) + (fc[2] as Vector3) * tan(t * PI / 4.0)).normalized()


func read(d: Vector3) -> Array:
	reads += 1
	WorldPlanet.surfAt(P, d.x, d.y, d.z)
	return [float(P.outH), int(P.outB)]


func col_of(h: float, b: int) -> Color:
	if h < 0.0:
		return Color("#3f7fb5").lerp(Color("#1f5a94"), clampf(-h / 300.0, 0.0, 1.0))
	var name: String = WorldPlanetWorld.BIOME_NAME[clampi(b, 0, WorldPlanetWorld.BIOME_NAME.size() - 1)]
	return RenderLook.col(RenderLook.BIOME.get(name, RenderLook.BIOME["plains"]))


func hash01(d: Vector3) -> float:
	var v: float = sin(d.x * 91234.5 + d.y * 45678.9 + d.z * 7123.4) * 43758.5453
	return v - floor(v)


func crater_at(d: Vector3) -> float:
	var s: float = 0.0
	for c in craters:
		var u: float = atan2(d.cross(c[0]).length(), d.dot(c[0])) * R / float(c[1])
		if u < 1.0:
			s -= float(c[2]) * pow(1.0 - u * u, 2.0)
		elif u < 1.3:
			s += float(c[2]) * 0.12 * (1.3 - u) / 0.3
	return s


func tile(f: int, L: int, i: int, j: int, parent: PackedFloat32Array = PackedFloat32Array(), corner: Vector2i = Vector2i.ZERO) -> Array:
	var h := PackedFloat32Array()
	h.resize(N * N)
	var c := PackedByteArray()
	c.resize(N * N * 4)
	for b in range(N):
		for a in range(N):
			var d: Vector3 = dir_of(f, L, i, j, float(a) / float(N - 1), float(b) / float(N - 1))
			var v: float
			var bi: int = 1
			if parent.is_empty():
				var r: Array = read(d)
				v = float(r[0])
				bi = int(r[1])
			else:
				var pa: float = float(corner.x) * 16.0 + float(a) * 0.5
				var pb: float = float(corner.y) * 16.0 + float(b) * 0.5
				var a0: int = int(floor(pa))
				var b0: int = int(floor(pb))
				var a1: int = mini(a0 + 1, N - 1)
				var b1: int = mini(b0 + 1, N - 1)
				var ua: float = pa - float(a0)
				var ub: float = pb - float(b0)
				v = lerpf(lerpf(parent[b0 * N + a0], parent[b0 * N + a1], ua), lerpf(parent[b1 * N + a0], parent[b1 * N + a1], ua), ub)
				if a % 2 == 1 or b % 2 == 1:
					v += (hash01(d) - 0.5) * 10.0 * (1.0 if v > 0.0 else 0.0)
				bi = -1
			var hh: float = v + (0.0 if v < 0.0 or not parent.is_empty() else crater_at(d))   # L4's nodes already hold it
			h[b * N + a] = hh
			var col: Color = col_of(hh, bi if bi >= 0 else _nearest_biome(d))
			var dent: float = crater_at(d)
			if dent < -6.0:
				col = col.lerp(Color("#5c4a3a"), clampf(-dent / 60.0, 0.3, 0.85))
			var k: int = (b * N + a) * 4
			c[k] = col.r8
			c[k + 1] = col.g8
			c[k + 2] = col.b8
			c[k + 3] = 255
	hs.append_array(h)
	cs.append_array(c)
	index["%d/%d/%d/%d" % [f, L, i, j]] = table.size()
	table.append([f, L, i, j])
	return [h]


func _nearest_biome(d: Vector3) -> int:
	var r: Array = read_free(d)
	return int(r[1])


func read_free(d: Vector3) -> Array:
	WorldPlanet.surfAt(P, d.x, d.y, d.z)
	return [float(P.outH), int(P.outB)]


## The ground as the mesh draws it at the finest level there: the same nodes and the same two triangles a quad. Feet and the sim read this.
func mesh_h(d: Vector3, from_level: int = 4) -> float:
	var ad := Vector3(absf(d.x), absf(d.y), absf(d.z))
	var f: int = (0 if d.x > 0.0 else 1) if ad.x >= ad.y and ad.x >= ad.z else ((2 if d.y > 0.0 else 3) if ad.y >= ad.z else (4 if d.z > 0.0 else 5))
	var fc: Array = FACES[f]
	var w: float = (fc[0] as Vector3).dot(d)
	var s: float = atan((fc[1] as Vector3).dot(d) / w) / (PI / 4.0)
	var t: float = atan((fc[2] as Vector3).dot(d) / w) / (PI / 4.0)
	for L in [4, 3, 2, 1, 0]:
		if L > from_level:
			continue
		var n: int = 1 << L
		var i: int = clampi(int((s + 1.0) * 0.5 * float(n)), 0, n - 1)
		var j: int = clampi(int((t + 1.0) * 0.5 * float(n)), 0, n - 1)
		var key: String = "%d/%d/%d/%d" % [f, L, i, j]
		if index.has(key):
			var o: int = int(index[key]) * N * N
			var fa: float = ((s + 1.0) * 0.5 * float(n) - float(i)) * 32.0
			var fb: float = ((t + 1.0) * 0.5 * float(n) - float(j)) * 32.0
			var a0: int = mini(int(fa), 31)
			var b0: int = mini(int(fb), 31)
			var u: float = fa - float(a0)
			var v: float = fb - float(b0)
			var h00: float = maxf(hs[o + b0 * N + a0], 0.0)
			var h10: float = maxf(hs[o + b0 * N + a0 + 1], 0.0)
			var h01: float = maxf(hs[o + (b0 + 1) * N + a0], 0.0)
			var h11: float = maxf(hs[o + (b0 + 1) * N + a0 + 1], 0.0)
			if u + v <= 1.0:
				return h00 + (h10 - h00) * u + (h01 - h00) * v
			return h11 + (h01 - h11) * (1.0 - u) + (h10 - h11) * (1.0 - v)
	return 0.0


var index: Dictionary = {}


func vnoise(p: Vector3) -> float:
	var i: Vector3 = p.floor()
	var q: Vector3 = p - i
	q = q * q * (Vector3.ONE * 3.0 - q * 2.0)
	var s: float = 0.0
	for k in range(8):
		var c: Vector3 = i + Vector3(float(k & 1), float((k >> 1) & 1), float((k >> 2) & 1))
		var v: float = sin(c.x * 127.1 + c.y * 311.7 + c.z * 74.7) * 43758.5453
		v -= floor(v)
		var w: float = (q.x if k & 1 else 1.0 - q.x) * (q.y if (k >> 1) & 1 else 1.0 - q.y) * (q.z if (k >> 2) & 1 else 1.0 - q.z)
		s += v * w
	return s - 0.5


## The pure detail term: a function of the planet direction alone, so the sim and the view can both run it. Its size follows the ground's own roughness at the coarse nodes.
func detail(d: Vector3, rough: float) -> float:
	var p: Vector3 = d * R
	return (vnoise(p / 340.0) * 1.0 + vnoise(p / 150.0) * 0.45 + vnoise(p / 70.0) * 0.18) * clampf(rough * 0.5, 10.0, 90.0)


## L2 to L4 again, from L1's nodes only, plus the term. Colours from the same canonical nodes.
func _coarse_set(src: PackedFloat32Array, srcc: PackedByteArray, coast: bool) -> void:
	hs = src.duplicate()
	cs = srcc.duplicate()
	for k in index:
		var e: PackedStringArray = (k as String).split("/")
		var L: int = int(e[1])
		if L < 2:
			continue
		var fi: int = int(e[0])
		var ii: int = int(e[2])
		var jj: int = int(e[3])
		var sh: int = L - 1
		var pi_: int = ii >> sh
		var pj: int = jj >> sh
		var pk: String = "%d/1/%d/%d" % [fi, pi_, pj]
		var op: int = int(index[pk]) * N * N
		var o: int = int(index[k]) * N * N
		var span: float = 32.0 / float(1 << sh)
		for b in range(N):
			for a in range(N):
				var fa: float = (float(ii - (pi_ << sh)) + float(a) / 32.0) * span
				var fb: float = (float(jj - (pj << sh)) + float(b) / 32.0) * span
				var a0: int = mini(int(fa), 31)
				var b0: int = mini(int(fb), 31)
				var u: float = fa - float(a0)
				var v: float = fb - float(b0)
				var h00: float = src[op + b0 * N + a0]
				var h10: float = src[op + b0 * N + a0 + 1]
				var h01: float = src[op + (b0 + 1) * N + a0]
				var h11: float = src[op + (b0 + 1) * N + a0 + 1]
				var d: Vector3 = dir_of(fi, L, ii, jj, float(a) / 32.0, float(b) / 32.0)
				var base: float = lerpf(lerpf(h00, h10, u), lerpf(h01, h11, u), v)
				var rough: float = maxf(maxf(h00, h10), maxf(h01, h11)) - minf(minf(h00, h10), minf(h01, h11))
				var win: float = pow(sin(u * PI) * sin(v * PI), 0.5) if u > 0.0 and v > 0.0 else 0.0
				var land: float = clampf(base / 30.0, 0.0, 1.0)
				var h: float = base + (0.0 if base < 0.0 else crater_at(d) * (1.0 if u > 0.0 or v > 0.0 else 0.0))
				var wet_exact: bool = src[o + b * N + a] < 0.0
				if coast:
					h = minf(h, -8.0) if wet_exact else maxf(h, 2.0)
				hs[o + b * N + a] = h
				var oc: int = (op + (b0 if v < 0.5 else b0 + 1) * N + (a0 if u < 0.5 else a0 + 1)) * 4
				var dent: float = crater_at(d)
				var col := Color8(srcc[oc], srcc[oc + 1], srcc[oc + 2])
				if h < 0.0 or (coast and wet_exact):
					col = col_of(minf(h, -1.0), 0)
				elif base >= 0.0 and col.b > col.g:
					col = col_of(h, 1)
				if dent < -6.0:
					col = col.lerp(Color("#5c4a3a"), clampf(-dent / 60.0, 0.3, 0.85))
				var ci: int = (o + b * N + a) * 4
				cs[ci] = col.r8
				cs[ci + 1] = col.g8
				cs[ci + 2] = col.b8


func _initialize() -> void:
	WorldClimate.useGen(2)
	P = WorldPlanet.make(7)
	# A place with buildings on it to fight beside: the largest city on the planet, else the largest town.
	var best: int = -1
	for i in range(P.n):
		if int(P.kind[i]) == WorldPlanet.KIND_CITY and (best < 0 or float(P.rad[i]) > float(P.rad[best])):
			best = i
	if best < 0:
		best = 0
	var city := Vector3(P.px[best], P.py[best], P.pz[best]).normalized()
	var e0: Vector3 = city.cross(Vector3(0.3, 1.0, 0.2)).normalized()
	var n0: Vector3 = city.cross(e0).normalized()
	var pivot: Vector3 = (city + n0 * (2300.0 / R)).normalized()
	var heading: Vector3 = pivot.cross(pivot.cross(e0)).normalized() * -1.0
	var side: Vector3 = heading.cross(pivot).normalized()
	craters = [[(pivot + heading * (900.0 / R) + side * (-400.0 / R)).normalized(), 420.0, 90.0]]
	var path: Array = []
	for k in range(0, 8):
		var ang: float = float(k) * 3000.0 / R
		path.append((pivot * cos(ang) + heading * sin(ang)).normalized())
	var t0: int = Time.get_ticks_msec()
	var near: Dictionary = {}
	for f in range(6):
		for L in range(0, 5):
			var n: int = 1 << L
			var w: float = 38400.0 / float(n)
			var reach: float = INF if L <= 1 else (40000.0 if L == 2 else (20000.0 if L == 3 else 11000.0))
			for j in range(n):
				for i in range(n):
					if reach < INF:
						var c: Vector3 = dir_of(f, L, i, j, 0.5, 0.5)
						var d: float = INF
						for q in path:
							d = minf(d, atan2(c.cross(q).length(), c.dot(q)) * R)
						if d > reach + w:
							continue
					if L == 4:
						var pk: String = "%d/%d/%d" % [f, i / 2, j / 2]
						if not near.has(pk):
							continue
						tile(f, L, i, j, near[pk], Vector2i(i % 2, j % 2))
					else:
						var r: Array = tile(f, L, i, j)
						if L == 3:
							near["%d/%d/%d" % [f, i, j]] = r[0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# The buildings: blocks on a street grid round the city's middle, tall in the middle, none on the fight's own patch.
	var blds: Array = []
	var crowd: Array = []
	var cell: float = 860.0
	for gx in range(-7, 8):
		for gz in range(-7, 8):
			var ox: float = float(gx) * cell + rng.randf_range(-40.0, 40.0)
			var oz: float = float(gz) * cell + rng.randf_range(-40.0, 40.0)
			var rr: float = sqrt(ox * ox + oz * oz)
			if rr > 5600.0 or rng.randf() < 0.3:
				continue
			var a: Vector3 = (city + (e0 * ox + n0 * oz) / R).normalized()
			if atan2(a.cross(pivot).length(), a.dot(pivot)) * R < 760.0:
				continue
			var g: float = mesh_h(a)
			if g < 2.0:
				continue
			var tall: float = lerpf(2600.0, 260.0, clampf(rr / 5000.0, 0.0, 1.0)) * rng.randf_range(0.55, 1.15)
			var east: Vector3 = (e0 - a * a.dot(e0)).normalized()
			blds.append({"a": [a.x, a.y, a.z], "e": [east.x, east.y, east.z], "w": rng.randf_range(280.0, 430.0), "d": rng.randf_range(280.0, 430.0), "h": tall, "g": g, "s": rng.randf(), "dmg": 0.0})
			for q in range(rng.randi_range(2, 6)):
				var fx: float = ox + rng.randf_range(-260.0, 260.0)
				var fz: float = oz + 250.0
				var fa: Vector3 = (city + (e0 * fx + n0 * fz) / R).normalized()
				crowd.append({"a": [fa.x, fa.y, fa.z], "e": [east.x, east.y, east.z], "g": mesh_h(fa), "c": [rng.randf(), rng.randf(), rng.randf(), rng.randf()]})
	# The damaged tower: the tallest within 2,600 of the fight.
	var dmg: int = -1
	for bi in range(blds.size()):
		var av: Array = blds[bi].a
		var a: Vector3 = Vector3(av[0], av[1], av[2])
		if atan2(a.cross(pivot).length(), a.dot(pivot)) * R < 2600.0 and (dmg < 0 or float(blds[bi].h) > float(blds[dmg].h)):
			dmg = bi
	if dmg >= 0:
		blds[dmg].dmg = 1.0
	var pv: float = mesh_h(pivot)
	# The levels agree where they meet: a child's even nodes against its parent's. (A crack can only come from a difference here.)
	var worst: float = 0.0
	var pairs: int = 0
	for k in index:
		var e: PackedStringArray = (k as String).split("/")
		var Lc: int = int(e[1])
		if Lc == 0:
			continue
		var fi: int = int(e[0])
		var ii: int = int(e[2])
		var jj: int = int(e[3])
		var pk: String = "%d/%d/%d/%d" % [fi, Lc - 1, ii / 2, jj / 2]
		if not index.has(pk):
			continue
		pairs += 1
		var oc: int = int(index[k]) * N * N
		var op: int = int(index[pk]) * N * N
		for b in range(0, N, 2):
			for a in range(0, N, 2):
				var pa: int = (ii % 2) * 16 + a / 2
				var pb: int = (jj % 2) * 16 + b / 2
				worst = maxf(worst, absf(hs[oc + b * N + a] - hs[op + pb * N + pa]))
	print("RES levels agree: %d child and parent pairs, largest height difference at a shared node %.4f" % [pairs, worst])
	var f := FileAccess.open("res://swing/h.bin", FileAccess.WRITE)
	f.store_buffer(hs.to_byte_array())
	f.close()
	f = FileAccess.open("res://swing/c.bin", FileAccess.WRITE)
	f.store_buffer(cs)
	f.close()
	# Line 3: a foot against the ground as drawn there. Level by distance from the pivot at rest; in a morph zone, the worse of the two. Pixels at 720 lines, from the camera at 2,600.
	var buckets: Dictionary = {1000: [0, 0.0, 0.0], 3000: [0, 0.0, 0.0], 6000: [0, 0.0, 0.0], 12000: [0, 0.0, 0.0]}
	for o in blds + crowd:
		var av: Array = o.a
		var ad: Vector3 = Vector3(av[0], av[1], av[2])
		var rr: float = atan2(ad.cross(pivot).length(), ad.dot(pivot)) * R
		var lv: int = 4
		var w: float = 2400.0
		while lv > 0 and rr > 1.4 * 1.6 * w:
			lv -= 1
			w *= 2.0
		var gap: float = absf(float(o.g) - mesh_h(ad, lv))
		if rr > 1.4 * 1.6 * w * 0.5 and lv < 4:
			gap = maxf(gap, absf(float(o.g) - mesh_h(ad, lv + 1)))
		for key in buckets:
			if rr <= float(key):
				var bk: Array = buckets[key]
				bk[0] += 1
				bk[1] = maxf(bk[1], gap)
				bk[2] = maxf(bk[2], gap * 720.0 / (2.0 * tan(deg_to_rad(15.0))) / maxf(2600.0 + rr * 0.5, 100.0))
				break
	print("RES feet to the drawn ground, by radius: %s (count, largest in units, largest in pixels)" % str(buckets))
	var fine_h: PackedFloat32Array = hs
	var fine_c: PackedByteArray = cs
	var g02: Array = [0.0, 0.0]
	for st in [1, 2]:
		_coarse_set(fine_h, fine_c, st == 2)
		for b0 in blds:
			var av: Array = b0.a
			b0["g%d" % (st + 1)] = mesh_h(Vector3(av[0], av[1], av[2]))
		for c0 in crowd:
			var av: Array = c0.a
			c0["g%d" % (st + 1)] = mesh_h(Vector3(av[0], av[1], av[2]))
		g02[st - 1] = mesh_h(pivot)
		f = FileAccess.open("res://swing/h%d.bin" % (st + 1), FileAccess.WRITE)
		f.store_buffer(hs.to_byte_array())
		f.close()
		f = FileAccess.open("res://swing/c%d.bin" % (st + 1), FileAccess.WRITE)
		f.store_buffer(cs)
		f.close()
	f = FileAccess.open("res://swing/world.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"tiles": table, "n": N, "R": R, "pivot": [pivot.x, pivot.y, pivot.z], "heading": [heading.x, heading.y, heading.z], "g0": pv, "g02": g02[0], "g03": g02[1], "blds": blds, "crowd": crowd}))
	f.close()
	print("RES tiles %d, reads %d, %.1f s, %.1f us a read; heights %.0f to %.0f; pivot ground %.0f; %d buildings, %d figures; damaged %d" % [table.size(), reads, float(Time.get_ticks_msec() - t0) / 1000.0, 0.0, Array(hs).min(), Array(hs).max(), pv, blds.size(), crowd.size(), dmg])
	quit(0)
