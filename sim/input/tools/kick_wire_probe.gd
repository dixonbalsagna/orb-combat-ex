extends SceneTree
## Is the pad wired to the instant takeoff (the kick, sim/core/kick.gd)? The real hub into SimCore with the kick on (setup "kick": true) and off: LT held with the stick
## pushed from a standstill, and the same with a short LT tap, and a stick flip at speed. Prints his speed as a share of top speed, tick by tick.
##   godot --headless --path . --script res://sim/input/tools/kick_wire_probe.gd
## `dash` in the intent is what the kick reads (flat-out flight): the layout writes it for a dodge press's lunge and for a sprint held past holdStart.


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	for kick in [false, true]:
		print("######## kick = %s ########" % str(kick))
		print("LT held, stick right, from a standstill:")
		print("   " + _run(kick, "hold"))
		print("LT tapped (3 ticks), stick right held:")
		print("   " + _run(kick, "tap"))
		print("stick right held, no LT:")
		print("   " + _run(kick, "stick"))
		print("LT held, stick right, then flipped left at tick 20:")
		print("   " + _run(kick, "flip"))
	quit(0)


func _run(kick: bool, mode: String) -> String:
	var hub := SimInputHub.new()
	hub.set_humans(true, false)
	hub.pad_button(7, "south", true)
	hub.pad_button(7, "south", false)
	hub.take_joins()
	hub.set_humans(true, false)
	var su: Dictionary = hub.setup()
	su["intro"] = false
	su["kick"] = kick
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	b.x = SimWrap.wrap(a.x + 6000.0)
	var quiet := SimIntent.new()
	for t in range(40):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		S.out.fx.clear()
	var top: float = 1.0
	var line: String = ""
	var dash_line: String = ""
	var sp_ref: float = 0.0
	for t in range(40):
		if t == 0:
			hub.pad_stick(7, 1.0, 0.0)
			if mode != "stick":
				hub.pad_trigger(7, "lt", 1.0)
		if mode == "tap" and t == 3:
			hub.pad_trigger(7, "lt", 0.0)
		if mode == "flip" and t == 20:
			hub.pad_stick(7, -1.0, 0.0)
		var i: SimIntent = hub.intent(0)
		SimCore.step(S, [i, quiet])
		hub.consumed()
		var v: float = SimDetMath.hypot(a.vx, a.vy)
		sp_ref = maxf(sp_ref, v)
		if t < 14 or t % 4 == 0:
			line += "%d " % int(round(v))
			dash_line += ("D" if i.dash else ".")
		S.out.fx.clear()
	SimCore.dispose(S)
	return "speed by tick (first 14, then every 4th): %s  | dash flag: %s  | peak %d" % [line, dash_line, int(sp_ref)]
