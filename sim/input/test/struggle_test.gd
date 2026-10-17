extends SceneTree
## Headless checks for the beam struggle's press (SimPressRead.struggle_press, docs/controls/struggle-input.md): what a press, a release and a
## hold read as on Arena, the keyboards, Full touch, the Simple pad and Simple touch, under RT, with the latched charge and charges off,
## and the traps (a Simple tap counts once, a tier change is no press, a flick and a guard are nothing). The reads run on intents built by
## the real layouts. From the repo root:
##   godot --headless --path . --script res://sim/input/test/struggle_test.gd
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
	_edges()
	_layer()
	_latched()
	_simple_pad()
	_simple_touch()
	_full_touch()
	_misc()
	print("struggle_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


## One driver for a layout or a touch: build, read against the last, consume (a live step).
class Rig:
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


func _rig(id: String) -> Rig:
	var r := Rig.new()
	r.l = SimLayout.new(SimInputData.preset(id))
	return r


func _count(a: Array, what: String) -> int:
	var n: int = 0
	for x in a:
		if x == what:
			n += 1
	return n


## A press and its hold and release read as exactly one `what` (on the press tick) and nothing else.
func _once(r: Rig, press: String, what: String, tag: String, hold: int = 20) -> void:
	r.l.press(press)
	var a: Array = r.steps(1)
	ok(a[0] == what, "%s: the press tick reads %s (got %s)" % [tag, what, str(a[0])])
	var rest: Array = r.steps(hold)
	r.l.release(press)
	rest.append_array(r.steps(6))
	ok(_count(rest, "none") == rest.size(), "%s: holding and letting go read nothing more" % tag)


func _edges() -> void:
	for lay in [["arena", ["pad:west", "pad:north", "pad:east", "pad:south"]], ["kb-solo", ["kb:KeyJ", "kb:KeyK", "kb:KeyL", "kb:KeyI"]], ["kb-shared-p1", ["kb:KeyF", "kb:KeyG", "kb:KeyR", "kb:KeyV"]], ["kb-shared-p2", ["kb:KeyH", "kb:KeyM", "kb:KeyU", "kb:Comma"]]]:
		var names: Array = ["X", "Y", "B", "A"]
		var want: Array = ["surge", "surge", "surge", "letgo"]
		var keys: Array = lay[1]
		for k in range(4):
			var r: Rig = _rig(lay[0])
			_once(r, keys[k], want[k], "%s %s" % [lay[0], names[k]])
	# Nothing else is a press: guard, energy, the boost, the stance buttons, the stick, escape.
	var r2: Rig = _rig("arena")
	for c in ["pad:lb", "pad:rb", "pad:lt", "pad:r3"]:
		r2.l.press(c)
		var a: Array = r2.steps(12)
		r2.l.release(c)
		a.append_array(r2.steps(6))
		ok(_count(a, "none") == a.size(), "arena: %s is no press in a struggle" % c)
	r2.l.axis("pad:ls", 1.0, 0.0)
	ok(_count(r2.steps(10), "none") == 10, "arena: the stick is no press")


func _layer() -> void:
	# Under RT the face buttons are the layer: X, Y and A are special 1, 2 and 3; B is still sig.
	var cases: Array = [["pad:west", "surge", "X"], ["pad:north", "surge", "Y"], ["pad:south", "letgo", "A"], ["pad:east", "surge", "B"]]
	for c in cases:
		var r: Rig = _rig("arena")
		r.l.press("pad:rt")
		r.steps(5)
		r.l.press(c[0])
		var a: Array = r.steps(1)
		ok(a[0] == c[1], "under RT: %s reads %s (got %s)" % [c[2], c[1], str(a[0])])
		ok(_count(r.steps(10), "none") == 10, "under RT: %s then reads nothing while held" % c[2])
	var rt: Rig = _rig("arena")
	rt.l.press("pad:rt")
	ok(_count(rt.steps(8), "none") == 8, "under RT: pressing RT itself is no press")


func _latched() -> void:
	# A latched Y: the first press is an edge and a rise (one surge); the finger leaving changes nothing; the second press is a level
	# FALL with no edge: it is a press only if the director says the slot is latched.
	for latched in [true, false]:
		var r: Rig = _rig("arena")
		r.l.set_latch_charge(true)
		r.opts = {"latched": latched}
		r.l.press("pad:north")
		var a1: Array = r.steps(1)
		ok(a1[0] == "surge", "latched Y: the first press is a surge")
		r.steps(3)
		r.l.release("pad:north")
		ok(_count(r.steps(30), "none") == 30, "latched Y: the finger leaving is no press")
		r.l.press("pad:north")
		var a2: Array = r.steps(1)
		ok(a2[0] == ("surge" if latched else "none"), "latched Y: the second press (a level fall, no edge) reads %s when the slot is %s" % ["a surge" if latched else "nothing", "latched" if latched else "not told it is"])
		r.l.release("pad:north")
		ok(_count(r.steps(6), "none") == 6, "latched Y: and its release is nothing")
	# The same for A, as the let-go, and for B.
	var ra: Rig = _rig("arena")
	ra.l.set_latch_charge(true)
	ra.opts = {"latched": true}
	ra.l.press("pad:south")
	ok(ra.steps(1)[0] == "letgo", "latched A: the first press is the let-go")
	ra.l.release("pad:south")
	ra.steps(10)
	ra.l.press("pad:south")
	ok(ra.steps(1)[0] == "letgo", "latched A: the second press (a level fall) is the let-go too")
	var rb: Rig = _rig("arena")
	rb.l.set_latch_charge(true)
	rb.opts = {"latched": true}
	rb.l.press("pad:east")
	ok(rb.steps(1)[0] == "surge", "latched B: the first press is a surge")
	rb.l.release("pad:east")
	rb.steps(10)
	rb.l.press("pad:east")
	ok(rb.steps(1)[0] == "surge", "latched B: the second press is a surge")
	# The light is not latched: X is the same with the setting on.
	var rx: Rig = _rig("arena")
	rx.l.set_latch_charge(true)
	rx.opts = {"latched": true}
	rx.l.press("pad:west")
	ok(rx.steps(1)[0] == "surge", "latched setting: X still surges on its press")
	rx.l.release("pad:west")
	ok(_count(rx.steps(8), "none") == 8, "latched setting: and its release is nothing")
	# Charges off: the edge on the press tick, nothing after.
	var ro: Rig = _rig("arena")
	ro.l.set_charges_off(true)
	ro.l.press("pad:north")
	ok(ro.steps(1)[0] == "surge" and _count(ro.steps(20), "none") == 20, "charges off: Y surges on its press tick and reads nothing held")


func _simple_pad() -> void:
	var r: Rig = _rig("simple-pad")
	# Attack tapped: one surge on the press (the rising level), nothing on the release edge (its level is off).
	r.l.press("pad:west")
	ok(r.steps(1)[0] == "surge", "simple pad: Attack's press is a surge, on its own tick")
	r.steps(4)
	r.l.release("pad:west")
	var rel: Array = r.steps(1)
	ok(rel[0] == "none", "simple pad: the Attack's release edge is never a press (a tap counts once)")
	ok(_count(r.steps(6), "none") == 6, "simple pad: and nothing after")
	# Attack held through both tiers: the level moves light, medium, heavy: no press at 12 or 28.
	r.l.press("pad:west")
	var held: Array = r.steps(35)
	ok(held[0] == "surge" and _count(held, "surge") == 1 and _count(held, "letgo") == 0, "simple pad: a held Attack is one surge: its tier changes at 12 and 28 are not presses")
	r.l.release("pad:west")
	ok(_count(r.steps(8), "none") == 8, "simple pad: and the heavy's release edge (level off) is nothing")
	# Y: a signature edge with its level on is a press; its hold and release are not.
	r.l.press("pad:north")
	ok(r.steps(1)[0] == "surge", "simple pad: Y's press is a surge")
	ok(_count(r.steps(20), "none") == 20, "simple pad: holding Y reads nothing more")
	r.l.release("pad:north")
	r.steps(6)
	# Guard (B) is the let-go; LB (Context, A's cell) is too; the Dodge (A) is nothing.
	r.l.press("pad:east")
	ok(r.steps(1)[0] == "letgo", "simple pad: Guard's press is the let-go")
	ok(_count(r.steps(10), "none") == 10, "simple pad: holding Guard reads nothing more")
	r.l.release("pad:east")
	r.steps(6)
	r.l.press("pad:lb")
	ok(r.steps(1)[0] == "letgo", "simple pad: LB (Context, A's cell) is the let-go too")
	r.l.release("pad:lb")
	r.steps(6)
	r.l.press("pad:south")
	var dodge: Array = r.steps(8)
	ok(_count(dodge, "none") == dodge.size(), "simple pad: the Dodge is no press")
	r.l.release("pad:south")
	r.steps(6)
	# RT + Attack (the director's special) and RT + Y (the signature's hold) are surges.
	r.l.analog("pad:rt", 0.9)
	r.steps(4)
	r.l.press("pad:west")
	ok(r.steps(1)[0] == "surge", "simple pad: RT + Attack (special) is a surge")
	r.l.release("pad:west")
	r.steps(6)
	r.l.press("pad:north")
	ok(r.steps(1)[0] == "surge", "simple pad: RT + Y is a surge")
	# Two quick Attack taps (a mash): each is a surge, each release nothing.
	var m: Rig = _rig("simple-pad")
	var res: Array = []
	for k in range(3):
		m.l.press("pad:west")
		res.append_array(m.steps(1))
		res.append_array(m.steps(2))
		m.l.release("pad:west")
		res.append_array(m.steps(1))
		res.append_array(m.steps(5))
	ok(_count(res, "surge") == 3 and _count(res, "letgo") == 0, "simple pad: three quick taps are three surges and no more")


func _simple_touch() -> void:
	var r := Rig.new()
	r.t = SimTouch.new()
	r.t.dp = 2.75
	r.t.touch_down(1, 700.0, 300.0, "attack")
	ok(r.steps(1)[0] == "surge", "simple touch: Attack's touch is a surge, on its own tick")
	r.steps(5)
	r.t.touch_up(1)
	ok(_count(r.steps(8), "none") == 8, "simple touch: its release (an edge with the level off) is nothing")
	# Held through the tiers: one surge.
	r.t.touch_down(2, 700.0, 300.0, "attack")
	var held: Array = r.steps(32)
	ok(_count(held, "surge") == 1 and _count(held, "letgo") == 0, "simple touch: a held Attack is one surge (the tiers at 12 and 28 are no press)")
	r.t.touch_up(2)
	r.steps(8)
	# Guard is the let-go; Power is nothing.
	r.t.touch_down(3, 600.0, 300.0, "guard")
	ok(r.steps(1)[0] == "letgo", "simple touch: Guard's touch is the let-go")
	r.t.touch_up(3)
	r.steps(8)
	r.t.touch_down(4, 500.0, 300.0, "power")
	var p: Array = r.steps(6)
	r.t.touch_up(4)
	p.append_array(r.steps(6))
	ok(_count(p, "none") == p.size(), "simple touch: Power is no press")
	# A flick on the stick is nothing: it must never be the let-go.
	r.t.touch_down(5, 200.0, 700.0, "stick")
	r.t.touch_move(5, 200.0 + 60.0 * 2.75, 700.0)
	var f: Array = r.steps(12)
	r.t.touch_up(5)
	f.append_array(r.steps(6))
	ok(_count(f, "none") == f.size(), "simple touch: a flick-to-dodge is no press and never the let-go")
	# A swipe up on Attack is two presses (the touch, then Y's edge): the director sees a stray.
	var s := Rig.new()
	s.t = SimTouch.new()
	s.t.dp = 2.75
	s.t.touch_down(6, 700.0, 300.0, "attack")
	var a1: Array = s.steps(2)
	s.t.touch_move(6, 702.0, 300.0 - 41.0 * 2.75)
	var a2: Array = s.steps(1)
	ok(a1[0] == "surge" and a2[0] == "surge", "simple touch: a swipe up on Attack reads two surges (the touch, then the swipe's Y): a stray for the director")


func _full_touch() -> void:
	var r := Rig.new()
	r.t = SimTouch.new()
	r.t.dp = 2.75
	r.t.set_preset("touch-full")
	r.t.set_stance_oneshot(false)
	var id: int = 1
	for c in [["light", "surge"], ["heavy", "surge"], ["signature", "surge"], ["context", "letgo"]]:
		r.t.touch_down(id, 0.0, 0.0, c[0])
		ok(r.steps(1)[0] == c[1], "full touch: %s reads %s" % [c[0], c[1]])
		var rest: Array = r.steps(15)
		r.t.touch_up(id)
		rest.append_array(r.steps(6))
		ok(_count(rest, "none") == rest.size(), "full touch: %s held and let go reads nothing more" % c[0])
		id += 1
	for w in ["guard", "dodge", "mode", "power"]:
		r.t.touch_down(id, 0.0, 0.0, w)
		var a: Array = r.steps(8)
		r.t.touch_up(id)
		a.append_array(r.steps(6))
		ok(_count(a, "none") == a.size(), "full touch: %s is no press" % w)
		id += 1
	# A latched Full touch Y: the second touch is a level fall.
	var l := Rig.new()
	l.t = SimTouch.new()
	l.t.dp = 2.75
	l.t.set_preset("touch-full")
	l.t.set_stance_oneshot(false)
	l.t.set_latch_charge(true)
	l.opts = {"latched": true}
	l.t.touch_down(20, 0.0, 0.0, "heavy")
	var f1: Array = l.steps(1)
	l.t.touch_up(20)
	l.steps(10)
	l.t.touch_down(21, 0.0, 0.0, "heavy")
	var f2: Array = l.steps(1)
	ok(f1[0] == "surge" and f2[0] == "surge", "full touch latched: both touches of Y read as surges")


func _misc() -> void:
	# Pure, null-safe, and the let-go wins a tie.
	var i := SimIntent.new()
	i.mode = 0   # a bare SimIntent has mode -1, which is a Simple slot's; a scripted player sets it as a layout does
	i.light = true
	ok(SimPressRead.struggle_press(null, i) == "surge" and SimPressRead.struggle_press(null, SimIntent.new()) == "none", "misc: a null previous reads as an idle intent")
	var bare := SimIntent.new()
	bare.light = true
	ok(SimPressRead.struggle_press(null, bare) == "none", "misc: a bare intent (mode -1) reads as Simple: a light edge with no level is a release, not a press")
	bare.lightHeld = true
	ok(SimPressRead.struggle_press(null, bare) == "surge", "misc: ... and with its level on (as QA's scripted presses set it) it is the press")
	var both := SimIntent.new()
	both.mode = 0
	both.light = true
	both.context = true
	ok(SimPressRead.struggle_press(null, both) == "letgo", "misc: a surge and a let-go on one tick read as the let-go")
	var a := SimIntent.new()
	a.mode = 0
	a.heavy = true
	ok(SimPressRead.struggle_press(SimIntent.new(), a) == SimPressRead.struggle_press(SimIntent.new(), a), "misc: the same intents read the same")
	# Reading changes no intent: the intent that was read is untouched.
	var b := SimIntent.new()
	b.mode = 0
	b.sig = true
	b.sigHeld = true
	var before: int = SimIntent.pack(b)
	SimPressRead.struggle_press(null, b, {"latched": true})
	ok(SimIntent.pack(b) == before, "misc: reading an intent does not change it")
	# A Simple tier change is not a press: light held, then medium held (light falls as heavy rises).
	var p := SimIntent.new()
	p.mode = -1
	p.lightHeld = true
	var q := SimIntent.new()
	q.mode = -1
	q.heavyHeld = true
	ok(SimPressRead.struggle_press(p, q) == "none", "misc: Simple's light level becoming the medium level is no press")
	var y := SimIntent.new()
	y.mode = -1
	y.sigHeld = true
	ok(SimPressRead.struggle_press(q, y) == "none", "misc: nor the medium level becoming the heavy's (no edge)")
	y.sig = true
	ok(SimPressRead.struggle_press(SimIntent.new(), y) == "surge", "misc: but Y's signature edge with its level on is a press")
	var w := SimIntent.new()
	w.mode = -1
	w.sig = true
	ok(SimPressRead.struggle_press(q, w) == "none", "misc: and a signature edge with its level off (an already-wound heavy) is not")
