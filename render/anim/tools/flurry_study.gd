extends Node
## The flurry look study (docs/animation/flurry-study.md; the EP's brief of 2026-10-06, Orb: "I'm excited to see Y and B flurries, I want to see how this looks visually"). VIEW ONLY: the real
## solver (AnimFighter, the real exchange beats, the contact solve, the defender's reaction) plays the three strengths on the two launch fighters against a dummy defender, in a fixed side view:
##   xmash  X mash, a light about every 6 ticks (style speed, as today)
##   xhold  X held: a burst that starts near one blow every 3 ticks and slows on a curve to one every 10 within a second, then stops (style burst: speed with the data's gap_amp, the closer the blows, the shorter each)
##   ymash  Y mash, a medium about every 14 ticks (style medium: today's heavy pieces and looks, quicker)
##   bmash  B mash, a super-heavy about every 28 ticks, wind-up starting on the press (style super, the PROVISIONAL pieces su_drive and su_turn, su_ram and su_heel)
##   bmash2 the same on today's heavy pieces at the super style (no new poses)
##   yhold  Y held: the wind-up keeps coiling for 40 ticks, the blow goes on release (medium)
##   bhold  B held: the wind-up keeps coiling for 60 ticks, the blow goes on release (super)
## The sim sends none of this yet: the beats are staged by hand with the fields a brawl beat carries (style, piece, and `windup` for a held blow). Nothing here is read by a live match: the super pieces are
## parked waves loaded by this scene only (AnimData.load_waves), and every number is provisional.
## Three ways to run it (all headless or the web build; never a window):
##   the web build: this scene as the main scene of a scratch export plays every scenario for both fighters in a loop in real time (the page is watchable as it is);
##     with `window.__cap = 1` it steps one tick for each `window.__adv` the driver sets and publishes `window.__tick`, `window.__scn` (scenario:fighter) so a driver can screenshot every tick;
##     `window.__sil = 1` draws flat silhouettes and `window.__far = 1` the fight-distance camera.
##   headless: godot --headless --path . res://render/anim/tools/flurry_study.tscn -- --measure   prints the solver's numbers for every scenario (contact error, joint violations, NaN) and quits.
const DT := 1.0 / 60.0
const FIGHTERS := {"protagonist": "PROTAGONIST", "antihero": "RIVAL"}
const DIST := 60.0
const PIECES := {   # blows that land on the chest or the gut (a blow aimed at the head reaches over the dummy's head at this distance)
	"protagonist": {"light": ["cross", "palm_heel", "spear_hand", "cross", "palm_heel", "spear_hand", "cross", "palm_heel"], "burst": ["cross", "pm.palm_rise", "pm.back_chop", "palm_heel", "spear_hand", "pm.fist_chop", "pm.palm_heave", "jab"],
		"medium": ["double_palm", "roundhouse", "cross_arm_ram", "spinning_heel", "axe_kick", "roundhouse"], "gather": ["double_palm", "cross_arm_ram", "double_hammer"],
		"super": ["su_drive", "su_turn", "su_drive", "su_turn"], "super2": ["roundhouse", "double_palm", "spinning_heel", "axe_kick"], "hold_m": "roundhouse", "hold_s": "su_drive"},
	"antihero": {"light": ["cross", "palm_heel", "spear_hand", "cross", "palm_heel", "spear_hand", "cross", "palm_heel"], "burst": ["cross", "rm.gut_rise", "rm.fist_sweep", "palm_heel", "spear_hand", "rm.arm_chop", "rm.plate_drop", "jab"],
		"medium": ["double_palm", "roundhouse", "cross_arm_ram", "spinning_heel", "axe_kick", "roundhouse"], "gather": ["double_palm", "cross_arm_ram", "double_hammer"],
		"super": ["su_ram", "su_heel", "su_ram", "su_heel"], "super2": ["roundhouse", "double_palm", "spinning_heel", "axe_kick"], "hold_m": "roundhouse", "hold_s": "su_ram"},
}
## contacts are ticks from the scenario's start; `pre` and `post` are the idle ticks before the first and after the last contact
const SCENARIOS := [
	{"id": "xmash", "label": "X mash: a light about every 6 ticks", "style": "speed", "set": "light", "kind": "light", "dmg": 20.0, "contacts": [30, 36, 42, 48, 54, 60, 66, 72], "post": 40},
	{"id": "xhold", "label": "X held: a burst of eight, gaps 4 4 5 6 8 11 15", "style": "burst", "set": "burst", "kind": "light", "dmg": 12.0,
		"contacts": [30, 34, 38, 43, 49, 57, 68, 83], "post": 44},
	{"id": "ymash", "label": "Y mash: a medium about every 14 ticks", "style": "medium", "set": "medium", "kind": "heavy", "dmg": 50.0, "contacts": [34, 48, 62, 76, 90], "post": 44},
	{"id": "bmash", "label": "B mash: a super-heavy about every 28 ticks (PROVISIONAL pieces)", "style": "super", "set": "super", "kind": "heavy", "dmg": 90.0, "contacts": [44, 72, 100, 128], "post": 56},
	{"id": "bmash2", "label": "B mash on today's heavy pieces at the super style", "style": "super", "set": "super2", "kind": "heavy", "dmg": 90.0, "contacts": [44, 72, 100, 128], "post": 56},
	{"id": "yhold", "label": "Y held: the coil deepens for 40 ticks, the blow goes on release", "style": "medium", "hold": "hold_m", "kind": "heavy", "dmg": 50.0, "contacts": [66], "windup": 42, "post": 50},
	{"id": "gather", "label": "28-tick gathers for Legal: double palm, crossed-arm ram, double hammer (h05)", "style": "super", "set": "gather", "kind": "heavy", "dmg": 90.0, "contacts": [40, 110, 180], "windup": 28, "post": 40},
	{"id": "bhold", "label": "B held: the coil deepens for 60 ticks, the blow goes on release (PROVISIONAL piece)", "style": "super", "hold": "hold_s", "kind": "heavy", "dmg": 90.0, "contacts": [86], "windup": 62, "post": 56},
]
const PAL_A := {"body": Color("#3d8fdc"), "legs": Color("#1b1f2a"), "arms": Color("#e6b995"), "skin": Color("#efc7a2"), "gear": Color("#cdd6e4"), "accent": Color("#4fb9a8"), "hair": Color("#22c7a0")}
const PAL_B := {"body": Color("#2a2043"), "legs": Color("#181228"), "arms": Color("#b98462"), "skin": Color("#b98462"), "gear": Color("#cbd3e2"), "accent": Color("#9a80d8"), "hair": Color("#1d1630")}
var main: Node
var S: SimState
var f0
var f1
var bodies: Array = []
var pivots: Array = []
var label: Label
var cam: Camera3D
var measure: bool = false
var sil: bool = false
var far: bool = false
var near: bool = false          # RL-105: a close view, the dummy drawn `offset` units farther away (render only), so one contact frame reads
var offset: float = 0.0
var tier_names: Array = []      # the super-heavy tier's stills: `window.__tier = "su_knee,su_plate"` (or --tier=...) names the pieces; one blow every 80 ticks on a 28-tick wind-up, each fighter's own
var cap: bool = false
var only: String = ""
var scn_i: int = 0
var fighter: String = "protagonist"
var k: int = 0
var n_ticks: int = 0
var ex
var sent: Array = []
var acc: float = 0.0
var adv_done: int = 0
var ready_to_run: bool = false
var stats := {"contact_err": 0.0, "viol": 0, "nan": 0, "frames": 0, "final": 0}


func _js(expr: String, default):
	if not OS.has_feature("web"):
		return default
	var v = JavaScriptBridge.eval(expr, true)
	return default if v == null else v


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--measure":
			measure = true
		elif a == "--sil":
			sil = true
		elif a == "--far":
			far = true
		elif a.begins_with("--only="):
			only = a.substr(7)
		elif a.begins_with("--tier="):
			tier_names = a.substr(7).split(",")
			only = "tier"
	if OS.has_feature("web"):
		cap = float(_js("window.__cap || 0", 0.0)) > 0.0
		sil = sil or float(_js("window.__sil || 0", 0.0)) > 0.0
		far = far or float(_js("window.__far || 0", 0.0)) > 0.0
		near = float(_js("window.__near || 0", 0.0)) > 0.0
		offset = float(_js("window.__offset || 0", 0.0))
		var tn = _js("window.__tier || ''", "")
		if String(tn) != "":
			tier_names = String(tn).split(",")
			only = "tier"
		var o = _js("window.__only || ''", "")
		if String(o) != "":
			only = String(o)
	AnimData.load_waves = true
	RenderAnim.joint_audit = measure
	DirData.templatesProfile = "dynamic"
	var vpn := SubViewport.new()
	vpn.size = Vector2i(640, 360)
	vpn.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vpn.own_world_3d = true   # the game scene lives in its own world: its terrain must not show in this view
	add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_setup.call_deferred()


func _setup() -> void:
	await get_tree().process_frame
	AnimData.load_all()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(DT)
	S = main.host.S
	RenderAnim.ground_feet = false
	f0 = S.fighters[0]
	f1 = S.fighters[1]
	if not measure:
		_build_view()
	ready_to_run = true
	_start_scenario()


func _build_view() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.93, 0.93, 0.95) if sil else Color(0.13, 0.15, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.85)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 380.0 if far else (112.0 if near else 118.0)
	cam.environment = env
	add_child(cam)
	cam.position = Vector3(offset * 0.5 if near else 0.0, 8.0 if not far else -20.0, 300.0)
	cam.current = true
	for i in range(2):
		var pv := Node3D.new()
		add_child(pv)
		var bd := AnimBody.new()
		var pal: Dictionary = PAL_A if i == 0 else PAL_B
		if sil:
			var dark := Color(0.08, 0.08, 0.1) if i == 0 else Color(0.62, 0.62, 0.66)   # the attacker dark, the dummy grey: the two shapes stay apart where they overlap
			pal = {"body": dark, "legs": dark, "arms": dark, "skin": dark, "gear": dark, "accent": dark, "hair": dark}
		bd.build(pal, false)
		pv.add_child(bd)
		pivots.append(pv)
		bodies.append(bd)
	var ground := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1200.0, 2.0, 2.0)
	ground.mesh = bm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.6, 0.6, 0.65) if sil else Color(0.35, 0.4, 0.5)
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground.material_override = gmat
	add_child(ground)
	ground.position = Vector3(0.0, -43.0, 0.0)
	var cl := CanvasLayer.new()
	add_child(cl)
	label = Label.new()
	label.position = Vector2(8, 4)
	label.add_theme_font_size_override("font_size", 16)
	if sil:
		label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))
	cl.add_child(label)


func _tier_pieces() -> Array:
	var pre: String = "pu." if fighter == "protagonist" else "ru."
	var out: Array = []
	for nm in tier_names:
		if AnimData.keysets.has(pre + String(nm)):
			out.append(String(nm))
	return out


func _scenarios() -> Array:
	var out: Array = []
	if only == "tier":
		var pcs: Array = _tier_pieces()
		var cs: Array = []
		for i in range(pcs.size()):
			cs.append(44 + 80 * i)
		if cs.is_empty():
			cs = [44]
		return [{"id": "tier", "label": "the super-heavy tier, one blow every 80 ticks on a 28-tick wind-up", "style": "super", "kind": "heavy", "dmg": 90.0, "contacts": cs, "windup": 28, "post": 60, "pieces": pcs}]
	for s in SCENARIOS:
		if only == "" or only == String(s.id):
			out.append(s)
	return out


func _start_scenario() -> void:
	var list: Array = _scenarios()
	var sc: Dictionary = list[scn_i % list.size()]
	var pcs: Dictionary = PIECES[fighter]
	var key: String = String(AnimData.ensure_fighter(String(FIGHTERS[fighter])))
	AnimData.ensure_fighter("RIVAL" if fighter == "protagonist" else "PROTAGONIST")
	# the parked super pieces are named for this scene only (a live match never resolves them)
	var by: Dictionary = AnimData.pair_lists[key].by_name
	var su_pre: String = "pu.su_" if fighter == "protagonist" else "ru.su_"
	for kid in AnimData.keysets:
		if String(kid).begins_with(su_pre):
			by[String(kid).substr(3)] = String(kid)
	# the parked lights the burst draws on (a rise, an arc, a drop), named by their wave prefix (pm. the Protagonist, rm. the rival)
	for pre in ["pm.", "rm."]:
		for nm2 in ["palm_rise", "back_chop", "fist_chop", "palm_heave", "gut_rise", "fist_sweep", "arm_chop", "plate_drop"]:
			if AnimData.keysets.has(pre + nm2):
				by[pre + nm2] = pre + nm2
	f0.id = FIGHTERS[fighter]
	f1.id = "RIVAL" if fighter == "protagonist" else "PROTAGONIST"
	RenderAnim._fighters.clear()
	f0.x = 500.0
	f1.x = 500.0 + DIST
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	ex = DirExchange.newEx(f0, f1, String(sc.kind))
	ex.n = 940 + scn_i
	ex.tag = "STUDY"
	var contacts: Array = sc.contacts
	var plist: Array = sc.pieces if sc.has("pieces") else pcs.get(String(sc.get("set", "")), [])
	sent = []
	for i in range(contacts.size()):
		var piece: String = String(pcs[sc.hold]) if sc.has("hold") else String(plist[i % maxi(1, plist.size())]) if not plist.is_empty() else "cross"
		var bargs := {"a": "A", "dmg": float(sc.dmg), "piece": "strike." + piece, "style": String(sc.style), "o": {"big": String(sc.kind) == "heavy"}}
		if sc.has("windup"):
			bargs["windup"] = int(sc.windup)
		if String(sc.id) == "tier":
			bargs["hand"] = "r"   # the tier's stills are all the drawn side (the director's own pick may mirror a piece)
		DirExchange.schedule(ex, float(contacts[i]) * DT, "strike", bargs)
		sent.append(false)
	S.dirS.ex = ex
	n_ticks = int(contacts[contacts.size() - 1]) + int(sc.post)
	k = 0
	S.tick = 1000
	S.T = 200.0


func _step_tick() -> void:
	var list: Array = _scenarios()
	var sc: Dictionary = list[scn_i % list.size()]
	S.tick = 1000 + k
	S.T = 200.0 + float(k) * DT
	ex.t = float(k) * DT
	var te := SimState.FxEvent.new()
	te.type = "tick"
	te.dt = DT
	te.frozen = false
	RenderAnim.consume(S, [te])
	var contacts: Array = sc.contacts
	for bi in range(contacts.size()):
		if not sent[bi] and k >= int(contacts[bi]):
			sent[bi] = true
			var de := SimState.FxEvent.new()
			de.type = "damage"
			de.victim = 1.0
			de.attacker = 0.0
			de.kind = String(sc.kind)
			de.amount = float(sc.dmg)
			de.region = "core"
			RenderAnim.consume(S, [de])
	var af0: AnimFighter = RenderAnim.solve(S, f0)
	var af1: AnimFighter = RenderAnim.solve(S, f1)
	if measure:
		stats.frames += 1
		for i in range(AnimRig.N):
			if is_nan(af0.q[i].x) or is_nan(af0.q[i].w):
				stats.nan += 1
		for stage in af0.audit:
			stats.viol += (af0.audit[stage] as Array).size()
		stats.final += AnimJoints.violations(af0.q, af0._rd.shape_key).size() + AnimJoints.violations(af1.q, af1._rd.shape_key).size()   # what reaches the screen, after the last pass
		stats.contact_err = maxf(float(stats.contact_err), float(af0.debug.get("contact_err_max", 0.0)))
	else:
		for i in range(2):
			var af: AnimFighter = af0 if i == 0 else af1
			# the attacker is always on the left, in his own colours: the rival's run draws him in the second body (the purple one) and the dummy in the first
			var bi: int = i if (fighter == "protagonist" or sil) else 1 - i   # (the silhouettes keep the attacker dark in both runs)
			pivots[bi].scale = Vector3(af.vface, 1.0, 1.0)
			var wx: float = -DIST * 0.5 if i == 0 else DIST * 0.5 + offset
			pivots[bi].position = Vector3(wx, -43.0, 0.0)
			bodies[bi].apply(af.q, af.hips, af.curl, af.root_off)
		var st: String = "%s %s" % [String(FIGHTERS[fighter]), String(sc.label)]
		label.text = st if not sil else String(sc.id)
		if near and not af0.press.is_empty():
			label.text = "%s  %s  %s: %s, %d ticks to contact" % [String(FIGHTERS[fighter]), String(af0._part), String(af0.press.phase), String(af0.press.style), int(af0.press.ticks_to_contact)]
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__scn = '%s:%s'; window.__k = %d; window.__n = %d;" % [String(sc.id), fighter, k, n_ticks], true)
	k += 1
	if k >= n_ticks:
		_next_scenario()


func _next_scenario() -> void:
	var list: Array = _scenarios()
	if measure:
		var dd: Dictionary = RenderAnim.fighter(S, f0).debug
		print("FLURRY %s %s: contact frames %d error %.4f rad (%s), viol so far %d" % [String(list[scn_i % list.size()].id), fighter, int(dd.get("contact_frames", 0)), float(dd.get("contact_err_max", 0.0)), str(dd.get("contact_err_bone", "-")), stats.viol])
	if fighter == "protagonist":
		fighter = "antihero"
	else:
		fighter = "protagonist"
		scn_i += 1
	if measure and scn_i >= list.size():
		_finish()
		return
	_start_scenario()


func _finish() -> void:
	var d0: Dictionary = RenderAnim.fighter(S, f0).debug
	ready_to_run = false
	print("FLURRY STUDY measure: %d frames, worst contact error %.4f rad, joint violations before the final pass %d, on screen %d, NaN %d" % [stats.frames, float(stats.contact_err), stats.viol, stats.final, stats.nan])
	get_tree().quit(0)


func _process(delta: float) -> void:
	if not ready_to_run:
		return
	if measure:
		for _i in range(60):
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
