extends SceneTree
## Headless checks for the aim helper (sim/input/aim.gd, docs/controls/agency-input.md 1b): the 8-sector snap, the dead zone,
## the keyboard's eight directions and a stick's every sector, the 12-tick latch, the director's snap, the toward, level and
## away pool, the sixteen sectors, the angle and bearing to a degree, the exit read from the sample ring, and determinism. Pure functions. From the repo root:
##   godot --headless --path . --script res://sim/input/test/aim_test.gd
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
	_data()
	_sectors()
	_keyboard()
	_boundaries()
	_latch()
	_snap()
	_pool()
	_sector16()
	_angles()
	_ring()
	_nudge()
	_determinism()
	print("aim_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _data() -> void:
	var p: Dictionary = SimAim.params()
	ok(absf(float(p["deadZone"]) - 0.35) < 1e-9 and p["latchTicks"] == 12 and p["snapMax"] == 1, "data: dead zone 0.35, latch 12 ticks, snap within 45 degrees")
	var saved = SimInputData.timing.get("aim", null)
	SimInputData.timing["aim"] = {"deadZone": 0.5, "latchTicks": 6, "snapMax": 2}
	var q: Dictionary = SimAim.params()
	ok(absf(float(q["deadZone"]) - 0.5) < 1e-9 and q["latchTicks"] == 6 and q["snapMax"] == 2, "data: a changed aim block is the helper's")
	if saved == null:
		SimInputData.timing.erase("aim")
	else:
		SimInputData.timing["aim"] = saved


func _sectors() -> void:
	# A full stick in each of the eight directions, y up.
	var dirs: Array = [[1.0, 0.0, 0], [0.7, 0.7, 1], [0.0, 1.0, 2], [-0.7, 0.7, 3], [-1.0, 0.0, 4], [-0.7, -0.7, 5], [0.0, -1.0, 6], [0.7, -0.7, 7]]
	for d in dirs:
		ok(SimAim.sector(d[0], d[1]) == d[2], "sector: (%.1f, %.1f) is sector %d" % [d[0], d[1], d[2]])
	# Bands of 45 degrees: 10 degrees off an axis is still the axis, 35 degrees is the diagonal.
	ok(SimAim.sector(1.0, 0.17) == SimAim.RIGHT, "sector: 10 degrees above right is right")
	ok(SimAim.sector(1.0, 0.70) == SimAim.UP_RIGHT, "sector: 35 degrees above right is up-right")
	ok(SimAim.sector(0.17, 1.0) == SimAim.UP, "sector: 10 degrees off up is up")
	ok(SimAim.sector(-1.0, -0.17) == SimAim.LEFT, "sector: 10 degrees below left is left")
	ok(SimAim.sector(-0.3, -1.0) == SimAim.DOWN, "sector: a stick mostly down is down")
	# The dead zone is a circle.
	ok(SimAim.sector(0.0, 0.0) == SimAim.NONE, "dead zone: centre is no aim")
	ok(SimAim.sector(0.34, 0.0) == SimAim.NONE and SimAim.sector(0.35, 0.0) == SimAim.NONE, "dead zone: up to 0.35 is no aim")
	ok(SimAim.sector(0.36, 0.0) == SimAim.RIGHT, "dead zone: past 0.35 aims")
	ok(SimAim.sector(0.24, 0.24) == SimAim.NONE and SimAim.sector(0.25, 0.25) == SimAim.UP_RIGHT, "dead zone: a circle, so a diagonal of 0.24 on each axis is inside and 0.25 (0.354 long) is out")
	ok(SimAim.sector(0.2, 0.0, 0.1) == SimAim.RIGHT, "dead zone: a caller's own dead zone applies")
	# Steps.
	ok(SimAim.step_x(0) == 1 and SimAim.step_y(0) == 0 and SimAim.step_x(3) == -1 and SimAim.step_y(3) == 1 and SimAim.step_y(6) == -1, "step: unit steps of the sectors, y up")
	ok(SimAim.step_x(SimAim.NONE) == 0 and SimAim.step_y(SimAim.NONE) == 0 and SimAim.step_x(9) == 0, "step: none is (0, 0)")


## A keyboard sends full deflection on each key held: eight directions and nothing else.
func _keyboard() -> void:
	var keys: Array = [[1, 0, 0], [1, 1, 1], [0, 1, 2], [-1, 1, 3], [-1, 0, 4], [-1, -1, 5], [0, -1, 6], [1, -1, 7]]
	for k in keys:
		ok(SimAim.sector(float(k[0]), float(k[1])) == k[2], "keyboard: keys (%d, %d) are sector %d" % [k[0], k[1], k[2]])
	var i := SimIntent.new()
	i.mx = 1.0
	i.my = 1.0
	ok(SimAim.of_intent(i) == SimAim.UP_RIGHT, "keyboard: of_intent reads an intent's stick")
	# The quantised stick values the layout sends (k / 127) read the same as the float stick.
	var q := SimIntent.new()
	q.mx = 127.0 / 127.0
	q.my = 30.0 / 127.0
	ok(SimAim.of_intent(SimIntent.canon(q)) == SimAim.RIGHT, "stick: a canonical intent (30 / 127 up on full right) is right")
	q.my = 60.0 / 127.0
	ok(SimAim.of_intent(SimIntent.canon(q)) == SimAim.UP_RIGHT, "stick: 60 / 127 up on full right is up-right")


## Exactly 22.5 degrees reads as the diagonal; just under is the axis. Mirror images agree.
func _boundaries() -> void:
	var t: float = SimAim.tan_22_5()
	ok(SimAim.sector(1.0, t) == SimAim.UP_RIGHT, "boundary: exactly 22.5 degrees is the diagonal")
	ok(SimAim.sector(1.0, t - 0.0001) == SimAim.RIGHT, "boundary: just under is the axis")
	ok(SimAim.sector(1.0, 1.0 / t - 0.0001) == SimAim.UP_RIGHT and SimAim.sector(1.0, 1.0 / t + 0.01) == SimAim.UP, "boundary: 67.5 degrees is where up-right becomes up")
	# Mirror symmetry in x and y over a sweep.
	var sym: bool = true
	for k in range(-20, 21):
		for m in range(-20, 21):
			var x: float = float(k) / 20.0
			var y: float = float(m) / 20.0
			var s: int = SimAim.sector(x, y)
			var sx: int = SimAim.sector(-x, y)
			if s != SimAim.NONE and (SimAim.step_y(s) != SimAim.step_y(sx) or SimAim.step_x(s) != -SimAim.step_x(sx)):
				sym = false
			if s != SimAim.NONE and SimAim.sector(x, -y) != SimAim.NONE and SimAim.step_x(s) != SimAim.step_x(SimAim.sector(x, -y)):
				sym = false
	ok(sym, "boundary: mirroring the stick in x or y mirrors the sector")


func _latch() -> void:
	var l: Dictionary = SimAim.new_latch()
	ok(SimAim.read(l, 100) == SimAim.NONE, "latch: nothing aimed")
	SimAim.update(l, 0.0, 0.0, 100)
	ok(SimAim.read(l, 100) == SimAim.NONE, "latch: a centred stick latches nothing")
	SimAim.update(l, 1.0, 0.0, 100)
	ok(SimAim.read(l, 100) == SimAim.RIGHT, "latch: an aim reads on its own tick")
	SimAim.update(l, 0.0, 0.0, 101)
	ok(SimAim.read(l, 105) == SimAim.RIGHT, "latch: letting go of the stick keeps the aim")
	ok(SimAim.read(l, 112) == SimAim.RIGHT, "latch: still there 12 ticks later")
	ok(SimAim.read(l, 113) == SimAim.NONE, "latch: gone after 13 ticks")
	SimAim.update(l, 0.1, 1.0, 110)
	ok(SimAim.read(l, 115) == SimAim.UP, "latch: a newer aim replaces the older one")
	SimAim.update(l, 0.2, 0.2, 111)
	ok(SimAim.read(l, 115) == SimAim.UP, "latch: a tremor inside the dead zone changes nothing")
	SimAim.update(l, -1.0, -1.0, 112)
	ok(SimAim.read(l, 112) == SimAim.DOWN_LEFT, "latch: the newest sample wins even a tick later")
	SimAim.clear(l)
	ok(SimAim.read(l, 112) == SimAim.NONE, "latch: clear forgets it")
	# A caller's own window.
	SimAim.update(l, 1.0, 0.0, 200)
	ok(SimAim.read(l, 205, {"latchTicks": 3}) == SimAim.NONE and SimAim.read(l, 203, {"latchTicks": 3}) == SimAim.RIGHT, "latch: a caller's latch window applies")
	# The state is two integers.
	ok(l.size() == 2 and l["sector"] is int and l["tick"] is int, "latch: the state is two integers")


func _snap() -> void:
	ok(SimAim.distance(0, 0) == 0 and SimAim.distance(0, 1) == 1 and SimAim.distance(0, 7) == 1 and SimAim.distance(0, 4) == 4 and SimAim.distance(2, 6) == 4 and SimAim.distance(1, 7) == 2, "snap: circular distances between sectors")
	ok(SimAim.distance(SimAim.NONE, 3) == 99, "snap: no aim is near nothing")
	# Candidates listed most dramatic first: building up-right, water right, crater down.
	var c: Array = [SimAim.UP_RIGHT, SimAim.RIGHT, SimAim.DOWN]
	ok(SimAim.snap(SimAim.UP_RIGHT, c) == 0, "snap: an exact aim takes its target")
	ok(SimAim.snap(SimAim.UP, c) == 0, "snap: up is 45 degrees from up-right, so the building")
	ok(SimAim.snap(SimAim.DOWN_RIGHT, c) == 1, "snap: down-right snaps to right (45 degrees), and the crater (down) is 45 too; the earlier wins")
	ok(SimAim.snap(SimAim.LEFT, c) == -1, "snap: left has nothing within 45 degrees")
	ok(SimAim.snap(SimAim.NONE, c) == -1, "snap: no aim means the director picks freely")
	ok(SimAim.snap(SimAim.UP_RIGHT, []) == -1, "snap: no candidates")
	ok(SimAim.snap(SimAim.LEFT, c, {"snapMax": 4}) == 2, "snap: a wider window takes the nearest (down, 2 sectors from left)")
	# The nearest beats an earlier one that is farther.
	ok(SimAim.snap(SimAim.RIGHT, [SimAim.UP_RIGHT, SimAim.RIGHT]) == 1, "snap: the nearer candidate beats an earlier, farther one")


func _pool() -> void:
	# Rival to the right: right is toward, left is away, vertical is level.
	ok(SimAim.pool(SimAim.RIGHT, 1) == "toward" and SimAim.pool(SimAim.LEFT, 1) == "away", "pool: rival on the right, right is toward and left is away")
	ok(SimAim.pool(SimAim.UP, 1) == "level" and SimAim.pool(SimAim.DOWN, 1) == "level", "pool: straight up or down is level")
	ok(SimAim.pool(SimAim.UP_RIGHT, 1) == "toward" and SimAim.pool(SimAim.DOWN_LEFT, 1) == "away", "pool: a diagonal counts by its horizontal part")
	# Rival to the left: mirrored (the wrap's shortest arc).
	ok(SimAim.pool(SimAim.RIGHT, -1) == "away" and SimAim.pool(SimAim.LEFT, -1) == "toward" and SimAim.pool(SimAim.UP_LEFT, -1) == "toward", "pool: rival on the left, everything mirrors")
	ok(SimAim.pool(SimAim.NONE, 1) == "level", "pool: no aim is level")


func _determinism() -> void:
	var a: Array = []
	var b: Array = []
	for k in range(-10, 11):
		for m in range(-10, 11):
			a.append(SimAim.sector(float(k) / 10.0, float(m) / 10.0))
			b.append(SimAim.sector(float(k) / 10.0, float(m) / 10.0))
	ok(a == b, "determinism: the same stick, the same sector")
	var l1: Dictionary = SimAim.new_latch()
	var l2: Dictionary = SimAim.new_latch()
	for t in range(40):
		var x: float = sin(float(t)) if t % 3 == 0 else 0.0
		SimAim.update(l1, x, 1.0 - float(t % 5) * 0.5, t)
		SimAim.update(l2, x, 1.0 - float(t % 5) * 0.5, t)
	ok(str(l1) == str(l2) and SimAim.read(l1, 41) == SimAim.read(l2, 41), "determinism: the same feed, the same latch")


func _unit(deg: float) -> Array:
	var r: float = deg * PI / 180.0
	return [cos(r), sin(r)]


func _sector16() -> void:
	# The centre of each of the sixteen sectors, and the same stick pushed 5 degrees either side stays in it.
	for k in range(16):
		var c: float = float(k) * 22.5
		for off in [-5.0, 0.0, 5.0]:
			var v: Array = _unit(c + off)
			ok(SimAim.sector16(v[0], v[1]) == k, "sector16: %.1f degrees is sector %d" % [c + off, k])
	# The edge: 11 degrees is still right, 12 degrees is the next one up.
	var e1: Array = _unit(11.0)
	var e2: Array = _unit(12.0)
	ok(SimAim.sector16(e1[0], e1[1]) == 0 and SimAim.sector16(e2[0], e2[1]) == 1, "sector16: the edge falls at 11.25 degrees")
	ok(SimAim.sector16(0.0, 0.0) == SimAim.NONE and SimAim.sector16(0.34, 0.0) == SimAim.NONE and SimAim.sector16(0.36, 0.0) == 0, "sector16: the same dead zone as the 8-sector")
	var agree: bool = true
	for k in range(8):
		var v: Array = _unit(float(k) * 45.0)
		agree = agree and SimAim.sector16(v[0], v[1]) == 2 * SimAim.sector(v[0], v[1])
	ok(agree, "sector16: an axis or a diagonal is twice the 8-sector number")
	ok(SimAim.sector16(1.0, 1.0) == 2 and SimAim.sector16(-1.0, 1.0) == 6 and SimAim.sector16(-1.0, -1.0) == 10 and SimAim.sector16(1.0, -1.0) == 14, "sector16: a keyboard diagonal is a diagonal sector")


func _angles() -> void:
	# The bearing, to a degree, over the whole circle (checked against the real trig, within one degree).
	var worst: int = 0
	for d in range(0, 360, 7):
		var v: Array = _unit(float(d))
		var b: int = SimAim.bearing_deg(v[0] * 0.9, v[1] * 0.9)
		var diff: int = absi(b - d)
		diff = mini(diff, 360 - diff)
		worst = maxi(worst, diff)
	ok(worst <= 1, "bearing: within one degree of the true angle all the way round (worst %d)" % worst)
	ok(SimAim.bearing_deg(1.0, 0.0) == 0 and SimAim.bearing_deg(0.0, 1.0) == 90 and SimAim.bearing_deg(-1.0, 0.0) == 180 and SimAim.bearing_deg(0.0, -1.0) == 270, "bearing: right 0, up 90, left 180, down 270")
	ok(SimAim.bearing_deg(0.0, 0.0) == 0, "bearing: no stick is 0")
	ok(SimAim.angle_off_away_deg(1.0, 0.0, 1) == 0 and SimAim.angle_off_away_deg(-1.0, 0.0, 1) == 180 and SimAim.angle_off_away_deg(0.0, 1.0, 1) == 90, "off away: straight away 0, back at him 180, square 90")
	ok(SimAim.angle_off_away_deg(-1.0, 0.0, -1) == 0 and SimAim.angle_off_away_deg(1.0, 0.0, -1) == 180, "off away: the sign flips which way is away")
	var w2: int = 0
	for d in range(0, 181, 5):
		var v: Array = _unit(float(d))
		w2 = maxi(w2, absi(SimAim.angle_off_away_deg(v[0], v[1], 1) - d))
		w2 = maxi(w2, absi(SimAim.angle_off_away_deg(-v[0], v[1], -1) - d))
	ok(w2 <= 1, "off away: within one degree every 5 degrees (worst %d)" % w2)
	var inside: Array = _unit(44.0)
	var outside: Array = _unit(47.0)
	ok(SimAim.within_away_cone(inside[0], inside[1], 1), "cone: 44 degrees off away is inside")
	ok(SimAim.within_away_cone(1.0, 1.0, 1), "cone: a keyboard diagonal (exactly 45) is inside, inclusive")
	ok(not SimAim.within_away_cone(outside[0], outside[1], 1), "cone: 47 degrees is outside")
	ok(not SimAim.within_away_cone(0.0, 0.0, 1) and not SimAim.within_away_cone(0.2, 0.0, 1), "cone: no stick (dead zone) is not away")
	ok(SimAim.within_away_cone(-1.0, 1.0, -1) and not SimAim.within_away_cone(-1.0, 0.0, 1), "cone: the sign flips the side")
	ok(absf(SimAim.exit_distance(4.0, 0) - 10.0) < 1e-9, "exit: straight away from 4 bh goes 6 bh further, 10")
	ok(absf(SimAim.exit_distance(4.0, 45) - 7.0) < 1e-9, "exit: 45 degrees off adds half, 7")
	ok(absf(SimAim.exit_distance(4.0, 90) - 4.0) < 1e-9 and absf(SimAim.exit_distance(4.0, 150) - 4.0) < 1e-9, "exit: square to his line or back toward him adds nothing")
	ok(absf(SimAim.exit_distance(9.0, 0) - 12.5) < 1e-9, "exit: capped at 12.5 bh")
	ok(absf(SimAim.exit_distance(14.0, 90) - 14.0) < 1e-9, "exit: never less than the start (a start past the cap keeps its own)")
	ok(absf(SimAim.exit_distance(2.0, 30) - (2.0 + 6.0 * (1.0 - 30.0 / 90.0))) < 1e-9, "exit: a one-degree grid, 30 degrees off from 2 bh")


func _feed(ring: Array, samples: Array) -> void:
	for s in samples:
		SimAim.push_sample(ring, s[0], s[1])


func _rep(v: Array, n: int) -> Array:
	var out: Array = []
	for k in range(n):
		out.append(v)
	return out


func _ring() -> void:
	var r: Array = SimAim.new_ring()
	ok(r.size() == 37 and SimAim.read_exit(r)["sector"] == SimAim.NONE, "ring: flat 37 integers and an empty one reads as none")
	# Held right for 5 of 12 ticks, rest at neutral: the exit is right, with the vector on the 1/127 grid.
	r = SimAim.new_ring()
	_feed(r, _rep([0.0, 0.0], 7) + _rep([0.8, 0.0], 5))
	var e: Dictionary = SimAim.read_exit(r)
	ok(e["sector"] == 0 and e["count"] == 5 and e["x"] == roundi(0.8 * 127.0) and e["y"] == 0, "ring: five ticks of right reads as right on the grid")
	# Under the dwell (3) it is not held.
	r = SimAim.new_ring()
	_feed(r, _rep([0.0, 0.0], 10) + _rep([0.0, 1.0], 2))
	ok(SimAim.read_exit(r)["sector"] == SimAim.NONE, "ring: two ticks is below the dwell: the zip goes back")
	# A spring-back: held up for 8 ticks, then the stick returns through the dead zone.
	r = SimAim.new_ring()
	_feed(r, _rep([0.0, 0.0], 2) + _rep([0.0, 0.9], 8) + [[0.0, 0.1], [0.0, 0.0]])
	var up: Dictionary = SimAim.read_exit(r)
	ok(up["sector"] == 4 and up["count"] == 8, "ring: a spring-back to neutral does not lose the held direction")
	# Most ticks wins: 6 left, 4 up.
	r = SimAim.new_ring()
	_feed(r, _rep([0.0, 1.0], 4) + _rep([-1.0, 0.0], 6) + _rep([0.0, 0.0], 2))
	ok(SimAim.read_exit(r)["sector"] == 8, "ring: the direction held longest wins")
	# A tie goes to the newer: 4 down then 4 right.
	r = SimAim.new_ring()
	_feed(r, _rep([0.0, -1.0], 4) + _rep([1.0, 0.0], 4) + _rep([0.0, 0.0], 4))
	ok(SimAim.read_exit(r)["sector"] == 0, "ring: a tie goes to the newer direction")
	# A keyboard diagonal is a held sector with a full vector.
	r = SimAim.new_ring()
	_feed(r, _rep([1.0, 1.0], 12))
	var dg: Dictionary = SimAim.read_exit(r)
	ok(dg["sector"] == 2 and dg["count"] == 12 and dg["x"] == 127 and dg["y"] == 127 and SimAim.bearing_deg(float(dg["x"]), float(dg["y"])) == 45, "ring: a keyboard diagonal reads as 45 degrees")
	# The vector is the mean of the sector's samples.
	r = SimAim.new_ring()
	_feed(r, [[0.9, 0.05], [0.9, 0.15], [0.9, 0.05], [0.9, 0.15]])
	var wb: Dictionary = SimAim.read_exit(r)
	ok(wb["sector"] == 0 and wb["count"] == 4 and absi(int(wb["y"]) - roundi(0.10 * 127.0)) <= 1 and wb["x"] == roundi(0.9 * 127.0), "ring: the vector is the mean of the held samples")
	# The ring forgets: samples older than the 12-tick window are gone.
	r = SimAim.new_ring()
	_feed(r, _rep([0.0, 1.0], 12) + _rep([0.0, 0.0], 12))
	ok(SimAim.read_exit(r)["sector"] == SimAim.NONE, "ring: after 12 ticks of nothing the old direction is gone")
	# The window and the dwell are data.
	r = SimAim.new_ring()
	_feed(r, _rep([0.0, 1.0], 8) + _rep([0.0, 0.0], 4))
	ok(SimAim.read_exit(r)["sector"] == 4 and SimAim.read_exit(r, {"exitWindow": 4})["sector"] == SimAim.NONE and SimAim.read_exit(r, {"dwellTicks": 9})["sector"] == SimAim.NONE, "ring: the window and the dwell are data")
	# Deterministic and integer.
	var r1: Array = SimAim.new_ring()
	var r2: Array = SimAim.new_ring()
	for t in range(30):
		var x: float = sin(float(t) * 0.7)
		var y: float = cos(float(t) * 0.4)
		SimAim.push_sample(r1, x, y)
		SimAim.push_sample(r2, x, y)
	ok(r1 == r2 and SimAim.read_exit(r1) == SimAim.read_exit(r2), "ring: the same feed, the same ring and the same read")
	var ints: bool = true
	for v in r1:
		ints = ints and typeof(v) == TYPE_INT
	ok(ints, "ring: every slot is an integer (a director can keep and hash it)")


func _nudge() -> void:
	var p: Dictionary = SimAim.params()
	ok(absf(float(p["nudgeStart"]) - 0.4) < 1e-9 and p["nudgeTicks"] == 12, "nudge: data 0.4 and 12 ticks")
	ok(SimAim.nudge_units(1.0) == 127 and SimAim.nudge_units(-1.0) == -127 and SimAim.nudge_units(0.0) == 0 and SimAim.nudge_units(64.0 / 127.0) == 64, "nudge: units are the stick's 1/127 steps")
	# A keyboard (0 to full in one tick) starts at the floor (51 of 127) and rises 7 a tick: full on the 12th tick.
	var seq: Array = []
	var prev: int = 0
	for k in range(14):
		prev = SimAim.nudge_ramp(prev, 127)
		seq.append(prev)
	ok(seq[0] == 51 and seq[1] == 58 and seq[10] == 121 and seq[11] == 127 and seq[13] == 127, "nudge: a full push starts at 51 and reaches 127 on the 12th tick (%s)" % str(seq))
	for k in range(1, seq.size()):
		ok(int(seq[k]) >= int(seq[k - 1]), "nudge: the ramp never falls while held (%d)" % k)
	# Let go is instant, and a new push starts again from the floor.
	ok(SimAim.nudge_ramp(127, 0) == 0 and SimAim.nudge_ramp(0, 127) == 51, "nudge: letting go is 0 at once, a new push starts at the floor")
	# The other way: a sign flip is a fresh push.
	ok(SimAim.nudge_ramp(100, -127) == -51 and SimAim.nudge_ramp(-51, -127) == -58 and SimAim.nudge_ramp(-120, -127) == -127, "nudge: the negative side is the same, a flip restarts at the floor")
	# An analogue stick moving gradually passes through unchanged: 3 units a tick up to 90.
	var ok_pass: bool = true
	prev = 0
	for k in range(31):
		var raw: int = mini(90, 3 * (k + 1))
		var out: int = SimAim.nudge_ramp(prev, raw)
		# the first ticks are under the floor, so raw; past it the rise (3) is under the step (7), so raw again
		ok_pass = ok_pass and out == raw
		prev = out
	ok(ok_pass, "nudge: a gradual analogue push is passed through unchanged")
	# An analogue flick to full is eased the same way as a keyboard.
	prev = SimAim.nudge_ramp(0, 127)
	prev = SimAim.nudge_ramp(prev, 127)
	ok(prev == 58, "nudge: a flick to full is eased as a keyboard is (device-agnostic)")
	# It follows the stick down at once.
	ok(SimAim.nudge_ramp(127, 60) == 60 and SimAim.nudge_ramp(60, 40) == 40, "nudge: it follows the stick down at once")
	# A small raw never exceeds itself: below the floor it is raw.
	ok(SimAim.nudge_ramp(0, 20) == 20 and SimAim.nudge_ramp(20, 20) == 20 and SimAim.nudge_ramp(20, 40) == 27, "nudge: a small push is itself, and a step-limited rise is 7")
	# The numbers come from data, and an override is honoured.
	var q: Dictionary = {"nudgeStart": 0.5, "nudgeTicks": 9}
	ok(SimAim.nudge_ramp(0, 127, q) == 64 and SimAim.nudge_ramp(64, 127, q) == 64 + 7, "nudge: the start and the ticks are data (0.5 and 9 give 64, then +7)")
	var saved = SimInputData.timing.get("aim", null)
	SimInputData.timing["aim"] = {"nudgeStart": 0.25, "nudgeTicks": 4}
	ok(SimAim.nudge_ramp(0, 127) == 32 and SimAim.nudge_ramp(32, 127) == 32 + 24, "nudge: a changed aim block in the data is the helper's (0.25 and 4 give 32, then +24)")
	if saved == null:
		SimInputData.timing.erase("aim")
	else:
		SimInputData.timing["aim"] = saved
	# Out of range raw is clamped, an integer in and out, and the same feed gives the same ramp.
	ok(SimAim.nudge_ramp(0, 500) == 51 and SimAim.nudge_ramp(0, -500) == -51, "nudge: a raw past 127 is clamped")
	var r1: Array = []
	var r2: Array = []
	var a1: int = 0
	var a2: int = 0
	for t in range(60):
		var raw2: int = int(round(sin(float(t) * 0.5) * 127.0))
		a1 = SimAim.nudge_ramp(a1, raw2)
		a2 = SimAim.nudge_ramp(a2, raw2)
		r1.append(a1)
		r2.append(a2)
		ok(typeof(a1) == TYPE_INT and absi(a1) <= 127 and absi(a1) <= absi(raw2), "nudge: tick %d is an integer within the stick" % t)
	ok(r1 == r2, "nudge: the same feed, the same ramp")
