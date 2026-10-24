extends SceneTree
# Game Design's ruling 12 at runtime (window 8, data/biomes/skate.json, off by default): control returns at the stop on reference ground, the body skating on after the get-up begins.
#   godot --headless --path . --script res://sim/world/tools/skate_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func world(fine: int) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	if fine >= 0:
		var nc: int = SimConst.NC
		S.base.fill(120.0)
		S.deform.fill(0.0)
		S.rubble.fill(0.0)
		S.buildings.clear()
		S.trees.clear()
		WorldWater.init(S)
		var pc := PackedByteArray()
		pc.resize(nc)
		pc.fill(1)
		var fc := PackedByteArray()
		fc.resize(nc)
		fc.fill(fine)
		WorldBiomes.planetCols = pc
		WorldBiomes.fineCols = fc
		WorldBiomes.worldId = WorldBiomes.claim()
		S.worldId = WorldBiomes.worldId
	return S


## A launch (as probe.gd makes them) played to the end of the skate; returns the tick control returned (the get-up began), the tick the body stopped, the distance and the state hash.
func play(S: SimState) -> Dictionary:
	var f = S.fighters[0]
	f.hp = 1.0e9
	f.launchBy = S.fighters[1]
	f.launchT = 1.0
	var x0: float = (2400.0 if S.fighters[0].x < 100000.0 else 30000.0) * SimConst.COL
	if WorldBiomes.fineCols.size() == 0:
		x0 = 30000.0
	f.x = x0
	f.y = WorldTerrain.groundY(S, x0) + 400.0
	f.vx = 3000.0
	f.vy = -800.0
	f.state = "launched"
	var hand: int = -1
	var stop: int = -1
	var t: int = 0
	var travelled: float = 0.0
	var px: float = f.x
	while t < 1500:
		if f.state == "launched":
			SimFighter.stepLaunched(S, f, SimConst.DT)
		elif f.skateV > 0.0:
			if hand < 0:
				hand = t
			WorldContact.stepSkate(S, f, SimConst.DT)
		else:
			break
		if hand < 0 and f.state != "launched":
			hand = t
		travelled += absf(SimWrap.sdx(px, f.x))
		px = f.x
		t += 1
	return {"hand": hand, "stop": t, "dist": travelled, "state": f.state, "skate": f.skateV, "hash": str(SimHash.stateHash(S).gameplay), "ctrlT": f.ctrlT}


func with_switch(on: bool, fine: int) -> Dictionary:
	WorldContact.skateOn()   # load the data before the switch is thrown
	WorldContact.K_SKATE = on
	var S: SimState = world(fine)
	var r: Dictionary = play(S)
	WorldContact.K_SKATE = false
	return r


func _init() -> void:
	WorldContact.skateOn()
	ok(not WorldContact.K_SKATE, "the switch (data/biomes/skate.json enabled) is off in the data")
	var res: Dictionary = {}
	for k in [1, 5, 6, 11, 7]:
		res[k] = [with_switch(false, k), with_switch(true, k)]
	var IO: Dictionary = res[5][0]
	var IN: Dictionary = res[5][1]
	# the lookahead's control tick for the same launch
	var Sx: SimState = world(5)
	var jc: Dictionary = WorldContact.journeyControl(Sx, WorldContact.launchBody(2400.0 * SimConst.COL, WorldTerrain.groundY(Sx, 2400.0 * SimConst.COL) + 400.0, 3000.0, -800.0, 1.0, 2.0))
	print("  (ice sheet, a fast skid: off: control at tick %d, stopped %d, %.0f units; on: control at tick %d, stopped %d, %.0f units; the lookahead says control at %d of %d)" % [IO.hand, IO.stop, IO.dist, IN.hand, IN.stop, IN.dist, jc.ctrl, jc.ticks])
	ok(IO.hand == IO.stop - 1 or IO.hand >= IO.stop - 2, "off: control (the get-up) begins only when the body stops, as before (tick %d of %d)" % [IO.hand, IO.stop])
	ok(IN.hand > 0 and IN.hand < IO.hand - 20 and absf(float(IN.hand) - float(jc.ctrl)) <= 2.0, "on: on ice the get-up begins at the reference stop (tick %d, the lookahead's %d; off it began at %d)" % [IN.hand, jc.ctrl, IO.hand])
	ok(IN.stop <= IO.stop + 3 and IN.stop > IN.hand + 10 and absf(IN.dist - IO.dist) / IO.dist < 0.06, "on: the body still slides the same distance (%.0f against %.0f units, %.1f%%) and stops no later (tick %d against %d; the skate has no tumble's last ticks): a skate after control" % [IN.dist, IO.dist, 100.0 * absf(IN.dist - IO.dist) / IO.dist, IN.stop, IO.stop])
	var s6: Dictionary = res[6][1]
	var o6: Dictionary = res[6][0]
	ok(s6.hand < o6.hand - 20 and absf(s6.dist - o6.dist) / o6.dist < 0.06, "sea ice the same (control at tick %d against %d, %.0f against %.0f units)" % [s6.hand, o6.hand, s6.dist, o6.dist])
	var same: bool = true
	for k in [1, 11, 7]:
		var o: Dictionary = res[k][0]
		var n: Dictionary = res[k][1]
		if o.hand != n.hand or o.stop != n.stop or absf(o.dist - n.dist) > 1.0e-6 or o.hash != n.hash:
			same = false
	ok(same, "on plains, wetland and jungle (they stop at or before the reference stop) the switch changes nothing: the same ticks, distance and state hash")
	ok(IN.state == "down" and float(IN.skate) == 0.0 and int(IN.ctrlT) == -1, "at the end the fighter is down with no skate left and the control tick cleared")
	# a gen 1 hand-made world: the switch changes nothing
	var o1: Dictionary = with_switch(false, -1)
	var n1: Dictionary = with_switch(true, -1)
	ok(o1.hash == n1.hash and o1.stop == n1.stop, "on the hand-made world the switch changes nothing (hash %s)" % str(o1.hash).substr(0, 8))
	# the hash is as it was while nothing is carried
	var S0: SimState = world(5)
	var h0: String = str(SimHash.stateHash(S0).gameplay)
	S0.fighters[0].ctrlT = 77
	var h1: String = str(SimHash.stateHash(S0).gameplay)
	S0.fighters[0].ctrlT = -1
	S0.fighters[0].skateV = 5.0
	var h2: String = str(SimHash.stateHash(S0).gameplay)
	S0.fighters[0].skateV = 0.0
	ok(h0 != h1 and h0 != h2 and h0 == str(SimHash.stateHash(S0).gameplay), "the state hash carries a control tick or a skate only while one is set")
	print("SKATE: %d check(s) failed" % fails)
	quit()
