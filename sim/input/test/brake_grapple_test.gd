extends SceneTree
## Headless checks for the three parked pieces (docs/controls/brake-and-grapple.md): the air brake's bit on a Simple slot (Guard held while
## sent, behind `switches.airBrakeGuard`), the "A only" option of struggle_press for a Simple slot in a clinch, and the grapple's catch_read
## and brace_read with a_read's shove and clinch retired (behind `switches.grappleReads`). From the repo root:
##   godot --headless --path . --script res://sim/input/test/brake_grapple_test.gd
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
	_switches()
	_brake_pad()
	_brake_touch()
	_brake_others()
	_brake_hub()
	_a_only()
	_catch()
	_brace()
	_a_read()
	print("brake_grapple_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(airbrake: bool, grapple: bool) -> void:
	SimInputData.timing["switches"] = {"airBrakeGuard": airbrake, "grappleReads": grapple}


func _no_sw() -> void:
	SimInputData.timing.erase("switches")


func _run(l: SimLayout, n: int) -> SimIntent:
	var i: SimIntent = null
	for k in range(n):
		i = l.build()
		l.consumed()
	return i


func _runt(t: SimTouch, n: int) -> SimIntent:
	var i: SimIntent = null
	for k in range(n):
		i = t.build()
		t.consumed()
	return i


func _switches() -> void:
	_no_sw()
	ok(not bool(SimInputData.t(["switches", "airBrakeGuard"], false)) and not bool(SimInputData.t(["switches", "grappleReads"], false)), "switches: absent, both are off")
	SimInputData.load_and_apply()
	ok(SimInputData.t(["switches", "airBrakeGuard"], true) == false and SimInputData.t(["switches", "grappleReads"], true) == false, "switches: timing.json has both off")


func _brake_pad() -> void:
	var l: SimLayout = SimLayout.new(SimInputData.preset("simple-pad"))
	# Off: Guard held is the defensive stance, sent or not.
	_no_sw()
	l.press("pad:east")
	ok(_run(l, 4).stanceMask == 1, "brake: with the switch off Simple's Guard held is the defensive stance")
	l.set_sent(true)
	ok(_run(l, 4).stanceMask == 1, "brake: and still with the switch off while sent")
	# On: while sent it is the manoeuvre bit, the guard field is untouched; not sent it is the defensive stance.
	_sw(true, false)
	var i: SimIntent = _run(l, 3)
	ok(i.stanceMask == 8 and i.guard, "brake: switch on, sent: Guard held is stanceMask 8, and `guard` stays true")
	l.set_sent(false)
	ok(_run(l, 3).stanceMask == 1, "brake: no longer sent, it is the defensive stance again")
	l.set_sent(true)
	ok(_run(l, 3).stanceMask == 8, "brake: sent again, 8")
	l.release("pad:east")
	ok(_run(l, 6).stanceMask == 0, "brake: let go, no stance")
	# Other Simple buttons are unaffected while sent.
	l.press("pad:west")
	ok(_run(l, 4).stanceMask == 0, "brake: the Attack held while sent is no stance")
	l.release("pad:west")
	_run(l, 4)
	# RT dominates, as always: Power held while sent is the charging stance, not a brake.
	l.analog("pad:rt", 0.9)
	l.press("pad:east")
	ok(_run(l, 4).stanceMask == 4, "brake: RT held dominates: no brake bit")
	_no_sw()


func _brake_touch() -> void:
	var t := SimTouch.new()
	t.dp = 2.75
	_no_sw()
	t.touch_down(1, 600.0, 300.0, "guard")
	ok(_runt(t, 4).stanceMask == 1, "brake touch: switch off, Guard held is the defensive stance")
	t.set_sent(true)
	ok(_runt(t, 4).stanceMask == 1, "brake touch: and while sent with the switch off")
	_sw(true, false)
	var i: SimIntent = _runt(t, 3)
	ok(i.stanceMask == 8 and i.guard, "brake touch: switch on, sent: Guard held is stanceMask 8, `guard` stays true")
	t.set_sent(false)
	ok(_runt(t, 3).stanceMask == 1, "brake touch: not sent, defensive")
	t.touch_up(1)
	_runt(t, 5)
	# The stick's outer ring (LT's bit already) still gives 8 while sent, with or without the switch.
	t.set_sent(true)
	t.touch_down(2, 200.0, 700.0, "stick")
	t.touch_move(2, 200.0 + 80.0 * 2.75, 700.0)
	ok(_runt(t, 10).stanceMask == 8, "brake touch: the outer ring is the manoeuvre bit as always")
	_no_sw()


func _brake_others() -> void:
	# LT held already sets bit 8, sent or not, switch or not; a tap at contact is still the dodge edge (the tech).
	for sw in [false, true]:
		if sw:
			_sw(true, false)
		else:
			_no_sw()
		var l: SimLayout = SimLayout.new(SimInputData.preset("arena"))
		l.set_sent(true)
		l.press("pad:lt")
		var i: SimIntent = l.build()
		ok(i.stanceMask == 8 and i.dodge, "brake arena (switch %s): LT is bit 8 and its press is the dodge edge (the tech)" % str(sw))
		l.consumed()
		ok(_run(l, 20).stanceMask == 8, "brake arena (switch %s): LT held stays 8" % str(sw))
		l.release("pad:lt")
		_run(l, 6)
		# Guard on an Arena pad is unchanged while sent: a pad has LT.
		l.press("pad:lb")
		ok(_run(l, 4).stanceMask == 1, "brake arena (switch %s): Guard (LB) held while sent is still the defensive stance: the pad has LT" % str(sw))
	_sw(true, false)
	var f := SimTouch.new()
	f.dp = 2.75
	f.set_preset("touch-full")
	f.set_stance_oneshot(false)
	f.set_sent(true)
	f.touch_down(1, 0.0, 0.0, "guard")
	ok(_runt(f, 4).stanceMask == 1, "brake full touch: Guard is unchanged (it has the Dodge button's hold for LT's bit)")
	f.touch_up(1)
	_runt(f, 4)
	f.touch_down(2, 0.0, 0.0, "dodge")
	ok(_runt(f, 14).stanceMask == 8, "brake full touch: the Dodge held is bit 8")
	var k: SimLayout = SimLayout.new(SimInputData.preset("kb-solo"))
	k.set_sent(true)
	k.press("kb:Space")
	ok(_run(k, 14).stanceMask == 8, "brake keyboard: Space (LT) held is bit 8")
	_no_sw()


func _brake_hub() -> void:
	_sw(true, false)
	var hub := SimInputHub.new()
	hub.set_humans(true, true)
	hub.set_pad_preset("simple-pad", 0)
	hub.set_pad_preset("simple-pad", 1)
	hub.pad_button(3, "south", true)
	hub.pad_button(3, "south", false)
	hub.pad_button(9, "south", true)
	hub.pad_button(9, "south", false)
	hub.intent(0)
	hub.intent(1)
	hub.consumed()
	hub.pad_button(3, "east", true)
	hub.pad_button(9, "east", true)
	hub.set_sent(1, true)
	var a: SimIntent = hub.intent(0)
	var b: SimIntent = hub.intent(1)
	hub.consumed()
	for n in range(3):
		a = hub.intent(0)
		b = hub.intent(1)
		hub.consumed()
	ok(a.stanceMask == 1 and b.stanceMask == 8, "brake hub: only the sent slot's Guard is the brake (player one 1, player two 8)")
	hub.set_sent(1, false)
	b = hub.intent(1)
	ok(b.stanceMask == 1, "brake hub: not sent, player two is defensive again")
	# The intent is recorded as built: bit 8 round-trips through the pack, so a replay needs no sim state.
	hub.set_sent(1, true)
	hub.consumed()
	var c: SimIntent = hub.intent(1)
	var u: SimIntent = SimIntent.unpack(SimIntent.pack(c))
	ok(u != null and u.stanceMask == 8, "brake hub: the brake bit survives the packed intent (a replay carries it)")
	_no_sw()
	hub.consumed()
	var d: SimIntent = hub.intent(1)
	ok(d.stanceMask == 1, "brake hub: switched off again, nothing changes")


func _a_only() -> void:
	var rig := _Rig.new()
	rig.l = SimLayout.new(SimInputData.preset("simple-pad"))
	rig.opts = {"a_only": true}
	rig.l.press("pad:lb")
	ok(rig.step() == "letgo", "a_only: Simple's LB (A) is A")
	rig.l.release("pad:lb")
	rig.steps(6)
	rig.l.press("pad:east")
	ok(rig.step() == "letgo", "a_only: Guard is A on a Simple slot (touch's stand-in)")
	rig.l.release("pad:east")
	rig.steps(6)
	rig.l.press("pad:west")
	ok(rig.steps(1)[0] == "none", "a_only: the Attack's press is not read in a clinch")
	rig.l.release("pad:west")
	rig.steps(6)
	rig.l.press("pad:north")
	ok(rig.steps(1)[0] == "none", "a_only: nor Y")
	rig.l.release("pad:north")
	rig.steps(6)
	var no_opt := _Rig.new()
	no_opt.l = SimLayout.new(SimInputData.preset("simple-pad"))
	no_opt.l.press("pad:west")
	ok(no_opt.step() == "surge", "a_only: without the option the Attack is a surge, as before")
	# A non-Simple slot ignores the option: it has real X, Y and B.
	var ar := _Rig.new()
	ar.l = SimLayout.new(SimInputData.preset("arena"))
	ar.opts = {"a_only": true}
	ar.l.press("pad:west")
	ok(ar.step() == "surge", "a_only: an Arena slot ignores it (X is still a surge)")
	var t := _Rig.new()
	t.t = SimTouch.new()
	t.t.dp = 2.75
	t.opts = {"a_only": true}
	t.t.touch_down(1, 700.0, 300.0, "attack")
	ok(t.step() == "none", "a_only: touch Simple's Attack is not read in a clinch")
	t.t.touch_up(1)
	t.steps(8)
	t.t.touch_down(2, 600.0, 300.0, "guard")
	ok(t.step() == "letgo", "a_only: touch Simple's Guard is A")


class _Rig:
	var l: SimLayout = null
	var t: SimTouch = null
	var prev: SimIntent = null
	var opts: Dictionary = {}

	func step() -> String:
		var i: SimIntent = t.build() if t != null else l.build()
		var r: String = SimPressRead.struggle_press(prev, i, opts)
		prev = i
		if t != null:
			t.consumed()
		else:
			l.consumed()
		return r

	func steps(n: int) -> Array:
		var out: Array = []
		for k in range(n):
			out.append(step())
		return out


func _a(held: int, ld: int = 50) -> Dictionary:
	var e: Dictionary = {"kind": SimPressRead.CONTEXT, "mode": 0, "down": 100, "up": -1, "beat": SimPressRead.NO_BEAT, "flash": SimPressRead.NO_FLASH, "stance": 0, "ldown": ld}
	if held >= 0:
		e["up"] = 100 + held
		e["lup"] = ld + held
	return e


func _catch() -> void:
	var p: Dictionary = SimPressRead.params()
	ok(p["catchTell"] == 10, "catch: the tell is 10 (data)")
	ok(SimPressRead.catch_read(_a(-1), 50 + 5) == "tell" and SimPressRead.catch_read(_a(-1), 50 + 13) == "tell", "catch: down inside the tell and the grace (under 14) is the tell")
	ok(SimPressRead.catch_read(_a(-1), 50 + 14) == "carry", "catch: still down at 14 live ticks is the carry")
	for h in [2, 5, 10, 12, 14]:
		ok(SimPressRead.catch_read(_a(h), 500) == "tap", "catch: let go at %d is the tap (the clinch)" % h)
	ok(SimPressRead.catch_read(_a(15), 500) == "carry", "catch: let go at 15 was a carry's release")
	# A touch tap (5 to 12 ticks) is always the tap, on every device.
	var all_tap: bool = true
	for h in range(3, 13):
		all_tap = all_tap and SimPressRead.catch_read(_a(h), 500) == "tap"
	ok(all_tap, "catch: every tap from 3 to 12 ticks (pad, keyboard and touch) is a catch, never a carry")
	# The live clock, not the real one.
	var fz: Dictionary = {"kind": SimPressRead.CONTEXT, "mode": 0, "down": 100, "up": 130, "beat": SimPressRead.NO_BEAT, "flash": SimPressRead.NO_FLASH, "stance": 0, "ldown": 50, "lup": 61}
	ok(SimPressRead.catch_read(fz, 500) == "tap", "catch: a release made after a long freeze is read at its live point (11 of 14: a tap)")
	ok(SimPressRead.catch_read({"kind": SimPressRead.LIGHT, "down": 100, "up": -1}, 200) == "none" and SimPressRead.catch_read({"kind": SimPressRead.HEAVY, "down": 100, "up": 105}, 200) == "none", "catch: only A is read")
	var unstamped: Dictionary = {"kind": SimPressRead.CONTEXT, "mode": 0, "down": 100, "up": 105, "beat": SimPressRead.NO_BEAT, "flash": SimPressRead.NO_FLASH, "stance": 0}
	ok(SimPressRead.catch_read(unstamped, 500) == "tap", "catch: with no live stamps the real ticks stand in")
	# The numbers are data: a longer tell moves the line.
	var q: Dictionary = SimPressRead.params().duplicate()   # (params() is read-only)
	q["catchTell"] = 20
	ok(SimPressRead.catch_read(_a(-1), 50 + 14, q) == "tell" and SimPressRead.catch_read(_a(-1), 50 + 24, q) == "carry", "catch: the tell is data (20 gives a line at 24)")
	# Out of reach A keeps its own line: the tackle's coil at 16, not 14.
	ok(SimPressRead.charge_read(_a(-1), 50 + 14) == "winding" and SimPressRead.charge_read(_a(-1), 50 + 16) == "charge", "catch: out of reach, charge_read still has the tackle's coil at 16")


func _brace() -> void:
	ok(not SimPressRead.brace_read(_a(-1), 50 + 13)["braced"], "brace: down 13 live ticks is not yet")
	var b: Dictionary = SimPressRead.brace_read(_a(-1), 50 + 14)
	ok(b["braced"] and b["since"] == 0, "brace: still down at 14 is the brace, since 0")
	ok(SimPressRead.brace_read(_a(-1), 50 + 30)["since"] == 16, "brace: it counts the live ticks past its start")
	ok(not SimPressRead.brace_read(_a(30), 500)["braced"], "brace: letting go ends it")
	var none: bool = true
	for h in range(3, 13):
		none = none and not SimPressRead.brace_read(_a(h), 500)["braced"]
	ok(none, "brace: a tap of 3 to 12 ticks never braces")
	ok(not SimPressRead.brace_read({"kind": SimPressRead.HEAVY, "down": 100, "up": -1, "ldown": 50}, 50 + 40)["braced"], "brace: only A")
	# The catch's carry and the brace share one line: the same tick.
	ok(SimPressRead.catch_read(_a(-1), 50 + 14) == "carry" and SimPressRead.brace_read(_a(-1), 50 + 14)["braced"], "brace: the carry and the brace start on the same tick (14)")


func _a_read() -> void:
	# Off (today): the shove, the clinch by a second press, the coil.
	_no_sw()
	var one: Array = []
	SimPressRead.push(one, SimPressRead.CONTEXT, 0, 100, SimPressRead.NO_BEAT, -1, 0, 50)
	SimPressRead.release(one, SimPressRead.CONTEXT, 103, 53)
	ok(SimPressRead.a_read(one, 60)["read"] == "shove" and SimPressRead.a_read(one, 60)["throw_at"] == 62, "a_read off: a tap is the shove, thrown at 62")
	var two: Array = one.duplicate(true)
	SimPressRead.push(two, SimPressRead.CONTEXT, 0, 108, SimPressRead.NO_BEAT, -1, 0, 58)
	ok(SimPressRead.a_read(two, 60)["read"] == "clinch", "a_read off: a second A inside the shove's 12 ticks is the clinch")
	# On (the grapple): no shove, no clinch-by-mash; the tackle's coil stays.
	_sw(false, true)
	var r1: Dictionary = SimPressRead.a_read(one, 60)
	ok(r1["read"] == "tap" and r1["throw_at"] == -1, "a_read on: a tap is just a tap, with no shove thrown")
	var r2: Dictionary = SimPressRead.a_read(two, 60)
	ok(r2["read"] == "winding" and r2["taps"] == 0, "a_read on: a second A inside 12 ticks is a new press, not a clinch")
	var down: Array = []
	SimPressRead.push(down, SimPressRead.CONTEXT, 0, 100, SimPressRead.NO_BEAT, -1, 0, 50)
	ok(SimPressRead.a_read(down, 50 + 15)["read"] == "winding" and SimPressRead.a_read(down, 50 + 16)["read"] == "coil", "a_read on: the tackle's coil is still at 16")
	ok(absf(float(SimPressRead.a_read(down, 50 + 26)["frac"]) - 0.5) < 1e-9, "a_read on: and its share toward full as before")
	ok(SimPressRead.a_read([], 100)["read"] == "none", "a_read on: no A, nothing")
	# The option overrides the data either way.
	_no_sw()
	ok(SimPressRead.a_read(two, 60, {"grapple": true})["read"] == "winding" and SimPressRead.a_read(two, 60, {"grapple": false})["read"] == "clinch", "a_read: opts.grapple overrides the switch")
	_no_sw()
