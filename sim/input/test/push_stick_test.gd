extends SceneTree
## Headless checks for the stick push in a beam struggle (docs/controls/push-stick.md; Game Design's playable-build.md section 3; Encounter's struggle.pushMode) and for the beam's six-rung
## charge ladder (strike.beamLevels 12, 28, 46, 66, 90, 120). On the real pad layout and the real hub with switches.rightStick on:
##   A  with the host's push word, a flick toward or away in a struggle is a request edge with its direction (the director's push or let-go); up and down too, for the director to ignore
##   B  holding or scrubbing the stick does not count again; a flick has to come back under the release line before the next one
##   C  a stick still out as the struggle begins is let go of (an edge) and must rest first; a flick still going at its end does not carry into the fight
##   D  the faces stay free, and a face press just before a flick does not delay it (no reverse lockout)
##   E  with no push word the stick does nothing in a struggle, as ruled for face mode; outside a struggle the push word means nothing
##   F  the hub: a stick-push struggle's flick is never a request left unanswered (no "no answer" refusal), a flick outside it still is
##   G  the six-rung beam ladder: the reader's rungs, the intent's level cut to 3, the pad's pulses at 12 / 28 / 46, a short list is refused
## From the repo root:
##   godot --headless --path . --script res://sim/input/test/push_stick_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0

const RIGHT: int = 4
const LEFT: int = 3
const UP: int = 1


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	_switches(true, true)
	_a_direction()
	_b_rearm()
	_c_edges()
	_d_faces()
	_e_no_push()
	_f_hub()
	_g_ladder()
	print("push_stick_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _switches(right: bool, refused: bool, ladder: bool = false) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = right
	sw["quickRead"] = false
	sw["stallKeep"] = false
	sw["beamAim"] = false
	sw["specialsOff"] = false
	sw["hapticRefused"] = refused
	sw["hapticLadder"] = ladder
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _pad() -> SimLayout:
	return SimLayout.new(SimInputData.preset("arena"))


## Events: [tick, kind, name, a, b]; "b" a face (a: down), "rs" the right stick (a, b). An event at tick t shows in intent t.
func _apply(l: SimLayout, e: Array) -> void:
	match str(e[1]):
		"b":
			if bool(e[3]):
				l.press("pad:" + str(e[2]))
			else:
				l.release("pad:" + str(e[2]))
		"rs":
			l.axis("pad:rs", float(e[3]), float(e[4]))


## Build `ticks` intents with the host's struggle word on from `s0` to before `s1`, with the push word `push`.
func _run(evs: Array, ticks: int, s0: int, s1: int, push: bool) -> Array:
	var l: SimLayout = _pad()
	var out: Array = []
	for t in range(ticks):
		for e in evs:
			if int(e[0]) == t:
				_apply(l, e)
		l.set_struggle(t >= s0 and t < s1, push)
		out.append(l.build())
		l.consumed()
	return out


func _starts(its: Array, from: int = 0, to: int = 100000) -> Array:
	var out: Array = []
	for t in range(from, mini(to, its.size())):
		if (its[t] as SimIntent).rsStart:
			out.append(t)
	return out


func _first(its: Array, field: String, from: int = 0) -> int:
	for t in range(from, its.size()):
		if (its[t] as SimIntent).get(field):
			return t
	return -1


func _a_direction() -> void:
	# A flick right at 20, left at 40, up at 60, each 4 ticks out and back, all inside a struggle from 15 to 90, push word on.
	var evs: Array = [[20, "rs", "", 1.0, 0.0], [24, "rs", "", 0.0, 0.0], [40, "rs", "", -1.0, 0.0], [44, "rs", "", 0.0, 0.0], [60, "rs", "", 0.0, 1.0], [64, "rs", "", 0.0, 0.0]]
	var its: Array = _run(evs, 100, 15, 90, true)
	var st: Array = _starts(its)
	ok(st.size() == 3, "A: three flicks are three request edges in the struggle (got %s)" % str(st))
	if st.size() == 3:
		ok((its[st[0]] as SimIntent).rsDir == RIGHT and (its[st[1]] as SimIntent).rsDir == LEFT and (its[st[2]] as SimIntent).rsDir == UP, "A: with their directions, right, left, up (the director turns them toward, away, nothing)")
		ok(st[0] >= 20 and st[0] <= 23 and st[1] >= 40 and st[1] <= 43 and st[2] >= 60 and st[2] <= 63, "A: each within the settle of its crossing (%s)" % str(st))


func _b_rearm() -> void:
	# Held out from 20 to 70: one edge only. Then a scrub between the lines (0.55 is above the release line and under the request line): no new edge.
	var held: Array = _run([[20, "rs", "", 1.0, 0.0], [70, "rs", "", 0.0, 0.0]], 100, 15, 95, true)
	ok(_starts(held).size() == 1, "B: holding the stick out is one request edge, not one a tick (got %s)" % str(_starts(held)))
	var scrub: Array = [[20, "rs", "", 1.0, 0.0], [30, "rs", "", 0.55, 0.0], [34, "rs", "", 1.0, 0.0], [38, "rs", "", 0.55, 0.0], [42, "rs", "", 1.0, 0.0], [60, "rs", "", 0.0, 0.0]]
	var its: Array = _run(scrub, 90, 15, 90, true)
	ok(_starts(its).size() == 1, "B: scrubbing between the lines is still the one edge (got %s)" % str(_starts(its)))
	# Back to rest and out again: a second edge. A second flick only 6 ticks after the first's return counts (the thumb has rested).
	var two: Array = _run([[20, "rs", "", 1.0, 0.0], [24, "rs", "", 0.0, 0.0], [30, "rs", "", 1.0, 0.0], [34, "rs", "", 0.0, 0.0]], 70, 15, 70, true)
	ok(_starts(two).size() == 2, "B: back to rest and out again is a second edge (got %s)" % str(_starts(two)))
	# The two edges are a beat apart at the rate the thumb flicks: 10 ticks here.
	var st: Array = _starts(two)
	ok(st.size() == 2 and st[1] - st[0] == 10, "B: ten ticks apart as flicked (got %s)" % str(st))


func _c_edges() -> void:
	# Out from 10, the struggle from 15: the held charge is let go on that tick (a cancel edge, no throw), the stick starts nothing until it rests, then a flick counts.
	var evs: Array = [[10, "rs", "", 1.0, 0.0], [40, "rs", "", 0.0, 0.0], [50, "rs", "", -1.0, 0.0], [54, "rs", "", 0.0, 0.0]]
	var its: Array = _run(evs, 90, 15, 90, true)
	ok(_first(its, "rsStart") == 12, "C: the stick had started a strike before the struggle (12)")
	ok(_first(its, "rsCancel") == 15, "C: it is let go on the struggle's first tick, a cancel edge (got %d)" % _first(its, "rsCancel"))
	ok(_first(its, "rsRelease") >= 50, "C: with no throw of the held charge (the first release is the later flick, got %d)" % _first(its, "rsRelease"))
	ok(_starts(its, 15).size() == 1 and _starts(its, 15)[0] >= 50, "C: the stick starts nothing until it has rested, then a flick counts (got %s)" % str(_starts(its, 15)))
	# A flick still going as the struggle ends is let go of: a cancel edge on the first tick after, no throw.
	var l: SimLayout = _pad()
	var out: Array = []
	for t in range(60):
		if t == 20:
			l.axis("pad:rs", 1.0, 0.0)
		if t == 45:
			l.axis("pad:rs", 0.0, 0.0)
		l.set_struggle(t >= 15 and t < 30, true)
		out.append(l.build())
		l.consumed()
	ok(_first(out, "rsCancel", 25) == 30, "C: a stick still out as the struggle ends is let go of at that tick (got %d)" % _first(out, "rsCancel", 25))
	ok(_first(out, "rsRelease") < 0 and _starts(out, 31).is_empty(), "C: and carries no strike into the fight")


func _d_faces() -> void:
	# X pressed at 28 and the stick out at 29: the press is free (its edge goes at 28) and the flick is not held back by it (no reverse lockout): the edge comes at the settle, 29 + 2.
	var evs: Array = [[28, "b", "west", true], [29, "rs", "", 1.0, 0.0], [30, "b", "west", false], [34, "rs", "", 0.0, 0.0]]
	var its: Array = _run(evs, 60, 15, 60, true)
	ok(_first(its, "light") == 28, "D: a face press in a struggle goes at once (28)")
	var st: Array = _starts(its)
	ok(st.size() == 1 and st[0] <= 31, "D: and the flick one tick after it is not held back by the reverse lockout (got %s; the face-mode lockout would be 36)" % str(st))
	# A face press during a flick (the director gives it no meaning in stick mode) leaves no queued blow behind for after the struggle.
	var evs2: Array = [[20, "rs", "", 1.0, 0.0], [22, "b", "west", true], [23, "b", "west", false], [26, "rs", "", 0.0, 0.0]]
	var its2: Array = _run(evs2, 70, 15, 40, true)
	ok(_first(its2, "light", 24) < 0, "D: a press the stick was busy with is not queued to come out later")


func _e_no_push() -> void:
	# With no push word, a struggle leaves the stick inert, as before: no edge in it.
	var evs: Array = [[20, "rs", "", 1.0, 0.0], [24, "rs", "", 0.0, 0.0], [40, "rs", "", -1.0, 0.0], [44, "rs", "", 0.0, 0.0]]
	var its: Array = _run(evs, 70, 15, 70, false)
	ok(_starts(its).is_empty(), "E: with no push word a struggle's flicks start nothing (face mode)")
	# Outside a struggle the push word means nothing: a flick is a strike.
	var l: SimLayout = _pad()
	var out: Array = []
	for t in range(40):
		if t == 10:
			l.axis("pad:rs", 1.0, 0.0)
		if t == 14:
			l.axis("pad:rs", 0.0, 0.0)
		l.set_struggle(false, true)
		out.append(l.build())
		l.consumed()
	ok(_starts(out).size() == 1, "E: outside a struggle the push word is nothing and a flick is the strike it always was")
	# The word is the struggle's: set_struggle(false, true) leaves struggle_push false.
	var l2: SimLayout = _pad()
	l2.set_struggle(false, true)
	ok(not l2.struggle_push and not l2.in_struggle, "E: set_struggle(false, true) is no push struggle")
	l2.set_struggle(true, true)
	ok(l2.struggle_push and l2.in_struggle, "E: set_struggle(true, true) is one")
	l2.set_struggle(true)
	ok(not l2.struggle_push and l2.in_struggle, "E: set_struggle(true) is a face-mode struggle (the old call)")


func _f_hub() -> void:
	# The pad through the hub, refusals on: a flick outside a struggle the director never starts is "no answer" after refuseTicks; a flick inside a stick-push struggle never is.
	var out_no_answer: Array = _hub_flick(false)
	var in_no_answer: Array = _hub_flick(true)
	var starts_in: int = int(in_no_answer[1])
	ok((out_no_answer[0] as Array).size() == 1 and str((out_no_answer[0] as Array)[0].get("code", "")) == "no_answer", "F: outside a struggle an unanswered flick is the one 'no answer' it always was (%s)" % str(out_no_answer[0]))
	ok((in_no_answer[0] as Array).is_empty(), "F: inside a stick-push struggle the flick is the push, never a 'no answer' (%s)" % str(in_no_answer[0]))
	ok(starts_in == 1, "F: and it reached the intent as a request edge through the hub (got %d)" % starts_in)
	# The refusal haptic too.
	ok(int(in_no_answer[2]) == 0, "F: no stick_refused knock for it either (got %d)" % int(in_no_answer[2]))


## Returns [refusals, request edges seen, stick_refused haptics]: one flick at tick 10 to 14, then 60 more ticks, struggle (with push) from tick 5 or none.
func _hub_flick(struggle: bool) -> Array:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var refusals: Array = []
	var edges: int = 0
	var knocks: int = 0
	for t in range(80):
		if t == 10:
			hub.pad_stick_right(7, 1.0, 0.0)
		if t == 14:
			hub.pad_stick_right(7, 0.0, 0.0)
		hub.set_struggle(0, struggle, struggle)
		var i: SimIntent = hub.intent(0)
		if i.rsStart:
			edges += 1
		for h in hub.take_haptics():
			if str(h.get("kind", "")) == "stick_refused":
				knocks += 1
		refusals.append_array(hub.take_refusals())
		hub.consumed()
	return [refusals, edges, knocks]


func _g_ladder() -> void:
	var r := SimStrikeRead.new()
	ok(r.beam_ladder == [12, 28, 46, 66, 90, 120], "G: the beam ladder is Encounter's six stages (got %s)" % str(r.beam_ladder))
	ok(r.ladder == [12, 30, 50], "G: the martial ladder is as it was")
	ok(r.level_at(120, true) == 6 and r.level_at(119, true) == 5, "G: the director's reading of a plain charge runs to the sixth rung")
	# The intent's level is cut to the wire's 3 whatever the count: a 130-tick hold on the energy layer holds level 3, and its throw is level 3.
	var l: SimLayout = _pad()
	var lv: int = 0
	var throw_lv: int = -1
	for t in range(150):
		if t == 5:
			l.press("pad:rb")
			l.axis("pad:rs", 1.0, 0.0)
		if t == 135:
			l.axis("pad:rs", 0.0, 0.0)
		var i: SimIntent = l.build()
		l.consumed()
		if i.rsHeld:
			lv = maxi(lv, i.rsLevel)
		if i.rsRelease:
			throw_lv = i.rsLevel
	ok(lv == 3 and throw_lv == 3, "G: a 130-tick beam hold is rsLevel 3 held and thrown (held %d, thrown %d)" % [lv, throw_lv])
	# A list of two (or seven) is refused: the default stands.
	var strike: Dictionary = SimInputData.timing.get("strike", {})
	var keep: Array = strike["beamLevels"]
	strike["beamLevels"] = [10, 20]
	SimInputData.timing["strike"] = strike
	SimInputData.invalidate()
	ok(SimStrikeRead.new().beam_ladder == [12, 28, 46, 66, 90, 120], "G: a two-rung list is refused and the default stands")
	strike["beamLevels"] = [1, 2, 3, 4, 5, 6, 7]
	SimInputData.invalidate()
	ok(SimStrikeRead.new().beam_ladder == [12, 28, 46, 66, 90, 120], "G: a seven-rung list is refused too")
	strike["beamLevels"] = [12, 28, 46]
	SimInputData.invalidate()
	ok(SimStrikeRead.new().beam_ladder == [12, 28, 46], "G: three rungs are accepted (a fighter who has only three stages)")
	strike["beamLevels"] = keep
	SimInputData.invalidate()
	# The pad's pulses (hapticLadder on): a 130-tick beam hold pulses at 12, 28 and 46 and no more (the host's stage cue is what would go on to 66, 90, 120).
	_switches(true, false, true)
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var at: Array = []
	var start_t: int = -1
	for t in range(150):
		if t == 5:
			hub.pad_button(7, "rb", true)
			hub.pad_stick_right(7, 1.0, 0.0)
		if t == 135:
			hub.pad_stick_right(7, 0.0, 0.0)
		var i: SimIntent = hub.intent(0)
		if i.rsStart and start_t < 0:
			start_t = t
		for h in hub.take_haptics():
			var k: String = str(h.get("kind", ""))
			if k.begins_with("ladder_"):
				at.append([k, t - start_t])
		hub.consumed()
	ok(at.size() == 3 and at[0][0] == "ladder_1" and at[1][0] == "ladder_2" and at[2][0] == "ladder_3", "G: the pad pulses a tick, a knock and a thud on a long beam hold (got %s)" % str(at))
	if at.size() == 3:
		ok(int(at[0][1]) == 12 and int(at[1][1]) == 28 and int(at[2][1]) == 46, "G: at 12, 28 and 46 ticks from the start: the first three stages (got %s)" % str(at))
	_switches(true, true)
