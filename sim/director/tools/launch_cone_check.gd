extends SceneTree
## The launch planner's cone (Game Design, docs/design/buildings.md section 10, second ruling): godot --headless --path . --script res://sim/director/tools/launch_cone_check.gd -- [--matches=6] [--ticks=18000] [--cone=on|off]
## Computer against computer on planet 7 (the field world), the data as it is: every launch aimed at a building (its aimB once launched) is
## measured against the blow's line in the ground plane (the launch's direction along x, at the launched body's depth). Game Design's QA
## row: launches aimed more than 20 degrees off the line, 0. --cone=off sets the cone to 0 in memory (today's planner): the negative control.

var args: Dictionary = {}
var fails: int = 0


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
	print(("ok    " if c else "FAIL  ") + what)


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var matches: int = int(args.get("matches", "6"))
	var ticks: int = int(args.get("ticks", "18000"))
	var coneOn: bool = String(args.get("cone", "on")) != "off"
	var wd: Dictionary = DirLaunch.data().knockBack.wall
	if not coneOn:
		wd["wallCone"] = 0.0
	var cone: float = float(wd.get("wallCone", 0.0))
	var launches: int = 0
	var aimed: int = 0
	var wide: int = 0
	var worst: float = 0.0
	var byName: Dictionary = {}
	var hist: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]   # by 10-degree bins
	for m in range(matches):
		var S := SimCore.createSim()
		SimCore.newMatch(S, 31 + m, {"p1": true, "p2": true}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
		var pre: Array = []
		for f in S.fighters:
			pre.append([f.x, f.z])
		for t in range(ticks):
			for k in range(S.fighters.size()):
				pre[k] = [S.fighters[k].x, S.fighters[k].z]
			SimCore.step(S)
			for e in S.out.fx:
				if e.type != "launch":
					continue
				launches += 1
				var k: int = int(e.actor)
				if k < 0 or k >= S.fighters.size():
					continue
				var f = S.fighters[k]
				if int(f.aimB) < 0:
					continue
				aimed += 1
				var b = S.buildings[int(f.aimB)]
				var s: float = SimMathx.jsign(float(e.ux)) if float(e.ux) != 0.0 else SimMathx.jsign(f.vx)
				var x0: float = float(pre[k][0])
				var z0: float = float(pre[k][1])
				var along: float = SimWrap.sdx(x0, b.x) * s - b.w * 0.5
				var off: float = maxf(0.0, absf(float(b.z) - z0) - float(b.d) * 0.5)
				var deg: float = atan2(off, maxf(along, 0.001)) * 180.0 / PI if along > 0.0 else 90.0 + atan2(-along, maxf(off, 0.001)) * 180.0 / PI
				worst = maxf(worst, deg)
				hist[mini(9, int(deg / 10.0))] += 1
				if deg > 20.01:
					wide += 1
				var nm: String = String(e.text) if String(e.text) != "" else "?"
				byName[nm] = int(byName.get(nm, 0)) + 1
			S.out.fx.clear()
			S.out.feed.clear()
			if SimCore.ended(S):
				break
		SimCore.dispose(S)
	print("      cone %s (%.0f degrees): %d matches, %d launches, %d aimed at a building, %d more than 20 degrees off the line (worst %.1f); by 10-degree bins %s" % ["on" if coneOn else "off", cone, matches, launches, aimed, wide, worst, str(hist)])
	if coneOn:
		ok(wide == 0, "Game Design's QA row: launches aimed more than 20 degrees off the blow's line, 0 (%d aimed)" % aimed)
		if aimed == 0:
			print("NOTE  no launch was aimed at a building in this run: the row had nothing to measure (more matches, or the 9 November data)")
	else:
		print("INFO  today's planner (no cone): %d of %d aimed launches more than 20 degrees off the line" % [wide, aimed])
	print("LAUNCH CONE: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
