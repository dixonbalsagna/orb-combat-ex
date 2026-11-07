extends SceneTree
## Headless checks for the charge stages' rumble and the throw's thump (docs/controls/beam-aim-feel.md section 5; timing.json switches.hapticLadder, off): a stage of N
## is the tick, the knock rising, then the thud; the throw of a charged strike answers with one low thump scaled by the charge, a flick with none; everything is soft and
## low (no pulse louder than the top one, the thump on the low motor); and none of it plays while the switch is off. From the repo root:
##   godot --headless --path . --script res://sim/input/test/stage_haptics_test.gd
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
	SimInputData.pin_switches_off()   # the data ships the page's switches on; this check is of the behaviour with them off
	SimInputData.clear_overrides()
	_sw(true, true)
	_stages()
	_thump()
	_soft()
	_hub()
	_sw(true, false)
	_off()
	print("stage_haptics_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(right: bool, ladder: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = right
	sw["hapticLadder"] = ladder
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _kinds(of: int) -> Array:
	var out: Array = []
	for n in range(1, of + 1):
		var r: Array = SimHaptics.stage_requests(0, n, of)
		out.append(r[0]["kind"] if r.size() == 1 else "none")
	return out


func _close(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for k in range(a.size()):
		if absf(float(a[k]) - float(b[k])) > 0.011:
			return false
	return true


func _scales(of: int) -> Array:
	var out: Array = []
	for n in range(1, of + 1):
		var r: Array = SimHaptics.stage_requests(0, n, of)
		out.append(snappedf(float(r[0]["scale"]), 0.01) if r.size() == 1 else -1.0)
	return out


func _stages() -> void:
	ok(_kinds(2) == ["ladder_1", "ladder_3"], "stages: a two-stage charge is the tick, then the thud: %s" % str(_kinds(2)))
	ok(_kinds(3) == ["ladder_1", "ladder_2", "ladder_3"], "stages: three is the old ladder: %s" % str(_kinds(3)))
	ok(_kinds(6) == ["ladder_1", "ladder_2", "ladder_2", "ladder_2", "ladder_2", "ladder_3"], "stages: six is the tick, four knocks, the thud: %s" % str(_kinds(6)))
	ok(_close(_scales(6), [1.0, 0.7, 0.8, 0.9, 1.0, 1.0]), "stages: the knocks climb from 0.7 to 1.0 of their strength, the tick and the thud are as written: %s" % str(_scales(6)))
	ok(_close(_scales(4), [1.0, 0.7, 1.0, 1.0]), "stages: four has a soft knock and a full one: %s" % str(_scales(4)))
	ok(SimHaptics.stage_requests(0, 0, 3).is_empty(), "stages: stage 0 (a charge starting) is silent")
	ok(SimHaptics.stage_requests(0, 4, 3).is_empty(), "stages: a stage past the last is silent")
	ok(SimHaptics.stage_requests(2, 1, 3).is_empty() and SimHaptics.stage_requests(-1, 1, 3).is_empty(), "stages: only slots 0 and 1 feel a stage")
	ok(int(SimHaptics.stage_requests(1, 2, 3)[0]["slot"]) == 1, "stages: the pulse is for the charger's slot")


func _thump() -> void:
	ok(SimHaptics.release_requests(0, 0).is_empty(), "thump: a flick (level 0) throws no thump")
	var sc: Array = []
	for lv in [1, 2, 3]:
		var r: Array = SimHaptics.release_requests(1, lv)
		ok(r.size() == 1 and r[0]["kind"] == "release_thump" and int(r[0]["slot"]) == 1, "thump: level %d is one release_thump for the thrower" % lv)
		sc.append(snappedf(float(r[0]["scale"]), 0.01))
	ok(_close(sc, [0.6, 0.8, 1.0]), "thump: scaled by the charge reached, 0.6 / 0.8 / 1.0: %s" % str(sc))
	ok(SimHaptics.release_requests(0, 2, 6)[0]["scale"] < SimHaptics.release_requests(0, 5, 6)[0]["scale"], "thump: with six stages a later stage thumps harder")
	ok(SimHaptics.release_requests(3, 2).is_empty(), "thump: only slots 0 and 1")


func _soft() -> void:
	var th: Array = SimHaptics.steps("release_thump", "pad", 1.0)
	ok(th.size() == 2, "soft: the thump is a push and a roll-off")
	var chunky: bool = true
	var quiet: bool = true
	for s in th:
		if float(s["strong"]) < float(s["weak"]) * 3.0 and float(s["weak"]) > 0.0:
			chunky = false
		if float(s["strong"]) > 0.7 or float(s["weak"]) > 0.15:
			quiet = false
	ok(chunky, "soft: the thump is the low motor (at least three times the high one)")
	ok(quiet, "soft: and no louder than 0.7 low, 0.15 high")
	var top: float = 0.0
	for k in ["ladder_1", "ladder_2", "ladder_3"]:
		for s in SimHaptics.steps(k, "pad", 1.0):
			top = maxf(top, float(s["strong"]))
	ok(float(SimHaptics.steps("release_thump", "pad", 1.0)[0]["strong"]) <= top, "soft: the thump is no heavier than the thud (%.2f against %.2f)" % [SimHaptics.steps("release_thump", "pad", 1.0)[0]["strong"], top])
	var knock_max: float = 0.0
	for n in range(2, 6):
		var r: Array = SimHaptics.stage_requests(0, n, 6)
		for s in SimHaptics.steps(r[0]["kind"], "pad", float(r[0]["scale"])):
			knock_max = maxf(knock_max, float(s["strong"]))
	ok(knock_max < top, "soft: no knock of a six-stage charge is as heavy as the thud (%.2f against %.2f)" % [knock_max, top])
	var plan: Dictionary = SimHaptics.plan("release_thump", {"kind": "pad", "id": 3}, true, -10000, 1000, 0.6)
	ok(plan.get("via", "") == "pad" and plan["steps"].size() == 2, "soft: a pad plays it")
	ok(SimHaptics.plan("release_thump", {"kind": "pad", "id": 3}, true, 950, 1000, 1.0).is_empty(), "soft: inside the slot-wide gap it is dropped")


func _hub_pad() -> SimInputHub:
	var hub: SimInputHub = SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	return hub


func _hub() -> void:
	# a held strike to level 3 and a throw: the three rungs, then the thump on the throw tick
	var hub: SimInputHub = _hub_pad()
	var got: Array = []
	for t in range(140):
		hub.pad_stick_right(7, 1.0 if (t >= 10 and t < 90) else 0.0, 0.0)
		hub.intent(0)
		for r in hub.take_haptics():
			got.append([t, String(r["kind"]), snappedf(float(r["scale"]), 0.01)])
		hub.consumed()
	var kinds: Array = []
	for g in got:
		kinds.append(g[1])
	ok(kinds == ["ladder_1", "ladder_2", "ladder_3", "release_thump"], "hub: a charge to the top answers each rung, then the throw: %s" % str(kinds))
	if got.size() == 4:
		ok(got[3][0] == 90 and absf(float(got[3][2]) - 1.0) < 0.011, "hub: the thump is on the tick the stick falls (90) at full scale: %s" % str(got[3]))
	# a charge thrown at level 1
	var h1: SimInputHub = _hub_pad()
	var k1: Array = []
	var s1: Array = []
	for t in range(100):
		h1.pad_stick_right(7, 1.0 if (t >= 10 and t < 30) else 0.0, 0.0)
		h1.intent(0)
		for r in h1.take_haptics():
			k1.append(String(r["kind"]))
			s1.append(snappedf(float(r["scale"]), 0.01))
		h1.consumed()
	ok(k1 == ["ladder_1", "release_thump"] and absf(float(s1[1]) - 0.6) < 0.011, "hub: a charge let go at the first rung is the tick and a 0.6 thump: %s %s" % [str(k1), str(s1)])
	# a quick flick: no rung, no thump
	var h2: SimInputHub = _hub_pad()
	var q: int = 0
	for t in range(60):
		h2.pad_stick_right(7, 1.0 if (t >= 10 and t < 14) else 0.0, 0.0)
		h2.intent(0)
		q += h2.take_haptics().size()
		h2.consumed()
	ok(q == 0, "hub: a quick flick throws no thump")
	# a cancelled charge (the guard): no throw, no thump
	var h3: SimInputHub = _hub_pad()
	var after: int = 0
	for t in range(100):
		h3.pad_stick_right(7, 1.0 if t >= 10 else 0.0, 0.0)
		if t == 25:
			h3.pad_button(7, "lb", true)
		h3.intent(0)
		for r in h3.take_haptics():
			if t >= 26:
				after += 1
		h3.consumed()
	ok(after == 0, "hub: a guard press ends the charge and nothing is felt after it")


func _off() -> void:
	ok(SimHaptics.stage_requests(0, 2, 3).is_empty() and SimHaptics.release_requests(0, 3).is_empty(), "off: with the switch off neither request exists")
	var hub: SimInputHub = _hub_pad()
	var n: int = 0
	for t in range(140):
		hub.pad_stick_right(7, 1.0 if (t >= 10 and t < 90) else 0.0, 0.0)
		hub.intent(0)
		n += hub.take_haptics().size()
		hub.consumed()
	ok(n == 0, "off: a whole charge and throw play nothing")
