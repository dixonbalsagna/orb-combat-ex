extends SceneTree
func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var cr := {}
	var sd := {}
	var land := {}
	var n: int = 0
	for sd_ in range(int(a[0]), int(a[1])):
		var S := SimCore.createSim()
		SimCore.newMatch(S, sd_)
		SimGolden.applyArm("default", S.fighters)
		var steps: int = 0
		while S.game.ko == null and steps < 54000:
			SimCore.step(S, null)
			for e in S.out.fx:
				if e.type == "crater":
					var col: int = int(floor(SimWrap.wrap(e.x) / SimConst.COL)) % SimConst.NC
					var k: String = "paved" if (WorldContact._colSurf[col] & 4) != 0 else "dirt"
					cr[k] = cr.get(k, 0) + 1
				elif e.type == "slide_dust":
					var k2: String = "%s" % e.variant
					sd[k2] = sd.get(k2, 0) + 1
				elif e.type == "land":
					var k3: String = "%s" % e.variant
					land[k3] = land.get(k3, 0) + 1
			S.out.fx.clear()
			S.out.feed.clear()
			steps += 1
		n += 1
		SimCore.dispose(S)
	print("MAT matches %d craters %s slide_dust %s land %s" % [n, str(cr), str(sd), str(land)])
	quit(0)
