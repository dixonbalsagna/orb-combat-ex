extends SceneTree
# WorldLanes.intersections, streets, limits: the grid's crossings are clear air from the ground to the sky
var fails: int = 0
func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1
func _init() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var lim: Array = WorldLanes.limits()
	var st: Array = WorldLanes.streets()
	ok(lim[0] > lim[1], "the band runs from z_front %.0f to z_back %.0f units (%.0f fighter heights deep)" % [lim[0], lim[1], (lim[0] - lim[1]) / 75.0])
	ok(st.size() >= 2, "the table has %d streets along the planet" % st.size())
	# the downtown centre: the district named downtown in S.lanes
	var t: PackedFloat32Array = S.lanes
	var nd: int = int(t[3])
	var oD: int = int(t[12])
	var cx: float = 0.0
	for i in range(nd):
		if int(t[oD + 6 * i + 2]) == 5:   # look index 5: downtown
			cx = (t[oD + 6 * i] + t[oD + 6 * i + 1]) * 0.5
	var us := Time.get_ticks_usec()
	var ix: Array = WorldLanes.intersections(S, cx, 3000.0)
	var cost: int = Time.get_ticks_usec() - us
	print("  intersections within 3,000 units of downtown's centre: %d (%d streets x avenues), nearest at %.0f units; %d us" % [ix.size(), st.size(), ix[0][4] if ix.size() > 0 else -1.0, cost])
	ok(ix.size() >= st.size() * 2, "at least two avenues cross each street near downtown's centre (%d crossings)" % ix.size())
	var bad: int = 0
	for c in ix:
		for b in S.buildings:
			if absf(SimWrap.sdx(c[0], b.x)) < c[2] + b.w * 0.5 - 0.5 and absf(c[1] - b.z) < c[3] + b.d * 0.5 - 0.5:
				bad += 1
	ok(bad == 0, "no building footprint stands in any of those intersections (%d overlaps)" % bad)
	# clear for a body: clearLane at an intersection's centre returns its own depth
	var same: int = 0
	for c in ix:
		if absf(WorldLanes.clearLane(S, c[0], c[1]) - c[1]) < 1.0:
			same += 1
	ok(same == ix.size(), "clearLane at the centre of each intersection is its own depth (%d of %d)" % [same, ix.size()])
	# avenueAt: the centre of each crossing is in an avenue; no building stands in the avenue at any depth of the band
	var inav: int = 0
	for c in ix:
		if WorldLanes.avenueAt(S, c[0]) >= 0:
			inav += 1
	ok(inav == ix.size(), "avenueAt finds the avenue at the centre of each crossing (%d of %d)" % [inav, ix.size()])
	var stray: int = 0
	for c in ix:
		var rx: float = WorldLanes.body()[0]
		if WorldLanes.avenueAt(S, c[0] + c[2] - rx - 1.0, rx) < 0 or WorldLanes.avenueAt(S, c[0] + c[2] + 1.0, 0.0) == WorldLanes.avenueAt(S, c[0], 0.0):
			stray += 1
	ok(stray == 0, "avenueAt's inset keeps a body of the half width inside the avenue (%d strays)" % stray)
	# every avenue of the planet is clear of the block rows 1 and 2 (the fight's band) at every depth: clear air from the street to the street
	var nav: int = int(t[4])
	var oA: int = oD + 6 * nd
	var inside: int = 0
	for i in range(nav):
		var a0: float = t[oA + 3 * i]
		var a1: float = t[oA + 3 * i + 1]
		for b in S.buildings:
			if (b.row == 1.0 or b.row == 2.0) and absf(SimWrap.sdx((a0 + a1) * 0.5, b.x)) < (a1 - a0) * 0.5 + b.w * 0.5 - 0.5:
				inside += 1
	ok(inside == 0, "%d avenues across the planet hold no block-row footprint (%d overlaps)" % [nav, inside])
	print("ISECT: %d check(s) failed" % fails)
	quit()
