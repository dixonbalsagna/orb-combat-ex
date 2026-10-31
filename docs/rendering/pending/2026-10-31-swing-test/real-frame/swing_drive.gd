class_name SwingDrive
extends RefCounted
# SCRATCH (rendering.md section 11): the swing in the real game frame. A page word turns it on: sw=1 tiles and the world turned, sw=2 no tiles, today's whole ground turned rigidly (for any world).
# swrate=<deg/s>, swq=1 small swings, swset=<baked set>. Reads ticks only, so a capture is repeatable.
const FACES: Array = [
	[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
	[Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
	[Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)],
	[Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
	[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
	[Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0)],
]
const R: float = 153600.0 / (2.0 * PI)
const N: int = 33
const K: float = 1.6
const EASE: int = 20
const HOLD: int = 40
const MAX_TILES: int = 512
const SKIP_COPY: Array = ["unused"]
const CURVE: Array = [[950.0, 0.95], [2700.0, 1.0]]   # only with swshare=95: 95% at the closest zoom; otherwise the true globe

static var words: Dictionary = {}
var mode: int = 0
var rate: float = 60.0
var small: bool = false
var started: bool = false
var pane: PaneWorld
var tile_mat: ShaderMaterial
var mm: MultiMesh
var tiles: Dictionary = {}
var heights: PackedFloat32Array
var pivot: Vector3
var hd0: Vector3
var sd0: Vector3
var px: float = 0.0
var band := Vector2.ZERO
var q_angles := PackedFloat32Array()
var last_tick: int = -1
var last_reff: float = -1.0
var drawn: int = 0
var horizon_reach: float = 1.0e9
var prof := PackedFloat32Array()
var prof_img: Image
var prof_tex: ImageTexture
var world_mats: Array = []
var copy_t: int = 0
static var view_us: int = 0


static func word(k: String) -> String:
	if words.is_empty() and OS.has_feature("web"):
		var s: String = str(JavaScriptBridge.eval("location.search", true)).trim_prefix("?")
		for p in s.split("&"):
			var kv: PackedStringArray = p.split("=")
			words[kv[0]] = kv[1] if kv.size() > 1 else "1"
		words["_read"] = "1"
	return str(words.get(k, ""))


func _init(p: PaneWorld) -> void:
	pane = p
	mode = int(word("sw")) if word("sw") != "" else 0
	rate = float(word("swrate")) if word("swrate") != "" else 60.0
	small = word("swq") == "1"
	if small:
		_q_setup(rate)


## Every frame after the planet's update.
func apply(host: SimHost, cam_x: float, vp: Vector2) -> void:
	if mode == 0 or host.S == null:
		return
	var t0: int = Time.get_ticks_usec()
	var S: SimState = host.S
	if not started:
		if mode == 1 and not (S.planetRing is Dictionary and not S.planetRing.is_empty()):
			return
		_begin(S)
		started = true
	var planet: PlanetView = pane.planet
	if mode == 2 and px == 0.0:
		px = SimWrap.wrap(S.fighters[0].x)
	var tk: int = host.ticks
	var turned: float = fposmod(q_angles[tk % q_angles.size()], 360.0) if small else _turn_at(tk)
	var th: float = deg_to_rad(turned)
	var cs := Vector2(cos(th), sin(th))
	var cpx: float = SimWrap.sdx(cam_x, px)
	var width: float = 2.0 * pane.cam_rig.half_width(vp.x)
	var reff: float = R / _share(width)
	# The sag, to everything that bends.
	var sent_all: bool = absf(reff - last_reff) > 1.0e-3 * reff or tk % 30 == 0
	if sent_all:
		last_reff = reff
		for m in pane.mats._cache.values():
			m.set_shader_parameter("r_eff", reff)
		for m in pane.mats._tracked:
			m.set_shader_parameter("r_eff", reff)
		for m in planet._crowd_mats:
			m.set_shader_parameter("r_eff", reff)
	if tk != last_tick or sent_all:
		last_tick = tk
		for m in pane.mats._cache.values():
			m.set_shader_parameter("sw_px", cpx)
		for m in pane.mats._tracked:
			m.set_shader_parameter("sw_px", cpx)
		for m in planet._crowd_mats:
			m.set_shader_parameter("sw_px", cpx)
		for m in world_mats:
			m.set_shader_parameter("sw_cs", cs)
		if pane._sky_mat != null:
			pane._sky_mat.set_shader_parameter("sky_turn", th)
		if mode == 1:
			# As bent_world turns a point: x' = x c - z s, z' = x s + z c.
			var hd: Vector3 = (hd0 * cs.x - sd0 * cs.y).normalized()
			var sd: Vector3 = (hd0 * cs.y + sd0 * cs.x).normalized()
			_select(hd, sd, pane.cam_rig.position.z)
			_plane_profile(hd, width)
			tile_mat.set_shader_parameter("hd", hd)
			tile_mat.set_shader_parameter("sd", sd)
	if mode == 1:
		for k in ["wl_mul", "wl_add", "fore_cam"]:
			tile_mat.set_shader_parameter(k, planet._terrain_mat.get_shader_parameter(k))
		copy_t += 1
		if copy_t % 30 == 1:
			_copy_ground(planet._terrain_mat)
	# The sky's horizon is the globe's, from the camera's height over the ground below it.
	var hc: float = maxf(pane.cam_rig.position.y, 1.0)
	var hz: float = -tan(acos(reff / (reff + hc)))
	if pane._sky_mat != null:
		pane._sky_mat.set_shader_parameter("horizon", hz)
	pane.mats.set_sky("horizon", hz)
	view_us = Time.get_ticks_usec() - t0


func _begin(_S: SimState) -> void:
	var planet: PlanetView = pane.planet
	var big := AABB(Vector3(-4.0e6, -4.0e6, -4.0e6), Vector3(8.0e6, 8.0e6, 8.0e6))
	if mode == 1:
		_load_tiles()
	for c in planet._copies:
		var k: int = int(c.get_meta("k"))
		for g in c.get_children():
			if not (g is GeometryInstance3D):
				continue
			var own: AABB = (g as MultiMeshInstance3D).multimesh.custom_aabb if g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh != null else AABB()
			(g as GeometryInstance3D).custom_aabb = big
			if _off(g.name as String) or (mode == 1 and k == 0 and _out_of_band(own)):
				(g as GeometryInstance3D).layers = 0
			if mode == 1 and (k != 0 or (g.name as String).begins_with("Terrain") or (g.name as String).begins_with("Water") or (g.name as String).begins_with("FarTowns")):
				(g as GeometryInstance3D).layers = 0
	world_mats = [planet._bld_mat, planet._front_mat, planet._tree_mat, planet._cover_mat, planet._town_mat]
	for m in planet._crowd_mats:
		world_mats.append(m)
	if mode == 2:
		world_mats.append(planet._terrain_mat)
		world_mats.append(planet._water_mat)
	if mode == 1:
		tile_mat.set_shader_parameter("sw_on", 0.0)
	for m in world_mats:
		if m == null:
			continue
		m.set_shader_parameter("sw_on", 1.0)
		m.set_shader_parameter("sw_band", band if mode == 1 else Vector2.ZERO)
		var small_thing: bool = m != planet._bld_mat and m != planet._front_mat and m != planet._terrain_mat and m != planet._water_mat
		m.set_shader_parameter("sw_front", 1.0 if small_thing and mode == 1 else 0.0)
	world_mats = world_mats.filter(func(m): return m != null)


## A chunk wholly outside the place's band is left out, as the camera would leave it: the turn needs the box gone, not the culling.
func _out_of_band(own: AABB) -> bool:
	if own.size.x <= 0.0 or own.size.x > SimConst.W * 0.5 or band.x <= 0.0:
		return false
	var mid: float = own.position.x + own.size.x * 0.5
	return absf(SimWrap.sdx(px, mid)) - own.size.x * 0.5 > band.x


## swoff=tiles,crowd,cover,trees,bld,props: leave that part out, to read what it costs.
static func _off(nm: String) -> bool:
	var w: String = word("swoff")
	if w == "":
		return false
	var part: String = "crowd" if nm.begins_with("Crowd") else ("cover" if nm.begins_with("Cover_") else ("trees" if nm.begins_with("Trees_") else ("bld" if nm.begins_with("Buildings") else ("" if nm.begins_with("Terrain") or nm.begins_with("Water") or nm.begins_with("FarTowns") else "props"))))
	return part != "" and part in w.split(",")


func _load_tiles() -> void:
	var set_name: String = word("swset") if word("swset") != "" else "city"
	var dir: String = "res://swing/%s" % set_name
	var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "/world.json"))
	heights = FileAccess.get_file_as_bytes(dir + "/h.bin").to_float32_array()
	var cb: PackedByteArray = FileAccess.get_file_as_bytes(dir + "/c.bin")
	var hb: PackedByteArray = heights.to_byte_array()
	var ih: Array[Image] = []
	var ic: Array[Image] = []
	var list: Array = t.tiles
	for k in range(list.size()):
		var e: Array = list[k]
		tiles["%d/%d/%d/%d" % [int(e[0]), int(e[1]), int(e[2]), int(e[3])]] = [k, k * N * N]
		ih.append(Image.create_from_data(N, N, false, Image.FORMAT_RF, hb.slice(k * N * N * 4, (k + 1) * N * N * 4)))
		ic.append(Image.create_from_data(N, N, false, Image.FORMAT_RGBA8, cb.slice(k * N * N * 4, (k + 1) * N * N * 4)))
	var th := Texture2DArray.new()
	th.create_from_images(ih)
	var tc := Texture2DArray.new()
	tc.create_from_images(ic)
	pivot = _v3(t.pivot)
	hd0 = _v3(t.hd0)
	sd0 = _v3(t.sd0)
	px = float(t.px)
	band = Vector2(float(t.band[0]), float(t.band[1]))
	tile_mat = ShaderMaterial.new()
	tile_mat.shader = load("res://swing/tile.gdshader")
	if word("swsimple") == "1":
		# A second shader without the fragment at all: a branch on a value may run both sides on the old compiler.
		var code: String = (tile_mat.shader as Shader).code
		var cut := Shader.new()
		cut.code = code.substr(0, code.find("void fragment() {")) + "void fragment() {\n\tALBEDO = v_col * wl_mul + wl_add;\n}\n"
		tile_mat.shader = cut
	_copy_ground(pane.planet._terrain_mat)
	tile_mat.set_shader_parameter("hts", th)
	tile_mat.set_shader_parameter("ids", tc)
	tile_mat.set_shader_parameter("pv", pivot)
	tile_mat.set_shader_parameter("hd0", hd0)
	tile_mat.set_shader_parameter("sd0", sd0)
	tile_mat.set_shader_parameter("strip_x", px)
	prof.resize(64)
	prof_img = Image.create_from_data(64, 1, false, Image.FORMAT_RF, prof.to_byte_array())
	prof_tex = ImageTexture.create_from_image(prof_img)
	tile_mat.set_shader_parameter("plane_tex", prof_tex)
	tile_mat.set_shader_parameter("sw_simple", 1.0 if word("swsimple") == "1" else 0.0)
	pane.mats.track(tile_mat)
	# The tile mesh: 33 by 33 and a ring outside it: the skirt.
	var vs := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var n2: int = N + 2
	for b in range(n2):
		for a in range(n2):
			vs.append(Vector3(float(a), 0.0, float(b)))
			uv.append(Vector2(float(a - 1) / 32.0, float(b - 1) / 32.0))
	for b in range(n2 - 1):
		for a in range(n2 - 1):
			var q: int = b * n2 + a
			idx.append_array([q, q + 1, q + n2, q + n2, q + 1, q + n2 + 1])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = am
	mm.instance_count = MAX_TILES
	mm.visible_instance_count = 0
	var n := MultiMeshInstance3D.new()
	n.multimesh = mm
	n.material_override = tile_mat
	n.custom_aabb = AABB(Vector3(-4.0e6, -4.0e6, -4.0e6), Vector3(8.0e6, 8.0e6, 8.0e6))
	if "tiles" in word("swoff").split(","):
		n.layers = 0
	pane.planet.add_child(n)


func _copy_ground(src: ShaderMaterial) -> void:
	for u in src.shader.get_shader_uniform_list():
		var nm: String = u.name
		if nm in ["heights", "sw_on", "sw_cs", "sw_band", "sw_front", "r_eff", "hts", "ids", "plane_tex", "plane_span", "sw_simple", "pv", "hd", "sd", "hd0", "sd0", "strip_x"]:
			continue
		var v: Variant = src.get_shader_parameter(nm)
		if v != null:
			tile_mat.set_shader_parameter(nm, v)


static func _share(w: float) -> float:
	if word("swshare") != "95":
		return 1.0
	if w <= float(CURVE[0][0]):
		return float(CURVE[0][1])
	for i in range(1, CURVE.size()):
		if w <= float(CURVE[i][0]):
			var k: float = (log(w) - log(float(CURVE[i - 1][0]))) / (log(float(CURVE[i][0])) - log(float(CURVE[i - 1][0])))
			return lerpf(float(CURVE[i - 1][1]), float(CURVE[i][1]), k)
	return 1.0


func _turn_at(t: int) -> float:
	var per: float = rate / 60.0
	var te: int = int(ceil(360.0 / per)) + EASE
	var c: int = t % (te + HOLD)
	if c >= te:
		return 0.0
	var peak: float = 360.0 / float(te - EASE)
	var a: float
	if c < EASE:
		a = 0.5 * peak * float(c * c) / float(EASE)
	elif c < te - EASE:
		a = peak * (float(c) - 0.5 * float(EASE))
	else:
		var r: int = te - c
		a = 360.0 - 0.5 * peak * float(r * r) / float(EASE)
	return fposmod(a, 360.0)


func _q_setup(r: float) -> void:
	var per: float = r / 60.0
	var cur: float = 0.0
	var sgn: float = 1.0
	var sizes: Array = [15.0, 5.0, 10.0]
	var k: int = 0
	while q_angles.size() < 1600:
		var deg: float = float(sizes[k % 3])
		var n: int = int(ceil(deg / per + 5.0))
		var peak: float = deg / (float(n) - 5.0)
		for c in range(n):
			var a: float
			if c < 5:
				a = 0.5 * peak * float(c * c) / 5.0
			elif c < n - 5:
				a = peak * (float(c) - 2.5)
			else:
				var r2: int = n - c
				a = deg - 0.5 * peak * float(r2 * r2) / 5.0
			q_angles.append(cur + sgn * a)
		cur += sgn * deg
		for c in range(24):
			q_angles.append(cur)
		sgn = -sgn
		k += 1


static func _v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


static func _center(f: int, L: int, i: int, j: int) -> Vector3:
	var size: float = 2.0 / float(1 << L)
	var s: float = -1.0 + (float(i) + 0.5) * size
	var t: float = -1.0 + (float(j) + 0.5) * size
	var fc: Array = FACES[f]
	return ((fc[0] as Vector3) + (fc[1] as Vector3) * tan(s * PI / 4.0) + (fc[2] as Vector3) * tan(t * PI / 4.0)).normalized()


func _select(hd: Vector3, sd: Vector3, cam_d: float) -> void:
	var hc: float = maxf(pane.cam_rig.position.y, 1.0)
	horizon_reach = cam_d + R * (acos(R / (R + hc)) + acos(R / (R + 7200.0)))
	var buf := PackedFloat32Array()
	buf.resize(MAX_TILES * 16)
	drawn = 0
	var tn: float = tan(deg_to_rad(15.0)) * 1.8
	for f in range(6):
		_walk(f, 0, 0, 0, buf, tn, hd, sd, cam_d)
	mm.visible_instance_count = 0
	mm.buffer = buf
	mm.visible_instance_count = drawn


func _walk(f: int, L: int, i: int, j: int, buf: PackedFloat32Array, tn: float, hd: Vector3, sd: Vector3, cam_d: float) -> void:
	var w: float = 38400.0 / float(1 << L)
	var c: Vector3 = _center(f, L, i, j)
	var a: float = atan2(c.cross(pivot).length(), c.dot(pivot))
	var d: float = a * R
	var k: float = a / max(sin(a), 1.0e-5) * R
	var x: float = c.dot(hd) * k
	var z: float = c.dot(sd) * k
	var reach: float = w * 0.8
	var depth: float = cam_d - z
	if depth < -reach or absf(x) - reach > (maxf(depth, 0.0) + reach) * tn:
		return
	# Past the globe's horizon nothing shows: the camera's own, plus what the tallest ground's would add.
	if d - reach > horizon_reach:
		return
	var split: bool = L < 4 and maxf(d - w * 0.75, 0.0) < K * w
	if split:
		for q in range(4):
			if not tiles.has("%d/%d/%d/%d" % [f, L + 1, i * 2 + (q & 1), j * 2 + (q >> 1)]):
				split = false
				break
	if split:
		for q in range(4):
			_walk(f, L + 1, i * 2 + (q & 1), j * 2 + (q >> 1), buf, tn, hd, sd, cam_d)
		return
	var key0: String = "%d/%d/%d/%d" % [f, L, i, j]
	if drawn >= MAX_TILES or not tiles.has(key0):
		return
	var fc: Array = FACES[f]
	var n: Vector3 = fc[0]
	var u: Vector3 = fc[1]
	var v: Vector3 = fc[2]
	var size: float = 2.0 / float(1 << L)
	var o: int = drawn * 16
	buf[o] = n.x
	buf[o + 1] = u.x
	buf[o + 2] = v.x
	buf[o + 3] = -1.0 + float(i) * size
	buf[o + 4] = n.y
	buf[o + 5] = u.y
	buf[o + 6] = v.y
	buf[o + 7] = -1.0 + float(j) * size
	buf[o + 8] = n.z
	buf[o + 9] = u.z
	buf[o + 10] = v.z
	buf[o + 11] = size
	buf[o + 12] = float(tiles[key0][0])
	buf[o + 13] = (1.4 * K * w if L > 0 else 3.0e5) / 1000.0
	buf[o + 14] = (1.95 * K * w if L > 0 else 3.1e5) / 1000.0
	buf[o + 15] = w / 1000.0
	drawn += 1


func _plane_profile(hd: Vector3, width: float) -> void:
	var half: float = width * 1.4
	for k in range(64):
		var a: float = lerpf(-half, half, float(k) / 63.0) / R
		prof[k] = maxf(_height(pivot * cos(a) + hd * sin(a)), 0.0)
	prof_img.set_data(64, 1, false, Image.FORMAT_RF, prof.to_byte_array())
	prof_tex.update(prof_img)
	tile_mat.set_shader_parameter("plane_span", half)


func _height(d: Vector3) -> float:
	var ad := Vector3(absf(d.x), absf(d.y), absf(d.z))
	var f: int
	if ad.x >= ad.y and ad.x >= ad.z:
		f = 0 if d.x > 0.0 else 1
	elif ad.y >= ad.z:
		f = 2 if d.y > 0.0 else 3
	else:
		f = 4 if d.z > 0.0 else 5
	var fc: Array = FACES[f]
	var w: float = (fc[0] as Vector3).dot(d)
	var s: float = atan((fc[1] as Vector3).dot(d) / w) / (PI / 4.0)
	var t: float = atan((fc[2] as Vector3).dot(d) / w) / (PI / 4.0)
	for L in [3, 2, 1]:
		var n: int = 1 << L
		var i: int = clampi(int((s + 1.0) * 0.5 * float(n)), 0, n - 1)
		var j: int = clampi(int((t + 1.0) * 0.5 * float(n)), 0, n - 1)
		var key: String = "%d/%d/%d/%d" % [f, L, i, j]
		if tiles.has(key):
			var fa: float = ((s + 1.0) * 0.5 * float(n) - float(i)) * 32.0
			var fb: float = ((t + 1.0) * 0.5 * float(n) - float(j)) * 32.0
			return heights[int(tiles[key][1]) + clampi(int(fb + 0.5), 0, 32) * N + clampi(int(fa + 0.5), 0, 32)]
	return 0.0
