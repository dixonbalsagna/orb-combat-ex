extends SceneTree
## The plain hold's stages (stick.json strikeStages; docs/director/beams-own-move-plan.md step 2), on the ladder and in a brawl:
##   godot --headless --path . --script res://sim/director/tools/strike_stages_check.gd
## - the ladder: six stages by the clock for a top fighter, the level capped at 3; the top's price, 2 a second; stepping down
## - in a brawl: a hold let go at 47 ticks lands at level 3 by the stages (2 by the stick's own ladder); a held charge never goes by
##   itself with the stages on (it goes at autoGoTicks off); a top fighter's hold to stage 5 lands at level 3
## Ends on the verdict line.

var failed: int = 0
var _rel: Array = []


func _init() -> void:
	DirStick.setForce(1)
	DirStick.setArmourForce(0)
	DirBeamMove.setStrikeForce(1)
	_ladder()
	_top()
	_level(true)
	_noGo(true)
	_cap()
	DirBeamMove.setStrikeForce(0)
	_level(false)
	_noGo(false)
	DirBeamMove.setStrikeForce(-1)
	DirStick.setArmourForce(-1)
	DirStick.setForce(-1)
	print("STRIKE STAGES: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _pair() -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.ki = 100.0
		f.hp = 100000.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 58.0)
	S.fighters[1].y = S.fighters[0].y
	for _k in range(10):
		_step(S)
	var l := SimIntent.new()
	l.light = true
	_step(S, l)
	for _k in range(30):
		_step(S)
	return S


func _step(S: SimState, a: SimIntent = null, b: SimIntent = null) -> void:
	SimCore.step(S, [a if a != null else SimIntent.new(), b if b != null else SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue" and e.kind == "stick_release":
			_rel.append([S.tick, int(String(e.source))])
	S.out.fx.clear()
	S.out.feed.clear()


func _word(start: bool, release: bool, held: bool, lvl: int = 0) -> SimIntent:
	var i := SimIntent.new()
	i.rsStart = start
	i.rsRelease = release
	i.rsHeld = held
	i.rsDir = SimStrikeRead.RIGHT
	i.rsLevel = lvl
	return i


## A plain hold of n live ticks, let go on the next with the stick's own level for that hold.
func _holdFor(S: SimState, n: int) -> void:
	_step(S, _word(true, false, true))
	for _k in range(n - 1):
		_step(S, _word(false, false, true))
	_step(S, _word(false, true, false, DirStick._reader().level_at(n)))
	for _k in range(30):
		_step(S)


func _ladder() -> void:
	var S := _pair()
	var A = S.fighters[0]
	A.tier = 4.0
	A.power = 100.0
	A.ki = 100.0
	DirBeamMove.strikeBegan(S, A)
	var got: Array = []
	var lv: Array = []
	for h in [11, 12, 28, 46, 66, 90, 120]:
		DirBeamMove.strikeHolding(S, A, h, 0.0)
		got.append(DirBeamMove.stage(A))
		lv.append(DirBeamMove.strikeLevel(A))
	_expect(got == [0, 1, 2, 3, 4, 5, 6] and lv == [0, 1, 2, 3, 3, 3, 3], "a top fighter's plain hold climbs six stages by the clock, its level capped at 3: %s, %s" % [str(got), str(lv)])
	SimCore.dispose(S)


func _top() -> void:
	var S := _pair()
	var A = S.fighters[0]
	A.tier = 1.0
	A.power = 0.0
	A.ki = 50.0
	DirBeamMove.strikeBegan(S, A)
	DirBeamMove.strikeHolding(S, A, 28, SimConst.DT)
	var ki0: float = A.ki
	for h in range(29, 89):
		DirBeamMove.strikeHolding(S, A, h, SimConst.DT)
	var spent: float = ki0 - A.ki
	_expect(DirBeamMove.stage(A) == 2 and absf(spent - 2.0) < 0.01, "at the top (2 of 2) a second's hold costs 2 (%.3f)" % spent)
	A.ki = 1.5   # under level 2's price over the quick's
	DirBeamMove.strikeHolding(S, A, 90, SimConst.DT)
	_expect(DirBeamMove.stage(A) == 1, "under the top's price it steps down: stage %d" % DirBeamMove.stage(A))
	SimCore.dispose(S)


func _level(on: bool) -> void:
	_rel.clear()
	var S := _pair()
	S.fighters[0].tier = 4.0
	S.fighters[0].power = 100.0
	_holdFor(S, 47)
	var l: int = int(_rel[_rel.size() - 1][1]) if not _rel.is_empty() else -1
	if on:
		_expect(l == 3, "with the stages, a top fighter's hold let go at 47 ticks lands at level 3 (stage 3 at 46): level %d" % l)
	else:
		_expect(l == 2, "off, the same hold lands at the stick's own level 2: level %d" % l)
	SimCore.dispose(S)
	if on:
		_rel.clear()
		var S2 := _pair()
		_holdFor(S2, 47)
		var l2: int = int(_rel[_rel.size() - 1][1]) if not _rel.is_empty() else -1
		_expect(l2 == 2, "a base fighter has 2 stages: the same hold lands at level 2: level %d" % l2)
		SimCore.dispose(S2)


func _noGo(on: bool) -> void:
	_rel.clear()
	var S := _pair()
	_step(S, _word(true, false, true))
	var t0: int = S.tick
	for _k in range(200):
		_step(S, _word(false, false, true))
	var went: int = int(_rel[0][0]) - t0 if not _rel.is_empty() else -1
	if on:
		_expect(went < 0, "with the stages, held 200 ticks it never goes by itself")
	else:
		_expect(went > 0 and went <= int(DirStick.cfg().autoGoTicks) + 12, "off, it goes by itself near autoGoTicks: after %d ticks" % went)
	SimCore.dispose(S)


func _cap() -> void:
	_rel.clear()
	var S := _pair()
	var A = S.fighters[0]
	A.tier = 4.0
	A.power = 100.0
	_holdFor(S, 95)
	var l: int = int(_rel[_rel.size() - 1][1]) if not _rel.is_empty() else -1
	_expect(l == 3, "a top fighter's hold to stage 5 lands at level 3, its blow's top: level %d" % l)
	SimCore.dispose(S)
