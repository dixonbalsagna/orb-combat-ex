extends SceneTree
## Headless checks for the stick's feel (docs/controls/rule-of-cool-pitches.md pitches 1 and 3, docs/design/rule-of-cool-map.md section 5's landing rule):
##   - the reader against the landing rule: the blow lands at the later of the wind-up's end and the stick's return. The reader's side of it: a flick held a
##     short time returns before a 7-tick wind-up ends; a stick still out holds the request (rsHeld) with level 0 until the dwell, then it is a charge on the
##     ladder; a release keeps the level it had; a flick held to 11 is still a quick strike
##   - the ladder's rumble (switches.hapticLadder): one pulse per rung, on the tick the level rises, none at rest, none after a cancel, again for a second charge
##   - the incoming cue (switches.hapticIncoming): the defender's pad, high for toward and up, low for away and down; the striker's none
##   - all of it off with its switch off, and nothing in the intent changes
##   godot --headless --path . --script res://sim/input/test/stick_feel_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	_sw(true, true, true, true)
	_landing()
	_ladder()
	_incoming()
	_beams()
	_b_hold()
	_beam_window()
	_zero()
	_refused()
	_specials_off()
	_sig_rt_only()
	_sw(true, true, false, false)
	_off()
	_sw(false, false, false, false)
	print("stick_feel_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(right: bool, quick: bool, ladder: bool, incoming: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = right
	sw["quickRead"] = quick
	sw["hapticLadder"] = ladder
	sw["hapticIncoming"] = incoming
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


## A flick right from rest at tick 10: full push in `ramp` ticks, held `hold` ticks, back in 3. Returns the intents.
func _flick(l: SimLayout, ramp: int, hold: int, ticks: int = 100) -> Array:
	var out: Array = []
	for t in range(ticks):
		var k: int = t - 10
		var m: float = 0.0
		if k >= 0 and k < ramp:
			m = float(k + 1) / float(ramp)
		elif k >= ramp and k < ramp + hold:
			m = 1.0
		elif k >= ramp + hold and k < ramp + hold + 3:
			m = 1.0 - float(k - ramp - hold + 1) / 3.0
		l.axis("pad:rs", m, 0.0)
		out.append(l.build())
		l.consumed()
	return out


func _first(its: Array, what: String, from: int = 0) -> int:
	for t in range(from, its.size()):
		var i: SimIntent = its[t]
		if (what == "rsStart" and i.rsStart) or (what == "rsRelease" and i.rsRelease):
			return t
	return -1


## The reader against the landing rule.
func _landing() -> void:
	var dwell: int = SimInputData.ti(["strike", "dwell"], 12)
	for h in [0, 2, 4, 6, 8, 10, 11, 14, 20]:
		var its: Array = _flick(SimLayout.new(SimInputData.preset("arena")), 2, h)
		var s: int = _first(its, "rsStart")
		var r: int = _first(its, "rsRelease", s)
		var out: int = r - s   # ticks the stick was out, from the request to its return
		# between the start and the return the request is in the sim's hands
		var held_all: bool = true
		for t in range(s, r):
			held_all = held_all and (its[t] as SimIntent).rsHeld
		ok(s >= 0 and r >= s and held_all, "landing: a flick held %d: rsHeld from the start to the return (start %d, return %d)" % [h, s, r])
		var lv: int = (its[r] as SimIntent).rsLevel
		ok((lv == 0) == (out < dwell), "landing: held %d: out for %d ticks, level %d at the return (a quick strike below the dwell of %d, a charge at or past it)" % [h, out, lv, dwell])
		if out >= 8:
			# the wind-up (7) is over and the stick is still out: the director waits on the return, and the reader says the request is still held, at level 0 until the dwell
			var at7: SimIntent = its[s + 7]
			ok(at7.rsHeld and not at7.rsRelease and at7.rsLevel == (0 if 7 < dwell else 1), "landing: held %d: at the wind-up's end (start + 7) the stick is still out, level %d, no release yet" % [h, at7.rsLevel])
		if out <= 6:
			ok(r < s + 7, "landing: held %d: the return comes before the wind-up ends, so the blow lands at the wind-up's end (return at +%d)" % [h, out])
	# the ladder through the reader, from the start: 12, 30, 50
	var long: Array = _flick(SimLayout.new(SimInputData.preset("arena")), 2, 90)
	var s2: int = _first(long, "rsStart")
	var lv_at: Callable = func(k: int) -> int: return (long[s2 + k] as SimIntent).rsLevel
	ok(lv_at.call(11) == 0 and lv_at.call(12) == 1 and lv_at.call(29) == 1 and lv_at.call(30) == 2 and lv_at.call(49) == 2 and lv_at.call(50) == 3, "landing: the charge ladder is unchanged by the quick read, 12 / 30 / 50 live ticks from the start")


## A held stick through the real hub: pulses as the rungs are reached.
func _hub_pad() -> SimInputHub:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	return hub


func _ladder() -> void:
	var hub: SimInputHub = _hub_pad()
	var start: int = -1
	var pulses: Array = []   # [tick, kind]
	for t in range(120):
		var m: float = 1.0 if (t >= 10 and t < 80) else 0.0
		hub.pad_stick_right(7, m, 0.0)
		var i: SimIntent = hub.intent(0)
		if i.rsStart and start < 0:
			start = t
		for r in hub.take_haptics():
			pulses.append([t, String(r["kind"]), int(r["slot"])])
		hub.consumed()
	var want: Array = ["ladder_1", "ladder_2", "ladder_3", "release_thump"]   # the throw at 80 answers with the thump (docs/controls/beam-aim-feel.md)
	var got: Array = []
	for p in pulses:
		got.append(p[1])
	ok(got == want, "ladder: one pulse per rung, in order (got %s)" % str(got))
	if pulses.size() == 4:
		ok(int(pulses[3][0]) == 80, "ladder: the thump comes on the throw tick (the stick falls at 80), not before (got %d)" % pulses[3][0])
		ok(int(pulses[0][0]) == start + 12 and int(pulses[1][0]) == start + 30 and int(pulses[2][0]) == start + 50, "ladder: on the ticks the level rises, 12 / 30 / 50 from the start (start %d, pulses at %d, %d, %d)" % [start, pulses[0][0], pulses[1][0], pulses[2][0]])
		ok(int(pulses[0][2]) == 0, "ladder: for the charger's slot")
	# a second charge pulses again
	var hub2: SimInputHub = _hub_pad()
	var n: int = 0
	for t in range(260):
		var m2: float = 1.0 if ((t >= 10 and t < 70) or (t >= 130 and t < 200)) else 0.0
		hub2.pad_stick_right(7, m2, 0.0)
		hub2.intent(0)
		n += hub2.take_haptics().size()
		hub2.consumed()
	ok(n >= 5, "ladder: a second charge pulses again (%d pulses over two charges of 60 and 70 ticks)" % n)
	# a flick, a stick at rest and a cancelled charge: no pulses
	var hub3: SimInputHub = _hub_pad()
	var quiet: int = 0
	for t in range(60):
		hub3.pad_stick_right(7, 1.0 if (t >= 10 and t < 14) else 0.0, 0.0)
		hub3.intent(0)
		quiet += hub3.take_haptics().size()
		hub3.consumed()
	ok(quiet == 0, "ladder: a quick flick reaches no rung, no pulse")
	var hub4: SimInputHub = _hub_pad()
	var after_cancel: int = 0
	for t in range(100):
		hub4.pad_stick_right(7, 1.0 if t >= 10 else 0.0, 0.0)
		if t == 25:
			hub4.pad_button(7, "lb", true)   # the guard: it ends a started charge
		hub4.intent(0)
		for r in hub4.take_haptics():
			if t >= 26:
				after_cancel += 1
		hub4.consumed()
	ok(after_cancel == 0, "ladder: a guard press ends the charge, and no rung is felt after it")


func _incoming() -> void:
	var cases: Array = [["toward", "incoming_high"], ["up", "incoming_high"], ["away", "incoming_low"], ["down", "incoming_low"]]
	for c in cases:
		var r0: Array = SimHaptics.requests("stick_start", 0, -1, c[0], 0.0)
		var r1: Array = SimHaptics.requests("stick_start", 1, 0, c[0], 0.0)
		ok(r0.size() == 1 and int(r0[0]["slot"]) == 1 and r0[0]["kind"] == c[1], "incoming: slot 0 strikes %s: slot 1 feels %s" % [c[0], c[1]])
		ok(r1.size() == 1 and int(r1[0]["slot"]) == 0 and r1[0]["kind"] == c[1], "incoming: slot 1 strikes %s: slot 0 feels %s" % [c[0], c[1]])
	ok(SimHaptics.requests("stick_start", 0, -1, "", 0.0).is_empty(), "incoming: no direction, no cue")
	ok(SimHaptics.requests("stick_start", -1, -1, "toward", 0.0).is_empty(), "incoming: no striker, no cue")
	for k in ["incoming_high", "incoming_low", "ladder_1", "ladder_2", "ladder_3"]:
		var pad: Dictionary = SimHaptics.plan(k, {"kind": "pad", "id": 3}, true, -10000, 1000)
		var ph: Dictionary = SimHaptics.plan(k, {"kind": "touch", "id": -1}, true, -10000, 1000)
		ok(not pad.is_empty() and not ph.is_empty(), "kinds: %s plays on a pad and a phone" % k)
	ok(SimHaptics.plan("incoming_high", {"kind": "kb", "id": -1}, true, -10000, 1000).is_empty(), "kinds: nothing on a keyboard")


## Row 40: the beam-answer window's crescendo on the receiver's pad (switches.hapticIncomingBeam).
func _beam_window() -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["hapticIncomingBeam"] = false
	SimInputData.timing["switches"] = sw
	ok(SimHaptics.beam_window(0, 1, "start", 30.0).is_empty(), "beam window: nothing with its switch off")
	sw["hapticIncomingBeam"] = true
	SimInputData.timing["switches"] = sw
	var w: Dictionary = SimHaptics.beam_window(0, 1, "start", 30.0)
	ok(not w.is_empty() and int(w["slot"]) == 1 and bool(w["open"]), "beam window: shooter 0, receiver 1: the receiver's pad")
	var w1: Dictionary = SimHaptics.beam_window(1, -1, "start", 30.0)
	ok(int(w1["slot"]) == 0, "beam window: no target given: the other slot is the receiver")
	var cases: Array = [6.0, 12.0, 20.0, 30.0, 60.0, 90.0]
	var gap: int = SimHaptics.kind_gap_ms("incoming_beam")
	for ticks in cases:
		var p: Array = SimHaptics.beam_window(0, 1, "start", ticks)["pulses"]
		var len_ms: int = int(ticks * 1000.0 / 60.0)
		var rising: bool = true
		var spaced: bool = true
		var inside: bool = p.size() >= 1 and p.size() <= 5
		for k in range(p.size()):
			inside = inside and int(p[k]["at"]) > 0 and int(p[k]["at"]) < len_ms
			if k > 0:
				rising = rising and float(p[k]["scale"]) > float(p[k - 1]["scale"])
				spaced = spaced and int(p[k]["at"]) - int(p[k - 1]["at"]) >= gap
		ok(inside and (rising or p.size() == 1) and spaced, "beam window: %d ticks: %d pulses inside the window, rising, at least %d ms apart" % [int(ticks), p.size(), gap])
		ok(p.size() == 0 or float(p[p.size() - 1]["scale"]) == 1.0, "beam window: %d ticks: the last pulse is the loudest (a crescendo to arrival)" % int(ticks))
	ok(not bool(SimHaptics.beam_window(0, 1, "end", 30.0)["open"]) and not bool(SimHaptics.beam_window(0, 1, "beam", 30.0)["open"]), "beam window: the end cue closes it, and an unknown text opens nothing")
	ok(not bool(SimHaptics.beam_window(0, 1, "start", 0.0)["open"]), "beam window: a zero-length window is closed")
	ok(SimHaptics.requests("beam_window", 0, 1, "start", 30.0).is_empty(), "beam window: the cue itself rumbles nothing: the pulses come from beam_window on the host's timers")
	for dev in [{"kind": "pad", "id": 3}, {"kind": "touch", "id": -1}]:
		ok(not SimHaptics.plan("incoming_beam", dev, true, -10000, 1000, 0.3).is_empty(), "beam window: incoming_beam plays on a %s even at its softest" % dev["kind"])
	sw["hapticIncomingBeam"] = false
	SimInputData.timing["switches"] = sw


func _off() -> void:
	ok(SimHaptics.requests("stick_start", 0, -1, "toward", 0.0).is_empty(), "off: the incoming cue asks for nothing with its switch off")
	var hub: SimInputHub = _hub_pad()
	var n: int = 0
	for t in range(100):
		hub.pad_stick_right(7, 1.0 if t >= 10 else 0.0, 0.0)
		hub.intent(0)
		n += hub.take_haptics().size()
		hub.consumed()
	ok(n == 0, "off: a held charge asks for no ladder pulses with its switch off")
	# the intents are the same with the ladder on and off
	_sw(true, true, true, false)
	var a: SimInputHub = _hub_pad()
	var pa: Array = []
	for t in range(80):
		a.pad_stick_right(7, 1.0 if (t >= 10 and t < 60) else 0.0, 0.0)
		pa.append(SimIntent.pack2(a.intent(0)))
		a.take_haptics()
		a.consumed()
	_sw(true, true, false, false)
	var b: SimInputHub = _hub_pad()
	var pb: Array = []
	for t in range(80):
		b.pad_stick_right(7, 1.0 if (t >= 10 and t < 60) else 0.0, 0.0)
		pb.append(SimIntent.pack2(b.intent(0)))
		b.take_haptics()
		b.consumed()
	ok(pa == pb, "off: asking for the ladder changes no intent (pack2 equal over 80 ticks)")


## E120: beams are the stick in the energy layer (RB + stick, and its mirrors), on the beam ladder 12 / 30 / 54, in every form and the left-handed swap.
func _beam_form(l: SimLayout, rb: String, press: Callable, release: Callable, name: String) -> void:
	l.press(rb)
	var its: Array = []
	for t in range(110):
		if t == 10:
			press.call()
		its.append(l.build())
		l.consumed()
	var st: int = _first(its, "rsStart")
	ok(st >= 0 and (its[st] as SimIntent).rsMask == SimStance.ENERGY, "beam: %s: RB + the stick is a request on the energy layer (mask %d)" % [name, (its[st] as SimIntent).rsMask if st >= 0 else -1])
	if st >= 0:
		var lv: Callable = func(k: int) -> int: return (its[st + k] as SimIntent).rsLevel
		ok(lv.call(11) == 0 and lv.call(12) == 1 and lv.call(29) == 1 and lv.call(30) == 2 and lv.call(53) == 2 and lv.call(54) == 3, "beam: %s: the beam ladder is 12 / 30 / 54 live ticks from the start" % name)
		ok((its[st + 90] as SimIntent).rsHeld and (its[st + 90] as SimIntent).rsLevel == 3, "beam: %s: a level 3 beam is held and never thrown by a timer (E129's Loaded is reachable on the stick)" % name)


func _beams() -> void:
	var a: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	_beam_form(a, "pad:rb", func(): a.axis("pad:rs", 1.0, 0.0), func(): pass, "pad stick")
	var b: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	b.set_mirror_dpad(true)
	_beam_form(b, "pad:rb", func(): b.press("pad:dpad_right"), func(): pass, "D-pad mirror")
	var c: SimLayout = SimLayout.new(SimInputData.preset("kb-solo"))
	_beam_form(c, "kb:KeyQ", func(): c.press("kb:ArrowRight"), func(): pass, "keyboard arrows")
	var d: SimLayout = SimLayout.new(SimInputData.preset("arena-swapped"))
	_beam_form(d, SimSwap.control("pad:rb"), func(): d.axis(SimSwap.control("pad:rs"), 1.0, 0.0), func(): pass, "left-handed pad")


## E131: while B is held in the energy layer the stick is inert; B released then the stick waits R; the stick first strips B.
func _b_hold() -> void:
	var rev: int = SimInputData.ti(["strike", "reverseLockout"], 8)
	var l: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	var its: Array = []
	for t in range(100):
		if t == 5:
			l.press("pad:rb")
		if t == 10:
			l.press("pad:east")   # B: the Driver's hold
		l.axis("pad:rs", 1.0 if ((t >= 20 and t < 31) or t >= 41) else 0.0, 0.0)
		if t == 40:
			l.release("pad:east")
		its.append(l.build())
		l.consumed()
	var st: int = _first(its, "rsStart")
	var inert_ok: bool = true
	for t in range(0, 41):
		inert_ok = inert_ok and not (its[t] as SimIntent).rsStart and not (its[t] as SimIntent).rsHeld
	ok(inert_ok, "B held: the stick (pushed twice while B is held in energy) starts nothing")
	ok(st >= 40 + rev and (its[st] as SimIntent).rsMask == SimStance.ENERGY, "B released then the stick: the beam request waits R = %d from the release (release 40, start %d)" % [rev, st])
	# the same stick with no B: it starts as soon as the reader allows
	var l0: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	var its0: Array = []
	for t in range(100):
		if t == 5:
			l0.press("pad:rb")
		l0.axis("pad:rs", 1.0 if t >= 41 else 0.0, 0.0)
		its0.append(l0.build())
		l0.consumed()
	var st0: int = _first(its0, "rsStart")
	ok(st0 >= 41 and st0 < 40 + rev, "B held: without B the same push starts at once (%d), which is the hole the release lockout closes" % st0)
	# the stick first: B is stripped while the beam is out (one charge at a time)
	var l2: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	var its2: Array = []
	for t in range(80):
		if t == 5:
			l2.press("pad:rb")
		l2.axis("pad:rs", 1.0 if t >= 10 else 0.0, 0.0)
		if t == 30:
			l2.press("pad:east")
		its2.append(l2.build())
		l2.consumed()
	var leak: bool = false
	for t in range(30, 80):
		leak = leak or (its2[t] as SimIntent).sig or (its2[t] as SimIntent).sigHeld
	ok(not leak and (its2[79] as SimIntent).rsHeld, "stick first: B pressed while the beam is out is held back (no sig, no sigHeld), and the beam stays held")
	# the keyboard's signature key is the same B
	var k: SimLayout = SimLayout.new(SimInputData.preset("kb-solo"))
	var itk: Array = []
	for t in range(60):
		if t == 3:
			k.press("kb:KeyQ")
		if t == 6:
			k.press("kb:KeyL")
		if t == 15:
			k.press("kb:ArrowRight")
		itk.append(k.build())
		k.consumed()
	ok(_first(itk, "rsStart") < 0, "B held: the keyboard's L is B too: the arrows start nothing while L is held in energy")


## Settle 0 (strike.settleQuick = 0, the option Orb can try): the strike's direction is taken on the crossing tick; nothing else about it moves.
func _set_settle(v: int) -> void:
	var st: Dictionary = SimInputData.timing.get("strike", {})
	st["settleQuick"] = v
	SimInputData.timing["strike"] = st
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _start_after_motion(l: SimLayout, ramp: int, press_x: int = -1) -> int:
	var its: Array = []
	for t in range(60):
		var k: int = t - 10
		var m: float = 0.0
		if k >= 0 and k < ramp:
			m = float(k + 1) / float(ramp)
		elif k >= ramp and k < ramp + 4:
			m = 1.0
		elif k >= ramp + 4 and k < ramp + 7:
			m = 1.0 - float(k - ramp - 3) / 3.0
		if t == press_x:
			l.press("pad:west")
		if t == press_x + 2:
			l.release("pad:west")
		l.axis("pad:rs", m, 0.0)
		its.append(l.build())
		l.consumed()
	return _first(its, "rsStart") - 10


func _zero() -> void:
	var one: Dictionary = {}
	var zero: Dictionary = {}
	_set_settle(1)
	for r in [1, 2, 3, 4]:
		one[r] = _start_after_motion(SimLayout.new(SimInputData.preset("arena")), r)
	_set_settle(0)
	for r in [1, 2, 3, 4]:
		zero[r] = _start_after_motion(SimLayout.new(SimInputData.preset("arena")), r)
		ok(zero[r] == one[r] - 1, "settle 0: a ramp-%d flick starts on the crossing tick, one sooner than settle 1 (%d, was %d)" % [r, zero[r], one[r]])
	# the crossing tick: ramp 1 crosses at motion +0, ramp 2 at +1
	ok(zero[1] == 0 and zero[2] == 1, "settle 0: the start is the crossing tick itself")
	# the direction is right at the crossing
	var l: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	var dirs_ok: bool = true
	for ang in [0.0, 90.0, 180.0, 270.0, 20.0, -20.0, 160.0, 200.0]:
		var lv: SimLayout = SimLayout.new(SimInputData.preset("arena"))
		var got: int = 0
		for t in range(30):
			var m: float = 1.0 if (t >= 5 and t < 15) else 0.0
			lv.axis("pad:rs", cos(deg_to_rad(ang)) * m, sin(deg_to_rad(ang)) * m)
			var it: SimIntent = lv.build()
			if it.rsStart and got == 0:
				got = it.rsDir
			lv.consumed()
		var want: int = SimStrikeRead.quadrant(cos(deg_to_rad(ang)), sin(deg_to_rad(ang)))
		dirs_ok = dirs_ok and got == want
	ok(dirs_ok, "settle 0: a full push at eight angles reads the quadrant it is in")
	# the law: a face press before the stick waits R; one on the crossing tick wins
	var rev: int = SimInputData.ti(["strike", "reverseLockout"], 8)
	var s_law: int = _start_after_motion(SimLayout.new(SimInputData.preset("arena")), 2, 9)
	ok(s_law + 10 >= 9 + rev, "settle 0: a face press 2 ticks before the crossing still holds the strike R = %d (start at %d, press at 9)" % [rev, s_law + 10])
	var l2: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	var its2: Array = []
	for t in range(60):
		if t == 10:
			l2.press("pad:west")   # on the crossing tick of a ramp-1 flick
		l2.axis("pad:rs", 1.0 if (t >= 10 and t < 20) else 0.0, 0.0)
		its2.append(l2.build())
		l2.consumed()
	var lt: int = -1
	for t in range(its2.size()):
		if (its2[t] as SimIntent).light and lt < 0:
			lt = t
	ok(lt == 10 and _first(its2, "rsStart") >= 10 + rev, "settle 0: the face press on the crossing tick wins (light at %d) and the strike starts R later (start %d)" % [lt, _first(its2, "rsStart")])
	# the mirrors act on the same tick as the stick
	var m1: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	m1.set_mirror_dpad(true)
	var ds: int = -1
	var k1: SimLayout = SimLayout.new(SimInputData.preset("kb-solo"))
	var ks: int = -1
	for t in range(30):
		if t == 10:
			m1.press("pad:dpad_right")
			k1.press("kb:ArrowRight")
		var a: SimIntent = m1.build()
		var b: SimIntent = k1.build()
		if a.rsStart and ds < 0:
			ds = t
		if b.rsStart and ks < 0:
			ks = t
		m1.consumed()
		k1.consumed()
	ok(ds == 10 and ks == 10, "settle 0: the D-pad and the keyboard arrows act on the press tick, like the stick (%d, %d)" % [ds, ks])
	# the swapped layout makes the same stream
	var sa: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	var sb: SimLayout = SimLayout.new(SimInputData.preset("arena-swapped"))
	var same: bool = true
	for t in range(100):
		var mm: float = 1.0 if (t % 25) in [10, 11, 12] else 0.0
		sa.axis("pad:rs", mm, 0.0)
		sb.axis("pad:ls", mm, 0.0)
		if t % 40 == 20:
			sa.press("pad:west")
			sb.press("pad:dpad_left")
		if t % 40 == 22:
			sa.release("pad:west")
			sb.release("pad:dpad_left")
		var ia: SimIntent = sa.build()
		var ib: SimIntent = sb.build()
		sa.consumed()
		sb.consumed()
		if SimIntent.pack(ia) != SimIntent.pack(ib) or SimIntent.pack2(ia) != SimIntent.pack2(ib):
			same = false
	ok(same, "settle 0: arena and arena-swapped make one stream")
	# the flick brace at settle 0 goes out on its crossing tick
	var lb: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	lb.press("pad:lb")
	var bt: int = -1
	for t in range(40):
		lb.axis("pad:ls", 0.0, 1.0 if (t >= 20 and t < 26) else 0.0)
		if lb.build().brace and bt < 0:
			bt = t
		lb.consumed()
	ok(bt == 20, "settle 0: the flick brace goes out on its crossing tick (%d)" % bt)
	# the vanish: a direction already out at the second press resolves at once; with none it still waits the settle
	var vt: int = _vanish_tick(true)
	var vn: int = _vanish_tick(false)
	ok(vt == 10 and vn == 12, "quick vanish: stick already out at the second press: that tick (%d); no stick: the settle, 2 later (%d)" % [vt, vn])
	_set_settle(1)


func _vanish_tick(stick_out: bool) -> int:
	var l: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	var got: int = -1
	for t in range(40):
		if stick_out and t >= 4:
			l.axis("pad:ls", 1.0, 0.0)
		if t == 9:
			l.press("pad:lb")
		if t == 10:
			l.analog("pad:lt", 1.0)
		if l.build().escape and got < 0:
			got = t
		l.consumed()
	return got


## The audit's gap 2: a stick press the game did not answer tells its pad (switches.hapticRefused), unless the director said it started.
func _refusal_hub(on: bool) -> SimInputHub:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["hapticRefused"] = on
	SimInputData.timing["switches"] = sw
	return _hub_pad()


func _refused() -> void:
	var refuse: int = SimInputData.ti(["strike", "refuseTicks"], 30)
	# no answer: a flick, then the live ticks pass with no stick_start
	var hub: SimInputHub = _refusal_hub(true)
	var got: Array = []
	for t in range(80):
		hub.pad_stick_right(7, 1.0 if (t >= 10 and t < 14) else 0.0, 0.0)
		hub.intent(0)
		for r in hub.take_haptics():
			got.append([t, String(r["kind"]), int(r["slot"])])
		hub.consumed()
		for r in hub.take_haptics():
			got.append([t, String(r["kind"]), int(r["slot"])])
	ok(got.size() == 1 and got[0][1] == "stick_refused" and got[0][2] == 0, "refused: a stick request with no strike started is told to its pad once (%s)" % str(got))
	if got.size() == 1:
		ok(int(got[0][0]) >= 10 + refuse and int(got[0][0]) <= 10 + refuse + 6, "refused: it comes refuseTicks = %d live ticks after the request (request about tick 12, told at %d)" % [refuse, got[0][0]])
	# answered: the host tells the hub the director started it
	var hub2: SimInputHub = _refusal_hub(true)
	var n2: int = 0
	for t in range(80):
		hub2.pad_stick_right(7, 1.0 if (t >= 10 and t < 14) else 0.0, 0.0)
		var i2: SimIntent = hub2.intent(0)
		if i2.rsStart:
			hub2.note_stick_started(0)   # Encounter's stick_start cue, on the same tick
		n2 += hub2.take_haptics().size()
		hub2.consumed()
		n2 += hub2.take_haptics().size()
	ok(n2 == 0, "refused: a strike the director started is never told as refused")
	# a cancelled request (the guard or dodge) is not a refusal
	var hub3: SimInputHub = _refusal_hub(true)
	var n3: int = 0
	for t in range(100):
		hub3.pad_stick_right(7, 1.0 if t >= 10 else 0.0, 0.0)
		if t == 14:
			hub3.pad_button(7, "lb", true)
		hub3.intent(0)
		n3 += hub3.take_haptics().size()
		hub3.consumed()
		n3 += hub3.take_haptics().size()
	ok(n3 <= 1, "refused: a request cancelled by the guard tells nothing more than once (%d)" % n3)
	# off
	var hub4: SimInputHub = _refusal_hub(false)
	var n4: int = 0
	for t in range(80):
		hub4.pad_stick_right(7, 1.0 if (t >= 10 and t < 14) else 0.0, 0.0)
		hub4.intent(0)
		hub4.consumed()
		n4 += hub4.take_haptics().size()
	ok(n4 == 0, "refused: nothing with its switch off")
	# Encounter's own cue, as soon as it knows
	_refusal_hub(true)
	var rq: Array = SimHaptics.requests("stick_refused", 1, -1, "", 0.0)
	ok(rq.size() == 1 and int(rq[0]["slot"]) == 1 and rq[0]["kind"] == "stick_refused", "refused: Encounter's stick_refused cue goes to the presser only")
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["hapticRefused"] = false
	SimInputData.timing["switches"] = sw
	ok(SimHaptics.requests("stick_refused", 1, -1, "", 0.0).is_empty(), "refused: the cue does nothing with the switch off")
	for dev in [{"kind": "pad", "id": 3}, {"kind": "touch", "id": -1}]:
		ok(not SimHaptics.plan("stick_refused", dev, true, -10000, 1000).is_empty(), "refused: the kind plays on a %s" % dev["kind"])


## The power specials are off (docs/design/pad-first-press.md): RT held, then X, Y or A is the plain blow, and the charge drops.
func _specials_off() -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	for off in [false, true]:
		sw["specialsOff"] = off
		SimInputData.timing["switches"] = sw
		SimInputData.clear_overrides()
		SimInputData.invalidate()
		for f in [["west", "light", 1], ["north", "heavy", 2], ["south", "context", 3]]:
			var l: SimLayout = SimLayout.new(SimInputData.preset("arena"))
			l.analog("pad:rt", 1.0)
			var plain: bool = false
			var special: int = 0
			var power_after: bool = true
			for t in range(40):
				if t == 20:
					l.press("pad:" + f[0])
				if t == 23:
					l.release("pad:" + f[0])
				var i: SimIntent = l.build()
				if t >= 20 and bool(i.get(f[1])):
					plain = true
				if i.special != 0:
					special = i.special
				if t == 30:
					power_after = i.power
				l.consumed()
			if off:
				ok(plain and special == 0 and not power_after, "specials off: RT then %s is the plain %s, no special, and the charge drops (plain %s, special %d, power after %s)" % [f[0], f[1], str(plain), special, str(power_after)])
			else:
				ok(special == f[2] and not plain, "specials on (as shipped): RT then %s is special %d" % [f[0], f[2]])
		# B in the power layer stays the signature
		var lb: SimLayout = SimLayout.new(SimInputData.preset("arena"))
		lb.analog("pad:rt", 1.0)
		var sig: bool = false
		for t in range(30):
			if t == 20:
				lb.press("pad:east")
			if lb.build().sig:
				sig = true
			lb.consumed()
		ok(sig, "specials %s: RT then B is still the signature" % ("off" if off else "on"))
	sw["specialsOff"] = false
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


## The signature is RT + B only (the EP's decision, E121): with the switch on, B with LB, RB or LT held is the heavy of that stance and never the signature; RT + B and B alone are as they were.
func _sig_rt_only() -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	for on in [false, true]:
		sw["signatureRtOnly"] = on
		SimInputData.timing["switches"] = sw
		SimInputData.clear_overrides()
		SimInputData.invalidate()
		for lay in [["none", ""], ["LB", "lb"], ["RB", "rb"], ["LT", "lt"], ["RT", "rt"]]:
			var l: SimLayout = SimLayout.new(SimInputData.preset("arena"))
			if lay[1] == "lt" or lay[1] == "rt":
				l.analog("pad:" + lay[1], 1.0)
			elif lay[1] != "":
				l.press("pad:" + lay[1])
			var sig: bool = false
			var heavy: bool = false
			var sig_held: bool = false
			var heavy_held: bool = false
			for t in range(40):
				if t == 20:
					l.press("pad:east")
				if t == 30:
					l.release("pad:east")
				var i: SimIntent = l.build()
				if t >= 20 and t < 30:
					sig_held = sig_held or i.sigHeld
					heavy_held = heavy_held or i.heavyHeld
				if t >= 20:
					sig = sig or i.sig
					heavy = heavy or i.heavy
				l.consumed()
			var is_sig: bool = (not on) or lay[0] == "none" or lay[0] == "RT"
			ok(sig == is_sig and heavy == (not is_sig), "signature RT only %s: B with %s is %s (sig %s, heavy %s)" % ["on" if on else "off", lay[0], "the signature" if is_sig else "the heavy", str(sig), str(heavy)])
			ok(sig_held == is_sig and heavy_held == (not is_sig), "signature RT only %s: B held with %s carries its level as %s" % ["on" if on else "off", lay[0], "sigHeld" if is_sig else "heavyHeld"])
	# With the Driver on RB (switches.driverOnRb): RB + B stays the B press for the Driver to read; LB + B and LT + B are still the stance's heavy.
	sw["signatureRtOnly"] = true
	sw["driverOnRb"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	for lay in [["LB", "lb", false], ["RB", "rb", true], ["LT", "lt", false]]:
		var l: SimLayout = SimLayout.new(SimInputData.preset("arena"))
		if lay[1] == "lt":
			l.analog("pad:lt", 1.0)
		else:
			l.press("pad:" + lay[1])
		var sig: bool = false
		var heavy: bool = false
		for t in range(40):
			if t == 20:
				l.press("pad:east")
			if t == 30:
				l.release("pad:east")
			var i: SimIntent = l.build()
			if t >= 20:
				sig = sig or i.sig
				heavy = heavy or i.heavy
			l.consumed()
		ok(sig == lay[2] and heavy == (not lay[2]), "driver on RB: B with %s is %s (sig %s, heavy %s)" % [lay[0], "left for the Driver" if lay[2] else "the heavy", str(sig), str(heavy)])
	sw["signatureRtOnly"] = false
	sw["driverOnRb"] = false
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
