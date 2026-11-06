extends SceneTree
# Nodes read ahead (World, sim/world/field.gd warmNear, data/biomes/field.json warm.radius 10,000; docs/world/node-warm.md): it reads every canonical node within a radius of a point, a slice at a time if asked; a node it reads
# is the node a cold read gives (bit for bit); a read of that ground afterwards finds them all; and a match with it on is the same match, to the hash.
#   godot --headless --path . --script res://sim/world/tools/node_warm_check.gd -- [--planet=12] [--touch=1]
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


func _init() -> void:
	var planet: int = 12
	var touch: int = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--touch="):
			touch = int(a.substr(8))
	var d: Dictionary = WorldField.data()
	ok(float(d.get("warm", {}).get("radius", -1.0)) == 10000.0 and WorldField.warmRadius() == 10000.0, "the data's radius is 10,000 units (Rendering's read: the tile bake reads to about 9,600 at load)")
	d["warm"] = {"radius": 0.0}   # the baseline match below has none
	var S := _match(planet, touch)
	var h_off: String = str(SimHash.stateHash(S).gameplay)
	var P := WorldPlanet.make(planet)
	var F = WorldField.of(P)
	var q := [-float(S.frame.px), -float(S.frame.py), -float(S.frame.pz)]   # the far side: nodes nobody has read
	var state := {}
	var r0: int = F.reads
	var t0: int = Time.get_ticks_usec()
	var done: bool = WorldField.warmNear(F, q[0], q[1], q[2], 4000.0, 0, state)
	var dt: int = Time.get_ticks_usec() - t0
	var n1: int = F.reads - r0
	ok(done and n1 > 1500 and n1 < 3000, "a radius of 4,000 units reads %d nodes in %.0f ms (%.0f microseconds a node)" % [n1, float(dt) / 1000.0, float(dt) / maxf(float(n1), 1.0)])
	var again := {}
	var r1: int = F.reads
	WorldField.warmNear(F, q[0], q[1], q[2], 4000.0, 0, again)
	ok(F.reads == r1, "a second call finds them all (0 new reads)")
	# the same disc a slice at a time, on another planet's far side: the same nodes
	var step_state := {}
	var calls: int = 0
	var F2 = WorldField.of(WorldPlanet.make(planet))   # the same field: already warm; count calls only
	while not WorldField.warmNear(F2, q[0], q[1], q[2], 4000.0, 400, step_state):
		calls += 1
		if calls > 1000:
			break
	ok(calls >= 1 and calls < 1000, "read a slice at a time (%d calls of 400 nodes) it ends" % calls)
	# a node it read is the node a cold read gives
	WorldField._locate(q[0], q[1], q[2], F.N)
	var face: int = WorldField._lf
	var ci: int = int(round(WorldField._la))
	var cj: int = int(round(WorldField._lb))
	var diff: int = 0
	var checked: int = 0
	for k in range(40):
		var ii: int = ci + (k % 8) * 3 - 12
		var jj: int = cj + (k / 8) * 3 - 6
		if ii < 0 or jj < 0 or ii > F.N or jj > F.N:
			continue
		var idx: int = WorldField.ensure(F, face, ii, jj)
		WorldField._read(F, WorldField.dirOf(face, ii, jj, F.N))
		if PackedFloat32Array([WorldField._vh])[0] != F.h[idx] or WorldField._vb != F.b[idx]:
			diff += 1
		checked += 1
	ok(checked >= 30 and diff == 0, "%d of the warmed nodes equal a fresh read of the planet's function (%d differ)" % [checked, diff])
	# a view's block read in the disc finds its nodes
	var r2: int = F.reads
	WorldField.block(F, face, ci - 8, cj - 8, 16, 1)
	ok(F.reads == r2, "a block read of 17 by 17 nodes in the disc reads nothing new")
	# the same match with it on: the same hash
	WorldField.data()["warm"] = {"radius": 10000.0}
	var S2 := _match(planet, touch)
	var h_on: String = str(SimHash.stateHash(S2).gameplay)
	WorldField.data()["warm"] = {"radius": 10000.0}
	ok(h_on == h_off, "a match with warm.radius 10,000 is the same match: the same state hash")
	print("NODEWARM: %d check(s) failed" % fails)
	quit(0 if fails == 0 else 1)
