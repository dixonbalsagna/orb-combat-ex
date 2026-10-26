extends SceneTree
# How often the campaign's ring turns (Game Design rulings 2026-10-26 item 5: 40 to 60% of columns 1 to 4), for tuning turn.minGain and turn.bonus: the planner is run over a sample of columns once, and the share
# that turn is read off for any pair of the two numbers. A column turns when the best turned ring's raw score plus the bonus is at least the unturned ring's plus minGain, so only (minGain - bonus) matters.
#   godot --headless --path . --script res://sim/world/tools/campaign_turns.gd [-- --gens=1,2 --planets=7,3,11,25,5,9]
## A Half ring through the planet's n-th city (the city is at the touch-down), as a setup's arena.
func ringThrough(P: WorldPlanet.Planet, nth: int, cols: int = 2400, phi: float = 0.7) -> Dictionary:
	var k: int = -1
	var id: int = 0
	for i in range(P.n):
		if P.kind[i] == WorldPlanet.KIND_CITY:
			k += 1
			if k == nth:
				id = i
				break
	return WorldRingPick.arenaOf(WorldRingPick.throughSpec(WorldRingPick.placePoint(P, id), cols, phi))


func _init() -> void:
	var gens: Array = [1, 2]
	var planets: Array = [7, 3, 11, 25, 5, 9]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--gens="):
			gens = Array(a.substr(7).split(",")).map(func(v): return int(v))
		if a.begins_with("--planets="):
			planets = Array(a.substr(10).split(",")).map(func(v): return int(v))
	WorldCampaign.setOn(true)
	var ds: Array = []
	for gen in gens:
		WorldClimate.useGen(gen)
		var dg: Array = []
		for sd in planets:
			var P := WorldPlanet.make(sd)
			for nth in range(2):
				var arena: Dictionary = ringThrough(P, nth)
				var here: Dictionary = arena
				var pc: int = int(WorldCampaign.specOf(arena).cols) / 2
				for col in range(1, 5):
					var job: WorldCampaign.ColumnJob = WorldCampaign.beginColumn(sd, 100 + sd + nth, col, here, pc, {})
					job.step(1 << 30)
					var s0: float = float(job.res[0].res.score)
					var best: float = -1.0e9
					for k in range(1, job.res.size()):
						best = maxf(best, float(job.res[k].res.score))
					dg.append(best - s0)
					# the walk continues on the ring the data's own numbers chose, as an episode would
					here = job.result.start
					pc = int(job.result.pc)
		dg.sort()
		ds.append_array(dg)
		var q: String = ""
		for p in [10, 25, 40, 50, 60, 75, 90]:
			q += " p%d %.2f" % [p, dg[mini(dg.size() - 1, dg.size() * p / 100)]]
		print("gen %d: %d columns; the best turned ring's score less the unturned one's:%s" % [gen, dg.size(), q])
	ds.sort()
	var bonus: float = WorldCampaign.K_TURN_BONUS
	for gain in [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]:
		var turned: int = 0
		for d in ds:
			if d + bonus >= gain - 1.0e-12:
				turned += 1
		print("  bonus %.2f minGain %.2f: %.0f%% of %d columns turn" % [bonus, gain, 100.0 * float(turned) / float(ds.size()), ds.size()])
	quit()
