extends SceneTree
## Walk him to the wall (docs/design/rule-of-cool-map.md row 2), by a scripted player on an idle rival near a building, on a field
## world: a lean for 3 blows and then B reaches it at least 70% of the time; no lean, it's today's rate; off, no slot; worth doesn't move.
##   godot --headless --path . --script res://sim/director/tools/walk_check.gd
## Ends on the verdict line.

var failed: int = 0
var _hits: int = 0
var _hitB: int = -1
var _last: Array = []
var names: Dictionary = {}


func _init() -> void:
	_rows()
	DirWalk.setForce(-1)
	print("WALK: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _step(S: SimState, a: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), SimIntent.new()])
	for e in S.out.fx:
		if e.type == "building_hit":
			_hits += 1
			_hitB = int(e.b)
		elif e.type == "launch_plan":
			_last.append(String(e.chosen))
	S.out.fx.clear()
	S.out.feed.clear()


func _fresh() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	for f in S.fighters:
		f.ai = null
		f.ki = 100.0
		f.hp = 100000.0
	S.out.fx.clear()
	return S


## Puts the pair gap short of the building's near side, the rival nearer it, and runs the string: blows, leaning or not, then B.
## Returns [reached, the rival's hit points lost to the blows].
func _run(i: int, gap: float, lean: float, blows: int, hold: int = 46) -> Array:
	var S := _fresh()
	var b = S.buildings[i]
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(b.x - (b.w * 0.5 + gap))
	D.y = WorldTerrain.groundY(S, D.x)
	A.x = SimWrap.wrap(D.x - 58.0)
	A.y = D.y
	A.face = 1.0
	for _k in range(5):
		_step(S)
	var hp0: float = D.hp
	for _n in range(blows):
		var a := SimIntent.new()
		a.light = true
		a.mx = lean
		_step(S, a)
		for _k in range(22):
			var h := SimIntent.new()
			h.mx = lean
			_step(S, h)
	var lost: float = hp0 - D.hp
	_hits = 0
	_hitB = -1
	var y := SimIntent.new()
	y.sig = true
	y.sigHeld = true
	y.mx = lean
	_step(S, y)
	for _k in range(hold):
		var h := SimIntent.new()
		h.sigHeld = true
		h.mx = lean
		_step(S, h)
	for _k in range(200):
		var h := SimIntent.new()
		h.mx = lean
		_step(S, h)
		for e in _last:
			names[e] = int(names.get(e, 0)) + 1
		_last.clear()
		if _hits > 0:
			break
	var reached: bool = _hits > 0
	SimCore.dispose(S)
	return [reached, lost]


func _rows() -> void:
	var S := _fresh()
	var ids: Array = []
	for i in range(S.buildings.size()):
		var b = S.buildings[i]
		if b.alive and not WorldSettle.noTarget(b.landmark) and absf(WorldBrunt.faceZ(b)) <= 800.0:
			ids.append(i)
	SimCore.dispose(S)
	var pick: Array = []
	var step: int = maxi(1, ids.size() / 10)
	var k: int = 0
	while k < ids.size() and pick.size() < 10:
		pick.append(ids[k])
		k += step
	DirWalk.setForce(1)
	var reachedOn: int = 0
	for i in pick:
		reachedOn += 1 if bool(_run(int(i), 700.0, 1.0, 3)[0]) else 0
	var short: int = 0
	for i in pick:
		short += 1 if bool(_run(int(i), 700.0, 1.0, 3, 16)[0]) else 0
	print("      a short charge's knock-back: %d of %d" % [short, pick.size()])
	var off: int = 0
	var worthOn: float = float(_run(int(pick[0]), 700.0, 1.0, 3)[1])
	DirWalk.setForce(0)
	for i in pick:
		off += 1 if bool(_run(int(i), 700.0, 1.0, 3)[0]) else 0
	var worthOff: float = float(_run(int(pick[0]), 700.0, 1.0, 3)[1])
	DirWalk.setForce(1)
	var noLean: int = 0
	for i in pick:
		noLean += 1 if bool(_run(int(i), 700.0, 0.0, 3)[0]) else 0
	print("      of %d buildings, 700 away: leaning %d, switch off %d, no lean %d" % [pick.size(), reachedOn, off, noLean])
	print("      sends seen: " + JSON.stringify(names))
	_expect(float(reachedOn) >= 0.7 * float(pick.size()), "3 blows leaning, then B: at least 70%% reach it (%d of %d)" % [reachedOn, pick.size()])
	_expect(noLean <= off + 1, "no lean: it's today's rate (%d against %d)" % [noLean, off])
	_expect(absf(worthOn - worthOff) < 0.001, "worth doesn't move (%.2f against %.2f)" % [worthOn, worthOff])
	DirWalk.setForce(0)
	var S2 := _fresh()
	var n0: int = S2.fighters[0].act.dirI.size()
	_expect(DirWalk.wall(S2, S2.fighters[0], 1.0).is_empty(), "off: no wall")
	_expect(S2.fighters[0].act.dirI.size() == n0, "off: no slot")
	SimCore.dispose(S2)
