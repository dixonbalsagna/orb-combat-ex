extends SceneTree
## A flash clip's camera, per tick, through the real game scene (the way tools/flash/flash_worst.gd plays it: render/main.tscn,
## the host's own step, the compositor attached), headless. One line a tick in the window: mode, layout, the displayed camera
## and its travel, the launch rule's phase. For reproducing what Tools' per-tick probe sees.
##   godot --headless --path . --script res://render/camera/tests/clip_probe.gd -- --scenario=ai --seed=38 --from=3440 --to=3560 [--hold] [--mz] [--slam] [--budget] [--reduced]
## Scenarios: ai (the real match with its writes), collapse (a blast through the front row every 150 ticks) and signaturecity
## (P1 human on a pad holding the signature on a 90-tick cycle beside the tallest tower, P2 the AI: tools/flash/flash_worst.gd's).

const DT: float = 1.0 / 60.0
const FORM_TICKS: Array = [300, 1500]

var main: Node
var scenario: String = "ai"
var seed_v: int = 12345
var t0: int = 0
var t1: int = 200
var hold: bool = false
var mz: bool = false
var budget: bool = false
var slam: bool = false
var reduced: bool = false
var nobundle: bool = false
var struggle: bool = false
var mlook: bool = false
var exo_y: float = 20000.0
var surges: bool = false
var sweepmid: bool = false
var sweep_t0: int = -1
var pulse_ticks: Array = []
var pulse_n: int = 0
var cue_seen: Dictionary = {}
var human0: bool = false
var held: Dictionary = {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scenario="):
			scenario = a.substr(11)
		elif a.begins_with("--seed="):
			seed_v = int(a.substr(7))
		elif a.begins_with("--from="):
			t0 = int(a.substr(7))
		elif a.begins_with("--to="):
			t1 = int(a.substr(5))
		elif a == "--hold":
			hold = true
		elif a == "--mz":
			mz = true
		elif a == "--slam":
			slam = true
		elif a == "--reduced":
			reduced = true
		elif a == "--nobundle":
			nobundle = true
		elif a == "--struggle":
			struggle = true
		elif a == "--mlook":
			mlook = true
		elif a.begins_with("--exoy="):
			exo_y = float(a.substr(7))
		elif a == "--surges":
			surges = true
		elif a == "--sweepmid":
			sweepmid = true
		elif a == "--human0":
			human0 = true
		elif a == "--budget":
			budget = true
	var vpn := SubViewport.new()
	vpn.size = Vector2i(1280, 720)
	vpn.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vpn)
	main = load("res://render/main.tscn").instantiate()
	main.manual = true
	vpn.add_child(main)
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var sv := SplitView.new()
	main.split_view = sv
	main.add_child(sv)
	main._sync_split_options()
	sv.attach(main)
	if budget:
		sv.set_travel_budget(true)
	if hold:
		sv.set_launch_hold(true)
	if mz:
		main.split_rig.merge_zoom_limit = true
	if slam:
		sv.set_slam_off(true)
	main.host.vfx.auto_quality = false
	main.host.vfx.destruction_enabled = true
	var human: bool = scenario == "signaturecity" or scenario == "rushcity"
	var both: bool = scenario == "clash"
	main.start_match(seed_v, {"p1": not (human or both), "p2": not both}, null)
	if struggle:
		sv.set_struggle_framing(true)
	if mlook:
		sv.set_merge_lookahead(true)
	if nobundle:
		main.split_rig.flash_bundle = false
	if human0:
		main.split_rig.test_human_slot = 0
	main.started = true   # the demo prompt is not part of the clip (the capture hook does the same)
	var host: SimHost = main.host
	host.vfx.force_reduced = reduced
	host.release_all()
	if human or both:
		host.hub.pad_button(0, "back", true)
		host.hub.pad_button(0, "back", false)
		host.take_players()
	if both:
		host.hub.pad_button(1, "back", true)
		host.hub.pad_button(1, "back", false)
		host.take_players()
	var rig: SplitRig = main.split_rig
	var cb := func(evs: Array, _lines: Array):
		for e in evs:
			if e.type == "cue":
				cue_seen[str(e.kind)] = int(cue_seen.get(str(e.kind), 0)) + 1
			if e.type == "cue" and str(e.kind) == "beam_pulse":
				pulse_ticks.append(host.ticks)
			elif e.type == "cue" and str(e.kind) == "beam_struggle":
				pulse_ticks.clear()
				pulse_n = 0
	host.drained.connect(cb)
	var prev: Vector3 = Vector3.ZERO
	var prev_ok: bool = false
	var prev1: Vector3 = Vector3.ZERO
	var worst: float = 0.0
	var over: int = 0
	var guard: int = 0
	while host.ticks <= t1 and guard < (t1 + 10) * 4:
		_drive(host.ticks, host.S)
		var before: int = host.ticks
		main.frame(DT)
		guard += 1
		if host.ticks == before:
			continue
		var fr: SplitFrame = rig.current()
		var pc: int = 1 if fr.shows(1) and not fr.shows(0) else 0
		var cam: Vector3 = Vector3(fr.cam_x[pc], fr.cam_y[pc], fr.cam_z[pc])
		var tr: float = 0.0
		if prev_ok and not fr.cut:
			var dx: float = SimWrap.sdx(prev.x, cam.x)
			var dy: float = cam.y - prev.y
			tr = sqrt(dx * dx + dy * dy) * cam.z / 1280.0 + 0.5 * absf(log(cam.z / maxf(prev.z, 0.0001)))
		var cam1: Vector3 = Vector3(fr.cam_x[1], fr.cam_y[1], fr.cam_z[1])
		var tr1: float = 0.0
		if prev_ok and not fr.cut:
			var dx1: float = SimWrap.sdx(prev1.x, cam1.x)
			var dy1: float = cam1.y - prev1.y
			tr1 = sqrt(dx1 * dx1 + dy1 * dy1) * cam1.z / 1280.0 + 0.5 * absf(log(cam1.z / maxf(prev1.z, 0.0001)))
		prev1 = cam1
		prev = cam
		prev_ok = true
		if host.ticks >= t0 and host.ticks <= t1:
			worst = maxf(worst, maxf(tr, tr1))
			if maxf(tr, tr1) > 0.03:
				over += 1
			var A = host.S.fighters[0]
			var B = host.S.fighters[1]
			print("P t ", host.ticks, " mode ", fr.mode, " sep ", snappedf(fr.sep, 0.01), " e ", snappedf(fr.e, 0.01), " solo ", rig.solo_kind, "/", snappedf(rig.solo_w, 0.01),
				" st ", A.state, "/", B.state, " gap ", snappedf(absf(SimWrap.sdx(A.x, B.x)), 1.0), " mx ", snappedf(rig._mx, 1.0), " mz ", snappedf(rig._mz, 0.001),
				" cam ", snappedf(cam.x, 1.0), " y ", snappedf(cam.y, 1.0), " ", snappedf(cam.z, 0.001), " travel ", snappedf(tr, 0.0001), " | p1 cam ", snappedf(cam1.x, 1.0), " ", snappedf(cam1.z, 0.001), " travel1 ", snappedf(tr1, 0.0001), " lh ", rig._lh, " cut ", fr.cut, " st ", rig._st_on, "/", snappedf(rig._st_mid, 0.01), "/m", (snappedf(float(host.S.game.clash.get("mid")), 0.01) if host.S.game.clash != null and host.S.game.clash.get("mid") != null else -9), " clash ", host.S.game.clash != null, " mt_z ", snappedf(rig._merged_target(host.S).z, 0.001), " vsm_m ", snappedf(rig._vsm_m, 1.0), " gov_m ", rig._gov_bind_m)
	print("PULSE cues seen: ", pulse_ticks.size(), " cue kinds: ", cue_seen)
	print("SUMMARY worst travel ", snappedf(worst, 0.0001), " ticks over 0.03: ", over)
	quit(0)


func _drive(t: int, S: SimState) -> void:
	if scenario == "ai":
		if FORM_TICKS.has(t):
			for f in S.fighters:
				f.act.formReady = true
		if t == 900:
			S.fighters[0].tier = 3.0
		if t == 1200:
			S.fighters[1].stage[1] = 2
	elif scenario == "exo":
		# the pair flown to the exosphere (the flight ceiling is 24,000 units): a free flight at --exoy, one drifting toward the other, to read what the
		# rig does at height (docs/camera/exosphere.md)
		var ey: float = exo_y
		for i in range(2):
			var fe = S.fighters[i]
			fe.y = ey + 300.0 * sin(float(t) / 90.0 + float(i))
			fe.vy = 0.0
			fe.x = SimWrap.wrap(fe.x + (3.0 if i == 0 else -3.0) * sin(float(t) / 150.0))
	elif scenario == "rushcity":
		# P1 sprints (stick held, dodge held: the sprint) along the front street, turning every 150 ticks; the AI fights him (tools/flash's rushcity)
		if t == 0:
			var tall2 = null
			for b in S.buildings:
				if b.alive and (tall2 == null or b.h > tall2.h):
					tall2 = b
			if tall2 != null:
				for i in range(2):
					var f2 = S.fighters[i]
					f2.x = SimWrap.wrap(tall2.x - 900.0 + 60.0 * float(i))
					f2.y = WorldTerrain.groundY(S, f2.x) + 10.0
					f2.vx = 0.0
					f2.vy = 0.0
		_stick(0, 1.0 if (t / 150) % 2 == 0 else -1.0)
		_btn(0, "lt", true)
	elif scenario == "signaturecity":
		if t == 0:
			var tall = null
			for b in S.buildings:
				if b.alive and (tall == null or b.h > tall.h):
					tall = b
			if tall != null:
				for i in range(2):
					var f = S.fighters[i]
					f.x = SimWrap.wrap(tall.x - 900.0 + 60.0 * float(i))
					f.y = WorldTerrain.groundY(S, f.x) + 10.0
					f.vx = 0.0
					f.vy = 0.0
		var dx: float = SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)
		var far: bool = absf(dx) > 1800.0
		_stick(0, signf(dx) if far else 0.0)
		S.fighters[0].ki = 100.0
		_btn(0, "rt", t % 90 < 60)
		_btn(0, "east", t % 90 > 2 and t % 90 < 14)
		_btn(0, "west", t % 90 > 40 and (t % 6) < 2)
	elif scenario == "clash":
		# both human, ki kept full, both firing the signature together every 30 ticks (tools/flash's clash scenario)
		var cdx: float = SimWrap.sdx(S.fighters[0].x, S.fighters[1].x)
		var cfar: bool = absf(cdx) > 1500.0
		_stick(0, signf(cdx) if cfar else 0.0)
		_stick(1, -signf(cdx) if cfar else 0.0)
		for f in S.fighters:
			f.ki = 100.0
		_btn(0, "rt", true)
		_btn(1, "rt", true)
		_btn(0, "east", t % 30 < 12)
		_btn(1, "east", t % 30 < 12)
		if sweepmid and S.game.clash != null and S.game.clash.get("mid") != null:
			# a test of the camera alone: the meeting point driven from the middle to a fighter's hands and back over 240 ticks, whatever the presses did
			if sweep_t0 < 0:
				sweep_t0 = t
			var ph: float = float(t - sweep_t0) / 240.0
			S.game.clash.mid = 0.5 + 0.42 * (1.0 - absf(2.0 * fposmod(ph, 1.0) - 1.0)) * (1.0 if int(ph) % 2 == 0 else -1.0)
		elif sweepmid:
			sweep_t0 = -1
		if surges and not pulse_ticks.is_empty():
			# P1 hits the beat the tick after each pulse (a sharp surge), except every third; P2 is three ticks late on every second one
			var lp: int = int(pulse_ticks[-1])
			var k: int = pulse_ticks.size()
			_btn(0, "west", t >= lp + 1 and t <= lp + 2 and k % 3 != 0)
			_btn(1, "west", t >= lp + 3 and t <= lp + 4 and k % 2 == 0)
	elif scenario == "collapse":
		if t == 0:
			var tall = null
			for b in S.buildings:
				if b.alive and (tall == null or b.h > tall.h):
					tall = b
			if tall != null:
				for i in range(2):
					var f = S.fighters[i]
					f.x = SimWrap.wrap(tall.x - 900.0 + 60.0 * float(i))
					f.y = WorldTerrain.groundY(S, f.x) + 10.0
					f.vx = 0.0
					f.vy = 0.0
			return
		var u: int = t - 90
		if u < 0 or (u % 150 != 0 and u % 150 != 3):
			return
		var front: Array = []
		for b in S.buildings:
			if b.alive and b.row == WorldStructures.PLANE_ROW:
				front.append(b)
		if front.is_empty():
			return
		var cx: float = S.fighters[0].x
		front.sort_custom(func(a, b): return absf(SimWrap.sdx(cx, a.x)) < absf(SimWrap.sdx(cx, b.x)))
		var k: int = (u / 150) % maxi(1, front.size() / 3)
		var b0 = front[mini(front.size() - 1, k * 3)]
		S.fighters[0].tier = 3.0
		WorldStructures.explode(S, b0.x, WorldTerrain.groundY(S, b0.x) + 40.0, 800.0, S.fighters[0])


func _btn(dev: int, name: String, down: bool) -> void:
	var k: String = "%d:%s" % [dev, name]
	if down == held.has(k):
		return
	if down:
		held[k] = true
	else:
		held.erase(k)
	main.host.hub.pad_button(dev, name, down)


func _stick(dev: int, x: float) -> void:
	var k: String = "%d:stick" % dev
	var v: float = signf(x)
	if held.get(k, 0.0) == v:
		return
	held[k] = v
	main.host.hub.pad_stick(dev, v, 0.0)
