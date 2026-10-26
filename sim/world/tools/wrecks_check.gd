extends SceneTree
# The liftable wreck (Game Design 23d section 8 item 20, Legal RL-183; WorldWrecks, data/biomes/wrecks.json): the query Encounter calls for the Cyborg's Wreck Toss and the scrap's burst.
#   godot --headless --path . --script res://sim/world/tools/wrecks_check.gd
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


## A building in the front row of at least `minMass`'s size, the nearest to x0 on its right.
func pickBuilding(S: SimState, x0: float, houses: bool):
	var best = null
	var bd: float = 1.0e18
	for b in S.buildings:
		if b.alive and int(b.row) == 1 and (b.floors < WorldBrunt.FLOORS_MIN) == houses and b.x > x0 and b.x - x0 < bd:
			bd = b.x - x0
			best = b
	return best


func kill(S: SimState, b) -> void:
	WorldStructures.damageBuilding(S, b, 1.0e9, S.fighters[0], "implode", b.x, 0.0)


func _init() -> void:
	ok(WorldWrecks.dataErrors().is_empty(), "wrecks.json is clean (%s)" % str(WorldWrecks.dataErrors()))
	var S := fresh(1)
	var f = S.fighters[0]
	var top: float = WorldWrecks.lift(4.0)
	var any: Dictionary = WorldWrecks.pick(S, f.x, f.y, f.z, top)
	ok(any.is_empty() and WorldWrecks.within(S, f.x, f.y, f.z, top).is_empty(), "no wreck stands where nothing has fallen: the query returns nothing")
	# the masses of the city's buildings, whole (for the data's numbers)
	var hm: Array = []
	var tm: Array = []
	for b in S.buildings:
		(tm if b.floors >= WorldBrunt.FLOORS_MIN else hm).append(WorldWrecks.mass(b))
	hm.sort()
	tm.sort()
	print("  houses %d: mass %.2f to %.2f (median %.2f); towers %d: %.2f to %.2f (median %.2f); lifts %s" % [hm.size(), hm[0], hm[hm.size() - 1], hm[hm.size() / 2], tm.size(), tm[0] if tm.size() > 0 else 0.0, tm[tm.size() - 1] if tm.size() > 0 else 0.0, tm[tm.size() / 2] if tm.size() > 0 else 0.0, str(WorldWrecks._d.tierLift)])
	# a fallen house, the fighter beside it
	var b = pickBuilding(S, f.x, true)
	ok(b != null, "the city has a house in the front row (hp %.0f, %.0f wide)" % [b.maxhp, b.w])
	kill(S, b)
	ok(not b.alive and WorldWrecks.isWreck(b) and WorldWrecks.empty(b) and b.popAlive == 0.0, "a house that falls is a wreck, and empty")
	f.x = b.x
	f.y = WorldStructures.baseY(S, b)
	f.z = b.z
	# neighbours may hold people: clear them for the first read, then put them back
	var saved: Array = []
	for o in S.buildings:
		if o != b and o.alive and absf(SimWrap.sdx(b.x, o.x)) - (b.w + o.w) * 0.5 < WorldWrecks.K_NEAR * WorldWrecks.BH + 1.0:
			saved.append([o, o.popAlive])
			o.popAlive = 0.0
	var pk: Dictionary = WorldWrecks.pick(S, f.x, f.y, f.z, top)
	ok(not pk.is_empty() and pk.id == b.idx and absf(pk.mass - WorldWrecks.mass(b)) < 1.0e-9 and pk.dist == 0.0, "beside it, the query returns the wreck's id and mass (id %d, mass %.2f)" % [pk.get("id", -1), pk.get("mass", 0.0)])
	var heavyLift: float = WorldWrecks.mass(b) * 0.5
	var why: Array = WorldWrecks.within(S, f.x, f.y, f.z, heavyLift)
	ok(WorldWrecks.pick(S, f.x, f.y, f.z, heavyLift).is_empty() and why.size() == 1 and why[0].why == "heavy", "a lift under its mass returns nothing, and says heavy")
	# reach: 2 body heights to the wreck's box
	var BH: float = WorldWrecks.BH
	f.x = b.x + b.w * 0.5 + 1.9 * BH
	var near_: bool = not WorldWrecks.pick(S, f.x, f.y, f.z, top).is_empty()
	f.x = b.x + b.w * 0.5 + 2.1 * BH
	var far_: bool = WorldWrecks.pick(S, f.x, f.y, f.z, top).is_empty()
	f.x = b.x
	f.y = WorldStructures.baseY(S, b) + 2.1 * BH
	var high_: bool = WorldWrecks.pick(S, f.x, f.y, f.z, top).is_empty()
	ok(near_ and far_ and high_, "within 2 body heights of its box it is found; past it, sideways or above, it is not")
	f.y = WorldStructures.baseY(S, b)
	# a living neighbour: Legal's rule
	var gotLiving: bool = false
	for s in saved:
		s[0].popAlive = s[1]
		if s[1] > 0.0:
			gotLiving = true
	var pl: Array = WorldWrecks.within(S, f.x, f.y, f.z, top)
	ok(not gotLiving or (WorldWrecks.pick(S, f.x, f.y, f.z, top).is_empty() and pl[0].why == "living"), "with people in a building beside it (%s) the wreck is not offered (RL-183)" % ("there are" if gotLiving else "there are none here: the check is vacuous"))
	# an occupied wreck is never offered (made by hand: the game has none)
	b.popAlive = 3.0
	ok(WorldWrecks.pick(S, f.x, f.y, f.z, top).is_empty() and not WorldWrecks.empty(b), "a wreck with anyone in it is not offered")
	b.popAlive = 0.0
	# burst
	for s in saved:
		s[0].popAlive = 0.0
	var counts: Array = []
	var tgt0 = null   # where the scrap lands: the toughest tower in the front row (a blast cannot finish a standing building, so only a tower shows the tiers)
	for o in S.buildings:
		if o.alive and o.floors >= WorldBrunt.FLOORS_MIN and int(o.row) == 1 and (tgt0 == null or o.maxhp > tgt0.maxhp):
			tgt0 = o
	for tier in [1.0, 2.0, 3.0, 4.0]:
		var St := fresh(1)
		var bt = St.buildings[b.idx]
		kill(St, bt)
		var hp0: float = 0.0
		for o in St.buildings:
			hp0 += maxf(o.hp, 0.0)
		var tg = St.buildings[tgt0.idx]
		var n: int = WorldWrecks.burst(St, bt.idx, tg.x, WorldStructures.baseY(St, tg), tier, St.fighters[0])
		var hp1: float = 0.0
		for o in St.buildings:
			hp1 += maxf(o.hp, 0.0)
		ok(n >= 0 and hp1 < hp0 and bt.marks == WorldWrecks.TAKEN and not WorldWrecks.isWreck(bt), "tier %d: landing on a tower the scrap takes %.0f hp off the structures (%d levelled) and the wreck is spent" % [int(tier), hp0 - hp1, n])
		counts.append(hp0 - hp1)
		if tier == 4.0:
			ok(WorldWrecks.burst(St, bt.idx, bt.x, 0.0, tier, St.fighters[0]) == -1 and WorldWrecks.pick(St, bt.x, 0.0, bt.z, top).is_empty(), "a spent wreck cannot be hurled again or offered")
	ok(counts[0] <= counts[1] and counts[1] <= counts[2] and counts[2] <= counts[3] and counts[3] > counts[0], "the scrap does more to structures as the tier rises (hp taken: %s)" % str(counts))
	var St2 := fresh(1)
	kill(St2, St2.buildings[b.idx])
	var S3 := fresh(1)
	kill(S3, S3.buildings[b.idx])
	WorldWrecks.burst(St2, b.idx, b.x, 0.0, 3.0, St2.fighters[0])
	WorldWrecks.burst(S3, b.idx, b.x, 0.0, 3.0, S3.fighters[0])
	ok(str(SimHash.stateHash(St2).gameplay) == str(SimHash.stateHash(S3).gameplay) and str(SimHash.stateHash(St2).gameplay) != str(SimHash.stateHash(fresh(1)).gameplay), "the burst is the same twice, and changes the state (hashed through the spent wreck's mark and the damage)")
	print("WRECKS: %d check(s) failed" % fails)
	quit()
