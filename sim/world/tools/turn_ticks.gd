extends SceneTree
# The cost of each tick of a calm turn's warm-up and preparation, gen 1 and gen 2 (the swap must not hitch): ticks WorldEpoch.tick with no hold until every ring is warm, and prints each tick's ms.
#   godot --headless --path . --script res://sim/world/tools/turn_ticks.gd
func run(gen: int) -> void:
	var setup: Dictionary = {"planet": 7, "touch": 1, "arena": {"cols": 2400, "turn": true}, "intro": false}
	if gen == 2:
		setup["planetGen"] = 2
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, setup)
	for t in range(30):
		SimCore.step(S)
	S.T = 100.0
	var mid: float = 0.5 * (S.fighters[0].x + S.fighters[1].x)
	if WorldEpoch.ask(S, "t", mid, 1, 0).is_empty():
		print("gen %d: no turn asked" % gen)
		return
	WorldEpoch.choose(S, 3)
	S.epoch.next.k = 100000
	var times: Array = []
	var n: int = 0
	while WorldEpoch.warmAngles(S).size() < S.epoch.warm.size() and n < 300:
		var t0: int = Time.get_ticks_usec()
		WorldEpoch.tick(S, false)
		times.append("%.1f" % (float(Time.get_ticks_usec() - t0) / 1000.0))
		n += 1
	var t1: int = Time.get_ticks_usec()
	WorldEpoch.tick(S, true)
	var swapMs: float = float(Time.get_ticks_usec() - t1) / 1000.0
	print("gen %d: %d ticks to warm, each ms: %s; the swap tick %.1f ms" % [gen, n, " ".join(times), swapMs])


func _init() -> void:
	run(1)
	run(2)
	WorldClimate.useGen(0)
	quit()
