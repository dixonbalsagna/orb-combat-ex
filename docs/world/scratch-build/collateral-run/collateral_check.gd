extends SceneTree
# The collateral window's checks: the tables in data are today's numbers, present and peopleLeft, a building's place and plan, the owner lint.
#   godot --headless --path . --script res://sim/world/tools/collateral_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func fresh(seed: int = 1) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false})
	S.out.fx.clear()
	return S


func scan(dir: String, calls: Array, hits: Array, counted: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		if sub == "tools" or sub == "test":
			continue   # the checks and probes pass nulls on purpose
		scan(dir + "/" + sub, calls, hits, counted)
	for f in d.get_files():
		if not f.ends_with(".gd"):
			continue
		var path: String = dir + "/" + f
		var n: int = 0
		for line in FileAccess.get_file_as_string(path).split("\n"):
			var code: String = line.split("#")[0]
			if code.contains("static func"):
				continue
			for fn in calls:
				var at: int = code.find(fn + "(")
				if at < 0:
					continue
				n += 1
				var args: String = code.substr(at + fn.length() + 1)
				# a literal null among the arguments of the call
				if args.contains("(null") or args.contains(", null") or args.begins_with("null"):
					hits.append("%s: %s" % [path, line.strip_edges()])
		counted.append(n)


func _init() -> void:
	# ---- 1. the tables are today's numbers
	ok(WorldCollateral.loadErrors.is_empty(), "collateral.json loads clean (%s)" % str(WorldCollateral.loadErrors))
	ok(WorldCollateral.BUDGET == [0.02, 0.04, 0.08, 0.15] and WorldCollateral.CEILING == [0.10, 0.30, 0.60, 0.90], "budget and ceiling are today's numbers (the constants they replace)")
	var ea: Dictionary = WorldCollateral.EVENT_ALLOW
	ok(ea["slide"] == [0.0, 0.0, 0.05, 0.10] and ea["chain"] == [0.0, 0.0, 0.12, 0.20] and ea["landslide"] == [0.0, 0.0, 0.05, 0.10] and ea["quake"] == [0.0, 0.0, 0.0, 0.10], "the four set-piece allowances are today's numbers")
	ok(ea.has("catastrophe") and ea["catastrophe"] == [0.0, 0.0, 0.0, 0.0], "the catastrophe kind is there, zero below tier 5")
	ok(WorldCollateral.eventAllow("chain", 4) == 0.20 and WorldCollateral.eventAllow("chain", 6) == 0.20 and WorldCollateral.eventAllow("nope", 3) == 0.0 and WorldCollateral.eventAllow("chain", 1) == 0.0, "eventAllow reads a tier, the last entry past the table, 0 for an unknown kind")
	# ---- 2. present
	var S := fresh(1)
	var w: SimState.World = S.world
	ok(w.present == w.pop0 and w.peopleLeft < 0.0, "a match starts with present equal to pop0 and no limit (%d people)" % int(w.pop0))
	w.maxTier = 4.0
	for f in S.fighters:
		f.tier = 4.0
	ok(absf(WorldCollateral.budget(S) - 0.15 * w.pop0) < 1.0e-9, "the budget is a share of the people present (%.1f)" % WorldCollateral.budget(S))
	w.present = w.pop0 * 0.5
	ok(absf(WorldCollateral.budget(S) - 0.15 * w.pop0 * 0.5) < 1.0e-9 and absf(WorldCollateral.ceilingLeft(S) - 0.90 * w.pop0 * 0.5) < 1.0e-6, "with half the people present, the budget and the ceiling are half")
	ok(absf(WorldCollateral.normPeople(S) - w.pop0) < 1.0e-9, "the meters' norm is pop0 by data (a casualty is worth the same in ruins)")
	WorldCollateral.METER_NORM = "present"
	ok(absf(WorldCollateral.normPeople(S) - w.pop0 * 0.5) < 1.0e-9, "and present when the data says so")
	WorldCollateral.METER_NORM = "pop0"
	# ---- 3. peopleLeft
	var S2 := fresh(2)
	S2.world.maxTier = 4.0
	for f in S2.fighters:
		f.tier = 4.0
	S2.world.peopleLeft = 100.0
	ok(WorldCollateral.ceilingLeft(S2) <= 100.0 + 1.0e-9, "ceilingLeft takes the lower of the tier's ceiling and peopleLeft (%.0f)" % WorldCollateral.ceilingLeft(S2))
	var thrown: float = 0.0
	for b in S2.buildings:
		S2.world.cbSum = 0.0   # keep the window open: only the ceiling limits
		for i in range(WorldCollateral.WINDOW_S):
			S2.world.cbBuckets[i] = 0.0
		thrown += WorldCollateral.kill(S2, b.idx, b.popAlive, S2.fighters[0], 0.0, b.x)
	ok(S2.world.casualties <= 100.0 + 0.001 and S2.world.casualties > 50.0, "a match with peopleLeft 100 never loses more than 100 people (%.1f died; the rest sheltered)" % S2.world.casualties)
	# ---- 4. place and plan
	var S3 := fresh(1)
	var seen := {}
	var allPlaced: bool = true
	var maxPlace: int = -1
	for b in S3.buildings:
		if b.place < 0 or b.plan < 0:
			allPlaced = false
		maxPlace = maxi(maxPlace, b.place)
		var key: String = "%d/%d" % [b.place, b.plan]
		if seen.has(key):
			allPlaced = false
		seen[key] = true
	ok(allPlaced and seen.size() == S3.buildings.size(), "every building has a place and a plan index, and the pair is unique (%d buildings in %d places)" % [S3.buildings.size(), maxPlace + 1])
	var S4 := fresh(9)
	var same: bool = S4.buildings.size() == S3.buildings.size()
	for i in range(mini(S3.buildings.size(), S4.buildings.size())):
		if S3.buildings[i].place != S4.buildings[i].place or S3.buildings[i].plan != S4.buildings[i].plan:
			same = false
	ok(same, "a building has the same place and plan index in every match (the plan is seeded)")
	# ---- 5. the hash: conditional appends
	var h0: Array = SimHash.collect(S3, "gameplay")
	var S5 := fresh(1)
	S5.world.present = S5.world.pop0 * 0.9
	var h1: Array = SimHash.collect(S5, "gameplay")
	var S6 := fresh(1)
	S6.world.peopleLeft = 500.0
	var h2: Array = SimHash.collect(S6, "gameplay")
	ok(h1.size() == h0.size() + 1 and h2.size() == h0.size() + 1 and SimHash.collect(fresh(1), "gameplay").size() == h0.size(), "present and peopleLeft join the hash only when they differ from versus's (a versus hash is as it was)")
	# ---- 6. the owner lint: no damage path is given a literal null
	var hits: Array = []
	var counted: Array = []
	scan("res://sim", ["damageBuilding", "damageArea", "WorldStructures.explode", "collapse", "startFail"], hits, counted)
	var total: int = 0
	for n in counted:
		total += n
	ok(hits.is_empty() and total > 15, "no call of damageBuilding, damageArea, explode, collapse or startFail passes a literal null owner (%d calls scanned; %s)" % [total, str(hits)])
	print("COLLATERAL: %d check(s) failed" % fails)
	quit()
