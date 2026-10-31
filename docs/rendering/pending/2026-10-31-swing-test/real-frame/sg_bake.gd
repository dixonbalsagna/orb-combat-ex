extends SceneTree
# SCRATCH (rendering.md section 11): tiles round a real match's pair, for the real frame. Runs the game's own match headless, so the pivot, the heading and the city's ground are the
# game's. Ground inside the city's band is the strip's own (the plan World's places would give); outside it, the planet's. Args after --: <set name> <wanted biome>.
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
var main: Node
var P
var hs := PackedFloat32Array()
var cs := PackedByteArray()
var table: Array = []
var index: Dictionary = {}
var pivot: Vector3
var hd0: Vector3
var sd0: Vector3
var px: float
var band := Vector2.ZERO
var S: SimState
var pal: Dictionary = {}
var reads: int = 0


func _initialize() -> void:
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


static func dir_of(f: int, L: int, i: int, j: int, a: float, b: float) -> Vector3:
	var size: float = 2.0 / float(1 << L)
	var s: float = -1.0 + (float(i) + a) * size
	var t: float = -1.0 + (float(j) + b) * size
	var fc: Array = FACES[f]
	return ((fc[0] as Vector3) + (fc[1] as Vector3) * tan(s * PI / 4.0) + (fc[2] as Vector3) * tan(t * PI / 4.0)).normalized()


func chart(d: Vector3) -> Vector2:
	var x: float = d.dot(hd0)
	var z: float = d.dot(sd0)
	var s: float = sqrt(x * x + z * z)
	var k: float = atan2(s, d.dot(pivot)) / s if s > 1.0e-6 else 1.0
	return Vector2(x, z) * k * R


func pal_of(d: Vector3, h: float) -> int:
	reads += 1
	var bi: int = int(P.outB)
	var fi: int = int(P.outF)
	var name: String = WorldClimate.fineName(fi) if fi >= 0 else WorldPlanetWorld.BIOME_NAME[clampi(bi, 0, WorldPlanetWorld.BIOME_NAME.size() - 1)]
	if not pal.has(name):
		pal[name] = RenderBiomeLook.id_of(name)
	return int(pal[name])


## The node's height and palette: the planet's, the strip's own inside the city's band.
func node(d: Vector3) -> Array:
	WorldPlanet.surfAt(P, d.x, d.y, d.z)
	var h: float = float(P.outH)
	var pid: int = pal_of(d, h)
	var c: Vector2 = chart(d)
	if band.x > 0.0:
		var wx: float = 1.0 - smoothstep(band.x, band.x + 1500.0, absf(c.x))
		var wz: float = 1.0 - smoothstep(band.y, band.y + 1500.0, absf(c.y))
		var w: float = wx * wz
		if w > 0.0:
			var col: float = SimWrap.wrap(px + c.x) / SimConst.COL
			var i0: int = int(col) % SimConst.NC
			var i1: int = (i0 + 1) % SimConst.NC
			var sb: float = lerpf(S.base[i0], S.base[i1], col - floor(col))
			h = lerpf(h, sb, w)
			if w > 0.5:
				var ipc: int = i0
				var nm: String = WorldBiomes.fineNameAt((float(ipc) + 0.5) * SimConst.COL)
				if not pal.has(nm):
					pal[nm] = RenderBiomeLook.id_of(nm)
				pid = int(pal[nm])
	return [h, pid]


func tile(f: int, L: int, i: int, j: int, parent: PackedFloat32Array = PackedFloat32Array(), pc: PackedByteArray = PackedByteArray(), corner: Vector2i = Vector2i.ZERO) -> Array:
	var h := PackedFloat32Array()
	h.resize(N * N)
	var c := PackedByteArray()
	c.resize(N * N * 4)
	for b in range(N):
		for a in range(N):
			var v: float
			var id: int
			if parent.is_empty():
				var r: Array = node(dir_of(f, L, i, j, float(a) / 32.0, float(b) / 32.0))
				v = r[0]
				id = r[1]
			else:
				var pa: float = float(corner.x) * 16.0 + float(a) * 0.5
				var pb: float = float(corner.y) * 16.0 + float(b) * 0.5
				var a0: int = int(floor(pa))
				var b0: int = int(floor(pb))
				var a1: int = mini(a0 + 1, N - 1)
				var b1: int = mini(b0 + 1, N - 1)
				v = lerpf(lerpf(parent[b0 * N + a0], parent[b0 * N + a1], pa - float(a0)), lerpf(parent[b1 * N + a0], parent[b1 * N + a1], pa - float(a0)), pb - float(b0))
				id = pc[(int(pb + 0.5) * N + int(pa + 0.5)) * 4]
			h[b * N + a] = v
			c[(b * N + a) * 4] = id
			c[(b * N + a) * 4 + 3] = 255
	index["%d/%d/%d/%d" % [f, L, i, j]] = table.size()
	table.append([f, L, i, j])
	hs.append_array(h)
	cs.append_array(c)
	return [h, c]


func _run() -> void:
	await process_frame
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var set_name: String = args[0]
	var want: String = args[1]
	main.started = true
	main.start_match(12345, {"p1": false, "p2": false}, {"planet": 7, "touch": 3, "planetGen": 2, "intro": false})
	while main.host.loading():
		main.frame(1.0 / 60.0)
	S = main.host.S
	WorldClimate.useGen(2)
	P = WorldPlanet.make(7)
	# The pb scene's place: the middle of the longest stretch of the wanted ground.
	var pc: PackedByteArray = WorldBiomes.planetCols
	var nc: int = SimConst.NC
	var names: Array = WorldPlanetWorld.BIOME_NAME
	var best_len: int = 0
	var best_c: int = nc / 2
	var run: int = 0
	for i in range(nc):
		if str(names[pc[i]]) == want:
			run += 1
			if run > best_len:
				best_len = run
				best_c = i - run / 2
		else:
			run = 0
	px = (float(best_c) + 0.5) * SimConst.COL + 30.0
	var ring: Dictionary = WorldRingPick.ringFrom(S.planetRing.c, int(S.planetRing.cols), S.planetRing.t)
	var u: Vector3 = Vector3(ring.u[0], ring.u[1], ring.u[2])
	var v: Vector3 = Vector3(ring.v[0], ring.v[1], ring.v[2])
	var ca: Vector3 = Vector3(ring.c[0], ring.c[1], ring.c[2])
	var st: float = float(ring.st)
	var ct: float = float(ring.ct)
	var a0: float = (float(best_c) + 30.0 / SimConst.COL + 0.5 - float(WorldPlanet.touchCol())) * SimConst.COL / (R * st)
	pivot = (ca * ct + (u * cos(a0) + v * sin(a0)) * st).normalized()
	hd0 = (v * cos(a0) - u * sin(a0)).normalized()
	sd0 = -pivot.cross(hd0).normalized()
	# The band: this place's buildings, in strip terms.
	var far_x: float = 0.0
	var count: int = 0
	if want == "city" or want == "village":
		for b in S.buildings:
			var dx: float = absf(SimWrap.sdx(px, b.x))
			if dx < 9000.0:
				far_x = maxf(far_x, dx + b.w * 0.5)
				count += 1
		band = Vector2(far_x + 200.0, 3400.0)
	var near: Dictionary = {}
	var nearc: Dictionary = {}
	var t0: int = Time.get_ticks_msec()
	for f in range(6):
		for L in range(0, 5):
			var n: int = 1 << L
			var w: float = 38400.0 / float(n)
			var reach: float = INF if L <= 1 else (50000.0 if L == 2 else (26000.0 if L == 3 else 13000.0))
			for j in range(n):
				for i in range(n):
					if reach < INF:
						var c: Vector3 = dir_of(f, L, i, j, 0.5, 0.5)
						if atan2(c.cross(pivot).length(), c.dot(pivot)) * R > reach + w:
							continue
					if L == 4:
						var pk: String = "%d/%d/%d" % [f, i / 2, j / 2]
						if near.has(pk):
							tile(f, L, i, j, near[pk], nearc[pk], Vector2i(i % 2, j % 2))
					else:
						var r: Array = tile(f, L, i, j)
						if L == 3:
							var k3: String = "%d/%d/%d" % [f, i, j]
							near[k3] = r[0]
							nearc[k3] = r[1]
	var dir_path: String = "res://swing/%s" % set_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var fl := FileAccess.open(dir_path + "/h.bin", FileAccess.WRITE)
	fl.store_buffer(hs.to_byte_array())
	fl.close()
	fl = FileAccess.open(dir_path + "/c.bin", FileAccess.WRITE)
	fl.store_buffer(cs)
	fl.close()
	fl = FileAccess.open(dir_path + "/world.json", FileAccess.WRITE)
	fl.store_string(JSON.stringify({"tiles": table, "pivot": [pivot.x, pivot.y, pivot.z], "hd0": [hd0.x, hd0.y, hd0.z], "sd0": [sd0.x, sd0.y, sd0.z], "px": px, "band": [band.x, band.y], "want": want}))
	fl.close()
	var col_h: float = S.base[best_c]
	print("RES %s: stretch %d columns at %d, %d buildings in the band %s; tiles %d, nodes read %d, %.1f s; heights %.0f to %.0f; ground at the pivot in the sim %.1f, in the tiles %.1f" % [set_name, best_len, best_c, count, str(band), table.size(), reads, float(Time.get_ticks_msec() - t0) / 1000.0, Array(hs).min(), Array(hs).max(), col_h, float(node(pivot)[0])])
	quit(0)
