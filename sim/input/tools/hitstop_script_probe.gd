extends SceneTree
## Replays docs/controls/clips/hitstop-ab.json (the hit-stop A/B clip's input script) through the real hub, with hit-stop off and on, on the same seed, a standing opponent 80 units away.
## Prints, per segment of the script, the ticks the sim held, the damage dealt and the opponent's HP at its end, so the capture can be checked against the sim and the script
## shown to land. Needs the right-hand switches (set in memory).
##   godot --headless --path . --script res://sim/input/tools/hitstop_script_probe.gd


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var sw: Dictionary = SimInputData.timing.get("switches", {})
	sw["rightStick"] = true
	sw["quickRead"] = true
	SimInputData.timing["switches"] = sw
	SimInputData.clear_overrides()
	SimInputData.invalidate()
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://docs/controls/clips/hitstop-ab.json"))
	if not (j is Dictionary):
		print("script not found")
		quit(1)
		return
	for on in [false, true]:
		print("######## hit-stop %s ########" % ("ON" if on else "off"))
		_play(j, on)
	quit(0)


func _play(j: Dictionary, hitstop: bool) -> void:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	su["hitstop"] = hitstop
	var S := SimCore.createSim()
	SimCore.newMatch(S, int(j.scene.seed), {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	b.x = SimWrap.wrap(a.x + float(j.scene.distanceUnits))
	b.y = a.y
	var quiet := SimIntent.new()
	for t in range(30):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	var segs: Array = j.segments
	var seg_i: int = 0
	var ev: Array = j.events
	var hp0: float = float(b.hp)
	var seg_hp: float = hp0
	var held_seg: int = 0
	var held_all: int = 0
	var tick: int = 0
	var total: int = int(j.scene.ticks)
	while tick < total:
		# one script tick per sim tick the page steps, held or not
		for e in ev:
			if int(e[0]) == tick:
				match str(e[1]):
					"b":
						hub.pad_button(7, str(e[2]), bool(e[3]))
					"t":
						hub.pad_trigger(7, str(e[2]), float(e[3]))
					"rs":
						hub.pad_stick_right(7, float(e[2]), float(e[3]))
					"ls":
						hub.pad_stick(7, float(e[2]), float(e[3]))
		var live: bool = SimCore.step(S, [hub.intent(0), quiet])
		if live:
			hub.consumed()
		else:
			held_seg += 1
			held_all += 1
		hub.take_haptics()
		S.out.fx.clear()
		tick += 1
		var end_seg: bool = (seg_i + 1 < segs.size() and tick == int(segs[seg_i + 1].from)) or tick == total
		if end_seg:
			print("  %-26s ticks %3d-%3d  held %3d  damage %6.1f  opponent HP %6.1f" % [segs[seg_i].name, int(segs[seg_i].from), tick, held_seg, seg_hp - float(b.hp), float(b.hp)])
			seg_hp = float(b.hp)
			held_seg = 0
			seg_i += 1
	print("  total held %d of %d ticks (%.0f%%), opponent HP %.0f of %.0f" % [held_all, total, 100.0 * float(held_all) / float(total), float(b.hp), hp0])
	SimCore.dispose(S)
