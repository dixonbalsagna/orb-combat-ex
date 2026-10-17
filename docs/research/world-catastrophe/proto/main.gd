extends Node3D
## World catastrophe render prototype (Research & Prototyping, 2026-10-16). Throwaway, standalone, Compatibility renderer,
## built for the web. Four scenes, each a fixed timeline in scene time t (seconds), with no sim and no fighters:
##   magma     a beam's cut through the crust, magma standing in it (docs/research/world-catastrophe.md, effect 1)
##   cloud     a mushroom cloud rising, its fireball, a ground shock ring, the sky darkening (effect 2)
##   orbit     the planet from orbital altitude, blasts thrown down from the exosphere and their surface impacts (effect 3)
##   collapse  thirty towers coming down at once with dust and debris (effect 4)
## Query string (web) or user args (desktop): scene=<name> t=<s> (a still at that time) od=1 (overdraw view: every effect
## layer adds 1/64 to a black frame, so a still's pixel value x 64 is the number of layers drawn there) reduced=1
## ("Reduce flashing") frames=1 (window.__adv = n poses tick n; window.__tick reports it drawn) bench=1 (frame times).
## Render-only by construction: there is no simulation here. Units are the game's (a fighter is 75 units tall).

const R_PLANET: float = 24446.0          # the arena's great circle: 153,600 / 2 pi
var opts: Dictionary = {}
var scene_name: String = "magma"
var t: float = 0.0
var od: bool = false
var reduced: bool = false
var frames_mode: bool = false
var last_adv: int = -1
var still_frames: int = -1
var cam: Camera3D
var env: Environment
var mats: Array = []                     # every ShaderMaterial, to set time and od on
var sets: Array = []                     # every Sprites set, for the CPU overdraw count
var apply_fn: Callable
var rng := RandomNumberGenerator.new()
# bench
var bench: bool = false
var bench_t: float = 0.0
var bench_last: int = 0
var frame_ms: PackedFloat32Array = []
var cpu_us: PackedFloat32Array = []
var draws: Array = []
var prims: Array = []


class Sprites:
	var mm: MultiMesh
	var n: int = 0
	var buf := PackedFloat32Array()


# --------------------------------------------------------------------------------------------------------------- setup
func _ready() -> void:
	_opts()
	scene_name = String(opts.get("scene", "magma"))
	od = String(opts.get("od", "0")) == "1"
	reduced = String(opts.get("reduced", "0")) == "1"
	frames_mode = opts.has("frames")
	bench = opts.has("bench")
	t = float(opts.get("t", "0"))
	rng.seed = 20261016
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	cam = Camera3D.new()
	cam.fov = 30.0
	cam.near = 20.0
	cam.far = 400000.0
	add_child(cam)
	cam.make_current()
	match scene_name:
		"magma":
			_build_magma()
		"cloud":
			_build_cloud()
		"orbit":
			_build_orbit()
		"collapse":
			_build_collapse()
	if od:
		env.background_color = Color(0, 0, 0)
	_apply(t)
	if bench:
		Engine.max_fps = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if not bench and not frames_mode:
		still_frames = 6


func _opts() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := String(a).trim_prefix("--").split("=")
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if OS.has_feature("web"):
		var q: Variant = JavaScriptBridge.eval("window.location.search")
		if typeof(q) == TYPE_STRING and String(q).length() > 1:
			for part in String(q).substr(1).split("&", false):
				var kv2 := part.split("=")
				opts[kv2[0]] = kv2[1] if kv2.size() > 1 else "1"


func _js(code: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(code)


func _process(delta: float) -> void:
	if frames_mode:
		var adv: Variant = JavaScriptBridge.eval("window.__adv === undefined ? -1 : window.__adv") if OS.has_feature("web") else -1
		if typeof(adv) != TYPE_NIL and int(adv) >= 0 and int(adv) != last_adv:
			last_adv = int(adv)
			_apply(float(last_adv) / 60.0)
			await RenderingServer.frame_post_draw
			_js("window.__tick = %d; window.__info = %s;" % [last_adv, JSON.stringify(_info())])
		return
	if still_frames >= 0:
		still_frames -= 1
		if still_frames == 0:
			_js("window.__info = %s; window.__ready = true;" % JSON.stringify(_info()))
		return
	var a: int = Time.get_ticks_usec()
	t += delta
	_apply(t)
	var cpu: int = Time.get_ticks_usec() - a
	if bench:
		_bench(cpu)


## Overdraw, counted on the CPU (the GPU view is not used): every live sprite's disc is projected through the camera and
## rasterised into a GX x GY grid. Returns the mean and peak layers a pixel gets, the share of the screen over 4 and over
## 8 layers, and the fragments shaded per frame at 1280 x 720 (the effect layers only; opaque scenery is not counted).
const GX: int = 256
const GY: int = 144


func _overdraw() -> Dictionary:
	var grid := PackedFloat32Array()
	grid.resize(GX * GY)
	var vp := Vector2(get_viewport().get_visible_rect().size)
	var focal: float = vp.y / (2.0 * tan(deg_to_rad(cam.fov) * 0.5))
	var frags: float = 0.0
	for s in sets:
		for i in s.n:
			var o: int = i * 20
			var size: float = s.buf[o]
			var a: float = s.buf[o + 15]
			if size <= 0.0 or a < 0.02:
				continue
			var p := Vector3(s.buf[o + 3], s.buf[o + 7], s.buf[o + 11])
			if cam.is_position_behind(p):
				continue
			var depth: float = -(cam.global_transform.affine_inverse() * p).z
			if depth <= cam.near:
				continue
			var sp := cam.unproject_position(p)
			var r: float = 0.5 * size * focal / depth   # the quad's half width; the drawn disc is inscribed in it
			var gx0: int = clampi(int(floor((sp.x - r) / vp.x * GX)), 0, GX - 1)
			var gx1: int = clampi(int(floor((sp.x + r) / vp.x * GX)), 0, GX - 1)
			var gy0: int = clampi(int(floor((sp.y - r) / vp.y * GY)), 0, GY - 1)
			var gy1: int = clampi(int(floor((sp.y + r) / vp.y * GY)), 0, GY - 1)
			if sp.x + r < 0.0 or sp.x - r > vp.x or sp.y + r < 0.0 or sp.y - r > vp.y:
				continue
			for gy in range(gy0, gy1 + 1):
				for gx in range(gx0, gx1 + 1):
					var cx: float = (float(gx) + 0.5) / GX * vp.x
					var cy: float = (float(gy) + 0.5) / GY * vp.y
					if (cx - sp.x) * (cx - sp.x) + (cy - sp.y) * (cy - sp.y) <= r * r:
						grid[gy * GX + gx] += 1.0
	var sum: float = 0.0
	var mx: float = 0.0
	var over4: int = 0
	var over8: int = 0
	for v in grid:
		sum += v
		mx = maxf(mx, v)
		if v > 4.0:
			over4 += 1
		if v > 8.0:
			over8 += 1
	var n: float = float(GX * GY)
	return {"meanLayers": snappedf(sum / n, 0.01), "maxLayers": mx, "over4": snappedf(float(over4) / n, 0.001), "over8": snappedf(float(over8) / n, 0.001),
		"fragsAt720p": int(sum / n * 1280.0 * 720.0)}


func _info() -> Dictionary:
	return {"scene": scene_name, "overdraw": _overdraw(), "t": t, "drawCalls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		"size": [get_viewport().size.x, get_viewport().size.y], "od": od, "reduced": reduced,
		"gpu": RenderingServer.get_video_adapter_name()}


func _bench(cpu: int) -> void:
	var now: int = Time.get_ticks_usec()
	var warm: float = float(opts.get("warm", "2"))
	var dur: float = float(opts.get("dur", "10"))
	bench_t = t
	if bench_t > warm and bench_last > 0:
		frame_ms.append(float(now - bench_last) / 1000.0)
		cpu_us.append(float(cpu))
		draws.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		prims.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	bench_last = now
	if bench_t > warm + dur:
		bench = false
		var s := Array(frame_ms)
		s.sort()
		var n: int = s.size()
		var sum: float = 0.0
		for v in s:
			sum += v
		var cs := Array(cpu_us)
		cs.sort()
		var res := {"scene": scene_name, "reduced": reduced, "frames": n, "frameMs": {"avg": sum / n, "p50": s[n / 2], "p95": s[int(n * 0.95)], "max": s[n - 1]},
			"cpuUpdateUs": {"p50": cs[n / 2], "p95": cs[int(n * 0.95)]}, "drawCallsMax": draws.max(), "primitivesMax": prims.max(), "info": _info()}
		_js("window.__benchResult = %s;" % JSON.stringify(res))
		print("BENCH ", JSON.stringify(res))


func _apply(time: float) -> void:
	t = time
	for m in mats:
		m.set_shader_parameter("time", time)
		m.set_shader_parameter("od", 1.0 if od else 0.0)
		m.set_shader_parameter("reduced", 1.0 if reduced else 0.0)
	if apply_fn.is_valid():
		apply_fn.call(time)


# ------------------------------------------------------------------------------------------------------------- helpers
const SPRITE_SHADER := """
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, BLEND;
uniform float od = 0.0;
uniform float time = 0.0;
uniform float reduced = 0.0;
varying vec4 col;
varying float emis;
void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
	col = COLOR;
	emis = INSTANCE_CUSTOM.x;
}
void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float a = clamp(1.0 - dot(q, q), 0.0, 1.0);
	a = a * a * col.a;
	if (od > 0.5) {
		if (a < 0.02) { discard; }
		ALBEDO = vec3(1.0 / 64.0);
		ALPHA = 1.0;
	} else {
		ALBEDO = col.rgb * (1.0 + emis);
		ALPHA = a;
	}
}
"""


func _shader(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	mats.append(m)
	return m


func _sprites(n: int, additive: bool) -> Sprites:
	var s := Sprites.new()
	s.n = n
	s.mm = MultiMesh.new()
	s.mm.transform_format = MultiMesh.TRANSFORM_3D
	s.mm.use_colors = true
	s.mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	s.mm.mesh = q
	s.mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = s.mm
	var blend: String = "blend_add" if (additive or od) else "blend_mix"
	mi.material_override = _shader(SPRITE_SHADER.replace("BLEND", blend))
	mi.custom_aabb = AABB(Vector3(-1.0e6, -1.0e6, -1.0e6), Vector3(2.0e6, 2.0e6, 2.0e6))
	add_child(mi)
	s.buf.resize(n * 20)
	sets.append(s)
	return s


func _put(s: Sprites, i: int, p: Vector3, size: float, c: Color, emis: float = 0.0) -> void:
	var o: int = i * 20   # (packed arrays are copy-on-write: write through s.buf itself)
	s.buf[o] = size; s.buf[o + 1] = 0.0; s.buf[o + 2] = 0.0; s.buf[o + 3] = p.x
	s.buf[o + 4] = 0.0; s.buf[o + 5] = size; s.buf[o + 6] = 0.0; s.buf[o + 7] = p.y
	s.buf[o + 8] = 0.0; s.buf[o + 9] = 0.0; s.buf[o + 10] = size; s.buf[o + 11] = p.z
	s.buf[o + 12] = c.r; s.buf[o + 13] = c.g; s.buf[o + 14] = c.b; s.buf[o + 15] = c.a
	s.buf[o + 16] = emis; s.buf[o + 17] = 0.0; s.buf[o + 18] = 0.0; s.buf[o + 19] = 0.0


func _hide(s: Sprites, i: int) -> void:
	_put(s, i, Vector3(0, -1.0e6, 0), 0.0, Color(0, 0, 0, 0))


func _flush(s: Sprites) -> void:
	s.mm.buffer = s.buf


const OPAQUE_HEAD := """
shader_type spatial;
render_mode unshaded;
uniform float od = 0.0;
uniform float time = 0.0;
uniform float reduced = 0.0;
varying vec3 wp;
varying vec3 wn;
float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float vnoise3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1,0,0)), f.x), mix(hash3(i + vec3(0,1,0)), hash3(i + vec3(1,1,0)), f.x), f.y);
	float b = mix(mix(hash3(i + vec3(0,0,1)), hash3(i + vec3(1,0,1)), f.x), mix(hash3(i + vec3(0,1,1)), hash3(i + vec3(1,1,1)), f.x), f.y);
	return mix(a, b, f.z);
}
"""


func _grid(nx: int, nz: int, x0: float, x1: float, zs: Array, hf: Callable, cf: Callable) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in nz:
		for i in nx + 1:
			var x: float = lerpf(x0, x1, float(i) / float(nx))
			var z: float = zs[k]
			st.set_color(cf.call(x, z))
			st.add_vertex(Vector3(x, hf.call(x, z), z))
	for k in nz - 1:
		for i in nx:
			var a: int = k * (nx + 1) + i
			var b: int = a + 1
			var c: int = a + nx + 1
			var d: int = c + 1
			st.add_index(a); st.add_index(c); st.add_index(b)
			st.add_index(b); st.add_index(c); st.add_index(d)
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------------------------------------- effect 1: the magma cut
const CUT_HALF: float = 2400.0     # the cut is 4,800 units long (64 fighter heights)
const CUT_DEPTH: float = 2080.0    # today's deformation floor (WorldCrater.DEFORM_FLOOR)
const MAGMA_BELOW: float = 610.0   # where the sim probe's magma stood (sim_probe.gd)


func _base_h(x: float, z: float) -> float:
	return 120.0 * sin(x * 0.0009) + 80.0 * sin(x * 0.0021 + 1.3) + 60.0 * sin(z * 0.002 + x * 0.0007)


func _along(x: float) -> float:
	return smoothstep(-CUT_HALF - 300.0, -CUT_HALF + 100.0, x) * (1.0 - smoothstep(CUT_HALF - 100.0, CUT_HALF + 300.0, x))


func _cut_h0(x: float, z: float) -> float:
	return _base_h(x, z) - CUT_DEPTH * _along(x) * (1.0 - smoothstep(170.0, 330.0, absf(z)))


## The game's foreground rule (render's fore_fall): in front of the fighter plane, the ground never rises above the
## plane's own profile less 3% of its depth, so a deep cut on the plane reads from the side as a notch.
func _cut_h(x: float, z: float) -> float:
	var h: float = _cut_h0(x, z)
	if z > 0.0:
		var prof: float = _cut_h0(x, 0.0)
		if _along(x) > 0.6:
			prof = maxf(prof, _base_h(x, 0.0) - MAGMA_BELOW)   # the plane's surface there is the magma's (as with water)
		h = minf(h, prof - 0.03 * z)
	return h


var mg_bub: Sprites
var mg_glow: Sprites
var mg_smoke: Sprites
var mg_seeds: Array = []


func _build_magma() -> void:
	env.background_color = Color(0.36, 0.42, 0.55)
	cam.position = Vector3(0, 500, 6800)
	cam.look_at(Vector3(0, -800, 0))
	var zs: Array = [7000.0, 4000.0, 2400.0, 1400.0, 900.0, 600.0, 400.0, 300.0, 240.0, 180.0, 120.0, 60.0, 0.0, -60.0, -120.0, -180.0, -240.0, -300.0, -400.0, -700.0, -1200.0, -2000.0, -3200.0, -5000.0, -8000.0]
	var gm := _grid(360, zs.size(), -6000.0, 6000.0, zs, _cut_h, func(x: float, z: float) -> Color:
		var depth01: float = clampf((_base_h(x, z) - _cut_h(x, z)) / CUT_DEPTH, 0.0, 1.0)
		var near: float = _along(x) * (1.0 - smoothstep(200.0, 1100.0, absf(z)))
		var rock := Color(0.42, 0.37, 0.31).lerp(Color(0.24, 0.2, 0.18), depth01)
		return rock.lerp(Color(0.72, 0.3, 0.12), near * 0.45 + depth01 * 0.35))
	var g := MeshInstance3D.new()
	g.mesh = gm
	g.material_override = _shader(OPAQUE_HEAD + """
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = NORMAL; }
void fragment() {
	float l = 0.55 + 0.45 * max(dot(normalize(wn), normalize(vec3(-0.4, 0.8, 0.45))), 0.0);
	ALBEDO = od > 0.5 ? vec3(0.0) : COLOR.rgb * l;
}
""")
	add_child(g)
	# the magma surface: a strip in the cut at the level the sim probe reached
	var mzs: Array = [7000.0, 3000.0, 1200.0, 400.0, 200.0, 120.0, 40.0, -40.0, -120.0, -200.0]
	var mm := _grid(240, mzs.size(), -CUT_HALF, CUT_HALF, mzs, func(x: float, z: float) -> float:
		return _base_h(x, 0.0) - MAGMA_BELOW - 2000.0 * (1.0 - smoothstep(0.55, 0.7, _along(x))), func(x: float, z: float) -> Color: return Color.WHITE)
	var m := MeshInstance3D.new()
	m.mesh = mm
	# Flash rules: the colours keep R / (R + G + B) under 0.8 (no saturated red), the plates drift slowly and the whole
	# surface breathes at 0.19 Hz by 8% (4% reduced): nothing on it changes faster than about 0.2 Hz.
	m.material_override = _shader(OPAQUE_HEAD + """
float vn2(vec2 p) { return vnoise3(vec3(p, 0.0)); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wp.xz / 260.0;
	float n = vn2(p + vec2(time * 0.05, 0.0)) * 0.6 + vn2(p * 2.3 - vec2(0.0, time * 0.08)) * 0.4;
	float crust = smoothstep(0.55, 0.75, n);
	vec3 hot = vec3(1.0, 0.58, 0.16);
	vec3 warm = vec3(0.85, 0.28, 0.08);
	vec3 cr = vec3(0.20, 0.09, 0.06);
	vec3 c = mix(mix(warm, hot, smoothstep(0.2, 0.6, n)), cr, crust * 0.85);
	float amp = reduced > 0.5 ? 0.04 : 0.08;
	c *= 1.0 + amp * sin(time * 1.2);
	ALBEDO = od > 0.5 ? vec3(0.0) : c;
}
""")
	add_child(m)
	mg_bub = _sprites(60, false)
	mg_glow = _sprites(14, true)
	mg_smoke = _sprites(60, false)
	for i in 60:
		mg_seeds.append([rng.randf_range(-CUT_HALF + 300.0, CUT_HALF - 300.0), rng.randf_range(-170.0, 170.0), rng.randf(), rng.randf()])
	apply_fn = func(time: float) -> void:
		for i in 60:
			var s: Array = mg_seeds[i]
			var ph: float = fposmod(time * 0.31 + s[2], 1.0)
			var y: float = _base_h(s[0], 0.0) - MAGMA_BELOW
			var size: float = 40.0 + 140.0 * ph
			var a: float = smoothstep(0.0, 0.2, ph) * (1.0 - smoothstep(0.8, 1.0, ph)) * (0.55 if reduced else 0.8)
			_put(mg_bub, i, Vector3(s[0], y + size * 0.25, s[1]), size, Color(1.0, 0.7, 0.32, a), 0.3)
			var sp: float = fposmod(time * 0.12 + s[3], 1.0)
			_put(mg_smoke, i, Vector3(s[0] * 0.9, y + 200.0 + sp * 2600.0, s[1] - 100.0), 220.0 + sp * 900.0, Color(0.33, 0.3, 0.29, 0.32 * (1.0 - sp)), 0.0)
		for k in 14:
			var x: float = lerpf(-CUT_HALF + 300.0, CUT_HALF - 300.0, float(k) / 13.0)
			_put(mg_glow, k, Vector3(x, _base_h(x, 0.0) - 300.0, 0.0), 1500.0, Color(1.0, 0.45, 0.15, 0.2), 0.0)
		_flush(mg_bub)
		_flush(mg_smoke)
		_flush(mg_glow)


# -------------------------------------------------------------------------------------------- effect 2: the mushroom cloud
const N_STEM: int = 260
const N_CAP: int = 680
const N_SKIRT: int = 220
var cl_s: Sprites
var cl_fire: Sprites
var cl_ring: Sprites
var cl_seeds: Array = []
var sky_mat: ShaderMaterial
var ground_mat: ShaderMaterial


func _build_cloud() -> void:
	cam.position = Vector3(0, 6000, 42000)
	cam.look_at(Vector3(0, 8000, 0))
	# the sky: a far wall with the four-band idea reduced to a gradient, darkened by the atmosphere's value
	sky_mat = _shader(OPAQUE_HEAD + """
uniform float dark = 0.0;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 hor = vec3(0.78, 0.8, 0.86); vec3 top = vec3(0.24, 0.42, 0.78); vec3 smoke = vec3(0.17, 0.14, 0.13);
	vec3 c = mix(hor, top, smoothstep(0.0, 90000.0, wp.y));
	c = mix(c, smoke, dark);
	ALBEDO = od > 0.5 ? vec3(0.0) : c;
}
""")
	var sky := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(900000, 500000)
	sky.mesh = qm
	sky.position = Vector3(0, 200000, -250000)
	sky.material_override = sky_mat
	add_child(sky)
	ground_mat = _shader(OPAQUE_HEAD + """
uniform float dark = 0.0;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float d = length(wp.xz);
	vec3 c = mix(vec3(0.36, 0.42, 0.26), vec3(0.5, 0.46, 0.36), vnoise3(vec3(wp.xz / 9000.0, 0.0)));
	c = mix(c, vec3(0.74, 0.76, 0.82), smoothstep(30000.0, 240000.0, d));
	c *= 1.0 - 0.6 * dark;
	ALBEDO = od > 0.5 ? vec3(0.0) : c;
}
""")
	var gr := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600000, 600000)
	gr.mesh = pm
	gr.material_override = ground_mat
	add_child(gr)
	cl_s = _sprites(N_STEM + N_CAP + N_SKIRT, false)
	cl_fire = _sprites(1, true)
	cl_ring = _sprites(72, true)
	for i in N_STEM + N_CAP + N_SKIRT:
		cl_seeds.append([rng.randf(), rng.randf(), rng.randf(), rng.randf()])
	apply_fn = func(time: float) -> void:
		var tt: float = maxf(time, 0.0)
		var H: float = 14000.0 * (1.0 - exp(-tt / 7.0)) + 300.0
		var Rc: float = 600.0 + 3800.0 * (1.0 - exp(-tt / 5.0))
		var heat: float = exp(-tt / 2.2)
		var smoke := Color(0.42, 0.38, 0.35)
		var fire := Color(1.0, 0.62, 0.28)
		for i in N_STEM + N_CAP + N_SKIRT:
			var s: Array = cl_seeds[i]
			var p := Vector3.ZERO
			var size: float = 0.0
			var a: float = 0.0
			var h: float = heat * (1.0 - 0.6 * s[2])
			if i < N_STEM:
				var u: float = s[0]
				var rr: float = 0.22 * Rc * (1.0 - 0.3 * u) * s[1]
				var th: float = TAU * s[3]
				p = Vector3(cos(th) * rr, H * u * 0.92, sin(th) * rr)
				size = 0.3 * Rc
				a = 0.45
				h *= 1.0 - 0.5 * u
			elif i < N_STEM + N_CAP:
				var th2: float = TAU * s[0]
				var ph: float = TAU * s[1] + tt * 0.35
				var rm: float = 0.48 * Rc * (0.6 + 0.4 * s[3])
				var c := Vector3(cos(th2) * Rc, H, sin(th2) * Rc)
				p = c + Vector3(cos(th2) * rm * cos(ph), rm * sin(ph), sin(th2) * rm * cos(ph))
				size = 0.5 * Rc * (0.7 + 0.6 * s[2])
				a = 0.55
			else:
				var th3: float = TAU * s[0]
				var Rs: float = 1.7 * Rc * minf(tt / 8.0, 1.0) * (0.7 + 0.3 * s[1])
				p = Vector3(cos(th3) * Rs, 300.0 * s[2], sin(th3) * Rs)
				size = 0.55 * Rc
				a = 0.32 * minf(tt / 1.5, 1.0)
				h *= 0.3
			var col := smoke.lerp(fire, clampf(h, 0.0, 1.0))
			col.a = a
			_put(cl_s, i, p, size, col, h * 1.2)
		# the fireball: it grows and brightens over 0.6 s (1.0 s reduced), never in one frame; at this distance it is
		# a small share of the screen. No sky flash: the sky only darkens, slowly.
		var rise: float = 1.0 if reduced else 0.6
		var inten: float = smoothstep(0.0, rise, tt) * exp(-maxf(tt - rise, 0.0) / 1.5) * (0.6 if reduced else 1.0)
		_put(cl_fire, 0, Vector3(0, H * 0.85, 0), 400.0 + 3100.0 * smoothstep(0.0, 1.0, tt), Color(1.0, 0.78, 0.45, 0.85 * inten), 0.4)
		# the shock ring on the ground
		var rr2: float = 9000.0 * sqrt(tt)
		for k in 72:
			var th4: float = TAU * float(k) / 72.0
			var soft: bool = String(opts.get("ring", "bright")) == "soft"
			var ra: float = clampf(1.0 - tt / 6.0, 0.0, 1.0) * (0.12 if soft else 0.45) * (0.6 if reduced else 1.0)
			_put(cl_ring, k, Vector3(cos(th4) * rr2, 150.0, sin(th4) * rr2), 2600.0, Color(1.0, 0.85, 0.65, ra), 0.0)
		_flush(cl_s)
		_flush(cl_fire)
		_flush(cl_ring)
		# the sky darkens with the atmosphere state, slew-limited as the game's sky driver limits every change
		var dk: float = minf(0.6 * (1.0 - exp(-tt / 12.0)), 0.02 * tt)
		sky_mat.set_shader_parameter("dark", dk)
		ground_mat.set_shader_parameter("dark", dk)


# ----------------------------------------------------------------------------------- effect 3: the fight from orbit
var or_mat: ShaderMaterial
var or_fx: Sprites
var or_stars: Sprites
var blasts: Array = []   # [launch time, fighter index, target dir]
var fighters_p: Array = []


func _build_orbit() -> void:
	var R: float = R_PLANET
	cam.position = Vector3(0, 0.42 * R, 3.35 * R)
	cam.look_at(Vector3(0, 0.12 * R, 0))
	or_mat = _shader(OPAQUE_HEAD + """
uniform vec4 imp[8];
uniform float imp_ramp = 0.25;
uniform float imp_gain = 1.0;
varying vec3 op;
void vertex() { op = VERTEX; wn = NORMAL; }
float fbm(vec3 p) { return 0.55 * vnoise3(p) + 0.3 * vnoise3(p * 2.1) + 0.15 * vnoise3(p * 4.3); }
void fragment() {
	vec3 p = normalize(op);
	float n = fbm(p * 3.0 + vec3(11.0));
	float land = smoothstep(0.5, 0.53, n);
	vec3 ocean = vec3(0.07, 0.2, 0.42);
	vec3 lc = mix(vec3(0.25, 0.4, 0.18), vec3(0.55, 0.47, 0.3), fbm(p * 7.0));
	vec3 c = mix(ocean, lc, land);
	float ice = smoothstep(0.78, 0.86, abs(p.y) + 0.06 * fbm(p * 9.0));
	c = mix(c, vec3(0.92, 0.95, 0.98), ice);
	float diff = clamp(dot(p, normalize(vec3(-0.45, 0.35, 0.82))) * 1.15 + 0.12, 0.04, 1.0);
	vec3 col = c * diff;
	for (int k = 0; k < 8; k++) {
		vec4 im = imp[k];
		float age = time - im.w;
		if (im.w > -0.5 && age > 0.0) {
			float ang = acos(clamp(dot(p, im.xyz), -1.0, 1.0));
			float inten = smoothstep(0.0, imp_ramp, age) * exp(-max(age - imp_ramp, 0.0) / 1.6) * imp_gain;
			float s = 0.012 + 0.008 * age;
			float g = inten * exp(-(ang * ang) / (s * s));
			float rr = 0.035 * sqrt(age);
			float dr = (ang - rr) / 0.004;
			float ring = exp(-dr * dr) * exp(-age / 2.5) * 0.5 * imp_gain;
			float scar = (1.0 - smoothstep(0.0, 0.03, ang)) * min(age / 2.0, 1.0) * 0.6;
			col = col * (1.0 - scar) + vec3(1.0, 0.66, 0.32) * g * 1.4 + vec3(1.0, 0.8, 0.6) * ring;
		}
	}
	ALBEDO = od > 0.5 ? vec3(0.0) : col;
}
""")
	var planet := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = R
	sm.height = 2.0 * R
	sm.radial_segments = 192
	sm.rings = 96
	planet.mesh = sm
	planet.material_override = or_mat
	add_child(planet)
	var rim := MeshInstance3D.new()
	var sm2 := SphereMesh.new()
	sm2.radius = R * 1.03
	sm2.height = 2.0 * R * 1.03
	sm2.radial_segments = 96
	sm2.rings = 48
	rim.mesh = sm2
	rim.material_override = _shader("""
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform float od = 0.0;
uniform float time = 0.0;
uniform float reduced = 0.0;
void fragment() {
	float f = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 3.0);
	ALBEDO = od > 0.5 ? vec3(1.0 / 64.0) : vec3(0.35, 0.6, 1.0) * f * 0.7;
}
""")
	add_child(rim)
	or_stars = _sprites(400, true)
	for i in 400:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, -0.2)).normalized()
		_put(or_stars, i, d * 20.0 * R, 0.012 * R, Color(0.8, 0.85, 1.0, 0.5), 0.0)
	_flush(or_stars)
	# two fighters in the upper exosphere (0.7 R up), on the side facing the camera
	fighters_p = [Vector3(0.3, 0.5, 1.0).normalized() * 1.7 * R, Vector3(-0.25, 0.45, 1.0).normalized() * 1.7 * R]
	for k in 6:
		var dir := Vector3(rng.randf_range(-0.45, 0.45), rng.randf_range(0.05, 0.5), 1.0).normalized()
		blasts.append([0.5 + 1.6 * k, k % 2, dir])
	or_fx = _sprites(2 * 13 + 6 * 24, true)
	apply_fn = func(time: float) -> void:
		var i: int = 0
		var cols := [Color(0.6, 0.85, 1.0), Color(1.0, 0.55, 0.42)]
		for f in 2:
			var fp: Vector3 = fighters_p[f]
			var wob := Vector3(sin(time * 0.7 + f), cos(time * 0.5 + 2.0 * f), 0.0) * 0.02 * R_PLANET
			for k in 13:
				var tp: Vector3 = fp + wob - Vector3(float(k) * 0.006 * R_PLANET * (1.0 if f == 0 else -1.0), 0.0, 0.0)
				var cc: Color = cols[f]
				cc.a = 0.9 if k == 0 else 0.35 * (1.0 - float(k) / 13.0)
				_put(or_fx, i, tp, (0.014 if k == 0 else 0.008) * R_PLANET, cc, 0.0)
				i += 1
		var imps := PackedVector4Array()
		for b in blasts:
			var t0: float = b[0]
			var fp2: Vector3 = fighters_p[b[1]]
			var target: Vector3 = (b[2] as Vector3) * R_PLANET
			var u: float = (time - t0) / 1.0
			for k in 24:
				var uu: float = u - float(k) * 0.012
				if uu < 0.0 or uu > 1.0:
					_hide(or_fx, i)
				else:
					var cc2: Color = cols[b[1]]
					cc2.a = 0.85 * (1.0 - float(k) / 24.0)
					_put(or_fx, i, fp2.lerp(target, uu), 0.006 * R_PLANET, cc2, 0.0)
				i += 1
			imps.append(Vector4((b[2] as Vector3).x, (b[2] as Vector3).y, (b[2] as Vector3).z, t0 + 1.0))
		while imps.size() < 8:
			imps.append(Vector4(0, 0, 0, -1))
		or_mat.set_shader_parameter("imp", imps)
		or_mat.set_shader_parameter("imp_ramp", 0.5 if reduced else 0.25)
		or_mat.set_shader_parameter("imp_gain", 0.6 if reduced else 1.0)
		_flush(or_fx)


# ---------------------------------------------------------------------------------------------- effect 4: the collapse
const N_TOWERS: int = 60
const N_FALL: int = 30
const N_DEB: int = 3000
var co_towers: MultiMesh
var co_tbuf := PackedFloat32Array()
var co_t: Array = []      # [x, z, w, h, d, delay, tilt sign, falls]
var co_deb: MultiMesh
var co_dbuf := PackedFloat32Array()
var co_dseed: Array = []
var co_dust: Sprites
var co_glow: Sprites


func _build_collapse() -> void:
	env.background_color = Color(0.5, 0.57, 0.7)
	cam.position = Vector3(0, 2600, 21000)
	cam.look_at(Vector3(0, 1400, -2500))
	var gr := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200000, 200000)
	gr.mesh = pm
	gr.material_override = _shader(OPAQUE_HEAD + """
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c = vec3(0.36, 0.37, 0.38);
	float st = 1.0 - step(60.0, abs(mod(wp.z + 1500.0, 2000.0) - 1000.0));
	c = mix(c, vec3(0.5, 0.5, 0.5), st * 0.5);
	ALBEDO = od > 0.5 ? vec3(0.0) : c;
}
""")
	add_child(gr)
	co_towers = MultiMesh.new()
	co_towers.transform_format = MultiMesh.TRANSFORM_3D
	co_towers.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(1, 1, 1)
	co_towers.mesh = bm
	co_towers.instance_count = N_TOWERS
	var tmi := MultiMeshInstance3D.new()
	tmi.multimesh = co_towers
	tmi.material_override = _shader(OPAQUE_HEAD + """
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz; }
void fragment() {
	vec3 n = normalize(wn);
	vec3 c = COLOR.rgb;
	if (abs(n.y) < 0.5) {
		float u = abs(n.x) > 0.5 ? wp.z : wp.x;
		float win = step(0.3, fract(u / 90.0)) * step(0.35, fract(wp.y / 110.0));
		c = mix(c, vec3(0.13, 0.17, 0.25), win * 0.7);
	}
	float l = 0.6 + 0.4 * max(dot(n, normalize(vec3(-0.4, 0.7, 0.6))), 0.0);
	ALBEDO = od > 0.5 ? vec3(0.0) : c * l;
}
""")
	tmi.custom_aabb = AABB(Vector3(-1.0e5, -1.0e4, -1.0e5), Vector3(2.0e5, 1.0e5, 2.0e5))
	add_child(tmi)
	co_tbuf.resize(N_TOWERS * 16)
	var rows := [-500.0, -2500.0, -4500.0]
	for i in N_TOWERS:
		var x: float = -11000.0 + 22000.0 * (float(i % 20) + rng.randf_range(0.1, 0.8)) / 20.0
		var z: float = rows[i / 20]
		co_t.append([x, z, rng.randf_range(300.0, 520.0), rng.randf_range(1200.0, 3600.0), rng.randf_range(300.0, 500.0), 0.0, 1.0 if rng.randf() < 0.5 else -1.0, false])
	var order: Array = range(N_TOWERS)
	order.sort_custom(func(a, b): return absf(co_t[a][0]) + absf(co_t[a][1] + 2500.0) < absf(co_t[b][0]) + absf(co_t[b][1] + 2500.0))
	for k in N_FALL:
		var tw: Array = co_t[order[k]]
		tw[7] = true
		tw[5] = Vector2(tw[0], tw[1] + 2500.0).length() / 6000.0   # the implode mode's delay by distance (IMPLODE_SPEED idea)
	co_deb = MultiMesh.new()
	co_deb.transform_format = MultiMesh.TRANSFORM_3D
	co_deb.use_colors = true
	var dbm := BoxMesh.new()
	dbm.size = Vector3(1, 1, 1)
	co_deb.mesh = dbm
	co_deb.instance_count = N_DEB
	var dmi := MultiMeshInstance3D.new()
	dmi.multimesh = co_deb
	dmi.material_override = _shader(OPAQUE_HEAD + """
void fragment() { ALBEDO = od > 0.5 ? vec3(0.0) : COLOR.rgb; }
""")
	dmi.custom_aabb = AABB(Vector3(-1.0e5, -1.0e4, -1.0e5), Vector3(2.0e5, 1.0e5, 2.0e5))
	add_child(dmi)
	co_dbuf.resize(N_DEB * 16)
	var fallers: Array = []
	for tw in co_t:
		if tw[7]:
			fallers.append(tw)
	for k in N_DEB:
		var tw2: Array = fallers[k % fallers.size()]
		co_dseed.append([tw2, rng.randf_range(-1, 1), rng.randf_range(0.3, 1.0), rng.randf_range(-1, 1), rng.randf_range(0.0, 1.5), rng.randf_range(20.0, 70.0)])
	co_dust = _sprites(N_FALL * 16, false)
	co_glow = _sprites(1, true)
	apply_fn = func(time: float) -> void:
		var di: int = 0
		for i in N_TOWERS:
			var tw: Array = co_t[i]
			var p: float = 0.0
			if tw[7]:
				p = clampf((time - 1.0 - tw[5]) / 2.6, 0.0, 1.0)
			var hs: float = lerpf(1.0, 0.08, p * p)
			var h: float = tw[3] * hs
			var basis := Basis(Vector3(0, 0, 1), 0.12 * p * tw[6]) * Basis.from_scale(Vector3(tw[2], h, tw[4]))
			var o: int = i * 16
			co_tbuf[o] = basis.x.x; co_tbuf[o + 1] = basis.y.x; co_tbuf[o + 2] = basis.z.x; co_tbuf[o + 3] = tw[0]
			co_tbuf[o + 4] = basis.x.y; co_tbuf[o + 5] = basis.y.y; co_tbuf[o + 6] = basis.z.y; co_tbuf[o + 7] = h * 0.5
			co_tbuf[o + 8] = basis.x.z; co_tbuf[o + 9] = basis.y.z; co_tbuf[o + 10] = basis.z.z; co_tbuf[o + 11] = tw[1]
			var c := Color(0.6, 0.6, 0.62).lerp(Color(0.38, 0.36, 0.35), p)
			co_tbuf[o + 12] = c.r; co_tbuf[o + 13] = c.g; co_tbuf[o + 14] = c.b; co_tbuf[o + 15] = 1.0
			if tw[7]:
				for k in 16:
					var dt2: float = time - 1.0 - tw[5]
					if dt2 <= 0.0:
						_hide(co_dust, di)
					else:
						var ang: float = TAU * float(k) / 16.0
						var sp: float = minf(dt2 / 6.0, 1.0)
						var pos := Vector3(tw[0] + cos(ang) * (200.0 + 1300.0 * sp), 150.0 + 500.0 * sp + 300.0 * float(k % 3), tw[1] + sin(ang) * 400.0)
						_put(co_dust, di, pos, 300.0 + 1500.0 * sp, Color(0.55, 0.5, 0.45, 0.5 * (1.0 - sp * 0.6)), 0.0)
					di += 1
		co_towers.buffer = co_tbuf
		for k in N_DEB:
			var s: Array = co_dseed[k]
			var tw3: Array = s[0]
			var dt3: float = time - 1.0 - tw3[5] - s[4]
			var o2: int = k * 16
			var pos2 := Vector3(0, -1.0e5, 0)
			var sz: float = 0.0
			if dt3 > 0.0:
				var v := Vector3(s[1] * 700.0, s[2] * 900.0, s[3] * 400.0)
				pos2 = Vector3(tw3[0], tw3[3] * 0.7, tw3[1]) + v * dt3 + Vector3(0, -1250.0 * dt3 * dt3, 0)
				if pos2.y < s[5]:
					pos2.y = s[5]
				sz = s[5]
			co_dbuf[o2] = sz; co_dbuf[o2 + 1] = 0.0; co_dbuf[o2 + 2] = 0.0; co_dbuf[o2 + 3] = pos2.x
			co_dbuf[o2 + 4] = 0.0; co_dbuf[o2 + 5] = sz; co_dbuf[o2 + 6] = 0.0; co_dbuf[o2 + 7] = pos2.y
			co_dbuf[o2 + 8] = 0.0; co_dbuf[o2 + 9] = 0.0; co_dbuf[o2 + 10] = sz; co_dbuf[o2 + 11] = pos2.z
			co_dbuf[o2 + 12] = 0.45; co_dbuf[o2 + 13] = 0.43; co_dbuf[o2 + 14] = 0.42; co_dbuf[o2 + 15] = 1.0
		co_deb.buffer = co_dbuf
		var gt: float = time - 1.0
		var rise: float = 0.9 if reduced else 0.5
		var inten: float = smoothstep(0.0, rise, gt) * exp(-maxf(gt - rise, 0.0) / 2.0) * (0.55 if reduced else 0.9) if gt > 0.0 else 0.0
		_put(co_glow, 0, Vector3(0, 900, -2500), 5200.0, Color(1.0, 0.72, 0.42, inten * 0.7), 0.0)
		_flush(co_dust)
		_flush(co_glow)
