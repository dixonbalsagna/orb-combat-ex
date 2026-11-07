extends SceneTree
## What the signature costs in ki (the card says 45): the fighter's ki every 4 ticks from the press, RT + B against doing nothing, same seed, a standing rival.
##   godot --headless --path . --script res://sim/input/tools/ki_probe.gd


func _init() -> void:
	SimInputData.load_and_apply()
	SimInputData.clear_overrides()
	var a: Array = _run(true)
	var b: Array = _run(false)
	print("tick: ki with RT + B | ki doing nothing | difference")
	for k in range(a.size()):
		print("%3d: %6.1f | %6.1f | %6.1f" % [k * 4, a[k], b[k], a[k] - b[k]])
	var cost: float = 0.0
	for k in range(a.size()):
		cost = minf(cost, a[k] - b[k])
	print("deepest difference (the cost, net of what regeneration gives either way): %.1f; ki before the press %.1f" % [cost, a[0]])
	quit(0)


func _run(press: bool) -> Array:
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
	var f = S.fighters[0]
	var o = S.fighters[1]
	o.x = SimWrap.wrap(f.x + 800.0)
	o.y = f.y
	var quiet := SimIntent.new()
	for t in range(30):
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
	f.ki = 100.0   # full
	var out: Array = []
	for t in range(100):
		if press and t == 0:
			hub.pad_trigger(7, "rt", 1.0)
		if press and t == 6:
			hub.pad_button(7, "east", true)
		if press and t == 9:
			hub.pad_button(7, "east", false)
		SimCore.step(S, [hub.intent(0), quiet])
		hub.consumed()
		if t % 4 == 0:
			out.append(float(f.ki))
		S.out.fx.clear()
	SimCore.dispose(S)
	return out
