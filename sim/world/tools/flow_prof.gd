extends SceneTree
# What the flow field's cells cost by phase (setup, seeds, flood, drainage, runoff): Flow.step in small calls, the time and the cells spent by the phase the call began in.
#   godot --headless --path . --script res://sim/world/tools/flow_prof.gd
func _init() -> void:
	WorldClimate.useGen(2)
	WorldPlanet.forget()
	var P := WorldPlanet.make(13)
	var F := WorldRivers.Flow.new(P.grid, false)
	var us: Dictionary = {}
	var cells: Dictionary = {}
	var worst: Dictionary = {}
	while not F.done:
		var ph: int = F._ph
		var s0: int = F.spent
		var t0: int = Time.get_ticks_usec()
		F.step(200)
		var d: float = float(Time.get_ticks_usec() - t0)
		us[ph] = us.get(ph, 0.0) + d
		cells[ph] = cells.get(ph, 0) + F.spent - s0
		worst[ph] = maxf(worst.get(ph, 0.0), d)
	for ph in us.keys():
		print("phase ", ph, ": ", cells[ph], " cells, ", snappedf(us[ph] / 1000.0, 0.1), " ms = ", snappedf(us[ph] / float(maxi(1, cells[ph])), 0.01), " us a cell, worst call ", snappedf(worst[ph] / 1000.0, 0.1), " ms")
	quit()
