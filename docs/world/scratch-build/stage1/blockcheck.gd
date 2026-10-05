extends SceneTree
func _init() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var city: float = 38600.0
	var open: float = 100000.0
	var BH: float = 75.0
	var n: int = 0
	var blocked_city: int = 0
	var blocked_open: int = 0
	var t0 := Time.get_ticks_usec()
	for rep in range(200):
		for k in range(24):
			var a: float = TAU * float(k) / 24.0
			var x: float = city + cos(a) * 900.0 + float(rep) * 37.0
			var y: float = WorldTerrain.groundY(S, x) + 300.0 + sin(a) * 900.0
			if WorldStructures.blockedAt(S, x, y, 0.0, BH):
				blocked_city += 1
			n += 1
	var us_city: float = float(Time.get_ticks_usec() - t0) / float(n)
	t0 = Time.get_ticks_usec()
	for rep in range(200):
		for k in range(24):
			var a: float = TAU * float(k) / 24.0
			var x: float = open + cos(a) * 900.0 + float(rep) * 37.0
			var y: float = WorldTerrain.groundY(S, x) + 300.0 + sin(a) * 900.0
			if WorldStructures.blockedAt(S, x, y, 0.0, BH):
				blocked_open += 1
	var us_open: float = float(Time.get_ticks_usec() - t0) / float(n)
	print("probes %d: city %.1f us each (%d blocked), open ground %.1f us each (%d blocked); 24 probes %.0f us city" % [n, us_city, blocked_city, us_open, blocked_open, us_city * 24.0])
	# a point inside a house, inside a cleared tower floor, above its roof, below ground, across the seam
	var h = null
	var t = null
	for b in S.buildings:
		if b.kind == "house" and b.alive and WorldStructures.dz(b) <= WorldStructures.Z_REACH and h == null:
			h = b
		if b.kind == "tower" and b.alive and WorldStructures.dz(b) <= WorldStructures.Z_REACH and t == null:
			t = b
	var gh: float = WorldStructures.baseY(S, h)
	print("  inside a house: ", WorldStructures.blockedAt(S, h.x, gh + h.h * 0.5, 0.0, BH), "; 2 bh above its roof: ", WorldStructures.blockedAt(S, h.x, gh + h.h + 2.0 * BH, 0.0, BH), "; 1 bh off its wall at mid height: ", WorldStructures.blockedAt(S, h.x + h.w * 0.5 + BH * 1.2, gh + h.h * 0.5, 0.0, BH))
	var gt: float = WorldStructures.baseY(S, t)
	var fh: float = WorldBrunt.floorH(t)
	print("  tower floor 5 before: ", WorldStructures.blockedAt(S, t.x, gt + fh * 5.5, 0.0, BH))
	t.fmask = t.fmask & ~(1 << 5)
	print("  tower floor 5 cleared: ", WorldStructures.blockedAt(S, t.x, gt + fh * 5.5, 0.0, BH), " (a floor is %.0f units; a margin of %.0f leaves %.0f clear)" % [fh, BH, fh - 2.0 * BH])
	h.hp = h.maxhp * 0.2
	print("  a shell (20%% hp): inside ", WorldStructures.blockedAt(S, h.x, WorldStructures.baseY(S, h) + h.h * 0.2, 0.0, BH), ", at the old roof height ", WorldStructures.blockedAt(S, h.x, WorldStructures.baseY(S, h) + h.h * 0.9, 0.0, BH))
	var g: float = WorldTerrain.groundY(S, 5.0)
	print("  below ground ", WorldStructures.blockedAt(S, 5.0, g - 10.0, 0.0, BH), ", 1 bh above ", WorldStructures.blockedAt(S, 5.0, g + BH * 1.01, 0.0, BH), ", across the seam at W-5 ", WorldStructures.blockedAt(S, SimConst.W - 5.0, WorldTerrain.groundY(S, SimConst.W - 5.0) + BH * 2.0, 0.0, BH))
	quit()
