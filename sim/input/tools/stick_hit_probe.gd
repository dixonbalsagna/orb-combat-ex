extends SceneTree
## From the thumb to the hit, through the real sim (docs/controls/responsiveness.md): a stick flick on the Arena pad's right stick, the hub into SimCore with an
## idle dummy, against a face-button tap. Needs a tree where the director reads the second word (Encounter's stick hook, docs/director/pending/stick); on a tree
## without it the stick does nothing in the sim and the probe says so. From the repo root:
##   godot --headless --path . --script res://sim/input/tools/stick_hit_probe.gd
## Ticks are counted from the first tick the thumb or the finger moves. quickRead is switched in memory (timing.json need not carry the key).

const MOTION: int = 10


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	for mode in ["shipped", "quick (settle 1)", "quick, settle 0"]:
		var quick: bool = mode != "shipped"
		_switches(true, quick)
		var st: Dictionary = SimInputData.timing.get("strike", {})
		st["settleQuick"] = 0 if mode == "quick, settle 0" else 1
		SimInputData.timing["strike"] = st
		SimInputData.clear_overrides()
		SimInputData.invalidate()
		print("######## switches.rightStick on, %s ########" % mode)
		for dist in [80.0, 150.0, 250.0]:
			print("%4.0f units:" % dist)
			print("   face tap, X          " + _case("tap", dist, 3, 0.0))
			print("   stick flick, ramp 2  " + _case("flick", dist, 2, 0.0) + "   [toward him]")
			print("   stick flick, ramp 4  " + _case("flick", dist, 4, 0.0) + "   [toward him]")
			print("   stick flick up, r 3  " + _case("flick", dist, 3, 90.0))
			print("   stick HOLD (charge)  " + _case("hold", dist, 3, 0.0) + "   [toward, held 40 ticks then back]")
	_switches(true, true)
	print("######## the landing rule: a flick held h ticks past the ramp (quickRead on, 80 units, ramp 2): the blow lands at the later of the wind-up's end and the stick's return ########")
	for h in [0, 2, 4, 6, 8, 10, 11, 12, 14]:
		print("   held %2d:  %s" % [h, _case("flick", 80.0, 2, 0.0, h)])
	_switches(false, false)
	quit(0)


func _switches(right: bool, quick: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = right
	sw["quickRead"] = quick
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _t(v: int) -> String:
	return "  -" if v < 0 else "%3d" % v


func _case(kind: String, dist: float, ramp: int, ang: float, hold_ticks: int = 4) -> String:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
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
	var hp0: float = float(b.hp)
	var rs_start: int = -1
	var rs_rel: int = -1
	var react: int = -1
	var body: int = -1
	var hit: int = -1
	var pre: int = -1
	var held: int = 40 if kind == "hold" else hold_ticks
	for t in range(MOTION + 90):
		var k: int = t - MOTION
		if kind == "tap":
			if k == 0:
				hub.pad_button(7, "west", true)
			elif k == 3:
				hub.pad_button(7, "west", false)
		else:
			var m: float = 0.0
			if k >= 0 and k < ramp:
				m = float(k + 1) / float(ramp)
			elif k >= ramp and k < ramp + held:
				m = 1.0
			elif k >= ramp + held and k < ramp + held + 3:
				m = 1.0 - float(k - ramp - held + 1) / 3.0
			hub.pad_stick_right(7, cos(deg_to_rad(ang)) * m, sin(deg_to_rad(ang)) * m)
		var i: SimIntent = hub.intent(0)
		if pre < 0 and not hub.strike_pre(0).is_empty():
			pre = k
		if i.rsStart and rs_start < 0:
			rs_start = k
		if i.rsRelease and rs_rel < 0:
			rs_rel = k
		SimCore.step(S, [i, quiet])
		hub.consumed()
		if react < 0 and k >= 0 and (S.dirS.ex != null or a.rush != null or a.state != "free"):
			react = k
		if body < 0 and k >= 0 and (absf(SimWrap.sdx(x0, a.x)) > 0.01):
			body = k
		if hit < 0 and float(b.hp) < hp0:
			hit = k
		S.out.fx.clear()
	SimCore.dispose(S)
	return "pre %s  rsStart %s  rsRelease %s  sim reacts %s  body moves %s  HITS HIM %s" % [_t(pre), _t(rs_start), _t(rs_rel), _t(react), _t(body), _t(hit)]
