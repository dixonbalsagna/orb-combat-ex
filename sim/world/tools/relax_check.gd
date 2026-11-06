extends SceneTree
# The relaxation to the angle of repose (World, sim/world/crater.gd relax; docs/world/water-read.md): it reads the ground under its window once and keeps each pair's allowed step, where it read both four times a pair every pass (up to
# 64 passes: 12 ms in one tick of Orb's play when a tower fell). The result must be the same, bit for bit: here the original is kept as `_relax_ref` and run beside it on the same terrain, over many windows with steps that
# need relaxing, with and without a frozen side, and the deform, the rubble and the lowest ground returned are compared.
#   godot --headless --path . --script res://sim/world/tools/relax_check.gd -- [--planet=7] [--touch=1]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _relax_ref(S: SimState, c0: int, half: int, freezeFrom: int = 0, freezeDir: int = 0) -> float:
	var NC: int = SimConst.NC
	var limit: float = WorldCrater.REPOSE_SLOPE * SimConst.COL
	var base: PackedFloat32Array = S.base
	var dfm: PackedFloat32Array = S.deform
	var rub: PackedFloat32Array = S.rubble
	var cnt: int = mini(2 * half + 1, NC)
	var lo: int = c0 - half
	# Most calls find nothing to do: look first, before the footing mask is built.
	var need: bool = false
	for k in range(cnt - 1):
		var i0: int = posmod(lo + k, NC)
		var j0: int = posmod(lo + k + 1, NC)
		var d0: float = (WorldTerrain.baseAt(S, j0) + dfm[j0]) - (WorldTerrain.baseAt(S, i0) + dfm[i0])
		if absf(d0) - maxf(limit, absf(WorldTerrain.baseAt(S, j0) - WorldTerrain.baseAt(S, i0))) > WorldCrater.REPOSE_EPS:
			need = true
			break
	if not need:
		var m0: float = 1.0e9
		for k in range(cnt):
			var c0m: int = posmod(lo + k, NC)
			m0 = minf(m0, WorldTerrain.baseAt(S, c0m) + dfm[c0m])
		return m0
	var pin: PackedByteArray = WorldStructures.pinned(S, c0, half)   # a standing building's footing is never moved
	if freezeDir != 0:   # columns from freezeFrom on, in this direction, are not touched at all (value 2)
		for kf in range(cnt):
			var cf: int = posmod(lo + kf, NC)
			if posmod((cf - freezeFrom) * freezeDir, NC) < NC / 2:
				pin[kf] = 2
	for pass_n in range(WorldCrater.REPOSE_PASSES):
		var moved: float = 0.0
		for sweep in range(2):
			for k in range(cnt - 1):
				var kk: int = k if sweep == 0 else cnt - 2 - k
				var i: int = posmod(lo + kk, NC)
				var j: int = posmod(lo + kk + 1, NC)
				var d: float = (WorldTerrain.baseAt(S, j) + dfm[j]) - (WorldTerrain.baseAt(S, i) + dfm[i])
				var ex: float = absf(d) - maxf(limit, absf(WorldTerrain.baseAt(S, j) - WorldTerrain.baseAt(S, i)))
				if ex <= WorldCrater.REPOSE_EPS:
					continue
				var e: float = ex * 0.5
				var hi: int = j if d > 0.0 else i
				var lw: int = i if d > 0.0 else j
				if pin[kk] == 2 or pin[kk + 1] == 2:
					continue
				if pin[kk + 1 if lw == j else kk] == 1:
					continue   # a footing may be lowered but never raised
				dfm[hi] = maxf(WorldCrater.DEFORM_FLOOR, dfm[hi] - e)
				dfm[lw] = minf(WorldCrater.DEFORM_CEIL, dfm[lw] + e)
				var rm: float = minf(rub[hi], e)
				if rm > 0.0:
					rub[hi] -= rm
					rub[lw] += rm
				moved += e
		if moved < WorldCrater.REPOSE_EPS:
			break
	S.deform = dfm
	S.rubble = rub
	var minG: float = 1.0e9
	for k in range(cnt):
		var c: int = posmod(lo + k, NC)
		minG = minf(minG, WorldTerrain.baseAt(S, c) + dfm[c])
	return minG


func _match(planet: int, touch: int) -> SimState:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	for i in range(30):
		SimCore.step(S)
	return S


func _init() -> void:
	var planet: int = 7
	var touch: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	var NC: int = SimConst.NC
	var worst: int = 0
	var trials: int = 0
	var moved_trials: int = 0
	var rng: int = 12345
	var altered: int = 0
	var t_new: int = 0
	var t_old: int = 0
	for trial in range(36):
		var A := _match(planet, touch)
		var B := _match(planet, touch)
		var c0: int = int(A.fighters[0].x / SimConst.COL) + 40 * (trial % 9) - 160
		var half: int = 14 + 11 * (trial % 6)
		# the same steep ground in both: a few raised and cut columns beside each other
		for k in range(-half, half + 1):
			rng = (rng * 1103515245 + 12345) & 0x7fffffff
			var v: float = 0.0
			if (rng >> 8) % 5 == 0:
				v = float((rng >> 12) % 1200) - 500.0
			var col: int = posmod(c0 + k, NC)
			A.deform[col] = clampf(v, WorldCrater.DEFORM_FLOOR, WorldCrater.DEFORM_CEIL)
			B.deform[col] = A.deform[col]
			A.rubble[col] = 20.0 if v > 200.0 else 0.0
			B.rubble[col] = A.rubble[col]
		var ff: int = 0
		var fd: int = 0
		if trial % 4 == 3:
			ff = posmod(c0 + half / 2, NC)
			fd = 1 if trial % 8 == 3 else -1
		var before: PackedFloat32Array = A.deform.duplicate()
		var t0: int = Time.get_ticks_usec()
		var r_new: float = WorldCrater.relax(A, c0, half, ff, fd)
		t_new += Time.get_ticks_usec() - t0
		t0 = Time.get_ticks_usec()
		var r_old: float = _relax_ref(B, c0, half, ff, fd)
		t_old += Time.get_ticks_usec() - t0
		if A.deform != before:
			altered += 1
		trials += 1
		var same: bool = r_new == r_old and A.deform == B.deform and A.rubble == B.rubble
		if not same:
			worst += 1
		# did it have something to do
		var changed: bool = false
		for k in range(-half, half + 1):
			if A.deform[posmod(c0 + k, NC)] != 0.0:
				changed = true
		if changed:
			moved_trials += 1
	ok(trials == 36 and moved_trials > 20, "%d windows of 29 to 84 columns on steep ground, %d with ground to relax" % [trials, moved_trials])
	ok(altered >= 20, "the relaxation moved ground in %d of the windows (the passes ran)" % altered)
	print("  info the original took %d microseconds over the windows, the new one %d" % [t_old, t_new])
	ok(worst == 0, "the new relax and the original give the same deform, rubble and lowest ground, bit for bit (%d of %d differ)" % [worst, trials])
	print("RELAX: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
