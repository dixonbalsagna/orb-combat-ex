extends SceneTree
## Headless checks for the right-hand attacks' plumbing (switches.rightStick on): the intent's second word (pack2, unpack2, canon), the hub's settings (the
## strike stick's style, the D-pad mirror and its automatic form, the swap), the remap screen's rows and rebinding for the strike stick, and the checks on
## the shipped presets. From the repo root:
##   godot --headless --path . --script res://sim/input/test/strike_hub_test.gd
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
	SimInputData.clear_overrides()
	_switch(true)
	_second_word()
	_hub_settings()
	_remap()
	_presets()
	_checks()
	_switch(false)
	_off()
	print("strike_hub_test: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)


func _switch(on: bool) -> void:
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = on
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()


func _second_word() -> void:
	var i := SimIntent.new()
	ok(SimIntent.pack2(i) == 0, "word: a neutral intent has a zero second word")
	i.rsHeld = true
	i.rsStart = true
	i.rsRelease = true
	i.rsCancel = true
	i.rsDir = 4
	i.rsLevel = 3
	i.rsMask = 10
	i.rsAim = 31
	i.rsLag = 15
	i.brace = true
	i.braceDir = 3
	var p: int = SimIntent.pack2(i)
	ok(p >> SimIntent.BITS2 == 0, "word: it fits in %d bits" % SimIntent.BITS2)
	var j := SimIntent.new()
	ok(SimIntent.unpack2(p, j), "word: it unpacks")
	ok(j.rsHeld and j.rsStart and j.rsRelease and j.rsCancel and j.rsDir == 4 and j.rsLevel == 3 and j.rsMask == 10 and j.rsAim == 31 and j.rsLag == 15 and j.brace and j.braceDir == 3, "word: every field round-trips")
	ok(SimIntent.pack2(j) == p, "word: and re-packs to the same integer")
	ok(not SimIntent.unpack2(1 << SimIntent.BITS2, SimIntent.new()), "word: a bit above the word is refused")
	ok(not SimIntent.unpack2(5 << 4, SimIntent.new()), "word: a direction above 4 is refused")
	ok(SimIntent.pack(i) == SimIntent.pack(SimIntent.new()), "word: the first word does not carry any of it (a replay with the switch off is the same integer)")
	var c: SimIntent = SimIntent.canon(i)
	ok(SimIntent.pack2(c) == p, "word: canon keeps the second word")
	var d := SimIntent.new()
	SimIntent.applyIntent(d, i)
	ok(SimIntent.pack2(d) == p, "word: applyIntent copies it")
	SimIntent.clearIntent(d)
	ok(SimIntent.pack2(d) == 0, "word: clearIntent clears it")


func _hub_settings() -> void:
	var hub := SimInputHub.new()
	ok(hub.strike_style_of(0) == "hold", "hub: the strike stick holds by default")
	hub.set_strike_style("toggle", 1)
	ok(hub.strike_style_of(1) == "toggle" and hub.strike_style_of(0) == "hold", "hub: toggle is player two's own")
	hub.set_strike_style("", 1)
	ok(hub.strike_style_of(1) == "hold", "hub: and goes back to the default")
	ok(not hub.mirror_on(0), "hub: the D-pad mirror is off by default")
	hub.set_humans(true, false)
	hub.pad_button(3, "south", true)
	hub.pad_button(3, "south", false)
	ok(hub.slot_pad[0] == 3, "hub: harness: pad 3 drives player one")
	_idle(hub, 12)   # the joining press was a face press: the law keeps a strike request R ticks from it
	hub.set_pad_has_right_stick(3, false)
	ok(hub.mirror_on(0), "hub: a pad with no right stick gets the mirror (auto)")
	hub.set_mirror("off", 0)
	ok(not hub.mirror_on(0), "hub: unless the player turned it off")
	hub.set_mirror("on", 0)
	hub.set_pad_has_right_stick(3, true)
	ok(hub.mirror_on(0), "hub: and the player can turn it on for a pad with a stick")
	hub.set_mirror("auto", 0)
	ok(not hub.mirror_on(0), "hub: auto with a right stick is off")
	# The mirror, through the hub: a D-pad press is a strike only with the mirror on.
	hub.set_mirror("on", 0)
	hub.pad_button(3, "dpad_right", true)
	var started: bool = false
	for t in range(8):
		var i: SimIntent = hub.intent(0)
		started = started or i.rsStart
		hub.consumed()
	ok(started, "hub: with the mirror on, the D-pad is a strike stick through the hub")
	hub.pad_button(3, "dpad_right", false)
	for t in range(6):
		hub.intent(0)
		hub.consumed()
	hub.set_mirror("off", 0)
	hub.pad_button(3, "dpad_right", true)
	started = false
	for t in range(8):
		var i2: SimIntent = hub.intent(0)
		started = started or i2.rsStart
		hub.consumed()
	ok(not started, "hub: with it off the D-pad does nothing")
	# The strike stick's toggle style through the hub.
	hub.pad_button(3, "dpad_right", false)
	hub.set_mirror("off", 0)
	hub.set_strike_style("toggle", 0)
	hub.pad_stick_right(3, 1.0, 0.0)
	var held_after_rest: bool = false
	for t in range(8):
		hub.intent(0)
		hub.consumed()
	hub.pad_stick_right(3, 0.0, 0.0)
	for t in range(10):
		var i3: SimIntent = hub.intent(0)
		held_after_rest = i3.rsHeld
		hub.consumed()
	ok(held_after_rest, "hub: the toggle style keeps the charge while the stick rests")
	# A right stick alone does not join: a stick on an unclaimed pad is nothing.
	var hub2 := SimInputHub.new()
	hub2.pad_stick_right(9, 1.0, 0.0)
	ok(hub2.slot_pad[0] == -1 and hub2.slot_pad[1] == -1, "hub: the right stick alone does not join")


func _idle(hub: SimInputHub, n: int) -> void:
	for t in range(n):
		hub.intent(0)
		hub.consumed()


func _kb_row(rows: Array, action: String) -> Dictionary:
	for r in rows:
		if str(r["action"]) == action:
			return r
	return {}


func _remap() -> void:
	var kb: Dictionary = SimInputData.preset("kb-solo")
	var rows: Array = SimInputRemap.listing(kb)
	var r: Dictionary = _kb_row(rows, "strike")
	ok(not r.is_empty() and not r["fixed"] and r["controls"].size() == 4, "remap: the keyboard's strike arrows are a remappable four-key row")
	var pad: Dictionary = SimInputData.preset("arena")
	var prows: Array = SimInputRemap.listing(pad)
	ok(bool(_kb_row(prows, "strike")["fixed"]) and bool(_kb_row(prows, "strike_mirror")["fixed"]), "remap: on a pad the strike stick and the D-pad mirror are fixed rows")
	var res: Dictionary = SimInputRemap.rebind(kb, "strike", null, 0, ["kb:KeyU", "kb:KeyH", "kb:KeyM", "kb:Comma"])
	ok(bool(res["ok"]), "remap: the strike arrows rebind to four free keys: %s" % str(res["error"]))
	var bad: Dictionary = SimInputRemap.rebind(kb, "strike", null, 0, ["kb:KeyJ", "kb:KeyH", "kb:KeyM", "kb:Comma"])
	ok(not bool(bad["ok"]) and str(bad["conflict"].get("action", "")) == "light", "remap: J is the light's, so it is a conflict, named")
	var dup: Dictionary = SimInputRemap.rebind(kb, "strike", null, 0, ["kb:KeyU", "kb:KeyU", "kb:KeyM", "kb:Comma"])
	ok(not bool(dup["ok"]), "remap: four different keys are required")
	var one: Dictionary = SimInputRemap.rebind(kb, "strike", null, 0, ["kb:KeyU"])
	ok(not bool(one["ok"]), "remap: the strike axis does not take one key")
	# Saved as overrides and applied again.
	var diff: Array = SimInputRemap.diff(kb, res["preset"])
	ok(diff.size() == 1 and str(diff[0]["action"]) == "strike" and diff[0]["controls"].size() == 4, "remap: the diff is one strike entry of four keys")
	SimInputData.set_overrides("kb-solo", diff)
	var back: Dictionary = SimInputData.preset("kb-solo")
	var ctl: Array = _kb_row(SimInputRemap.listing(back), "strike")["controls"]
	ok(ctl == ["kb:KeyU", "kb:KeyH", "kb:KeyM", "kb:Comma"], "remap: the override is applied again")
	var l := SimLayout.new(back)
	l.press("kb:KeyM")
	var i: SimIntent = null
	var got_down: bool = false
	for t in range(6):
		i = l.build()
		got_down = got_down or (i.rsStart and i.rsDir == SimStrikeRead.DOWN)
		l.consumed()
	ok(got_down, "remap: and the layout strikes down on the new down key")
	SimInputData.clear_overrides()
	# A strike key is a single control and rebinds like a button.
	var sh: Dictionary = SimInputData.preset("kb-shared-p1")
	var rk: Dictionary = SimInputRemap.rebind(sh, "strike_key", null, 0, ["kb:KeyU"])
	ok(bool(rk["ok"]), "remap: the shared keyboard's strike key rebinds")
	var reserved: Array = SimInputRemap.check_bindings(SimInputRemap.rebind(sh, "strike_key", null, 0, ["kb:KeyT"])["preset"])
	ok(not reserved.is_empty(), "remap: T is reserved for the system and the check says so")


func _presets() -> void:
	# The swapped layouts are real presets: derived for every pad preset, shipped for the solo keyboard.
	var a: Dictionary = SimInputData.preset("arena")
	var sw: Dictionary = SimInputData.preset("arena-swapped")
	ok(not sw.is_empty() and str(sw["hand"]) == "swapped" and not sw.has("default"), "presets: arena-swapped exists, is tagged swapped and is not a default")
	ok(not SimInputData.preset("simple-pad-swapped").is_empty(), "presets: and so does the Simple pad's")
	ok(SimInputData.preset("arena-swapped-swapped").is_empty(), "presets: a swapped preset is not swapped again")
	ok(SimSwap.mirror_preset(sw)["bindings"] == a["bindings"], "presets: swapping the swapped preset gives Arena's bindings back")
	var ks: Dictionary = SimInputData.preset("kb-solo-swapped")
	ok(not ks.is_empty() and str(ks["hand"]) == "swapped" and ks["device"] == "kb", "presets: kb-solo-swapped is shipped, for the keyboard")
	ok(SimInputData.default_preset("pad") == "arena" and SimInputData.default_preset("kb") == "kb-solo", "presets: the defaults are still Arena and the solo keyboard")
	# Remap: the optional rows (the pad leaves the strike button, the brace button and Escape unbound), and binding one.
	var rows: Array = SimInputRemap.listing(a)
	var opt: Dictionary = {}
	for r in rows:
		if (r["controls"] as Array).is_empty():
			opt[str(r["action"])] = r
	ok(opt.has("strike_key") and opt.has("brace_key") and opt.has("escape"), "remap: the pad lists the strike button, the brace button and Escape as rows with no control: %s" % str(opt.keys()))
	var res: Dictionary = SimInputRemap.rebind(a, "strike_key", null, 0, ["pad:l3"])
	ok(bool(res["ok"]), "remap: the strike button binds to L3: %s" % str(res["error"]))
	var res2: Dictionary = SimInputRemap.rebind(a, "escape", null, 0, ["pad:r3"])
	ok(bool(res2["ok"]), "remap: Escape (the single-control vanish) binds to any control, R3 included, by the player's choice")
	var res3: Dictionary = SimInputRemap.rebind(a, "brace_key", null, 0, ["pad:west"])
	ok(not bool(res3["ok"]) and str(res3["conflict"].get("action", "")) == "light", "remap: a taken control is a conflict, named")
	SimInputData.set_overrides("arena", SimInputRemap.diff(a, res["preset"]))
	var back: Dictionary = SimInputData.preset("arena")
	var has_sk: bool = false
	for b in back["bindings"]:
		if str(b["action"]) == "strike_key" and b["controls"] == ["pad:l3"]:
			has_sk = true
	ok(has_sk, "remap: the saved override gives the strike button back")
	SimInputData.clear_overrides()
	# The shared keyboard's two halves share nothing, strike and brace keys included, and the solo's brace key is a row.
	ok(not _kb_row(SimInputRemap.listing(SimInputData.preset("kb-solo")), "brace_key").is_empty(), "remap: the keyboard's brace key is a row")
	ok(not _kb_row(SimInputRemap.listing(SimInputData.preset("kb-shared-p2")), "strike_key").is_empty(), "remap: and the shared keyboard's strike key (Accessibility's row 10)")


func _checks() -> void:
	for id in ["arena", "kb-solo", "kb-shared-p1", "kb-shared-p2", "simple-pad"]:
		var p: Dictionary = SimInputData.preset(id)
		var probs: Array = SimInputData.check_bindings(p, 0)
		ok(probs.is_empty(), "checks: %s has no problems with the strike bindings (%s)" % [id, str(probs)])
	var a: Dictionary = SimInputData.preset("kb-shared-p1")
	var b: Dictionary = SimInputData.preset("kb-shared-p2")
	var clash: Array = SimInputRemap.check_bindings(a, b)
	ok(clash.is_empty(), "checks: the shared keyboard's two halves share no control (including the strike keys): %s" % str(clash))
	ok(not _has_action(SimInputData.preset("simple-pad"), "strike"), "checks: the Simple pad has no strike stick (strikes off by default)")


func _has_action(p: Dictionary, a: String) -> bool:
	for b in p.get("bindings", []):
		if str(b["action"]) == a:
			return true
	return false


func _off() -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(3, "south", true)
	hub.pad_button(3, "south", false)
	hub.pad_stick_right(3, 1.0, 0.0)
	var any: bool = false
	for t in range(10):
		var i: SimIntent = hub.intent(0)
		any = any or i.rsHeld or i.rsStart
		hub.consumed()
	ok(not any, "off: with the switch off a right stick through the hub does nothing")
	ok(SimIntent.pack2(hub.intent(0)) == 0, "off: and the second word is zero")
