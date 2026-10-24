extends SceneTree
# What planet generation costs, generation 1 against generation 2 (World, window 3): a point (surfAt on random points), a ring pick (WorldPlanet.pick: the candidates read coarsely), a slice read (4,800
# columns, WorldPlanet.sliceFor: the pick and the full read), and a gen 2 planet's one-off set-up (the climate grid, the plates). Prints a table; whether a pick finds a ring in each generation.
#   godot --headless --path . --script res://sim/world/tools/gen_cost.gd -- --seeds=7,3,11,25 --touches=0,1,2,3
# Run it on a quiet machine (a run while other sessions hold the CPU is not a measurement).


func _init() -> void:
	var seeds: Array = [7, 3, 11, 25]
	var touches: Array = [0, 1, 2, 3]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = Array(a.substr(8).split(",")).map(func(v): return int(v))
		if a.begins_with("--touches="):
			touches = Array(a.substr(10).split(",")).map(func(v): return int(v))
	print("gen | seed | set-up ms | us a point | pick ms (found/%d) | slice read ms (4,800 cols, pick + read)" % touches.size())
	for g in [1, 2]:
		for sd in seeds:
			WorldClimate.useGen(g)
			WorldPlanet.forget()
			var t0: int = Time.get_ticks_usec()
			var P := WorldPlanet.make(sd)
			if g >= 2:
				WorldClimate.gridOf(P)
				WorldLand.platesOf(P)
			var setup: float = float(Time.get_ticks_usec() - t0) / 1000.0
			var rng := SimRng.new(99)
			var pts: Array = []
			for k in range(4000):
				pts.append(WorldPlanet.unitFromDraws(rng.next(), rng.next()))
			t0 = Time.get_ticks_usec()
			for q in pts:
				WorldPlanet.surfAt(P, q[0], q[1], q[2])
			var us: float = float(Time.get_ticks_usec() - t0) / 4000.0
			var found: int = 0
			var pickMs: float = 0.0
			var sliceMs: float = 0.0
			SimConst.setArena(SimConst.PLANET_NC)
			for tk in touches:
				t0 = Time.get_ticks_usec()
				var r: Dictionary = WorldPlanet.pick(P, tk, PackedByteArray(), false)
				pickMs += float(Time.get_ticks_usec() - t0) / 1000.0
				if r.ok:
					found += 1
					t0 = Time.get_ticks_usec()
					var sl: WorldPlanet.Slice = WorldPlanet.readSlice(P, WorldPlanet.ringThrough(r.circle, SimConst.NC, 1), r.T, PackedByteArray())
					sliceMs += float(Time.get_ticks_usec() - t0) / 1000.0
			print("%d | %d | %.0f | %.1f | %.0f (%d/%d) | %.0f" % [g, sd, setup, us, pickMs / float(touches.size()), found, touches.size(), sliceMs / float(maxi(found, 1))])
	WorldClimate.useGen(0)
	quit()
