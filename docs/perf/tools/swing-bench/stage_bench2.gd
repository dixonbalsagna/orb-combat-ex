extends SceneTree
## Scratch bench (Performance, 2026-10-31): every tick of a whole AI-vs-AI match on the stack, per rep, as JSON (so a match run first in a process, and a rematch in the same process, are told apart).
##   godot --headless --path . --script res://sim/core/tools/stage_bench2.gd -- --planet=7 --seed=77 --swing=on --ticks=7200 --reps=2 --out=<abs path of the json> [--detail=5000]
## Needs hook-14-stages.py (SimCore.stg), hook-7-recut.mjs (SimSwing.tus) and the DirSwing.pm marks (hook-11/12/13 or the hand marks) on the tree.
## JSON: {planet, seed, swing, ticks, reps:[{us:[per tick], nodes:[new lattice nodes per tick], det:{tick:{stg, pm, tags, own, swing}}, end}]}. det holds a tick whose step was over --detail microseconds.
## Wall-clock microseconds (Time.get_ticks_usec): a machine that is busy adds to a tick, so a tick is believed only when it shows in every independent run.

var planet: int = 7
var seed_: int = 77
var swing: String = "on"
var reps: int = 2
var ticks: int = 7200
var detail: int = 5000
var outp: String = ""
var prime: bool = false   # --prime: read the surface once after newMatch, as the proposal for WorldContact._buildSurf would (the match start builds the table)


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
		elif a.begins_with("--detail="):
			detail = int(a.substr(9))
		elif a == "--prime":
			prime = true
		elif a.begins_with("--out="):
			outp = a.substr(6)
	var res: Array = []
	for rep in range(reps):
		var S := SimCore.createSim()
		var setup := {"planet": planet, "touch": 1, "planetGen": 3, "intro": false}
		if swing == "off":
			setup["swing"] = "off"
		SimCore.newMatch(S, seed_, {"p1": true, "p2": true}, setup)
		if SimField._F != null:
			WorldField.bakeStep(SimField._F, 1 << 40)
		if prime:
			WorldContact.surfaceAt(S, 0.0)
		var us: Array = []
		var nodes: Array = []
		var det := {}
		for t in range(ticks):
			SimSwing.tus = 0
			SimCore.stg.clear()
			DirSwing.pm.clear()
			var rd0: int = SimField._F.reads if SimField._F != null else 0
			var a: int = Time.get_ticks_usec()
			SimCore.step(S)
			var b: int = Time.get_ticks_usec()
			us.append(b - a)
			var nn: int = (SimField._F.reads if SimField._F != null else 0) - rd0
			nodes.append(nn)
			if b - a > detail:
				var tags: Array = []
				for e in S.out.feed:
					tags.append(String(e.tag))
				det[str(t)] = {"stg": SimCore.stg.duplicate(), "pm": DirSwing.pm.duplicate(), "tags": tags, "own": SimSwing.tus, "swing": (S.swing != null and S.swing.active)}
			S.out.fx.clear()
			S.out.feed.clear()
		res.append({"us": us, "nodes": nodes, "det": det, "end": "tick %d, x %.3f / %.3f, hp %.3f / %.3f" % [S.tick, S.fighters[0].x, S.fighters[1].x, S.fighters[0].hp, S.fighters[1].hp]})
		SimCore.dispose(S)
	var f := FileAccess.open(outp, FileAccess.WRITE)
	f.store_string(JSON.stringify({"planet": planet, "seed": seed_, "swing": swing, "ticks": ticks, "reps": res}))
	f.close()
	print("wrote ", outp)
	quit(0)
