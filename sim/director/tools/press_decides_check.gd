extends SceneTree
## Game Design's docs/design/press-decides.md, each rule behind its own switch, on an idle dummy with real presses: a released charge closes the
## gap; a press waits for the blow in hand and a hold builds while it waits, and a stun clears it; one rule for B; the circle's price and what
## stops it; the stick's steal. Off, nothing changes.
##   godot --headless --path . --script res://sim/director/tools/press_decides_check.gd
## Ends on the verdict line.

var failed: int = 0
var _cues: Array = []
var _tapped: Array = []


func _init() -> void:
	DirStick.setForce(1)
	DirStance.setForce(1)
	var b: Dictionary = DirBrawl.cfg()
	if b.has("chargeClose"):
		_close(b)
	if b.has("pressWait"):
		_wait(b)
	if b.has("oneRuleB"):
		_rule(b)
	if DirStance.cfg().has("circle"):
		_circle(DirStance.cfg())
	if DirStick.cfg().has("steal"):
		_steal(DirStick.cfg())
	if DirStick.cfg().has("pendFollow"):
		_pend(DirStick.cfg(), b)
		_swept(DirStick.cfg())
		_sweptQuiet(DirStick.cfg())
	if DirStick.cfg().has("flickRun"):
		_flickRun(DirStick.cfg())
	DirStance.setForce(-1)
	DirStick.setForce(-1)
	print("PRESS: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _pair(gap: float = 58.0, brawl: bool = true) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"intro": false})
	for f in S.fighters:
		f.ai = null
		f.act.v2 = true
		f.ki = 100.0
		f.hp = 100000.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + gap)
	S.fighters[1].y = S.fighters[0].y + 200.0
	S.fighters[0].y = S.fighters[1].y
	for _k in range(5):
		_step(S)
	if brawl:
		_tap(S, _press(true, false, false))
		for _k in range(30):
			_step(S)
	return S


func _step(S: SimState, a: SimIntent = null, d: SimIntent = null) -> bool:
	_cues = []
	var live: bool = SimCore.step(S, [a if a != null else SimIntent.new(), d if d != null else SimIntent.new()])
	for e in S.out.fx:
		if e.type == "cue":
			_cues.append(String(e.kind) + ":" + String(e.text))
			if String(e.kind) == "stick_refused" and int(e.actor) == 0:
				_cues.append("refused/" + String(e.get("source")))
			if String(e.kind) == "stick_release" and int(e.actor) == 0:
				_cues.append("rlevel/" + String(e.get("source")))
		elif e.type == "launch_plan":
			_cues.append("send:" + String(e.chosen))
	S.out.fx.clear()
	S.out.feed.clear()
	return live


func _tap(S: SimState, i: SimIntent, d: SimIntent = null) -> void:
	for _k in range(30):
		if _step(S, i, d):
			_tapped = _cues.duplicate()
			return


func _press(light: bool, heavy: bool, sig: bool, mask: int = 0) -> SimIntent:
	var i := SimIntent.new()
	i.light = light
	i.heavy = heavy
	i.sig = sig
	i.stanceMask = mask
	return i


func _sent(list: Array) -> String:
	for c in list:
		if String(c).begins_with("send:"):
			return String(c).substr(5)
	return ""


## Holds B for `hold` ticks, the rival stepping back if `walk`, then lets go. Returns [what was sent, whether it missed, damage].
func _charge(S: SimState, hold: int, walk: bool) -> Array:
	var A = S.fighters[0]
	var D = S.fighters[1]
	var away: float = signf(SimWrap.sdx(A.x, D.x))
	var first := _press(false, false, true)
	first.sigHeld = true
	_tap(S, first)
	var hp: float = D.hp
	for _k in range(hold):
		var h := SimIntent.new()
		h.sigHeld = true
		var m := SimIntent.new()
		if walk:
			m.mx = away
		_step(S, h, m)
	var sent: String = ""
	var missed: bool = false
	for _k in range(30):
		var m2 := SimIntent.new()
		if walk:
			m2.mx = away
		_step(S, null, m2)
		missed = missed or _cues.has("miss:gave_ground") or _cues.has("miss:reach")
		if sent == "":
			sent = _sent(_cues)
	return [sent, missed, hp - D.hp]


## (2) A released charge, at a rival stepping back: off it can miss; on, it closes up to 3 bh past the first flash and 6 at the full flash.
func _close(b: Dictionary) -> void:
	for on_ in [false, true]:
		b.chargeClose.enabled = on_
		for hold in [36, 46]:
			var S := _pair()
			var r: Array = _charge(S, hold, true)
			print("      charge close %s, held %d, rival stepping back: sent '%s', missed %s, %.0f taken" % [str(on_), hold, r[0], str(r[1]), r[2]])
			if on_:
				_expect(not bool(r[1]) and float(r[2]) > 0.0, "charge close on, held %d: it reaches him" % hold)
			SimCore.dispose(S)
	# Too far: past fullBh it doesn't fly.
	b.chargeClose.enabled = true
	var S2 := _pair()
	S2.fighters[1].x = SimWrap.wrap(S2.fighters[0].x + 58.0 + 8.0 * DirInterrupt.BH)
	var r2: Array = _charge(S2, 46, false)
	print("      8 bh away: sent '%s', %.0f taken" % [r2[0], r2[2]])
	_expect(float(r2[2]) == 0.0, "past fullBh it doesn't travel to him")
	SimCore.dispose(S2)
	b.chargeClose.enabled = false


## (3) and (5): a press waits for the blow in hand, and a hold builds while it waits; a stun clears it, and a press in a stun is told.
func _wait(b: Dictionary) -> void:
	for on_ in [false, true]:
		b.pressWait.enabled = on_
		var S := _pair()
		var y := _press(false, true, false)
		y.heavyHeld = true
		_tap(S, y)
		var first := _press(false, false, true)
		first.sigHeld = true
		first.heavyHeld = true
		_tap(S, first)
		var lapsed: bool = false
		var full: int = -1
		for k in range(80):
			var h := SimIntent.new()
			h.sigHeld = true
			h.heavyHeld = k < 13
			_step(S, h)
			lapsed = lapsed or _cues.has("press_ack:lapsed")
			if full < 0 and _cues.has("charge_full:"):
				full = k + 1
		print("      press wait %s: B held from during Y's wind-up: lapsed %s, full charge %d ticks after the B" % [str(on_), str(lapsed), full])
		if on_:
			_expect(not lapsed and full > 0 and full <= 48, "press wait on: the hold built since the press, so the flash comes on time (%d)" % full)
		else:
			_expect(lapsed and full < 0, "press wait off: the press lapses and the hold comes to nothing")
		SimCore.dispose(S)
	b.pressWait.enabled = true
	# A stun clears the waiting press, and says so.
	var S2 := _pair()
	var A2 = S2.fighters[0]
	var y2 := _press(false, true, false)
	y2.heavyHeld = true
	_tap(S2, y2)
	_tap(S2, _press(false, false, true))
	A2.stunTicks = 10
	var told: bool = false
	var heavies: int = 0
	for _k in range(40):
		_step(S2)
		told = told or _cues.has("press_ack:stunned")
		if _cues.has("blow:heavy"):
			heavies += 1
	_expect(told and heavies == 0, "a stun clears the waiting press, and says so")
	SimCore.dispose(S2)
	# A press in a stun is told.
	var S3 := _pair()
	S3.fighters[0].stunTicks = 8
	_step(S3, _press(false, true, false))
	_expect(_cues.has("press_ack:stunned"), "a press in a stun is told, not silent")
	SimCore.dispose(S3)
	b.pressWait.enabled = false


## (1) One rule for B.
func _rule(b: Dictionary) -> void:
	b.oneRuleB.enabled = true
	var S := _pair()
	_tap(S, _press(false, false, true))
	var said: Array = []
	for _k in range(40):
		_step(S)
		said.append_array(_cues)
	_expect(said.has("stagger:heavy") and _sent(said) == "", "a tapped B in a brawl is a stagger (%s)" % str(said.filter(func(c): return String(c).begins_with("stagger") or String(c).begins_with("send") or String(c).begins_with("recoil"))))
	SimCore.dispose(S)
	var S2 := _pair(160.0, false)
	_tap(S2, _press(false, false, true))
	var said2: Array = []
	for _k in range(80):
		_step(S2)
		said2.append_array(_cues)
	var sent2: String = _sent(said2)
	print("      a tapped B starting an exchange from 160: sent '%s', his stun %d" % [sent2, S2.fighters[1].stunTicks])
	_expect(sent2 != "KNOCK BACK", "a tapped B starting an exchange isn't a knock-back")
	SimCore.dispose(S2)
	for row in [[36, "KNOCK BACK"], [46, ""]]:
		var S3 := _pair()
		var r: Array = _charge(S3, int(row[0]), false)
		print("      held %d: sent '%s'" % [row[0], r[0]])
		if String(row[1]) == "KNOCK BACK":
			_expect(r[0] == "KNOCK BACK", "past the first flash: a knock-back")
		else:
			_expect(r[0] != "" and r[0] != "KNOCK BACK", "the full flash: a send (%s)" % r[0])
		SimCore.dispose(S3)
	b.oneRuleB.enabled = false


## (4) The circle: 10 ki, x1.5 inside 3 s; a light doesn't stop it.
func _circle(st: Dictionary) -> void:
	var c: Dictionary = st.circle
	c.enabled = true
	var S := _pair()
	var A = S.fighters[0]
	var D = S.fighters[1]
	var paid: Array = []
	for _n in range(3):
		A.ki = 100.0
		_tap(S, _press(false, true, false, 8))
		paid.append(snappedf(100.0 - A.ki, 0.1))
		for _k in range(40):
			_step(S)
	print("      three in a row: paid %s" % str(paid))
	_expect(paid.size() == 3 and absf(paid[0] - 10.0) < 1.5 and absf(paid[1] - 15.0) < 1.5 and absf(paid[2] - 22.5) < 1.5, "10 ki, then x1.5 each inside 3 s")
	SimCore.dispose(S)
	var S2 := _pair()
	var A2 = S2.fighters[0]
	var D2 = S2.fighters[1]
	var side: float = SimWrap.sdx(D2.x, A2.x)
	_tap(S2, _press(false, true, false, 8))
	var landed: bool = false
	var hp: float = D2.hp
	for k in range(30):
		_step(S2, null, _press(true, false, false) if k == 3 else null)
		landed = landed or D2.hp < hp
	print("      a light at him as he rises: he's on side %.0f, his medium landed %s" % [SimWrap.sdx(D2.x, A2.x), str(landed)])
	_expect(landed and signf(SimWrap.sdx(D2.x, A2.x)) == -signf(side), "a light doesn't stop it")
	SimCore.dispose(S2)
	c.enabled = false


## The stick's steal: a quick flick on a rival with a run takes it.
func _steal(sc: Dictionary) -> void:
	sc.steal.enabled = true
	var S := _pair()
	var A = S.fighters[0]
	var D = S.fighters[1]
	DirBrawl._s(D, DirBrawl.RUN, 3 * DirBrawl.RUN_U)
	var w := SimIntent.new()
	w.rsStart = true
	w.rsHeld = true
	w.rsDir = SimStrikeRead.LEFT if SimWrap.sdx(A.x, D.x) < 0.0 else SimStrikeRead.RIGHT
	_step(S, w)
	var stole: String = ""
	for k in range(30):
		if stole == "":
			DirBrawl._s(D, DirBrawl.RUN, 3 * DirBrawl.RUN_U)   # a trade on: both have landed lately, so his run holds
			DirBrawl._s(D, DirBrawl.LL_AT, S.tick)
			DirBrawl._s(A, DirBrawl.LL_AT, S.tick)
		var h := SimIntent.new()
		if k < 3:
			h.rsHeld = true
			h.rsDir = w.rsDir
		elif k == 3:
			h.rsRelease = true
			h.rsDir = w.rsDir
		_step(S, h)
		for c in _cues:
			if String(c).begins_with("stick_steal:"):
				stole = String(c).substr(12)
	print("      the steal: took '%s', his run now %d, mine %d" % [stole, DirBrawl._g(D, DirBrawl.RUN), DirBrawl._g(A, DirBrawl.RUN)])
	_expect(stole == "3" and DirBrawl._g(D, DirBrawl.RUN) == 0, "a quick flick takes his run")
	SimCore.dispose(S)
	sc.steal.enabled = false


## A stick strike waiting for its blow follows its request: told at once when refused or answered.
func _pend(sc: Dictionary, _b: Dictionary) -> void:
	for on_ in [false, true]:
		sc.pendFollow.enabled = on_
		# Refused: the first move is his rival's, and the flick is out of reach.
		var S := _pair(400.0, false)
		var A = S.fighters[0]
		DirBrawl._s(A, DirBrawl.MOVE_AT, S.tick + 300)
		var when: Dictionary = _flick(S, 30)
		print("      pendFollow %s, refused by the first move: %s" % [str(on_), str(when)])
		if on_:
			_expect(when.get("refused/refused", -1) == 0 and not when.has("refused/late"), "pendFollow on: a refused flick is told at once, as refused")
		else:
			_expect(when.has("refused/late"), "pendFollow off: a refused flick says late")
		SimCore.dispose(S)
	sc.pendFollow.enabled = false


## A quick flick toward him, then n ticks: the first tick of each cue of his, from the flick.
func _flick(S: SimState, n: int) -> Dictionary:
	var A = S.fighters[0]
	var D = S.fighters[1]
	var w := SimIntent.new()
	w.rsStart = true
	w.rsHeld = true
	w.rsDir = SimStrikeRead.LEFT if SimWrap.sdx(A.x, D.x) < 0.0 else SimStrikeRead.RIGHT
	var seen: Dictionary = {}
	for k in range(n):
		var h: SimIntent = w if k == 0 else SimIntent.new()
		if k > 0 and k < 3:
			h.rsHeld = true
			h.rsDir = w.rsDir
		elif k == 3:
			h.rsRelease = true
			h.rsDir = w.rsDir
		_step(S, h)
		for c in _cues:
			if String(c).begins_with("stick") or String(c).begins_with("refused/"):
				var key: String = String(c) if String(c).begins_with("refused/") else String(c).split(":")[0] + ":"
				if not seen.has(key):
					seen[key] = k
	return seen


## A hold swept up by a planned exchange goes on his first free tick, and its level counts from then.
func _swept(sc: Dictionary) -> void:
	sc.pendFollow.enabled = true
	var S := _pair()
	var A = S.fighters[0]
	var D = S.fighters[1]
	var dir: int = DirStick.TOWARD
	DirStick.sweep(S, A, dir | (1 << 3))
	A.stunTicks = 20   # (what the planned exchange's answer did to him)
	var w := SimIntent.new()
	w.rsHeld = true
	w.rsDir = SimStrikeRead.LEFT if SimWrap.sdx(A.x, D.x) < 0.0 else SimStrikeRead.RIGHT
	var startAt: int = -1
	var released: int = -1
	var lvl: int = -1
	var k: int = 0
	while k < 120 and released < 0:
		var h := SimIntent.new()
		h.rsDir = w.rsDir
		if startAt < 0 or k - startAt < 20:
			h.rsHeld = true
			h.rsLevel = 3   # the stick's own count runs from the first press: well past level 1
		else:
			h.rsRelease = true
			h.rsLevel = 3
		_step(S, h)
		for c in _cues:
			if String(c).begins_with("stick_start") and startAt < 0:
				startAt = k
			if String(c).begins_with("rlevel/") and released < 0:
				released = k
				lvl = int(String(c).substr(7))
		k += 1
	print("      a swept hold: it went at %d (his stun was 20), released at %d; the level kept %d" % [startAt, released, lvl])
	_expect(startAt >= 18 and startAt <= 24, "a swept hold goes on his first free tick")
	_expect(lvl >= 0 and lvl < 3, "... and its level counts from then, not from the first press (%d)" % lvl)
	SimCore.dispose(S)
	sc.pendFollow.enabled = false


## A landed quick flick adds a light's point to its striker's run.
func _flickRun(sc: Dictionary) -> void:
	for on_ in [false, true]:
		sc.flickRun.enabled = on_
		var S := _pair()
		var A = S.fighters[0]
		var D = S.fighters[1]
		var run0: int = DirBrawl._g(A, DirBrawl.RUN)
		var w := SimIntent.new()
		w.rsStart = true
		w.rsHeld = true
		w.rsDir = SimStrikeRead.LEFT if SimWrap.sdx(A.x, D.x) < 0.0 else SimStrikeRead.RIGHT
		_step(S, w)
		var hit: bool = false
		var after: int = run0
		for k in range(30):
			var h := SimIntent.new()
			h.rsDir = w.rsDir
			if k < 2:
				h.rsHeld = true
			elif k == 2:
				h.rsRelease = true
			_step(S, h)
			if not hit and _cues.any(func(c): return String(c).begins_with("stick_hit")):
				hit = true
				after = DirBrawl._g(A, DirBrawl.RUN)
		print("      flickRun %s: the flick landed %s; his run %d to %d quarters" % [str(on_), str(hit), run0, after])
		if on_:
			_expect(hit and after - run0 == int(round(float(sc.flickRun.points) * float(DirBrawl.RUN_U))), "flickRun on: a landed flick adds flickRun.points to his run")
		else:
			_expect(hit and after == run0, "flickRun off: a flick builds no run of his own")
		SimCore.dispose(S)
	sc.flickRun.enabled = false


## A swept hold doesn't go again while a planned exchange holds him, and its press is told once at most.
func _sweptQuiet(sc: Dictionary) -> void:
	sc.pendFollow.enabled = true
	var S := _pair(400.0, false)
	var A = S.fighters[0]
	var D = S.fighters[1]
	var w := SimIntent.new()
	w.rsDir = SimStrikeRead.LEFT if SimWrap.sdx(A.x, D.x) < 0.0 else SimStrikeRead.RIGHT
	DirStick.sweep(S, A, DirStick.TOWARD | (1 << 3))
	var refused: int = 0
	var acks: int = 0
	var went: int = -1
	for k in range(90):
		var h := SimIntent.new()
		h.rsHeld = true
		h.rsDir = w.rsDir
		var ex = S.dirS.ex
		_step(S, h)
		for c in _cues:
			if String(c).begins_with("stick_refused"):
				refused += 1
			if String(c).begins_with("press_ack"):
				acks += 1
		if went < 0 and DirStick._g(A, DirStick.ST_BUF) == 0:
			went = k
	print("      a swept hold, the stick held 90 ticks from 400 away: it went at %d; refusals said %d, press acks %d" % [went, refused, acks])
	_expect(refused <= 1 and acks <= 2, "a swept hold goes once: no refusal every tick (%d)" % refused)
	SimCore.dispose(S)
	sc.pendFollow.enabled = false

