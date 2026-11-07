extends SceneTree
## Synthetic thumbs through the strike reader (docs/controls/clips/thumbs.json, from right-stick-model.py: min-jerk strokes, angle and timing noise, a 50% recentring overshoot after flicks,
## drift up to 0.08, 1/16 quantisation): each trace is fed to a fresh Arena layout one sample a tick, with 30 ticks of rest after, and the strike requests it makes are counted.
## Reports, per kind and skill, the share of traces that made no request (missed), exactly one, and MORE than one (a phantom: a spring-back or drift read as a second flick), the direction
## agreement for the axis-aligned ones, and any request from an idle thumb.
##   godot --headless --path . --script res://sim/input/tools/thumb_phantom_probe.gd
## Run for the shipped read (settle 2), the quick read (settle 1) and settle 0. The black box's raw stick log of a real hand replaces these traces.


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://docs/controls/clips/thumbs.json"))
	if not (j is Dictionary):
		print("thumbs.json not found")
		quit(1)
		return
	for cfg in [["shipped (settle 2)", false, 2], ["quick (settle 1)", true, 1], ["quick, settle 0", true, 0]]:
		var sw: Dictionary = SimInputData.timing.get("switches", {})
		sw["rightStick"] = true
		sw["quickRead"] = cfg[1]
		SimInputData.timing["switches"] = sw
		var st: Dictionary = SimInputData.timing.get("strike", {})
		st["settleQuick"] = cfg[2]
		SimInputData.timing["strike"] = st
		SimInputData.clear_overrides()
		SimInputData.invalidate()
		print("######## %s ########" % cfg[0])
		_report(j.traces)
	quit(0)


func _report(traces: Array) -> void:
	var rows: Dictionary = {}
	for tr in traces:
		var key: String = "%s %s" % [tr.skill, tr.kind]
		if not rows.has(key):
			rows[key] = {"n": 0, "zero": 0, "one": 0, "many": 0, "dir_n": 0, "dir_ok": 0, "after_release": 0}
		var r: Dictionary = rows[key]
		r["n"] += 1
		var res: Dictionary = _feed(tr)
		var starts: int = int(res["starts"])
		if starts == 0:
			r["zero"] += 1
		elif starts == 1:
			r["one"] += 1
		else:
			r["many"] += 1
		if int(res["after_release"]) > 0:
			r["after_release"] += 1
		if tr.dir4 != null and starts >= 1:
			r["dir_n"] += 1
			if int(res["first_dir"]) == int(tr.dir4):
				r["dir_ok"] += 1
	var keys: Array = rows.keys()
	keys.sort()
	print("%-20s %4s  %9s %9s %9s  %12s  %s" % ["skill kind", "n", "no start", "1 start", ">1 start", "after return", "direction right (axis-aligned)"])
	for k in keys:
		var r: Dictionary = rows[k]
		var n: float = float(r["n"])
		print("%-20s %4d  %8.1f%% %8.1f%% %8.1f%%  %11.1f%%  %s" % [k, r["n"], 100.0 * r["zero"] / n, 100.0 * r["one"] / n, 100.0 * r["many"] / n, 100.0 * r["after_release"] / n, ("%.1f%% of %d" % [100.0 * r["dir_ok"] / maxf(1.0, r["dir_n"]), r["dir_n"]]) if r["dir_n"] > 0 else "-"])


## Feeds one trace; returns {starts, first_dir, after_release}: the requests it made, the first one's direction, and how many started after the stick had come back below the dead zone once.
func _feed(tr: Dictionary) -> Dictionary:
	var l: SimLayout = SimLayout.new(SimInputData.preset("arena"))
	var starts: int = 0
	var first_dir: int = 0
	var after_release: int = 0
	var returned: bool = false
	var seen_out: bool = false
	var samples: Array = tr.samples
	for t in range(samples.size() + 30):
		var x: float = 0.0
		var y: float = 0.0
		if t < samples.size():
			x = float(samples[t][0])
			y = float(samples[t][1])
		l.axis("pad:rs", x, y)
		var i: SimIntent = l.build()
		if i.rsStart:
			starts += 1
			if starts == 1:
				first_dir = i.rsDir
			elif returned:
				after_release += 1
		if sqrt(x * x + y * y) > 0.7:
			seen_out = true
		if seen_out and sqrt(x * x + y * y) < 0.25:
			returned = true
		l.consumed()
	return {"starts": starts, "first_dir": first_dir, "after_release": after_release}
