extends SceneTree
## Read-only probe for the computer's flight strikes (zip.flightStrikes on; playable-build.md section 1, the computer's own): computer
## against computer at one level, and per match the flight strikes as a share of the blows thrown (each link one blow; a flight strike's
## own blow not counted twice), by button and path, the computer's "No energy" refusals (there should be none) and the time in a brawl.
##   godot --headless --path . --script res://sim/director/tools/fs_share_probe.gd -- <matches> <baseSeed> [--level=medium]
##   [--share=0.15] [--max=120]
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 6
	var base: int = int(args[1]) if args.size() > 1 else 1
	var level := "medium"
	var share: float = -1.0
	var maxT := 120.0
	for a in args:
		if a.begins_with("--level="):
			level = a.substr(8)
		if a.begins_with("--share="):
			share = float(a.substr(8))
		if a.begins_with("--max="):
			maxT = float(a.substr(6))
		if a.begins_with("--reserve="):
			DirZip.fsCfg().ai["kiReserve"] = float(a.substr(10))
	DirZip.setFsForce(1)
	load("res://sim/director/ai.gd").set("level", level)
	if share >= 0.0:
		DirAI.lv()["flightShare"] = share
	var fs := 0
	var blows := 0
	var btn := {}
	var path := {}
	var refused := 0
	var brawlT := 0
	var allT := 0
	var ends := {}
	var counters := 0
	var arrivals := 0
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, base + m, {"p1": true, "p2": true}, {"intro": false})
		while S.T < maxT and S.game.ko == null:
			SimCore.step(S, [null, null])
			allT += 1
			var ex = S.dirS.ex
			if DirBrawl.isBrawl(ex) and not DirBrawl.quiet(ex):
				brawlT += 1
			for e in S.out.fx:
				if String(e.type) != "cue":
					continue
				var k: String = String(e.kind)
				if k == "zip_light" or k == "zip_heavy" or k == "zip_big":
					fs += 1
					btn[String(e.source)] = int(btn.get(String(e.source), 0)) + 1
					path[String(e.text)] = int(path.get(String(e.text), 0)) + 1
				elif k == "blow" and String(e.source) != "zip":
					blows += 1
				elif k == "press_refused":
					refused += 1
					print("      refused: %s %s slot %d at %d" % [String(e.text), String(e.source), int(e.actor), S.tick])
				elif k == "zip_end":
					ends[String(e.text)] = int(ends.get(String(e.text), 0)) + 1
			S.out.fx.clear()
			S.out.feed.clear()
		SimCore.dispose(S)
	var total: int = fs + blows
	print("FS SHARE %s" % JSON.stringify({"level": level, "matches": n, "flightShare": float(DirAI.lv().get("flightShare", -1.0)), "flightStrikes": fs, "blows": total, "share": snappedf(float(fs) / maxf(1.0, float(total)), 0.001), "buttons": btn, "paths": path, "noEnergy": refused, "brawlTime": snappedf(float(brawlT) / maxf(1.0, float(allT)), 0.001), "ends": ends}))
	DirZip.setFsForce(-1)
	quit(0)
