extends SceneTree
# How densely a gen 2 ring's places are built (docs/world/density.md, data/biomes/density.json): the archetype made denser for a gen 2 ring and never for gen 1; a gen 2 ring stands more structures with it on than off,
# the same twice; Half rings meet Game Design's target (at least 60 on average, aiming for 80); the other lengths scale with their columns.
#   godot --headless --path . --script res://sim/world/tools/density_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func match_for(planet: int, touch: int, cols: int, gen: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": planet, "touch": touch, "arena": {"cols": cols}, "planetGen": gen, "intro": false})
	return S


func sig(S: SimState) -> String:
	var h: int = S.buildings.size()
	for b in S.buildings:
		h = (h * 31 + int(b.x * 8.0) + int(b.w) * 7 + int(b.row) * 13) % 1000000007
	return "%d/%d" % [S.buildings.size(), h]


func _init() -> void:
	var D: Dictionary = WorldDensity.data()
	ok(WorldDensity.errors().is_empty() and not D.is_empty(), "density.json loads with no errors")
	# the archetype: apply() makes a copy denser and the data does not move
	WorldClimate.useGen(2)
	var arch: Dictionary = {}
	for sd in WorldSettle.data().settlements:
		arch[sd.id] = sd
	var before: String = JSON.stringify(arch["outskirts"])
	var copy: Dictionary = arch["outskirts"].duplicate(true)
	WorldDensity.apply(copy, "town")
	var g0: Array = arch["outskirts"].districts[0].gap_bh
	var g1: Array = copy.districts[0].gap_bh
	ok(absf(float(g1[0]) - float(g0[0]) * float(D.town.gapMul)) < 1.0e-9 and absf(float(g1[1]) - float(g0[1]) * float(D.town.gapMul)) < 1.0e-9, "a town's gaps are the archetype's times gapMul")
	var w0: Array = arch["outskirts"].districts[0].width_bh
	var w1: Array = copy.districts[0].width_bh
	ok(absf(float(w1[0]) - float(w0[0]) * float(D.town.widthMul)) < 1.0e-9, "a town's houses are the archetype's width times widthMul")
	ok(copy.districts[0].rows.has(3) and not copy.districts[0].rows.has(0), "a village builds the back street and never the foreground row")
	ok(JSON.stringify(arch["outskirts"]) == before, "the archetype in settlements.json is untouched (apply works on the caller's copy)")
	# gen 1 never reads it
	WorldClimate.useGen(1)
	var c1: Dictionary = arch["outskirts"].duplicate(true)
	WorldDensity.apply(c1, "town")
	ok(JSON.stringify(c1) == before, "gen 1: apply() changes nothing (on() is false)")
	# a ring: gen 1 planet ring identical with the module on or off; gen 2 more with it on, the same twice
	var on0: bool = bool(D.enabled)
	D["enabled"] = true
	var a1: String = sig(match_for(7, 2, 2400, 1))
	D["enabled"] = false
	var a0: String = sig(match_for(7, 2, 2400, 1))
	ok(a1 == a0, "a gen 1 planet ring is laid the same with the module on or off (%s)" % a1)
	D["enabled"] = true
	var h1: SimState = match_for(7, 2, 2400, 2)
	D["enabled"] = false
	var h0: SimState = match_for(7, 2, 2400, 2)
	ok(h1.buildings.size() > h0.buildings.size(), "a gen 2 ring stands more structures with it on than off (%d against %d)" % [h1.buildings.size(), h0.buildings.size()])
	D["enabled"] = true
	ok(sig(match_for(7, 2, 2400, 2)) == sig(h1), "a gen 2 ring is laid the same twice")
	# the targets: QA's forty gen 2 Half rings (ten planets, four touches) on average. A ring with few places stands few (2 of the 40 have none), so the mean is the target: Game Design's at least 60, aiming for 80
	var tot: int = 0
	var n: int = 0
	for pl in [3, 7, 11, 13, 17, 19, 23, 25, 29, 31]:
		for touch in range(4):
			tot += match_for(pl, touch, 2400, 2).buildings.size()
			n += 1
	var mean: float = float(tot) / float(n)
	ok(mean >= 70.0, "QA's forty Half rings stand %.1f structures on average (Game Design: at least 60, aiming for 80)" % mean)
	# the other lengths scale with their columns
	var half: int = match_for(13, 3, 2400, 2).buildings.size()
	var whole: int = match_for(13, 3, 4800, 2).buildings.size()
	ok(whole >= half, "a Whole ring stands at least what a Half ring on the same touch does (%d against %d)" % [whole, half])
	D["enabled"] = on0
	print("DENSITY: %d check(s) failed" % fails)
	quit()
