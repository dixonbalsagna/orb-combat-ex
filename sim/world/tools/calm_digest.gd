extends SceneTree
# A calm turn played to its swap, its state hashed on the way: the tick the turn swaps on and the gameplay hash at fixed ticks, for a one-ring pick and a two-ring pick at several k. Compare two builds line for
# line: the calm turn must be the same turn.   godot --headless --path . --script res://sim/world/tools/calm_digest.gd [-- --total]   (--total: the turn data's warmTotal 1: k shared among the rings)
func scenario(k: int, fb: float, gen: int, total: bool, ahead: int) -> String:
	WorldClimate.useGen(gen)
	WorldRingPick.cfg().turn["warmTotal"] = 1 if total else 0
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}, "planetGen": gen, "intro": false})
	for t in range(30):
		SimCore.step(S)
	S.T = 100.0
	var px: float = 0.5 * (S.fighters[0].x + S.fighters[1].x)
	var c: Array = WorldEpoch.ask(S, "digest", px, 1, 0)
	WorldEpoch.choose(S, c.size() - 1, k, fb)
	var swapTick: int = -1
	var hs: String = ""
	var g: int = 0
	var aheadMax: int = 0
	while S.epoch.next != null and g < 3000:
		if ahead > 0:
			WorldEpoch.readAhead(S, ahead)
			for p in WorldEpoch.warmPlan(S):
				aheadMax = maxi(aheadMax, int(p[0]) - int(p[2]))
		SimCore.step(S)
		g += 1
		if g % 100 == 0:
			hs += " %d:%s" % [g, str(SimHash.stateHash(S).gameplay).substr(0, 10)]
	return "gen %d k %d fb %.1f total %s ahead %d: swapped after %d ticks%s final %s%s" % [gen, k, fb, str(total), ahead, g, hs, str(SimHash.stateHash(S).gameplay).substr(0, 16), (" (read ahead by up to %d columns)" % aheadMax) if ahead > 0 else ""]


func _init() -> void:
	var total: bool = "--total" in OS.get_cmdline_user_args()
	var withAhead: bool = "--ahead" in OS.get_cmdline_user_args()
	for gen in [1, 2]:
		for k in [32, 12]:
			print(scenario(k, 0.0, gen, total, 0))
			print(scenario(k, 2.5, gen, total, 0))
			if withAhead:
				print(scenario(k, 2.5, gen, total, 150))
	quit()
