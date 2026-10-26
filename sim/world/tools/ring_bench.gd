extends SceneTree
# The cost of reading a ring of the planet, and a fingerprint of what it reads, to prove a faster read is the same read:
#   godot --headless --path . --script res://sim/world/tools/ring_bench.gd [-- --fast]
# For several planets, rings and the three sizes it prints the slice hash (heights and biomes), the places held and the time a column costs. Compare the hashes before and after a change to the noise:
# they must be identical, line for line. (Times on a busy PC are for comparing runs on the same PC, not for budgets.)


func _init() -> void:
	var fast: bool = "--fast" in OS.get_cmdline_user_args()
	var gen: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--gen="):
			gen = int(a.substr(6))
	WorldClimate.useGen(gen)   # the generation the planets are made by (window 20: gen 2's read is proved the same by its hashes)
	var lines: Array = []
	var totUs: float = 0.0
	var totCols: int = 0
	for seed in ([7, 3, 11, 25] if not fast else [7]):
		var P := WorldPlanet.make(seed)
		for cols in [1200, 2400, 4800]:
			SimConst.setArena(cols)
			var T: Array = WorldPlanet.unitFromDraws(0.37 + 0.05 * float(seed % 7), 0.62)
			var spec: Dictionary = WorldRingPick.roundSpec(T, cols, 0.9) if cols < 4800 else WorldRingPick.throughSpec(T, cols, 0.9)
			var ring: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
			var t0: int = Time.get_ticks_usec()
			var sl: WorldPlanet.Slice = WorldPlanet.readSlice(P, ring, ring.u)
			var us: float = float(Time.get_ticks_usec() - t0)
			totUs += us
			totCols += SimConst.NC
			lines.append("g%d %d/%d hash %d held %d  %.1f us/col (%.0f ms)" % [gen, seed, cols, WorldPlanet.sliceHash(sl), sl.held.size(), us / float(SimConst.NC), us / 1000.0])
	for l in lines:
		print(l)
	print("RINGBENCH: %.1f us/col over %d columns" % [totUs / float(maxi(totCols, 1)), totCols])
	quit()
