extends SceneTree
## Headless checks for the chord pick (docs/controls/chord-pick.md; timing.json switches.chordPick, off): two attack edges on one tick (B with X or Y, or Y with X) used to reach SimControl together, which takes one
## attack a tick (the light, then the heavy, then the signature), so a B pressed with an X was dropped with no word (14 of Orb's presses). With the switch the biggest press goes (signature over heavy over light)
## and each smaller one is let go of and told: the refusal code "chord" through the layout's take_dropped, and through the hub as one knock and one UI row. From the repo root:
##   godot --headless --path . --script res://sim/input/test/chord_pick_test.gd
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
	_pad()
	_other_ticks()
	_keyboard()
	_hub()
	_sw(false)
	_off()
	SimInputData.pin_switches_off()
	print("chord_pick_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(on: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["chordPick"] = on
	sw["rightStick"] = true
	sw["hapticRefused"] = on
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


## The control of an action's plain binding in a preset.
func _ctl(preset: Dictionary, action: String) -> String:
	for b in preset["bindings"]:
		if str(b["action"]) == action and b.get("layer", null) == null and b.get("gesture", null) == null and (b["controls"] as Array).size() == 1:
			return str(b["controls"][0])
	return ""


## Press the controls on one tick (after a rest), run 6 ticks; what the intent said on the press tick and after, and what the layout let go of.
func _run(layout: SimLayout, presses: Array) -> Dictionary:
	for t in range(6):
		layout.build()
		layout.consumed()
	for c in presses:
		layout.press(c)
	var seen := {"light": false, "heavy": false, "sig": false}
	var drops: Array = []
	for t in range(8):
		var i: SimIntent = layout.build()
		seen["light"] = seen["light"] or i.light
		seen["heavy"] = seen["heavy"] or i.heavy
		seen["sig"] = seen["sig"] or i.sig
		drops.append_array(layout.take_dropped())
		layout.consumed()
	for c in presses:
		layout.release(c)
	for t in range(40):
		layout.build()
		layout.consumed()
	layout.take_dropped()
	seen["drops"] = drops
	return seen


func _codes(r: Dictionary) -> Array:
	var out: Array = []
	for d in r["drops"]:
		if str(d["why"]) == "chord":
			out.append(str(d["k"]))
	out.sort()
	return out


func _pad() -> void:
	var p: Dictionary = SimInputData.preset("arena")
	var x: String = _ctl(p, "light")
	var y: String = _ctl(p, "heavy")
	var b: String = _ctl(p, "signature")
	ok(x != "" and y != "" and b != "" and x != y and y != b, "pad: Arena has the three attack controls (%s %s %s)" % [x, y, b])
	var r: Dictionary = _run(SimLayout.new(p), [b, x])
	ok(r["sig"] and not r["light"] and not r["heavy"] and _codes(r) == ["light"], "pad: B with X on one tick is the signature, X let go of and told chord: %s" % str(r))
	r = _run(SimLayout.new(p), [b, y])
	ok(r["sig"] and not r["heavy"] and not r["light"] and _codes(r) == ["heavy"], "pad: B with Y is the signature, Y told chord")
	r = _run(SimLayout.new(p), [y, x])
	ok(r["heavy"] and not r["light"] and not r["sig"] and _codes(r) == ["light"], "pad: Y with X is the heavy, X told chord")
	r = _run(SimLayout.new(p), [b, y, x])
	ok(r["sig"] and not r["heavy"] and not r["light"] and _codes(r) == ["heavy", "light"], "pad: all three is the signature, the other two told chord")
	r = _run(SimLayout.new(p), [x])
	ok(r["light"] and not r["heavy"] and not r["sig"] and r["drops"].is_empty(), "pad: X alone is the light and nothing is told")
	r = _run(SimLayout.new(p), [b])
	ok(r["sig"] and not r["light"] and r["drops"].is_empty(), "pad: B alone is the signature and nothing is told")
	# The pad swapped: the face buttons trade places with the D-pad, the rule is the same on whatever carries the actions.
	var sp: Dictionary = SimInputData.preset("arena-swapped")
	var sx: String = _ctl(sp, "light")
	var sb: String = _ctl(sp, "signature")
	r = _run(SimLayout.new(sp), [sb, sx])
	ok(r["sig"] and not r["light"] and _codes(r) == ["light"], "pad swapped: the same pick (%s with %s)" % [sb, sx])


## Edges one tick apart are two presses, as ever.
func _other_ticks() -> void:
	var p: Dictionary = SimInputData.preset("arena")
	var l := SimLayout.new(p)
	for t in range(6):
		l.build()
		l.consumed()
	l.press(_ctl(p, "light"))
	var a: SimIntent = l.build()
	l.consumed()
	l.press(_ctl(p, "signature"))
	var b: SimIntent = l.build()
	ok(a.light and not a.sig and b.sig and not b.light and l.take_dropped().is_empty(), "ticks: X then B on the next tick are two presses, nothing is let go of")


func _keyboard() -> void:
	var p: Dictionary = SimInputData.preset("kb-solo")
	var x: String = _ctl(p, "light")
	var b: String = _ctl(p, "signature")
	if x == "" or b == "":
		ok(false, "keyboard: the solo layout has a light and a signature key")
		return
	var r: Dictionary = _run(SimLayout.new(p), [b, x])
	ok(r["sig"] and not r["light"] and _codes(r) == ["light"], "keyboard: the same pick on the keys: %s" % str(r))


## Through the hub: one knock for the tick and one row for UI with the code chord.
func _hub() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	for t in range(6):
		hub.intent(0)
		hub.consumed()
	hub.pad_button(7, "west", true)
	hub.pad_button(7, "east", true)
	var knocks: int = 0
	var reasons: Array = []
	var refusals: Array = []
	var sig: bool = false
	var light: bool = false
	for t in range(6):
		var i: SimIntent = hub.intent(0)
		sig = sig or i.sig
		light = light or i.light
		for h in hub.take_haptics():
			if str(h.get("kind", "")) == "stick_refused":
				knocks += 1
				reasons.append(str(h.get("reason", "")))
		refusals.append_array(hub.take_refusals())
		hub.consumed()
	ok(sig and not light, "hub: the intent is the signature alone")
	ok(knocks == 1 and reasons == ["chord"], "hub: one knock, reason chord: %s" % str(reasons))
	ok(refusals.size() == 1 and str(refusals[0]["code"]) == "chord", "hub: one row for UI, code chord: %s" % str(refusals))
	ok(SimHaptics.REFUSALS.has("chord") and SimHaptics.refusal_word("chord") == "One at a time", "hub: the code has its word")


## Off: both edges reach the director as ever, nothing is told.
func _off() -> void:
	var p: Dictionary = SimInputData.preset("arena")
	var r: Dictionary = _run(SimLayout.new(p), [_ctl(p, "signature"), _ctl(p, "light")])
	ok(r["sig"] and r["light"] and r["drops"].is_empty(), "off: B with X is both edges, as it was, and nothing is told")
