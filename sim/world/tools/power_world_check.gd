extends SceneTree
# The power model, World's half (docs/world/power-world.md; docs/design/power-scale.md; sim/core/power.gd is Simulation's): with a match's power switch on, a crater is the energy of the send with no tier term and no
# ordinary cap, a building takes its mass of the body's energy (house 1, low tower 5, tall tower 15) and a send goes through while it has it, and a send bounces off the terrain at most once. With the switch off nothing changes.
#   godot --headless --path . --script res://sim/world/tools/power_world_check.gd -- [--planet=7] [--touch=1]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _match(planet: int, touch: int, power: bool) -> SimState:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3, "power": power})
	for i in range(30):
		SimCore.step(S)
	return S


func _speed(E: float) -> float:
	return SimPower.speedUnit * sqrt(E)


## First building of the kind: "house", "low" (a tower under powerLowTowerMaxH) or "tall".
func _find(S: SimState, kind: String):
	var lim: float = float(WorldBrunt.cfg().powerLowTowerMaxH)
	for b in S.buildings:
		if not b.alive:
			continue
		var house: bool = WorldBrunt.isHouse(b)
		if (kind == "house" and house) or (kind == "low" and not house and b.h < lim) or (kind == "tall" and not house and b.h >= lim):
			return b
	return null


func _init() -> void:
	var planet: int = 7
	var touch: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	var off := _match(planet, touch, false)
	var on := _match(planet, touch, true)
	ok(not off.powerOn and on.powerOn, "the setup's power switch is the match's (off %s, on %s)" % [str(off.powerOn), str(on.powerOn)])
	# craters: the energy of the send, no tier term, no ordinary cap
	var e_old: float = WorldCrater.impactEnergy(900.0, 4.0)
	ok(is_equal_approx(e_old, 1.75) and is_equal_approx(WorldCrater.impactEnergy(900.0, 4.0, off), 1.75), "off: tier 4 at 900 a second is E 1.75, as before (%.2f)" % e_old)
	ok(is_equal_approx(WorldCrater.impactEnergy(900.0, 4.0, on), 1.0) and is_equal_approx(WorldCrater.impactEnergy(2700.0, 1.0, on), 9.0), "on: no tier term (900 is E 1, 2,700 is E 9)")
	var r_off = WorldCrater.dig(off, off.fighters[0].x, 100.0, off.fighters[0], "impact", 0.0, 1.0, false)
	var r_on = WorldCrater.dig(on, on.fighters[0].x, 100.0, on.fighters[0], "impact", 0.0, 1.0, false)
	ok(r_off != null and absf(r_off.r - WorldCrater.ORD_R_MAX) < 0.5, "off: an ordinary blow of E 100 is held to %.0f (%.0f)" % [WorldCrater.ORD_R_MAX, r_off.r if r_off != null else -1.0])
	ok(r_on != null and absf(r_on.r - WorldCrater.R_BASE * 10.0) < 0.5, "on: the same energy digs %.0f, 160 x root E (%.0f)" % [WorldCrater.R_BASE * 10.0, r_on.r if r_on != null else -1.0])
	# what a body goes through: the masses
	var house = _find(on, "house")
	var low = _find(on, "low")
	var tall = _find(on, "tall")
	ok(house != null and low != null and tall != null, "the planet has a house, a low tower and a tall tower to test on")
	ok(is_equal_approx(WorldBrunt.massOf(house), 1.0) and is_equal_approx(WorldBrunt.massOf(low), 5.0) and is_equal_approx(WorldBrunt.massOf(tall), 15.0), "masses 1, 5 and 15 (%.0f, %.0f, %.0f)" % [WorldBrunt.massOf(house), WorldBrunt.massOf(low), WorldBrunt.massOf(tall)])
	var oc: Dictionary = WorldBrunt.outcomeOf(on, house, 0.0, _speed(4.94), 1.0)
	ok(oc.pass and oc.outcome == "collapse" and is_equal_approx(oc.keep, sqrt((4.94 - 1.0) / 4.94)), "a base send (E 4.94) goes through a house and keeps %.2f of its speed" % oc.keep)
	var y_low: float = WorldStructures.baseY(on, low) + 0.5 * low.h
	var y_tall: float = WorldStructures.baseY(on, tall) + 0.5 * tall.h
	var lo1: Dictionary = WorldBrunt.outcomeOf(on, low, y_low, _speed(4.94), 4.0)
	var lo2: Dictionary = WorldBrunt.outcomeOf(on, low, y_low, _speed(6.0), 1.0)
	ok(not lo1.pass, "E 4.94 does not go through a low tower (mass 5), whatever the tier: %s" % lo1.outcome)
	ok(lo2.pass and is_equal_approx(lo2.keep, sqrt(1.0 / 6.0)), "E 6 does, and keeps the root of what is left (%.2f)" % lo2.keep)
	var hold: Dictionary = WorldBrunt.outcomeOf(on, tall, y_tall, _speed(14.0), 4.0)
	ok(not hold.pass and hold.keep == 0.0, "E 14 is held by a tall tower (mass 15): %s" % hold.outcome)
	# the maximum send through skyscrapers: four, then held
	var E: float = 60.5
	var n: int = 0
	for k in range(8):
		var o: Dictionary = WorldBrunt.outcomeOf(on, tall, y_tall, _speed(E), 4.0)
		if not o.pass:
			break
		n += 1
		E *= o.keep * o.keep
	ok(n == 4, "a maximum send (E 60.5) goes through %d tall towers (Game Design: 4), speed falling as it goes" % n)
	ok(WorldBrunt.chainCap(1.0, false, off) == 1.0 and WorldBrunt.chainCap(4.0, false, off) == 4.0 and WorldBrunt.chainCap(1.0, false, on) >= 99.0, "chain cap: off the tier's links (1 and 4), on the energy is the budget")
	# the tables that were read by tier are read by level under the power model: the last hit of a lodge, a slab, a thrown wreck, the hold
	var tf: Array = WorldBrunt.cfg().tierFactor
	var ls: Array = WorldBrunt.cfg().lodgeSeconds
	var base := {"tier": 1.0, "power": 0.0}
	var top := {"tier": 4.0, "power": 100.0}
	var mid := {"tier": 3.0, "power": 50.0}
	ok(WorldBrunt.tierFactorOf(off, top, 4.0, false) == float(tf[3]) and WorldBrunt.tierFactorOf(off, base, 1.0, false) == float(tf[0]), "off: the tier factor is the tier's row (%.2f, %.2f)" % [WorldBrunt.tierFactorOf(off, top, 4.0, false), WorldBrunt.tierFactorOf(off, base, 1.0, false)])
	ok(is_equal_approx(WorldBrunt.tierFactorOf(on, base, 4.0, false), float(tf[0])) and is_equal_approx(WorldBrunt.tierFactorOf(on, top, 1.0, false), float(tf[3])), "on: the level decides, not the tier: base %.2f, top %.2f" % [WorldBrunt.tierFactorOf(on, base, 4.0, false), WorldBrunt.tierFactorOf(on, top, 1.0, false)])
	var fm: float = WorldBrunt.tierFactorOf(on, mid, 1.0, false)
	ok(fm > float(tf[0]) and fm < float(tf[3]) and is_equal_approx(WorldBrunt.lodgeSecondsOf(on, top, 1.0, false), float(ls[3])) and is_equal_approx(WorldBrunt.lodgeSecondsOf(off, top, 4.0, false), float(ls[3])), "on: a middle level reads between the rows (%.2f), and the hold follows the level (%.1f s at the top)" % [fm, WorldBrunt.lodgeSecondsOf(on, top, 1.0, false)])
	# the terrain: at most one bounce a send
	var b4 := WorldContact.launchBody(0.0, 0.0, 0.0, 0.0, 1.0, 4.0)
	var b1 := WorldContact.launchBody(0.0, 0.0, 0.0, 0.0, 1.0, 1.0)
	ok(WorldContact._bounceCap(off, b4) == 3 and WorldContact._bounceCap(off, b1) == 1, "off: the bounces a send may take go with the tier (tier 4: %d, tier 1: %d)" % [WorldContact._bounceCap(off, b4), WorldContact._bounceCap(off, b1)])
	ok(WorldContact._bounceCap(on, b4) == 1 and WorldContact._bounceCap(on, b1) == 1, "on: one bounce a send at most, whatever the tier")
	var x0: float = float(on.fighters[0].x)
	var worst_on: int = 0
	var worst_off: int = 0
	var max_c_on: int = 0
	var max_c_off: int = 0
	for k in range(8):
		var ang: float = 0.12 + 0.05 * float(k)
		var vx: float = 3200.0 * 2.0 * cos(ang)
		var vy: float = -3200.0 * sin(ang)
		var bo = WorldContact.launchBody(x0, WorldTerrain.groundY(on, x0) + 400.0, vx, vy, 2.0, 4.0)
		var bf = WorldContact.launchBody(x0, WorldTerrain.groundY(off, x0) + 400.0, vx, vy, 2.0, 4.0)
		var jo: Dictionary = WorldContact.journey(on, bo)
		var jf: Dictionary = WorldContact.journey(off, bf)
		worst_on = maxi(worst_on, _count(jo, "bounce"))
		max_c_on = maxi(max_c_on, int(jo.n))
		worst_off = maxi(worst_off, _count(jf, "bounce"))
		max_c_off = maxi(max_c_off, int(jf.n))
	ok(worst_on <= 1 and max_c_on <= 3 + 6, "on: no journey of eight shallow tier-4 sends bounces off the ground more than once (%d; off: %d), and the contacts of the worst are %d (off: %d)" % [worst_on, worst_off, max_c_on, max_c_off])
	print("POWERWORLD: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)


func _count(j: Dictionary, kind: String) -> int:
	var n: int = 0
	for c in j.contacts:
		if String(c.kind) == kind:
			n += 1
	return n
