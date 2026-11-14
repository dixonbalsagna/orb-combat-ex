extends SceneTree
## What a press that comes and goes between two steps leaves in the intent (docs/controls/stall-keep.md): for each pad control, a press with the finger still down at the build, and a press
## and release both made before the build (a hitch: the page's events arrive together, the steps after). Prints the fields that are set in each, so a press that is lost shows as
## nothing in the second column.
##   godot --headless --path . --script res://sim/input/tools/stall_probe.gd

const FIELDS: Array = ["light", "heavy", "sig", "context", "guardPress", "guard", "dodge", "power", "powerPress", "powerTap", "special", "transform", "lightHeld", "heavyHeld", "sigHeld", "escape", "dash", "charge", "sprint", "contextHeld"]


func _init() -> void:
	SimInputData.load_and_apply()
	for preset in ["arena", "simple"]:
		print("== preset ", preset)
		for c in ["pad:south", "pad:west", "pad:north", "pad:east", "pad:lb", "pad:rb", "pad:lt", "pad:rt", "pad:l3", "pad:r3", "pad:back"]:
			var held: Array = _fields(preset, c, false)
			var tap: Array = _fields(preset, c, true)
			var flag: String = ""
			if tap.is_empty() and not held.is_empty():
				flag = "   <-- LOST in the stall"
			print("%-10s finger down: %-48s down and up first: %s%s" % [c, str(held), str(tap), flag])
	quit(0)


func _fields(preset: String, c: String, release_first: bool) -> Array:
	var l: SimLayout = SimLayout.new(SimInputData.preset(preset))
	for t in range(3):
		l.build()
		l.consumed()
	if c == "pad:lt" or c == "pad:rt":
		l.analog(c, 1.0)
		if release_first:
			l.analog(c, 0.0)
	else:
		l.press(c)
		if release_first:
			l.release(c)
	var i: SimIntent = l.build()
	var out: Array = []
	for f in FIELDS:
		var v = i.get(f)
		if (v is bool and v) or (v is int and v != 0):
			out.append(f)
	return out
