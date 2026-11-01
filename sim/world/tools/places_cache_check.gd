extends SceneTree
# The far places in the cache (World, sim/world/plan.gd placesLoad/placesStore, planet_world.gd settleFree): a warm match start lays the same buildings, lots and state as the cold one that filled the cache, a new ring
# that holds other places fills the rest, and with the cache off or rivers on nothing is kept.
#   godot --headless --path . --script res://sim/world/tools/places_cache_check.gd
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _match(planet: int, touch: int) -> SimState:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	return S


func _init() -> void:
	WorldFieldCache.dirOverride = "user://field-cache-places-check/"
	WorldFieldCache.enabledOverride = 1
	DirAccess.make_dir_recursive_absolute(WorldFieldCache.dir())
	for fn in DirAccess.get_files_at(WorldFieldCache.dir()):
		DirAccess.remove_absolute(WorldFieldCache.dir() + fn)
	WorldPlan.everywhereOverride = 1
	var t0: int = Time.get_ticks_usec()
	var cold := _match(7, 1)
	var t_cold: int = Time.get_ticks_usec() - t0
	var h_cold: String = str(SimHash.stateHash(cold).gameplay)
	var n: int = cold.buildings.size()
	var P := WorldPlanet.make(7)
	var kept: Dictionary = WorldPlan.placesLoad(P)
	ok(kept.size() > 30, "the cold start kept %d far places in the cache (%d buildings in the match)" % [kept.size(), n])
	print("  info the blob is %d KB for %d places" % [var_to_bytes(kept).size() / 1024, kept.size()])
	var t1: int = Time.get_ticks_usec()
	var warm := _match(7, 1)
	var t_warm: int = Time.get_ticks_usec() - t1
	ok(warm.buildings.size() == n and str(SimHash.stateHash(warm).gameplay) == h_cold, "a warm start lays the same state as the cold one (%d buildings, hash %s); cold %d ms, warm %d ms" % [n, h_cold, t_cold / 1000, t_warm / 1000])
	var same_lots: bool = cold.fieldRecs.size() == warm.fieldRecs.size()
	if same_lots:
		for i in range(cold.fieldRecs.size()):
			if var_to_str(cold.fieldRecs[i]) != var_to_str(warm.fieldRecs[i]):
				same_lots = false
				break
	ok(same_lots and cold.bDir == warm.bDir, "the records (platforms, lots) and the planet points are identical")
	# another ring holds other places: those are laid cold, the union is kept
	var other := _match(7, 2)
	var kept2: Dictionary = WorldPlan.placesLoad(P)
	ok(kept2.size() >= kept.size(), "another ring's start keeps its own places too (%d places now)" % kept2.size())
	var h_other: String = str(SimHash.stateHash(other).gameplay)
	var other2 := _match(7, 2)
	ok(str(SimHash.stateHash(other2).gameplay) == h_other, "and starts the same the second time")
	# cache off: nothing is kept
	WorldFieldCache.enabledOverride = 0
	ok(WorldPlan.placesLoad(P).is_empty(), "with the cache off nothing is read")
	for fn in DirAccess.get_files_at(WorldFieldCache.dir()):
		DirAccess.remove_absolute(WorldFieldCache.dir() + fn)
	DirAccess.remove_absolute(WorldFieldCache.dir())
	WorldFieldCache.dirOverride = ""
	WorldFieldCache.enabledOverride = -1
	WorldPlan.everywhereOverride = -1
	print("PLACESCACHE: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
