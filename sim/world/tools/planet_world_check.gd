extends SceneTree
# Planet window 2 (draft): a match on a slice. A smoke run, determinism, and the golden keys a regeneration would add.
#   godot --headless --path . --script res://sim/world/tools/planet_world_check.gd [-- <ticks>]
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func planetMatch(seed: int, planet: int, touch: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false, "planet": planet, "touch": touch})
	S.out.fx.clear()
	return S


func run(S: SimState, ticks: int) -> int:
	var n: int = 0
	for t in range(ticks):
		SimCore.step(S)
		S.out.fx.clear()
		n += 1
		if (S.game.ko != null):
			break
	return n


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var ticks: int = int(args[0]) if args.size() > 0 else 1800
	# ---- the hand-made world is as it was
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 1, {}, {"intro": false})
	ok(S0.buildings.size() == 118 and WorldBiomes.planetCols.size() == 0 and WorldBiomes.biomeAt(50000.0) == "city", "a setup without a planet is today's world (118 buildings, the city at x 50,000)")
	# ---- the planet world
	var S := planetMatch(1, 7, 3)
	var sl: WorldPlanet.Slice = WorldPlanet.sliceFor(7, 3)
	ok(S.buildings.size() > 20 and S.world.pop0 > 100.0, "a match on planet 7, touch 3: %d buildings, %d people, %d places held" % [S.buildings.size(), int(S.world.pop0), sl.held.size()])
	var near: bool = true
	for f in S.fighters:
		if absf(SimWrap.sdx(float(WorldPlanet.touchCol()) * SimConst.COL, f.x)) > 1000.0:
			near = false
	ok(near, "the fighters start astride the touch-down (x %.0f and %.0f)" % [S.fighters[0].x, S.fighters[1].x])
	var same: int = 0
	for i in range(0, SimConst.NC, 7):
		var b: String = WorldBiomes.biomeAt(float(i) * SimConst.COL + 1.0)
		if b == WorldPlanetWorld.BIOME_NAME[sl.biomes[i]] or b == "city" or b == "village":
			same += 1
	ok(same * 100 >= 99 * int(ceil(SimConst.NC / 7.0)), "biomeAt reads the slice's biomes (and a settlement's ground as village or city)")
	var placed: bool = true
	var seen := {}
	for b in S.buildings:
		var key: String = "%d/%d" % [b.place, b.plan]
		if b.place < 0 or b.plan < 0 or seen.has(key):
			placed = false
		seen[key] = true
		if b.x < 0.0 or b.x >= SimConst.W:
			placed = false
	ok(placed, "every building has a place and a plan index, unique, inside the world")
	var groundOk: bool = true
	for b in S.buildings:
		if WorldTerrain.groundY(S, b.x) < 0.0:
			groundOk = false
	ok(groundOk, "every building stands on dry ground")
	# ---- a smoke run, twice (determinism)
	var n: int = run(S, ticks)
	var h1: String = SimHash.stateHash(S).gameplay
	var S2 := planetMatch(1, 7, 3)
	run(S2, ticks)
	var h2: String = SimHash.stateHash(S2).gameplay
	ok(n == ticks or (S.game.ko != null), "ran %d ticks (%.0f s of match) without an error; casualties %.1f, craters %d, structures lost %d" % [n, S.T, S.world.casualties, S.craters.size(), int(S.world.structuresLost)])
	ok(h1 == h2, "the same planet, touch and seed play to the same hash twice (%s)" % h1)
	# ---- a second slice
	var S3 := planetMatch(2, 11, 2)
	run(S3, 600)
	ok(S3.buildings.size() > 0, "planet 11, touch 2: %d buildings, %d people; 600 ticks run" % [S3.buildings.size(), int(S3.world.pop0)])
	# ---- the golden keys a regeneration would add
	print("GOLDEN KEYS (planet window 2):")
	for pt in [[7, 3], [7, 9], [11, 2]]:
		print("  planetSlice %d/%d: slice hash %08x" % [pt[0], pt[1], WorldPlanet.sliceHash(WorldPlanet.sliceFor(pt[0], pt[1]))])
	for pt in [[7, 3], [11, 2]]:
		var St := planetMatch(1, pt[0], pt[1])
		print("  tick 0 of %d/%d: gameplay hash %s" % [pt[0], pt[1], SimHash.stateHash(St).gameplay])
	print("  AI match 7/3 seed 1 after %d ticks: %s" % [n, h1])
	print("PLANETWORLD: %d check(s) failed" % fails)
	quit()
