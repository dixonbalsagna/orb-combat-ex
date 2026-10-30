extends SceneTree
# Props and water (World, 2026-10-30; Rendering's finding): no prop of WorldGround.matchProps stands where a river or a lake is drawn: in a column with its water, or on the strip of dry land the water shader floods beside it
# (RenderLook.SHORE_FLOOD under the level, within RenderLook.SHORE_COLS columns of the water: GroundField.flooded's rule, read here from the sim's own water).
#   godot --headless --path . --script res://sim/world/tools/props_wet_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func gen2_match(sd: int, touch: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": sd, "touch": touch, "arena": {"cols": 2400}, "planetGen": 2, "intro": false})
	return S


## GroundField.flooded's rule from the sim's water: the column has water, or dry land at most flood under the level of the nearest wet column within cols columns.
func flooded_cols(S: SimState) -> PackedByteArray:
	var nc: int = SimConst.NC
	var k: int = RenderLook.SHORE_COLS
	var out := PackedByteArray()
	out.resize(nc)
	var lvl := PackedFloat64Array()
	lvl.resize(nc)
	var dist := PackedInt32Array()
	dist.resize(nc)
	dist.fill(k + 1)
	lvl.fill(-1.0e9)
	for dir in [1, -1]:
		var lv: float = -1.0e9
		var d: int = k + 1
		for n in range(-k, nc):
			var i: int = posmod(n if dir == 1 else nc - 1 - n, nc)
			if S.water[i] >= WorldWater.MIN_DEPTH:
				lv = S.base[i] + S.deform[i] + S.water[i]
				d = 0
			else:
				d += 1
			if d <= k and n >= 0 and (d < dist[i] or (d == dist[i] and lv > lvl[i])):
				dist[i] = d
				lvl[i] = lv
	for i in range(nc):
		if S.water[i] >= WorldWater.MIN_DEPTH:
			out[i] = 1
		elif lvl[i] > -1.0e8:
			var below: float = lvl[i] - (S.base[i] + S.deform[i])
			if below > 0.0 and below <= RenderLook.SHORE_FLOOD:
				out[i] = 1
	return out


func _init() -> void:
	ok(WorldLakes.SHORE_COLS == RenderLook.SHORE_COLS and WorldLakes.SHORE_FLOOD == RenderLook.SHORE_FLOOD, "World's copies of the flood strip's two numbers (%d columns, %.0f units) are Rendering's" % [WorldLakes.SHORE_COLS, WorldLakes.SHORE_FLOOD])
	WorldGround.K_PROVISIONAL = true
	var total: int = 0
	var inLake: int = 0
	var inStrip: int = 0
	var trees: int = 0
	var control: int = 0
	var seen := ""
	var rings: int = 0
	for sd in [21, 7, 47, 3, 11]:
		for touch in [3, 0]:
			var S: SimState = gen2_match(sd, touch)
			if not S.planetRing.has("seed"):
				continue
			var fl: PackedByteArray = flooded_cols(S)
			var lakes: Array = S.planetRing.get("lakes", [])
			var props: Array = WorldGround.matchProps(S, 0.0, SimConst.W)
			var a: int = 0
			for p in props:
				var c: int = int(p.col)
				if fl[c] == 1 and _near_lake(lakes, c, SimConst.NC):   # a river's or a lake's sheet (the sea's shallows keep their props: they are the sea's)
					a += 1
					if WorldLakes.inLake(lakes, c, SimConst.NC):
						inLake += 1
					else:
						inStrip += 1
					if String(p.kind).find("tree") >= 0:
						trees += 1
			if sd == 21 and touch == 3:   # the control: the same ring laid without its lakes, as before the change, does put props in the water (so the check can fail)
				var raw: Array = WorldGround.propsIn(WorldBiomes.fineCols, WorldBiomes.planetCols, S.base, int(S.planetRing.seed), 0, S.base.size(), S.trees, [])
				for p in raw:
					if fl[int(p.col)] == 1 and _near_lake(lakes, int(p.col), SimConst.NC):
						control += 1
			total += props.size()
			rings += 1
			seen += "%d/%d:%d/%d " % [sd, touch, a, props.size()]
	ok(rings >= 6, "%d gen 2 rings read" % rings)
	ok(inLake == 0 and inStrip == 0, "no prop stands in a lake's or a river's water or on its flood strip: %d in the water, %d on the strip (%d of them trees) of %d props   [per ring: wet/all %s]" % [inLake, inStrip, trees, total, seen])
	ok(control > 0, "control: laid without the lakes, planet 21 puts %d props in the water or on its strip" % control)
	print("PROPSWET: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)


## Is column c within the strip of one of the ring's lakes or rivers (the lake's columns and SHORE_COLS either side)?
func _near_lake(lakes: Array, c: int, n: int) -> bool:
	for lk in lakes:
		var off: int = posmod(c - int(lk[0]), n)
		if off < int(lk[3]) + RenderLook.SHORE_COLS or off >= n - RenderLook.SHORE_COLS:
			return true
	return false
