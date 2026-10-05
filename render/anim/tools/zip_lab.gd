extends SceneTree
## Zip lab (docs/animation/zip.md): the body of the LT zip through the real solver, with the sim's part played by hand: the lab moves the zipper along the zip as the prototype does
## (docs/ep/prototypes/lt-zip-v4.html: home, the way in, the arrival, the way out), hands the body its zip (RenderAnim.zip_start), the exchange's strike beats (each with the press
## style of its reading and `zip: true`), the damage events of each contact and the defender's answer. A close fixed side view, wide enough for the whole zip. Scenes (--scene=):
##   speed | tech | heavy      LT + X in that reading, back to where he came from (--btn=x|y|b picks the strike: a jab string, a kick, both hands)
##   through                   the stick toward the rival: zip in, strike, run through to his far side (the facing turns)
##   up | down                 an exit up (a run up and back), a zip from above that exits down
##   away                      the stick away: the way out ends further than he started
##   caught | countered        the defender answers a timed tech or heavy: the zipper is caught in reach, or countered on arrival
##   tackle | throw            LT + A pressed (carry) and held (lift and throw)
## Needs a window to draw; run it with --no-window (offscreen), never a window.
##   godot --no-window --path . -s res://render/anim/tools/zip_lab.gd -- --scene=speed --fighter=protagonist --out=a.rgb [--btn=x] [--reading=speed] [--ghosts] [--off] [--size=520x240] [--step=1]
## --ghosts draws the hand-off (press_pose, the previous poses with their world positions) as flat translucent bodies. --off plays the same beats with the press styles off (no zip).
## --measure runs headless and prints one line: the phases seen, the contact error, joint violations, the path.

const DT := 1.0 / 60.0
const HOME := 125.0
const CXD := 56.0
const PRE := 24
const POST := 34
const FIGHTERS := {"protagonist": "KAI", "antihero": "VORR"}
const PIECES := {
	"x": {"speed": ["strike.jab", "strike.cross", "strike.jab"], "tech": ["strike.cross"], "heavy": ["strike.hook"]},
	"y": {"speed": ["strike.front_kick", "strike.low_kick", "strike.front_kick"], "tech": ["strike.side_kick"], "heavy": ["strike.roundhouse"]},
	"b": {"speed": ["strike.twin_spear", "strike.twin_spear", "strike.twin_spear"], "tech": ["strike.twin_spear"], "heavy": ["strike.double_hammer"]},
}

var scene: String = "speed"
var fighter: String = "protagonist"
var btn: String = "x"
var reading: String = ""
var via_arg: String = ""
var out: String = "zip.rgb"
var off: bool = false
var ghosts: bool = false
var measure: bool = false
var size := Vector2i(520, 240)
var step: int = 1
var main: Node


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			scene = a.substr(8)
		elif a.begins_with("--fighter="):
			fighter = a.substr(10)
		elif a.begins_with("--btn="):
			btn = a.substr(6)
		elif a.begins_with("--via="):
			via_arg = a.substr(6)
		elif a.begins_with("--reading="):
			reading = a.substr(10)
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a == "--off":
			off = true
		elif a == "--ghosts":
			ghosts = true
		elif a == "--measure":
			measure = true
		elif a.begins_with("--size="):
			var p: PackedStringArray = a.substr(7).split("x")
			size = Vector2i(int(p[0]), int(p[1]))
		elif a.begins_with("--step="):
			step = int(a.substr(7))
	RenderAnim.press_styles = not off
	RenderAnim.joint_audit = measure
	DirData.templatesProfile = "dynamic"
	var vpn := SubViewport.new()
	vpn.size = Vector2i(640, 360)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


## What a scene is: the reading, the way out, the defender's answer.
func _plan() -> Dictionary:
	var p := {"reading": "speed", "via": "back", "def": "stand", "air": false}
	match scene:
		"speed", "tech", "heavy":
			p.reading = scene
		"through":
			p.reading = "speed" if reading == "" else reading
			p.via = "through"
		"up":
			p.reading = "speed" if reading == "" else reading
			p.via = "up"
		"down":
			p.reading = "speed" if reading == "" else reading
			p.via = "down"
			p.air = true
		"away":
			p.reading = "speed" if reading == "" else reading
			p.via = "away"
		"caught":
			p.reading = "speed" if reading == "" else reading
			p.def = "caught"
		"countered":
			p.reading = "heavy" if reading == "" else reading
			p.def = "countered"
		"tackle":
			p.reading = "press"
			btn = "a"
		"throw":
			p.reading = "hold"
			btn = "a"
	if reading != "" and scene in ["speed", "tech", "heavy"]:
		p.reading = reading
	return p


func _ease(x: float) -> float:
	var c: float = clampf(x, 0.0, 1.0)
	return 1.0 - (1.0 - c) * (1.0 - c)


## Where the zipper is, as the sim would put him: (x, y) in world units, tk ticks from the zip's start.
func _att_pos(z: Dictionary, p: Dictionary, tk: float) -> Vector2:
	var dx: float = 500.0
	var home := Vector2(dx - HOME, 90.0 if p.air else 0.0)
	var cx := Vector2(dx - CXD, 30.0 if p.air else 0.0)
	var rd: String = String(z.reading)
	if rd == "press":
		cx.x += 20.0 * _ease(clampf((tk - float(z.T2)) / 12.0, 0.0, 1.0))
	var tgt: Vector2 = home
	match String(p.via):
		"through":
			tgt = Vector2(dx + HOME, 0.0)
		"up":
			tgt = Vector2(dx - 70.0, 80.0)
		"down":
			tgt = Vector2(dx - 90.0, 0.0)
		"away":
			tgt = Vector2(dx - HOME - 110.0, 0.0)
	if tk < float(z.T1):
		return home
	if tk < float(z.T2):
		return home.lerp(cx, _ease((tk - float(z.T1)) / maxf(float(z.inn), 1.0)))
	if tk < float(z.T3):
		return cx
	if tk < float(z.T4):
		return cx.lerp(tgt, _ease((tk - float(z.T3)) / maxf(float(z.out), 1.0)))
	return tgt


func _run() -> void:
	await process_frame
	var plan: Dictionary = _plan()
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
	for f in [f0, f1]:
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	f1.x = 500.0
	f1.y = 0.0
	# the zip's phases: the reading's own ticks, from the data
	var rd: String = String(plan.reading)
	var row: Dictionary = AnimData.zip.readings[rd]
	var spec := {"reading": rd, "btn": btn}
	if via_arg != "":
		spec["via"] = via_arg   # else the body reads the way out from the sim's own motion (auto)
	var T0: float = 200.0 + float(PRE) * DT
	var z := {"reading": rd, "T1": float(row.tell), "T2": float(row.tell + row["in"]), "inn": int(row["in"]), "out": int(row.out)}
	var ho: int = int(row.get("lift", 0))
	z["T3"] = float(z.T2) + float(ho) + float(row.hits) * float(row.hd)
	z["T4"] = float(z.T3) + float(row.out)
	var n_ticks: int = PRE + int(z.T4) + POST
	# the exchange: strike beats of the zipper (arrival, then every hd ticks), the defender's answer
	var kind: String = "heavy" if (rd == "heavy" or rd == "hold") else "light"
	var ex := DirExchange.newEx(f0, f1, kind)
	ex.n = 941
	ex.tag = "ZIP"
	var t_arrive: float = (float(PRE) + float(z.T2)) * DT
	var contacts: Array = []
	var dmg: float = 66.0 if kind == "heavy" else 22.0
	var countered: bool = String(plan.def) == "countered"
	var caught: bool = String(plan.def) == "caught"
	if rd == "press":
		contacts.append(float(PRE) + float(z.T3))
	elif rd == "hold":
		contacts.append(float(PRE) + float(z.T2) + float(ho))
	elif not countered:
		var pcs: Array = PIECES[btn][rd] if PIECES.has(btn) else PIECES["x"][rd]
		var hits: int = int(row.hits)
		for i in range(hits):
			var tc: float = float(PRE) + float(z.T2) + float(i) * float(row.hd)
			var args := {"a": "A", "dmg": dmg, "piece": String(pcs[i % pcs.size()]), "style": rd, "zip": true, "o": {"big": kind == "heavy"}}
			DirExchange.schedule(ex, tc * DT, "strike", args)
			contacts.append(tc)
	if countered or caught:
		# the defender's timed answer: a heavy or a tech strike whose contact falls on the arrival (countered) or a few ticks after it (caught in reach)
		var tcd: float = float(PRE) + float(z.T2) + (0.0 if countered else 4.0)
		DirExchange.schedule(ex, tcd * DT, "strike", {"a": "D", "dmg": 40.0, "piece": "strike.cross", "style": "tech", "o": {"big": false}})
	S.dirS.ex = ex
	var sv: SubViewport = null
	var bodies: Array = []
	var pivots: Array = []
	var ghost_bodies: Array = []
	var label: Label = null
	var fa: FileAccess = null
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
		cam.size = 200.0 if (scene == "up" or scene == "down") else 150.0   # a zip that goes up or down needs the sky
		cam.environment = env
		sv.add_child(cam)
		cam.position = Vector3(0.0, 48.0 if (scene == "up" or scene == "down") else 22.0, 300.0)
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
		if ghosts:
			var gm := StandardMaterial3D.new()
			gm.albedo_color = Color(0.6, 0.9, 1.0, 0.18)
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			for k in range(6):
				var pv2 := Node3D.new()
				sv.add_child(pv2)
				var gb := AnimBody.new()
				gb.build(pals[0], false)
				pv2.add_child(gb)
				for mi in gb.find_children("*", "MeshInstance3D", true, false):
					(mi as MeshInstance3D).material_override = gm
				pv2.visible = false
				ghost_bodies.append([pv2, gb])
		var ground := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(600.0, 2.0, 2.0)
		ground.mesh = bm
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(0.35, 0.4, 0.5)
		gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ground.material_override = gmat
		sv.add_child(ground)
		ground.position = Vector3(0.0, -43.0, 0.0)
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
	var frames: int = 0
	var phases: Array = []
	var cframes: int = 0
	var viol: int = 0
	var vstage: Dictionary = {}
	var vnotes: Dictionary = {}
	var sent: Array = []
	for _c in contacts:
		sent.append(false)
	var counter_sent: bool = false
	var ended: bool = false
	var path_len: float = 0.0
	var prev := Vector2.ZERO
	var have_prev: bool = false
	var held_sent: bool = false
	var thrown: bool = false
	var smear_ticks: int = 0
	for k in range(n_ticks):
		S.tick = 1000 + k
		S.T = 200.0 + float(k) * DT
		ex.t = float(k) * DT
		var tk: float = float(k - PRE)
		# the sim's part: the zipper's position along the zip, from the zip's start
		var pos: Vector2 = _att_pos(z, plan, tk) if k >= PRE else Vector2(500.0 - HOME, 90.0 if plan.air else 0.0)
		if k >= PRE and tk >= float(z.T4):
			pos = _att_pos(z, plan, float(z.T4))
		if countered and k >= PRE + int(z.T2) and not ended:
			pos = Vector2(500.0 - CXD, pos.y)
		f0.x = pos.x
		f0.y = pos.y
		f0.vx = 0.0
		f0.vy = 0.0
		if k == PRE:
			RenderAnim.zip_start(S, f0, spec)
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = DT
		te.frozen = false
		RenderAnim.consume(S, [te])
		# the defender is held by a tackle or a lift
		if rd == "press" and not held_sent and k >= PRE + int(z.T2):
			held_sent = true
			RenderAnim.zip_held(S, f1, "carried", float(row.hd) * DT)
		if rd == "hold" and not held_sent and k >= PRE + int(z.T2):
			held_sent = true
			RenderAnim.zip_held(S, f1, "lifted", float(ho) * DT)
		# the contact events, and the answer
		for ci in range(contacts.size()):
			if not sent[ci] and float(k) >= float(contacts[ci]) - 0.5:
				sent[ci] = true
				var de := SimState.FxEvent.new()
				de.type = "damage"
				de.victim = 1.0
				de.attacker = 0.0
				de.kind = "heavy" if kind == "heavy" else "light"
				de.amount = dmg
				de.region = "core"
				RenderAnim.consume(S, [de])
		if (countered or caught) and not counter_sent and float(k) >= float(PRE) + float(z.T2) + (0.0 if countered else 4.0) - 0.5:
			counter_sent = true
			var dc := SimState.FxEvent.new()
			dc.type = "damage"
			dc.victim = 0.0
			dc.attacker = 1.0
			dc.kind = "heavy" if countered else "light"
			dc.amount = 66.0 if countered else 30.0
			dc.region = "core"
			RenderAnim.consume(S, [dc])
			RenderAnim.zip_end(S, f0, "countered" if countered else "caught")
			ended = true
		var af0: AnimFighter = RenderAnim.solve(S, f0)
		var af1: AnimFighter = RenderAnim.solve(S, f1)
		if not af0.zip.is_empty():
			if phases.is_empty() or String(phases[phases.size() - 1]) != String(af0.zip.phase):
				phases.append(String(af0.zip.phase))
			if bool(af0.zip.smear):
				smear_ticks += 1
		if have_prev:
			path_len += pos.distance_to(prev)
		prev = pos
		have_prev = true
		if measure:
			var fin: Array = AnimJoints.violations(af0.q, af0._rd.shape_key)
			vstage["final"] = int(vstage.get("final", 0)) + fin.size()
			for vv in fin:
				vnotes["FINAL %s %s %.0f @%s" % [vv[0], vv[1], float(vv[2]), String(af0.zip.get("phase", "-"))]] = true
			for stage in af0.audit:
				viol += (af0.audit[stage] as Array).size()
				vstage[stage] = int(vstage.get(stage, 0)) + (af0.audit[stage] as Array).size()
				if stage == "D":
					for vv in (af0.audit[stage] as Array):
						vnotes["%s %s %.0f @%s" % [vv[0], vv[1], float(vv[2]), String(af0.zip.get("phase", "-"))]] = true
			continue
		if (k % step) == 0 and k >= PRE - 10:
			var txt: String = "%s  %s  %s %s%s" % [fighter, scene, "LT+" + btn.to_upper(), rd, "  [press styles OFF]" if off else ""]
			if not af0.zip.is_empty():
				txt += "   " + String(af0.zip.phase)
			label.text = txt
			var mid: float = 500.0 - 20.0
			for i in range(2):
				var af: AnimFighter = af0 if i == 0 else af1
				var fx: float = f0.x if i == 0 else f1.x
				var fy: float = f0.y if i == 0 else f1.y
				pivots[i].scale = Vector3(af.vface, 1.0, 1.0)
				pivots[i].position = Vector3(fx - mid, -43.0 + fy, 0.0)
				bodies[i].apply(af.q, af.hips, af.curl, af.root_off)
			if ghosts:
				for gi in range(ghost_bodies.size()):
					var e: Dictionary = af0.press_pose(gi * 2 + 1)
					var gp: Node3D = ghost_bodies[gi][0]
					if e.is_empty() or af0.zip.is_empty():
						gp.visible = false
						continue
					gp.visible = true
					gp.scale = Vector3(float(e.vface), 1.0, 1.0)
					gp.position = Vector3(float(e.pos.x) - mid, -43.0 + float(e.pos.y), -2.0)
					(ghost_bodies[gi][1] as AnimBody).apply(e.q, e.hips, af0.curl, e.root_off)
			for _w in range(4):
				await process_frame
			var img: Image = sv.get_texture().get_image()
			img.convert(Image.FORMAT_RGB8)
			fa.store_buffer(img.get_data())
			frames += 1
	var d0: Dictionary = RenderAnim.fighter(S, f0).debug
	if fa != null:
		fa.seek(8)
		fa.store_32(frames)
		fa.close()
		print("ZIP LAB ", out, " ", frames, " frames ", size.x, "x", size.y)
	print("zip lab %s %s LT+%s %s%s: phases %s, smear ticks %d, path %.0f u, contact frames %d (error %.4f rad), joint violations %d" % [fighter, scene, btn, rd, " OFF" if off else "", phases, smear_ticks, path_len, int(d0.get("contact_frames", 0)), float(d0.get("contact_err_max", 0.0)), viol])
	if measure and not vnotes.is_empty():
		print("  by stage ", vstage, " D: ", vnotes.keys().slice(0, 10))
	quit(0)
