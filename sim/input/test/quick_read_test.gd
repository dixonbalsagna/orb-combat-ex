extends SceneTree
## Headless checks for the quick read (docs/controls/responsiveness.md; timing.json switches.quickRead, off): the strike and brace settle one tick sooner, the
## vanish resolves on the second press, the stick publishes a pre-read for the pose, and none of it loosens the no-claw law, changes the swapped layout's
## stream, or changes anything while the switch is off. From the repo root:
##   godot --headless --path . --script res://sim/input/test/quick_read_test.gd
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
	_sw(true, false)
	var base: Dictionary = _timings()
	_sw(true, true)
	var quick: Dictionary = _timings()
	_off(base)
	_sooner(base, quick)
	_pre()
	_law()
	_swap()
	_sw(false, false)
	_off_switch()
	print("quick_read_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(right: bool, quick: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = right
	sw["quickRead"] = quick
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _pad(preset: String = "arena") -> SimLayout:
	return SimLayout.new(SimInputData.preset(preset))


func _first(its: Array, what: String) -> int:
	for t in range(its.size()):
		var i: SimIntent = its[t]
		match what:
			"rsStart": if i.rsStart: return t
			"rsRelease": if i.rsRelease: return t
			"brace": if i.brace: return t
			"escape": if i.escape: return t
			"light": if i.light: return t
	return -1


## A flick on the strike stick from rest at tick 10: full push in `ramp` ticks, held 4, back in 3. Returns the intents.
func _flick(l: SimLayout, ramp: int, ticks: int = 40, ang: float = 0.0) -> Array:
	var out: Array = []
	for t in range(ticks):
		var k: int = t - 10
		var m: float = 0.0
		if k >= 0 and k < ramp:
			m = float(k + 1) / float(ramp)
		elif k >= ramp and k < ramp + 4:
			m = 1.0
		elif k >= ramp + 4 and k < ramp + 7:
			m = 1.0 - float(k - ramp - 3) / 3.0
		l.axis("pad:rs", cos(deg_to_rad(ang)) * m, sin(deg_to_rad(ang)) * m)
		out.append(l.build())
		l.consumed()
	return out


## The numbers this file compares, under the current switches: strike start by ramp, brace flick, vanish by gap.
func _timings() -> Dictionary:
	var d: Dictionary = {}
	for ramp in [1, 2, 3, 4]:
		var its: Array = _flick(_pad(), ramp)
		d["start%d" % ramp] = _first(its, "rsStart") - 10
		d["dir%d" % ramp] = (its[_first(its, "rsStart")] as SimIntent).rsDir
	var l: SimLayout = _pad()
	l.press("pad:lb")
	var got: int = -1
	for t in range(40):
		var k: int = t - 15
		l.axis("pad:ls", 0.0, 1.0 if k >= 0 and k < 8 else 0.0)
		var i: SimIntent = l.build()
		if i.brace and got < 0:
			got = k
		l.consumed()
	d["brace"] = got
	for g in [0, 3, 6]:
		var lv: SimLayout = _pad()
		var e: int = -1
		for t in range(30):
			if t == 5:
				lv.press("pad:lb")
			if t == 5 + g:
				lv.analog("pad:lt", 1.0)
			var iv: SimIntent = lv.build()
			if iv.escape and e < 0:
				e = t - 5
			lv.consumed()
		d["vanish%d" % g] = e
	return d


func _off(base: Dictionary) -> void:
	ok(base["start3"] == 4 and base["start1"] == 2, "off: a ramp-3 flick starts 4 ticks after the thumb moved, a ramp-1 flick 2 (the settle of 2): %s %s" % [base["start3"], base["start1"]])
	ok(base["vanish0"] == 6 and base["vanish3"] == 6 and base["vanish6"] == 8, "off: the vanish resolves at the later of the window and the second press + 2 (6, 6, 8): %s %s %s" % [base["vanish0"], base["vanish3"], base["vanish6"]])


func _sooner(base: Dictionary, quick: Dictionary) -> void:
	for ramp in [1, 2, 3, 4]:
		ok(quick["start%d" % ramp] == base["start%d" % ramp] - 1, "quick: a ramp-%d flick starts one tick sooner (%s -> %s)" % [ramp, base["start%d" % ramp], quick["start%d" % ramp]])
		ok(quick["dir%d" % ramp] == base["dir%d" % ramp] and quick["dir%d" % ramp] == SimStrikeRead.RIGHT, "quick: the locked direction is the same (right) at ramp %d" % ramp)
	ok(quick["brace"] == base["brace"] - 1, "quick: the flick brace is one tick sooner (%s -> %s)" % [base["brace"], quick["brace"]])
	ok(quick["vanish0"] == 2 and quick["vanish3"] == 5 and quick["vanish6"] == 8, "quick: the vanish resolves on the second press + 2 (2, 5, 8; was 6, 6, 8): %s %s %s" % [quick["vanish0"], quick["vanish3"], quick["vanish6"]])
	# A vanish with the stick already leaning keeps the direction.
	var l: SimLayout = _pad()
	var vy: float = -9.0
	for t in range(30):
		if t >= 3:
			l.axis("pad:ls", 0.0, 1.0)
		if t == 5:
			l.press("pad:lb")
			l.analog("pad:lt", 1.0)
		var i: SimIntent = l.build()
		if i.escape and vy < -5.0:
			vy = i.my
		l.consumed()
	ok(vy > 0.5, "quick: a vanish with the stick leaning up before the presses is sent up (my %.2f)" % vy)
	# A guard and a dodge more than the window apart are no vanish, quick or not.
	var l2: SimLayout = _pad()
	var any_escape: bool = false
	for t in range(40):
		if t == 5:
			l2.press("pad:lb")
		if t == 14:
			l2.analog("pad:lt", 1.0)
		if l2.build().escape:
			any_escape = true
		l2.consumed()
	ok(not any_escape, "quick: LT 9 ticks after LB is the plain dodge out of guard, no vanish")
	# One of the two let go before the second press + 2: no vanish.
	var l3: SimLayout = _pad()
	var esc3: bool = false
	for t in range(30):
		if t == 5:
			l3.press("pad:lb")
			l3.analog("pad:lt", 1.0)
		if t == 6:
			l3.release("pad:lb")
		if l3.build().escape:
			esc3 = true
		l3.consumed()
	ok(not esc3, "quick: LB let go the next tick: no vanish")


func _pre() -> void:
	var l: SimLayout = _pad()
	var pre_first: int = -1
	var start: int = -1
	var dir_ok: bool = true
	var after_start: bool = false
	for t in range(40):
		var k: int = t - 10
		var m: float = 0.0
		if k >= 0 and k < 3:
			m = float(k + 1) / 3.0
		elif k >= 3 and k < 7:
			m = 1.0
		elif k >= 7 and k < 10:
			m = 1.0 - float(k - 6) / 3.0
		l.axis("pad:rs", m, 0.0)
		var i: SimIntent = l.build()
		var pre: Dictionary = l.strike_pre()
		if not pre.is_empty():
			if pre_first < 0:
				pre_first = k
			if int(pre["dir"]) != SimStrikeRead.RIGHT:
				dir_ok = false
		if i.rsStart and start < 0:
			start = k
		if start >= 0 and k > start and not pre.is_empty():
			after_start = true
		l.consumed()
	ok(pre_first >= 0 and start >= 0 and pre_first < start, "pre: the pre-read appears before the request starts (pre at +%d, start at +%d)" % [pre_first, start])
	ok(start - pre_first >= 2, "pre: it leads the start by at least 2 ticks on a ramp-3 flick (%d)" % (start - pre_first))
	ok(dir_ok, "pre: the leaning direction is right")
	ok(not after_start, "pre: gone once the request has started (the sim has it)")
	ok(l.strike_pre().is_empty(), "pre: empty at rest")
	# The pre-read is not in the intent: the streams with and without asking for it are the same.
	var a: Array = _flick(_pad(), 3)
	var lb: SimLayout = _pad()
	var b: Array = []
	for t in range(40):
		var k: int = t - 10
		var m: float = 0.0
		if k >= 0 and k < 3:
			m = float(k + 1) / 3.0
		elif k >= 3 and k < 7:
			m = 1.0
		elif k >= 7 and k < 10:
			m = 1.0 - float(k - 6) / 3.0
		lb.axis("pad:rs", m, 0.0)
		b.append(lb.build())
		lb.strike_pre()
		lb.consumed()
	var same: bool = true
	for t in range(40):
		if SimIntent.pack(a[t]) != SimIntent.pack(b[t]) or SimIntent.pack2(a[t]) != SimIntent.pack2(b[t]):
			same = false
	ok(same, "pre: asking for it changes no intent")
	# The inert layer (RT held) has none.
	var li: SimLayout = _pad()
	li.analog("pad:rt", 1.0)
	var inert_pre: bool = false
	for t in range(20):
		li.axis("pad:rs", 1.0 if t > 5 else 0.0, 0.0)
		li.build()
		if not li.strike_pre().is_empty():
			inert_pre = true
		li.consumed()
	ok(not inert_pre, "pre: none on an inert layer (RT held)")
	# The hub says the same for a slot, and is empty with the switch off.
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	hub.pad_stick_right(7, 1.0, 0.0)
	hub.intent(0)
	ok(int(hub.strike_pre(0).get("dir", 0)) == SimStrikeRead.RIGHT, "pre: the hub gives a slot its pre-read")


## The no-claw law holds with the quick read on: numbers read from data, nothing hard-coded to the settle of 2.
func _law() -> void:
	var lock: int = SimInputData.ti(["strike", "lockout"], 6)
	var rev: int = SimInputData.ti(["strike", "reverseLockout"], 8)
	# A face press 4 ticks before the stick crosses: the strike waits until R after it.
	var l: SimLayout = _pad()
	var its: Array = []
	for t in range(60):
		if t == 20:
			l.press("pad:west")
		if t == 22:
			l.release("pad:west")
		l.axis("pad:rs", 1.0 if t >= 24 else 0.0, 0.0)
		its.append(l.build())
		l.consumed()
	var st: int = _first(its, "rsStart")
	ok(st >= 20 + rev, "law: a strike never starts inside R = %d of a face press (face at 20, start at %d)" % [rev, st])
	ok(_first(its, "light") == 20, "law: the face press made before the strike is the press (tick 20)")
	# A face press the tick after the strike starts is held back (the faces are inert while it is out).
	var l2: SimLayout = _pad()
	var its2: Array = []
	for t in range(60):
		if t == 17:
			l2.press("pad:west")
		l2.axis("pad:rs", 1.0 if t >= 10 else 0.0, 0.0)
		its2.append(l2.build())
		l2.consumed()
	var st2: int = _first(its2, "rsStart")
	var pressed_at: int = st2 + 1
	var l3: SimLayout = _pad()
	var its3: Array = []
	for t in range(60):
		if t == pressed_at:
			l3.press("pad:west")
		l3.axis("pad:rs", 1.0 if t >= 10 else 0.0, 0.0)
		its3.append(l3.build())
		l3.consumed()
	var lt3: int = _first(its3, "light")
	ok(lt3 < 0 or lt3 >= 10 + 40, "law: a face press one tick after the start does not reach the sim while the stick is out (light at %d)" % lt3)
	# The thumb leaving the stick frees the faces L later.
	var l4: SimLayout = _pad()
	var its4: Array = []
	for t in range(60):
		if t == 12:
			l4.press("pad:west")
		l4.axis("pad:rs", 1.0 if (t >= 5 and t < 11) else 0.0, 0.0)
		its4.append(l4.build())
		l4.consumed()
	var lt4: int = _first(its4, "light")
	ok(lt4 >= 11 + lock - 1, "law: a face press right after the thumb leaves the stick waits L = %d (light at %d)" % [lock, lt4])


## The swapped layout makes the same stream under the quick read (row S's idea, one script).
func _swap() -> void:
	var a: SimLayout = _pad("arena")
	var b: SimLayout = _pad("arena-swapped")
	var same: bool = true
	for t in range(120):
		var m: float = 1.0 if (t % 30) in [10, 11, 12, 13] else 0.0
		var dirx: float = 1.0 if int(t / 30) % 2 == 0 else -1.0
		a.axis("pad:rs", m * dirx, 0.0)
		b.axis("pad:ls", m * dirx, 0.0)
		if t % 40 == 20:
			a.press("pad:west")
			b.press("pad:dpad_left")
		if t % 40 == 22:
			a.release("pad:west")
			b.release("pad:dpad_left")
		var ia: SimIntent = a.build()
		var ib: SimIntent = b.build()
		a.consumed()
		b.consumed()
		if SimIntent.pack(ia) != SimIntent.pack(ib) or SimIntent.pack2(ia) != SimIntent.pack2(ib):
			same = false
	ok(same, "swap: arena and arena-swapped make one stream under the quick read")


## Off: the switch missing or false is the layout as it was.
func _off_switch() -> void:
	var l: SimLayout = _pad()
	ok(l.strike_pre().is_empty(), "off: no pre-read")
	var its: Array = _flick(_pad(), 3)
	var any: bool = false
	for i in its:
		if (i as SimIntent).rsStart or (i as SimIntent).rsHeld:
			any = true
	ok(not any, "off: no strike at all with switches.rightStick false")
