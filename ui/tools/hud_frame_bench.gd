extends SceneTree
## The HUD's per-frame cost (the brief of 2026-10-27: UiSimBridge.patch and UiHud.advance on a phone). Plays AI against AI through the real sim host, one tick a frame, with the game's own hookups
## (anchors, planet strip), and times, per frame, the bridge's patch and UiHud.advance, plus (a second, uncounted call on the same frame) the pieces of advance: the hub's advance and the layers' update.
## Headless GDScript time, no GPU; the median and the mean in microseconds. Run: godot --headless --path . --script res://ui/tools/hud_frame_bench.gd [-- --seed=4 --ticks=1500 --gen=2 --fast=1]
## `--fast=0` plays the cost the HUD had before UiFast (the bench's switch).

func _initialize() -> void:
	_run.call_deferred()


func _med(a: Array) -> float:
	var b: Array = a.duplicate()
	b.sort()
	return float(b[b.size() / 2])


func _mean(a: Array) -> float:
	var s := 0.0
	for x in a:
		s += float(x)
	return s / maxf(float(a.size()), 1.0)


func _run() -> void:
	var seed: int = 4
	var ticks: int = 1500
	var gen: int = 1
	var fast: bool = true
	var touch: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			seed = int(a.substr(7))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--gen="):
			gen = int(a.substr(6))
		elif a.begins_with("--fast="):
			fast = int(a.substr(7)) != 0
		elif a.begins_with("--touch="):
			touch = int(a.substr(8)) != 0
	UiFast.on = fast
	var host := SimHost.new()
	if gen == 2:
		WorldClimate.useGen(2)
		host.new_match(seed, {"p1": true, "p2": true}, {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}, "planetGen": 2, "intro": false})
	else:
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
	hud.strip_fn = func() -> Dictionary:
		return UiSimBridge.strip_data(host.S, float(host.S.fighters[0].x), 1600.0)
	host.drained.connect(func(evs: Array, _lines: Array): hud.consume_all(evs))
	hud.hub.model(0).ai = false
	if touch:
		hud.touch_state_fn = host.touch.display_state
		hud.set_option("touch_ui", true)
		hud.set_option("touch_preset", "touch-full")
	var p_us: Array = []
	var a_us: Array = []
	var h_us: Array = []
	var u_us: Array = []
	var warm: int = 200
	for i in range(ticks):
		host.tick(1280.0, 720.0)
		var t0: int = Time.get_ticks_usec()
		UiSimBridge.patch(hud, host.S)
		var t1: int = Time.get_ticks_usec()
		UiSimBridge.feed(hud, host.feed.slice(maxi(0, host.feed.size() - 1)))
		var t2: int = Time.get_ticks_usec()
		hud.advance(1.0 / 60.0)
		var t3: int = Time.get_ticks_usec()
		hud.hub.advance(0.0)
		var t4: int = Time.get_ticks_usec()
		hud._update_layers()
		var t5: int = Time.get_ticks_usec()
		if i >= warm:
			p_us.append(t1 - t0)
			a_us.append(t3 - t2)
			h_us.append(t4 - t3)
			u_us.append(t5 - t4)
		await process_frame
	print("hud_frame_bench: touch %s, touch controls %d, seed %d gen %d fast %s, %d frames (microseconds, median / mean)" % [str(touch), hud.layout.touch_ctrl.size(), seed, gen, str(fast), p_us.size()])
	print("  UiSimBridge.patch   %7.0f / %7.0f" % [_med(p_us), _mean(p_us)])
	print("  UiHud.advance       %7.0f / %7.0f" % [_med(a_us), _mean(a_us)])
	print("    hub.advance       %7.0f / %7.0f   (a second call with dt 0)" % [_med(h_us), _mean(h_us)])
	print("    _update_layers    %7.0f / %7.0f   (a second call)" % [_med(u_us), _mean(u_us)])
	print("  hash gameplay %s" % str(SimHash.stateHash(host.S).gameplay).substr(0, 16))
	hud.queue_free()
	quit()
