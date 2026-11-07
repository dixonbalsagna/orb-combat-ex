extends SceneTree
## City step one's push (docs/director/pending/city-push/): the wall push that fires, the computer's lean, and the turn on impact.
##   godot --headless --path . --script res://sim/director/tools/city_push_check.gd
## - a knock-back after a walked string reaches for its building whatever the attacker's care (the knock's own care roll is for an
##   unwalked one); B's launch counts the walked building among its candidates
## - the computer leans (walk.ai): its stick toward its rival when a standing building stands beyond him, by its personality's share, and
##   the lean carries its blows like a player's; off, never
## - the turn on impact (swing.json slam): a slam into a building on a field world starts a big swing, cause slam, toward the street
##   behind it, and when it's done the line runs nearer down the street; a lodge in the tick's events starts it too; off, nothing
## Ends on the verdict line.

var failed: int = 0
const FIELD: Dictionary = {"intro": false, "planet": 7, "touch": 1, "planetGen": 3}


func _init() -> void:
	DirWalk.setForce(1)
	_aiLean()
	_turn()
	DirWalk.setForce(-1)
	print("CITY PUSH: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## A building in a lot whose street stands at an angle to the line at its place, near a fighter: [S, bi], or [S, -1].
func _cityPair(su: Dictionary, ai: bool) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 21, {"p1": ai, "p2": ai}, su)
	for f in S.fighters:
		f.hp = 100000.0
	# The line starts laid along the street: turn it 25 degrees first, so the streets stand at an angle to it.
	SimSwing.ask(S, {"deg": 20.0, "cause": "launch", "pivotX": float(S.buildings[0].x) if S.buildings.size() > 0 else float(S.fighters[0].x)})   # about the town, so its buildings stay near the line
	for _k in range(600):
		if not S.swing.active:
			break
		SimCore.step(S, [SimIntent.new(), SimIntent.new()] if not ai else [null, null])
		S.out.fx.clear()
		S.out.feed.clear()
	var pick: int = -1
	var best: float = 0.0
	for bi in range(S.buildings.size()):
		var b = S.buildings[bi]
		if not b.alive or float(b.z) > WorldBrunt.BR_Z_FRONT or -float(b.z) > WorldBrunt.BR_Z_BACK:   # in the fight's depth band
			continue
		var ax: Dictionary = WorldStructures.streetAxis(S, bi)
		var a: float = absf(float(ax.alongSin))
		if bool(ax.found) and a > 0.2 and a < 0.65 and a > best:
			best = a
			pick = bi
	var nz: int = 0
	var na: int = 0
	for bj in range(S.buildings.size()):
		if float(S.buildings[bj].z) <= WorldBrunt.BR_Z_FRONT and -float(S.buildings[bj].z) <= WorldBrunt.BR_Z_BACK:
			nz += 1
			if absf(float(WorldStructures.streetAxis(S, bj).alongSin)) > 0.2:
				na += 1
	print("      (after the turn: swing active %s, %d buildings near the line, %d of them at an angle)" % [str(S.swing.active), nz, na])
	if pick >= 0:
		var b = S.buildings[pick]
		S.fighters[1].x = SimWrap.wrap(b.x - 400.0)
		S.fighters[0].x = SimWrap.wrap(b.x - 460.0)
		S.fighters[0].y = WorldTerrain.groundY(S, S.fighters[0].x) + 2.0
		S.fighters[1].y = WorldTerrain.groundY(S, S.fighters[1].x) + 2.0
		S.fighters[0].z = float(b.z)
		S.fighters[1].z = float(b.z)
	return [S, pick]


func _aiLean() -> void:
	var ai: Dictionary = DirWalk.cfg().ai
	var r: Array = _cityPair(FIELD, true)
	var S: SimState = r[0]
	var bi: int = r[1]
	_expect(bi >= 0, "a building on a field world beyond the pair (%d)" % bi)
	if bi < 0:
		SimCore.dispose(S)
		return
	var A = S.fighters[0]
	var D = S.fighters[1]
	# the lean, read on its own: share forced to all its strings
	ai["enabled"] = true
	var keep: float = float(ai.get("villain", 0.5))
	var keepH: float = float(ai.get("hero", 0.275))
	ai["villain"] = 1.0
	ai["hero"] = 1.0
	var i := SimIntent.new()
	DirWalk.aiLean(S, A, D, i)
	var side: float = 1.0 if SimWrap.sdx(A.x, D.x) >= 0.0 else -1.0
	var leaned: bool = i.mx == side and DirWalk._g(A, DirWalk.W_TGT) > 0   # (the nearest standing building beyond him: with buildings everywhere, not always the one the pair stands by)
	ai["villain"] = 0.0
	ai["hero"] = 0.0
	S.dirS.exN += 1   # a new string: a new draw
	var i2 := SimIntent.new()
	DirWalk.aiLean(S, A, D, i2)
	var never: bool = i2.mx == 0.0
	ai["enabled"] = false
	S.dirS.exN += 1
	var i3 := SimIntent.new()
	DirWalk.aiLean(S, A, D, i3)
	var off: bool = i3.mx == 0.0
	ai["villain"] = keep
	ai["hero"] = keepH
	_expect(leaned, "with its share at all strings, the computer holds its stick toward its rival, a building beyond him its target")
	_expect(never and off, "with its share at none it never leans, and off it never does")
	SimCore.dispose(S)


func _turn() -> void:
	var sl: Dictionary = DirSwing.cfg().slam
	var r: Array = _cityPair(FIELD, true)   # (its own turn first, with the director's swing off, so nothing rests it)
	var S: SimState = r[0]
	var bi: int = r[1]
	DirSwing.setForce(1)
	sl["enabled"] = true
	if bi < 0:
		_expect(false, "a building to slam into")
		SimCore.dispose(S)
		return
	var A = S.fighters[0]
	var D = S.fighters[1]
	for _k in range(30):
		SimCore.step(S, [null, null])
		S.out.fx.clear()
	var before: float = float(WorldStructures.streetAxis(S, bi).alongSin)
	DirSwing.atImpact(S, A, D, bi)
	var started: bool = S.swing.active and String(S.swing.cause) == "slam"
	for _k in range(600):
		if not S.swing.active:
			break
		SimCore.step(S, [null, null])
		S.out.fx.clear()
	var after: float = float(WorldStructures.streetAxis(S, bi).alongSin)
	print("      the street's angle to the line at the building: sine %.3f before, %.3f after" % [before, after])
	_expect(started, "a slam starts a big swing, cause slam")
	_expect(absf(after) < absf(before) - 0.1, "and when it's done the line runs nearer down the street behind the building")
	SimCore.dispose(S)
	# a lodge among the tick's events starts it too
	DirSwing.setForce(-1)
	var r2: Array = _cityPair(FIELD, true)
	DirSwing.setForce(1)
	var S2: SimState = r2[0]
	var b2: int = r2[1]
	for _k in range(30):
		SimCore.step(S2, [null, null])
		S2.out.fx.clear()
	SimFx.lodge(S2, S2.fighters[1], S2.buildings[b2], S2.fighters[1].x, S2.fighters[1].y, 0.5, 1, S2.fighters[0])
	DirSwing._impacts(S2)
	_expect(S2.swing.active and String(S2.swing.cause) == "slam", "a lodge in the tick's events starts it")
	SimCore.dispose(S2)
	sl["enabled"] = false
	DirSwing.setForce(-1)
	var r3: Array = _cityPair(FIELD, true)
	DirSwing.setForce(1)
	var S3: SimState = r3[0]
	for _k in range(30):
		SimCore.step(S3, [null, null])
		S3.out.fx.clear()
	DirSwing.atImpact(S3, S3.fighters[0], S3.fighters[1], int(r3[1]))
	_expect(not (S3.swing.active and String(S3.swing.cause) == "slam"), "off, a slam turns nothing")
	SimCore.dispose(S3)
	DirSwing.setForce(-1)
