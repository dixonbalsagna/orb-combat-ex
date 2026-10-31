extends SceneTree
# Planet generation 3's field (World, docs/world/ring-any-angle/research.md T6 stage 3; sim/world/field.gd): that the lattice, the nodes, the bake and the gen 3 ring read are what they say, and that gen 2 does not move.
#   godot --headless --path . --script res://sim/world/tools/field_check.gd -- [--planet=7] [--ticks=300] [--quick]
# Prints a line a check and FIELD_CHECK PASS or FAIL. The cost lines are for the report, not a gate (this machine is shared).
var fails: int = 0
var planet: int = 7


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _init() -> void:
	var ticks: int = 300
	var quick: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a == "--quick":
			quick = true
	ok(WorldField.dataErrors().is_empty(), "field.json loads: %s" % str(WorldField.dataErrors()))
	ok(WorldField.cells() % WorldField.bakeStride() == 0, "cells %d is a multiple of the bake stride %d" % [WorldField.cells(), WorldField.bakeStride()])
	# the planet's gen 3 and its gen 2 twin: the same seed, the same function
	WorldClimate.useGen(2)
	var P2 := WorldPlanet.make(planet)
	WorldClimate.useGen(3)
	var P3 := WorldPlanet.make(planet)
	ok(P3.gen == 3 and P2.gen == 2 and P3 != P2, "a gen 3 planet is its own object")
	ok(P3.n == P2.n, "the same places: %d and %d" % [P2.n, P3.n])
	var same: bool = true
	for i in range(P2.n):
		if P2.px[i] != P3.px[i] or P2.py[i] != P3.py[i] or P2.pz[i] != P3.pz[i] or P2.rad[i] != P3.rad[i]:
			same = false
	ok(same, "the places are where gen 2's are")
	var F := WorldField.of(P3)
	ok(WorldField.of(P3) == F, "the field is memoised by the seed")
	# dir and locate: a round trip, and the faces meet
	var worst: float = 0.0
	var rng := SimRng.new(77)
	var off: int = 0
	var N: int = F.N
	for k in range(400):
		var face: int = int(rng.next() * 6.0)
		var i: int = int(rng.next() * float(N + 1))
		var j: int = int(rng.next() * float(N + 1))
		var d: Array = WorldField.dirOf(face, i, j, N)
		var len2: float = d[0] * d[0] + d[1] * d[1] + d[2] * d[2]
		worst = maxf(worst, absf(len2 - 1.0))
		WorldField._locate(d[0], d[1], d[2], N)
		if WorldField._lf == face:
			worst = maxf(worst, absf(WorldField._la - float(i)) * 1.0e-3)
			worst = maxf(worst, absf(WorldField._lb - float(j)) * 1.0e-3)
		elif i != 0 and i != N and j != 0 and j != N:
			off += 1
	ok(worst < 1.0e-9 and off == 0, "dirOf is unit and locate inverts it (worst %.9f, %d interior nodes landed on another face)" % [worst, off])
	# a node is gen 2's own column value there (the surface plus the detail), bit for bit once stored as float32
	var mism: int = 0
	var checked: int = 0
	WorldClimate.useGen(2)
	for k in range(60):
		var face: int = int(rng.next() * 6.0)
		var i: int = int(rng.next() * float(N + 1))
		var j: int = int(rng.next() * float(N + 1))
		var d: Array = WorldField.dirOf(face, i, j, N)
		WorldPlanet.surfAt(P2, d[0], d[1], d[2])
		var h: float = P2.outH
		var b: int = P2.outB
		var c: Dictionary = P2.c
		if b >= WorldPlanet.BIO_PLAINS and b <= WorldPlanet.BIO_MOUNTAINS:
			h += (WorldPlanet._fbm(P2.R, d[0], d[1], d[2], c.detailScale, int(c.detailOct), P2.seed + int(c.sDetail)) - 0.5) * c.detailAmp
		elif b == WorldPlanet.BIO_ICE_SHEET and h > 100.0:
			h += (WorldPlanet._fbm(P2.R, d[0], d[1], d[2], c.detailScale, int(c.detailOct), P2.seed + int(c.sDetail)) - 0.5) * c.detailAmp * c.detailSheet
		WorldClimate.useGen(3)
		var idx: int = WorldField.ensure(F, face, i, j)
		WorldClimate.useGen(2)
		checked += 1
		if F.h[idx] != float(PackedFloat32Array([h])[0]) or F.b[idx] != b:
			mism += 1
	WorldClimate.useGen(3)
	ok(mism == 0, "%d nodes are gen 2's column value at the node's point (%d differ)" % [checked, mism])
	# the cell's two triangles: exact at a node, linear along the cell's edge, bounded by the corners
	var tri: bool = true
	for k in range(200):
		var face: int = int(rng.next() * 6.0)
		var i: int = 1 + int(rng.next() * float(N - 2))
		var j: int = 1 + int(rng.next() * float(N - 2))
		var d: Array = WorldField.dirOf(face, i, j, N)
		WorldField.sample(F, d[0], d[1], d[2])
		var idx: int = face * F.side * F.side + j * F.side + i
		if absf(F.oh - F.h[idx]) > 0.01:
			tri = false
	ok(tri, "a sample at a node is the node's height")
	# the bake is nested: a bake-stride read at a bake node is the canonical read there
	var nest: bool = true
	var st: int = F.stride
	for k in range(100):
		var face: int = int(rng.next() * 6.0)
		var i: int = int(rng.next() * float(N / st + 1)) * st
		var j: int = int(rng.next() * float(N / st + 1)) * st
		var d: Array = WorldField.dirOf(face, i, j, N)
		WorldField.sample(F, d[0], d[1], d[2], 1)
		var a: float = F.oh
		WorldField.sample(F, d[0], d[1], d[2], st)
		if absf(F.oh - a) > 0.01:
			nest = false
	ok(nest, "the bake and the canonical lattice agree at every bake node")
	# two faces' copies of an edge node
	var edge: float = 0.0
	for k in range(40):
		var face: int = int(rng.next() * 6.0)
		var t: int = int(rng.next() * float(N + 1))
		var d: Array = WorldField.dirOf(face, N, t, N)   # an edge node of this face
		var idx1: int = WorldField.ensure(F, face, N, t)
		WorldField._locate(d[0], d[1], d[2], N)
		var f2: int = WorldField._lf
		if f2 != face:
			var i2: int = int(round(WorldField._la))
			var j2: int = int(round(WorldField._lb))
			var idx2: int = WorldField.ensure(F, f2, i2, j2)
			edge = maxf(edge, absf(F.h[idx1] - F.h[idx2]))
	ok(edge < 0.05, "an edge node read from its two faces differs by %.4f units at most" % edge)
	if quick:
		print("FIELD: %d check(s) failed" % fails)
		quit(0 if fails == 0 else 1)
		return
	# the bake: whole, hashed, the same in any order and after other reads
	var t0: int = Time.get_ticks_usec()
	var done: bool = false
	var calls: int = 0
	while not done:
		done = WorldField.bakeStep(F, 2000)
		calls += 1
	var bake_ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
	var hashA: String = F.bakeHash
	ok(F.bakeDone and hashA != "", "the bake is whole: %d nodes in %d steps, %.0f ms here, hash %s, %d nodes read in all" % [F.bakeN, calls, bake_ms, hashA, F.reads])
	WorldPlanet.forget()
	WorldClimate.useGen(3)
	var Pb := WorldPlanet.make(planet)
	var Fb := WorldField.of(Pb)
	for k in range(Fb.bakeN - 1, -1, -37):   # a scatter in reverse before the bake runs
		var bs: int = Fb.N / Fb.stride + 1
		var face: int = k / (bs * bs)
		var r: int = k - face * bs * bs
		WorldField.ensure(Fb, face, (r % bs) * Fb.stride, (r / bs) * Fb.stride)
	while not WorldField.bakeStep(Fb, 5000):
		pass
	ok(Fb.bakeHash == hashA, "the bake's hash is the same after a scattered read first (%s)" % Fb.bakeHash)
	WorldPlanet.forget()
	var other := WorldPlanet.make(planet + 1)
	var Fo := WorldField.of(other)
	while not WorldField.bakeStep(Fo, 100000):
		pass
	ok(Fo.bakeHash != hashA, "another seed's bake differs")
	# a ring through the field against gen 2's exact ring: what the smoother planet is
	WorldPlanet.forget()
	var res: Array = []
	for gen in [2, 3]:
		var S := SimCore.createSim()
		var t1: int = Time.get_ticks_usec()
		SimCore.newMatch(S, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": gen, "intro": false})
		var ms: float = float(Time.get_ticks_usec() - t1) / 1000.0
		res.append([S, ms])
	var S2: SimState = res[0][0]
	var S3: SimState = res[1][0]
	var NC: int = SimConst.NC
	ok(S3.planetGen == 3 and S2.planetGen == 2 and S3.base.size() == S2.base.size() and S3.base.size() == NC, "a gen 3 match has a gen 3 ground of %d columns" % NC)
	var sq: float = 0.0
	var mx: float = 0.0
	var bm: int = 0
	for i in range(NC):
		var e: float = S3.base[i] - S2.base[i]
		sq += e * e
		mx = maxf(mx, absf(e))
		if WorldBiomes.planetCols.size() == NC and S3.planetCols[i] != S2.planetCols[i]:
			bm += 1
	print("  info the gen 3 ring against gen 2's exact one: RMS %.1f, max %.0f, %d of %d biome columns differ; match start gen 2 %.0f ms, gen 3 %.0f ms (planet and ring cold)" % [sqrt(sq / float(NC)), mx, bm, NC, res[0][1], res[1][1]])
	ok(sqrt(sq / float(NC)) < 12.0, "the field's ring is within 12 units RMS of the exact ring")
	var finite: bool = true
	for i in range(NC):
		if is_nan(S3.base[i]) or absf(S3.base[i]) > 20000.0:
			finite = false
	ok(finite, "every column of the gen 3 ground is finite")
	# trees are keyed by the planet cell: the ring read backwards lays the same trees
	var slc: WorldPlanet.Slice = WorldPlanet.sliceFor(planet, 1, PackedByteArray(), false, 1)
	ok(slc != null and slc.cell.size() == NC, "a gen 3 slice carries a planet cell for each column")
	if slc != null and slc.cell.size() == NC:
		var tseed: int = WorldPlanet.treeSeed(P3, 5)
		ok(tseed != 5 and tseed == WorldPlanet.treeSeed(P3, 99), "a gen 3 planet's tree seed is its own, not the slice's hash")
		var fr := PackedByteArray()
		var br := PackedByteArray()
		var hr := PackedFloat32Array()
		var cr := PackedInt32Array()
		for i in range(NC - 1, -1, -1):
			fr.append(slc.fine[i])
			br.append(slc.biomes[i])
			hr.append(slc.heights[i])
			cr.append(slc.cell[i])
		var ta: Array = WorldGround.layTrees(slc.fine, slc.biomes, slc.heights, tseed, PackedFloat32Array(), slc.cell)
		var tb: Array = WorldGround.layTrees(fr, br, hr, tseed, PackedFloat32Array(), cr)
		var ha: Array = []
		var hb2: Array = []
		for t in ta:
			ha.append(t.h)
		for t in tb:
			hb2.append(t.h)
		ha.sort()
		hb2.sort()
		ok(ta.size() > 0 and ha == hb2, "%d trees by planet cell, the same %d when the ring is read backwards" % [ta.size(), tb.size()])
		var tc: Array = WorldGround.layTrees(slc.fine, slc.biomes, slc.heights, 5)
		var td: Array = WorldGround.layTrees(fr, br, hr, 5)
		var hc: Array = []
		var hd: Array = []
		for t in tc:
			hc.append(t.h)
		for t in td:
			hd.append(t.h)
		hc.sort()
		hd.sort()
		ok(hc != hd, "control: keyed by column index, the backwards ring lays other trees")
	# the same match twice: the same state
	var Sa := SimCore.createSim()
	SimCore.newMatch(Sa, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	var Sb := SimCore.createSim()
	SimCore.newMatch(Sb, 1, {}, {"planet": planet, "touch": 1, "arena": {"cols": 2400}, "planetGen": 3, "intro": false})
	for t in range(ticks):
		SimCore.step(Sa)
		SimCore.step(Sb)
	var ha: String = str(SimHash.stateHash(Sa).gameplay)
	var hb: String = str(SimHash.stateHash(Sb).gameplay)
	ok(ha == hb, "a gen 3 match played %d ticks twice has one state (%s)" % [ticks, ha])
	ok(Sa.buildings.size() > 0 and Sa.world != null, "a gen 3 match stands %d buildings and %d trees" % [Sa.buildings.size(), Sa.trees.size()])
	print("FIELD: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
