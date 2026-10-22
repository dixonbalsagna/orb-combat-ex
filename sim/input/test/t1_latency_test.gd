extends SceneTree
## T1 (docs/controls/input-scheme.md): a tap's sim reaction is on the SAME TICK as the press. Real presses go through the real hub (the solo
## keyboard's J, K, L, Space, Shift; the Arena pad's west, north, east, LB) into SimCore with the host's own setup (v2 slots) and an idle
## dummy, at three distances, tapped and held. Dodge and guard are read from the act record (dodgeTick, guardSince); light, heavy and
## signature must show a reaction the sim makes on the press tick: an exchange, a rush, a state or velocity change, or any event but the
## tick mark (press_ack, rush, windup, lunge ...). Performance measured the light at 5 ticks, every trial, on 2026-10-22
## (docs/perf/input-latency-2026-10-22.md); this test fails until the melee start is fixed (Encounter's) and must pass after.
## PARKED: not in sim/input/test while it fails on main. When Encounter's fix lands, move it to sim/input/test/ and add it to the gates.
##   godot --headless --path . --script res://sim/input/test/t1_latency_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0
const SETTLE: int = 30
const WATCH: int = 12


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	for dist in [80.0, 150.0, 250.0]:
		for hold in [true, false]:
			for k in [["kb", "KeyJ", "light"], ["kb", "KeyK", "heavy"], ["kb", "KeyL", "signature"], ["kb", "Space", "dodge"], ["kb", "Shift", "guard"]]:
				_case(k[0], k[1], k[2], dist, hold)
	for k in [["pad", "west", "light"], ["pad", "north", "heavy"], ["pad", "east", "signature"], ["pad", "lb", "guard"]]:
		_case(k[0], k[1], k[2], 150.0, true)
		_case(k[0], k[1], k[2], 150.0, false)
	print("t1_latency_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _press(hub: SimInputHub, dev: String, code: String, down: bool) -> void:
	if dev == "kb":
		hub.key(code, down)
	else:
		hub.pad_button(7, code, down)


## One press on the first tick, held or released after 3 ticks; the tick of the first reaction (0 = the press tick), or -1.
func _case(dev: String, code: String, what: String, dist: float, hold: bool) -> void:
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
	for t in range(SETTLE):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	var x0: float = a.x
	var first: int = -1
	for t in range(WATCH):
		if t == 0:
			_press(hub, dev, code, true)
		elif t == 3 and not hold:
			_press(hub, dev, code, false)
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		var reacted: bool = false
		match what:
			"dodge":
				reacted = a.act.dodgeTick == S.tick
			"guard":
				reacted = a.act.guardSince == S.tick
			_:
				reacted = S.dirS.ex != null or a.rush != null or a.state != "free" or absf(a.vx) > 0.0 or absf(SimWrap.sdx(x0, a.x)) > 0.0
				for e in S.out.fx:
					if String(e.type) != "tick":
						reacted = true
		S.out.fx.clear()
		if reacted and first < 0:
			first = t
	SimCore.dispose(S)
	ok(first == 0, "T1: %s %s (%s, %.0f units, %s) reacts on the press tick (first reaction: %s)" % [what, code, dev, dist, "held" if hold else "tapped", "never in %d ticks" % WATCH if first < 0 else "tick %d" % first])
