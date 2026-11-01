extends SceneTree
## Scratch bench (Performance, 2026-10-31): every tick over a limit in a whole AI-vs-AI match on the stack, by stage.
##   godot --headless --path . --script res://sim/core/tools/stage_bench.gd -- --planet=7 --seed=77 --swing=on --ticks=3600 --reps=2 [--limit=16000]
## Needs hook-14-stages.py (SimCore.stg), hook-7-recut.mjs (SimSwing.tus) and, for the launch marks, hook-11/12/13 (DirSwing.pm) on the tree. The match is the same every rep, so the per-tick minimum over reps stands in for CPU time on a busy machine.
## --swing=off sets setup.swing "off" (the page's swings=off word): SimSwing still runs its tick, its motion is off.
## Prints  TICK n rep1 us min us | stage us ... | new lattice nodes | swing | feed tags   for every tick whose minimum is over the limit, and the match's quantiles.

var planet: int = 7
var seed_: int = 77
var swing: String = "on"
var reps: int = 2
var ticks: int = 3600
var limit: int = 16000


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--seed="):
			seed_ = int(a.substr(7))
		elif a.begins_with("--swing="):
			swing = a.substr(8)
		elif a.begins_with("--reps="):
			reps = int(a.substr(7))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--limit="):
			limit = int(a.substr(8))
	var mins: Array = []
	var first: Array = []
	var info := {}   # tick -> {stg, nodes, swing, tags, own}: from the rep whose step was the slowest at that tick
	var endState: String = ""
	for rep in range(reps):
		var S := SimCore.createSim()
		var setup := {"planet": planet, "touch": 1, "planetGen": 3, "intro": false}
		if swing == "off":
			setup["swing"] = "off"
		SimCore.newMatch(S, seed_, {"p1": true, "p2": true}, setup)
		if SimField._F != null:
			WorldField.bakeStep(SimField._F, 1 << 40)
		for t in range(ticks):
			SimSwing.tus = 0
			SimCore.stg.clear()
			var rd0: int = SimField._F.reads if SimField._F != null else 0
			var a: int = Time.get_ticks_usec()
			SimCore.step(S)
			var b: int = Time.get_ticks_usec()
			var us: int = b - a
			if rep == 0:
				mins.append(us)
				first.append(us)
			else:
				mins[t] = mini(mins[t], us)
			if us > 9000 and (not info.has(t) or info[t].us < us):
				var tags: Array = []
				for e in S.out.feed:
					tags.append(String(e.tag))
				info[t] = {"us": us, "stg": SimCore.stg.duplicate(), "nodes": (SimField._F.reads if SimField._F != null else 0) - rd0, "swing": (S.swing != null and S.swing.active), "tags": tags, "own": SimSwing.tus, "pm": DirSwing.pm.duplicate()}
			S.out.fx.clear()
			S.out.feed.clear()
			if true:
				DirSwing.pm.clear()
		endState = "tick %d, x %.3f / %.3f, hp %.3f / %.3f" % [S.tick, S.fighters[0].x, S.fighters[1].x, S.fighters[0].hp, S.fighters[1].hp]
		SimCore.dispose(S)
	var srt: Array = mins.duplicate()
	srt.sort()
	var fs: Array = first.duplicate()
	fs.sort()
	var tot: float = 0.0
	for v in mins:
		tot += v
	var over: int = 0
	var overFirst: int = 0
	for v in mins:
		if v > limit:
			over += 1
	for v in first:
		if v > limit:
			overFirst += 1
	print("CASE planet %d seed %d swing %s | %d ticks, %d reps | end %s" % [planet, seed_, swing, ticks, reps, endState])
	print("  min-over-reps us: mean %.0f p50 %d p95 %d p99 %d max %d | over %d us: %d ticks (rep 1 alone: %d ticks, max %d)" % [tot / mins.size(), srt[srt.size() / 2], srt[int(srt.size() * 0.95)], srt[int(srt.size() * 0.99)], srt[srt.size() - 1], limit, over, overFirst, fs[fs.size() - 1]])
	for t in range(mins.size()):
		if mins[t] > limit or first[t] > limit:
			var i: Dictionary = info.get(t, {})
			var stg: Dictionary = i.get("stg", {})
			var keys: Array = stg.keys()
			keys.sort_custom(func(x, y): return stg[x] > stg[y])
			var parts: String = ""
			for k in keys.slice(0, 4):
				parts += " %s %d" % [k, stg[k]]
			var pm: Dictionary = i.get("pm", {})
			var pmk: Array = pm.keys()
			pmk.sort_custom(func(x, y): return pm[x] > pm[y])
			var pms: String = ""
			for k in pmk.slice(0, 4):
				pms += " %s %d" % [k, pm[k]]
			print("  TICK %d first %d min %d | stages:%s | pm:%s | nodes %d | swing %s own %d | %s" % [t, first[t], mins[t], parts, pms, i.get("nodes", -1), str(i.get("swing", "?")), i.get("own", 0), ",".join(PackedStringArray(i.get("tags", [])))])
	quit(0)
