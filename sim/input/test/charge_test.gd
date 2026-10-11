extends SceneTree
## Headless checks for the two slow-button settings (docs/controls/windup-read.md, section 2): a latched charge and charges off, on the
## pad, the keyboard and Full touch, through the hub per player, and not on the Simple layouts; plus a measure of how often a tap would
## read as a charge by device (against QA's bands). From the repo root:
##   godot --headless --path . --script res://sim/input/test/charge_test.gd
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
	_latch()
	_charges_off()
	_not_simple()
	_simple_cells()
	_hub()
	_touch()
	_tap_reads_as_hold()
	print("charge_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _mk(id: String) -> SimLayout:
	return SimLayout.new(SimInputData.preset(id))


func _run(l: SimLayout, n: int) -> SimIntent:
	var i: SimIntent = null
	for k in range(n):
		i = l.build()
		l.consumed()
	return i


## The slow button of a layout and the levels it makes: [control, edge name, level name].
func _slow(layout: String) -> Array:
	if layout == "arena":
		return [["pad:north", "heavy", "heavyHeld"], ["pad:east", "sig", "sigHeld"], ["pad:south", "context", "contextHeld"]]
	return [["kb:KeyK", "heavy", "heavyHeld"], ["kb:KeyL", "sig", "sigHeld"], ["kb:KeyI", "context", "contextHeld"]]


func _latch() -> void:
	for lay in ["arena", "kb-solo"]:
		for s in _slow("arena" if lay == "arena" else "kb"):
			var tag: String = "latch %s %s" % [lay, s[2]]
			var l: SimLayout = _mk(lay)
			l.set_latch_charge(true)
			l.press(s[0])
			var i: SimIntent = l.build()
			ok(i.get(s[1]) and i.get(s[2]), "%s: the press is an edge with its level on" % tag)
			l.consumed()
			_run(l, 3)
			l.release(s[0])
			i = _run(l, 30)
			ok(i.get(s[2]) and not i.get(s[1]), "%s: after the finger leaves the level stays on (the charge is latched), with no edge" % tag)
			# The next press lets it go: the level falls and no edge is sent.
			l.press(s[0])
			i = l.build()
			ok(not i.get(s[2]) and not i.get(s[1]), "%s: the next press lets it go: level down, no edge" % tag)
			l.consumed()
			_run(l, 2)
			l.release(s[0])
			i = _run(l, 3)
			ok(not i.get(s[2]) and not i.get(s[1]), "%s: and its release does nothing" % tag)
			# Then a fresh press starts a new wind-up.
			l.press(s[0])
			i = l.build()
			ok(i.get(s[1]) and i.get(s[2]), "%s: the press after that is a new edge" % tag)
	# The light is not a slow button: it is unaffected.
	var lx: SimLayout = _mk("arena")
	lx.set_latch_charge(true)
	lx.press("pad:west")
	_run(lx, 3)
	lx.release("pad:west")
	ok(not _run(lx, 3).lightHeld, "latch: X is not latched (the burst is a hold, not a charge)")
	# Switching it off lets a latched charge go.
	var ly: SimLayout = _mk("arena")
	ly.set_latch_charge(true)
	ly.press("pad:north")
	_run(ly, 3)
	ly.release("pad:north")
	ok(_run(ly, 5).heavyHeld, "latch: latched")
	ly.set_latch_charge(false)
	ok(not _run(ly, 2).heavyHeld, "latch: turning the setting off lets it go")
	# Two buttons latched at once are independent.
	var lb: SimLayout = _mk("arena")
	lb.set_latch_charge(true)
	lb.press("pad:north")
	_run(lb, 2)
	lb.release("pad:north")
	lb.press("pad:east")
	_run(lb, 2)
	lb.release("pad:east")
	var both: SimIntent = _run(lb, 4)
	ok(both.heavyHeld and both.sigHeld, "latch: Y and B latch independently")
	lb.press("pad:north")
	var rel: SimIntent = lb.build()
	ok(not rel.heavyHeld and rel.sigHeld, "latch: pressing Y lets only Y go")
	# Off by default.
	var d: SimLayout = _mk("arena")
	d.press("pad:north")
	_run(d, 3)
	d.release("pad:north")
	ok(not _run(d, 3).heavyHeld, "latch: off by default, a release is a release")
	# A re-press inside the contact debounce (2 ticks) is the same press: the latch is not let go by a bounce.
	var db: SimLayout = _mk("arena")
	db.set_latch_charge(true)
	db.press("pad:north")
	_run(db, 3)
	db.release("pad:north")
	_run(db, 1)
	db.press("pad:north")
	var bi: SimIntent = db.build()
	ok(bi.heavyHeld and not bi.heavy, "latch: a bounce 1 tick after the release is the same press: still latched, no edge")


func _charges_off() -> void:
	for lay in ["arena", "kb-solo"]:
		for s in _slow("arena" if lay == "arena" else "kb"):
			var tag: String = "charges off %s %s" % [lay, s[2]]
			var l: SimLayout = _mk(lay)
			l.set_charges_off(true)
			l.press(s[0])
			var i: SimIntent = l.build()
			ok(i.get(s[1]) and i.get(s[2]), "%s: the press is an edge with its level on, on its own tick" % tag)
			l.consumed()
			i = _run(l, 20)
			ok(not i.get(s[2]) and not i.get(s[1]), "%s: held 20 ticks it reports nothing more: a press is always a tap" % tag)
			l.release(s[0])
			ok(not _run(l, 3).get(s[2]), "%s: and the release changes nothing" % tag)
	# The light and the layer's signature (RT + B, the ultimate's hold) keep their holds.
	var l2: SimLayout = _mk("arena")
	l2.set_charges_off(true)
	l2.press("pad:west")
	ok(_run(l2, 20).lightHeld, "charges off: X keeps its level (the burst)")
	l2.release("pad:west")
	_run(l2, 3)
	l2.press("pad:rt")
	_run(l2, 4)
	l2.press("pad:east")
	ok(_run(l2, 30).sigHeld, "charges off: RT + B keeps its hold (the signature's ladder is not a slow-button charge)")
	# Both on: charges off wins.
	var l3: SimLayout = _mk("arena")
	l3.set_latch_charge(true)
	l3.set_charges_off(true)
	l3.press("pad:north")
	_run(l3, 3)
	l3.release("pad:north")
	ok(not _run(l3, 3).heavyHeld, "charges off: with both on, nothing is latched")


func _not_simple() -> void:
	var l: SimLayout = _mk("simple-pad")
	l.set_latch_charge(true)
	l.set_charges_off(true)
	l.press("pad:west")
	var i: SimIntent = _run(l, 13)
	ok(i.heavyHeld, "simple: the attack hold still reaches the medium with both settings on (a weight, not a charge)")
	l.release("pad:west")
	i = l.build()
	ok(i.heavy, "simple: and the release is the medium")
	l.consumed()
	l.press("pad:north")
	i = l.build()
	ok(i.sig and i.sigHeld, "simple: the signature button is untouched by charges off")


## Simple's two ways to a heavy, and how the director tells them apart without a new bit: Y's `signature` edge always has its level ON
## on the tick of its press (the wind-up starts then); the Attack's heavy (held past 28 live ticks) is a `signature` edge with its level
## OFF (the hold was the wind-up and it is over). LB is Context, A's cell.
func _simple_cells() -> void:
	var l: SimLayout = _mk("simple-pad")
	l.press("pad:north")
	var y: SimIntent = l.build()
	ok(y.sig and y.sigHeld and y.stanceMask == 0, "simple Y: a tap is a signature edge (B's cell) with its level on, in the martial stance")
	l.consumed()
	_run(l, 5)
	l.release("pad:north")
	ok(not _run(l, 2).sigHeld, "simple Y: and letting go is the level falling")
	_run(l, 3)
	l.press("pad:west")
	_run(l, 30)
	l.release("pad:west")
	var a: SimIntent = l.build()
	ok(a.sig and not a.sigHeld and not a.light and not a.heavy, "simple Attack: held past 28 the release is a signature edge with its level OFF: already wound")
	l.consumed()
	_run(l, 3)
	# RT + Y is the layer's signature: the same edge, level on, in the charging stance (4); the hold is the ladder.
	l.analog("pad:rt", 0.9)
	_run(l, 3)
	l.press("pad:north")
	var ry: SimIntent = l.build()
	ok(ry.sig and ry.sigHeld and ry.stanceMask == 4 and ry.special == 0, "simple RT+Y: a signature edge with its level on, in the charging stance")
	l.consumed()
	ok(_run(l, 30).sigHeld, "simple RT+Y: held, the level stays on (the ladder)")
	l.release("pad:north")
	l.analog("pad:rt", 0.0)
	_run(l, 4)
	# LB is Context (A's cell): an edge, and its level while held, which is what the director logs as the CONTEXT kind.
	l.press("pad:lb")
	var c: SimIntent = l.build()
	ok(c.context and c.contextHeld and not c.special, "simple LB: Context, an edge with its level on")
	l.consumed()
	ok(_run(l, 20).contextHeld, "simple LB: held, contextHeld stays on (the coil, the clinch's taps)")
	l.release("pad:lb")
	ok(not _run(l, 2).contextHeld, "simple LB: and falls on release")
	# And no tap fires the signature: B on Simple is guard, A dodge.
	var g: SimLayout = _mk("simple-pad")
	g.press("pad:east")
	ok(g.build().guard and not g.build().sig, "simple B: guard, no signature")
	var d: SimLayout = _mk("simple-pad")
	d.press("pad:south")
	ok(d.build().dodge and not d.build().sig, "simple A: dodge, no signature")


func _hub() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, true)
	hub.pad_button(3, "south", true)
	hub.pad_button(3, "south", false)
	hub.pad_button(9, "south", true)
	hub.pad_button(9, "south", false)
	hub.consumed()
	ok(not hub.latch_charge_of(0) and not hub.latch_charge_of(1) and not hub.charges_off_of(0) and not hub.charges_off_of(1), "hub: both settings are off by default")
	hub.set_latch_charge(true, 1)
	ok(not hub.latch_charge_of(0) and hub.latch_charge_of(1), "hub: a player turns the latch on for themselves")
	hub.set_charges_off(true, 0)
	ok(hub.charges_off_of(0) and not hub.charges_off_of(1), "hub: and charges off for themselves")
	# Player two (device 9) latches Y; player one (device 3) with charges off does not.
	hub.pad_button(9, "north", true)
	hub.intent(0)
	hub.intent(1)
	hub.consumed()
	hub.pad_button(9, "north", false)
	for k in range(6):
		hub.intent(0)
		hub.intent(1)
		hub.consumed()
	ok(hub.intent(1).heavyHeld, "hub: player two's Y is latched")
	hub.consumed()
	hub.pad_button(3, "north", true)
	var p1: SimIntent = hub.intent(0)
	ok(p1.heavy and p1.heavyHeld, "hub: player one's press is an edge with its level")
	hub.consumed()
	for k in range(5):
		p1 = hub.intent(0)
		hub.intent(1)
		hub.consumed()
	ok(not p1.heavyHeld, "hub: and with charges off it is not held after that, though the finger is down")
	hub.set_latch_charge(false)
	hub.set_charges_off(false)
	ok(not hub.latch_charge_of(1) and not hub.charges_off_of(0), "hub: -1 sets both players")


func _touch() -> void:
	var t := SimTouch.new()
	t.dp = 2.75
	t.set_preset("touch-full")
	t.set_stance_oneshot(false)
	t.set_latch_charge(true)
	t.touch_down(1, 0.0, 0.0, "heavy")
	var i: SimIntent = t.build()
	ok(i.heavy and i.heavyHeld, "touch Full latch: the press is an edge with its level")
	t.consumed()
	t.touch_up(1)
	var held: bool = true
	for k in range(30):
		i = t.build()
		held = held and i.heavyHeld
		t.consumed()
	ok(held and not i.heavy, "touch Full latch: the level stays on after the finger leaves")
	t.touch_down(2, 0.0, 0.0, "heavy")
	i = t.build()
	ok(not i.heavyHeld and not i.heavy, "touch Full latch: the next touch lets it go with no edge")
	t.consumed()
	t.touch_up(2)
	ok(not _tb(t, 3).heavyHeld, "touch Full latch: and its release does nothing")
	var u := SimTouch.new()
	u.dp = 2.75
	u.set_preset("touch-full")
	u.set_stance_oneshot(false)
	u.set_charges_off(true)
	u.touch_down(1, 0.0, 0.0, "signature")
	i = u.build()
	ok(i.sig and i.sigHeld, "touch Full charges off: the press is an edge with its level")
	u.consumed()
	ok(not _tb(u, 10).sigHeld, "touch Full charges off: held, it reports nothing more")
	# Simple touch ignores both.
	var s := SimTouch.new()
	s.dp = 2.75
	s.set_latch_charge(true)
	s.set_charges_off(true)
	s.touch_down(1, 700.0, 300.0, "attack")
	for k in range(13):
		s.build()
		s.consumed()
	ok(s.build().heavyHeld, "touch Simple: the attack hold is a weight: both settings are ignored")


func _tb(t: SimTouch, n: int) -> SimIntent:
	var last: SimIntent = null
	for k in range(n):
		last = t.build()
		t.consumed()
	return last


## How often a tap would read as a charge, by device. The tap lengths are MODELLED from the ranges in docs/controls/q19-input.md (pad
## 3 to 6 ticks, keyboard 4 to 8, touch 5 to 12, each with a small tail of lingering presses): they are assumptions to be replaced by
## QA's measured ones, not measurements. A press reads as a charge when it is still down at wind-up plus grace (Y 16, B 32, A 16).
## QA's bands: under 2% on pad and keyboard, under 5% on touch.
func _tap_reads_as_hold() -> void:
	var rng := SimRng.new(20261006)
	var models: Dictionary = {
		"pad": [3, 4.5, 6, 0.003, 6, 14],
		"keyboard": [4, 6.0, 8, 0.005, 8, 16],
		"touch": [5, 8.0, 12, 0.03, 12, 24],
	}
	var bands: Dictionary = {"pad": 0.02, "keyboard": 0.02, "touch": 0.05}
	var p: Dictionary = SimPressRead.params()
	for dev in models:
		var m: Array = models[dev]
		for kind in [SimPressRead.LIGHT, SimPressRead.HEAVY, SimPressRead.CONTEXT, SimPressRead.SIG]:
			var n: int = 20000
			var charge: int = 0
			for k in range(n):
				var held: int
				if rng.next() < float(m[3]):
					held = int(round(float(m[4]) + rng.next() * float(m[5] - m[4])))   # a lingering press
				else:
					# a triangular distribution on [lo, hi] with mode `mid`
					var u: float = rng.next()
					var lo: float = float(m[0])
					var mid: float = float(m[1])
					var hi: float = float(m[2])
					var f: float = (mid - lo) / (hi - lo)
					var v: float = lo + sqrt(u * (hi - lo) * (mid - lo)) if u < f else hi - sqrt((1.0 - u) * (hi - lo) * (hi - mid))
					held = int(round(v))
				var e: Dictionary = {"kind": kind, "stance": 0, "down": 100, "up": 100 + held, "ldown": 50, "lup": 50 + held}
				if kind == SimPressRead.LIGHT:
					# X has no wind-up: the question is whether the tap was long enough to start the burst (still down at burstStart).
					var still: Dictionary = {"kind": kind, "stance": 0, "down": 100, "up": -1, "ldown": 50}
					if SimPressRead.burst_read(still, 50 + held, p)["ready"]:
						charge += 1
				elif SimPressRead.charge_read(e, 1000, p) == "charge":
					charge += 1
			var rate: float = float(charge) / float(n)
			ok(rate < float(bands[dev]), "tap read: a %s tap on kind %d reads as a charge (X: starts the burst at 16) %.2f%% of the time (band under %.0f%%; modelled lengths)" % [dev, kind, rate * 100.0, float(bands[dev]) * 100.0])
			print("  tap read as charge: ", dev, " kind ", kind, " ", snapped(rate * 100.0, 0.01), "%")
