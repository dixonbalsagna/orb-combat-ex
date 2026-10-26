extends SceneTree
# The throwable objects' hold points (docs/world/prop-hold-points.md; data/biomes/props.json; WorldProps):
#   godot --headless --path . --script res://sim/world/tools/props_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func near(a: Array, b: Array, e: float = 0.0001) -> bool:
	return a.size() == 3 and b.size() == 3 and absf(a[0] - b[0]) < e and absf(a[1] - b[1]) < e and absf(a[2] - b[2]) < e


func _init() -> void:
	ok(WorldProps.dataErrors().is_empty(), "props.json loads clean (%s)" % str(WorldProps.dataErrors()))
	var cl: Dictionary = WorldProps.classes()
	ok(cl.keys() == ["bike", "sedan", "van", "bus"], "the four classes of Art's cars (%s)" % str(cl.keys()))
	var art = JSON.parse_string(FileAccess.open("res://data/art/vehicles.json", FileAccess.READ).get_as_text())
	var same: bool = true
	for k in cl:
		var v = art.vehicles[k]
		if int(cl[k].length) != int(v.length) or int(cl[k].height) != int(v.height) or int(cl[k].mass) != int(v.mass_class):
			same = false
	ok(same, "each box and mass class is Art's (data/art/vehicles.json)")
	# the first tier that lifts a car is the throwables ruling's (docs/design/rule-of-cool.md: tier 1 lifts a van, tier 2 a bus), not Art's throw_tier (1, 2, 3, 4, still in vehicles.json)
	var tiers: Array = []
	for k in cl:
		tiers.append(int(cl[k].throwTier))
	ok(tiers == [1, 1, 1, 2], "each class's first throw tier is the throwables ruling's: bike, sedan and van 1, bus 2 (%s)" % str(tiers))
	# every class has all six slots and every point lies in its box
	var inbox: bool = true
	for k in cl:
		var c = cl[k]
		for sl in WorldProps.SLOTS:
			var p: Array = WorldProps.local(k, sl)
			if p.size() != 3 or absf(p[0]) > float(c.length) * 0.5 + 0.001 or p[1] < 0.0 or p[1] > float(c.height) + 0.001 or absf(p[2]) > float(c.depth) * 0.5 + 0.001:
				inbox = false
	ok(inbox, "all six hold points of every class lie inside its box")
	ok(WorldProps.local("tank", "frame").is_empty() and WorldProps.local("bike", "wing").is_empty() and WorldProps.holdPoint("tank", "top", 0.0, 0.0, 0.0).is_empty(), "an unknown class or slot gives []")
	# placement: no turn, facing +1 is the local point moved to the prop's place
	var p0: Array = WorldProps.holdPoint("sedan", "underside_r", 1000.0, 5.0, -20.0)
	ok(near(p0, [1000.0 + 54.0, 5.0 + 12.6, -20.0]), "unturned it is the local point moved to the prop's place (%s)" % str(p0))
	# facing -1 mirrors x: l and r swap places
	var pl: Array = WorldProps.holdPoint("sedan", "underside_l", 1000.0, 5.0, 0.0, 0.0, -1.0)
	ok(near(pl, [1000.0 + 54.0, 5.0 + 12.6, 0.0]), "turned about (facing -1) the left hold is where the right one was (%s)" % str(pl))
	# a turn keeps every point's distance from the middle of the box
	var keeps: bool = true
	for k in cl:
		var hm: float = float(cl[k].height) * 0.5
		for sl in WorldProps.SLOTS:
			var l: Array = WorldProps.local(k, sl)
			var d0: float = sqrt(l[0] * l[0] + (l[1] - hm) * (l[1] - hm))
			for t in [0.3, 1.2, 2.5, -1.7, 3.14159]:
				var w: Array = WorldProps.holdPoint(k, sl, 500.0, 40.0, 0.0, t)
				var dx: float = SimWrap.sdx(500.0, w[0])
				var d1: float = sqrt(dx * dx + (w[1] - 40.0 - hm) * (w[1] - 40.0 - hm))
				if absf(d1 - d0) > 0.001:
					keeps = false
	ok(keeps, "a turn about the middle of the box keeps each point's distance from it")
	# a quarter turn moves the front end to the top
	var q: Array = WorldProps.holdPoint("bus", "end_b", 0.0, 0.0, 0.0, PI * 0.5)
	var hmb: float = float(cl.bus.height) * 0.5
	ok(absf(q[1] - (hmb + 0.5 * float(cl.bus.length))) < 0.01 and absf(SimWrap.sdx(0.0, q[0]) + (WorldProps.local("bus", "end_b")[1] - hmb)) < 0.01, "a quarter turn (counter-clockwise) puts the bus's front end at the top (%s)" % str(q))
	# the seam: a prop astride x = 0 wraps its points
	var sw: Array = WorldProps.holdPoint("bus", "end_a", 4.0, 0.0, 0.0)
	ok(sw[0] > 0.0 and sw[0] < SimConst.NC * SimConst.COL and sw[0] > SimConst.NC * SimConst.COL - 300.0, "a prop at x = 4 has its rear end across the planet's seam (x %.1f)" % sw[0])
	# all six at once, and the same every call
	var all1: Dictionary = WorldProps.holdPoints("van", 300.0, 2.0, 5.0, 0.7, -1.0)
	var all2: Dictionary = WorldProps.holdPoints("van", 300.0, 2.0, 5.0, 0.7, -1.0)
	ok(all1.size() == 6 and str(all1) == str(all2), "holdPoints gives the six by name, the same every call")
	ok(WorldProps.dataHash().length() == 16, "the data has a hash (%s)" % WorldProps.dataHash())
	print("PROPS: %d check(s) failed" % fails)
	quit()
