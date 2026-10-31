extends SceneTree
# The field's records (World, sim/world/field.gd, data/biomes/field.json refine): a creased cell (a wall, a shoreline) is read at 32 units, exactly as the planet's function gives it, its neighbours carry the
# difference along the shared edge, and nothing cracks. Compares a gen 3 ring with the records on and off against gen 2's exact ring.
#   godot --headless --path . --script res://sim/world/tools/field_records_check.gd -- [--planet=7] [--touch=1]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _norm(a: Array) -> Array:
	var l: float = 1.0 / sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])
	return [a[0] * l, a[1] * l, a[2] * l]


func _mix(a: Array, b: Array, t: float) -> Array:
	return _norm([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t])


## The ground of the gen 3 ring of a match (planet, touch), the records on or off.
func _ring(planet: int, touch: int, rec: int) -> Dictionary:
	WorldPlanet.forget()
	WorldField.refineOverride = rec
	var S := SimCore.createSim()
	var t0: int = Time.get_ticks_usec()
	SimCore.newMatch(S, 1, {}, {"planet": planet, "touch": touch, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
	var F: WorldField.Field = WorldField.of(WorldPlanet.make(planet))
	return {"S": S, "F": F, "ms": ms}


func _shore(base: PackedFloat32Array) -> Array:
	var out: Array = []
	var nc: int = base.size()
	for i in range(nc - 1):
		if (base[i] - WorldWater.SHORE_WET) * (base[i + 1] - WorldWater.SHORE_WET) < 0.0:
			out.append(i)
	return out


func _init() -> void:
	var planet: int = 7
	var touch: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	ok(WorldField.dataErrors().is_empty() and bool(WorldField.data().refine.enabled), "field.json loads with the records on")
	# gen 2's exact ring
	WorldPlanet.forget()
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 1, {}, {"planet": planet, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	var NC: int = SimConst.NC
	var exact: PackedFloat32Array = S2.base.duplicate()
	var off: Dictionary = _ring(planet, touch, 0)
	var on: Dictionary = _ring(planet, touch, 1)
	WorldField.refineOverride = -1
	var res: Array = []
	for r in [off, on]:
		var base: PackedFloat32Array = r.S.base
		var sq: float = 0.0
		var mx: float = 0.0
		for i in range(NC):
			var e: float = base[i] - exact[i]
			sq += e * e
			mx = maxf(mx, absf(e))
		# the shoreline: each crossing of the exact ring against the nearest crossing of this one
		var xe: Array = _shore(exact)
		var xs: Array = _shore(base)
		var dsq: float = 0.0
		var dmx: float = 0.0
		var lost: int = 0
		for ci in xe:
			var best: float = 1.0e9
			for cj in xs:
				best = minf(best, absf(float(cj - ci)))
			if best > 40.0:
				lost += 1
			else:
				dsq += best * best * SimConst.COL * SimConst.COL
				dmx = maxf(dmx, best * SimConst.COL)
		res.append([sqrt(sq / float(NC)), mx, xe.size(), lost, sqrt(dsq / maxf(1.0, float(xe.size() - lost))), dmx, r.F.refined, r.F.subReads, r.ms])
	print("  info records off: column RMS %.2f max %.0f, %d exact shore crossings %d lost, displacement RMS %.0f max %.0f, refined %d cells, %d sub-reads, match start %.0f ms" % res[0])
	print("  info records on:  column RMS %.2f max %.0f, %d exact shore crossings %d lost, displacement RMS %.0f max %.0f, refined %d cells, %d sub-reads, match start %.0f ms" % res[1])
	ok(res[1][0] <= res[0][0] + 1.0e-6, "the records do not worsen the column RMS (%.2f against %.2f)" % [res[1][0], res[0][0]])
	ok(res[1][4] <= res[0][4] + 1.0e-6 and res[1][3] <= res[0][3], "the records do not worsen the shoreline (displacement %.0f against %.0f, lost %d against %d)" % [res[1][4], res[0][4], res[1][3], res[0][3]])
	ok(res[1][6] > 0, "the ring met %d creased cells" % res[1][6])
	# the records on, a scan of what has been decided: no cracks along the refined cells' edges, in both directions
	var F: WorldField.Field = on.F
	var N: int = F.N
	var tested: int = 0
	var crack: float = 0.0
	var rng := SimRng.new(5)
	for face in range(6):
		for j in range(1, N - 1):
			for i in range(1, N - 1):
				if F.rf[(face * N + j) * N + i] != 2 or tested > 60:
					continue
				# the four edges' mid-sub-nodes, from this cell's side and from the neighbour's
				var sub: int = F.sub
				var cc: Array = WorldField.dirOf(face, i * sub + sub / 2, j * sub + sub / 2, N * sub)
				var nbs: Array = [[0, -1], [0, 1], [-1, 0], [1, 0]]
				for e in range(4):
					var di: int = nbs[e][0]
					var dj: int = nbs[e][1]
					var k: int = 1 + int(rng.next() * float(sub - 1))
					var pi4: int = i * sub + (k if dj != 0 else (0 if di < 0 else sub))
					var pj4: int = j * sub + (k if di != 0 else (0 if dj < 0 else sub))
					var ep: Array = WorldField.dirOf(face, pi4, pj4, N * sub)
					var nc2: Array = WorldField.dirOf(face, (i + di) * sub + sub / 2, (j + dj) * sub + sub / 2, N * sub)
					var pa: Array = _mix(ep, cc, 0.0005)
					var pb: Array = _mix(ep, nc2, 0.0005)
					WorldField.sample(F, pa[0], pa[1], pa[2])
					var ha: float = F.oh
					WorldField.sample(F, pb[0], pb[1], pb[2])
					crack = maxf(crack, absf(F.oh - ha))
					tested += 1
	ok(tested > 0 and crack < 0.3, "%d edge points of refined cells read from both sides differ by %.4f units at most" % [tested, crack])
	# a sub-node of a refined cell is the planet's function there
	var sn: int = 0
	var worst_sn: float = 0.0
	WorldClimate.useGen(3)
	var P3 := WorldPlanet.make(planet)
	for face in range(6):
		for j in range(1, N - 1):
			for i in range(1, N - 1):
				if F.rf[(face * N + j) * N + i] != 2 or sn >= 20:
					continue
				var d: Array = WorldField.dirOf(face, i * F.sub + 1, j * F.sub + 3, N * F.sub)
				WorldField.sample(F, d[0], d[1], d[2])
				var got: float = F.oh
				WorldField._read(F, d)
				worst_sn = maxf(worst_sn, absf(got - float(PackedFloat32Array([WorldField._vh])[0])))
				sn += 1
	ok(sn > 0 and worst_sn < 0.05, "%d sub-nodes of refined cells read back as the exact ground, %.4f units at most" % [sn, worst_sn])
	# order does not matter: the same directions read forward and backward on two fresh fields
	var dirs: Array = []
	for k in range(300):
		var col: int = int(rng.next() * float(NC))
		dirs.append(col)
	var base_on: PackedFloat32Array = on.S.base
	WorldPlanet.forget()
	WorldField.refineOverride = 1
	WorldClimate.useGen(3)
	var Pa := WorldPlanet.make(planet)
	var Fa := WorldField.of(Pa)
	var ring: Dictionary = on.S.planetRing
	var cir: Dictionary = WorldRingPick.ringFrom(ring.c, int(ring.cols), ring.t)
	var fw: Array = []
	for col in dirs:
		var pnt: Array = WorldPlanet.columnPoint(Pa, cir, col)
		WorldField.sample(Fa, pnt[0], pnt[1], pnt[2])
		fw.append(Fa.oh)
	WorldPlanet.forget()
	var Pb := WorldPlanet.make(planet)
	var Fb := WorldField.of(Pb)
	var rv: Array = []
	for k in range(dirs.size() - 1, -1, -1):
		var pnt: Array = WorldPlanet.columnPoint(Pb, cir, dirs[k])
		WorldField.sample(Fb, pnt[0], pnt[1], pnt[2])
		rv.append(Fb.oh)
	rv.reverse()
	ok(fw == rv, "300 reads give the same ground in either order")
	WorldField.refineOverride = -1
	print("FIELDRECORDS: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
