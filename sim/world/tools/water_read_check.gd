extends SceneTree
# The ground's record lookup (World, sim/world/waterrec.gd near: the box's records and the big ones, made once a box; the big ones in a coarse grid; docs/world/water-read.md): for every point, near() lists every record
# whose reach contains it (a record it leaves out could change the ground), in the order the records were planned, the same list twice, and a record the planet is too big for (past BIG_MAX) is still listed.
#   godot --headless --path . --script res://sim/world/tools/water_read_check.gd -- [--planet=7] [--touch=1]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _init() -> void:
	var planet: int = 7
	var touch: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	WorldClimate.useGen(3)
	WorldPlan.everywhereOverride = 1
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	var recs: Array = S.fieldRecs
	var R: float = SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI)
	ok(recs.size() > 100, "the planet has %d records to look up" % recs.size())
	var big: int = 0
	var centres: Array = []
	var reaches: PackedFloat64Array = PackedFloat64Array()
	for rec in recs:
		var c: Array = rec.get("c", [])
		if c.is_empty():
			c = [rec.get("px", 0.0), rec.get("py", 0.0), rec.get("pz", 0.0)]
		var reach: float = float(rec.get("r", 0.0)) + float(rec.get("blend", 0.0))
		if reach > WorldWaterRec.BIG:
			big += 1
		centres.append(c)
		reaches.append(reach)
	ok(big > 0, "%d of them reach past %.0f units (the coarse grid's)" % [big, WorldWaterRec.BIG])
	var missed: int = 0
	var unordered: int = 0
	var unstable: int = 0
	var points: int = 0
	var inside_total: int = 0
	var step: int = maxi(recs.size() / 300, 1)
	for k in range(0, recs.size(), step):
		var c: Array = centres[k]
		var reach: float = maxf(reaches[k], 50.0)
		for t in range(6):
			# a point at 0 to 1.4 reaches from the record's centre, in a direction that turns with t and k, on the sphere
			var ang: float = SimMathx.f64("3ff0c152382d7365") * float(t) + 0.37 * float(k)
			var dist: float = reach * (0.0 if t == 0 else 0.25 * float(t))
			var e1: Array = WorldPlanet._unit(WorldPlanet._cross(c, [0.0, 1.0, 0.0]))
			if absf(float(e1[0])) + absf(float(e1[1])) + absf(float(e1[2])) < 0.5:
				e1 = WorldPlanet._unit(WorldPlanet._cross(c, [1.0, 0.0, 0.0]))
			var e2: Array = WorldPlanet._cross(c, e1)
			var dx: float = SimDetMath.cos(ang) * dist / R
			var dy: float = SimDetMath.sin(ang) * dist / R
			var q: Array = WorldPlanet._unit([float(c[0]) + dx * float(e1[0]) + dy * float(e2[0]), float(c[1]) + dx * float(e1[1]) + dy * float(e2[1]), float(c[2]) + dx * float(e1[2]) + dy * float(e2[2])])
			var near: Array = WorldWaterRec.near(S, q[0], q[1], q[2])
			var near2: Array = WorldWaterRec.near(S, q[0], q[1], q[2])
			points += 1
			if near.size() != near2.size():
				unstable += 1
			var last: int = -1
			var set := {}
			for r in near:
				var idx: int = recs.find(r)
				if idx <= last:
					unordered += 1
				last = idx
				set[idx] = true
			for j in range(recs.size()):
				var cj: Array = centres[j]
				var ex: float = (float(q[0]) - float(cj[0])) * R
				var ey: float = (float(q[1]) - float(cj[1])) * R
				var ez: float = (float(q[2]) - float(cj[2])) * R
				if sqrt(ex * ex + ey * ey + ez * ez) <= reaches[j]:
					inside_total += 1
					if not set.has(j):
						missed += 1
	ok(points >= 1000 and inside_total > points, "%d points, %d record-reaches contain one" % [points, inside_total])
	ok(missed == 0, "near() lists every record whose reach contains the point (%d missed)" % missed)
	ok(unordered == 0, "the records come in the order they were planned (%d out of order)" % unordered)
	ok(unstable == 0, "the same point gives the same list twice")
	var avg: float = 0.0
	for k in range(0, recs.size(), step):
		var c2: Array = centres[k]
		avg += float(WorldWaterRec.near(S, c2[0], c2[1], c2[2]).size())
	avg /= float(ceili(float(recs.size()) / float(step)))
	print("  info records a lookup lists at a record's centre: %.1f on average (of %d)" % [avg, recs.size()])
	print("WATERREAD: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
