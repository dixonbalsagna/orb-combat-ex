extends SceneTree
## Headless checks for the beam's aim (docs/controls/beam-aim-feel.md; timing.json switches.beamAim, off): the throw carries the aim the stick held at the rim, not the zero of a
## stick that has sprung home; the shown aim trails a still thumb's wobble by a small dead band and follows a real re-aim; a flick shorter than the settle takes its peak;
## nothing changes while the switch is off. The thumbs are the measured ones from Orb's first play (rim spread about 3 degrees, spring-back inside a tick). From the repo root:
##   godot --headless --path . --script res://sim/input/test/beam_aim_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0
var _seed: int = 12345


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	_sw(true, false)
	_off()
	_sw(true, true)
	_throw_carries_aim()
	_still_thumb()
	_re_aim()
	_flick()
	_bounce()
	_toggle_and_inert()
	_sw(true, false)
	_off_is_the_old_stream()
	print("beam_aim_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(right: bool, beam: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = right
	sw["beamAim"] = beam
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _rnd() -> float:
	_seed = (_seed * 1103515245 + 12345) & 0x7fffffff
	return float(_seed) / float(0x7fffffff)


## A roughly normal wobble with the given spread (the sum of four uniforms).
func _noise(sd: float) -> float:
	return ((_rnd() + _rnd() + _rnd() + _rnd()) - 2.0) * sd * 1.732


## The stick vector at an angle in degrees (counter-clockwise from right, y up) and a magnitude.
func _v(deg: float, m: float = 1.0) -> Vector2:
	var a: float = deg / 180.0 * PI
	return Vector2(cos(a), sin(a)) * m


## A hold: 2 ticks of rest, a one-tick arc in (80% of the way, 8 degrees short), `ticks` on the rim with a `sd`-degree wobble, then home in one tick.
func _hold(deg: float, ticks: int, sd: float = 3.0, home_ticks: int = 6) -> Array:
	var out: Array = [Vector2.ZERO, Vector2.ZERO, _v(deg - 8.0, 0.8)]
	for t in range(ticks):
		out.append(_v(deg + _noise(sd), 1.0 + _noise(0.01)))
	for t in range(home_ticks):
		out.append(Vector2.ZERO)
	return out


## Plays frames through one reader the way the layout does (one step a tick, edges cleared after each). Returns what the sim's intent would have carried.
func _play(frames: Array) -> Dictionary:
	var r: SimStrikeRead = SimStrikeRead.new()
	var aims: Array = []
	var res: Dictionary = {"aims": aims, "start": -1, "release": -1, "rel_aim": -1, "start_aim": -1, "held_aim": []}
	for t in range(frames.size()):
		var v: Vector2 = frames[t]
		r.step(v.x, v.y, 0, t, t)
		aims.append(r.aim)
		if r.start and res["start"] < 0:
			res["start"] = t
			res["start_aim"] = r.aim
		if r.release and res["release"] < 0:
			res["release"] = t
			res["rel_aim"] = r.aim
		r.clear_edges()
	return res


## The angular distance between two 32-way sectors, in sectors.
func _sdist(a: int, b: int) -> int:
	var d: int = absi(a - b) % 32
	return mini(d, 32 - d)


func _off() -> void:
	# the old behaviour, kept while the switch is off: the throw reads the stick at rest
	var res: Dictionary = _play(_hold(180.0, 30))
	ok(res["release"] >= 0, "off: the hold is thrown")
	ok(res["rel_aim"] == 0, "off: the throw's aim is the stick at rest (0, which reads as right) for a hold toward the left: %d" % res["rel_aim"])


func _throw_carries_aim() -> void:
	var cases: Array = [[180.0, 16], [0.0, 0], [90.0, 8], [270.0, 24], [45.0, 4], [135.0, 12], [225.0, 20], [315.0, 28]]
	for c in cases:
		var res: Dictionary = _play(_hold(c[0], 30))
		ok(res["release"] >= 0, "on: a hold at %d degrees is thrown" % int(c[0]))
		ok(_sdist(res["rel_aim"], c[1]) <= 1, "on: the throw carries the held direction %d degrees (sector %d, got %d)" % [int(c[0]), c[1], res["rel_aim"]])
	# the same thumbs in a spread of lengths and wobbles, 60 holds: the error of the throw's aim
	var worst: int = 0
	var over1: int = 0
	var n: int = 0
	for k in range(60):
		var deg: float = float((k * 37) % 360)
		var res: Dictionary = _play(_hold(deg, 8 + (k % 40), 3.0 + float(k % 4)))
		var want: int = int(floor(deg / 11.25 + 0.5)) % 32
		var e: int = _sdist(res["rel_aim"], want)
		worst = maxi(worst, e)
		if e > 1:
			over1 += 1
		n += 1
	ok(over1 <= 6, "on: of %d spread holds (wobble 3 to 6 degrees) at most 6 are thrown more than one sector off the held direction (%d, worst %d)" % [n, over1, worst])
	ok(worst <= 2, "on: and none is more than two sectors off (worst %d)" % worst)


func _still_thumb() -> void:
	# a thumb that means to hold still, 3 degrees of wobble: the shown aim changes far less than the raw sector would
	var shown: int = 0
	var raw: int = 0
	for k in range(30):
		var deg: float = float((k * 53) % 360) + 5.0
		var frames: Array = _hold(deg, 40, 3.0)
		var r: SimStrikeRead = SimStrikeRead.new()
		var last_s: int = -1
		var last_raw: int = -1
		for t in range(frames.size()):
			var v: Vector2 = frames[t]
			r.step(v.x, v.y, 0, t, t)
			if r.down and t >= 4 and t < 4 + 40:
				if last_s >= 0 and r.aim != last_s:
					shown += 1
				last_s = r.aim
				var rs: int = SimStrikeRead.sector(v.x, v.y)
				if last_raw >= 0 and rs != last_raw:
					raw += 1
				last_raw = rs
			r.clear_edges()
	print("still thumb: shown aim changes ", shown, ", raw sector changes ", raw)
	ok(shown * 10 <= raw * 7, "still thumb: the shown aim changes at most 70%% as often as the raw sector (%d against %d over 30 holds)" % [shown, raw])


func _re_aim() -> void:
	# a charge held at the right, then swept up by 80 degrees over four ticks and held there: the shown aim follows within a tick or two, the throw is the new place
	var frames: Array = [Vector2.ZERO, Vector2.ZERO, _v(-8.0, 0.8)]
	for t in range(20):
		frames.append(_v(0.0 + _noise(2.0)))
	for t in range(4):
		frames.append(_v(20.0 * float(t + 1)))
	for t in range(20):
		frames.append(_v(80.0 + _noise(2.0)))
	for t in range(6):
		frames.append(Vector2.ZERO)
	var r: SimStrikeRead = SimStrikeRead.new()
	var follow: int = -1
	var rel_aim: int = -1
	for t in range(frames.size()):
		var v: Vector2 = frames[t]
		r.step(v.x, v.y, 0, t, t)
		if t >= 3 + 20 + 4 and follow < 0 and r.down and _sdist(r.aim, 7) <= 1:
			follow = t
		if r.release:
			rel_aim = r.aim
		r.clear_edges()
	ok(follow >= 0 and follow <= 3 + 20 + 4 + 1, "re-aim: the shown aim is at the new place (sector 7) by the tick after the sweep ends (tick %d)" % follow)
	ok(_sdist(rel_aim, 7) <= 1, "re-aim: the throw is the new place, sector 7 (got %d)" % rel_aim)


func _flick() -> void:
	# a flick that is back at rest before the settle: it starts and throws together, with the peak of its arc
	var frames: Array = [Vector2.ZERO, Vector2.ZERO, _v(110.0, 0.9), _v(100.0, 1.0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var res: Dictionary = _play(frames)
	ok(res["release"] >= 0, "flick: a flick shorter than the settle is thrown")
	ok(_sdist(res["rel_aim"], 9) <= 1, "flick: and carries its direction, sector 9 (got %d)" % res["rel_aim"])


func _bounce() -> void:
	# the thumb lifts and the stick bounces past the centre (0.4 the other way): no aim is read after the throw
	var frames: Array = _hold(0.0, 20)
	frames.append(_v(180.0, 0.4))
	frames.append(_v(180.0, 0.3))
	frames.append(Vector2.ZERO)
	frames.append(Vector2.ZERO)
	var res: Dictionary = _play(frames)
	ok(_sdist(res["rel_aim"], 0) <= 1, "bounce: the throw carries the held direction, right (got %d)" % res["rel_aim"])
	var after: bool = true
	for t in range(res["release"] + 1, frames.size()):
		if res["aims"][t] != 0:
			after = false
	ok(after, "bounce: after the throw the aim is 0 (at rest), the bounce is not read")


func _toggle_and_inert() -> void:
	# a stick pushed on an inert layer (pure 4a: RT held) does nothing: no start, no release, the aim stays 0
	var r: SimStrikeRead = SimStrikeRead.new()
	var any: bool = false
	var frames: Array = _hold(0.0, 20)
	for t in range(frames.size()):
		var v: Vector2 = frames[t]
		r.step(v.x, v.y, 0, t, t, 0, false, true)
		if r.start or r.release:
			any = true
		r.clear_edges()
	ok(not any, "inert: nothing starts or releases on an inert layer, with the aim switch on")
	# a cancelled charge (the left hand): no throw, and the reader is ready for the next hold at a new direction
	var r2: SimStrikeRead = SimStrikeRead.new()
	var f2: Array = _hold(0.0, 20)
	var thrown: bool = false
	for t in range(f2.size()):
		var v2: Vector2 = f2[t]
		r2.step(v2.x, v2.y, 0, t, t)
		if t == 14:
			r2.cancel_now(t)
		if r2.release:
			thrown = true
		r2.clear_edges()
	ok(not thrown, "cancel: a cancelled charge is not thrown")
	var res: Dictionary = _play(_hold(180.0, 20))
	ok(_sdist(res["rel_aim"], 16) <= 1, "next hold: a new direction after the old one is its own (got %d)" % res["rel_aim"])


func _off_is_the_old_stream() -> void:
	# with the switch off the reader's aim is exactly the sector of the stick every step, the way it was
	var same: bool = true
	var frames: Array = _hold(70.0, 25)
	var r: SimStrikeRead = SimStrikeRead.new()
	for t in range(frames.size()):
		var v: Vector2 = frames[t]
		r.step(v.x, v.y, 0, t, t)
		var want: int = SimStrikeRead.sector(v.x, v.y) if (r.deflection(v.x, v.y) > 0.0 and (v.x != 0.0 or v.y != 0.0)) else 0
		if r.aim != want:
			same = false
		r.clear_edges()
	ok(same, "off: with the switch off the aim is the live sector of the stick on every step")
