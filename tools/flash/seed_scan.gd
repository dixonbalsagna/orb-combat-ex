extends SceneTree
## Which AI-match seeds show what, for choosing the required set of tools/flash/sources.json (docs/tools/flash-check.md): plays seeds of the sim alone (no scene, no window, fast)
## and prints, for each seed, the signatures each fighter fires (an `attack` event of kind sig), the beam outcomes, the transformations and the building falls, over the clip's length.
##   godot --headless --path . --script res://tools/flash/seed_scan.gd -- [--from=1 --to=40 --ticks=3600 --slots=PROTAGONIST,RIVAL]
## The forms are made ready at the ai case's ticks (300 and 1500) and the tier raised at 900, as flash_worst.gd does for `ai`, so a seed here is the seed there.

var from_seed: int = 1
var to_seed: int = 40
var ticks: int = 3600
var slots: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--from="):
			from_seed = int(a.substr(7))
		elif a.begins_with("--to="):
			to_seed = int(a.substr(5))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--slots="):
			slots = Array(a.substr(8).split(","))
	for seed in range(from_seed, to_seed + 1):
		var S := SimCore.createSim()
		var setup: Dictionary = {}
		if not slots.is_empty():
			setup["slots"] = slots
		SimCore.newMatch(S, seed, {"p1": true, "p2": true}, setup)
		var sig: Dictionary = {}
		var outcomes: Dictionary = {}
		var other: Dictionary = {"transform": 0, "building_fall": 0, "shot_hit": 0}
		var t: int = 0
		while t < ticks and not (S.game.ko != null and S.game.koT > 3.0):
			SimCore.step(S)
			for e in S.out.fx:
				if e.type == "attack" and str(e.kind) == "sig":
					var id: String = str(S.fighters[int(e.actor)].id)
					sig[id] = int(sig.get(id, 0)) + 1
				elif e.type == "beam_outcome":
					outcomes[str(e.kind)] = int(outcomes.get(str(e.kind), 0)) + 1
				elif other.has(e.type):
					other[e.type] = int(other[e.type]) + 1
			S.out.fx.clear()
			S.out.feed.clear()
			t += 1
			if t == 300 or t == 1500:
				for f in S.fighters:
					f.act.formReady = true
			if t == 900:
				S.fighters[0].tier = 3.0
			if t == 1200:
				S.fighters[1].stage[1] = 2
		print("seed %3d: %4d ticks%s sig %s beams %s %s" % [seed, t, " (KO)" if S.game.ko != null else "", JSON.stringify(sig), JSON.stringify(outcomes), JSON.stringify(other)])
		SimCore.dispose(S)
	quit(0)
