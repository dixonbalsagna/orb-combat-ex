extends SceneTree
## DirSwing on the core's swing (encounter.md section 2; simulation.md section 11), on field worlds: the switch off asks nothing;
## a turn the score asks for brings its place onto the line; a plan's read of the end line leaves nothing behind; a match swings,
## twice the same, and at rest every building is where the line puts it; a landing's swing is at rest by its time; a rest rule
## rests it.
##   godot --headless --path . --script res://sim/director/tools/swing_check.gd
## Ends on the verdict line.

const PLANETS := [7, 3, 11, 13]
const FIGHT_TICKS := 5400

var failed: int = 0


func _init() -> void:
	DirSwing.setForce(0)
	_off()
	DirSwing.setForce(1)
	_gen2()
	for p in PLANETS:
		_turnsOntoPlace(p)
		_planLeavesNothing(p)
	_match(7)
	_match(11)
	_restRule()
	_restBy()
	_buildings()
	DirSwing.setForce(-1)
	print("SWING: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _setup(planet: int) -> Dictionary:
	return {"planet": planet, "touch": 1, "planetGen": 3, "intro": false}


func _start(planet: int, ai: bool = true) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, planet, {"p1": ai, "p2": ai}, _setup(planet))
	return S


func _step(S: SimState, n: int = 1) -> void:
	for _k in range(n):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()


func _off() -> void:
	var S := _start(7)
	var picks: int = 0
	for _k in range(FIGHT_TICKS):
		SimCore.step(S)
		for e in S.out.fx:
			if e.type == "cue" and (e.kind == "swing_place" or e.kind == "swing_nudge"):
				picks += 1
		S.out.fx.clear()
		S.out.feed.clear()
		if S.game.ko != null:
			break
	_expect(picks == 0 and S.swing.n == 0, "the switch off: no pick, no swing (%d, %d)" % [picks, S.swing.n])
	# Another block's switch can size the integers past the swing's (a grapple's, say). What the switch off promises is that the swing wrote nothing there.
	var ints = S.fighters[0].act.dirI
	var wrote: int = 0
	for i in range(DirSwing._b(), mini(ints.size(), DirSwing._b() + DirSwing.W_N)):
		if int(ints[i]) != 0:
			wrote += 1
	_expect(wrote == 0, "the switch off: nothing in the swing's slots (%d)" % wrote)
	SimCore.dispose(S)


## The switch on, off a field world: nothing to turn.
func _gen2() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 7, {}, {"planet": 7, "touch": 1, "planetGen": 2, "intro": false})
	_expect(S.frame == null and not DirSwing.on(S), "gen 2: no line, so the switch does nothing")
	for _k in range(600):
		SimCore.step(S)
		for e in S.out.fx:
			if e.type == "cue" and e.kind == "swing_place":
				_expect(false, "gen 2: a pick")
		S.out.fx.clear()
		S.out.feed.clear()
	SimCore.dispose(S)


## The signs: for each place a candidate names, the turn asked brings the line's way onto it, either side of the pivot. With the
## law off: two idle fighters standing far apart would only slow it.
func _turnsOntoPlace(planet: int) -> void:
	SimField.data()["limitOff"] = true
	DirSwing.everyPlace = true
	var S := _start(planet, false)
	if S.frame == null:
		_expect(false, "planet %d has no field world" % planet)
		SimCore.dispose(S)
		return
	var done: int = 0
	for side in [1, -1]:
		_step(S, 2)
		var pv: float = float(S.fighters[0].x)
		var list: Array = DirSwing.candidates(S, pv, side, 150.0, 30000.0)
		var one = null
		for c in list:
			if int(c.id) >= 0 and absf(float(c.turn)) >= 20.0:
				one = c
				break
		if one == null:
			continue
		SimSwing.ask(S, {"deg": float(one.turn), "cause": "launch", "pivotX": pv})
		var limit: int = 0
		while S.swing.active and limit < 6000:
			_step(S)
			limit += 1
		_expect(not S.swing.active, "planet %d: it came to rest (%d ticks)" % [planet, limit])
		var found: bool = false
		for pl in DirSwing.places(S, DirSwing._planet(S), DirSwing._frame(S, pv), 1.0e9):
			if int(pl.id) == int(one.id):
				found = true
				var off: float = absf(float(DirSwing._turnFor(float(pl.phi), side)))
				_expect(off < 1.0, "planet %d side %d: a %.1f degree turn brings %s %d onto the line (%.3f off)" % [planet, side, float(one.turn), String(one.kind), int(one.id), off])
		_expect(found, "planet %d: the place is still listed" % planet)
		done += 1
	_expect(done > 0, "planet %d: a place to turn onto" % planet)
	SimField.data()["limitOff"] = false
	SimCore.dispose(S)


## A plan's read of the end line, and a running swing's, changes nothing the state keeps.
func _planLeavesNothing(planet: int) -> void:
	DirSwing.everyPlace = false
	var S := _start(planet, false)
	_step(S, 2)
	var A = S.fighters[0]
	var h0 = SimHash.stateHash(S)
	var bx0: PackedFloat64Array = S.bX.duplicate()
	var fr = S.frame.copy()
	SimSwing._applyTurn(fr, float(A.x), 60.0)
	var was = S.frame
	DirSwing._planOn(S, fr, float(S.fighters[1].x))
	var g1: float = WorldTerrain.groundY(S, float(A.x) + 3000.0, 0.0)
	var moved: bool = S.bX != bx0
	DirSwing._planOff(S)
	var g0: float = WorldTerrain.groundY(S, float(A.x) + 3000.0, 0.0)
	_expect(S.frame == was and DirSwing._was == null, "planet %d: the frame is back" % planet)
	_expect(SimHash.stateHash(S) == h0, "planet %d: the hash is the same after a plan's read" % planet)
	var same: bool = S.bX.size() == bx0.size()
	for i in range(S.bX.size() if same else 0):
		same = same and absf(S.bX[i] - bx0[i]) < 0.001
	_expect(same, "planet %d: the poses are back" % planet)
	moved = moved or DirSwing._posed.is_empty()   # no building within a plan's reach: nothing to move
	_expect(moved and g1 != g0, "planet %d: the plan read another line: the ground 3000 on, %.1f against %.1f" % [planet, g1, g0])
	SimCore.dispose(S)


## A whole fight, twice: swings happen, the frame stays unit and square, nothing leaks out of a plan, poses at rest match the line.
func _match(planet: int) -> void:
	var a: Array = _fight(planet)
	var b: Array = _fight(planet)
	_expect(a[0] == b[0], "planet %d: two runs, one hash" % planet)
	_expect(int(a[1]) > 0, "planet %d: swings ran (%d, of which %d big, on %d ticks)" % [planet, int(a[1]), int(a[2]), int(a[3])])
	_expect(int(a[4]) == 0, "planet %d: no plan left its frame in place (%d)" % [planet, int(a[4])])
	_expect(float(a[5]) < 0.5, "planet %d: at rest, once the far poses are done, the worst pose is %.3f off the line (%d rests)" % [planet, float(a[5]), int(a[7])])
	_expect(float(a[6]) < 0.5, "planet %d: on the rest's own tick, the worst pose a plan can ask about is %.3f off the line" % [planet, float(a[6])])


func _fight(planet: int) -> Array:
	var S := _start(planet)
	var big: int = 0
	var leak: int = 0
	var ticks: int = 0
	var worst: float = 0.0
	var worstNear: float = 0.0
	var rests: int = 0
	var was: bool = false
	var due: bool = false
	for _k in range(FIGHT_TICKS):
		SimCore.step(S)
		for e in S.out.fx:
			if e.type == "cue" and e.kind == "swing_place":
				big += 1
		S.out.fx.clear()
		S.out.feed.clear()
		if DirSwing._was != null:
			leak += 1
		if S.swing.active:
			ticks += 1
			due = false
		elif was:
			due = true
			for i in SimSwing._poseList(S):   # the buildings a plan can ask about are right at once. With places everywhere the far ones follow, a share a tick (SimSwing._posesFar)
				SimField.strip(S, S.bDir[i * 3], S.bDir[i * 3 + 1], S.bDir[i * 3 + 2])
				worstNear = maxf(worstNear, absf(SimWrap.sdx(SimField.sx, S.bX[i])))
		if due and S.swing.poseK < 0:
			due = false
			rests += 1
			for i in range(S.bX.size()):
				SimField.strip(S, S.bDir[i * 3], S.bDir[i * 3 + 1], S.bDir[i * 3 + 2])
				worst = maxf(worst, absf(SimWrap.sdx(SimField.sx, S.bX[i])))
		was = S.swing.active
		if S.game.ko != null:
			break
	var out: Array = [SimHash.stateHash(S), S.swing.n, big, ticks, leak, worst, worstNear, rests]
	SimCore.dispose(S)
	return out


## A rest rule (a KO, say) eases a running swing out, once.
func _restRule() -> void:
	var S := _start(7, false)
	_step(S, 2)
	SimSwing.ask(S, {"deg": 170.0, "cause": "launch"})
	_step(S, 40)
	_expect(S.swing.active and S.swing.rate > 0.0, "a running swing before the rule")
	S.fighters[0].interior = S.buildings[0]   # a tower chain
	_step(S, 1)
	var t: float = float(S.swing.ticks)
	_expect(DirSwing._resting(S.swing), "a rest rule rests it (%s)" % DirSwing.restRule(S))
	_step(S, 1)
	_expect(float(S.swing.ticks) == t or not S.swing.active, "and doesn't ask again")
	S.fighters[0].interior = null
	_step(S, int(DirSwing.cfg().restOut) + 2)
	_expect(not S.swing.active, "it's down in its ease")
	SimCore.dispose(S)


## A launch's ask, through a hit-stop, is at rest by its flight's time and has turned as far as that allowed. Also the guard: a
## swing the law has all but stopped gives up.
func _restBy() -> void:
	SimField.data()["limitOff"] = true
	var S := _start(7, false)
	_step(S, 2)
	var keep := [S.frame.tx, S.frame.ty, S.frame.tz]
	S.dirS.stop = 0.2
	var by: int = 90 - int(DirSwing.cfg().restTicks)
	var t0: int = S.tick
	_expect(DirSwing._take(S, "launch", S.fighters[0], {"id": -1, "s": 1.0, "kind": "open"}, {"deg": 170.0, "cause": "launch", "pivotX": float(S.fighters[0].x), "restBy": by, "later": true}, "launcher"), "the pick is taken")
	var asked: float = 0.0
	var at: int = -1
	for _k in range(240):
		_step(S)
		if S.swing.active:
			asked = float(S.swing.deg)
		elif asked > 0.0:
			at = S.tick - t0
			break
	_expect(at > 12 + by - 3 and at <= 12 + by + 2, "asked to rest %d live ticks after a 12-tick stop: rests at %d" % [by, at])
	_expect(asked < 170.0 and asked > 30.0, "the angle gave way to the time: %.1f" % asked)
	_expect(S.frame.tx != keep[0] or S.frame.ty != keep[1] or S.frame.tz != keep[2], "and the line moved")
	SimField.data()["limitOff"] = false
	SimCore.dispose(S)
	var S2 := _start(7, false)
	_step(S2, 2)
	SimSwing.ask(S2, {"deg": 170.0, "cause": "launch"})
	S2.swing.age = int(DirSwing.cfg().stallTicks)
	_step(S2, 1)
	_expect(DirSwing._resting(S2.swing), "a swing past stallTicks rests")
	SimCore.dispose(S2)


## Section 15, in a town: a standing building is offered, a turn that loses the town costs until two sends, and after a turn no
## building off the fight's depth is a target.
func _buildings() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	var A = S.fighters[0]
	var D = S.fighters[1]
	var target = null
	for b in S.buildings:
		if b.alive and b.row == 1.0 and not WorldSettle.noTarget(b.landmark) and (target == null or absf(SimWrap.sdx(A.x, b.x)) < absf(SimWrap.sdx(A.x, target.x))):
			target = b
	D.x = SimWrap.wrap(target.x - target.w * 0.5 - 600.0)
	D.y = WorldTerrain.groundY(S, D.x) + 80.0
	A.x = SimWrap.wrap(D.x - 58.0)
	A.y = D.y
	var list: Array = DirSwing.candidates(S, A.x, 1, 120.0, 13000.0)
	var offered: int = 0
	var costed: int = 0
	var most: float = 0.0
	for c in list:
		offered += 1 if c.has("bld") else 0
		costed += 1 if float(c.get("lost", 0.0)) > 0.0 else 0
		most = maxf(most, float(c.get("lost", 0.0)))
	_expect(offered > 0, "in a town, standing buildings are offered (%d)" % offered)
	_expect(costed > 0 and most > 0.0, "a turn that loses them costs (%d, most %.2f)" % [costed, most])
	var worst: Dictionary = {}
	for c in list:
		if float(c.get("lost", 0.0)) == most:
			worst = c
			break
	var dirNoCost: Dictionary = worst.duplicate()
	dirNoCost.erase("lost")
	var P = DirSwing._planet(S)
	var fr: Dictionary = DirSwing._frame(S, A.x)
	var a: float = float(DirSwing._direction(S, worst, A, 1, 13000.0, 120.0, P, fr).s)
	var b: float = float(DirSwing._direction(S, dirNoCost, A, 1, 13000.0, 120.0, P, fr).s)
	_expect(absf(b - a - float(DirSwing.cfg().buildings.leave) * most) < 0.0001, "the cost is leave times the share lost (%.2f)" % (b - a))
	DirSwing._s(S, DirSwing.W_SENDS, int(DirSwing.cfg().buildings.sends))
	var after: Array = DirSwing.candidates(S, A.x, 1, 120.0, 13000.0)
	var still: int = 0
	for c in after:
		still += 1 if c.has("lost") else 0
	_expect(still == 0, "after its sends, a turn costs nothing (%d)" % still)
	SimCore.dispose(S)
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	SimSwing.ask(S2, {"deg": 60.0, "cause": "launch"})
	var guard: int = 0
	while S2.swing.active and guard < 900:
		_step(S2)
		guard += 1
	var D2 = S2.fighters[1]
	var bad: int = 0
	var seen: int = 0
	var step: int = 0
	while step < 40:
		D2.x = SimWrap.wrap(D2.x + 900.0)
		D2.y = WorldTerrain.groundY(S2, D2.x) + 80.0
		for bi in WorldBrunt.candidates(S2, D2):
			seen += 1
			var bz: float = float(S2.buildings[bi].z) - float(D2.z)
			if bz > WorldBrunt.BR_Z_FRONT or -bz > WorldBrunt.BR_Z_BACK:
				bad += 1
		step += 1
	_expect(guard < 900, "the turn rested (%d)" % guard)
	DirSwing.everyPlace = false
	var S3 := _start(7, false)
	var P3 = DirSwing._planet(S3)
	var all: int = P3.n
	var built: int = DirSwing.places(S3, P3, DirSwing._frame(S3, float(S3.fighters[0].x)), 200000.0).size()
	_expect(built > 0 and (built < all or S3.bFirst > 0), "only built places count as towns (%d of %d; with places everywhere, all of them are built)" % [built, all])
	SimCore.dispose(S3)
	_expect(bad == 0, "after a turn, no target stands off the fight's depth (%d of %d)" % [bad, seen])
	SimCore.dispose(S2)
