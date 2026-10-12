extends SceneTree
func _init() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var fl: Array = []
	var hp: Array = []
	var houses: int = 0
	var hhp: Array = []
	var byRow := {}
	for b in S.buildings:
		if b.floors >= WorldBrunt.FLOORS_MIN:
			fl.append(b.floors)
			hp.append(b.maxhp)
		else:
			houses += 1
			hhp.append(b.maxhp)
		byRow[int(b.row)] = byRow.get(int(b.row), 0) + 1
	fl.sort()
	hp.sort()
	hhp.sort()
	var mid: int = fl.size() / 2
	print("TW buildings %d: towers of 5 floors or more %d (floors median %d, max %d; hit points min %.0f median %.0f max %.0f); below 5 floors %d (hit points median %.0f max %.0f); by row %s" % [S.buildings.size(), fl.size(), fl[mid], fl[-1], hp[0], hp[mid], hp[-1], houses, hhp[hhp.size() / 2], hhp[-1], str(byRow)])
	# a typical tower: the median one in row 1: its floors' strengths, top and bottom, and a tier-1 .. 4 brunt at 1500 speed
	var t = null
	for b in S.buildings:
		if b.floors >= WorldBrunt.FLOORS_MIN and int(b.row) == 1 and b.floors == fl[mid]:
			t = b
			break
	if t != null:
		var ss: Array = []
		for k in [0, t.floors / 2, t.floors - 2]:
			ss.append("%.0f" % (WorldBrunt.floorStr(t, k) + WorldBrunt.floorStr(t, k + 1)))
		print("TW a median tower: %d floors, %.0f hit points; the strength of the two floors a body covers, at the ground, the middle, the top: %s" % [t.floors, t.maxhp, ", ".join(ss)])
	quit()
