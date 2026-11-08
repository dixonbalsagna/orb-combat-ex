extends SceneTree
## The flight strikes (docs/design/playable-build.md section 1; docs/director/pending/flight-strikes/): hold LT, point the left stick,
## press X, Y or B. godot --headless --path . --script res://sim/director/tools/flight_strike_check.gd
## - the path by the stick's bearing on the press's tick: neutral the zip, toward the line, away the parting shot, the upper half the
##   arc over, the lower half the arc under; the start cue's text is the path's word, its source the button
## - each button's tell and kind (zip_light, zip_heavy, zip_big); the price by distance; the range from contact to 12.5 bh
## - the take-back: 0 to 4 ticks after LT's press, LT held; the button first never; a paid dodge-cancel's energy and cooldown back;
##   no energy refuses with the knock and leaves LT's own move alone
## - chains: a press in the last ticks starts the next link with its tell halved, dearer and worth less; the third same path and
##   button has its full tell; a press soon after the end links too
## - counters: a timed B and a charged stick strike stop it (the striker reels, never sent); a light doesn't; a guard blocks and the
##   path completes; a dodge is a miss that leaves him open
## - where each path ends; X's, Y's and B's results; the stances' LT lane steps aside; the computer picks paths; off, the zip as it was
## Ends on the verdict line.

var failed: int = 0
var cues: Array = []
const BH: float = 75.0


func _init() -> void:
	DirZip.setFsForce(1)
	_paths()
	_buttons()
	_prices()
	_range()
	_takeBack()
	_overLunge()
	_fromBrawl()
	_refund()
	_noKi()
	_chain()
	_after()
	_counter()
	_thrown()
	_stickCounter()
	_light()
	_guard()
	_dodge()
	_ends()
	_results()
	_stances()
	_ai()
	DirZip.setFsForce(0)
	_off()
	DirZip.setFsForce(-1)
	print("FLIGHT STRIKE: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


## Two players in the air, dBh apart (the rival on the striker's +x side), dy higher; full energy and a deep health bar.
func _pair(dBh: float, dy: float = 0.0) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 31, {"p1": false, "p2": false}, {"v2": [true, true], "intro": false})
	for _k in range(5):
		_step(S, null, null)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var x0: float = A.x
	var x1: float = SimWrap.wrap(x0 + dBh * BH)
	A.y = maxf(WorldTerrain.groundY(S, x0), WorldTerrain.groundY(S, x1)) + 600.0
	D.y = A.y + dy
	D.x = x1
	for f in [A, D]:
		f.vx = 0.0
		f.vy = 0.0
		f.ki = 100.0
		f.hp = 100000.0
		f.rush = null
		f.state = "free"
		f.stunTicks = 0
	cues.clear()
	return S


func _step(S: SimState, a, b) -> void:
	for i in [a, b]:
		if i != null:
			i.dodgeHeld = (int(i.stanceMask) & 8) != 0   # the finger on LT, as the layout says it with Controls' dodgeHeld on (off, it's unread)
	SimCore.step(S, [a, b])
	for e in S.out.fx:
		if String(e.type) == "cue":
			cues.append({"kind": String(e.kind), "text": String(e.text), "src": String(e.source), "actor": int(e.actor), "amount": float(e.amount), "n": int(e.n), "k": float(e.k), "x": float(e.x), "y": float(e.y), "tick": S.tick})
	S.out.fx.clear()
	S.out.feed.clear()


## LT pressed and held with a face button on the same tick (the take-back's same tick), the stick at (mx, my).
func _press(btn: String, mx: float = 0.0, my: float = 0.0, dodge: bool = true) -> SimIntent:
	var i := SimIntent.new()
	i.stanceMask = 8
	i.dodge = dodge
	i.mx = mx
	i.my = my
	i.light = btn == "x"
	i.heavy = btn == "y"
	i.sig = btn == "b"
	return i


func _held() -> SimIntent:
	var i := SimIntent.new()
	i.stanceMask = 8
	return i


func _find(kinds: Array, actor: int = 0) -> Dictionary:
	for c in cues:
		if kinds.has(c.kind) and c.actor == actor:
			return c
	return {}


func _all(kinds: Array, actor: int = 0) -> Array:
	var out: Array = []
	for c in cues:
		if kinds.has(c.kind) and c.actor == actor:
			out.append(c)
	return out


const STARTS: Array = ["zip_light", "zip_heavy", "zip_big"]


## Runs ticks until the striker's flight strike is over (zip_end), or n ticks. Returns the zip_end cue's text.
func _run(S: SimState, n: int, d = null) -> String:
	for _k in range(n):
		_step(S, _held(), d)
		var e: Dictionary = _find(["zip_end"])
		if not e.is_empty():
			return String(e.text)
	return ""


func _paths() -> void:
	var cases: Array = [[0.0, 0.0, "zip"], [1.0, 0.0, "line"], [-1.0, 0.0, "parting"], [0.0, 1.0, "over"], [0.0, -1.0, "under"],
		[0.8, 0.6, "line"], [0.6, 0.8, "over"], [-0.8, -0.6, "parting"], [-0.6, -0.8, "under"], [0.3, 0.2, "zip"]]
	var good: int = 0
	var src: bool = true
	var seen: Array = []
	for cs in cases:
		var S := _pair(6.0)
		_step(S, _press("x", float(cs[0]), float(cs[1])), null)
		var c: Dictionary = _find(STARTS)
		seen.append(String(c.get("text", "-")))
		if not c.is_empty() and String(c.text) == String(cs[2]):
			good += 1
		src = src and String(c.get("src", "")) == "x"
		SimCore.dispose(S)
	print("      paths read: %s" % str(seen))
	_expect(good == cases.size(), "the path by the stick's bearing: neutral the zip, toward the line, away the parting shot, the halves over and under (%d of %d)" % [good, cases.size()])
	_expect(src, "the start cue's source is the button")


func _buttons() -> void:
	var want: Dictionary = {"x": ["zip_light", 6], "y": ["zip_heavy", 10], "b": ["zip_big", 14]}
	var ok: bool = true
	for b in want:
		var S := _pair(6.0)
		_step(S, _press(b), null)
		var c: Dictionary = _find(STARTS)
		print("      %s: %s, a tell of %d" % [b, String(c.get("kind", "-")), int(c.get("amount", -1))])
		ok = ok and String(c.get("kind", "")) == String(want[b][0]) and int(c.amount) == int(want[b][1]) and String(c.src) == b
		SimCore.dispose(S)
	_expect(ok, "X, Y and B: zip_light, zip_heavy and zip_big, tells of 6, 10 and 14")


func _prices() -> void:
	var cases: Array = [["x", 3.0, 10.0], ["x", 12.5, 20.0], ["x", 7.75, 15.0], ["y", 12.5, 25.0], ["b", 12.5, 30.0], ["b", 2.0, 20.0]]
	var ok: bool = true
	for cs in cases:
		var S := _pair(float(cs[1]))
		var k0: float = S.fighters[0].ki
		_step(S, _press(String(cs[0])), null)
		var paid: float = k0 - S.fighters[0].ki
		print("      %s at %.2f bh: paid %.2f (want %.1f, less a tick's regen)" % [cs[0], cs[1], paid, cs[2]])
		ok = ok and not _find(STARTS).is_empty() and absf(paid - float(cs[2])) < 0.5
		SimCore.dispose(S)
	_expect(ok, "the price: X 10, Y 15, B 20, plus up to 10 rising from 3 bh to 12.5 bh")


func _range() -> void:
	var S := _pair(13.0)
	_step(S, _press("x"), null)
	var far: bool = _find(STARTS).is_empty()
	SimCore.dispose(S)
	S = _pair(1.0)
	_step(S, _press("x"), null)
	var near: bool = not _find(STARTS).is_empty()
	SimCore.dispose(S)
	_expect(far and near, "the range: at 1 bh it starts, at 13 bh it doesn't (today's long strike)")


func _takeBack() -> void:
	var res: Array = []
	for gap in [0, 4, 5]:
		var S := _pair(6.0)
		var lt := SimIntent.new()
		lt.stanceMask = 8
		lt.dodge = true
		if gap == 0:
			_step(S, _press("x"), null)
		else:
			_step(S, lt, null)
			for _k in range(gap - 1):
				_step(S, _held(), null)
			_step(S, _press("x", 0.0, 0.0, false), null)
		res.append(not _find(STARTS).is_empty())
		SimCore.dispose(S)
	# the button first, LT a tick later
	var S2 := _pair(6.0)
	var x := SimIntent.new()
	x.light = true
	_step(S2, x, null)
	var lt2 := SimIntent.new()
	lt2.stanceMask = 8
	lt2.dodge = true
	_step(S2, lt2, null)
	var first: bool = _find(STARTS).is_empty()
	SimCore.dispose(S2)
	# LT let go before the face press
	var S3 := _pair(6.0)
	var lt3 := SimIntent.new()
	lt3.stanceMask = 8
	lt3.dodge = true
	_step(S3, lt3, null)
	var x3 := SimIntent.new()
	x3.light = true
	_step(S3, x3, null)
	var letGo: bool = _find(STARTS).is_empty()
	SimCore.dispose(S3)
	print("      same tick %s, 4 ticks %s, 5 ticks %s" % [str(res[0]), str(res[1]), str(res[2])])
	_expect(res[0] and res[1] and not res[2], "the take-back: the same tick and 4 ticks after LT's press convert, 5 doesn't")
	_expect(first and letGo, "the button first never converts, nor a press with LT already let go")


## LT and X on one tick while his own lunge flies: LT is read first, so the lunge is called off and the flight strike starts.
func _overLunge() -> void:
	var S := _pair(6.0)
	var A = S.fighters[0]
	var x := SimIntent.new()
	x.light = true
	_step(S, x, null)
	for _k in range(3):
		if DirBands.pending(A):
			break
		_step(S, null, null)
	var was: bool = DirBands.pending(A)
	_step(S, _press("x"), null)
	var ok: bool = was and not _find(STARTS).is_empty() and _find(["press_refused"]).is_empty()
	print("      a lunge in flight %s; LT and X on one tick started %s" % [str(was), str(not _find(STARTS).is_empty())])
	_expect(ok, "LT and a face button on one tick during his own lunge: LT calls it off first, and the flight strike starts")
	SimCore.dispose(S)


## A brawl at contact, his line free: [S, true when one started].
func _brawl() -> Array:
	var S := _pair(0.9)
	var A = S.fighters[0]
	for k in range(120):
		var i := SimIntent.new()
		i.light = k % 12 == 0 and S.dirS.ex == null
		_step(S, i, null)
		if DirBrawl.isBrawl(S.dirS.ex) and DirBrawl._free(S, A) and k > 20:
			return [S, true]
	return [S, false]


## In a brawl (section 1: the flight strikes replace the stances' LT lane, from contact): LT and X on one tick, his line free, end the
## brawl (brawl_end flight) and start a flight strike; LT held with no fresh LT press is the brawl's blow; no energy is refused, and the
## brawl goes on.
func _fromBrawl() -> void:
	var r: Array = _brawl()
	var S: SimState = r[0]
	var A = S.fighters[0]
	cues.clear()
	_step(S, _press("x", 1.0, 0.0), null)
	var ended: String = String(_find(["brawl_end"]).get("text", ""))
	var started: Dictionary = _find(STARTS)
	var go: bool = bool(r[1]) and ended == "flight" and String(started.get("text", "")) == "line" and S.dirS.ex == null
	SimCore.dispose(S)
	r = _brawl()
	S = r[0]
	A = S.fighters[0]
	for _k in range(8):
		_step(S, _held(), null)
	cues.clear()
	var held := _held()
	held.light = true
	_step(S, held, null)
	var stays: bool = bool(r[1]) and _find(STARTS).is_empty() and DirBrawl.isBrawl(S.dirS.ex)
	SimCore.dispose(S)
	r = _brawl()
	S = r[0]
	A = S.fighters[0]
	A.ki = 3.0
	cues.clear()
	_step(S, _press("x"), null)
	var poor: bool = bool(r[1]) and String(_find(["press_refused"]).get("text", "")) == "ki" and _find(STARTS).is_empty() and DirBrawl.isBrawl(S.dirS.ex)
	SimCore.dispose(S)
	print("      from a brawl: started %s (the brawl ended %s); LT held with no fresh press stays a blow %s; no energy refused %s" % [str(go), ended, str(stays), str(poor)])
	_expect(go, "in a brawl, LT and X on one tick end it (brawl_end flight) and start the flight strike")
	_expect(stays and poor, "in a brawl, LT held with no fresh LT press is the brawl's blow, and no energy is refused while the brawl goes on")


func _refund() -> void:
	var S := _pair(6.0)
	var A = S.fighters[0]
	var dc: Dictionary = DirInterrupt.data().dodgeCancel
	A.ki = 50.0
	A.act.dodgeTick = S.tick
	A.act.dodgeCool = int(dc.cooldownTicks)   # as a paid dodge-cancel leaves it
	var price: float = 10.0 + 10.0 * (3.0 / 9.5)
	_step(S, _press("x", 0.0, 0.0, false), null)
	var tb: Dictionary = _find(["take_back"])
	var ki: float = A.ki
	print("      ki 50 -> %.2f (want about %.2f), cooldown %d, take_back %s" % [ki, 50.0 + float(dc.ki) - price, A.act.dodgeCool, String(tb.get("text", "-"))])
	_expect(not _find(STARTS).is_empty() and absf(ki - (50.0 + float(dc.ki) - price)) < 0.5 and A.act.dodgeCool == 0 and A.act.dodgeTick < -1000 and String(tb.get("text", "")) == "cancel",
		"the take-back of a paid dodge-cancel gives its 15 ki and its cooldown back, and ends the slip's protection")
	SimCore.dispose(S)


func _noKi() -> void:
	var S := _pair(6.0)
	var A = S.fighters[0]
	A.ki = 5.0
	_step(S, _press("x"), null)
	var r: Dictionary = _find(["press_refused"])
	var none: bool = _find(STARTS).is_empty()
	var slip: bool = A.act.dodgeTick > 0
	_expect(none and String(r.get("text", "")) == "ki" and String(r.get("src", "")) == "x" and slip, "no energy: press_refused ki (the knock), nothing starts, and LT's slip carries on")
	SimCore.dispose(S)


## A chain of zips on X: a press kept in the last ticks starts each next link.
func _chain() -> void:
	var S := _pair(6.0)
	var A = S.fighters[0]
	_step(S, _press("x"), null)
	var kiAt: Array = []
	for _k in range(240):
		var i := _held()
		i.light = S.tick % 2 == 0
		var k0: float = A.ki
		var n0: int = _all(STARTS).size()
		_step(S, i, null)
		if _all(STARTS).size() > n0:
			kiAt.append(k0 - A.ki)
		if _all(STARTS).size() >= 4:
			break
	var st: Array = _all(STARTS)
	var tells: Array = []
	var links: Array = []
	for c in st:
		tells.append(int(c.amount))
		links.append(int(c.k))
	print("      links %s, tells %s, prices of links 1 to 3 %s" % [str(links), str(tells), str(kiAt)])
	_expect(st.size() >= 4 and links == [0, 1, 2, 3], "a press in a flight strike's last ticks starts the next link as it ends")
	_expect(tells.size() >= 4 and tells[1] == 4 and tells[2] == 6 and tells[3] == 4, "a link's tell is halved (at least 4), and the third same path and button has its full tell")
	_expect(kiAt.size() >= 2 and absf(kiAt[1] / maxf(0.01, kiAt[0]) - 1.5) < 0.05, "each link costs 1.5 times the one before")
	SimCore.dispose(S)
	# its worth: the blow's damage at link 0 and link 1
	var dm: Array = []
	S = _pair(6.0)
	_step(S, _press("x"), null)
	for _k in range(240):
		var i := _held()
		i.light = S.tick % 2 == 0 and DirZip._left(S.fighters[0]) <= 12
		_step(S, i, null)
		var ex = S.dirS.ex
		if ex != null and DirBrawl.quiet(ex):
			for b in ex.beats:
				if not b.done and b.args != null and b.args.get("zip", false) and not b.args.has("_seen"):
					b.args["_seen"] = true
					dm.append(float(b.args.dmg))
		if dm.size() >= 2:
			break
	print("      X's blow: %s (2.5 light units is %.2f)" % [str(dm), 2.5 * DirBrawl._unit()])
	_expect(dm.size() >= 2 and absf(dm[0] - 2.5 * DirBrawl._unit()) < 0.01 and absf(dm[1] / dm[0] - 0.85) < 0.001, "X is worth a medium's 2.5, and a link 0.85 of it")
	SimCore.dispose(S)


func _after() -> void:
	var S := _pair(6.0)
	_step(S, _press("x"), null)
	var end: String = _run(S, 120)
	for _k in range(5):
		_step(S, _held(), null)
	var n0: int = _all(STARTS).size()
	var i := _held()
	i.light = true
	_step(S, i, null)
	var st: Array = _all(STARTS)
	var linked: bool = st.size() == n0 + 1 and int(st[st.size() - 1].k) == 1
	SimCore.dispose(S)
	S = _pair(6.0)
	_step(S, _press("x"), null)
	_run(S, 120)
	for _k in range(15):
		_step(S, _held(), null)
	n0 = _all(STARTS).size()
	var j := _held()
	j.light = true
	_step(S, j, null)
	var late: bool = _all(STARTS).size() == n0
	SimCore.dispose(S)
	_expect(end == "done" and linked and late, "a press 6 ticks after a flight strike ends links; 16 ticks after, with no LT press, it's the button's own blow")


## B at 12 bh: the rival's B, pressed a tick into its tell, lands in the counter's window.
func _counter() -> void:
	var S := _pair(12.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	_step(S, _press("b"), null)
	for _k in range(40):
		if DirZip._g(A, DirZip.PH) == 2 and DirZip._g(A, DirZip.LEFT) <= 2:
			break   # it arrives on the next tick (its rush ends a tick before its count does)
		_step(S, _held(), null)
	DirZip._s(D, DirZip.ANS_W, 3)   # a B pressed so that its wind-up ends two ticks after the arrival
	DirZip._s(D, DirZip.ANS_AT, S.tick + 1 + 2 - int(DirBrawl.cfg().heavy.windupTicks))
	var dmg: float = -1.0
	var reel: bool = false
	var why: String = ""
	for _k in range(80):
		_step(S, _held(), null)
		var ex = S.dirS.ex
		if ex != null:
			for b in ex.beats:
				if b.args != null and String(b.args.get("counter", "")) == "flight":
					dmg = float(b.args.dmg)
		var e: Dictionary = _find(["zip_end"])
		if not e.is_empty() and why == "":
			why = String(e.text)
			reel = DirBrawl._g(A, DirBrawl.REEL_AT) > DirBrawl._now(S)
		if why != "" and _k > 30:
			break
	print("      ended %s; the counter's blow %.2f (want %.2f); reeling %s; state %s" % [why, dmg, DirBrawl.cfg().heavy.worth * DirBrawl._unit() * 1.25, str(reel), A.state])
	_expect(why == "countered" and absf(dmg - float(DirBrawl.cfg().heavy.worth) * DirBrawl._unit() * 1.25) < 0.01 and reel and A.state != "launched" and A.state != "down",
		"a B timed to land at its arrival stops it: the striker takes 1.25 of it and reels, never sent")
	SimCore.dispose(S)
	# A real B, pressed a tick into a B flight strike's tell at 12.5 bh: the latest it can be pressed and still land in the window
	S = _pair(12.4)
	_step(S, _press("b"), null)
	var bb := SimIntent.new()
	bb.sig = true
	_step(S, _held(), bb)
	var w2: String = _run(S, 80)
	print("      (a real B pressed a tick into a B flight strike's tell at 12.4 bh: %s; B's wind-up is %d ticks)" % [w2, int(DirBrawl.cfg().heavy.windupTicks)])
	SimCore.dispose(S)


## A B thrown in the window (re-ruled 2026-11-07): its wind-up starting 3 ticks before an X's arrival meets him as he arrives; one thrown in
## the ticks in reach before a Y's blow stops him at once. Both reel him and send nothing.
func _thrown() -> void:
	var S := _pair(6.0)
	var A = S.fighters[0]
	_step(S, _press("x"), null)
	for _k in range(40):
		if DirZip._g(A, DirZip.PH) == 2 and DirZip._g(A, DirZip.LEFT) <= 3:
			break
		_step(S, _held(), null)
	var bb := SimIntent.new()
	bb.sig = true
	_step(S, _held(), bb)
	var w1: String = _run(S, 30)
	var r1: bool = A.state != "launched" and A.state != "down"
	SimCore.dispose(S)
	S = _pair(6.0)
	A = S.fighters[0]
	_step(S, _press("y"), null)
	for _k in range(40):
		if DirZip._g(A, DirZip.PH) == 3:
			break
		_step(S, _held(), null)
	var at: int = S.tick
	var b2 := SimIntent.new()
	b2.sig = true
	_step(S, _held(), b2)
	var w2: String = ""
	var t2: int = -1
	for _k in range(10):
		var e: Dictionary = _find(["zip_end"])
		if not e.is_empty():
			w2 = String(e.text)
			t2 = int(e.tick) - at
			break
		_step(S, _held(), null)
	var reel: bool = DirBrawl._g(A, DirBrawl.REEL_AT) > DirBrawl._now(S) and A.state != "launched" and A.state != "down"
	SimCore.dispose(S)
	print("      a B thrown 3 ticks before an X arrives: %s; a B thrown in a Y's reach: %s %d ticks later, reeling %s" % [w1, w2, t2, str(reel)])
	_expect(w1 == "countered" and r1, "a B whose wind-up starts in the window before the arrival counters, and sends nothing")
	_expect(w2 == "countered" and t2 >= 0 and t2 <= 3 and reel, "a B thrown in the ticks in reach before his blow stops him at once, and he reels")


func _stickCounter() -> void:
	DirStick.setForce(1)
	var S := _pair(6.0)
	var D = S.fighters[1]
	_step(S, _press("y"), null)
	var why: String = ""
	for k in range(60):
		var di := SimIntent.new()
		if k >= 6:
			di.rsHeld = true
		if k == 6:
			DirStick._s(D, DirStick.ST_PEND, 1 | (1 << 3))
			DirStick._s(D, DirStick.ST_AT, DirBrawl._now(S) - 30)
			DirStick._s(D, DirStick.ST_PAT, DirBrawl._now(S))
		_step(S, _held(), di)
		var e: Dictionary = _find(["zip_end"])
		if not e.is_empty():
			why = String(e.text)
			break
	DirStick.setForce(-1)
	print("      against a charged stick strike: %s" % why)
	_expect(why == "countered", "a charged stick strike stops it")
	SimCore.dispose(S)


## X: the rival's light two ticks before its arrival doesn't stop it.
func _light() -> void:
	var S := _pair(6.0)
	var D = S.fighters[1]
	var hp0: float = D.hp
	_step(S, _press("x"), null)
	var ends: Array = []
	for k in range(60):
		var di := SimIntent.new()
		di.light = k == 5
		_step(S, _held(), di)
	for c in _all(["zip_end"]):
		ends.append(String(c.text))
	print("      ends %s; the rival lost %.1f" % [str(ends), hp0 - D.hp])
	_expect(ends.size() >= 1 and ends[0] == "done" and hp0 - D.hp > 2.0 * DirBrawl._unit(), "a light doesn't stop it: his blow lands and the path completes")
	SimCore.dispose(S)


func _guard() -> void:
	var S := _pair(6.0)
	var D = S.fighters[1]
	_step(S, _press("x"), null)
	var g := SimIntent.new()
	g.guard = true
	var end: String = _run(S, 80, g)
	var stun: int = D.stunTicks
	print("      against a guard: %s, rival stunned %d" % [end, stun])
	_expect(end == "done", "a guard blocks the blow, and the path completes")
	SimCore.dispose(S)


func _dodge() -> void:
	var S := _pair(6.0)
	var A = S.fighters[0]
	_step(S, _press("x"), null)
	var why: String = ""
	var at: int = -1
	for k in range(40):
		var di := SimIntent.new()
		di.dodge = k == 4
		_step(S, _held(), di)
		var e: Dictionary = _find(["zip_end"])
		if not e.is_empty():
			why = String(e.text)
			at = S.tick
			break
	var openAt: int = DirZip._g(A, DirZip.F_OPEN)
	_step(S, _press("x"), null)
	var refused: bool = String(_find(["press_ack"]).get("text", "")) == "open" and _all(STARTS).size() == 1
	for _k in range(24):
		_step(S, _held(), null)
	cues.clear()
	_step(S, _press("x"), null)
	var again: bool = not _find(STARTS).is_empty()
	SimCore.dispose(S)
	# the latest press held through the opening is thrown as it ends (the brawl's held-press rule)
	S = _pair(6.0)
	A = S.fighters[0]
	_step(S, _press("x"), null)
	for k in range(40):
		var di := SimIntent.new()
		di.dodge = k == 4
		_step(S, _held(), di)
		if not _find(["zip_end"]).is_empty():
			break
	var openEnd: int = DirZip._g(A, DirZip.F_OPEN)
	while S.tick < openEnd - 5:
		_step(S, SimIntent.new(), null)
	var xp := SimIntent.new()
	xp.light = true
	_step(S, xp, null)
	cues.clear()
	var thrownAt: int = -1
	for _k in range(12):
		_step(S, SimIntent.new(), null)
		for c in cues:
			if c.actor == 0 and (String(c.kind).begins_with("lunge") or (String(c.kind) == "press_ack" and (String(c.text) == "started" or String(c.text) == "queued"))):
				thrownAt = int(c.tick)
		if thrownAt >= 0:
			break
	var held: bool = thrownAt >= openEnd and thrownAt <= openEnd + 1
	print("      ended %s, open for %d ticks; a press then refused %s; after it %s; a press held through it thrown at its end %s" % [why, openAt - at, str(refused), str(again), str(held)])
	_expect(why == "missed" and openAt - at == 20 and refused and again and held, "a dodge makes it a miss: he's open for 20 ticks, his presses wait, and the latest is thrown as it ends")
	SimCore.dispose(S)


## Where each path ends, and an arc's blow at the top (or the bottom) of its loop.
func _ends() -> void:
	var cases: Array = [["line", 1.0, 0.0], ["over", 0.0, 1.0], ["under", 0.0, -1.0], ["parting", -1.0, 0.0], ["zip", 0.0, 0.0]]
	for cs in cases:
		var S := _pair(6.0)
		var A = S.fighters[0]
		var D = S.fighters[1]
		var ax0: float = A.x
		var ay0: float = A.y
		_step(S, _press("x", float(cs[1]), float(cs[2])), null)
		var blowDy: float = -9999.0
		var outD: Array = []
		var end: String = ""
		for _k in range(120):
			var st0: int = DirZip._g(A, DirZip.STATE)
			_step(S, _held(), null)
			if st0 == 0 and DirZip._g(A, DirZip.STATE) == 1 and blowDy < -9000.0:
				blowDy = A.y - D.y
			var o: Dictionary = _find(["zip_out"])
			if not o.is_empty() and outD.is_empty():
				outD = [D.x, D.y, o.x, o.y]
			var e: Dictionary = _find(["zip_end"])
			if not e.is_empty():
				end = String(e.text)
				break
		var side1: float = signf(SimWrap.sdx(D.x, A.x))
		var p: String = String(cs[0])
		var ok: bool = end == "done"
		var note: String = ""
		if p == "line":
			var past: float = absf(SimWrap.sdx(float(outD[0]), float(outD[2]))) / BH
			ok = ok and side1 > 0.0 and absf(past - 1.5) < 0.05 and absf(SimWrap.sdx(A.x, float(outD[2]))) < 2.0
			note = "%.2f bh past him, his other side" % past
		elif p == "over" or p == "under":
			ok = ok and side1 > 0.0 and absf((A.y - D.y) / BH - 0.5) < 0.35 and (blowDy > 1.0 * BH if p == "over" else blowDy < 0.0)
			note = "the blow %.2f bh %s him; ends %.2f bh up behind him" % [absf(blowDy) / BH, "over" if blowDy > 0.0 else "under", (A.y - D.y) / BH]
		elif p == "parting":
			var far: float = SimDetMath.hypot(SimWrap.sdx(float(outD[0]), float(outD[2])), float(outD[3]) - float(outD[1])) / BH
			ok = ok and side1 < 0.0 and absf(far - 9.0) < 0.1
			note = "%.2f bh out (6 + 3)" % far
		else:
			ok = ok and absf(SimWrap.sdx(ax0, A.x)) < 2.0 and absf(A.y - ay0) < 2.0
			note = "back where he started"
		print("      %s: %s, %s" % [p, end, note])
		_expect(ok, "the %s ends where it should" % p)
		SimCore.dispose(S)


func _results() -> void:
	var res: Dictionary = {}
	for b in ["x", "y", "b"]:
		var S := _pair(6.0)
		var D = S.fighters[1]
		_step(S, _press(b), null)
		var stun: int = 0
		var reel: bool = false
		for _k in range(60):
			_step(S, _held(), null)
			stun = maxi(stun, D.stunTicks)
			reel = reel or DirBrawl._g(D, DirBrawl.REEL_AT) > DirBrawl._now(S)
		res[b] = [stun, reel, D.state]
		SimCore.dispose(S)
	print("      the rival after X %s, Y %s, B %s (most stun, reeled, state)" % [str(res.x), str(res.y), str(res.b)])
	_expect(res.x[1] and res.x[0] == 0, "X reels him")
	_expect(res.y[0] >= 12 and res.b[0] >= int(DirBrawl.cfg().heavy.staggerTicks) and res.b[2] != "launched", "Y staggers him; B staggers him by the one rule for B, never a send")


func _stances() -> void:
	DirStick.setForce(1)
	DirStance.setForce(1)
	var S := _pair(1.0)
	var A = S.fighters[0]
	A.input.stanceMask = DirStick.LT
	var a1: Dictionary = {}
	DirStance.note(A, a1, 0)
	DirZip.setFsForce(0)
	var a2: Dictionary = {}
	DirStance.note(A, a2, 0)
	DirZip.setFsForce(1)
	DirStance.setForce(-1)
	DirStick.setForce(-1)
	_expect(not a1.has("stanceBlow") and int(a2.get("stanceBlow", 0)) == DirStance.STEP, "with flight strikes on, LT + X in a brawl isn't the step strike (off, it is)")
	SimCore.dispose(S)


## The computer's pick (DirZip.aiUse, at its level's zipShare forced to every beat): one draw over the paths, and its press starts
## the flight strike on that path.
## The computer's own (playable-build.md section 1, ruled 2026-11-07): one keyed draw a chance at its level's flightShare; buttons by ai.buttons
## (B among them), paths by ai.paths; a rival who's pressing doesn't stop it in the middle band; never a press it can't pay for with ai.kiReserve
## kept back; from a brawl when the rival has guarded (the line or an arc) or it's losing the run; the parting shot when it wants out; a chain
## link only with the next one and the reserve in hand.
func _ai() -> void:
	var S := _pair(6.0)
	var A = S.fighters[0]
	var D = S.fighters[1]
	A.ai = SimState.AiState.new()
	var lv: Dictionary = DirAI.lv()
	var keep = lv.get("flightShare", null)
	lv["flightShare"] = 1.0
	var picks: Dictionary = {}
	var btns: Dictionary = {}
	for k in range(300):
		var i := SimIntent.new()
		if DirZip._aiFly(S, A, D, i, -1, "check.ai", k):
			var p: int = DirZip._g(A, DirZip.AI_EXIT) - 1
			picks[DirZip.PATHS[p]] = int(picks.get(DirZip.PATHS[p], 0)) + 1
			var b: String = "b" if i.sig else ("y" if i.heavy else "x")
			btns[b] = int(btns.get(b, 0)) + 1
	print("      the computer's picks over 300 chances: paths %s, buttons %s" % [str(picks), str(btns)])
	_expect(picks.size() == 5 and btns.size() == 3 and int(btns.get("b", 0)) > 30 and int(btns.get("x", 0)) > int(btns.get("y", 0)), "the computer picks every path, and every button, B included (about half X, 30% Y, 20% B)")
	# a rival who's pressing doesn't stop it, and its press flies the path it picked
	D.lastAtkT = S.T
	var i2 := SimIntent.new()
	i2.mode = 0
	i2.light = true
	var went: bool = DirZip.aiUse(S, A, D, i2)
	var want: String = DirZip.PATHS[DirZip._g(A, DirZip.AI_EXIT) - 1] if went else "-"
	SimIntent.applyIntent(A.input, i2)
	var kind: String = "sig" if i2.sig else ("heavy" if i2.heavy else "light")
	DirZip.takes(S, A, kind)
	var last: String = ""
	for e in S.out.fx:
		if String(e.type) == "cue" and STARTS.has(String(e.kind)):
			last = String(e.text)
	_expect(went and last == want, "at a rival who's pressing it still flies one, on the path it picked (%s)" % last)
	SimCore.dispose(S)
	# never a press it can't pay for: with too little ki it presses nothing
	S = _pair(6.0)
	A = S.fighters[0]
	D = S.fighters[1]
	A.ai = SimState.AiState.new()
	A.ki = 25.0   # X at 6 bh is 13.2, and the reserve is 20
	var i3 := SimIntent.new()
	var poor: bool = not DirZip._aiFly(S, A, D, i3, -1, "check.ai", 1)
	A.ki = 36.0   # X is in hand, Y (18.2 + 20) and B (23.2 + 20) aren't: a dearer pick gives way to X
	var xs: bool = true
	for k in range(40):
		var i4 := SimIntent.new()
		if DirZip._aiFly(S, A, D, i4, -1, "check.ai", k):
			xs = xs and i4.light and not i4.heavy and not i4.sig
	_expect(poor and xs, "never a press it can't pay for with its 20 ki kept back; a dearer button gives way to one it can")
	SimCore.dispose(S)
	# from a brawl: round a guard (the line or an arc), and the parting shot when it wants out
	var r: Array = _brawl()
	S = r[0]
	A = S.fighters[0]
	D = S.fighters[1]
	D.ai = SimState.AiState.new()
	S.tick += 100   # (a match old enough for a guard of 70 ticks)
	A.act.guardSince = S.tick - 70
	A.input.guard = true
	A.stance = 1.0
	var i5 := SimIntent.new()
	var g: bool = DirZip.aiBrawl(S, D, i5, 0)
	var gp: String = DirZip.PATHS[DirZip._g(D, DirZip.AI_EXIT) - 1] if g else "-"
	A.act.guardSince = -1
	A.stance = 0.0
	DirBrawl._s(A, DirBrawl.RUN, 0)
	DirBrawl._s(D, DirBrawl.RUN, 0)
	var i6 := SimIntent.new()
	var calm: bool = not DirZip.aiBrawl(S, D, i6, 0)
	var i7 := SimIntent.new()
	var out: bool = DirZip.aiOut(S, D, i7, S.tick)
	var op: String = DirZip.PATHS[DirZip._g(D, DirZip.AI_EXIT) - 1] if out else "-"
	print("      from a brawl: round a guard %s (%s); with no reason %s; wanting out %s (%s)" % [str(g), gp, str(not calm), str(out), op])
	_expect(bool(r[1]) and g and ["line", "over", "under"].has(gp) and calm and out and op == "parting", "from a brawl: round a guard of a second the line or an arc, nothing with no reason, and the parting shot when it wants out")
	SimCore.dispose(S)
	# a chain link only with the next link and the reserve in hand
	var ch: Array = []
	for kk in [100.0, 30.0]:
		S = _pair(6.0)
		A = S.fighters[0]
		D = S.fighters[1]
		_step(S, _press("x"), null)
		A.ai = SimState.AiState.new()
		var linked: bool = false
		for _k in range(120):
			if DirZip._g(A, DirZip.PH) >= 3 and DirZip._left(A) <= 12 and DirZip._g(A, DirZip.F_NEXT) == 0:
				A.ki = kk
				var i8 := SimIntent.new()
				DirZip.aiZipping(S, A, i8)
				if i8.light or i8.heavy or i8.sig:
					linked = true
				break
			_step(S, _held(), null)
		ch.append(linked)
		SimCore.dispose(S)
	if keep == null:
		lv.erase("flightShare")
	else:
		lv["flightShare"] = keep
	_expect(ch[0] and not ch[1], "a chain link only when it can pay the next link and keep 20 back (full ki %s; 30 ki %s)" % [str(ch[0]), str(ch[1])])


func _off() -> void:
	var S := _pair(6.0)
	_step(S, _press("x"), null)
	var c: Dictionary = _find(STARTS)
	var asWas: bool = String(c.get("kind", "")) == "zip_light" and String(c.get("text", "")) == "zip" and String(c.get("src", "-")) == ""
	SimCore.dispose(S)
	S = _pair(2.0)
	_step(S, _press("x"), null)
	var near: bool = _find(STARTS).is_empty()
	SimCore.dispose(S)
	_expect(asWas and near, "off: LT + X is today's zip (its cue as it was), and not inside 3 bh")
