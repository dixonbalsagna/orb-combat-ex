extends SceneTree
## GD's map row 42 ("a far press follows him"), played through the real hub: send the rival with a heavy launch, then tap X / Y / B while he is far, at 0.3 s, 1 s, 2 s and
## 3 s after the send; and the same far tap with no send before it. Prints the distance, the events the presser made (taunt, rush, lunge) and whether he closed.
##   godot --headless --path . --script res://sim/input/tools/row42_probe.gd


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	print("== ROW 42: a far tap after a send ==")
	for btn in ["west", "north", "east"]:
		print("-- button %s" % btn)
		print("   no send, rival placed 3000 units away: " + _case(btn, -1, 3000.0))
		for after in [18, 60, 120, 180]:
			print("   after a send (rival then 3000 away), tap %3d ticks after the launch: %s" % [after, _case(btn, after, 0.0)])
	quit(0)


func _case(btn: String, after: int, far: float) -> String:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	var quiet := SimIntent.new()
	b.x = SimWrap.wrap(a.x + (far if far > 0.0 else 80.0))
	b.y = a.y
	for t in range(30):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	var send_tick: int = -1
	if after >= 0:
		# a heavy launch: B held (the launcher), then released
		hub.pad_button(7, "east", true)
		for t in range(40):
			SimCore.step(S, [hub.intent(0), quiet])
			hub.consumed()
			for e in S.out.fx:
				if (String(e.type) == "launch" or String(e.kind) == "launch") and send_tick < 0:
					send_tick = t
			S.out.fx.clear()
		hub.pad_button(7, "east", false)
		for t in range(after + 30):
			SimCore.step(S, [hub.intent(0), quiet])
			hub.consumed()
			S.out.fx.clear()
	if after >= 0:
		b.x = SimWrap.wrap(a.x + 3000.0)   # a stand-in for a far send: the rival is far, after a launch the presser threw
		b.y = a.y
		b.vx = 0.0
		b.vy = 0.0
	var d0: float = absf(SimWrap.sdx(a.x, b.x))
	var names: Dictionary = {}
	var x0: float = a.x
	hub.pad_button(7, btn, true)
	var closed: float = 0.0
	for t in range(60):
		if t == 3:
			hub.pad_button(7, btn, false)
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		for e in S.out.fx:
			var nm: String = String(e.kind) if String(e.type) == "cue" else String(e.type)
			if nm != "press_ack" and int(e.actor) == 0:
				names[nm] = true
		S.out.fx.clear()
	var d1: float = absf(SimWrap.sdx(a.x, b.x))
	var ev: Array = names.keys()
	ev.sort()
	SimCore.dispose(S)
	return "gap %6.0f -> %6.0f  flew %+6.0f  ev %s" % [d0, d1, SimWrap.sdx(x0, a.x), ",".join(ev)]
