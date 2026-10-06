extends SceneTree
## Headless checks for the stance mask (sim/input/stance.gd, the layouts, docs/controls/lunge-control.md A2 and A5): every held set
## on a pad, the keyboards and touch; a stance is exclusive until hybrids exist (the older button's own fields go neutral, no new
## edge on the hand-back); RT dominates but its edges (the burst from a guard) always report; the transform chord changes no stance;
## the release grace; hybrids switched on by data; the one-shot arming; the held levels sigHeld and contextHeld; the trigger
## sensitivity; and the packing of the mask. From the repo root:
##   godot --headless --path . --script res://sim/input/test/stance_test.gd
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
	_resolve()
	_singles()
	_exclusive()
	_rt_and_burst()
	_chord()
	_grace()
	_hybrids()
	_oneshot()
	_armed_view()
	_freeze_release()
	_levels()
	_keyboards()
	_touch(2.75)
	_hub()
	_pack()
	print("stance_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _mk(id: String) -> SimLayout:
	return SimLayout.new(SimInputData.preset(id))


func _run(l: SimLayout, n: int) -> SimIntent:
	var i: SimIntent = null
	for k in range(n):
		i = l.build()
		l.consumed()
	return i


func _resolve() -> void:
	ok(SimStance.resolve(0, 0) == 0, "resolve: nothing held is martial")
	for b in [1, 2, 4, 8]:
		ok(SimStance.resolve(b, b) == b, "resolve: bit %d alone is itself" % b)
	# RT dominates every set.
	for on in [4, 5, 6, 12, 7, 13, 14, 15]:
		ok(SimStance.resolve(on, 1) == 4, "resolve: any set with RT (%d) is the charging stance" % on)
	# A pair that is not enabled reads as its newest bit.
	ok(SimStance.resolve(3, 1) == 1 and SimStance.resolve(3, 2) == 2, "resolve: LB+RB reads as the newer of the two")
	ok(SimStance.resolve(10, 8) == 8 and SimStance.resolve(10, 2) == 2, "resolve: LT+RB reads as the newer of the two")
	ok(SimStance.resolve(9, 1) == 1 and SimStance.resolve(9, 8) == 8, "resolve: LT+LB reads as the newer of the two")
	# Enabled hybrids are themselves.
	ok(SimStance.resolve(10, 2, [10]) == 10 and SimStance.resolve(3, 1, [10]) == 1, "resolve: an enabled hybrid is the set, others still fall back")
	ok(SimStance.resolve(10, 2, [10, 3, 9]) == 10 and SimStance.resolve(3, 2, [10, 3, 9]) == 3 and SimStance.resolve(9, 8, [10, 3, 9]) == 9, "resolve: all three hybrids")
	ok(SimStance.resolve(7, 1, [10, 3, 9, 7]) == 4, "resolve: RT still dominates with hybrids on")
	ok(SimStance.newest_of(11, {1: 5, 2: 9, 8: 7}) == 2 and SimStance.newest_of(11, {1: 5, 2: 5, 8: 5}) == 8, "newest: the later tick wins and a tie goes to the higher bit")
	ok(SimStance.label(0) == "martial" and SimStance.label(10) == "evasive energy" and SimStance.label(3) == "defensive ki" and SimStance.label(9) == "terrain while flying", "label: the names")
	ok(SimInputData.hybrids().is_empty(), "data: no hybrid is enabled yet (stances.json)")


func _singles() -> void:
	for c in [["pad:lb", 1], ["pad:rb", 2], ["pad:rt", 4], ["pad:lt", 8]]:
		var l: SimLayout = _mk("arena")
		ok(_run(l, 3).stanceMask == 0, "single: martial with nothing held (%s)" % c[0])
		l.press(c[0])
		var i: SimIntent = l.build()
		ok(i.stanceMask == c[1], "single: %s is mask %d on the tick it is pressed" % [c[0], c[1]])
		l.consumed()
		ok(_run(l, 20).stanceMask == c[1], "single: and while held (%s)" % c[0])
		l.release(c[0])
		_run(l, 4)
		ok(l.build().stanceMask == 0, "single: martial again after the release (%s)" % c[0])
	# A press shorter than a tick still has its stance for its tick.
	var q: SimLayout = _mk("arena")
	q.press("pad:rb")
	q.release("pad:rb")
	ok(q.build().stanceMask == 2, "single: a sub-tick tap has its stance for its tick")


## A stance is exclusive until hybrids exist: the older button's own fields go neutral, and the hand-back fires no new edge.
func _exclusive() -> void:
	# LB held, then RB: RB (newest) is the stance; guard goes neutral; RB's mode is on.
	var l: SimLayout = _mk("arena")
	l.press("pad:lb")
	var i: SimIntent = l.build()
	ok(i.stanceMask == 1 and i.guard and i.guardPress, "exclusive: LB alone is defensive with its guard and its perfect-block edge")
	l.consumed()
	_run(l, 10)
	l.press("pad:rb")
	i = l.build()
	ok(i.stanceMask == 2 and i.mode == 1 and not i.guard and not i.guardPress, "exclusive: RB pressed over LB is energy, and the guard goes neutral")
	l.consumed()
	l.release("pad:rb")
	_run(l, 4)   # past the release grace
	i = l.build()
	ok(i.stanceMask == 1 and i.guard and not i.guardPress and i.mode == 0, "exclusive: letting go of RB hands the stance back to LB with its guard and NO new guardPress")
	l.consumed()
	l.release("pad:lb")
	_run(l, 4)
	# RB held, then LB: LB is the stance; the held RB's mode goes neutral.
	l.press("pad:rb")
	i = l.build()
	ok(i.stanceMask == 2 and i.mode == 1, "exclusive: RB alone is energy")
	l.consumed()
	_run(l, 5)
	l.press("pad:lb")
	i = l.build()
	ok(i.stanceMask == 1 and i.guard and i.mode == 0, "exclusive: LB pressed over RB is defensive: guard on, the energy goes neutral (no guard while RB is held is true by construction)")
	l.consumed()
	l.release("pad:lb")
	_run(l, 4)
	ok(l.build().mode == 1 and l.build().stanceMask == 2, "exclusive: and the energy comes back when LB is let go")
	l.consumed()
	l.release("pad:rb")
	_run(l, 4)
	# LT (a boost) then LB: the sprint goes neutral.
	l.press("pad:lt")
	_run(l, 20)
	ok(l.build().sprint, "exclusive: LT held 20 ticks is a sprint")
	l.consumed()
	l.press("pad:lb")
	i = l.build()
	ok(i.stanceMask == 1 and i.guard and not i.sprint and not i.dash, "exclusive: LB pressed during a boost guards and ends the sprint (no guard in manoeuvre is true by construction)")
	l.consumed()
	l.release("pad:lb")
	_run(l, 4)
	i = l.build()
	ok(i.stanceMask == 8 and i.sprint and not i.dodge, "exclusive: the boost resumes when LB goes, with no new dodge")
	l.consumed()
	l.release("pad:lt")
	_run(l, 4)
	# The dodge edge reports even if LT is shadowed.
	var d: SimLayout = _mk("arena")
	d.press("pad:rt")
	_run(d, 20)
	d.press("pad:lt")
	i = d.build()
	ok(i.stanceMask == 4 and i.dodge and not i.sprint, "exclusive: LT pressed while RT is held (not a chord) still dodges; RT keeps the stance")


func _rt_and_burst() -> void:
	# RT dominates: LB held, then RT: charging, guard neutral, but the power edges always report.
	var l: SimLayout = _mk("arena")
	l.press("pad:lb")
	_run(l, 10)
	l.press("pad:rt")
	var i: SimIntent = l.build()
	ok(i.stanceMask == 4 and i.powerPress and i.power and not i.guard, "rt: RT pressed over a guard is the charging stance, its powerPress reports (the burst from a guard), the guard goes neutral")
	l.consumed()
	_run(l, 3)
	l.release("pad:rt")
	i = l.build()
	ok(i.powerTap, "rt: a quick release is the powerTap (the burst when not threatened)")
	l.consumed()
	_run(l, 4)
	i = l.build()
	ok(i.stanceMask == 1 and i.guard and not i.guardPress, "rt: and the guard comes back with no new perfect-block edge")
	l.consumed()
	l.release("pad:lb")
	_run(l, 4)
	# The same from LB pressed after RT: RT still dominates and LB is shadowed.
	l.press("pad:rt")
	_run(l, 20)
	l.press("pad:lb")
	i = l.build()
	ok(i.stanceMask == 4 and not i.guard and not i.guardPress and i.power, "rt: LB pressed while RT is held cannot take the stance or the guard")
	l.consumed()
	l.release("pad:lb")
	l.release("pad:rt")
	_run(l, 4)
	# RT held over RB: charging, energy neutral.
	l.press("pad:rb")
	_run(l, 5)
	l.press("pad:rt")
	i = l.build()
	ok(i.stanceMask == 4 and i.mode == 0, "rt: RT over RB is charging and the energy goes neutral")


func _chord() -> void:
	var l: SimLayout = _mk("arena")
	l.press("pad:lb")
	_run(l, 5)
	l.press("pad:lt")
	_run(l, 3)
	l.press("pad:rt")   # 3 ticks after LT: the transform chord
	var seen: Array = []
	var got: bool = false
	for k in range(40):
		var i: SimIntent = l.build()
		l.consumed()
		seen.append(i.stanceMask)
		got = got or i.transform
	ok(got, "chord: LT then RT within 6 ticks is the transform chord")
	ok(seen[10] == 1 and seen[39] == 1, "chord: while it is pending or held the stance is what it was before (LB), not manoeuvre or charging (%s)" % str(seen.slice(0, 12)))
	l.release("pad:lt")
	l.release("pad:rt")
	_run(l, 4)
	ok(l.build().stanceMask == 1, "chord: and after it, LB is still the stance")
	l.consumed()
	l.release("pad:lb")
	_run(l, 4)
	# 8 ticks apart is no chord: RT dominates.
	l.press("pad:lt")
	_run(l, 8)
	l.press("pad:rt")
	var j: SimIntent = _run(l, 10)
	ok(j.stanceMask == 4 and not j.transform, "chord: 8 ticks apart is two stances, RT wins")


func _grace() -> void:
	var l: SimLayout = _mk("arena")
	l.press("pad:lb")
	_run(l, 5)
	l.release("pad:lb")
	var m: Array = []
	for k in range(5):
		m.append(l.build().stanceMask)
		l.consumed()
	ok(m == [1, 1, 0, 0, 0], "grace: a released stance button keeps the mask for 2 ticks (%s)" % str(m))
	# A flutter: let go and press again inside the grace: the mask never leaves the stance.
	var f: SimLayout = _mk("arena")
	f.press("pad:rb")
	_run(f, 5)
	f.release("pad:rb")
	var a: int = f.build().stanceMask
	f.consumed()
	f.press("pad:rb")
	var b: int = f.build().stanceMask
	f.consumed()
	ok(a == 2 and b == 2, "grace: a flutter of the stance button does not flicker the stance")


func _hybrids() -> void:
	var saved = SimInputData.stances
	SimInputData.stances = {"schema": 1, "hybrids": [10, 3, 9]}
	# LT + RB: evasive energy: both buttons' own fields stay on.
	var l: SimLayout = _mk("arena")
	l.press("pad:lt")
	_run(l, 14)
	l.press("pad:rb")
	var i: SimIntent = l.build()
	ok(i.stanceMask == 10 and i.mode == 1 and i.sprint, "hybrid: LT+RB is mask 10 with the energy and the boost both on")
	l.consumed()
	l.release("pad:rb")
	l.release("pad:lt")
	_run(l, 4)
	# LB + RB: defensive ki: guard and energy.
	l.press("pad:lb")
	_run(l, 3)
	l.press("pad:rb")
	i = l.build()
	ok(i.stanceMask == 3 and i.mode == 1 and i.guard, "hybrid: LB+RB is mask 3 with the guard and the energy")
	l.consumed()
	l.release("pad:lb")
	l.release("pad:rb")
	_run(l, 4)
	# LT + LB: terrain while flying.
	l.press("pad:lt")
	_run(l, 14)
	l.press("pad:lb")
	i = l.build()
	ok(i.stanceMask == 9 and i.guard and i.sprint, "hybrid: LT+LB is mask 9 with the guard and the boost")
	l.consumed()
	l.release("pad:lb")
	l.release("pad:lt")
	_run(l, 4)
	# RT still dominates, and a set that is not a hybrid still falls back.
	l.press("pad:lb")
	l.press("pad:rt")
	i = l.build()
	ok(i.stanceMask == 4, "hybrid: RT dominates even with hybrids on")
	l.consumed()
	SimInputData.stances = saved
	# Switched off again, the same pair reads as the newer button.
	var l2: SimLayout = _mk("arena")
	l2.press("pad:lt")
	_run(l2, 5)
	l2.press("pad:rb")
	ok(l2.build().stanceMask == 2, "hybrid: with none enabled LT+RB reads as the newer (RB)")


func _oneshot() -> void:
	var l: SimLayout = _mk("arena")
	l.set_stance_oneshot(true)
	# A tap on RB arms energy for the next blow.
	l.press("pad:rb")
	_run(l, 3)
	l.release("pad:rb")
	_run(l, 4)
	var i: SimIntent = l.build()
	ok(i.stanceMask == 2 and i.mode == 1, "oneshot: a tap on RB arms the energy stance, with the mode on for the next blow")
	l.consumed()
	_run(l, 40)
	ok(l.build().stanceMask == 2, "oneshot: it waits for the blow")
	l.consumed()
	l.press("pad:west")
	i = l.build()
	ok(i.light and i.stanceMask == 2 and i.mode == 1, "oneshot: the next blow reads it")
	l.consumed()
	l.release("pad:west")
	i = l.build()
	ok(i.stanceMask == 0 and i.mode == 0, "oneshot: and the arming is spent")
	l.consumed()
	# It times out.
	l.press("pad:lt")
	_run(l, 3)
	l.release("pad:lt")
	_run(l, 4)
	ok(l.build().stanceMask == 8, "oneshot: a tap on LT arms the manoeuvre stance")
	l.consumed()
	_run(l, 95)
	ok(l.build().stanceMask == 0, "oneshot: unspent after 90 ticks it lapses")
	l.consumed()
	# A tap on an armed button cancels it.
	l.press("pad:lb")
	_run(l, 3)
	l.release("pad:lb")
	_run(l, 3)
	ok(l.build().stanceMask == 1, "oneshot: LB armed")
	l.consumed()
	l.press("pad:lb")
	_run(l, 3)
	l.release("pad:lb")
	_run(l, 4)
	ok(l.build().stanceMask == 0, "oneshot: a second tap cancels it")
	l.consumed()
	# A hold is momentary and arms nothing.
	l.press("pad:rb")
	_run(l, 30)
	l.release("pad:rb")
	_run(l, 4)
	ok(l.build().stanceMask == 0, "oneshot: a held button is momentary: nothing armed")
	l.consumed()
	# The chord's taps arm nothing.
	l.press("pad:lt")
	l.press("pad:rt")
	_run(l, 3)
	l.release("pad:lt")
	l.release("pad:rt")
	_run(l, 5)
	ok(l.build().stanceMask == 0, "oneshot: the two taps of the transform chord arm nothing")
	l.consumed()
	# Off by default.
	var d: SimLayout = _mk("arena")
	d.press("pad:rb")
	_run(d, 3)
	d.release("pad:rb")
	_run(d, 4)
	ok(d.build().stanceMask == 0, "oneshot: off by default on a pad")
	# Switching it off disarms.
	l.set_stance_oneshot(true)
	l.press("pad:rb")
	_run(l, 3)
	l.release("pad:rb")
	_run(l, 4)
	l.set_stance_oneshot(false)
	ok(l.build().stanceMask == 0, "oneshot: turning it off disarms")
	# An armed charging stance is the power layer: the next face press is the special, not a light.
	var c: SimLayout = _mk("arena")
	c.set_stance_oneshot(true)
	c.press("pad:rt")
	_run(c, 3)
	c.release("pad:rt")
	_run(c, 4)
	ok(c.build().stanceMask == 4, "oneshot: a tap on RT arms the charging stance")
	c.consumed()
	c.press("pad:west")
	i = c.build()
	ok(i.special == 1 and not i.light and i.stanceMask == 4, "oneshot: an armed charging stance makes X special1 (the layer is the stance)")
	c.consumed()
	c.release("pad:west")
	_run(c, 2)
	c.press("pad:west")
	i = c.build()
	ok(i.light and i.special == 0 and i.stanceMask == 0, "oneshot: and it is spent: the next X is a light in martial")
	c.consumed()
	c.release("pad:west")
	# A pad with the mode latch (hybrid): a tap latches energy; the one-shot is not stacked on it.
	var m: SimLayout = _mk("arena")
	m.set_stance_oneshot(true)
	m.set_mode_style("hybrid")
	m.press("pad:rb")
	_run(m, 3)
	m.release("pad:rb")
	_run(m, 4)
	ok(m.build().stanceMask == 2 and m.build().mode == 1, "oneshot: a tap on RB with the latch is energy, latched")
	m.consumed()
	m.press("pad:west")
	_run(m, 2)
	m.release("pad:west")
	_run(m, 3)
	ok(m.build().stanceMask == 2, "oneshot: a blow does not spend a latch")
	m.consumed()
	m.press("pad:rb")
	_run(m, 3)
	m.release("pad:rb")
	_run(m, 4)
	ok(m.build().stanceMask == 0 and m.build().mode == 0, "oneshot: the second tap unlatches, and nothing is left armed behind it")


## The HUD's read-only view of the arming: the share of the 90-tick window left, which stance, the latch.
func _armed_view() -> void:
	var l: SimLayout = _mk("arena")
	ok(l.armed_share(2) == 0.0 and l.armed_bits() == 0 and l.armed_newest() == 0 and not l.energy_latched(), "armed view: nothing at rest")
	l.set_stance_oneshot(true)
	l.press("pad:rb")
	_run(l, 3)
	l.release("pad:rb")
	l.build()
	l.consumed()
	var s0: float = l.armed_share(2)
	ok(s0 > 0.97 and s0 <= 1.0 and l.armed_bits() == 2 and l.armed_newest() == 2 and l.armed_share(1) == 0.0, "armed view: a tap arms energy with nearly the whole window left")
	_run(l, 44)
	var s1: float = l.armed_share(2)
	ok(s1 < s0 and absf(s1 - 0.5) < 0.06, "armed view: it runs down, about half at 45 ticks (%.3f)" % s1)
	_run(l, 40)
	var s2: float = l.armed_share(2)
	ok(s2 < s1 and s2 > 0.0, "armed view: still armed and almost out at 85 ticks (%.3f)" % s2)
	_run(l, 10)
	ok(l.armed_share(2) == 0.0 and l.armed_bits() == 0, "armed view: lapsed after the 90 ticks, share 0 and nothing armed")
	# A second tap cancels.
	l.press("pad:lb")
	_run(l, 3)
	l.release("pad:lb")
	_run(l, 2)
	ok(l.armed_share(1) > 0.9 and l.armed_newest() == 1, "armed view: LB armed")
	l.press("pad:lb")
	_run(l, 3)
	l.release("pad:lb")
	_run(l, 2)
	ok(l.armed_share(1) == 0.0 and l.armed_bits() == 0, "armed view: a second tap cancels it")
	# Two armed: the newest is the stance, both show.
	l.press("pad:lt")
	_run(l, 3)
	l.release("pad:lt")
	_run(l, 5)
	l.press("pad:lb")
	_run(l, 3)
	l.release("pad:lb")
	_run(l, 2)
	ok(l.armed_bits() == 9 and l.armed_newest() == 1 and l.armed_share(8) > 0.0 and l.armed_share(1) > l.armed_share(8), "armed view: two armed, the newer is the stance and has more window left")
	# A blow consumes whatever is armed.
	l.press("pad:west")
	_run(l, 2)
	ok(l.armed_bits() == 0 and l.armed_share(1) == 0.0 and l.armed_share(8) == 0.0, "armed view: the blow spends the arming")
	l.release("pad:west")
	# The energy latch (the hybrid style): a tap latches, a blow does not spend it, the next tap puts it away.
	var m: SimLayout = _mk("arena")
	m.set_mode_style("hybrid")
	m.set_stance_oneshot(true)
	m.press("pad:rb")
	_run(m, 3)
	m.release("pad:rb")
	_run(m, 3)
	ok(m.energy_latched() and m.armed_bits() == 0, "armed view: a tap latches energy and arms nothing")
	m.press("pad:west")
	_run(m, 2)
	m.release("pad:west")
	_run(m, 3)
	ok(m.energy_latched(), "armed view: a blow does not spend the latch")
	m.press("pad:rb")
	_run(m, 3)
	m.release("pad:rb")
	_run(m, 3)
	ok(not m.energy_latched(), "armed view: the second tap puts it away")
	# The hold style has no latch.
	var h: SimLayout = _mk("arena")
	h.press("pad:rb")
	_run(h, 20)
	h.release("pad:rb")
	_run(h, 3)
	ok(not h.energy_latched(), "armed view: the hold style never latches")
	# Reading it changes nothing: the same feed with and without the reads gives the same intents.
	var a: SimLayout = _mk("arena")
	var b: SimLayout = _mk("arena")
	a.set_stance_oneshot(true)
	b.set_stance_oneshot(true)
	var same: bool = true
	for t in range(130):
		if t == 5:
			a.press("pad:rb")
			b.press("pad:rb")
		if t == 8:
			a.release("pad:rb")
			b.release("pad:rb")
		var ia: int = SimIntent.pack(a.build())
		b.armed_share(2)
		b.armed_bits()
		b.armed_newest()
		b.energy_latched()
		var ib: int = SimIntent.pack(b.build())
		# keep both layouts on the same tick count: b built once, a built once
		a.consumed()
		b.consumed()
		same = same and ia == ib
	ok(same, "armed view: the reads change nothing in the intents")


## A level that falls (or rises) during a hit-stop: the host builds an intent every tick, SimCore.step returns false during the
## freeze and the host does not call consumed(), so what reaches the sim is the state at the first live build, with nothing
## advanced in between. Checked on the pad, the keyboard and Full touch, for the slow buttons' release (the wind-up's decision).
func _freeze_release() -> void:
	var devs: Array = [["arena", "pad:north"], ["kb-solo", "kb:KeyK"], ["touch-full", "heavy"]]
	for d in devs:
		var tag: String = str(d[0])
		var touch: bool = tag == "touch-full"
		var l: SimLayout = null
		var t: SimTouch = null
		if touch:
			t = SimTouch.new()
			t.dp = 2.75
			t.set_preset("touch-full")
			t.set_stance_oneshot(false)
		else:
			l = _mk(tag)
		# A: pressed live and consumed; released during a 6-build freeze; the first live build reads it released.
		var i: SimIntent = _fz_press(l, t, d[1], 1)
		ok(i.heavy and i.heavyHeld, "freeze %s: the press is an edge with its level on the live tick" % tag)
		_fz_consumed(l, t)
		var builds: Array = []
		for k in range(6):
			if k == 2:
				_fz_release(l, t, d[1], 1)
			builds.append(_fz_build(l, t))
		var live: SimIntent = _fz_build(l, t)
		ok(not live.heavyHeld and not live.heavy and live.waited == 0, "freeze %s: a release made in the freeze reaches the first live build as a level that is down, no edge, nothing carried" % tag)
		_fz_consumed(l, t)
		# B: a tap made wholly inside a freeze: an edge with its level on, carrying how long it waited; the next build it is up.
		for k in range(6):
			if k == 1:
				_fz_press_only(l, t, d[1], 2)
			if k == 3:
				_fz_release(l, t, d[1], 2)
			_fz_build(l, t)
		var first: SimIntent = _fz_build(l, t)
		ok(first.heavy and first.heavyHeld and first.waited >= 3, "freeze %s: a tap wholly in the freeze arrives as an edge with its level on, having waited (%d)" % [tag, first.waited])
		_fz_consumed(l, t)
		var nxt: SimIntent = _fz_build(l, t)
		ok(not nxt.heavyHeld and not nxt.heavy, "freeze %s: and the next build it is up" % tag)
		_fz_consumed(l, t)
		# C: the smallest case that can still read a tap as a hold: down live, released and pressed again inside ONE freeze.
		_fz_press(l, t, d[1], 3)
		_fz_consumed(l, t)
		for k in range(10):
			if k == 1:
				_fz_release(l, t, d[1], 3)
			if k == 6:
				_fz_press_only(l, t, d[1], 3)
			_fz_build(l, t)
		var dbl: SimIntent = _fz_build(l, t)
		ok(dbl.heavy and dbl.heavyHeld, "freeze %s: a release and a re-press inside one freeze arrive as an edge with the level still on: the release itself is not visible, only the edge says so (the director must read an edge on a button it saw held as release then press)" % tag)
		_fz_consumed(l, t)


func _fz_press(l: SimLayout, t: SimTouch, c, id: int) -> SimIntent:
	_fz_press_only(l, t, c, id)
	return _fz_build(l, t)


func _fz_press_only(l: SimLayout, t: SimTouch, c, id: int) -> void:
	if t != null:
		t.touch_down(id, 0.0, 0.0, str(c))
	else:
		l.press(str(c))


func _fz_release(l: SimLayout, t: SimTouch, c, id: int) -> void:
	if t != null:
		t.touch_up(id)
	else:
		l.release(str(c))


func _fz_build(l: SimLayout, t: SimTouch) -> SimIntent:
	return t.build() if t != null else l.build()


func _fz_consumed(l: SimLayout, t: SimTouch) -> void:
	if t != null:
		t.consumed()
	else:
		l.consumed()


func _levels() -> void:
	# Arena: B (east) is the signature, A (south) is context.
	var l: SimLayout = _mk("arena")
	ok(not _run(l, 3).sigHeld and not l.build().contextHeld, "levels: none at rest")
	l.press("pad:east")
	var i: SimIntent = l.build()
	ok(i.sig and i.sigHeld and not i.contextHeld, "levels: B is the signature edge and its held level on its tick")
	l.consumed()
	ok(_run(l, 25).sigHeld, "levels: still down 25 ticks later, the level and no new edge")
	l.release("pad:east")
	ok(not _run(l, 1).sigHeld, "levels: released, the level ends")
	l.press("pad:south")
	i = l.build()
	ok(i.context and i.contextHeld and not i.sigHeld, "levels: A is the context edge and its held level")
	l.consumed()
	ok(_run(l, 20).contextHeld, "levels: A held")
	l.release("pad:south")
	ok(not _run(l, 1).contextHeld, "levels: A released")
	# A sub-tick tap has its level for its tick.
	l.press("pad:east")
	l.release("pad:east")
	i = l.build()
	ok(i.sig and i.sigHeld, "levels: a sub-tick tap of B has its level for its tick")
	l.consumed()
	# The ultimate's hold: B under RT (the power layer) is a held signature too.
	l.press("pad:rt")
	_run(l, 4)
	l.press("pad:east")
	i = l.build()
	ok(i.sig and i.sigHeld and i.stanceMask == 4, "levels: B under RT is the signature in the charging stance, and held")
	l.consumed()
	ok(_run(l, 40).sigHeld, "levels: and its hold counts (the ultimate's 45 ticks)")
	l.release("pad:east")
	ok(not _run(l, 1).sigHeld, "levels: letting go of B ends it")
	l.release("pad:rt")
	_run(l, 4)
	# Simple: Y (north) is the signature, LB the context, and RT + LB the utility special.
	var s: SimLayout = _mk("simple-pad")
	s.press("pad:north")
	ok(s.build().sigHeld, "levels: Simple's Y is a held signature")
	s.consumed()
	s.release("pad:north")
	_run(s, 3)
	s.press("pad:lb")
	i = s.build()
	ok(i.context and i.contextHeld, "levels: Simple's LB is a held context (A's cell)")
	s.consumed()
	s.release("pad:lb")
	_run(s, 3)
	s.press("pad:rt")
	_run(s, 3)
	s.press("pad:lb")
	i = s.build()
	ok(i.special == 3 and not i.context and i.stanceMask == 4, "simple: RT + LB is the utility special (special3), not a context")
	s.consumed()
	s.release("pad:lb")
	s.press("pad:west")
	i = s.build()
	ok(i.special == 7, "simple: RT + X is special_auto")
	s.consumed()
	s.release("pad:west")
	s.press("pad:north")
	i = s.build()
	ok(i.sig and i.sigHeld, "simple: RT + Y is the signature (the ultimate)")


func _keyboards() -> void:
	var cases: Array = [["kb-solo", "kb:Shift", 1], ["kb-solo", "kb:KeyQ", 2], ["kb-solo", "kb:KeyE", 4], ["kb-solo", "kb:Space", 8],
		["kb-shared-p1", "kb:Shift", 1], ["kb-shared-p1", "kb:KeyE", 2], ["kb-shared-p1", "kb:KeyQ", 4], ["kb-shared-p1", "kb:Space", 8],
		["kb-shared-p2", "kb:Semicolon", 1], ["kb-shared-p2", "kb:KeyO", 2], ["kb-shared-p2", "kb:Slash", 4], ["kb-shared-p2", "kb:Period", 8]]
	for c in cases:
		var l: SimLayout = _mk(c[0])
		l.press(c[1])
		var i: SimIntent = l.build()
		ok(i.stanceMask == c[2], "keyboard: %s on %s is mask %d" % [c[1], c[0], c[2]])
	# Two keys on the solo keyboard: Shift then Q: the newer wins, and the held levels follow the face keys.
	var k: SimLayout = _mk("kb-solo")
	k.press("kb:Shift")
	_run(k, 4)
	k.press("kb:KeyQ")
	var j: SimIntent = k.build()
	ok(j.stanceMask == 2 and not j.guard and j.mode == 1, "keyboard: Q over Shift is energy and the guard goes neutral")
	k.consumed()
	k.press("kb:KeyL")
	j = k.build()
	ok(j.sig and j.sigHeld and j.stanceMask == 2, "keyboard: L is B, the signature, in the energy stance (the beam's cell)")
	k.consumed()
	k.release("kb:KeyL")
	k.press("kb:KeyI")
	j = k.build()
	ok(j.context and j.contextHeld, "keyboard: I is A, the context, and its held level")


func _touch(dp: float) -> void:
	# Simple touch: Guard is LB, Power is RT, the stick's outer ring is LT.
	var t := SimTouch.new()
	t.dp = dp
	var i: SimIntent = t.build()
	ok(i.stanceMask == 0 and i.mode == -1, "touch Simple: martial at rest, and the director keeps the mode")
	t.touch_down(1, 400.0, 300.0, "guard")
	i = t.build()
	ok(i.stanceMask == 1 and i.guard, "touch Simple: the Guard button is the defensive stance")
	t.consumed()
	t.touch_down(2, 500.0, 300.0, "power")
	i = t.build()
	ok(i.stanceMask == 4 and not i.guard and i.power, "touch Simple: Power over Guard is the charging stance (RT dominates), the guard goes neutral")
	t.consumed()
	t.touch_up(2)
	t.touch_up(1)
	t.consumed()
	_run_touch(t, 3)
	# The outer ring held: the manoeuvre stance, and the sprint.
	var r := SimTouch.new()
	r.dp = dp
	r.touch_down(1, 200.0, 700.0, "stick")
	r.touch_move(1, 200.0 + 80.0 * dp, 700.0)
	var s: SimIntent = null
	for n in range(10):
		s = r.build()
		r.consumed()
	ok(s.sprint and s.stanceMask == 8, "touch Simple: the stick's outer ring held is the sprint and the manoeuvre stance (the zip's LT)")
	r.touch_down(2, 400.0, 300.0, "guard")
	s = r.build()
	ok(s.stanceMask == 1 and s.guard and not s.sprint, "touch Simple: Guard pressed over the ring guards and ends the sprint")
	r.consumed()
	# Full touch: the one-shot is on: tap Dodge, then the Light button.
	var f := SimTouch.new()
	f.dp = dp
	f.set_preset("touch-full")
	f.touch_down(1, 100.0, 500.0, "dodge")
	_run_touch(f, 3)
	f.touch_up(1)
	_run_touch(f, 4)
	i = f.build()
	ok(i.stanceMask == 8, "touch Full: a tap on Dodge arms the manoeuvre stance (one-shot is the default there)")
	f.consumed()
	f.touch_down(2, 700.0, 500.0, "light")
	i = f.build()
	ok(i.light and i.stanceMask == 8, "touch Full: the next blow reads it")
	f.consumed()
	f.touch_up(2)
	i = f.build()
	ok(i.stanceMask == 0, "touch Full: and it is spent")
	f.consumed()
	f.set_stance_oneshot(false)
	f.touch_down(3, 100.0, 500.0, "guard")
	_run_touch(f, 3)
	f.touch_up(3)
	_run_touch(f, 4)
	ok(f.build().stanceMask == 0, "touch Full: with the one-shot off a tap arms nothing")


func _run_touch(t: SimTouch, n: int) -> SimIntent:
	var i: SimIntent = null
	for k in range(n):
		i = t.build()
		t.consumed()
	return i


func _hub() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, true)
	hub.pad_button(3, "south", true)
	hub.pad_button(3, "south", false)
	hub.pad_button(9, "south", true)
	hub.pad_button(9, "south", false)
	hub.consumed()
	ok(not hub.stance_oneshot_of(0) and not hub.stance_oneshot_of(1), "hub: the one-shot is off on a pad by default")
	hub.set_stance_oneshot("on", 1)
	ok(not hub.stance_oneshot_of(0) and hub.stance_oneshot_of(1), "hub: a player can turn it on for themselves")
	hub.pad_button(9, "rb", true)
	hub.intent(1)
	hub.consumed()
	hub.pad_button(9, "rb", false)
	hub.intent(1)
	hub.consumed()
	for n in range(4):
		hub.intent(0)
		hub.intent(1)
		hub.consumed()
	ok(hub.intent(1).stanceMask == 2 and hub.intent(0).stanceMask == 0, "hub: player two's tap armed energy, player one's pad did not")
	ok(hub.armed_stance(1) == 2 and hub.armed_share(1) > 0.9 and hub.armed_stance(0) == 0 and hub.armed_share(0) == 0.0 and not hub.energy_latched(1), "hub: armed_stance and armed_share read the slot's own arming, and energy is not latched on the hold style")
	hub.consumed()
	# The mask passes through the canonical packing for every held set.
	hub.set_stance_oneshot("off", 1)
	hub.pad_button(3, "lb", true)
	ok(hub.intent(0).stanceMask == 1, "hub: the mask survives canon() (pack and unpack)")
	hub.consumed()
	hub.pad_button(3, "lb", false)
	# Trigger sensitivity: a stiffer threshold needs a firmer pull.
	hub.set_trigger_threshold(0.5, 0)
	hub.pad_trigger(3, "rt", 0.45)
	ok(not hub.intent(0).power, "hub: 0.45 is under a 0.5 threshold, no press")
	hub.consumed()
	hub.pad_trigger(3, "rt", 0.55)
	ok(hub.intent(0).power, "hub: 0.55 is over it")
	hub.consumed()
	hub.pad_trigger(3, "rt", 0.45)
	ok(hub.intent(0).power, "hub: and it stays down until 0.1 below")
	hub.consumed()
	hub.pad_trigger(3, "rt", 0.35)
	ok(not hub.intent(0).power, "hub: and lets go below that")
	hub.consumed()
	# A retired preset becomes Arena.
	hub.set_pad_preset("brawler", 0)
	ok(hub.pad_preset_of(0) == "arena" or hub.layout_of(0) == "arena", "hub: a saved Brawler choice is Arena")


func _pack() -> void:
	for m in range(16):
		var i := SimIntent.new()
		i.stanceMask = m
		var u: SimIntent = SimIntent.unpack(SimIntent.pack(i))
		ok(u != null and u.stanceMask == m and not u.light and not u.sigHeld and not u.contextHeld, "pack: stanceMask %d round-trips alone" % m)
	var a := SimIntent.new()
	a.contextHeld = true
	var ua: SimIntent = SimIntent.unpack(SimIntent.pack(a))
	ok(ua.contextHeld and not ua.sigHeld and ua.stanceMask == 0, "pack: contextHeld round-trips alone")
	var b := SimIntent.new()
	b.sigHeld = true
	var ub: SimIntent = SimIntent.unpack(SimIntent.pack(b))
	ok(ub.sigHeld and not ub.contextHeld and ub.stanceMask == 0, "pack: sigHeld round-trips alone")
	var all := SimIntent.new()
	all.stanceMask = 15
	all.contextHeld = true
	all.sigHeld = true
	all.waited = 15
	all.escape = true
	all.lightHeld = true
	all.heavyHeld = true
	all.mx = 1.0
	all.my = -1.0
	var p: int = SimIntent.pack(all)
	ok(p < (1 << 53) and p >= 0, "pack: the whole record fits the 53 bits")
	var ua2: SimIntent = SimIntent.unpack(p)
	ok(ua2.stanceMask == 15 and ua2.contextHeld and ua2.sigHeld and ua2.waited == 15 and ua2.escape and ua2.lightHeld and ua2.heavyHeld and ua2.mx == 1.0 and ua2.my == -1.0, "pack: and every field comes back")
	ok(SimIntent.unpack(1 << 53) == null and SimIntent.unpack((1 << 53) | 5) == null and SimIntent.unpack(-5) == null, "pack: a bit above 52 or a negative is refused")
	# Applying and clearing.
	var dst := SimIntent.new()
	SimIntent.applyIntent(dst, all)
	ok(dst.stanceMask == 15 and dst.contextHeld and dst.sigHeld, "pack: applyIntent copies the new fields")
	SimIntent.clearIntent(dst)
	ok(dst.stanceMask == 0 and not dst.contextHeld and not dst.sigHeld, "pack: clearIntent clears them")
	# A version-3 packed intent (no bits above 46) is still a valid record and reads as martial.
	var old := SimIntent.new()
	old.light = true
	old.waited = 5
	var uo: SimIntent = SimIntent.unpack(SimIntent.pack(old))
	ok(uo.stanceMask == 0 and not uo.contextHeld and not uo.sigHeld and uo.light and uo.waited == 5, "pack: an intent without the new fields reads as martial with them off")
