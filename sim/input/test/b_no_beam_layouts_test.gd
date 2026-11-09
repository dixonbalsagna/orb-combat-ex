extends SceneTree
## Headless checks for "no press of B fires a beam or a signature, alone or with any shoulder, in any stance or layout" (docs/design/overnight-2026-11-08.md (b); docs/controls/b-no-beam.md): every pad, keyboard and touch
## preset, every stance on its own and in the pairs a thumb can hold (LB guard, RB energy, RT power, LT dodge), B tapped and held, at three distances, the flight strikes on (the Sunday build's rows), a standing rival,
## the real layout built tick by tick into the sim. With switches.bNoBeam on no combination starts a beam. Off (the control), some combination does, so the scan can tell. From the repo root:
##   godot --headless --path . --script res://sim/input/test/b_no_beam_layouts_test.gd
## Exit 0 if every check passes.

var fails: int = 0
var checks: int = 0
var zip_fs0: bool = false
var runs: int = 0

const PRESETS: Array = ["arena", "arena-swapped", "simple-pad", "kb-solo", "kb-solo-swapped", "kb-shared-p1", "kb-shared-p2", "touch-full"]
const STANCES: Array = [[], ["guard"], ["mode"], ["power"], ["dodge"], ["guard", "mode"], ["dodge", "guard"], ["power", "dodge"], ["mode", "dodge"], ["power", "mode"], ["power", "guard"]]
const DISTS: Array = [80.0, 212.0, 800.0]


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.pin_switches_off()
	zip_fs0 = bool(DirZip.fsCfg().get("enabled", false))
	DirZip.fsCfg()["enabled"] = true   # the Sunday build's flight strikes row: one key in interrupts.json, two in timing.json
	_sw(true)
	var leaks_on: Array = _scan()
	ok(leaks_on.is_empty(), "on: no B press starts a beam in any preset, stance, hold or distance (%d leaks: %s)" % [leaks_on.size(), str(leaks_on.slice(0, 6))])
	print("scanned %d runs with the switch on" % runs)
	_sw(true, true)
	runs = 0
	var leaks_keep: Array = _scan()
	var all_rt: bool = true
	var rt_alone: bool = false
	for l in leaks_keep:
		all_rt = all_rt and (" power " in (" " + String(l) + " ") or String(l).contains("power"))
		rt_alone = rt_alone or String(l).begins_with("arena power ")
	ok(not leaks_keep.is_empty() and all_rt and rt_alone, "interim (bNoBeamKeepRt): the only beams from B are the ones with RT in the combination, and RT + B on the pad is still one (%d leaks, e.g. %s)" % [leaks_keep.size(), str(leaks_keep.slice(0, 4))])
	print("scanned %d runs with the interim: %d beams from B, all with RT held" % [runs, leaks_keep.size()])
	runs = 0
	var leaks_chan: Array = _scan(30)   # the same scan with B 30 ticks after the stances (an RT channel is on): Game Design's condition
	ok(leaks_chan.is_empty(), "interim: B pressed 30 ticks after the stance (an RT channel) fires no signature in any preset or stance combination (%d leaks: %s)" % [leaks_chan.size(), str(leaks_chan.slice(0, 4))])
	print("scanned %d runs with the interim and B 30 ticks after the stance: %d beams from B" % [runs, leaks_chan.size()])
	_sw(false)
	runs = 0
	var leaks_off: Array = _scan()
	ok(leaks_off.size() >= 1, "off (the control): the same scan finds beams from B (%d found, e.g. %s), so it can tell" % [leaks_off.size(), str(leaks_off.slice(0, 3))])
	print("scanned %d runs with the switch off: %d beams from B (%s)" % [runs, leaks_off.size(), str(leaks_off.slice(0, 12))])
	DirZip.fsCfg()["enabled"] = zip_fs0
	SimInputData.pin_switches_off()
	print("b_no_beam_layouts_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(on: bool, keep_rt: bool = false) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["signatureRtOnly"] = true
	sw["flightStrikeB"] = true
	sw["dodgeHeld"] = true
	sw["bNoBeam"] = on
	sw["bNoBeamKeepRt"] = keep_rt
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


## The control of an action's plain binding in a preset ("" if it has none).
func _ctl(preset: Dictionary, action: String) -> String:
	for b in preset["bindings"]:
		if str(b["action"]) == action and b.get("layer", null) == null and b.get("gesture", null) == null and (b["controls"] as Array).size() == 1:
			return str(b["controls"][0])
	return ""


func _scan(lead: int = 10) -> Array:
	var leaks: Array = []
	for pid in PRESETS:
		var preset: Dictionary = SimInputData.preset(pid)
		if preset.is_empty():
			ok(false, "scan: the preset %s exists" % pid)
			continue
		var b: String = _ctl(preset, "signature")
		if b == "":
			continue
		for st in STANCES:
			var ctls: Array = []
			var have: bool = true
			for a in st:
				var c: String = _ctl(preset, a)
				if c == "":
					have = false
				ctls.append(c)
			if not have:
				continue
			for hold_b in [false, true]:
				for dist in DISTS:
					if _beam(preset, ctls, b, hold_b, dist, lead):
						leaks.append("%s %s %s %d" % [pid, "+".join(st) if not st.is_empty() else "none", "held" if hold_b else "tap", int(dist)])
	return leaks


func _beam(preset: Dictionary, ctls: Array, b: String, hold_b: bool, dist: float, lead: int = 10) -> bool:
	runs += 1
	var layout := SimLayout.new(preset)
	var su := {"v2": [true, true], "assists": [[], []], "intro": false}
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var r = S.fighters[1]
	r.x = SimWrap.wrap(a.x + dist)
	r.y = a.y
	var quiet := SimIntent.new()
	var beam: bool = false
	for t in range(30):
		SimCore.step(S, [layout.build(), quiet])
		layout.consumed()
		S.out.fx.clear()
	for c in ctls:
		layout.press(c)
	for t in range(lead):
		SimCore.step(S, [layout.build(), quiet])
		layout.consumed()
		S.out.fx.clear()
	layout.press(b)
	for t in range(120):
		if t == (24 if hold_b else 3):
			layout.release(b)
		SimCore.step(S, [layout.build(), quiet])
		layout.consumed()
		for e in S.out.fx:
			var nm: String = String(e.kind) if String(e.type) == "cue" else String(e.type)
			if int(e.actor) == 0 and (nm == "beam_fire" or nm == "beam_charge" or nm == "beam_outcome"):
				beam = true
		S.out.fx.clear()
		if beam:
			break
	SimCore.dispose(S)
	return beam
