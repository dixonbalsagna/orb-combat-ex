extends SceneTree
## Finds the frames where the HUD's own work is long. Plays AI against AI through the real sim host (one tick a frame, as the game does) with moving anchors, and times, for each tick, the bridge's patch,
## the feed, UiHud.advance and the drawing of the layers (the engine's idle frame, headless: GDScript time, no GPU). Prints the median, the worst frames and, for each, what the HUD was doing: which
## layers redrew on it and the sizes of the model's queues. Headless: no window. Run: godot --headless --path . --script res://ui/tools/hud_hitch.gd [-- --seed=4 --ticks=2200 --top=8]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var seed: int = 4
	var ticks: int = 2200
	var top: int = 8
	var around: int = -1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed = int(a.substr(7))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--top="):
			top = int(a.substr(6))
		elif a.begins_with("--around="):
			around = int(a.substr(9))
	var host := SimHost.new()
	host.new_match(seed)
	root.size = Vector2i(1280, 720)
	var hud: UiHud = load("res://ui/hud/ui_hud.tscn").instantiate()
	hud.size = Vector2(1280, 720)
	root.add_child(hud)
	await process_frame
	var f: Array = UiSimBridge.fighters(host.S)
	hud.setup(f[0], f[1])
	var vp: Vector2 = hud.layout.vp
	hud.anchor_fn = func(slot: int) -> Dictionary:
		var fi = host.S.fighters[slot]
		var mid: float = float(host.S.fighters[0].x) + SimWrap.sdx(float(host.S.fighters[0].x), float(host.S.fighters[1].x)) * 0.5
		var dx: float = SimWrap.sdx(mid, float(fi.x))
		return {"pos": Vector2(vp.x * 0.5 + dx * 0.35, vp.y * 0.62 - float(fi.y) * 0.35), "h": vp.y * 0.11, "visible": true}
	var consume_us := [0]
	var kinds := [""]
	host.drained.connect(func(evs: Array, _lines: Array):
		var c0: int = Time.get_ticks_usec()
		hud.consume_all(evs)
		consume_us[0] += Time.get_ticks_usec() - c0
		var ks := PackedStringArray()
		for e in evs:
			ks.append(str(e.type) + (":" + str(e.kind) if e.type == "cue" else ""))
		kinds[0] = ", ".join(ks))
	var layers: Array = []
	for l in hud._all_layers():
		if l != null:
			layers.append(l)
	var last_red: Dictionary = {}
	for l in layers:
		last_red[l] = l.redraws
	var rows: Array = []
	for i in range(ticks):
		consume_us[0] = 0
		kinds[0] = ""
		host.tick(1280.0, 720.0)
		var cons: int = consume_us[0]
		var evk: String = kinds[0]
		var t0: int = Time.get_ticks_usec()
		UiSimBridge.patch(hud, host.S)
		var t1: int = Time.get_ticks_usec()
		UiSimBridge.feed(hud, host.feed.slice(maxi(0, host.feed.size() - 1)))
		hud.hub.model(0).ai = false
		var t2: int = Time.get_ticks_usec()
		hud.advance(1.0 / 60.0)
		var t3: int = Time.get_ticks_usec()
		await process_frame
		var t4: int = Time.get_ticks_usec()
		var redrew := PackedStringArray()
		for l in layers:
			if l.redraws != last_red[l]:
				redrew.append(str(l.painter.get_method()) + (str(l.painter.get_bound_arguments()) if l.painter.get_bound_arguments_count() > 0 else ""))
				last_red[l] = l.redraws
		rows.append({"tick": i, "patch": t1 - t0, "feed": t2 - t1, "advance": t3 - t2, "draw": t4 - t3, "consume": cons, "events": evk, "total": (t1 - t0) + (t2 - t1) + (t3 - t2) + cons, "redrew": redrew,
			"cards": hud.hub.cards.size() if "cards" in hud.hub else -1, "feed_lines": hud.hub.feed.size()})
	var totals: Array = rows.map(func(r): return int(r["total"]))
	totals.sort()
	print("seed %d, %d ticks: HUD script time (patch + feed + advance) median %.2f ms, p99 %.2f ms" % [seed, ticks, float(totals[totals.size() / 2]) / 1000.0, float(totals[int(float(totals.size()) * 0.99)]) / 1000.0])
	rows.sort_custom(func(a, b): return int(a["total"]) > int(b["total"]))
	for k in range(mini(top, rows.size())):
		var r: Dictionary = rows[k]
		print("  tick %4d: total %6.2f ms (consume %5.2f, patch %5.2f, feed %5.2f, advance %5.2f; draw %5.2f)  redrew: %s  events: %s" % [r["tick"], float(r["total"]) / 1000.0, float(r["consume"]) / 1000.0, float(r["patch"]) / 1000.0, float(r["feed"]) / 1000.0, float(r["advance"]) / 1000.0, float(r["draw"]) / 1000.0, ", ".join(r["redrew"]), str(r["events"]).substr(0, 140)])
	if around >= 0:
		rows.sort_custom(func(a, b): return int(a["tick"]) < int(b["tick"]))
		for k in range(maxi(around - 4, 0), mini(around + 5, rows.size())):
			var r2: Dictionary = rows[k]
			print("  around tick %4d: total %6.2f ms (consume %5.2f, patch %5.2f, feed %5.2f, advance %5.2f) events: %s" % [r2["tick"], float(r2["total"]) / 1000.0, float(r2["consume"]) / 1000.0, float(r2["patch"]) / 1000.0, float(r2["feed"]) / 1000.0, float(r2["advance"]) / 1000.0, str(r2["events"]).substr(0, 90)])
	# What a redraw costs: the mean idle-frame time (the layers' drawing, headless) on frames where a plate redrew, where something else did, and where nothing did.
	var buckets := {"a plate redrew": [0, 0.0], "another layer redrew": [0, 0.0], "nothing redrew": [0, 0.0]}
	for r in rows:
		var key: String = "nothing redrew"
		var rs: PackedStringArray = r["redrew"]
		if not rs.is_empty():
			key = "another layer redrew"
			for x in rs:
				if x.begins_with("_paint_plate"):
					key = "a plate redrew"
		buckets[key][0] += 1
		buckets[key][1] += float(r["draw"]) / 1000.0
	print("mean drawing time of a frame (idle frame, headless; noisy on a busy PC):")
	for k in buckets:
		var bk: Array = buckets[k]
		print("  %-22s %5d frames  %.2f ms" % [k, int(bk[0]), (float(bk[1]) / float(maxi(int(bk[0]), 1)))])
	hud.queue_free()
	quit()
