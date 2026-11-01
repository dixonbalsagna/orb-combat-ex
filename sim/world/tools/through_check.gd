extends SceneTree
# WorldBrunt.through (World, sim/world/brunt.gd; docs/world/building-pass-through.md): a body on a curve goes through a building and stays on it. The building takes the ladder's damage capped at the cap share of its
# hit points, is marked, and the event and the splash happen; the body's velocity and place, the chain, the lodge, the hit stop and his hit points are not touched.
#   godot --headless --path . --script res://sim/world/tools/through_check.gd
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _init() -> void:
	WorldClimate.useGen(1)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 3, {"p1": false, "p2": false}, {"intro": false})
	var bi: int = -1
	for i in range(S.buildings.size()):
		if S.buildings[i].alive and S.buildings[i].h > 600.0 and (bi < 0 or S.buildings[i].maxhp > S.buildings[bi].maxhp):
			bi = i
	ok(bi >= 0, "a tall building to go through (%d)" % bi)
	var b = S.buildings[bi]
	var f = S.fighters[0]
	f.state = "launched"
	f.launchT = 1.0
	f.launchBy = S.fighters[1]
	f.x = b.x - b.w * 0.5 - 10.0
	f.vx = 1500.0
	f.vy = -5000.0
	f.y = 800.0
	var hp0: float = b.hp
	var marks0: int = b.marks
	var vx0: float = f.vx
	var vy0: float = f.vy
	var x0: float = f.x
	var fhp0: float = f.hp
	var stop0: float = S.dirS.stop
	var hits0: int = f.flightHits
	WorldBrunt.through(S, f, b, 600.0, b.x - b.w * 0.5, 1.0, 0.6)
	ok(f.vx == vx0 and f.vy == vy0 and f.x == x0, "his velocity and place are untouched")
	ok(f.hp == fhp0 and S.dirS.stop == stop0, "no wear and no hit stop")
	ok(f.state == "launched", "he is still in flight")
	ok(b.marks == marks0 + 1 or int(WorldBrunt.cfg().repeatMarks) == 0, "the building is marked")
	ok(f.flightHits == hits0 + 1, "the flight counts the hit")
	ok(b.hp < hp0 or not b.alive, "the building took damage (%d to %d of %d)" % [int(hp0), int(b.hp), int(b.maxhp)])
	ok(b.hp >= hp0 - 0.6 * b.maxhp - 1.0e-6 or not b.alive, "the damage is capped at the share of its hit points (at most %d)" % int(0.6 * b.maxhp))
	var ev: int = 0
	for e in S.out.fx:
		if String(e.type).find("building") >= 0:
			ev += 1
	ok(ev >= 1, "the building's hit event went out (%d fx events)" % S.out.fx.size())
	WorldBrunt.through(S, f, b, 600.0, b.x - b.w * 0.5, 1.0, 0.6)
	ok(f.vx == vx0 and f.vy == vy0, "a second building changes nothing of him either")
	print("THROUGH: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
