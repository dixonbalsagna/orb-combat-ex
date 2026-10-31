extends SceneTree
## Scratch (Performance, 2026-10-31): DirLaunch.chooseLaunch called directly, on the plain line and on a swung line (DirSwing._planOn, as atLaunch does), twice each, at 12 points of an AI match.
## Needs hook-11 and hook-12 (DirSwing.pm). godot --headless --path . --script res://sim/core/tools/choose_bench.gd -- --planet=7
var planet: int = 7


func one(S: SimState, label: String, swung: bool, deg: float) -> void:
	var A = S.fighters[0]
	var D = S.fighters[1]
	var was = null
	if swung:
		var fr = S.frame.copy()
		SimSwing._applyTurn(fr, float(A.x), deg)
		DirSwing._planOn(S, fr)
	for rep in range(2):
		DirSwing.pm.clear()
		var t0: int = Time.get_ticks_usec()
		DirLaunch.chooseLaunch(S, A, D, 1600.0, false, "", 0, false)
		var dt: int = Time.get_ticks_usec() - t0
		print("%-10s call %d: %6d us | biomeCands+mount %6d, brunt %6d, predict %6d (%d), head %d, score loop %d" % [label, rep + 1, dt, DirSwing.pm.get("L4_biome", 0), DirSwing.pm.get("L2_brunt", 0), DirSwing.pm.get("predict", 0), DirSwing.pm.get("predictN", 0), DirSwing.pm.get("L1_head", 0), DirSwing.pm.get("L5_score", 0)])
	if swung:
		DirSwing._planOff(S)


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": true, "p2": true}, {"planet": planet, "touch": 1, "planetGen": 3, "intro": false})
	print("planet %d, %d buildings; field world %s" % [planet, S.bX.size(), str(S.frame != null)])
	for k in range(24):
		var x: float = 4000.0 * k + 500.0
		S.fighters[0].x = x
		S.fighters[1].x = x + 58.0
		S.fighters[0].vx = 0.0
		S.fighters[1].vx = 0.0
		print("-- x %.0f biome %s, ground %.0f" % [x, WorldBiomes.biomeAt(x), WorldTerrain.groundY(S, x)])
		one(S, "plain", false, 0.0)
	quit(0)
