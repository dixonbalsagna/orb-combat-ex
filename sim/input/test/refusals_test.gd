extends SceneTree
## Headless checks for every press answered (docs/controls/refusals.md; timing.json switches.hapticRefused, off): the strike law's two silent drops (a face press that waited behind the stick past its life, the
## oldest of a full queue) are listed with a reason code and knock the pad of their slot; the director's stick_refused texts and the new press_refused cue carry the codes UI shows; the code table is complete.
## From the repo root:
##   godot --headless --path . --script res://sim/input/test/refusals_test.gd
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
	_sw(true, true)
	_law()
	_hub()
	_cues()
	_table()
	_sw(true, false)
	_off()
	print("refusals_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _sw(right: bool, refused: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	for k in ["quickRead", "beamAim", "hapticLadder", "hapticIncoming", "specialsOff", "signatureRtOnly", "driverOnRb", "stallKeep", "hapticImpact"]:
		sw[k] = false
	sw["rightStick"] = right
	sw["hapticRefused"] = refused
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _pad() -> SimLayout:
	return SimLayout.new(SimInputData.preset("arena"))


## Builds `n` ticks; before tick t the events of `evs` ([tick, kind, name, a, b]) are applied. Returns every drop the layout reported, as [tick, why, k].
func _run(l: SimLayout, evs: Array, n: int) -> Array:
	var out: Array = []
	for t in range(n):
		for e in evs:
			if int(e[0]) == t:
				match str(e[1]):
					"b":
						if bool(e[3]):
							l.press("pad:" + str(e[2]))
						else:
							l.release("pad:" + str(e[2]))
					"rs":
						l.axis("pad:rs", float(e[3]), float(e[4]))
		l.build()
		for d in l.take_dropped():
			out.append([t, str(d["why"]), str(d["k"])])
		l.consumed()
	return out


func _law() -> void:
	var expiry: int = SimInputData.ti(["strike", "queueTicks"], 36)
	# a stick held out, a face press made behind it that waits past its life
	var d1: Array = _run(_pad(), [[10, "rs", "", 1.0, 0.0], [20, "b", "west", true], [21, "b", "west", false]], 20 + expiry + 20)
	ok(d1.size() == 1 and d1[0][1] == "face_late" and d1[0][2] == "light", "law: a light press that waited behind the held stick past the queue's life is dropped as face_late (%s)" % str(d1))
	ok(d1.size() == 1 and d1[0][0] > 20 + expiry - 1 and d1[0][0] <= 20 + expiry + 3, "law: and told just after its life ends (tick %s, pressed at 20, life %d)" % [str(d1[0][0] if d1.size() > 0 else -1), expiry])
	# a full queue: the fourth press pushes the oldest out
	var d2: Array = _run(_pad(), [[10, "rs", "", 1.0, 0.0], [20, "b", "west", true], [21, "b", "west", false], [22, "b", "north", true], [23, "b", "north", false], [24, "b", "east", true], [25, "b", "east", false], [26, "b", "south", true], [27, "b", "south", false]], 30)
	ok(d2.size() == 1 and d2[0][1] == "face_overflow" and d2[0][2] == "light", "law: a fourth press behind the stick pushes the oldest out as face_overflow (%s)" % str(d2))
	# the stick lets go in time: the press goes, nothing is dropped
	var d3: Array = _run(_pad(), [[10, "rs", "", 1.0, 0.0], [14, "b", "west", true], [15, "b", "west", false], [18, "rs", "", 0.0, 0.0]], 70)
	ok(d3.is_empty(), "law: a press that waits and then goes is not a refusal (%s)" % str(d3))
	# no stick, no queue, no drop
	var d4: Array = _run(_pad(), [[10, "b", "west", true], [11, "b", "west", false], [30, "b", "north", true], [31, "b", "north", false]], 80)
	ok(d4.is_empty(), "law: face presses with the stick at rest are never dropped")
	# with the right-hand switch off the list is empty (there is no law)
	_sw(false, true)
	var d5: Array = _run(_pad(), [[10, "rs", "", 1.0, 0.0], [20, "b", "west", true], [21, "b", "west", false]], 80)
	ok(d5.is_empty(), "law: with rightStick off there is no law and no drop")
	_sw(true, true)


func _hub_run(evs: Array, n: int) -> Dictionary:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var knocks: Array = []
	var refusals: Array = []
	for t in range(n):
		for e in evs:
			if int(e[0]) == t:
				if str(e[1]) == "rs":
					hub.pad_stick_right(7, float(e[3]), float(e[4]))
				else:
					hub.pad_button(7, str(e[2]), bool(e[3]))
		hub.intent(0)
		for r in hub.take_haptics():
			knocks.append(r)
		refusals.append_array(hub.take_refusals())
		hub.consumed()
	return {"knocks": knocks, "refusals": refusals}


func _hub() -> void:
	var expiry: int = SimInputData.ti(["strike", "queueTicks"], 36)
	var r: Dictionary = _hub_run([[10, "rs", "", 1.0, 0.0], [20, "b", "west", true], [21, "b", "west", false]], 20 + expiry + 20)
	var late: Array = []
	for k in r["knocks"]:
		if k.get("reason", "") == "face_late":
			late.append(k)
	ok(late.size() == 1 and late[0]["kind"] == "stick_refused" and int(late[0]["slot"]) == 0, "hub: the dropped face press knocks its slot's pad, one stick_refused with the reason face_late")
	var codes: Array = []
	for x in r["refusals"]:
		if x["code"] == "face_late":
			codes.append(x)
	ok(codes.size() == 1 and int(codes[0]["slot"]) == 0 and codes[0]["button"] == "light", "hub: and it is listed for UI: take_refusals() gives slot, code, tick and button")
	ok(SimHaptics.refusal_word(codes[0]["code"]) == "Too late", "hub: and the code has its word")
	ok(SimHaptics.plan("stick_refused", {"kind": "pad", "id": 3}, true, -10000, 1000).get("via", "") == "pad", "hub: a pad plays the knock")
	ok(_hub_run([[10, "rs", "", 1.0, 0.0], [20, "b", "west", true], [21, "b", "west", false]], 20 + expiry + 20)["refusals"].size() == r["refusals"].size(), "hub: the same run gives the same list (deterministic)")
	# taken once: nothing is left to take
	var hub := SimInputHub.new()
	ok(hub.take_refusals().is_empty(), "hub: nothing to take on a fresh hub")


func _cues() -> void:
	var cases: Array = [["ki", "no_energy"], ["taken", "hit"], ["late", "too_late"], ["replaced", "replaced"], ["chase", "no_reach"], ["answered", "answered"], ["dodged", "dodged"], ["cancel", "cancelled"], ["refused", "not_yours"], ["5", "busy"], ["stun_limit", "stun_limit"], ["", "other"], ["no such word", "other"]]
	for c in cases:
		ok(SimHaptics.refusal_code(c[0]) == c[1], "cues: the text '%s' is the code %s" % [c[0], c[1]])
		var r: Array = SimHaptics.requests("stick_refused", 1, -1, c[0], 0.0)
		ok(r.size() == 1 and r[0]["kind"] == "stick_refused" and int(r[0]["slot"]) == 1 and r[0]["reason"] == c[1], "cues: a stick_refused cue with '%s' knocks slot 1 with the reason %s" % [c[0], c[1]])
	for code in ["stun_limit", "queue_expired", "block_lockout"]:
		var p: Array = SimHaptics.requests("press_refused", 0, -1, code, 0.0)
		ok(p.size() == 1 and p[0]["kind"] == "stick_refused" and p[0]["reason"] == code and int(p[0]["slot"]) == 0, "cues: a press_refused cue with %s knocks slot 0 with that reason" % code)
	ok(SimHaptics.requests("press_refused", -1, -1, "stun_limit", 0.0).is_empty() and SimHaptics.requests("press_refused", 2, -1, "stun_limit", 0.0).is_empty(), "cues: only slots 0 and 1 are knocked")
	# press_refused needs only the refused switch, not the right hand
	_sw(false, true)
	ok(SimHaptics.requests("press_refused", 0, -1, "block_lockout", 0.0).size() == 1, "cues: press_refused works with the right-hand switch off (a block's lockout is not the stick's)")
	ok(SimHaptics.requests("stick_refused", 0, -1, "ki", 0.0).is_empty(), "cues: the stick's own cue still needs the right hand")
	_sw(true, true)


func _table() -> void:
	for code in SimHaptics.REFUSALS.keys():
		var row: Dictionary = SimHaptics.REFUSALS[code]
		ok(String(row["word"]) != "" and (row["owner"] == "controls" or row["owner"] == "encounter") and String(row["what"]) != "", "table: %s has a word, an owner and what happened" % code)
	for t in SimHaptics.REFUSAL_TEXT.keys():
		ok(SimHaptics.REFUSALS.has(SimHaptics.REFUSAL_TEXT[t]), "table: the director's text '%s' maps to a code in the table" % t)
	for code in ["face_late", "face_overflow", "stun_limit", "queue_expired", "block_lockout"]:
		ok(SimHaptics.REFUSALS.has(code), "table: the four silent drops of the brief are all there (%s)" % code)
	ok(SimHaptics.refusal_word("nonsense") == "Not now", "table: an unknown code reads Not now")


func _off() -> void:
	var expiry: int = SimInputData.ti(["strike", "queueTicks"], 36)
	var r: Dictionary = _hub_run([[10, "rs", "", 1.0, 0.0], [20, "b", "west", true], [21, "b", "west", false]], 20 + expiry + 20)
	var n: int = 0
	for k in r["knocks"]:
		if k.get("reason", "") == "face_late":
			n += 1
	ok(n == 0 and r["refusals"].is_empty(), "off: with hapticRefused off nothing is knocked or listed (the law's drop stays silent, as it was)")
	ok(SimHaptics.requests("press_refused", 0, -1, "stun_limit", 0.0).is_empty(), "off: and the press_refused cue maps to nothing")
