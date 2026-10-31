extends SceneTree
## Scratch (Performance, 2026-10-31): DirLaunch._propFlight with the early exit against the original (_propFlightOld), on the props ahead of the launcher at many points of AI matches. Same answer every time, and the time of each.
##   godot --headless --path . --script res://sim/core/tools/prop_equiv.gd -- --planet=7 --ticks=3200
var planet: int = 7
var ticks: int = 3200


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": true, "p2": true}, {"planet": planet, "touch": 1, "planetGen": 3, "intro": false})
	WorldField.bakeStep(SimField._F, 1 << 40)
	var same: int = 0
	var diff: int = 0
	var cases: int = 0
	var told: int = 0
	var tnew: int = 0
	var hits: int = 0
	var t: int = 0
	while t < ticks:
		for k in range(40):
			SimCore.step(S)
			S.out.fx.clear(); S.out.feed.clear()
		t += 40
		var A = S.fighters[0]
		var D = S.fighters[1]
		var cd: Dictionary = DirLaunch.biome().get("candidates", {})
		var pq: Dictionary = cd.get("PROP SMASH", {})
		if pq.is_empty():
			continue
		var preach: float = float(pq.get("reachBh", 0.0)) * DirLaunch.BH
		for who in range(2):
			var L = A if who == 0 else D
			var T = D if who == 0 else A
			for f in [-1.0, 1.0]:
				SimField.far()
				var near: Array = DirLaunch._propsNear(S, T.x - preach, T.x + preach)
				var props: Array = DirLaunch._propTargets(S, T, near, pq.props, f, preach)
				if props.is_empty():
					SimField.near()
					continue
				for fm in pq.get("aimFm", [1.0]):
					for pf in [1600.0, 900.0, 2600.0]:
						var t0: int = Time.get_ticks_usec()
						var a: int = DirLaunch._propFlightOld(S, L, T, f, float(pq.uy), pf * float(fm), props)
						var t1: int = Time.get_ticks_usec()
						var b: int = DirLaunch._propFlight(S, L, T, f, float(pq.uy), pf * float(fm), props)
						var t2: int = Time.get_ticks_usec()
						told += t1 - t0
						tnew += t2 - t1
						cases += 1
						if a == b:
							same += 1
						else:
							diff += 1
							print("DIFF tick %d old %d new %d" % [S.tick, a, b])
						if a >= 0:
							hits += 1
				SimField.near()
	print("planet %d: %d flights compared, %d same, %d differ (%d of them hit a prop); old total %d us, new total %d us" % [planet, cases, same, diff, hits, told, tnew])
	quit(0)
