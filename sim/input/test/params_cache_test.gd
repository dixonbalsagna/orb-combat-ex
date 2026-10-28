extends SceneTree
## Headless checks for the kept params() of the press reader and the aim helper (sim/input/press_read.gd, sim/input/aim.gd): the copy is
## built once and handed back as is, it is read-only, it equals a fresh build from the data, and it NEVER outlives a change of
## the data: a SimInputData load (with other numbers), a section replaced, invalidate(). Passing `p` (or latchTicks, snapMax) in
## opts never builds one. From the repo root:
##   godot --headless --path . --script res://sim/input/test/params_cache_test.gd
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
	_kept()
	_equal()
	_reload()
	_swap()
	_in_place()
	_opts()
	_hash_free()
	SimInputData.load_and_apply()
	print("params_cache_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


## What a build from the data gives, written out of the readers (one lookup per number, as the build was before it was kept).
func _fresh_read() -> Dictionary:
	var p: Dictionary = SimPressRead.DEFAULTS.duplicate()
	for k in SimPressRead.DEFAULTS:
		p[k] = SimInputData.ti(["read", k], int(SimPressRead.DEFAULTS[k]))
	p["holdTicks"] = SimInputData.ti(["read", "holdTicks"], SimInputData.ti(["tapHold", "holdStart"], int(SimPressRead.DEFAULTS["holdTicks"])))
	return p


func _fresh_aim() -> Dictionary:
	var d: Dictionary = SimAim.DEFAULTS
	var p: Dictionary = d.duplicate()
	p["deadZone"] = SimInputData.tf(["aim", "deadZone"], float(d["deadZone"]))
	p["latchTicks"] = SimInputData.ti(["aim", "latchTicks"], int(d["latchTicks"]))
	p["snapMax"] = SimInputData.ti(["aim", "snapMax"], int(d["snapMax"]))
	p["nudgeStart"] = SimInputData.tf(["aim", "nudgeStart"], float(d["nudgeStart"]))
	p["nudgeTicks"] = SimInputData.ti(["aim", "nudgeTicks"], int(d["nudgeTicks"]))
	return p


func _kept() -> void:
	var a: Dictionary = SimPressRead.params()
	var b: Dictionary = SimPressRead.params()
	ok(is_same(a, b), "kept: the press reader's params() is the same dictionary on the second call")
	ok(a.is_read_only(), "kept: ... and read-only, so no caller can change what the next one reads")
	var c: Dictionary = a.duplicate()
	ok(not c.is_read_only(), "kept: a duplicate() of it is writable")
	c["mashGap"] = 99
	ok(SimPressRead.params()["mashGap"] == a["mashGap"] and a["mashGap"] != 99, "kept: changing the duplicate leaves the kept copy alone")
	var x: Dictionary = SimAim.params()
	var y: Dictionary = SimAim.params()
	ok(is_same(x, y) and x.is_read_only(), "kept: the aim helper's params() is the same read-only dictionary on the second call")
	var z: Dictionary = x.duplicate()
	z["deadZone"] = 0.9
	ok(not z.is_read_only() and absf(float(SimAim.params()["deadZone"]) - 0.35) < 1e-9, "kept: a duplicate of the aim copy is writable and apart")


func _equal() -> void:
	ok(SimPressRead.params() == _fresh_read(), "equal: the kept press numbers are what a fresh build from the data gives, key for key")
	ok(SimAim.params() == _fresh_aim(), "equal: the kept aim numbers are what a fresh build from the data gives, key for key")
	ok(SimPressRead.params().size() == SimPressRead.DEFAULTS.size(), "equal: no key more or fewer than the defaults")


## A load of other numbers: the kept copy must not survive it. The file is written to user:// and removed after.
func _reload() -> void:
	var before_r: Dictionary = SimPressRead.params()
	var before_a: Dictionary = SimAim.params()
	var rev: int = SimInputData.revision
	var t: Dictionary = (SimInputData.timing as Dictionary).duplicate(true)
	t["read"]["mashGap"] = 6
	t["read"]["beatHalf"] = 5
	t["aim"] = {"deadZone": 0.5, "latchTicks": 6, "snapMax": 2}
	var dir: String = "user://params_cache_test/"
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir + "timing.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(t))
	f.close()
	SimInputData.load_data(dir)
	ok(SimInputData.revision > rev, "reload: a load bumps the data's revision")
	ok(SimPressRead.params()["mashGap"] == 6 and SimPressRead.params()["beatHalf"] == 5, "reload: the press reader reads the NEW numbers after a load (mashGap 6, beatHalf 5)")
	ok(absf(float(SimAim.params()["deadZone"]) - 0.5) < 1e-9 and SimAim.params()["latchTicks"] == 6 and SimAim.params()["snapMax"] == 2, "reload: the aim helper reads the NEW numbers after a load")
	ok(not is_same(before_r, SimPressRead.params()) and not is_same(before_a, SimAim.params()), "reload: neither kept copy is the one from before the load")
	ok(before_r["mashGap"] == 10 and before_a["latchTicks"] == 12, "reload: the old copies were not altered on the way (still the shipped 10 and 12)")
	ok(SimPressRead.params() == _fresh_read() and SimAim.params() == _fresh_aim(), "reload: and they equal a fresh build from the new data")
	# The reload with the SAME numbers is also a rebuild, equal in content.
	SimInputData.load_and_apply()
	ok(SimPressRead.params()["mashGap"] == 10 and SimPressRead.params()["beatHalf"] == 4 and SimAim.params()["latchTicks"] == 12, "reload: loading the shipped data again brings the shipped numbers back")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir + "timing.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))


## A section replaced by another dictionary (what the tests of the readers do): noticed with no help.
func _swap() -> void:
	var saved = SimInputData.timing.get("read", null)
	SimInputData.timing["read"] = (saved as Dictionary).duplicate()
	SimInputData.timing["read"]["mashGap"] = 7
	ok(SimPressRead.params()["mashGap"] == 7, "swap: a replaced `read` section is read at once")
	SimInputData.timing["read"] = saved
	ok(SimPressRead.params()["mashGap"] == 10, "swap: and the shipped one when it is put back")
	# holdTicks is the `read` block's own when it has one; the game's hold (tapHold.holdStart) stands in when it has not.
	var no_hold: Dictionary = (SimInputData.timing["read"] as Dictionary).duplicate()
	no_hold.erase("holdTicks")
	SimInputData.timing["read"] = no_hold
	ok(SimPressRead.params()["holdTicks"] == 12, "swap: with no holdTicks of its own the reader takes the game's hold (12)")
	var th = SimInputData.timing.get("tapHold", null)
	SimInputData.timing["tapHold"] = (th as Dictionary).duplicate()
	SimInputData.timing["tapHold"]["holdStart"] = 15
	ok(SimPressRead.params()["holdTicks"] == 15, "swap: a replaced `tapHold` section moves holdTicks")
	SimInputData.timing["tapHold"] = th
	ok(SimPressRead.params()["holdTicks"] == 12, "swap: ... and back")
	SimInputData.timing["read"] = saved
	ok(SimPressRead.params()["holdTicks"] == 12 and SimPressRead.params() == _fresh_read(), "swap: the shipped `read` section back")
	var am = SimInputData.timing.get("aim", null)
	SimInputData.timing.erase("aim")
	ok(absf(float(SimAim.params()["deadZone"]) - 0.35) < 1e-9, "swap: with the `aim` section gone the defaults stand")
	SimInputData.timing["aim"] = {"deadZone": 0.45}
	ok(absf(float(SimAim.params()["deadZone"]) - 0.45) < 1e-9, "swap: a new `aim` section is read at once")
	if am != null:
		SimInputData.timing["aim"] = am
	ok(absf(float(SimAim.params()["deadZone"]) - 0.35) < 1e-9, "swap: and the shipped one when it is put back")


## Changing a section in place is the one change the readers cannot see for themselves: invalidate() is for it.
func _in_place() -> void:
	var before: Dictionary = SimPressRead.params()
	SimInputData.timing["read"]["mashGap"] = 8
	ok(SimPressRead.params()["mashGap"] == before["mashGap"], "in place: an edit inside the same section is NOT seen until invalidate() (the documented limit)")
	SimInputData.invalidate()
	ok(SimPressRead.params()["mashGap"] == 8, "in place: invalidate() makes it seen")
	ok(not is_same(before, SimPressRead.params()), "in place: ... as a new copy")
	SimInputData.timing["read"]["mashGap"] = 10
	SimInputData.invalidate()
	ok(SimPressRead.params()["mashGap"] == 10 and SimPressRead.params() == _fresh_read(), "in place: put back and invalidated, the shipped numbers")
	var r: int = SimInputData.revision
	SimInputData.invalidate()
	ok(SimInputData.revision == r + 1, "in place: invalidate() bumps the revision by one")


## `p` (or latchTicks, snapMax) in opts is used as given, and params() is not what answers.
func _opts() -> void:
	var q: Dictionary = SimPressRead.params().duplicate()
	q["beatHalf"] = 1
	ok(SimPressRead.grade_of(3, {"p": q}) == "off" and SimPressRead.grade_of(3) == "perfect", "opts: grade_of with its own p reads that p (beat half 1: 3 ticks is off; shipped 4: perfect)")
	q["beatHalf"] = 9
	ok(SimPressRead.grade_of(9, {"p": q}) == "perfect" and SimPressRead.grade_of(9) == "off", "opts: ... and a wider p widens it")
	ok(SimPressRead.grade_of(3, {"p": {"beatHalf": 1, "touchBeatHalf": 1, "assistFactor": 2, "blurBeatHalf": 1}}) == "off", "opts: a bare p dictionary with only the keys the grade reads is enough (no params() underneath)")
	var latch: Dictionary = {"sector": 2, "tick": 100}
	ok(SimAim.read(latch, 105, {"latchTicks": 3}) == SimAim.NONE and SimAim.read(latch, 105, {"latchTicks": 5}) == 2 and SimAim.read(latch, 105) == 2, "opts: the aim read takes latchTicks from opts, else the data's 12")
	ok(SimAim.snap(0, [2, 1], {"snapMax": 0}) == -1 and SimAim.snap(0, [2, 1], {"snapMax": 1}) == 1 and SimAim.snap(0, [2, 1]) == 1, "opts: the snap takes snapMax from opts, else the data's 1")


## A read through the kept copy gives the answers of one through a fresh build, over a spread of logs.
func _hash_free() -> void:
	var fresh: Dictionary = _fresh_read()
	var same: bool = true
	for gap in range(2, 24, 3):
		var lg: Array = []
		for k in range(6):
			SimPressRead.push(lg, SimPressRead.LIGHT if k % 3 != 2 else SimPressRead.HEAVY, 0, 100 + k * gap, (k % 5) - 2)
			SimPressRead.release(lg, SimPressRead.LIGHT if k % 3 != 2 else SimPressRead.HEAVY, 100 + k * gap + 3)
		var a: Dictionary = SimPressRead.classify(lg, 100 + 6 * gap + 4, {})
		var b: Dictionary = SimPressRead.classify(lg, 100 + 6 * gap + 4, {"p": fresh})
		if var_to_str(a) != var_to_str(b):
			same = false
	ok(same, "answers: classify through the kept copy equals classify through a fresh build, over eight spacings")
