extends SceneTree
# Dumps the re-laid city (L1 with D1) and a staged-destruction sequence on one downtown block as JSON for the SVG stills (World's own scratch view).
const OUT: String = "res://lanesview.json"

func snap(S: SimState, ids: Array) -> Array:
	var a: Array = []
	for i in ids:
		var b = S.buildings[i]
		a.append({"i": i, "hp": b.hp / b.maxhp, "alive": b.alive, "fmask": b.fmask, "stage": WorldStructures.stage(b), "curH": WorldStructures.curH(b)})
	return a

func _init() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	var out := {}
	var bl: Array = []
	for b in S.buildings:
		bl.append({"i": b.idx, "x": b.x, "w": b.w, "h": b.h, "z": b.z, "d": b.d, "row": int(b.row), "kind": b.kind, "shape": b.shape, "district": b.district, "floors": b.floors, "landmark": b.landmark, "base": WorldStructures.baseY(S, b), "pop": b.pop})
	out["buildings"] = bl
	out["lanes"] = Array(S.lanes)
	out["settle"] = WorldSettle.data()
	out["W"] = SimConst.W
	# ground samples every 64 units over the whole planet
	var g: Array = []
	var x: float = 0.0
	while x < SimConst.W:
		g.append(WorldTerrain.groundY(S, x))
		x += 64.0
	out["ground"] = g
	# the staged-destruction sequence on the block around the tallest downtown tower
	var peak = null
	for b in S.buildings:
		if b.row == 1.0 and b.kind == "tower" and (peak == null or b.h > peak.h):
			peak = b
	var tall = null   # a typical downtown tower of 12 to 24 floors in row 1, the nearest to the tallest one
	for b in S.buildings:
		if b.row == 1.0 and b.kind == "tower" and b.floors >= 12 and b.floors <= 24:
			if tall == null or absf(SimWrap.sdx(peak.x, b.x)) < absf(SimWrap.sdx(peak.x, tall.x)):
				tall = b
	var cx: float = tall.x
	var ids: Array = []
	for b in S.buildings:
		if absf(SimWrap.sdx(cx, b.x)) < 1500.0:
			ids.append(b.idx)
	out["seqCentre"] = cx
	out["seqIds"] = ids
	var seq: Array = []
	seq.append({"label": "intact", "state": snap(S, ids)})
	var by = S.fighters[0]
	by.tier = 3.0
	var gy: float = WorldStructures.baseY(S, tall)
	# 1: a landing's blast beside the block
	WorldStructures.damageArea(S, cx - 500.0, gy + 60.0, 500.0, 60.0, by)
	seq.append({"label": "one landing", "state": snap(S, ids)})
	# 2: a body through the tower: the floors at mid height punched out
	var oc: Dictionary = WorldBrunt.outcomeDmg(S, tall, gy + tall.h * 0.45, 4000.0)
	WorldBrunt.applyFloors(S, tall, oc, by, 0.0, cx, S.fighters[1], gy + tall.h * 0.45)
	WorldStructures.damageArea(S, cx + 400.0, gy + 60.0, 500.0, 120.0, by)
	seq.append({"label": "a brunt through the tower and a second landing", "state": snap(S, ids)})
	# 3: two more landings
	WorldStructures.damageArea(S, cx, gy + 60.0, 700.0, 200.0, by)
	WorldStructures.damageArea(S, cx - 300.0, gy + 60.0, 700.0, 260.0, by)
	seq.append({"label": "two more landings", "state": snap(S, ids)})
	out["sequence"] = seq
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("LANESVIEW buildings %d, sequence block of %d buildings at x %.0f, tower %.0f units tall (%d floors)" % [bl.size(), ids.size(), cx, tall.h, tall.floors])
	quit(0)
