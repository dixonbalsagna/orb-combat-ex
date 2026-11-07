extends SceneTree
## The old-PC kit's native half (Performance and Platform, 2026-11-01). Plays whole AI-vs-AI matches headless on this processor and writes ONE json file:
##   - the time of every sim tick (percentiles, ticks over 16 and 33 ms, the worst ten), the match build, and a fixed float64 job, so two PCs can be set side by side;
##   - the sim's gameplay hash every --every ticks and at the end (SimHash.stateHash), so a second PC's file can be compared with the first (compare-results.mjs):
##     the same seed on two different processors must give the same hashes, tick for tick. This is the two-processor look; Netcode's own check replaces or adds to it when it parks.
## Writes nothing but --out and Godot's own user folder; opens no socket.
##   godot --headless --path <kit project> --script res://oldpc_sim.gd -- --out=<file> [--ticks=7200] [--every=120] [--cases=7:77,12:5,21:77] [--reps=2]
## A case is planet:seed. rep 0 is the first match in the process, rep 1 the rematch (the second newMatch in one process builds the contact table late: see docs/perf/hitch-table-2026-10-31.md).

var outp: String = "oldpc-sim-result.json"
var ticks: int = 7200
var every: int = 120
var reps: int = 2
var cases: Array = [[7, 77], [12, 5], [21, 77]]
var fights: int = 1   # --fights=2: two fights on one line with hits across and blows from outside (the co-op 2v2 sim, four AI bodies); ticks are timed for BOTH fights


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			outp = a.substr(6)
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
		elif a.begins_with("--fights="):
			fights = 2 if int(a.substr(9)) == 2 else 1
		elif a.begins_with("--every="):
			every = maxi(1, int(a.substr(8)))
		elif a.begins_with("--reps="):
			reps = maxi(1, int(a.substr(7)))
		elif a.begins_with("--cases="):
			cases = []
			for c in a.substr(8).split(","):
				var pr: PackedStringArray = c.split(":")
				if pr.size() == 2:
					cases.append([int(pr[0]), int(pr[1])])
	var t0: int = Time.get_ticks_usec()
	var out := {"kit": "oldpc_sim", "when": Time.get_datetime_string_from_system(false, true), "godot": Engine.get_version_info().string, "os": OS.get_name(),
		"cpu": OS.get_processor_name(), "threads": OS.get_processor_count(), "ticks": ticks, "every": every, "fights": fights, "cases": []}
	print("Orb Combat EX old-PC kit, native half   %s   %s, %d threads   %d cases x %d matches x %d ticks" % [out.godot, out.cpu, out.threads, cases.size(), reps, ticks])
	out["job_ms"] = _job()
	print("  fixed float64 job: %.0f ms" % out.job_ms)
	for c in cases:
		var rows: Array = []
		for rep in range(reps):
			rows.append(_play(int(c[0]), int(c[1]), rep))
		out.cases.append({"planet": c[0], "seed": c[1], "matches": rows})
	out["total_s"] = snappedf(float(Time.get_ticks_usec() - t0) / 1e6, 0.1)
	var f := FileAccess.open(outp, FileAccess.WRITE)
	if f == null:
		printerr("could not write ", outp)
		quit(1)
		return
	f.store_string(JSON.stringify(out, "\t"))
	f.close()
	print("wrote ", outp.get_file())
	quit(0)


## A fixed amount of float64 arithmetic (the same on every PC), timed: one number to set the processors side by side beside the game's own ticks.
func _job() -> float:
	var a: int = Time.get_ticks_usec()
	var x: float = 0.5
	var y: float = 0.25
	for i in range(6000000):
		x = x * 1.0000001 + y * 0.9999999 - 0.0000001
		y = y * 0.9999999 + x * 0.0000001
	var ms: float = float(Time.get_ticks_usec() - a) / 1000.0
	return snappedf(ms + (0.0 if x > -1e30 else 1.0), 1.0)   # x is read so the loop is not dropped


func _play(planet: int, seed_: int, rep: int) -> Dictionary:
	var S := SimCore.createSim()
	var setup := {"planet": planet, "touch": 1, "planetGen": 3, "intro": false}
	var ai := {"p1": true, "p2": true}
	if fights == 2:
		setup["fights"] = 2
		setup["cross"] = true
		setup["outside"] = true
		ai = {"p1": true, "p2": true, "p3": true, "p4": true}
	var a: int = Time.get_ticks_usec()
	SimCore.newMatch(S, seed_, ai, setup)
	var new_ms: float = float(Time.get_ticks_usec() - a) / 1000.0
	a = Time.get_ticks_usec()
	if SimField._F != null:
		WorldField.bakeStep(SimField._F, 1 << 40)
	var bake_ms: float = float(Time.get_ticks_usec() - a) / 1000.0
	var us: Array = []
	var hashes: Array = []
	for t in range(ticks):
		var b: int = Time.get_ticks_usec()
		SimCore.step(S)
		us.append(Time.get_ticks_usec() - b)
		S.out.fx.clear()
		S.out.feed.clear()
		if (t + 1) % every == 0:
			hashes.append(String(SimHash.stateHash(S).gameplay))
	var fin: String = String(SimHash.stateHash(S).gameplay)
	var s: Array = us.duplicate()
	s.sort()
	var n: int = s.size()
	var over16: int = 0
	var over33: int = 0
	for v in us:
		if v > 16000:
			over16 += 1
		if v > 33000:
			over33 += 1
	var worst: Array = []
	for i in range(mini(10, n)):
		var u: int = int(s[n - 1 - i])
		worst.append({"us": u, "tick": us.find(u)})
	var sum: float = 0.0
	for v in us:
		sum += float(v)
	var end: String = "tick %d, x %.3f / %.3f, hp %.3f / %.3f" % [S.tick, S.fighters[0].x, S.fighters[1].x, S.fighters[0].hp, S.fighters[1].hp]
	SimCore.dispose(S)
	print("  planet %d seed %d %s: new %.0f ms, bake %.0f ms, tick mean %.2f p50 %.2f p99 %.2f max %.1f ms, over 16 ms: %d   final %s" % [planet, seed_,
		"first" if rep == 0 else "rematch", new_ms, bake_ms, sum / float(n) / 1000.0, float(s[n / 2]) / 1000.0, float(s[int(n * 0.99)]) / 1000.0, float(s[n - 1]) / 1000.0, over16, fin.substr(0, 12)])
	return {"rep": rep, "new_ms": snappedf(new_ms, 0.1), "bake_ms": snappedf(bake_ms, 0.1), "mean_us": snappedf(sum / float(n), 0.1), "p50_us": s[n / 2], "p95_us": s[int(n * 0.95)],
		"p99_us": s[int(n * 0.99)], "max_us": s[n - 1], "over16ms": over16, "over33ms": over33, "worst": worst, "end": end, "final": fin, "hashes": hashes}
