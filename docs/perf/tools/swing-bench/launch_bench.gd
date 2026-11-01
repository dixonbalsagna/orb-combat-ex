extends SceneTree
## Lean bench (Performance and Platform, 2026-11-01): one whole AI-vs-AI match on the tree as it is, no hooks, per-tick wall time, the launch ticks, and the gameplay hash every 600 ticks, as JSON.
##   godot --headless --path . --script res://sim/core/tools/launch_bench.gd -- --planet=7 --seed=77 --ticks=7200 --out=<abs json> [--warm=8 --warmb=8]
## --warm and --warmb set SimField.warmN and warmB (docs/perf/tools/swing-bench/fix-ring-warm.py; the tree must carry that patch). The hashes of two runs of the same case must be equal whatever those are.
## JSON: {planet, seed, ticks, warm, warmb, us:[per tick], launches:[{tick, us, tag}], hashes:[...], end}.

var planet: int = 7
var seed_: int = 77
var ticks: int = 7200
var warm: int = 0
var warmb: int = 0
var outp: String = ""


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--seed="):
			seed_ = int(a.substr(7))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--warm="):
			warm = int(a.substr(7))
		elif a.begins_with("--warmb="):
			warmb = int(a.substr(8))
		elif a.begins_with("--out="):
			outp = a.substr(6)
	if warm > 0 or warmb > 0:
		SimField.warmN = warm
		SimField.warmB = warmb
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {"p1": true, "p2": true}, {"planet": planet, "touch": 1, "planetGen": 3, "intro": false})
	if SimField._F != null:
		WorldField.bakeStep(SimField._F, 1 << 40)
	var us: Array = []
	var launches: Array = []
	var hashes: Array = []
	for t in range(ticks):
		var a: int = Time.get_ticks_usec()
		SimCore.step(S)
		var d: int = Time.get_ticks_usec() - a
		us.append(d)
		for e in S.out.feed:
			if String(e.tag).begins_with("LAUNCH"):
				launches.append({"tick": t, "us": d, "tag": String(e.tag).substr(0, 40)})
				break
		S.out.fx.clear()
		S.out.feed.clear()
		if (t + 1) % 600 == 0:
			hashes.append(String(SimHash.stateHash(S).gameplay))
	var end: String = "tick %d, x %.3f / %.3f, hp %.3f / %.3f" % [S.tick, S.fighters[0].x, S.fighters[1].x, S.fighters[0].hp, S.fighters[1].hp]
	SimCore.dispose(S)
	var f := FileAccess.open(outp, FileAccess.WRITE)
	f.store_string(JSON.stringify({"planet": planet, "seed": seed_, "ticks": ticks, "warm": warm, "warmb": warmb, "us": us, "launches": launches, "hashes": hashes, "end": end}))
	f.close()
	print("wrote ", outp)
	quit(0)
