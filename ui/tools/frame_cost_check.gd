extends SceneTree
## The HUD's per-frame savings change nothing the player sees (docs/ui/frame-cost.md). The same seeded match is played twice through the real sim host, with UiFast off (the cost the HUD had) and on, and after
## every frame's UiSimBridge.patch and UiHud.advance a digest of what the HUD would draw is taken: every layer's signature, visibility, position and size, every fighter model's fields, the toll, the planet strip's
## data and the feed's size. The two runs' digests must be equal on every frame. Gen 1 and a gen 2 coast, with and without the touch buttons, plus the cases the savings are careful about (a planet turn or the
## campaign's wear changing the fallen buildings without a loss being counted: the strip's marks catch up within a quarter second). Headless; run from the repo root:
##   godot --headless --path . --script res://ui/tools/frame_cost_check.gd [-- --ticks=900]
## `--dump=<file>` appends the digests of the savings-on run, frame by frame, to a file, so the same run on another tree (the HEAD before the savings) can be compared with it line for line.
## Exits 0 when every check passes.

var fails: int = 0
var checks: int = 0


func _ok(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL  ", what)


func _initialize() -> void:
	_run.call_deferred()


func _plain(v) -> bool:
	return typeof(v) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_COLOR, TYPE_VECTOR2, TYPE_RECT2, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_NIL, TYPE_STRING_NAME]


func _model_digest(m: UiFighterModel) -> String:
	var out := PackedStringArray()
	for p in m.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var v = m.get(p["name"])
		if _plain(v):
			out.append("%s=%s" % [p["name"], var_to_str(v)])
	return "|".join(out)


func _digest(hud: UiHud) -> String:
	var parts := PackedStringArray()
	for l in hud._all_layers():
		if l == null:
			parts.append("-")
		else:
			parts.append("%s@%s/%s/%s" % [var_to_str(l.sig), str(l.visible), str(l.position), str(l.size)])
	for m in hud.hub.models:
		parts.append(_model_digest(m))
	parts.append(var_to_str(hud.hub.toll))
	parts.append(str(hud.hub.toll_age))
	parts.append(str(hud.hub.feed.size()))
	parts.append("%s %s %s %s %s" % [str(hud.hub.cards.size()), str(hud.hub.barks.size()), str(hud.hub.mode), str(hud.hub.t_now), str(hud._t)])
	parts.append("%s %s %s %s %s" % [var_to_str(hud.hub.banner), var_to_str(hud.hub.hint), var_to_str(hud.hub.telegraph), var_to_str(hud.hub.caption), var_to_str(hud.hub.tug)])
	parts.append("%s %s %s" % [str(hud._lb), str(hud._swap_fade), str(hud._intro_a)])
	parts.append(str(hud.hub.stats["events"]))
	parts.append(var_to_str(hud._strip_data))
	return "\n".join(parts).sha1_text()


## One run: returns the digest of every frame.
func _play(fast: bool, gen: int, touch: bool, ticks: int, mid: Callable = Callable()) -> Array:
	UiFast.on = fast
	var host := SimHost.new()
	if gen == 2:
		WorldClimate.useGen(2)
		host.new_match(4, {"p1": true, "p2": true}, {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}, "planetGen": 2, "intro": false})
	else:
		host.new_match(4)
	var hud: UiHud = load("res://ui/hud/ui_hud.tscn").instantiate()
	hud.size = Vector2(1280, 720)
	root.add_child(hud)
	await process_frame
	var f: Array = UiSimBridge.fighters(host.S)
	hud.setup(f[0], f[1])
	var vp: Vector2 = hud.layout.vp
	hud.anchor_fn = func(slot: int) -> Dictionary:
		var fi = host.S.fighters[slot]
		var m: float = float(host.S.fighters[0].x) + SimWrap.sdx(float(host.S.fighters[0].x), float(host.S.fighters[1].x)) * 0.5
		var dx: float = SimWrap.sdx(m, float(fi.x))
		return {"pos": Vector2(vp.x * 0.5 + dx * 0.35, vp.y * 0.62 - float(fi.y) * 0.35), "h": vp.y * 0.11, "visible": true}
	hud.strip_fn = func() -> Dictionary:
		return UiSimBridge.strip_data(host.S, float(host.S.fighters[0].x), 1600.0)
	host.drained.connect(func(evs: Array, _lines: Array): hud.consume_all(evs))
	hud.hub.model(0).ai = false
	if touch:
		hud.touch_state_fn = host.touch.display_state
		hud.set_option("touch_ui", true)
		hud.set_option("touch_preset", "touch-full")
	var out: Array = []
	for i in range(ticks):
		host.tick(1280.0, 720.0)
		UiSimBridge.patch(hud, host.S, host.hub)
		hud.advance(1.0 / 60.0)
		if mid.is_valid():
			mid.call(host, hud, i)
		out.append(_digest(hud))
		if i % 4 == 0:
			await process_frame
	hud.queue_free()
	await process_frame
	return out


func _first_diff(a: Array, b: Array) -> int:
	for i in range(mini(a.size(), b.size())):
		if a[i] != b[i]:
			return i
	return -1 if a.size() == b.size() else mini(a.size(), b.size())


func _run() -> void:
	var ticks: int = 900
	var dump: String = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--dump="):
			dump = a.substr(7)
	for gen in [1, 2]:
		for touch in [false, true]:
			var off: Array = await _play(false, gen, touch, ticks)
			if gen == 1 and not touch:
				var again: Array = await _play(false, gen, touch, ticks)
				_ok(_first_diff(off, again) == -1, "the digest is repeatable: the same run twice, savings off, is the same on every frame")
				# Negative controls: the digest does see a changed field, a changed layer and a changed toll.
				var nudged: Array = await _play(false, gen, touch, 200, func(_h, hud: UiHud, i: int): if i == 150: hud.hub.models[1].tier = 3)
				_ok(_first_diff(off.slice(0, 200), nudged) == 150, "the digest sees a fighter's field change on the frame it changes (frame %d)" % _first_diff(off.slice(0, 200), nudged))
				var toll_n: Array = await _play(false, gen, touch, 200, func(_h, hud: UiHud, i: int): if i == 120: hud.hub.toll["craters"] = 99)
				_ok(_first_diff(off.slice(0, 200), toll_n) == 120, "the digest sees the toll change (frame %d)" % _first_diff(off.slice(0, 200), toll_n))
			var on: Array = await _play(true, gen, touch, ticks)
			if dump != "":
				var lines := PackedStringArray()
				for i in range(on.size()):
					lines.append("%d %s %d %s" % [gen, str(touch), i, on[i]])
				var fa := FileAccess.open(dump, FileAccess.READ_WRITE if FileAccess.file_exists(dump) else FileAccess.WRITE)
				fa.seek_end()
				fa.store_string("
".join(lines) + "
")
				fa.close()
			var d: int = _first_diff(off, on)
			_ok(d == -1 and off.size() == ticks, "gen %d touch %s: all %d frames draw the same with the savings on (first difference: %d)" % [gen, str(touch), ticks, d])
	# A building brought down without the sim's count of losses moving (the campaign's wear, a planet turn): the strip's mark is there within a quarter second and not before it is asked for.
	UiFast.on = true
	var host := SimHost.new()
	host.new_match(4)
	var S: SimState = host.S
	var before: int = (UiSimBridge.strip_data(S, 0.0, 1600.0)["dead"] as Array).size()
	S.buildings[0].alive = false
	var got: int = (UiSimBridge.strip_data(S, 0.0, 1600.0)["dead"] as Array).size()
	var t0: int = Time.get_ticks_msec()
	while got == before and Time.get_ticks_msec() - t0 < 1000:
		OS.delay_msec(20)
		got = (UiSimBridge.strip_data(S, 0.0, 1600.0)["dead"] as Array).size()
	_ok(got == before + 1 and Time.get_ticks_msec() - t0 <= 600, "a building that falls without a counted loss reaches the strip within a quarter second (%d ms)" % (Time.get_ticks_msec() - t0))
	S.world.structuresLost += 1.0
	S.buildings[1].alive = false
	_ok((UiSimBridge.strip_data(S, 0.0, 1600.0)["dead"] as Array).size() == before + 2, "a counted loss reaches the strip at once")
	UiFast.on = false
	_ok((UiSimBridge.strip_data(S, 0.0, 1600.0)["dead"] as Array).size() == before + 2, "with the savings off the strip reads the buildings every call, as before")
	# display_text answers the same with the memo.
	UiFast.on = false
	var texts: Array = ["K.O.  PROTAGONIST WINS", "RIVAL", "protagonist.sig", "PROTAGONIST.SIG lands", "no names here", "", "the rival smiles"]
	var plain: Array = texts.map(func(t): return UiData.display_text(t))
	UiFast.on = true
	var memo1: Array = texts.map(func(t): return UiData.display_text(t))
	var memo2: Array = texts.map(func(t): return UiData.display_text(t))
	_ok(plain == memo1 and plain == memo2, "display_text answers the same from the memo (%s)" % str(plain))
	UiFast.on = true
	print("frame_cost_check: %d checks, %d failed" % [checks, fails])
	quit(1 if fails > 0 else 0)
