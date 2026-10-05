extends SceneTree
## Press lab (docs/animation/press-styles.md): plays a string of blows in one press style on a launch fighter against a dummy defender,
## through the real solver (the real AnimFighter, the real exchange beats, the contact solve and the defender's hit reaction), in a close
## fixed side view. The lab hands the director's beats over by hand, each with the `style` field the plan asks the sim to stamp
## (args.style), so it shows what a stamped beat plays. Scenes:
##   tech    three timed blows, 30 ticks apart: the tell, the contact pose with no in-between, the held beat, the quick return
##   speed   five mashed blows, 8 ticks apart: contact on the trigger frame, alternating limbs, a loose body, the retract blended
##   heavy   one held blow: the wind-up squash, the release's stretch with its smear frame, the held follow-through
##   combo   three mashed blows and a heavy closer (the style changes inside a string)
##   push    one push: no impact snap, the blow drives into its contact (style push)
##   check   three checks (`check: true`): a cross, a short elbow and a low kick thrown over the guard: the other arm stays set
## Needs a window to draw; run it with --no-window (offscreen), never a window.
##   godot --no-window --path . -s res://render/anim/tools/press_lab.gd -- --scene=speed --fighter=protagonist --out=a.rgb [--off] [--path] [--size=300x190] [--step=1]
## --off plays the same beats with the press styles off (the before). --path draws the striking limb's tip path (the VFX hand-off) as dots.
## --measure runs headless and prints what the solver did (contact error, joint audit, the limb path length) as one line.

const DT := 1.0 / 60.0
const SCENES := {   # beats: [contact tick, piece, style, damage]
	"tech": {"kind": "light", "beats": [[42, "strike.jab", "tech", 26.0], [72, "strike.cross", "tech", 26.0], [102, "strike.hook", "tech", 30.0]]},
	"speed": {"kind": "light", "beats": [[36, "strike.jab", "speed", 20.0], [44, "strike.cross", "speed", 20.0], [52, "strike.jab", "speed", 20.0], [60, "strike.cross", "speed", 20.0], [68, "strike.hook", "speed", 22.0]]},
	"heavy": {"kind": "heavy", "beats": [[60, "strike.haymaker", "heavy", 66.0]]},
	"push": {"kind": "light", "beats": [[48, "strike.shoulder_check", "push", 10.0]]},
	"check": {"kind": "light", "beats": [[42, "strike.cross", "speed", 12.0, {"check": true}], [62, "strike.short_elbow", "speed", 12.0, {"check": true}], [82, "strike.low_kick", "speed", 12.0, {"check": true}]]},
	"combo": {"kind": "light", "beats": [[36, "strike.jab", "speed", 20.0], [45, "strike.cross", "speed", 20.0], [54, "strike.hook", "speed", 22.0], [90, "strike.haymaker", "heavy", 66.0]]},
}
const FIGHTERS := {"protagonist": "KAI", "antihero": "VORR"}
const DIST := 60.0

var scene: String = "speed"
var fighter: String = "protagonist"
var out: String = "press.rgb"
var off: bool = false
var show_path: bool = false
var measure: bool = false
var size := Vector2i(300, 190)
var step: int = 1
var main: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene = a.substr(8)
		elif a.begins_with("--fighter="):
			fighter = a.substr(10)
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a == "--off":
			off = true
		elif a == "--path":
			show_path = true
		elif a == "--measure":
			measure = true
		elif a == "--no-hand-tips":
			RenderAnim.hand_tips = false
		elif a == "--no-press":
			RenderAnim.press_styles = false
		elif a.begins_with("--size="):
			var p: PackedStringArray = a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--step="):
			step = int(a.substr(7))
	RenderAnim.press_styles = not off and not OS.get_cmdline_user_args().has("--no-press")
	RenderAnim.joint_audit = measure
	DirData.templatesProfile = "dynamic"
	var vpn := SubViewport.new()
	vpn.size = Vector2i(640, 360)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var sc: Dictionary = SCENES[scene]
	AnimData.load_all()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(DT)
	var S: SimState = main.host.S
	RenderAnim.ground_feet = false
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = FIGHTERS[fighter]
	f1.id = "VORR" if fighter == "protagonist" else "KAI"
	AnimData.ensure_fighter(String(f0.id))
	AnimData.ensure_fighter(String(f1.id))
	RenderAnim._fighters.clear()
	var sv: SubViewport = null
	var bodies: Array = []
	var pivots: Array = []
	var dots: Array = []
	var label: Label = null
	var fa: FileAccess = null
	var beats: Array = sc.beats
	var t_first: float = float(beats[0][0]) * DT
	var t_last: float = float(beats[beats.size() - 1][0]) * DT
	var pre: float = 0.45 if scene != "heavy" else 0.62
	var post: float = 0.55
	var start_t: float = t_first - pre
	var end_t: float = t_last + post
	if not measure:
		sv = SubViewport.new()
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
		cam.size = 118.0
		cam.environment = env
		sv.add_child(cam)
		cam.position = Vector3(0.0, 0.0, 300.0)
		cam.current = true
		var pals: Array = [{"body": Color("#3d8fdc"), "legs": Color("#1b1f2a"), "arms": Color("#e6b995"), "skin": Color("#efc7a2"), "gear": Color("#cdd6e4"), "accent": Color("#4fb9a8"), "hair": Color("#22c7a0")},
			{"body": Color("#2a2043"), "legs": Color("#181228"), "arms": Color("#b98462"), "skin": Color("#b98462"), "gear": Color("#cbd3e2"), "accent": Color("#9a80d8"), "hair": Color("#1d1630")}]
		if fighter == "antihero":
			pals.reverse()
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
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(0.35, 0.4, 0.5)
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ground.material_override = gm
		sv.add_child(ground)
		ground.position = Vector3(0.0, -43.0, 0.0)
		if show_path:
			for k in range(12):
				var dm := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 1.6
				sm.height = 3.2
				dm.mesh = sm
				var dmat := StandardMaterial3D.new()
				dmat.albedo_color = Color(1.0, 0.85, 0.2)
				dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				dm.material_override = dmat
				dm.visible = false
				sv.add_child(dm)
				dots.append(dm)
		var cl := CanvasLayer.new()
		sv.add_child(cl)
		label = Label.new()
		label.position = Vector2(4, 2)
		label.add_theme_font_size_override("font_size", 11)
		cl.add_child(label)
		fa = FileAccess.open(out, FileAccess.WRITE)
		fa.store_32(size.x)
		fa.store_32(size.y)
		fa.store_32(0)
	var base_t: float = 200.0
	var base_tick: int = 1000
	f0.x = 500.0
	f1.x = 500.0 + DIST
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	var ex := DirExchange.newEx(f0, f1, String(sc.kind))
	ex.n = 931
	ex.tag = "LAB"
	for b in beats:
		var heavy_b: bool = float(b[3]) >= 40.0
		var bargs := {"a": "A", "dmg": float(b[3]), "piece": String(b[1]), "style": String(b[2]), "o": {"big": heavy_b}}
		if b.size() > 4:
			bargs.merge(b[4], true)
		DirExchange.schedule(ex, float(b[0]) * DT, "strike", bargs)
	S.dirS.ex = ex
	var n_ticks: int = int(end_t / DT) + 2
	var sent: Array = []
	for _b in beats:
		sent.append(false)
	var frames: int = 0
	var cerr: float = 0.0
	var cframes: int = 0
	var viol: Dictionary = {}
	var vnotes: Dictionary = {}
	var styles_seen: Dictionary = {}
	var phases: Array = []
	var path_len: float = 0.0
	var prev_tip := Vector3.ZERO
	var have_tip: bool = false
	for k in range(n_ticks):
		S.tick = base_tick + k
		S.T = base_t + float(k) * DT
		ex.t = float(k) * DT
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = DT
		te.frozen = false
		RenderAnim.consume(S, [te])
		for bi in range(beats.size()):
			if not sent[bi] and ex.t >= float(beats[bi][0]) * DT - DT * 0.5:
				sent[bi] = true
				var de := SimState.FxEvent.new()
				de.type = "damage"
				de.victim = 1.0
				de.attacker = 0.0
				de.kind = "heavy" if float(beats[bi][3]) >= 40.0 else "light"
				de.amount = float(beats[bi][3])
				de.region = "core"
				RenderAnim.consume(S, [de])
		var af0: AnimFighter = RenderAnim.solve(S, f0)
		var af1: AnimFighter = RenderAnim.solve(S, f1)
		if not af0.press.is_empty():
			styles_seen[String(af0.press.style)] = true
			if phases.is_empty() or String(phases[phases.size() - 1]) != String(af0.press.phase):
				phases.append(String(af0.press.phase))
			var tip: Vector3 = af0.socket(String(af0.press.bone))
			if have_tip:
				path_len += tip.distance_to(prev_tip)
			prev_tip = tip
			have_tip = true
		if measure:
			var a0: Dictionary = af0.audit
			for stage in a0:
				viol[stage] = int(viol.get(stage, 0)) + ((a0[stage] as Array).size() if a0[stage] is Array else 0)
				if a0[stage] is Array and stage == "D":
					for vv in (a0[stage] as Array):
						vnotes["%s %s %.0f @%s %d" % [vv[0], vv[1], float(vv[2]), String(af0.press.get("phase", "-")), roundi((float(k) * DT - float(beats[0][0]) * DT) / DT)]] = true
			continue
		if ex.t >= start_t and (k % step) == 0:
			label.text = "%s  %s  %s%s" % [fighter, scene, "press styles OFF" if off else "press styles ON", ("   " + String(af0.press.style) + " " + String(af0.press.phase)) if not af0.press.is_empty() else ""]
			for i in range(2):
				var af: AnimFighter = af0 if i == 0 else af1
				pivots[i].scale = Vector3(af.vface, 1.0, 1.0)
				var wx: float = -DIST * 0.5 if i == 0 else DIST * 0.5
				pivots[i].position = Vector3(wx, -43.0, 0.0)
				bodies[i].apply(af.q, af.hips, af.curl, af.root_off)
			if show_path:
				for di in range(dots.size()):
					var pp: Array = af0.press_path
					if di < pp.size():
						var tp: Vector3 = pp[pp.size() - 1 - di].tip
						dots[di].position = Vector3(-DIST * 0.5 + af0.vface * tp.x, -43.0 + tp.y, 6.0)
						dots[di].visible = true
						(dots[di].material_override as StandardMaterial3D).albedo_color = Color(1.0, 0.85, 0.2).lerp(Color(0.13, 0.15, 0.22), float(di) / 12.0)
					else:
						dots[di].visible = false
			for _w in range(4):
				await process_frame
			var img: Image = sv.get_texture().get_image()
			img.convert(Image.FORMAT_RGB8)
			fa.store_buffer(img.get_data())
			frames += 1
	var d0: Dictionary = RenderAnim.fighter(S, f0).debug
	cerr = float(d0.get("contact_err_max", 0.0))
	cframes = int(d0.get("contact_frames", 0))
	if fa != null:
		fa.seek(8)
		fa.store_32(frames)
		fa.close()
		print("PRESS LAB ", out, " ", frames, " frames ", size.x, "x", size.y)
	print("press lab %s %s %s: styles %s, phases %s, tip path %.0f u, contact frames %d (error %.4f rad at %s), joint violations by stage (A before the contact solve, B after it, C after the ragdoll, D before the limb pass) %s" % [fighter, scene, "OFF" if off else "ON", styles_seen.keys(), phases, path_len, cframes, cerr, String(d0.get("contact_err_bone", "")), viol])
	if measure and not vnotes.is_empty():
		print("  stage D: ", vnotes.keys().slice(0, 8))
	quit(0)
