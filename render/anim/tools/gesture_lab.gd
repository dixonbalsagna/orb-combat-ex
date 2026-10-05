extends SceneTree
## Gesture lab (docs/animation/intro-gestures.md): Narrative's ten gesture intents through the real solver, as the sim's `intro_gesture {actor, intent, at}` event would start them (staged by hand
## here: the composer does not send it yet). Two fighters standing in their idles, the actor's own motion for the intent played over the idle, the same idle without it beside it (left), one clip a
## fighter with the ten intents in a row (each labelled new or reused). --measure runs headless and prints, for each intent, how far the pose moved from the idle, the joint violations that reach the
## screen, and whether the fighter has no motion for it (a silent skip).
##   godot --no-window --path . -s res://render/anim/tools/gesture_lab.gd -- --fighter=protagonist --out=a.rgb [--intent=claim] [--size=300x200] [--step=2] [--idle=...] [--measure]
const DT := 1.0 / 60.0
const INTENTS := ["acknowledge", "appraise", "dismiss", "defer", "brace", "ease", "claim", "check", "soften", "harden"]
const FIGHTERS := {"protagonist": "KAI", "antihero": "VORR"}
const PRE := 14
const POST := 14
var fighter: String = "protagonist"
var only: String = ""
var out: String = "gesture.rgb"
var measure: bool = false
var size := Vector2i(300, 200)
var step: int = 2
var main: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fighter="):
			fighter = a.substr(10)
		elif a.begins_with("--intent="):
			only = a.substr(9)
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a == "--measure":
			measure = true
		elif a.begins_with("--size="):
			var p: PackedStringArray = a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--step="):
			step = int(a.substr(7))
	RenderAnim.joint_audit = measure
	DirData.templatesProfile = "dynamic"
	var vpn := SubViewport.new()
	vpn.size = Vector2i(640, 360)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


## One run of the stand-off: the gesture event at tick PRE (or none), the solved poses of the actor (and the other) from there.
func _play(S: SimState, intent: String, with_gesture: bool, dur_ticks: int) -> Array:
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = FIGHTERS[fighter]
	f1.id = "VORR" if fighter == "protagonist" else "KAI"
	RenderAnim._fighters.clear()
	S.dirS.ex = null
	f0.x = 500.0
	f1.x = 560.0
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	var frames: Array = []
	for k in range(PRE + dur_ticks + POST):
		S.tick = 1000 + k
		S.T = 200.0 + float(k) * DT
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = DT
		te.frozen = false
		RenderAnim.consume(S, [te])
		if with_gesture and k == PRE:
			var ge := SimState.FxEvent.new()
			ge.type = "intro_gesture"
			ge.actor = 0.0
			ge.kind = intent
			ge.text = "look_start"
			ge.tick = S.tick
			RenderAnim.consume(S, [ge])
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		var a1: AnimFighter = RenderAnim.solve(S, f1)
		var viol: int = AnimJoints.violations(a0.q, a0._rd.shape_key).size() if measure else 0
		frames.append({"q": a0.q.duplicate(), "hips": a0.hips, "curl": a0.curl, "ro": a0.root_off, "vf": a0.vface, "q1": a1.q.duplicate(), "h1": a1.hips, "c1": a1.curl, "v1": a1.vface, "viol": viol, "gest": not a0._gest.is_empty()})
	return frames


func _run() -> void:
	await process_frame
	AnimData.load_all()
	AnimData.ensure_fighter(String(FIGHTERS[fighter]))
	AnimData.ensure_fighter("VORR" if fighter == "protagonist" else "KAI")
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(DT)
	var S: SimState = main.host.S
	RenderAnim.ground_feet = false
	var key: String = String(AnimData.fighter_key(String(FIGHTERS[fighter])))
	var tbl: Dictionary = AnimData.pair.get("roles", {}).get(key, {}).get("gestures", {})
	var list: Array = INTENTS if only == "" else [only]
	var runs: Array = []
	var report: Array = []
	for intent in list:
		var dur_ticks: int = 30
		if tbl.has(intent):
			var id: String = String(tbl[intent].get("seq", ""))
			dur_ticks = int(AnimData.entries[id].dur) if AnimData.entries.has(id) else 36
		var idle: Array = _play(S, String(intent), false, dur_ticks)
		var ges: Array = _play(S, String(intent), true, dur_ticks)
		var worst: float = 0.0
		var viol: int = 0
		var played: bool = false
		for k in range(idle.size()):
			for b in range(AnimRig.N):
				worst = maxf(worst, (idle[k].q[b] as Quaternion).angle_to(ges[k].q[b]))
			viol += int(ges[k].viol)
			played = played or bool(ges[k].gest)
		var reused: bool = tbl.has(intent) and not (String(tbl[intent].seq).begins_with("pi.") or String(tbl[intent].seq).begins_with("ri."))
		report.append("%-12s %s: seq %s, %d ticks, moves the pose up to %.2f rad, %d joint violations on screen%s" % [intent, "plays" if played else "SILENT SKIP", tbl[intent].get("seq", "-") if tbl.has(intent) else "-", dur_ticks, worst, viol, " (reused)" if reused else ""])
		runs.append({"intent": intent, "idle": idle, "ges": ges, "reused": reused, "played": played})
	if measure:
		print("gesture lab %s:\n  %s" % [fighter, "\n  ".join(report)])
		quit(0)
		return
	var sv := SubViewport.new()
	sv.size = size
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.15, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.85)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 120.0
	cam.environment = env
	sv.add_child(cam)
	cam.position = Vector3(0.0, 8.0, 300.0)
	cam.current = true
	var pals: Array = [{"body": Color("#3d8fdc"), "legs": Color("#1b1f2a"), "arms": Color("#e6b995"), "skin": Color("#efc7a2"), "gear": Color("#cdd6e4"), "accent": Color("#4fb9a8"), "hair": Color("#22c7a0")},
		{"body": Color("#2a2043"), "legs": Color("#181228"), "arms": Color("#b98462"), "skin": Color("#b98462"), "gear": Color("#cbd3e2"), "accent": Color("#9a80d8"), "hair": Color("#1d1630")}]
	if fighter == "antihero":
		pals.reverse()
	var bodies: Array = []
	var pivots: Array = []
	for i in range(2):
		var pv := Node3D.new()
		sv.add_child(pv)
		var bd := AnimBody.new()
		bd.build(pals[i], false)
		pv.add_child(bd)
		pivots.append(pv)
		bodies.append(bd)
	var ground := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(400.0, 2.0, 2.0)
	ground.mesh = bm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.35, 0.4, 0.5)
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground.material_override = gmat
	sv.add_child(ground)
	ground.position = Vector3(0.0, -43.0, 0.0)
	var cl := CanvasLayer.new()
	sv.add_child(cl)
	var label := Label.new()
	label.position = Vector2(4, 2)
	label.add_theme_font_size_override("font_size", 11)
	cl.add_child(label)
	# two clips in one file, side by side by gif.mjs: the idle without the gesture, the gesture. This file is the gesture; --idle is written beside it.
	var fa := FileAccess.open(out, FileAccess.WRITE)
	var fi := FileAccess.open(out.get_basename() + "_idle.rgb", FileAccess.WRITE)
	var total: int = 0
	for r in runs:
		total += int(ceil(float(r.ges.size()) / float(step)))
	for f in [fa, fi]:
		f.store_32(size.x)
		f.store_32(size.y)
		f.store_32(total)
	for r in runs:
		for which in ["ges", "idle"]:
			var fr: Array = r[which]
			for k in range(0, fr.size(), step):
				var e: Dictionary = fr[k]
				label.text = "%s  %s%s%s" % [fighter, String(r.intent), (" (new)" if not r.reused else " (reused)") if which == "ges" else "", "" if which == "ges" else "   idle only"]
				if which == "ges" and not r.played:
					label.text += "   no motion: silent skip"
				for i in range(2):
					pivots[i].scale = Vector3(float(e.vf) if i == 0 else float(e.v1), 1.0, 1.0)
					pivots[i].position = Vector3(-30.0 if i == 0 else 30.0, -43.0, 0.0)
					if i == 0:
						bodies[0].apply(e.q, e.hips, e.curl, e.ro)
					else:
						bodies[1].apply(e.q1, e.h1, e.c1, Vector3.ZERO)
				for _w in range(4):
					await process_frame
				var img: Image = sv.get_texture().get_image()
				img.convert(Image.FORMAT_RGB8)
				(fa if which == "ges" else fi).store_buffer(img.get_data())
	fa.close()
	fi.close()
	print("GESTURE LAB ", out, " ", total, " frames")
	print("gesture lab %s:\n  %s" % [fighter, "\n  ".join(report)])
	quit(0)
