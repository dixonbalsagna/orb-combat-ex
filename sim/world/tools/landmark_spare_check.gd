extends SceneTree
# A landmark barred by c09 (WorldSettle.noTarget: today the hill chapel; a school, hospital or place of worship if one is ever added) is out of every blast and fall (Legal RL-242; World, docs/world/landmark-spare.md): the meteor's
# blast (DirArc._blast), area damage (WorldStructures.damageArea: a beam, a power-up, a blast), the splash of a brunt and the crater's block fall (WorldStructures.levelIn) leave it standing with its hp, and take every other
# building in reach as they did. Nothing visible: it is a data fact on the landmark.
#   godot --headless --path . --script res://sim/world/tools/landmark_spare_check.gd -- [--planet=7] [--touch=1]
var fails: int = 0


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		fails += 1
		print("  FAIL ", what)


func _match(planet: int, touch: int) -> SimState:
	WorldClimate.useGen(3)
	WorldPlanet.forget()
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false, "planet": planet, "touch": touch, "planetGen": 3})
	for i in range(30):
		SimCore.step(S)
	return S


## A cluster: the first standing building with at least three others within 600 units; returns [x, z, spared index, [others]] with one of its neighbours marked as the barred landmark.
func _setup(S: SimState, barred: int) -> Array:
	for i in range(mini(S.buildings.size(), S.bFirst if S.bFirst > 0 else S.buildings.size())):
		var a = S.buildings[i]
		if not a.alive:
			continue
		var ids: Array = []
		for j in WorldStructures.near(S, a.x, 600.0):
			var b = S.buildings[j]
			if b.alive and int(j) != i and SimDetMath.hypot(SimWrap.sdx(a.x, b.x), float(b.z) - float(a.z)) <= 500.0:
				ids.append(int(j))
		if ids.size() >= 3:
			var spared: int = ids[0]
			S.buildings[spared].landmark = barred
			return [float(a.x), float(a.z), spared, ids.slice(1)]
	return []


func _init() -> void:
	var planet: int = 7
	var touch: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	var barred: int = 0
	var lm: Array = WorldSettle.data().get("landmarks", [])
	for k in range(lm.size()):
		if WorldSettle.noTarget(k + 1):
			barred = k + 1
			break
	ok(barred > 0, "a landmark is barred in the data (noTarget %d)" % barred)
	# the meteor's blast
	var S := _match(planet, touch)
	var cl: Array = _setup(S, barred)
	ok(not cl.is_empty(), "a cluster of buildings to blast, one of them marked barred")
	var sp = S.buildings[cl[2]]
	var hp0: float = sp.hp
	DirArc._blast(S, cl[0], cl[1], 600.0, null, {"blastKeep": 0.2})
	var others_gone: int = 0
	for j in cl[3]:
		if not S.buildings[j].alive:
			others_gone += 1
	ok(sp.alive and sp.hp == hp0, "the meteor's blast leaves the barred landmark standing with its hp (%.0f of %.0f)" % [sp.hp, hp0])
	ok(others_gone >= 1, "and takes the others in reach (%d of %d fall)" % [others_gone, cl[3].size()])
	# area damage
	var S2 := _match(planet, touch)
	var cl2: Array = _setup(S2, barred)
	var sp2 = S2.buildings[cl2[2]]
	var hp2: float = sp2.hp
	var hp2o: Array = []
	for j in cl2[3]:
		hp2o.append(float(S2.buildings[j].hp))
	WorldStructures.damageArea(S2, cl2[0], 100.0, 600.0, 1.0e6, S2.fighters[0])
	var gone2: int = 0
	for j in cl2[3]:
		if not S2.buildings[j].alive or S2.buildings[j].hp < float(hp2o[cl2[3].find(j)]):
			gone2 += 1
	ok(sp2.alive and sp2.hp == hp2, "area damage (a beam, a power-up) leaves it standing (%.0f of %.0f)" % [sp2.hp, hp2])
	ok(gone2 >= 1, "and hurts the others (%d of %d lose hp or fall)" % [gone2, cl2[3].size()])
	# the crater's block fall
	var S3 := _match(planet, touch)
	var cl3: Array = _setup(S3, barred)
	var sp3 = S3.buildings[cl3[2]]
	var hp3: float = sp3.hp
	# levelIn comes with crater-collapse (docs/world/pending/crater-collapse); until it lands, this part is skipped
	var ws: Script = load("res://sim/world/structures.gd")
	if ws.get_script_method_list().any(func(m): return m.name == "levelIn"):
		ws.call("levelIn", S3, cl3[0], cl3[1], 600.0, S3.fighters[0], 99, 0.2)
		ok(sp3.alive and sp3.hp == hp3, "the crater's block fall leaves it standing (%.0f of %.0f)" % [sp3.hp, hp3])
	# a brunt's splash
	var S4 := _match(planet, touch)
	var cl4: Array = _setup(S4, barred)
	var sp4 = S4.buildings[cl4[2]]
	var hp4: float = sp4.hp
	var hit_b = S4.buildings[cl4[3][0]]
	var f = S4.fighters[0]
	f.splashed.clear()
	WorldBrunt._splash(S4, f, hit_b, 1.0e6, f, 0.0, f.x, hit_b.x, 1.0, false)
	ok(sp4.alive and sp4.hp == hp4, "the splash of a brunt on its neighbours leaves it standing (%.0f of %.0f)" % [sp4.hp, hp4])
	# a body that meets it (RL-243): no hit, no damage, no event, his flight unchanged
	var S6 := _match(planet, touch)
	var cl6: Array = _setup(S6, barred)
	var sp6 = S6.buildings[cl6[2]]
	var hp6: float = sp6.hp
	var f6 = S6.fighters[0]
	f6.vx = 3000.0
	f6.vy = 100.0
	f6.launchT = 1.0
	var fx0: int = S6.out.fx.size()
	var vx0: float = f6.vx
	var vy0: float = f6.vy
	WorldBrunt.hit(S6, f6, sp6, WorldStructures.baseY(S6, sp6) + 40.0, sp6.x, 1.0)
	WorldBrunt.through(S6, f6, sp6, WorldStructures.baseY(S6, sp6) + 40.0, sp6.x, 1.0, 1.0)
	ok(sp6.alive and sp6.hp == hp6 and S6.out.fx.size() == fx0 and f6.vx == vx0 and f6.vy == vy0, "a body meeting it (a hit, the meteor passing) changes nothing: its hp, the events and his velocity are as they were")
	# the flight itself, through the swept path (depth on): the same body flown through the same building barred and not: unbarred it is struck and slowed, barred it is not touched and flies on at its speed
	for mark in [barred, 0]:
		var S7 := _match(planet, touch)
		var cl7: Array = _setup(S7, mark)
		var bb = S7.buildings[cl7[2]]
		var g7: float = WorldStructures.baseY(S7, bb) + 0.5 * minf(bb.h, 300.0)
		var f7 = S7.fighters[0]
		f7.launchBy = S7.fighters[1]
		f7.launchT = 1.0
		f7.flightHits = 0
		f7.aimB = cl7[2]   # aimed at it (a barred one is never aimed at by the planner; this is a chain or a test), the swept path (depth on) meets it unaimed too
		f7.state = "launched"
		f7.z = bb.z
		f7.y = g7
		f7.vy = 0.0
		f7.vx = 2400.0
		f7.x = SimWrap.wrap(bb.x - bb.w * 0.5 - 200.0)
		var hits: int = 0
		var fx7: int = S7.out.fx.size()
		for t in range(60):
			var ox: float = f7.x
			var oy: float = f7.y
			f7.x = SimWrap.wrap(f7.x + f7.vx * SimConst.DT)
			if WorldBrunt.checkHit(S7, f7, ox, oy):
				hits += 1
		if mark == barred:
			ok(hits == 0 and S7.out.fx.size() == fx7 and bb.alive and f7.vx == 2400.0, "flown through a barred landmark the body is not struck and keeps its speed (%d hits, vx %.0f)" % [hits, f7.vx])
		else:
			ok(hits >= 1 or not bb.alive, "control: the same flight through the building when it is not barred strikes it (%d hits; depth on: %s)" % [hits, str(S7.depthOn)])
	# control: the same blast on an unmarked cluster takes the building
	var S5 := _match(planet, touch)
	var cl5: Array = _setup(S5, 0)
	var u = S5.buildings[cl5[2]]
	DirArc._blast(S5, cl5[0], cl5[1], 600.0, null, {"blastKeep": 0.2})
	ok(not u.alive, "control: the same blast takes the building when it is not barred")
	print("LANDMARKSPARE: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
