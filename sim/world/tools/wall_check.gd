extends SceneTree
# The wall slam and the lodge event (docs/design/buildings.md section 2; data/biomes/brunt.json wallSlamMul, wallStaggerTicks, lodgeHold):
#   godot --headless --path . --script res://sim/world/tools/wall_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func fresh(seed: int = 1) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false})
	S.out.fx.clear()
	return S


func tower(S: SimState, lo: int = 9, hi: int = 15):
	for b in S.buildings:
		if b.floors >= lo and b.floors <= hi and int(b.row) == 1:
			return b
	return null


## Drive one launched flight at a building; returns its events.
func fly(S: SimState, A, D, b, tier: float, force: float = 2000.0) -> Array:
	A.tier = tier
	D.hp = 1.0e9
	A.hp = 1.0e9
	D.x = SimWrap.wrap(b.x - 3000.0)
	D.y = WorldTerrain.groundY(S, D.x) + 100.0
	var plan = WorldBrunt.aim(S, A, D, b, force, 1.0 + A.ld.launch * (tier - 1.0), false)
	if plan == null:
		return []
	DirLaunch.doLaunch(S, A, D, plan, force)
	var ev: Array = []
	var g: int = 0
	while D.state == "launched" and g < 900:
		S.dirS.stop = 0.0
		SimFighter.stepLaunched(S, D, SimConst.DT)
		for e in S.out.fx:
			ev.append(e)
		S.out.fx.clear()
		g += 1
	return ev


func _init() -> void:
	var c: Dictionary = WorldBrunt.cfg()
	ok(WorldBrunt.dataErrors().is_empty(), "brunt.json loads clean (%s)" % str(WorldBrunt.dataErrors()))
	ok(c.lodgeHold == "world" and int(c.towerPunches[0]) == 0, "the homework switches stand at today's behaviour (lodgeHold %s, towerPunches[0] %d)" % [c.lodgeHold, int(c.towerPunches[0])])
	var S := fresh(1)
	var tw = tower(S)
	var D = S.fighters[0]
	var ev: Array = fly(S, S.fighters[1], D, tw, 1.0)
	var hits: Array = ev.filter(func(e): return e.type == "building_hit")
	ok(hits.size() == 1 and hits[0].outcome == "wall" and hits[0].keep == 0.0, "a tier-1 body at a tower is a wall: building_hit outcome wall, keep 0 (%s)" % str(hits.map(func(e): return e.outcome)))
	var fh: Array = ev.filter(func(e): return e.type == "floor_hit")
	ok(fh.size() == 1 and fh[0].outcome in ["crack", "dent"], "and the floor_hit says how it broke (%s)" % str(fh.map(func(e): return e.outcome)))
	ok(ev.filter(func(e): return e.type == "lodge").is_empty(), "a held body has no lodge event")
	# the stagger: set to the flight and then the data's ticks, so he is staggered that long after he lands; a max, never lowered
	ok(D.state != "launched" and D.stunTicks >= int(c.wallStaggerTicks), "he is staggered at least %d ticks after the rebound (%d left when he is down)" % [int(c.wallStaggerTicks), D.stunTicks])
	var S4 := fresh(1)
	var D4 = S4.fighters[0]
	D4.stunTicks = 500
	fly(S4, S4.fighters[1], D4, tower(S4), 1.0)
	ok(D4.stunTicks >= 400, "a longer stun already on him is not lowered (%d)" % D4.stunTicks)
	# the slam is twice the hit
	var S1 := fresh(1)
	var D1 = S1.fighters[0]
	c.wallSlamMul = 1.0
	fly(S1, S1.fighters[1], D1, tower(S1), 1.0)
	c.wallSlamMul = 2.0
	var hurt1: float = 1.0e9 - D1.hp
	var S2 := fresh(1)
	var D2 = S2.fighters[0]
	fly(S2, S2.fighters[1], D2, tower(S2), 1.0)
	var hurt2: float = 1.0e9 - D2.hp
	ok(hurt2 > hurt1 * 1.5 and hurt2 < hurt1 * 2.6, "the wall slam is twice the hit: %.1f against %.1f with wallSlamMul 1" % [hurt2, hurt1])
	# the lodge event
	var rg := SimRng.new(3)
	var lodges: int = 0
	var lodge_ok: int = 0
	for n in range(60):
		var Sx := fresh(1 + n % 5)
		var Dx = Sx.fighters[0]
		var pick = Sx.buildings[int(rg.next() * float(Sx.buildings.size()))]
		var evx: Array = fly(Sx, Sx.fighters[1], Dx, pick, float(1 + n % 4))
		var hs: Array = evx.filter(func(e): return e.type == "building_hit")
		for e in evx:
			if e.type == "lodge":
				lodges += 1
				var h = hs[hs.size() - 1] if hs.size() > 0 else null
				if e.hold > 0.45 and e.hold < 0.95 and absf(e.x - Dx.x) < 1.0 and e.b >= 0.0 and h != null and h.keep == 0.0 and int(h.b) == int(e.b):
					lodge_ok += 1
	ok(lodges > 5 and lodge_ok == lodges, "a lodge event carries x, y, z and the hold seconds, after a building_hit with keep 0 (%d lodges, %d well formed)" % [lodges, lodge_ok])
	# lodgeHold body: no hit-stop of the world, the body is stunned
	c.lodgeHold = "body"
	var stop_max: float = 0.0
	var stunned: bool = false
	for n in range(40):
		var Sy := fresh(1 + n % 5)
		var Dy = Sy.fighters[0]
		var evy: Array = fly(Sy, Sy.fighters[1], Dy, Sy.buildings[(n * 7) % Sy.buildings.size()], 4.0)
		if evy.any(func(e): return e.type == "lodge"):
			stunned = Dy.stunTicks >= 20
			break
	ok(stunned, "lodgeHold body: the body is stunned for the hold")
	c.lodgeHold = "world"
	print("WALL: %d check(s) failed" % fails)
	quit()
