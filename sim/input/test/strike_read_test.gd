extends SceneTree
## Headless checks for the strike stick's reader (sim/input/strike_read.gd, docs/controls/right-hand-attacks.md section 1): the dead zone and
## quantising, the four directions and the 32 sectors, the settle, the quick strike and the charge ladder (live ticks), the direction lock, the
## beam rungs, the toggle style, the left hand's cancel, the law's floor, a freeze that holds an edge, and a push that must rest before the next. From the repo root:
##   godot --headless --path . --script res://sim/input/test/strike_read_test.gd
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
	_helpers()
	_quick()
	_charge()
	_lock()
	_beam_rungs()
	_toggle()
	_cancel()
	_floor()
	_freeze()
	_rest_between()
	_no_push()
	print("strike_read_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


## Drive a reader: one entry per tick, a Vector2 (the stick). Returns the ticks at which start, release and cancel were seen, and the last dir and level.
## `live_step` is false for a frozen tick (the sim took no step), as the hub does on a hit-stop tick: live does not advance and the edges are not cleared.
func _drive(r: SimStrikeRead, seq: Array, mask: int = 0, floor_tick: int = 0, frozen: Array = []) -> Dictionary:
	var out: Dictionary = {"start": -1, "release": -1, "cancel": -1, "dir": 0, "level": -1, "lvl_at_release": -1, "starts": 0, "releases": 0}
	var live: int = 0
	for t in range(seq.size()):
		var v: Vector2 = seq[t]
		r.step(v.x, v.y, mask, t + 1, live, floor_tick)
		if r.start:
			out["start"] = t + 1
			out["starts"] += 1
			out["dir"] = r.dir
		if r.release:
			out["release"] = t + 1
			out["releases"] += 1
			out["lvl_at_release"] = r.level
		if r.cancel:
			out["cancel"] = t + 1
		out["level"] = r.level
		if not frozen.has(t):
			r.clear_edges()
			live += 1
		else:
			pass
	return out


func _hold(v: Vector2, n: int) -> Array:
	var a: Array = []
	for i in range(n):
		a.append(v)
	return a


func _helpers() -> void:
	var r := SimStrikeRead.new()
	ok(r.deflection(0.1, 0.1) == 0.0, "helpers: inside the dead zone is nothing")
	ok(r.deflection(1.0, 0.0) == 1.0, "helpers: full is 1")
	ok(r.deflection(0.7, 0.0) >= 0.6, "helpers: 0.70 clears `on` after the rescale")
	ok(r.deflection(0.6, 0.0) < 0.6, "helpers: 0.60 raw does not")
	ok(SimStrikeRead.quadrant(0.0, 1.0) == SimStrikeRead.UP and SimStrikeRead.quadrant(0.0, -1.0) == SimStrikeRead.DOWN, "helpers: up and down")
	ok(SimStrikeRead.quadrant(-1.0, 0.0) == SimStrikeRead.LEFT and SimStrikeRead.quadrant(1.0, 0.0) == SimStrikeRead.RIGHT, "helpers: left and right")
	ok(SimStrikeRead.quadrant(1.0, 1.0) == SimStrikeRead.UP and SimStrikeRead.quadrant(-1.0, -1.0) == SimStrikeRead.DOWN, "helpers: a tie goes to the vertical")
	ok(SimStrikeRead.quadrant(0.0, 0.0) == SimStrikeRead.NONE, "helpers: no push is no direction")
	ok(SimStrikeRead.sector(1.0, 0.0) == 0 and SimStrikeRead.sector(0.0, 1.0) == 8 and SimStrikeRead.sector(-1.0, 0.0) == 16 and SimStrikeRead.sector(0.0, -1.0) == 24, "helpers: the sectors, right counter-clockwise")
	ok(SimStrikeRead.relative(SimStrikeRead.RIGHT, 1) == "toward" and SimStrikeRead.relative(SimStrikeRead.RIGHT, -1) == "away", "helpers: relative: right is toward when he faces right")
	ok(SimStrikeRead.relative(SimStrikeRead.LEFT, -1) == "toward" and SimStrikeRead.relative(SimStrikeRead.UP, -1) == "up", "helpers: relative: left, and up never turns")
	ok(r.level_at(11) == 0 and r.level_at(12) == 1 and r.level_at(30) == 2 and r.level_at(49) == 2 and r.level_at(50) == 3, "helpers: the strike rungs 12, 30, 50")
	ok(r.level_at(53, true) == 2 and r.level_at(54, true) == 3, "helpers: the beam rungs 12, 30, 54")
	ok(SimStrikeRead.is_beam_layer(SimStance.ENERGY) and SimStrikeRead.is_beam_layer(SimStance.CHARGING) and not SimStrikeRead.is_beam_layer(SimStance.MARTIAL) and not SimStrikeRead.is_beam_layer(SimStance.DEFENSIVE), "helpers: beam layers are energy and power")


## A flick: out for 3 ticks and back. The request begins 2 ticks after the crossing (the settle) and is thrown with it, at level 0, in the pushed direction.
func _quick() -> void:
	var r := SimStrikeRead.new()
	var seq: Array = []
	seq.append_array(_hold(Vector2.ZERO, 3))
	seq.append_array(_hold(Vector2(0.0, 1.0), 3))   # up, ticks 4 to 6 (1-based); the crossing is tick 4
	seq.append_array(_hold(Vector2.ZERO, 10))
	var o: Dictionary = _drive(r, seq)
	ok(o["start"] == 6, "quick: starts 2 ticks after the crossing (tick 6)")
	ok(o["release"] == 7 or o["release"] == 6, "quick: thrown as soon as it is back and started (got %d)" % o["release"])
	ok(o["starts"] == 1 and o["releases"] == 1, "quick: one start and one throw")
	ok(o["dir"] == SimStrikeRead.UP, "quick: the direction is the push (up)")
	ok(o["lvl_at_release"] == 0, "quick: level 0")
	# A one-tick graze still counts: any speed of push is a strike.
	var r2 := SimStrikeRead.new()
	var seq2: Array = _hold(Vector2.ZERO, 2)
	seq2.append(Vector2(1.0, 0.0))
	seq2.append_array(_hold(Vector2.ZERO, 8))
	var o2: Dictionary = _drive(r2, seq2)
	ok(o2["starts"] == 1 and o2["releases"] == 1 and o2["dir"] == SimStrikeRead.RIGHT, "quick: a one-tick flick is a strike to the right")
	# A push that never reaches `on` is nothing.
	var r3 := SimStrikeRead.new()
	var o3: Dictionary = _drive(r3, _hold(Vector2(0.5, 0.0), 20))
	ok(o3["starts"] == 0, "quick: half a push is not a strike")


## Held out, the quick strike's wind-up turns into the charge, and the ladder runs on live ticks since the start.
func _charge() -> void:
	var r := SimStrikeRead.new()
	var seq: Array = _hold(Vector2(1.0, 0.0), 70)
	seq.append_array(_hold(Vector2.ZERO, 6))
	var lv: Array = []
	var live: int = 0
	var start_live: int = -1
	for t in range(seq.size()):
		var v: Vector2 = seq[t]
		r.step(v.x, v.y, 0, t + 1, live, 0)
		if r.start:
			start_live = live
		if start_live >= 0 and r.is_active():
			lv.append([live - start_live, r.level])
		if r.release:
			ok(r.level == 3, "charge: released at level 3 after a long hold (got %d)" % r.level)
			ok(r.dir == SimStrikeRead.RIGHT, "charge: thrown to the right")
		r.clear_edges()
		live += 1
	var seen: Dictionary = {}
	for e in lv:
		seen[int(e[0])] = int(e[1])
	ok(seen.get(0, -1) == 0, "charge: level 0 at the start")
	ok(seen.get(11, -1) == 0 and seen.get(12, -1) == 1, "charge: level 1 at 12 live ticks")
	ok(seen.get(29, -1) == 1 and seen.get(30, -1) == 2, "charge: level 2 at 30")
	ok(seen.get(49, -1) == 2 and seen.get(50, -1) == 3, "charge: level 3 at 50 (the charged heavy's flash plus the settle)")
	# Released between rungs: the level reached.
	var r2 := SimStrikeRead.new()
	var o: Dictionary = _drive(r2, _hold(Vector2(0.0, -1.0), 40) + _hold(Vector2.ZERO, 6))
	ok(o["lvl_at_release"] == 2 and o["dir"] == SimStrikeRead.DOWN, "charge: released at tick ~40 is level 2, down")


## The direction is taken at the settle and locked: a thumb that wanders afterwards changes nothing, and the settle reads the stick, not the crossing.
func _lock() -> void:
	var r := SimStrikeRead.new()
	var seq: Array = _hold(Vector2.ZERO, 2)
	seq.append_array(_hold(Vector2(1.0, 0.0), 6))     # right: crossing tick 3, settle at tick 5
	seq.append_array(_hold(Vector2(0.0, 1.0), 20))    # then up
	seq.append_array(_hold(Vector2.ZERO, 5))
	var o: Dictionary = _drive(r, seq)
	ok(o["dir"] == SimStrikeRead.RIGHT, "lock: a stick that wanders after the settle still throws right")
	ok(o["starts"] == 1 and o["releases"] == 1, "lock: one deflection past `off` and back is one strike")
	# The crossing was on a diagonal that turned to right inside the settle: the direction is the stick at the settle.
	var r2 := SimStrikeRead.new()
	var seq2: Array = _hold(Vector2.ZERO, 2)
	seq2.append(Vector2(0.0, 1.0))                     # crossing tick 3, up
	seq2.append_array(_hold(Vector2(1.0, 0.0), 10))    # right by the settle (tick 5)
	seq2.append_array(_hold(Vector2.ZERO, 5))
	var o2: Dictionary = _drive(r2, seq2)
	ok(o2["dir"] == SimStrikeRead.RIGHT, "lock: the direction is taken at the settle, not at the crossing")
	# Two pushes with a rest between are two strikes.
	var r3 := SimStrikeRead.new()
	var seq3: Array = []
	for k in range(2):
		seq3.append_array(_hold(Vector2(-1.0, 0.0), 14))
		seq3.append_array(_hold(Vector2.ZERO, 6))
	var o3: Dictionary = _drive(r3, seq3)
	ok(o3["starts"] == 2 and o3["releases"] == 2, "lock: two pushes are two strikes")


func _beam_rungs() -> void:
	var r := SimStrikeRead.new()
	var o: Dictionary = _drive(r, _hold(Vector2(1.0, 0.0), 53) + _hold(Vector2.ZERO, 4), SimStance.ENERGY)
	ok(o["lvl_at_release"] == 2, "beam: 53 live ticks on the energy layer is level 2 (the beam's third rung is 54): got %d" % o["lvl_at_release"])
	var r2 := SimStrikeRead.new()
	var o2: Dictionary = _drive(r2, _hold(Vector2(1.0, 0.0), 58) + _hold(Vector2.ZERO, 4), SimStance.ENERGY)
	ok(o2["lvl_at_release"] == 3, "beam: 58 ticks is level 3")
	var r3 := SimStrikeRead.new()
	var o3: Dictionary = _drive(r3, _hold(Vector2(1.0, 0.0), 53) + _hold(Vector2.ZERO, 4), SimStance.MARTIAL)
	ok(o3["lvl_at_release"] == 3, "beam: the same hold on the martial layer is level 3 already (50)")
	ok(r.layer == SimStance.ENERGY, "beam: the layer is the mask at the crossing")


## Toggle style (accessibility): a push starts the charge, the stick may rest, and the NEXT push throws it.
func _toggle() -> void:
	var r := SimStrikeRead.new()
	r.toggle = true
	var seq: Array = _hold(Vector2.ZERO, 2)
	seq.append_array(_hold(Vector2(1.0, 0.0), 6))
	seq.append_array(_hold(Vector2.ZERO, 30))      # the thumb rests; nothing is thrown
	var o: Dictionary = _drive(r, seq)
	ok(o["starts"] == 1 and o["releases"] == 0, "toggle: a push starts and the rest throws nothing")
	ok(r.is_active() and r.level >= 1, "toggle: the charge goes on while the stick rests (level %d)" % r.level)
	var seq2: Array = _hold(Vector2(1.0, 0.0), 4)  # the next push
	seq2.append_array(_hold(Vector2.ZERO, 6))
	var live: int = 40
	var rel: bool = false
	for t in range(seq2.size()):
		r.step(seq2[t].x, seq2[t].y, 0, 100 + t, live, 0)
		rel = rel or r.release
		r.clear_edges()
		live += 1
	ok(rel, "toggle: the next push throws it")
	ok(not r.is_active(), "toggle: and it is over")


## The left hand's guard or dodge cancels a charge that has started: no throw, a cancel edge; a stick still out must rest before the next.
func _cancel() -> void:
	var r := SimStrikeRead.new()
	var live: int = 0
	var got_cancel: bool = false
	var rel: bool = false
	for t in range(40):
		r.step(1.0, 0.0, 0, t + 1, live, 0)
		if t == 25:
			ok(r.is_active(), "cancel: the charge is under way before the guard")
			got_cancel = r.cancel_now(t + 1)
		rel = rel or r.release
		r.clear_edges()
		live += 1
	ok(got_cancel and not rel, "cancel: a guard press ends the charge with no throw")
	ok(r.phase == SimStrikeRead.SPENT, "cancel: the stick is still out, so nothing starts again")
	for t in range(40, 46):
		r.step(0.0, 0.0, 0, t + 1, live, 0)
		live += 1
	ok(r.phase == SimStrikeRead.IDLE, "cancel: at rest it is ready again")
	# A cancel before the start (inside the settle) drops the request quietly.
	var r2 := SimStrikeRead.new()
	r2.step(0.0, 0.0, 0, 1, 0, 0)
	r2.step(1.0, 0.0, 0, 2, 1, 0)
	ok(r2.phase == SimStrikeRead.CROSSED, "cancel: crossed, not yet started")
	ok(not r2.cancel_now(3), "cancel: no cancel edge for a request that had not started")
	ok(r2.phase == SimStrikeRead.SPENT, "cancel: the request is dropped")


## The law's floor: a request may not start before it, whatever the settle says.
func _floor() -> void:
	var r := SimStrikeRead.new()
	var o: Dictionary = _drive(r, _hold(Vector2.ZERO, 2) + _hold(Vector2(0.0, 1.0), 20) + _hold(Vector2.ZERO, 4), 0, 20)
	ok(o["start"] == 20, "floor: the start waits for the law's floor (tick 20), got %d" % o["start"])
	var r2 := SimStrikeRead.new()
	var seq: Array = _hold(Vector2.ZERO, 2) + _hold(Vector2(0.0, 1.0), 2) + _hold(Vector2.ZERO, 30)
	var o2: Dictionary = _drive(r2, seq, 0, 12)
	ok(o2["start"] == 12 and o2["release"] == 12, "floor: a flick that is over before the floor starts and throws together at it")


## A freeze: the sim took no step, so live does not advance and the edges stay until a step takes them.
func _freeze() -> void:
	var r := SimStrikeRead.new()
	var seq: Array = _hold(Vector2.ZERO, 2) + _hold(Vector2(1.0, 0.0), 40) + _hold(Vector2.ZERO, 3)
	var frozen: Array = []
	for t in range(10, 30):
		frozen.append(t)
	var o: Dictionary = _drive(r, seq, 0, 0, frozen)
	ok(o["releases"] >= 1, "freeze: the throw is seen")
	# 20 frozen ticks did not count: 40 held - 20 frozen = ~20 live, level 1, not 2.
	ok(o["lvl_at_release"] == 1, "freeze: a freeze does not charge (level %d, expected 1)" % o["lvl_at_release"])
	# An edge made inside a freeze is kept until a step takes it.
	var r2 := SimStrikeRead.new()
	var live: int = 0
	for t in range(8):
		var v: Vector2 = Vector2(1.0, 0.0) if t >= 1 and t < 5 else Vector2.ZERO
		r2.step(v.x, v.y, 0, t + 1, live, 0)   # no clear_edges, no live: all frozen
	ok(r2.start and r2.release, "freeze: a flick inside a freeze keeps its start and its throw until a step takes them")
	ok(r2.pending_lag(8) > 0, "freeze: and the lag says how long they waited (%d)" % r2.pending_lag(8))
	r2.clear_edges()
	ok(not r2.start and not r2.release and r2.pending_lag(9) == 0, "freeze: a step spends them")


## A push that never rests between is one request: a stick held out after a throw does not start again.
func _rest_between() -> void:
	var r := SimStrikeRead.new()
	r.toggle = false
	var seq: Array = _hold(Vector2(1.0, 0.0), 8)
	var o: Dictionary = _drive(r, seq)
	ok(o["starts"] == 1, "rest: a held push is one request")
	# Wobble across `off` and `on`: the hysteresis keeps it one stick-out.
	var r2 := SimStrikeRead.new()
	var wob: Array = []
	for i in range(30):
		wob.append(Vector2(0.9 if i % 2 == 0 else 0.62, 0.0))   # 0.62 raw rescales under `on` but over `off`: still out
	var o2: Dictionary = _drive(r2, wob)
	ok(o2["starts"] == 1, "rest: a wobble between `on` and `off` is one stick-out (hysteresis)")


func _no_push() -> void:
	var r := SimStrikeRead.new()
	var o: Dictionary = _drive(r, _hold(Vector2.ZERO, 60))
	ok(o["starts"] == 0 and o["releases"] == 0 and r.phase == SimStrikeRead.IDLE and not r.has_edges(), "idle: a stick at rest does nothing")
	ok(r.aim == 0, "idle: no aim")
	# A strike KEY: pressed with no direction is a request with no direction (the director strikes toward him).
	var r2 := SimStrikeRead.new()
	var live: int = 0
	var dir: int = -1
	for t in range(12):
		r2.step(0.0, 0.0, 0, t + 1, live, 0, t >= 1 and t < 6)
		if r2.start:
			dir = r2.dir
		r2.clear_edges()
		live += 1
	ok(dir == SimStrikeRead.NONE, "key: a strike key with no direction held starts with dir 0 (toward him)")
