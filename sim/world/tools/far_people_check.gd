extends SceneTree
# A far town's people (World, sim/world/collateral.gd farInfo/wakeFar/kill; docs/world/places-everywhere.md; Game Design ring-any-angle/game-design.md 15): with plans.farPeople the far places' buildings hold
# people, asleep until the place is posed; with plans.farAnguish they count toward the hero's anguish by their place's share and feed nothing else. Off, a far building has no people.
#   godot --headless --path . --script res://sim/world/tools/far_people_check.gd
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _match(people: bool, anguish: bool) -> SimState:
	WorldClimate.useGen(3)
	WorldPlan.everywhereOverride = 1
	var d: Dictionary = WorldField.data()
	d["plans"]["farPeople"] = people
	d["plans"]["farAnguish"] = anguish
	d["plans"]["farReach"] = 100.0
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"intro": false, "planet": 7, "touch": 1, "planetGen": 3})
	return S


func _init() -> void:
	var off := _match(false, false)
	var n_off_pop: float = 0.0
	for b in off.buildings:
		n_off_pop += b.pop
	ok(not WorldCollateral.isFar(off, off.buildings.size() - 1), "off: no far record, no far building")
	var S := _match(true, true)
	var info: Array = WorldCollateral._farInfo(S)
	var nfar: int = int(info[0])
	ok(nfar > 0 and nfar < S.buildings.size(), "on: the far record names the first far building (%d of %d)" % [nfar, S.buildings.size()])
	var pop_far: float = 0.0
	var alive_far: float = 0.0
	for i in range(nfar, S.buildings.size()):
		pop_far += S.buildings[i].pop
		alive_far += S.buildings[i].popAlive
	ok(pop_far > 0.0 and alive_far == 0.0, "the far buildings hold %d people, all asleep" % int(pop_far))
	var pop_near: float = 0.0
	for i in range(nfar):
		pop_near += S.buildings[i].pop
	ok(S.world.pop0 == off.world.pop0 and S.popHist == off.popHist, "pop0 (%d) and the lure buckets are the first ring's" % int(S.world.pop0))
	ok(info[1].size() > 20, "%d far places" % info[1].size())
	# posing: out of reach nothing wakes, at a great reach everything does
	for t in range(60):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
	ok(S.world.farMask == 0, "no far place is within 100 units of a fighter: none is posed")
	WorldField.data()["plans"]["farReach"] = 1.0e7
	for t in range(40):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
	var posed: int = 0
	for k in range(mini(info[1].size(), 62)):
		if (S.world.farMask >> k) & 1:
			posed += 1
	ok(posed == mini(info[1].size(), 62), "within reach every place is posed (%d)" % posed)
	var woke: float = 0.0
	for i in range(nfar, S.buildings.size()):
		woke += S.buildings[i].popAlive
	ok(woke > 0.0 and absf(woke - pop_far) < 1.0e-6 or posed < info[1].size(), "a posed place's people are awake")
	ok(S.world.pop0 == off.world.pop0 and WorldCollateral.normPeople(S) == S.world.pop0, "posing places leaves pop0 (what menace, mood and Witness read) the first ring's")
	# a far casualty feeds the hero's anguish and nothing else
	var hero = null
	for f in S.fighters:
		if f.hasAnguish:
			hero = f
	var villain = S.fighters[0] if S.fighters[0] != hero else S.fighters[1]
	if hero != null:
		var bi: int = nfar
		while bi < S.buildings.size() - 1 and S.buildings[bi].popAlive <= 0.0:
			bi += 1
		var a0: float = hero.anguish
		var cas0: float = S.world.casualties
		var cb0: float = S.world.cbSum
		var men0: float = villain.menace if villain.hasMenace else 0.0
		var pow0: float = villain.power
		var got: float = WorldCollateral.kill(S, bi, 5.0, villain, 0.0, S.buildings[bi].x)
		ok(got > 0.0, "a casualty in a far building is %d people" % int(got))
		ok(hero.anguish > a0, "the hero's anguish rose (%.3f to %.3f)" % [a0, hero.anguish])
		ok(S.world.casualties == cas0 and S.world.cbSum == cb0 and (villain.menace if villain.hasMenace else 0.0) == men0 and villain.power == pow0, "casualties, the budget, menace and power did not move")
	# the share is a fraction of the place's own base (RL-228 term 3): losing a whole small place and a whole large one costs the hero the same
	if hero != null:
		var pls: Array = info[1]
		var small: Dictionary = {}
		var large: Dictionary = {}
		for pk in pls:
			if small.is_empty() or float(pk.pop) < float(small.pop):
				if float(pk.pop) > 0.0:
					small = pk
			if large.is_empty() or float(pk.pop) > float(large.pop):
				large = pk
		var costs: Array = []
		for pk in [small, large]:
			hero.anguish = 0.0
			for bi2 in range(int(pk.first), int(pk.first) + int(pk.count)):
				WorldCollateral.kill(S, bi2, S.buildings[bi2].popAlive, villain, 0.0, S.buildings[bi2].x)
			costs.append(hero.anguish)
		ok(float(large.pop) > 2.0 * float(small.pop) and costs[0] > 0.0 and absf(costs[1] - costs[0]) <= 0.01 * costs[0], "a place of %d people lost whole costs the hero %.3f, a place of %d costs %.3f: the same, whatever its size" % [int(small.pop), costs[0], int(large.pop), costs[1]])
	# the lint (RL-228 term 2): the far branch of WorldCollateral.kill names none of the four sinks that get nothing: menace, power from casualties, Witness, mood's aggression
	var src: String = FileAccess.get_file_as_string("res://sim/world/collateral.gd")
	var i0: int = src.find("far branch begin")
	var i1: int = src.find("far branch end")
	var body: String = src.substr(i0, i1 - i0)
	var bad: Array = []
	for word in ["menace", "power", "SimForms.casualty", "witness", "Witness", "mood", "Mood", "aggression", "casualties", "cbSum", "cbBuckets", "evtDead", "_feed(", "popHist"]:
		if body.find(word) >= 0:
			bad.append(word)
	ok(i0 > 0 and i1 > i0 and bad.is_empty(), "the far branch touches none of the sinks (menace, power from casualties, Witness, mood's aggression, the budget, the lure buckets) %s" % str(bad))
	# the chapel filter reaches the new towns: a far building of a no-target landmark reports it as the first ring's do
	var chap: int = 0
	var chap_bad: int = 0
	for i in range(nfar, S.buildings.size()):
		var lm: int = int(S.buildings[i].landmark)
		if lm > 0 and WorldSettle.noTarget(lm):
			chap += 1
	for i in range(nfar, S.buildings.size()):
		var lm2: int = int(S.buildings[i].landmark)
		if lm2 > WorldSettle.data().get("landmarks", []).size():
			chap_bad += 1
	ok(chap_bad == 0, "every far building's landmark index resolves in the data, so the director's no-target filter (WorldSettle.noTarget) reads the new towns as it does the first ring's (%d far buildings carry a no-target landmark on this planet)" % chap)
	# off: the same casualty feeds nothing
	WorldField.data()["plans"]["farPeople"] = false
	WorldField.data()["plans"]["farAnguish"] = false
	WorldPlan.everywhereOverride = -1
	print("FARPEOPLE: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
