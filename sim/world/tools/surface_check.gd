extends SceneTree
# The surfacing rule (Game Design rulings 2026-10-23b item 7; data/biomes/water.json surface; sim/world/contact.gd): a launched body that goes into water surfaces set within 30 ticks, with no down state beyond.
#   godot --headless --path . --script res://sim/world/tools/surface_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func fresh() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"intro": false})
	S.out.fx.clear()
	return S


func seaX(S: SimState) -> float:
	for i in range(0, SimConst.NC, 7):
		var x: float = (float(i) + 0.5) * SimConst.COL
		if WorldTerrain.seaAt(S, x) and WorldTerrain.seaAt(S, x - 400.0) and WorldTerrain.seaAt(S, x + 400.0) and S.base[i] < -400.0:
			return x
	return -1.0


## A launch into the sea from y 400 at (vx, vy): the tick he is first wet, the tick his flight ends (state free), where, and the state he is in.
func dive(vx: float, vy: float) -> Dictionary:
	var S := fresh()
	var f = S.fighters[0]
	f.x = seaX(S)
	f.y = 400.0
	f.vx = vx
	f.vy = vy
	f.state = "launched"
	f.launchBy = S.fighters[1]
	f.launchT = 1.0
	f.stateT = 0.0
	f.jContacts = 0
	var wetTick: int = -1
	var endTick: int = -1
	var maxWetT: int = 0
	var down: bool = false
	for t in range(240):
		SimFighter.stepLaunched(S, f, SimConst.DT)
		S.tick += 1
		if f.wet and wetTick < 0:
			wetTick = t
		maxWetT = maxi(maxWetT, f.wetT)
		if f.state == "down":
			down = true
		if f.state != "launched":
			endTick = t
			break
	return {"wet": wetTick, "end": endTick, "y": f.y, "state": f.state, "down": down, "maxWetT": maxWetT, "wetT": f.wetT, "S": S}


func _init() -> void:
	ok(WorldFill.dataErrors().is_empty(), "water.json is clean (%s)" % str(WorldFill.dataErrors()))
	ok(not WorldFill.surfaceOn() and WorldFill.surfaceTicks() == 30, "the surfacing rule ships off, at 30 ticks")
	var S0 := fresh()
	ok(seaX(S0) > 0.0 and S0.contactOn, "the hand-made world has deep sea, and ground contact is on")
	# off: today's rule (the body's flight ends where it has slowed under the sea)
	var offs: Array = []
	for v in [[300.0, -1500.0], [200.0, -3000.0], [600.0, -6000.0]]:
		offs.append(dive(v[0], v[1]))
	WorldFill.setSurface(true)
	var onAll: bool = true
	var line: String = ""
	var deepest: int = 0
	for v in [[300.0, -1500.0], [200.0, -3000.0], [600.0, -6000.0], [0.0, -800.0], [1500.0, -1200.0]]:
		var d: Dictionary = dive(v[0], v[1])
		if d.wet < 0 or d.end < 0 or d.end - d.wet > 30 or d.state != "free" or d.down or absf(d.y) > 1.0e-9 or d.wetT != 0:
			onAll = false
		line += " %d" % (d.end - d.wet)
		deepest = maxi(deepest, d.maxWetT)
	ok(onAll, "with the rule on, five launches into the sea (slow, steep, fast and glancing) each surface set on the surface within 30 ticks of going under (ticks under:%s), never down" % line)
	ok(deepest <= 30, "the count of ticks under never passes 30 (%d)" % deepest)
	# the rule is a change: the same launches with it off end elsewhere or later
	var changed: int = 0
	for k in range(offs.size()):
		var on: Dictionary = dive([300.0, 200.0, 600.0][k], [-1500.0, -3000.0, -6000.0][k])
		if offs[k].end != on.end or absf(offs[k].y - on.y) > 1.0 or offs[k].down:
			changed += 1
	ok(changed >= 1, "with the rule off, %d of 3 of those launches end at another tick or depth, or down (the old sink rule)" % changed)
	# determinism, and what the state hash sees
	var a: Dictionary = dive(300.0, -3000.0)
	var b: Dictionary = dive(300.0, -3000.0)
	ok(a.end == b.end and str(SimHash.stateHash(a.S).gameplay) == str(SimHash.stateHash(b.S).gameplay), "a dive is the same twice")
	var Sa := fresh()
	WorldFill.setSurface(false)
	var h0: String = str(SimHash.stateHash(Sa).gameplay)
	WorldFill.setSurface(true)
	ok(h0 == str(SimHash.stateHash(Sa).gameplay), "a dry state hashes the same with the rule on or off (wetT is hashed only while not 0)")
	Sa.fighters[0].wetT = 5
	ok(str(SimHash.stateHash(Sa).gameplay) != h0, "a fighter who is under (wetT 5) is not the same state as a dry one")
	WorldFill.setSurface(false)
	print("SURFACE: %d check(s) failed" % fails)
	quit()
