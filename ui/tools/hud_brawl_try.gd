extends SceneTree
## Tries the HUD against the real brawl's cues (docs/director/brawl-c2.md section 7): plays AI against AI through the real sim host with the three_strengths flag on (in this
## process only), feeds every event to the HUD the way the game does, and reports which cue kinds arrived, which the hub reads, and what the models and widgets did with them.
## Run: godot --headless --path . --script res://ui/tools/hud_brawl_try.gd [-- --seeds=12345,4 --ticks=3600]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var seeds: Array = [12345, 4]
	var ticks := 3600
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = []
			for s in a.substr(8).split(","):
				seeds.append(int(s))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	UiData.set_feature("three_strengths", true)
	var total_cues := {}
	var read := {}
	var hud_seen := {"windup_on_ticks": 0, "windup_starts": 0, "ends": {1: 0, 2: 0, 3: 0, 4: 0}, "launcher_open_ticks": 0, "acks": {}, "charge_dur_values": {},
		"launcher_known_ticks": 0, "launcher_ready_ticks": 0, "launcher_rest_ticks": 0, "weights": {}}
	for seed in seeds:
		var host := SimHost.new()
		host.new_match(seed)
		var hud: UiHud = load("res://ui/hud/ui_hud.tscn").instantiate()
		hud.size = Vector2(1280, 720)
		root.add_child(hud)
		await process_frame
		var f: Array = UiSimBridge.fighters(host.S)
		hud.setup(f[0], f[1])
		var evs_by_kind := {}
		host.drained.connect(func(evs: Array, _lines: Array):
			for e in evs:
				if e.type == "cue":
					var k: String = str(e.kind) + (":" + str(e.text) if str(e.text) != "" else "")
					evs_by_kind[k] = int(evs_by_kind.get(k, 0)) + 1
					if str(e.kind) == "windup" and str(e.text) == "start":
						var dd: String = str(snappedf(float(e.get("dur") if "dur" in e else 0.0), 0.01))
						(hud_seen["charge_dur_values"] as Dictionary)[dd] = int((hud_seen["charge_dur_values"] as Dictionary).get(dd, 0)) + 1
						hud_seen["windup_starts"] += 1
					if str(e.kind) == "windup" and str(e.text) == "end":
						var kk: int = int(e.get("k") if "k" in e else 0)
						if hud_seen["ends"].has(kk):
							hud_seen["ends"][kk] += 1
			hud.consume_all(evs))
		for i in range(ticks):
			host.tick(1280.0, 720.0)
			UiSimBridge.patch(hud, host.S)
			UiSimBridge.feed(hud, host.feed.slice(maxi(0, host.feed.size() - 1)))
			hud.hub.model(0).ai = false   # the HUD's own reading of "my fighter"
			hud.advance(1.0 / 60.0)
			for m in hud.hub.models:
				if m.charge_on:
					hud_seen["windup_on_ticks"] += 1
				if m.launcher_open:
					hud_seen["launcher_open_ticks"] += 1
				if m.launcher_known:
					hud_seen["launcher_known_ticks"] += 1
					if m.launcher_ready:
						hud_seen["launcher_ready_ticks"] += 1
					else:
						hud_seen["launcher_rest_ticks"] += 1
				if m.press_ack_kind != "" and m.press_ack_t == 0.0:
					hud_seen["acks"][m.press_ack_kind] = int(hud_seen["acks"].get(m.press_ack_kind, 0)) + 1
				hud_seen["weights"][m.weight] = int(hud_seen["weights"].get(m.weight, 0)) + 1
		for k in evs_by_kind:
			total_cues[k] = int(total_cues.get(k, 0)) + int(evs_by_kind[k])
		for k in hud.hub.stats:
			if str(k).begins_with("cue_unread_"):
				read[k] = int(read.get(k, 0)) + int(hud.hub.stats[k])
		hud.queue_free()
		await process_frame
	print("BRAWL TRY seeds ", seeds, " ticks ", ticks)
	print("cue kinds that arrived (count): ", total_cues)
	print("cue kinds the hub counted as unread: ", read)
	print("what the models did: ", hud_seen)
	quit(0)
