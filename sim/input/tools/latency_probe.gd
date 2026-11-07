extends SceneTree
## Responsiveness probe (docs/controls/responsiveness.md): where the ticks go between a thumb and the sim. Native, headless, no render, no clock of its own.
##   godot --headless --path . --script res://sim/input/tools/latency_probe.gd [-- --part=taps|stick|brace|vanish|law|all]
## A tick is 1/60 s. "Motion" is the first tick the physical control moves; every stage is counted from it.
##   taps    the real hub into SimCore with an idle dummy: press tick to the first sim reaction (T1's), the press_ack, the first event the animator
##           can start a pose from, and the first tick the body itself moves
##   stick   the strike stick through the reader, with synthetic thumbs (ramp length, aim error, rest-offset): motion to crossing, to the start edge,
##           to the throw; and how often the locked direction is the intended one, by the settle and the `on` threshold
##   brace   LB and a flick from rest, and the brace button; motion to the brace edge
##   vanish  LB and LT at gaps of 0 to 6 ticks: first press to the escape edge
##   law     a face press, then the stick: how many ticks the no-claw law adds to the start
## The synthetic thumbs are assumptions, not captures (no real stick traces exist yet: docs/controls/right-stick-capture.md); the probe says so in its output.

var _lcg: int = 12345
var part: String = "all"


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--part="):
			part = a.substr(7)
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	if part == "all" or part == "taps":
		_taps()
	for quick in [false, true]:
		_switch(true)
		var sw: Dictionary = SimInputData.timing.get("switches", {})
		sw["quickRead"] = quick
		SimInputData.timing["switches"] = sw
		SimInputData.clear_overrides()
		SimInputData.invalidate()
		print("
######## switches.quickRead = %s ########" % str(quick))
		if part == "all" or part == "stick":
			_stick(quick)
		if part == "all" or part == "brace":
			_brace()
		if part == "all" or part == "vanish":
			_vanish()
		if part == "all" or part == "law":
			_law()
	_switch(false)
	quit(0)


func _switch(on: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = on
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _set_strike(key: String, v) -> void:
	var st: Dictionary = SimInputData.timing.get("strike", {})
	st[key] = v
	SimInputData.timing["strike"] = st
	SimInputData.clear_overrides()
	SimInputData.invalidate()


## A small LCG, so the probe has no engine random numbers (the determinism lint covers sim/input).
func _rnd() -> float:
	_lcg = (_lcg * 1103515245 + 12345) & 0x7fffffff
	return float(_lcg) / 2147483648.0


# ---- taps -------------------------------------------------------------------------------------------------------------------------------------------

func _taps() -> void:
	print("== TAPS: press tick = 0. Columns: sim reaction (T1), press_ack, first event of the presser (what the animator starts a pose from), body moves")
	var rows: Array = [["kb", "KeyJ", "light"], ["kb", "KeyK", "heavy"], ["kb", "KeyL", "signature"], ["kb", "Space", "dodge"], ["kb", "Shift", "guard"], ["pad", "west", "light"], ["pad", "north", "heavy"], ["pad", "east", "signature"], ["pad", "lb", "guard"]]
	for r in rows:
		for dist in [80.0, 150.0, 250.0]:
			print("%-4s %-9s %-10s %4.0fu  %s" % [r[0], r[1], r[2], dist, _tap_case(r[0], r[1], r[2], dist)])


func _tap_case(dev: String, code: String, what: String, dist: float) -> String:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	if dev == "pad":
		hub.pad_button(7, "south", true)
		hub.pad_button(7, "south", false)
		hub.take_joins()
		hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	b.x = SimWrap.wrap(a.x + dist)
	b.y = a.y
	var quiet := SimIntent.new()
	for t in range(30):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	var x0: float = a.x
	var y0: float = a.y
	var react: int = -1
	var ack: int = -1
	var fxt: int = -1
	var fxk: String = ""
	var body: int = -1
	var hit: int = -1
	var hp0: float = float(b.hp)
	for t in range(70):
		if t == 0:
			if dev == "kb":
				hub.key(code, true)
			else:
				hub.pad_button(7, code, true)
		elif t == 3:
			if dev == "kb":
				hub.key(code, false)
			else:
				hub.pad_button(7, code, false)
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		var r: bool = false
		match what:
			"dodge":
				r = a.act.dodgeTick == S.tick
			"guard":
				r = a.act.guardSince == S.tick
			_:
				r = S.dirS.ex != null or a.rush != null or a.state != "free" or absf(a.vx) > 0.0 or absf(SimWrap.sdx(x0, a.x)) > 0.0
		for e in S.out.fx:
			var nm: String = String(e.kind) if String(e.type) == "cue" else String(e.type)
			if nm == "rush":
				r = true
			if nm == "press_ack" and ack < 0:
				ack = t
			if fxt < 0 and int(e.actor) == 0 and nm != "press_ack":
				fxt = t
				fxk = nm
		if absf(SimWrap.sdx(x0, a.x)) > 0.01 or absf(float(a.y) - y0) > 0.01:
			if body < 0:
				body = t
		if hit < 0 and float(b.hp) < hp0:
			hit = t
		S.out.fx.clear()
		if r and react < 0:
			react = t
	SimCore.dispose(S)
	return "sim %s  ack %s  event %s  body %s  hits him %s" % [_t(react), _t(ack), (_t(fxt) + " " + fxk) if fxt >= 0 else "-", _t(body), _t(hit)]


func _t(v: int) -> String:
	return "-" if v < 0 else str(v)


# ---- the stick ---------------------------------------------------------------------------------------------------------------------------------

## A thumb flick: from rest to `peak` magnitude in `ramp` ticks (linear), the angle starting `bias` degrees off the target and settling onto it over the ramp,
## held `hold` ticks, then back to rest in `back` ticks. Returns [x, y] for tick t counted from the motion start.
func _thumb(t: int, ramp: int, hold: int, back: int, ang: float, bias: float, peak: float) -> Vector2:
	var m: float
	var k: float = 1.0
	if t < ramp:
		m = peak * float(t + 1) / float(ramp)
		k = float(t + 1) / float(ramp)
	elif t < ramp + hold:
		m = peak
	elif t < ramp + hold + back:
		m = peak * (1.0 - float(t - ramp - hold + 1) / float(back))
	else:
		m = 0.0
	var a: float = deg_to_rad(ang + bias * (1.0 - k))
	return Vector2(cos(a), sin(a)) * m


func _pad_layout() -> SimLayout:
	return SimLayout.new(SimInputData.preset("arena"))


## One flick through the reader. Returns {cross, start, release, dir, ok}: ticks from the motion start (-1 if none).
func _flick(ramp: int, hold: int, back: int, ang: float, bias: float, peak: float, lead: int = 8) -> Dictionary:
	var l: SimLayout = _pad_layout()
	var out: Dictionary = {"cross": -1, "start": -1, "release": -1, "dir": 0, "pre": -1}
	var rd: SimStrikeRead = SimStrikeRead.new()   # a twin reader, only to see the crossing tick (the layout's own is private)
	var tick: int = 0
	for t in range(lead + ramp + hold + back + 14):
		var v: Vector2 = _thumb(t - lead, ramp, hold, back, ang, bias, peak) if t >= lead else Vector2.ZERO
		l.axis("pad:rs", v.x, v.y)
		var was_down: bool = rd.down
		rd.step(v.x, v.y, 0, t, t)
		if rd.down and not was_down and out["cross"] < 0:
			out["cross"] = t - lead
		var i: SimIntent = l.build()
		if out["pre"] < 0 and not l.strike_pre().is_empty():
			out["pre"] = t - lead
		if i.rsStart and out["start"] < 0:
			out["start"] = t - lead
			out["dir"] = i.rsDir
		if i.rsRelease and out["release"] < 0:
			out["release"] = t - lead
		l.consumed()
		tick += 1
	return out


func _stick(quick: bool = false) -> void:
	print("== STICK: ticks from the first tick the thumb moves (the reader's numbers: dead %.2f, on %.2f, off %.2f, settle %d, dwell %d)" % [
		SimInputData.tf(["strike", "deadzone"], 0.25), SimInputData.tf(["strike", "on"], 0.6), SimInputData.tf(["strike", "off"], 0.35), SimInputData.ti(["strike", "settle"], 2), SimInputData.ti(["strike", "dwell"], 12)])
	print("(synthetic thumbs: a ramp to full deflection of R ticks, held, then released in 3; the accuracy tables say their own aim error and rest-offset)")
	print("-- motion to crossing / start / throw, by ramp length R (no aim error, full push, held 3)")
	for ramp in [1, 2, 3, 4, 6, 8]:
		var f: Dictionary = _flick(ramp, 3, 3, 0.0, 0.0, 1.0)
		var h: Dictionary = _flick(ramp, 3, 3, 0.0, 0.0, 0.8)
		print("R %d: full push  pre %s  cross %s  start %s  throw %s   |   80%% push  pre %s  cross %s  start %s  throw %s" % [ramp, _t(f["pre"]), _t(f["cross"]), _t(f["start"]), _t(f["release"]), _t(h["pre"]), _t(h["cross"]), _t(h["start"]), _t(h["release"])])
	for harsh in ([] if quick else [[35.0, 50.0], [40.0, 90.0], [45.0, 120.0]]):
		print("-- direction accuracy (4000 flicks per cell; intended direction aimed within +-%.0f degrees, ramp 2 to 6 ticks, peak 0.75 to 1.0, a rest-offset of up to %.0f degrees fading over the ramp)" % [harsh[0], harsh[1]])
		for on in [0.5, 0.6, 0.7]:
			var line: String = "on %.2f:" % on
			for settle in [0, 1, 2, 3]:
				_set_strike("on", on)
				_set_strike("settle", settle)
				var acc: Dictionary = _accuracy(4000, harsh[0], harsh[1])
				line += "  settle %d: %.1f%% right, start +%.1f" % [settle, acc["right"], acc["start"]]
			print(line)
	_set_strike("on", 0.6)
	_set_strike("settle", 2)


func _accuracy(n: int, aim_err: float = 35.0, bias_max: float = 50.0) -> Dictionary:
	_lcg = 777
	var right: int = 0
	var started: int = 0
	var start_sum: float = 0.0
	for k in range(n):
		var d: int = int(_rnd() * 4.0) % 4
		var axis_deg: float = [90.0, 270.0, 180.0, 0.0][d]   # UP, DOWN, LEFT, RIGHT (SimStrikeRead's 1 to 4)
		var ang: float = axis_deg + (_rnd() * 2.0 - 1.0) * aim_err
		var ramp: int = 2 + int(_rnd() * 5.0)
		var peak: float = 0.75 + _rnd() * 0.25
		var bias: float = (_rnd() * 2.0 - 1.0) * bias_max
		var f: Dictionary = _flick(ramp, 4, 3, ang, bias, peak)
		if f["start"] >= 0:
			started += 1
			start_sum += float(f["start"])
			if int(f["dir"]) == d + 1:
				right += 1
	return {"right": 100.0 * float(right) / float(max(started, 1)), "start": start_sum / float(max(started, 1))}


# ---- the left hand -----------------------------------------------------------------------------------------------------------------------------

func _brace() -> void:
	print("== BRACE: ticks from the first tick the thumb moves (flick), or the button press, to the brace edge")
	for ramp in [1, 2, 3]:
		var l: SimLayout = _pad_layout()
		l.press("pad:lb")
		var got: int = -1
		for t in range(40):
			var v: Vector2 = _thumb(t - 15, ramp, 4, 3, 90.0, 0.0, 1.0) if t >= 15 else Vector2.ZERO
			l.axis("pad:ls", v.x, v.y)
			var i: SimIntent = l.build()
			if i.brace and got < 0:
				got = t - 15
			l.consumed()
		print("flick, LB held, stick at rest 15 ticks, ramp %d: brace at +%s" % [ramp, _t(got)])
	var l2: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	l2.axis("pad:ls", 0.0, 1.0)
	var got2: int = -1
	for t in range(20):
		if t == 5:
			l2.press("pad:l3")
		var i2: SimIntent = l2.build()
		if i2.brace and got2 < 0:
			got2 = t - 5
		l2.consumed()
	print("button (L3), the stick already held up: brace at +%s" % _t(got2))


func _vanish() -> void:
	print("== VANISH: LB first, LT after a gap of g ticks; ticks from the FIRST press to the escape edge (the dodge itself starts on the LT press)")
	for g in range(0, 7):
		var l: SimLayout = _pad_layout()
		var got: int = -1
		for t in range(30):
			if t == 5:
				l.press("pad:lb")
			if t == 5 + g:
				l.analog("pad:lt", 1.0)
			var i: SimIntent = l.build()
			if i.escape and got < 0:
				got = t - 5
			l.consumed()
		print("gap %d: escape at +%s (second press +%d)" % [g, _t(got), g])


# ---- the no-claw law ---------------------------------------------------------------------------------------------------------------------------

func _law() -> void:
	print("== LAW: a face press (X) at tick 0, the stick starts moving at +m (ramp 2, full push); ticks from the stick's motion to the start edge, and the extra the law added")
	var base: int = -1
	for m in [-12, -8, -6, -4, -2, 0, 2, 4, 6, 8, 12]:
		var l: SimLayout = _pad_layout()
		var got: int = -1
		for t in range(60):
			var tt: int = t - 20
			if tt == 0:
				l.press("pad:west")
			if tt == 3:
				l.release("pad:west")
			var v: Vector2 = _thumb(tt - m, 2, 4, 3, 0.0, 0.0, 1.0) if tt >= m else Vector2.ZERO
			l.axis("pad:rs", v.x, v.y)
			var i: SimIntent = l.build()
			if i.rsStart and got < 0:
				got = tt - m
			l.consumed()
		print("X at 0, stick moves at %+d: start at motion +%s" % [m, _t(got)])
