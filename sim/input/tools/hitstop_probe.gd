extends SceneTree
## Hit-stop by the blow, with the pad's inputs (data/fight/hitstop.json, off): the same scripted input on the same seed with hit-stop off and on, and how many ticks the
## sim held in 120 (SimCore.step returns false on a held tick), per blow and in total. Includes the right-hand strikes (the quick strike, the charge levels, the energy
## strike) so the table can be judged on the current stack.
##   godot --headless --path . --script res://sim/input/tools/hitstop_probe.gd
## The right-hand switches are set in memory (rightStick, quickRead on).

func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["quickRead"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	print("== HIT-STOP: ticks the sim held in 120 from the input (hits landed), off versus on; a standing opponent at 80 units ==")
	print("%-40s %-22s %-22s" % ["input", "off: held (blows)", "on: held (blows) [stops]"])
	var cases: Array = [
		["X tap (light)", [["b", "west", 0, true], ["b", "west", 3, false]]],
		["Y tap (heavy)", [["b", "north", 0, true], ["b", "north", 3, false]]],
		["B tap", [["b", "east", 0, true], ["b", "east", 3, false]]],
		["X mash (8 in 48)", _mash("west")],
		["Y mash (8 in 48)", _mash("north")],
		["B held 40 (launch)", [["b", "east", 0, true], ["b", "east", 40, false]]],
		["RB + X (shot)", [["b", "rb", -10, true], ["b", "west", 0, true], ["b", "west", 3, false]]],
		["RB + Y (blast)", [["b", "rb", -10, true], ["b", "north", 0, true], ["b", "north", 3, false]]],
		["RB + B (signature beam)", [["b", "rb", -10, true], ["b", "east", 0, true], ["b", "east", 3, false]]],
		["stick quick strike (toward)", [["rs", 1.0, 0, true], ["rs", 0.0, 3, true]]],
		["stick hold 40 (charge level 1)", [["rs", 1.0, 0, true], ["rs", 0.0, 40, true]]],
		["stick hold 70 (charge level 3)", [["rs", 1.0, 0, true], ["rs", 0.0, 70, true]]],
		["stick in energy (RB), quick", [["b", "rb", -10, true], ["rs", 1.0, 0, true], ["rs", 0.0, 3, true]]],
		["stick mash (8 flicks)", _stick_mash()],
	]
	for c in cases:
		var off: Array = _run(c[1], false)
		var on: Array = _run(c[1], true)
		print("%-40s %3d (%d)               %3d (%d)  %s" % [c[0], off[0], off[1], on[0], on[1], str(on[2])])
	quit(0)


func _mash(btn: String) -> Array:
	var out: Array = []
	for k in range(8):
		out.append(["b", btn, k * 6, true])
		out.append(["b", btn, k * 6 + 2, false])
	return out


func _stick_mash() -> Array:
	var out: Array = []
	for k in range(8):
		out.append(["rs", 1.0, k * 6, true])
		out.append(["rs", 0.0, k * 6 + 3, true])
	return out


## Returns [held ticks, blows that landed, the stops as lengths].
func _run(script: Array, hitstop: bool) -> Array:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	su["hitstop"] = hitstop
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	b.x = SimWrap.wrap(a.x + 80.0)
	b.y = a.y
	var quiet := SimIntent.new()
	for t in range(30):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	var held: int = 0
	var blows: int = 0
	var stops: Array = []
	var run_len: int = 0
	for t in range(-10, 120):
		for e in script:
			if int(e[2]) == t:
				if str(e[0]) == "b":
					hub.pad_button(7, str(e[1]), bool(e[3]))
				else:
					hub.pad_stick_right(7, float(e[1]), 0.0)
		var live: bool = SimCore.step(S, [hub.intent(0), quiet])
		if live:
			hub.consumed()
			if run_len > 0:
				stops.append(run_len)
				run_len = 0
		else:
			held += 1
			run_len += 1
		for e in S.out.fx:
			if String(e.type) == "damage" or String(e.type) == "blow":
				blows += 1 if String(e.type) == "blow" else 0
		S.out.fx.clear()
	SimCore.dispose(S)
	return [held, blows, stops]
