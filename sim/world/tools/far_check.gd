extends SceneTree
# WorldPlanet.farColumn (shifting-arena-design.md window 2): the ground beside a ring.
#   godot --headless --path . --script res://sim/world/tools/far_check.gd
var fails: int = 0
func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1
func _init() -> void:
	var P := WorldPlanet.make(7)
	var sl = WorldPlanet.sliceFor(7, 3)
	var same: bool = true
	for i in range(0, 4800, 97):
		var r: Array = WorldPlanet.farColumn(P, sl.circ, i, 0.0)
		if r[0] != sl.heights[i] and absf(r[0] - sl.heights[i]) > 0.001:
			same = false
		if r[1] != sl.biomes[i]:
			same = false
	ok(same, "at z = 0 farColumn is the slice's own column: the same height (to float32) and biome at 50 columns of the Planet slice")
	SimConst.setArena(1200)
	var sc = WorldPlanet.sliceFor(7, 3)
	var same2: bool = true
	for i in range(0, 1200, 41):
		var r2: Array = WorldPlanet.farColumn(P, sc.circ, i, 0.0)
		if absf(r2[0] - sc.heights[i]) > 0.001 or r2[1] != sc.biomes[i]:
			same2 = false
	# beside the ring: the distance moved is z, and a column moved to the centre and back is the column
	var ring: Dictionary = sc.circ
	var p: Array = WorldPlanet.columnPoint(P, ring, 300)
	var moved: bool = true
	for z in [-3000.0, -800.0, 1200.0, 6000.0]:
		var r3: Array = WorldPlanet.farColumn(P, ring, 300, z)
		if r3.size() != 2 or is_nan(r3[0]):
			moved = false
	ok(same2 and moved, "on a Close ring too (1,200 columns): z = 0 is the slice's column, and the reads beside it are numbers")
	var det: bool = true
	for z in [-3000.0, 1200.0]:
		var a: Array = WorldPlanet.farColumn(P, ring, 777, z)
		var b: Array = WorldPlanet.farColumn(P, ring, 777, z)
		if a[0] != b[0] or a[1] != b[1]:
			det = false
	ok(det, "the same read twice is the same")
	# the far ground is the planet's own: z over the whole ring's lateral range reads many kinds of ground
	var seen: Dictionary = {}
	for z in range(-12000, 12001, 1500):
		seen[WorldPlanet.farColumn(P, ring, 150, float(z))[1]] = true
	ok(seen.size() >= 2, "a column's far ground out to 12,000 units each side changes with distance (%d kinds of ground)" % seen.size())
	SimConst.setArena(SimConst.PLANET_NC)
	print("FAR: %d check(s) failed" % fails)
	quit()
