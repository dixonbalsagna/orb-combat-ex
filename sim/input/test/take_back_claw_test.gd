extends SceneTree
## The claw check for the flight strike's LT take-back (docs/controls/lt-take-back-claw.md; controller vision section 2): "a face button within about 8 ticks of LT turns the slip or the dodge-cancel into
## the flight strike". The proposed rule, read off the intent the sim sees (after the strike law): the take-back happens when a face edge (light, heavy or sig) comes 0 to W ticks after the LT edge (`dodge`),
## W = 8. A claw, paddles or a keyboard issue the inputs with no transfer; a fast standard thumb needs 6 ticks to move from the stick to a button and a slow one 13 (docs/controls/claw-bot-gate.md). The property:
## a claw never takes a back that a fast thumb could not, and the strike law holds a face press behind a strike stick the same for all three. Pure input, through the real layout. From the repo root:
##   godot --headless --path . --script res://sim/input/test/take_back_claw_test.gd
## Exit 0 if every check passes.

const W: int = 8
var fails: int = 0
var checks: int = 0


func ok(c: bool, what: String) -> void:
	checks += 1
	if not c:
		fails += 1
		print("FAIL  ", what)


func _init() -> void:
	SimInputData.load_and_apply()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	for k in ["quickRead", "beamAim", "hapticLadder", "hapticIncoming", "hapticRefused", "specialsOff", "signatureRtOnly", "driverOnRb", "stallKeep", "hapticImpact"]:
		sw[k] = false
	sw["rightStick"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	_free_hands()
	_stick_busy()
	_after_flick()
	_order()
	_face_kinds()
	_swapped()
	print("take_back_claw_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _pad(swapped: bool = false) -> SimLayout:
	var id: String = SimSwap.swapped_id("arena") if swapped else "arena"
	return SimLayout.new(SimInputData.preset(id))


func _c(c: String, swapped: bool) -> String:
	return SimSwap.control(c) if swapped else c


## Events [tick, kind, name, a, b]: "t" LT or RT value, "b" a button, "rs" the strike stick. Returns {lt: tick of the dodge edge, face: tick of the first face edge after the law, kind}.
func _run(evs: Array, n: int = 80, swapped: bool = false) -> Dictionary:
	var l: SimLayout = _pad(swapped)
	var res: Dictionary = {"lt": -1, "face": -1, "kind": "", "faces": []}
	for t in range(n):
		for e in evs:
			if int(e[0]) == t:
				match str(e[1]):
					"t":
						l.analog(_c("pad:" + str(e[2]), swapped), float(e[3]))
					"b":
						var c: String = _c("pad:" + str(e[2]), swapped)
						if bool(e[3]):
							l.press(c)
						else:
							l.release(c)
					"rs":
						l.axis(_c("pad:rs", swapped), float(e[3]), float(e[4]))
		var i: SimIntent = l.build()
		if i.dodge and res["lt"] < 0:
			res["lt"] = t
		var kind: String = "light" if i.light else ("heavy" if i.heavy else ("sig" if i.sig else ""))
		if kind != "":
			res["faces"].append([t, kind])
			if res["face"] < 0:
				res["face"] = t
				res["kind"] = kind
		l.consumed()
	return res


## The take-back under the proposed rule: the first face edge is 0 to W ticks after the LT edge.
func _converted(r: Dictionary) -> bool:
	return r["lt"] >= 0 and r["face"] >= 0 and r["face"] - r["lt"] >= 0 and r["face"] - r["lt"] <= W


## The three thumb models' gaps (ticks from the LT edge to the face press): CLAW 0, FAST 6, SLOW 13.
const MODELS: Dictionary = {"CLAW": 0, "FAST": 6, "SLOW": 13}


func _free_hands() -> void:
	# No stick in play: LT at 10, the face press at 10 + g. LT and the face button are two different hands, so every gap is the player's own timing: nothing a claw adds.
	var table: Array = []
	for g in range(0, 16):
		var r: Dictionary = _run([[10, "t", "lt", 1.0], [10 + g, "b", "west", true], [12 + g, "b", "west", false]])
		table.append([g, r["face"] - r["lt"], _converted(r)])
		ok(r["lt"] == 10 and r["face"] == 10 + g, "free: LT on tick 10 and the face press %d ticks later reach the sim on ticks 10 and %d (the law holds nothing with the stick at rest)" % [g, 10 + g])
		ok(_converted(r) == (g <= W), "free: a gap of %d ticks is %s" % [g, "a take-back" if g <= W else "too late for it"])
	var claw: bool = _converted(_run([[10, "t", "lt", 1.0], [10 + MODELS["CLAW"], "b", "west", true]]))
	var fast: bool = _converted(_run([[10, "t", "lt", 1.0], [10 + MODELS["FAST"], "b", "west", true]]))
	var slow: bool = _converted(_run([[10, "t", "lt", 1.0], [10 + MODELS["SLOW"], "b", "west", true]]))
	ok(claw and fast and not slow, "free: CLAW and FAST both take it back, SLOW (13) does not: the claw gains nothing over a fast thumb")


func _stick_busy() -> void:
	# A strike charge held on the right stick: a face press is inert behind it and queues (K3), so the take-back cannot happen while the stick is out, for any model. The stick goes out at tick 4 and is
	# let go at tick 40; LT at 10 and the face press at 10 + g (a claw's g = 0 is the same tick as LT).
	var faces: Dictionary = {}
	for m in MODELS.keys():
		var g: int = MODELS[m]
		var r: Dictionary = _run([[4, "rs", "", 1.0, 0.0], [10, "t", "lt", 1.0], [10 + g, "b", "west", true], [11 + g, "b", "west", false], [40, "rs", "", 0.0, 0.0]], 100)
		faces[m] = r["face"]
		ok(not _converted(r), "busy: %s presses LT and a face button while the strike stick is out: no take-back (the face went on tick %d, LT on %d)" % [m, r["face"], r["lt"]])
		ok(r["face"] >= 40 + SimInputData.ti(["strike", "lockout"], 6) or r["face"] < 0, "busy: and the face press waits for the stick to be let go, plus the lockout L (tick %d, the stick was let go on 40)" % r["face"])
	print("take_back_claw_test: strike stick out, the face press goes on tick (-1 = dropped behind the stick): ", faces)
	ok(faces["CLAW"] == faces["FAST"] and faces["FAST"] == faces["SLOW"], "busy: the face press goes on the same tick for CLAW, FAST and SLOW (%s)" % str(faces))


func _after_flick() -> void:
	# A flick ends on tick 12; the faces are free L later. LT at 14 and the face press at 14 + g: the press cannot start before the stick's end + L for any model; the take-back happens only where
	# the gap allows, the same for CLAW and FAST.
	var out: Dictionary = {}
	for m in MODELS.keys():
		var g: int = MODELS[m]
		var r: Dictionary = _run([[8, "rs", "", 1.0, 0.0], [12, "rs", "", 0.0, 0.0], [14, "t", "lt", 1.0], [14 + g, "b", "west", true], [15 + g, "b", "west", false]], 100)
		out[m] = [r["lt"], r["face"], _converted(r)]
	print("take_back_claw_test: flick ended on 12, [LT tick, face tick, taken back] by model: ", out)
	ok(out["CLAW"][1] >= 12 + SimInputData.ti(["strike", "lockout"], 6), "flick: even a claw's face press waits the lockout L after the stick's end (tick %d)" % out["CLAW"][1])
	ok(out["CLAW"][2] == out["FAST"][2] or (not out["CLAW"][2] and out["FAST"][2]), "flick: a claw never converts where a fast thumb does not (%s)" % str(out))
	ok(out["CLAW"][1] <= out["FAST"][1], "flick: and a fast thumb's press never goes before the claw's (%d against %d): both are held to the same floor" % [out["FAST"][1], out["CLAW"][1]])
	ok(not (out["CLAW"][2] and not out["FAST"][2]), "flick: no gain for the claw")


func _order() -> void:
	# The face first and LT after: the blow has already started on its press tick (T1), so there is no take-back, for any gap. LT and the face on the same tick: LT first, a take-back.
	for g in [1, 2, 3, 5, 8]:
		var r: Dictionary = _run([[10, "b", "west", true], [11, "b", "west", false], [10 + g, "t", "lt", 1.0]])
		ok(not _converted(r) and r["face"] == 10 and r["lt"] == 10 + g, "order: the face press %d ticks before LT is not a take-back (face on %d, LT on %d)" % [g, r["face"], r["lt"]])
	var same: Dictionary = _run([[10, "t", "lt", 1.0], [10, "b", "west", true], [11, "b", "west", false]])
	ok(_converted(same) and same["lt"] == 10 and same["face"] == 10, "order: LT and a face press on the same tick are a take-back (a claw or a keyboard can do it; a standard thumb only by luck)")


func _face_kinds() -> void:
	# X, Y and B each read as a face edge; A (the context press) is not a blow and is not one of the three.
	for pair in [["west", "light"], ["north", "heavy"], ["east", "sig"]]:
		var r: Dictionary = _run([[10, "t", "lt", 1.0], [13, "b", pair[0], true], [14, "b", pair[0], false]])
		ok(r["kind"] == pair[1] and _converted(r), "kinds: LT then %s is a face edge of kind %s inside the window" % [pair[0], pair[1]])


func _swapped() -> void:
	# The left-handed layout makes the same stream: the flight strike's inputs are LT-side and face-side in both.
	var a: Dictionary = _run([[10, "t", "lt", 1.0], [14, "b", "west", true], [15, "b", "west", false]], 80, false)
	var b: Dictionary = _run([[10, "t", "lt", 1.0], [14, "b", "west", true], [15, "b", "west", false]], 80, true)
	ok(a["lt"] == b["lt"] and a["face"] == b["face"] and _converted(a) == _converted(b), "swapped: the swapped layout takes it back on the same ticks (LT %d / %d, face %d / %d)" % [a["lt"], b["lt"], a["face"], b["face"]])
	var c: Dictionary = _run([[4, "rs", "", 1.0, 0.0], [10, "t", "lt", 1.0], [11, "b", "west", true], [12, "b", "west", false], [40, "rs", "", 0.0, 0.0]], 100, false)
	var d: Dictionary = _run([[4, "rs", "", 1.0, 0.0], [10, "t", "lt", 1.0], [11, "b", "west", true], [12, "b", "west", false], [40, "rs", "", 0.0, 0.0]], 100, true)
	ok(c["face"] == d["face"], "swapped: and with a strike stick out the face press waits the same on both layouts (%d / %d)" % [c["face"], d["face"]])
