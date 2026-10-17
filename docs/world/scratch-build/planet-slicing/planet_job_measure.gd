extends SceneTree
# What the time-sliced load costs a frame. A host loop of 4 ms budgets is simulated: the module owns no clock; this tool does.
#   godot --headless --path . --script res://sim/world/tools/planet_job_measure.gd      (run at below-normal priority; a busy machine makes every number an upper bound)
func pct(a: Array, p: float) -> float:
	if a.is_empty():
		return 0.0
	a.sort()
	return float(a[mini(a.size() - 1, int(float(a.size()) * p))]) / 1000.0


func run(label: String, seed: int, touch: int, budgetUs: int) -> void:
	WorldPlanet.forget()
	var frames: int = 0
	var fr: Array = []
	var calls := [[], [], []]
	var t_all: int = Time.get_ticks_usec()
	var job: WorldPlanet.LoadJob = WorldPlanet.beginLoad(seed, touch)
	var firstCoarse: int = -1
	while not job.done and frames < 100000:
		var t0: int = Time.get_ticks_usec()
		var stage: int = job.stage
		while Time.get_ticks_usec() - t0 < budgetUs and not job.done:
			var c0: int = Time.get_ticks_usec()
			job.step(4)
			if stage < 3:
				calls[mini(stage, 2)].append(Time.get_ticks_usec() - c0)
		fr.append(Time.get_ticks_usec() - t0)
		frames += 1
		if firstCoarse < 0 and job.stage == 2 and job.sliceJob.phase == 1:
			firstCoarse = Time.get_ticks_usec() - t_all
	var total: float = 0.0
	for x in fr:
		total += x
	print("%s: %d frames at a %d us budget, %.0f ms of work; frame median %.1f ms, 99th %.1f ms, worst %.1f ms; coarse ground ready after %.0f ms" % [label, frames, budgetUs, total / 1000.0, pct(fr, 0.5), pct(fr, 0.99), pct(fr, 1.0), firstCoarse / 1000.0])
	print("      a 4-unit call: places median %.2f / 99th %.2f ms; pick %.2f / %.2f ms; ground %.2f / %.2f ms" % [pct(calls[0], 0.5), pct(calls[0], 0.99), pct(calls[1], 0.5), pct(calls[1], 0.99), pct(calls[2], 0.5), pct(calls[2], 0.99)])


func _init() -> void:
	run("planet 7, touch 3", 7, 3, 4000)
	run("planet 7, touch 9", 7, 9, 4000)
	run("planet 11, touch 2", 11, 2, 4000)
	# the whole call for comparison
	WorldPlanet.forget()
	var t0: int = Time.get_ticks_usec()
	var P := WorldPlanet.make(7)
	var t1: int = Time.get_ticks_usec()
	var pr := WorldPlanet.pick(P, 3)
	var t2: int = Time.get_ticks_usec()
	WorldPlanet.readSlice(P, pr.circle, pr.T)
	var t3: int = Time.get_ticks_usec()
	print("the whole calls: places %.0f ms, pick %.0f ms, slice %.0f ms" % [(t1 - t0) / 1000.0, (t2 - t1) / 1000.0, (t3 - t2) / 1000.0])
	quit()
