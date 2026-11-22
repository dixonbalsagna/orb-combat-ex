extends SceneTree
# The world a match plays on when its setup names none (World, A-WORLD-01 and A-WORLD-14; sim/world/default.gd, data/biomes/world.json). From the repo root:
#   godot --headless --path . --script res://sim/world/tools/world_default_check.gd -- [--negative-control]
# Proves: shipped, a setup with no planet key plays the hand-made arena as it did; with the mode on planet it plays the round planet (a generated planet, not the arena); an explicit planet key and the key world: "arena"
# win; the same seed gives the same planet twice and the same match hash; the quick-match draw is a pure function of the match's seed, stays in the data's pool and uses all of it; a first match and the tests use the fixed
# planet; every planet in the pool, at every touch, generates and plays. --negative-control makes the draw ignore the seed: the spread check must then fail.
var fails: int = 0
var negative: bool = false
const SU: Dictionary = {"intro": false}


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func _match(seed: int, setup: Dictionary, ticks: int = 60) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, setup)
	for t in range(ticks):
		SimCore.step(S)
	return S


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	print("data")
	ok(WorldDefault.dataErrors().is_empty(), "world.json loads clean (%s)" % str(WorldDefault.dataErrors()))
	var shipped: String = WorldDefault.mode()
	ok(shipped == "arena" or shipped == "planet", "the data's mode is arena or planet (it is %s)" % shipped)
	if shipped == "arena":
		ok(WorldDefault.apply({}, 5).is_empty() and WorldDefault.part(5).is_empty(), "the mode is arena (until GW1b): a setup with no planet key plays the hand-made arena, and nothing is added to it")
	else:
		ok(int(WorldDefault.apply({}, 5, true).get("planet", -1)) == 7, "the mode is planet (GW1b): a setup with no planet key plays the fixed planet 7 (the sim's hook asks for the fixed one)")
	print("the planet default")
	WorldDefault.setForTest("planet", false)
	var s: Dictionary = {"intro": false}
	var a: Dictionary = WorldDefault.apply(s, 5)
	ok(int(a.planet) == 7 and int(a.touch) == 3 and int(a.planetGen) == 3 and a.intro == false, "a setup with no planet key gets the fixed planet (7, touch 3, generation 3)")
	ok(not s.has("planet"), "... and the setup it was given is not changed")
	ok(int(WorldDefault.apply({"planet": 3, "touch": 1}, 5).planet) == 3, "an explicit planet key wins")
	ok(not WorldDefault.apply({"world": "arena"}, 5).has("planet"), "the key world: arena asks for the hand-made arena, and gets it")
	print("the draw")
	WorldDefault.setForTest("planet", true)
	var same: bool = true
	var seen: Dictionary = {}
	var seenT: Dictionary = {}
	var pool: Array = WorldDefault.K_POOL
	var inPool: bool = true
	var det: bool = true
	for sd in range(1, 301):
		var d1: Array = WorldDefault.draw(sd if not negative else 1)
		var d2: Array = WorldDefault.draw(sd if not negative else 1)
		det = det and d1 == d2
		seen[d1[0]] = true
		seenT[d1[1]] = true
		inPool = inPool and pool.has(d1[0])
	ok(det, "the same seed draws the same planet and touch, every time (300 seeds)")
	ok(inPool, "every draw is a planet in the data's pool")
	ok(seen.size() == pool.size() and seenT.size() == WorldDefault.K_TOUCHES.size(), "300 seeds use the whole pool (%d of %d planets, %d of %d touches)" % [seen.size(), pool.size(), seenT.size(), WorldDefault.K_TOUCHES.size()])
	var p1: Dictionary = WorldDefault.part(11)
	var pf: Dictionary = WorldDefault.part(11, true)
	ok(int(pf.planet) == 7 and int(pf.touch) == 3, "a newcomer's first match plays the fixed planet whatever the seed")
	ok(p1.has("planet") and p1.has("touch") and int(p1.planetGen) == 3, "a quick match's part names the planet, the touch and the generation")
	print("matches")
	WorldDefault.setForTest("planet", false)
	var A := _match(77, SU)
	var d: Dictionary = WorldDefault.describe(A)
	ok(not A.planetRing.is_empty() and int(d.planet) == 7 and int(d.gen) == 3 and A.frame != null, "with the mode on planet a match with no planet key plays a generated planet (planet %d, generation %d, a frame), not the arena" % [d.planet, d.gen])
	var B := _match(77, SU)
	ok(SimHash.stateHash(A).gameplay == SimHash.stateHash(B).gameplay and WorldPlanet.dataHash(3) == WorldPlanet.dataHash(3), "the same seed plays the same planet twice: the match's hash is the same at tick 60")
	var Ar := _match(77, {"intro": false, "world": "arena"})
	ok(Ar.planetRing.is_empty() and int(WorldDefault.describe(Ar).planet) == 0, "world: arena plays the hand-made arena (no planet ring)")
	WorldDefault.setForTest(shipped, false)
	var Sh := _match(77, SU)
	if shipped == "arena":
		ok(Sh.planetRing.is_empty(), "with the data's mode (arena) the same setup plays the arena")
	else:
		ok(not Sh.planetRing.is_empty(), "with the data's mode (planet) the same setup plays a planet")
	print("every planet in the pool generates and plays")
	WorldDefault.setForTest("planet", true)
	var bad: int = 0
	for pl in pool:
		for tc in WorldDefault.K_TOUCHES:
			var M := _match(3, {"intro": false, "planet": pl, "touch": tc, "planetGen": 3}, 90)
			var f0 = M.fighters[0]
			var f1 = M.fighters[1]
			var fine: bool = M.tick >= 90 and is_finite(f0.x) and is_finite(f0.y) and is_finite(f1.x) and is_finite(f1.y) and int(M.planetRing.seed) == pl and M.frame != null
			if not fine:
				bad += 1
				print("     planet %d touch %d did not start well" % [pl, tc])
			SimCore.dispose(M)
	ok(bad == 0, "%d planets at %d touches each: all generate and play 90 ticks" % [pool.size(), WorldDefault.K_TOUCHES.size()])
	WorldDefault.setForTest(shipped, false)
	print("WORLDDEFAULT: %d check(s) failed%s" % [fails, " (negative control)" if negative else ""])
	quit(0)
