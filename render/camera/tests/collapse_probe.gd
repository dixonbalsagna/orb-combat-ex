extends SceneTree
## The collapse clip's sim staging (render/tools/flash_capture.gd: AI against AI, a blast through the front row every 150
## ticks from tick 90) through the rig, headless: what the displayed camera does around the launch at about tick 724, one line
## a tick, and the worst travel in the window. The rig is the one the game builds; --hold turns the launch rule on.
##   godot --headless --path . --script res://render/camera/tests/collapse_probe.gd -- [--hold] [--from=700 --to=900] [--seed=12345]

func _to_the_city(S: SimState) -> void:
	var tall = null
	for b in S.buildings:
		if b.alive and (tall == null or b.h > tall.h):
			tall = b
	if tall == null:
		return
	for i in range(2):
		var f = S.fighters[i]
		f.x = SimWrap.wrap(tall.x - 900.0 + 60.0 * float(i))
		f.y = WorldTerrain.groundY(S, f.x) + 10.0
		f.vx = 0.0
		f.vy = 0.0


func _stage_collapse(S: SimState, t: int) -> void:
	if t == 0:
		_to_the_city(S)
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


func _initialize() -> void:
	var seed_v: int = 12345
	var t0: int = 700
	var t1: int = 800
	var hold: bool = false
	var vw: float = 1280.0
	var vh: float = 720.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed_v = int(a.substr(7))
		elif a == "--hold":
			hold = true
		elif a.begins_with("--from="):
			t0 = int(a.substr(7))
		elif a.begins_with("--to="):
			t1 = int(a.substr(5))
	var S: SimState = SimCore.createSim()
	SimCore.newMatch(S, seed_v, {"p1": true, "p2": true})
	S.dt = SplitRig.DT
	var rig := SplitRig.new()
	rig.launch_hold = hold
	rig.reset(S, vw, vh)
	var prev: Vector3 = Vector3.ZERO
	var prev_ok: bool = false
	var worst: float = 0.0
	var over: int = 0
	for t in range(t1 + 1):
		_stage_collapse(S, t)
		SimCore.step(S)
		var ev: Array = S.out.fx.duplicate()
		S.out.fx.clear()
		S.out.feed.clear()
		rig.step(S, vw, vh, ev)
		var fr: SplitFrame = rig.current()
		var pc: int = 1 if fr.shows(1) and not fr.shows(0) else 0
		var cam: Vector3 = Vector3(fr.cam_x[pc], fr.cam_y[pc], fr.cam_z[pc])
		var tr: float = 0.0
		if prev_ok and not fr.cut:
			var dx: float = SimWrap.sdx(prev.x, cam.x)
			var dy: float = cam.y - prev.y
			tr = sqrt(dx * dx + dy * dy) * cam.z / vw + 0.5 * absf(log(cam.z / maxf(prev.z, 0.0001)))
		prev = cam
		prev_ok = true
		if t >= t0 and t <= t1:
			worst = maxf(worst, tr)
			if tr > 0.03:
				over += 1
			var A = S.fighters[0]
			var B = S.fighters[1]
			print("P t ", t, " mode ", fr.mode, " sep ", snappedf(fr.sep, 0.01), " e ", snappedf(fr.e, 0.01), " solo ", rig.solo_kind, " chase ", rig.chase_slot,
				" st ", A.state, "/", B.state, " vA ", snappedf(absf(A.vx), 1.0), " vB ", snappedf(absf(B.vx), 1.0), " gap ", snappedf(absf(SimWrap.sdx(A.x, B.x)), 1.0),
				" mx ", snappedf(rig._mx, 1.0), " mz ", snappedf(rig._mz, 0.001), " cam ", snappedf(cam.x, 1.0), " ", snappedf(cam.z, 0.001), " travel ", snappedf(tr, 0.0001),
				" lh ", rig._lh, " holds ", rig.launch_holds, " cut ", fr.cut)
	print("SUMMARY worst travel ", snappedf(worst, 0.0001), " ticks over 0.03: ", over)
	quit(0)
