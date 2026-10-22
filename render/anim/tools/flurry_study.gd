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
		"super": ["su_drive", "su_turn", "su_drive", "su_turn"], "super2": ["roundhouse", "double_palm", "spinning_heel", "axe_kick"], "tap_heavy": ["su_edge_unwind"], "hold_m": "roundhouse", "hold_s": "su_drive"},
	"antihero": {"light": ["cross", "palm_heel", "spear_hand", "cross", "palm_heel", "spear_hand", "cross", "palm_heel"], "burst": ["cross", "rm.gut_rise", "rm.fist_sweep", "palm_heel", "spear_hand", "rm.arm_chop", "rm.plate_drop", "jab"],
		"medium": ["double_palm", "roundhouse", "cross_arm_ram", "spinning_heel", "axe_kick", "roundhouse"], "gather": ["double_palm", "cross_arm_ram", "double_hammer"],
		"super": ["su_ram", "su_heel", "su_ram", "su_heel"], "super2": ["roundhouse", "double_palm", "spinning_heel", "axe_kick"], "tap_heavy": ["su_plate"], "hold_m": "roundhouse", "hold_s": "su_ram"},
}
## contacts are ticks from the scenario's start; `pre` and `post` are the idle ticks before the first and after the last contact
const SCENARIOS := [
	{"id": "xtap", "label": "X tap: one light, the plain light's pin (the hand set on him 6 ticks)", "style": "speed", "set": "light", "kind": "light", "dmg": 20.0, "contacts": [30], "plain": true, "post": 44},
	{"id": "xtap0", "label": "X tap: one light, no pin (before)", "style": "speed", "set": "light", "kind": "light", "dmg": 20.0, "contacts": [30], "post": 44},
	{"id": "ytap", "label": "Y tap: one medium on its 12-tick wind-up", "style": "medium", "set": "medium", "kind": "heavy", "dmg": 50.0, "contacts": [44], "windup": 12, "post": 48},
	{"id": "btap", "label": "B tap: one heavy on its 28-tick wind-up (a turn, an unwind)", "style": "super", "set": "tap_heavy", "kind": "heavy", "dmg": 90.0, "contacts": [60], "windup": 28, "post": 60},
	{"id": "xmash", "label": "X mash: a light about every 6 ticks", "style": "speed", "set": "light", "kind": "light", "dmg": 20.0, "contacts": [30, 36, 42, 48, 54, 60, 66, 72], "post": 40},
	{"id": "xhold", "label": "X held: one light, a 16-tick set, then the stream, gaps 4 4 5 6 8 11", "style": "burst", "set": "burst", "kind": "light", "dmg": 12.0,
		"contacts": [30, 46, 50, 54, 59, 65, 73, 84], "post": 44},
	{"id": "ymash", "label": "Y mash: a medium about every 14 ticks", "style": "medium", "set": "medium", "kind": "heavy", "dmg": 50.0, "contacts": [34, 48, 62, 76, 90], "post": 44},
	{"id": "bmash", "label": "B mash: a super-heavy about every 28 ticks (PROVISIONAL pieces)", "style": "super", "set": "super", "kind": "heavy", "dmg": 90.0, "contacts": [44, 72, 100, 128], "post": 56},
	{"id": "bmash2", "label": "B mash on today's heavy pieces at the super style", "style": "super", "set": "super2", "kind": "heavy", "dmg": 90.0, "contacts": [44, 72, 100, 128], "post": 56},
	{"id": "yhold", "label": "Y held: the coil deepens for 40 ticks, the blow goes on release", "style": "medium", "hold": "hold_m", "kind": "heavy", "dmg": 50.0, "contacts": [66], "windup": 42, "post": 50},
	{"id": "gather", "label": "28-tick gathers for Legal: double palm, crossed-arm ram, double hammer (h05)", "style": "super", "set": "gather", "kind": "heavy", "dmg": 90.0, "contacts": [40, 110, 180], "windup": 28, "post": 40},
	{"id": "bhold", "label": "B held: the coil deepens for 60 ticks, the blow goes on release (PROVISIONAL piece)", "style": "super", "hold": "hold_s", "kind": "heavy", "dmg": 90.0, "contacts": [86], "windup": 62, "post": 56},
]
## The cue scenarios (the next chain's cues, made here: `only` = "cue_launcher", "cue_gave_ground", "cue_reach" or "cue_dodge"): no exchange, one cue sent at tick 10 to the fighter on the left (a miss) or to the fighter
## on the right as the staggered target of the left one (the launcher's stagger), 90 ticks in all.
const CUE_SCENARIOS := {
	"cue_launcher": {"kind": "launcher_open", "actor": 0, "target": 1, "text": "stun", "span": 40, "label": "launcher_open: the staggered fighter (the right one) for 40 ticks"},
	"cue_gave_ground": {"kind": "miss", "actor": 0, "target": -1, "text": "gave_ground", "span": 20, "label": "miss gave_ground: open for 20 ticks (the left one)"},
	"cue_reach": {"kind": "miss", "actor": 0, "target": -1, "text": "reach", "span": 20, "label": "miss reach: open for 20 ticks (the left one)"},
	"cue_dodge": {"kind": "miss", "actor": 0, "target": -1, "text": "dodge", "span": 20, "label": "miss dodge: open for 20 ticks (the left one)"},
	"cue_tech": {"kind": "tech", "actor": 0, "target": -1, "text": "", "span": 14, "label": "the air tech (the tenth round's chase answer): thrown open, then tucked, 14 ticks (the left one)"},
	"cue_chase": {"kind": "chase", "actor": 0, "target": -1, "text": "start", "span": 0, "end_k": 50, "end_text": "end", "label": "the chase: the chaser's dive from tick 10 to tick 50 (the left one)"},
	"cue_cast_charge": {"kind": "beam", "actor": 0, "target": -1, "text": "charge", "span": 0, "label": "a beam charging (the left one): the fighter's own casting pose (data/anim/pair_live.json roles.<fighter>.beam)"},
	"cue_cast_fire": {"kind": "beam", "actor": 0, "target": -1, "text": "fire", "span": 0, "label": "a beam fired (the left one): the fighter's own casting pose, the arm thrown out"},
	"rd_launch": {"kind": "rd", "actor": 0, "target": -1, "text": "launch", "span": 0, "label": "a launch (the left one): a heavy blow at tick 6, then 84 ticks of flight with the ragdoll (RG0 to RG3: `window.__oop = 1` for the out-of-plane joints)"},
	"rd_brake": {"kind": "rd", "actor": 0, "target": -1, "text": "brake", "span": 0, "label": "the mid-air skid (the left one): launched at 1,500 u/s, the sim's air brake from tick 30 to 60 (RG2)"},
	"rd_poses": {"kind": "rd", "actor": 0, "target": -1, "text": "poses", "span": 0, "label": "pose sheet (the left one): the poses named in `window.__poses` (a comma list), ten ticks each, up to nine, standing in place"},
	"fs_open_palm": {"kind": "fs", "actor": 0, "target": -1, "text": "open_palm", "span": 0, "n": 150, "label": "finisher style Open Palm (Protagonist): the blast over, then one open hand held out low to the fallen rival; a wide low camera pulling back and up; one steady Trial-teal pulse"},
	"fs_held_breath": {"kind": "fs", "actor": 0, "target": -1, "text": "held_breath", "span": 0, "n": 150, "label": "finisher style Held Breath (Protagonist): the head bowed, looking back for the people; a tight push-in, then a hard cut wide; one steady Witness-blue pulse"},
	"fs_both_roads": {"kind": "fs", "actor": 0, "target": -1, "text": "both_roads", "span": 0, "n": 150, "label": "finisher style Both Roads (Protagonist): one open hand raised to the shoulder, palm out, a pledge; a slow half circle round him; one steady two-tone pulse"},
	"cue_interject": {"kind": "windup", "actor": 0, "target": -1, "text": "interject", "span": 24, "dur": 24.0, "label": "an interjection's tell: the guard (the left one) shows a 24-tick wind-up"},
}
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
var tier_style: String = "super"   # the style, the gap, the wind-up and the first contact of the tier scene (`window.__style`, `__gap`, `__windup`, `__first`): the energy-in-reach stills play the speed style at 6 ticks a blow
var tier_gap: int = 80
var rd_launch_n: int = 0
var rd_opp_tier: float = 1.0
var rd_poses: Array = []
var pulse: ColorRect   # the finisher scenarios' one steady pulse: a colour wash over the frame that rises and falls once (a peak of 0.16)
var tier_windup: int = 28
var tier_first: int = 44
var tier_hands_pk: Array = []   # the arm of each blow of a tier run (`window.__hands_pk`, `__hands_rk`: "r,r,l,..."): the free arm (l) mirrors the key set (Legal e09: the arm is chosen per throw)
var tier_hands_rk: Array = []
var body_tint: Color = Color.WHITE   # `window.__tint = "0.5,0.55,0.75"`: the world's light on the bodies (AnimBody.set_tint), to see what it does
var tier_slack: float = 0.0     # units the rival stands beyond the study's distance (`window.__slack`): the closing rule's slack, to see a heave's half step
var tier_names: Array = []      # the super-heavy tier's stills: `window.__tier = "su_knee,su_plate"` (or --tier=...) names the pieces; one blow every 80 ticks on a 28-tick wind-up, each fighter's own
var cap: bool = false
var only: String = ""
var scn_i: int = 0
var fighter: String = "protagonist"
var k: int = 0
var n_ticks: int = 0
var ex
var sent: Array = []


## a stand-in for the sim's beam, for the cast pose's stills (`_beam_layer` reads A, t, life and the direction)
class FakeBeam extends RefCounted:
	var A = null
	var t: float = 0.0
	var life: float = 1.0
	var ux: float = 1.0
	var uy: float = 0.0

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
		RenderAnim.fighter_ease = float(_js("window.__noease || 0", 0.0)) <= 0.0   # the moveset distinction's before: `window.__noease = 1`
		if float(_js("window.__nolimits || 0", 0.0)) > 0.0:   # the homework 4 pass's before: the limbs left to the last pass, no giving ground, no free-arm rate limit
			RenderAnim.source_limits = false
			RenderAnim.kick_retreat = false
			RenderAnim.hand_retreat = false
			RenderAnim.free_arm_slew = false
		if float(_js("window.__noab || 0", 0.0)) > 0.0:   # RG2's before: no mid-air skid
			RenderAnim.air_brake = false
		if float(_js("window.__novary || 0", 0.0)) > 0.0:   # RG0's before: every launch flails the same, a hit always folds
			RenderAnim.rd_variety = false
		if float(_js("window.__noweight || 0", 0.0)) > 0.0:   # RG1's before: no tier, no mass, no lag down the body
			RenderAnim.rd_weight = false
		rd_launch_n = int(_js("window.__launchn || 0", 0.0))   # the launch number of the rd scenarios (RG0 hashes it)
		rd_opp_tier = float(_js("window.__optier || 1", 1.0))   # the power tier of the opponent in them (RG1's gain)
		rd_poses = String(_js("window.__poses || ''", "")).split(",", false)   # the poses of the rd_poses sheet
		if float(_js("window.__oop || 0", 0.0)) > 0.0:   # RG3's after: the out-of-plane degrees of freedom on (`window.__oop = 1`)
			RenderAnim.rd_oop = true
		sil = sil or float(_js("window.__sil || 0", 0.0)) > 0.0
		far = far or float(_js("window.__far || 0", 0.0)) > 0.0
		near = float(_js("window.__near || 0", 0.0)) > 0.0
		offset = float(_js("window.__offset || 0", 0.0))
		var ts = String(_js("window.__style || ''", ""))
		if ts != "":
			tier_style = ts
		var tn2 = String(_js("window.__tint || ''", ""))
		if tn2 != "":
			var tp: PackedStringArray = tn2.split(",")
			if tp.size() >= 3:
				body_tint = Color(float(tp[0]), float(tp[1]), float(tp[2]))
		tier_slack = float(_js("window.__slack || 0", 0.0))
		tier_gap = int(float(_js("window.__gap || 80", 80.0)))
		tier_windup = int(float(_js("window.__windup || 28", 28.0)))
		tier_first = int(float(_js("window.__first || 44", 44.0)))
		var hp = String(_js("window.__hands_pk || ''", ""))
		if hp != "":
			tier_hands_pk = hp.split(",")
		var hr = String(_js("window.__hands_rk || ''", ""))
		if hr != "":
			tier_hands_rk = hr.split(",")
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
	pulse = ColorRect.new()
	pulse.color = Color(1, 1, 1, 0)
	pulse.size = Vector2(4096, 2160)
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(pulse)


func _tier_pieces() -> Array:
	var pre: String = "pu." if fighter == "protagonist" else "ru."
	var pre2: String = "pk." if fighter == "protagonist" else "rk."   # the energy-in-reach pieces
	var pre3: String = "pv." if fighter == "protagonist" else "rq."
	var out: Array = []
	for nm in tier_names:
		var s: String = String(nm)
		if s.length() > 3 and s.substr(2, 1) == ".":
			# a prefixed name ("pk.bolt_flat") is one fighter's own: a run is each fighter's order
			if s.begins_with(pre2) and AnimData.keysets.has(s):
				out.append(s.substr(3))
		elif AnimData.keysets.has(pre + s):
			out.append(s)
		elif AnimData.keysets.has(pre2 + s):
			out.append(s)
		elif AnimData.keysets.has(pre3 + s) or (fighter == "antihero" and AnimData.keysets.has("gd." + s)):
			out.append(s)   # Combat's pieces of 2026-10-16 (pv. the Protagonist, rq. the rival; the guards' falling sole, gd., shown on the rival's body)
		else:
			# any strike the fighter plays by name (a common piece: the front kick, the roundhouse, the jab): the names of his own pick lists, so a kick can be seen at any distance with `window.__slack`
			var kk: String = String(AnimData.ensure_fighter(String(FIGHTERS[fighter])))
			if kk != "" and AnimData.pair_lists.has(kk) and AnimData.pair_lists[kk].by_name.has(s):
				out.append(s)
	return out


func _scenarios() -> Array:
	var out: Array = []
	if CUE_SCENARIOS.has(only):
		var cs: Dictionary = CUE_SCENARIOS[only]
		return [{"id": only, "label": String(cs.label), "style": "speed", "kind": "light", "dmg": 0.0, "contacts": [], "post": 90, "cue": cs}]
	if only == "tier":
		var pcs: Array = _tier_pieces()
		var cs: Array = []
		for i in range(pcs.size()):
			cs.append(tier_first + tier_gap * i)
		if cs.is_empty():
			cs = [44]
		var heavy_kind: bool = tier_style == "super" or tier_style == "medium"
		return [{"id": "tier", "label": "the tier: style %s, a blow every %d ticks on a %d-tick wind-up" % [tier_style, tier_gap, tier_windup], "style": tier_style, "kind": "heavy" if heavy_kind else "light", "dmg": 90.0 if heavy_kind else 12.0, "contacts": cs, "windup": tier_windup, "post": 60, "pieces": pcs}]
	for s in SCENARIOS:
		if only == "" or only == String(s.id):
			out.append(s)
	return out


func _start_scenario() -> void:
	_cam_reset()
	var list: Array = _scenarios()
	var sc: Dictionary = list[scn_i % list.size()]
	var pcs: Dictionary = PIECES[fighter]
	var key: String = String(AnimData.ensure_fighter(String(FIGHTERS[fighter])))
	AnimData.ensure_fighter("RIVAL" if fighter == "protagonist" else "PROTAGONIST")
	# the parked super pieces are named for this scene only (a live match never resolves them)
	var by: Dictionary = AnimData.pair_lists[key].by_name
	var su_pre: String = "pu.su_" if fighter == "protagonist" else "ru.su_"
	var rc_pre: String = "pk." if fighter == "protagonist" else "rk."
	for kid in AnimData.keysets:
		if String(kid).begins_with(su_pre) or String(kid).begins_with(rc_pre) or (fighter == "antihero" and String(kid).begins_with("gd.")):
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
	f1.x = 500.0 + DIST + tier_slack
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
		f.beamCharge = null
	S.beams = []
	if sc.has("cue"):
		ex = null
		S.dirS.ex = null
		sent = []
		n_ticks = int(sc.cue.get("n", 90))
		k = 0
		S.tick = 1000
		S.T = 200.0
		return
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
		if sc.has("plain"):
			bargs["plain"] = true
		if String(sc.id) == "tier":
			var hl: Array = tier_hands_pk if fighter == "protagonist" else tier_hands_rk
			bargs["hand"] = String(hl[i % hl.size()]) if not hl.is_empty() else "r"   # the tier's stills are the drawn side unless a run names the arm of each blow
		DirExchange.schedule(ex, float(contacts[i]) * DT, "strike", bargs)
		sent.append(false)
	S.dirS.ex = ex
	n_ticks = int(contacts[contacts.size() - 1]) + int(sc.post)
	k = 0
	S.tick = 1000
	S.T = 200.0


func _cam_reset() -> void:
	if cam == null:
		return   # --measure draws nothing
	cam.size = 380.0 if far else (112.0 if near else 118.0)
	cam.position = Vector3(offset * 0.5 if near else 0.0, 8.0 if not far else -20.0, 300.0)
	cam.rotation = Vector3.ZERO
	if pulse != null:
		pulse.color = Color(1, 1, 1, 0)


## The three finisher styles' stage (docs/art/hero-forms-look.md section 3): the Protagonist's closing sequence on the left, the rival down, a camera that moves as Art describes and one steady colour pulse (Trial teal, Witness blue,
## or the two). A pulse is one slow rise and fall of at most 0.16 of the frame's alpha, over half a second: no strobe, never gold, white or red.
func _fs_tick(style: String, k: int) -> void:
	if k == 0:
		f1.state = "down"
	if k == 8:
		var id: String = "fn." + style
		if AnimData.entries.has(id):
			RenderAnim.fighter(S, f0)._seq = {"id": id, "t0": S.T, "dur": float(AnimData.entries[id].dur) / 60.0, "wt": 1.0}
	if cam == null:
		return   # --measure draws nothing
	var cx: float = -DIST * 0.5
	var t: float = clampf(float(k) / float(n_ticks), 0.0, 1.0)
	cam.rotation = Vector3.ZERO
	match style:
		"open_palm":
			# wide and low, pulling back and up
			cam.size = lerpf(74.0, 150.0, smoothstep(0.0, 1.0, t))
			cam.position = Vector3(cx * 0.5, lerpf(-14.0, 44.0, smoothstep(0.0, 1.0, t)), 300.0)
		"held_breath":
			# a tight push-in on him, then a hard cut wide
			if k < 80:
				var u: float = float(k) / 80.0
				cam.size = lerpf(112.0, 60.0, smoothstep(0.0, 1.0, u))
				cam.position = Vector3(cx, lerpf(8.0, 22.0, u), 300.0)
			else:
				cam.size = 170.0
				cam.position = Vector3(cx * 0.5, 14.0, 300.0)
		"both_roads":
			# a slow half circle round him
			var a: float = PI * smoothstep(0.0, 1.0, clampf(float(k - 10) / 120.0, 0.0, 1.0))
			var c := Vector3(cx, 14.0, 0.0)
			cam.size = 104.0
			cam.position = c + Vector3(sin(a) * 300.0, 0.0, cos(a) * 300.0)
			cam.look_at(c, Vector3.UP)
	var pk: float = 0.0
	if k >= 40 and k <= 70:
		pk = sin(PI * float(k - 40) / 30.0)
	var col := Color("#2dbeab") if style == "open_palm" else (Color("#598ecf") if style == "held_breath" else Color("#2dbeab").lerp(Color("#598ecf"), clampf(float(k - 40) / 30.0, 0.0, 1.0)))
	pulse.color = Color(col.r, col.g, col.b, 0.16 * pk)


func _step_tick() -> void:
	var list: Array = _scenarios()
	var sc: Dictionary = list[scn_i % list.size()]
	S.tick = 1000 + k
	S.T = 200.0 + float(k) * DT
	if ex != null:
		ex.t = float(k) * DT
	var te := SimState.FxEvent.new()
	te.type = "tick"
	te.dt = DT
	te.frozen = false
	RenderAnim.consume(S, [te])
	if sc.has("cue") and k == 10 and String(sc.cue.kind) == "beam":
		# the beam layer reads the sim's own state: the charge's start time, or a beam of the fighter's that is alive
		if String(sc.cue.text) == "charge":
			f0.beamCharge = S.T - 0.9
		else:
			var fb := FakeBeam.new()
			fb.A = f0
			S.beams = [fb]
	if sc.has("cue") and String(sc.cue.kind) == "fs":
		_fs_tick(String(sc.cue.text), k)
	if sc.has("cue") and String(sc.cue.kind) == "rd":
		# a launched body flying free (no ground): the flail, the brace and, with the brake event, the skid. The study draws a body in place, so only its shape shows
		if k == 0:
			f0.state = "launched"
			f0.launchN = rd_launch_n
			f1.tier = rd_opp_tier
			f0.vx = 1500.0
			f0.vy = 40.0
			f0.y = 90.0
			f0.slide = 0.0
			f0.spin = 0.0
		f0.stateT = float(k) * DT
		if String(sc.cue.text) == "brake" and k >= 30 and k < 60:
			f0.vx = maxf(f0.vx - 40.0, 0.0)
		f0.x += f0.vx * DT
		if String(sc.cue.text) == "brake" and (k == 30 or k == 60):
			var be := SimState.FxEvent.new()
			be.type = "air_brake"
			be.actor = 0.0
			be.text = "start" if k == 30 else "end"
			be.kind = "released"
			be.amount = 1500.0
			RenderAnim.consume(S, [be])
		if k == 6:
			var he := SimState.FxEvent.new()
			he.type = "damage"
			he.victim = 0.0
			he.attacker = 1.0
			he.kind = "heavy"
			he.amount = 90.0
			he.region = "core"
			RenderAnim.consume(S, [he])
	if sc.has("cue") and k == 10 and String(sc.cue.kind) != "beam" and String(sc.cue.kind) != "rd" and String(sc.cue.kind) != "fs":
		var cd: Dictionary = sc.cue
		var ce := SimState.FxEvent.new()
		ce.type = "cue"
		ce.kind = String(cd.kind)
		ce.actor = float(cd.actor)
		ce.target = float(cd.target)
		ce.text = String(cd.text)
		ce.n = float(S.tick + int(cd.span))
		ce.tick = S.tick
		if cd.has("dur"):
			ce.dur = float(cd.dur)
		RenderAnim.consume(S, [ce])
	if sc.has("cue") and sc.cue.has("end_k") and k == int(sc.cue.end_k):
		var ce2 := SimState.FxEvent.new()
		ce2.type = "cue"
		ce2.kind = String(sc.cue.kind)
		ce2.actor = float(sc.cue.actor)
		ce2.target = float(sc.cue.target)
		ce2.text = String(sc.cue.end_text)
		ce2.tick = S.tick
		RenderAnim.consume(S, [ce2])
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
			var wx: float = -DIST * 0.5 if i == 0 else DIST * 0.5 + offset + tier_slack
			pivots[bi].position = Vector3(wx, -43.0, 0.0)
			if sc.has("cue") and String(sc.cue.text) == "poses" and i == 0 and not rd_poses.is_empty():
				var pid: String = String(rd_poses[(k / 10) % rd_poses.size()])
				if AnimData.pose_exists(pid):
					var pp: AnimPose = AnimData.pose(pid)
					bodies[bi].apply(pp.q, pp.hips, pp.curl, Vector3.ZERO)
					label.text = pid
					bodies[bi].set_tint(body_tint)
					continue
			bodies[bi].apply(af.q, af.hips, af.curl, af.root_off)
			bodies[bi].set_tint(body_tint)
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
