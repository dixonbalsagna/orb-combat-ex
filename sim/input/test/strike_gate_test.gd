extends SceneTree
## The claw-bot gate for the right-hand attacks (docs/controls/right-hand-attacks.md section 6.4, rows J to R, and the swap), run on the real layout with
## switches.rightStick ON, and the proof that with it OFF nothing changes. A scripted thumb (a "claw" that can press anything at any tick, the "fast" standard
## thumb that needs L = 6 ticks to cross between its stick and its face buttons, a slow one) drives the Arena pad; the invariant is on the intent stream:
##   J  strike then face, face then strike, for X, Y, B and A at every gap 0 to 40: the second command never overlaps the first, and the claw's best equals the fast thumb's
##   K  a face press during a charge starts no earlier than the throw + L (and an old one expires); the claw's blows in a charge window are none
##   L  the direction is locked at the settle
##   M  the same tick: the face press wins, the strike starts R later
##   N  the layer is the stance mask at the crossing tick, whichever event came first
##   O  right-hand noise leaves a slip, a brace and a vanish where they were
##   P  the arrow keys, the D-pad mirror and the strike key act on the stick's tick
##   Q  the vanish chord: LB and LT within 6 either order upgrade the dodge; 7 apart is a dodge and a guard; LT after a held LB is a plain dodge
##   R  R3 never produces an escape once freed
##   S  the swap: the same script on a mirrored pad with mirrored controls gives the identical intent stream
##   T  switches.rightStick off: the second word is 0 on every tick and the intents equal the layout without the strike bindings
##   U  the hybrids 3 and 10 come on with the switch, 9 does not; with it off none
## From the repo root:
##   godot --headless --path . --script res://sim/input/test/strike_gate_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0
var rig_swapped: bool = false   # the whole pad battery runs twice: on the standard preset and on the swapped one (Accessibility's rule 8)
var tag: String = ""

const FACE: Dictionary = {"X": "west", "Y": "north", "B": "east", "A": "south"}
const L: int = 6
const R: int = 8


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", tag, what)


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	_switch(true)
	for sw in [false, true]:
		rig_swapped = sw
		tag = "[swapped pad] " if sw else ""
		_row_j()
		_row_k()
		_row_l()
		_row_m()
		_row_n()
		_row_o()
		_row_p()
		_row_q()
		_row_r()
		_row_u()
		_row_inert()
		_row_struggle()
		_cancel_and_toggle()
		_pause()
		_row_strike_button()
		_row_brace_button()
		_row_vanish_button()
	rig_swapped = false
	tag = ""
	_row_s()
	_row_kb()
	_row_kb_swapped()
	_row_hand_layout()
	_switch(false)
	_row_t()
	_row_r_off()
	_row_u_off()
	print("strike_gate_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _switch(on: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = on
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _pad(swapped: bool = false, preset: String = "arena") -> SimLayout:
	var id: String = SimSwap.swapped_id(preset) if (swapped or rig_swapped) else preset   # the swapped layout is a real preset (SimInputData derives it)
	return SimLayout.new(SimInputData.preset(id))


## The control a pad event name stands for under the rig's layout.
func _ctl(c: String) -> String:
	return SimSwap.control(c) if rig_swapped else c


## A pad preset with one more binding (a custom bind, as the Remap screen would make), mirrored under the swapped rig.
func _pad_with(action: String, control: String) -> SimLayout:
	var p: Dictionary = SimInputData.preset("arena").duplicate(true)
	p["bindings"].append({"controls": [control], "action": action})
	if rig_swapped:
		p = SimSwap.mirror_preset(p)
		p["hand"] = "swapped"
	return SimLayout.new(p)


func _kb(preset: String = "kb-solo") -> SimLayout:
	return SimLayout.new(SimInputData.preset(preset))


## Events: [tick, kind, name, a, b]. "b" a button (a: down), "t" a trigger (a: 0..1), "ls"/"rs" a stick (a, b), "k" a key. `swapped` renames the pad controls.
func _apply(l: SimLayout, e: Array, swapped: bool) -> void:
	var kind: String = str(e[1])
	var name: String = str(e[2])
	match kind:
		"b":
			var c: String = "pad:" + name
			if swapped:
				c = SimSwap.control(c)
			if bool(e[3]):
				l.press(c)
			else:
				l.release(c)
		"t":
			var c2: String = "pad:" + name
			if swapped:
				c2 = SimSwap.control(c2)
			l.analog(c2, float(e[3]))
		"ls", "rs":
			var c3: String = "pad:" + kind
			if swapped:
				c3 = SimSwap.control(c3)
			l.axis(c3, float(e[3]), float(e[4]))
		"k":
			if bool(e[3]):
				l.press("kb:" + name)
			else:
				l.release("kb:" + name)


## Build `ticks` intents. Events whose tick is t are applied before build t (so an event at t shows in intent index t).
func _run(l: SimLayout, evs: Array, ticks: int, swapped: bool = false) -> Array:
	swapped = swapped or rig_swapped
	var out: Array = []
	for t in range(ticks):
		for e in evs:
			if int(e[0]) == t:
				_apply(l, e, swapped)
		out.append(l.build())
		l.consumed()
	return out


func _face_tick(its: Array, face: String, from: int = 0) -> int:
	for t in range(from, its.size()):
		var i: SimIntent = its[t]
		match face:
			"X": if i.light: return t
			"Y": if i.heavy: return t
			"B": if i.sig: return t
			"A": if i.context: return t
	return -1


func _first(its: Array, field: String, from: int = 0) -> int:
	for t in range(from, its.size()):
		if its[t].get(field):
			return t
	return -1


func _flick(t0: int, t1: int, dir: Vector2 = Vector2(1.0, 0.0)) -> Array:
	return [[t0, "rs", "", dir.x, dir.y], [t1, "rs", "", 0.0, 0.0]]


func _press(t: int, face: String, hold: int = 2) -> Array:
	return [[t, "b", FACE[face], true], [t + hold, "b", FACE[face], false]]


# ---- J --------------------------------------------------------------------------------------------------------

func _row_j() -> void:
	for face in ["X", "Y", "B", "A"]:
		var bad_a: int = 0
		var bad_b: int = 0
		var best_claw: int = 1000
		for g in range(0, 41):
			# strike (a 5-tick flick at 10), face pressed g ticks after the crossing
			var its: Array = _run(_pad(), _flick(10, 15) + _press(10 + g, face), 90)
			var ts: int = _first(its, "rsStart")
			var tr: int = _first(its, "rsRelease")
			var tf: int = _face_tick(its, face)
			if ts < 0 or tr < 0 or tf < 0:
				bad_a += 1
				continue
			var no_overlap: bool = (tf < ts and ts >= tf + R) or (tf >= tr + L)
			if not no_overlap:
				bad_a += 1
			for t in range(ts, tr):
				if its[t].get("light") or its[t].get("heavy") or its[t].get("sig") or its[t].get("context"):
					bad_a += 1
			if tf >= tr:
				best_claw = mini(best_claw, tf - 10)   # the face went AFTER the strike: its earliest tick over every gap
		ok(bad_a == 0, "J strike then %s: at every gap 0 to 40 the face never overlaps the strike (%d bad)" % [face, bad_a])
		# The fast standard thumb: lets go of the stick at 15 and presses at 15 + 6.
		var fast: Array = _run(_pad(), _flick(10, 15) + _press(15 + L, face), 90)
		var tf_fast: int = _face_tick(fast, face)
		ok(tf_fast == 15 + L, "J strike then %s: the law does not slow the fast thumb (press at 21 goes at %d)" % [face, tf_fast])
		ok(best_claw == tf_fast - 10, "J strike then %s: the claw's best (%d after the crossing) equals the fast thumb's (%d)" % [face, best_claw, tf_fast - 10])
		# face then strike
		var best_start: int = 1000
		for g2 in range(0, 31):
			var its2: Array = _run(_pad(), _press(10, face) + _flick(10 + g2, 10 + g2 + 5), 90)
			var tf2: int = _face_tick(its2, face)
			var ts2: int = _first(its2, "rsStart")
			if tf2 != 10 or ts2 < 0:
				bad_b += 1
				continue
			if ts2 < tf2 + R or ts2 < 10 + g2 + 2:
				bad_b += 1
			if g2 == 0:
				best_start = ts2
		ok(bad_b == 0, "J %s then strike: at every gap 0 to 30 the strike starts R after the face press and 2 after its crossing (%d bad)" % [face, bad_b])
		var fast2: Array = _run(_pad(), _press(10, face) + _flick(10 + L, 10 + L + 5), 90)
		ok(_first(fast2, "rsStart") == best_start, "J %s then strike: the claw's best start (%d) equals the fast thumb's (%d)" % [face, best_start, _first(fast2, "rsStart")])
	# The special layer: RT held with a face button is a face press too.
	var sp: Array = _run(_pad(), [[2, "t", "rt", 1.0]] + _flick(10, 15) + [[13, "b", "west", true], [15, "b", "west", false]], 60)
	var tfs: int = _first(sp, "special")
	ok(tfs >= _first(sp, "rsRelease") + L, "J special: RT + X during a strike waits for the throw + L (got %d)" % tfs)


# ---- K --------------------------------------------------------------------------------------------------------

func _row_k() -> void:
	for held in [12, 30, 54]:
		var evs: Array = [[10, "rs", "", 1.0, 0.0], [10 + held, "rs", "", 0.0, 0.0]]
		for tp in range(20, 10 + held, 6):   # a claw taps X at its mash cap throughout the charge
			evs.append([tp, "b", "west", true])
			evs.append([tp + 2, "b", "west", false])
		var its: Array = _run(_pad(), evs, 10 + held + 80)
		var tr: int = _first(its, "rsRelease")
		var blows: int = 0
		var early: int = 0
		for t in range(0, its.size()):
			if its[t].light:
				blows += 1
				if t < tr + L:
					early += 1
		ok(early == 0, "K charge of %d: no face blow before the throw + L (%d early)" % [held, early])
		ok(blows <= 3, "K charge of %d: at most the queue's depth (3) comes out afterwards, got %d" % [held, blows])
		var held_ticks: int = 0
		for t in range(0, its.size()):
			if its[t].rsHeld and (its[t].light or its[t].heavy or its[t].sig or its[t].context):
				held_ticks += 1
		ok(held_ticks == 0, "K charge of %d: not one face edge while the strike is in the sim's hands" % held)
		for t in range(0, its.size()):
			if its[t].rsHeld and (its[t].lightHeld or its[t].heavyHeld or its[t].sigHeld or its[t].contextHeld):
				held_ticks += 1
		ok(held_ticks == 0, "K charge of %d: and no held level either (nothing about a charge is changed by a face button)" % held)
	# A press made early in a long charge expires; one made late goes out.
	var evs2: Array = [[10, "rs", "", 1.0, 0.0], [90, "rs", "", 0.0, 0.0], [20, "b", "west", true], [22, "b", "west", false], [80, "b", "north", true], [82, "b", "north", false]]
	var its2: Array = _run(_pad(), evs2, 140)
	ok(_face_tick(its2, "X") < 0, "K: a press made at tick 20 of an 80-tick charge has expired by the throw (36 ticks)")
	ok(_face_tick(its2, "Y") >= _first(its2, "rsRelease") + L, "K: a press made late in the charge goes out after the throw + L")


# ---- L --------------------------------------------------------------------------------------------------------

func _row_l() -> void:
	var evs: Array = [[10, "rs", "", 1.0, 0.0], [14, "rs", "", 0.0, 1.0], [30, "rs", "", -1.0, 0.0], [40, "rs", "", 0.0, 0.0]]
	var its: Array = _run(_pad(), evs, 60)
	var dirs: Dictionary = {}
	for t in range(0, its.size()):
		if its[t].rsHeld:
			dirs[its[t].rsDir] = true
	ok(dirs.size() == 1 and dirs.has(SimStrikeRead.RIGHT), "L: a stick that wanders after the settle throws in the locked direction (%s)" % str(dirs.keys()))
	var starts: int = 0
	for t in range(0, its.size()):
		if its[t].rsStart:
			starts += 1
	ok(starts == 1, "L: one deflection past off and back is one strike")


# ---- M --------------------------------------------------------------------------------------------------------

func _row_m() -> void:
	for order in [0, 1]:
		var evs: Array = []
		if order == 0:
			evs = [[10, "b", "west", true], [12, "b", "west", false], [10, "rs", "", 1.0, 0.0], [15, "rs", "", 0.0, 0.0]]
		else:
			evs = [[10, "rs", "", 1.0, 0.0], [10, "b", "west", true], [12, "b", "west", false], [15, "rs", "", 0.0, 0.0]]
		var its: Array = _run(_pad(), evs, 60)
		ok(_face_tick(its, "X") == 10, "M order %d: the face press wins the tick" % order)
		ok(_first(its, "rsStart") == 10 + R, "M order %d: the strike starts R later (got %d)" % [order, _first(its, "rsStart")])


# ---- N --------------------------------------------------------------------------------------------------------

func _row_n() -> void:
	var cases: Array = [
		["RB the tick before the crossing", [[9, "t", "rb", 1.0]], SimStance.ENERGY],
		["RB on the crossing tick, stick first", [[10, "rs", "", 1.0, 0.0], [10, "t", "rb", 1.0]], SimStance.ENERGY],
		["RB on the crossing tick, RB first", [[10, "t", "rb", 1.0], [10, "rs", "", 1.0, 0.0]], SimStance.ENERGY],
		["RB a tick after the crossing", [[10, "rs", "", 1.0, 0.0], [11, "t", "rb", 1.0]], SimStance.MARTIAL],
		["LB held", [[5, "b", "lb", true], [10, "rs", "", 1.0, 0.0]], SimStance.DEFENSIVE],
		["nothing", [[10, "rs", "", 1.0, 0.0]], SimStance.MARTIAL],
	]
	for c in cases:
		var evs: Array = []
		for e in c[1]:
			evs.append(e)
		if not _has_stick(evs):
			evs.append([10, "rs", "", 1.0, 0.0])
		evs.append([16, "rs", "", 0.0, 0.0])
		# the RB / RT / LB cases above that do not list the stick get it
		var its: Array = _run(_pad(), evs, 40)
		var ts: int = _first(its, "rsStart")
		ok(ts >= 0 and its[ts].rsMask == int(c[2]), "N %s: the layer is %s (got %d)" % [c[0], SimStance.label(int(c[2])), its[ts].rsMask if ts >= 0 else -1])


func _has_stick(evs: Array) -> bool:
	for e in evs:
		if str(e[1]) == "rs":
			return true
	return false


# ---- O --------------------------------------------------------------------------------------------------------

func _left_marks(its: Array) -> Dictionary:
	var m: Dictionary = {"dodge": _first(its, "dodge"), "escape": _first(its, "escape"), "brace": _first(its, "brace")}
	var e: int = int(m["escape"])
	m["escape_mx"] = its[e].mx if e >= 0 else 0.0
	m["escape_my"] = its[e].my if e >= 0 else 0.0
	var b: int = int(m["brace"])
	m["brace_dir"] = its[b].braceDir if b >= 0 else 0
	return m


func _noise(t0: int) -> Array:
	var n: Array = []
	for k in range(4):
		n.append([t0 + k * 3, "b", "west", true])
		n.append([t0 + k * 3 + 1, "b", "west", false])
	n.append([t0 + 1, "rs", "", 0.0, -1.0])
	n.append([t0 + 6, "rs", "", 0.0, 0.0])
	return n


func _row_o() -> void:
	# A slip: LT and a flick of the left stick, with and without the right hand busy.
	var slip: Array = [[10, "t", "lt", 1.0], [11, "ls", "", 0.0, 1.0], [14, "ls", "", 0.0, 0.0], [20, "t", "lt", 0.0]]
	var a: Dictionary = _left_marks(_run(_pad(), slip, 50))
	var b: Dictionary = _left_marks(_run(_pad(), slip + _noise(9), 50))
	ok(a["dodge"] == 10 and b["dodge"] == 10, "O slip: the dodge starts on the press tick with the right hand busy or not")
	# A brace: LB held, a flick from rest.
	var brace: Array = [[2, "b", "lb", true], [20, "ls", "", 0.0, 1.0], [24, "ls", "", 0.0, 0.0]]
	var a2: Dictionary = _left_marks(_run(_pad(), brace, 50))
	var b2: Dictionary = _left_marks(_run(_pad(), brace + _noise(19), 50))
	ok(a2["brace"] >= 0 and a2["brace"] == b2["brace"] and a2["brace_dir"] == SimStrikeRead.UP and b2["brace_dir"] == SimStrikeRead.UP, "O brace: the read goes out on the same tick, the same way, with noise (%s vs %s)" % [str(a2["brace"]), str(b2["brace"])])
	# A vanish: LB and LT, a flick up, with RB and the right thumb busy.
	var van: Array = [[10, "b", "lb", true], [12, "t", "lt", 1.0], [11, "ls", "", 0.0, 1.0], [14, "ls", "", 0.0, 0.0]]
	var a3: Dictionary = _left_marks(_run(_pad(), van, 50))
	var noisy: Array = van + _noise(9) + [[10, "t", "rb", 1.0]]
	var b3: Dictionary = _left_marks(_run(_pad(), noisy, 50))
	ok(a3["escape"] >= 0 and a3["escape"] == b3["escape"] and a3["escape_my"] == b3["escape_my"] and a3["escape_my"] > 0.5, "O vanish: the same tick and direction with the right hand busy (%s vs %s)" % [str(a3["escape"]), str(b3["escape"])])
	ok(a3["dodge"] == b3["dodge"], "O vanish: and the dodge's own press tick")


# ---- P --------------------------------------------------------------------------------------------------------

func _row_p() -> void:
	var pad: Array = _run(_pad(), _flick(10, 15), 40)
	var padl: SimLayout = _pad()
	padl.set_mirror_dpad(true)
	var dpad: Array = _run(padl, [[10, "b", "dpad_right", true], [15, "b", "dpad_right", false]], 40)
	var ts: int = _first(pad, "rsStart")
	ok(ts == 12, "P stick: starts at the crossing + 2 (got %d)" % ts)
	ok(_first(dpad, "rsStart") == ts and dpad[ts].rsDir == pad[ts].rsDir, "P D-pad mirror: the same tick and direction as the stick")
	ok(_first(dpad, "rsRelease") == _first(pad, "rsRelease"), "P: and the same throw tick")
	var off: SimLayout = _pad()   # mirror setting off: the D-pad does nothing
	var dead: Array = _run(off, [[10, "b", "dpad_right", true], [15, "b", "dpad_right", false]], 40)
	ok(_first(dead, "rsStart") < 0, "P: with the mirror off the D-pad is not a strike stick")


# ---- Q --------------------------------------------------------------------------------------------------------

func _row_q() -> void:
	# LB first, LT 3 later, a flick up: the dodge on LT's press tick, the escape at max(10 + 6, 13 + 2) = 16, with up.
	var a: Array = _run(_pad(), [[10, "b", "lb", true], [11, "ls", "", 0.0, 1.0], [13, "t", "lt", 1.0], [13, "ls", "", 0.0, 0.0]], 50)
	ok(_first(a, "dodge") == 13, "Q: the dodge still starts on LT's press tick")
	ok(_first(a, "escape") == 16, "Q: LB then LT 3 apart: the escape at 16 (got %d)" % _first(a, "escape"))
	ok(a[16].my > 0.5, "Q: with the flick's direction (up)")
	var b: Array = _run(_pad(), [[10, "t", "lt", 1.0], [11, "b", "lb", true], [11, "ls", "", 1.0, 0.0], [13, "ls", "", 0.0, 0.0]], 50)
	ok(_first(b, "escape") == 16 and b[16].mx > 0.5, "Q: LT then LB: the same, to the right (%d)" % _first(b, "escape"))
	var c: Array = _run(_pad(), [[10, "b", "lb", true], [17, "t", "lt", 1.0]], 60)
	ok(_first(c, "escape") < 0 and _first(c, "dodge") == 17, "Q: LT 7 after LB is a dodge out of guard, no vanish")
	var d: Array = _run(_pad(), [[10, "b", "lb", true], [16, "t", "lt", 1.0]], 60)
	ok(_first(d, "escape") == 18, "Q: 6 apart is still the chord, and resolves at 18")
	var e: Array = _run(_pad(), [[10, "b", "lb", true], [12, "t", "lt", 1.0], [14, "t", "lt", 0.0]], 60)
	ok(_first(e, "escape") < 0, "Q: LT let go before it resolved: no vanish")
	var f: Array = _run(_pad(), [[10, "b", "lb", true], [12, "t", "lt", 1.0]], 60)
	ok(_first(f, "escape") == 16 and f[16].mx == 0.0 and f[16].my == 0.0, "Q: a neutral stick sends escape with a zero vector (away)")
	var n: int = 0
	for t in range(0, f.size()):
		if f[t].escape:
			n += 1
	ok(n == 1, "Q: one escape for one chord")


# ---- R --------------------------------------------------------------------------------------------------------

func _row_r() -> void:
	var its: Array = _run(_pad(), [[10, "b", "r3", true], [12, "b", "r3", false], [20, "b", "l3", true], [22, "b", "l3", false]], 40)
	ok(_first(its, "escape") < 0, "R: R3 (and L3) produce no escape once freed")


func _row_r_off() -> void:
	var its: Array = _run(_pad(), [[10, "b", "r3", true], [12, "b", "r3", false]], 40)
	ok(_first(its, "escape") == 10, "R off: with the switch off R3 is Escape, as it was")


# ---- S --------------------------------------------------------------------------------------------------------

func _random_script(seed: int, ticks: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var evs: Array = []
	var btns: Array = ["west", "north", "east", "south", "lb"]
	var trigs: Array = ["lt", "rt", "rb"]
	for t in range(ticks):
		if rng.randi() % 5 == 0:
			evs.append([t, "b", btns[rng.randi() % btns.size()], rng.randi() % 2 == 0])
		if rng.randi() % 9 == 0:
			evs.append([t, "t", trigs[rng.randi() % trigs.size()], float(rng.randi() % 2)])
		if rng.randi() % 6 == 0:
			var x: float = [-1.0, 0.0, 0.0, 1.0, 0.5][rng.randi() % 5]
			var y: float = [-1.0, 0.0, 0.0, 1.0, 0.5][rng.randi() % 5]
			evs.append([t, "rs", "", x, y])
		if rng.randi() % 6 == 0:
			var x2: float = [-1.0, 0.0, 0.0, 1.0][rng.randi() % 4]
			var y2: float = [-1.0, 0.0, 0.0, 1.0][rng.randi() % 4]
			evs.append([t, "ls", "", x2, y2])
	return evs


func _row_s() -> void:
	var diffs: int = 0
	var ticks: int = 600
	var any_strike: int = 0
	var any_escape: int = 0
	for sd in range(1, 9):
		var evs: Array = _random_script(sd, ticks)
		var plain: Array = _run(_pad(), evs, ticks)
		# The swapped pad: the same script with the controls mirrored, on the mirrored preset. The sticks swap, so a "rs" event goes to the left stick.
		var swapped: Array = _run(_pad(true), evs, ticks, true)
		for t in range(ticks):
			if SimIntent.pack(plain[t]) != SimIntent.pack(swapped[t]) or SimIntent.pack2(plain[t]) != SimIntent.pack2(swapped[t]):
				diffs += 1
			if plain[t].rsStart:
				any_strike += 1
			if plain[t].escape:
				any_escape += 1
	ok(diffs == 0, "S swap: 8 random scripts of 600 ticks give the identical intent stream on a mirrored pad (%d differing ticks)" % diffs)
	ok(any_strike > 20 and any_escape > 0, "S swap: and the scripts did strike (%d starts) and vanish (%d)" % [any_strike, any_escape])
	# The mirror is its own inverse and leaves the keyboard and the Start button alone.
	var p: Dictionary = SimInputData.preset("arena")
	ok(SimSwap.mirror_preset(SimSwap.mirror_preset(p)) == p, "S swap: swapping twice is the shipped preset")
	ok(SimSwap.control("pad:start") == "pad:start" and SimSwap.control("kb:KeyW") == "kb:KeyW", "S swap: Start and the keyboard are left alone")
	ok(SimSwap.control("pad:ls") == "pad:rs" and SimSwap.control("pad:lb") == "pad:rb" and SimSwap.control("pad:south") == "pad:dpad_down", "S swap: sticks, shoulders and face / D-pad trade sides")
	ok(SimSwap.mirror_preset(SimInputData.preset("kb-solo")) == SimInputData.preset("kb-solo"), "S swap: a keyboard preset is not swapped")
	# The claw model's numbers under the swap: the law reads the swap side's lockouts from data.
	var law := SimStrikeLaw.new(true)
	ok(law.lockout == 6 and law.reverse_lockout == 8, "S swap: the swapped side's lockouts default to the unswapped ones (never faster)")
	# Through the hub: with the swap on, the physical RIGHT stick moves and the physical LEFT stick strikes.
	var hub := SimInputHub.new()
	hub.reload_layouts()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.set_swap(true, 0)
	hub.pad_stick_right(7, 1.0, 0.0)
	hub.pad_button(7, "start", false)
	var moved: float = 0.0
	var struck: bool = false
	hub.pad_stick(7, 0.0, 0.0)
	hub.pad_stick_right(7, 1.0, 0.0)
	var i1: SimIntent = hub.intent(0)
	moved = i1.mx
	hub.consumed()
	ok(moved > 0.5, "S hub: with the swap on, the right stick moves (mx %.2f)" % moved)
	hub.pad_stick_right(7, 0.0, 0.0)
	hub.pad_stick(7, 1.0, 0.0)
	for t in range(6):
		var i2: SimIntent = hub.intent(0)
		struck = struck or i2.rsStart
		hub.consumed()
	ok(struck, "S hub: and the left stick strikes")
	hub.set_swap(false, 0)
	ok(not hub.swap_of(0), "S hub: the swap turns off again")


# ---- U --------------------------------------------------------------------------------------------------------

func _row_u() -> void:
	var h: Array = SimStance.hybrids()
	ok(h.has(3) and h.has(10) and not h.has(9), "U: with the switch on, the lay (3) and the kite (10) come on and the terrain hybrid (9) does not: %s" % str(h))
	var its: Array = _run(_pad(), [[5, "t", "lt", 1.0], [8, "t", "rb", 1.0]], 20)
	ok(its[15].stanceMask == SimStance.HYBRID_EVASIVE, "U: LT then RB held is the kite (10), got %d" % its[15].stanceMask)
	var its2: Array = _run(_pad(), [[5, "b", "lb", true], [8, "t", "rb", 1.0]], 20)
	ok(its2[15].stanceMask == SimStance.HYBRID_WARD, "U: LB and RB held is the lay (3), got %d" % its2[15].stanceMask)
	var its3: Array = _run(_pad(), [[5, "t", "lt", 1.0], [8, "b", "lb", true]], 20)
	ok(its3[15].stanceMask == SimStance.DEFENSIVE, "U: LT and LB held is still the newer button (guard), the terrain hybrid stays off")


func _row_u_off() -> void:
	ok(SimStance.hybrids().is_empty(), "U off: with the switch off no hybrid is on")


# ---- the strike BUTTON on a pad (Accessibility's one-stick form), the brace BUTTON and the single-control vanish -------------------------

func _row_strike_button() -> void:
	# L3 (R3 under the swap) bound to the strike button: the direction is the left stick's. It starts on the stick form's tick, in its direction, throws on its tick.
	var stick: Array = _run(_pad(), _flick(10, 15), 40)
	var ts: int = _first(stick, "rsStart")
	var evs: Array = [[10, "ls", "", 1.0, 0.0], [10, "b", "l3", true], [15, "b", "l3", false], [15, "ls", "", 0.0, 0.0]]
	var its: Array = _run(_pad_with("strike_key", "pad:l3"), evs, 40)
	ok(_first(its, "rsStart") == ts and its[ts].rsDir == SimStrikeRead.RIGHT, "strike button: with the left stick right it starts on the stick's tick (%d), to the right" % ts)
	ok(_first(its, "rsRelease") == _first(stick, "rsRelease"), "strike button: and throws on the stick's tick")
	var evs0: Array = [[10, "b", "l3", true], [15, "b", "l3", false]]
	var its0: Array = _run(_pad_with("strike_key", "pad:l3"), evs0, 40)
	ok(_first(its0, "rsStart") == ts and its0[ts].rsDir == 0, "strike button: with no direction held it starts with dir 0 (toward him)")
	# The law holds on it: a face press during the strike waits for the throw + L, and one on the crossing tick wins.
	var evs2: Array = evs + [[13, "b", "west", true], [14, "b", "west", false]]
	var its2: Array = _run(_pad_with("strike_key", "pad:l3"), evs2, 60)
	ok(_face_tick(its2, "X") >= _first(its2, "rsRelease") + L, "strike button: a face press during it waits for the throw + L (got %d)" % _face_tick(its2, "X"))
	var evs3: Array = evs + [[10, "b", "west", true], [11, "b", "west", false]]
	var its3: Array = _run(_pad_with("strike_key", "pad:l3"), evs3, 60)
	ok(_face_tick(its3, "X") == 10 and _first(its3, "rsStart") == 10 + R, "strike button: the same tick, the face wins and the strike starts R later")
	# It moves the fighter too (the left stick is the movement) and is a button of the attack hand's rig: unbound, it is nothing.
	var none: Array = _run(_pad(), evs, 40)
	ok(_first(none, "rsStart") < 0, "strike button: unbound by default, L3 does nothing")


func _row_brace_button() -> void:
	# The brace BUTTON (timing-free): pressed with the direction already held on the left stick, the read goes out 2 ticks later; no LB, no flick speed.
	var evs: Array = [[10, "ls", "", 0.0, 1.0], [10, "b", "l3", true], [12, "b", "l3", false]]
	var its: Array = _run(_pad_with("brace_key", "pad:l3"), evs, 40)
	var tb: int = _first(its, "brace")
	ok(tb == 12 and its[tb].braceDir == SimStrikeRead.UP, "brace button: stick up held at the press: the up read, 2 ticks later (got %d)" % tb)
	var evs2: Array = [[10, "b", "l3", true], [11, "ls", "", 1.0, 0.0], [13, "b", "l3", false]]
	var its2: Array = _run(_pad_with("brace_key", "pad:l3"), evs2, 40)
	ok(_first(its2, "brace") == 12 and its2[12].braceDir == SimStrikeRead.RIGHT, "brace button: a direction taken inside the settle counts (right)")
	var its3: Array = _run(_pad_with("brace_key", "pad:l3"), [[10, "b", "l3", true], [12, "b", "l3", false]], 40)
	ok(_first(its3, "brace") == 12 and its3[12].braceDir == 0, "brace button: no direction held: the read is set with direction 0 (the director picks)")
	var n: int = 0
	for t in range(its.size()):
		if its[t].brace:
			n += 1
	ok(n == 1, "brace button: one press, one read")
	# Defence purity: the right hand busy leaves its tick and direction alone.
	var noisy: Array = _run(_pad_with("brace_key", "pad:l3"), evs + _noise(9), 40)
	ok(_first(noisy, "brace") == tb and noisy[tb].braceDir == SimStrikeRead.UP, "brace button: the same tick and direction with the right hand busy")
	# The assist: "press" turns the flick read off and leaves the button; "flick" is the default.
	var flick: Array = [[2, "b", "lb", true], [20, "ls", "", 0.0, 1.0], [24, "ls", "", 0.0, 0.0]]
	var l: SimLayout = _pad_with("brace_key", "pad:l3")
	l.set_brace_flick(false)
	var off: Array = _run(l, flick, 50)
	ok(_first(off, "brace") < 0, "brace button: with brace_style press the flick sets no read")
	var l2: SimLayout = _pad_with("brace_key", "pad:l3")
	l2.set_brace_flick(false)
	var on: Array = _run(l2, evs, 40)
	ok(_first(on, "brace") == tb, "brace button: and the button still does")
	ok(_first(_run(_pad(), flick, 50), "brace") >= 0, "brace button: by default the flick sets the read")


func _row_vanish_button() -> void:
	# The single-control vanish: Escape bound to any control by the player (here L3), a pad's one-button Escape; the direction is the left stick at the press.
	var l: SimLayout = _pad_with("escape", "pad:l3")
	var its: Array = _run(l, [[10, "ls", "", 0.0, 1.0], [10, "b", "l3", true], [12, "b", "l3", false]], 40)
	ok(_first(its, "escape") == 10 and its[10].my > 0.5, "vanish button: one control sends escape on its press tick with the stick's direction (up)")
	var plain: Array = _run(_pad(), [[10, "b", "l3", true], [12, "b", "l3", false]], 40)
	ok(_first(plain, "escape") < 0, "vanish button: unbound by default (R3 and L3 are freed)")
	# A toggled guard plus LT is a plain dodge, but the button does not need the chord.
	var tg: SimLayout = _pad_with("escape", "pad:l3")
	tg.set_hold_style("guard", "toggle")
	var tgi: Array = _run(tg, [[5, "b", "lb", true], [6, "b", "lb", false], [20, "b", "l3", true]], 40)
	ok(_first(tgi, "escape") == 20, "vanish button: reachable with a toggled guard (no chord needed)")


# ---- the inert layers (pure 4a) --------------------------------------------------------------------------------------

func _row_inert() -> void:
	# RT held (the power layer): the stick does nothing and the faces stay free (the special goes at once).
	var a: Array = _run(_pad(), [[2, "t", "rt", 1.0], [10, "rs", "", 1.0, 0.0], [20, "b", "west", true], [22, "b", "west", false], [40, "rs", "", 0.0, 0.0]], 60)
	ok(_first(a, "rsStart") < 0 and _first(a, "rsHeld") < 0, "inert: RT held, the stick starts no strike")
	ok(_first(a, "special") == 20, "inert: and a face press goes at once (a special, tick 20)")
	# The lay (LB + RB, hybrid 3): inert too.
	var b: Array = _run(_pad(), [[2, "b", "lb", true], [3, "t", "rb", 1.0], [10, "rs", "", 1.0, 0.0], [20, "b", "west", true], [22, "b", "west", false], [40, "rs", "", 0.0, 0.0]], 60)
	ok(_first(b, "rsStart") < 0, "inert: the lay (LB + RB) starts no strike")
	ok(_face_tick(b, "X") == 20, "inert: and the faces are free in it")
	# RT let go with the stick still out: it must rest first, then it is a strike again.
	var c: Array = _run(_pad(), [[2, "t", "rt", 1.0], [10, "rs", "", 1.0, 0.0], [20, "t", "rt", 0.0], [40, "rs", "", 0.0, 0.0], [50, "rs", "", 0.0, 1.0], [54, "rs", "", 0.0, 0.0]], 80)
	ok(_first(c, "rsStart") >= 50, "inert: a stick pushed under RT and still out after it fires nothing until it rests")
	# Energy (RB) and the kite (LT + RB) and the guard / manoeuvre stances do strike.
	for case in [["RB", [[2, "t", "rb", 1.0]], SimStance.ENERGY], ["LT + RB", [[2, "t", "lt", 1.0], [3, "t", "rb", 1.0]], SimStance.HYBRID_EVASIVE], ["LT", [[2, "t", "lt", 1.0]], SimStance.MANOEUVRE]]:
		var evs: Array = []
		for e in case[1]:
			evs.append(e)
		evs.append([20, "rs", "", 1.0, 0.0])
		evs.append([26, "rs", "", 0.0, 0.0])
		var its: Array = _run(_pad(), evs, 50)
		var ts: int = _first(its, "rsStart")
		ok(ts >= 0 and its[ts].rsMask == int(case[2]), "inert: %s strikes, with layer %d" % [case[0], int(case[2])])


# ---- a struggle: the stick does nothing, the faces are free -------------------------------------------------------------

func _row_struggle() -> void:
	# The host says "struggle" from tick 15: a started strike is cancelled (an edge), the stick starts nothing, and the surges go at once.
	var l: SimLayout = _pad()
	var its: Array = []
	var evs: Array = [[10, "rs", "", 1.0, 0.0], [40, "rs", "", 0.0, 0.0], [20, "b", "west", true], [21, "b", "west", false], [24, "b", "north", true], [25, "b", "north", false], [60, "rs", "", 0.0, 1.0], [70, "rs", "", 0.0, 0.0], [64, "b", "west", true], [65, "b", "west", false]]
	for t in range(90):
		for e in evs:
			if int(e[0]) == t:
				_apply(l, e, rig_swapped)
		l.set_struggle(t >= 15 and t < 80)
		its.append(l.build())
		l.consumed()
	ok(_first(its, "rsStart") == 12, "struggle: before it the strike started (12)")
	ok(_first(its, "rsCancel") == 15, "struggle: and it is cancelled on the first tick of the struggle (got %d)" % _first(its, "rsCancel"))
	ok(_first(its, "rsRelease") < 0, "struggle: with no throw")
	ok(_face_tick(its, "X") == 20 and _face_tick(its, "Y") == 24, "struggle: the surges go on their own press ticks, stick out or not (X %d, Y %d)" % [_face_tick(its, "X"), _face_tick(its, "Y")])
	var starts_in: int = 0
	for t in range(15, 80):
		if its[t].rsStart:
			starts_in += 1
	ok(starts_in == 0, "struggle: a push inside it starts nothing")
	ok(_face_tick(its, "X", 60) == 64, "struggle: and a face press with the stick out goes at once (X at 64)")
	# Nothing queued from before goes out as a surge.
	var l2: SimLayout = _pad()
	var evs2: Array = [[10, "rs", "", 1.0, 0.0], [14, "b", "west", true], [15, "b", "west", false], [30, "rs", "", 0.0, 0.0]]
	var its2: Array = []
	for t in range(60):
		for e in evs2:
			if int(e[0]) == t:
				_apply(l2, e, rig_swapped)
		l2.set_struggle(t >= 20)
		its2.append(l2.build())
		l2.consumed()
	ok(_face_tick(its2, "X") < 0, "struggle: a press queued before the struggle does not come out inside it as a surge")


# ---- cancel, toggle, pause -------------------------------------------------------------------------------------

func _cancel_and_toggle() -> void:
	# A guard press during a charge cancels it: a cancel edge, no throw; the faces stay inert while the stick is out and free L after it rests.
	var evs: Array = [[10, "rs", "", 1.0, 0.0], [30, "b", "lb", true], [32, "b", "lb", false], [40, "rs", "", 0.0, 0.0], [34, "b", "west", true], [36, "b", "west", false]]
	var its: Array = _run(_pad(), evs, 90)
	ok(_first(its, "rsCancel") == 30, "cancel: LB pressed at 30 cancels the charge on that tick (got %d)" % _first(its, "rsCancel"))
	ok(_first(its, "rsRelease") < 0, "cancel: and nothing is thrown")
	ok(_face_tick(its, "X") >= 40 + L, "cancel: the face press made while the stick is still out waits for it to rest + L (got %d)" % _face_tick(its, "X"))
	var evs2: Array = [[10, "rs", "", 1.0, 0.0], [30, "t", "lt", 1.0], [40, "rs", "", 0.0, 0.0]]
	var its2: Array = _run(_pad(), evs2, 70)
	ok(_first(its2, "rsCancel") == 30 and _first(its2, "dodge") == 30, "cancel: the dodge cancels it too, and starts on its own press tick")
	# Toggle style: a push starts the charge, the next push throws it.
	var l: SimLayout = _pad()
	l.set_strike_style("toggle")
	var its3: Array = _run(l, [[10, "rs", "", 1.0, 0.0], [14, "rs", "", 0.0, 0.0], [40, "rs", "", 1.0, 0.0], [43, "rs", "", 0.0, 0.0]], 70)
	ok(_first(its3, "rsStart") == 12 and _first(its3, "rsRelease") == 40, "toggle: starts at 12, thrown by the next push at 40 (got %d, %d)" % [_first(its3, "rsStart"), _first(its3, "rsRelease")])
	ok(its3[39].rsHeld and its3[39].rsLevel >= 1, "toggle: and the charge ran while the stick rested")


func _pause() -> void:
	# A pause drops the strike: a stick still out after it fires nothing until it has rested.
	var l: SimLayout = _pad()
	var its: Array = []
	for t in range(40):
		if t == 5:
			l.axis(_ctl("pad:rs"), 1.0, 0.0)
		if t == 20:
			l.drop_edges()
			l.resume()
		its.append(l.build())
		l.consumed()
	var after: int = 0
	for t in range(21, 40):
		if its[t].rsStart:
			after += 1
	ok(after == 0, "pause: a stick still out after a pause starts nothing")
	l.axis(_ctl("pad:rs"), 0.0, 0.0)
	for t in range(4):
		l.build()
		l.consumed()
	l.axis(_ctl("pad:rs"), 0.0, 1.0)
	var got: bool = false
	for t in range(6):
		var i: SimIntent = l.build()
		got = got or i.rsStart
		l.consumed()
	ok(got, "pause: and after it rests, the next push is a strike")


# ---- T --------------------------------------------------------------------------------------------------------

func _row_t() -> void:
	# Switch off: a layout built from the shipped preset gives the same intents as one built without the strike bindings, and the second word is 0.
	var shipped: Dictionary = SimInputData.preset("arena")
	ok(not _has_action(shipped, "strike"), "T: with the switch off the preset carries no strike binding")
	var bare: Dictionary = SimInputData.original("arena").duplicate(true)
	bare.erase("strikeBindings")
	var diffs: int = 0
	var w2: int = 0
	for sd in range(1, 6):
		var evs: Array = _random_script(sd, 500)
		var a: Array = _run(_pad(), evs, 500)
		var lb := SimLayout.new(bare)
		var b: Array = _run(lb, evs, 500)
		for t in range(500):
			if SimIntent.pack(a[t]) != SimIntent.pack(b[t]) or SimIntent.pack2(a[t]) != 0 or SimIntent.pack2(b[t]) != 0:
				diffs += 1
			if a[t].rsHeld or a[t].rsStart or a[t].brace:
				w2 += 1
	ok(diffs == 0 and w2 == 0, "T off: 5 random scripts: the intents equal the layout without the strike bindings and the second word is 0 (%d differ, %d set)" % [diffs, w2])
	var kb: Array = _run(_kb(), [[10, "k", "ArrowRight", true], [15, "k", "ArrowRight", false]], 30)
	ok(_first(kb, "rsStart") < 0, "T off: the arrow keys strike nothing")
	var hub := SimInputHub.new()
	ok(hub.mirror_on(0) == false, "T off: the D-pad mirror is a setting, off by default")


func _has_action(p: Dictionary, a: String) -> bool:
	for b in p.get("bindings", []):
		if str(b["action"]) == a:
			return true
	return false


# ---- the keyboards -----------------------------------------------------------------------------------------------------

func _row_kb() -> void:
	var pad: Array = _run(_pad(), _flick(10, 15), 40)
	var ts: int = _first(pad, "rsStart")
	var kb: Array = _run(_kb(), [[10, "k", "ArrowRight", true], [15, "k", "ArrowRight", false]], 40)
	ok(_first(kb, "rsStart") == ts and kb[ts].rsDir == pad[ts].rsDir, "kb P arrow keys: the same tick and direction as the stick")
	ok(_first(kb, "rsRelease") == _first(pad, "rsRelease"), "kb P: and the same throw tick")
	# The shared keyboard's strike key, with a movement key for the direction (and none: toward him).
	var key: Array = _run(_kb("kb-shared-p1"), [[10, "k", "KeyB", true], [10, "k", "KeyD", true], [15, "k", "KeyB", false], [15, "k", "KeyD", false]], 40)
	ok(_first(key, "rsStart") == ts and key[ts].rsDir == SimStrikeRead.RIGHT, "kb P strike key: B with D held starts on the stick's tick, to the right")
	var key0: Array = _run(_kb("kb-shared-p1"), [[10, "k", "KeyB", true], [15, "k", "KeyB", false]], 40)
	ok(_first(key0, "rsStart") == ts and key0[ts].rsDir == 0, "kb P strike key: with no direction it starts with dir 0 (toward him)")
	var kf: Array = _run(_kb("kb-shared-p1"), [[10, "k", "KeyB", true], [15, "k", "KeyB", false], [13, "k", "KeyF", true], [14, "k", "KeyF", false]], 60)
	ok(_first(kf, "light") >= _first(kf, "rsRelease") + L, "kb P: F during a strike waits for the throw + L")
	var kk: Array = _run(_kb("kb-solo"), [[10, "k", "ArrowRight", true], [15, "k", "ArrowRight", false], [13, "k", "KeyJ", true], [14, "k", "KeyJ", false]], 60)
	ok(_first(kk, "light") >= _first(kk, "rsRelease") + L, "kb P: and J during an arrow strike on the solo keyboard")
	# The vanish chord and its single-key mirror.
	var kv: Array = _run(_kb(), [[10, "k", "Shift", true], [11, "k", "Space", true], [11, "k", "KeyW", true], [13, "k", "KeyW", false]], 50)
	ok(_first(kv, "escape") == 16 and kv[16].my > 0.5, "kb Q: Shift + Space and a tap of W is the vanish up (%d)" % _first(kv, "escape"))
	var kc: Array = _run(_kb(), [[10, "k", "KeyC", true], [11, "k", "KeyC", false]], 20)
	ok(_first(kc, "escape") == 10, "kb Q: the single-key mirror C still sends escape on its press tick")
	# The brace: a tap with Shift down, and the brace key (timing-free) with the direction held.
	var kt: Array = _run(_kb(), [[2, "k", "Shift", true], [20, "k", "KeyW", true], [23, "k", "KeyW", false]], 50)
	ok(_first(kt, "brace") == 23 and kt[23].braceDir == SimStrikeRead.UP, "kb brace: a tap of W with Shift down sets the up read on the release")
	var kw: Array = _run(_kb(), [[2, "k", "Shift", true], [20, "k", "KeyW", true], [40, "k", "KeyW", false]], 60)
	ok(_first(kw, "brace") < 0, "kb brace: walking guarded (a hold) sets none")
	var kbk: Array = _run(_kb(), [[10, "k", "KeyW", true], [10, "k", "KeyX", true], [12, "k", "KeyX", false]], 40)
	ok(_first(kbk, "brace") == 12 and kbk[12].braceDir == SimStrikeRead.UP, "kb brace key: X with W held sets the up read 2 ticks later, no Shift, no flick")
	# R3 mirrors stay.
	var kr: Array = _run(_kb(), [[10, "k", "KeyC", true]], 20)
	ok(_first(kr, "escape") == 10, "kb R: the keyboard's C is still Escape")


## The swapped solo keyboard (hand_layout "swapped"): arrows move, WASD strikes, F G R V are the faces, the law and the reads are the same.
func _row_kb_swapped() -> void:
	var sw := func(): return SimLayout.new(SimInputData.preset("kb-solo-swapped"))
	var std: Array = _run(_kb(), [[10, "k", "ArrowRight", true], [15, "k", "ArrowRight", false]], 40)
	var ts: int = _first(std, "rsStart")
	var a: Array = _run(sw.call(), [[10, "k", "KeyD", true], [15, "k", "KeyD", false]], 40)
	ok(_first(a, "rsStart") == ts and a[ts].rsDir == SimStrikeRead.RIGHT and _first(a, "rsRelease") == _first(std, "rsRelease"), "kb swapped: D strikes right on the standard keyboard's tick")
	var mv: Array = _run(sw.call(), [[10, "k", "ArrowRight", true]], 20)
	ok(mv[12].mx > 0.5, "kb swapped: the arrows move")
	var b: Array = _run(sw.call(), [[10, "k", "KeyD", true], [15, "k", "KeyD", false], [13, "k", "KeyF", true], [14, "k", "KeyF", false]], 60)
	ok(_first(b, "light") >= _first(b, "rsRelease") + L, "kb swapped: F during a strike waits for the throw + L")
	var c: Array = _run(sw.call(), [[10, "k", "KeyF", true], [11, "k", "KeyF", false], [10, "k", "KeyD", true], [15, "k", "KeyD", false]], 60)
	ok(_first(c, "light") == 10 and _first(c, "rsStart") == 10 + R, "kb swapped: the same tick: the face wins, the strike starts R later")
	var d: Array = _run(sw.call(), [[10, "k", "Shift", true], [11, "k", "Space", true], [11, "k", "ArrowUp", true], [13, "k", "ArrowUp", false]], 50)
	ok(_first(d, "escape") == 16 and d[16].my > 0.5, "kb swapped: Shift + Space and a tap of Up is the vanish up")
	var e: Array = _run(sw.call(), [[10, "k", "Period", true], [10, "k", "ArrowUp", true], [12, "k", "Period", false]], 40)
	ok(_first(e, "brace") == 12 and e[12].braceDir == SimStrikeRead.UP, "kb swapped: the brace key (Period) with Up held sets the up read")
	var f: Array = _run(sw.call(), [[10, "k", "Quote", true]], 20)
	ok(_first(f, "escape") == 10, "kb swapped: Quote is the single-key Escape")
	var g: Array = _run(sw.call(), [[10, "k", "KeyF", true], [11, "k", "KeyF", false], [2, "k", "KeyE", true]], 30)
	ok(_first(g, "special") == 10, "kb swapped: E + F is special 1")
	# The preset passes the checks and shares no key within itself; the swapped law takes the swapped thumb's lockouts.
	var p: Dictionary = SimInputData.preset("kb-solo-swapped")
	ok(SimInputData.check_bindings(p, 0).is_empty(), "kb swapped: the preset has no problems: %s" % str(SimInputData.check_bindings(p, 0)))
	ok(sw.call().swapped, "kb swapped: the layout is marked swapped (the swapped lockouts)")


## hand_layout through the hub: the same hub drives the standard and the swapped layout of a pad and of the solo keyboard.
func _row_hand_layout() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(5, "south", true)
	hub.pad_button(5, "south", false)
	for t in range(12):
		hub.intent(0)
		hub.consumed()
	ok(hub.hand_layout_of(0) == "standard", "hand_layout: standard by default")
	hub.set_hand_layout("swapped", 0)
	hub.pad_stick_right(5, 1.0, 0.0)
	var i: SimIntent = hub.intent(0)
	hub.consumed()
	ok(i.mx > 0.5 and hub.pads[5].swapped, "hand_layout: swapped pad: the right stick moves and the layout takes the swapped lockouts")
	hub.set_hand_layout("standard", 0)
	ok(hub.swap_of(0) == false, "hand_layout: and back to standard")
	# the keyboard
	var kh := SimInputHub.new()
	kh.set_humans(true, false)
	kh.set_hand_layout("swapped", 0)
	kh.key("KeyD", true)
	var started: bool = false
	for t in range(5):
		var k: SimIntent = kh.intent(0)
		started = started or k.rsStart
		kh.consumed()
	ok(started, "hand_layout: swapped keyboard through the hub: D strikes")
	kh.key("KeyD", false)
	kh.set_hand_layout("standard", 0)
	kh.key("ArrowRight", true)
	for t in range(12):
		kh.intent(0)
		kh.consumed()
	kh.key("ArrowRight", false)
	# brace style through the hub
	var bh := SimInputHub.new()
	ok(bh.brace_style_of(0) == "flick", "brace style: flick by default")
	bh.set_brace_style("press", 1)
	ok(bh.brace_style_of(1) == "press" and bh.brace_style_of(0) == "flick", "brace style: press is player two's own")
