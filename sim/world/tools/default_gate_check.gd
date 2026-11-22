extends SceneTree
# The default world and the host's load gate (World, docs/world/pending/a-world-01; GW1b review B-13): a set-up that names no planet passes SimPlanetLoad.mayStart, and the default planet is added after it, so a start that is
# refused in the game (a planet not made) makes it cold inside the start. With the host applying WorldDefault before its gate (grant-rendering-host.patch) the gate sees the planet. The rows are the gate's, not the host's:
#   godot --headless --path . --script res://sim/world/tools/default_gate_check.gd
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _init() -> void:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	WorldField.forget()
	WorldDefault.setForTest("planet", false)
	var named: Dictionary = WorldDefault.apply({}, 5, true)
	ok(int(named.get("planet", -1)) == 7 and int(named.get("touch", -1)) == 3 and int(named.get("planetGen", -1)) == 3, "mode planet: a set-up that names none plays planet 7, touch 3, generation 3 (%s)" % str(named))
	ok(SimPlanetLoad.mayStart({}), "the gate looks at a set-up with no planet and lets it through (the hole: the default is added after it)")
	ok(not SimPlanetLoad.mayStart(named), "the gate on the set-up with the default applied holds a start whose planet is not made")
	ok(SimPlanetLoad.mayStart(WorldDefault.apply({"planet": 7, "planetGen": 3}, 5, true)) == SimPlanetLoad.mayStart({"planet": 7, "planetGen": 3}), "an explicit planet is the gate's own business: the default does not touch it")
	ok(WorldDefault.apply({"world": "arena"}, 5, true).has("planet") == false and SimPlanetLoad.mayStart(WorldDefault.apply({"world": "arena"}, 5, true)), "world: arena plays the hand-made arena and the gate lets it through")
	WorldDefault.setForTest("arena", false)
	ok(WorldDefault.apply({}, 5, true).is_empty() and SimPlanetLoad.mayStart(WorldDefault.apply({}, 5, true)), "mode arena: nothing is added and the gate lets it through, as today")
	print("DEFAULTGATE: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
