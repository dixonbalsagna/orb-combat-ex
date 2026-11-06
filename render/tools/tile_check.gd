extends SceneTree
## The tile ground's field holds the ground it says it does: on a gen 3 match, the tiles along the line read the sim's ground to within a
## few units, level 0 is there after the load, and a tile's heights aren't empty. Headless: it needs no picture. Run with --path . --script.
const TOLERANCE: float = 30.0   # the 128 triangles against the sim's own read, which refines creased cells at 32 u: the lift covers this much


func _init() -> void:
	WorldClimate.useGen(3)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": 7, "touch": 3, "planetGen": 3, "intro": false})
	var fd := RenderTileField.new()
	fd.begin(S)
	while not fd.boot(100000):
		pass
	while not fd.boot_near(100000):
		pass
	var fails: int = 0
	var worst: float = 0.0
	var cx: float = float(S.fighters[0].x)
	for k in range(-20, 21):
		var x: float = cx + float(k) * 64.0
		var d: Vector3 = fd.dir_at(x, 0.0, S.frame)
		var gap: float = absf(fd.height_at(d) - fd._sim_ground(d))
		worst = maxf(worst, gap)
		if gap > TOLERANCE:
			fails += 1
	print("%s the tiles read the sim's ground along the line, worst %.1f units over %d columns" % ["ok  " if fails == 0 else "FAIL", worst, 41])
	var f0: int = 0
	for q in range(fd.POOL):
		if fd._keys[q] >= 0 and (fd._hs[q] as PackedFloat32Array).size() != fd.TEX * fd.TEX:
			f0 += 1
	print("%s every stored tile holds its nodes" % ("ok  " if f0 == 0 else "FAIL"))
	print("tile check %s" % ("passed" if fails == 0 and f0 == 0 else "FAILED"))
	quit(0 if fails == 0 and f0 == 0 else 1)
