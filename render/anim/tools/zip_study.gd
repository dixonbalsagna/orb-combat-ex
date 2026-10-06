extends Node
## The zip's view, drawn (docs/animation/zip.md section 15; the EP's Z1 brief): REAL zips of the director (DirZip, sim/director/zip.gd) started on a staged pair, played through the real sim and the real
## animation solver, and drawn by this scene in a fixed side view that follows the pair: the tell, the way in, the blow, the way out, every exit, every zip_end word and the drop. VIEW ONLY.
##   zip_strike_home / far / above / away    a zip strike on each of the four exits the AI zipper holds (back, the far side, above, away)
##   zip_heavy_home / far                    a zip heavy
##   end_stopped / end_outrun / end_shot     the director ends the zip on the way in (the sim's own function), the three words
##   end_countered / end_caught              the rival's light pressed in the arrival's window (a tech counter), and the hard AI's punish after the blow
##   end_down                                shot down on the way out: a drop of 24 ticks, a soft landing, the recovery
## Ways to run it (headless or the web build; never a window): as the main scene of a web export it loops every scenario in real time; with `window.__cap = 1` it steps one tick for each `window.__adv` the
## driver sets and publishes `window.__tick` and `window.__scn`; `window.__only = 'name'` plays one scenario. Headless: godot --headless --path . res://render/anim/tools/zip_study.tscn -- --measure
## prints what the body did for each scenario (phases, end word, exit, ticks drawn, violations on screen) and quits.
const DT := 1.0 / 60.0
const SCENARIOS := [
	{"id": "zip_strike_home", "label": "zip strike, home exit: the stick is let go, he steps back to where he began", "who": 0, "heavy": false, "exit": 0},
	{"id": "zip_strike_far", "label": "zip strike, far-side exit: through the rival and out the other side, over him", "who": 0, "heavy": false, "exit": 1},
	{"id": "zip_strike_above", "label": "zip strike, a point above: a run up and round", "who": 0, "heavy": false, "exit": 2},
	{"id": "zip_strike_away", "label": "zip strike, a point away: a run back and out", "who": 0, "heavy": false, "exit": 3},
	{"id": "zip_heavy_home", "label": "zip heavy, home exit: the coil, the lunge, the blow, the step back", "who": 0, "heavy": true, "exit": 0},
	{"id": "zip_heavy_far", "label": "zip heavy, far-side exit", "who": 0, "heavy": true, "exit": 1},
	{"id": "zip_strike_far_rival", "label": "the rival's zip strike, far-side exit", "who": 1, "heavy": false, "exit": 1},
	{"id": "zip_heavy_home_rival", "label": "the rival's zip heavy, home exit", "who": 1, "heavy": true, "exit": 0},
	{"id": "end_stopped", "label": "ended: stopped (he let go on the way in; the stance takes over)", "who": 0, "heavy": false, "exit": 0, "hook": "in", "why": "stopped"},
	{"id": "end_outrun", "label": "ended: outrun (the rival got away; he is carried past off balance)", "who": 0, "heavy": false, "exit": 0, "hook": "in", "why": "outrun"},
	{"id": "end_shot", "label": "ended: shot (a shot stopped the zip strike on the way in)", "who": 0, "heavy": false, "exit": 0, "hook": "in", "why": "shot"},
	{"id": "end_countered", "label": "ended: countered (a light pressed in the arrival's window)", "who": 0, "heavy": false, "exit": 0, "ans": 10},
	{"id": "end_caught", "label": "ended: caught (the hard rival punishes him in reach)", "who": 0, "heavy": false, "exit": 0, "level": "hard", "seeds": [4, 5, 6, 7, 8, 9, 10, 11]},
	{"id": "end_down", "label": "ended: down (shot on the way out: a fall of 24 ticks, a soft landing, the recovery)", "who": 0, "heavy": false, "exit": 0, "hook": "out", "why": "down", "after": 70},
]
const PAL_A := {"body": Color("#3d8fdc"), "legs": Color("#1b1f2a"), "arms": Color("#e6b995"), "skin": Color("#efc7a2"), "gear": Color("#cdd6e4"), "accent": Color("#4fb9a8"), "hair": Color("#22c7a0")}
const PAL_B := {"body": Color("#2a2043"), "legs": Color("#181228"), "arms": Color("#b98462"), "skin": Color("#b98462"), "gear": Color("#cbd3e2"), "accent": Color("#9a80d8"), "hair": Color("#1d1630")}
var main: Node
var S: SimState
var bodies: Array = []
var pivots: Array = []
var label: Label
var cam: Camera3D
var measure: bool = false
var cap: bool = false
var only: String = ""
var ready_to_run: bool = false
var scn_i: int = 0
var k: int = 0
var acc: float = 0.0
var adv_done: int = 0
var seed_i: int = 0
var zi: int = 0          # the zipper's slot
var started: bool = false
var after: int = 0
var hook_done: bool = false
var cam_x: float = 0.0
var cam_y: float = 0.0
var rec := {"phases": [], "end": "", "exit": "", "pass": "", "in": 0, "out": 0, "drawn_in": 0, "drawn_out": 0, "screen": 0, "nan": 0, "drop": 0}


func _js(expr: String, default):
	if not OS.has_feature("web"):
		return default
	var v = JavaScriptBridge.eval(expr, true)
	return default if v == null else v


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--measure":
			measure = true
		elif a.begins_with("--only="):
			only = a.substr(7)
	if OS.has_feature("web"):
		cap = float(_js("window.__cap || 0", 0.0)) > 0.0
		var o = _js("window.__only || ''", "")
		if String(o) != "":
			only = String(o)
	AnimData.load_waves = true
	RenderAnim.press_styles = true
	RenderAnim.joint_audit = false
	DirData.templatesProfile = "dynamic"
	var vpn := SubViewport.new()
	vpn.size = Vector2i(640, 360)
	vpn.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vpn.own_world_3d = true
	add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_setup.call_deferred()


func _setup() -> void:
	await get_tree().process_frame
	AnimData.load_all()
	if not measure:
		_build_view()
	ready_to_run = true
	_start_scenario()


func _build_view() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.15, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.85)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 450.0
	cam.environment = env
	add_child(cam)
	cam.position = Vector3(0.0, 0.0, 400.0)
	cam.current = true
	for i in range(2):
		var pv := Node3D.new()
		add_child(pv)
		var bd := AnimBody.new()
		bd.build(PAL_A if i == 0 else PAL_B, false)
		pv.add_child(bd)
		pivots.append(pv)
		bodies.append(bd)
	var ground := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2400.0, 2.0, 2.0)
	ground.mesh = bm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.35, 0.4, 0.5)
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground.material_override = gmat
	ground.name = "Ground"
	add_child(ground)
	var cl := CanvasLayer.new()
	add_child(cl)
	label = Label.new()
	label.position = Vector2(8, 4)
	label.add_theme_font_size_override("font_size", 16)
	cl.add_child(label)


func _scenarios() -> Array:
	var out: Array = []
	for s in SCENARIOS:
		if only == "" or only == String(s.id) or (only.ends_with("*") and String(s.id).begins_with(only.trim_suffix("*"))):
			out.append(s)
	return out


func _start_scenario() -> void:
	var list: Array = _scenarios()
	var sc: Dictionary = list[scn_i % list.size()]
	load("res://sim/director/ai.gd").set("level", String(sc.get("level", "easy")))
	var sd: int = int((sc.get("seeds", [4]) as Array)[seed_i % (sc.get("seeds", [4]) as Array).size()])
	RenderAnim._fighters.clear()
	main.start_match(sd, {"p1": true, "p2": true})
	for i in range(6):
		main.frame(DT)
	S = main.host.S
	zi = int(sc.who)
	var z = S.fighters[zi]
	var o = S.fighters[1 - zi]
	S.dirS.ex = null
	var dir: float = 1.0 if zi == 0 else -1.0
	z.x = 1500.0   # clear ground on both sides (the exit points are probed against the ground and the buildings), and 940 units to the left of it before the world wraps at 0
	o.x = z.x + 450.0 * dir
	for f in [z, o]:
		f.y = WorldTerrain.groundY(S, f.x)
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
		f.stunTicks = 0
		f.ki = 100.0
	DirZip.start(S, z, o, bool(sc.heavy), S.tick)
	DirZip._s(z, DirZip.AI_EXIT, int(sc.exit))
	if sc.has("ans"):
		DirZip._s(o, DirZip.AI_ANS, 3)
		DirZip._s(o, DirZip.AI_AT, S.tick + int(sc.ans))
	k = 0
	started = false
	after = 0
	hook_done = false
	rec = {"phases": [], "end": "", "exit": "", "pass": "", "in": 0, "out": 0, "drawn_in": 0, "drawn_out": 0, "screen": 0, "nan": 0, "drop": 0}
	cam_x = z.x + SimWrap.sdx(z.x, o.x) * 0.5
	cam_y = (z.y + o.y) * 0.5 + 60.0


func _hook(sc: Dictionary, z, r: Dictionary) -> void:
	if hook_done or not sc.has("hook") or r.is_empty() or String(r.phase) != String(sc.hook) or int(r.n) < 2:
		return
	hook_done = true
	var why: String = String(sc.why)
	DirZip._end(S, z, why)
	var vx: float = z.vx
	var vy: float = z.vy
	z.rush = null
	if why == "down":
		SimFighter.drop(S, z, int(DirZip.cfg().knockdownTicks), vx, vy)


func _step_tick() -> void:
	var list: Array = _scenarios()
	var sc: Dictionary = list[scn_i % list.size()]
	var z = S.fighters[zi]
	var o = S.fighters[1 - zi]
	var r0: Dictionary = DirZip.read(S, z)
	_hook(sc, z, r0)
	main.frame(DT)
	var az: AnimFighter = RenderAnim.fighter(S, z)
	var ao: AnimFighter = RenderAnim.fighter(S, o)
	var r: Dictionary = DirZip.read(S, z)
	if not r.is_empty():
		started = true
		if (rec.phases as Array).is_empty() or String(rec.phases[rec.phases.size() - 1]) != String(r.phase):
			rec.phases.append(String(r.phase))
		if String(r.phase) == "in":
			rec["in"] += 1
			rec.drawn_in += 1 if (not az.zip.is_empty() and String(az.zip.phase) == "in") else 0
		if String(r.phase) == "out":
			rec["out"] += 1
			rec.drawn_out += 1 if (not az.zip.is_empty() and String(az.zip.phase) == "out") else 0
		rec.exit = String(r.exit) if String(r.exit) != "" else rec.exit
		rec["pass"] = String(r["pass"]) if String(r["pass"]) != "" else rec["pass"]
	if z.state == "dropped":
		rec.drop += 1
	for i in range(AnimRig.N):
		if is_nan(az.q[i].x) or is_nan(az.q[i].w):
			rec.nan += 1
	rec.screen += AnimJoints.violations(az.q, az._rd.shape_key).size() + AnimJoints.violations(ao.q, ao._rd.shape_key).size()
	if started and r.is_empty():
		after += 1
		if String(rec.end) == "":
			rec.end = az._zip_last_end
	if not measure:
		# the camera follows the middle of the pair, smoothed (the way out of a far-side exit goes past the rival)
		cam_x += SimWrap.sdx(cam_x, z.x + SimWrap.sdx(z.x, o.x) * 0.5) * 0.55
		cam_y += ((z.y + o.y) * 0.5 + 40.0 - cam_y) * 0.55
		# the view closes in on the pair and opens as he leaves it: wide enough for both, never under 230 units high
		var want: float = clampf(maxf((absf(SimWrap.sdx(z.x, o.x)) + 260.0) / 1.78, absf(z.y - o.y) + 300.0), 230.0, 900.0)
		cam.size += (want - cam.size) * 0.45
		for i in range(2):
			var f = z if i == 0 else o
			var af: AnimFighter = az if i == 0 else ao
			pivots[i].scale = Vector3(af.vface, 1.0, 1.0)
			pivots[i].position = Vector3(SimWrap.sdx(cam_x, f.x), f.y - cam_y - 34.0, 0.0)
			bodies[i].apply(af.q, af.hips, af.curl, af.root_off)
		var gy: float = WorldTerrain.groundY(S, z.x)
		get_node("Ground").position = Vector3(0.0, gy - cam_y - 34.0 - 1.0, 0.0)
		var ph: String = String(r.phase) if not r.is_empty() else ("(drop)" if z.state == "dropped" else "")
		label.text = "%s   %s   tick %d%s" % [String(sc.label), ph, k, ("   ended: " + String(rec.end)) if String(rec.end) != "" else ""]
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__scn = '%s'; window.__k = %d;" % [String(sc.id), k], true)
	k += 1
	var limit: int = int(sc.get("after", 30))
	if (started and after > limit) or k > 600:
		_next()


func _next() -> void:
	var list: Array = _scenarios()
	var sc: Dictionary = list[scn_i % list.size()]
	if measure:
		print("ZIPSTUDY %s: phases %s end %s exit %s pass %s in %d (drawn %d) out %d (drawn %d) drop %d nan %d screen %d" % [String(sc.id), str(rec.phases), String(rec.end), String(rec.exit), String(rec["pass"]), rec["in"], rec.drawn_in, rec["out"], rec.drawn_out, rec.drop, rec.nan, rec.screen])
	# the caught scenario tries seeds until the hard AI punishes
	if sc.has("seeds") and String(rec.end) != "caught" and seed_i < (sc.seeds as Array).size() - 1:
		seed_i += 1
		_start_scenario()
		return
	seed_i = 0
	scn_i += 1
	if measure and scn_i >= list.size():
		ready_to_run = false
		get_tree().quit(0)
		return
	_start_scenario()


func _process(delta: float) -> void:
	if not ready_to_run:
		return
	if measure:
		for _i in range(40):
			if not ready_to_run:
				return
			_step_tick()
		return
	if cap:
		var adv: int = int(float(_js("window.__adv || 0", 0.0)))
		if adv > adv_done:
			adv_done = adv
			_step_tick()
			if OS.has_feature("web"):
				JavaScriptBridge.eval("window.__tick = %d;" % adv_done, true)
		return
	acc += minf(delta, 0.1)
	while acc >= DT:
		acc -= DT
		_step_tick()
