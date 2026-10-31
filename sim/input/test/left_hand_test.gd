extends SceneTree
## Headless checks for the left hand's brace and vanish reads (sim/input/left_hand.gd, docs/controls/right-hand-attacks.md section 2): a quick flick from
## rest with LB down is a brace in the flick's direction; a lean, a flick without LB, a flick without a rest first, and a second flick before the stick
## rested are not; a keyboard TAP with LB down is; LB and LT within the window (either order, still down) resolve to a vanish with the strongest direction
## of the gather; further apart, or let go early, they do not. From the repo root:
##   godot --headless --path . --script res://sim/input/test/left_hand_test.gd
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
	_brace_pad()
	_brace_keys()
	_vanish()
	print("left_hand_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


## Run a stick sequence (one Vector2 a tick) with LB down for the whole run (or from `guard_from`); returns [[tick, dir], ...] for each brace.
func _braces(seq: Array, digital: bool = false, guard_from: int = 0) -> Array:
	var h := SimLeftHand.new()
	var out: Array = []
	for t in range(seq.size()):
		var v: Vector2 = seq[t]
		h.step(v.x, v.y, digital, t >= guard_from, false, t == guard_from, false, t + 1)
		if h.brace:
			out.append([t + 1, h.brace_dir])
	return out


func _hold(v: Vector2, n: int) -> Array:
	var a: Array = []
	for i in range(n):
		a.append(v)
	return a


func _brace_pad() -> void:
	# A flick up from a stick that sat at rest: the read goes out 2 ticks after the crossing, up.
	var seq: Array = _hold(Vector2.ZERO, 12) + _hold(Vector2(0.0, 1.0), 4) + _hold(Vector2.ZERO, 12)
	var b: Array = _braces(seq)
	ok(b.size() == 1 and b[0][1] == SimStrikeRead.UP, "brace: a flick up with LB down sets the up read")
	ok(b.size() == 1 and b[0][0] == 15, "brace: it goes out 2 ticks after the crossing (tick 15), got %s" % str(b))
	for pair in [[Vector2(0.0, -1.0), SimStrikeRead.DOWN], [Vector2(-1.0, 0.0), SimStrikeRead.LEFT], [Vector2(1.0, 0.0), SimStrikeRead.RIGHT]]:
		var s2: Array = _hold(Vector2.ZERO, 12) + _hold(pair[0], 4) + _hold(Vector2.ZERO, 12)
		var b2: Array = _braces(s2)
		ok(b2.size() == 1 and b2[0][1] == pair[1], "brace: the four ways, %s" % str(pair[0]))
	# A slow lean (rises over 16 ticks) sets nothing: walking guarded is not a brace.
	var lean: Array = _hold(Vector2.ZERO, 12)
	for k in range(1, 17):
		lean.append(Vector2(0.0, float(k) / 16.0))
	lean.append_array(_hold(Vector2(0.0, 1.0), 20))
	ok(_braces(lean).is_empty(), "brace: a lean is not a flick")
	# Not at rest first (the stick was moving 5 ticks ago): nothing.
	var busy: Array = _hold(Vector2(0.0, 0.5), 3) + _hold(Vector2.ZERO, 5) + _hold(Vector2(0.0, 1.0), 4) + _hold(Vector2.ZERO, 10)
	ok(_braces(busy).is_empty(), "brace: a flick without 10 ticks of rest first sets nothing")
	# Without LB down: nothing.
	var nolb: Array = _hold(Vector2.ZERO, 12) + _hold(Vector2(0.0, 1.0), 4) + _hold(Vector2.ZERO, 12)
	ok(_braces(nolb, false, 1000).is_empty(), "brace: no LB, no read")
	# Two flicks: the second needs its own rest.
	var two: Array = _hold(Vector2.ZERO, 12) + _hold(Vector2(1.0, 0.0), 4) + _hold(Vector2.ZERO, 3) + _hold(Vector2(0.0, 1.0), 4) + _hold(Vector2.ZERO, 12)
	ok(_braces(two).size() == 1, "brace: one at a time: the second flick came before the stick rested")
	var two_ok: Array = _hold(Vector2.ZERO, 12) + _hold(Vector2(1.0, 0.0), 4) + _hold(Vector2.ZERO, 12) + _hold(Vector2(0.0, 1.0), 4) + _hold(Vector2.ZERO, 12)
	ok(_braces(two_ok).size() == 2, "brace: and with a rest between, two")
	# LB pressed late (after the settle): the flick was an ordinary one.
	var late: Array = _hold(Vector2.ZERO, 12) + _hold(Vector2(0.0, 1.0), 4) + _hold(Vector2.ZERO, 12)
	ok(_braces(late, false, 16).is_empty(), "brace: LB pressed after the flick is no brace")


func _brace_keys() -> void:
	# A tap of a direction key with LB down: up and down inside 8 ticks, read on the release.
	var seq: Array = _hold(Vector2.ZERO, 5) + _hold(Vector2(0.0, 1.0), 4) + _hold(Vector2.ZERO, 6)
	var b: Array = _braces(seq, true)
	ok(b.size() == 1 and b[0][1] == SimStrikeRead.UP, "keys: a tap of up with LB down is the up read")
	ok(b.size() == 1 and b[0][0] == 10, "keys: read on the release tick (10), got %s" % str(b))
	var walk: Array = _hold(Vector2.ZERO, 5) + _hold(Vector2(1.0, 0.0), 30) + _hold(Vector2.ZERO, 6)
	ok(_braces(walk, true).is_empty(), "keys: walking guarded (a hold) is not a brace")
	var diag: Array = _hold(Vector2.ZERO, 5) + _hold(Vector2(1.0, 1.0), 3) + _hold(Vector2.ZERO, 4)
	var bd: Array = _braces(diag, true)
	ok(bd.size() == 1 and bd[0][1] == SimStrikeRead.UP, "keys: two keys at once take the vertical (a tie goes to the vertical)")
	ok(_braces(seq, true, 1000).is_empty(), "keys: no LB, no read")


## Run a vanish scenario: the press ticks of LB (guard) and LT (dodge), the release ticks (-1 for never), the stick by tick. Returns [tick, vec] or [].
func _vanish_run(gp: int, dp: int, g_up: int, d_up: int, seq: Array) -> Array:
	var h := SimLeftHand.new()
	var gd: bool = false
	var dd: bool = false
	var res: Array = []
	for t in range(seq.size()):
		var tick: int = t + 1
		var gpress: bool = (tick == gp)
		var dpress: bool = (tick == dp)
		if gpress:
			gd = true
		if dpress:
			dd = true
		if g_up > 0 and tick == g_up:
			gd = false
		if d_up > 0 and tick == d_up:
			dd = false
		h.step(seq[t].x, seq[t].y, false, gd, dd, gpress, dpress, tick)
		if h.vanish:
			res.append([tick, h.vanish_vec])
	return res


func _vanish() -> void:
	var z: Vector2 = Vector2.ZERO
	var up: Vector2 = Vector2(0.0, 1.0)
	# LB at 10, LT at 13, a flick up inside the gather: it resolves at max(10 + 6, 13 + 2) = 16 with up.
	var seq: Array = _hold(z, 10) + _hold(up, 3) + _hold(z, 30)
	var r: Array = _vanish_run(10, 13, -1, -1, seq)
	ok(r.size() == 1 and r[0][0] == 16, "vanish: LB then LT 3 apart resolves at tick 16, got %s" % str(r))
	ok(r.size() == 1 and r[0][1].y > 0.5 and absf(r[0][1].x) < 0.1, "vanish: with the strongest direction of the gather (up)")
	var r2: Array = _vanish_run(13, 10, -1, -1, seq)
	ok(r2.size() == 1 and r2[0][0] == 16, "vanish: and the other order, the same")
	var r3: Array = _vanish_run(10, 10, -1, -1, seq)
	ok(r3.size() == 1 and r3[0][0] == 16, "vanish: the same tick resolves at first + 6 (16)")
	var r4: Array = _vanish_run(10, 16, -1, -1, _hold(z, 40))
	ok(r4.size() == 1 and r4[0][0] == 18, "vanish: 6 apart is still a chord; it resolves 2 after the second press (18)")
	ok(r4.size() == 1 and r4[0][1] == Vector2.ZERO, "vanish: a neutral stick sends a zero vector (the sim goes away)")
	var r5: Array = _vanish_run(10, 17, -1, -1, _hold(z, 40))
	ok(r5.is_empty(), "vanish: 7 apart is a guard and a dodge, not a chord")
	var r6: Array = _vanish_run(10, 12, -1, 14, _hold(z, 40))
	ok(r6.is_empty(), "vanish: LT let go before it resolved: no vanish")
	var r7: Array = _vanish_run(10, 12, 13, -1, _hold(z, 40))
	ok(r7.is_empty(), "vanish: LB let go before it resolved: no vanish")
	# Only the strongest push counts, and a stick that rests inside the gather is remembered.
	var seq8: Array = _hold(z, 10) + _hold(Vector2(1.0, 0.0), 2) + _hold(z, 30)
	var r8: Array = _vanish_run(10, 11, -1, -1, seq8)
	ok(r8.size() == 1 and r8[0][1].x > 0.5, "vanish: a flick that came and went inside the gather is still the direction")
	# A second vanish needs two fresh presses.
	var h := SimLeftHand.new()
	var n: int = 0
	for t in range(60):
		var tick: int = t + 1
		h.step(0.0, 0.0, false, true, true, tick == 5, tick == 5, tick)
		if h.vanish:
			n += 1
	ok(n == 1, "vanish: holding both after it fired does not fire it again")
