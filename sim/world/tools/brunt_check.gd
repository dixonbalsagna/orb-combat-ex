extends SceneTree
# The ladder and the lodge (docs/design/buildings.md sections 1 and 4; data/biomes/brunt.json): what a body does to a house and to a tower by tier,
# the building that remembers its walls, a chain's links (a house half), and that every flight ends held or lodged.
#   godot --headless --path . --script res://sim/world/tools/brunt_check.gd
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


func _init() -> void:
	var S := fresh(1)
	var c: Dictionary = WorldBrunt.cfg()
	ok(WorldBrunt.dataErrors().is_empty(), "brunt.json loads clean (%s)" % str(WorldBrunt.dataErrors()))
	# a tower of 8 or more floors and a house, both whole
	var tw = null
	var hs = null
	for b in S.buildings:
		if tw == null and b.floors >= 8 and int(b.row) == 1:
			tw = b
		if hs == null and b.floors < WorldBrunt.FLOORS_MIN and int(b.row) == 1 and b.maxhp > 100.0:
			hs = b
	ok(tw != null and hs != null, "the city has a tower of 8 floors and a house in row 1 (%d floors, hp %.0f; a house hp %.0f)" % [tw.floors, tw.maxhp, hs.maxhp])
	var gy: float = WorldStructures.baseY(S, tw)
	var fh: float = WorldBrunt.floorH(tw)
	# the ladder, on intact buildings, over speeds of a launch (500 to 3000) and heights (the middle floors)
	var t1_through: int = 0
	var t1_n: int = 0
	var t2_first: int = 0
	var t2_second_through: int = 0
	var t3_ok: int = 0
	var t3_n: int = 0
	var t4_ok: int = 0
	var t4_n: int = 0
	for sp in [500.0, 900.0, 1400.0, 2000.0, 3000.0]:
		for fl in range(1, tw.floors - 1):
			var y: float = gy + (float(fl) + 0.5) * fh
			var o1: Dictionary = WorldBrunt.outcomeOf(S, tw, y, sp, 1.0, 0, false)
			t1_n += 1
			if o1.pass:
				t1_through += 1
			var o2a: Dictionary = WorldBrunt.outcomeOf(S, tw, y, sp, 2.0, 0, false)
			var o2b: Dictionary = WorldBrunt.outcomeOf(S, tw, y, sp, 2.0, 1, false)
			if o2a.outcome == "punch" or not o2a.pass:
				t2_first += 1
			if o2b.pass:
				t2_second_through += 1
			var o3: Dictionary = WorldBrunt.outcomeOf(S, tw, y, sp, 3.0, 5, false)
			var base3: Dictionary = WorldBrunt.outcomeDmg(S, tw, y, sp * float(c.tierFactor[2]) * float(c.bruntMul))
			t3_n += 1
			if (base3.outcome == "punch") == o3.pass:
				t3_ok += 1
			var o4: Dictionary = WorldBrunt.outcomeOf(S, tw, y, sp, 4.0, 5, false)
			var base4: Dictionary = WorldBrunt.outcomeDmg(S, tw, y, sp * float(c.tierFactor[3]) * float(c.bruntMul))
			t4_n += 1
			if (base4.outcome == "punch") == o4.pass:
				t4_ok += 1
	ok(t1_through == 0, "a tier-1 body never goes through an intact tower (%d of %d speed and height pairs pass)" % [t1_through, t1_n])
	ok(t2_second_through == 0, "at tier 2 a second tower holds him (the first may be punched: %d of %d)" % [t2_first, t1_n])
	ok(t3_ok == t3_n, "at tier 3 a tower the body has the strength to punch lets him through, and one it cannot holds him (%d of %d)" % [t3_ok, t3_n])
	ok(t4_ok == t4_n, "at tier 4 the same (%d of %d)" % [t4_ok, t4_n])
	# a house is gone through at every tier and speed
	var house_ok: int = 0
	var house_n: int = 0
	for t in [1.0, 2.0, 3.0, 4.0]:
		for sp in [500.0, 1500.0, 3000.0]:
			var oh: Dictionary = WorldBrunt.outcomeOf(S, hs, gy, sp, t, 0, false)
			house_n += 1
			if oh.pass and oh.outcome == "collapse" and absf(oh.keep - float(c.houseKeep)) < 0.0001 and oh.dmg >= hs.hp:
				house_ok += 1
	ok(house_ok == house_n, "a house is gone through at every tier and speed, at houseKeep, and the hit kills it (%d of %d)" % [house_ok, house_n])
	# the building that remembers its walls: three walls and the fourth goes through
	var Sw := fresh(1)
	var tw2 = null   # a median tower (9 to 15 floors): a 20-floor one holds a tier-1 body for good (its weakened floors still beat his hit)
	for b3 in Sw.buildings:
		if b3.floors >= 9 and b3.floors <= 15 and int(b3.row) == 1:
			tw2 = b3
			break
	var y2: float = WorldStructures.baseY(Sw, tw2) + (float(tw2.floors / 2) + 0.5) * WorldBrunt.floorH(tw2)
	var walls: int = 0
	var passed: bool = false
	for n in range(12):
		var o: Dictionary = WorldBrunt.outcomeOf(Sw, tw2, y2, 1400.0, 1.0, 0, false)
		if o.pass:
			passed = true
			break
		# apply the held hit as the runtime does: floor damage on the floors covered
		if tw2.fdmg.size() != tw2.floors:
			tw2.fdmg = PackedFloat32Array()
			tw2.fdmg.resize(tw2.floors)
			tw2.fdmg.fill(0.0)
		for j in o.hit:
			tw2.fdmg[j] += o.dmg
		walls += 1
	ok(passed and walls >= 2 and walls <= 8, "a tier-1 tower of %d floors and %.0f hit points gives way after %d walls at speed 1400 (the data's giveWay %.1f; a median tower of 13 floors: about 3)" % [tw2.floors, tw2.maxhp, walls, float(c.giveWay)])
	# flights: every flight that touches a building ends held or lodged; a chain never uses more links than its cap
	var rg := SimRng.new(404)
	var flights: int = 0
	var ended_ok: int = 0
	var cap_ok: int = 0
	var lodge_hold_ok: int = 0
	var lodges: int = 0
	var held_n: int = 0
	var t1_tower_punch: int = 0
	var by_tier := {}
	for n in range(260):
		var Sf := fresh(1 + n % 5)
		var A = Sf.fighters[1]
		var D = Sf.fighters[0]
		var special: bool = n % 13 == 0
		A.tier = float(1 + n % 4)
		A.hp = 1.0e9
		D.hp = 1.0e9
		var pick: int = int(rg.next() * float(Sf.buildings.size()))
		var side: float = -1.0 if rg.next() < 0.5 else 1.0
		D.x = SimWrap.wrap(Sf.buildings[pick].x - side * rg.range_(1200.0, 7000.0))
		D.y = WorldTerrain.groundY(Sf, D.x) + rg.range_(40.0, 300.0)
		var force: float = rg.range_(1500.0, 2600.0)
		var tierF: float = 1.0 + A.ld.launch * (A.tier - 1.0)
		var plan = null
		for cbi in WorldBrunt.candidates(Sf, D):
			plan = WorldBrunt.aim(Sf, A, D, Sf.buildings[cbi], force, tierF, special)
			if plan != null:
				break
		if plan == null:
			continue
		DirLaunch.doLaunch(Sf, A, D, plan, force)
		if special:
			D.launchSpecial = true
		var hits: Array = []
		var guard: int = 0
		var stop_after: float = 0.0
		while D.state == "launched" and guard < 900:
			Sf.dirS.stop = 0.0
			SimFighter.stepLaunched(Sf, D, SimConst.DT)
			for e in Sf.out.fx:
				if e.type == "building_hit":
					hits.append({"b": int(e.b), "outcome": str(e.outcome), "keep": float(e.keep), "stop": Sf.dirS.stop})
			Sf.out.fx.clear()
			guard += 1
		if hits.is_empty():
			continue
		flights += 1
		var last: Dictionary = hits[hits.size() - 1]
		var held: bool = last.outcome in ["crack", "dent", "wreck"]
		var lodged: bool = last.outcome in ["punch", "collapse", "pancake", "heavy"] and last.keep == 0.0
		if held or lodged:
			ended_ok += 1
		if held:
			held_n += 1
		if lodged:
			lodges += 1
		var want: float = WorldBrunt.lodgeSeconds(A.tier, special)
		if last.stop >= want - 0.0001 and (held or lodged):
			lodge_hold_ok += 1
		var used: float = 0.0
		for h in hits:
			if h.outcome in ["punch", "collapse", "pancake", "heavy"]:
				used += float(c.houseLink) if WorldBrunt.isHouse(Sf.buildings[h.b]) else 1.0
		if used <= WorldBrunt.chainCap(A.tier, special) + 0.0001:
			cap_ok += 1
		if A.tier == 1.0 and not special:
			for h in hits:
				var hb = Sf.buildings[h.b]
				if not WorldBrunt.isHouse(hb) and h.outcome == "punch" and (hb.fdmg.size() == 0):
					t1_tower_punch += 1
	ok(flights > 40, "%d flights touched a building" % flights)
	ok(ended_ok == flights, "every flight ends held at a wall or lodged in its last building (%d of %d; %d held, %d lodged)" % [ended_ok, flights, held_n, lodges])
	ok(lodge_hold_ok == flights, "the last hit holds the body for the tier's seconds (%d of %d)" % [lodge_hold_ok, flights])
	ok(cap_ok == flights, "no chain uses more links than its tier's cap, a house half (%d of %d)" % [cap_ok, flights])
	ok(t1_tower_punch == 0, "a tier-1 flight never punches an unmarked tower (%d did)" % t1_tower_punch)
	print("BRUNT: %d check(s) failed" % fails)
	quit()
