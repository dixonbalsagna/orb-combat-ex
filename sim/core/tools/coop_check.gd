extends SceneTree
## Co-op 2v2's two switches (docs/architecture/cross-fights.md, "A match's own switches"):
##   godot --headless --path . --script res://sim/core/tools/coop_check.gd [-- --negative-control]
## - a setup's "outside" turns blows from outside on or off for its match, over interrupts.json outside.enabled, both where a
##   blow starts (DirOutside.on) and where it lands (DirOutside.landed); it does nothing in a 1v1 or with hits across off; a
##   rollback across a blow from outside it let through is the same, by hash and digest
## - 2v2's time cap and the ending's last event (cross.json timeCapAt, lastAt) are on the stage's clock, the longer of the
##   fights' clocks as a tick starts, so both fights reach them on one tick; a 1v1, and two fights with hits across off,
##   keep each fight's own 660 on its own clock; a rollback across the cap is the same
## - the picture's lists (cross-fights.md, "For the picture"): every fight's events stay for one tick, whichever fight the host
##   holds between ticks; a host holding fight 1 (NetLan's fight-1 PC) never sees one of fight 0's events twice, the intro too
## --negative-control plants three breaks (SimCross.blind 6: the stage's clock stands still; 5: the setup's "outside" is
## ignored; 7: the step clears the lists as it used to, fight 0's never), and the checks must see each.

var fails: int = 0
var negative: bool = false
var notes: Array = []
var _cues: Array = []


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func _q(S: SimState) -> Array:
	var q: Array = []
	for k in ["p1", "p2", "p3", "p4"]:
		for f in SimStage.bodies(S):
			if f.keys == k:
				q.append(f)
	return q


func _put(f, x: float, ref) -> void:
	f.x = SimWrap.wrap(x)
	f.y = ref.y
	f.z = ref.z
	f.vx = 0.0
	f.vy = 0.0


func _drain(S: SimState) -> void:
	var outs: Array = [S.out]
	if S.stage != null:
		for r in S.stage.fights:
			if r.out != null and r.out != S.out:
				outs.append(r.out)
	for o in outs:
		for e in o.fx:
			if e.type == "cue" and String(e.kind).begins_with("outside"):
				_cues.append(String(e.kind))
		o.fx.clear()
		o.feed.clear()


func _step(S: SimState, i = null) -> void:
	var ins: Array = [i if i != null else SimIntent.new(), SimIntent.new()]
	if S.stage != null:
		ins.append(SimIntent.new())
		ins.append(SimIntent.new())
	SimCore.step(S, ins)
	_drain(S)


func _x() -> SimIntent:
	var i := SimIntent.new()
	i.light = true
	return i


func _hd(S: SimState) -> String:
	return "%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)]


# ---------------------------------------------------------------- blows from outside, by the setup

## Outside_check's opening: p1 (fight 0) presses X with p4, his enemy in fight 1, stunned 140 in front of him, and p2, his own
## rival, far off. setup: the match's extra keys. Returns [the blow's damage on p4, whether it started, DirOutside.on in fight 0,
## the hash and digest of the 20 ticks after the press].
func _blow(setup: Dictionary, fights: int = 2) -> Array:
	var su: Dictionary = {"intro": false, "fights": fights, "cross": true}
	su.merge(setup, true)
	var S := SimCore.createSim()
	var keys: Dictionary = {"p1": false, "p2": false, "p3": false, "p4": false} if fights == 2 else {"p1": false, "p2": false}
	SimCore.newMatch(S, 21, keys, su)
	if S.stage == null:
		var on1: bool = DirOutside.on(S)
		SimCore.dispose(S)
		return [0.0, false, on1, []]
	var q: Array = _q(S)
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
	var D = q[3]
	D.stunTicks = 40
	var hp: float = D.hp
	var on: bool = DirOutside.on(S)
	_cues = []
	var hs: Array = []
	_step(S, _x())
	hs.append(_hd(S))
	for _k in range(20):
		_step(S)
		hs.append(_hd(S))
	var out: Array = [hp - D.hp, _cues.has("outside"), on, hs]
	SimCore.dispose(S)
	return out


func _outside() -> void:
	var data: Dictionary = DirOutside.cfg()
	var was = data.get("enabled", false)
	for dataOn in [false, true]:
		data["enabled"] = dataOn
		var keyOn: Array = _blow({"outside": true})
		var keyOff: Array = _blow({"outside": false})
		var none: Array = _blow({})
		var d: String = "with interrupts.json's switch %s" % ("on" if dataOn else "off")
		ok(keyOn[2] and float(keyOn[0]) > 0.0, "the setup's \"outside\": true lets a blow from outside land, %s (%.0f)" % [d, keyOn[0]])
		ok(not keyOff[2] and float(keyOff[0]) == 0.0, "... \"outside\": false keeps it out, %s (%.0f)" % [d, keyOff[0]])
		ok(none[2] == dataOn and (float(none[0]) > 0.0) == dataOn, "... no key, and the data's switch decides, %s (%.0f)" % [d, none[0]])
		notes.append("blow from outside, %s: key on %.0f, key off %.0f, no key %.0f" % [d, keyOn[0], keyOff[0], none[0]])
	data["enabled"] = true
	var oneV: Array = _blow({"outside": true}, 1)
	ok(not oneV[2], "a 1v1 with \"outside\": true and the data on has no blows from outside")
	var crossOff: Array = _blow({"outside": true, "cross": false})
	ok(not crossOff[2] and float(crossOff[0]) == 0.0, "two fights with hits across off and \"outside\": true have none either (%.0f)" % crossOff[0])
	data["enabled"] = was
	# The landing reads the match's key too: a blow already on its way when nothing else would let it land.
	var S := SimCore.createSim()
	SimCore.newMatch(S, 21, {"p1": false, "p2": false, "p3": false, "p4": false}, {"intro": false, "fights": 2, "cross": true, "outside": true})
	var q: Array = _q(S)
	SimStage.enter(S, 1)
	_cues = []
	DirOutside.landed(S, q[0], q[3], {})
	_drain(S)
	ok(_cues.has("outside_hit"), "a landing reads the match's key: \"outside\": true with the data off")
	SimStage.enter(S, 0)
	S.stage.outside = 0
	SimStage.enter(S, 1)
	_cues = []
	DirOutside.landed(S, q[0], q[3], {})
	_drain(S)
	ok(not _cues.has("outside_hit"), "... and \"outside\": false keeps a landing out")
	SimCore.dispose(S)
	# A rollback across a blow from outside the key let through.
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 21, {"p1": false, "p2": false, "p3": false, "p4": false}, {"intro": false, "fights": 2, "cross": true, "outside": true})
	var q2: Array = _q(S2)
	for f in q2:
		f.ai = null
		f.hp = 100000.0
		f.ki = 100.0
	var A = q2[0]
	_put(q2[1], A.x - 2400.0 * A.face, A)
	_put(q2[2], A.x + 2600.0 * A.face, A)
	_put(q2[3], A.x + 140.0 * A.face, A)
	for _k in range(3):
		_step(S2)
	q2[3].stunTicks = 40
	var snap: NetSnapshot = NetSnapshot.take(S2)
	var hp0: float = q2[3].hp
	var hs: Array = []
	_step(S2, _x())
	hs.append(_hd(S2))
	for _k in range(30):
		_step(S2)
		hs.append(_hd(S2))
	var took: float = hp0 - q2[3].hp
	NetSnapshot.restore(S2, snap)
	ok(S2.stage.outside == 1, "a restore keeps the match's key")
	var differ: int = 0
	_step(S2, _x())
	if _hd(S2) != hs[0]:
		differ += 1
	for k in range(30):
		_step(S2)
		if _hd(S2) != hs[k + 1]:
			differ += 1
	ok(took > 0.0 and differ == 0, "a rollback across a blow from outside: 31 ticks, %d differ (it took %.0f)" % [differ, took])
	SimCore.dispose(S2)


# ---------------------------------------------------------------- the time cap on the stage's clock

## A match of computer fighters, set on its clocks: t0 for fight 0's clock, t1 for fight 1's (two fights). Steps up to n
## ticks and returns [the tick fight 0 reached the cap, fight 1's, -1 for never; the stage's clock at the end].
func _cap(fights: int, cross: bool, t0: float, t1: float, n: int) -> Array:
	var S := SimCore.createSim()
	var keys: Dictionary = {"p1": true, "p2": true, "p3": true, "p4": true} if fights == 2 else {"p1": true, "p2": true}
	SimCore.newMatch(S, 9, keys, {"intro": false, "fights": fights, "cross": cross})
	S.T = t0
	if S.stage != null:
		S.stage.fights[1].T = t1
	var at: Array = [-1, -1]
	for k in range(n):
		SimCore.step(S)
		_drain(S)
		if at[0] < 0 and _game(S, 0).timeCap:
			at[0] = S.tick
		if S.stage != null and at[1] < 0 and _game(S, 1).timeCap:
			at[1] = S.tick
	var clock: float = S.stage.clock if S.stage != null else -1.0
	SimCore.dispose(S)
	return [at[0], at[1], clock]


func _game(S: SimState, i: int):
	return S.game if S.stage == null or S.stage.cur == i else S.stage.fights[i].game


func _timeCap() -> void:
	var cap: float = SimCross.timeCap()
	var last: float = SimCross.lastAt()
	ok(cap == 840.0 and last == 900.0, "2v2's time cap and last event are 14:00 and 15:00 (%.0f, %.0f)" % [cap, last])
	var one: Array = _cap(1, false, 659.95, 0.0, 20)
	ok(one[0] > 0, "a 1v1 reaches its own 660 (tick %d)" % one[0])
	var off: Array = _cap(2, false, 659.95, 500.0, 20)
	ok(off[0] > 0 and off[1] < 0, "two fights with hits across off: each on its own clock, fight 0 at 660, fight 1 not (ticks %d, %d)" % [off[0], off[1]])
	var early: Array = _cap(2, true, 700.0, 500.0, 20)
	ok(early[0] < 0 and early[1] < 0, "with hits across on, 660 isn't the cap for either (ticks %d, %d)" % [early[0], early[1]])
	var on: Array = _cap(2, true, cap - 0.05, 700.0, 20)
	ok(on[0] > 0 and on[0] == on[1], "with hits across on, both fights reach the cap on one tick of the stage's clock, fight 1 at 700 of its own (ticks %d, %d; clock %.2f)" % [on[0], on[1], on[2]])
	var behind: Array = _cap(2, true, 700.0, cap - 0.05, 20)
	ok(behind[0] > 0 and behind[0] == behind[1], "... whichever fight's clock is the longer (ticks %d, %d)" % [behind[0], behind[1]])
	notes.append("cap: 1v1 tick %d; two fights off %d, %d; on %d, %d (clock %.2f); led by fight 1 %d, %d" % [one[0], off[0], off[1], on[0], on[1], on[2], behind[0], behind[1]])
	# The ending's last event: both fights' on one tick of the stage's clock (DirEnding forced on, both already capped).
	DirEnding.setForce(1)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 9, {"p1": true, "p2": true, "p3": true, "p4": true}, {"intro": false, "fights": 2, "cross": true})
	S.T = last - 0.05
	S.stage.fights[1].T = cap + 5.0
	S.game.timeCap = true
	S.stage.fights[1].game.timeCap = true
	var at: Array = [-1, -1]
	for k in range(20):
		SimCore.step(S)
		_drain(S)
		for i in [0, 1]:
			SimStage.enter(S, i)
			if at[i] < 0 and DirEnding._g(S.fighters[0], DirEnding.E_DONE) != 0:
				at[i] = S.tick
		SimStage.enter(S, 0)
	ok(at[0] > 0 and at[0] == at[1], "the ending's last event comes to both fights on one tick of the stage's clock (ticks %d, %d)" % [at[0], at[1]])
	notes.append("last event: ticks %d, %d" % [at[0], at[1]])
	# A rollback across the cap.
	var snap: NetSnapshot = null
	SimCore.dispose(S)
	var S2 := SimCore.createSim()
	SimCore.newMatch(S2, 9, {"p1": true, "p2": true, "p3": true, "p4": true}, {"intro": false, "fights": 2, "cross": true})
	S2.T = cap - 0.1
	S2.stage.fights[1].T = 700.0
	SimCore.step(S2)
	_drain(S2)
	snap = NetSnapshot.take(S2)
	var hs: Array = []
	for k in range(30):
		SimCore.step(S2)
		_drain(S2)
		hs.append(_hd(S2))
	var capped: bool = S2.game.timeCap and S2.stage.fights[1].game.timeCap
	NetSnapshot.restore(S2, snap)
	var differ: int = 0
	for k in range(30):
		SimCore.step(S2)
		_drain(S2)
		if _hd(S2) != hs[k]:
			differ += 1
	ok(capped and differ == 0, "a rollback across the cap: 30 ticks, %d differ (both capped %s)" % [differ, str(capped)])
	SimCore.dispose(S2)
	DirEnding.setForce(-1)


# ---------------------------------------------------------------- the picture's lists

## A two-fight match of computer fighters, the host holding fight `held` between ticks as NetLan._follow does and draining its
## own list, as SimHost does. Each tick, the other fight's list is what other_events() hands the picture: none of its events
## may be one it handed before. Returns [events seen, repeats, the most at once].
func _held(held: int, intro: bool) -> Array:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 9, {"p1": true, "p2": true, "p3": true, "p4": true}, {"intro": intro, "fights": 2, "cross": true})
	var other: int = 1 - held
	var prev: Array = []
	var seen: int = 0
	var repeats: int = 0
	var most: int = 0
	for t in range(700):
		SimCore.step(S)
		SimStage.enter(S, held)
		S.out.fx.clear()
		S.out.feed.clear()
		var cur: Array = S.stage.fights[other].out.fx
		for e in cur:
			if prev.has(e):
				repeats += 1
		seen += cur.size()
		most = maxi(most, cur.size())
		prev = cur.duplicate()
	SimCore.dispose(S)
	return [seen, repeats, most]


func _lists() -> void:
	for c in [[0, false], [1, false], [1, true]]:
		var r: Array = _held(c[0], c[1])
		var w: String = "a host holding fight %d%s" % [c[0], " through the intro" if c[1] else ""]
		ok(int(r[0]) > 0 and int(r[1]) == 0, "%s: fight %d's list hands the picture each event once (%d events in 700 ticks, %d repeated, at most %d at once)" % [w, 1 - c[0], r[0], r[1], r[2]])
		notes.append("lists, %s: %d events, %d repeated, at most %d at once" % [w, r[0], r[1], r[2]])


func _run() -> void:
	if negative:
		for mode in [6, 5, 7]:
			SimCross.blind = mode
			var f0: int = fails
			print("-- planted: %s" % ["", "", "", "", "", "the setup's \"outside\" is ignored", "the stage's clock stands still", "the lists cleared as they used to be"][mode])
			if mode == 6:
				_timeCap()
			elif mode == 7:
				_lists()
			else:
				_outside()
			var seen: int = fails - f0
			fails = f0
			ok(seen > 0, "the negative control's planted break %d is seen (%d checks)" % [mode, seen])
		SimCross.blind = 0
		print("COOP negative control: %d check(s) failed" % fails)
		quit(1 if fails > 0 else 0)
		return
	_outside()
	_timeCap()
	_lists()
	for n in notes:
		print("  " + n)
	print("COOP: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	_run()
