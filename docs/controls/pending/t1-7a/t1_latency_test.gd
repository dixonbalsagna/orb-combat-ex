extends SceneTree
## T1 (docs/controls/input-scheme.md): a tap's sim reaction is on the SAME TICK as the press. Real presses go through the real hub (the solo
## keyboard's J, K, L, Space, Shift; the Arena pad's west, north, east, LB) into SimCore with the host's own setup (v2 slots) and an idle
## dummy, at three distances, tapped and held. Dodge and guard are read from the act record (dodgeTick, guardSince).
## TIGHTENED (2026-10-22, after Encounter found the opening-cooldown skip never runs): for light, heavy and signature a reaction is a START
## made by the sim on the press tick: an exchange (S.dirS.ex), a rush or approach (the fighter's rush, or a `rush` event), or the fighter's
## state, velocity or position changing. A press_ack alone is an acknowledgement, NOT a start, and does not count. The acknowledgement has
## its own row: a press_ack event appears on the press tick. Performance measured the light at 5 ticks (docs/perf/input-latency-2026-10-22.md).
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
	var ack: int = -1
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
					var nm: String = String(e.kind) if String(e.type) == "cue" else String(e.type)
					if nm == "rush":
						reacted = true   # the rush's own event; a press_ack, a lunge or windup cue is only an announcement
					elif nm == "press_ack" and int(e.actor) == 0 and ack < 0:
						ack = t
		S.out.fx.clear()
		if reacted and first < 0:
			first = t
	SimCore.dispose(S)
	if what != "dodge" and what != "guard":
		ok(ack == 0, "ACK: %s %s (%s, %.0f units, %s) is acknowledged by a press_ack on the press tick (first ack: %s)" % [what, code, dev, dist, "held" if hold else "tapped", "never in %d ticks" % WATCH if ack < 0 else "tick %d" % ack])
	ok(first == 0, "T1: %s %s (%s, %.0f units, %s) STARTS on the press tick (an exchange, a rush, or a state, velocity or position change; first start: %s)" % [what, code, dev, dist, "held" if hold else "tapped", "never in %d ticks" % WATCH if first < 0 else "tick %d" % first])
