extends SceneTree
# WorldStructures.blockedAt: the point test for the zip's exit (docs/world/point-clear.md).
var fails: int = 0
const BH: float = 75.0
func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1
func fresh() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	S.out.fx.clear()
	return S
func isolate(S: SimState, b) -> void:
	for q in S.buildings:
		if q != b and absf(SimWrap.sdx(q.x, b.x)) < 1500.0:
			q.alive = false
func pick(S: SimState, kind: String, minFloors: int = 0):
	for b in S.buildings:
		if b.kind == kind and b.alive and WorldStructures.dz(b) <= WorldStructures.Z_REACH and b.floors >= minFloors and absf(WorldTerrain.groundY(S, b.x) - WorldStructures.baseY(S, b)) < 15.0:
			isolate(S, b)
			return b
	return null
func blk(S: SimState, x: float, y: float, m: float = BH) -> bool:
	return WorldStructures.blockedAt(S, x, y, 0.0, m)
func _init() -> void:
	print("== blockedAt ==")
	# the open and the ground
	var S0 := fresh()
	var xo: float = 100000.0
	var g: float = WorldTerrain.groundY(S0, xo)
	ok(not blk(S0, xo, g + 2.0 * BH), "open air 2 bh above the ground is clear")
	ok(blk(S0, xo, g + 0.5 * BH), "half a body height above the ground is blocked (the margin)")
	ok(blk(S0, xo, g - 10.0), "inside the ground is blocked")
	ok(not blk(S0, xo, g + BH * 1.01), "just over 1 bh above the ground is clear")
	# a standing house
	var S1 := fresh()
	var h = pick(S1, "house")
	var gh: float = WorldStructures.baseY(S1, h)
	ok(blk(S1, h.x, gh + h.h * 0.5), "inside a standing house is blocked")
	ok(blk(S1, h.x + h.w * 0.5 + 0.5 * BH, gh + h.h * 0.5), "half a body height off its wall is blocked (the margin)")
	ok(not blk(S1, h.x + h.w * 0.5 + 1.5 * BH, gh + h.h * 0.5), "1.5 bh off its wall is clear")
	ok(not blk(S1, h.x, gh + h.h + 2.0 * BH), "2 bh above its roof is clear")
	# a shell: a house at 20% of its hit points stands at 44% of its height
	var S2 := fresh()
	var h2 = pick(S2, "house")
	var g2: float = WorldStructures.baseY(S2, h2)
	h2.hp = h2.maxhp * 0.2
	var cur: float = WorldStructures.curH(h2)
	ok(WorldStructures.stage(h2) == 3, "a house at 20% hit points is stage 3")
	ok(blk(S2, h2.x, g2 + cur * 0.5), "inside a shell (below its current height) is blocked")
	ok(blk(S2, h2.x, g2 + cur + 0.5 * BH), "within a body height over a shell's top is blocked")
	ok(not blk(S2, h2.x, g2 + h2.h * 0.9), "at the old roof height above a shell (%.0f of %.0f) is clear" % [cur, h2.h])
	# a fallen building: not alive, a rubble heap on the ground
	var S3 := fresh()
	var h3 = pick(S3, "house")
	var g3: float = WorldStructures.baseY(S3, h3)
	WorldStructures.damageBuilding(S3, h3, 1.0e9, S3.fighters[0], "implode", h3.x, 0.0)
	ok(not h3.alive, "the house is gone")
	ok(not blk(S3, h3.x, g3 + h3.h * 0.5), "inside the footprint of a fallen house at its old mid height is clear")
	ok(blk(S3, h3.x, WorldTerrain.groundY(S3, h3.x) + 0.3 * BH), "on its rubble heap (ground) is blocked")
	# a cut floor
	var S4 := fresh()
	var t = pick(S4, "tower", 8)
	var g4: float = WorldStructures.baseY(S4, t)
	var fh: float = WorldBrunt.floorH(t)
	ok(blk(S4, t.x, g4 + fh * 5.5), "inside a whole tower is blocked")
	t.fmask = t.fmask & ~(1 << 5)
	ok(not blk(S4, t.x, g4 + fh * 5.5, 0.4 * fh), "the centre of one cleared floor is open for a margin of 0.4 floor (%.0f of %.0f units)" % [0.4 * fh, fh])
	ok(blk(S4, t.x, g4 + fh * 5.5, BH) == (BH * 2.0 > fh), "and for the full margin it is open only if the floor is 2 bh (floor %.0f, 2 bh %.0f)" % [fh, 2.0 * BH])
	t.fmask = t.fmask & ~(1 << 6)
	ok(not blk(S4, t.x, g4 + fh * 6.0, BH), "the middle of two cleared floors (%.0f units) is open for 1 bh" % (2.0 * fh))
	ok(blk(S4, t.x, g4 + fh * 3.5, 0.4 * fh), "a standing floor below is blocked")
	ok(blk(S4, t.x + t.w * 0.5 - 0.1 * BH, g4 + fh * 6.0, BH), "a point in the cleared floors but against the wall is blocked")
	# the seam: a point and its wrapped twin agree, and the seam itself is open ground
	var S5 := fresh()
	var same: bool = true
	for i in range(400):
		var x: float = float(i) * 311.0
		var y: float = WorldTerrain.groundY(S5, x) + float(i % 9) * 40.0
		if blk(S5, x, y) != blk(S5, x + SimConst.W, y) or blk(S5, x, y) != blk(S5, x - SimConst.W, y):
			same = false
	ok(same, "400 points and their wrapped twins (x +- W) agree")
	ok(not blk(S5, SimConst.W - 5.0, WorldTerrain.groundY(S5, SimConst.W - 5.0) + 2.0 * BH) and not blk(S5, 5.0, WorldTerrain.groundY(S5, 5.0) + 2.0 * BH), "2 bh over the ground either side of the seam is clear")
	# pure: no draw, no change of state
	var S6 := fresh()
	var rng0: int = S6.rng.state_i32()
	var hp0: float = 0.0
	for b in S6.buildings:
		hp0 += b.hp
	for i in range(500):
		blk(S6, float(i) * 97.0, 300.0)
	var hp1: float = 0.0
	for b in S6.buildings:
		hp1 += b.hp
	ok(S6.rng.state_i32() == rng0 and hp0 == hp1 and S6.out.fx.is_empty(), "no draw, no change, no event")
	# the cost of 24 probes: on open ground and in the densest streets
	var Sc := fresh()
	var t_open: int = 0
	var t_city: int = 0
	var n: int = 0
	for rep in range(100):
		for k in range(24):
			var a: float = TAU * float(k) / 24.0
			var xc: float = 38600.0 + float(rep) * 53.0 + cos(a) * 450.0
			var yc: float = WorldTerrain.groundY(Sc, xc) + 700.0 + sin(a) * 450.0
			var u0 := Time.get_ticks_usec()
			blk(Sc, xc, yc)
			t_city += Time.get_ticks_usec() - u0
			var xp: float = 100000.0 + float(rep) * 53.0 + cos(a) * 450.0
			var yp: float = WorldTerrain.groundY(Sc, xp) + 700.0 + sin(a) * 450.0
			var u1 := Time.get_ticks_usec()
			blk(Sc, xp, yp)
			t_open += Time.get_ticks_usec() - u1
			n += 1
	print("  cost: %.1f us a probe in the city, %.1f us over open ground; 24 probes %.0f and %.0f us" % [float(t_city) / n, float(t_open) / n, float(t_city) / n * 24.0, float(t_open) / n * 24.0])
	print("BLOCK: %d check(s) failed" % fails)
	quit()
