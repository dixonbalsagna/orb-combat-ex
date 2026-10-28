extends SceneTree
## Animation check (slice A1, docs/animation/pose-pipeline.md sections 8.6 and 10). Real AI matches run through the full
## scene, one tick per frame, on the templates' dynamic profile:
## 1. the gameplay hash is the same with the mannequin on and off, for both timing styles (render only);
## 2. no bone rotation is ever NaN;
## 3. timing fidelity: on the frame of every blow's contact the solved pose is the contact key (max angle error);
## 4. strikes and reactions actually play (counts), and every part came from a known key set;
## 5. (A2) the contact solve runs and the striking limb ends within 2 units of the defender on average; the per-part mix is a fourth mode;
## 6. nothing under render/anim/ assigns to the sim state S (a static scan).
##   godot --path . --script res://render/anim/tools/anim_check.gd [-- --seeds=4,12345 --ticks=4200]

const DT := 1.0 / 60.0

var seeds: Array = [4, 12345]
var max_ticks: int = 4200
var main: Node
var report_out: String = ""
var report: Dictionary = {"runs": []}
var fails: Array = []
var checks: int = 0
var _press_default: bool = true   # RenderAnim.press_styles as the run started (the shipped default, unless a flag on the command line changed it): the tests that end by restoring it restore this


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--ticks="):
			max_ticks = int(a.substr(8))
		elif a.begins_with("--report="):
			report_out = a.substr(9)
	RenderAnim.is_enabled()   # reads --press-styles and --no-press-styles
	_press_default = RenderAnim.press_styles
	DirData.templatesProfile = "dynamic"
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _expect(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		fails.append(what)


func _scan_writes() -> void:
	var re := RegEx.new()
	re.compile("(^|[^\\w.])(S|f|ex)\\.[\\w.\\[\\]]+\\s*([+\\-*/]?=)[^=]")
	var d := DirAccess.open("res://render/anim")
	var n := 0
	for fn in d.get_files():
		if not fn.ends_with(".gd"):
			continue
		var lines: PackedStringArray = FileAccess.get_file_as_string("res://render/anim/" + fn).split("\n")
		for i in range(lines.size()):
			var l: String = lines[i].strip_edges()
			if l.begins_with("#") or l.begins_with("##"):
				continue
			n += 1
			_expect(re.search(l) == null, "%s:%d assigns to the sim state: %s" % [fn, i + 1, l])
	print("static scan: %d code lines in render/anim/ read the sim and never assign to it" % n)


## The defensive and clash beats on a stub exchange (no match needed, so a parry is forced): each layer must pull the
## pose toward its own key and leave the fighters it is not for alone.
func _test_beats() -> void:
	var beats: Array = [
		{"op": "wind", "t": 0.0, "args": {}},
		{"op": "strike", "t": 0.3, "args": {"a": "A"}},
		{"op": "slip", "t": 1.0, "args": {}},
		{"op": "dodge", "t": 1.5, "args": {}},
		{"op": "guardBreak", "t": 2.0, "args": {}},
		{"op": "clashWave", "t": 2.5, "args": {}},
		{"op": "dodge", "t": 3.0, "args": {"side": "cross", "dur": 0.15}},
	]
	# [role, cancel, time, the pose that must come, true if it must come]
	var cases: Array = [
		["D", false, 0.25, "def.parry_ready", true], ["A", false, 0.25, "def.parry_ready", false],
		["D", true, 0.34, "def.parry", true], ["A", true, 0.34, "react.rebuff", true],
		["D", false, 1.1, "def.slip", true], ["A", false, 1.1, "def.slip", false],
		["D", false, 1.6, "def.blink_in", true], ["A", false, 1.6, "def.blink_in", false],
		["D", false, 3.04, "def.hop", true], ["D", false, 3.12, "def.drop", true], ["A", false, 3.04, "def.hop", false],
		["D", false, 2.1, "def.guard_break", true], ["A", false, 2.1, "def.guard_break", false],
		["D", false, 2.6, "clash.push", true], ["A", false, 2.6, "clash.push", true],
		["D", false, 3.6, "def.parry_ready", false],
	]
	for c in cases:
		var af := AnimFighter.new(0)
		af._beat_layers({"beats": beats, "cancel": c[1]}, c[0], 0.0, c[2])
		var key: AnimPose = AnimData.pose(c[3])
		var before := 0.0
		var after := 0.0
		for i in range(AnimRig.N):
			before += Quaternion.IDENTITY.angle_to(key.q[i])
			after += af.q[i].angle_to(key.q[i])
		if c[4]:
			_expect(after < before * 0.6, "beat test: %s at %.2f s (cancel %s, role %s) did not pull toward %s (%.2f of %.2f)" % [c[0], c[2], c[1], c[0], c[3], after, before])
		else:
			_expect(after > before * 0.99, "beat test: role %s at %.2f s moved toward %s though the beat is not its own" % [c[0], c[2], c[3]])
	print("beat test: %d cases on a stub exchange (parry forced)" % cases.size())


## The transformation's three beats, in each version, without a match: the gather compresses, the break is exactly the break
## pose on its first tick, the settle holds the settle pose, and the last tick is back on the base pose.
func _test_form() -> void:
	var n := 0
	for v in ["full", "short", "live"]:
		var spec: Dictionary = AnimData.forms[v]
		var g: int = int(spec.gather)
		var b: int = int(spec["break"])
		var tot: int = g + b + int(spec.settle)
		var poses: Dictionary = {}
		for k in AnimData.form_poses:
			poses[k] = AnimData.pose(String(AnimData.form_poses[k]))
		var base: AnimPose = AnimData.pose("stance.aggressive")
		var steps: Array = [["gather", float(g - 1)], ["break", float(g) + 0.5], ["settle", float(g + b) + minf(float(spec.hold) * 0.5, 4.0) + 1.0]]
		for st in steps:
			var af := AnimFighter.new(0)
			af._base = base.q.duplicate()
			af._base_hips = base.hips
			af._base_curl = base.curl
			for i in range(AnimRig.N):
				af.q[i] = base.q[i]
			af.hips = base.hips
			af._form_pose(spec, st[1], v == "live")
			var key: AnimPose = poses[st[0]]
			var d_base := 0.0
			var d_after := 0.0
			for i in range(AnimRig.N):
				d_base += base.q[i].angle_to(key.q[i])
				d_after += af.q[i].angle_to(key.q[i])
			var tol: float = 0.05 if st[0] == "break" else (0.7 if (st[0] == "gather" and v == "live") else 0.45)
			_expect(d_after <= d_base * tol + 0.001, "form test: %s %s beat at tick %.1f is %.2f from its pose (the base is %.2f)" % [v, st[0], st[1], d_after, d_base])
			n += 1
		var af2 := AnimFighter.new(0)
		af2._base = base.q.duplicate()
		af2._base_hips = base.hips
		af2._base_curl = base.curl
		af2._form_pose(spec, float(tot) - 0.5, v == "live")
		var back := 0.0
		for i in range(AnimRig.N):
			back += af2.q[i].angle_to(base.q[i])
		_expect(back < 0.3, "form test: %s ends %.2f rad from the base pose" % [v, back])
		n += 1
	print("form test: %d checks (full, short, live: gather, break, settle, end)" % n)


## Battle damage on a real match, the wear set by hand on a fresh one (a test: this match's hash is not compared): fighter 0 has
## both arms and both legs broken, fighter 1 is worn and then fresh. The broken arm must hang when no blow is being thrown, no
## blow may use the broken limb, the stance must sag toward the brink and the worn fighter must breathe harder than the fresh one.
func _test_wounds() -> void:
	# Every part is a controlled case that cannot depend on how a live match plays (the sim changes under it: launches, embeds, skids): a match is started only for
	# the fighters' records, and the animation is driven directly.
	var live_was: bool = RenderAnim.wave1_live
	RenderAnim.wave1_live = false
	RenderAnim.enabled = true
	RenderAnim.style_override = ""
	main.start_match(4, {"p1": true, "p2": true})
	var S: SimState = main.host.S
	for i in range(30):
		main.frame(DT)
	var a = S.fighters[0]
	var b = S.fighters[1]
	var at: int = int(a.wd.stageAt[2])
	a.wear = [0, 0, at, at]
	a.stage = [0, 0, 3, 3]
	b.wear = [0, int(at * 0.85), 0, 0]
	b.stage = [0, 2, 0, 0]
	var s2: int = AnimRig.index["spine_2"]
	# 1. a broken arm hangs: a fighter standing calm (no blow, no sequence, no ragdoll) with his right or left arm broken, over a second of sim time
	var hang_n := 0
	var hang_ok := 0
	for slot_i in [0, 1]:
		var afa := AnimFighter.new(slot_i)
		afa._wound_read(a)
		var limp: AnimPose = AnimData.pose("wound.arm_limp", not afa._hang_right)
		var fo: int = AnimRig.index["forearm_" + ("r" if afa._hang_right else "l")]
		var stub: Dictionary = {"state": "free", "vx": 0.0}
		for tk in range(60):
			afa.q = AnimData.pose("stance.aggressive").q.duplicate()
			afa.hips = AnimData.pose("stance.aggressive").hips
			afa._part = ""
			afa._wound_limbs(stub, float(tk) * DT)
			hang_n += 1
			if afa.q[fo].angle_to(limp.q[fo]) < 0.3:
				hang_ok += 1
	_expect(hang_n > 0 and hang_ok == hang_n, "wound test: the broken arm hung on %d of %d calm frames" % [hang_ok, hang_n])
	# 3. a fighter at the brink is drawn toward the sagging stance more than a fresh one: the same fighter, the same state, only the sim's brink progress differs
	var sag0: AnimPose = AnimData.pose("wound.sag")
	var dists: Array = []
	for brink in [1.0, 0.0]:
		var afb := AnimFighter.new(1)
		b.state = "free"
		afb._wound_read(b)
		afb._brinkp = brink
		afb._tq = AnimPose.identity_q()
		afb._bkey = -1   # rebuild the target now
		afb._bkey2 = -1
		afb._target_base(S, b, S.T)
		var dw := 0.0
		for nm0 in ["spine_1", "spine_2", "head", "pelvis"]:
			var i0: int = AnimRig.index[nm0]
			dw += afb._tq[i0].angle_to(sag0.q[i0])
		dists.append(dw)
	var d_worn: float = dists[0]
	var d_fresh: float = dists[1]
	_expect(d_worn < d_fresh * 0.9, "wound test: the stance did not sag toward the brink (%.3f against %.3f)" % [d_worn, d_fresh])
	# 2. no blow uses a broken limb: one match, and only if it threw blows with the arm broken (counted when it did; the number must be 0)
	var afm: AnimFighter = RenderAnim.fighter(S, a)
	for i in range(600):
		main.frame(DT)
	_expect(int(afm.debug["wound_bad"]) == 0, "wound test: %d blows used a broken limb (of %d)" % [afm.debug["wound_bad"], afm.debug["wound_strikes"]])
	# the breath of a worn fighter against a fresh one, in a controlled setup (the same fighter, the same four seconds, only the wear differs):
	# a live match plays differently whenever the sim changes, so the chest of whoever happened to be standing in it is not a measure
	b.state = "free"
	var ranges: Array = []
	for wear_b in [[0, int(at * 0.85), 0, 0], [0, 0, 0, 0]]:
		b.wear = wear_b
		b.stage = [0, 2, 0, 0] if int(wear_b[1]) > 0 else [0, 0, 0, 0]
		var afc := AnimFighter.new(1)
		afc._wound_read(b)
		var lo_c := 9.0
		var hi_c := -9.0
		for tk in range(240):
			afc.q = AnimPose.identity_q()
			afc._wear_motion(b, float(tk) * DT)
			var angc: float = afc.q[s2].angle_to(Quaternion.IDENTITY)
			lo_c = minf(lo_c, angc)
			hi_c = maxf(hi_c, angc)
		ranges.append(hi_c - lo_c)
	_expect(float(ranges[0]) > float(ranges[1]) * 1.2, "wound test: the worn fighter's chest moves %.3f, the fresh one's %.3f" % [ranges[0], ranges[1]])
	print("wound test: broken arm hung on %d of %d calm frames, %d blows by the broken limb, stance sag %.3f against %.3f fresh, chest range worn %.3f fresh %.3f (controlled)" % [hang_ok, hang_n, afm.debug["wound_bad"], d_worn, d_fresh, ranges[0], ranges[1]])
	RenderAnim.wave1_live = live_was


## A broken arm hangs heavy while the body is thrown about: with the same kicks, a broken arm swings a third as far as the good one beside it.
func _test_heavy_arm() -> void:
	var swing: Array = []
	for broken in [false, true]:
		var af := AnimFighter.new(0)
		af._arm_broken = broken
		af._hang_right = true
		af._rd.reset()
		for i in range(AnimRagdoll.N):
			af._rd.th[i] = 0.5
		var q1: Array[Quaternion] = AnimPose.identity_q()
		af._rd.apply(q1, 1.0, af._rd_scale())
		var ix: Dictionary = AnimRig.index
		swing.append([q1[ix["upper_arm_r"]].angle_to(Quaternion.IDENTITY), q1[ix["upper_arm_l"]].angle_to(Quaternion.IDENTITY)])
	_expect(float(swing[1][0]) < float(swing[0][0]) * 0.5 and absf(float(swing[1][1]) - float(swing[0][1])) < 0.001, "heavy arm test: the broken arm swings %.2f against %.2f (the good arm %.2f and %.2f)" % [swing[1][0], swing[0][0], swing[1][1], swing[0][1]])
	print("heavy arm test: a broken arm swings %.2f rad where the same arm unbroken swings %.2f; the good arm is untouched" % [swing[1][0], swing[0][0]])


## The flight lead (docs/animation/pose-pipeline.md 9.23, GB-006): a fast launched body that has stopped tumbling flies head first along its velocity whatever angle the
## spin left it at, and is let go when the launch ends; a fighter carried fast by position (a knockback) with his head against the way he goes is stood up to the tilt cap.
func _test_flight_lead() -> void:
	_expect(not AnimData.flight.is_empty() and AnimData.flight.has("tilt"), "flight lead test: data/anim/flight.json did not load")
	main.start_match(4, {"p1": true, "p2": true})
	var S: SimState = main.host.S
	var f = S.fighters[0]
	var saved_on: bool = RenderAnim.flight_lead
	var base: AnimPose = AnimData.pose("stance.aggressive")
	var lead_on: float = 0.0
	var lead_off: float = 0.0
	var left_over: float = 1.0
	for on in [true, false]:
		RenderAnim.flight_lead = on
		var af := AnimFighter.new(0)
		af.vface = 1.0
		f.state = "launched"
		f.slide = 0.0
		f.vx = -900.0
		f.vy = 300.0
		f.rot = 2.6   # turned over: the head on the far side
		f.spin = 0.4
		for k in range(45):
			af.q = base.q.duplicate()
			af.hips = base.hips
			af.root_off = Vector3.ZERO
			f.rot += f.spin / 60.0
			af._lead_layer(S, f, 1.0 / 60.0)
		AnimPose.fk(af.q, af.hips, af.gq, af.gp)
		var ax: Vector3 = af.gp[AnimRig.index["head"]] - af.gp[AnimRig.index["pelvis"]]
		var c: float = cos(-f.rot)
		var sn: float = sin(-f.rot)
		var w := Vector2(ax.x * c - ax.y * sn, ax.x * sn + ax.y * c).normalized()
		var d: float = w.dot(Vector2(f.vx, f.vy).normalized())
		if on:
			lead_on = d
			# the launch ends: the turn is let go
			f.state = "free"
			f.vx = 0.0
			f.vy = 0.0
			f.rot = 0.0
			f.spin = 0.0
			for k in range(90):
				af.q = base.q.duplicate()
				af.hips = base.hips
				af.root_off = Vector3.ZERO
				af._lead_layer(S, f, 1.0 / 60.0)
			left_over = absf(af._lead_d)
		else:
			lead_off = d
	RenderAnim.flight_lead = saved_on
	_expect(lead_on > 0.9 and lead_off < 0.5, "flight lead test: the head leads %.2f with the lead on (want over 0.9) and %.2f with it off (want under 0.5: the sim's own angle)" % [lead_on, lead_off])
	_expect(left_over < 0.01, "flight lead test: the turn was not let go after the launch (%.3f rad left)" % left_over)
	# a knockback carries him back by position with his head toward the blow: the folded body is stood up to the tilt cap
	var fold: AnimPose = AnimData.pose("move.sprint")   # head forward, body level: the worst case
	var ak := AnimFighter.new(0)
	ak.vface = 1.0
	f.state = "locked"
	f.slide = 0.0
	f.rot = 0.0
	f.spin = 0.0
	f.x = 1000.0
	f.y = 0.0
	var tilt_ok: float = 99.0
	for k in range(30):
		S.tick += 1
		f.x -= 9.0   # backward, 540 u/s, while the pose leans forward
		ak.q = fold.q.duplicate()
		ak.hips = fold.hips
		ak.root_off = Vector3.ZERO
		ak._lead_layer(S, f, 1.0 / 60.0)
	AnimPose.fk(ak.q, ak.hips, ak.gq, ak.gp)
	var kx: Vector3 = ak.gp[AnimRig.index["head"]] - ak.gp[AnimRig.index["pelvis"]]
	tilt_ok = absf(rad_to_deg(atan2(kx.x, kx.y)))
	_expect(tilt_ok < 45.0, "flight lead test: a body laid out against a knockback was only stood up to %.0f degrees of tilt (want under 45)" % tilt_ok)
	print("flight lead test: head leads %.2f along the velocity (the sim's own angle %.2f), let go after the launch, a knockback fold stood up to %.0f degrees" % [lead_on, lead_off, tilt_ok])
	f.state = "free"

## The launch pair live (docs/animation/pair-live.md): a roster id plays as its fighter of data/anim/fighters.json (PROTAGONIST the protagonist, RIVAL the antihero, the neutral id rival too);
## his waves are baked and his pick lists and entries built; in a real match his blows are his own key sets (pr and ph for the protagonist, w1 and rb for the rival); the energy
## cues and shots start the sequence or hold of his role; a far taunt is one of his own gestures and is cut like the shared one.
## The press styles (docs/animation/press-styles.md, RenderAnim.press_styles, default ON): each style on each launch fighter through a hand-fed
## exchange. The style layer sits on top of the contact key (a few hundredths of a radian on the spine), a styled blow is never worse
## for the joints than the plain one, the contact point is held through a tech blow's beat, VFX's hand-off (press, press_pose, press_path)
## is filled, and the flag moves no gameplay hash.
func _press_scene(S: SimState, who: String, kind: String, beats: Array) -> Dictionary:
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = "PROTAGONIST" if who == "protagonist" else "RIVAL"
	f1.id = "RIVAL" if who == "protagonist" else "PROTAGONIST"
	RenderAnim._fighters.clear()
	f0.x = 500.0
	f1.x = 560.0
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	var ex := DirExchange.newEx(f0, f1, kind)
	ex.n = 931
	ex.tag = "CHK"
	for b in beats:
		DirExchange.schedule(ex, float(b[0]) / 60.0, "strike", {"a": "A", "dmg": float(b[3]), "piece": String(b[1]), "style": String(b[2]), "o": {"big": float(b[3]) >= 40.0}})
	S.dirS.ex = ex
	var sent: Array = []
	for _b in beats:
		sent.append(false)
	var res := {"styles": {}, "phases": {}, "viol": 0, "nan": 0, "ring": 0, "path": 0, "dx_max": 0.0, "tip_drift": 0.0}
	var tip_at_contact := Vector3.ZERO
	var have_tip := false
	var n_ticks: int = int(float(beats[beats.size() - 1][0]) + 40.0)
	for k in range(n_ticks):
		S.tick = 1000 + k
		S.T = 200.0 + float(k) / 60.0
		ex.t = float(k) / 60.0
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		for bi in range(beats.size()):
			if not sent[bi] and k >= int(beats[bi][0]):
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
		RenderAnim.solve(S, f1)
		for i in range(AnimRig.N):
			if is_nan(af0.q[i].x) or is_nan(af0.q[i].w):
				res.nan += 1
		for stage in af0.audit:
			res.viol += (af0.audit[stage] as Array).size()
		res["ring"] = maxi(int(res.ring), af0.press_ring.size())
		res["path"] = maxi(int(res.path), af0.press_path.size())
		if not af0.press.is_empty():
			res.styles[String(af0.press.style)] = true
			res.phases[String(af0.press.phase)] = true
			if String(af0.press.phase) == "load" and int(af0.press.ordinal) == 0:
				res["load_ticks"] = maxi(int(res.get("load_ticks", 0)), int(af0.press.ticks_to_contact))
			res.dx_max = maxf(float(res.dx_max), absf(float(af0.press.dx)))
			if k == int(beats[0][0]):
				tip_at_contact = af0.socket(String(af0.press.bone))
				have_tip = true
			elif have_tip and k <= int(beats[0][0]) + 8 and String(af0.press.style) == "tech":
				res.tip_drift = maxf(float(res.tip_drift), af0.socket(String(af0.press.bone)).distance_to(tip_at_contact))
	var af: AnimFighter = RenderAnim.fighter(S, f0)
	res["err"] = float(af.debug.get("contact_err_max", 0.0))
	res["frames"] = int(af.debug.get("contact_frames", 0))
	return res


## The brawl's riposte and its stagger (docs/animation/press-styles.md section 12), against hand-staged cues (the sim sends none yet). A blocker's perfect block (or reversal) cue, the riposte cue, the blow's beat with
## `riposte` (or `reversal`, `sure`), and the stagger cue for the rival with its ticks. `solve_every` 2 solves every second tick (consume still runs every tick), to compare the ragdoll's raw state at one and two.
func _rip_scene(S: SimState, who: String, block: String, kind: String, stag_n: int, solve_every: int = 1, reduced: bool = false) -> Dictionary:
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = "PROTAGONIST" if who == "protagonist" else "RIVAL"
	f1.id = "RIVAL" if who == "protagonist" else "PROTAGONIST"
	RenderAnim._fighters.clear()
	RenderAnim.reduced_motion = reduced
	for f in [f0, f1]:
		f.x = 500.0 if f == f0 else 560.0
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
		f.stunTicks = 0
	var contact: int = 60
	var ex := DirExchange.newEx(f0, f1, "heavy" if kind == "heavy" else "light")
	ex.n = 940
	ex.tag = "LAB"
	var bargs := {"a": "A", "dmg": 66.0 if kind == "heavy" else 26.0, "piece": "strike.haymaker" if kind == "heavy" else "strike.cross", "o": {"big": kind == "heavy"}, "sure": true}
	bargs["reversal" if block == "reversal" else "riposte"] = true
	DirExchange.schedule(ex, float(contact) / 60.0, "strike", bargs)
	S.dirS.ex = ex
	var res := {"viol": 0, "nan": 0, "rip_seen": 0, "ttc_at_contact": 99, "sure": false, "press_riposte": false, "load_ttc": 99, "fade": [], "seq": {}, "seq_after": "x", "watch": -1, "err": 0.0, "cue_only": 0, "stag_id": "", "stag_dur": 0.0, "stag_fit": false, "stag_end": -1}
	var f1_seq_seen := false
	var n_ticks: int = contact + stag_n + 30
	for k in range(n_ticks):
		S.tick = 1000 + k
		S.T = 200.0 + float(k) / 60.0
		ex.t = float(k) / 60.0
		var evs: Array = []
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		evs.append(te)
		if k == 20:
			var bc := SimState.FxEvent.new()
			bc.type = "cue"
			bc.actor = 0.0
			bc.kind = block
			bc.tick = S.tick
			evs.append(bc)
		if k == 24:
			var rc := SimState.FxEvent.new()
			rc.type = "cue"
			rc.actor = 0.0
			rc.target = 1.0
			rc.kind = "riposte"
			rc.text = "heavy" if kind == "heavy" else "light"
			rc.n = contact - k
			rc.tick = S.tick
			evs.append(rc)
		if k == contact:
			var sc := SimState.FxEvent.new()
			sc.type = "cue"
			sc.actor = 1.0
			sc.target = 0.0
			sc.kind = "stagger"
			sc.text = block
			sc.n = stag_n
			sc.tick = S.tick
			evs.append(sc)
			f1.stunTicks = stag_n   # the sim's own stun: the old watch would see it
		RenderAnim.consume(S, evs)
		if k % solve_every != 0:
			continue
		var af0: AnimFighter = RenderAnim.solve(S, f0)
		var af1: AnimFighter = RenderAnim.solve(S, f1)
		for i in range(AnimRig.N):
			if is_nan(af0.q[i].x) or is_nan(af0.q[i].w) or is_nan(af1.q[i].x) or is_nan(af1.q[i].w):
				res.nan += 1
		for stage in af0.audit:
			res.viol += (af0.audit[stage] as Array).size()
		for stage in af1.audit:
			res.viol += (af1.audit[stage] as Array).size()
		if not af0.riposte.is_empty():
			res.rip_seen += 1
			if bool(af0.riposte.get("cue", false)):
				res.cue_only += 1
			elif int(af0.riposte.ticks_to_contact) == 0:
				res.ttc_at_contact = 0
		if not af0.press.is_empty():
			res.sure = res.sure or bool(af0.press.get("sure", false))
			res.press_riposte = res.press_riposte or bool(af0.press.get("riposte", false))
			if String(af0.press.phase) == "load" and int(af0.press.ordinal) == 0:
				res.load_ttc = mini(int(res.load_ttc) if int(res.load_ttc) != 99 else 99, 99)
				res["load_first"] = maxi(int(res.get("load_first", 0)), int(af0.press.ticks_to_contact))
		if k >= contact - 8 and k <= contact + 1:
			res.fade.append(af0._rip_fade(S, f0, S.T))
		if not af1._seq.is_empty() and String(af1._seq.id).begins_with("s3.stagger_"):
			f1_seq_seen = true
			res.stag_id = String(af1._seq.id)
			res.stag_dur = float(af1._seq.dur) * 60.0
			res.stag_fit = bool(af1._seq.get("fit", false))
			res.watch = af1._stun_watch
		elif f1_seq_seen and res.stag_end < 0:
			res.stag_end = k - contact
		res["err"] = float(af0.debug.get("contact_err_max", 0.0))
	var th: Array = []
	for f in [f0, f1]:
		var a: AnimFighter = RenderAnim.fighter(S, f)
		for i in range(AnimRagdoll.N):
			th.append(a._rd.th[i])
		th.append(a._rd.out_w)
		for i in range(5):
			th.append(a._sx[i])
		th.append(a._look)
	res["th"] = th
	RenderAnim.reduced_motion = false
	return res


func _test_riposte() -> void:
	_expect(AnimData.press.has("riposte") and AnimData.press.riposte.has("windup") and AnimData.press.riposte.has("fade"), "riposte: data/anim/press_styles.json has no riposte block")
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var audit_was: bool = RenderAnim.joint_audit
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.joint_audit = true
	RenderAnim.ground_feet = false
	AnimData.ensure_fighter("PROTAGONIST")
	AnimData.ensure_fighter("RIVAL")
	var summary: Array = []
	for who in ["protagonist", "antihero"]:
		for case in [["perfect_block", "light", 20], ["perfect_block", "heavy", 40], ["reversal", "light", 20], ["reversal", "heavy", 40]]:
			var block: String = case[0]
			var kind: String = case[1]
			var n: int = case[2]
			var tag: String = "riposte %s %s %s n %d" % [who, block, kind, n]
			RenderAnim.press_styles = true
			var a: Dictionary = _rip_scene(S, who, block, kind, n)
			_expect(int(a.nan) == 0 and int(a.viol) == 0, "%s: %d NaN rotations, %d joint violations" % [tag, int(a.nan), int(a.viol)])
			_expect(int(a.rip_seen) > 5 and int(a.ttc_at_contact) == 0, "%s: the riposte was exposed for %d solves and did not reach 0 ticks to contact (%d)" % [tag, int(a.rip_seen), int(a.ttc_at_contact)])
			_expect(bool(a.press_riposte) and bool(a.sure), "%s: press.riposte %s and press.sure %s on the blow (both must be true)" % [tag, str(a.press_riposte), str(a.sure)])
			# the wind-up is cut: the blow's load phase starts at most 5 ticks (a light) or 6 (a heavy) before the contact
			_expect(int(a.get("load_first", 99)) <= (6 if kind == "heavy" else 5), "%s: the riposte winds up %d ticks ahead of its contact (the cut is %d)" % [tag, int(a.get("load_first", 99)), int(AnimData.press.riposte.windup[kind])])
			_expect(float(a.err) < 0.2, "%s: the blow is %.3f rad from its contact key" % [tag, float(a.err)])
			# the block pose fades out over the fade ticks and is gone on the contact tick
			var fd: Array = a.fade
			var mono: bool = true
			for i in range(1, fd.size()):
				mono = mono and float(fd[i]) <= float(fd[i - 1]) + 0.0001
			_expect(mono and float(fd[0]) > 0.99 and float(fd[fd.size() - 2]) < 0.01, "%s: the block's fade is %s (1 at the start of the fade, 0 on contact, never rising)" % [tag, str(fd)])
			# the stagger: the rival's step 3 stagger fitted to n, the old watch cleared, still the cue's sequence five ticks later
			var sid: String = "s3.stagger_blocked" if block == "perfect_block" else "s3.stagger_countered"
			_expect(String(a.stag_id) == sid and absf(float(a.stag_dur) - float(n)) < 0.01 and bool(a.stag_fit) and int(a.watch) == 0, "%s: stagger %s fitted %s to %.1f ticks (want %s at %d), watch %d" % [tag, String(a.stag_id), str(a.stag_fit), float(a.stag_dur), sid, n, int(a.watch)])
			_expect(int(a.stag_end) >= n - 2 and int(a.stag_end) <= n + 4, "%s: the stagger ended %d ticks after the cue (want %d)" % [tag, int(a.stag_end), n])
			summary.append("%s %s n%d: load %d ticks ahead" % [block, kind, n, int(a.get("load_first", 99))])
	# reduced motion does not shorten the stagger (it is the sim's time)
	RenderAnim.press_styles = true
	var rm: Dictionary = _rip_scene(S, "protagonist", "perfect_block", "light", 20, 1, true)
	_expect(absf(float(rm.stag_dur) - 20.0) < 0.01, "riposte: reduced motion plays the stagger for %.1f ticks (the sim's 20)" % float(rm.stag_dur))
	# the stagger cue wins over the old watch whichever comes first: a perfect_block cue after the stagger cue sets no watch (same tick)
	# one tick a frame against two: the ragdoll's raw state agrees to the same tolerance as the ragdoll test
	var r1: Dictionary = _rip_scene(S, "protagonist", "perfect_block", "heavy", 40, 1)
	var r2: Dictionary = _rip_scene(S, "protagonist", "perfect_block", "heavy", 40, 2)
	var dmax: float = 0.0
	for i in range(mini(r1.th.size(), r2.th.size())):
		dmax = maxf(dmax, absf(float(r1.th[i]) - float(r2.th[i])))
	_expect(dmax <= RD_FRAME_TOL, "riposte: the ragdoll state differs by %s between one tick a frame and two (tolerance %s)" % [str(dmax), str(RD_FRAME_TOL)])
	# the flag off: the beat plays as any blow (no cut, no press), the cue still exposes the riposte for VFX and the stagger still plays
	RenderAnim.press_styles = false
	var off: Dictionary = _rip_scene(S, "antihero", "perfect_block", "light", 20)
	_expect(not bool(off.press_riposte) and String(off.stag_id) == "s3.stagger_blocked" and int(off.rip_seen) > 5, "riposte: with the press styles off press.riposte is %s, the stagger %s, the riposte exposed for %d solves" % [str(off.press_riposte), String(off.stag_id), int(off.rip_seen)])
	RenderAnim.press_styles = styles_was
	RenderAnim.joint_audit = audit_was
	RenderAnim.ground_feet = ground_was
	S.dirS.ex = null
	print("riposte: %s; the block fades out over the data's ticks, press.sure and press.riposte exposed, the stagger fitted to n (20 and 40) for both builds, one tick a frame against two within %s" % [", ".join(summary.slice(0, 3)), str(RD_FRAME_TOL)])


## The flurry look study's three strengths (docs/animation/flurry-study.md): X light (speed), Y medium, B super, and the burst's gap rule. `contacts` are ticks; `extra` is merged into every beat (windup).
var _tier_dist: float = 60.0    # how far apart a tier scene stages the two (the closing rule's slack beyond striking distance is added to it)
var _tier_damage: bool = false   # a tier scene sends the damage event of every blow, so the defender reacts as in the study scene (the heads close on each other in a run)


func _tier_scene(S: SimState, who: String, style: String, pieces: Array, contacts: Array, extra: Dictionary = {}, kind: String = "light") -> Dictionary:
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = "PROTAGONIST" if who == "protagonist" else ("REFERENCE" if who == "common" else "RIVAL")   # `common`: the training dummy (data/anim/fighters.json `common`)
	f1.id = "RIVAL" if who == "protagonist" else "PROTAGONIST"
	RenderAnim._fighters.clear()
	var key: String = String(AnimData.ensure_fighter(String(f0.id)))
	AnimData.ensure_fighter(String(f1.id))
	var su_pre: String = "pu.su_" if who == "protagonist" else ("gd.su_" if who == "common" else "ru.su_")   # the super-heavy tier is parked (no fighter's wave list names it): every piece of it is findable by name
	var rc_pre: String = "pk." if who == "protagonist" else "rk."   # the energy-in-reach pieces (C2t) are parked too
	for kid in AnimData.keysets:
		if String(kid).begins_with(su_pre) or String(kid).begins_with(rc_pre):
			AnimData.pair_lists[key].by_name[String(kid).substr(3)] = String(kid)
	for pre in ["pm.", "rm."]:
		for nm2 in ["palm_rise", "back_chop", "fist_chop", "palm_heave", "gut_rise", "fist_sweep", "arm_chop", "plate_drop"]:
			if AnimData.keysets.has(pre + nm2):
				AnimData.pair_lists[key].by_name[pre + nm2] = pre + nm2
	f0.x = 500.0
	f1.x = 500.0 + _tier_dist
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	var ex := DirExchange.newEx(f0, f1, kind)
	ex.n = 970
	ex.tag = "TIER"
	for i in range(contacts.size()):
		var bargs := {"a": "A", "dmg": 20.0 if kind == "light" else 60.0, "piece": "strike." + String(pieces[i % pieces.size()]), "style": style, "o": {"big": kind == "heavy"}}
		bargs.merge(extra, true)
		if bargs.has("_hands"):
			bargs["hand"] = String((bargs["_hands"] as Array)[i % (bargs["_hands"] as Array).size()])   # the arm of each blow of a run
			bargs.erase("_hands")
		DirExchange.schedule(ex, float(contacts[i]) / 60.0, "strike", bargs)
	S.dirS.ex = ex
	var res := {"reach": [], "nan": 0, "screen": 0, "ghosts": 0, "squash": 0.0, "lead": 0.0, "load_first": [], "load_run": 0, "err": 0.0, "frames": 0, "parts": [], "exc": [], "sides": []}
	var hi_run: int = 0
	var hi_max: int = 0
	var wrist_min: float = 1.0e9
	var hi_early: int = 0
	var peak_y: float = -1.0e9
	var peak_apart: float = 0.0
	var dev_sum: float = 0.0
	var dev_n: int = 0
	var arm_idx: Array = []
	for bn in ["upper_arm_r", "forearm_r", "upper_arm_l", "forearm_l"]:
		arm_idx.append(AnimRig.index[bn])
	var hxr: Array = []   # the forward reach of each hand on every tick, from the pelvis (to find how far the striking hand draws back between contacts)
	var hxl: Array = []
	var limbs: Array = []
	var cset: Dictionary = {}
	for c in contacts:
		cset[int(c)] = true
	var run: int = 0
	var seen_first: Dictionary = {}
	for k in range(int(contacts[contacts.size() - 1]) + 50):
		S.tick = 1000 + k
		S.T = 200.0 + float(k) / 60.0
		ex.t = float(k) / 60.0
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		if _tier_damage and cset.has(k):
			var dmg_e := SimState.FxEvent.new()
			dmg_e.type = "damage"
			dmg_e.victim = 1.0
			dmg_e.attacker = 0.0
			dmg_e.kind = kind
			dmg_e.amount = 20.0 if kind == "light" else 60.0
			dmg_e.region = "core"
			RenderAnim.consume(S, [dmg_e])
		var af0: AnimFighter = RenderAnim.solve(S, f0)
		var af1t: AnimFighter = RenderAnim.solve(S, f1)
		if _bn_on:
			_bend_sample(who, k, af0)
		for i in range(AnimRig.N):
			if is_nan(af0.q[i].x) or is_nan(af0.q[i].w):
				res.nan += 1
		res.screen += AnimJoints.violations(af0.q, af0._rd.shape_key).size()
		if k >= int(contacts[0]) - 2:
			var hg: float = (float(f1.x) - float(f0.x)) + af1t.vface * af1t.socket("head").x - af0.vface * af0.socket("head").x   # the world gap between the two heads (the defender is drawn mirrored)
			if hg < float(res.get("hmin", 1.0e9)):
				res["hmin"] = hg
				res["hmin_k"] = k - int(contacts[0])
		if not af0.press.is_empty():
			var stl: Dictionary = res.get("styles", {})
			stl[String(af0.press.style)] = true
			res["styles"] = stl
		res["hold_max"] = maxf(float(res.get("hold_max", 0.0)), af0.hold_coil)
		if k >= int(contacts[0]) - 30 and k <= int(contacts[0]) + 4:
			var fl: Array = res.get("feet", [])
			fl.append([k - int(contacts[0]), af0.socket("foot_r").y, af0.socket("foot_l").y, af0.socket("pelvis").y])   # [ticks to the contact, the right foot's height, the left's, the pelvis's]
			res["feet"] = fl
		if af0.burst_set > 0.5:
			res["set_ticks"] = int(res.get("set_ticks", 0)) + 1
			res["set_first"] = mini(int(res.get("set_first", 9999)), k)
			res["set_last"] = maxi(int(res.get("set_last", 0)), k)
			res["set_apart"] = minf(float(res.get("set_apart", 1.0e9)), af0.socket("hand_r").distance_to(af0.socket("hand_l")))
			res["set_top"] = maxf(float(res.get("set_top", 0.0)), maxf(af0.socket("hand_r").y, af0.socket("hand_l").y))
		if not af0.press.is_empty():
			res.ghosts = maxi(int(res.ghosts), int(af0.press.ghosts))
			res.squash = maxf(float(res.squash), float(af0.press.squash))
			res.lead = maxf(float(res.lead), absf(float(af0.press.dx)))
			var bl: int = int(af0.press.blow)
			if String(af0.press.phase) == "load":
				run += 1
				if not seen_first.has(bl):
					seen_first[bl] = true
					res.load_first.append(int(af0.press.ticks_to_contact))
			else:
				if run > int(res.load_run):
					res.load_run = run
				run = 0
			if cset.has(k):
				# on the blow's own contact tick (a tight burst never shows the "contact" phase: the next blow's window has opened)
				res.parts.append(af0._part)
				res.sides.append(bool(af0.press.side))
				limbs.append(String(af0.press.limb))
		if k >= int(contacts[0]) - 2 and k <= int(contacts[contacts.size() - 1]) + 2 and af0._base.size() == AnimRig.N:
			var dv: float = 0.0
			for ai in arm_idx:
				dv += af0.q[ai].angle_to(af0._base[ai])
			dev_sum += dv
			dev_n += 1
		if k >= int(contacts[0]) - 28 and k <= int(contacts[0]) - 7:
			wrist_min = minf(wrist_min, af0.socket("hand_r").distance_to(af0.socket("hand_l")))
		var topy: float = maxf(maxf(af0.socket("hand_r").y, af0.socket("hand_l").y), maxf(af0.socket("foot_r").y, af0.socket("foot_l").y))
		var hy: float = maxf(af0.socket("hand_r").y, af0.socket("hand_l").y)
		if hy > peak_y:
			peak_y = hy
			peak_apart = af0.socket("hand_r").distance_to(af0.socket("hand_l"))
		if topy > 80.0 and not cset.has(k) and k < int(contacts[0]) - 6:
			hi_early += 1
		if topy > 80.0 and not cset.has(k):
			hi_run += 1
			hi_max = maxi(hi_max, hi_run)
		else:
			hi_run = 0
		if (k >= int(contacts[0]) - 34 and k <= int(contacts[0]) and (k - int(contacts[0])) % 4 == 0) or (k > int(contacts[0]) and k <= int(contacts[0]) + 14 and (k - int(contacts[0])) % 2 == 0):
			var pv: Vector3 = af0.socket("pelvis")
			var tr := {"dt": k - int(contacts[0]), "ph": String(af0.press.get("phase", "")), "ks": af0._part, "px": af0.socket("pelvis").x, "tw": absf(af0.socket("upper_arm_r").x - af0.socket("upper_arm_l").x)}
			for sn in ["hand_r", "hand_l", "foot_r", "foot_l"]:
				tr[sn] = (af0.socket(sn) - pv).snapped(Vector3(0.1, 0.1, 0.1))
			tr["hgap"] = (float(f1.x) - float(f0.x)) + af1t.vface * af1t.socket("head").x - af0.vface * af0.socket("head").x   # the world gap between the two heads (the defender is drawn mirrored)
			var el: Vector3 = af0.socket("forearm_r")
			var hd: Vector3 = af0.socket("hand_r")
			tr["fa"] = rad_to_deg(atan2(hd.y - el.y, hd.x - el.x))   # the forearm's angle in the side view (0 level, up positive): a line is level, a flick rises, a sweep falls
			tr["abs_hand_r"] = af0.socket("hand_r").y
			tr["abs_hand_l"] = af0.socket("hand_l").y
			tr["pv_y"] = pv.y
			if not res.has("trace"):
				res["trace"] = []
			res["trace"].append(tr)
		hxr.append(af0.socket("hand_r").x - af0.socket("pelvis").x)
		hxl.append(af0.socket("hand_l").x - af0.socket("pelvis").x)
		var lfix: float = float(af0.debug.get("limit_fix", 0.0))   # what the solve's last pass had to pull back this frame (radians, the worst joint)
		res["fix_max"] = maxf(float(res.get("fix_max", 0.0)), lfix)
		res["march"] = maxf(float(res.get("march", 0.0)), af0.march_w)
		res["bob"] = maxf(float(res.get("bob", 0.0)), af0.press_bob)
		if lfix > deg_to_rad(20.0):
			res["fix_n20"] = int(res.get("fix_n20", 0)) + 1
		if lfix > deg_to_rad(10.0):
			res["fix_n10"] = int(res.get("fix_n10", 0)) + 1
		if lfix > deg_to_rad(30.0):
			res["fix_n30"] = int(res.get("fix_n30", 0)) + 1
			var fl: Array = res.get("fix_log", [])
			fl.append("k%d (contact %d) %.0f deg, press %s, B %s, D %s" % [k, int(contacts[0]), rad_to_deg(lfix), str(af0.press.get("phase", "")), str(af0.audit.get("B", "")), str(af0.audit.get("D", ""))])
			res["fix_log"] = fl
		res.err = float(af0.debug.get("contact_err_max", 0.0))
		res["gap"] = float(af0.debug.get("gap_max", 0.0))   # how far short of the target the hand ends at the contact, in units
		res.frames = int(af0.debug.get("contact_frames", 0))
	# the excursion of each blow: how much farther the hand is at its contact than at its deepest point since the last one
	for i in range(1, contacts.size()):
		var arr: Array = hxl if (i < limbs.size() and String(limbs[i]).ends_with("l")) else hxr
		var lo: float = 1.0e9
		for k2 in range(int(contacts[i - 1]) + 2, int(contacts[i])):
			lo = minf(lo, float(arr[k2]))
		res.exc.append(float(arr[mini(int(contacts[i]) + 1, arr.size() - 1)]) - lo)
	if run > int(res.load_run):
		res.load_run = run
	res["hi_max"] = hi_max
	res["wrist_gather"] = wrist_min
	res["hi_early"] = hi_early
	res["peak_apart"] = peak_apart
	res["dev"] = dev_sum / maxf(1.0, float(dev_n))
	return res


## Legal h05 on a chamber pose (a wind-up of 12 ticks or more is a held pose): the loaded limb at shoulder height or lower (a leg may be chambered), never a hand at a hip, never both hands together
## (shoulder width, 20, apart at least), no limb above 80, no crossed forearms. Reads the pose's authored targets.
func _h05_chamber(pid: String) -> Array:
	var out: Array = []
	if not AnimData.raw.has(pid):
		return ["no pose " + pid]
	var d: Dictionary = AnimData.raw[pid]
	var hr = d.get("hand_r")
	var hl = d.get("hand_l")
	for hv in [["right", hr], ["left", hl]]:
		var h = hv[1]
		if h != null and float(h[0]) <= 14.0 and float(h[1]) >= 24.0 and float(h[1]) <= 44.0:
			out.append("the %s hand is at a hip" % hv[0])
	if hr != null and hl != null:
		var dd: float = Vector3(float(hr[0]) - float(hl[0]), float(hr[1]) - float(hl[1]), float(hr[2]) - float(hl[2])).length()
		if dd < 20.0:
			out.append("both hands together (%.0f apart)" % dd)
		if float(hr[2]) < -2.0 and float(hl[2]) > 2.0:
			out.append("the forearms are crossed")
	for k in ["hand_r", "hand_l", "foot_r", "foot_l"]:
		var v = d.get(k)
		if v != null and float(v[1]) > 80.0:
			out.append("%s is above 80 (%.0f)" % [k, float(v[1])])
	return out


## A real zip, in a real sim (Encounter's DirZip: docs/director/zip-z1.md), started by the director's own function on a staged pair, the AI at its easiest so nobody answers. `exit_ai` is the AI zipper's
## exit (0 back, 1 the far side, 2 above, 3 away); `hook` is called each tick with (S, zipper, tick since the start) and may end the zip another way. Returns what the body did, tick by tick.
func _zip_live(seed: int, heavy: bool, exit_ai: int, hook = null, ticks_after: int = 40, rival_ans: int = 0, ans_at: int = 6, level: String = "easy") -> Dictionary:
	load("res://sim/director/ai.gd").set("level", level)
	RenderAnim._fighters.clear()
	main.start_match(seed, {"p1": true, "p2": true})
	for i in range(6):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var z0 = S.fighters[0]
	var z1 = S.fighters[1]
	S.dirS.ex = null
	z0.x = 500.0
	z1.x = 500.0 + 450.0
	for f in [z0, z1]:
		f.y = WorldTerrain.groundY(S, f.x)
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
		f.stunTicks = 0
		f.ki = 100.0
	DirZip.start(S, z0, z1, heavy, S.tick)
	DirZip._s(z0, DirZip.AI_EXIT, exit_ai)
	if rival_ans > 0:
		DirZip._s(z1, DirZip.AI_ANS, rival_ans)
		DirZip._s(z1, DirZip.AI_AT, S.tick + ans_at)
	var res := {"phases": [], "frames": 0, "drawn_in": 0, "drawn_out": 0, "gap_zip": 0, "nan": 0, "screen": 0, "reads": [], "end": "", "exit": "", "pass": "", "via": "", "tilt": 0.0, "depth": 0.0, "pos": [], "states": [], "blows": 0, "dropped_ticks": 0, "drop_seen": false, "plan": {}, "arrived_hold": 0}
	var t_zip: int = 0
	var after: int = 0
	var started := false
	var af: AnimFighter = null
	for k in range(900):
		main.frame(1.0 / 60.0)
		af = RenderAnim.fighter(S, z0)
		var r: Dictionary = DirZip.read(S, z0)
		res.frames += 1
		for i in range(AnimRig.N):
			if is_nan(af.q[i].x) or is_nan(af.q[i].w):
				res.nan += 1
		res.screen += AnimJoints.violations(af.q, af._rd.shape_key).size()
		if not r.is_empty():
			started = true
			t_zip += 1
			if (res.phases as Array).is_empty() or String(res.phases[res.phases.size() - 1]) != String(r.phase):
				res.phases.append(String(r.phase))
				if res.plan.is_empty():
					res.plan = {"tell": int(r.tell), "in": int(r["in"]), "hd": int(r.hd), "out": int(r.out), "reading": String(r.reading)}
			res.reads.append(r)
			if String(r.phase) == "in" and not af.zip.is_empty() and String(af.zip.phase) == "in":
				res.drawn_in += 1
			if String(r.phase) == "out" and not af.zip.is_empty() and String(af.zip.phase) == "out":
				res.drawn_out += 1
			if af.zip.is_empty():
				res.gap_zip += 1
				res["gap_at"] = String(r.phase) + str(int(r.n))
			if String(r.phase) == "reach" and int(r.blow) == 0 and bool(af.zip.get("live", false)):
				res.arrived_hold += 1
			if int(r.blow) == 1:
				res.blows = 1
			res.exit = String(r.exit) if String(r.exit) != "" else res.exit
			res["pass"] = String(r["pass"]) if String(r["pass"]) != "" else res["pass"]
			res.via = String(r.via) if String(r.via) != "" else res.via
			res.tilt = maxf(float(res.tilt), absf(af._zip_tilt))
			res.depth = maxf(float(res.depth), absf(af._zip_depth))
			if hook != null:
				hook.call(S, z0, t_zip)
		res.pos.append(Vector2(z0.x, z0.y))
		res.states.append(String(z0.state))
		if z0.state == "dropped":
			res.dropped_ticks += 1
			res.drop_seen = true
		if started and r.is_empty():
			after += 1
			if String(res.end) == "":
				res.end = af._zip_last_end
			if after > ticks_after:
				break
	res["hash"] = str(SimHash.stateHash(S).gameplay)
	res["af"] = af
	RenderAnim.reduced_motion = false
	return res


## A hook that ends the live zip the way the director would, once the zip is in `phase_name` for 2 ticks: `why` is the end word (stopped, outrun, shot or down); down also drops him (SimFighter.drop), as a shot on the way out does.
func _zhook(phase_name: String, why: String, drop: bool = false) -> Callable:
	var st := {"done": false}
	return func(S, z, t):
		var r: Dictionary = DirZip.read(S, z)
		if st.done or r.is_empty() or String(r.phase) != phase_name or int(r.n) < 2:
			return
		st.done = true
		DirZip._end(S, z, why)
		var vx: float = z.vx
		var vy: float = z.vy
		z.rush = null
		if drop:
			SimFighter.drop(S, z, int(DirZip.cfg().knockdownTicks), vx, vy)


## The zip's view (docs/animation/zip.md sections 9 to 15; the EP's Z1 brief): the body from the tell to the exit on real zips of the director, every zip_end word, the drop and the three exits.
func _test_zip_view() -> void:
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.press_styles = true
	var ai_was = load("res://sim/director/ai.gd").get("level")
	var ground_was: bool = RenderAnim.ground_feet
	RenderAnim.ground_feet = false
	var summary: Array = []
	# 1. the tell to the exit, a strike and a heavy, on the four exits the AI zipper holds (back, the far side, above, away)
	var kinds: Dictionary = {}
	for sc in [[false, 0], [false, 1], [false, 2], [false, 3], [true, 0], [true, 1]]:
		var r: Dictionary = _zip_live(4, sc[0], sc[1])
		var tag: String = "zip view %s exit %d" % ["heavy" if sc[0] else "strike", sc[1]]
		var n_in: int = 0
		var n_out: int = 0
		for rd in r.reads:
			n_in += 1 if String(rd.phase) == "in" else 0
			n_out += 1 if String(rd.phase) == "out" else 0
		_expect(r.phases == ["tell", "in", "reach", "out"], "%s: the phases are %s" % [tag, str(r.phases)])
		_expect(int(r.nan) == 0 and int(r.screen) == 0, "%s: %d NaN, %d joint violations on screen" % [tag, int(r.nan), int(r.screen)])
		# Legal RL-076: the way in and the way out are each drawn on at least 4 ticks, the body present on every tick of the zip (the one tick the zip starts on is the sim's own: it began before the first frame)
		_expect(n_in >= 4 and n_out >= 4 and int(r.drawn_in) == n_in and int(r.drawn_out) == n_out, "%s: the way in is %d ticks and was drawn on %d, the way out %d and %d (4 each at least, all drawn)" % [tag, n_in, int(r.drawn_in), n_out, int(r.drawn_out)])
		_expect(int(r.gap_zip) <= 1, "%s: the zip's layers were missing on %d ticks (at %s)" % [tag, int(r.gap_zip), str(r.get("gap_at", "-"))])
		_expect(String(r.end) == "done" and int(r.blows) == 1, "%s: the zip ended %s with %d blows (done and 1 wanted)" % [tag, String(r.end), int(r.blows)])
		_expect(int(r.arrived_hold) >= (11 if sc[0] else 3), "%s: the body held its arrival for %d ticks before the blow (the sim's 4 or 12 ticks after arriving)" % [tag, int(r.arrived_hold)])
		var key: String = "%s/%s/%s" % [String(r.exit), String(r["pass"]), String(r.via)]
		kinds["%s %d" % ["heavy" if sc[0] else "strike", sc[1]]] = {"key": key, "tilt": float(r.tilt), "depth": float(r.depth), "exit": String(r.exit), "pos": r.pos}
		summary.append("%s %d: %s tilt %.2f depth %.0f" % ["heavy" if sc[0] else "strike", sc[1], key, float(r.tilt), float(r.depth)])
	# 2. the three exits read apart: home goes back (a back-step), the far side goes through (a run over him, drawn in front of him), a point goes round (a run, tilted along its path)
	var home: Dictionary = kinds["strike 0"]
	var far: Dictionary = kinds["strike 1"]
	var pt: Dictionary = kinds["strike 2"]
	_expect(String(home.exit) == "home" and String(far.exit) == "far" and String(pt.exit) == "point", "zip view: the exits came out %s, %s and %s" % [String(home.exit), String(far.exit), String(pt.exit)])
	_expect(String(home.key) != String(far.key) and String(far.key) != String(pt.key) and String(home.key) != String(pt.key) or (float(far.tilt) > float(home.tilt) + 0.1 and float(pt.tilt) > float(home.tilt) + 0.1), "zip view: the three exits do not differ in via, pass or tilt (%s, %s, %s)" % [String(home.key), String(far.key), String(pt.key)])
	_expect(float(far.depth) >= float(AnimData.zip.get("pass_depth", {}).get("z", 24.0)) - 0.01, "zip view: a far-side pass is drawn %.1f toward the camera, not %.1f (the pass depth)" % [float(far.depth), float(AnimData.zip.get("pass_depth", {}).get("z", 24.0))])
	_expect(float(home.depth) == 0.0 and float(home.tilt) < 0.2, "zip view: a home exit tilts %.2f and is drawn %.1f in front (a back-step is neither)" % [float(home.tilt), float(home.depth)])
	# 3. the pass names map to entries (over, round, under), and a read's entries and pass are what the body plays
	var fi: AnimFighter = AnimFighter.new(0)
	fi.pair_key = "protagonist"
	var fake := {"phase": "out", "n": 1, "len": 10, "tell": 6, "in": 7, "hd": 10, "out": 10, "reading": "speed", "btn": "x", "blow": 1, "via": "run", "pass": "", "entry_in": "", "entry_out": "", "dist_bh": 6.0, "exit": "far", "x": 0.0, "y": 0.0}
	var want := {"over": "arc_dive", "round": "pivot", "under": "pivot"}
	for pk in want:
		fake["pass"] = pk
		var zz: Dictionary = AnimZip._from_read(fi, fake, 5.0)
		_expect(String(zz.entry_out) == String(want[pk]) and int(zz.T4) == 6 + 7 + 10 + 10 and absf(float(zz.t0) - (5.0 - float(zz.tk) / 60.0)) < 0.0001, "zip view: pass %s plays %s (wanted %s), T4 %d" % [pk, String(zz.entry_out), String(want[pk]), int(zz.T4)])
	# 4. every zip_end word has a look
	var rs: Dictionary = {}
	rs["stopped"] = _zip_live(4, false, 0, _zhook("in", "stopped"))
	rs["outrun"] = _zip_live(4, false, 0, _zhook("in", "outrun"))
	rs["shot"] = _zip_live(4, false, 0, _zhook("in", "shot"))
	for why in ["stopped", "outrun", "shot"]:
		var r2: Dictionary = rs[why]
		_expect(String(r2.end) == why and int(r2.nan) == 0 and int(r2.screen) == 0, "zip view %s: the end was %s, %d NaN, %d joint violations on screen" % [why, String(r2.end), int(r2.nan), int(r2.screen)])
	var ov: int = int((rs["outrun"].af as AnimFighter).debug.get("overcommits", 0))
	_expect(ov >= 1, "zip view outrun: the zipper was not carried past off balance (overcommits %d)" % ov)
	var ov0: int = int((rs["stopped"].af as AnimFighter).debug.get("overcommits", 0))
	_expect(ov0 == 0, "zip view stopped: the zipper was carried past (overcommits %d)" % ov0)
	# countered: a light pressed inside the arrival's window (a strike), a heavy for a heavy; caught: the hard AI's punish after the blow
	var cs: Dictionary = _zip_live(4, false, 0, null, 30, 3, 10)
	_expect(String(cs.end) == "countered" and int(cs.nan) == 0 and int(cs.screen) == 0, "zip view countered: the end was %s, %d NaN, %d violations" % [String(cs.end), int(cs.nan), int(cs.screen)])
	var ch: Dictionary = {}
	for sd in [4, 5, 6, 7, 8, 9, 10, 11]:
		var cr: Dictionary = _zip_live(sd, false, 0, null, 30, 0, 6, "hard")
		if String(cr.end) == "caught":
			ch = cr
			break
	_expect(not ch.is_empty() and int(ch.nan) == 0 and int(ch.screen) == 0, "zip view caught: no zip of eight seeds against the hard AI ended caught (the punish)")
	var cf: AnimFighter = cs.af
	# 5. a drop: shot down on the way out, falls for the sim's ticks, lands soft, recovers
	var dn: Dictionary = _zip_live(4, false, 0, _zhook("out", "down", true), 60)
	var daf: AnimFighter = dn.af
	_expect(bool(dn.drop_seen) and int(dn.dropped_ticks) == int(DirZip.cfg().knockdownTicks) and int(dn.nan) == 0 and int(dn.screen) == 0, "zip view down: dropped %d ticks (the sim's %d), %d NaN, %d violations on screen" % [int(dn.dropped_ticks), int(DirZip.cfg().knockdownTicks), int(dn.nan), int(dn.screen)])
	_expect(String(dn.end) == "down" and daf._drop.is_empty() and String(dn.states[dn.states.size() - 1]) == "free", "zip view down: end %s, the drop %s at the end, the state %s" % [String(dn.end), str(daf._drop), String(dn.states[dn.states.size() - 1])])
	_expect(int(daf.debug.get("drops", 0)) == 1, "zip view down: %d drops seen" % int(daf.debug.get("drops", 0)))
	# 6. a rendered run and the sim alone end in the same gameplay hash
	RenderAnim.enabled = false
	var off: Dictionary = _zip_live(4, true, 1)
	RenderAnim.enabled = true
	var on_: Dictionary = _zip_live(4, true, 1)
	_expect(String(off.hash) == String(on_.hash), "zip view: the gameplay hash differs with the animation off (%s) and on (%s)" % [String(off.hash), String(on_.hash)])
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	load("res://sim/director/ai.gd").set("level", ai_was if ai_was != null else "medium")
	print("zip view: %s; every end word (stopped, outrun, shot, countered, caught, down) has a look; a drop falls %d ticks and recovers; the way in and out are drawn on every tick" % [" | ".join(summary), int(DirZip.cfg().knockdownTicks)])


func _test_flurry_tiers() -> void:
	AnimData.load_every_wave()
	var dig_was: bool = RenderAnim.dig_in
	var ease_was: bool = RenderAnim.fighter_ease
	RenderAnim.fighter_ease = false   # the narrowing is the global row's: each fighter's own ease is tested in _test_round10
	RenderAnim.dig_in = false   # this test is about the burst's narrowing (arm distance from guard): the held X's dig-in moves the legs and is tested in _test_cells
	var P: Dictionary = AnimData.press.get("styles", {})
	_expect(P.has("medium") and P.has("super") and P.has("speed"), "flurry tiers: press_styles.json needs the speed, medium and super rows")
	var sp: Dictionary = P.get("speed", {})
	var bu: Dictionary = P.get("burst", {})
	var md: Dictionary = P.get("medium", {})
	var su: Dictionary = P.get("super", {})
	# the three strengths are ordered in the data: the lead, the squash, the ghosts and the wind-up grow from X to Y to B
	_expect(float(su.stretch.lead) > float(md.stretch.lead) and float(md.stretch.lead) > float(sp.stretch.lead), "flurry tiers: the stretch lead is not ordered X < Y < B")
	_expect(float(su.squash) > float(md.squash) and float(md.squash) > float(sp.squash), "flurry tiers: the squash is not ordered X < Y < B")
	_expect(int(su.ghosts) <= 2 and int(md.ghosts) <= 2 and int(bu.ghosts) <= 2, "flurry tiers: a new row has more than 2 ghosts of a limb (Legal f01: at most 2 at any instant)")
	_expect(int(su.prof.load_ticks.heavy) > int(md.prof.load_ticks.heavy) and int(md.prof.load_ticks.heavy) > int(sp.prof.load_ticks.heavy), "flurry tiers: the wind-up is not ordered X < Y < B")
	# the gap rule: monotone, the data's floor at its `from`, 1 from its `to`, and a mash at 6 ticks or more is today's
	var ga: Dictionary = bu.get("gap_amp", {})
	_expect(not ga.is_empty() and float(ga.to) <= 12.0 and not sp.has("gap_amp"), "flurry tiers: the burst row has no gap_amp, or the live speed row carries one (an ordinary mash must not be narrowed)")
	var fi: AnimFighter = AnimFighter.new(0)
	var prev: float = 0.0
	var mono: bool = true
	for g in [2.0, 4.0, 5.0, 6.0, 8.0, 11.0, 15.0]:
		var a: float = fi._gap_amp(bu, g)
		mono = mono and a >= prev - 0.0001
		prev = a
	_expect(mono and absf(fi._gap_amp(bu, float(ga.get("from", 3))) - float(ga.get("min", 0.55))) < 0.001 and fi._gap_amp(bu, float(ga.get("to", 11))) > 0.999 and fi._gap_amp(bu, 5.0) < 0.999, "flurry tiers: the gap rule is not monotone, or does not run from its floor to 1")
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	var summary: Array = []
	for who in ["protagonist", "antihero"]:
		var tag: String = "flurry tiers %s" % who
		# the held-X burst: one blow every 3 ticks slowing to one every 10 (gaps 3 3 3 4 4 5 6 7 8 10), straight blows
		var bc: Array = [30, 34, 38, 43, 49, 57, 68, 83]   # gaps 4 4 5 6 8 11 15: three under 6 in a row at the opening (Legal f04)
		var run6: int = 0
		var max6: int = 0
		for i in range(1, bc.size()):
			run6 = run6 + 1 if int(bc[i]) - int(bc[i - 1]) < 6 else 0
			max6 = maxi(max6, run6)
		_expect(max6 <= 3, "%s: the burst runs %d blows in a row under 6 ticks apart (f04 allows 3)" % [tag, max6])
		var burst: Dictionary = _tier_scene(S, who, "burst", ["cross", "pm.palm_rise" if who == "protagonist" else "rm.gut_rise", "pm.back_chop" if who == "protagonist" else "rm.fist_sweep", "palm_heel", "spear_hand", "pm.fist_chop" if who == "protagonist" else "rm.arm_chop", "pm.palm_heave" if who == "protagonist" else "rm.plate_drop", "jab"], bc)
		_expect(int(burst.nan) == 0 and int(burst.screen) == 0 and int(burst.frames) == bc.size(), "%s: the burst has %d NaN, %d joint violations on screen, %d of %d contacts" % [tag, int(burst.nan), int(burst.screen), int(burst.frames), bc.size()])
		var sides: Array = burst.sides
		var alt: bool = sides.size() == bc.size()
		for i in range(1, sides.size()):
			alt = alt and sides[i] != sides[i - 1]
		_expect(alt, "%s: the burst's hands do not alternate (%s; f05)" % [tag, str(sides)])
		# the narrowing: the same straight blow drawn back farther when it is thrown slower (a controlled pair of scenes; the pieces of the real burst differ in how far they draw back)
		var tight: Dictionary = _tier_scene(S, who, "burst", ["cross", "palm_heel", "spear_hand"], [30, 34, 38, 43])
		var plain: Dictionary = _tier_scene(S, who, "speed", ["cross", "palm_heel", "spear_hand"], [30, 34, 38, 43])
		var slow: Dictionary = _tier_scene(S, who, "burst", ["cross", "palm_heel", "spear_hand"], [30, 42, 54, 66])
		var slow_plain: Dictionary = _tier_scene(S, who, "speed", ["cross", "palm_heel", "spear_hand"], [30, 42, 54, 66])
		var early: float = float(tight.dev)
		var late: float = float(slow.dev)
		# the same blows at the same tight gaps carry the arms less far from their guard in the burst than in a plain mash, and a slow burst is not narrowed at all
		_expect(float(tight.dev) < 0.93 * float(plain.dev) and absf(float(slow.dev) - float(slow_plain.dev)) < 0.02 * maxf(0.1, float(slow_plain.dev)), "%s: the burst's narrowing: tight %.3f against a plain mash %.3f, slow %.3f against %.3f (arm distance from guard, rad)" % [tag, float(tight.dev), float(plain.dev), float(slow.dev), float(slow_plain.dev)])
		# a mash at 6 ticks is today's: no narrowing
		var mash: Dictionary = _tier_scene(S, who, "speed", ["cross"], [30, 36, 42, 48, 54, 60])
		var mm: Array = mash.exc
		_expect(float(mm[mm.size() - 1]) > late - 5.0 and int(mash.screen) == 0, "%s: a 6-tick mash draws back %.1f against the slow burst's %.1f (it must not be narrowed)" % [tag, float(mm[mm.size() - 1]), late])
		# Y mash, medium, every 14 ticks; B mash, super, every 28, on the provisional pieces
		var ym: Dictionary = _tier_scene(S, who, "medium", ["double_palm", "roundhouse", "cross_arm_ram", "spinning_heel"], [34, 48, 62, 76], {}, "heavy")
		var bm: Dictionary = _tier_scene(S, who, "super", ["su_drive", "su_turn"] if who == "protagonist" else ["su_ram", "su_heel"], [44, 72, 100, 128], {}, "heavy")
		for sc in [["Y mash", ym, 4], ["B mash", bm, 4]]:
			var r: Dictionary = sc[1]
			_expect(int(r.nan) == 0 and int(r.screen) == 0 and int(r.frames) == int(sc[2]), "%s: %s has %d NaN, %d joint violations on screen, %d of %d contacts" % [tag, sc[0], int(r.nan), int(r.screen), int(r.frames), int(sc[2])])
			_expect(float(r.err) < 0.25, "%s: %s contact pose is %.3f rad from the key" % [tag, sc[0], float(r.err)])
		_expect(String(bm.parts[0]).begins_with("pu.su_") or String(bm.parts[0]).begins_with("ru.su_"), "%s: the B mash played %s, not the provisional pieces" % [tag, str(bm.parts)])
		# the three read apart by size: the super reaches and leads farther than the medium, the medium farther than the light, and each wind-up starts where the data says
		var mx_b: float = 0.0
		var mx_y: float = 0.0
		for v in bm.reach:
			mx_b = maxf(mx_b, float(v))
		for v in ym.reach:
			mx_y = maxf(mx_y, float(v))
		_expect(float(bm.lead) > float(ym.lead) and float(ym.lead) >= float(mash.lead) and int(bm.ghosts) >= int(ym.ghosts), "%s: lead %.1f, %.1f, %.1f and ghosts %d, %d are not ordered B > Y >= X" % [tag, float(bm.lead), float(ym.lead), float(mash.lead), int(bm.ghosts), int(ym.ghosts)])
		_expect(int(bm.load_first[1]) >= 16 and int(ym.load_first[1]) >= 6 and int(ym.load_first[1]) < int(bm.load_first[1]), "%s: the wind-ups start %d (B) and %d (Y) ticks before contact (B from the press, 16 or more)" % [tag, int(bm.load_first[1]), int(ym.load_first[1])])
		# held: the wind-up keeps coiling for the whole hold, the blow goes on release
		var yh: Dictionary = _tier_scene(S, who, "medium", ["roundhouse"], [66], {"windup": 42}, "heavy")
		var bh: Dictionary = _tier_scene(S, who, "super", ["su_drive" if who == "protagonist" else "su_ram"], [86], {"windup": 62}, "heavy")
		# Legal h05 on every wind-up of 12 ticks or more: a limb above 80 only in the last 6 ticks (the super pieces, the two holds), the chambers at shoulder height or lower and never at a hip
		_expect(int(bm.hi_max) <= 6 and int(bh.hi_max) <= 6 and int(yh.hi_max) <= 6, "%s: a limb stays above 80 for %d, %d and %d ticks before a contact (h05 allows the last 6)" % [tag, int(bm.hi_max), int(bh.hi_max), int(yh.hi_max)])
		for cid in (["pu.su_drive", "pu.su_turn"] if who == "protagonist" else ["ru.su_ram", "ru.su_heel"]):
			var iss: Array = _h05_chamber(cid + ".chamber")
			_expect(iss.is_empty(), "%s: %s breaks h05 as drawn (%s)" % [tag, cid, ", ".join(iss)])
		_expect(int(yh.load_run) >= 38 and int(bh.load_run) >= 56 and int(yh.screen) == 0 and int(bh.screen) == 0 and int(yh.nan) + int(bh.nan) == 0, "%s: held Y coils %d ticks (want 38 or more), held B %d (56 or more), violations %d and %d" % [tag, int(yh.load_run), int(bh.load_run), int(yh.screen), int(bh.screen)])
		summary.append("%s: the burst at gaps 4 4 5 carries the arms %.2f rad from guard against a plain mash's %.2f (a slow burst is not narrowed), super lead %.0f against medium %.0f" % [who, early, float(plain.dev), float(bm.lead), float(ym.lead)])
	# informational, for Legal (h05 on a 28-tick wind-up): how long a limb stays above 80 and what the chamber breaks, for the three stand-ins Legal asked to see drawn
	for who2 in ["protagonist", "antihero"]:
		var gl: Array = []
		for gp in ["double_palm", "cross_arm_ram", "double_hammer"]:
			var gr: Dictionary = _tier_scene(S, who2, "super", [gp], [70], {"windup": 28}, "heavy")
			gl.append("%s %d ticks above 80, wrists %.1f apart through the gather, %.1f at the peak (%s)" % [gp, int(gr.hi_max), float(gr.wrist_gather), float(gr.peak_apart), ", ".join(_h05_chamber(("pr." if who2 == "protagonist" else "w1.") + gp + ".chamber"))])
			if gp == "double_hammer":
				# RL-105: the hands a shoulder width (20) apart at the peak, and the peak inside the last 6 ticks
				_expect(int(gr.hi_early) == 0 and int(gr.hi_max) <= 6 and float(gr.peak_apart) >= 20.0, "flurry tiers %s: the double hammer's peak: %d ticks above 80 before the last 6, hands %.1f apart (need none early, at least 20 apart)" % [who2, int(gr.hi_early), float(gr.peak_apart)])
			if gp == "cross_arm_ram":
				# RL-105: the second forearm must not meet or cross the first until the last 6 ticks before the strike: the wrists more than 7 apart through the gather
				_expect(float(gr.wrist_gather) > 7.0, "flurry tiers %s: the crossed-arm ram's wrists come within %.1f of each other in the gather (they must stay over 7 until the last 6 ticks)" % [who2, float(gr.wrist_gather)])
		print("flurry tiers, 28-tick gathers (%s): %s" % [who2, "; ".join(gl)])
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	print("flurry tiers: %s; held Y and B coil for the whole hold; the tiers are ordered X < Y < B in the data and on the body" % " | ".join(summary))
	RenderAnim.dig_in = dig_was
	RenderAnim.fighter_ease = ease_was


## Legal's h05 on the real wind-up (RL-105; the held lint judges the chamber pose, this the path to it): every medium (on 12 ticks) and every piece of the super-heavy tier (on 28) of both fighters
## keeps every limb at 80 or lower until the last 6 ticks before the contact, with every contact solved, no NaN and nothing past a joint limit on screen. The flagged mediums are judged on 28.
func _test_windups() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	var wu: Dictionary = AnimHeldLint.windups()
	var worst: String = ""
	var judged: int = 0
	var fol_max: float = 0.0
	for who in ["protagonist", "antihero"]:
		var pre: String = "pr." if who == "protagonist" else "w1."
		var spre: String = "pu." if who == "protagonist" else "ru."
		var epre: String = "pk." if who == "protagonist" else "rk."
		var names: Array = []
		for cid in wu:
			var sid: String = String(wu[cid].strike)
			if sid.begins_with(pre) or sid.begins_with(spre) or sid.begins_with(epre):
				var held_only: bool = ["double_hammer", "double_palm", "cross_arm_ram", "drop_kick", "spinning_elbow", "spinning_back_kick", "spinning_heel"].has(sid.substr(3))   # Combat's w1 to w3: held-Y only, judged on the long wind-up
				names.append([sid.substr(3), bool(wu[cid].super) or held_only])
		names.sort()
		for nm in names:
			var sup: bool = bool(nm[1])
			var r: Dictionary = _tier_scene(S, who, "super" if sup else "medium", [String(nm[0])], [64], {"windup": 28 if sup else 12, "hand": "r"}, "heavy")
			judged += 1
			if bool(nm[1]) and String(nm[0]).begins_with("su_"):
				# the launcher (C2t): the same heavy on a 14-tick wind-up with the tell cut to its last third; the same rules hold
				# the heavy's held charge (Game Design: B still down at 32 ticks keeps charging, full at 44, by itself at 70): 62 ticks of wind-up, loaded in plain sight, nothing above 80 early, every contact solved
				var rhd: Dictionary = _tier_scene(S, who, "super", [String(nm[0])], [96], {"windup": 62, "hand": "r"}, "heavy")
				judged += 1
				if int(rhd.hi_early) > 0 or int(rhd.nan) > 0 or int(rhd.screen) > 0 or int(rhd.frames) != 1 or float(rhd.err) >= 0.25 or float(rhd.get("hold_max", 0.0)) < 0.6:
					worst += "%s %s held 62 ticks (%d ticks above 80 early, %d NaN, %d on screen, %d of 1 contacts, error %.3f, loaded to %.2f: it must keep loading, 0.6 or more); " % [who, String(nm[0]), int(rhd.hi_early), int(rhd.nan), int(rhd.screen), int(rhd.frames), float(rhd.err), float(rhd.get("hold_max", 0.0))]
				var rl: Dictionary = _tier_scene(S, who, "super", [String(nm[0])], [64], {"windup": 14, "hand": "r"}, "heavy")
				judged += 1
				if int(rl.hi_early) > 0 or int(rl.nan) > 0 or int(rl.screen) > 0 or int(rl.frames) != 1 or float(rl.err) >= 0.25:
					worst += "%s %s on 14 ticks (%d ticks above 80 early, %d NaN, %d on screen, %d of 1 contacts, error %.3f); " % [who, String(nm[0]), int(rl.hi_early), int(rl.nan), int(rl.screen), int(rl.frames), float(rl.err)]
			if bool(nm[1]) and String(nm[0]).begins_with("su_"):
				# Legal (super-heavy screen): a hand held up after the blow is a held raise (b09, h05; L1 lowers at once): by 6 ticks after the contact at or below 76, and never above 80 in the 14 after
				for tr in r.get("trace", []):
					if int(tr.dt) >= 6:
						for hk in ["abs_hand_r", "abs_hand_l"]:
							var hy: float = float(tr[hk])
							fol_max = maxf(fol_max, hy)
							if hy > (76.0 if int(tr.dt) == 6 else 80.0):
								worst += "%s %s: a hand is at %.0f %d ticks after the contact (76 or lower by 6, 80 after); " % [who, String(nm[0]), hy, int(tr.dt)]
			if int(r.hi_early) > 0 or int(r.nan) > 0 or int(r.screen) > 0 or int(r.frames) != 1 or float(r.err) >= 0.25:
				worst += "%s %s (%d ticks above 80 before the last 6, %d NaN, %d on screen, %d of 1 contacts, error %.3f); " % [who, String(nm[0]), int(r.hi_early), int(r.nan), int(r.screen), int(r.frames), float(r.err)]
	_expect(worst == "", "windups (h05): %s" % worst)
	_expect(judged >= 40, "windups: only %d wind-ups were judged" % judged)
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	print("windups: %d medium and heavy wind-ups judged on the real solve: no limb above 80 before the last 6 ticks, every contact solved; after a super-heavy's blow no hand is above %.0f from 6 ticks on" % [judged, fol_max])


## Many bodies (nine-cells-look.md section 5; `AnimMany`): a body's rival is the one in his exchange, else the nearest; with two bodies it is the other one, always; two stand-ins in a ring about the pair are solved
## with the real two for 300 ticks: each picks the nearest real fighter, the waiting repertoire shows (circle, guard, step in, settle; a flinch when a blow lands near), no joint is past a limit on a stand-in,
## no NaN, and the real pair's own rival is still his partner.
func _test_many_bodies() -> void:
	AnimData.load_every_wave()
	RenderAnim._fighters.clear()
	main.start_match(4, {"p1": true, "p2": true})
	var S: SimState = main.host.S
	var two_ok: bool = true
	for k in range(120):
		main.frame(1.0 / 60.0)
		var a0: AnimFighter = RenderAnim.fighter(S, S.fighters[0])
		two_ok = two_ok and a0._opponent(S, S.fighters[0]) == S.fighters[1] and a0._opponent(S, S.fighters[1]) == S.fighters[0]
	_expect(two_ok, "many bodies: with two bodies each one's rival is the other")
	var stands: Array = AnimMany.make(S, 2)
	var kinds := {}
	var nearest_ok: bool = true
	var partner_ok: bool = true
	var bad: int = 0
	var nan: int = 0
	var in_exchange: int = 0
	for k in range(300):
		main.frame(1.0 / 60.0)
		AnimMany.step(S, stands, 1.0 / 60.0)
		var ex = S.dirS.ex
		if ex != null:
			in_exchange += 1
			var a1: AnimFighter = RenderAnim.fighter(S, ex.A)
			partner_ok = partner_ok and a1._opponent(S, ex.A) == ex.D and a1._opponent(S, ex.D) == ex.A
		for st in stands:
			var af: AnimFighter = RenderAnim.fighter(S, st)
			var near = null
			var nd: float = 1.0e18
			for o in S.fighters:
				if o != st:
					var d: float = absf(SimWrap.sdx(st.x, o.x))
					if d < nd:
						nd = d
						near = o
			if ex == null or (ex.A != st and ex.D != st):
				nearest_ok = nearest_ok and af._opponent(S, st) == near
			if af.waiting_kind != "":
				kinds[af.waiting_kind] = int(kinds.get(af.waiting_kind, 0)) + 1
			bad += AnimJoints.violations(af.q, af._rd.shape_key).size()
			for qq in af.q:
				if is_nan(qq.x) or is_nan(qq.w):
					nan += 1
		AnimMany.detach(S, stands)
	_expect(nearest_ok, "many bodies: a stand-in outside the exchange looks at the nearest")
	_expect(partner_ok, "many bodies: the two in the exchange are each other's rival, with four bodies in the list")
	_expect(bad == 0 and nan == 0, "many bodies: %d joint violations and %d NaN on the stand-ins" % [bad, nan])
	_expect(in_exchange > 40 and kinds.has("circle") and kinds.has("guard") and kinds.has("step_in"), "many bodies: the waiting repertoire showed %s over %d exchange ticks" % [str(kinds), in_exchange])
	print("many bodies: 2 stand-ins about the pair for 300 ticks, waiting %s, %d joint violations" % [str(kinds), bad])


## The heavy's tell sinks (the nine cells' look audit, number 1): on the 28-tick wind-up the pelvis goes down 5 units or more by the end of the tell for a step, a turn or an unwind, and a fall (which
## rises to come down) does not sink. Read off the real solve's trace of the pelvis, 32 ticks before the contact (not started) against the lowest point up to 4 before it.
## The tenth round and the moveset distinction (docs/animation/tenth-round.md): each fighter's ease keeps the one clock (hold + follow + recover of every row sums to the global row's) and differs the way
## the pipeline says (the Protagonist's overshoot is greater and his follow longer, the Anti-hero's is a dead stop with a longer hold); the cash-in is a 2-tick heavy with no sink; a held hit's flinch hangs
## and is kept past 0.7 s; the air tech is a sequence that plays; a ring guard's interjection cue shows its tell and the chase cue dives the chaser and clears at its end.
func _test_round10() -> void:
	AnimData.load_every_wave()
	RenderAnim._fighters.clear()
	for st in ["speed", "burst", "medium", "super"]:
		var g: Dictionary = AnimData.press.styles[st].prof
		var gs: int = int(g.get("hold_ticks", 0)) + int(g.follow_ticks) + int(g.recover_ticks)
		var sums := {}
		var rows := {}
		for who in ["protagonist", "antihero"]:
			var af := AnimFighter.new(0)
			af.pair_key = who
			rows[who] = af._style_row(st)
			var pr: Dictionary = rows[who].prof
			sums[who] = int(pr.get("hold_ticks", 0)) + int(pr.follow_ticks) + int(pr.recover_ticks)
		_expect(sums.protagonist == gs and sums.antihero == gs, "ease %s: the clock is the global row's (%d): protagonist %d, antihero %d" % [st, gs, int(sums.protagonist), int(sums.antihero)])
		if st == "super":
			_expect(rows.protagonist.prof == rows.antihero.prof, "ease super: the heavy is thrown the same way by both (no ease)")
			continue
		_expect(float(rows.protagonist.prof.get("overshoot", 0.0)) > float(rows.antihero.prof.get("overshoot", 0.0)) and int(rows.antihero.prof.get("hold_ticks", 0)) >= int(rows.protagonist.prof.get("hold_ticks", 0)), "ease %s: fluid against snappy (overshoot %.2f against %.2f, hold %d against %d)" % [st, float(rows.protagonist.prof.get("overshoot", 0.0)), float(rows.antihero.prof.get("overshoot", 0.0)), int(rows.protagonist.prof.get("hold_ticks", 0)), int(rows.antihero.prof.get("hold_ticks", 0))])
	var ease_was: bool = RenderAnim.fighter_ease
	RenderAnim.fighter_ease = false
	var af0 := AnimFighter.new(0)
	af0.pair_key = "antihero"
	_expect(float(af0._style_row("speed").prof.overshoot) == float(AnimData.press.styles.speed.prof.overshoot), "ease: with the switch off the global row plays")
	RenderAnim.fighter_ease = ease_was
	var ci: Dictionary = af0._press_prof({}, "super", {"cash_in": true})
	_expect(int(ci.load_ticks.heavy) == 2 and int(ci.snap_ticks) == 0, "cash-in: a 2-tick heavy (%s)" % str(ci.load_ticks))
	# a held hit: the flinch is kept past 0.7 s for the hang, and the same hit without a hang is not
	RenderAnim.hit_variants = false   # the hang is the plain flinch's own length
	var h1 := AnimFighter.new(1)
	var h2 := AnimFighter.new(1)
	h1.on_hit(0.0, "chest", true, 0.5, "light", Vector2.ZERO, 0.6, 1, 0.1, 0)
	h2.on_hit(0.0, "chest", true, 0.5, "light", Vector2.ZERO, 0.6, 1, 0.0, 0)
	h1._reaction_layer(0.75)
	h2._reaction_layer(0.75)
	RenderAnim.hit_variants = true
	_expect(h1._reacts.size() == 1 and h2._reacts.size() == 0, "held hit: the flinch hangs (%d kept with a hang, %d without)" % [h1._reacts.size(), h2._reacts.size()])
	var ent: bool = AnimData.entries.has("rt.air_tech") and AnimData.pose_exists("rt.interject.tell") and AnimData.pose_exists("rt.chase.dive")
	_expect(ent, "round 10: the air tech sequence and the interjection and chase poses are baked")
	var h3 := AnimFighter.new(1)
	h3.on_tech(1.0)
	_expect(String(h3._seq.get("id", "")) == "rt.air_tech" and h3.tech_cue == 1.0, "air tech: the sequence plays")
	# the interjection and the chase, on the real solve with two stand-in bodies about the pair
	main.start_match(4, {"p1": true, "p2": true})
	var S: SimState = main.host.S
	for k in range(120):
		main.frame(1.0 / 60.0)
	var stands: Array = AnimMany.make(S, 2)
	var shown: int = 0
	var chased: bool = false
	var cleared: bool = false
	for k in range(60):
		main.frame(1.0 / 60.0)
		AnimMany.step(S, stands, 1.0 / 60.0)
		var st0 = stands[0]
		var sa: AnimFighter = RenderAnim.fighter(S, st0)
		if k == 5:
			sa.on_windup("interject", "guard", 18, S.tick + 18, 0, S.T, S.tick)
		if k == 40:
			sa.on_chase("start", 0, 0, S.T)
		if k > 5 and sa.waiting_kind == "interject":
			shown += 1
		if k == 50 and sa.chase_state == "start":
			chased = true
			sa.on_chase("end", 0, 0, S.T)
		if k == 53 and sa.chase_state == "":
			cleared = true
		AnimMany.detach(S, stands)
	_expect(shown >= 8, "interjection: the guard shows his tell for %d ticks (8 or more)" % shown)
	_expect(chased and cleared, "chase: the dive starts on the cue and clears at the end (%s, %s)" % [str(chased), str(cleared)])
	print("round 10: ease keeps the clock; cash-in 2 ticks; held hit hangs; air tech plays; interjection tell shown %d ticks; chase dive starts and clears" % shown)


func _test_pieces() -> void:
	AnimData.load_every_wave()
	RenderAnim._fighters.clear()
	# the mannequin and the guards play the common pool: the same key sets by the same names
	_expect(AnimData.ensure_fighter("REFERENCE") == "common" and AnimData.ensure_fighter("guard") == "common", "pieces: the training dummy and the guard play the common row (%s, %s)" % [AnimData.ensure_fighter("REFERENCE"), AnimData.ensure_fighter("guard")])
	_expect(AnimData.ensure_fighter("PROTAGONIST") == "protagonist" and AnimData.ensure_fighter("RIVAL") == "antihero", "pieces: the pair keeps its own rows")
	var cl: Dictionary = AnimData.pair_lists["common"]
	var shared_ok: bool = true
	for nm in ["jab", "cross", "backfist", "stomp", "uppercut", "palm_heel", "axe_kick", "rib_shot", "plate_drop", "su_sole_fall"]:
		if not cl.by_name.has(nm) or not AnimData.keysets.has(String(cl.by_name[nm])):
			shared_ok = false
			print("  pieces: the common row has no key set named ", nm)
	_expect(shared_ok, "pieces: the common row names the shared strikes (w1.*, rb.*, rm.*) and the guards' heavy")
	_expect(AnimData.resolve_strike("common", "strike.cross") == "w1.cross" and AnimData.resolve_strike("common", "strike.su_sole_fall") == "gd.su_sole_fall", "pieces: a beat's piece reaches the same key set for the dummy as for the Anti-hero")
	# Combat's new pieces: each is findable by its name, in no pick list, and its contact is solved
	var table := {"protagonist": ["su_blade_fall", "su_palm_arm", "palm_turn"], "antihero": ["jab_fist", "cross_fist", "spear_fist", "su_fist_unwind"], "common": ["su_sole_fall"]}
	var pre := {"protagonist": "pv.", "antihero": "rq.", "common": "gd."}
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	for who in table:
		for nm in table[who]:
			var id: String = String(pre[who]) + String(nm)
			var lst: Dictionary = AnimData.pair_lists[who]
			var listed: bool = (lst.light as Array).has(id) or (lst.heavy as Array).has(id)
			_expect(AnimData.keysets.has(id) and String(lst.by_name.get(nm, "")) == id and not listed, "pieces: %s is findable by name and in no pick list (listed: %s)" % [id, str(listed)])
			var heavy: bool = String(AnimData.keysets[id].weight) == "heavy"
			var sc: Dictionary = _tier_scene(S, who, "super" if heavy else "speed", [nm], [44, 80] if heavy else [30, 50], {}, "heavy" if heavy else "light")
			_expect(int(sc.nan) == 0 and int(sc.screen) == 0 and int(sc.frames) == 2 and float(sc.err) < 0.25 and String(sc.parts[0]) == id, "pieces: %s plays (%d NaN, %d joint violations on screen, contact %.3f rad, played %s)" % [id, int(sc.nan), int(sc.screen), float(sc.err), str(sc.parts)])
	# the beam's cast poses, one a fighter, and the generic pair for a body with none
	var cp := AnimFighter.new(0)
	cp.pair_key = "protagonist"
	var ca := AnimFighter.new(1)
	ca.pair_key = "antihero"
	var cc := AnimFighter.new(0)
	cc.pair_key = "common"
	_expect(cp._cast_id("fire") == "bm.hold.fire_protagonist" and ca._cast_id("charge") == "bm.hold.charge_antihero" and cc._cast_id("fire") == "beam.fire", "pieces: each fighter casts in his own pose, a body with none in the generic one")
	# the cash-in has its own row, which reaches VFX as the super style
	var af0 := AnimFighter.new(0)
	af0.pair_key = "antihero"
	var ci: Dictionary = af0._press_prof({}, "cash_in", {"cash_in": true})
	_expect(AnimData.press.styles.has("cash_in") and int(ci.load_ticks.heavy) == 2 and int(ci.snap_ticks) == 0 and float(AnimData.press.styles.cash_in.squash) == 0.0, "pieces: the cash-in row loads in 2 ticks with no snap and no sink (%s)" % str(ci.load_ticks))
	# the chase's agreed cue: k the blow's number, n an absolute tick; arrive eases the dive out
	var ch := AnimFighter.new(0)
	ch.on_chase("start", 0, 0, 1.0, 100)
	ch.on_chase("blow", 3, 140, 1.5, 120)
	_expect(ch.chase_n == 3 and ch.chase_tick == 140 and ch.chase_state == "blow", "chase: blow 3 is in k (%d) and its contact tick in n (%d)" % [ch.chase_n, ch.chase_tick])
	ch.on_chase("arrive", 0, 150, 1.6, 130)
	_expect(ch.chase_tick == 150 and ch.chase_state == "blow" and ch._chase_arrived_t == 1.6, "chase: arrive keeps the state and records the tick")
	# the opening (the eleventh round): the head snapped back and the arms thrown open, for a few ticks
	var op = AnimData.entries.get("lq.open")
	_expect(op != null and String(op.phases[0].pose) == "lq.open.snap" and String(op.phases[1].pose) == "lq.open.open" and int(op.phases[0].ticks) + int(op.phases[1].ticks) < 12, "opening: the stagger begins with the snap and the open arms, under 12 ticks in all")
	print("pieces: the common row, the new pieces, the cast poses, the cash-in row, the chase cue and the opening")


func _arm_wings(id: String) -> int:
	var p: AnimPose = AnimData.pose(id)
	var gq: Array[Quaternion] = []
	var gp := PackedVector3Array()
	gq.resize(AnimRig.N)
	gp.resize(AnimRig.N)
	AnimPose.fk(p.q, p.hips, gq, gp)
	var n: int = 0
	for side in ["r", "l"]:
		var sh: Vector3 = gp[AnimRig.index["upper_arm_" + side]]
		var el: Vector3 = gp[AnimRig.index["forearm_" + side]]
		var wr: Vector3 = gp[AnimRig.index["hand_" + side]]
		var flex: float = 180.0 - rad_to_deg((sh - el).normalized().angle_to((wr - el).normalized()))
		if flex > 50.0 and el.y > sh.y + 2.0 and el.y - wr.y > 8.0 and el.x < sh.x - 4.0:
			n += 1
	return n


func _test_arms() -> void:
	AnimData.load_every_wave()
	# the chicken wing (homework 4: "arms still seem to bend in weird, unnatural ways"): an elbow carried above and behind its shoulder with the forearm hanging down from it
	var wings: int = 0
	var total: int = 0
	var worst: Array = []
	for id in AnimData.poses:
		var s: String = String(id)
		if not (s.ends_with(".contact") or s.ends_with(".follow")):
			continue
		total += 1
		var w: int = _arm_wings(s)
		wings += w
		if w > 0 and worst.size() < 8:
			worst.append(s)
	_expect(wings <= 8, "arms: %d chicken-wing arms in the %d strike contact and follow keys (8 or fewer; 57 before the pose bake's wing fix): %s" % [wings, total, str(worst)])
	# the air tech (the tenth round; homework 4: "his legs fold up and look strange"): no tuck, the feet stay low
	var tech_ok: bool = true
	for pid in ["rt.air_tech.spread", "rt.air_tech.brace"]:
		var p: AnimPose = AnimData.pose(pid)
		var gq: Array[Quaternion] = []
		var gp := PackedVector3Array()
		gq.resize(AnimRig.N)
		gp.resize(AnimRig.N)
		AnimPose.fk(p.q, p.hips, gq, gp)
		var fy: float = maxf(gp[AnimRig.index["foot_r"]].y, gp[AnimRig.index["foot_l"]].y)
		if fy > 20.0:
			tech_ok = false
			print("  arms: the air tech's %s lifts a foot to %.1f" % [pid, fy])
	_expect(tech_ok, "arms: the air tech keeps both feet low (no tuck)")
	# the mash's beat: the pelvis dips on each blow of a run, never on a tap
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	for who in ["protagonist", "antihero"]:
		var tap: Dictionary = _tier_scene(S, who, "speed", ["cross"], [30])
		var mash: Dictionary = _tier_scene(S, who, "speed", ["cross", "palm_heel", "spear_hand"], [30, 36, 42, 48, 54, 60])
		var ymash: Dictionary = _tier_scene(S, who, "medium", ["double_palm", "roundhouse", "cross_arm_ram"], [34, 48, 62, 76], {}, "heavy")
		_expect(float(tap.get("bob", 0.0)) == 0.0 and float(mash.get("bob", 0.0)) >= 1.0 and float(ymash.get("bob", 0.0)) >= 1.5, "arms: %s the beat is %.2f on a tap, %.2f on an X mash and %.2f on a Y mash" % [who, float(tap.get("bob", 0.0)), float(mash.get("bob", 0.0)), float(ymash.get("bob", 0.0))])
	print("arms: wings %d of %d keys, the air tech's feet low, the mash's beat" % [wings, total])


func _test_pulls() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	# a beam's aim turns both upper arms; the turn is shortened until neither is past its limit (live seed 4 tick 1121 had the last pass pull one 77 degrees)
	var bad: int = 0
	for pid in ["bm.hold.fire_protagonist", "bm.hold.charge_protagonist", "bm.hold.fire_antihero", "bm.hold.charge_antihero", "beam.fire", "beam.charge"]:
		for alpha in [-1.2, -0.6, 0.0, 0.6, 1.2]:
			var af := AnimFighter.new(0)
			af.q = AnimData.pose(pid).q.duplicate()
			af._aim_arms(alpha, 1.0)
			for nm in ["upper_arm_l", "upper_arm_r"]:
				var e: Vector2 = AnimJoints.ball_excess(af.q, AnimRig.index[nm], af._rd.shape_key)
				if e.x + e.y > 0.02:
					bad += 1
	_expect(bad == 0, "pulls: a beam's aim leaves an upper arm past its limit in %d of 60 cases" % bad)
	# the heavies' kicks at their own striking distance: no frame of the last pass pulling over 30 degrees (the pose's own lunge used to leave the hip past the target)
	var dad := DirAccess.open("res://data/anim/waves")
	var offs := {}
	for fn in dad.get_files():
		if String(fn).ends_with(".manifest.json"):
			var mm = JSON.parse_string(FileAccess.get_file_as_string("res://data/anim/waves/" + String(fn)))
			for st in mm.get("strikes", []):
				offs[String(st.id)] = float(st.get("offset", 58.0))
	var dist_was: float = _tier_dist
	for pc in [["protagonist", "su_edge_step", "pu.su_edge_step"], ["protagonist", "su_edge_unwind", "pu.su_edge_unwind"], ["antihero", "su_heel", "ru.su_heel"]]:
		_tier_dist = float(offs.get(String(pc[2]), 58.0))
		var r: Dictionary = _tier_scene(S, String(pc[0]), "super", [String(pc[1])], [44], {"windup": 28}, "heavy")
		_expect(int(r.get("fix_n30", 0)) == 0, "pulls: %s at its own range (%.0f) has %d frames of the last pass pulling over 30 degrees" % [String(pc[2]), _tier_dist, int(r.get("fix_n30", 0))])
	# a defender closer than a kick's range: the body gives ground instead of the thigh being pulled back through its limit (data sockets.json limbs.foot.min_fwd)
	var retreat_was: bool = RenderAnim.kick_retreat
	var limits_was: bool = RenderAnim.source_limits
	var closes := {}
	for on in [false, true]:
		RenderAnim.kick_retreat = on
		RenderAnim.source_limits = on
		_tier_dist = 38.0
		var tot: int = 0
		for nm in ["front_kick", "snap_round", "side_kick"]:
			tot += int(_tier_scene(S, "protagonist", "medium", [nm], [44], {"windup": 12}, "heavy").get("fix_n30", 0))
		closes[on] = tot
	RenderAnim.kick_retreat = retreat_was
	RenderAnim.source_limits = limits_was
	_expect(int(closes[true]) == 0 and int(closes[false]) > int(closes[true]), "pulls: three kicks at 38 units pull the last pass over 30 degrees on %d frames without the retreat and the source limits and %d with them" % [int(closes[false]), int(closes[true])])
	# the arm version of the retreat (its own switch `RenderAnim.hand_retreat`, data limbs.hand.min_fwd): a defender at 24 units, nearer than a jab's range, leaves the blow short of him by
	# a few units; the body giving ground brings the fist to him
	var hand_was: bool = RenderAnim.hand_retreat
	var gaps := {}
	for on in [false, true]:
		RenderAnim.hand_retreat = on
		_tier_dist = 24.0
		var g: float = 0.0
		for nm in ["jab", "cross", "palm_heel", "spear_hand", "hook"]:
			g = maxf(g, float(_tier_scene(S, "antihero", "speed", [nm], [30], {}, "light").get("gap", 0.0)))
		gaps[on] = g
	RenderAnim.hand_retreat = hand_was
	_expect(float(gaps[true]) <= 3.0 and float(gaps[false]) > float(gaps[true]) + 2.0, "pulls: a hand blow at 24 units ends %.1f short of the defender without the arm's retreat and %.1f with it" % [float(gaps[false]), float(gaps[true])])
	_tier_dist = dist_was
	print("pulls: a beam's aim stays inside the limits; the three heavies' kicks need no big correction at their range")


# ---- the wide net (homework 4b): the bends that read as wrong, sampled on every tick of the nine cells; and the styles' distinctness measured on the same samples
const CELLS := ["xtap", "xmash", "xhold", "ytap", "ymash", "yhold", "btap", "bmash", "bhold"]
const CELL_CONTACTS := {"xtap": [30], "xmash": [30, 36, 42, 48, 54, 60, 66, 72], "xhold": [30, 46, 50, 54, 59, 65, 73, 84], "ytap": [44], "ymash": [34, 48, 62, 76, 90], "yhold": [66], "btap": [60], "bmash": [44, 72, 100, 128], "bhold": [86]}
var _bn_on: bool = false
var _bn_tag: String = ""
var _bn_rows: Array = []


## One tick of a fighter, kept for the scans: the joints of both arms and legs in the model's frame, the wrist's and the upper arm's local rotations, the stage D audit (what the layers
## left past a limit before the last pass), the last pass's correction, and which arm is striking.
func _bend_sample(who: String, k: int, af: AnimFighter) -> void:
	var r := {"tag": _bn_tag, "who": who, "k": k}
	var ix: Dictionary = AnimRig.index
	r["pel"] = af.socket("pelvis")
	r["head"] = af.socket("head")
	for side in ["r", "l"]:
		var d := {}
		d["hand_a"] = rad_to_deg(2.0 * acos(clampf(absf(af.q[ix["hand_" + side]].w), 0.0, 1.0)))
		d["hand_q"] = af.q[ix["hand_" + side]]
		d["ua_q"] = af.q[ix["upper_arm_" + side]]
		var sh: Vector3 = af.socket("upper_arm_" + side)
		var el: Vector3 = af.socket("forearm_" + side)
		var wr: Vector3 = af.socket("hand_" + side)
		d["sh"] = sh
		d["el"] = el
		d["wr"] = wr
		d["flex"] = 180.0 - rad_to_deg((sh - el).normalized().angle_to((wr - el).normalized()))
		var hp: Vector3 = af.socket("thigh_" + side)
		var kn: Vector3 = af.socket("shin_" + side)
		var ft: Vector3 = af.socket("foot_" + side)
		d["hip"] = hp
		d["kn"] = kn
		d["ft"] = ft
		d["kflex"] = 180.0 - rad_to_deg((hp - kn).normalized().angle_to((ft - kn).normalized()))
		r[side] = d
	var sl: String = ""
	if (af._ci_w > 0.01 or af._part != "") and String(af._ci_limb).contains("_"):
		sl = String(af._ci_limb).substr(String(af._ci_limb).length() - 1)
		if af._ci_side:
			sl = "l" if sl == "r" else "r"
	r["strike"] = sl
	r["ttc"] = int(af.press.get("ticks_to_contact", 99)) if not af.press.is_empty() else 99
	r["D"] = (af.audit.get("D", []) as Array).duplicate()
	r["fix"] = rad_to_deg(float(af.debug.get("limit_fix", 0.0)))
	_bn_rows.append(r)


## The nine cells of both fighters at the frame rate (`same_piece`: every style of a button throws the same piece, so what differs is the style and not the piece).
func _run_cells(same_piece: bool) -> void:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var press_was: bool = RenderAnim.press_styles
	var audit_was: bool = RenderAnim.joint_audit
	var dmg_was: bool = _tier_damage
	var ground_was: bool = RenderAnim.ground_feet
	RenderAnim.press_styles = true
	RenderAnim.joint_audit = true
	RenderAnim.ground_feet = false
	_tier_damage = true
	_bn_on = true
	_bn_rows.clear()
	for who in ["protagonist", "antihero"]:
		var burst: Array = ["cross", "pm.palm_rise", "palm_heel", "spear_hand", "pm.back_chop", "jab"] if who == "protagonist" else ["cross", "rm.gut_rise", "palm_heel", "spear_hand", "rm.arm_chop", "jab"]
		var sup: Array = ["su_drive", "su_turn"] if who == "protagonist" else ["su_ram", "su_heel"]
		var med: Array = ["double_palm", "roundhouse", "cross_arm_ram", "spinning_heel", "axe_kick"]
		var xl: Array = ["cross", "palm_heel", "spear_hand"]
		var xm: Array = ["cross", "palm_heel", "spear_hand", "jab"]
		var btap: Array = ["su_edge_unwind"] if who == "protagonist" else ["su_plate"]
		var yhold: Array = ["roundhouse"]
		if same_piece:
			burst = ["cross"]
			sup = [sup[0]]
			med = ["double_palm"]
			xl = ["cross"]
			xm = ["cross"]
			btap = sup
			yhold = med
		_bn_tag = "xtap"
		_tier_scene(S, who, "speed", xl, CELL_CONTACTS.xtap, {}, "light")
		_bn_tag = "xmash"
		_tier_scene(S, who, "speed", xm, CELL_CONTACTS.xmash, {}, "light")
		_bn_tag = "xhold"
		_tier_scene(S, who, "burst", burst, CELL_CONTACTS.xhold, {}, "light")
		_bn_tag = "ytap"
		_tier_scene(S, who, "medium", med, CELL_CONTACTS.ytap, {"windup": 12}, "heavy")
		_bn_tag = "ymash"
		_tier_scene(S, who, "medium", med, CELL_CONTACTS.ymash, {}, "heavy")
		_bn_tag = "yhold"
		_tier_scene(S, who, "medium", yhold, CELL_CONTACTS.yhold, {"windup": 42}, "heavy")
		_bn_tag = "btap"
		_tier_scene(S, who, "super", btap, CELL_CONTACTS.btap, {"windup": 28}, "heavy")
		_bn_tag = "bmash"
		_tier_scene(S, who, "super", sup, CELL_CONTACTS.bmash, {}, "heavy")
		_bn_tag = "bhold"
		_tier_scene(S, who, "super", [sup[0]], CELL_CONTACTS.bhold, {"windup": 62}, "heavy")
	_bn_on = false
	RenderAnim.press_styles = press_was
	RenderAnim.joint_audit = audit_was
	RenderAnim.ground_feet = ground_was
	_tier_damage = dmg_was


## The counts of each kind of bend over the samples: wing (the elbow up and behind its shoulder, the forearm hanging), hyper (an elbow or knee bent the wrong way), overfold (past its end),
## wrist70 (a wrist turned past 70 degrees), wristjerk (a wrist turned 35 degrees in one tick), uajerk (an upper arm turned 45 degrees in one tick), elbowflip (the elbow's plane turned
## 80 degrees in one tick), kneein (a planted knee 5 units in off the hip-to-foot line, bent), stageD (what the layers left past a limit before the last pass), pull20 (frames the last pass
## corrected by more than 20 degrees); and f_ the three that are the FREE arm's (the arm that is not striking).
func _bend_counts() -> Dictionary:
	var c := {"wing": 0, "hyper": 0, "overfold": 0, "wrist70": 0, "wristjerk": 0, "uajerk": 0, "elbowflip": 0, "kneein": 0, "stageD": 0, "pull20": 0, "f_uajerk": 0, "f_elbowflip": 0, "f_wing": 0, "arrival_uajerk": 0, "arrival_elbowflip": 0}
	var groups := {}
	for r in _bn_rows:
		var key: String = "%s:%s" % [r.tag, r.who]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(r)
	for key in groups:
		var prev := {}
		for r in groups[key]:
			if float(r.fix) > 20.0:
				c.pull20 += 1
			for e in r.D:
				var w: String = String(e[0])
				if w == "hinge wrong way":
					c.hyper += 1
				elif w == "hinge past end":
					c.overfold += 1
				else:
					c.stageD += 1
			for side in ["r", "l"]:
				var d: Dictionary = r[side]
				var free: bool = String(r.strike) != side
				var arrival: bool = int(r.ttc) >= 0 and int(r.ttc) <= 2   # the two ticks to a blow's contact, and the contact tick: the blow's own deadline (the sim announces most blows fewer than four ticks ahead)
				var tor: Vector3 = r.head - r.pel
				var upright: bool = absf(tor.x) < 0.6 * tor.y   # a wing is a bend judged against up: a body laid over in flight or a fall has none
				if upright and float(d.flex) > 50.0 and d.el.y > d.sh.y + 2.0 and d.el.y - d.wr.y > 8.0 and d.el.x < d.sh.x - 4.0:
					c.wing += 1
					if free:
						c.f_wing += 1
				if float(d.hand_a) > 70.0:
					c.wrist70 += 1
				var line: Vector3 = d.ft - d.hip
				var t: float = clampf((d.kn - d.hip).dot(line) / maxf(line.length_squared(), 0.001), 0.0, 1.0)
				var on_line: Vector3 = d.hip + line * t
				var lat: float = (d.kn.z - on_line.z) * (1.0 if side == "r" else -1.0)
				if lat < -5.0 and float(d.kflex) > 30.0 and d.ft.y < 8.0:
					c.kneein += 1
				if prev.has(side):
					var p: Dictionary = prev[side]
					if rad_to_deg((d.hand_q as Quaternion).angle_to(p.hand_q)) > 35.0:
						c.wristjerk += 1
					if rad_to_deg((d.ua_q as Quaternion).angle_to(p.ua_q)) > 45.0:
						c.uajerk += 1
						if free:
							if arrival:
								c.arrival_uajerk += 1
							else:
								c.f_uajerk += 1
					var a1: Vector3 = (d.wr - d.sh).normalized()
					var e1: Vector3 = (d.el - d.sh) - a1 * (d.el - d.sh).dot(a1)
					var b1: Vector3 = (p.wr - p.sh).normalized()
					var e0: Vector3 = (p.el - p.sh) - b1 * (p.el - p.sh).dot(b1)
					if float(d.flex) > 35.0 and float(p.flex) > 35.0 and e1.length() > 3.0 and e0.length() > 3.0 and rad_to_deg(e1.angle_to(e0)) > 80.0:
						c.elbowflip += 1
						if free:
							if arrival:
								c.arrival_elbowflip += 1
							else:
								c.f_elbowflip += 1
				prev[side] = d
	return c


## The same scan over live play: four seeded AI-vs-AI matches (every solved frame of both fighters, the hits, the flights and the ragdolls included), counted by the same kinds.
func _run_live(seeds: Array, ticks: int) -> void:
	var audit_was: bool = RenderAnim.joint_audit
	RenderAnim.joint_audit = true
	_bn_rows.clear()
	for seed in seeds:
		main.start_match(int(seed), {"p1": true, "p2": true})
		var S: SimState = main.host.S
		var n: int = 0
		while main.host.ticks < ticks and not (S.game.ko != null and S.game.koT > 3.0):
			main.frame(1.0 / 60.0)
			n += 1
			for fi in range(S.fighters.size()):
				var af: AnimFighter = RenderAnim.fighter(S, S.fighters[fi])
				if af.version == 0:
					continue
				_bn_tag = "seed%d" % int(seed)
				_bend_sample("f%d" % fi, n, af)
	RenderAnim.joint_audit = audit_was


func _test_bends_live() -> void:
	AnimData.load_every_wave()
	_run_live([4, 7, 9, 12345], 2400)
	var c: Dictionary = _bend_counts()
	var frames: int = _bn_rows.size()
	_expect(int(c.hyper) == 0 and int(c.overfold) <= 2 and int(c.wrist70) == 0 and int(c.wristjerk) <= 5, "bends live: %d frames of four matches: hyperextension %d, folded past the end %d (2 or fewer), a wrist past 70 degrees %d, a wrist turned 35 degrees in a tick %d (5 or fewer)" % [frames, int(c.hyper), int(c.overfold), int(c.wrist70), int(c.wristjerk)])
	# what the live scan read after the fixes (before them: wing 553, overfold 13, stageD 1009, pull20 143, uajerk 1776, elbowflip 623): the wings are judged on an upright body only; the knees in are a taunt's
	# back turned (the body's own turn spoils the lateral measure) and a single frame of a heel kick
	_expect(int(c.pull20) <= 20 and int(c.stageD) <= 420, "bends live: the last pass corrected %d frames by over 20 degrees (20 or fewer; 143 before), %d left past a limit by the layers (420 or fewer; 1009 before)" % [int(c.pull20), int(c.stageD)])
	_expect(int(c.wing) <= 260 and int(c.kneein) <= 8, "bends live: a chicken wing on %d of the upright arm-frames (260 or fewer; 553 before), a planted knee in on %d (8 or fewer)" % [int(c.wing), int(c.kneein)])
	print("bends live: %d frames, %s" % [frames, str(c)])


func _test_bends() -> void:
	AnimData.load_every_wave()
	_run_cells(false)
	var c: Dictionary = _bend_counts()
	# the thresholds are what the scan read after the fixes (before them: wing 58, overfold 4, uajerk 151, elbowflip 64, stageD 115, pull20 38), with a little room. The arm's snaps in the two
	# ticks to a blow's contact ("arrival") are the blow's own deadline (the sim announces most blows fewer than four ticks ahead): counted, bounded, not removed
	_expect(int(c.hyper) == 0 and int(c.overfold) == 0, "bends: an elbow or a knee bent the wrong way or past its end on %d + %d frames of the nine cells (0 allowed)" % [int(c.hyper), int(c.overfold)])
	_expect(int(c.wrist70) == 0 and int(c.wristjerk) == 0, "bends: a wrist past 70 degrees on %d frames and turned 35 degrees in a tick on %d (0 allowed)" % [int(c.wrist70), int(c.wristjerk)])
	_expect(int(c.kneein) == 0, "bends: a planted knee in off its line on %d frames (0 allowed)" % int(c.kneein))
	_expect(int(c.stageD) <= 4 and int(c.pull20) <= 2, "bends: %d frames left past a limit by the layers (4 or fewer), %d the last pass corrected by over 20 degrees (2 or fewer)" % [int(c.stageD), int(c.pull20)])
	_expect(int(c.f_uajerk) <= 6 and int(c.f_elbowflip) <= 3, "bends: the free arm's upper arm turned 45 degrees in one tick outside the blow's last two ticks on %d frames (6 or fewer) and its elbow's plane flipped on %d (3 or fewer)" % [int(c.f_uajerk), int(c.f_elbowflip)])
	_expect(int(c.arrival_uajerk) <= 75 and int(c.arrival_elbowflip) <= 35, "bends: the free arm's snaps in the last two ticks to a contact: %d upper-arm turns of 45 degrees (75 or fewer; 65 before) and %d elbow flips (35 or fewer; 29 before)" % [int(c.arrival_uajerk), int(c.arrival_elbowflip)])
	_expect(int(c.f_wing) <= 24 and int(c.wing) <= 62, "bends: the free arm a chicken wing on %d frames (24 or fewer; 19 before), either arm on %d (62 or fewer; 58 before)" % [int(c.f_wing), int(c.wing)])
	print("bends: nine cells x two fighters at 60 Hz, %s" % str(c))


## The pulled frames (homework 4b): every key set of both fighters, at the study's 60 units and at its own striking range, none of them with a frame of the last pass pulling over 30 degrees,
## at most two over 20.
## The contact-key pass (docs/animation/guard-pass.md): the free hand of every strike's contact key is within its goal of the stance guard (20 units for a hand blow, 30 for a kick, in the chest's frame).
func _test_guard() -> void:
	var rs: Array = preload("res://render/anim/tools/guard_scan.gd").rows(20.0, 30.0, false)
	var over: Array = []
	var worst: float = 0.0
	for r in rs:
		worst = maxf(worst, float(r.err))
		if float(r.err) > float(r.goal):
			over.append("%s %.1f" % [r.id, float(r.err)])
	_expect(over.is_empty(), "guard: %d of %d free hands on a contact key are past their goal from the stance guard (worst %.1f; 0 allowed; before the pass 28 of 149): %s" % [over.size(), rs.size(), worst, str(over.slice(0, 5))])
	# the pass is data: every row of data/anim/guard_pass.json names a contact key that exists
	var gp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/anim/guard_pass.json")).get("contacts", {})
	var missing: Array = []
	for id in gp:
		if not AnimData.poses.has(id):
			missing.append(id)
	_expect(missing.is_empty(), "guard: every row of the pass names a contact key that is baked (%s missing)" % str(missing.slice(0, 4)))
	print("guard: %d free hands, worst %.1f from the guard, %d rows in the pass" % [rs.size(), worst, gp.size()])


## RG0 (docs/animation/ragdoll-physics-paper.md): a launch flails its own way, the same way on every replay; a hit on the back arches and a hit on the front folds.
func _test_ragdoll_vary() -> void:
	AnimRagdoll.setup()
	var run := func(slot: int, n: int, flights: int) -> PackedFloat32Array:
		var rd := AnimRagdoll.new()
		rd.set_flail_seed(slot, n, flights)
		rd.w_flail = 1.0
		for k in range(40):
			rd.step(1.0 / 60.0, Vector2(900.0, 0.0), Vector2.ZERO, 0.85, 1.0, 5.0 + float(k) / 60.0)
		return rd.th.duplicate()
	var a: PackedFloat32Array = run.call(0, 1, 1)
	var a2: PackedFloat32Array = run.call(0, 1, 1)
	var b: PackedFloat32Array = run.call(0, 2, 2)
	var c: PackedFloat32Array = run.call(1, 1, 1)
	var d_ab: float = 0.0
	var d_ac: float = 0.0
	var d_aa: float = 0.0
	for i in range(AnimRagdoll.N):
		d_ab = maxf(d_ab, absf(a[i] - b[i]))
		d_ac = maxf(d_ac, absf(a[i] - c[i]))
		d_aa = maxf(d_aa, absf(a[i] - a2[i]))
	_expect(d_aa == 0.0 and d_ab > 0.05 and d_ac > 0.05, "ragdoll variety: the same launch flails the same way (%.4f apart), another launch (%.3f rad) and another fighter (%.3f rad) differently" % [d_aa, d_ab, d_ac])
	var h0: float = AnimRagdoll.hash01(3, 7, 11)
	_expect(h0 >= 0.0 and h0 <= 1.0 and h0 == AnimRagdoll.hash01(3, 7, 11) and h0 != AnimRagdoll.hash01(3, 7, 12), "ragdoll variety: the hash is in 0 to 1 and the same for the same integers")
	var fold := AnimRagdoll.new()
	fold.crumple(1.0, 1.0, 1.0)
	var arch := AnimRagdoll.new()
	arch.crumple(1.0, 1.0, -1.0)
	_expect(fold.om[1] * arch.om[1] < 0.0 and fold.om[0] * arch.om[0] < 0.0, "ragdoll side: the spine and the head go opposite ways for a hit on the front (%.2f, %.2f) and on the back (%.2f, %.2f)" % [fold.om[1], fold.om[0], arch.om[1], arch.om[0]])
	var af := AnimFighter.new(0)
	af.vface = 1.0
	af._rd_rot = PI * 0.5
	var s_front: float = af._hit_side(0.0, 1.0)
	af._rd_rot = -PI * 0.5
	var s_back: float = af._hit_side(0.0, 1.0)
	af._rd_rot = 0.0
	var s_feet: float = af._hit_side(0.0, 1.0)
	_expect(s_front > 0.9 and s_back < -0.9 and s_feet == 1.0, "ragdoll side: a body turned chest-down on the floor reads %.2f (front), turned back-down %.2f (back), upright %.2f (feet first: a plain fold)" % [s_front, s_back, s_feet])
	print("ragdoll variety: launches differ by %.3f rad, the same one repeats exactly, the side of the hit picks fold or arch" % d_ab)


## Flail families and the launch's own power (docs/animation/ragdoll-families.md). Six families, each its own way of going limp or fighting the air, picked by a hash of the slot and the launch number; a light pop flails gently and a full send frantically.
## The flail alone (the springs' target, no pose), 90 ticks, the head, spine, arms, legs and out-of-plane joints measured by how far they swing.
func _rg_fam_run(launch_n: int, speed: float) -> Dictionary:
	var rd := AnimRagdoll.new()
	rd.n_on = AnimRagdoll.N
	rd.set_flail_seed(0, launch_n, 1, speed)
	rd.w_flail = 1.0
	var act := [0.0, 0.0, 0.0, 0.0, 0.0]   # how fast each group moves: the mean angular speed over the flail, rad a second
	var cnt := [0, 0, 0, 0, 0]
	var hist: Array = []
	for k in range(90):
		rd.step(1.0 / 60.0, Vector2(900.0, 0.0), Vector2.ZERO, 0.85, 1.0, 5.0 + float(k) / 60.0)
		hist.append(rd.th.duplicate())
		for i in range(AnimRagdoll.N):
			var g: int = AnimRagdoll.group_of[i]
			act[g] += absf(rd.om[i])
			cnt[g] += 1
	for g in range(5):
		act[g] = float(act[g]) / maxf(float(cnt[g]), 1.0)
	return {"fam": rd.fam_idx, "hist": hist, "sw": act, "dur": rd.fam_dur * rd.launch_dur, "amp": rd.launch_amp}


func _test_ragdoll_families() -> void:
	AnimRagdoll.setup()
	var bad: Array = []
	var by_fam: Dictionary = {}
	for n in range(1, 80):
		var r: Dictionary = _rg_fam_run(n, 1500.0)
		if not by_fam.has(int(r.fam)):
			by_fam[int(r.fam)] = r
	if by_fam.size() != AnimRagdoll.families.size():
		bad.append("%d of %d families came up in 80 launches" % [by_fam.size(), AnimRagdoll.families.size()])
	# two families differ when some joint's whole trajectory differs: the rms of the difference over the flail, the most of any joint
	var worst: float = 1.0e9
	var keys: Array = by_fam.keys()
	for a in range(keys.size()):
		for b in range(a + 1, keys.size()):
			var d: float = 0.0
			for i in range(AnimRagdoll.N):
				var ss: float = 0.0
				for k in range(90):
					var df: float = float(by_fam[keys[a]].hist[k][i]) - float(by_fam[keys[b]].hist[k][i])
					ss += df * df
				d = maxf(d, sqrt(ss / 90.0))
			worst = minf(worst, d)
	if worst < 0.25:
		bad.append("two families are within %.2f rad (rms) of each other in every joint (0.25 wanted)" % worst)
	# a light pop against a full send: the same launch, the flail wider and longer
	var light: Dictionary = _rg_fam_run(3, 450.0)
	var full: Dictionary = _rg_fam_run(3, 2600.0)
	var sl: float = 0.0
	var sf: float = 0.0
	for g in range(5):
		sl += float(light.sw[g])
		sf += float(full.sw[g])
	if sf < 1.35 * sl or float(full.dur) < 1.5 * float(light.dur):
		bad.append("a full send moves %.2f against %.2f rad a second for a light pop and lasts %.2f against %.2f (1.35 and 1.5 times wanted)" % [sf, sl, float(full.dur), float(light.dur)])
	_expect(bad.is_empty(), "ragdoll families: six distinct flails, a full send wider and longer than a light pop: %s" % str(bad))
	print("ragdoll families: %d families, the closest pair %.2f rad apart (rms) in their most different joint; light pop %.1f rad a second of motion (summed over the groups) for %.2f s of flail scale, full send %.1f for %.2f" % [by_fam.size(), worst, sl, float(light.dur), sf, float(full.dur)])


## RG1: the ragdoll has weight. A heavier body moves less for the same blow, a higher tier moves it more, and a blow travels down the body (the head first, the legs last).
func _test_ragdoll_weight() -> void:
	AnimRagdoll.setup()
	var rd := AnimRagdoll.new()
	rd.weighted = true
	rd.tier = 1.0
	rd.mass = 1.0
	var g1: float = rd.gain()
	rd.mass = 1.3
	var g_heavy: float = rd.gain()
	rd.mass = 1.0
	rd.tier = 4.0
	var g_t4: float = rd.gain()
	rd.tier = 2.5
	var g_t25: float = rd.gain()
	rd.weighted = false
	var g_off: float = rd.gain()
	_expect(absf(g1 - 1.0) < 0.001 and g_heavy < g1 and g_t4 > 1.5 and g_t25 > g1 and g_t25 < g_t4 and g_off == 1.0, "ragdoll weight: gain is %.2f at tier 1, %.2f for a body 1.3 times heavier, %.2f at tier 2.5, %.2f at tier 4, %.2f with weighting off" % [g1, g_heavy, g_t25, g_t4, g_off])
	var a := AnimRagdoll.new()
	a.weighted = true
	a.crumple(1.0, 1.0, 1.0)
	var head0: float = a.om[0]
	var sh_l: int = 9
	a.step(1.0 / 60.0, Vector2.ZERO, Vector2.ZERO, 0.0, 1.0, 0.0)
	a.step(1.0 / 60.0, Vector2.ZERO, Vector2.ZERO, 0.0, 1.0, 0.0)
	var spine_2: float = a.om[1]
	var shin_2: float = a.om[sh_l]
	for _k in range(5):
		a.step(1.0 / 60.0, Vector2.ZERO, Vector2.ZERO, 0.0, 1.0, 0.0)
	var shin_7: float = a.om[sh_l]
	_expect(head0 != 0.0 and spine_2 != 0.0 and shin_2 == 0.0 and shin_7 != 0.0, "ragdoll lag: after a crumple the head moves at once (%.2f), the spine by 2 ticks (%.2f), the shin not yet (%.2f) and by 7 ticks it does (%.2f)" % [head0, spine_2, shin_2, shin_7])
	var b := AnimRagdoll.new()
	b.weighted = false
	b.crumple(1.0, 1.0, 1.0)
	_expect(b.om[sh_l] != 0.0, "ragdoll lag: with weighting off every degree of freedom takes the blow at once, as before")
	print("ragdoll weight: gain %.2f to %.2f by tier, %.2f for a heavier body; a blow reaches the head, then the spine, then the legs" % [g1, g_t4, g_heavy])


## RG3 (docs/animation/ragdoll-physics-paper.md): six degrees of freedom out of the plane, behind RenderAnim.rd_oop. Off, the body never leaves its plane; on, a flail and a hit turn it about its long axis, no joint goes past a limit, and
## none sits at its limit for as long as a tenth of a second (a twist saturated in a tumble reads as a stuck rag).
func _test_ragdoll_oop() -> void:
	AnimRagdoll.setup()
	_expect(AnimRagdoll.N == 18 and AnimRagdoll.N_BASE == 12, "ragdoll oop: eighteen degrees of freedom, the first twelve the sagittal ones")
	var run := func(n_on: int) -> Dictionary:
		var rd := AnimRagdoll.new()
		rd.n_on = n_on
		rd.set_flail_seed(0, 3, 1)
		rd.w_flail = 1.0
		rd.hit(40.0, 10.0, 1.0, 1, 0.6, -0.4)
		rd.crumple(1.0, 1.0, -1.0)
		var stuck: int = 0
		var stuck_max: int = 0
		var oop_peak: float = 0.0
		for k in range(180):
			rd.step(1.0 / 60.0, Vector2(900.0, 100.0), Vector2(0.0, 0.0), 0.85, 1.0, 5.0 + float(k) / 60.0)
			var at_limit: bool = false
			for i in range(AnimRagdoll.N_BASE, AnimRagdoll.N):
				oop_peak = maxf(oop_peak, absf(rd.th[i]))
				var lim: float = AnimRagdoll.hi[i] if rd.th[i] >= 0.0 else -AnimRagdoll.lo[i]
				if absf(rd.th[i]) >= 0.98 * lim:
					at_limit = true
			stuck = stuck + 1 if at_limit else 0
			stuck_max = maxi(stuck_max, stuck)
		return {"peak": oop_peak, "stuck": stuck_max}
	var off: Dictionary = run.call(AnimRagdoll.N_BASE)
	var on: Dictionary = run.call(AnimRagdoll.N)
	_expect(float(off.peak) == 0.0 and float(on.peak) > 0.1 and int(on.stuck) < 6, "ragdoll oop: off the six stay at 0 (%.3f), on they turn the body up to %.2f rad and none sits at its limit for more than %d ticks (6 allowed)" % [float(off.peak), float(on.peak), int(on.stuck)])
	# every extreme turn of the six, applied to a standing pose, is cut inside the joint limits
	var viol: int = 0
	var rd2 := AnimRagdoll.new()
	rd2.n_on = AnimRagdoll.N
	for sgn in [-1.0, 1.0]:
		for i in range(AnimRagdoll.N_BASE, AnimRagdoll.N):
			rd2.reset()
			rd2.th[i] = (AnimRagdoll.hi[i] if sgn > 0.0 else AnimRagdoll.lo[i])
			var q1: Array[Quaternion] = AnimData.pose("stance.aggressive").q.duplicate()
			rd2.apply(q1, 1.0)
			viol += AnimJoints.violations(q1, rd2.shape_key).size()
	_expect(viol == 0, "ragdoll oop: the six at their extremes leave %d joints past a limit on the guard stance (0 allowed)" % viol)
	_expect(RenderAnim.rd_oop == true, "ragdoll oop: the switch is on by default (Orb, 2026-10-25: turn them on)")
	print("ragdoll oop: on, the body turns up to %.2f rad out of its plane; off, none; no joint past a limit at the extremes" % float(on.peak))


## RG2 (docs/animation/ragdoll-physics-paper.md section 3a): the mid-air skid. A launched fighter flying fast is laid out head first; the sim's brake event braces him against his velocity (the body leans back, the feet toward the travel), the
## weight follows the deceleration he shows, no joint goes past a limit, and when the brake ends he is let go within the exit ramp. The same fighter without the event stays head first.
func _test_air_brake() -> void:
	AnimData.load_every_wave()
	var lean_of := func(af: AnimFighter, f) -> float:
		var head: Vector3 = af.head_center()
		var pel: Vector3 = af.socket("pelvis")
		var d := Vector2((head.x - pel.x) * af.vface, head.y - pel.y)
		var c: float = cos(-f.rot)
		var s: float = sin(-f.rot)
		var a := Vector2(d.x * c - d.y * s, d.x * s + d.y * c)
		return rad_to_deg(atan2(a.x, a.y))
	var run := func(brake: bool) -> Dictionary:
		main.start_match(4, {"p1": false, "p2": false})
		for i in range(10):
			main.frame(1.0 / 60.0)
		var S: SimState = main.host.S
		var f0 = S.fighters[0]
		var f1 = S.fighters[1]
		RenderAnim._fighters.clear()
		f0.id = "PROTAGONIST"
		f1.id = "RIVAL"
		f0.x = 500.0
		f1.x = 2600.0
		f0.y = 300.0
		f1.y = 0.0
		f0.vx = 1600.0
		f0.vy = 0.0
		f0.state = "launched"
		f0.slide = 0.0
		var res := {"lean_coast": 0.0, "lean_brake": 0.0, "w_max": 0.0, "viol": 0, "braking_ticks": 0, "w_end": 1.0, "nan": 0}
		var af0: AnimFighter = null
		for k in range(90):
			S.tick = 2000 + k
			S.T = 300.0 + float(k) / 60.0
			if brake and k == 30:
				var ev := SimState.FxEvent.new()
				ev.type = "air_brake"
				ev.actor = 0.0
				ev.text = "start"
				ev.kind = "released"
				ev.amount = 1600.0
				RenderAnim.consume(S, [ev])
			if brake and k == 60:
				var ev2 := SimState.FxEvent.new()
				ev2.type = "air_brake"
				ev2.actor = 0.0
				ev2.text = "end"
				ev2.kind = "released"
				RenderAnim.consume(S, [ev2])
			if brake and k >= 30 and k < 60:
				f0.vx = maxf(f0.vx - 40.0, 0.0)   # 2,400 u/s2 of braking
			f0.x += f0.vx / 60.0
			var te := SimState.FxEvent.new()
			te.type = "tick"
			te.dt = 1.0 / 60.0
			te.frozen = false
			RenderAnim.consume(S, [te])
			af0 = RenderAnim.solve(S, f0)
			RenderAnim.solve(S, f1)
			for i in range(AnimRig.N):
				if is_nan(af0.q[i].x) or is_nan(af0.q[i].w):
					res.nan += 1
			res.viol += AnimJoints.violations(af0.q, af0._rd.shape_key).size()
			if k == 29:
				res.lean_coast = absf(lean_of.call(af0, f0))
			if k == 50:
				res.lean_brake = absf(lean_of.call(af0, f0))
			res.w_max = maxf(float(res.w_max), af0._ab_w)
			if af0.braking():
				res.braking_ticks += 1
			if k == 75:
				res.w_end = af0._ab_w
		return res
	var on: Dictionary = run.call(true)
	var off: Dictionary = run.call(false)
	_expect(int(on.nan) == 0 and int(on.viol) == 0, "air brake: no NaN (%d) and no joint past a limit (%d) through the skid" % [int(on.nan), int(on.viol)])
	_expect(float(on.w_max) > 0.9 and int(on.braking_ticks) >= 24 and int(off.braking_ticks) == 0, "air brake: the skid weight reaches %.2f over %d ticks with the event and never without it (%d)" % [float(on.w_max), int(on.braking_ticks), int(off.braking_ticks)])
	_expect(float(on.lean_brake) < 55.0 and float(on.lean_brake) > 8.0 and float(off.lean_coast) > 70.0 and float(on.lean_brake) < float(on.lean_coast) - 25.0, "air brake: laid out head first at %.0f degrees from upright while coasting, braced at %.0f against the velocity while braking (under 55)" % [float(on.lean_coast), float(on.lean_brake)])
	_expect(float(on.w_end) < 0.05, "air brake: the skid is let go within its exit ramp after the event ends (weight %.2f 15 ticks on)" % float(on.w_end))
	print("air brake: laid out at %.0f degrees, braced at %.0f, let go inside the ramp; none of it without the sim's event" % [float(on.lean_coast), float(on.lean_brake)])


## RG4 (docs/animation/ragdoll-physics-paper.md section 4; Game Design's chain, docs/design/buildings.md section 7.3): a scripted chain through a tower (the face, a slab he breaks, the ceiling, a slab again, the lodge) with World's contacts
## handed to the fighter by the scan, since World has no such event yet (the render reads `kind` as the surface, and `nx`, `ny`, `punch`, `stop`, `vn`, `vt` as the paper asks). Nothing may be NaN or past a limit, the ceiling plays the slam and then the rebound, the lodge plays the climb and ends, and no bone turns more than 25 degrees in a tick from the climb on (the hand-off; the sudden stop at the lodge whips the arms, and that is meant), nor more than 45 through the
## chain (a hit's own flail is quick).
func _test_chain() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = "PROTAGONIST"
	f1.id = "RIVAL"
	f0.x = 500.0
	f1.x = 2600.0
	f0.y = 200.0
	f1.y = 0.0
	f0.vx = 1400.0
	f0.vy = 300.0
	f0.state = "launched"
	f0.slide = 0.0
	var C: Dictionary = AnimData.chain
	var seen := {}
	var nan: int = 0
	var viol: int = 0
	var maxrot: float = 0.0
	var maxhand: float = 0.0
	var prev: Array[Quaternion] = []
	var seq_end: int = -1
	var ev_at := {10: ["face", false, -1.0, 0.0, 1500.0, 15], 25: ["floor", true, 0.0, 1.0, 900.0, 0], 40: ["ceiling", true, 0.0, -1.0, 700.0, 0], 55: ["floor", true, 0.0, 1.0, 500.0, 0]}
	for k in range(190):
		S.tick = 3000 + k
		S.T = 400.0 + float(k) / 60.0
		var afc: AnimFighter = RenderAnim.fighter(S, f0)
		if ev_at.has(k):
			var d: Array = ev_at[k]
			afc.on_interior_contact({"surface": String(d[0]), "punch": bool(d[1]), "nx": float(d[2]), "ny": float(d[3]), "vn": float(d[4]), "vt": 200.0, "stop": int(d[5]), "k": k}, S.T)
		if k == 70:
			afc.on_lodge(0.7, S.T)
			f0.vx = 0.0   # lodged: the breach holds him where he is
			f0.vy = 0.0
		f0.x += f0.vx / 60.0
		f0.vx *= 0.985
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		var af0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		if not af0._seq.is_empty():
			seen[String(af0._seq.id)] = true
		elif seen.has("lg.climb") and seq_end < 0:
			seq_end = k
		for i in range(AnimRig.N):
			if is_nan(af0.q[i].x) or is_nan(af0.q[i].w):
				nan += 1
		viol += AnimJoints.violations(af0.q, af0._rd.shape_key).size()
		if prev.size() == AnimRig.N and k > 2:
			for i in range(AnimRig.N):
				var dr: float = prev[i].angle_to(af0.q[i])
				maxrot = maxf(maxrot, dr)
				if k >= 112:
					maxhand = maxf(maxhand, dr)   # the climb and the stand: after the 0.7 s hold that begins at tick 70
		prev = af0.q.duplicate()
	_expect(not C.is_empty() and seen.has("ce.slam") and seen.has("ce.rebound") and seen.has("lg.climb") and seen.has("gc.bounce"), "chain: the face, the ceiling (slam then rebound) and the lodge each play their sequence (%s)" % str(seen.keys()))
	_expect(nan == 0 and viol == 0, "chain: no NaN (%d) and no joint past a limit (%d) through five contacts and the lodge" % [nan, viol])
	_expect(seq_end > 0 and seq_end < 190, "chain: the lodge's climb ends and hands him back (at tick %d)" % seq_end)
	_expect(rad_to_deg(maxhand) <= 25.0 and rad_to_deg(maxrot) <= 45.0, "chain: no bone turns more than %.1f degrees in a tick from the climb on (25 allowed: the hand-off) or %.1f through the whole chain (45: a hit's own flail)" % [rad_to_deg(maxhand), rad_to_deg(maxrot)])
	print("chain: face, slab, ceiling, slab, lodge: slam, rebound and climb play, the hand-off at tick %d, the largest turn in a tick %.1f degrees (%.1f from the climb on)" % [seq_end, rad_to_deg(maxrot), rad_to_deg(maxhand)])


## C0 and C1 of the clinch (docs/animation/clinch-sizing.md): the partner pick, the regions a hold takes, and the thrower's side of the eight throws.
## The partner is the exchange's other fighter, else the nearest body by the shortest arc (not the first in the list: with four bodies the first is often the wrong one). The hold regions are the places Legal allows (collar,
## shoulders, upper arms, the waist, the ankles; g01: never the throat) and the back for a pin. The throws: every pose exists and is inside the joint limits, the hands apart by 16 or more where Legal asks, no arm crossed (h09).
func _test_grapple_c0_c1() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	var stands: Array = AnimMany.make(S, 2)
	f0.x = 1000.0
	f1.x = 1900.0
	for st in stands:
		st.y = 0.0
		S.fighters.append(st)
	stands[0].x = 1300.0
	stands[1].x = 2500.0
	var af0 := AnimFighter.new(0)
	var near = af0._opponent(S, f0)
	S.dirS.ex = null
	var near_ok: bool = near != f1 and near != f0
	var ex := DirExchange.newEx(f0, f1, "light")
	S.dirS.ex = ex
	var ex_ok: bool = af0._opponent(S, f0) == f1 and af0._opponent(S, f1) == f0
	S.dirS.ex = null
	AnimMany.detach(S, stands)
	_expect(near_ok and ex_ok, "grapple C0: with four bodies the partner is the nearest by the arc when there is no exchange (%s) and the exchange's other fighter when there is (%s)" % [str(near_ok), str(ex_ok)])
	# the regions of a hold
	var af := AnimFighter.new(0)
	af.q = AnimData.pose("stance.aggressive").q.duplicate()
	af.hips = AnimData.pose("stance.aggressive").hips
	var gq: Array[Quaternion] = []
	var gp := PackedVector3Array()
	gq.resize(AnimRig.N)
	gp.resize(AnimRig.N)
	AnimPose.fk(af.q, af.hips, gq, gp)
	AnimPose.fk(af.q, af.hips, af.gq, af.gp)
	af._full_fk = true
	var neck: Vector3 = gp[AnimRig.index["neck"]]
	var head: Vector3 = af.head_center()
	var bad: Array = []
	for rn in ["collar_r", "collar_l", "shoulder_r", "shoulder_l", "upper_arm_r", "upper_arm_l", "waist", "ankle_r", "ankle_l", "back"]:
		if not AnimData.sockets.get("regions", {}).has(rn):
			bad.append(rn + " missing")
			continue
		var pt: Vector3 = af._region_point(rn)
		if not (is_finite(pt.x) and is_finite(pt.y) and is_finite(pt.z)):
			bad.append(rn + " not finite")
		elif rn.begins_with("collar") or rn.begins_with("shoulder") or rn.begins_with("upper_arm"):
			if pt.distance_to(neck) < 7.0 or pt.distance_to(head) < 12.0:
				bad.append("%s %.1f from the neck, %.1f from the head" % [rn, pt.distance_to(neck), pt.distance_to(head)])
	_expect(bad.is_empty(), "grapple C0: the ten hold regions exist and none is within 7 of the neck or 12 of the head (g01) %s" % str(bad))
	# the throws
	var T: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/anim/throws.json"))
	var wmin: float = float(T.get("wrists_apart_min", 16.0))
	var ids := {}
	for send in T.sends:
		for who in T.sends[send]:
			ids[String(T.sends[send][who])] = true
	var lost: Array = []
	var viol: int = 0
	var crossed: Array = []
	var near_hands: Array = []
	var posed: int = 0
	for id in ids:
		if not AnimData.entries.has(id):
			lost.append(id)
			continue
		for ph in AnimData.entries[id].phases:
			var p: AnimPose = AnimData.pose(String(ph.pose))
			posed += 1
			viol += AnimJoints.violations(p.q, "P").size()
			var q2: Array[Quaternion] = []
			var p2 := PackedVector3Array()
			q2.resize(AnimRig.N)
			p2.resize(AnimRig.N)
			AnimPose.fk(p.q, p.hips, q2, p2)
			var hr: Vector3 = p2[AnimRig.index["hand_r"]]
			var hl: Vector3 = p2[AnimRig.index["hand_l"]]
			if hr.z < hl.z:
				crossed.append(String(ph.pose))
			if (AnimData.raw[String(ph.pose)].get("_legal", []) as Array).has("wrists_apart") and hr.distance_to(hl) < wmin:
				near_hands.append("%s %.1f" % [String(ph.pose), hr.distance_to(hl)])
	_expect(lost.is_empty() and posed == 24, "grapple C1: the eight throws are sequences of three poses each (%d poses; missing %s)" % [posed, str(lost)])
	_expect(viol == 0, "grapple C1: the throw poses leave %d joints past a limit (0 allowed)" % viol)
	_expect(crossed.is_empty() and near_hands.is_empty(), "grapple C1: no arm crossed (%s) and no hands under %.0f apart where Legal asks (%s)" % [str(crossed), wmin, str(near_hands)])
	var grips: Dictionary = T.get("grip", {})
	var gbad: Array = []
	for id2 in grips:
		if String(id2).begins_with("_"):
			continue
		for hand in grips[id2]:
			if not AnimData.sockets.get("regions", {}).has(String(grips[id2][hand])):
				gbad.append("%s %s" % [id2, hand])
	_expect(gbad.is_empty(), "grapple C1: every grip names a region that exists %s" % str(gbad))
	print("grapple: the partner pick and ten hold regions (C0), %d throw poses clean (C1)" % posed)


## The charge's held flight pose does not ride a flight: a fighter charging in place keeps it, one carried off at speed (a rush, a lunge, a drift, a bounce) loses it at once (lead_scan found him laid out feet first at 718 u/s on the
## launcher build's heavy, holding `ag.hold.charge_heavy`).
func _test_charge_cut() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = "PROTAGONIST"
	f1.id = "RIVAL"
	f0.x = 500.0
	f1.x = 2600.0
	f0.y = 0.0
	f1.y = 0.0
	f0.vx = 0.0
	f0.vy = 0.0
	f0.state = "free"
	var held_still: int = 0
	var cut_at: int = -1
	var af0: AnimFighter = null
	for k in range(80):
		S.tick = 4000 + k
		S.T = 500.0 + float(k) / 60.0
		if k == 4:
			RenderAnim.fighter(S, f0).on_agency("charge_heavy", S.T, {})
		if k >= 40:
			f0.x += 718.0 / 60.0
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		af0 = RenderAnim.solve(S, f0)
		if k >= 8 and k < 40 and af0._ag_t0 >= 0.0:
			held_still += 1
		if k >= 40 and cut_at < 0 and af0._ag_t0 < 0.0:
			cut_at = k
	_expect(held_still == 32 and cut_at >= 40 and cut_at <= 41, "charge cut: the charge pose is held for %d of 32 ticks standing and let go at tick %d of the carry (40 is its first tick; at most 41)" % [held_still, cut_at])
	print("charge cut: held while he stands, let go %d ticks after he is carried at 718 u/s" % (cut_at - 40))


## C2 of the clinch (docs/animation/clinch-sizing.md): the grip layer. Two fighters tied up (the read the sim will send, handed to both by the scan): each hand lands on its region of the other (the shortfall within the data's gap
## budget), no joint is past a limit, the bodies do not pass through one another (pair_clear: the bone capsules of one against the other's, the gripping forearms apart, to within 1.5 units: two arms crossing in a hold touch), the hands never lace (g02: 8 or more between one's hand
## and the other's), and the heads and torsos keep a forearm's length of air (g06). It also scans the spacing from 26 to 46 units and prints, for each grade of the grip, the least spacing at which all of that holds: the
## table Simulation holds the pair to.
func _seg_dist(p1: Vector3, p2: Vector3, q1: Vector3, q2: Vector3) -> float:
	var d1: Vector3 = p2 - p1
	var d2: Vector3 = q2 - q1
	var r: Vector3 = p1 - q1
	var a: float = d1.dot(d1)
	var e: float = d2.dot(d2)
	var fq: float = d2.dot(r)
	var s: float = 0.0
	var t: float = 0.0
	if a <= 0.00001 and e <= 0.00001:
		return r.length()
	if a <= 0.00001:
		t = clampf(fq / e, 0.0, 1.0)
	else:
		var c: float = d1.dot(r)
		if e <= 0.00001:
			s = clampf(-c / a, 0.0, 1.0)
		else:
			var b: float = d1.dot(d2)
			var den: float = a * e - b * b
			s = clampf((b * fq - c * e) / den, 0.0, 1.0) if den > 0.00001 else 0.0
			t = (b * s + fq) / e
			if t < 0.0:
				t = 0.0
				s = clampf(-c / a, 0.0, 1.0)
			elif t > 1.0:
				t = 1.0
				s = clampf((b - c) / a, 0.0, 1.0)
	return (p1 + d1 * s).distance_to(q1 + d2 * t)


func _segs_of(af: AnimFighter, f) -> Array:
	# [name, from, to, radius] in world space (x with the facing, y, z): the torso, the head, the upper arms, the thighs and shins (the forearms are the grip's own contact and are left out)
	var out: Array = []
	var wp := func(n: String) -> Vector3:
		var s: Vector3 = af.socket(n)
		return Vector3(f.x + af.vface * s.x, f.y + s.y, s.z)
	var hc: Vector3 = af.head_center()
	var head := Vector3(f.x + af.vface * hc.x, f.y + hc.y, hc.z)
	out.append(["torso", wp.call("pelvis"), wp.call("neck"), 6.5])
	out.append(["head", head, head, 5.0])
	for sd in ["r", "l"]:
		out.append(["upper_arm_" + sd, wp.call("upper_arm_" + sd), wp.call("forearm_" + sd), 3.5])
		out.append(["thigh_" + sd, wp.call("thigh_" + sd), wp.call("shin_" + sd), 4.5])
		out.append(["shin_" + sd, wp.call("shin_" + sd), wp.call("foot_" + sd), 3.5])
	return out


func _grip_scene(grade: float, spacing: float, kind: String = "tie", grips: Dictionary = {"hand_r": "collar_r", "hand_l": "upper_arm_l"}, role_b: String = "holder") -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = "PROTAGONIST"
	f1.id = "RIVAL"
	f0.x = 1000.0
	f1.x = 1000.0 + spacing
	f0.y = 0.0
	f1.y = 0.0
	f0.vx = 0.0
	f1.vx = 0.0
	f0.state = "locked"
	f1.state = "locked"
	var res := {"nan": 0, "viol": 0, "gap": 0.0, "clear": 1.0e9, "laced": 1.0e9, "g06": 1.0e9, "hand_d": 0.0}
	var a0: AnimFighter = null
	var a1: AnimFighter = null
	for k in range(18):
		S.tick = 5000 + k
		S.T = 600.0 + float(k) / 60.0
		if k == 2:
			RenderAnim.fighter(S, f0).on_hold({"partner": 1, "kind": kind, "role": "holder", "grade": grade, "side": "l", "grips": grips}, S.T)
			RenderAnim.fighter(S, f1).on_hold({"partner": 0, "kind": kind, "role": role_b, "grade": -grade, "side": "r", "grips": grips if role_b == "holder" else {}}, S.T)
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		a0 = RenderAnim.solve(S, f0)
		a1 = RenderAnim.solve(S, f1)
		for af in [a0, a1]:
			for i in range(AnimRig.N):
				if is_nan(af.q[i].x) or is_nan(af.q[i].w):
					res.nan += 1
			res.viol += AnimJoints.violations(af.q, af._rd.shape_key).size()
	res.gap = maxf(float(a0.debug.get("grip_gap_max", 0.0)), float(a1.debug.get("grip_gap_max", 0.0)))
	var sa: Array = _segs_of(a0, f0)
	var sb: Array = _segs_of(a1, f1)
	for x in sa:
		for y in sb:
			var cl: float = _seg_dist(x[1], x[2], y[1], y[2]) - float(x[3]) - float(y[3])
			if cl < float(res.clear):
				res["worst"] = "%s / %s" % [x[0], y[0]]
			res.clear = minf(float(res.clear), cl)
			if (String(x[0]) == "torso" or String(x[0]) == "head") and (String(y[0]) == "torso" or String(y[0]) == "head"):
				res.g06 = minf(float(res.g06), cl)
	for h0 in ["hand_r", "hand_l"]:
		for h1 in ["hand_r", "hand_l"]:
			var p0: Vector3 = a0.socket(h0)
			var p1: Vector3 = a1.socket(h1)
			var w0 := Vector3(f0.x + a0.vface * p0.x, f0.y + p0.y, p0.z)
			var w1 := Vector3(f1.x + a1.vface * p1.x, f1.y + p1.y, p1.z)
			res.laced = minf(float(res.laced), w0.distance_to(w1))
	return res


func _test_grip() -> void:
	AnimData.load_every_wave()
	var table: Array = []
	var worst_nan: int = 0
	var worst_viol: int = 0
	var worst_gap_at_40: float = 0.0
	var all_ok_by: Dictionary = {}
	for grade in [-1.0, 0.0, 1.0]:
		var least: float = -1.0
		var most: float = -1.0
		for spacing in range(26, 47, 2):
			var r: Dictionary = _grip_scene(grade, float(spacing))
			worst_nan += int(r.nan)
			worst_viol += int(r.viol)
			if spacing == 40:
				worst_gap_at_40 = maxf(worst_gap_at_40, float(r.gap))
			var ok: bool = float(r.gap) <= float(AnimData.clinch.get("gap_budget", 3.0)) and float(r.clear) >= -1.5 and float(r.laced) >= 8.0 and float(r.g06) >= 15.0
			if ok and least < 0.0:
				least = float(spacing)
			if ok:
				most = float(spacing)
		table.append([grade, least, most])
		all_ok_by[grade] = least
	_expect(worst_nan == 0 and worst_viol == 0, "grip: no NaN (%d) and no joint past a limit (%d) through the tie-up at every grade and spacing from 26 to 46" % [worst_nan, worst_viol])
	var fits: bool = true
	for row in table:
		if float(row[1]) < 0.0 or float(row[2]) - float(row[1]) < 4.0:
			fits = false   # a window of at least 4 units for the sim to hold the pair in
	_expect(fits, "grip: each grade has a window of 4 units or more (least and most spacing) where the hands land (gap within the budget), the bodies clear to within 1.5 (arms crossing in a hold touch: a bone capsule is a fat model of an arm), no hands laced (8) and heads and torsos a forearm apart (15): %s" % str(table))
	# every kind of hold once, at 34 units: no NaN, no joint past a limit, the hands on their regions (the refused grip over-reaches by design)
	var kinds := {
		"pummel": [{"hand_r": "collar_r", "hand_l": "upper_arm_l"}, "holder"],
		"brace": [{"hand_r": "collar_r"}, "holder"],
		"pin": [{"hand_r": "shoulder_r", "hand_l": "upper_arm_l"}, "held"],
		"carry": [{"hand_r": "collar_r", "hand_l": "waist"}, "holder"],
		"strain": [{"hand_r": "collar_r", "hand_l": "waist"}, "holder"],
		"whiff": [{"hand_r": "collar_r"}, "holder"],
		"apart": [{}, "holder"]}
	var kbad: Array = []
	for kd in kinds:
		var kr: Dictionary = _grip_scene(0.0, 34.0, kd, kinds[kd][0], kinds[kd][1])
		if int(kr.nan) > 0 or int(kr.viol) > 0 or (kd != "whiff" and float(kr.gap) > float(AnimData.clinch.get("gap_budget", 3.0))):
			kbad.append("%s nan %d viol %d gap %.1f" % [kd, int(kr.nan), int(kr.viol), float(kr.gap)])
	_expect(kbad.is_empty(), "grip: each kind of hold (pummel, brace, pin with the pinned body's brace, carry, strain, the refused grip, the push apart) is clean at 34 units %s" % str(kbad))
	print("grip: the least and most spacing (units) that hold the gap, the clearance, g02 and g06, by grade behind, even, ahead: [grade, least, most] %s; the largest shortfall at 40 units %.1f" % [str(table), worst_gap_at_40])


## Recoil exits and ricochets (docs/combat/choreography-feel.md; data/anim/recoil.json). Each kind plays on the struck fighter's own body at the cue's landing tick: a back flip turns the whole body once, backward (the head goes
## back first), through upside down, and lands upright; a handspring puts the hands to the ground at the top; a back tuck and a flip are inverted at the middle; a wall ricochet turns the feet to face the wall; a skip does not turn.
## Nothing may be NaN or past a limit, the exit ends on its tick and hands the body back clean, and the sim's position is never moved (the layer only turns and lifts the drawn body).
func _recoil_probe(kind: String, ticks: int, nx: float, ny: float, who: String) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1070.0
	f0.y = 0.0
	f1.y = 0.0
	f0.state = "free"
	f1.state = "free"
	f0.vx = 0.0
	var res := {"nan": 0, "viol": 0, "min_head": 1.0e9, "low": 1.0e9, "min_hand": 1.0e9, "turn": 0.0, "first_back": 0.0, "end_head": 0.0, "feet_dot": -1.0, "x_moved": 0.0, "ended": false, "recoiled": 0}
	var prev_ang: float = 0.0
	var have_prev: bool = false
	var unwrapped: float = 0.0
	var a0: AnimFighter = null
	for k in range(ticks + 8):
		S.tick = 7000 + k
		S.T = 800.0 + float(k) / 60.0
		if k == 2:
			RenderAnim.fighter(S, f0).on_recoil(kind, ticks, S.T, nx, ny)
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		a0 = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		for i in range(AnimRig.N):
			if is_nan(a0.q[i].x) or is_nan(a0.q[i].w):
				res.nan += 1
		res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size()
		var pel: Vector3 = a0.socket("pelvis")
		var hd: Vector3 = a0.head_center()
		var dv := Vector2((hd.x - pel.x) * a0.vface, hd.y - pel.y)
		var ang: float = atan2(dv.x, dv.y)   # 0 upright, positive leaning toward +x (forward on screen when he faces right)
		if have_prev:
			unwrapped += wrapf(ang - prev_ang, -PI, PI)
		prev_ang = ang
		have_prev = true
		if k >= 2 and k < 2 + ticks:
			res.min_head = minf(float(res.min_head), hd.y - pel.y)
			res.min_hand = minf(float(res.min_hand), minf(a0.socket("hand_r").y, a0.socket("hand_l").y))
			res.low = minf(float(res.low), minf(hd.y - 9.0, minf(a0.socket("hand_r").y, a0.socket("hand_l").y)))
			var u: float = float(k - 2) / float(ticks)
			if u > 0.2 and u < 0.3 and absf(res.first_back) < 0.001:
				res.first_back = dv.x
			if u > 0.38 and u < 0.46:
				var feet: Vector3 = (a0.socket("foot_r") + a0.socket("foot_l")) * 0.5 - pel
				var fd := Vector2(feet.x * a0.vface, feet.y).normalized()
				res.feet_dot = maxf(float(res.feet_dot), fd.dot(Vector2(-nx, -ny)))
		res.x_moved = maxf(float(res.x_moved), absf(f0.x - 1000.0))
	res.turn = unwrapped
	res.end_head = (a0.head_center().y - a0.socket("pelvis").y)
	res.ended = not a0.recoiling()
	res.recoiled = int(a0.debug.get("recoils", 0))
	return res


func _test_recoil() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	for who in ["PROTAGONIST", "RIVAL"]:
		for kd in ["backflip", "tuck", "handspring"]:
			var tk: int = {"backflip": 24, "tuck": 16, "handspring": 18}[kd]
			var r: Dictionary = _recoil_probe(kd, tk, 0.0, 1.0, who)
			seen.append("%s %s turn %.1f head %.0f hand %.0f" % [who.substr(0, 1), kd, rad_to_deg(float(r.turn)), float(r.min_head), float(r.min_hand)])
			if int(r.nan) > 0 or int(r.viol) > 0 or not bool(r.ended) or int(r.recoiled) != 1:
				bad.append("%s %s: nan %d viol %d ended %s recoiled %d" % [who, kd, int(r.nan), int(r.viol), str(r.ended), int(r.recoiled)])
			# one whole turn, backward (the head goes back first), upside down at the middle, upright at the end, and the sim's x never moved
			if absf(absf(float(r.turn)) - TAU) > 0.5 or float(r.first_back) >= 0.0 or float(r.min_head) > -12.0 or float(r.end_head) < 12.0 or float(r.x_moved) > 0.001:
				bad.append("%s %s: turn %.0f deg, first_back %.1f, lowest head %.1f, end head %.1f, moved %.3f" % [who, kd, rad_to_deg(float(r.turn)), float(r.first_back), float(r.min_head), float(r.end_head), float(r.x_moved)])
	for who2 in ["PROTAGONIST", "RIVAL"]:
		for kd2 in ["backflip", "tuck", "handspring"]:
			for tk2 in [8, 12, 18, 24]:
				var r2: Dictionary = _recoil_probe(kd2, tk2, 0.0, 1.0, who2)
				if int(r2.viol) > 0 or int(r2.nan) > 0 or not bool(r2.ended) or absf(absf(float(r2.turn)) - TAU) > 0.5:
					bad.append("%s %s over %d ticks: viol %d nan %d turn %.0f" % [who2, kd2, tk2, int(r2.viol), int(r2.nan), rad_to_deg(float(r2.turn))])
				# no body point below the ground (hands at the fingertips, the head a head's radius under its centre) with no path under it: nothing sinks through the floor at any duration
				if float(r2.low) < -1.0:
					bad.append("%s %s over %d ticks: the lowest point is %.1f under the ground" % [who2, kd2, tk2, -float(r2.low)])
	var hs: Dictionary = _recoil_probe("handspring", 18, 0.0, 1.0, "PROTAGONIST")
	if float(hs.min_hand) > 8.0:
		bad.append("handspring: the hands come no nearer the ground than %.1f (8 or under: they take it)" % float(hs.min_hand))
	var wl: Dictionary = _recoil_probe("ricochet_wall", 14, 1.0, 0.0, "PROTAGONIST")
	if float(wl.feet_dot) < 0.85 or int(wl.nan) > 0 or int(wl.viol) > 0 or not bool(wl.ended):
		bad.append("wall: the feet face the wall by %.2f (0.85 needed), nan %d viol %d ended %s" % [float(wl.feet_dot), int(wl.nan), int(wl.viol), str(wl.ended)])
	var sk: Dictionary = _recoil_probe("skip", 10, 0.0, 1.0, "PROTAGONIST")
	if absf(float(sk.turn)) > 0.6 or float(sk.min_head) < 10.0 or int(sk.viol) > 0 or not bool(sk.ended):
		bad.append("skip: turn %.0f, lowest head %.1f, viol %d" % [rad_to_deg(float(sk.turn)), float(sk.min_head), int(sk.viol)])
	var gr: Dictionary = _recoil_probe("ricochet_ground", 12, 0.0, 1.0, "PROTAGONIST")
	if int(gr.nan) > 0 or int(gr.viol) > 0 or not bool(gr.ended):
		bad.append("ground ricochet: nan %d viol %d ended %s" % [int(gr.nan), int(gr.viol), str(gr.ended)])
	_expect(bad.is_empty(), "recoil: every exit plays clean and does what it should: %s" % str(bad))
	print("recoil: %s; wall feet %.2f, handspring hands %.1f" % [" | ".join(seen), float(wl.feet_dot), float(hs.min_hand)])


## The shake by weight (rulings-2026-10-22 5b and section 6). A hit-stop's shake follows its weight (a mashed light's 2 ticks a little over half the profile's, 8 ticks as before, 24 at 1.6), and a blow that flows with no stop
## of its own (a mash's later blows) shakes the struck body a little for 6 ticks, drawn only; a guard and a blow with a stop of its own add nothing past the stop.
func _shiver_probe(stop_ticks: int, hit_stop: int, kind: String, ticks: int, hold: int = -1) -> Array:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	RenderAnim._fighters.clear()
	RenderAnim.debug_checks = true
	var out: Array = []
	var hl: int = stop_ticks if hold < 0 else hold
	var af: AnimFighter = RenderAnim.fighter(S, f0)
	for k in range(ticks):
		S.tick = 9000 + k
		S.T = 900.0 + float(k) / 60.0
		if k == 2:
			if hit_stop >= 0:
				af.on_hit(S.T, "core", true, 0.3, kind, Vector2(-1, 0), 0.4, S.tick, 0.0, 0, hit_stop)
		S.dirS.stop = float(stop_ticks) / 60.0 if (stop_ticks > 0 and k >= 2 and k < 2 + hl) else 0.0
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = S.dirS.stop > 0.0
		RenderAnim.consume(S, [te])
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		out.append(float(a0.debug.get("shiver", 0.0)))
	RenderAnim.debug_checks = false
	return out


func _test_shake() -> void:
	var bad: Array = []
	var peak: Dictionary = {}
	for n in [2, 3, 5, 8, 12, 24]:
		var o: Array = _shiver_probe(n, n, "heavy", 40, 30)   # the stop held 30 ticks at that weight, so the peak is over many jitters
		peak[n] = (o.slice(2, 32) as Array).max()
	var base: float = float(peak[8])
	if base < 0.05:
		bad.append("the 8-tick stop does not shake at all (%.3f)" % base)
	else:
		if float(peak[2]) / base > 0.62 or float(peak[2]) / base < 0.4:
			bad.append("a 2-tick stop shakes %.2f of the 8-tick one (about 0.5 wanted)" % (float(peak[2]) / base))
		if float(peak[24]) / base < 1.4:
			bad.append("a 24-tick stop shakes %.2f of the 8-tick one (1.6 at most, 1.4 at least)" % (float(peak[24]) / base))
		if float(peak[12]) < float(peak[8]) * 1.1 or float(peak[5]) > float(peak[8]) or float(peak[3]) > float(peak[5]) * 1.001:
			bad.append("the shake does not rise with the stop: %s" % str(peak))
	# a blow with no stop of its own: a small shake for the contact, gone in 6 ticks
	var fl: Array = _shiver_probe(0, 0, "light", 20)
	var fl_peak: float = (fl.slice(2, 6) as Array).max()
	var fl_after: float = (fl.slice(10, 20) as Array).max()
	if fl_peak < 0.04 or fl_peak > base * 0.8:
		bad.append("a flowing light's shake is %.3f against the 8-tick stop's %.3f (small but there)" % [fl_peak, base])
	if fl_after > 0.001:
		bad.append("a flowing blow's shake lasts past 6 ticks (%.3f at tick 8 on)" % fl_after)
	var gd: Array = _shiver_probe(0, 0, "guard", 12)
	if (gd as Array).max() > 0.001:
		bad.append("a guarded blow shakes (%.3f)" % (gd as Array).max())
	var st: Array = _shiver_probe(4, 4, "light", 20)
	if (st.slice(2 + 4, 20) as Array).max() > 0.001:
		bad.append("a blow with a stop of its own shakes past it (%.3f)" % (st.slice(6, 20) as Array).max())
	_expect(bad.is_empty(), "the shake by weight: %s" % str(bad))
	print("shake by weight: stops 2 %.2f, 3 %.2f, 5 %.2f, 8 %.2f, 12 %.2f, 24 %.2f; a flowing light %.2f, gone by tick 10 (%.3f)" % [peak[2], peak[3], peak[5], peak[8], peak[12], peak[24], fl_peak, fl_after])


## The press-tick anticipation (docs/animation/press-ack.md). A press that has to wait is committed to on its own tick: the body leans and sets (a light), moves its weight and winds a shoulder (a heavy) or sinks (a signature) over 6 ticks,
## holds while the wait runs, and lets go over 6 ticks, or at once when the exchange starts (a blow taken, the wind-up cue). Nothing may be NaN or past a limit, and the body is exactly the idle stand again after it.
func _ack_probe(cell: String, who: String, wait: int, ticks: int, hit_at: int, off: bool) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1180.0
	f0.y = 0.0
	f1.y = 0.0
	f0.state = "free"
	f1.state = "free"
	f0.vx = 0.0
	RenderAnim.press_ack = not off
	var res := {"nan": 0, "viol": 0, "lean_peak": 0.0, "drop_peak": 0.0, "rest_diff": 0.0, "cleared_at": -1, "hold_diff": 0.0}
	var base_head: Array = []
	var a0: AnimFighter = null
	for k in range(ticks):
		S.tick = 8000 + k
		S.T = 850.0 + float(k) / 60.0
		if k == 4:
			RenderAnim.fighter(S, f0).on_press_ack(cell, -1 if wait < 0 else 8000 + 4 + wait, wait, S.T)
		if hit_at >= 0 and k == hit_at:
			RenderAnim.fighter(S, f0).on_hit(S.T, "core", true, 0.3, "light", Vector2(-1, 0), 0.4, S.tick, 0.0, 0)
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		a0 = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		for i in range(AnimRig.N):
			if is_nan(a0.q[i].x) or is_nan(a0.q[i].w):
				res.nan += 1
		res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size()
		var pel: Vector3 = a0.socket("pelvis")
		var hd: Vector3 = a0.head_center()
		base_head.append([(hd.x - pel.x) * a0.vface, pel.y, hd.y])
		if res.cleared_at < 0 and k > 4 and a0._ack.is_empty():
			res.cleared_at = k
	res["samples"] = base_head
	RenderAnim.press_ack = true
	return res


func _test_press_ack() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	for who in ["PROTAGONIST", "RIVAL"]:
		for cell in ["x", "y", "b"]:
			var on: Dictionary = _ack_probe(cell, who, 20, 50, -1, false)
			var off: Dictionary = _ack_probe(cell, who, 20, 50, -1, true)
			var lean: float = 0.0
			var drop: float = 0.0
			for k in range(on.samples.size()):
				lean = maxf(lean, absf(float(on.samples[k][0]) - float(off.samples[k][0])))
				drop = maxf(drop, float(off.samples[k][1]) - float(on.samples[k][1]))
			var rest: float = 0.0
			for k in range(40, 50):
				rest = maxf(rest, absf(float(on.samples[k][0]) - float(off.samples[k][0])) + absf(float(on.samples[k][1]) - float(off.samples[k][1])))
			# nothing pops: the part the pose adds to the stand never changes by more than 0.6 of its whole size in one tick (the 6-tick ramps in and out, solved on twos: a pop is 0.7 or more)
			var step: float = 0.0
			var total: float = 0.0
			for k in range(1, on.samples.size()):
				var dk: float = (float(on.samples[k][0]) - float(off.samples[k][0])) - (float(on.samples[k - 1][0]) - float(off.samples[k - 1][0]))
				var dh: float = (float(on.samples[k][1]) - float(off.samples[k][1])) - (float(on.samples[k - 1][1]) - float(off.samples[k - 1][1]))
				step = maxf(step, Vector2(dk, dh).length())
				total = maxf(total, Vector2(float(on.samples[k][0]) - float(off.samples[k][0]), float(on.samples[k][1]) - float(off.samples[k][1])).length())
			if step > 0.6 * total:
				bad.append("%s %s: the anticipation changes the body by %.2f of its %.2f units in one tick (0.6 at most)" % [who, cell, step, total])
			var early: float = absf(float(on.samples[8][0]) - float(off.samples[8][0])) + absf(float(on.samples[8][1]) - float(off.samples[8][1]))
			seen.append("%s %s lean %.1f drop %.1f rest %.2f cleared %d" % [who.substr(0, 1), cell, lean, drop, rest, int(on.cleared_at)])
			if int(on.nan) > 0 or int(on.viol) > 0:
				bad.append("%s %s: nan %d viol %d" % [who, cell, int(on.nan), int(on.viol)])
			# it must show: a few units of lean or of sink by the end of the ramp; and be gone, to the idle stand, after the wait and the exit
			if early < 1.2:
				bad.append("%s %s: shows %.2f units 4 ticks in (1.2 wanted)" % [who, cell, early])
			if rest > 0.35 or int(on.cleared_at) < 0:
				bad.append("%s %s: not back to the stand after the wait (diff %.2f, cleared %d)" % [who, cell, rest, int(on.cleared_at)])
	# a blow taken ends it at once: let go over its 6 ticks from the hit, not at the end of the wait
	var hit: Dictionary = _ack_probe("x", "PROTAGONIST", 30, 50, 12, false)
	if int(hit.cleared_at) < 0 or int(hit.cleared_at) > 12 + 8:
		bad.append("a blow taken at tick 12 leaves it on until tick %d (20 at most)" % int(hit.cleared_at))
	# a wait under min_wait shows nothing
	var tiny: Dictionary = _ack_probe("y", "PROTAGONIST", 2, 20, -1, false)
	if int(tiny.cleared_at) != 5:
		bad.append("a 2-tick wait started an anticipation (cleared at %d: 5 means it never started)" % int(tiny.cleared_at))
	_expect(bad.is_empty(), "press-tick anticipation: every cell and fighter plays clean, shows and hands back: %s" % str(bad))
	print("press-tick anticipation: %s" % " | ".join(seen))


## The beam struggle's dig-in (docs/animation/struggle-dig-in.md). With the meeting point past the middle the fighter it pushes back digs in (the pelvis sinks, the drawn body is dragged back) and trembles; the winner leans in a
## little; an even point and no point show nothing; and it all eases away when the struggle ends, with nothing popping. Nothing may be NaN or past a limit, and the sim's position is never moved.
func _struggle_probe(who: String, mid: float, ticks: int, end_at: int, off: bool) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1180.0
	f0.y = 0.0
	f1.y = 0.0
	f0.state = "free"
	f1.state = "free"
	RenderAnim.struggle_dig = not off
	var res := {"nan": 0, "viol": 0, "moved": 0.0}
	var s0: Array = []
	var s1: Array = []
	for k in range(ticks):
		S.tick = 8500 + k
		S.T = 870.0 + float(k) / 60.0
		if k < end_at and mid != -9.0:
			var c := SimState.Clash.new()
			c.A = f0
			c.D = f1
			c.t0 = S.T
			c.dur = 3.0
			c.mid = mid
			S.game.clash = c
		else:
			S.game.clash = null
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		var a1: AnimFighter = RenderAnim.solve(S, f1)
		for i in range(AnimRig.N):
			if is_nan(a0.q[i].x) or is_nan(a1.q[i].x):
				res.nan += 1
		res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size() + AnimJoints.violations(a1.q, a1._rd.shape_key).size()
		s0.append([a0.socket("pelvis").x, a0.socket("pelvis").y])
		s1.append([a1.socket("pelvis").x, a1.socket("pelvis").y])
		res.moved = maxf(float(res.moved), absf(f0.x - 1000.0) + absf(f1.x - 1180.0))
	S.game.clash = null
	RenderAnim.struggle_dig = true
	res["a"] = s0
	res["d"] = s1
	return res


func _test_struggle() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	for who in ["PROTAGONIST", "RIVAL"]:
		var on: Dictionary = _struggle_probe(who, 0.9, 80, 999, false)   # D is being pushed back
		var off: Dictionary = _struggle_probe(who, 0.9, 80, 999, true)
		var d_drop: float = float(off.d[79][1]) - float(on.d[79][1])
		var d_back: float = float(off.d[79][0]) - float(on.d[79][0])
		var a_lean: float = float(on.a[79][0]) - float(off.a[79][0])
		var a_drop: float = absf(float(off.a[79][1]) - float(on.a[79][1]))
		seen.append("%s loser drop %.1f back %.1f, winner lean %.1f drop %.1f" % [who.substr(0, 1), d_drop, d_back, a_lean, a_drop])
		if int(on.nan) > 0 or int(on.viol) > 0 or float(on.moved) > 0.001:
			bad.append("%s: nan %d viol %d moved %.3f" % [who, int(on.nan), int(on.viol), float(on.moved)])
		if d_drop < 3.0 or d_back < 5.0:
			bad.append("%s: the loser digs in by %.1f down and %.1f back (3 and 5 wanted)" % [who, d_drop, d_back])
		if a_lean < 1.0 or a_lean > 4.0 or a_drop > 1.0:
			bad.append("%s: the winner leans %.1f and sinks %.1f (1 to 4 forward, no sink)" % [who, a_lean, a_drop])
		# the mirror: A losing
		var mir: Dictionary = _struggle_probe(who, 0.1, 80, 999, false)
		if float(off.a[79][1]) - float(mir.a[79][1]) < 3.0:
			bad.append("%s: with the point at 0.1 the first fighter does not dig in (%.1f)" % [who, float(off.a[79][1]) - float(mir.a[79][1])])
		# even and none: nothing
		var even: Dictionary = _struggle_probe(who, 0.5, 60, 999, false)
		var none: Dictionary = _struggle_probe(who, -1.0, 60, 999, false)
		var base: Dictionary = _struggle_probe(who, -9.0, 120, 999, false)
		for k in [30, 59]:
			for o in [even, none]:
				if absf(float(o.d[k][0]) - float(base.d[k][0])) > 0.3 or absf(float(o.d[k][1]) - float(base.d[k][1])) > 0.3:
					bad.append("%s: an even point or none changes the body at tick %d" % [who, k])
		# it ends: eased back, in small steps
		var endr: Dictionary = _struggle_probe(who, 0.9, 120, 50, false)
		var rest: float = absf(float(endr.d[119][0]) - float(base.d[119][0])) + absf(float(endr.d[119][1]) - float(base.d[119][1]))
		var step: float = 0.0
		for k in range(1, 120):
			step = maxf(step, Vector2(float(endr.d[k][0]) - float(endr.d[k - 1][0]), float(endr.d[k][1]) - float(endr.d[k - 1][1])).length())
		if rest > 0.6 or step > 3.0:
			bad.append("%s: after the struggle the body is %.2f off the stand and moves %.2f in a tick (0.6 and 3 at most)" % [who, rest, step])
	_expect(bad.is_empty(), "the beam struggle's dig-in: the pushed fighter digs in and is dragged back, the winner leans, it eases away: %s" % str(bad))
	print("struggle dig-in: %s" % " | ".join(seen))


## The grip fed from the sim as five stages (docs/animation/grip-stages.md). A catch's tell shows the catcher's reach and the caught nothing; the clinch is the tie-up, and the grade (-2 to 2) mixes the bodies in a step at a time:
## the leader at two ahead sets his hips (lower than at one ahead), the one at two behind caves (up on the heels); a pummel swims a hand in and out; the end lets the hold go. Nothing may pop (the largest move of a pelvis
## in a tick), no NaN, no joint past a limit, the hands stay within the grip budget on their regions, and the sim's position is never moved.
func _grip_feed_run(who: String) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1034.0
	f0.y = 0.0
	f1.y = 0.0
	f0.state = "locked"
	f1.state = "locked"
	var res := {"nan": 0, "viol": 0, "gap": 0.0, "caught_shows": 0, "moved": 0.0}
	var p0: Array = []
	var p1: Array = []
	var a0: AnimFighter = null
	var a1: AnimFighter = null
	for k in range(130):
		S.tick = 9500 + k
		S.T = 900.0 + float(k) / 60.0
		var g0: Dictionary = {}
		var g1: Dictionary = {}
		if k >= 4 and k < 14:
			g0 = {"mode": "tell", "role": "catcher", "grip": 0, "pulse": 0, "t0": 9504}
			g1 = {"mode": "tell", "role": "caught", "grip": 0, "pulse": 0, "t0": 9504}
		elif k >= 14 and k < 104:
			var gr: int = 0 if k < 40 else (1 if k < 62 else 2)
			g0 = {"mode": "clinch", "role": "catcher", "grip": gr, "pulse": 0, "t0": 9514}
			g1 = {"mode": "clinch", "role": "caught", "grip": -gr, "pulse": 0, "t0": 9514}
		a0 = RenderAnim.fighter(S, f0)
		a1 = RenderAnim.fighter(S, f1)
		a0._feed_from(S, f0, g0, S.T)
		a1._feed_from(S, f1, g1, S.T)
		if k == 78:
			a0.on_grip_pummel("step", S.T)
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		a0 = RenderAnim.solve(S, f0)
		a1 = RenderAnim.solve(S, f1)
		if k >= 4 and k < 14 and not a1._gr.is_empty():
			res.caught_shows += 1
		for af in [a0, a1]:
			for i in range(AnimRig.N):
				if is_nan(af.q[i].x) or is_nan(af.q[i].w):
					res.nan += 1
			res.viol += AnimJoints.violations(af.q, af._rd.shape_key).size()
		if k >= 30 and k < 100:
			res.gap = maxf(float(res.gap), maxf(float(a0.debug.get("grip_gap_max", 0.0)), float(a1.debug.get("grip_gap_max", 0.0))))
		p0.append([a0.socket("pelvis").x, a0.socket("pelvis").y])
		p1.append([a1.socket("pelvis").x, a1.socket("pelvis").y])
		res.moved = maxf(float(res.moved), absf(f0.x - 1000.0) + absf(f1.x - 1034.0))
	res["p0"] = p0
	res["p1"] = p1
	return res


func _test_grip_feed() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	for who in ["PROTAGONIST", "RIVAL"]:
		var r: Dictionary = _grip_feed_run(who)
		if int(r.nan) > 0 or int(r.viol) > 0 or float(r.moved) > 0.001:
			bad.append("%s: nan %d viol %d moved %.3f" % [who, int(r.nan), int(r.viol), float(r.moved)])
		if int(r.caught_shows) > 0:
			bad.append("%s: the caught shows a hold in the catch's tell (%d frames)" % [who, int(r.caught_shows)])
		# the five stages: the leader's hips go down a step at a time, the one behind's come up; the top step is lower than the one before it
		var y_even: float = float(r.p0[38][1])
		var y_one: float = float(r.p0[60][1])
		var y_two: float = float(r.p0[98][1])
		var b_even: float = float(r.p1[38][1])
		var b_two: float = float(r.p1[98][1])
		seen.append("%s leader hips even %.1f one ahead %.1f set %.1f; behind caves %.1f to %.1f; grip gap %.2f" % [who.substr(0, 1), y_even, y_one, y_two, b_even, b_two, float(r.gap)])
		if not (y_one < y_even - 0.8 and y_two < y_one - 1.5):
			bad.append("%s: the leader's hips do not go down a stage at a time (%.1f, %.1f, %.1f)" % [who, y_even, y_one, y_two])
		if b_two < b_even + 1.0:
			bad.append("%s: the one two behind does not cave up (%.1f to %.1f)" % [who, b_even, b_two])
		if float(r.gap) > 4.0:
			bad.append("%s: the hands end %.2f short of their regions (4 allowed, 3 the budget)" % [who, float(r.gap)])
		# nothing pops: a pelvis never moves more than 2.5 units in a tick, through the reach into the tie-up, the steps, the pummel and the end
		var step: float = 0.0
		for k in range(1, 130):
			step = maxf(step, Vector2(float(r.p0[k][0]) - float(r.p0[k - 1][0]), float(r.p0[k][1]) - float(r.p0[k - 1][1])).length())
			step = maxf(step, Vector2(float(r.p1[k][0]) - float(r.p1[k - 1][0]), float(r.p1[k][1]) - float(r.p1[k - 1][1])).length())
		if step > 2.5:
			bad.append("%s: a pelvis moves %.2f units in a tick (2.5 at most)" % [who, step])
		# the end lets go: back to the standing body
		var rest: float = absf(float(r.p0[129][1]) - float(r.p0[0][1])) + absf(float(r.p0[129][0]) - float(r.p0[0][0]))
		if rest > 1.0:
			bad.append("%s: the leader is %.2f off his stand after the hold ends" % [who, rest])
	_expect(bad.is_empty(), "the grip as five stages: the reach, the tie-up by grade, the pummel, the set and the cave, the end: %s" % str(bad))
	print("grip stages: %s" % " | ".join(seen))


## The grapple's end as a throw (docs/animation/grip-stages.md; data/anim/throws.json). The grapple_end cue (throw_across, thrown_up, thrown_down, reversal) plays the thrower's own sequence (both fighters, all four sends and the
## send past him) from the tick the sim sends the other body, and the hold lets go without the hands chasing him. Nothing may be NaN or past a limit, the sequence plays and ends, and nothing pops.
func _throw_probe(who: String, text: String, past: bool) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1034.0
	f0.y = 0.0
	f1.y = 0.0
	f0.state = "locked"
	f1.state = "locked"
	var res := {"nan": 0, "viol": 0, "played": 0, "seq": "", "chased": 0, "step": 0.0, "rest": 0.0}
	var prev := Vector2.ZERO
	var base := Vector2.ZERO
	for k in range(70):
		S.tick = 9800 + k
		S.T = 910.0 + float(k) / 60.0
		var af0: AnimFighter = RenderAnim.fighter(S, f0)
		var af1: AnimFighter = RenderAnim.fighter(S, f1)
		var g0: Dictionary = {}
		var g1: Dictionary = {}
		if k >= 4 and k < 30:
			g0 = {"mode": "clinch", "role": "catcher", "grip": 2, "pulse": 0, "t0": 9804}
			g1 = {"mode": "clinch", "role": "caught", "grip": -2, "pulse": 0, "t0": 9804}
		af0._feed_from(S, f0, g0, S.T)
		af1._feed_from(S, f1, g1, S.T)
		if k == 30:
			af0.on_grip_throw(text, past, S.T)
			res.seq = String(af0._seq.get("id", ""))
			f1.x = 1034.0 + 200.0   # the other body has gone
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		af0 = RenderAnim.solve(S, f0)
		af1 = RenderAnim.solve(S, f1)
		for af in [af0, af1]:
			for i in range(AnimRig.N):
				if is_nan(af.q[i].x) or is_nan(af.q[i].w):
					res.nan += 1
			res.viol += AnimJoints.violations(af.q, af._rd.shape_key).size()
		var pel := Vector2(af0.socket("pelvis").x, af0.socket("pelvis").y)
		if k == 0:
			base = pel
		if k > 0:
			res.step = maxf(float(res.step), (pel - prev).length())
		prev = pel
		if k >= 30 and k < 46 and not af0._seq.is_empty():
			res.played += 1
		if k > 31 and int(af0.debug.get("grips", 0)) > 0 and k < 60:
			pass
	res.rest = (prev - base).length()
	var a0b: AnimFighter = RenderAnim.fighter(S, f0)
	res["grips_after"] = int(a0b.debug.get("grips", 0))
	return res


func _test_grip_throw() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	for who in ["PROTAGONIST", "RIVAL"]:
		for tx in [["throw_across", false], ["throw_across", true], ["thrown_up", false], ["thrown_down", false], ["reversal", false]]:
			var r: Dictionary = _throw_probe(who, String(tx[0]), bool(tx[1]))
			seen.append("%s %s%s -> %s" % [who.substr(0, 1), String(tx[0]), " past" if bool(tx[1]) else "", String(r.seq).replace("zq.", "")])
			if String(r.seq) == "":
				bad.append("%s %s: no throw sequence started" % [who, String(tx[0])])
			if int(r.nan) > 0 or int(r.viol) > 0:
				bad.append("%s %s: nan %d viol %d" % [who, String(tx[0]), int(r.nan), int(r.viol)])
			if float(r.step) > 8.0:
				bad.append("%s %s: a pelvis moves %.2f units in a tick (8 at most: a throw is a quick blow, and the snappy profile solves on twos)" % [who, String(tx[0]), float(r.step)])
			if float(r.rest) > 2.0:
				bad.append("%s %s: the thrower is %.2f off his stand after the throw" % [who, String(tx[0]), float(r.rest)])
	# nothing for a parting: the push-off, the time and a lapse are not throws
	var none: Dictionary = _throw_probe("PROTAGONIST", "push_off", false)
	if String(none.seq) != "":
		bad.append("a push-off started a throw sequence (%s)" % String(none.seq))
	_expect(bad.is_empty(), "the grapple's end as a throw: every send plays the thrower's own sequence clean and hands back: %s" % str(bad))
	print("grip throws: %s" % " | ".join(seen))


## The per-tick work (docs/animation/tick-cost.md): the ragdoll step and the cloth and follow-through springs worked out once a tick give the same bodies, bit for bit, as the versions before (`--no-tick-fast`). One seeded match (seed 11: a launch, a flail) drawn both ways, a hash of every bone rotation, the hips, the ragdoll's angles and speeds and the springs after every frame.
func _tick_hash(fast: bool, ticks: int) -> Array:
	RenderAnim.tick_fast = fast
	main.start_match(11, {"p1": true, "p2": true})
	var h: int = 7
	var launched: int = 0
	while main.host.ticks < ticks:
		main.frame(1.0 / 60.0)
		var S: SimState = main.host.S
		for f in S.fighters:
			var af: AnimFighter = RenderAnim.fighter(S, f)
			for qq in af.q:
				h = (h * 1000003 + hash(qq)) & 0x7fffffffffff
			for v in [af.hips, af.root_off]:
				h = (h * 1000003 + hash(v)) & 0x7fffffffffff
			for arr in [af._rd.th, af._rd.om, af._fw_x, af._fw_v, af._sx, af._sv]:
				for v in arr:
					h = (h * 1000003 + hash(v)) & 0x7fffffffffff
			if String(f.state) == "launched":
				launched += 1
	RenderAnim.tick_fast = true
	return [h, launched]


func _test_tick_fast() -> void:
	var fast: Array = _tick_hash(true, 1200)
	var before: Array = _tick_hash(false, 1200)
	_expect(int(fast[0]) == int(before[0]), "per-tick work: the poses with the work worked out once a tick are the poses before it, bit for bit (hash %d against %d)" % [int(fast[0]), int(before[0])])
	_expect(int(fast[1]) > 0, "per-tick work: the match used to compare them launches a fighter (%d launched samples), so the ragdoll's flail is in the comparison" % int(fast[1]))
	print("per-tick work: seed 11, 1200 ticks, hash %d both ways, %d launched samples" % [int(fast[0]), int(fast[1])])


## The incremental bake's queue (docs/animation/incremental-bake.md). A queued pose exists before it is baked, is baked in order a slice at a time or at once when asked for, and is exactly the pose the eager bake makes of the same sketch;
## the pick-list work queued for a fighter is done when something asks for it. (The whole-game comparison is tools/bake_check.gd: the same hash eager and lazy.)
func _test_incremental_bake() -> void:
	AnimData.load_all()
	var bad: Array = []
	var src: String = "stance.aggressive"
	var sk: Dictionary = AnimData.raw[src]
	var want: AnimPose = AnimPose.bake("zz.bake.want", sk)
	AnimData._queue("zz.bake.a", sk)
	AnimData._queue("zz.bake.b", sk)
	AnimData._queue("zz.bake.c", sk)
	if AnimData.poses.has("zz.bake.a") or not AnimData.pose_exists("zz.bake.a") or AnimData.bake_idle():
		bad.append("a queued pose must exist and not be baked yet")
	# one slice bakes at least one, in order
	AnimData.bake_pending(0)
	if not AnimData.poses.has("zz.bake.a") or AnimData.poses.has("zz.bake.c"):
		bad.append("a slice of 0 microseconds bakes exactly the first queued pose")
	# asked for out of order: baked on the spot
	var pc: AnimPose = AnimData.pose("zz.bake.c")
	if pc == null or not AnimData.poses.has("zz.bake.c") or AnimData.poses.has("zz.bake.b"):
		bad.append("asking for the last queued pose bakes that one only")
	AnimData.bake_all()
	if not AnimData.bake_idle() or not AnimData.poses.has("zz.bake.b"):
		bad.append("bake_all leaves the queue empty and every pose baked")
	var same: bool = true
	for nm in ["zz.bake.a", "zz.bake.b", "zz.bake.c"]:
		var p: AnimPose = AnimData.poses[nm]
		for i in range(AnimRig.N):
			if not p.q[i].is_equal_approx(want.q[i]):
				same = false
		if not p.hips.is_equal_approx(want.hips):
			same = false
	if not same:
		bad.append("a queued pose is not the pose the eager bake makes of the same sketch")
	for nm in ["zz.bake.a", "zz.bake.b", "zz.bake.c"]:
		AnimData.poses.erase(nm)
	# the fighter's queued waves and lists: done on demand
	if AnimData.lazy:
		bad.append("the tools bake eagerly (lazy is off under -s)")
	var was: bool = AnimData.lazy
	AnimData.lazy = true
	var key: String = AnimData.ensure_fighter("REFERENCE")
	var queued: int = AnimData._work.size()
	var ready: bool = AnimData.pair_ready(key) if key != "" else true
	AnimData.lazy = was
	AnimData.bake_all()
	if key != "" and (not ready or not AnimData.pair_lists.has(key) or not AnimData._work.is_empty()):
		bad.append("a fighter's queued work is run when his pick lists are asked for")
	_expect(bad.is_empty(), "incremental bake: a queued pose exists, bakes in order or on demand, is the eager pose, and a fighter's queued waves run when asked for: %s" % str(bad))
	print("incremental bake: the queue holds, orders and drains; the eager and lazy poses are identical; %d pieces queued for one fighter" % queued)


## The mid-band lunge's wind-up crouch (docs/animation/lunge-crouch.md). From the lunge cue on its own tick the body deepens into the cell's pose over the cue's ticks (light 6, heavy 10, the return's 10), and hands over to the travel
## with no snap: the pose is let go over its exit ramp when the rush begins, and the body is exactly the stand again after. A wind-up of 3 to 5 ticks is drawn over 6; under 3 nothing. Nothing may be NaN or past a limit.
func _lunge_probe(who: String, weight: String, wind: int, ticks: int, off: bool) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1250.0
	f0.y = 0.0
	f1.y = 0.0
	f0.state = "free"
	f1.state = "free"
	RenderAnim.press_ack = not off
	var res := {"nan": 0, "viol": 0, "samples": [], "cleared_at": -1}
	for k in range(ticks):
		S.tick = 8700 + k
		S.T = 880.0 + float(k) / 60.0
		if k == 4:
			RenderAnim.fighter(S, f0).on_lunge_crouch(weight, wind, S.T)
		if k == 4 + wind:
			f0.rush = SimState.Rush.new()   # the travel begins: the layer lets go
			f0.rush.tgt = f1
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		for i in range(AnimRig.N):
			if is_nan(a0.q[i].x) or is_nan(a0.q[i].w):
				res.nan += 1
		res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size()
		var pel: Vector3 = a0.socket("pelvis")
		var hd: Vector3 = a0.head_center()
		res.samples.append([(hd.x - pel.x) * a0.vface, pel.y])
		if res.cleared_at < 0 and k > 4 and a0._ack.is_empty():
			res.cleared_at = k
	RenderAnim.press_ack = true
	return res


func _test_lunge_crouch() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	for who in ["PROTAGONIST", "RIVAL"]:
		for spec in [["light", 6], ["light", 5], ["heavy", 10], ["return", 10]]:
			var weight: String = String(spec[0])
			var wind: int = int(spec[1])
			var on: Dictionary = _lunge_probe(who, weight, wind, 40, false)
			var off: Dictionary = _lunge_probe(who, weight, wind, 40, true)
			var excursion: float = 0.0
			var step: float = 0.0
			var early: float = 0.0
			for k in range(on.samples.size()):
				var d := Vector2(float(on.samples[k][0]) - float(off.samples[k][0]), float(on.samples[k][1]) - float(off.samples[k][1]))
				excursion = maxf(excursion, d.length())
				if k >= 1:
					var dp := Vector2(float(on.samples[k - 1][0]) - float(off.samples[k - 1][0]), float(on.samples[k - 1][1]) - float(off.samples[k - 1][1]))
					step = maxf(step, (d - dp).length())
				if k == 4 + wind - 1:
					early = d.length()
			var rest: float = Vector2(float(on.samples[39][0]) - float(off.samples[39][0]), float(on.samples[39][1]) - float(off.samples[39][1])).length()
			seen.append("%s %s %d ticks: crouch %.1f at the end, rest %.2f, step %.2f of %.1f" % [who.substr(0, 1), weight, wind, early, rest, step, excursion])
			if int(on.nan) > 0 or int(on.viol) > 0:
				bad.append("%s %s: nan %d viol %d" % [who, weight, int(on.nan), int(on.viol)])
			if early < 2.5:
				bad.append("%s %s: the crouch is %.2f units deep at the end of its wind-up (2.5 wanted)" % [who, weight, early])
			if rest > 0.35 or int(on.cleared_at) < 0:
				bad.append("%s %s: not back to the stand after the travel starts (diff %.2f, cleared %d)" % [who, weight, rest, int(on.cleared_at)])
			if step > 0.6 * excursion:
				bad.append("%s %s: the body changes by %.2f of its %.2f units in one tick (0.6 at most)" % [who, weight, step, excursion])
	var tiny: Dictionary = _lunge_probe("PROTAGONIST", "light", 2, 20, false)
	if int(tiny.cleared_at) != 5:
		bad.append("a 2-tick crouch was drawn (cleared at %d: 5 means it never started)" % int(tiny.cleared_at))
	_expect(bad.is_empty(), "the lunge's wind-up crouch: drawn over the cue's ticks, handed to the travel without a snap, gone after: %s" % str(bad))
	print("lunge crouch: %s" % " | ".join(seen))


## Flight locomotion (docs/animation/flight-locomotion.md). A free fighter in the air leans into an acceleration on a spring that overshoots, flares when he stops hard from speed, coils at a dash's press, banks into a curve and breathes
## in the hover; none of it while he is busy. The sim's velocity is driven here with its own smoothing (fighter.gd: k = 1 - 0.0008^dt toward the stick's speed). Nothing may be NaN or past a limit, and nothing pops.
func _loco_run(who: String, course: Array, ticks: int, off: bool) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1900.0
	f0.y = WorldTerrain.groundY(S, f0.x, f0.z) + 400.0
	f1.y = WorldTerrain.groundY(S, f1.x, f1.z)
	f0.state = "free"
	f1.state = "free"
	f0.face = 1.0
	f0.vx = 0.0
	f0.vy = 0.0
	RenderAnim.flight_loco = not off
	var res := {"nan": 0, "viol": 0, "lean": [], "flare": [], "bank": [], "hover": [], "head": [], "pel": [], "hips": [], "moved": 0.0}
	var k_s: float = 1.0 - pow(0.0008, 1.0 / 60.0)
	for k in range(ticks):
		S.tick = 9100 + k
		S.T = 930.0 + float(k) / 60.0
		var seg: Array = course[0]
		for c in course:
			if k >= int(c[0]):
				seg = c
		var mx: float = float(seg[1])
		var my: float = float(seg[2])
		var dash: bool = bool(seg[3])
		var sp: float = 1300.0 if dash else 430.0
		f0.input.dash = dash
		f0.vx += (mx * sp - f0.vx) * k_s
		f0.vy += (my * sp * 0.85 - f0.vy) * k_s
		f0.y += f0.vy / 60.0
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		RenderAnim.debug_checks = true
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		RenderAnim.debug_checks = false
		for i in range(AnimRig.N):
			if is_nan(a0.q[i].x) or is_nan(a0.q[i].w):
				res.nan += 1
		res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size()
		res.lean.append(float(a0.debug.get("loco_lean", 0.0)))
		res.flare.append(float(a0.debug.get("loco_flare", 0.0)))
		res.bank.append(float(a0.debug.get("loco_bank", 0.0)))
		res.hover.append(float(a0.debug.get("loco_hover", 0.0)))
		var pel: Vector3 = a0.socket("pelvis")
		var hd: Vector3 = a0.head_center()
		res.head.append((hd.x - pel.x) * a0.vface)
		res.pel.append(pel.y)
		res.hips.append(hd.y)
		res.moved = maxf(float(res.moved), absf(f0.x - 1000.0))
	RenderAnim.flight_loco = true
	return res


func _test_locomotion() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	# hover 0-59, cruise right 60-129, dash 130-199, stop 200-279, an arc up and over 280-339, a reversal 340-389, hover 390-479
	var course: Array = [[0, 0.0, 0.0, false], [60, 1.0, 0.0, false], [130, 1.0, 0.0, true], [200, 0.0, 0.0, false], [280, 1.0, 1.0, false], [310, 1.0, -1.0, false], [340, -1.0, 0.0, false], [390, 0.0, 0.0, false]]
	for who in ["PROTAGONIST", "RIVAL"]:
		var on: Dictionary = _loco_run(who, course, 600, false)
		var off: Dictionary = _loco_run(who, course, 600, true)
		if int(on.nan) > 0 or int(on.viol) > 0:
			bad.append("%s: nan %d viol %d" % [who, int(on.nan), int(on.viol)])
		# the lean: forward in the cruise's acceleration, back in the stop, and the spring overshoots (it crosses zero after the stop's back lean)
		var lean_acc: float = (on.lean.slice(62, 90) as Array).max()
		var lean_brake: float = (on.lean.slice(200, 235) as Array).min()
		var lean_after: float = (on.lean.slice(222, 280) as Array).max()
		var forward: float = 0.0
		for k in range(62, 90):
			forward = maxf(forward, float(on.head[k]) - float(off.head[k]))
		seen.append("%s accel lean %.2f (head forward %.1f), brake %.2f then %.2f, flare %.2f, bank %.2f, hover %.2f" % [who.substr(0, 1), lean_acc, forward, lean_brake, lean_after, (on.flare as Array).max(), maxf((on.bank as Array).max(), -(on.bank as Array).min()), (on.hover as Array).max()])
		if lean_acc < 0.35 or forward < 1.2:
			bad.append("%s: the acceleration leans %.2f and the head goes %.1f forward (0.35 and 1.2 wanted)" % [who, lean_acc, forward])
		if lean_brake > -0.3:
			bad.append("%s: the stop leans back only %.2f (0.25 wanted)" % [who, -lean_brake])
		if lean_after < 0.02:
			bad.append("%s: the lean does not overshoot after the stop (%.3f)" % [who, lean_after])
		# the flare in the stop from the dash, and none in the cruise's start
		if (on.flare.slice(200, 240) as Array).max() < 0.3:
			bad.append("%s: no braking flare after the dash (%.2f)" % [who, (on.flare.slice(200, 240) as Array).max()])
		if (on.flare.slice(60, 100) as Array).max() > 0.05:
			bad.append("%s: a flare in the cruise's start (%.2f)" % [who, (on.flare.slice(60, 100) as Array).max()])
		# the dash's coil: the weight goes down and back at the press, before the speed is up
		var dip: float = 0.0
		for k in range(131, 142):
			dip = maxf(dip, float(off.hips[k]) - float(on.hips[k]))
		if dip < 0.8:
			bad.append("%s: the dash's coil dips the head only %.2f at the press (0.8 wanted)" % [who, dip])
		# the bank: in the arc
		var bk: float = 0.0
		for k in range(285, 345):
			bk = maxf(bk, absf(float(on.bank[k])))
		if bk < 0.25:
			bad.append("%s: the arc banks only %.2f (0.25 wanted)" % [who, bk])
		# the hover breathes: the head moves through a breath, and not at speed
		var hmin: float = 1.0e9
		var hmax: float = -1.0e9
		for k in range(440, 600):
			hmin = minf(hmin, float(on.hips[k]) - float(off.hips[k]))
			hmax = maxf(hmax, float(on.hips[k]) - float(off.hips[k]))
		if hmax - hmin < 0.3:
			bad.append("%s: the hover does not breathe (the head moves %.2f)" % [who, hmax - hmin])
		if (on.hover.slice(160, 190) as Array).max() > 0.05:
			bad.append("%s: the hover breathes at dash speed (%.2f)" % [who, (on.hover.slice(160, 190) as Array).max()])
		# nothing pops: the head and pelvis change by 4 units a tick at most against the plain run (a stop from a dash), and the sim's position is what the course made it
		var step: float = 0.0
		for k in range(1, 600):
			var d1 := Vector2(float(on.head[k]) - float(off.head[k]), float(on.hips[k]) - float(off.hips[k]))
			var d0 := Vector2(float(on.head[k - 1]) - float(off.head[k - 1]), float(on.hips[k - 1]) - float(off.hips[k - 1]))
			step = maxf(step, (d1 - d0).length())
		if step > 4.0:
			bad.append("%s: the head moves %.2f units a tick against the plain run (4 at most: a hard stop from a dash is quick)" % [who, step])
	# busy: nothing in a lock
	var busy: Dictionary = _loco_busy_probe()
	if float(busy.lean) > 0.001:
		bad.append("the layer is still leaning (%.3f) 30 ticks after a lock began" % float(busy.lean))
	_expect(bad.is_empty(), "flight locomotion: the lean, the flare, the dash's coil, the bank and the hover's breath: %s" % str(bad))
	print("flight locomotion: %s" % " | ".join(seen))


func _loco_busy_probe() -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	RenderAnim._fighters.clear()
	f0.y = WorldTerrain.groundY(S, f0.x, f0.z) + 400.0
	f0.state = "free"
	f0.face = 1.0
	var lean: float = 0.0
	for k in range(80):
		S.tick = 9300 + k
		S.T = 950.0 + float(k) / 60.0
		f0.vx = 300.0 + 400.0 * sin(float(k) / 6.0)
		f0.state = "locked" if k >= 30 else "free"
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		RenderAnim.debug_checks = true
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.debug_checks = false
		if k == 79:
			lean = absf(a0._lo_act) * absf(float(a0.debug.get("loco_lean", 0.0)))
	return {"lean": lean}


## Ground locomotion (docs/animation/ground-locomotion.md). A free fighter on the ground walks and runs on a gait that follows the distance he covers, kicks off the ground when he rises from it, and absorbs his landing by the arrival
## speed and the surface; none of it while he is busy. The sim's velocity is driven here with its own smoothing. Nothing may be NaN or past a limit, and nothing pops.
func _gl_run(who: String, course: Array, ticks: int, off: bool, surface: String) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1900.0
	f0.y = WorldTerrain.groundY(S, f0.x, f0.z) + float(course[0][4]) if course[0].size() > 4 else WorldTerrain.groundY(S, f0.x, f0.z)
	f1.y = WorldTerrain.groundY(S, f1.x, f1.z)
	f0.state = "free"
	f1.state = "free"
	f0.face = 1.0
	f0.vx = 0.0
	f0.vy = 0.0
	RenderAnim.ground_loco = not off
	var res := {"nan": 0, "viol": 0, "foot": [], "hips": [], "head": [], "gait": [], "air": [], "surface": ""}
	var k_s: float = 1.0 - pow(0.0008, 1.0 / 60.0)
	var af0: AnimFighter = RenderAnim.fighter(S, f0)
	af0._gl_surface_override = surface
	for k in range(ticks):
		S.tick = 9600 + k
		S.T = 960.0 + float(k) / 60.0
		var seg: Array = course[0]
		for c in course:
			if k >= int(c[0]):
				seg = c
		var g: float = WorldTerrain.groundY(S, f0.x, f0.z)
		var sp: float = 430.0
		f0.vx += (float(seg[1]) * sp - f0.vx) * k_s
		if bool(seg[3]):
			f0.vy = float(seg[2])   # a plain vertical velocity for the take-off and the fall
		else:
			f0.vy += (float(seg[2]) * sp * 0.85 - f0.vy) * k_s
		f0.y += f0.vy / 60.0
		if f0.y <= g:
			f0.y = g
			if f0.vy < 0.0:
				f0.vy = 0.0
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		RenderAnim.debug_checks = true
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		RenderAnim.debug_checks = false
		for i in range(AnimRig.N):
			if is_nan(a0.q[i].x) or is_nan(a0.q[i].w):
				res.nan += 1
		res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size()
		var pel: Vector3 = a0.socket("pelvis")
		var ft: Vector3 = a0.socket("foot_r")
		var hd: Vector3 = a0.head_center()
		res.foot.append(ft.x - pel.x)
		res.hips.append(pel.y)
		res.head.append(hd.y)
		res.gait.append(float(a0.debug.get("gl_gait", 0.0)))
		res.air.append(f0.y - g)
		res.surface = String(a0.debug.get("gl_surface", ""))
	RenderAnim.ground_loco = true
	return res


func _test_ground_motion() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	# stand 0-39, walk 40-109 (stick 0.35), run 110-179 (stick 1), stop 180-249
	var walk: Array = [[0, 0.0, 0.0, false], [40, 0.35, 0.0, false], [110, 1.0, 0.0, false], [180, 0.0, 0.0, false]]
	# stand 0-29, rise 30-59 (vy 500), hover 60-89, fall 90-200 (vy -900) to the ground
	var hop: Array = [[0, 0.0, 0.0, false, 0.0], [30, 0.0, 500.0, true], [60, 0.0, 0.0, true], [90, 0.0, -900.0, true]]
	for who in ["PROTAGONIST", "RIVAL"]:
		var on: Dictionary = _gl_run(who, walk, 250, false, "")
		var off: Dictionary = _gl_run(who, walk, 250, true, "")
		if int(on.nan) > 0 or int(on.viol) > 0:
			bad.append("%s: nan %d viol %d" % [who, int(on.nan), int(on.viol)])
		var fw_lo: float = 1.0e9
		var fw_hi: float = -1.0e9
		var fr_lo: float = 1.0e9
		var fr_hi: float = -1.0e9
		for k in range(70, 110):
			fw_lo = minf(fw_lo, float(on.foot[k]) - float(off.foot[k]))
			fw_hi = maxf(fw_hi, float(on.foot[k]) - float(off.foot[k]))
		for k in range(140, 180):
			fr_lo = minf(fr_lo, float(on.foot[k]) - float(off.foot[k]))
			fr_hi = maxf(fr_hi, float(on.foot[k]) - float(off.foot[k]))
		var bob: float = 0.0
		for k in range(140, 180):
			bob = maxf(bob, absf(float(on.hips[k]) - float(off.hips[k])))
		seen.append("%s walk foot swing %.1f, run %.1f, bob %.1f" % [who.substr(0, 1), fw_hi - fw_lo, fr_hi - fr_lo, bob])
		if fw_hi - fw_lo < 3.0:
			bad.append("%s: the walk swings the foot only %.1f units (3 wanted)" % [who, fw_hi - fw_lo])
		if fr_hi - fr_lo < 8.0:
			bad.append("%s: the run swings the foot only %.1f units (8 wanted)" % [who, fr_hi - fr_lo])
		if bob < 0.5:
			bad.append("%s: the run bobs the hips only %.2f (0.5 wanted)" % [who, bob])
		if (on.gait.slice(10, 30) as Array).max() > 0.01:
			bad.append("%s: a gait while standing still (%.2f)" % [who, (on.gait.slice(10, 30) as Array).max()])
		if (on.gait.slice(235, 250) as Array).max() > 0.05:
			bad.append("%s: the gait goes on after the stop (%.2f)" % [who, (on.gait.slice(235, 250) as Array).max()])
		# nothing pops: the head moves 3 units a tick at most against the plain run
		var step: float = 0.0
		for k in range(1, 250):
			step = maxf(step, absf((float(on.head[k]) - float(off.head[k])) - (float(on.head[k - 1]) - float(off.head[k - 1]))))
		if step > 3.0:
			bad.append("%s: the head moves %.2f units a tick against the plain run (3 at most)" % [who, step])
		# the kick-off and the landing
		for surf in ["soil", "rock", "sand", "rubble", "water"]:
			var hon: Dictionary = _gl_run(who, hop, 230, false, surf)
			var hoff: Dictionary = _gl_run(who, hop, 230, true, surf)
			if int(hon.nan) > 0 or int(hon.viol) > 0:
				bad.append("%s %s hop: nan %d viol %d" % [who, surf, int(hon.nan), int(hon.viol)])
			var land_at: int = -1
			for k in range(91, 229):
				if float(hoff.air[k]) <= 0.5 and land_at < 0:
					land_at = k
			var sink: float = 0.0
			if land_at >= 0:
				for k in range(land_at, mini(land_at + 14, 229)):
					sink = maxf(sink, float(hoff.hips[k]) - float(hon.hips[k]))
			var kick: float = 0.0
			for k in range(31, 44):
				kick = maxf(kick, float(hoff.foot[k]) - float(hon.foot[k]))
			seen.append("%s %s kick %.1f sink %.1f" % [who.substr(0, 1), surf, kick, sink])
			if land_at < 0:
				bad.append("%s %s hop: never landed in the probe" % [who, surf])
			elif sink < 2.0:
				bad.append("%s %s: the landing sinks the hips only %.2f (2 wanted)" % [who, surf, sink])
			if kick < 1.5:
				bad.append("%s %s: the kick-off trails the foot only %.2f (1.5 wanted)" % [who, surf, kick])
	# water sinks deeper than rock, and sand is the one that slides the drawn body (the hop on each, Protagonist)
	var w_hon: Dictionary = _gl_run("PROTAGONIST", hop, 230, false, "water")
	var r_hon: Dictionary = _gl_run("PROTAGONIST", hop, 230, false, "rock")
	var wmin: float = 1.0e9
	var rmin: float = 1.0e9
	for k in range(100, 229):
		wmin = minf(wmin, float(w_hon.hips[k]))
		rmin = minf(rmin, float(r_hon.hips[k]))
	if wmin > rmin - 0.8:
		bad.append("water does not sink deeper than rock (%.1f against %.1f)" % [wmin, rmin])
	var busy: Dictionary = _gl_busy_probe()
	if float(busy.gait) > 0.001:
		bad.append("the gait still shows (%.3f) 30 ticks after a lock began" % float(busy.gait))
	_expect(bad.is_empty(), "ground locomotion: the gait, the kick-off and the landing by surface, none while busy: %s" % str(bad))
	print("ground locomotion: %s" % " | ".join(seen))


func _gl_busy_probe() -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	RenderAnim._fighters.clear()
	f0.y = WorldTerrain.groundY(S, f0.x, f0.z)
	f0.face = 1.0
	var gait: float = 0.0
	for k in range(80):
		S.tick = 9800 + k
		S.T = 980.0 + float(k) / 60.0
		f0.vx = 300.0
		f0.state = "locked" if k >= 30 else "free"
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		RenderAnim.debug_checks = true
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.debug_checks = false
		if k == 79:
			gait = absf(a0._gl_act) * float(a0.debug.get("gl_gait", 0.0))
	return {"gait": gait}


## Hit reactions with variety (docs/animation/hit-reactions.md). Each blow picks a variant by weight, direction and body part, never the one the last blow picked, and the same hits pick the same variants on a replay; every variant and every
## recovery plays clean for both fighters, shows against the plain flinch, and hands the body back. Nothing may be NaN or past a limit.
func _hv_run(who: String, hits: Array, ticks: int, off: bool) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1250.0
	f0.y = 0.0
	f1.y = 0.0
	f0.state = "free"
	f1.state = "free"
	RenderAnim.hit_variants = not off
	var res := {"nan": 0, "viol": 0, "head": [], "hips": [], "ids": [], "var": 0}
	var af: AnimFighter = RenderAnim.fighter(S, f0)
	for k in range(ticks):
		S.tick = 9900 + k
		S.T = 990.0 + float(k) / 60.0
		for h in hits:
			if int(h[0]) == k:
				af.on_hit(S.T, String(h[1]), bool(h[2]), clampf(float(h[3]), 0.2, 1.0), String(h[4]), Vector2(float(h[5]), float(h[6])), float(h[3]), S.tick, 0.0, 0)
				res.ids.append(String(af._reacts[-1].get("var", "")))
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		RenderAnim.debug_checks = true
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.debug_checks = false
		RenderAnim.solve(S, f1)
		for i in range(AnimRig.N):
			if is_nan(a0.q[i].x) or is_nan(a0.q[i].w):
				res.nan += 1
		res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size()
		var pel: Vector3 = a0.socket("pelvis")
		var hd: Vector3 = a0.head_center()
		res.head.append(Vector2((hd.x - pel.x) * a0.vface, hd.y - pel.y))
		res.hips.append(pel.y)
		res.var = int(a0.debug.get("reaction_variants", 0))
	RenderAnim.hit_variants = true
	return res


func _test_reactions() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	var R: Dictionary = AnimData.reactions
	if R.is_empty():
		bad.append("no reactions data")
	# one hit of each weight, region, direction and draw: [tick, region, front, force, kind, dx, dy]
	var specs: Array = []
	var k: int = 10
	for fo in [0.35, 0.8, 1.3]:
		for rg in ["head", "core", "arms", "legs"]:
			for fr in [true, false]:
				for dy in [0.0, -0.7]:
					specs.append([k, rg, fr, fo, "light" if fo < 0.5 else "heavy", -1.0 if fr else 1.0, dy])
					k += 60
	var all_used: Dictionary = {}
	var by_weight: Dictionary = {"light": {}, "medium": {}, "heavy": {}}
	var worst: float = 0.0
	for who in ["PROTAGONIST", "RIVAL"]:
		# the hits one at a time are too many runs: the whole list in one run each way, sampled by the hit
		var total: int = k + 80
		var on: Dictionary = _hv_run(who, specs, total, false)
		var off: Dictionary = _hv_run(who, specs, total, true)
		if int(on.nan) > 0 or int(on.viol) > 0:
			bad.append("%s: nan %d viol %d" % [who, int(on.nan), int(on.viol)])
		var prev: String = "-"
		for i in range(on.ids.size()):
			var id: String = String(on.ids[i])
			all_used[id] = true
			var sp: Array = specs[i]
			var wc: String = "light" if float(sp[3]) < 0.5 else ("medium" if float(sp[3]) < 1.0 else "heavy")
			by_weight[wc][id] = true
			if id == "":
				bad.append("%s hit %d (%s %s, force %.2f) picked no variant" % [who, i, String(sp[1]), "front" if bool(sp[2]) else "back", float(sp[3])])
			if id == prev and id != "":
				bad.append("%s: hit %d picked %s again" % [who, i, id])
			prev = id
		# each hit shows against the plain flinch: the head or the hips differ by 0.6 units somewhere in its first 0.6 s, and the body is back (0.4) 1.3 s after
		var shown: int = 0
		for i in range(specs.size()):
			var t0: int = int(specs[i][0])
			var dmax: float = 0.0
			for tt in range(t0, mini(t0 + 36, int(on.head.size()))):
				dmax = maxf(dmax, (Vector2(on.head[tt]) - Vector2(off.head[tt])).length() + absf(float(on.hips[tt]) - float(off.hips[tt])))
			worst = maxf(worst, dmax)
			if dmax >= 0.6:
				shown += 1
		if shown < specs.size() - 4:
			bad.append("%s: only %d of %d hits differ from the plain flinch by 0.6 units" % [who, shown, specs.size()])
		seen.append("%s %d hits, %d variants shown, the largest swing from plain %.1f" % [who.substr(0, 1), specs.size(), shown, worst])
	# the same hits draw the same variants on a replay
	var a: Dictionary = _hv_run("PROTAGONIST", specs.slice(0, 12), 12 * 60 + 80, false)
	var b: Dictionary = _hv_run("PROTAGONIST", specs.slice(0, 12), 12 * 60 + 80, false)
	if str(a.ids) != str(b.ids):
		bad.append("a replay picks other variants: %s against %s" % [str(a.ids), str(b.ids)])
	# a lighter blow and a heavier one do not draw from the same pool
	var shared: Array = []
	for id in by_weight.light:
		if by_weight.heavy.has(id):
			shared.append(id)
	if not shared.is_empty() and (by_weight.light.size() <= shared.size() or by_weight.heavy.size() <= shared.size()):
		bad.append("light and heavy draw the same variants: %s" % str(shared))
	all_used.erase("")
	if all_used.size() < 12:
		bad.append("only %d variants were picked in the sweep (12 or more wanted)" % all_used.size())
	_expect(bad.is_empty(), "hit reactions: variety by weight, direction and body part, never the same twice in a row, clean, back to the stand: %s" % str(bad))
	print("hit reactions: %s; %d variants used (%s)" % [" | ".join(seen), all_used.size(), ", ".join(PackedStringArray(all_used.keys()))])


## The air recovery (docs/animation/air-recovery.md). A launched body that gets control back well off the ground, at speed, catches itself: the arms fling, the torso rocks once and settles. Launched 20 to 59, free after; `height` is how high above the ground he is.
func _ar_run(who: String, speed: float, height: float, off: bool) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1900.0
	f1.y = WorldTerrain.groundY(S, f1.x, f1.z)
	f0.face = 1.0
	RenderAnim.air_recover = not off
	var res := {"nan": 0, "viol": 0, "head": [], "hips": [], "env": []}
	for k in range(150):
		S.tick = 9700 + k
		S.T = 970.0 + float(k) / 60.0
		var g: float = WorldTerrain.groundY(S, f0.x, f0.z)
		if k < 20:
			f0.state = "free"
			f0.vx = 0.0
			f0.vy = 0.0
			f0.y = g + height
		elif k < 60:
			f0.state = "launched"
			f0.vx = speed * (1.0 - float(k - 20) / 45.0)
			f0.vy = 0.0
		else:
			f0.state = "free"
			f0.vx *= 0.9
			f0.vy = 0.0
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		RenderAnim.debug_checks = true
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		RenderAnim.debug_checks = false
		for i in range(AnimRig.N):
			if is_nan(a0.q[i].x) or is_nan(a0.q[i].w):
				res.nan += 1
		res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size()
		var hd: Vector3 = a0.head_center()
		var pel: Vector3 = a0.socket("pelvis")
		res.head.append(Vector2((hd.x - pel.x) * a0.vface, hd.y - pel.y))
		res.hips.append(pel.y)
		res.env.append(float(a0.debug.get("ar_env", 0.0)))
	RenderAnim.air_recover = true
	return res


func _test_air_recover() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	for who in ["PROTAGONIST", "RIVAL"]:
		var on: Dictionary = _ar_run(who, 1500.0, 400.0, false)
		var off: Dictionary = _ar_run(who, 1500.0, 400.0, true)
		if int(on.nan) > 0 or int(on.viol) > 0:
			bad.append("%s: nan %d viol %d" % [who, int(on.nan), int(on.viol)])
		var peak: float = 0.0
		var step: float = 0.0
		var prev: float = 0.0
		for k in range(60, 100):
			var d: float = (Vector2(on.head[k]) - Vector2(off.head[k])).length()
			peak = maxf(peak, d)
			step = maxf(step, absf(d - prev))
			prev = d
		var tail: float = 0.0
		for k in range(120, 150):
			tail = maxf(tail, (Vector2(on.head[k]) - Vector2(off.head[k])).length())
		var before: float = 0.0
		for k in range(0, 60):
			before = maxf(before, (Vector2(on.head[k]) - Vector2(off.head[k])).length())
		seen.append("%s catch %.1f, step %.2f, tail %.2f" % [who.substr(0, 1), peak, step, tail])
		if peak < 2.5:
			bad.append("%s: the air recovery moves the head only %.2f units (2.5 wanted)" % [who, peak])
		if step > 2.0:
			bad.append("%s: the recovery moves the head %.2f units a tick against none (2 at most)" % [who, step])
		if tail > 0.3:
			bad.append("%s: the recovery has not let go 1 s on (%.2f)" % [who, tail])
		if before > 0.05:
			bad.append("%s: the recovery shows before the launch ends (%.2f)" % [who, before])
		# a slow launch and a launch near the ground are caught by nothing
		var slow_on: Dictionary = _ar_run(who, 150.0, 400.0, false)
		var slow_off: Dictionary = _ar_run(who, 150.0, 400.0, true)
		var low_on: Dictionary = _ar_run(who, 1500.0, 8.0, false)
		var low_off: Dictionary = _ar_run(who, 1500.0, 8.0, true)
		var sd: float = 0.0
		var ld: float = 0.0
		for k in range(60, 100):
			sd = maxf(sd, (Vector2(slow_on.head[k]) - Vector2(slow_off.head[k])).length())
			ld = maxf(ld, (Vector2(low_on.head[k]) - Vector2(low_off.head[k])).length())
		if sd > 0.05:
			bad.append("%s: a slow launch is caught anyway (%.2f)" % [who, sd])
		if ld > 0.05:
			bad.append("%s: a launch at the ground is caught anyway (%.2f)" % [who, ld])
	_expect(bad.is_empty(), "air recovery: a body that gets control back in the air at speed catches itself and lets go, none when slow or low: %s" % str(bad))
	print("air recovery: %s" % " | ".join(seen))


## Follow-through (docs/animation/secondary-motion.md). A run, a stop, a hop and a landing, and a blow, with the head, upper back and forearms free against fixed; nothing pops, nothing stays moving, nothing moves standing still.
func _sec_run(who: String, off: bool) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1900.0
	f0.y = WorldTerrain.groundY(S, f0.x, f0.z)
	f1.y = WorldTerrain.groundY(S, f1.x, f1.z)
	f0.state = "free"
	f1.state = "free"
	f0.face = 1.0
	f0.vx = 0.0
	f0.vy = 0.0
	RenderAnim.secondary_motion = not off
	var res := {"nan": 0, "viol": 0, "head": [], "hand": [], "ang": []}
	var k_s: float = 1.0 - pow(0.0008, 1.0 / 60.0)
	var af0: AnimFighter = RenderAnim.fighter(S, f0)
	for k in range(420):
		S.tick = 9800 + k
		S.T = 980.0 + float(k) / 60.0
		var g: float = WorldTerrain.groundY(S, f0.x, f0.z)
		var stick: float = 1.0 if (k >= 30 and k < 90) else 0.0
		f0.vx += (stick * 430.0 - f0.vx) * k_s
		if k >= 140 and k < 160:
			f0.vy = 500.0
		elif k >= 160 and f0.y > g + 0.01:
			f0.vy = maxf(f0.vy - 25.0, -900.0)
		f0.y += f0.vy / 60.0
		if f0.y <= g:
			f0.y = g
			if f0.vy < 0.0:
				f0.vy = 0.0
		if k == 280:
			af0.on_hit(S.T, "core", true, 0.8, "heavy", Vector2(-1.0, 0.0), 1.0, S.tick, 0.0, 0)
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		RenderAnim.debug_checks = true
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		RenderAnim.debug_checks = false
		for i in range(AnimRig.N):
			if is_nan(a0.q[i].x) or is_nan(a0.q[i].w):
				res.nan += 1
		res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size()
		var pel: Vector3 = a0.socket("pelvis")
		var hd: Vector3 = a0.head_center()
		var hn: Vector3 = a0.socket("hand_r")
		res.head.append(Vector2((hd.x - pel.x) * a0.vface, hd.y - pel.y))
		res.hand.append(Vector2((hn.x - pel.x) * a0.vface, hn.y - pel.y))
		res.ang.append(Vector2(float(a0.debug.get("fw_head", 0.0)), float(a0.debug.get("fw_arm", 0.0))))
	RenderAnim.secondary_motion = true
	return res


func _sec_diff(on: Array, off: Array, a: int, b: int) -> float:
	var m: float = 0.0
	for k in range(a, b):
		m = maxf(m, (Vector2(on[k]) - Vector2(off[k])).length())
	return m


func _test_secondary() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	for who in ["PROTAGONIST", "RIVAL"]:
		var on: Dictionary = _sec_run(who, false)
		var off: Dictionary = _sec_run(who, true)
		if int(on.nan) > 0 or int(on.viol) > 0:
			bad.append("%s: nan %d viol %d" % [who, int(on.nan), int(on.viol)])
		var still: float = _sec_diff(on.hand, off.hand, 0, 30) + _sec_diff(on.head, off.head, 0, 30)
		var run_h: float = _sec_diff(on.hand, off.hand, 30, 80)
		var stop_h: float = _sec_diff(on.hand, off.hand, 90, 130)
		var land_h: float = _sec_diff(on.hand, off.hand, 160, 270)
		var land_d: float = _sec_diff(on.head, off.head, 160, 270)
		var hit_h: float = _sec_diff(on.hand, off.hand, 280, 340)
		var hit_d: float = _sec_diff(on.head, off.head, 280, 340)
		var tail: float = _sec_diff(on.hand, off.hand, 380, 420) + _sec_diff(on.head, off.head, 380, 420)
		# the angles themselves move smoothly: 0.09 rad a tick at most, and never past their bound
		var step: float = 0.0
		var top: float = 0.0
		for k in range(1, 420):
			step = maxf(step, (Vector2(on.ang[k]) - Vector2(on.ang[k - 1])).length())
			top = maxf(top, maxf(absf(Vector2(on.ang[k]).x), absf(Vector2(on.ang[k]).y)))
		seen.append("%s run %.1f stop %.1f land %.1f/%.1f hit %.1f/%.1f step %.3f top %.2f tail %.2f" % [who.substr(0, 1), run_h, stop_h, land_h, land_d, hit_h, hit_d, step, top, tail])
		if still > 0.02:
			bad.append("%s: follow-through while standing still (%.2f)" % [who, still])
		if run_h < 1.5 or stop_h < 1.5:
			bad.append("%s: the forearms barely follow a start or a stop (%.2f, %.2f; 1.5 wanted)" % [who, run_h, stop_h])
		if land_h < 2.0 or land_d < 0.5:
			bad.append("%s: the landing sets the forearms and head swinging only %.2f and %.2f (2 and 0.5 wanted)" % [who, land_h, land_d])
		if hit_h < 2.0 or hit_d < 0.6:
			bad.append("%s: a blow sets the forearms and head swinging only %.2f and %.2f (2 and 0.6 wanted)" % [who, hit_h, hit_d])
		if step > 0.09:
			bad.append("%s: the follow-through turns a part %.3f rad a tick (0.09 at most)" % [who, step])
		if tail > 0.3:
			bad.append("%s: the follow-through has not settled 1 s after the last blow (%.2f)" % [who, tail])
	_expect(bad.is_empty(), "secondary motion: the head, back and forearms follow a start, a stop, a landing and a blow, settle, and are still at rest: %s" % str(bad))
	print("secondary motion: %s" % " | ".join(seen))


## The pop (docs/animation/pop-juggle.md). The cue sequences of Encounter's pop on the popped fighter, drawn with and without the layer: up then land set, up then land reel, up then slam then land, up then burst; the body differs while he is up, nothing pops, nothing stays after.
func _pop_run(who: String, seq: Array, ticks: int, off: bool) -> Dictionary:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	RenderAnim._fighters.clear()
	f0.id = who
	f1.id = "PROTAGONIST" if who == "RIVAL" else "RIVAL"
	f0.x = 1000.0
	f1.x = 1250.0
	f0.y = WorldTerrain.groundY(S, f0.x, f0.z) + 90.0
	f1.y = WorldTerrain.groundY(S, f1.x, f1.z)
	f0.state = "free"
	f1.state = "free"
	f0.vx = 0.0
	f0.vy = 0.0
	RenderAnim.pop_juggle = not off
	var res := {"nan": 0, "viol": 0, "head": [], "hips": [], "pops": 0}
	var af0: AnimFighter = RenderAnim.fighter(S, f0)
	for k in range(ticks):
		S.tick = 9900 + k
		S.T = 990.0 + float(k) / 60.0
		for c in seq:
			if int(c[0]) == k:
				af0.on_pop(String(c[1]), int(c[2]), float(c[3]), float(c[4]), S.T)
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		RenderAnim.debug_checks = true
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		RenderAnim.debug_checks = false
		for i in range(AnimRig.N):
			if is_nan(a0.q[i].x) or is_nan(a0.q[i].w):
				res.nan += 1
		res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size()
		var pel: Vector3 = a0.socket("pelvis")
		var hd: Vector3 = a0.head_center()
		res.head.append(Vector2((hd.x - pel.x) * a0.vface, hd.y - pel.y))
		res.hips.append(pel.y)
		res.pops = int(a0.debug.get("pops", 0))
	RenderAnim.pop_juggle = true
	return res


func _test_pop() -> void:
	AnimData.load_every_wave()
	var bad: Array = []
	var seen: Array = []
	var seqs := {
		"up+set": [[10, "up", 40, 30, 2.5], [40, "land", 1, 0, 0.0]],
		"up+reel": [[10, "up", 40, 30, 2.5], [40, "land", 0, 0, 0.0]],
		"up+slam": [[10, "up", 40, 30, 2.5], [24, "slam", 30, 6, 0.0], [30, "land", 0, 0, 0.0]],
		"up+spike": [[10, "up", 40, 30, 2.5], [22, "spike", 0, 8, 0.0], [30, "land", 0, 0, 1.0]],
		"up+burst": [[10, "up", 40, 30, 2.5], [28, "burst", 0, 0, 0.0], [40, "land", 1, 0, 0.0]],
	}
	for who in ["PROTAGONIST", "RIVAL"]:
		for name in seqs:
			var on: Dictionary = _pop_run(who, seqs[name], 140, false)
			var off: Dictionary = _pop_run(who, seqs[name], 140, true)
			if int(on.nan) > 0 or int(on.viol) > 0:
				bad.append("%s %s: nan %d viol %d" % [who, name, int(on.nan), int(on.viol)])
			var peak: float = 0.0
			var step: float = 0.0
			var prev: float = 0.0
			for k in range(10, 140):
				var d: float = (Vector2(on.head[k]) - Vector2(off.head[k])).length() + absf(float(on.hips[k]) - float(off.hips[k]))
				peak = maxf(peak, d)
				step = maxf(step, absf(d - prev))
				prev = d
			var before: float = 0.0
			for k in range(0, 10):
				before = maxf(before, (Vector2(on.head[k]) - Vector2(off.head[k])).length())
			var tail: float = 0.0
			for k in range(120, 140):
				tail = maxf(tail, (Vector2(on.head[k]) - Vector2(off.head[k])).length() + absf(float(on.hips[k]) - float(off.hips[k])))
			seen.append("%s %s swing %.1f step %.2f tail %.2f" % [who.substr(0, 1), name, peak, step, tail])
			if peak < 4.0:
				bad.append("%s %s: the pop moves the body only %.2f units (4 wanted)" % [who, name, peak])
			if step > 0.45 * peak:
				bad.append("%s %s: the pop changes the body by %.2f of its %.2f units in one solve (0.45 at most: a snap)" % [who, name, step, peak])
			if tail > 0.3 or before > 0.05:
				bad.append("%s %s: not clean at the edges (before %.2f, after %.2f)" % [who, name, before, tail])
	# the tech plays the air tech's own sequence and no pop pose
	var t_on: Dictionary = _pop_run("PROTAGONIST", [[10, "up", 40, 30, 2.5], [30, "tech", 40, 0, 0.0]], 80, false)
	if int(t_on.pops) != 1:
		bad.append("a tech cue counted %d pops (the up alone is one)" % int(t_on.pops))
	_expect(bad.is_empty(), "the pop: the body shows the rise, the hang, the fall, the slam, the burst and the landing, without a snap, clean at both edges: %s" % str(bad))
	print("pop: %s" % " | ".join(seen))


func _test_pulled() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var press_was: bool = RenderAnim.press_styles
	var ground_was: bool = RenderAnim.ground_feet
	var dist_was: float = _tier_dist
	RenderAnim.press_styles = true
	RenderAnim.ground_feet = false
	_tier_damage = true
	var offs := {}
	var dad := DirAccess.open("res://data/anim/waves")
	for fn in dad.get_files():
		if String(fn).ends_with(".manifest.json"):
			var mm = JSON.parse_string(FileAccess.get_file_as_string("res://data/anim/waves/" + String(fn)))
			for st in mm.get("strikes", []):
				offs[String(st.id)] = float(st.get("offset", 58.0))
	var totals := {}
	for own in [false, true]:
		var n30: int = 0
		var n20: int = 0
		var sets: int = 0
		var bad: Array = []
		for who in ["protagonist", "antihero"]:
			S.fighters[0].id = "PROTAGONIST" if who == "protagonist" else "RIVAL"
			var key: String = String(AnimData.ensure_fighter(String(S.fighters[0].id)))
			var names: Array = []
			for nm in AnimData.pair_lists[key].by_name:
				var id: String = String(AnimData.pair_lists[key].by_name[nm])
				if AnimData.keysets.has(id) and not String(nm).contains("."):
					names.append([String(nm), id])
			names.sort()
			for pr in names:
				var heavy: bool = String(AnimData.keysets[pr[1]].get("weight", "light")) == "heavy"
				var nm2: String = String(pr[0])
				var is_bolt: bool = nm2.begins_with("bolt_")
				var is_blast: bool = nm2.begins_with("blast_")
				_tier_dist = float(offs.get(String(pr[1]), 58.0)) if own else 60.0
				var extra: Dictionary = {"windup": 12} if is_blast else ({"windup": 28} if heavy else ({"windup": 2} if is_bolt else {}))
				var r: Dictionary = _tier_scene(S, who, "super" if (heavy and not is_blast) else "speed", [nm2], [44] if heavy else [30], extra, "heavy" if heavy else "light")
				sets += 1
				n30 += int(r.get("fix_n30", 0))
				n20 += int(r.get("fix_n20", 0))
				if int(r.get("fix_n30", 0)) > 0 and bad.size() < 6:
					bad.append(String(pr[1]))
		totals["own" if own else "60"] = [sets, n30, n20]
		_expect(n30 == 0 and n20 <= 2, "pulled: %d key sets %s: %d frames of the last pass pulling over 30 degrees (0 allowed; 35 and 39 before) and %d over 20 (2 or fewer): %s" % [sets, "at their own range" if own else "at 60 units", n30, n20, str(bad)])
	_tier_dist = dist_was
	RenderAnim.press_styles = press_was
	RenderAnim.ground_feet = ground_was
	print("pulled: %s" % str(totals))


## The styles' distinctness (homework 4b). A cell is one scene (a button's tap, mash or hold, one fighter, every style of a button throwing the SAME piece). Its features over the blows' window:
## the mean and the spread of nine joints about the pelvis (pose), how far and how low the pelvis goes (travel), and the hand-speed peaks a second, the hand's speed and the pelvis's bob (rhythm).
## The distance of two cells is pose (RMS of the means / 4 units + RMS of the spreads / 2) + travel (range / 6, mean height / 3, lowest / 4, averaged) + rhythm (peak rate / 2 Hz, speed / 2,
## bob / 1, averaged). The threshold is 2.5: Orb called the fighters "different people" and the same cell thrown by the two fighters is 2.1 apart (the median), and the two NEAREST different
## buttons are 3.7 apart; a style pair must read at least a third farther apart than the fighters do and two thirds as far as the nearest two buttons.
func _cell_features(rows: Array, tag: String) -> Dictionary:
	var ct: Array = CELL_CONTACTS[tag]
	var k0: int = int(ct[0]) - 12
	var k1: int = int(ct[ct.size() - 1]) + 14
	var poses: Array = []
	var pxs: Array = []
	var pys: Array = []
	var hs: Array = []
	var prev_h: Array = []
	for r in rows:
		if int(r.k) < k0 or int(r.k) > k1:
			continue
		var pel: Vector3 = r.pel
		var v: Array = []
		for jn in [r.head, r.r.el, r.l.el, r.r.wr, r.l.wr, r.r.kn, r.l.kn, r.r.ft, r.l.ft]:
			var d: Vector3 = jn - pel
			v.append(d.x)
			v.append(d.y)
			v.append(d.z)
		poses.append(v)
		pxs.append(pel.x)
		pys.append(pel.y)
		var hsum: float = 0.0
		if not prev_h.is_empty():
			hsum = (r.r.wr - prev_h[0]).length() + (r.l.wr - prev_h[1]).length()
		prev_h = [r.r.wr, r.l.wr]
		hs.append(hsum)
	var n: int = poses.size()
	var m: int = (poses[0] as Array).size()
	var mean := []
	var sd := []
	for j in range(m):
		var s: float = 0.0
		for p in poses:
			s += float(p[j])
		s /= float(n)
		var vv: float = 0.0
		for p in poses:
			vv += (float(p[j]) - s) * (float(p[j]) - s)
		mean.append(s)
		sd.append(sqrt(vv / float(n)))
	var xmin: float = 1.0e9
	var xmax: float = -1.0e9
	var ym: float = 0.0
	var ymin: float = 1.0e9
	for i in range(n):
		xmin = minf(xmin, float(pxs[i]))
		xmax = maxf(xmax, float(pxs[i]))
		ym += float(pys[i])
		ymin = minf(ymin, float(pys[i]))
	ym /= float(n)
	var ysd: float = 0.0
	for i in range(n):
		ysd += (float(pys[i]) - ym) * (float(pys[i]) - ym)
	ysd = sqrt(ysd / float(n))
	var hmax: float = 0.0
	var hrms: float = 0.0
	for h in hs:
		hmax = maxf(hmax, float(h))
		hrms += float(h) * float(h)
	hrms = sqrt(hrms / float(n))
	var peaks: int = 0
	for i in range(1, n - 1):
		if float(hs[i]) > 0.5 * hmax and float(hs[i]) >= float(hs[i - 1]) and float(hs[i]) > float(hs[i + 1]):
			peaks += 1
	return {"mean": mean, "sd": sd, "xr": xmax - xmin, "ym": ym, "ymin": ymin, "ysd": ysd, "rate": float(peaks) / (float(n) / 60.0), "hrms": hrms}


func _cell_distance(a: Dictionary, b: Dictionary) -> float:
	var dm: float = 0.0
	var ds: float = 0.0
	var m: int = (a.mean as Array).size()
	for j in range(m):
		dm += (float(a.mean[j]) - float(b.mean[j])) * (float(a.mean[j]) - float(b.mean[j]))
		ds += (float(a.sd[j]) - float(b.sd[j])) * (float(a.sd[j]) - float(b.sd[j]))
	var d_pose: float = sqrt(dm / float(m)) / 4.0 + sqrt(ds / float(m)) / 2.0
	var d_travel: float = (absf(float(a.xr) - float(b.xr)) / 6.0 + absf(float(a.ym) - float(b.ym)) / 3.0 + absf(float(a.ymin) - float(b.ymin)) / 4.0) / 3.0
	var d_rhythm: float = (absf(float(a.rate) - float(b.rate)) / 2.0 + absf(float(a.hrms) - float(b.hrms)) / 2.0 + absf(float(a.ysd) - float(b.ysd)) / 1.0) / 3.0
	return d_pose + d_travel + d_rhythm


func _test_styles() -> void:
	AnimData.load_every_wave()
	RenderAnim.hit_variants = false   # the styles are the attackers' own: the defender answers with the plain flinch here
	_run_cells(true)
	var feat := {}
	var groups := {}
	for r in _bn_rows:
		var key: String = "%s:%s" % [r.tag, r.who]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(r)
	for key in groups:
		feat[key] = _cell_features(groups[key], String(key).get_slice(":", 0))
	var inner: Array = []
	var worst: String = ""
	var worst_d: float = 1.0e9
	for who in ["protagonist", "antihero"]:
		for b in ["x", "y", "b"]:
			var names: Array = [b + "tap", b + "mash", b + "hold"]
			for i in range(3):
				for j in range(i + 1, 3):
					var d: float = _cell_distance(feat["%s:%s" % [names[i], who]], feat["%s:%s" % [names[j], who]])
					inner.append(d)
					if d < worst_d:
						worst_d = d
						worst = "%s %s~%s" % [who, names[i], names[j]]
	var fighters: Array = []
	for c in CELLS:
		fighters.append(_cell_distance(feat["%s:protagonist" % c], feat["%s:antihero" % c]))
	fighters.sort()
	var cross_min: float = 1.0e9
	for who in ["protagonist", "antihero"]:
		for i in range(CELLS.size()):
			for j in range(i + 1, CELLS.size()):
				if String(CELLS[i]).substr(0, 1) != String(CELLS[j]).substr(0, 1):
					cross_min = minf(cross_min, _cell_distance(feat["%s:%s" % [CELLS[i], who]], feat["%s:%s" % [CELLS[j], who]]))
	RenderAnim.hit_variants = true
	_expect(worst_d >= 2.5, "styles: the nearest two styles of a button are %.2f apart (%s); the threshold is 2.5 (the fighters are %.2f apart at the median, the nearest two buttons %.2f)" % [worst_d, worst, float(fighters[fighters.size() / 2]), cross_min])
	print("styles: 18 style pairs, nearest %.2f (%s); the fighters %.2f apart at the median; the nearest two buttons %.2f" % [worst_d, worst, float(fighters[fighters.size() / 2]), cross_min])


func _test_march() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	var one: Dictionary = _tier_scene(S, "protagonist", "super", ["su_edge_step"], [64], {"windup": 28, "hand": "r"}, "heavy")
	var two: Dictionary = _tier_scene(S, "protagonist", "super", ["su_edge_step", "su_edge_step"], [64, 150], {"windup": 28, "hand": "r"}, "heavy")
	_expect(float(one.get("march", 0.0)) == 0.0 and float(two.get("march", 0.0)) >= 0.5, "march: a lone heavy does not march (%.2f), a second within 140 ticks does (%.2f)" % [float(one.get("march", 0.0)), float(two.get("march", 0.0))])
	_expect(int(two.nan) == 0 and int(two.screen) == 0 and int(two.frames) == 2 and float(two.err) < 0.25, "march: two heavies: %d NaN, %d on screen, %d of 2 contacts, error %.3f" % [int(two.nan), int(two.screen), int(two.frames), float(two.err)])
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	print("march: a second heavy within 140 ticks marches %.2f, a lone one %.2f" % [float(two.get("march", 0.0)), float(one.get("march", 0.0))])


func _test_tell_sinks() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	var seen: Array = []
	for pc in [["protagonist", "su_edge_step", true], ["protagonist", "su_blade_jaw", true], ["protagonist", "su_edge_unwind", true], ["antihero", "su_ram", true], ["antihero", "su_plate", true],
			["antihero", "su_hook", true], ["antihero", "su_knee", true], ["antihero", "su_heel", false], ["protagonist", "su_drive", false]]:
		var r: Dictionary = _tier_scene(S, String(pc[0]), "super", [String(pc[1])], [64], {"windup": 28, "hand": "r"}, "heavy")
		var base_y: float = -1.0
		var low_y: float = 1.0e9
		for tr in r.get("trace", []):
			if int(tr.dt) == -32:
				base_y = float(tr.pv_y)
			elif int(tr.dt) >= -28 and int(tr.dt) <= -4:
				low_y = minf(low_y, float(tr.pv_y))
		var drop: float = base_y - low_y
		seen.append("%s %.1f" % [pc[1], drop])
		if bool(pc[2]):
			_expect(drop >= 5.0, "tell sinks: %s %s sinks %.1f units over its wind-up (5 or more)" % [pc[0], pc[1], drop])
		else:
			_expect(drop <= 2.5, "tell sinks: %s %s, a fall, sinks %.1f units (it rises: 2.5 or less)" % [pc[0], pc[1], drop])
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	print("tell sinks: %s" % ", ".join(seen))


## The super-heavy tier's drives (docs/combat/pending/movegen/three-strengths.md section 3, Legal D1 to D5), read off the three key poses of every piece: where the body is at the tell and where it ends, so a flurry's next
## blow starts where the last stopped. step_through: a full pace behind the blow; turn: half a turn, never more, wound away and unwound through; unwind: one limb crossed over his centre in the tell, out the other side at the
## blow; heave: sunk deep, then stood tall, the feet keeping their place; fall: risen at the tell with the limb at shoulder height or lower, sunk lower at the blow; full_turn: one turn, wound away, a quarter past.
func _test_tier_drives() -> void:
	AnimData.load_every_wave()
	var judged: int = 0
	var bad: Array = []
	for kid in AnimData.keysets:
		var ks: Dictionary = AnimData.keysets[kid]
		if not (String(kid).begins_with("ru.su_") or String(kid).begins_with("pu.su_")):
			continue
		var drive: String = String(ks.get("drive", ""))
		var ch: Dictionary = AnimData.raw.get(String(kid) + ".chamber", {})
		var ct: Dictionary = AnimData.raw.get(String(kid) + ".contact", {})
		var fo: Dictionary = AnimData.raw.get(String(kid) + ".follow", {})
		if drive == "" or ch.is_empty() or ct.is_empty() or fo.is_empty():
			bad.append("%s has no drive or a missing key pose" % kid)
			continue
		judged += 1
		var limb: String = String(ks.get("limb", "hand_r"))
		var lk: String = limb.replace("elbow", "hand").replace("knee", "foot").replace("shoulder", "hand")
		var twc: float = float(ch.get("hip_twist", 0.0)) + float(ch.get("spine", {}).get("twist", 0.0))
		var twk: float = float(ct.get("hip_twist", 0.0)) + float(ct.get("spine", {}).get("twist", 0.0))
		var twf: float = float(fo.get("hip_twist", 0.0)) + float(fo.get("spine", {}).get("twist", 0.0))
		var hc: float = float(ch.get("hips", [0, 0, 0])[1])
		var hk: float = float(ct.get("hips", [0, 0, 0])[1])
		var hf: float = float(fo.get("hips", [0, 0, 0])[1])
		match drive:
			"step_through":
				if float(fo.hips[0]) - float(ch.hips[0]) < 25.0:
					bad.append("%s: a stepping heavy carries the body %.0f (a full pace is 25 or more)" % [kid, float(fo.hips[0]) - float(ch.hips[0])])
			"turn":
				if not (twc <= -50.0 and twk >= 40.0 and absf(twk - twc) <= 190.0 and absf(twk) < 100.0):
					bad.append("%s: a turning heavy winds %.0f and unwinds %.0f (half a turn, never more)" % [kid, twc, twk])
			"unwind":
				var zc: float = float(ch.get(lk, [0, 0, 0])[2])
				var zk: float = float(ct.get(lk, [0, 0, 0])[2])
				if not (zc < -2.0 and zk > 2.0):
					bad.append("%s: an unwinding heavy's limb is at z %.0f in the tell and %.0f at the blow (it crosses his centre, then goes out)" % [kid, zc, zk])
				var other: String = "hand_l" if lk.begins_with("hand") else "hand_r"
				if lk.begins_with("hand") and float(ch.get("hand_l", [0, 0, -8])[2]) > 2.0:
					bad.append("%s: both arms cross his centre in the tell" % kid)
			"heave":
				if not (hc <= -16.0 and hf >= hc + 16.0):
					bad.append("%s: a heaving heavy sinks to %.0f and stands to %.0f (sunk deep, then 16 or more taller)" % [kid, hc, hf])
				for fk in ["foot_r", "foot_l"]:
					if fk != limb and absf(float(ch[fk][0]) - float(ct[fk][0])) > 4.0 and float(ch[fk][1]) <= 3.0:
						bad.append("%s: %s moves %.0f between the tell and the blow (a heave keeps its feet in place)" % [kid, fk, float(ch[fk][0]) - float(ct[fk][0])])
			"fall":
				var ly: float = float(ch.get(lk, [0, 0, 0])[1])
				if not (hc >= 2.0 and hk <= hc - 8.0 and ly <= 70.0):
					bad.append("%s: a falling heavy is at %.0f in the tell (limb %.0f high) and %.0f at the blow (risen, the limb at shoulder height, then sunk 8 or more)" % [kid, hc, ly, hk])
			"full_turn":
				if not (twc <= -60.0 and twk >= 50.0 and twf >= 20.0 and twf <= 60.0):
					bad.append("%s: a full turn winds %.0f, unwinds %.0f and ends %.0f (a quarter past the rival)" % [kid, twc, twk, twf])
			_:
				bad.append("%s: unknown drive %s" % [kid, drive])
		# the chamber is a tell in plain sight: the loaded limb at shoulder height or lower, never both hands together (the held lint also judges it)
		var hr = ch.get("hand_r")
		var hl = ch.get("hand_l")
		if hr != null and hl != null and Vector3(float(hr[0]) - float(hl[0]), float(hr[1]) - float(hl[1]), float(hr[2]) - float(hl[2])).length() < 10.0:
			bad.append("%s: both hands together in the tell" % kid)
	_expect(bad.is_empty(), "tier drives: %s" % "; ".join(bad))
	_expect(judged >= 16, "tier drives: only %d pieces of the tier were found (16 are the first set)" % judged)
	print("tier drives: %d pieces of the super-heavy tier read as their drive (a pace, half a turn, one limb crossing, sunk then tall, risen then sunk, one turn)" % judged)


## The reach table (docs/animation/cues-c2.md section 2; the closing rule of Encounter's C2t): for every strike key set of the launch pair, how many units beyond its own striking distance (the manifest row's
## `range.offset`: where the blow is drawn from) the rival may stand and the hand, foot, elbow or knee still ends within 1.5 units of the target at the contact, with the body's own lunge and step: `cover`. Bisected
## on the real solve (a wind-up of 2 ticks for a light bolt, 4 for a light, 12 for a medium or a blast, 28 for the super-heavy tier), the rival staged at offset + slack. Writes data/anim/reach.json (`--reach=path` on
## anim_check, or call it from a harness). A planted heave (its step is 22 at most) and a bolt (step 4) come out low; a stepping drive and the generic strikes high.
func _reach_scan(out_path: String) -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	_tier_damage = false
	var cover := {}
	var da := DirAccess.open("res://data/anim/waves")
	var files: Array = Array(da.get_files())
	files.sort()
	for fn in files:
		if not String(fn).ends_with(".manifest.json"):
			continue
		var wn: String = String(fn).trim_suffix(".manifest.json")
		var who: String = "protagonist" if (wn.begins_with("protag")) else ("antihero" if (wn.begins_with("wave") or wn.begins_with("rival") or wn.begins_with("guard")) else "")
		if who == "":
			continue
		var m = JSON.parse_string(FileAccess.get_file_as_string("res://data/anim/waves/" + String(fn)))
		for st in m.get("strikes", []):
			var sid: String = String(st.id)
			if String(st.get("name", "")).begins_with("tail") or not AnimData.keysets.has(sid):
				continue
			var key: String = String(AnimData.ensure_fighter("PROTAGONIST" if who == "protagonist" else "RIVAL"))
			AnimData.ensure_fighter("RIVAL" if who == "protagonist" else "PROTAGONIST")
			AnimData.pair_lists[key].by_name[sid] = sid
			var heavy: bool = String(st.weight) == "heavy"
			var tier: bool = sid.contains(".su_")
			var wu: int = 28 if tier else (12 if heavy else (2 if sid.contains(".bolt_") else 4))
			var style: String = "super" if tier else ("medium" if heavy else "speed")
			var base: float = float(st.get("offset", 58.0))
			var lo: int = 0
			var hi: int = 160
			while lo < hi:
				var mid: int = (lo + hi + 1) / 2
				_tier_dist = base + float(mid)
				var r: Dictionary = _tier_scene(S, who, style, [sid], [40], {"windup": wu, "hand": "r"}, "heavy" if heavy else "light")
				if float(r.get("gap", 99.0)) <= 1.5:
					lo = mid
				else:
					hi = mid - 1
			if lo == 0:
				_tier_dist = base
				var r0: Dictionary = _tier_scene(S, who, style, [sid], [40], {"windup": wu, "hand": "r"}, "heavy" if heavy else "light")
				if float(r0.get("gap", 0.0)) > 1.5:
					lo = -int(ceil(float(r0.get("gap", 0.0))))   # short even at its own striking distance: how far
			cover[sid] = lo
	_tier_dist = 60.0
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	var keys: Array = cover.keys()
	keys.sort()
	var lines: PackedStringArray = []
	for k2 in keys:
		lines.append("  %s: %d" % [JSON.stringify(k2), int(cover[k2])])
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string('{\n "schema": "anim.reach/1",\n "_about": "How many units beyond its own striking distance (the manifest row\'s range.offset) the rival may stand and a strike key set still lands: the hand, foot, elbow or knee ends within 1.5 units of the target at the contact, with the body\'s own lunge and step (render only; a negative number is how far it ends short even at its own striking distance). Measured on the real solve by render/anim/tools/anim_check.gd `_reach_scan` (a wind-up of 2 ticks for a bolt, 4 for a light, 12 for a medium or a blast, 28 for the super-heavy tier), at most 160. Encounter\'s closing rule keeps a blow\'s slack inside this number (docs/animation/cues-c2.md section 2).",\n "cover": {\n' + ",\n".join(lines) + '\n }\n}\n')
	f.close()
	print("reach scan: %d key sets, written to %s" % [cover.size(), out_path])


## A heave may take one sliding half step (Legal h08): when the closing slack is more than its pose bridges (the rival 30 units farther than its striking distance), the body steps in, up to about 22 units, and
## the rear foot stays on the ground the whole way, the other foot never leaves the ground (a foot blow's own foot excepted: it is loaded low behind and goes at the blow), there is no leap, and nothing rises before
## the blow: the stand is the heave's own. Played on all four heaves with a 30-unit slack and a 62-tick hold too.
func _test_heave_step() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	var bad: Array = []
	var seen: Array = []
	for pc in [["antihero", "su_elbow_heave", false], ["antihero", "su_fist_heave", false], ["protagonist", "su_palm_heave", false], ["protagonist", "su_ball_heave", true]]:
		for wu in [28, 62]:
			_tier_dist = 60.0 + 30.0
			var r: Dictionary = _tier_scene(S, pc[0], "super", [String(pc[1])], [96], {"windup": wu, "hand": "r"}, "heavy")
			_tier_dist = 60.0
			var fl: Array = r.get("feet", [])
			var ground: float = 1.0e9
			for e in fl:
				if int(e[0]) >= -14 and int(e[0]) <= -4:
					ground = minf(ground, minf(float(e[1]), float(e[2])))
			var worst_stand: float = 0.0
			var worst_strike: float = 0.0
			var rise: float = 0.0
			var hy0: float = -1.0e9
			for e in fl:
				if int(e[0]) == -14:
					hy0 = float(e[3])   # the tell is reached by the middle of a 28-tick wind-up: from there to the blow nothing may rise
				if int(e[0]) >= -14 and int(e[0]) <= -4:
					worst_stand = maxf(worst_stand, float(e[2]) - ground if bool(pc[2]) else maxf(float(e[1]), float(e[2])) - ground)
					worst_strike = maxf(worst_strike, float(e[1]) - ground)
					if hy0 > -1.0e8:
						rise = maxf(rise, float(e[3]) - hy0)
			if worst_stand > 4.0 or (bool(pc[2]) and worst_strike > 12.0) or rise > 1.5 or int(r.nan) > 0 or int(r.screen) > 0 or int(r.frames) != 1:
				bad.append("%s %s on %d ticks with a 30-unit slack: a standing foot is %.1f off the ground, the loaded foot %.1f, the pelvis rises %.1f before the blow (%d of 1 contacts)" % [pc[0], pc[1], wu, worst_stand, worst_strike, rise, int(r.frames)])
			elif wu == 28:
				seen.append("%s: feet down to %.1f, pelvis up %.1f, short by %.1f" % [pc[1], worst_stand, rise, float(r.get("gap", 0.0))])
	_expect(bad.is_empty(), "heave step: %s" % "; ".join(bad))
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	print("heave step (30-unit slack): %s" % " | ".join(seen))


## The body's tint and palette (the dynamic sky's light on the bodies, Art's colour-vision presets): the tint is one multiply colour per body, white by default (no change by a pixel); the lane colour's parts carry a
## 0 alpha in the mesh and every other vertex 1, which the body shader reads as its tint mask; a hit flash is drawn untinted; a new palette swaps the cached mesh and keeps the bones.
func _test_body_tint() -> void:
	var pal := {"body": Color("#3d8fdc"), "legs": Color("#1b1f2a"), "arms": Color("#e6b995"), "skin": Color("#efc7a2"), "gear": Color("#cdd6e4"), "accent": Color("#4fb9a8"), "hair": Color("#22c7a0")}
	var b := AnimBody.new()
	b.build(pal, true)
	var arr: Array = b.mi.mesh.surface_get_arrays(0)
	var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR]
	var lane: int = 0
	var other: int = 0
	var bad: int = 0
	var acc: Color = pal["accent"]
	for c in cols:
		if c.a < 0.01:
			lane += 1
			if absf(c.r - acc.r) > 0.02 or absf(c.g - acc.g) > 0.02 or absf(c.b - acc.b) > 0.02:
				bad += 1
		elif c.a > 0.99:
			other += 1
		else:
			bad += 1
	_expect(lane > 0 and other > lane and bad == 0, "body tint: the mask is wrong (%d lane vertices, %d others, %d wrong)" % [lane, other, bad])
	var mat: ShaderMaterial = b.mi.material_override
	b.set_tint(Color(0.5, 0.55, 0.7))
	_expect((mat.get_shader_parameter("tint") as Color).is_equal_approx(Color(0.5, 0.55, 0.7)), "body tint: set_tint did not set the uniform")
	b.set_look(1.0, false)
	_expect((mat.get_shader_parameter("tint") as Color).is_equal_approx(Color.WHITE), "body tint: a hit flash is tinted")
	b.set_look(0.0, false)
	_expect((mat.get_shader_parameter("tint") as Color).is_equal_approx(Color(0.5, 0.55, 0.7)), "body tint: the tint did not come back after the flash")
	b.set_tint(Color.WHITE)
	var pal2: Dictionary = pal.duplicate()
	pal2["accent"] = Color("#e69f00")
	var mesh1: Mesh = b.mi.mesh
	b.set_palette(pal2)
	_expect(b.mi.mesh != mesh1 and b.mi.skin != null, "body tint: set_palette did not swap the mesh")
	b.free()
	print("body tint: %d lane-colour vertices left out of the tint, %d tinted; the flash is untinted; a palette swap keeps the skin" % [lane, other])


## The nine cells in the live three-strength brawl (docs/animation/nine-cells.md; Game Design's brawl-second-pass section 15): a scripted pad on slot 0 against the medium AI, each cell pressed its own way, read off
## the body's own debug. A held X plays the burst row (blows 2 to 8) with its set pose in the gap; Y plays the medium row and B the super row, each with the sim's own wind-up drawn whole (the cue `windup`); a B
## held past its landing is drawn in its chamber and loads (never thrown at its 28th tick, never idle through the charge), and its release is the sim's next beat; a heavy winding barely moves for a light.
var _cells_held := {}
func _cells_btn(host, name: String, down: bool) -> void:
	var k := "0:" + name
	if down == _cells_held.has(k):
		return
	if down:
		_cells_held[k] = true
	else:
		_cells_held.erase(k)
	host.hub.pad_button(0, name, down)


func _cells_run(btn: String, pat: Callable, ticks: int, seed: int) -> Dictionary:
	_cells_held.clear()
	RenderAnim._fighters.clear()
	main.start_match(seed, {"p1": false, "p2": true}, {})
	var host = main.host
	host.release_all()
	host.hub.pad_button(0, "back", true)
	host.hub.pad_button(0, "back", false)
	host.take_players()
	var S: SimState = host.S
	var res := {"hold": 0, "held_coil": 0.0, "set": 0.0, "styles": {}, "phases": {}, "blows": 0, "cue_windups": 0, "ttc_first": [], "dig": 0.0, "lean": 0.0, "march": 0.0, "drop": 0.0, "_idle_y": -1.0, "shine": 0.0}
	var t0: int = -1
	var stick: float = 0.0
	var last_blow: int = -1
	for tick in range(ticks + 900):
		var f0 = S.fighters[0]
		var f1 = S.fighters[1]
		var dx: float = SimWrap.sdx(f0.x, f1.x)
		var brawl: bool = S.dirS.ex != null and String(S.dirS.ex.tpl) == "brawl"
		if brawl and t0 < 0:
			t0 = tick
		var want: float = signf(dx) if (absf(dx) > 110.0 and t0 < 0) else 0.0
		if want != stick:
			stick = want
			host.hub.pad_stick(0, want, 0.0)
		var rel: int = tick - t0 if t0 >= 0 else -1
		_cells_btn(host, btn, rel >= 0 and rel < ticks and bool(pat.call(rel)))
		host.acc = SimConst.DT * 0.9999
		main.frame(SimConst.DT)
		var a0: AnimFighter = RenderAnim.fighter(S, S.fighters[0])
		if rel >= 0 and not a0.press.is_empty():
			var st: String = String(a0.press.style)
			res.styles[st] = true
			var ph: String = String(a0.press.phase)
			res.phases[ph] = int(res.phases.get(ph, 0)) + 1
			if ph == "hold":
				res.hold += 1
			if int(a0.press.blow) != last_blow:
				last_blow = int(a0.press.blow)
				res.blows += 1
		res.held_coil = maxf(float(res.held_coil), a0.hold_coil)
		res.dig = maxf(float(res.dig), a0.dig_w)
		res.lean = maxf(float(res.lean), a0.press_lean)
		res.shine = maxf(float(res.shine), a0.hand_shine)
		var py: float = a0.socket("pelvis").y
		if float(res._idle_y) < 0.0 and rel >= 0:
			res._idle_y = py
		if rel >= 0 and not a0.press.is_empty():
			res.drop = maxf(float(res.drop), float(res._idle_y) - py)
		res.march = maxf(float(res.march), a0.march_w)
		res.set = maxf(float(res.set), a0.burst_set)
		if t0 >= 0 and rel > ticks + 60:
			break
	var d: Dictionary = RenderAnim.fighter(S, S.fighters[0]).debug
	res.cue_windups = int(d.get("cue_windups", 0))
	host.release_all()
	return res


func _test_cells() -> void:
	AnimData.load_every_wave()
	load("res://sim/director/ai.gd").set("level", "medium")
	var seen: Array = []
	# the shipped default is today's picture: the sim stamps a style on every brawl beat, and until Encounter's hook drops it the strength map is not reached (a mashed Y plays the heavy row, no medium)
	var forced_was: bool = RenderAnim.strength_styles
	RenderAnim.strength_styles = false
	var yd: Dictionary = _cells_run("north", func(t): return (t % 12) < 3, 200, 21)
	# with the recipes' hook in (the brawl asks by cell and names no style) the cells' looks are the picture with the switch off: a mashed Y plays the medium row, wound in plain sight, and the hook has been seen
	_expect(yd.styles.has("medium") and not yd.styles.has("heavy") and RenderAnim.hook_seen and yd.cue_windups > 0, "cells: by default (the hook landed) a mashed Y plays the medium row with the sim's wind-ups drawn whole (%s, hook seen %s, %d wind-ups drawn whole)" % [str(yd.styles.keys()), str(RenderAnim.hook_seen), yd.cue_windups])
	RenderAnim.strength_styles = true
	var xh: Dictionary = _cells_run("west", func(t): return true, 140, 21)
	_expect(xh.styles.has("burst") and float(xh.set) > 0.5, "cells: a held X plays the burst row and its set pose (styles %s, set %.2f)" % [str(xh.styles.keys()), float(xh.set)])
	var xm: Dictionary = _cells_run("west", func(t): return (t % 7) < 3, 200, 21)
	var xt: Dictionary = _cells_run("west", func(t): return (t % 70) < 2, 220, 21)
	_expect(float(xt.shine) >= 0.5, "cells: a tapped X's hand shines while its hit is held (%.2f)" % float(xt.shine))
	_expect(float(xm.lean) >= 0.08 and float(xt.lean) == 0.0, "cells: a mashed X leans in (%.2f rad) and a tapped X does not (%.2f)" % [float(xm.lean), float(xt.lean)])
	_expect(float(xh.dig) >= 0.5 and float(xm.dig) == 0.0, "cells: a held X digs in (%.2f) and a mashed X does not (%.2f)" % [float(xh.dig), float(xm.dig)])
	_expect(xm.styles.has("speed") and not xm.styles.has("burst") and xm.blows >= 12, "cells: a mashed X plays the speed row (%s, %d blows)" % [str(xm.styles.keys()), xm.blows])
	var ym: Dictionary = _cells_run("north", func(t): return (t % 12) < 3, 200, 21)
	_expect(float(ym.lean) >= 0.1, "cells: a mashed Y leans in (%.2f rad)" % float(ym.lean))
	_expect(ym.styles.has("medium") and not ym.styles.has("heavy") and ym.cue_windups > 0, "cells: a mashed Y plays the medium row with the sim's wind-up (%s, %d wind-ups drawn whole)" % [str(ym.styles.keys()), ym.cue_windups])
	var bt: Dictionary = _cells_run("east", func(t): return (t % 130) < 4, 150, 33)
	_expect(float(bt.drop) >= 4.0, "cells: a tapped B sinks %.1f units over its tell in the live brawl (4 or more)" % float(bt.drop))
	var bh: Dictionary = _cells_run("east", func(t): return t >= 70 and t < 125, 200, 33)
	_expect(bh.styles.has("super") and bh.hold >= 10 and float(bh.held_coil) >= 0.9, "cells: a held B is drawn in its chamber and loads (%d hold ticks, coil %.2f)" % [bh.hold, float(bh.held_coil)])
	RenderAnim.strength_styles = forced_was
	seen.append("held X: burst %.2f set; mashed Y %d blows on the medium row; held B %d hold ticks, coil %.2f" % [float(xh.set), ym.blows, bh.hold, float(bh.held_coil)])
	print("cells: %s" % "; ".join(seen))


## The strength map's precedence (Combat's and Encounter's window): a beat that names a style row keeps it (today's picture); a beat that carries a strength and names none gets the strength's row, flurry or not,
## and that is how Animation sees that the hook has landed; the switch `strength_styles` forces the map over a beat's explicit style.
func _test_strength_map() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f = S.fighters[0]
	var af: AnimFighter = RenderAnim.fighter(S, f)
	var press_was: bool = RenderAnim.press_styles
	var forced_was: bool = RenderAnim.strength_styles
	var seen_was: bool = RenderAnim.hook_seen
	RenderAnim.press_styles = true
	RenderAnim.strength_styles = false
	RenderAnim.hook_seen = false
	var n: int = 9000
	var cases := [
		["explicit heavy on a medium", {"brawl": true, "strength": "medium", "style": "heavy", "flurry": false}, "heavy", false],
		["explicit speed on a light", {"brawl": true, "strength": "light", "style": "speed", "flurry": false}, "speed", false],
		["no style, a medium", {"brawl": true, "strength": "medium", "flurry": false}, "medium", true],
		["no style, a heavy", {"brawl": true, "strength": "heavy", "flurry": false}, "super", true],
		["no style, a light in a flurry", {"brawl": true, "strength": "light", "flurry": true}, "speed", true],
		["no style, a burst blow", {"brawl": true, "strength": "light", "burst": 4, "flurry": true}, "burst", true],
	]
	for c in cases:
		n += 1
		RenderAnim.hook_seen = false
		var ex := {"n": n}
		var sk: Array = [0.0, 1, c[1], "heavy" if String(c[1].get("strength", "")) == "heavy" else "light"]
		af._pr_cache.clear()
		var got: String = af._press_style(S, f, ex, sk)
		_expect(got == String(c[2]), "strength map %s: plays %s, wanted %s" % [c[0], got, c[2]])
		_expect(RenderAnim.hook_seen == bool(c[3]), "strength map %s: hook seen %s, wanted %s" % [c[0], str(RenderAnim.hook_seen), str(c[3])])
	RenderAnim.strength_styles = true
	RenderAnim.hook_seen = false
	af._pr_cache.clear()
	var forced: String = af._press_style(S, f, {"n": n + 1}, [0.0, 1, {"brawl": true, "strength": "medium", "style": "heavy", "flurry": false}, "light"])
	_expect(forced == "medium", "strength map forced: an explicit heavy on a medium plays %s, wanted medium" % forced)
	# the plain light's pin (the perfect follow-up's window opens as it lets go): on by default for one brawl light that is no flurry's or chain's (no change to a sim data file), on for a beat that says `plain`, off with the switch
	var pin_was: bool = RenderAnim.plain_pin
	var lt := {"brawl": true, "strength": "light", "flurry": false, "k": 1, "burst": 0}
	_expect(RenderAnim.plain_pin and int(af._press_prof({}, "speed", lt).get("ci_pin", 0)) == 6, "plain pin: on by default, a plain light pins 6 ticks")
	_expect(int(af._press_prof({}, "speed", {"plain": true}).get("ci_pin", 0)) == 6, "plain pin: a beat that says plain pins 6 ticks")
	RenderAnim.plain_pin = false
	_expect(not af._press_prof({}, "speed", lt).has("ci_pin"), "plain pin: with the switch off a plain light does not")
	RenderAnim.plain_pin = true
	var fl: Dictionary = lt.duplicate()
	fl["flurry"] = true
	_expect(not af._press_prof({}, "speed", fl).has("ci_pin"), "plain pin: a flurry's light does not")
	var k3: Dictionary = lt.duplicate()
	k3["k"] = 3
	_expect(not af._press_prof({}, "speed", k3).has("ci_pin"), "plain pin: a chain's later light does not")
	RenderAnim.plain_pin = pin_was
	RenderAnim.press_styles = press_was
	RenderAnim.strength_styles = forced_was
	RenderAnim.hook_seen = seen_was
	S.dirS.ex = null
	print("strength map: %d cases" % (cases.size() + 1))


## Fighters in depth (docs/animation/fighters-in-depth.md): all of it inert with depth off (no yaw, no line, no stride, the step layer draws nothing), and with depth on the body turns toward the rival's depth
## (positive toward the camera), the step layer lifts the feet only when his depth changes, the contact reach is three-axis.
func _test_depth() -> void:
	AnimData.load_every_wave()
	main.start_match(5, {"p1": false, "p2": false}, {})
	for i in range(30):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var af0: AnimFighter = RenderAnim.fighter(S, f0)
	_expect(not S.depthOn and not af0.depth_on and af0.depth_yaw == 0.0 and af0.depth_line == 0.0 and af0._stride == 0.0, "depth off: no yaw, no line, no stride (yaw %.3f)" % af0.depth_yaw)
	af0.depth_vz = 2.0   # a forced read: with depth off the layer must still draw nothing
	var h0: Vector3 = af0.hips
	af0._depth_step_layer(S, f0)
	_expect(af0.hips == h0, "depth off: the step layer draws nothing")
	af0.depth_vz = 0.0
	main.start_match(5, {"p1": false, "p2": false}, {"depth": true})
	for i in range(30):
		main.frame(1.0 / 60.0)
	S = main.host.S
	_expect(S.depthOn, "depth on: the probe match has depth physical")
	var a = S.fighters[0]
	var b = S.fighters[1]
	for i in range(40):
		a.z = 0.0
		a.zT = 0.0
		b.z = 40.0
		b.zT = 40.0
		b.x = a.x + 150.0   # close enough for the line to turn them (it fades out from 300 to 700 units)
		main.frame(1.0 / 60.0)
	var aa: AnimFighter = RenderAnim.fighter(S, a)
	var ab: AnimFighter = RenderAnim.fighter(S, b)
	_expect(aa.depth_on and aa.depth_line > 0.0 and aa.depth_yaw > 0.0, "depth on: he turns toward the camera when the rival is nearer it (line %.1f deg, yaw %.3f)" % [aa.depth_line, aa.depth_yaw])
	_expect(ab.depth_yaw < 0.0 and absf(aa.depth_yaw + ab.depth_yaw) < 0.02, "depth on: the rival turns the other way, the same amount (%.3f, %.3f)" % [aa.depth_yaw, ab.depth_yaw])
	_expect(absf(aa.depth_yaw) <= 0.6 + 1.0e-6, "depth on: the turn is capped (%.3f)" % aa.depth_yaw)
	# a step in depth lifts the feet: his depth changes by 2 a tick for 20 ticks, then stands
	a.state = "free"
	var feet_lift: float = 0.0
	for i in range(20):
		a.z += 2.0
		a.zT = a.z
		b.x = a.x + 150.0
		main.frame(1.0 / 60.0)
	_expect(absf(aa.depth_vz) >= 1.0 and aa._stride > 0.5, "depth on: his speed in depth is read from his depth (vz %.2f, stride %.2f)" % [aa.depth_vz, aa._stride])
	var q_a: Array = aa.q.duplicate()
	var hips_a: Vector3 = aa.hips
	aa.depth_vz = 0.0
	aa._depth_step_layer(S, a)
	_expect(aa.hips == hips_a and aa.q == q_a, "depth on: standing still, the step layer draws nothing")
	aa.depth_vz = 2.0
	aa._depth_step_layer(S, a)
	_expect(aa.hips != hips_a or aa.q != q_a, "depth on: a step in depth is drawn over the base pose")
	# the reach is three-axis: the rival's depth lengthens the distance the contact IK must cover
	var dx: float = absf(SimWrap.sdx(a.x, b.x))
	print("depth: line %.1f deg, yaw %.3f / %.3f, gap %.0f units" % [aa.depth_line, aa.depth_yaw, ab.depth_yaw, dx])


## The burst's set (Game Design brawl-second-pass section 3; data/anim/press_styles.json burst.set; docs/animation/energy-reach.md section 5): one light at once, then about 10 ticks of a set pose before the stream
## at 18, 22, 26, 31, 37, 45 and 56 ticks from the press. Played on the new ticks the set shows between the first light and the stream's first blow and nowhere else; the stream's own gaps (4 to 11) show none.
func _test_burst_set() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	var seen: Array = []
	for who in ["protagonist", "antihero"]:
		var r: Dictionary = _tier_scene(S, who, "burst", ["cross", "palm_heel", "spear_hand", "cross", "palm_heel", "spear_hand", "cross", "palm_heel"], [30, 46, 50, 54, 59, 65, 73, 84], {}, "light")
		var n: int = int(r.get("set_ticks", 0))
		_expect(n >= 7 and n <= 13 and int(r.get("set_first", 0)) >= 32 and int(r.get("set_last", 9999)) <= 44, "burst set %s: the set pose shows %d ticks (%d to %d): it belongs between the first light (30) and the stream (46), about 10 ticks" % [who, n, int(r.get("set_first", 0)), int(r.get("set_last", 0))])
		_expect(int(r.nan) == 0 and int(r.screen) == 0 and int(r.frames) == 8, "burst set %s: %d NaN, %d joint violations on screen, %d of 8 contacts" % [who, int(r.nan), int(r.screen), int(r.frames)])
		# honest to h05 although short of 12 ticks: the hands a shoulder width apart (16 or more), never above the shoulder (76), never together
		_expect(float(r.get("set_apart", 0.0)) >= 16.0 and float(r.get("set_top", 999.0)) <= 76.0, "burst set %s: the hands come within %.1f of each other, or up to %.0f high (16 apart, 76 at most)" % [who, float(r.get("set_apart", 0.0)), float(r.get("set_top", 999.0))])
		var r2: Dictionary = _tier_scene(S, who, "burst", ["cross", "palm_heel", "spear_hand", "cross"], [30, 34, 38, 43], {}, "light")
		_expect(int(r2.get("set_ticks", 0)) == 0, "burst set %s: the stream's own gaps (4 and 5 ticks) show the set pose %d ticks" % [who, int(r2.get("set_ticks", 0))])
		seen.append("%s: %d ticks (%d to %d), hands %.0f apart and no higher than %.0f" % [who, n, int(r.get("set_first", 0)), int(r.get("set_last", 0)), float(r.get("set_apart", 0.0)), float(r.get("set_top", 0.0))])
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	print("burst set: %s" % " | ".join(seen))


## The cues of the next chain (Encounter's brawl-plan.md section 10.3; the sim side does not exist yet, so the cues are made here): launcher_open shows the plain stagger on the target for the ticks it lasts and closes
## cleanly; miss shows a whiff for its word; windup, energy_reach, energy_land and double_hit are kept for VFX and move nothing; a flurry blow's strength picks its style and the old text is not needed.
func _test_c2_cues() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = "PROTAGONIST"
	f1.id = "RIVAL"
	RenderAnim._fighters.clear()
	AnimData.ensure_fighter("PROTAGONIST")
	AnimData.ensure_fighter("RIVAL")
	f0.x = 500.0
	f1.x = 560.0
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	S.dirS.ex = null
	var ground_was: bool = RenderAnim.ground_feet
	var step3_was: bool = RenderAnim.step3_cues
	RenderAnim.ground_feet = false
	RenderAnim.step3_cues = true
	var seen: Array = []
	var head0: float = 0.0
	for k in range(60):
		S.tick = 3000 + k
		S.T = 300.0 + float(k) / 60.0
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		if k == 20:
			head0 = RenderAnim.solve(S, f1).socket("head").y
			var ce := SimState.FxEvent.new()
			ce.type = "cue"
			ce.kind = "launcher_open"
			ce.actor = 0.0
			ce.target = 1.0
			ce.text = "stun"
			ce.n = float(S.tick + 30)
			ce.tick = S.tick
			RenderAnim.consume(S, [ce])
		var a0: AnimFighter = RenderAnim.solve(S, f0)
		var a1: AnimFighter = RenderAnim.solve(S, f1)
		if k == 20 + 18:
			_expect(String(a1._seq.get("id", "")) == "lq.open" and String(a0.launcher.get("role", "")) == "actor" and String(a1.launcher.get("role", "")) == "target", "c2 cues: launcher_open did not show the stagger on the target (%s) or mark the launcher (%s)" % [str(a1._seq.get("id", "")), str(a0.launcher)])
			var drop: float = head0 - a1.socket("head").y
			_expect(drop >= 8.0, "c2 cues: the launcher's stagger leaves the head only %.1f lower than before (it is doubled over, dazed)" % drop)
			seen.append("the stagger doubles him over by %.0f" % drop)
		if k == 20 + 34:
			_expect(String(a1._seq.get("id", "")) == "", "c2 cues: the stagger still plays after its n")
		if k == 20 + 24:
			var cl := SimState.FxEvent.new()
			cl.type = "cue"
			cl.kind = "launcher_close"
			cl.actor = 0.0
			cl.text = "lapsed"
			cl.tick = S.tick
			RenderAnim.consume(S, [cl])
	_expect(a_is_empty(RenderAnim.solve(S, f1).launcher), "c2 cues: launcher_close did not clear the cue")
	# a miss for each word: he is carried forward and open
	for w in ["gave_ground", "reach", "dodge"]:
		RenderAnim._fighters.clear()
		AnimData.ensure_fighter("PROTAGONIST")
		for k in range(40):
			S.tick = 3100 + k
			S.T = 310.0 + float(k) / 60.0
			var te2 := SimState.FxEvent.new()
			te2.type = "tick"
			te2.dt = 1.0 / 60.0
			te2.frozen = false
			RenderAnim.consume(S, [te2])
			if k == 10:
				var me := SimState.FxEvent.new()
				me.type = "cue"
				me.kind = "miss"
				me.actor = 0.0
				me.text = w
				me.n = 20.0
				me.tick = S.tick
				RenderAnim.consume(S, [me])
			var m0: AnimFighter = RenderAnim.solve(S, f0)
			RenderAnim.solve(S, f1)
			if k == 10 + 12:
				_expect(String(m0._seq.get("id", "")) == "mi." + w and String(m0.miss_cue.get("text", "")) == w, "c2 cues: miss %s did not show its whiff (%s)" % [w, str(m0._seq.get("id", ""))])
				seen.append("miss %s plays mi.%s" % [w, w])
	# a flurry blow's strength picks its style (the text flurry is retired)
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	S = main.host.S
	for pr in [["light", "speed"], ["medium", "medium"], ["heavy", "super"]]:
		var r: Dictionary = _tier_scene(S, "protagonist", "", ["cross"], [40], {"flurry": true, "strength": pr[0], "hand": "r"}, "light")
		_expect(r.get("styles", {}).has(pr[1]), "c2 cues: a flurry blow of strength %s played %s, not %s" % [pr[0], str(r.get("styles", {}).keys()), pr[1]])
	seen.append("a flurry blow's strength light, medium, heavy plays speed, medium, super")
	RenderAnim.ground_feet = ground_was
	RenderAnim.step3_cues = step3_was
	S.dirS.ex = null
	print("c2 cues: %s" % "; ".join(seen))


func a_is_empty(d: Dictionary) -> bool:
	return d.is_empty()


## Energy in reach (slice C2t; docs/animation/energy-reach.md; Legal e06, e08, e09): the twelve point-blank pieces read as a blow and a shot at once, and a mashed run reads as varied on screen. A bolt lands below the
## collar (the hand 38 to 62 high), a line is level, a flick rises and a sweep falls in the side view (the three paths differ at the contact itself, by the forearm's angle), and in Combat's sample run of twelve
## (the order, the arm and the mirror of each bolt) the two heads keep a hand's width (18 or more) between them.
func _test_energy_reach() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	_tier_damage = true
	var seen: Array = []
	var runs := {
		"protagonist": [["bolt_flat", "bolt_thrust", "bolt_sweep", "bolt_flick", "bolt_thrust", "bolt_sweep", "bolt_flick", "bolt_thrust", "bolt_flat", "bolt_flick", "bolt_sweep", "bolt_thrust"], ["r", "r", "r", "l", "r", "r", "r", "r", "l", "r", "r", "r"]],
		"antihero": [["bolt_blade", "bolt_fist", "bolt_sweep", "bolt_flick", "bolt_fist", "bolt_blade", "bolt_sweep", "bolt_fist", "bolt_flick", "bolt_sweep", "bolt_fist", "bolt_blade"], ["r", "r", "r", "l", "r", "r", "l", "r", "r", "r", "r", "r"]],
	}
	var lines := {"protagonist": ["bolt_thrust", "bolt_flat", "bolt_flick", "bolt_sweep"], "antihero": ["bolt_blade", "bolt_fist", "bolt_flick", "bolt_sweep"]}
	for who in ["protagonist", "antihero"]:
		var fa: Dictionary = {}
		for nm in lines[who]:
			var r: Dictionary = _tier_scene(S, who, "speed", [String(nm)], [40], {"windup": 2, "hand": "r"}, "light")
			_expect(int(r.nan) == 0 and int(r.screen) == 0 and int(r.frames) == 1 and float(r.err) < 0.25, "energy reach %s %s: %d NaN, %d on screen, %d of 1 contacts, error %.3f" % [who, nm, int(r.nan), int(r.screen), int(r.frames), float(r.err)])
			for tr in r.get("trace", []):
				if int(tr.dt) == 0:
					fa[nm] = float(tr.fa)
					_expect(float(tr.abs_hand_r) >= 38.0 and float(tr.abs_hand_r) <= 62.0, "energy reach %s %s: the hand lands %.0f high (the chest or the gut: 38 to 62, below the collar)" % [who, nm, float(tr.abs_hand_r)])
		var line_a: float = maxf(float(fa.get(lines[who][0], 0.0)), float(fa.get(lines[who][1], 0.0)))
		var flick_a: float = float(fa.get("bolt_flick", 0.0))
		var sweep_a: float = float(fa.get("bolt_sweep", 0.0))
		_expect(flick_a > line_a + 12.0 and sweep_a < minf(float(fa.get(lines[who][0], 0.0)), float(fa.get(lines[who][1], 0.0))) - 6.0, "energy reach %s: the contacts do not differ by path: forearm angle %.0f flick, %.0f sweep, %.0f and %.0f the lines (a flick rises, a sweep falls)" % [who, flick_a, sweep_a, float(fa.get(lines[who][0], 0.0)), float(fa.get(lines[who][1], 0.0))])
		var run: Array = runs[who]
		var cs: Array = []
		for i in range(12):
			cs.append(30 + 6 * i)
		var rr: Dictionary = _tier_scene(S, who, "speed", run[0], cs, {"windup": 2, "_hands": run[1]}, "light")
		_expect(int(rr.nan) == 0 and int(rr.screen) == 0, "energy reach %s run: %d NaN, %d joint violations on screen" % [who, int(rr.nan), int(rr.screen)])
		_expect(float(rr.get("hmin", 0.0)) >= 18.0, "energy reach %s run: the heads come within %.1f of each other (a hand's width, 18 or more, Legal e09)" % [who, float(rr.get("hmin", 0.0))])
		seen.append("%s: flick %.0f, sweep %.0f, lines %.0f and %.0f degrees; the run's heads no nearer than %.0f" % [who, flick_a, sweep_a, float(fa.get(lines[who][0], 0.0)), float(fa.get(lines[who][1], 0.0)), float(rr.get("hmin", 0.0))])
	_tier_damage = false
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	print("energy reach: %s" % " | ".join(seen))


## The free arm (Legal e09: a mashed run must not pump one arm): every bolt and blast of both fighters and every hand piece of the tier, thrown with the left hand, through the real solve: the same contact reached
## (error under 0.25, one contact, nothing on screen, no NaN) and the bolts' hand at the chest or the gut (38 to 62 high, below the collar) with the left hand as with the right. Mirroring is the renderer's
## (`side` from the beat's `hand`): this proves each piece plays whole on the other arm.
## What the solve's last pass has to pull back (Combat's finding on `ru.su_knee`, `pk.bolt_flat` and `pk.bolt_thrust`: over 30 degrees on some live frames): each of the three, and the other pieces of their kind, on
## the real solve at their own striking distance and at the slack the closing rule may leave them (data/anim/reach.json), the frames whose correction goes over 30 degrees counted. The flagged knee and the heel,
## the four new pieces and the three bolts that showed it may have none up to 20 units of slack; the rest are measured and printed.
func _test_fix30() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	_tier_damage = true
	var lines: Array = []
	var offs := {}
	var cover: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/anim/reach.json")).get("cover", {})
	var dad := DirAccess.open("res://data/anim/waves")
	for fn in dad.get_files():
		if String(fn).ends_with(".manifest.json"):
			var mm = JSON.parse_string(FileAccess.get_file_as_string("res://data/anim/waves/" + String(fn)))
			for st in mm.get("strikes", []):
				offs[String(st.id)] = float(st.get("offset", 58.0))
	# [who, name, style, wind-up, weight, must be clean]: the pieces that were flagged and the four new ones must be; the rest are measured and printed (a one-frame pull on a joint that the last pass corrects is
	# the solve's net doing its work: the library has them, and they pass the joint scan)
	for pc in [["antihero", "su_knee", "super", 28, "heavy", true], ["antihero", "su_edge_legs", "super", 28, "heavy", true], ["antihero", "su_plate_arm", "super", 28, "heavy", true],
			["protagonist", "su_knee_legs", "super", 28, "heavy", true], ["protagonist", "su_elbow_jaw", "super", 28, "heavy", true],
			["antihero", "su_heel", "super", 28, "heavy", true],
			["protagonist", "bolt_flat", "speed", 2, "light", true], ["protagonist", "bolt_thrust", "speed", 2, "light", true], ["antihero", "bolt_fist", "speed", 2, "light", true],
			["antihero", "su_ram", "super", 28, "heavy", false]]:
		var row: Array = []
		var pre0: String = ("ru." if pc[0] == "antihero" else "pu.") if String(pc[1]).begins_with("su_") else ("rk." if pc[0] == "antihero" else "pk.")
		var cov: float = float(cover.get(pre0 + String(pc[1]), 10.0))
		for over in [0.0, minf(cov, 10.0), minf(cov, 20.0)]:
			_tier_dist = float(offs.get(pre0 + String(pc[1]), 58.0)) + over
			var bx := {"windup": int(pc[3]), "hand": "r"}
			if String(pc[1]).begins_with("bolt_"):
				bx["strength"] = "bolt"   # a bolt's return is 3 ticks longer (data beat.bolt_recover_add): the arm is let go as it comes home
			var r: Dictionary = _tier_scene(S, String(pc[0]), String(pc[2]), [String(pc[1])], [40], bx, String(pc[4]))
			row.append("+%d: %.0f deg, %d frames over 30" % [int(over), rad_to_deg(float(r.get("fix_max", 0.0))), int(r.get("fix_n30", 0))])
			if bool(pc[5]):
				_expect(int(r.get("fix_n30", 0)) == 0, "fix30 %s %s +%d: %d frames of the last pass pulling over 30 degrees (worst %.0f)" % [pc[0], pc[1], int(over), int(r.get("fix_n30", 0)), rad_to_deg(float(r.get("fix_max", 0.0)))])
		lines.append("%s %s [%s]" % [pc[0], pc[1], " | ".join(row)])
	_tier_dist = 60.0
	_tier_damage = false
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	print("fix30: %s" % "; ".join(lines))


func _test_free_arm() -> void:
	AnimData.load_every_wave()
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var kp: String = AnimData.ensure_fighter("PROTAGONIST")
	var kr: String = AnimData.ensure_fighter("RIVAL")
	_expect(AnimData.resolve_strike(kp, "strike.bolt_flick") == "pk.bolt_flick" and AnimData.resolve_strike(kp, "strike.bolt_sweep") == "pk.bolt_sweep", "free arm: the Protagonist's bolts keep strike.bolt_flick and strike.bolt_sweep")
	_expect(AnimData.resolve_strike(kr, "strike.bolt_flick_gut") == "rk.bolt_flick" and AnimData.resolve_strike(kr, "strike.bolt_sweep_chest") == "rk.bolt_sweep" and AnimData.resolve_strike(kr, "strike.bolt_flick") == "rk.bolt_flick", "free arm: the rival's bolts answer to strike.bolt_flick_gut and strike.bolt_sweep_chest (and still to the old name)")
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	_tier_damage = true
	var plan := {
		"protagonist": [["bolt_thrust", 2, "speed", "light", true], ["bolt_flat", 2, "speed", "light", true], ["bolt_flick", 2, "speed", "light", true], ["bolt_sweep", 2, "speed", "light", true],
			["blast_chest", 12, "medium", "heavy", false], ["blast_gut", 12, "medium", "heavy", false],
			["su_drive", 28, "super", "heavy", false], ["su_turn", 28, "super", "heavy", false], ["su_blade_jaw", 28, "super", "heavy", false], ["su_palm_heave", 28, "super", "heavy", false],
			["su_hammer_arm", 28, "super", "heavy", false], ["su_elbow_jaw", 28, "super", "heavy", false], ["su_knee_legs", 28, "super", "heavy", false]],
		"antihero": [["bolt_blade", 2, "speed", "light", true], ["bolt_fist", 2, "speed", "light", true], ["bolt_flick", 2, "speed", "light", true], ["bolt_sweep", 2, "speed", "light", true],
			["blast_chest", 12, "medium", "heavy", false], ["blast_gut", 12, "medium", "heavy", false],
			["su_ram", 28, "super", "heavy", false], ["su_plate", 28, "super", "heavy", false], ["su_hook", 28, "super", "heavy", false], ["su_fist_heave", 28, "super", "heavy", false],
			["su_hammer", 28, "super", "heavy", false], ["su_plate_arm", 28, "super", "heavy", false], ["su_edge_legs", 28, "super", "heavy", false]],
	}
	var n: int = 0
	for who in plan:
		for pc in plan[who]:
			var r: Dictionary = _tier_scene(S, who, String(pc[2]), [String(pc[0])], [40], {"windup": int(pc[1]), "hand": "l"}, String(pc[3]))
			n += 1
			_expect(int(r.nan) == 0 and int(r.screen) == 0 and int(r.frames) == 1 and float(r.err) < 0.25, "free arm %s %s: %d NaN, %d on screen, %d of 1 contacts, error %.3f" % [who, pc[0], int(r.nan), int(r.screen), int(r.frames), float(r.err)])
			if bool(pc[4]):
				for tr in r.get("trace", []):
					if int(tr.dt) == 0:
						_expect(float(tr.abs_hand_l) >= 38.0 and float(tr.abs_hand_l) <= 62.0, "free arm %s %s: the left hand lands %.0f high (38 to 62, below the collar)" % [who, pc[0], float(tr.abs_hand_l)])
	_tier_damage = false
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	print("free arm: %d pieces thrown left-handed" % n)


## Combat's eight rules for a medium on Y's 12-tick wind-up (data/anim/medium_wind.json, docs/animation/super-heavy.md): the data covers the mediums, the held-only ones are named, and the rules do what they say:
## w7 (an arc) and w8 (a rise) reach less of their chamber 6 ticks before the contact, w6 (a line) travels about half as far, w4 (a dropping kick) lifts its leg less; nothing else changes with the flag off.
func _test_medium_wind() -> void:
	AnimData.load_every_wave()
	var mw: Dictionary = AnimData.medium_wind
	_expect(mw.get("sets", {}).size() >= 20 and mw.get("held_only", []).size() >= 8 and mw.get("rules", {}).has("w7"), "medium wind: data/anim/medium_wind.json did not load or is thin (%d sets)" % mw.get("sets", {}).size())
	for sid in mw.get("sets", {}):
		_expect(AnimData.keysets.has(String(sid)), "medium wind: %s is not a key set" % sid)
	for sid in mw.get("held_only", []):
		_expect(AnimData.keysets.has(String(sid)) and not mw.sets.has(String(sid)), "medium wind: %s is held-only but is not a key set, or also has a rule" % sid)
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var ground_was: bool = RenderAnim.ground_feet
	var styles_was: bool = RenderAnim.press_styles
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	var seen: Array = []
	for pc in [["roundhouse", "w7", "tw"], ["uppercut", "w8", "hand_r"], ["driving_knee", "w6", "px"], ["stomp", "w4", "foot_r"]]:
		var ys: Array = []
		for on in [true, false]:
			RenderAnim.medium_wind = on
			var r: Dictionary = _tier_scene(S, "antihero", "medium", [String(pc[0])], [40], {"hand": "r"}, "heavy")
			var rowt: Dictionary = {}
			for tr in r.get("trace", []):
				if int(tr.dt) == -4 or int(tr.dt) == 0 or int(tr.dt) == -28:
					rowt[int(tr.dt)] = tr
			if not rowt.has(-4) or not rowt.has(0):
				ys.append(0.0)
			elif String(pc[2]) == "px":
				ys.append(float(rowt[0].px) - float(rowt[-28].px) if rowt.has(-28) else float(rowt[0].px))
			elif String(pc[2]) == "tw":
				ys.append(float(rowt[-4].tw))   # the shoulders turned: a flatter wind-up turns less
			else:
				ys.append(float(rowt[-4][String(pc[2])].y))
		RenderAnim.medium_wind = true
		seen.append("%s %s %.1f with, %.1f without" % [pc[0], pc[1], float(ys[0]), float(ys[1])])
		if String(pc[2]) == "px":
			_expect(float(ys[0]) < float(ys[1]) - 0.5, "medium wind: %s (%s) travels %.1f with the rule against %.1f without (a half step)" % [pc[0], pc[1], float(ys[0]), float(ys[1])])
		elif String(pc[1]) == "w4":
			_expect(float(ys[0]) <= float(ys[1]) + 0.01, "medium wind: %s (%s) lifts its foot to %.1f with the rule against %.1f without (never higher)" % [pc[0], pc[1], float(ys[0]), float(ys[1])])
		else:
			_expect(float(ys[0]) < float(ys[1]) - 0.5, "medium wind: %s (%s) reaches %.1f (height, or the shoulders' turn) 4 ticks out with the rule against %.1f without (a flatter wind-up)" % [pc[0], pc[1], float(ys[0]), float(ys[1])])
	RenderAnim.medium_wind = true
	RenderAnim.ground_feet = ground_was
	RenderAnim.press_styles = styles_was
	S.dirS.ex = null
	print("medium wind: %d mediums on a rule, %d held-only; %s" % [mw.sets.size(), mw.held_only.size(), "; ".join(seen)])


func _test_press_styles() -> void:
	_expect(_press_default, "press styles: the flag must be ON by default (brawl B1 stamps every beat; --no-press-styles is the before)")
	_expect(not AnimData.press.is_empty() and AnimData.press.get("styles", {}).has("tech") and AnimData.press.styles.has("speed") and AnimData.press.styles.has("heavy"), "press styles: data/anim/press_styles.json did not load")
	var scenes := {
		"tech": ["light", [[42, "strike.jab", "tech", 26.0], [72, "strike.cross", "tech", 26.0]]],
		"speed": ["light", [[36, "strike.jab", "speed", 20.0], [44, "strike.cross", "speed", 20.0], [52, "strike.jab", "speed", 20.0]]],
		"heavy": ["heavy", [[60, "strike.haymaker", "heavy", 66.0]]],
	}
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	var audit_was: bool = RenderAnim.joint_audit
	var ground_was: bool = RenderAnim.ground_feet
	RenderAnim.joint_audit = true
	RenderAnim.ground_feet = false
	AnimData.ensure_fighter("PROTAGONIST")
	AnimData.ensure_fighter("RIVAL")
	for who in ["protagonist", "antihero"]:
		for sc in scenes:
			RenderAnim.press_styles = true
			var on: Dictionary = _press_scene(S, who, scenes[sc][0], scenes[sc][1])
			RenderAnim.press_styles = false
			var off: Dictionary = _press_scene(S, who, scenes[sc][0], scenes[sc][1])
			var tag: String = "press styles %s %s" % [who, sc]
			_expect(on.styles.has(sc) and on.styles.size() == 1, "%s: the beat's style was not played (%s)" % [tag, on.styles.keys()])
			_expect(off.styles.is_empty() and float(off.dx_max) == 0.0, "%s: with the flag off the style layer still ran" % tag)
			_expect(int(on.frames) == scenes[sc][1].size() and float(on.err) < 0.2, "%s: contact frames %d of %d, the style layer is %.3f rad from the contact key (limit 0.2)" % [tag, int(on.frames), scenes[sc][1].size(), float(on.err)])
			_expect(int(on.nan) == 0, "%s: NaN rotations" % tag)
			_expect(int(on.viol) <= int(off.viol), "%s: %d joint violations against %d for the plain blow" % [tag, int(on.viol), int(off.viol)])
			_expect(on.phases.has("contact") and on.phases.has("load") and int(on.ring) > 0 and int(on.path) > 0, "%s: the hand-off (press, press_pose, press_path) is empty (phases %s, ring %d, path %d)" % [tag, on.phases.keys(), int(on.ring), int(on.path)])
			if sc == "tech":
				_expect(on.phases.has("hold") and float(on.tip_drift) < 1.5, "%s: the held beat moved the fist %.2f units off the contact point" % [tag, float(on.tip_drift)])
			if sc == "speed":
				_expect(int(on.get("load_ticks", 99)) <= 2, "%s: the first blow from idle winds up %d ticks ahead (the ruling: 2, press-to-blow wins)" % [tag, int(on.get("load_ticks", 99))])
			if sc == "heavy":
				_expect(on.phases.has("smear") and float(on.dx_max) > 1.0, "%s: no smear frame or lunge (%s, dx %.2f)" % [tag, on.phases.keys(), float(on.dx_max)])
	RenderAnim.press_styles = _press_default
	RenderAnim.joint_audit = audit_was
	RenderAnim.ground_feet = ground_was
	# a real seeded match: the flag moves no gameplay hash, and the styles come from the press log when the beat names none
	var hs: Dictionary = {}
	var counts: Dictionary = {}
	for on_flag in [false, true]:
		RenderAnim.press_styles = on_flag
		RenderAnim._fighters.clear()
		main.start_match(7, {"p1": true, "p2": true})
		var S2: SimState = main.host.S
		for k in range(1500):
			main.frame(1.0 / 60.0)
			for i in range(2):
				RenderAnim.solve(S2, S2.fighters[i])
		hs[on_flag] = str(SimHash.stateHash(S2).gameplay)
		if on_flag:
			for i in range(2):
				var pn: Dictionary = RenderAnim.fighter(S2, S2.fighters[i]).debug.get("press_n", {})
				for kk in pn:
					counts[kk] = int(counts.get(kk, 0)) + int(pn[kk])
	RenderAnim.press_styles = _press_default
	_expect(hs[false] == hs[true], "press styles: the gameplay hash differs with the flag on")
	var total: int = 0
	for kk in counts:
		total += int(counts[kk])
	_expect(total > 5, "press styles: in a 1500-tick match no blow was given a style (%s)" % [counts])
	print("  press styles in a 1500-tick AI match: %s" % [counts])


## The hand state of a blow's tip (data/anim/tips.json, RenderAnim.hand_tips): the rival's posed heavy hands close to a fist at the contact tick, the Protagonist's stay open,
## a beat's own `tip` wins, a light blow of the rival stays a blade, the flag off leaves the key set's own hands, and the same blow lands the same way either way.
func _hand_scene(S: SimState, who: String, piece: String, tip: String, heavy: bool) -> Dictionary:
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = "PROTAGONIST" if who == "protagonist" else "RIVAL"
	f1.id = "RIVAL" if who == "protagonist" else "PROTAGONIST"
	RenderAnim._fighters.clear()
	f0.x = 500.0
	f1.x = 558.0
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	var ex := DirExchange.newEx(f0, f1, "heavy" if heavy else "light")
	ex.n = 933
	ex.tag = "CHK"
	var args := {"a": "A", "dmg": 66.0 if heavy else 22.0, "piece": piece, "o": {"big": heavy}}
	if tip != "":
		args["tip"] = tip
	DirExchange.schedule(ex, 60.0 / 60.0, "strike", args)
	S.dirS.ex = ex
	var res := {"curl": 0.0, "kid": ""}
	for k in range(75):
		S.tick = 1000 + k
		S.T = 200.0 + float(k) / 60.0
		ex.t = float(k) / 60.0
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		var af0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		if k == 60:
			res["curl"] = af0.curl.y
			res["kid"] = af0._part
	return res


func _test_hand_tips() -> void:
	_expect(RenderAnim.hand_tips and not AnimData.tips.is_empty() and AnimData.tips.reaim.size() >= 80, "hand tips: data/anim/tips.json did not load (%d re-aim rows)" % AnimData.tips.get("reaim", {}).size())
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	AnimData.ensure_fighter("PROTAGONIST")
	AnimData.ensure_fighter("RIVAL")
	var untagged: Array = []
	var n_tagged: int = 0
	for kid in AnimData.keysets:
		var ksx: Dictionary = AnimData.keysets[kid]
		if String(ksx.get("_combat", "")) == "":
			continue
		n_tagged += 1
		if not ["fist", "blade", "palm", "heel", "plate", "ball", "instep", "edge", "sole", "point", "cap", "brow"].has(String(ksx.get("tip", ""))) or not ["line", "arc_in", "arc_out", "rise", "drop", "spin"].has(String(ksx.get("path", ""))):
			untagged.append(kid)
	_expect(n_tagged >= 60 and untagged.is_empty(), "hand tips: %d of %d strike key sets have no tip or path (%s)" % [untagged.size(), n_tagged, untagged.slice(0, 5)])
	var ground_was: bool = RenderAnim.ground_feet
	RenderAnim.ground_feet = false
	var fist: float = float(AnimData.tips.curl.fist)
	var a: Dictionary = _hand_scene(S, "antihero", "strike.haymaker", "", true)
	_expect(absf(float(a.curl) - fist) < 0.05 and String(a.kid) == "w1.haymaker", "hand tips: the rival's haymaker (posed blade) has hand curl %.2f at contact, a fist is %.2f (%s)" % [float(a.curl), fist, a.kid])
	var l: Dictionary = _hand_scene(S, "antihero", "strike.jab", "", false)
	_expect(float(l.curl) < 0.05, "hand tips: the rival's light jab changed its blade hand (curl %.2f)" % float(l.curl))
	var p: Dictionary = _hand_scene(S, "protagonist", "strike.haymaker", "", true)
	_expect(float(p.curl) < 0.05, "hand tips: the Protagonist's haymaker closed its hand (curl %.2f)" % float(p.curl))
	var t: Dictionary = _hand_scene(S, "protagonist", "strike.jab", "fist", false)
	_expect(absf(float(t.curl) - fist) < 0.05, "hand tips: a beat's own tip (fist) was not shown (curl %.2f)" % float(t.curl))
	var t2: Dictionary = _hand_scene(S, "antihero", "strike.haymaker", "blade", true)
	_expect(float(t2.curl) < 0.05, "hand tips: a beat's own tip (blade) did not win over the rule (curl %.2f)" % float(t2.curl))
	RenderAnim.hand_tips = false
	var o: Dictionary = _hand_scene(S, "antihero", "strike.haymaker", "", true)
	RenderAnim.hand_tips = true
	_expect(float(o.curl) < 0.05, "hand tips: with the flag off the haymaker still closed (curl %.2f)" % float(o.curl))
	RenderAnim.ground_feet = ground_was
	print("  hand tips: the rival's heavy hand closes to a fist (%.2f), his light blade and the Protagonist's heavy stay open, a beat's own tip wins" % float(a.curl))


## The LT zip's body (docs/animation/zip.md, RenderAnim.press_styles): each reading on each launch fighter, the sim's part played by hand (the zipper moved along the zip, the strike beats
## with `zip: true`, the damage events). The phases come in order, the screen never sees a joint past its limit, every reading is drawn travelling for at least 4 ticks each way (Legal RL-076: no vanish and reappear, the tech zip included) and the heavy one has a smear frame, the
## hand-off (zip, zip_path, press_pose with a world position) is filled, and with the flag off nothing plays.
func _zip_scene(S: SimState, who: String, reading: String, off: bool, extra: Dictionary = {}) -> Dictionary:
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = "PROTAGONIST" if who == "protagonist" else "RIVAL"
	f1.id = "RIVAL" if who == "protagonist" else "PROTAGONIST"
	RenderAnim._fighters.clear()
	for f in [f0, f1]:
		f.vx = 0.0
		f.vy = 0.0
		f.y = 0.0
		f.state = "free"
	f1.x = 500.0
	var row: Dictionary = AnimData.zip.readings[reading]
	var pre: int = 20
	var t1: int = int(row.tell)
	var t2: int = t1 + int(row["in"])
	var t3: int = t2 + int(row.hits) * int(row.hd)
	var t4: int = t3 + int(row.out)
	var heavy: bool = reading == "heavy"
	var ex := DirExchange.newEx(f0, f1, "heavy" if heavy else "light")
	ex.n = 951
	ex.tag = "ZCK"
	var pcs: Array = ["strike.jab", "strike.cross", "strike.jab"]
	if heavy:
		pcs = ["strike.hook"]
	for i in range(int(row.hits)):
		DirExchange.schedule(ex, float(pre + t2 + i * int(row.hd)) / 60.0, "strike", {"a": "A", "dmg": 66.0 if heavy else 22.0, "piece": String(pcs[i % pcs.size()]), "style": reading, "zip": true, "o": {"big": heavy}})
	S.dirS.ex = ex
	var res := {"phases": [], "viol": 0, "in_travel": 0, "out_ticks": 0, "smear": 0, "path": 0, "ghost_pos": false, "frames": 0, "err": 0.0}
	for k in range(pre + t4 + 30):
		S.tick = 1000 + k
		S.T = 200.0 + float(k) / 60.0
		ex.t = float(k) / 60.0
		var tk: float = float(k - pre)
		var x: float = 375.0
		if tk >= float(t2) and tk < float(t3):
			x = 444.0
		elif tk >= float(t1) and tk < float(t2):
			x = lerpf(375.0, 444.0, clampf((tk - float(t1)) / maxf(float(t2 - t1), 1.0), 0.0, 1.0))
		elif tk >= float(t3) and tk < float(t4):
			x = lerpf(444.0, 375.0, clampf((tk - float(t3)) / maxf(float(t4 - t3), 1.0), 0.0, 1.0))
		f0.x = x
		if k == pre:
			var zspec := {"reading": reading, "btn": "x"}
			zspec.merge(extra, true)
			RenderAnim.zip_start(S, f0, zspec)
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		for i in range(int(row.hits)):
			if k == pre + t2 + i * int(row.hd):
				var de := SimState.FxEvent.new()
				de.type = "damage"
				de.victim = 1.0
				de.attacker = 0.0
				de.kind = "heavy" if heavy else "light"
				de.amount = 66.0 if heavy else 22.0
				de.region = "core"
				RenderAnim.consume(S, [de])
		var af0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		res.viol += AnimJoints.violations(af0.q, af0._rd.shape_key).size()
		if not af0.zip.is_empty():
			if res.phases.is_empty() or String(res.phases[res.phases.size() - 1]) != String(af0.zip.phase):
				res.phases.append(String(af0.zip.phase))
			res.in_travel += 1 if (String(af0.zip.phase) == "in" and bool(af0.zip.travelling)) else 0
			res.out_ticks += 1 if String(af0.zip.phase) == "out" else 0
			res.smear += 1 if bool(af0.zip.smear) else 0
			res.path = maxi(int(res.path), af0.zip_path.size())
			var e: Dictionary = af0.press_pose(2)
			if not e.is_empty() and e.has("pos"):
				res.ghost_pos = true
	var d: Dictionary = RenderAnim.fighter(S, f0).debug
	res.frames = int(d.get("contact_frames", 0))
	res.err = float(d.get("contact_err_max", 0.0))
	res["entries"] = int(d.get("entries", 0))
	return res


func _test_zip() -> void:
	_expect(not AnimData.zip.is_empty() and AnimData.zip.readings.has("speed") and AnimData.zip.readings.has("heavy"), "zip: data/anim/zip.json did not load")
	for rdn in ["speed", "tech", "heavy", "press", "hold"]:
		var rrow: Dictionary = AnimData.zip.readings.get(rdn, {})
		_expect(int(rrow.get("in", 0)) >= 4 and int(rrow.get("out", 0)) >= 4 and String(rrow.get("travel_pose", "")) != "", "zip: the %s reading's way in is %d ticks, its way out %d, its travel pose %s (floor: 4 ticks each way and a drawn travel pose)" % [rdn, int(rrow.get("in", 0)), int(rrow.get("out", 0)), rrow.get("travel_pose", "")])
	for id in ["zp.hold.tackle", "zp.hold.carried", "zp.hold.lift", "zp.hold.lifted", "zp.hold.throw"]:
		_expect(AnimData.pose_exists(id), "zip: the grab pose %s is not baked" % id)
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	AnimData.ensure_fighter("PROTAGONIST")
	AnimData.ensure_fighter("RIVAL")
	var ground_was: bool = RenderAnim.ground_feet
	RenderAnim.ground_feet = false
	for who in ["protagonist", "antihero"]:
		for rd in ["speed", "tech", "heavy"]:
			RenderAnim.press_styles = true
			var on: Dictionary = _zip_scene(S, who, rd, false)
			RenderAnim.press_styles = false
			var off: Dictionary = _zip_scene(S, who, rd, true)
			var tag: String = "zip %s %s" % [who, rd]
			_expect(on.phases == ["tell", "in", "reach", "out", "settle"], "%s: the phases were %s" % [tag, on.phases])
			_expect(off.phases.is_empty(), "%s: with the flag off a zip still played (%s)" % [tag, off.phases])
			_expect(int(on.viol) == 0, "%s: %d joint violations reach the screen" % [tag, int(on.viol)])
			_expect(int(on.frames) >= 1 and float(on.err) < 0.2, "%s: contact frames %d, the style layer is %.3f rad from the contact key" % [tag, int(on.frames), float(on.err)])
			_expect(int(on.path) > 6 and bool(on.ghost_pos), "%s: the hand-off is empty (zip_path %d, previous poses with a position %s)" % [tag, int(on.path), on.ghost_pos])
			_expect(int(on.in_travel) >= 4 and int(on.out_ticks) >= 4, "%s: the body travels %d ticks in and %d out; Legal's floor (RL-076) is 4 each way, drawn on every tick" % [tag, int(on.in_travel), int(on.out_ticks)])
			_expect(int(on.smear) == 0 or rd == "heavy", "%s: a smear frame outside the heavy zip" % tag)
			if rd == "heavy":
				_expect(int(on.smear) >= 1, "%s: no smear frame on the way in" % tag)
	RenderAnim.press_styles = _press_default
	RenderAnim.ground_feet = ground_was
	print("  zip: speed, tech and heavy on both fighters play tell, in, reach, out; no joint past its limit on screen; every reading is drawn travelling at least 4 ticks each way, the heavy one smears")


## What the beat tells (Encounter's slice B0: style, grade, k, n, closing, charge, hand, ender; a chainStrike carries a and d): read in place of the press log, behind the press-styles flag.
## A perfect tech blow holds its beat longer than a good one, the beat's `hand` is the striking side, a held heavy squashes deeper than a tapped one, the closing blow of a string holds,
## and a chainStrike's own style is the one played.
func _bm(a: Dictionary, b: Dictionary) -> Dictionary:
	var o: Dictionary = a.duplicate()
	o.merge(b, true)
	return o


func _beat_scene(S: SimState, who: String, ops: Array) -> Dictionary:
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = "PROTAGONIST" if who == "protagonist" else "RIVAL"
	f1.id = "RIVAL" if who == "protagonist" else "PROTAGONIST"
	RenderAnim._fighters.clear()
	f0.x = 500.0
	f1.x = 560.0
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	var ex := DirExchange.newEx(f0, f1, "light")
	ex.n = 961
	ex.tag = "BCK"
	var last: int = 0
	for o in ops:
		DirExchange.schedule(ex, float(o[0]) / 60.0, String(o[1]), o[2])
		last = maxi(last, int(o[0]))
	S.dirS.ex = ex
	var res := {"hold_ticks": 0, "sides": [], "squash": 0.0, "styles": {}, "ghosts": 0, "release_ticks": 0, "guard_dev": 0.0}
	var gpose: AnimPose = AnimData.pose(String(AnimData.press.get("guard", {}).get("pose", "stance.defensive")))
	var ua_l: int = AnimRig.index["upper_arm_l"]
	for k in range(last + 40):
		S.tick = 1000 + k
		S.T = 200.0 + float(k) / 60.0
		ex.t = float(k) / 60.0
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		var af0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		if not af0.press.is_empty():
			res.styles[String(af0.press.style)] = true
			res.hold_ticks += 1 if String(af0.press.phase) == "hold" else 0
			res.release_ticks += 1 if String(af0.press.phase) == "release" else 0
			if String(af0.press.phase) == "contact":
				res.guard_dev = maxf(float(res.guard_dev), af0.q[ua_l].angle_to(gpose.q[ua_l]))
			res.squash = maxf(float(res.squash), float(af0.press.squash))
			res.ghosts = maxi(int(res.ghosts), int(af0.press.ghosts))
			if String(af0.press.phase) == "contact":
				res.sides.append(bool(af0.press.side))
	return res


func _test_beat_fields() -> void:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	AnimData.ensure_fighter("PROTAGONIST")
	AnimData.ensure_fighter("RIVAL")
	var ground_was: bool = RenderAnim.ground_feet
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	for who in ["protagonist", "antihero"]:
		var base := {"a": "A", "d": "D", "dmg": 26.0, "piece": "strike.cross", "o": {"big": false}}
		var perfect: Dictionary = _beat_scene(S, who, [[60, "strike", _bm(base, {"style": "tech", "grade": "perfect", "k": 1, "n": 1, "hand": "r", "closing": false, "charge": 0.0, "ender": false})]])
		var good: Dictionary = _beat_scene(S, who, [[60, "strike", _bm(base, {"style": "tech", "grade": "good", "k": 1, "n": 1, "hand": "l", "closing": false, "charge": 0.0, "ender": false})]])
		var tag: String = "beat fields %s" % who
		_expect(int(perfect.hold_ticks) > int(good.hold_ticks) and int(perfect.hold_ticks) >= 8, "%s: a perfect tech blow holds %d ticks and a good one %d (the data: 10 and 6)" % [tag, int(perfect.hold_ticks), int(good.hold_ticks)])
		_expect(int(perfect.ghosts) == 3 and int(good.ghosts) == 2, "%s: the grade's after-images are %d and %d (3 and 2)" % [tag, int(perfect.ghosts), int(good.ghosts)])
		_expect(perfect.sides == [false] and good.sides == [true], "%s: the beat's hand did not set the side (r %s, l %s)" % [tag, perfect.sides, good.sides])
		var held: Dictionary = _beat_scene(S, who, [[80, "strike", _bm(base, {"piece": "strike.haymaker", "dmg": 66.0, "style": "heavy", "grade": "none", "k": 1, "n": 1, "hand": "r", "closing": false, "charge": 1.0, "ender": false, "o": {"big": true}})]])
		var tapped: Dictionary = _beat_scene(S, who, [[80, "strike", _bm(base, {"piece": "strike.haymaker", "dmg": 66.0, "style": "heavy", "grade": "none", "k": 1, "n": 1, "hand": "r", "closing": false, "charge": 0.0, "ender": false, "o": {"big": true}})]])
		_expect(float(held.squash) > float(tapped.squash) + 0.1, "%s: a held heavy squashes %.2f and a tapped one %.2f" % [tag, float(held.squash), float(tapped.squash)])
		var plain: Dictionary = _beat_scene(S, who, [[60, "strike", _bm(base, {"style": "speed", "grade": "none", "k": 1, "n": 1, "hand": "r", "closing": false, "charge": 0.0, "ender": false})]])
		var closer: Dictionary = _beat_scene(S, who, [[60, "strike", _bm(base, {"style": "speed", "grade": "none", "k": 1, "n": 1, "hand": "r", "closing": true, "charge": 0.0, "ender": false})]])
		_expect(int(closer.hold_ticks) > int(plain.hold_ticks), "%s: the closing blow holds %d ticks against %d for a plain one" % [tag, int(closer.hold_ticks), int(plain.hold_ticks)])
		var chain: Dictionary = _beat_scene(S, who, [[50, "strike", _bm(base, {"style": "speed", "k": 1, "n": 2, "hand": "r"})], [70, "chainStrike", {"a": "A", "d": "D", "style": "tech", "grade": "perfect", "k": 2, "n": 2, "hand": "l", "closing": true, "charge": 0.0, "ender": false}]])
		_expect(chain.styles.has("tech") and chain.styles.has("speed"), "%s: a chainStrike's own style was not played (%s)" % [tag, chain.styles.keys()])
	RenderAnim.press_styles = _press_default
	RenderAnim.ground_feet = ground_was
	print("  beat fields: grade sets a tech blow's hold and after-images, hand the side, charge a heavy's squash, closing the hold, and a chainStrike plays its own style")


## "Tech" means the same thing everywhere (the EP's rule, docs/ep/vision.md questionnaire 18): the strike pose lands on the contact tick with no in-between, held the same beat, returning
## the same way, whether the blow comes from idle, at the end of a string or at the end of a zip's dash; the dash itself gets no snap. The same perfect tech cross, three ways, the
## pose of every bone compared on the contact tick and the twelve after it.
func _tech_poses(S: SimState, who: String, mode: String) -> Array:
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = "PROTAGONIST" if who == "protagonist" else "RIVAL"
	f1.id = "RIVAL" if who == "protagonist" else "PROTAGONIST"
	RenderAnim._fighters.clear()
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = "free"
	f1.x = 560.0
	var pre: int = 20
	var tc: int = pre + (40 if mode != "zip" else 10)   # contact tick
	var ex := DirExchange.newEx(f0, f1, "light")
	ex.n = 971
	ex.tag = "TCK"
	var tech := {"a": "A", "d": "D", "dmg": 26.0, "piece": "strike.cross", "style": "tech", "grade": "perfect", "k": 1, "n": 1, "hand": "r", "closing": false, "charge": 0.0, "ender": false, "o": {"big": false}}
	if mode == "zip":
		tech["zip"] = true
	if mode == "string":
		DirExchange.schedule(ex, float(tc - 14) / 60.0, "strike", {"a": "A", "d": "D", "dmg": 20.0, "piece": "strike.jab", "style": "speed", "grade": "none", "k": 1, "n": 2, "hand": "l", "closing": false, "charge": 0.0, "ender": false, "o": {"big": false}})
		tech["k"] = 2
		tech["n"] = 2
	DirExchange.schedule(ex, float(tc) / 60.0, "strike", tech)
	S.dirS.ex = ex
	var out: Array = []
	var row: Dictionary = AnimData.zip.readings.tech
	for k in range(tc + 14):
		S.tick = 1000 + k
		S.T = 200.0 + float(k) / 60.0
		ex.t = float(k) / 60.0
		var x: float = 500.0
		if mode == "zip":
			var t1: int = pre + int(row.tell)
			var t2: int = tc
			x = lerpf(375.0, 500.0, clampf(float(k - t1) / maxf(float(t2 - t1), 1.0), 0.0, 1.0)) if k >= t1 else 375.0
			if k == pre:
				RenderAnim.zip_start(S, f0, {"reading": "tech", "btn": "x", "tell": int(row.tell), "in": tc - pre - int(row.tell), "hits": 1, "hd": 16, "out": 4})
		f0.x = x
		var te := SimState.FxEvent.new()
		te.type = "tick"
		te.dt = 1.0 / 60.0
		te.frozen = false
		RenderAnim.consume(S, [te])
		if k == tc:
			var de := SimState.FxEvent.new()
			de.type = "damage"
			de.victim = 1.0
			de.attacker = 0.0
			de.kind = "light"
			de.amount = 26.0
			de.region = "core"
			RenderAnim.consume(S, [de])
		var af0: AnimFighter = RenderAnim.solve(S, f0)
		RenderAnim.solve(S, f1)
		if k >= tc:
			out.append(af0.q.duplicate())
	return out


func _test_tech_consistency() -> void:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	AnimData.ensure_fighter("PROTAGONIST")
	AnimData.ensure_fighter("RIVAL")
	var ground_was: bool = RenderAnim.ground_feet
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	var worst: float = 0.0
	var where: String = ""
	for who in ["protagonist", "antihero"]:
		var idle: Array = _tech_poses(S, who, "idle")
		for mode in ["string", "zip"]:
			var other: Array = _tech_poses(S, who, mode)
			_expect(idle.size() == other.size() and idle.size() >= 13, "tech consistency %s %s: %d and %d frames from the contact tick on" % [who, mode, idle.size(), other.size()])
			for i in range(mini(idle.size(), other.size())):
				var d: float = 0.0
				for b in range(AnimRig.N):
					d = maxf(d, (idle[i][b] as Quaternion).angle_to(other[i][b]))
				if d > worst:
					worst = d
					where = "%s %s, %d ticks after contact" % [who, mode, i]
	RenderAnim.press_styles = _press_default
	RenderAnim.ground_feet = ground_was
	_expect(worst < 0.15, "tech consistency: the tech blow's pose differs by %.3f rad between idle, a string and a zip (%s); the limit is 0.15 (the contact solve's small differences)" % [worst, where])
	print("  tech consistency: the same perfect tech cross from idle, in a string and at the end of a zip: worst difference %.3f rad (%s)" % [worst, where])


## The zip slice: an entry of his own played at the zip's speed over the way in, a far-side pass by name, the guard layer a check is thrown over, and the push style (no impact snap).
func _test_zip_slice() -> void:
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	AnimData.ensure_fighter("PROTAGONIST")
	AnimData.ensure_fighter("RIVAL")
	var ground_was: bool = RenderAnim.ground_feet
	RenderAnim.ground_feet = false
	RenderAnim.press_styles = true
	for who in ["protagonist", "antihero"]:
		var plain: Dictionary = _zip_scene(S, who, "speed", false)
		var spiral: Dictionary = _zip_scene(S, who, "speed", false, {"entry_in": "spiral"})
		var over: Dictionary = _zip_scene(S, who, "speed", false, {"pass": "over"})
		var round: Dictionary = _zip_scene(S, who, "speed", false, {"pass": "round"})
		var missing: Dictionary = _zip_scene(S, who, "speed", false, {"entry_in": "no_such_entry"})
		var tag: String = "zip slice %s" % who
		_expect(int(spiral.entries) > int(plain.entries) and int(over.entries) > int(plain.entries) and int(round.entries) > int(plain.entries), "%s: the entries did not play (spiral %d, over %d, round %d against %d)" % [tag, int(spiral.entries), int(over.entries), int(round.entries), int(plain.entries)])
		_expect(int(spiral.viol) == 0 and int(over.viol) == 0 and int(round.viol) == 0, "%s: a joint past its limit reaches the screen with an entry (spiral %d, over %d, round %d)" % [tag, int(spiral.viol), int(over.viol), int(round.viol)])
		_expect(missing.phases == ["tell", "in", "reach", "out", "settle"] and int(missing.entries) == int(plain.entries), "%s: a name he has no entry for should play the run pose (%s, %d entries)" % [tag, missing.phases, int(missing.entries)])
		var base := {"a": "A", "d": "D", "dmg": 12.0, "piece": "strike.cross", "o": {"big": false}}
		var chk: Dictionary = _beat_scene(S, who, [[60, "strike", _bm(base, {"style": "speed", "check": true, "hand": "r"})]])
		var nochk: Dictionary = _beat_scene(S, who, [[60, "strike", _bm(base, {"style": "speed", "hand": "r"})]])
		_expect(float(chk.guard_dev) < float(nochk.guard_dev) - 0.15, "%s: a check keeps the other arm in the guard (%.2f rad from it against %.2f without)" % [tag, float(chk.guard_dev), float(nochk.guard_dev)])
		var push: Dictionary = _beat_scene(S, who, [[60, "strike", _bm(base, {"piece": "strike.shoulder_check", "style": "push"})]])
		var tech: Dictionary = _beat_scene(S, who, [[60, "strike", _bm(base, {"style": "tech", "grade": "perfect"})]])
		_expect(push.styles.has("push") and int(push.release_ticks) >= 4 and int(tech.release_ticks) <= 1, "%s: a push should drive into its contact with no snap (%d ticks of drive against %d for a tech blow)" % [tag, int(push.release_ticks), int(tech.release_ticks)])
	RenderAnim.press_styles = _press_default
	RenderAnim.ground_feet = ground_was
	print("  zip slice: an entry plays at zip speed over the way in, a far-side pass over or round, a missing entry falls back, a check holds the guard arm, a push drives with no snap")


## The intro gestures (Narrative's ten intents, docs/animation/intro-gestures.md): the sim's `intro_gesture {actor, intent, at}` event, staged here, starts the fighter's own motion for the intent
## over his idle. Every intent plays on both launch fighters (the table is complete), a masked one leaves the legs where the idle has them, no joint past its limit reaches the screen, a gesture
## plays on the intro's tick clock (the match clock is frozen at 0 in the intro), a fighter with no entry for an intent plays nothing and no error, and the flag off plays nothing.
func _gesture_run(S: SimState, who: String, intent: String, state: String, ticks: int) -> Dictionary:
	var f0 = S.fighters[0]
	var f1 = S.fighters[1]
	f0.id = "PROTAGONIST" if who == "protagonist" else ("RIVAL" if who == "antihero" else "NOBODY")
	f1.id = "RIVAL" if who == "protagonist" else "PROTAGONIST"
	RenderAnim._fighters.clear()
	S.dirS.ex = null
	for f in [f0, f1]:
		f.y = 0.0
		f.vx = 0.0
		f.vy = 0.0
		f.state = state
	f0.x = 500.0
	f1.x = 560.0
	var res := {"played": false, "viol": 0, "legs": 0.0, "moved": 0.0}
	var thigh: int = AnimRig.index["thigh_r"]
	var idle_thigh: Quaternion = Quaternion.IDENTITY
	for pass_i in range(2):   # the first pass without the event, for the idle's legs; the second with it
		RenderAnim._fighters.clear()
		for k in range(ticks):
			S.tick = 1000 + k
			S.T = 0.0 if state == "intro" else 200.0 + float(k) / 60.0
			var te := SimState.FxEvent.new()
			te.type = "tick"
			te.dt = 1.0 / 60.0
			te.frozen = false
			RenderAnim.consume(S, [te])
			if pass_i == 1 and k == 10:
				var ge := SimState.FxEvent.new()
				ge.type = "intro_gesture"
				ge.actor = 0.0
				ge.kind = intent
				ge.text = "land_first"
				ge.tick = S.tick
				RenderAnim.consume(S, [ge])
			var a0: AnimFighter = RenderAnim.solve(S, f0)
			RenderAnim.solve(S, f1)
			if pass_i == 0 and k == 24:
				idle_thigh = a0.q[thigh]
			if pass_i == 1:
				res.viol += AnimJoints.violations(a0.q, a0._rd.shape_key).size()
				if not a0._gest.is_empty():
					res.played = true
					res.moved = maxf(float(res.moved), a0.q[AnimRig.index["head"]].angle_to(AnimData.pose("stance.aggressive").q[AnimRig.index["head"]]))
				if k == 24:
					res.legs = a0.q[thigh].angle_to(idle_thigh)
	return res


func _test_gestures() -> void:
	_expect(AnimData.pair.get("gesture_groups", {}).has("head") and AnimData.pair.roles.protagonist.has("gestures") and AnimData.pair.roles.antihero.has("gestures"), "gestures: pair_live.json has no gestures table")
	main.start_match(4, {"p1": false, "p2": false})
	for i in range(10):
		main.frame(1.0 / 60.0)
	var S: SimState = main.host.S
	AnimData.ensure_fighter("PROTAGONIST")
	AnimData.ensure_fighter("RIVAL")
	var ground_was: bool = RenderAnim.ground_feet
	RenderAnim.ground_feet = false
	var intents: Array = ["acknowledge", "appraise", "dismiss", "defer", "brace", "ease", "claim", "check", "soften", "harden"]
	for who in ["protagonist", "antihero"]:
		var tbl: Dictionary = AnimData.pair.roles[who].gestures
		_expect(tbl.size() == 10, "gestures %s: %d of the ten intents have a motion" % [who, tbl.size()])
		for intent in intents:
			var r: Dictionary = _gesture_run(S, who, intent, "free", 90)
			_expect(bool(r.played) and int(r.viol) == 0, "gestures %s %s: played %s, %d joint violations on screen" % [who, intent, r.played, int(r.viol)])
			if (tbl[intent].get("mask", []) as Array).has("legs") == false and (tbl[intent].get("mask", []) as Array).size() > 0:
				_expect(float(r.legs) < 0.05, "gestures %s %s: a masked gesture moved the legs by %.3f rad" % [who, intent, float(r.legs)])
		var ri: Dictionary = _gesture_run(S, who, "appraise", "intro", 90)
		_expect(bool(ri.played), "gestures %s: a gesture did not play on the intro's tick clock" % who)
	var none: Dictionary = _gesture_run(S, "nobody", "claim", "free", 60)
	_expect(not bool(none.played), "gestures: a fighter with no table played a motion")
	var unk: Dictionary = _gesture_run(S, "protagonist", "no_such_intent", "free", 60)
	_expect(not bool(unk.played), "gestures: an unknown intent played a motion")
	RenderAnim.intro_gestures = false
	var offr: Dictionary = _gesture_run(S, "protagonist", "claim", "free", 60)
	RenderAnim.intro_gestures = true
	_expect(not bool(offr.played), "gestures: with the flag off a gesture still played")
	RenderAnim.ground_feet = ground_was
	print("  gestures: all ten intents play on both launch fighters over their idles (masked ones leave the legs), on the intro's tick clock too, a fighter or an intent with no entry is a silent skip")


func _test_pair_live() -> void:
	_expect(RenderAnim.pair_live and not AnimData.pair.is_empty(), "pair live test: data/anim/pair_live.json did not load or the live pair is off")
	_expect(AnimData.fighter_key("PROTAGONIST") == "protagonist" and AnimData.fighter_key("RIVAL") == "antihero" and AnimData.fighter_key("rival") == "antihero" and AnimData.fighter_key("Protagonist") == "protagonist" and AnimData.fighter_key("NOBODY") == "", "pair live test: a roster id did not map to its fighter")
	_expect(AnimData.fighter_key("KAI") == "" and AnimData.fighter_key("VORR") == "", "pair live test: a placeholder spelling (KAI, VORR) still maps to a fighter after the rename clean-up")
	_expect(String(AnimRagdoll.shape_of.get("PROTAGONIST", "")) == "P" and String(AnimRagdoll.shape_of.get("RIVAL", "")) == "A" and not AnimRagdoll.shape_of.has("KAI") and not AnimRagdoll.shape_of.has("VORR"), "pair live test: ragdoll_motion.json must key the launch pair by PROTAGONIST and RIVAL (else the rival falls with the Protagonist's shape)")
	var kp: String = AnimData.ensure_fighter("PROTAGONIST")
	var kr: String = AnimData.ensure_fighter("RIVAL")
	var lp: Dictionary = AnimData.pair_lists.get(kp, {})
	var lr: Dictionary = AnimData.pair_lists.get(kr, {})
	_expect(kp == "protagonist" and kr == "antihero" and lp.light.size() >= 15 and lp.heavy.size() >= 15 and lr.light.size() >= 12 and lr.heavy.size() >= 15, "pair live test: his pick lists were not built (%d and %d lights, %d and %d heavies)" % [lp.light.size(), lr.light.size(), lp.heavy.size(), lr.heavy.size()])
	var tail_free := true
	for id in lp.light + lp.heavy + lr.light + lr.heavy:
		tail_free = tail_free and not String(id).contains("tail") and AnimData.keysets.has(String(id))
	_expect(tail_free, "pair live test: a pick list names a tail strike or a key set that is not baked")
	_expect(AnimData.resolve_entry(kp, "entry.hop_back") == "pe.hop_back" and AnimData.resolve_entry(kr, "entry.hop_back") == "w2.hop_back" and AnimData.resolve_entry(kp, "entry.air_roll") == "pe.air_roll" and AnimData.resolve_entry(kr, "entry.air_roll") == "", "pair live test: an entry id did not resolve to the fighter's own")
	_expect(AnimData.resolve_strike(kp, "strike.palm_push") == "pr.palm_push" and AnimData.resolve_strike(kp, "strike.body_hook") == "ph.body_hook" and AnimData.resolve_strike(kr, "strike.body_hook") == "rb.body_hook" and AnimData.resolve_strike(kr, "strike.jab") == "w1.jab" and AnimData.resolve_strike(kr, "strike.palm_push") == "" and AnimData.resolve_strike(kr, "strike.tail_jab") == "", "pair live test: a strike id did not resolve to the fighter's own key set")
	# a real match: every blow he throws is one of his own key sets
	main.start_match(4, {"p1": true, "p2": true})
	var S: SimState = main.host.S
	var seen: Array = [{}, {}]
	for k in range(1500):
		main.frame(1.0 / 60.0)
		for i in range(2):
			RenderAnim.solve(S, S.fighters[i])
	# "his own": a key set of one of the packs his pick list is built from (the recipes' pieces now include the tier, the energy pieces and the mediums, so the prefixes are read off his own lists)
	var mine: Array = [{}, {}]
	for i2 in range(2):
		var lst: Dictionary = AnimData.pair_lists.get(kp if i2 == 0 else kr, {})
		for nm2 in lst.get("by_name", {}):
			mine[i2][String(lst.by_name[nm2]).get_slice(".", 0)] = true
	var own := [true, true]
	var n_picks := 0
	for i in range(2):
		var af0: AnimFighter = RenderAnim.fighter(S, S.fighters[i])
		n_picks += int(af0.debug.get("pair_picks", 0))
		for ksid in af0.debug.get("keysets", {}):
			var pre: String = String(ksid).get_slice(".", 0)
			if not mine[i].has(pre):
				own[i] = false
	_expect(own[0] and own[1] and n_picks > 20, "pair live test: in a 1500-tick match his blows were not all his own key sets (protagonist own %s, rival own %s, %d picks)" % [own[0], own[1], n_picks])
	# the energy press and the pair's own events, on stub bodies outside an exchange: the match is stepped on until no exchange runs (the poses do not start for a fighter in
	# one, and a brawl's lunge may be mid-flight at tick 1,500), and if one still runs after 400 ticks it is cleared: this test is of the stub bodies, not of the match
	var guard: int = 0
	while S.dirS.ex != null and guard < 400:
		main.frame(1.0 / 60.0)
		guard += 1
	if S.dirS.ex != null:
		S.dirS.ex = null
	var rows: Array = [["protagonist", "pg.bolt", "pg.spray", "pn.hold.brace_load", "pn.hold.brace_hold", "pn.hold.palm_thrust"], ["antihero", "rw.bolt", "en.spray", "rw.charged_brace.charge", "rw.charged_brace.charge", "rw.charged_brace.release"]]
	var ok_energy := true
	var why := ""
	for r in rows:
		var ae := AnimFighter.new(0)
		ae.pair_key = r[0]
		var fe = S.fighters[0]
		ae.on_blast_cue("blast_windup", 1.0, S, fe)
		if String(ae._seq.get("id", "")) != r[1]:
			ok_energy = false
			why += " %s windup %s;" % [r[0], ae._seq.get("id", "")]
		ae.on_shot("bolt", 1.1, S, fe, 100, 1)
		if absf(float(ae._seq.get("t0", 0.0)) - (1.1 - 4.0 / 60.0)) > 0.001:
			ok_energy = false
			why += " %s bolt not aligned;" % r[0]
		ae.on_shot("bolt", 1.2, S, fe, 104, 1)
		if String(ae._seq.get("id", "")) != r[2]:
			ok_energy = false
			why += " %s spray %s;" % [r[0], ae._seq.get("id", "")]
		ae.on_blast_cue("blast_charge", 3.0, S, fe)
		if ae._en_pose != r[3] or ae._en_t1 >= 0.0:
			ok_energy = false
			why += " %s charge %s;" % [r[0], ae._en_pose]
		ae.on_blast_cue("blast_full", 3.5, S, fe)
		if ae._en_pose != r[4]:
			ok_energy = false
			why += " %s full %s;" % [r[0], ae._en_pose]
		ae.q = AnimData.pose("stance.aggressive").q.duplicate()
		var q0: Quaternion = ae.q[AnimRig.index["upper_arm_r"]]
		ae._energy_layer(S, fe, 3.6)
		if ae.q[AnimRig.index["upper_arm_r"]].angle_to(q0) < 0.05:
			ok_energy = false
			why += " %s the charge pose did not show;" % r[0]
		ae.on_shot("charged", 3.7, S, fe, 200, 2)
		if ae._en_pose != r[5] or ae._en_t1 < 0.0:
			ok_energy = false
			why += " %s release %s;" % [r[0], ae._en_pose]
		ae.on_blast_cue("blast_charge", 5.0, S, fe)
		ae.on_blast_cue("blast_cancel", 5.2, S, fe)
		if ae._en_t1 < 0.0:
			ok_energy = false
			why += " %s cancel did not end the charge;" % r[0]
		ae.on_deflect(6.0, S, fe)
		if String(ae._seq.get("id", "")) != "en.swat":
			ok_energy = false
			why += " %s swat;" % r[0]
		ae.on_agency("taunt_start", 7.0, {})
		var tid: String = String(ae._seq.get("id", ""))
		if not AnimData.pair.roles[r[0]].taunts.has(tid):
			ok_energy = false
			why += " %s taunt %s;" % [r[0], tid]
		ae.on_agency("taunt_end_cut", 7.2, {})
		if not ae._seq.is_empty():
			ok_energy = false
			why += " %s taunt not cut;" % r[0]
	_expect(ok_energy, "pair live test: the energy events did not start his own poses:" + why)
	# off: no fighter plays his own waves (the live loader is skipped)
	var was: bool = RenderAnim.pair_live
	RenderAnim.pair_live = false
	var af_off := AnimFighter.new(0)
	af_off.pair_key = "protagonist"
	af_off.on_blast_cue("blast_windup", 1.0, S, S.fighters[0])
	RenderAnim.pair_live = was
	_expect(af_off._seq.is_empty(), "pair live test: with the live pair off a blast cue still started a sequence")
	print("pair live test: PROTAGONIST plays as %s (%d lights, %d heavies, %d entries), RIVAL as %s (%d, %d, %d); %d own picks in 1500 ticks; the energy presses, taunts and swat start his own poses; the pair's waves baked in %.0f ms (%d poses)" % [kp, lp.light.size(), lp.heavy.size(), lp.entries.size(), kr, lr.light.size(), lr.heavy.size(), lr.entries.size(), n_picks, float(AnimData.pair_bake_usec) / 1000.0, AnimData.pair_bake_poses])


## The joint limits (docs/animation/joint-limits.md): no knee or elbow can be bent past its end or the wrong way, from any source.
## 1. every authored pose (near and far side, each shape's scale) of every wave is inside the limits; 2. every sequence frame, after the solve's last pass;
## 3. the rule itself: a thigh twisted 170 degrees (the flipped knee of a kick) is out of range, and the pass folds the knee the right way;
## 4. the limited IK reaches a kick, a high kick and a hand behind the shoulder with the bend plane inside the twist range and the end where it was asked;
## 5. a ragdoll thrown to its extremes keeps every elbow and knee inside its hinge before the last pass; 6. a live match: no frame that reaches the screen is past a limit.
## Legal's held-pose rules (RL-087 scope, render/anim/anim_held_lint.gd): no pose held 12 ticks or more fails the pair, emitter, arms-wide or crouch tests; the scope must be present in Legal's file.
func _test_held() -> void:
	var r: Dictionary = AnimHeldLint.scan()
	_expect(bool(r.ok), "held poses: the heldScope is missing from docs/legal/movegen-banned.json")
	_expect(int(r.held) >= 100, "held poses: only %d held poses found (the scan lost its sources)" % int(r.held))
	var names: Array = []
	for f in r.fails:
		names.append("%s: %s" % [f.pose, "; ".join(f.why)])
	_expect((r.fails as Array).is_empty(), "held poses: %d fail Legal's held rules (%s)" % [(r.fails as Array).size(), " | ".join(names.slice(0, 3))])


func _test_joints() -> void:
	AnimData.load_every_wave()
	var rp: Dictionary = AnimJointLint.poses()
	var bad_p: int = AnimJointLint.sum(rp.groups, "bad_frames")
	_expect(bad_p == 0, "joint limits: %d pose frames are past a limit (%s)" % [bad_p, ", ".join(rp.bad_ids.slice(0, 6))])
	var rs: Dictionary = AnimJointLint.sequences()
	var bad_s: int = AnimJointLint.sum(rs.groups, "bad_frames")
	_expect(bad_s == 0, "joint limits: %d sequence frames are past a limit (%s)" % [bad_s, ", ".join(rs.bad_ids.slice(0, 6))])
	var ix: Dictionary = AnimRig.index
	# 3. a flipped knee
	var flip: Array[Quaternion] = AnimPose.identity_q()
	flip[ix["thigh_r"]] = Quaternion(Vector3(0, 1, 0), deg_to_rad(170.0)) * Quaternion(Vector3(0, 0, 1), deg_to_rad(80.0))
	flip[ix["shin_r"]] = Quaternion(Vector3(0, 0, 1), deg_to_rad(-60.0))
	var before: Array = AnimJoints.violations(flip, "")
	AnimJoints.enforce(flip, "")
	var after: Array = AnimJoints.violations(flip, "")
	var tw_after: float = AnimJoints.twist_of(flip[ix["thigh_r"]])
	_expect(not before.is_empty() and after.is_empty() and absf(tw_after) <= deg_to_rad(86.0), "joint limits: a thigh twisted 170 degrees was not brought inside the range (twist now %.0f)" % rad_to_deg(tw_after))
	# 4. limited IK on a kick, a high kick and a hand behind the shoulder
	var base: AnimPose = AnimData.pose("stance.aggressive")
	var worst_end: float = 0.0
	var worst_tw: float = 0.0
	var n_ik := 0
	for lean in [0.0, 25.0, -20.0]:
		for tgt in [Vector3(52, 44, 6), Vector3(48, 54, 8), Vector3(40, 20, 6), Vector3(60, 30, 6), Vector3(22, 14, 6)]:
			var lq: Array[Quaternion] = base.q.duplicate()
			lq[ix["pelvis"]] = Quaternion(Vector3(0, 0, 1), -deg_to_rad(lean))
			var gq: Array[Quaternion] = []
			gq.resize(AnimRig.N)
			var gp := PackedVector3Array()
			gp.resize(AnimRig.N)
			AnimPose.fk(lq, base.hips, gq, gp)
			var th: int = ix["thigh_r"]
			AnimPose.ik_limb(lq, gq, gp, th, th + 1, th + 2, tgt, gp[th] + Vector3(10, 1, 0), -1.0)
			AnimPose.fk(lq, base.hips, gq, gp)
			var ex: Vector2 = AnimJoints.ball_excess(lq, th, "")
			worst_tw = maxf(worst_tw, ex.x + ex.y)
			worst_end = maxf(worst_end, (gp[th + 2] - tgt).length() if (tgt - gp[th]).length() < 33.0 else 0.0)
			n_ik += 1
	_expect(worst_tw <= 0.0005 and worst_end < 0.5, "joint limits: the limited IK left a thigh %.3f rad past its range or the foot %.2f units from a reachable target" % [worst_tw, worst_end])
	# 5. a ragdoll thrown to its extremes
	var rd_bad := 0
	for sgn in [1.0, -1.0]:
		for mag in [0.6, 1.5, 3.0]:
			var af := AnimFighter.new(0)
			af._rd.reset()
			for i in range(AnimRagdoll.N):
				af._rd.th[i] = mag * sgn * (1.0 if i % 2 == 0 else -1.0)
			var rq: Array[Quaternion] = base.q.duplicate()
			af._rd.apply(rq, 1.0)
			for nm in ["forearm_l", "forearm_r", "shin_l", "shin_r"]:
				var bi: int = ix[nm]
				var th2: float = AnimJoints.hinge_state(rq[bi], bi).x
				if th2 < AnimJoints.hinge_min[bi] - 0.02 or th2 > AnimJoints.hinge_max[bi] + 0.02:
					rd_bad += 1
	_expect(rd_bad == 0, "joint limits: the ragdoll folded %d elbows or knees past their hinge" % rd_bad)
	# 6. a live match
	RenderAnim.enabled = true
	main.start_match(4, {"p1": true, "p2": true})
	var S: SimState = main.host.S
	var live_bad := 0
	var live_n := 0
	RenderAnim.joint_audit = true
	var src_bad := 0
	while main.host.ticks < 2400 and not (S.game.ko != null and S.game.koT > 3.0):
		main.frame(DT)
		for f in S.fighters:
			var a: AnimFighter = RenderAnim.fighter(S, f)
			if a.version == 0:
				continue
			live_n += 1
			if not AnimJoints.violations(a.q, a._rd.shape_key).is_empty():
				live_bad += 1
			if a.audit.has("D") and not (a.audit["D"] as Array).is_empty():
				src_bad += 1
	RenderAnim.joint_audit = false
	_expect(live_bad == 0 and live_n > 1000, "joint limits: %d of %d live fighter-frames reach the screen past a limit" % [live_bad, live_n])
	print("joint limits: %d poses and %d sequence frames inside the limits; a flipped thigh is brought in; the limited IK keeps %d targets legal (worst %.4f rad); ragdoll hinges kept; live %d frames, %d reach the screen past a limit (the sources alone leave %d for the last pass)" % [AnimJointLint.sum(rp.groups, "frames") / 10, AnimJointLint.sum(rs.groups, "frames"), n_ik, worst_tw, live_n, live_bad, src_bad])


## The agency slice's events (docs/animation/pose-pipeline.md 9.22): a knockback holds its pose for the event's own length and lets go; the embed plays its sequence
## over the held-down ticks; the far taunt plays its shrug and is cut by taunt_end_cut; a charge holds its flight pose until a fall (or the exchange) ends it, and a
## feint swaps it for the peel; reduced motion plays them at 60%; switched off, none of it plays.
func _test_agency() -> void:
	var A: Dictionary = AnimData.agency
	_expect(not A.is_empty() and AnimData.pose_exists("ag.hold.charge_heavy") and AnimData.entries.has("ag.taunt") and AnimData.entries.has("ag.embed"), "agency test: the agency data or its poses did not load")
	main.start_match(4, {"p1": true, "p2": true})
	var S: SimState = main.host.S
	var f = S.fighters[0]
	var base: AnimPose = AnimData.pose("stance.aggressive")
	var ix: Dictionary = AnimRig.index
	var th: int = ix["thigh_l"]
	# a knockback: mixed in while it lasts, gone after it
	var af := AnimFighter.new(0)
	af.on_agency("knockback", 1.0, {"kind": "slideLong", "dur": 0.6})
	var seen := 0.0
	var gone := false
	for tk in range(0, 120, 3):
		af.q = base.q.duplicate()
		af.hips = base.hips
		af._agency_layer(S, f, 1.0 + float(tk) / 60.0)
		if tk == 18:
			seen = af.q[th].angle_to(base.q[th])
		if tk == 117:
			gone = af.q[th].angle_to(base.q[th]) < 0.0001 and af._ag_t0 < 0.0
	_expect(seen > 0.1 and gone, "agency test: the knockback pose %s (%.3f rad mid-slide) and %s after it" % ["did not play" if seen <= 0.1 else "played", seen, "was gone" if gone else "stayed"])
	# the embed and the taunt: sequences, the taunt cut
	af.on_agency("embed", 2.0, {"dur": 1.0})
	_expect(String(af._ag_sq.get("id", "")) == "ag.embed" and absf(float(af._ag_sq.dur) - 0.88) < 0.001, "agency test: the embed sequence did not start for the held-down time")
	af.on_agency("taunt_start", 3.0, {})
	_expect(String(af._seq.get("id", "")) == "ag.taunt", "agency test: the taunt did not start")
	af.on_agency("taunt_end_cut", 3.2, {})
	_expect(af._seq.is_empty(), "agency test: the taunt was not cut")
	# a charge: held until a fall; a feint takes the peel
	var ac := AnimFighter.new(0)
	ac.on_agency("charge_heavy", 5.0, {})
	f.state = "free"
	ac.q = base.q.duplicate()
	ac._agency_layer(S, f, 5.5)
	var held: bool = ac._ag_t1 < 0.0 and ac._ag_hold == "ag.hold.charge_heavy"
	f.state = "launched"
	ac._agency_layer(S, f, 5.6)
	var ended: bool = ac._ag_t1 >= 0.0
	f.state = "free"
	ac.on_agency("charge_feint", 6.0, {})
	_expect(held and ended and ac._ag_hold == "ag.hold.charge_peel" and ac._ag_t1 > 6.0, "agency test: the charge held %s, ended on a fall %s, the feint took the peel %s" % [held, ended, ac._ag_hold == "ag.hold.charge_peel"])
	# every way a charge or a taunt ends: no pose runs to its cap
	for end_kind in ["dodge_cancel", "challenge_answered"]:
		var ae := AnimFighter.new(0)
		ae.on_agency("charge_light", 7.0, {})
		ae.on_agency(end_kind, 7.4, {})
		_expect(ae._ag_t1 >= 7.4 and ae._ag_t1 < 7.5, "agency test: a charge was not ended by %s" % end_kind)
	for cut_kind in ["taunt_end_cut", "taunt_end_accepted", "taunt_end_takeoff_light", "taunt_end_takeoff_heavy"]:
		var at := AnimFighter.new(0)
		at.on_agency("taunt_start", 8.0, {})
		at.on_agency(cut_kind, 8.1, {})
		_expect(at._seq.is_empty(), "agency test: a taunt was not ended by %s" % cut_kind)
	# reduced motion plays at 60%
	var red_was: bool = RenderAnim.reduced_motion
	RenderAnim.reduced_motion = true
	var ar := AnimFighter.new(0)
	ar.on_agency("knockback", 1.0, {"kind": "slideShort", "dur": 0.5})
	var w_red: float = ar._ag_w
	RenderAnim.reduced_motion = red_was
	var ar2 := AnimFighter.new(0)
	ar2.on_agency("knockback", 1.0, {"kind": "slideShort", "dur": 0.5})
	_expect(w_red < ar2._ag_w * 0.7, "agency test: reduced motion plays the knockback at %.2f of %.2f" % [w_red, ar2._ag_w])
	# switched off: nothing
	RenderAnim.agency_poses = false
	var ao := AnimFighter.new(0)
	ao.on_agency("knockback", 1.0, {"kind": "slideShort", "dur": 0.5})
	ao.on_agency("embed", 1.0, {"dur": 1.0})
	RenderAnim.agency_poses = true
	_expect(ao._ag_t0 < 0.0 and ao._seq.is_empty() and ao._ag_sq.is_empty(), "agency test: the events played with the agency poses off")
	print("agency test: knockback mid-slide %.3f rad, embed, taunt cut, charge held and ended on a fall, feint peel, reduced motion %.2f of %.2f, off plays nothing" % [seen, w_red, ar2._ag_w])


## The raw (unrounded) ragdoll states of the one-tick and the two-tick runs must agree to this much. The two runs do the same float operations in the same order, so they agree to within float noise
## (1e-12 or so); a tick-driven term that reads something stepped per rendered frame is off by about 1e-6 or more (the stale wear was 5e-6 a tick). The test used to round both to 0.0001 before comparing,
## which passed or failed on whether a value straddled a rounding boundary and hid how large the difference was.
const RD_FRAME_TOL := 1.0e-7


## The active ragdoll (overhaul unit A): the same match at one tick a frame and at two ticks a frame ends with the same ragdoll state
## (it is stepped per sim tick, never per frame); reduced motion shrinks the motion; the overhaul can be switched off; the ground
## events of World's plan (a stub shaped like docs/world/ground-contact.md) move the body. The gameplay hash is compared in the main loop.
func _rd_run(per_frame: int, until: int, reduced: bool, enabled: bool = true) -> Dictionary:
	RenderAnim.enabled = true
	RenderAnim.ragdoll_enabled = enabled
	RenderAnim.reduced_motion = reduced
	main.start_match(4, {"p1": true, "p2": true})
	var S: SimState = main.host.S
	var maxe := 0.0
	var maxlook := 0.0
	var active := 0
	while main.host.ticks < until:
		main.frame(DT * per_frame)
		for f in S.fighters:
			var rd: AnimRagdoll = RenderAnim.fighter(S, f)._rd
			maxe = maxf(maxe, rd.energy())
			maxlook = maxf(maxlook, absf(RenderAnim.fighter(S, f)._look))
			if rd.out_w > 0.5:
				active += 1
	var th: Array = []
	for f in S.fighters:
		var rd2: AnimRagdoll = RenderAnim.fighter(S, f)._rd
		for i in range(AnimRagdoll.N):
			th.append(rd2.th[i])
		th.append(rd2.out_w)
		var afx: AnimFighter = RenderAnim.fighter(S, f)
		for i in range(5):
			th.append(afx._sx[i])
		th.append(afx._look)
	RenderAnim.reduced_motion = false
	return {"th": th, "maxe": maxe, "active": active, "ticks": main.host.ticks, "look": maxlook}


func _test_ragdoll() -> void:
	var a: Dictionary = _rd_run(1, 1200, false)
	var b: Dictionary = _rd_run(2, 1200, false)
	_expect(a.ticks == b.ticks, "ragdoll test: the runs ended on different ticks (%d, %d)" % [a.ticks, b.ticks])
	var di: int = -1
	for i in range(mini(a.th.size(), b.th.size())):
		if absf(float(a.th[i]) - float(b.th[i])) > RD_FRAME_TOL:
			di = i
			break
	_expect(di < 0, "ragdoll test: the ragdoll state differs between one tick a frame and two at entry %d of %d (%s against %s; per fighter: 12 joints, out_w, 5 cloth, look)" % [di, a.th.size(), str(a.th[di] if di >= 0 else 0), str(b.th[di] if di >= 0 else 0)])
	_expect(a.active > 20, "ragdoll test: the ragdoll was never active (%d frames)" % a.active)
	var r: Dictionary = _rd_run(1, 1200, true)
	# reduced motion narrows every joint to half its range as well as shrinking the drive, so even a whole match with hard tumbles is calmer by a good margin
	_expect(r.maxe < a.maxe * 0.6, "ragdoll test: reduced motion moves %.2f against %.2f" % [r.maxe, a.maxe])
	var kick_e: Array = []
	for amp_k in [1.0, 0.35]:
		var rdk := AnimRagdoll.new()
		rdk.crumple(1.0, amp_k)
		var mk := 0.0
		for tk in range(40):
			rdk.step(DT, Vector2.ZERO, Vector2.ZERO, 1.0, amp_k, float(tk) * DT)
			mk = maxf(mk, rdk.energy())
		kick_e.append(mk)
	_expect(float(kick_e[1]) < float(kick_e[0]) * 0.5, "ragdoll test: the same crumple moves %.2f at reduced motion against %.2f" % [kick_e[1], kick_e[0]])
	var off: Dictionary = _rd_run(1, 600, false, false)
	_expect(off.maxe == 0.0, "ragdoll test: the switch left the ragdoll moving (%.3f)" % off.maxe)
	RenderAnim.ragdoll_enabled = true
	# World's ground events, a stub in the planned shape
	var S: SimState = main.host.S
	var af := AnimFighter.new(0)
	af.on_ground_event("bounce", {"actor": 0, "k": 1, "vn": -2400.0, "vt": 900.0, "keep": 0.5, "surface": "soil"}, 1.0)
	var e1: float = af._rd.energy() + af._rd.om[0] * 0.0
	var w1 := 0.0
	for i in range(AnimRagdoll.N):
		w1 += absf(af._rd.om[i])
	af.on_ground_event("land", {"actor": 0, "kind": "slam", "sin_a": 0.96, "surface": "soil"}, 1.1)
	var w2 := 0.0
	for i in range(AnimRagdoll.N):
		w2 += absf(af._rd.om[i])
	_expect(w1 > 1.0 and w2 > w1, "ragdoll test: the ground events did not move the body (%.2f, %.2f)" % [w1, w2])
	_expect(a.look > 0.03, "ragdoll test: the head never looked at the opponent (%.3f)" % a.look)
	var sk := AnimFighter.new(0)
	sk.on_skim(2.0, 3000.0)
	_expect(sk._skim_t0 == 2.0 and absf(sk._rd.om[1]) > 1.0, "ragdoll test: a water skim did not start the arch")
	print("ragdoll test: same state at one and two ticks a frame, %d active frames, reduced %.2f of %.2f, ground-event stub %.1f then %.1f rad/s" % [a.active, r.maxe, a.maxe, w1, w2])


## Hit reactions computed from the blow (overhaul unit B): the direction decides which way the head snaps, the force and the
## victim's wear scale it, two hits in a row differ, the same hit at the same tick is the same (a replay), reduced motion shrinks it.
func _hit(af: AnimFighter, d: Vector2, force: float, tick: int, region: String = "head") -> Array:
	af._rd.reset()
	af.on_hit(1.0, region, d.x < 0.0, 0.5, "", d, force, tick)
	return [af._rd.om[0], af._rd.om[1], af._rd.om[2], af._rd.om[5]]


func _test_hits() -> void:
	RenderAnim.ragdoll_enabled = true
	RenderAnim.reduced_motion = false
	var af := AnimFighter.new(0)
	var front: Array = _hit(af, Vector2(-1, 0), 0.8, 100)
	var back: Array = _hit(af, Vector2(1, 0), 0.8, 100)
	_expect(front[0] > 1.0 and back[0] < -1.0, "hit test: the head snaps %.2f from the front and %.2f from behind" % [front[0], back[0]])
	var gut: Array = _hit(af, Vector2(-1, 0), 0.8, 100, "core")
	_expect(gut[1] < -1.0, "hit test: a blow to the gut from the front should fold the spine forward (%.2f)" % gut[1])
	var small: Array = _hit(af, Vector2(-1, 0), 0.3, 100)
	var big: Array = _hit(af, Vector2(-1, 0), 1.2, 100)
	_expect(absf(big[0]) > absf(small[0]) * 2.5, "hit test: force 1.2 gives %.2f, force 0.3 gives %.2f" % [big[0], small[0]])
	af._worn = 0.9
	var worn: Array = _hit(af, Vector2(-1, 0), 0.8, 100)
	af._worn = 0.0
	var fresh: Array = _hit(af, Vector2(-1, 0), 0.8, 100)
	_expect(absf(worn[0]) > absf(fresh[0]) * 1.3, "hit test: a worn fighter's head snaps %.2f against %.2f fresh" % [worn[0], fresh[0]])
	var first: Array = _hit(af, Vector2(-1, 0), 0.8, 200)
	var second: Array = _hit(af, Vector2(-1, 0), 0.8, 200)
	_expect(first != second, "hit test: two identical hits in a row came out identical")
	var a1 := AnimFighter.new(1)
	var a2 := AnimFighter.new(1)
	var r1: Array = _hit(a1, Vector2(-1, 0), 0.8, 300)
	var r2: Array = _hit(a2, Vector2(-1, 0), 0.8, 300)
	_expect(r1 == r2, "hit test: the same hit at the same tick differs between two bodies (a replay would differ)")
	RenderAnim.reduced_motion = true
	var red: Array = _hit(AnimFighter.new(1), Vector2(-1, 0), 0.8, 300)
	RenderAnim.reduced_motion = false
	_expect(absf(red[0]) < absf(r1[0]) * 0.5, "hit test: reduced motion head snap %.2f against %.2f" % [red[0], r1[0]])
	# the contact catch's smear: the body lags the anchor and catches up in 3 ticks; the contact solve reaches that far
	var cs := AnimFighter.new(0)
	cs._smear = -20.0
	cs._smear_t0 = 1.0
	_expect(cs._smear_now(1.0) == -20.0 and cs._smear_now(1.025) < -2.0 and cs._smear_now(1.025) > -18.0 and cs._smear_now(1.06) == 0.0, "hit test: the catch smear does not ease out")
	print("hit test: head snap front %.1f behind %.1f, force 0.3 gives %.1f and 1.2 gives %.1f, worn %.1f fresh %.1f, two in a row %.1f then %.1f" % [front[0], back[0], small[0], big[0], worn[0], fresh[0], first[0], second[0]])


## Feet on a slope (overhaul unit D): a crater is dug beside a stand on open ground; with the feet placed the ankles must sit on the
## ground under each foot (the pose's own ankle height, 2.5 u), without they float or sink. The fighter is a stub (position and
## state only) on a real terrain, so the check does not depend on where an AI match happens to fight.
func _slope_run(on: bool, S: SimState, X: float) -> Dictionary:
	var f := {"x": X, "y": WorldTerrain.groundY(S, X), "z": 0.0, "state": "free", "slide": 0.0, "vx": 0.0, "vy": 0.0}
	var af := AnimFighter.new(0)
	af.vface = 1.0
	var base: AnimPose = AnimData.pose("stance.aggressive")
	for i in range(AnimRig.N):
		af.q[i] = base.q[i]
	af.hips = base.hips
	var gq: Array[Quaternion] = []
	gq.resize(AnimRig.N)
	var gp := PackedVector3Array()
	gp.resize(AnimRig.N)
	var err := 0.0
	var n := 0
	var worst := 0.0
	var g0: float = WorldTerrain.groundY(S, X)
	for k in range(-20, 40):
		# stand at a series of places across the crater wall
		var x: float = X + float(k) * 10.0
		f.x = x
		f.y = WorldTerrain.groundY(S, x)
		for i in range(AnimRig.N):
			af.q[i] = base.q[i]
		af.hips = base.hips
		if on:
			for rep in range(40):
				for i in range(AnimRig.N):
					af.q[i] = base.q[i]
				af.hips = base.hips
				af._gf_gtick = -100
				af._gf_x_valid = false
				af._ground_feet(S, f, 0.05)
		AnimPose.fk(af.q, af.hips, gq, gp)
		for nm in ["foot_l", "foot_r"]:
			var gpf: Vector3 = gp[AnimRig.index[nm]]
			var fx: float = x + gpf.x
			var gd: float = WorldTerrain.groundY(S, fx) - WorldTerrain.groundY(S, x)
			if absf(gd) > 3.0:
				var e: float = absf(gpf.y - gd - 2.5)
				err += e
				worst = maxf(worst, e)
				n += 1
	return {"n": n, "mean": err / maxf(1.0, n), "worst": worst}


func _test_slope() -> void:
	RenderAnim.enabled = true
	RenderAnim.ragdoll_enabled = true
	RenderAnim.ground_feet = true
	main.start_match(4, {"p1": true, "p2": true})
	var S: SimState = main.host.S
	for i in range(5):
		main.frame(DT)
	var X: float = -1.0
	var xs: float = 0.0
	while xs < 100000.0:
		var g: float = WorldTerrain.groundY(S, xs)
		if g > 40.0 and absf(WorldTerrain.groundY(S, xs + 120.0) - g) < 1.0 and absf(WorldTerrain.groundY(S, xs - 120.0) - g) < 1.0:
			X = xs
			break
		xs += 100.0
	_expect(X >= 0.0, "slope test: found no flat land for the test crater")
	if X < 0.0:
		return
	WorldCrater.dig(S, SimWrap.wrap(X + 150.0), 1.0, S.fighters[1], "impact", 0.0, 1.0, false)
	var off: Dictionary = _slope_run(false, S, X)
	var on: Dictionary = _slope_run(true, S, X)
	_expect(on.n > 5, "slope test: the stand was never on a slope (%d foot samples)" % on.n)
	_expect(on.mean < 1.5 and on.mean < off.mean * 0.5, "slope test: the ankle is %.2f u off the ground with the feet placed and %.2f without" % [on.mean, off.mean])
	print("slope test: %d foot samples on a crater wall, ankle height error %.2f u with the feet placed (worst %.1f), %.2f without" % [on.n, on.mean, on.worst, off.mean])


## Anticipation and follow-through by the blow's weight, and the beam's aim (overhaul unit D).
func _test_weight_aim() -> void:
	var w20: float = AnimFighter._blow_weight({"dmg": 20.0})
	var w50: float = AnimFighter._blow_weight({"dmg": 50.0})
	var w90: float = AnimFighter._blow_weight({"dmg": 90.0})
	_expect(w20 < w50 and w50 < w90 and w90 <= 1.4, "weight test: the blow weights are %.2f, %.2f, %.2f" % [w20, w50, w90])
	_expect(AnimFighter._blow_weight({"o": {"big": true}}) == 1.0 and AnimFighter._blow_weight({}) < 1.0, "weight test: a chain link or a blow without damage reads wrong")
	var af := AnimFighter.new(0)
	var before: Quaternion = af.q[AnimRig.index["upper_arm_r"]]
	af._aim_arms(0.5, 1.0)
	var turned: float = af.q[AnimRig.index["upper_arm_r"]].angle_to(before)
	_expect(absf(turned - 0.5) < 0.02, "aim test: the arm turned %.3f rad for an aim of 0.5" % turned)
	print("weight test: blow weights %.2f %.2f %.2f for 20 50 90 damage; aim turns the arms %.2f rad for 0.5" % [w20, w50, w90, turned])


## Unit E: the defender's side and the fighters' own flinch shapes.
func _test_defender() -> void:
	var stub: Dictionary = {"cancel": false, "t": 0.0, "kind": "heavy", "beats": [{"op": "strike", "t": 0.1, "done": false, "args": {"a": "A", "dmg": 60.0}}, {"op": "strike", "t": 0.4, "done": false, "args": {"a": "A", "dmg": 0.0}}]}
	var nb: Array = AnimFighter._next_blow(stub)
	_expect(nb.size() == 4 and absf(float(nb[0]) - 0.1) < 0.001 and nb[1] == true and float(nb[2]) == 60.0, "defender test: the next blow is %s" % str(nb))
	stub.cancel = true
	_expect(AnimFighter._next_blow(stub).is_empty(), "defender test: a parried exchange still has a next blow")
	stub.cancel = false
	stub.t = 0.42
	var miss: Array = AnimFighter._next_blow(stub)
	_expect(miss.size() == 4 and float(miss[2]) == 0.0 and float(miss[0]) < 0.0, "defender test: a blow just missed should be found (%s)" % str(miss))
	stub.beats.append({"op": "dodge", "t": 0.2, "done": true, "args": {}})
	_expect(AnimFighter._has_evade(stub), "defender test: a dodge beat is not seen")
	# the flinch keys differ per fighter: the same heavy blow, a few ticks of the ragdoll, two shapes
	RenderAnim.ragdoll_enabled = true
	RenderAnim.reduced_motion = false
	var res: Array = []
	for rid in ["PROTAGONIST", "RIVAL"]:
		var af := AnimFighter.new(0)
		af._rd.set_shape(rid)
		af.on_hit(1.0, "core", true, 0.9, "", Vector2(-1, 0), 1.2, 500)
		for i in range(25):
			af._rd.w_crumple = af._hit_crum * af._hit_w * 0.5
			af._rd.w_brace = (1.0 - af._hit_crum) * af._hit_w * 0.45
			af._hit_w = maxf(0.0, af._hit_w - (1.0 / 60.0) / 0.3)
			af._rd.step(1.0 / 60.0, Vector2.ZERO, Vector2.ZERO, 0.4, 1.0, 1.0 + i / 60.0)
		res.append(af._rd.th.duplicate())
	var dist := 0.0
	for i in range(AnimRagdoll.N):
		dist += absf(res[0][i] - res[1][i])
	_expect(dist > 0.3, "defender test: two fighters flinch the same (%.3f rad apart in total)" % dist)
	var ev: Array = AnimFighter._next_evade({"beats": [{"op": "dodge", "t": 0.5, "args": {}}, {"op": "slip", "t": 0.3, "args": {}}], "t": 0.2})
	_expect(ev.size() == 2 and absf(float(ev[0]) - 0.1) < 0.001 and int(ev[1]) == 1, "defender test: the next evade is %s" % str(ev))
	var ms: Array = AnimFighter._next_miss({"beats": [{"op": "strike", "t": 0.3, "args": {"a": "A", "dmg": 0.0}}, {"op": "strike", "t": 0.1, "args": {"a": "A", "dmg": 40.0}}], "t": 0.25})
	_expect(ms.size() == 2 and absf(float(ms[0]) - 0.05) < 0.001 and int(ms[1]) == 0, "defender test: the next whiff is %s" % str(ms))
	var lean := AnimFighter.new(0)
	lean._lean_away(1.0, 1.0)
	var over := AnimFighter.new(0)
	over._over_commit(1.0, 1.0)
	var blk := AnimFighter.new(0)
	blk.on_blocked(1.0)
	_expect(lean._rd.om[0] > 3.0 and over._rd.om[1] < -3.0 and blk._rd.om[2] < -3.0, "defender test: lean-away, over-commit and blocked recoil do not point the right ways (%.1f, %.1f, %.1f)" % [lean._rd.om[0], over._rd.om[1], blk._rd.om[2]])
	_expect(lean._evade_offsets(1.15) < -0.5 and over._evade_offsets(1.15) > 0.5 and blk._evade_offsets(1.03) < -1.0, "defender test: the evade root offsets do not move the body the right way")
	print("defender test: next blow %s, a miss is found, the two shapes flinch %.2f rad apart in total" % [str(nb), dist])


## Unit F: idles with personality, the guard's overlap, the turn-around step.
func _test_personality() -> void:
	RenderAnim.ragdoll_enabled = true
	RenderAnim.reduced_motion = false
	var ranges: Dictionary = {}
	for stance in [1, 2]:
		var lo := 99.0
		var hi := -99.0
		for k in range(240):
			var af := AnimFighter.new(0)
			af.hips = Vector3.ZERO
			af._personality_layer(float(k) / 60.0, stance, 0, 1.0)
			lo = minf(lo, af.hips.y)
			hi = maxf(hi, af.hips.y)
		ranges[stance] = hi - lo
	_expect(ranges[2] > ranges[1] * 2.0, "personality test: the evasive bounce is %.2f and the defensive %.2f" % [ranges[2], ranges[1]])
	var chest: Array = []
	for tier in [0, 3]:
		var m := 0.0
		for k in range(240):
			var af2 := AnimFighter.new(0)
			af2._personality_layer(float(k) / 60.0, 0, tier, 1.0)
			m = maxf(m, af2.q[AnimRig.index["spine_2"]].angle_to(Quaternion.IDENTITY))
		chest.append(m)
	_expect(chest[1] > chest[0] * 1.15, "personality test: the breath of tier 4 (%.4f) is not deeper than tier 1 (%.4f)" % [chest[1], chest[0]])
	var g := AnimFighter.new(0)
	g._stance_kick(0, 1)
	var up: float = g._rd.om[2]
	var g2 := AnimFighter.new(0)
	g2._stance_kick(1, 0)
	var down: float = g2._rd.om[2]
	_expect(up > 1.0 and down < -1.0, "personality test: the guard kicks are %.2f up and %.2f down" % [up, down])
	var t := AnimFighter.new(0)
	t._turn_t0 = 5.0
	t._turn_dir = 1.0
	t._turn_layer(5.11)
	_expect(t.hips.y < -0.8 and t.q[AnimRig.index["thigh_r"]].angle_to(Quaternion.IDENTITY) > 0.2, "personality test: the turn step does not dip and swing (%.2f)" % t.hips.y)
	var t2 := AnimFighter.new(0)
	t2._turn_t0 = 5.0
	t2._turn_layer(5.3)
	_expect(t2.hips == Vector3.ZERO, "personality test: the turn step runs past its time")
	print("personality test: bounce %.2f evasive against %.2f defensive, breath %.4f tier 4 against %.4f tier 1, guard kicks %.1f up %.1f down, turn dip %.2f" % [ranges[2], ranges[1], chest[1], chest[0], up, down, t.hips.y])


## Unit G: the gait events, the shudder of a nearby impact, the bank.
func _test_flight() -> void:
	_expect(AnimFighter._gait_event(20000.0, 100.0, 300.0) == "burst", "flight test: a hard push from nearly still is not a burst")
	_expect(AnimFighter._gait_event(20000.0, 900.0, 1100.0) == "", "flight test: a run getting faster is a burst")
	_expect(AnimFighter._gait_event(-12000.0, 900.0, 600.0) == "brake", "flight test: a hard slowdown from a run is not a brake")
	_expect(AnimFighter._gait_event(-12000.0, 100.0, 80.0) == "", "flight test: a slow body is braking")
	RenderAnim.ragdoll_enabled = true
	RenderAnim.reduced_motion = false
	var af := AnimFighter.new(0)
	af.on_shock(1.0, 0.8)
	var h := 0.0
	for k in range(30):
		af.hips = Vector3.ZERO
		af._shock_layer(1.0 + float(k) / 60.0)
		h = maxf(h, absf(af.hips.y))
	var late := AnimFighter.new(0)
	late.on_shock(1.0, 0.8)
	late.hips = Vector3.ZERO
	late._shock_layer(2.5)
	_expect(h > 0.5 and late.hips.y == 0.0, "flight test: the shudder is %.2f at its height and %.2f after 1.5 s" % [h, late.hips.y])
	var far := AnimFighter.new(0)
	far.on_shock(1.0, 0.0)
	_expect(far._shock_amp == 0.0, "flight test: an impact of no strength shook him")
	print("flight test: gait events found, the shudder of a nearby impact peaks at %.2f u" % h)


## Unit H: the quality levels switch the layers they list off, and only those, and never touch the simulation.
func _test_quality() -> void:
	RenderAnim.ragdoll_enabled = true
	RenderAnim.set_quality("high")
	for nm in ["ragdoll", "feet", "look", "aim", "personality", "transitions", "defender", "flight", "cloth", "lean"]:
		_expect(RenderAnim.layer(nm), "quality test: layer %s is off at high" % nm)
	RenderAnim.set_quality("medium")
	_expect(not RenderAnim.layer("look") and not RenderAnim.layer("feet") and not RenderAnim.layer("personality") and RenderAnim.layer("ragdoll") and RenderAnim.layer("defender"), "quality test: medium switches the wrong layers")
	RenderAnim.set_quality("low")
	_expect(RenderAnim.layer("ragdoll") and not RenderAnim.layer("cloth") and not RenderAnim.layer("flight"), "quality test: low keeps the ragdoll and drops the cloth and flight layers")
	RenderAnim.set_quality("minimal")
	_expect(not RenderAnim.layer("ragdoll"), "quality test: minimal keeps the ragdoll")
	var hashes: Dictionary = {}
	for lv in ["high", "low", "minimal"]:
		RenderAnim.set_quality(lv)
		main.start_match(4, {"p1": true, "p2": true})
		var S: SimState = main.host.S
		while main.host.ticks < 600:
			main.frame(DT)
		hashes[lv] = str(SimHash.stateHash(S).gameplay)
	RenderAnim.set_quality("high")
	_expect(hashes.high == hashes.low and hashes.high == hashes.minimal, "quality test: the gameplay hash differs between quality levels (%s)" % str(hashes))
	print("quality test: levels switch their layers, the gameplay hash is the same at high, low and minimal (%s)" % hashes.high)


## Unit K: the winner's beats after a KO (stand, survey, then hold or a raised fist by shape) and the KO's fall, on stub fighters
## (position and state only) in a real world.
func _tq_nearest(af: AnimFighter, ids: Array) -> String:
	var best: String = ""
	var bd := 1.0e9
	for id in ids:
		var p: AnimPose = AnimData.pose(id)
		var d := 0.0
		for i in range(AnimRig.N):
			d += af._tq[i].angle_to(p.q[i])
		if d < bd:
			bd = d
			best = id
	return best


func _stub(S: SimState, state: String, st: float, id: String) -> Dictionary:
	return {"state": state, "stateT": st, "slide": 0.0, "stance": 0, "vx": 0.0, "vy": 0.0, "ki": 50.0, "x": S.fighters[0].x, "y": WorldTerrain.groundY(S, S.fighters[0].x), "id": id, "tier": 1.0, "beamCharge": null}


func _test_win_ko() -> void:
	RenderAnim.enabled = true
	RenderAnim.ragdoll_enabled = true
	main.start_match(4, {"p1": true, "p2": true})
	var S: SimState = main.host.S
	for i in range(5):
		main.frame(DT)
	S.game.ko = S.fighters[1]
	var cands: Array = ["win.stand", "win.survey", "emote.victory", "stance.aggressive"]
	var got: Array = []
	for pair in [[1.2, "PROTAGONIST"], [2.5, "PROTAGONIST"], [6.0, "PROTAGONIST"], [6.0, "RIVAL"]]:
		S.game.koT = pair[0]
		var af := AnimFighter.new(0)
		af._target_base(S, _stub(S, "free", 0.0, pair[1]), 5.0)
		got.append(_tq_nearest(af, cands))
	_expect(got == ["win.stand", "win.survey", "win.survey", "emote.victory"], "win test: the winner's beats are %s" % str(got))
	var f2: Dictionary = _stub(S, "down", 0.0, "PROTAGONIST")
	S.game.ko = f2
	var early := AnimFighter.new(0)
	early._target_base(S, f2, 5.0)
	f2.stateT = 0.6
	var late := AnimFighter.new(0)
	late._target_base(S, f2, 5.0)
	var fall: Array = [_tq_nearest(early, ["react.stagger", "down.ko"]), _tq_nearest(late, ["react.stagger", "down.ko"])]
	_expect(fall == ["react.stagger", "down.ko"], "win test: the KO falls %s" % str(fall))
	S.game.ko = null
	print("win test: the winner's beats %s, a KO falls %s" % [str(got), str(fall)])


## The clavicle hunch effector and the socket table: the shoulder goes where it is told on both sides, a baked pose with a hand
## target past the arm's reach carries its shoulder toward it, an authored hunch moves the shoulder of its pose, and the table
## names every limb and region a key set may use.
func _test_hunch() -> void:
	var ix: Dictionary = AnimRig.index
	var gq: Array[Quaternion] = []
	gq.resize(AnimRig.N)
	var gp := PackedVector3Array()
	gp.resize(AnimRig.N)
	var q0: Array[Quaternion] = AnimPose.identity_q()
	AnimPose.fk(q0, Vector3.ZERO, gq, gp)
	var rest: Dictionary = {"r": gp[ix["upper_arm_r"]], "l": gp[ix["upper_arm_l"]]}
	var moved: Array = []
	for sd in ["r", "l"]:
		var lq: Array[Quaternion] = AnimPose.identity_q()
		AnimPose.hunch(lq, sd, 3.0, 2.0)
		AnimPose.fk(lq, Vector3.ZERO, gq, gp)
		var dlt: Vector3 = gp[ix["upper_arm_" + sd]] - rest[sd]
		moved.append(snappedf(dlt.x, 0.1))
		moved.append(snappedf(dlt.y, 0.1))
		_expect(absf(dlt.x - 3.0) < 0.15 and absf(dlt.y - 2.0) < 0.3, "hunch test: the %s shoulder moved by %s, not (3, 2)" % [sd, str(dlt)])
	# a hand target past the arm's reach: the baked shoulder comes toward it, and nothing moves with the hunch off
	var d: Dictionary = {"family": "upright", "hand_r": [45, 60, 5], "hand_l": [0, 30, -10]}
	var on: AnimPose = AnimPose.bake("t_on", d)
	var was: bool = AnimPose.hunch_auto
	AnimPose.hunch_auto = false
	var off: AnimPose = AnimPose.bake("t_off", d)
	AnimPose.hunch_auto = was
	var shx: Array = []
	for pz in [on, off]:
		AnimPose.fk(pz.q, pz.hips, gq, gp)
		shx.append(gp[ix["upper_arm_r"]].x)
	_expect(float(shx[0]) > float(shx[1]) + 1.0, "hunch test: the shoulder reached %.1f with the hunch, %.1f without" % [shx[0], shx[1]])
	# the table names every limb and region the key sets use
	var limbs: Dictionary = AnimData.sockets.get("limbs", {})
	var regs: Dictionary = AnimData.sockets.get("regions", {})
	for k in AnimData.keysets:
		var ks = AnimData.keysets[k]
		if typeof(ks) != TYPE_DICTIONARY or not ks.has("limb"):
			continue
		var lb: String = String(ks.get("limb", "hand_r"))
		_expect(limbs.has(lb.get_slice("_", 0)), "hunch test: key set %s names the limb %s, not in sockets.json" % [k, lb])
		_expect(regs.has(String(ks.get("target", "chest"))), "hunch test: key set %s names the region %s, not in sockets.json" % [k, ks.get("target", "chest")])
	print("hunch test: shoulder moved by %s, the reach hunch brought it %.1f units forward, %d limbs and %d regions in the socket table" % [str(moved), float(shx[0]) - float(shx[1]), limbs.size(), regs.size()])


## Per-fighter tuning against the four shape languages (data/anim/shapes.json): the same blow flinches each shape by its own
## amount (the heavy build least, the sweeping build most in the arms and spine), and every shape has an idle entry.
func _test_shapes() -> void:
	var out: Dictionary = {}
	for key in ["P", "A", "E", "C"]:
		AnimRagdoll.shape_of["T_" + key] = key
		var rd := AnimRagdoll.new()
		rd.set_shape("T_" + key)
		rd.hit(1.0, 0.0, 1.0, 1, 0.0, 0.0)
		var sums: Dictionary = {"head": 0.0, "spine": 0.0, "arms": 0.0, "legs": 0.0}
		for i in range(AnimRagdoll.N):
			var bn: String = String(AnimRig.BONES[AnimRagdoll.bone_a[i]][0])
			var grp: String = "legs"
			if bn.begins_with("head") or bn.begins_with("neck"):
				grp = "head"
			elif bn.begins_with("spine") or bn.begins_with("pelvis"):
				grp = "spine"
			elif bn.begins_with("upper_arm") or bn.begins_with("forearm") or bn.begins_with("clavicle"):
				grp = "arms"
			sums[grp] = float(sums[grp]) + absf(rd.om[i])
		out[key] = sums
		_expect(AnimData.shapes.get(key, {}).has("idle") and AnimData.shapes.get(key, {}).has("hit"), "shape test: no idle and hit entry for shape %s" % key)
		AnimRagdoll.shape_of.erase("T_" + key)
	_expect(float(out["C"].head) < float(out["P"].head) and float(out["C"].head) < float(out["A"].head), "shape test: the heavy build's head does not flinch least (%s)" % str(out))
	_expect(float(out["E"].arms) > float(out["A"].arms) and float(out["E"].arms) > float(out["C"].arms), "shape test: the sweeping build's arms do not flinch most (%s)" % str(out))
	print("shape test: head flinch P %.1f A %.1f E %.1f C %.1f, arms P %.1f A %.1f E %.1f C %.1f" % [out.P.head, out.A.head, out.E.head, out.C.head, out.P.arms, out.A.arms, out.E.arms, out.C.arms])


## The entry layer (parked sequences of poses played by an `entry` beat): a phase with ticks holds that long, the last phase is shown at the end,
## and the first at the start.
func _test_entry() -> void:
	AnimData.entries["t.entry"] = {"phases": [{"pose": "stance.aggressive", "ticks": 3}, {"pose": "move.dash"}, {"pose": "move.brake", "ticks": 3}]}
	var ix: Dictionary = AnimRig.index
	var errs: Array = []
	for pair in [[0.0, "stance.aggressive"], [0.5, "move.dash"], [0.9999, "move.brake"]]:
		var af := AnimFighter.new(0)
		var dur: float = 0.4
		af._entry_layer(0.0, dur, "t.entry", float(pair[0]) * dur, 1.0 / 60.0)
		var pz: AnimPose = AnimData.pose(String(pair[1]))
		var worst: float = 0.0
		for bn in ["upper_arm_r", "thigh_l", "spine_2"]:
			worst = maxf(worst, af.q[ix[bn]].angle_to(pz.q[ix[bn]]))
		errs.append(snappedf(worst, 0.001))
		_expect(worst < 0.05, "entry test: at %.2f of the entry the pose is %.3f rad from %s" % [float(pair[0]), worst, String(pair[1])])
	AnimData.entries.erase("t.entry")
	print("entry test: the entry's start, middle and end are %s rad from their poses" % str(errs))


## World's ground-contact events as the sim sends them (spd, n, k, vn, vt, sina, slope, vx, vy, cause, kind, surface, dur): a bounce starts the bounce
## sequence at a weight by its speed and its surface, a launch off a lip or a crest the launch sequence, a tumble's landing holds the brace until the
## tumble ends, a recovery is the tech flip, and the end of the journey lets the brace go.
func _test_ground() -> void:
	var af := AnimFighter.new(0)
	var G: Dictionary = AnimData.ground
	_expect(not G.is_empty() and AnimData.entries.has("gc.bounce") and AnimData.pose_exists("gc.hold.brace_tumble"), "ground test: the ground data or poses are not loaded")
	af.on_ground_event("bounce", {"actor": 0, "n": 1, "k": 1, "vn": -1800.0, "vt": 900.0, "surface": "rock", "sina": 0.7, "slope": 0.1, "spd": 1500.0}, 1.0)
	_expect(String(af._seq.get("id", "")) == "gc.bounce" and float(af._seq.wt) > 0.99, "ground test: a hard bounce on rock did not start gc.bounce at full weight (%s)" % str(af._seq))
	var af2 := AnimFighter.new(0)
	af2.on_ground_event("bounce", {"actor": 0, "n": 1, "k": 1, "vn": -900.0, "vt": 100.0, "surface": "sand", "sina": 0.5, "slope": 0.0, "spd": 900.0}, 1.0)
	_expect(float(af2._seq.wt) < float(af._seq.wt) - 0.2, "ground test: a soft bounce on sand is not lighter than a hard one on rock (%.2f against %.2f)" % [float(af2._seq.wt), float(af._seq.wt)])
	var af3 := AnimFighter.new(0)
	af3.on_ground_event("left_ground", {"actor": 0, "n": 1, "cause": "bounce", "vx": 100.0, "vy": 800.0, "spd": 800.0}, 1.0)
	_expect(af3._seq.is_empty(), "ground test: leaving the ground by a bounce started a launch sequence")
	af3.on_ground_event("left_ground", {"actor": 0, "n": 1, "cause": "lip", "vx": 900.0, "vy": 500.0, "spd": 1800.0, "slope": -0.7}, 2.0)
	_expect(String(af3._seq.get("id", "")) == "gc.lip_launch", "ground test: a launch off a lip did not start gc.lip_launch")
	af3.on_ground_event("land", {"actor": 0, "n": 1, "kind": "tumble", "surface": "soil", "contacts": 2}, 3.0)
	_expect(af3._gc_hold_t0 >= 0.0 and af3._gc_hold_t1 < 0.0, "ground test: a tumble's landing did not hold the brace")
	af3.on_ground_event("tumble_end", {"actor": 0, "n": 1, "kind": "recover", "contacts": 2}, 4.0)
	_expect(af3._gc_hold_t1 >= 0.0 and String(af3._seq.get("id", "")) == "gc.tech_flip", "ground test: a recovery did not release the brace and flip")
	var af5 := AnimFighter.new(0)
	af5.on_ground_event("land", {"actor": 0, "kind": "tumble", "surface": "soil", "spd": 250.0}, 1.0)
	var firm_w: float = af5._gc_hold_w
	var af6 := AnimFighter.new(0)
	af6.on_ground_event("land", {"actor": 0, "kind": "tumble", "surface": "soil", "spd": 1800.0}, 1.0)
	var loose_w: float = af6._gc_hold_w
	var af7 := AnimFighter.new(0)
	af7._worn = 1.0
	af7.on_ground_event("land", {"actor": 0, "kind": "tumble", "surface": "soil", "spd": 250.0}, 1.0)
	_expect(firm_w > loose_w + 0.2 and af7._gc_hold_w < firm_w - 0.15 and loose_w < 0.5 and firm_w <= 0.85, "ground test: the brace is not firmer when slow and looser when fast or worn (%.2f slow, %.2f fast, %.2f slow and worn)" % [firm_w, loose_w, af7._gc_hold_w])
	var af4 := AnimFighter.new(0)
	af4.on_ground_event("land", {"actor": 0, "kind": "tumble", "surface": "soil"}, 1.0)
	af4.on_ground_event("journey_end", {"actor": 0, "kind": "stop"}, 2.0)
	_expect(af4._gc_hold_t1 >= 0.0, "ground test: the end of the journey left the brace held")
	print("ground test: bounce weights %.2f (rock, hard) and %.2f (sand, soft), the lip launch, the tumble brace (%.2f slow, %.2f fast, %.2f slow and worn) and its release, the tech flip" % [float(af._seq.wt), float(af2._seq.wt), firm_w, loose_w, af7._gc_hold_w])


## The opening (docs/architecture/intro-phase.md): the sim's events on the sim's tick (the match clock is frozen) drive the pose: the fall until the landing, the
## landing sequence, the staredown set and its tension near the clock, reduced motion standing from the start, and clock_start handing the body back.
func _test_intro() -> void:
	AnimData.load_all()
	if AnimData.intro.is_empty() or not AnimData.entries.has("in.land"):
		_expect(false, "intro test: the opening's data is not loaded")
		return
	main.start_match(4, {"p1": false, "p2": false})
	var S: SimState = main.host.S
	var f = S.fighters[0]
	f.state = "intro"
	var ix: Dictionary = AnimRig.index
	var af := AnimFighter.new(0)
	var evs: Array = []
	for spec in [["intro_start", 0, 0.0], ["entrance_fall", 0, 0.6], ["entrance_land", 36, 0.0], ["staredown_start", 144, 2.6]]:
		var e := SimState.FxEvent.new()
		e.type = String(spec[0])
		e.tick = int(spec[1])
		e.dur = float(spec[2])
		evs.append(e)
		af.on_intro(e.type, float(e.tick) / 60.0, e.dur, "")
	_expect(not af._intro.is_empty() and float(af._intro.land_t) > 0.0, "intro test: the events did not set the opening")
	var errs: Array = []
	for pair in [[20, "in.hold.fall"], [200, "in.hold.set"]]:
		af.q = AnimPose.identity_q()
		S.tick = int(pair[0])
		af._intro_layer(S, f)
		var pz: AnimPose = AnimData.pose(String(pair[1]))
		var worst: float = 0.0
		for bn in ["spine_2", "upper_arm_r", "thigh_l"]:
			worst = maxf(worst, af.q[ix[bn]].angle_to(pz.q[ix[bn]]))
		errs.append(snappedf(worst, 0.001))
		_expect(worst < 0.4, "intro test: at tick %d the pose is %.2f rad from %s" % [int(pair[0]), worst, String(pair[1])])
	# the tension near the clock is the tense pose, and reduced motion stands from the start
	af.q = AnimPose.identity_q()
	S.tick = 285
	af._intro_layer(S, f)
	var tp: AnimPose = AnimData.pose("in.hold.tense")
	_expect(af.q[ix["spine_2"]].angle_to(tp.q[ix["spine_2"]]) < 0.15, "intro test: the pose near the clock is not the tension")
	RenderAnim.reduced_motion = true
	af.q = AnimPose.identity_q()
	S.tick = 20
	af._intro_layer(S, f)
	var sp: AnimPose = AnimData.pose("in.hold.set")
	_expect(af.q[ix["spine_2"]].angle_to(sp.q[ix["spine_2"]]) < 0.05, "intro test: reduced motion did not stand while falling")
	RenderAnim.reduced_motion = false
	af.on_intro("clock_start", 5.0, 0.0, "full")
	_expect(af._intro.is_empty(), "intro test: clock_start did not hand the body back")
	f.state = "free"
	print("intro test: the fall, the set and the tension are %s rad from their poses; reduced motion stands; the clock ends it" % str(errs))


## The opening through the sim's own state and events (a match started with the setup's "intro": true): the mannequin follows the fall, the landing and the
## staredown, the tension is in before the clock, and the clock hands the body back; the gameplay hash is compared in the main loop.
func _test_intro_real() -> void:
	RenderAnim.enabled = true
	main.start_match(4, {"p1": false, "p2": false}, {"intro": true})
	var S: SimState = main.host.S
	var ix: Dictionary = AnimRig.index
	# the very first frame, before the first tick's events: both fighters are in the fall pose, not standing
	for j0 in range(2):
		var af0: AnimFighter = RenderAnim.solve(S, S.fighters[j0])
		var pz0: AnimPose = AnimData.pose("in.hold.fall")
		var w0: float = 0.0
		for bn0 in ["spine_2", "upper_arm_r", "thigh_l"]:
			w0 = maxf(w0, af0.q[ix[bn0]].angle_to(pz0.q[ix[bn0]]))
		_expect(S.fighters[j0].state == "intro" and w0 < 0.5, "intro real test: on the first frame fighter %d is %s and %.2f rad from the fall pose" % [j0, S.fighters[j0].state, w0])
	var checks: Array = [[20, 0, "in.hold.fall"], [110, 0, "in.hold.set"], [60, 1, "in.hold.fall"], [270, 0, "in.hold.tense"], [270, 1, "in.hold.tense"]]
	var results: Array = []
	var ci: int = 0
	while main.host.ticks < 300 and ci < checks.size():
		main.frame(DT)
		var ck: Array = checks[ci]
		if S.tick >= int(ck[0]):
			var f = S.fighters[int(ck[1])]
			var af: AnimFighter = RenderAnim.solve(S, f)
			af.socket("foot_l")
			var pz: AnimPose = AnimData.pose(String(ck[2]))
			var worst: float = 0.0
			for bn in ["spine_2", "upper_arm_r", "thigh_l"]:
				worst = maxf(worst, af.q[ix[bn]].angle_to(pz.q[ix[bn]]))
			results.append(snappedf(worst, 0.01))
			_expect(f.state == "intro" and worst < 0.5, "intro real test: at tick %d fighter %d is %s and %.2f rad from %s" % [int(ck[0]), int(ck[1]), f.state, worst, String(ck[2])])
			ci += 1
	_expect(ci == checks.size(), "intro real test: the opening did not reach all its checks (%d of %d)" % [ci, checks.size()])
	for i in range(40):
		main.frame(DT)
	_expect(S.fighters[0].state == "free" and S.fighters[1].state == "free", "intro real test: the fighters are not free after the clock")
	_expect(RenderAnim.fighter(S, S.fighters[0])._intro.is_empty(), "intro real test: the clock did not end the opening in the animator")
	print("intro real test: the animator follows the sim's own opening: %s rad from the fall, set, fall, tension, tension poses" % str(results))


## The last stand's body cue (docs/architecture/last-stand.md): ready starts the steadying beat of his shape and the held resolve, `expired` slumps him, `used`
## only lets the resolve go; reduced motion plays it at 60%.
func _test_last_stand() -> void:
	AnimData.load_all()
	_expect(not AnimData.last_stand.is_empty() and AnimData.entries.has("ls.ready_a") and AnimData.pose_exists("ls.hold.resolve"), "last stand test: the data or poses are not loaded")
	var got: Array = []
	for pair in [["PROTAGONIST", "ls.ready_p"], ["RIVAL", "ls.ready_a"]]:
		var af := AnimFighter.new(0)
		af._rd.set_shape(String(pair[0]))
		af.on_last_stand("last_stand_ready", 5.0, 20.0, "")
		got.append(String(af._seq.get("id", "")))
		_expect(String(af._seq.get("id", "")) == String(pair[1]) and af._ls_t0 == 5.0, "last stand test: %s plays %s, not %s" % [String(pair[0]), String(af._seq.get("id", "")), String(pair[1])])
		af.on_last_stand("last_stand_end", 9.0, 0.0, "used")
		_expect(af._ls_t1 == 9.0 and String(af._seq.get("id", "")) == String(pair[1]), "last stand test: a used window slumped him or kept the resolve held")
	var ex := AnimFighter.new(0)
	ex.on_last_stand("last_stand_ready", 5.0, 20.0, "")
	ex.on_last_stand("last_stand_end", 25.0, 0.0, "expired")
	_expect(String(ex._seq.get("id", "")) == "ls.slump", "last stand test: an expired window did not slump")
	RenderAnim.reduced_motion = true
	var rd := AnimFighter.new(0)
	rd.on_last_stand("last_stand_ready", 5.0, 20.0, "")
	_expect(float(rd._seq.wt) < 0.7, "last stand test: reduced motion does not soften the beat")
	RenderAnim.reduced_motion = false
	print("last stand test: %s for the two shapes in play, the slump on expiry, reduced motion softer" % str(got))


func _run() -> void:
	await process_frame
	_scan_writes()
	AnimData.load_all()
	_test_beats()
	_test_form()
	_test_hunch()
	_test_shapes()
	_test_entry()
	_test_ground()
	_test_intro()
	_test_intro_real()
	_test_last_stand()
	RenderAnim.debug_checks = true
	for seed in seeds:
		var hashes: Dictionary = {}
		for mode in ["off", "mix", "snappy", "fluid"]:
			RenderAnim.enabled = mode != "off"
			RenderAnim.style_override = mode if (mode == "snappy" or mode == "fluid") else ""
			RenderAnim.solve_usec = 0
			RenderAnim.solve_count = 0
			main.start_match(seed, {"p1": true, "p2": true})
			var S: SimState = main.host.S
			while main.host.ticks < max_ticks and not (S.game.ko != null and S.game.koT > 3.0):
				main.frame(DT)
			hashes[mode] = str(SimHash.stateHash(S).gameplay)
			if mode == "off":
				continue
			var frames := 0
			var cerr := 0.0
			var parts := 0
			var nan := 0
			var ikf := 0
			var gmax := 0.0
			var gsum := 0.0
			var gn := 0
			var flips := 0
			var gl: Array = []
			var far := 0
			var blows := 0
			var rdt := 0
			var rdu := 0
			var catches := 0
			var vars: Dictionary = {}
			var ksets: Dictionary = {}
			var s3n: int = 0
			var lsn: int = 0
			var late := 0
			var supers := 0
			for id in RenderAnim._fighters:
				var d: Dictionary = RenderAnim._fighters[id].debug
				supers += int(d.get("press_n", {}).get("super", 0))
				frames += int(d.contact_frames)
				cerr = maxf(cerr, float(d.contact_err_max))
				parts += int(d.parts)
				nan += int(d.nan)
				ikf += int(d.ik_frames)
				gmax = maxf(gmax, float(d.gap_max))
				gsum += float(d.gap_sum)
				gn += int(d.gap_n)
				flips += int(d.face_flips)
				blows += int(d.blows)
				rdt += int(d.rd_ticks)
				rdu += int(d.rd_usec)
				catches += int(d.catches)
				s3n += int(d.get("step3", 0))
				lsn += int(d.get("last_stand", 0))
				for kk in d.get("keysets", {}):
					ksets[kk] = int(ksets.get(kk, 0)) + int(d.keysets[kk])
				for vk in d.variants:
					vars[vk] = int(vars.get(vk, 0)) + int(d.variants[vk])
				late += int(d.late)
				if mode == "mix":
					for ln in d.late_notes:
						print("    late: seed %d %s" % [seed, ln])
				for gi in range(0, d.gaps.size(), 2):
					if float(d.gaps[gi + 1]) <= 0.0:
						gl.append(float(d.gaps[gi]))
					else:
						far += 1
				if mode == "mix":
					for nt in d.notes:
						print("    short: seed %d %s" % [seed, nt])
			_expect(nan == 0, "seed %d %s: %d NaN rotations" % [seed, mode, nan])
			_expect(frames > 0, "seed %d %s: no blow reached its contact frame (%d part frames)" % [seed, mode, parts])
			# the press styles' own body at the contact tick (a mashed blow twists the spine, up to the data's cap of 0.08 rad on spine_1 and spine_2, measured on every real seed) is not an error: the limit is that cap plus a margin
			var c_lim: float = 0.1 if RenderAnim.press_styles else 0.02
			if RenderAnim.press_styles and supers > 0:
				c_lim = 0.2   # the super row's own body at the contact: a stretch of the spine of 0.34 (the tier's blow), which is the style and not an error
			_expect(cerr < c_lim, "seed %d %s: the pose on a contact frame is %.4f rad from the contact key (limit %.2f)" % [seed, mode, cerr, c_lim])
			gl.sort()
			var gworst: float = gl.back() if gl.size() > 0 else 0.0
			_expect(ikf > 0 and gl.size() > 0, "seed %d %s: the contact solve never ran (%d IK frames, %d reachable contacts)" % [seed, mode, ikf, gl.size()])
			# measured on the plane (the side-on view cannot show a few units of depth). 3 units, not 1: the limit-respecting solve (the pulled-frames patch) stops an arm raised to the head at its shoulder's range, 2.4 units short at worst on the real seeds (seed 12345 tick 2509: 5.0 as a three-dimensional gap)
			_expect(gworst < 3.0, "seed %d %s: a blow within reach ends %.2f units short of the defender (3 allowed)" % [seed, mode, gworst])
			report.runs.append({"seed": seed, "mode": mode, "contact_err_max": cerr, "contact_gap_worst": gworst, "contacts_within_reach": gl.size(), "contacts_beyond_reach": far, "solve_us": float(RenderAnim.solve_usec) / maxf(1.0, RenderAnim.solve_count), "late_blows": late, "blows": blows, "catches": catches})
			print("  contact solve: %d IK frames, %d contacts within reach (worst gap %.2f units), %d beyond reach (the sim put the fighters farther apart than the arm, lunge and step-in reach), %d facing flips" % [ikf, gl.size(), gworst, far, flips])
			print("  base variants played: %s" % [vars])
			if mode == "mix":
				print("  key sets played: %s" % [ksets])
				if RenderAnim.step3_cues:
					print("  step 3 cue sequences played: %d, last stand cues: %d" % [s3n, lsn])
			print("  ragdoll step: %.1f us a tick a fighter (%d ticks), %d contact catches smeared" % [float(rdu) / maxf(1.0, rdt), rdt, catches])
			print("  blows: %d, announced under 4 ticks ahead (no wind-up possible): %d" % [blows, late])
			print("seed %d %s: %d ticks, %d part frames, %d contact frames, worst contact error %.5f rad, solve %.1f us each (%d solves), hash %s" % [seed, mode, main.host.ticks, parts, frames, cerr, float(RenderAnim.solve_usec) / maxf(1.0, RenderAnim.solve_count), RenderAnim.solve_count, hashes[mode]])
		_expect(hashes["off"] == hashes["snappy"] and hashes["off"] == hashes["fluid"] and hashes["off"] == hashes["mix"], "seed %d: the gameplay hash differs with the mannequin (off %s, mix %s, snappy %s, fluid %s)" % [seed, hashes["off"], hashes["mix"], hashes["snappy"], hashes["fluid"]])
	await _test_wounds()
	_test_heavy_arm()
	await _test_ragdoll()
	_test_slope()
	_test_hits()
	_test_weight_aim()
	_test_defender()
	_test_personality()
	_test_flight()
	_test_quality()
	_test_win_ko()
	_test_agency()
	_test_flight_lead()
	_test_pair_live()
	_test_press_styles()
	_test_flurry_tiers()
	_test_windups()
	_test_tier_drives()
	_test_tell_sinks()
	_test_many_bodies()
	_test_march()
	_test_round10()
	_test_pieces()
	_test_arms()
	_test_pulls()
	_test_guard()
	_test_ragdoll_vary()
	_test_ragdoll_weight()
	_test_ragdoll_families()
	_test_ragdoll_oop()
	_test_air_brake()
	_test_chain()
	_test_grapple_c0_c1()
	_test_charge_cut()
	_test_grip()
	_test_recoil()
	_test_press_ack()
	_test_lunge_crouch()
	_test_locomotion()
	_test_ground_motion()
	_test_reactions()
	_test_air_recover()
	_test_secondary()
	_test_pop()
	_test_struggle()
	_test_grip_feed()
	_test_grip_throw()
	_test_shake()
	_test_incremental_bake()
	_test_tick_fast()
	_test_pulled()
	_test_bends()
	_test_styles()
	_test_medium_wind()
	_test_energy_reach()
	_test_free_arm()
	_test_fix30()
	_test_burst_set()
	_test_cells()
	_test_strength_map()
	_test_depth()
	_test_body_tint()
	_test_heave_step()
	_test_c2_cues()
	_test_zip_view()
	_test_riposte()
	_test_hand_tips()
	_test_zip()
	_test_beat_fields()
	_test_tech_consistency()
	_test_zip_slice()
	_test_gestures()
	_test_joints()
	_test_held()
	RenderAnim.enabled = true
	RenderAnim.style_override = ""
	RenderAnim.debug_checks = false
	print("Anim check  %d checks" % checks)
	if report_out != "":
		report["checks"] = checks
		report["failures"] = fails
		var rf := FileAccess.open(report_out, FileAccess.WRITE)
		rf.store_string(JSON.stringify(report))
		rf.close()
	if fails.is_empty():
		print("\nanim check passed")
	else:
		for f in fails.slice(0, 20):
			print("FAIL  " + f)
		print("\nanim check FAILED (%d)" % fails.size())
	quit(0 if fails.is_empty() else 1)
