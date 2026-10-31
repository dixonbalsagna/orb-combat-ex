extends Node3D
# SCRATCH (docs/world/ring-any-angle/rendering.md, section 6): the swing test. No sim, no game code: tiles, a frame uniform, boxes, the real figure.
# It speaks Tools' hook (window.__flashcap), so frame-bench.mjs and capture-web.mjs drive it as they drive the game.
# Scenes: s<rate><rule|sink|clip> turns a full 360 at that peak, holds, and repeats; flight<reads> flies 3 s at 6,000 u/s with that read budget.
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
const HOLD: int = 40
const EASE: int = 20
const MAX_TILES: int = 512

var mats: Array = []
var ground_mat: ShaderMaterial
var box_mat: ShaderMaterial
var crowd_mat: ShaderMaterial
var sky_mat: ShaderMaterial
var mm: MultiMesh
var tiles: Dictionary = {}     # "f/L/i/j" -> [layer, height offset]
var heights: PackedFloat32Array
var ready_at: Dictionary = {}  # a streamed tile: when it may be used (ticks); absent: resident
var sharp_from: Dictionary = {}
var pivot0: Vector3
var head0: Vector3
var pivot: Vector3
var head: Vector3
var side: Vector3
var cam_node: Camera3D
var label: Label
var g0: float = 0.0
var cam_d: float = 2600.0
var scene_name: String = ""
var rate: float = 60.0
var near: int = 0
var reduced: bool = false
var reads_budget: float = 4.0
var flight: bool = false
var tick: int = 0
var turned: float = 0.0
var travelled: float = 0.0
var hook: bool = false
var shown_due: bool = false
var ready_told: bool = false
var frames: int = 0
var last_view_ms: float = 0.0
var last_select_ms: float = 0.0
var last_low_ms: float = 0.0
var drawn: int = 0
var reads_spent: float = 0.0
var queue: Array = []
var magenta: bool = false
var nohud: bool = false
var wall: bool = false
var coarse: int = 0
var no_stream: bool = false
var boxes: Array = []
var q_angles := PackedFloat32Array()
var ground0: float = 0.0
var tex_h: Texture2DArray
var tex_c: Texture2DArray
var hbytes: PackedByteArray
var cbytes_all: PackedByteArray
var uploads: int = 0
var upload_us: int = 0
var acc: float = 0.0
var wall_th: float = 0.0
var blds: Array = []


func _ready() -> void:
	var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://swing/world.json"))
	if OS.has_feature("web"):
		var sr: String = str(JavaScriptBridge.eval("location.search", true))
		coarse = 1 if sr.contains("coarse=1") else (2 if sr.contains("coarse=2") else 0)
	var su: String = "" if coarse == 0 else str(coarse + 1)
	heights = FileAccess.get_file_as_bytes("res://swing/h%s.bin" % su).to_float32_array()
	var cbytes: PackedByteArray = FileAccess.get_file_as_bytes("res://swing/c%s.bin" % su)
	var imgs_h: Array[Image] = []
	var imgs_c: Array[Image] = []
	var hb: PackedByteArray = heights.to_byte_array()
	var list: Array = t.tiles
	for k in range(list.size()):
		var e: Array = list[k]
		tiles["%d/%d/%d/%d" % [int(e[0]), int(e[1]), int(e[2]), int(e[3])]] = [k, k * N * N]
		imgs_h.append(Image.create_from_data(N, N, false, Image.FORMAT_RF, hb.slice(k * N * N * 4, (k + 1) * N * N * 4)))
		imgs_c.append(Image.create_from_data(N, N, false, Image.FORMAT_RGBA8, cbytes.slice(k * N * N * 4, (k + 1) * N * N * 4)))
	var th := Texture2DArray.new()
	th.create_from_images(imgs_h)
	var tc := Texture2DArray.new()
	tc.create_from_images(imgs_c)
	tex_h = th
	tex_c = tc
	hbytes = hb
	cbytes_all = cbytes
	pivot0 = _v3(t.pivot)
	head0 = _v3(t.heading)
	g0 = maxf(float(t["g0" + su]), 0.0)
	ground0 = g0
	ground_mat = _mat("res://swing/ground.gdshader")
	ground_mat.set_shader_parameter("surface_detail", 0.0 if coarse == 0 else 0.5)
	ground_mat.set_shader_parameter("hts", th)
	ground_mat.set_shader_parameter("cols", tc)
	box_mat = _mat("res://swing/box.gdshader")
	crowd_mat = _mat("res://swing/crowd.gdshader")
	crowd_mat.set_shader_parameter("outline_col", RenderLook.col(RenderLook.CROWD_OUTLINE))
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = load("res://swing/sky.gdshader")
	# The one tile mesh.
	var vs := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	for b in range(N):
		for a in range(N):
			vs.append(Vector3(float(a), 0.0, float(b)))
			uv.append(Vector2(float(a) / 32.0, float(b) / 32.0))
	for b in range(N - 1):
		for a in range(N - 1):
			var q: int = b * N + a
			idx.append_array([q, q + 1, q + N, q + N, q + 1, q + N + 1])
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
	_mmi(mm, ground_mat)
	# Buildings.
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	bm.subdivide_width = 3
	bm.subdivide_depth = 3
	bm.subdivide_height = 6
	# VERTEX.y of a BoxMesh runs -0.5 to 0.5: lift it so the foot is 0.
	var ba: Array = bm.get_mesh_arrays()
	var bv: PackedVector3Array = ba[Mesh.ARRAY_VERTEX]
	for i in range(bv.size()):
		bv[i].y += 0.5
	ba[Mesh.ARRAY_VERTEX] = bv
	var bmesh := ArrayMesh.new()
	bmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ba)
	var bl: Array = t.blds
	blds = bl
	var mb := MultiMesh.new()
	mb.transform_format = MultiMesh.TRANSFORM_3D
	mb.mesh = bmesh
	mb.instance_count = bl.size()
	for i in range(bl.size()):
		var d: Dictionary = bl[i]
		mb.set_instance_transform(i, Transform3D(Basis(_v3(d.a), _v3(d.e), Vector3(float(d.w), float(d.d), float(d.h))), Vector3(float(d["g" + su]), float(d.s), float(d.dmg))))
	_mmi(mb, box_mat)
	# The figures.
	var cl: Array = t.crowd
	var mc := MultiMesh.new()
	mc.transform_format = MultiMesh.TRANSFORM_3D
	mc.use_custom_data = true
	mc.mesh = CrowdMesh.build()
	mc.instance_count = cl.size()
	for i in range(cl.size()):
		var d: Dictionary = cl[i]
		mc.set_instance_transform(i, Transform3D(Basis(_v3(d.a), _v3(d.e), Vector3.ZERO), Vector3(float(d["g" + su]), 0.0, 0.0)))
		var cc: Array = d.c
		mc.set_instance_custom_data(i, Color(float(cc[0]), float(cc[1]), float(cc[2]), float(cc[3])))
	_mmi(mc, crowd_mat)
	if OS.has_feature("web") and str(JavaScriptBridge.eval("location.search", true)).contains("nobld=1"):
		mb.visible_instance_count = 0
		mc.visible_instance_count = 0
	# Two fighters, on the line: they never move on the screen.
	for i in range(2):
		var box := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(26.0, 75.0, 14.0)
		box.mesh = fm
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.albedo_color = Color("#d8392f") if i == 0 else Color("#2f7fd8")
		box.material_override = sm
		box.position = Vector3(-90.0 if i == 0 else 90.0, g0 + 37.5, 0.0)
		add_child(box)
		boxes.append(box)
	# The sky.
	cam_node = Camera3D.new()
	cam_node.fov = 30.0
	cam_node.far = 400000.0
	cam_node.near = 5.0
	add_child(cam_node)
	cam_node.current = true
	var sq := QuadMesh.new()
	sq.size = Vector2(2.0, 2.0)
	var smi := MeshInstance3D.new()
	smi.mesh = sq
	smi.material_override = sky_mat
	# Filling the view at 380,000 away: x 1 at the view's edge at 16:9 (wider screens run a little past it), y 1 at its top.
	smi.position = Vector3(0.0, 0.0, -380000.0)
	smi.scale = Vector3(380000.0 * tan(deg_to_rad(15.0)) * 2.5, 380000.0 * tan(deg_to_rad(15.0)), 1.0)
	smi.custom_aabb = AABB(Vector3(-2.0, -2.0, -2.0), Vector3(4.0, 4.0, 4.0))
	cam_node.add_child(smi)
	label = Label.new()
	label.position = Vector2(14.0, 8.0)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	var layer := CanvasLayer.new()
	layer.add_child(label)
	add_child(layer)
	hook = OS.has_feature("web") and str(JavaScriptBridge.eval("location.search", true)).contains("flashcap=1")
	magenta = OS.has_feature("web") and str(JavaScriptBridge.eval("location.search", true)).contains("magenta=1")
	nohud = OS.has_feature("web") and str(JavaScriptBridge.eval("location.search", true)).contains("nohud=1")
	if magenta:
		sky_mat.set_shader_parameter("magenta", true)
		ground_mat.set_shader_parameter("clear_haze", Vector3.ZERO)
	label.visible = not nohud
	if hook:
		JavaScriptBridge.eval("""window.__flashcap = {
			ready: false, tick: 0, scenario: '', error: '', in_window: 0, _req: null, _want: 0, _done: 0, _waiting: [],
			start(scenario, opts) { this._req = { scenario: String(scenario), reduced: !!(opts && opts.reduced) }; },
			step() { return new Promise((res) => { this._waiting.push(res); this._want += 1; }); },
			_shown(tick) { this.tick = tick; this._done += 1; const r = this._waiting.shift(); if (r) r(tick); }
		};""", true)
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	begin("s60rule", false)


func _mat(p: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(p)
	mats.append(m)
	return m


func _mmi(m: MultiMesh, mat: Material) -> void:
	var n := MultiMeshInstance3D.new()
	n.multimesh = m
	n.material_override = mat
	n.custom_aabb = AABB(Vector3(-1.0e6, -1.0e6, -1.0e6), Vector3(2.0e6, 2.0e6, 2.0e6))
	add_child(n)


static func _v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func begin(name_: String, red: bool) -> void:
	if name_ == "upload":
		var txt: String = ""
		for sz in [33, 65]:
			for ly in [8, 64, 256]:
				txt += "side %d, %d layers: %.0f us an update   " % [sz, ly, upload_bench(ly, 400, sz)]
			txt += "\n"
		label.text = txt
		label.add_theme_font_size_override("font_size", 22)
		scene_name = name_
		print(txt)
		return
	scene_name = name_
	reduced = red
	tick = 0
	turned = 0.0
	travelled = 0.0
	flight = name_.begins_with("flight")
	q_angles = PackedFloat32Array()
	g0 = ground0
	wall = name_ == "wall"
	ready_at.clear()
	sharp_from.clear()
	reads_spent = 0.0
	queue.clear()
	if flight:
		reads_budget = float(name_.substr(6))
		no_stream = reads_budget <= 0.0
		rate = 0.0
		near = 0
		cam_d = 4400.0
	else:
		var m := RegEx.create_from_string("^s([0-9]+)(rule|sink|clip)$").search(name_)
		if name_.begins_with("q"):
			m = null
		rate = float(m.get_string(1)) if m != null else 60.0
		var nm: String = m.get_string(2) if m != null else "rule"
		near = 0 if nm == "rule" else (1 if nm == "sink" else 2)
		cam_d = 2600.0
	if OS.has_feature("web"):
		var mcd := RegEx.create_from_string("camd=([0-9]+)").search(str(JavaScriptBridge.eval("location.search", true)))
		if mcd != null:
			cam_d = float(mcd.get_string(1))
	var mq := RegEx.create_from_string("^q([0-9]+)([co])$").search(name_)
	if mq != null:
		_q_setup(float(mq.get_string(1)))
		near = 0
		cam_d = 2600.0
		if mq.get_string(2) == "o":
			_open_ground()
	for b2 in boxes:
		(b2 as MeshInstance3D).position.y = g0 + 37.5
	for m2 in mats:
		m2.set_shader_parameter("near_mode", near)
	var d: float = cam_d
	cam_node.position = Vector3(0.0, g0 + d * 0.115, d)
	cam_node.look_at(Vector3(0.0, g0 + d * 0.077, 0.0), Vector3.UP)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var zoom: float = vp.y / (2.0 * d * tan(deg_to_rad(15.0)))
	var bend: float = 4.0 * 0.035 * vp.y * zoom / (vp.x * vp.x)
	for m2 in mats:
		m2.set_shader_parameter("cam", cam_node.position)
		m2.set_shader_parameter("bend", bend)
	var hy: float = cam_node.unproject_position(Vector3(0.0, g0, -70000.0)).y
	sky_mat.set_shader_parameter("horizon", 1.0 - hy / vp.y)
	if flight and not no_stream:
		_stream_setup()
	# The wall: the tallest building within 700 to 1,400 of the pivot, brought onto the line at 60 deg/s and held, drawn where it stands.
	box_mat.set_shader_parameter("keep_anchor", Vector3.ZERO)
	if wall:
		var best: int = -1
		for i in range(blds.size()):
			var av: Vector3 = _v3(blds[i].a)
			var dd: float = _ang(av, pivot0) * R
			if dd > 800.0 and dd < 1700.0 and (best < 0 or float(blds[i].h) > float(blds[best].h)):
				best = i
		var a2: Vector3 = _v3(blds[best].a)
		wall_th = rad_to_deg(atan2(a2.dot(head0.cross(pivot0).normalized()), a2.dot(head0)))
		box_mat.set_shader_parameter("keep_anchor", a2)
		rate = 60.0
		near = 0
		for m2 in mats:
			m2.set_shader_parameter("near_mode", near)
	_apply()


## The far levels are resident (a far map's worth); L3 and L4 along the flight come in by the read budget, nearest the pivot first.
func _stream_setup() -> void:
	for key in tiles:
		var e: PackedStringArray = (key as String).split("/")
		if int(e[1]) >= 2:
			var c: Vector3 = _center(int(e[0]), int(e[1]), int(e[2]), int(e[3]))
			if _ang(c, pivot0) * R > 26000.0 * (0.5 if int(e[1]) == 2 else 0.4):
				ready_at[key] = 1 << 30   # not read yet


## The flight's follow: the pair over the ground ahead, the camera with them, eased.
func _follow_ground() -> void:
	var a: float = (travelled + 700.0) / R
	var ahead: Vector3 = (pivot0 * cos(a) + head0 * sin(a)).normalized()
	var want: float = maxf(maxf(_height(ahead), _height(pivot)), 0.0) + (260.0 if travelled > 0.0 and tick < 300 else 0.0)
	g0 = lerpf(g0, want, 0.08)
	cam_node.position = Vector3(0.0, g0 + cam_d * 0.115, cam_d)
	cam_node.look_at(Vector3(0.0, g0 + cam_d * 0.077, 0.0), Vector3.UP)
	for m2 in mats:
		m2.set_shader_parameter("cam", cam_node.position)
	for b2 in boxes:
		(b2 as MeshInstance3D).position.y = g0 + 37.5
	var vp: Vector2 = get_viewport().get_visible_rect().size
	sky_mat.set_shader_parameter("horizon", 1.0 - cam_node.unproject_position(Vector3(0.0, g0, -70000.0)).y / vp.y)


## Small fast swings: 15, 5, 10 degrees, turn about, each eased over 5 ticks at both ends, 24 ticks still between them.
func _q_setup(r: float) -> void:
	var per: float = r / 60.0
	var cur: float = 0.0
	var sgn: float = 1.0
	var sizes: Array = [15.0, 5.0, 10.0]
	var k: int = 0
	rate = r
	while q_angles.size() < 1200:
		var deg: float = float(sizes[k % 3])
		var dur: float = deg / per + 5.0
		var n: int = int(ceil(dur))
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


## Open ground: along the flight's line, the first land clear of the city.
func _open_ground() -> void:
	for k in range(4, 8):
		var dist: float = float(k) * 2500.0 + 4000.0
		var a: float = dist / R
		var d: Vector3 = (pivot0 * cos(a) + head0 * sin(a)).normalized()
		var h: float = _height(d)
		if h > 5.0:
			travelled = dist
			g0 = h
			return


func _center(f: int, L: int, i: int, j: int) -> Vector3:
	return _dir(f, L, i, j, 0.5, 0.5)


static func _dir(f: int, L: int, i: int, j: int, a: float, b: float) -> Vector3:
	var size: float = 2.0 / float(1 << L)
	var s: float = -1.0 + (float(i) + a) * size
	var t: float = -1.0 + (float(j) + b) * size
	var fc: Array = FACES[f]
	return ((fc[0] as Vector3) + (fc[1] as Vector3) * tan(s * PI / 4.0) + (fc[2] as Vector3) * tan(t * PI / 4.0)).normalized()


static func _ang(a: Vector3, b: Vector3) -> float:
	return atan2(a.cross(b).length(), a.dot(b))


## The angle at tick t of the repeating turn: eased in and out, exactly 360 at its end.
func _turn_at(t: int) -> float:
	var per: float = rate / 60.0
	if per <= 0.0:
		return 0.0
	var te: int = int(ceil(360.0 / per)) + EASE
	var cycle: int = te + HOLD
	var c: int = t % cycle
	if c >= te:
		return 0.0
	var a: float
	var peak: float = 360.0 / float(te - EASE)
	if c < EASE:
		a = 0.5 * peak * float(c * c) / float(EASE)
	elif c < te - EASE:
		a = peak * (float(c) - 0.5 * float(EASE))
	else:
		var r: int = te - c
		a = 360.0 - 0.5 * peak * float(r * r) / float(EASE)
	return fposmod(a, 360.0)


func _advance() -> void:
	tick += 1
	if scene_name == "upload":
		return
	if flight:
		# 40 ticks still, ease to 6,000 u/s, 3 s, ease out, then rest.
		var t: float = float(tick - 40)
		var v: float = 0.0
		if t > 0.0:
			var e: float = minf(t / 15.0, 1.0)
			if t > 195.0:
				e = clampf((225.0 - t) / 30.0, 0.0, 1.0)
			v = 100.0 * e
		travelled += v
		# The reads.
		reads_spent += reads_budget
		_follow_ground()
	elif not q_angles.is_empty():
		turned = fposmod(q_angles[tick % q_angles.size()], 360.0)
	elif wall:
		# Eased to rest at the bearing, by the same 20 ticks.
		var t: float = float(maxi(tick - 40, 0))
		var total: float = absf(wall_th)
		var dur: float = total / 1.0 + 20.0
		var c: float = minf(t, dur)
		var a: float
		if c < 20.0:
			a = 0.5 * c * c / 20.0
		elif c < dur - 20.0:
			a = c - 10.0
		else:
			var r2: float = dur - c
			a = total - 0.5 * r2 * r2 / 20.0
		turned = fposmod(a * signf(wall_th), 360.0)
	else:
		turned = _turn_at(tick)
	_apply()


func _apply() -> void:
	var ang: float = travelled / R
	var p0: Vector3 = pivot0 * cos(ang) + head0 * sin(ang)
	var h0: Vector3 = head0 * cos(ang) - pivot0 * sin(ang)
	pivot = p0.normalized()
	var th: float = deg_to_rad(turned)
	var s0: Vector3 = h0.cross(pivot).normalized()
	head = (h0 * cos(th) + s0 * sin(th)).normalized()
	side = head.cross(pivot).normalized()
	var t0: int = Time.get_ticks_usec()
	_select()
	var t1: int = Time.get_ticks_usec()
	var low: float = _plane_low()
	var t2: int = Time.get_ticks_usec()
	for m in mats:
		m.set_shader_parameter("pv", pivot)
		m.set_shader_parameter("hd", head)
		m.set_shader_parameter("sd", side)
		m.set_shader_parameter("plane_low", low)
	sky_mat.set_shader_parameter("sky_turn", th + ang)
	last_select_ms = float(t1 - t0) / 1000.0
	last_low_ms = float(t2 - t1) / 1000.0
	last_view_ms = float(Time.get_ticks_usec() - t0) / 1000.0
	if not nohud and scene_name != "upload":
		var nm: String = ["the rule", "sink", "hard clip"][near]
		label.text = ("flight, %.1f reads a tick" % reads_budget) if flight else (("a wall brought onto the line and held") if wall else ("%d deg/s, near line: %s%s%s  (1 2 3 rate; 4 5 small at 240, 120, city; 6 7 open; Q W E near; F flight; T wall)" % [int(rate), nm, ", reduced" if reduced else "", ", small swings" if not q_angles.is_empty() else ""]))


## The tiles to draw: a quadtree from the faces, split by distance, a child only when it's been read. Instances go straight to the buffer.
func _select() -> void:
	var buf := PackedFloat32Array()
	buf.resize(MAX_TILES * 16)
	drawn = 0
	var tn: float = tan(deg_to_rad(15.0)) * 1.8
	for f in range(6):
		_walk(f, 0, 0, 0, buf, tn)
	mm.visible_instance_count = 0
	mm.buffer = buf
	mm.visible_instance_count = drawn


func _walk(f: int, L: int, i: int, j: int, buf: PackedFloat32Array, tn: float) -> void:
	var w: float = 38400.0 / float(1 << L)
	var c: Vector3 = _center(f, L, i, j)
	var a: float = _ang(c, pivot)
	var d: float = a * R
	var k: float = a / max(sin(a), 1.0e-5) * R
	var x: float = c.dot(head) * k
	var z: float = c.dot(side) * k
	# Behind the camera, or wide of the view, by a tile's reach.
	var reach: float = w * 0.8
	var depth: float = cam_d - z
	if depth < -reach or absf(x) - reach > (maxf(depth, 0.0) + reach) * tn:
		return
	var split: bool = L < 4 and maxf(d - w * 0.75, 0.0) < K * w
	if split:
		for q in range(4):
			var ci: int = i * 2 + (q & 1)
			var cj: int = j * 2 + (q >> 1)
			var key: String = "%d/%d/%d/%d" % [f, L + 1, ci, cj]
			if not tiles.has(key) or not _usable(key):
				split = false
				break
	if split:
		for q in range(4):
			_walk(f, L + 1, i * 2 + (q & 1), j * 2 + (q >> 1), buf, tn)
		return
	var key0: String = "%d/%d/%d/%d" % [f, L, i, j]
	if drawn >= MAX_TILES or not tiles.has(key0):
		return
	var fc: Array = FACES[f]
	var n: Vector3 = fc[0]
	var u: Vector3 = fc[1]
	var v: Vector3 = fc[2]
	var size: float = 2.0 / float(1 << L)
	var s0: float = -1.0 + float(i) * size
	var t0: float = -1.0 + float(j) * size
	var o: int = drawn * 16
	# RS's order: x row, y row, z row, then the custom.
	buf[o] = n.x
	buf[o + 1] = u.x
	buf[o + 2] = v.x
	buf[o + 3] = s0
	buf[o + 4] = n.y
	buf[o + 5] = u.y
	buf[o + 6] = v.y
	buf[o + 7] = t0
	buf[o + 8] = n.z
	buf[o + 9] = u.z
	buf[o + 10] = v.z
	buf[o + 11] = size
	# A coarser neighbour is only ever where the distance is 2 K w or more, so a vertex has gone to the coarser lattice by then.
	var ms: float = 1.4 * K * w
	var me: float = 1.95 * K * w
	buf[o + 12] = float(tiles[key0][0])
	buf[o + 13] = (ms if L > 0 else 3.0e5) / 1000.0
	buf[o + 14] = (me if L > 0 else 3.1e5) / 1000.0
	buf[o + 15] = _sharp(key0)
	drawn += 1


func _usable(key: String) -> bool:
	if not ready_at.has(key):
		return true
	return _try_read(key)


## A tile asked for and not read yet: it takes its nodes from the budget, a whole tile at a time, as the reads allow.
func _try_read(key: String) -> bool:
	if int(ready_at[key]) <= tick:
		return true
	if int(ready_at[key]) == 1 << 30:
		var L: int = int(key.split("/")[1])
		var cost: float = 0.0 if L == 4 else 1089.0
		if reads_spent >= cost:
			reads_spent -= cost
			ready_at[key] = tick
			sharp_from[key] = tick
			var t0: int = Time.get_ticks_usec()
			var k: int = int(tiles[key][0])
			tex_h.update_layer(Image.create_from_data(N, N, false, Image.FORMAT_RF, hbytes.slice(k * N * N * 4, (k + 1) * N * N * 4)), k)
			tex_c.update_layer(Image.create_from_data(N, N, false, Image.FORMAT_RGBA8, cbytes_all.slice(k * N * N * 4, (k + 1) * N * N * 4)), k)
			uploads += 1
			upload_us += Time.get_ticks_usec() - t0
			return true
	return false


## 0 just read (it stands on its parent's lattice), 1 after 30 ticks: the height morph that test 7 worries about.
func _sharp(key: String) -> float:
	if not sharp_from.has(key):
		return 1.0
	return clampf(float(tick - int(sharp_from[key])) / 30.0, 0.0, 1.0)


## The plane's lowest ground in view: 64 points along the line, from the tiles, as the foreground rule would need it.
func _plane_low() -> float:
	var low: float = INF
	var half: float = 1.1 * cam_d * tan(deg_to_rad(15.0)) * 1.8
	for k in range(64):
		var x: float = lerpf(-half, half, float(k) / 63.0)
		var a: float = x / R
		var d: Vector3 = pivot * cos(a) + head * sin(a)
		low = minf(low, maxf(_height(d), 0.0))
	return low


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
		if tiles.has(key) and (not ready_at.has(key) or int(ready_at[key]) <= tick):
			var fa: float = ((s + 1.0) * 0.5 * float(n) - float(i)) * 32.0
			var fb: float = ((t + 1.0) * 0.5 * float(n) - float(j)) * 32.0
			return heights[int(tiles[key][1]) + clampi(int(fb + 0.5), 0, 32) * N + clampi(int(fa + 0.5), 0, 32)]
	return 0.0


func _process(d: float) -> void:
	if hook:
		_poll()
	else:
		acc = minf(acc + d, 0.1)
		while acc >= 1.0 / 60.0:
			acc -= 1.0 / 60.0
			_advance()


func _poll() -> void:
	if shown_due:
		shown_due = false
		JavaScriptBridge.eval("window.__flashcap._shown(%d);" % tick, true)
	frames += 1
	if not ready_told and frames >= 3:
		ready_told = true
		JavaScriptBridge.eval("window.__flashcap.ready = true;", true)
	var st = JSON.parse_string(str(JavaScriptBridge.eval("(() => { const fc = window.__flashcap; const r = fc._req; fc._req = null; return JSON.stringify({ req: r, pending: fc._want - fc._done, auto: !!fc.auto }); })()", true)))
	if not (st is Dictionary):
		return
	if st.get("req") is Dictionary:
		var req: Dictionary = st.req
		begin(String(req.scenario), bool(req.reduced))
		var fl: String = "true" if bool(req.reduced) else "false"
		JavaScriptBridge.eval("window.__flashcap.scenario = %s; window.__flashcap.tick = 0; window.__flashcap.switches = { reduce_flashing: %s }; window.__flashcap.mode = { reduce_flashing: %s, flash_calm: %s };" % [JSON.stringify(scene_name), fl, fl, fl], true)
	if scene_name != "" and (int(st.get("pending", 0)) > 0 or bool(st.get("auto", false))):
		_advance()
		shown_due = true
		var rid: RID = get_viewport().get_viewport_rid()
		JavaScriptBridge.eval("window.__flashcap.perf = %s;" % JSON.stringify({
			"uploads": uploads, "upload_us": upload_us, "frame_ms": 0.0, "tick_ms": 0.0, "fx_ms": 0.0, "view_ms": last_view_ms, "select_ms": last_select_ms, "low_ms": last_low_ms, "tiles": drawn,
			"draws": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
			"prims": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			"vmem": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), "tmem": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
			"smem": 0, "parts": 0, "rcpu": RenderingServer.viewport_get_measured_render_time_cpu(rid), "rgpu": RenderingServer.viewport_get_measured_render_time_gpu(rid), "tick": tick,
		}), true)


func _unhandled_input(e: InputEvent) -> void:
	if hook or not (e is InputEventKey) or not e.pressed:
		return
	var parts: Dictionary = {KEY_1: 30, KEY_2: 60, KEY_3: 98}
	if e.keycode == KEY_4 or e.keycode == KEY_5:
		begin("q%d%s" % [240 if e.keycode == KEY_4 else 120, "c"], false)
		return
	if e.keycode == KEY_6 or e.keycode == KEY_7:
		begin("q%d%s" % [240 if e.keycode == KEY_6 else 120, "o"], false)
		return
	var nm: Array = ["rule", "sink", "clip"]
	match e.keycode:
		KEY_1, KEY_2, KEY_3:
			begin("s%d%s" % [parts[e.keycode], nm[near]], false)
		KEY_Q:
			begin("s%d%s" % [int(rate) if rate > 0.0 else 60, "rule"], false)
		KEY_W:
			begin("s%d%s" % [int(rate) if rate > 0.0 else 60, "sink"], false)
		KEY_E:
			begin("s%d%s" % [int(rate) if rate > 0.0 else 60, "clip"], false)
		KEY_F:
			begin("flight1.5", false)
		KEY_T:
			begin("wall", false)


## window.__uploadbench: one tile's layer written many times, at two array sizes: does the time follow the array?
func upload_bench(layers: int, n: int, side_: int) -> float:
	var base := PackedFloat32Array()
	base.resize(side_ * side_)
	var imgs: Array[Image] = []
	for k in range(layers):
		imgs.append(Image.create_from_data(side_, side_, false, Image.FORMAT_RF, base.to_byte_array()))
	var a := Texture2DArray.new()
	a.create_from_images(imgs)
	var one: Image = imgs[0]
	var t0: int = Time.get_ticks_usec()
	for k in range(n):
		a.update_layer(one, k % layers)
	return float(Time.get_ticks_usec() - t0) / float(n)
