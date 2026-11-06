extends SceneTree
## 2v2's blow from outside (DirOutside, Game Design's "Hits across fights" 1 and 2), on a match of two fights with cross on: it lands
## only on an opening, waits for one or whiffs, one an opening, never on a partner, and what it does in the fight it lands in. Off,
## nothing crosses.
##   godot --headless --path . --script res://sim/director/tools/outside_check.gd
## Ends on the verdict line.

var failed: int = 0
var _cues: Array = []


func _init() -> void:
	DirOutside.setForce(1)
	_opening()
	_waits()
	_whiff()
	_once()
	_ownFirst()
	_string()
	_beamStop()
	_shotAcross()
	_teamStun()
	_join()
	_brink()
	_winner(true)
	_winner(false)
	DirOutside.setForce(0)
	_off()
	DirOutside.setForce(-1)
	print("OUTSIDE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## Four bodies, the fights apart by setup: p1 (A, fight 0) and p4 (his enemy in fight 1) put close; p2, A's own rival, far off.
func _new() -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 21, {"p1": false, "p2": false, "p3": false, "p4": false}, {"intro": false, "fights": 2, "cross": true})
	var q: Array = []
	for k in ["p1", "p2", "p3", "p4"]:
		for f in SimStage.bodies(S):
			if f.keys == k:
				q.append(f)
	for f in q:
		f.ai = null
		f.hp = 100000.0
		f.ki = 100.0
	var A = q[0]
	_put(q[1], A.x - 2400.0 * A.face, A)
	_put(q[2], A.x + 2600.0 * A.face, A)
	_put(q[3], A.x + 140.0 * A.face, A)
	for _k in range(3):
		_step(S)
	return [S, q]


func _put(f, x: float, ref) -> void:
	f.x = SimWrap.wrap(x)
	f.y = ref.y
	f.z = ref.z
	f.vx = 0.0
	f.vy = 0.0


func _step(S: SimState, i = null, i3 = null, i4 = null) -> void:
	_cues = []
	SimCore.step(S, [i if i != null else SimIntent.new(), SimIntent.new(), i3 if i3 != null else SimIntent.new(), i4 if i4 != null else SimIntent.new()])
	var outs: Array = [S.out]
	for r in S.stage.fights:
		if r.out != null and r.out != S.out:
			outs.append(r.out)
	for o in outs:
		for e in o.fx:
			if e.type == "cue" and (String(e.kind).begins_with("outside") or String(e.kind) == "brink_call"):
				_cues.append(String(e.kind) + ":" + String(e.text) + ("/" + String(e.source) if String(e.source) != "" else ""))
		o.fx.clear()
		o.feed.clear()


func _said(list: Array, prefix: String) -> bool:
	for c in list:
		if String(c).begins_with(prefix):
			return true
	return false


func _x() -> SimIntent:
	var i := SimIntent.new()
	i.light = true
	return i


## His enemy across, stunned: X goes to him and the blow lands in his fight.
func _opening() -> void:
	var r: Array = _new()
	var S: SimState = r[0]
	var q: Array = r[1]
	var D = q[3]
	D.stunTicks = 40
	var hp: float = D.hp
	_step(S, _x())
	var said: Array = _cues.duplicate()
	for _k in range(20):
		_step(S)
	print("      stunned across: said %s; he took %.0f" % [str(said), hp - D.hp])
	_expect(_said(said, "outside:start") and hp - D.hp > 0.0, "a blow from outside lands on an enemy across who's open")
	SimCore.dispose(S)


## Not open as he arrives: he hovers, and it lands on the opening that comes inside waitSec.
func _waits() -> void:
	var r: Array = _new()
	var S: SimState = r[0]
	var D = r[1][3]
	var hp: float = D.hp
	_step(S, _x())
	for k in range(30):
		if k == 12:
			D.stunTicks = 20
		_step(S)
	print("      open 12 ticks in: he took %.0f" % (hp - D.hp))
	_expect(hp - D.hp > 0.0, "he hovers in reach and it lands on the opening that comes")
	SimCore.dispose(S)


## No opening inside waitSec: a whiff, and he's open.
func _whiff() -> void:
	var r: Array = _new()
	var S: SimState = r[0]
	var A = r[1][0]
	var D = r[1][3]
	var hp: float = D.hp
	_step(S, _x())
	var whiffed: bool = false
	for _k in range(50):
		_step(S)
		whiffed = whiffed or _said(_cues, "outside:whiff")
	print("      never open: whiffed %s, he took %.0f, his line free in %d" % [str(whiffed), hp - D.hp, DirBrawl._g(A, DirBrawl.FREE_AT) - S.tick])
	_expect(whiffed and hp - D.hp == 0.0, "no opening: a whiff, and nothing lands")
	SimCore.dispose(S)


## One an opening: a second press in the same stun lands nothing more.
func _once() -> void:
	var r: Array = _new()
	var S: SimState = r[0]
	var D = r[1][3]
	D.stunTicks = 60
	_step(S, _x())
	for _k in range(15):
		_step(S)
	var hp1: float = D.hp
	_step(S, _x())
	for _k in range(15):
		_step(S)
	print("      a second press in the same stun: he took %.0f more" % (hp1 - D.hp))
	_expect(hp1 - D.hp == 0.0, "one blow from outside an opening")
	SimCore.dispose(S)


## His own rival nearer: the press is his own fight's.
func _ownFirst() -> void:
	var r: Array = _new()
	var S: SimState = r[0]
	var q: Array = r[1]
	var A = q[0]
	_put(q[1], A.x + 60.0 * A.face, A)
	q[3].stunTicks = 40
	_step(S, _x())
	print("      his own rival at 60: said %s" % str(_cues))
	_expect(not _said(_cues, "outside:start"), "his own rival nearer: no blow from outside")
	SimCore.dispose(S)


## In the fight it lands in: on someone in a string, it ends his string and his run. Fight 1's pair trade blows, then his blow lands.
func _string() -> void:
	var r: Array = _new()
	var S: SimState = r[0]
	var q: Array = r[1]
	var A = q[0]
	var C = q[2]
	var D = q[3]
	_put(C, D.x + 60.0 * A.face, D)
	var ranAt: int = -1
	var hit: bool = false
	var strBefore: int = 0
	var runBefore: int = 0
	for k in range(140):
		var i3: SimIntent = _x() if k % 7 == 0 else null
		var i4: SimIntent = _x() if k % 7 == 3 else null
		var i1: SimIntent = null
		if k == 60:
			strBefore = DirBrawl._g(D, DirBrawl.STR_ON)
			runBefore = DirBrawl._g(D, DirBrawl.RUN)
			i1 = _x()
		_step(S, i1, i3, i4)
		for c in _cues:
			if String(c).begins_with("outside_hit:") and not hit:
				hit = true
				ranAt = k
		if hit:
			break
	print("      in a trade across: his string %d and run %d as the press went; the blow landed at %d: string %d, run %d" % [strBefore, runBefore, ranAt, DirBrawl._g(D, DirBrawl.STR_ON), DirBrawl._g(D, DirBrawl.RUN)])
	_expect(hit, "a blow from outside lands on a man in a trade of his own")
	_expect(not hit or DirBrawl._g(D, DirBrawl.STR_ON) == 0, "... and ends his string, his run with it")
	SimCore.dispose(S)


## Off: nothing crosses.
func _off() -> void:
	var r: Array = _new()
	var S: SimState = r[0]
	var D = r[1][3]
	D.stunTicks = 40
	var hp: float = D.hp
	_step(S, _x())
	for _k in range(20):
		_step(S)
	_expect(hp - D.hp == 0.0 and not _said(_cues, "outside:start"), "off: nothing crosses")
	SimCore.dispose(S)


## A beam whose line meets an enemy of the other fight first: he's warned, it stops on him, and the beam's own target is spared its
## outcome, the exchange over.
func _beamStop() -> void:
	var r: Array = _new()
	var S: SimState = r[0]
	var q: Array = r[1]
	var A = q[0]
	var R = q[1]
	var D = q[3]
	_put(R, A.x + 1600.0 * A.face, A)
	_put(D, A.x + 700.0 * A.face, A)
	A.ki = 100.0
	var hpR: float = R.hp
	var hpD: float = D.hp
	var warned: bool = false
	var stopped: bool = false
	DirBeamPlay.setFrontForce(1)
	var fc: Dictionary = DirBeamPlay.frontCfg()
	var was = fc.get("stationary", false)
	fc["stationary"] = true   # the shooter stays put: the beam runs level, along the ground
	var fired: bool = false
	for k in range(300):
		var h := SimIntent.new()
		if k == 0:
			h.sig = true
			h.stanceMask = 4   # the charging stance: B is the signature (beam_front_check's _fire)
		_step(S, h)
		warned = warned or DirOutside._g(D, DirOutside.O_WARN) != 0
		fired = fired or not S.beams.is_empty()
		for b in S.beams:
			stopped = stopped or float(b.stopAt) >= 0.0
		if fired and S.dirS.ex == null:
			break
	print("      a beam at his rival 1,600 off, an enemy across at 700 on its line: fired %s, warned %s, stopped %s; the rival took %.0f, the enemy across %.0f" % [str(fired), str(warned), str(stopped), hpR - R.hp, hpD - D.hp])
	_expect(fired and stopped and warned, "a beam meets an enemy across first: he's warned, and it stops on him")
	_expect(hpR - R.hp == 0.0, "... and its own target is spared it, the exchange over")
	fc["stationary"] = was
	DirBeamPlay.setFrontForce(-1)
	SimCore.dispose(S)


## A blast press with his focus across: the shot is made in the other fight, at him, and lands there; the ki is paid as for any shot.
func _shotAcross() -> void:
	var r: Array = _new()
	var S: SimState = r[0]
	var q: Array = r[1]
	var A = q[0]
	var D = q[3]
	_put(D, A.x + 1500.0 * A.face, A)
	A.act.v2 = true   # (the pad's path: its intent's mode is read)
	var bd: Dictionary = DirBlast.data()
	var was = bd.get("enabled", false)
	bd["enabled"] = true   # the energy family's blasts (off on main)
	var hp: float = D.hp
	var ki: float = A.ki
	var made: bool = false
	for k in range(120):
		var i: SimIntent = null
		if k == 0:
			i = _x()
			i.mode = 1   # the energy family: X is a bolt
		elif k < 3:
			i = SimIntent.new()
			i.mode = 1
		_step(S, i)
		made = made or not S.stage.fights[1].shots.is_empty()
		if D.hp < hp:
			break
	print("      a bolt with his focus across, the enemy 1,500 off: made in his fight %s, he took %.0f, ki %.0f to %.0f" % [str(made), hp - D.hp, ki, A.ki])
	_expect(made and hp - D.hp > 0.0, "a blast press with his focus across fires into the other fight, and it lands there")
	bd["enabled"] = was
	SimCore.dispose(S)


## One stun a string across a team: a blow from outside holds his stick-stun from resetting for teamRestunTicks.
func _teamStun() -> void:
	var r: Array = _new()
	var S: SimState = r[0]
	var q: Array = r[1]
	var A = q[0]
	var D = q[3]
	SimStage.enter(S, 1)
	var before: bool = DirOutside.holdsStun(S, D)
	DirOutside.landed(S, A, D, {})
	var at: int = S.tick
	var held: bool = DirOutside.holdsStun(S, D)
	SimStage.enter(S, 0)
	var n: int = int(DirOutside.cfg().get("teamRestunTicks", 24))
	for _k in range(n + 2):
		_step(S)
	SimStage.enter(S, 1)
	var after: bool = DirOutside.holdsStun(S, D)
	SimStage.enter(S, 0)
	print("      before a blow from outside %s; as it lands %s; %d ticks on %s" % [str(before), str(held), S.tick - at, str(after)])
	_expect(not before and held and not after, "a blow from outside holds his stun from resetting, for teamRestunTicks only")
	SimCore.dispose(S)


## The sends that bring the fights together: after a while apart, a landing toward the other fight scores, away from it costs; not before,
## and not at two on one.
func _join() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 21, {"p1": false, "p2": false, "p3": false, "p4": false}, {"intro": false, "fights": 2, "cross": true})
	var A = S.fighters[0]
	var D = S.fighters[1]
	for _k in range(3):
		_step(S)
	var other: float = SimWrap.wrap(D.x + 20000.0)
	var gi: int = 0
	for g in S.stage.fights[1].fighters:
		g.x = SimWrap.wrap(other + 100.0 * float(gi))   # the other fight off to one side, a fifth of the way round
		gi += 1
	var toward: float = SimWrap.wrap(D.x + signf(SimWrap.sdx(D.x, other)) * 3000.0)
	var away: float = SimWrap.wrap(D.x - signf(SimWrap.sdx(D.x, other)) * 3000.0)
	var fresh: float = DirOutside.joinScore(S, A, D, toward)
	DirOutside._s(A, DirOutside.O_APART, S.tick - int(70.0 * DirData.TICKS_PER_SEC) + 1)
	var t: float = DirOutside.joinScore(S, A, D, toward)
	var w: float = DirOutside.joinScore(S, A, D, away)
	S.stage.fights[1].game.ko = {"winner": 2}
	var ko: float = DirOutside.joinScore(S, A, D, toward)
	S.stage.fights[1].game.ko = null
	print("      apart a moment: %.2f; 70 s apart: toward %.2f, away %.2f; two on one %.2f" % [fresh, t, w, ko])
	_expect(fresh == 0.0 and t > 0.0 and w < 0.0 and ko == 0.0, "after a while apart a send scores the way of the other fight; not before, not at two on one")
	SimCore.dispose(S)


## The brink's call: once a brink; and a computer partner comes, and strikes from outside on an opening.
func _brink() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 21, {"p1": true, "p2": false, "p3": false, "p4": false}, {"intro": false, "fights": 2, "cross": true})
	var q: Array = []
	for k in ["p1", "p2", "p3", "p4"]:
		for f in SimStage.bodies(S):
			if f.keys == k:
				q.append(f)
	for f in q:
		f.hp = 100000.0
	var A = q[0]
	_put(q[1], A.x - 3000.0 * A.face, A)
	_put(q[2], A.x + 6000.0 * A.face, A)
	_put(q[3], A.x + 6100.0 * A.face, A)
	for _k in range(3):
		_step(S)
	q[2].brink = true
	q[3].stunTicks = 400
	var calls: int = 0
	var started: bool = false
	var d0: float = absf(SimWrap.sdx(A.x, q[3].x))
	var hp: float = q[3].hp
	for _k in range(400):
		_step(S)
		for c in _cues:
			if String(c).begins_with("outside:start"):
				started = true
			if String(c).begins_with("brink_call"):
				calls += 1
		if hp - q[3].hp > 0.0:
			break
	print("      his partner on the brink 6,000 off: he came from %.0f to %.0f; blow from outside %s; the one who had him took %.0f" % [d0, absf(SimWrap.sdx(A.x, q[3].x)), str(started), hp - q[3].hp])
	_expect(calls == 1, "the brink's call goes once (%d)" % calls)
	_expect(absf(SimWrap.sdx(A.x, q[3].x)) < d0 * 0.5 and hp - q[3].hp > 0.0, "a computer partner comes when his partner's on the brink, and strikes from outside")
	SimCore.dispose(S)


## His fight finished: a computer winner flies to the other fight unasked; a human's press pursues across, however far.
func _winner(ai: bool) -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 21, {"p1": ai, "p2": false, "p3": false, "p4": false}, {"intro": false, "fights": 2, "cross": true})
	var q: Array = []
	for k in ["p1", "p2", "p3", "p4"]:
		for f in SimStage.bodies(S):
			if f.keys == k:
				q.append(f)
	for f in q:
		if f != q[0]:
			f.ai = null
	var A = q[0]
	_put(q[1], A.x + 80.0 * A.face, A)
	_put(q[2], A.x + 9000.0 * A.face, A)
	_put(q[3], A.x + 9100.0 * A.face, A)
	q[2].hp = 100000.0
	q[3].hp = 100000.0
	for _k in range(3):
		_step(S)
	q[1].hp = 0.0
	SimDamage.ko(S, q[1], A)   # (as cross_end_check: his fight is finished)
	for _k in range(5):
		_step(S)
	q[3].stunTicks = 600
	var d0: float = absf(SimWrap.sdx(A.x, q[3].x))
	var hp: float = q[3].hp
	var koed: bool = S.game.ko != null
	for k in range(500):
		_step(S, _x() if (not ai and k == 0) else null)
		if hp - q[3].hp > 0.0:
			break
	print("      %s winner, his fight %s: from %.0f to %.0f of the other fight; it took %.0f" % ["a computer" if ai else "a human", "finished" if koed else "NOT finished", d0, absf(SimWrap.sdx(A.x, q[3].x)), hp - q[3].hp])
	_expect(koed and hp - q[3].hp > 0.0, "%s winner goes to the other fight and strikes from outside" % ("a computer" if ai else "a human's press: his"))
	SimCore.dispose(S)

