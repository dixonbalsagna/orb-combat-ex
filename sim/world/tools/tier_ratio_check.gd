extends SceneTree
# A-WORLD-06: the crater's width at the top tier is about three times the base (X-14; Game Design's numbers, docs/design/buildings.md section 6.2; docs/world/crater-tiers.md).
#   godot --headless --path . --script res://sim/world/tools/tier_ratio_check.gd
# With the energy model on, the model decides: from a fresh base fighter to the top tier at full power at least 3 times, and tier for tier at equal power between 2.5 and 3.5.
# With it off, the tier table (craters.json tier: energy 1, 2.1, 4.3, 9) makes the radius 1, 1.45, 2.07 and 3.0 times: the top tier's 3.0 within 5 percent. Shots (blast.json tierEnergy) read the same numbers with the model off;
# with it on a shot's crater energy is the kind's own base times 12.25 to the level, 3.5 times the radius from a fresh base fighter to a full top tier (Game Design, docs/design/buildings.md section 9).
# The table rows set the table themselves (WorldCraters.setTier), so they test the rule whether the data's switch is on or off; two rows read the data's own words.
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


## The radius of a bowl a send of this speed and tier digs, uncapped (what the dig uses for a special or a model blow).
func _r(sp: float, tier: float, S) -> float:
	return WorldCrater.radiusOf(WorldCrater.impactEnergy(sp, tier, S), true)


func _init() -> void:
	ok(WorldCraters.dataErrors().is_empty(), "craters.json loads clean (%s)" % str(WorldCraters.dataErrors()))
	var tab: PackedFloat64Array = WorldCraters.tierTable()
	ok(tab.size() == 4 and tab[0] == 1.0 and absf(tab[1] - 2.1) < 1.0e-9 and absf(tab[2] - 4.3) < 1.0e-9 and absf(tab[3] - 9.0) < 1.0e-9, "the data's table is Game Design's: 1, 2.1, 4.3, 9 (%s)" % str(tab))
	var B = JSON.parse_string(FileAccess.get_file_as_string("res://data/biomes/blast.json"))
	var te: Array = B.tierEnergy if B is Dictionary and B.has("tierEnergy") else []
	var shots_on: bool = te.size() == 4 and absf(float(te[3]) - 9.0) < 1.0e-9
	var shots_off: bool = te.size() == 4 and absf(float(te[3]) - 2.2) < 1.0e-9
	ok(shots_on or shots_off, "shots: blast.json tierEnergy is today's (1, 1.3, 1.7, 2.2) or the table (1, 2.1, 4.3, 9): %s" % str(te))
	if WorldCraters.tierOn():
		ok(shots_on and absf(float(te[1]) - 2.1) < 1.0e-9 and absf(float(te[2]) - 4.3) < 1.0e-9, "with the tier table on, shots read the same numbers with the model off (%s)" % str(te))
	else:
		ok(shots_off, "with the tier table off, shots are today's with the model off (%s)" % str(te))
	var was_on: bool = WorldCraters.tierOn()
	var was_tab: PackedFloat64Array = WorldCraters.tierTable()
	var table := PackedFloat64Array([1.0, 2.1, 4.3, 9.0])
	var Soff := SimCore.createSim()
	Soff.powerOn = false
	var Son := SimCore.createSim()
	Son.powerOn = true
	# --- the model off, with the table: radius 1, 1.45, 2.07, 3.0 times
	WorldCraters.setTier(true, table)
	var base: float = _r(900.0, 1.0, Soff)
	var rs: Array = []
	for t in range(1, 5):
		rs.append(_r(900.0, float(t), Soff) / base)
	ok(absf(float(rs[3]) - 3.0) <= 0.15, "model off, table: tier 4 digs %.3f times tier 1 (3.0 within 5 percent)" % float(rs[3]))
	ok(absf(float(rs[1]) - 1.45) < 0.03 and absf(float(rs[2]) - 2.07) < 0.03, "... tiers 2 and 3 dig %.3f and %.3f times (1.45, 2.07)" % [float(rs[1]), float(rs[2])])
	ok(is_equal_approx(WorldCrater.impactEnergy(900.0, 1.0, Soff), 1.0) and is_equal_approx(WorldCrater.impactEnergy(900.0, 4.0, Soff), 9.0), "... energy 1 at tier 1 and 9 at tier 4 at 900 a second")
	var mono: bool = true
	var last: float = 0.0
	for k in range(0, 31):
		var e: float = WorldCraters.tierEnergy(1.0 + float(k) * 0.1)
		if e < last:
			mono = false
		last = e
	ok(mono and is_equal_approx(WorldCraters.tierEnergy(2.5), 3.2) and WorldCraters.tierEnergy(0.2) == 1.0 and WorldCraters.tierEnergy(7.0) == 9.0, "a tier between two is the line between them (2.5 reads %.2f), and the ends hold" % WorldCraters.tierEnergy(2.5))
	# --- the model off, without the table: today's 25 percent a tier
	WorldCraters.setTier(false, table)
	var old4: float = _r(900.0, 4.0, Soff) / _r(900.0, 1.0, Soff)
	ok(is_equal_approx(WorldCrater.impactEnergy(900.0, 4.0, Soff), 1.75) and absf(old4 - sqrt(1.75)) < 1.0e-9, "table off: tier 4 is E 1.75 and %.3f times the width, as today (this is what the control below reads)" % old4)
	ok(absf(old4 - 3.0) > 0.15, "table off, the 3-times row would fail (%.3f)" % old4)
	# --- the model on: the model decides, the table is not read
	SimPower._ensure()
	var fresh := {"tier": 1.0, "power": 0.0}
	var top := {"tier": 4.0, "power": 100.0}
	WorldCraters.setTier(true, table)   # on, to show the model does not read it
	var r_base: float = _r(SimPower.fullSpeed(fresh), float(fresh.tier), Son)
	var r_top: float = _r(SimPower.fullSpeed(top), float(top.tier), Son)
	ok(r_base > 340.0 and r_base < 370.0 and r_top > 1200.0 and r_top < 1260.0, "model on: a fresh base fighter's full send digs %.0f and a top-tier one's %.0f (the plan's 356 and 1,244)" % [r_base, r_top])
	ok(r_top / r_base >= 3.0, "model on: base to top at full power is %.2f times (at least 3)" % (r_top / r_base))
	var good: bool = true
	var worst: String = ""
	for pw in [0.0, 25.0, 50.0, 75.0, 100.0]:
		var a := {"tier": 1.0, "power": pw}
		var b := {"tier": 4.0, "power": pw}
		var q: float = _r(SimPower.fullSpeed(b), 4.0, Son) / _r(SimPower.fullSpeed(a), 1.0, Son)
		if q < 2.5 or q > 3.5:
			good = false
			worst = "%.2f at power %d" % [q, int(pw)]
	ok(good, "model on: tier for tier at equal power it is between 2.5 and 3.5 times (tier 4 over tier 1 at power 0 reads %.2f)" % (_r(SimPower.fullSpeed({"tier": 4.0, "power": 0.0}), 4.0, Son) / _r(SimPower.fullSpeed({"tier": 1.0, "power": 0.0}), 1.0, Son)) + worst)
	ok(is_equal_approx(WorldCrater.impactEnergy(900.0, 4.0, Son), 1.0), "model on: no tier term, table or not (E 1 at 900 a second)")
	# --- shots: the model off reads blast.json tierEnergy, the model on the kind's base times 12.25 to the level (WorldBlast.shotModelOverride 1: the rule is behind blast.json's shotModel, shipped off)
	WorldBlast.shotModelOverride = 1
	var Dk: Dictionary = WorldBlast.data()
	var on_ok: bool = true
	var off_ok: bool = true
	var base_ok: bool = true
	var seen: int = 0
	var qon: float = 0.0
	var qoff: float = 0.0
	for kn in Dk.kinds:
		var kk: Dictionary = Dk.kinds[kn]
		seen += 1
		var e0: float = WorldBlast.craterEnergy(Son, fresh, kk, 1.0)
		var e1: float = WorldBlast.craterEnergy(Son, top, kk, 1.0)
		qon = WorldCrater.radiusOf(e1, true) / WorldCrater.radiusOf(e0, true)
		if absf(qon - 3.5) > 0.01:
			on_ok = false
		if not is_equal_approx(e0, float(kk.craterE)):
			base_ok = false
		var f1 := {"tier": 1.0, "power": 0.0}
		var f4 := {"tier": 4.0, "power": 0.0}
		qoff = WorldCrater.radiusOf(WorldBlast.craterEnergy(Soff, f4, kk, 1.0), true) / WorldCrater.radiusOf(WorldBlast.craterEnergy(Soff, f1, kk, 1.0), true)
		var want: float = sqrt(float(te[3]) / float(te[0]))
		if absf(qoff - want) > 0.001:
			off_ok = false
	ok(seen >= 4 and on_ok and base_ok, "model on: a shot's crater is the kind's base at level 0 and %.2f times the radius from a fresh base fighter to a full top tier, for each of %d kinds" % [qon, seen])
	ok(off_ok, "model off: a tier-4 shot digs %.3f times a tier-1 shot's radius, the square root of blast.json tierEnergy's last over its first (%.3f)" % [qoff, sqrt(float(te[3]) / float(te[0]))])
	if shots_on:
		ok(absf(qoff - 3.0) <= 0.15, "model off, table: a tier-4 shot is 3.0 times (within 5 percent): %.3f" % qoff)
	var alt := {"tier": 4.0, "power": 0.0}
	var kk0: Dictionary = Dk.kinds[Dk.kinds.keys()[0]]
	var qt: float = WorldCrater.radiusOf(WorldBlast.craterEnergy(Son, alt, kk0, 1.0), true) / WorldCrater.radiusOf(WorldBlast.craterEnergy(Son, fresh, kk0, 1.0), true)
	ok(qt >= 2.5 and qt <= 3.5, "model on: tier for tier at equal power a shot is between 2.5 and 3.5 times (tier 4 over tier 1 reads %.2f)" % qt)
	# the rule shipped off: with the energy model on a shot's crater is the kind's base times blast.json tierEnergy[tier], exactly as before this park, for each kind at each tier; and the rule on is not that (the row can fail)
	var same_old: bool = true
	var differs_on: bool = false
	for kn2 in Dk.kinds:
		var k2: Dictionary = Dk.kinds[kn2]
		for ti in range(4):
			var fz := {"tier": float(ti + 1), "power": 1.0}
			var base2: float = lerpf(float(k2.get("craterETap", k2.craterE)), float(k2.craterE), 1.0)
			var old: float = base2 * float(te[ti])
			WorldBlast.shotModelOverride = 0
			if not is_equal_approx(WorldBlast.craterEnergy(Son, fz, k2, 1.0), old):
				same_old = false
			WorldBlast.shotModelOverride = 1
			if not is_equal_approx(WorldBlast.craterEnergy(Son, fz, k2, 1.0), old):
				differs_on = true
	ok(same_old, "the shot rule off (shipped): with the energy model on a shot's crater is the kind's base times blast.json tierEnergy[tier], as the 9 November build, for every kind at every tier")
	ok(differs_on, "control: with the shot rule on a top-tier shot is not that, so the row above can fail")
	WorldBlast.shotModelOverride = -1
	var shipped_key: bool = Dk.has("shotModel")
	print("      blast.json shotModel in the shipped data: %s (absent or false: the shot rule is off)" % ("present, " + str(Dk.shotModel) if shipped_key else "absent"))
	WorldCraters.setTier(was_on, was_tab)
	print("TIERRATIO: %d check(s) failed" % fails)
	quit()
