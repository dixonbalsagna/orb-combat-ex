extends SceneTree
# The planet job's calls (WorldPlanet.PlanetJob.step) timed one by one with what each was doing: the grid's cells, the carry that ends the grid, the flow field's steps, the places' steps.
#   godot --headless --path . --script res://sim/world/tools/job_prof.gd [-- --budget=200 --rivers --b]
func _init() -> void:
	var budget: int = 200
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--budget="):
			budget = int(a.substr(9))
	WorldClimate.useGen(2)
	WorldRivers.setOn("--rivers" in OS.get_cmdline_user_args())
	WorldLand.setB("--b" in OS.get_cmdline_user_args())
	WorldPlanet.forget()
	var t0: int = Time.get_ticks_usec()
	var job: WorldPlanet.PlanetJob = WorldPlanet.makeJob(7)
	print("makeJob (the places' start): ", float(Time.get_ticks_usec() - t0) / 1000.0, " ms")
	var rows: Array = []
	var total: float = 0.0
	while not job.done and rows.size() < 100000:
		var what: String = "grid" if job._grid != null else ("flow" if job.get("_flow") != null else "places")
		var t1: int = Time.get_ticks_usec()
		job.step(budget)
		var dt: float = float(Time.get_ticks_usec() - t1) / 1000.0
		total += dt
		rows.append([dt, what, rows.size()])
	rows.sort_custom(func(a, b): return a[0] > b[0])
	var top: String = ""
	for q in range(mini(6, rows.size())):
		top += " %.1f ms (%s call %d)," % [rows[q][0], rows[q][1], rows[q][2]]
	print(rows.size(), " calls of budget ", budget, ", ", total, " ms in all; the six longest:", top)
	var by: Dictionary = {}
	for r in rows:
		by[r[1]] = by.get(r[1], 0.0) + r[0]
	print("by what: ", by)
	quit()
