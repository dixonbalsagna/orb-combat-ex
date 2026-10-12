extends SceneTree
# the reads Game Design asked World for (docs/design/depth.md): home, depthRoom, nearestFace, crossingNear. Costs and agreement with brute force.
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func _init() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var BH: float = 75.0
	var rx: float = WorldLanes.body()[0]
	var rz: float = WorldLanes.body()[2]
	var ix: Array = WorldLanes.intersections(S, 46599.0, 3000.0)
	var c0: Array = ix[0]
	var st: Array = WorldLanes.streets()
	var lim: Array = WorldLanes.limits()
	# home
	var h: Array = WorldLanes.home(S, c0[0], c0[1])
	ok(h[2] == 1 and absf(h[0] - c0[0]) < 0.01 and absf(h[1] - c0[1]) < 0.01, "at a crossing's middle home is the crossing (kind %d, %.1f, %.1f)" % [h[2], h[0], h[1]])
	var mid0: float = (st[0][0] + st[0][1]) * 0.5
	var bx: float = c0[0] + c0[2] + 3.0 * BH   # x beside the avenue, in a block
	while WorldLanes.avenueAt(S, bx, 0.0) >= 0:
		bx += BH
	h = WorldLanes.home(S, bx, mid0 + 40.0)
	ok(h[2] == 0 and h[0] == bx and absf(h[1] - mid0) < 0.01, "in a street, off a crossing: the lane's middle, x kept (kind %d, hz %.1f)" % [h[2], h[1]])
	var between: float = (st[0][1] + st[1][0]) * 0.5
	h = WorldLanes.home(S, bx, between)
	ok(h[2] == 2, "in a block row at street level: the nearest street's middle (kind %d, hz %.1f)" % [h[2], h[1]])
	h = WorldLanes.home(S, c0[0], between)
	ok(h[2] == 2, "in a cross street between two streets: the nearest street's middle (kind %d)" % h[2])
	# depthRoom
	var r: Array = WorldLanes.depthRoom(S, c0[0], 60.0, c0[1], rx, rz)
	ok(absf(r[0] - (lim[1] + rz)) < 0.01 and absf(r[1] - (lim[0] - rz)) < 0.01, "in an avenue the room is the whole band (%.0f to %.0f)" % [r[0], r[1]])
	r = WorldLanes.depthRoom(S, bx, 60.0, mid0, rx, rz)
	ok(absf(r[0] - (st[0][1] + rz)) < 0.01 and absf(r[1] - (st[0][0] - rz)) < 0.01, "in a street between blocks the room is the street (%.0f to %.0f)" % [r[0], r[1]])
	r = WorldLanes.depthRoom(S, bx, 20000.0, mid0, rx, rz)
	ok(absf(r[0] - (lim[1] + rz)) < 0.01, "above every roof the room is the band again")
	# nearestFace against brute force
	var rng := SimRng.new(77)
	var bad: int = 0
	var found: int = 0
	var total_us: int = 0
	var n: int = 4000
	for i in range(n):
		var x: float = c0[0] + rng.range_(-1500.0, 1500.0)
		var z: float = rng.range_(lim[1], lim[0])
		var y: float = rng.range_(10.0, 900.0)
		var us: int = Time.get_ticks_usec()
		var f: Dictionary = WorldStructures.nearestFace(S, x, y, z, 300.0)
		total_us += Time.get_ticks_usec() - us
		var bb: int = -1
		var bdd: float = 300.0
		for bi in range(S.buildings.size()):
			var b = S.buildings[bi]
			if not b.alive or y > WorldStructures.baseY(S, b) + WorldStructures.curH(b):
				continue
			var dx: float = maxf(absf(SimWrap.sdx(x, b.x)) - b.w * 0.5, 0.0)
			var dz: float = maxf(absf(z - b.z) - b.d * 0.5, 0.0)
			var d: float = sqrt(dx * dx + dz * dz)
			if d < bdd or (d == bdd and bb >= 0 and bi < bb):
				bdd = d
				bb = bi
		if (bb < 0) != f.is_empty() or (bb >= 0 and int(f.b) != bb):
			bad += 1
		if not f.is_empty():
			found += 1
	ok(bad == 0, "nearestFace agrees with brute force on %d random points (%d with a face in reach, %d disagree)" % [n, found, bad])
	print("  cost: nearestFace %.1f us a call (%d calls)" % [float(total_us) / n, n])
	var us2: int = Time.get_ticks_usec()
	for i in range(n):
		WorldLanes.home(S, c0[0] + float(i % 97) * 30.0, rng.range_(lim[1], lim[0]))
	print("  cost: home %.1f us a call" % (float(Time.get_ticks_usec() - us2) / n))
	us2 = Time.get_ticks_usec()
	for i in range(n):
		WorldLanes.depthRoom(S, c0[0] + float(i % 97) * 30.0, 60.0, rng.range_(lim[1], lim[0]), rx, rz)
	print("  cost: depthRoom %.1f us a call" % (float(Time.get_ticks_usec() - us2) / n))
	us2 = Time.get_ticks_usec()
	for i in range(n):
		WorldLanes.crossingNear(S, c0[0] + float(i % 97) * 30.0, rng.range_(lim[1], lim[0]), 3.0 * BH)
	print("  cost: crossingNear (3 bh) %.1f us a call" % (float(Time.get_ticks_usec() - us2) / n))
	var cn: Array = WorldLanes.crossingNear(S, c0[0] + 100.0, c0[1] + 50.0, 3.0 * BH)
	ok(cn.size() == 3 and cn[2] <= 3.0 * BH, "a crossing within 3 bh of a point near one is found (%s)" % str(cn))
	# standingAt: the surface under a body
	var tb = null
	for b in S.buildings:
		if b.alive and int(b.row) == 1 and b.h > 600.0:
			tb = b
			break
	var top: float = WorldStructures.baseY(S, tb) + WorldStructures.curH(tb)
	var sa: Dictionary = WorldStructures.standingAt(S, tb.x, top + 40.0, tb.z)
	ok(sa.kind == "roof" and sa.b == tb.idx and absf(sa.y - top) < 0.01, "a body 40 units over a roof stands on it (%s at %.0f)" % [sa.kind, sa.y])
	sa = WorldStructures.standingAt(S, tb.x, top * 0.5, tb.z)
	ok(sa.kind == "ground", "a body inside the building's height reads the ground (the roof is not under it)")
	sa = WorldStructures.standingAt(S, tb.x + tb.w * 0.5 + 200.0, top + 40.0, tb.z)
	ok(sa.kind == "ground" or sa.b != tb.idx, "a body beside the footprint does not stand on its roof")
	var t0: int = Time.get_ticks_usec()
	for i in range(n):
		WorldStructures.standingAt(S, c0[0] + float(i % 97) * 30.0, 300.0, rng.range_(lim[1], lim[0]), 20.0)
	print("  cost: standingAt %.1f us a call" % (float(Time.get_ticks_usec() - t0) / n))
	print("DEPTHREADS: %d check(s) failed" % fails)
	quit()
