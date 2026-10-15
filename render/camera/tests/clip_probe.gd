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
	var human: bool = scenario == "signaturecity"
	main.start_match(seed_v, {"p1": not human, "p2": true}, null)
	main.started = true   # the demo prompt is not part of the clip (the capture hook does the same)
	var host: SimHost = main.host
	host.vfx.force_reduced = reduced
	host.release_all()
	if human:
		host.hub.pad_button(0, "back", true)
		host.hub.pad_button(0, "back", false)
		host.take_players()
	var rig: SplitRig = main.split_rig
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
				" cam ", snappedf(cam.x, 1.0), " y ", snappedf(cam.y, 1.0), " ", snappedf(cam.z, 0.001), " travel ", snappedf(tr, 0.0001), " | p1 cam ", snappedf(cam1.x, 1.0), " ", snappedf(cam1.z, 0.001), " travel1 ", snappedf(tr1, 0.0001), " lh ", rig._lh, " cut ", fr.cut)
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
