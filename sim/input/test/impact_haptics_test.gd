extends SceneTree
## Headless checks for the impact rumble (docs/controls/impact-haptics.md; timing.json switches.hapticImpact, off): Orb's 2026-10-05 picks that were missing, a landed blow, a close, a launch felt by the one
## launched, a landing and a building breaking. Pure mapping over fabricated events, the kinds' shapes (soft, low, no hum), and a run of real AI matches whose events go through the same mapping, so a
## field name that does not match the sim's own events shows. From the repo root:
##   godot --headless --path . --script res://sim/input/test/impact_haptics_test.gd
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
	_sw(true)
	_blows()
	_moves()
	_shapes()
	_matches()
	_sw(false)
	_off()
	print("impact_haptics_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(on: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["hapticImpact"] = on
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _ev(type: String) -> SimState.FxEvent:
	var e := SimState.FxEvent.new()
	e.type = type
	return e


func _dmg(att: int, vic: int, kind: String) -> SimState.FxEvent:
	var e: SimState.FxEvent = _ev("damage")
	e.attacker = float(att)
	e.victim = float(vic)
	e.kind = kind
	e.amount = 30.0
	return e


func _blows() -> void:
	var r: Array = SimHaptics.event_requests(_dmg(0, 1, "heavy"))
	ok(r.size() == 2 and int(r[0]["slot"]) == 0 and r[0]["kind"] == "blow_land" and int(r[1]["slot"]) == 1 and r[1]["kind"] == "hit_taken", "blows: a heavy from slot 0 to slot 1: slot 0 feels blow_land, slot 1 hit_taken")
	ok(absf(float(r[0]["scale"]) - 1.0) < 0.001, "blows: a heavy is scale 1.0")
	var sc: Array = []
	for k in ["light", "medium", "heavy"]:
		sc.append(float(SimHaptics.event_requests(_dmg(0, 1, k))[0]["scale"]))
	ok(sc[0] < sc[1] and sc[1] < sc[2], "blows: light, medium, heavy climb (%s)" % str(sc))
	var g: Array = SimHaptics.event_requests(_dmg(1, 0, "guard"))
	ok(g.size() == 2 and float(g[0]["scale"]) <= 0.2 + 0.001 and int(g[0]["slot"]) == 1, "blows: a guarded blow is dull (0.2) and the attacker is slot 1")
	ok(SimHaptics.event_requests(_dmg(-1, 1, "light")).size() == 1 and SimHaptics.event_requests(_dmg(-1, 1, "light"))[0]["kind"] == "hit_taken", "blows: a hit with no attacker (the world) is felt by the one hit only")
	ok(SimHaptics.event_requests(_dmg(0, -1, "light")).size() == 1 and SimHaptics.event_requests(_dmg(0, -1, "light"))[0]["kind"] == "blow_land", "blows: a blow that hit nobody on a pad is felt by the attacker only")
	ok(SimHaptics.event_requests(_dmg(0, 0, "light")).is_empty(), "blows: a fighter hurting himself rumbles nothing")
	for k in ["beam", "impact", "burn", ""]:
		ok(SimHaptics.event_requests(_dmg(0, 1, k)).is_empty(), "blows: kind '%s' rumbles nothing here (beams have the struggle's kinds, a landing its own event)" % k)
	ok(SimHaptics.event_requests(_dmg(2, 3, "heavy")).is_empty(), "blows: slots past the two pads rumble nothing (a third and fourth fighter)")


func _moves() -> void:
	var rush: SimState.FxEvent = _ev("rush")
	rush.actor = 1.0
	var r: Array = SimHaptics.event_requests(rush)
	ok(r.size() == 1 and int(r[0]["slot"]) == 1 and r[0]["kind"] == "close_surge", "close: a rush's actor feels close_surge")
	var la: SimState.FxEvent = _ev("launch")
	la.actor = 1.0
	la.target = 0.0
	la.amount = 1500.0
	var l: Array = SimHaptics.event_requests(la)
	ok(l.size() == 1 and int(l[0]["slot"]) == 1 and l[0]["kind"] == "launch_felt", "launch: the one sent (actor) feels launch_felt; the launcher is not asked here (UI's launcher_open)")
	var slow: SimState.FxEvent = _ev("launch")
	slow.actor = 0.0
	slow.amount = 300.0
	ok(float(SimHaptics.event_requests(slow)[0]["scale"]) < float(l[0]["scale"]), "launch: a slower send is gentler")
	var ld: SimState.FxEvent = _ev("land")
	ld.actor = 0.0
	ld.spd = 1400.0
	var lr: Array = SimHaptics.event_requests(ld)
	ok(lr.size() == 1 and int(lr[0]["slot"]) == 0 and lr[0]["kind"] == "landing_thud" and absf(float(lr[0]["scale"]) - 1.0) < 0.001, "landing: the one touching down feels landing_thud at the top scale for a hard one")
	ld.spd = 100.0
	ok(float(SimHaptics.event_requests(ld)[0]["scale"]) >= 0.25 - 0.001, "landing: a soft landing is not silent: the least scale is 0.25")
	var bf: SimState.FxEvent = _ev("building_fall")
	bf.depth = 300.0
	var b: Array = SimHaptics.event_requests(bf)
	ok(b.size() == 2 and b[0]["kind"] == "building_break" and b[1]["kind"] == "building_break" and int(b[0]["slot"]) == 0 and int(b[1]["slot"]) == 1, "building: a fall rumbles both pads")
	bf.depth = 60.0
	ok(float(SimHaptics.event_requests(bf)[0]["scale"]) < 1.0, "building: a low one is gentler")
	ok(SimHaptics.event_requests(_ev("spark")).is_empty() and SimHaptics.event_requests(_ev("crater")).is_empty(), "other events rumble nothing here")


func _shapes() -> void:
	var top: float = 0.0
	for k in ["ladder_1", "ladder_2", "ladder_3"]:
		for s in SimHaptics.steps(k, "pad", 1.0):
			top = maxf(top, float(s["strong"]))
	for k in ["blow_land", "hit_taken", "close_surge", "launch_felt", "landing_thud", "building_break"]:
		var st: Array = SimHaptics.steps(k, "pad", 1.0)
		ok(not st.is_empty() and st.size() <= 4, "shape: %s has steps (at most four)" % k)
		var bright: bool = false
		for s in st:
			if float(s["weak"]) > 0.35:
				bright = true
		ok(not bright, "shape: %s has nothing bright on the high motor (0.35 at most)" % k)
		ok(SimHaptics.steps(k, "handheld", 1.0).size() >= 1, "shape: %s has a phone pulse" % k)
		ok(SimHaptics.kind_gap_ms(k) >= 90, "shape: %s has its own gap, 90 ms or more" % k)
	for k in ["blow_land", "hit_taken", "landing_thud", "building_break", "launch_felt"]:
		var low: bool = true
		for s in SimHaptics.steps(k, "pad", 1.0):
			if float(s["strong"]) < float(s["weak"]):
				low = false
		ok(low, "shape: %s is the low motor first (strong at least weak in every step)" % k)
	ok(float(SimHaptics.steps("launch_felt", "pad", 1.0)[0]["strong"]) >= float(SimHaptics.steps("hit_taken", "pad", 1.0)[0]["strong"]), "shape: being launched is the heaviest push of the blows")
	ok(float(SimHaptics.steps("blow_land", "pad", 0.3)[0]["strong"]) < float(SimHaptics.steps("blow_land", "pad", 1.0)[0]["strong"]), "shape: a light blow is softer than a heavy one")
	var p: Dictionary = SimHaptics.plan("landing_thud", {"kind": "pad", "id": 3}, true, -10000, 1000, 0.5)
	ok(p.get("via", "") == "pad" and p["steps"].size() == 2, "shape: a pad plays landing_thud in two steps")


## Real AI matches: the events the sim itself emits go through the same mapping.
func _matches() -> void:
	var tally: Dictionary = {}
	var bad: int = 0
	var ticks: int = 0
	for seed_v in [3, 11]:
		var S: SimState = SimCore.createSim()
		SimCore.newMatch(S, seed_v, {}, {"intro": false})
		var t: int = 0
		while t < 5400 and S.game.ko == null:
			SimCore.step(S)
			t += 1
			for e in S.out.fx:
				for r in SimHaptics.event_requests(e):
					tally[r["kind"]] = int(tally.get(r["kind"], 0)) + 1
					if int(r["slot"]) < 0 or int(r["slot"]) > 1 or float(r["scale"]) < 0.0 or float(r["scale"]) > 1.0 or not SimHaptics.kinds().has(r["kind"]):
						bad += 1
			S.out.fx.clear()
		ticks += t
	print("impact_haptics_test: real matches, %d ticks: %s" % [ticks, str(tally)])
	ok(bad == 0, "matches: every request from real events has a slot 0 or 1, a scale from 0 to 1 and a known kind")
	for k in ["blow_land", "hit_taken"]:
		ok(int(tally.get(k, 0)) > 0, "matches: real blows reach %s (%d)" % [k, int(tally.get(k, 0))])
	var any_move: int = int(tally.get("close_surge", 0)) + int(tally.get("launch_felt", 0)) + int(tally.get("landing_thud", 0)) + int(tally.get("building_break", 0))
	ok(any_move > 0, "matches: real closes, launches, landings or building breaks reach the mapping (%d)" % any_move)


func _off() -> void:
	ok(SimHaptics.event_requests(_dmg(0, 1, "heavy")).is_empty(), "off: with the switch off nothing is asked, whatever the event")
	var la: SimState.FxEvent = _ev("launch")
	la.actor = 1.0
	la.amount = 1500.0
	ok(SimHaptics.event_requests(la).is_empty(), "off: and no launch, landing or break either")
