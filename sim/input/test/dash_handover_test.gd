extends SceneTree
## Headless checks for LT's dash handover (docs/controls/dash-handover.md; timing.json switches.dashHandover, off; Game Design's ruling of 2026-11-08 (c)): LT's high speed is on from the press tick and only while LT is held,
## a tapped LT stays the slip. Before, a press gave a free 12-tick lunge (dodge.lungeTicks) whatever the release, so a tap was a 12-tick dash, which would be a leap once the dash is fast at any range. From the repo root:
##   godot --headless --path . --script res://sim/input/test/dash_handover_test.gd
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
	_sw(true)
	_on()
	_sim(true)
	_sw(false)
	_off()
	_sim(false)
	SimInputData.pin_switches_off()
	print("dash_handover_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(on: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["dashHandover"] = on
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _ctl(preset: Dictionary, action: String) -> String:
	for b in preset["bindings"]:
		if str(b["action"]) == action and b.get("layer", null) == null and b.get("gesture", null) == null and (b["controls"] as Array).size() == 1:
			return str(b["controls"][0])
	return ""


## Press `ctls` (a list of controls, together) after a rest, hold `hold` ticks, release, run to 40 ticks; returns {dash: [per tick bool], sprint: [...]}; a control with a leading "@" is pressed `late` ticks after the first.
func _run(layout: SimLayout, ctls: Array, hold: int, late: Array = [], late_at: int = 0) -> Dictionary:
	for t in range(8):
		layout.build()
		layout.consumed()
	for c in ctls:
		layout.press(c)
	var dash: Array = []
	var sprint: Array = []
	for t in range(40):
		if t == hold:
			for c in ctls:
				layout.release(c)
		if late.size() > 0 and t == late_at:
			for c in late:
				layout.press(c)
		var i: SimIntent = layout.build()
		dash.append(i.dash)
		sprint.append(i.sprint)
		layout.consumed()
	for c in ctls + late:
		layout.release(c)
	for t in range(30):
		layout.build()
		layout.consumed()
	return {"dash": dash, "sprint": sprint}


func _count(a: Array) -> int:
	var n: int = 0
	for v in a:
		if v:
			n += 1
	return n


func _on() -> void:
	var arena: Dictionary = SimInputData.preset("arena")
	var lt: String = _ctl(arena, "dodge")
	var lb: String = _ctl(arena, "guard")
	var rt: String = _ctl(arena, "power")
	ok(lt != "" and lb != "" and rt != "", "on: Arena has LT, LB and RT (%s %s %s)" % [lt, lb, rt])
	var tap: Dictionary = _run(SimLayout.new(arena), [lt], 2)
	ok(tap["dash"][0] and _count(tap["dash"]) <= 3 and not tap["dash"][5] and not tap["dash"][12], "on: a tap (LT let go after 2 ticks) is a dash on the press tick and only while it is down: %s" % str(tap["dash"].slice(0, 14)))
	var tap6: Dictionary = _run(SimLayout.new(arena), [lt], 6)
	ok(tap6["dash"][0] and _count(tap6["dash"]) <= 7 and not tap6["dash"][9], "on: a tap let go after 6 ticks is 6 or 7 dash ticks, none after: %s" % str(tap6["dash"].slice(0, 12)))
	var held: Dictionary = _run(SimLayout.new(arena), [lt], 30)
	var all_held: bool = true
	for k in range(30):
		all_held = all_held and held["dash"][k]
	ok(held["dash"][0] and all_held and not held["dash"][32], "on: held, the dash is on from the first tick to the release (30 ticks) and ends when it is let go: dash ticks %d" % _count(held["dash"]))
	var hs: int = SimInputData.ti(["tapHold", "holdStart"], 12)
	ok(not held["sprint"][hs - 3] and held["sprint"][hs + 2], "on: the sprint bit still starts at tapHold.holdStart (%d): %s" % [hs, str(held["sprint"].slice(hs - 3, hs + 3))])
	var back: Dictionary = _run(SimLayout.new(arena), [lt], 30, [lb], 5)
	ok(back["dash"][2] and not back["dash"][10], "on: LB pressed after LT (the vanish) ends the dash (a stance that is not LT's): %s" % str(back["dash"].slice(0, 12)))
	var chord: Dictionary = _run(SimLayout.new(arena), [lt, rt], 20)
	ok(_count(chord["dash"]) == 0, "on: LT and RT together within the chord window are the transform chord: no dash (%d)" % _count(chord["dash"]))
	var kb: Dictionary = SimInputData.preset("kb-solo")
	var kdash: String = _ctl(kb, "dodge")
	var ktap: Dictionary = _run(SimLayout.new(kb), [kdash], 2)
	ok(kdash != "" and ktap["dash"][0] and _count(ktap["dash"]) <= 3, "on: the keyboard's dodge key is the same (a tap is %d dash ticks)" % _count(ktap["dash"]))
	var over := SimLayout.new(arena)
	over.sprint_override = true
	for t in range(10):
		over.build()
		over.consumed()
	var oi: SimIntent = over.build()
	ok(oi.dash and oi.sprint, "on: a host-held sprint (the touch outer ring) is the dash")
	var edge := SimLayout.new(arena)
	for t in range(8):
		edge.build()
		edge.consumed()
	edge.press(lt)
	edge.release(lt)
	var e1: SimIntent = edge.build()
	ok(e1.dodge and e1.dash, "on: a press and release inside one tick still moves him on that tick (the dodge edge): dodge %s dash %s" % [str(e1.dodge), str(e1.dash)])
	edge.consumed()
	var e2: SimIntent = edge.build()
	ok(not e2.dash, "on: ... and not on the next")


func _off() -> void:
	var arena: Dictionary = SimInputData.preset("arena")
	var lt: String = _ctl(arena, "dodge")
	var tap: Dictionary = _run(SimLayout.new(arena), [lt], 2)
	ok(_count(tap["dash"]) >= SimInputData.ti(["dodge", "lungeTicks"], 12), "off (the control): a tap is a free lunge of lungeTicks dash ticks, whatever the release: %d" % _count(tap["dash"]))


## Through the sim (a standing rival 3,000 off, the energy model on, the stick held toward him): a tap carries him less than the same tap did, and a hold is the same either way.
func _sim(on: bool) -> void:
	var tap: float = _carry(4)
	var held: float = _carry(0)
	var none: float = _carry(-1)
	if on:
		ok(tap - none < 2.0, "on: a tap let go at tick 4 carries him less than 2 body heights beyond the stick alone (%.2f)" % (tap - none))
		ok(held - none > 8.0, "on: held, the dash carries him far (%.2f bh beyond the stick alone)" % (held - none))
	else:
		ok(tap - none > 3.5, "off (the control): the same tap carries him more than 3.5 body heights beyond the stick alone (%.2f)" % (tap - none))


func _carry(release_at: int) -> float:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	su["power"] = true
	su["travel"] = 1.5
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	b.x = SimWrap.wrap(a.x + 3000.0)
	b.y = a.y
	var quiet := SimIntent.new()
	for t in range(70):
		a.vx = 0.0
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	var x0: float = a.x
	hub.pad_stick(7, 1.0, 0.0)
	if release_at >= 0:
		hub.pad_trigger(7, "lt", 1.0)
	for t in range(1, 61):
		if release_at > 0 and t == release_at + 1:
			hub.pad_trigger(7, "lt", 0.0)
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	var d: float = absf(SimWrap.sdx(x0, a.x)) / 75.0
	SimCore.dispose(S)
	return d
