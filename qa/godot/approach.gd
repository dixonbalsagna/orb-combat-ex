extends SceneTree
## Approach time with keepTop on and off (EP's order of 2026-11-01, read 3; Simulation's park docs/architecture/pending/kick-keep-top): a player flies flat out (stick and dash held) at an idle rival from a gap,
## and the ticks to reach 1,500 units (where a blow starts) and 300 units are read, with the kick on. Same start, same match seed, only SimKick.keepTop differs.
##   godot --headless --path . --script res://qa/godot/approach.gd -- [--gaps=3000,6500,12000,24000] [--seeds=5]
## The kick and keepTop are Simulation's (SimKick); this reads them and writes nothing in sim/. Prints one APPROACH JSON line.


func _init() -> void:
	var gaps: Array = [3000.0, 6500.0, 12000.0, 24000.0]
	var seeds: int = 5
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--gaps="):
			gaps = []
			for g in a.substr(7).split(","):
				gaps.append(float(g))
		elif a.begins_with("--seeds="):
			seeds = int(a.substr(8))
	if not ("keepTop" in SimKick):
		print("APPROACH " + JSON.stringify({"error": "SimKick.keepTop is not in this build"}))
		quit(2)
		return
	var out: Array = []
	for gap in gaps:
		var row := {"gap": gap}
		for keep in [true, false]:
			var t1500: Array = []
			var t300: Array = []
			var peak: float = 0.0
			for s in range(seeds):
				SimKick.keepTop = keep
				var S := SimCore.createSim()
				SimCore.newMatch(S, 77 + s, {"p1": false, "p2": false}, {"kick": true, "intro": false})
				var f = S.fighters[0]
				var o = S.fighters[1]
				f.x = 40000.0
				o.x = 40000.0 + gap
				f.y = 3000.0
				o.y = 3000.0
				var a1500: int = -1
				var a300: int = -1
				for t in range(1800):
					var i := SimIntent.new()
					i.mx = 1.0
					i.dash = true
					SimCore.step(S, [i, null])
					S.out.fx.clear()
					S.out.feed.clear()
					var d: float = absf(SimWrap.sdx(f.x, o.x))
					peak = maxf(peak, absf(f.vx))
					if a1500 < 0 and d <= 1500.0:
						a1500 = t
					if d <= 300.0:
						a300 = t
						break
				t1500.append(a1500)
				t300.append(a300)
				SimCore.dispose(S)
			row["keep" if keep else "old"] = {"to1500": _med(t1500), "to300": _med(t300), "peak": snappedf(peak, 1.0)}
		out.append(row)
	print("APPROACH " + JSON.stringify(out))
	quit()


func _med(a: Array) -> int:
	var b: Array = a.duplicate()
	b.sort()
	return int(b[b.size() / 2]) if b.size() > 0 else -1
