extends SceneTree
## The opening's framing (docs/camera/rule-of-cool-shots.md row 7; Simulation's intro phase): a match started with its composed intro
## (the host's own intro record: one of three openings by seed), AI against AI through the real scene, headless. Per tick of the intro and
## the staredown it reads the displayed picture: ticks a fighter who is on the ground is off the picture ("lost"), the smallest he is drawn,
## the travel a tick (bound 0.045 of the width), the cuts, and how long the intro runs. `--solo` plays it as one human against the
## computer with the split off (the camera follows the human alone when far: the known gap of the longest opening).
##   godot --headless --path . --script res://render/camera/tests/intro_probe.gd -- --seed=1 [--solo] [--reduced] [--ticks=700]
## Prints one RESULT line.

const DT: float = 1.0 / 60.0

var main: Node
var seed_v: int = 1
var ticks: int = 700
var solo: bool = false
var reduced: bool = false
var verbose: bool = false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed_v = int(a.substr(7))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a == "--solo":
			solo = true
		elif a == "--reduced":
			reduced = true
		elif a == "--verbose":
			verbose = true
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
	main.host.vfx.auto_quality = false
	main.host.vfx.destruction_enabled = true
	var host: SimHost = main.host
	main.start_match(seed_v, {"p1": true, "p2": true}, {"intro": host.intro_record(seed_v)})
	main.started = true
	host.vfx.force_reduced = reduced
	host.release_all()
	if solo:
		main.ui_hud.opts["split_solo"] = false
		main.split_rig.test_human_slot = 0
	var rig: SplitRig = main.split_rig
	var vw: float = rig.vw
	var vh: float = rig.vh
	var prev: Vector3 = Vector3.ZERO
	var prev_ok: bool = false
	var n: int = 0
	var lost: Array = [0, 0]
	var longest_lost: Array = [0, 0]
	var run: Array = [0, 0]
	var min_px: float = 1.0e9
	var worst: float = 0.0
	var cuts: int = 0
	var intro_ticks: int = 0
	var kinds: Dictionary = {}
	var guard: int = 0
	while host.ticks < ticks and guard < ticks * 4:
		var before: int = host.ticks
		main.frame(DT)
		guard += 1
		if host.ticks == before:
			continue
		var S: SimState = host.S
		var fr: SplitFrame = rig.current()
		var intro_on: bool = rig.intro_active
		if rig.solo_kind != "":
			kinds[rig.solo_kind] = int(kinds.get(rig.solo_kind, 0)) + 1
		var pc: int = 1 if fr.shows(1) and not fr.shows(0) else 0
		var cam: Vector3 = Vector3(fr.cam_x[pc], fr.cam_y[pc], fr.cam_z[pc])
		if prev_ok and fr.cut:
			cuts += 1
		elif prev_ok and intro_on:
			var dx: float = SimWrap.sdx(prev.x, cam.x)
			var dy: float = cam.y - prev.y
			var trv: float = sqrt(dx * dx + dy * dy) * cam.z / vw + 0.5 * absf(log(cam.z / maxf(prev.z, 0.0001)))
			worst = maxf(worst, trv)
			if verbose and trv > 0.06:
				print("J t ", host.ticks, " travel ", snappedf(trv, 0.001), " cam ", snappedf(cam.x, 1.0), " y ", snappedf(cam.y, 1.0), " z ", snappedf(cam.z, 0.001), " from z ", snappedf(prev.z, 0.001), " phase ", rig._in_phase, " solo ", rig.solo_kind, "/", snappedf(rig.solo_w, 0.01))
		prev = cam
		prev_ok = true
		if not intro_on:
			if intro_ticks > 0:
				break
			continue
		intro_ticks += 1
		n += 1
		for k in range(2):
			var f = S.fighters[k]
			var grounded: bool = float(f.y) - WorldTerrain.groundY(S, f.x) < 40.0
			var on: bool = false
			for pi in range(2):
				if not fr.shows(pi):
					continue
				var sp: Vector2 = fr.screen_pos(pi, f.x, f.y + CamParams.CHEST, float(f.z))
				var inside: bool = sp.x >= 0.0 and sp.x <= vw and sp.y >= 0.0 and sp.y <= vh
				if inside and fr.feather <= 0.001 and fr.sep >= 0.5:
					var side: float = (sp - fr.c).dot(fr.n)
					inside = side <= 0.0 if pi == 0 else side > 0.0
				if inside:
					on = true
					min_px = minf(min_px, fr.apparent_height(pi, f.x, f.y, float(f.z)))
			if grounded and not on:
				lost[k] = int(lost[k]) + 1
				run[k] = int(run[k]) + 1
				longest_lost[k] = maxi(int(longest_lost[k]), int(run[k]))
			else:
				run[k] = 0
		if verbose and host.ticks % 20 == 0:
			print("I t ", host.ticks, " ", fr.mode, " cam ", snappedf(cam.x, 1.0), " z ", snappedf(cam.z, 0.001), " A ", snappedf(S.fighters[0].x, 1.0), "/", snappedf(S.fighters[0].y, 1.0), " B ", snappedf(S.fighters[1].x, 1.0), "/", snappedf(S.fighters[1].y, 1.0), " solo ", rig.solo_kind, " phase ", rig._in_phase)
	print("RESULT seed=", seed_v, " solo=", solo, " reduced=", reduced, " intro_ticks=", intro_ticks, " lost_A=", lost[0], " lost_B=", lost[1], " longest_lost=", longest_lost,
		" min_px=", snappedf(min_px, 0.1), " worst_travel=", snappedf(worst, 0.0001), " cuts=", cuts, " shots=", kinds)
	quit(0)
