extends SceneTree
## Biomes W3: a gen 2 AI-against-AI batch for the launch mix (QA's bands, launch_biome.json biome.qa). Every launch the
## planner picks (the launch_plan event) is counted by candidate, by the fine biome under the target, and where it was
## offered; when his flight ends, whether he came down in the sea. Prints a line a match and one BATCH line of JSON for
## the totals (a run can be split across processes by seed and the lines summed).
##   godot --headless --path . --script res://sim/director/tools/launchbiome_batch.gd -- --on --seeds=7,3,11 --matches=4
##   --on / --off: biome.enabled forced for the run (the file is not edited); --ticks=N the cap a match (default 7200)

const SKIP: Array = ["KNOCK BACK", "STAY", ""]


func _init() -> void:
	var on: bool = true
	var seeds: Array = [7, 3, 11, 25]
	var matches: int = 2
	var ticks: int = 7200
	for a in OS.get_cmdline_user_args():
		if a == "--on":
			on = true
		elif a == "--off":
			on = false
		elif a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(s): return int(s))
		elif a.begins_with("--matches="):
			matches = int(a.substr(10))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	DirLaunch.forceBiome = 1 if on else 0
	var tot: Dictionary = {"launches": 0, "chosen": {}, "offered": {}, "byBiome": {}, "sea": 0, "ended": 0, "matches": 0, "seconds": 0.0}
	for sd in seeds:
		for m in range(matches):
			var setup: Dictionary = {"planet": int(sd), "touch": m % 3, "arena": {"cols": 2400}, "planetGen": 2, "intro": false}
			var S := SimCore.createSim()
			SimCore.newMatch(S, 100 + m, {}, setup)
			var pend: Dictionary = {}   # target index: true while his launch's flight is under way
			var n0: int = int(tot.launches)
			for t in range(ticks):
				SimCore.step(S)
				for e in S.out.fx:
					if String(e.type) != "launch_plan" or SKIP.has(String(e.chosen)):
						continue
					var nm: String = String(e.chosen)
					var ti: int = int(e.target)
					tot.launches += 1
					tot.chosen[nm] = int(tot.chosen.get(nm, 0)) + 1
					var bio: String = WorldBiomes.fineNameAt(S.fighters[ti].x)
					if not tot.byBiome.has(bio):
						tot.byBiome[bio] = {}
					tot.byBiome[bio][nm] = int(tot.byBiome[bio].get(nm, 0)) + 1
					var seen: Dictionary = {}
					for part in String(e.text).split("|"):
						var c: String = part.substr(0, part.rfind(" "))
						if c.contains("#"):
							c = c.substr(0, c.find("#"))
						if c != "" and not seen.has(c):
							seen[c] = true
							tot.offered[c] = int(tot.offered.get(c, 0)) + 1
					pend[ti] = 2   # look from the next tick: the launch is applied after the plan
				for ti in pend.keys():
					var f = S.fighters[ti]
					if int(pend[ti]) > 1:
						pend[ti] = 1
					elif f.state != "launched":
						tot.ended += 1
						if WorldTerrain.seaAt(S, f.x) or f.y < WorldWater.seaTop(S, f.x):
							tot.sea += 1
						pend.erase(ti)
				S.out.fx.clear()
				S.out.feed.clear()
				if S.game.ko != null and S.game.koT > 3.0:
					break
			tot.matches += 1
			tot.seconds += S.T
			print("seed %d match %d: %.0f s, %d launches" % [int(sd), m, S.T, int(tot.launches) - n0])
			SimCore.dispose(S)
	DirLaunch.forceBiome = -1
	print("BATCH " + JSON.stringify(tot))
	quit()
