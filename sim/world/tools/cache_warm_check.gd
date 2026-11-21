extends SceneTree
# A world read back from the field cache is bit for bit the world a fresh bake makes (World, sim/world/plan.gd geometry; docs/world/field-cache-determinism.md). With plans.everywhere on, the far places are kept in
# user://field-cache (the places blob) and a later match restores them; a swing re-lays part of the planet. This plays one match twice, the second time from the cache the first filled, and compares every building's
# position and size and every ground column of the strip after the swing, bit for bit. Fault it guards: the layout memo's key rounded the shift to 8 units, so a layout made for one shift answered a call for another (whichever
# came first), and a cache warm start differed from a cold one in the last bits (about 1e-13 on 72 columns, 3e-11 on 5 building positions in Simulation's fork_check, planet 12).
#   godot --headless --path . --script res://sim/world/tools/cache_warm_check.gd -- [--planet=12] [--negative-control]
# --negative-control puts the old key back: the warm run must then differ from the cold one (the check passes when it does).
var fails: int = 0
const DIR: String = "user://cache-warm-check/"


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _step(S: SimState, n: int) -> void:
	for i in range(n):
		SimCore.step(S, null)
		S.out.fx.clear()


## One match: planet `planet`, a rematch first (as a process that played one before), ten ticks, then a swing; returns every building's x, z, h, w, d and every strip column's ground, as one array of doubles.
func _play(planet: int) -> PackedFloat64Array:
	WorldPlan._memo.clear()
	WorldPlanet.forget()
	var first := SimCore.createSim()
	SimCore.newMatch(first, 5, {"p1": false, "p2": false}, {"planet": planet, "touch": 2, "planetGen": 3, "intro": false})
	_step(first, 5)
	SimCore.dispose(first)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": false, "p2": false}, {"planet": planet, "touch": 1, "planetGen": 3, "intro": false})
	for f in S.fighters:
		f.y = 3000.0
	_step(S, 10)
	SimSwing.ask(S, {"deg": 40.0, "cause": "launch", "pivotX": SimWrap.wrap(S.fighters[0].x + 9000.0)})
	var n: int = 0
	while S.swing.active and n < 600:
		_step(S, 1)
		n += 1
	var out := PackedFloat64Array()
	out.append(float(S.buildings.size()))
	for b in S.buildings:
		out.append(b.x)
		out.append(b.z)
		out.append(b.h)
		out.append(b.w)
		out.append(b.d)
	for c in range(SimConst.NC):
		out.append(WorldTerrain.groundY(S, (float(c) + 0.5) * SimConst.COL))
	SimCore.dispose(S)
	return out


func _clear_dir() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var d := DirAccess.open(DIR)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)


func _init() -> void:
	var planet: int = 12
	var neg: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a == "--negative-control":
			neg = true
	WorldClimate.useGen(3)
	WorldFieldCache.dirOverride = DIR
	WorldFieldCache.enabledOverride = 1
	WorldPlan.everywhereOverride = 1
	WorldPlan.shiftBucketOverride = neg
	_clear_dir()
	var cold: PackedFloat64Array = _play(planet)
	var files: int = DirAccess.open(DIR).get_files().size()
	var warm: PackedFloat64Array = _play(planet)
	var diffs: int = 0
	var worst: float = 0.0
	for i in range(mini(cold.size(), warm.size())):
		if cold[i] != warm[i]:
			diffs += 1
			worst = maxf(worst, absf(cold[i] - warm[i]))
	print("      planet %d: the cold run filled %d cache files; %d numbers compared; %d differ (largest %s)" % [planet, files, cold.size(), diffs, String.num_scientific(worst)])
	_clear_dir()
	WorldPlan.shiftBucketOverride = false
	WorldPlan.everywhereOverride = -1
	WorldFieldCache.enabledOverride = -1
	WorldFieldCache.dirOverride = ""
	if neg:
		ok(files >= 2 and cold.size() == warm.size() and diffs > 0, "negative control (the old memo key): the warm run differs from the cold one (%d numbers, largest %s)" % [diffs, String.num_scientific(worst)])
	else:
		ok(files >= 2, "the cold run filled the cache (%d files: the planet and the places)" % files)
		ok(cold.size() == warm.size() and cold.size() > 3000, "both runs read the same number of values (%d)" % cold.size())
		ok(diffs == 0, "the warm run, read back from the cache, is bit for bit the cold run's: every building's position and size and every ground column after the swing (%d differ)" % diffs)
	print("CACHEWARM: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
