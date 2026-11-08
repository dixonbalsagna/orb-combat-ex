extends SceneTree
## Headless checks for the flight strike's B (docs/controls/flight-strike-b.md): with switches.signatureRtOnly the layout sends B with LB, RB or LT held as Y's heavy, so LT + B could not be pressed as B
## and the flight strike's biggest blow was out of reach on a pad. With switches.flightStrikeB (set with the flight strikes' own switch) LT + B stays the B press (sig, sigHeld); everything else is as it was.
## From the repo root:
##   godot --headless --path . --script res://sim/input/test/flight_strike_b_test.gd
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
	SimInputData.pin_switches_off()
	_matrix()
	_dodge_intact()
	SimInputData.pin_switches_off()
	print("flight_strike_b_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(rt_only: bool, fsb: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["signatureRtOnly"] = rt_only
	sw["flightStrikeB"] = fsb
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


## Hold `held` (a list of pad controls: "lb", "rb" button names, "lt" and "rt" analog), press B (pad:east) on tick 20 and let go on 30; what the intent said.
func _b(held: Array) -> Dictionary:
	var l: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	for h in held:
		if h == "lt" or h == "rt":
			l.analog("pad:" + h, 1.0)
		else:
			l.press("pad:" + h)
	var r: Dictionary = {"sig": false, "heavy": false, "sigHeld": false, "heavyHeld": false}
	for t in range(40):
		if t == 20:
			l.press("pad:east")
		if t == 30:
			l.release("pad:east")
		var i: SimIntent = l.build()
		if t >= 20:
			r["sig"] = r["sig"] or i.sig
			r["heavy"] = r["heavy"] or i.heavy
		if t >= 20 and t < 30:
			r["sigHeld"] = r["sigHeld"] or i.sigHeld
			r["heavyHeld"] = r["heavyHeld"] or i.heavyHeld
		l.consumed()
	return r


func _matrix() -> void:
	# [name, held controls, B is the signature when the rule is on, ... when flightStrikeB is also on]
	var rows: Array = [
		["none", [], true, true],
		["RT", ["rt"], true, true],
		["LB", ["lb"], false, false],
		["RB", ["rb"], false, false],
		["LT", ["lt"], false, true],
		["LT+LB", ["lt", "lb"], false, false],
	]
	# The rule off: B is the signature whatever is held, and flightStrikeB changes nothing.
	for fsb in [false, true]:
		_sw(false, fsb)
		for row in rows:
			var r: Dictionary = _b(row[1])
			ok(r["sig"] and not r["heavy"] and r["sigHeld"] and not r["heavyHeld"], "RT-only off, flightStrikeB %s: B with %s is the signature (sig %s, heavy %s)" % [str(fsb), row[0], str(r["sig"]), str(r["heavy"])])
	# The rule on, flightStrikeB off (the control): only LT + B is the problem.
	_sw(true, false)
	for row in rows:
		var r: Dictionary = _b(row[1])
		var want: bool = row[2]
		ok(r["sig"] == want and r["heavy"] == (not want) and r["sigHeld"] == want and r["heavyHeld"] == (not want), "RT-only on, flightStrikeB off: B with %s is %s (sig %s, heavy %s)" % [row[0], "the signature" if want else "the heavy", str(r["sig"]), str(r["heavy"])])
	# The rule on and flightStrikeB on: LT + B is B; LB + B and RB + B are the heavy as before.
	_sw(true, true)
	for row in rows:
		var r: Dictionary = _b(row[1])
		var want: bool = row[3]
		ok(r["sig"] == want and r["heavy"] == (not want) and r["sigHeld"] == want and r["heavyHeld"] == (not want), "RT-only on, flightStrikeB on: B with %s is %s (sig %s, heavy %s)" % [row[0], "the signature" if want else "the heavy", str(r["sig"]), str(r["heavy"])])
	# With the Driver on RB too: RB + B stays B for the Driver, LT + B for the flight strike, LB + B the heavy.
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["driverOnRb"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	for row in [["LB", ["lb"], false], ["RB", ["rb"], true], ["LT", ["lt"], true]]:
		var r: Dictionary = _b(row[1])
		ok(r["sig"] == row[2] and r["heavy"] == (not row[2]), "driverOnRb and flightStrikeB both on: B with %s is %s (sig %s, heavy %s)" % [row[0], "B" if row[2] else "the heavy", str(r["sig"]), str(r["heavy"])])


## The dodge itself is not touched: LT held reports the stance mask's MANOEUVRE bit with the switch on, as it does with it off.
func _dodge_intact() -> void:
	for fsb in [false, true]:
		_sw(true, fsb)
		var l: SimLayout = SimLayout.new(SimInputData.preset("arena"))
		l.analog("pad:lt", 1.0)
		var m: int = 0
		for t in range(20):
			var i: SimIntent = l.build()
			m = i.stanceMask
			l.consumed()
		ok((m & SimStance.MANOEUVRE) != 0, "flightStrikeB %s: LT held still reports the manoeuvre stance bit (mask %d)" % [str(fsb), m])
