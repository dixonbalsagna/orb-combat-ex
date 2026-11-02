extends SceneTree
## Per-tick profile of a recorded match (Performance and Platform, 2026-11-01): Orb's first play, `replay` of homework/Files/orb-first-play-*.json (the black box's SimReplay dictionary).
## Re-runs the match headless with the very same SimCore.step and inputs, one tick at a time, and writes for every tick the sim's own time in microseconds, plus, for the ticks in the given windows, what happened
## (every fx type and feed tag of that tick, both fighters' hit points and positions). It also times SimHash.stateHash, the black box's checkpoint (one every 600 ticks), on its own.
## The match is only worth reading if it REPRODUCES: --verify checks every checkpoint and the final hash and prints MISMATCH at the first tick that differs (then the numbers are not Orb's match).
##   godot --headless --path <the stack tree that built the page> --script res://<this file> -- --replay=<replay.json> --out=<file.json> [--win=1562-1644,2751-2801] [--pad=30]
## --replay is the `replay` object alone (extract it with node first). Writes nothing but --out. Run it at below-normal priority and alone: its times are CPU times of this process.

func _init() -> void:
	var rp_path := ""
	var outp := ""
	var wins: Array = []
	var pad: int = 30
	var upto: int = 1 << 30
	var want_frames: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--replay="):
			rp_path = a.substr(9)
		elif a.begins_with("--out="):
			outp = a.substr(6)
		elif a == "--frames":
			want_frames = true
		elif a.begins_with("--upto="):
			upto = int(a.substr(7))
		elif a.begins_with("--pad="):
			pad = int(a.substr(6))
		elif a.begins_with("--win="):
			for w in a.substr(6).split(","):
				var p: PackedStringArray = w.split("-")
				if p.size() == 2:
					wins.append([int(p[0]) - pad, int(p[1]) + pad])
	var rp = JSON.parse_string(FileAccess.get_file_as_string(rp_path))
	if not (rp is Dictionary):
		printerr("replay_prof: not a replay dictionary: ", rp_path)
		quit(2)
		return
	var packed: Array = []
	for inp in rp.get("inputs", []):
		var p: int = SimReplay.join(inp[2], inp[3])
		var it = null
		if p != -1:
			it = SimIntent.unpack(p) if p >= 0 else null
			if it != null and inp.size() == 5:
				SimIntent.unpack2(int(inp[4]), it)
		packed.append(it)
	var data_now: String = SimReplay.dataHash(rp.get("setup", {}))
	print("replay_prof: data hash now ", data_now, " recorded ", rp.get("data", ""), "  ", "SAME" if data_now == rp.get("data", "") else "DIFFERENT (the tree is not the page's)")
	# the page's load bakes the planet's nodes before the first tick: do the same, or a far read computes its nodes on the spot (about 100 us a read where the page pays about 33) and cold reads are overstated
	WorldClimate.useGen(3)
	WorldField.bakeStep(WorldField.of(WorldPlanet.make(int(rp.get("setup", {}).get("planet", 7)))), 1 << 40)
	var S := SimCore.createSim()
	var t_new: int = Time.get_ticks_usec()
	SimCore.newMatch(S, int(rp.seed), rp.ai, rp.get("setup", {}))
	t_new = Time.get_ticks_usec() - t_new
	var cur: Array = []
	cur.resize(S.fighters.size())
	var checks := {}
	for c in rp.checkpoints:
		checks[int(c[0])] = String(c[1])
	var us: PackedInt32Array = PackedInt32Array()
	var ev := {}
	var hash_us: Array = []
	var swing: Array = []   # per tick: [active 0/1, rate*10, frame px*100, frame x0*100] when --frames
	var bad: int = -1
	var ii := 0
	var ti := 0
	var toggles: Array = rp.get("toggles", [])
	var inputs: Array = rp.get("inputs", [])
	for t in range(mini(int(rp.ticks), upto)):
		while ti < toggles.size() and int(toggles[ti][0]) == t:
			SimCore.toggleAI(S, int(toggles[ti][1]))
			ti += 1
		while ii < inputs.size() and int(inputs[ii][0]) == t:
			cur[int(inputs[ii][1])] = packed[ii]
			ii += 1
		var a: int = Time.get_ticks_usec()
		SimCore.step(S, cur)
		us.append(Time.get_ticks_usec() - a)
		var want := false
		for w in wins:
			if t >= w[0] and t <= w[1]:
				want = true
		if want:
			var names: Array = []
			for e in S.out.fx:
				names.append("fx:" + String(e.type))
			for e in S.out.feed:
				names.append("feed:" + String(e.tag).substr(0, 40))
			var f0 = S.fighters[0]
			var f1 = S.fighters[1]
			ev[str(t)] = {"e": names, "hp": [snappedf(f0.hp, 0.1), snappedf(f1.hp, 0.1)], "x": [snappedf(f0.x, 1.0), snappedf(f1.x, 1.0)], "y": [snappedf(f0.y, 1.0), snappedf(f1.y, 1.0)], "ser": SimField._serial, "bh": SimField._bHave.size(), "sh": S.storeHash}
		if want_frames:
			var sw = S.swing
			var fr = S.frame
			swing.append([1 if (sw != null and sw.active) else 0, int(round(float(sw.rate) * 10.0)) if sw != null else 0, int(round(float(fr.px) * 100.0)) if fr != null else 0, int(round(float(fr.x0) * 100.0)) if fr != null else 0])
		S.out.fx.clear()
		S.out.feed.clear()
		if checks.has(t + 1):
			var h0: int = Time.get_ticks_usec()
			var hh: String = String(SimHash.stateHash(S).gameplay)
			hash_us.append(Time.get_ticks_usec() - h0)
			if bad < 0 and hh != checks[t + 1]:
				bad = t + 1
	var fin: String = String(SimHash.stateHash(S).gameplay)
	var ok: bool = bad < 0 and (upto < int(rp.ticks) or fin == String(rp.get("final", "")))
	print("replay_prof: ", "REPRODUCES (every checkpoint and the final hash)" if ok else "MISMATCH at checkpoint tick %d, final %s against recorded %s" % [bad, fin, rp.get("final", "")])
	var res := {"ticks": int(rp.ticks), "reproduces": ok, "badCheckpoint": bad, "dataSame": data_now == rp.get("data", ""), "newMatchUs": t_new, "us": Array(us), "hashUs": hash_us, "events": ev, "swing": swing}
	SimCore.dispose(S)
	if outp != "":
		var f := FileAccess.open(outp, FileAccess.WRITE)
		f.store_string(JSON.stringify(res))
		f.close()
	quit(0 if ok else 1)
