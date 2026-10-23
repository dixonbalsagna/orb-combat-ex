extends SceneTree
## A sample run's grounds (docs/architecture/run-core.md section 11): for each chapter, the ring the next stage is
## fought on, picked by SimRun.beginGround and stepped a frame at a time at the data's pace, as the host steps it
## during the previous stage's beats. Prints the pick per stage, checks a stepped pick against one made at once, and
## builds each stage's match from its setup alone and plays it twice. Each stage's arena goes to the later picks as a
## ring the run has fought (opts.used: a run never fights the same ring twice), and a boss ring under Whole's minimum
## must hold Game Design's waiver (his home and a standing city). Until the run's carry is built, the places an
## earlier stage's ring held stand in for the run's wear: they go to the later picks as damaged (--no-wear: none).
##   godot --headless --path . --script res://sim/core/tools/run_ground.gd -- [run seed, 16 hex] [opponents, comma
##   separated, the boss last] [--ticks=600] [--no-wear]

const BIOMES: Array = ["ocean", "plains", "forest", "desert", "mountains", "ice", "sea ice"]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var run: String = args[0] if args.size() > 0 and not args[0].begins_with("--") else "00c0ffee0badf00d"
	var opps: Array = Array((args[1] if args.size() > 1 and not args[1].begins_with("--") else "RIVAL,EMPRESS,CYBORG,RIVAL").split(","))
	var ticks: int = 600
	for a in args:
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	var wear: bool = not args.has("--no-wear")
	var damaged: Array = []
	var used: Array = []
	var repeats: int = 0
	var bad: int = 0
	var P: WorldPlanet.Planet = WorldPlanet.make(SimRun.planetSeed(run))
	var hm: Dictionary = SimRun.homes(P)
	print("run %s: planet %d (%d places); switch %s; frames a read %s; stand-in homes %s" % [run, SimRun.planetSeed(run), P.n, "on" if SimRun.groundOn() else "off", str(SimRun.framesPerRead), str(hm)])
	for i in range(opps.size()):
		var ch: int = i + 1
		var opp: String = String(opps[i])
		var t0: int = Time.get_ticks_usec()
		var g: SimRun.GroundJob = SimRun.beginGround(run, ch, opp, {"damaged": damaged.duplicate(), "used": used.duplicate()})
		var t1: int = Time.get_ticks_usec()
		var frames: int = 0
		var worst: int = 0
		while true:
			var f0: int = Time.get_ticks_usec()
			var fin: bool = g.frame()
			frames += 1
			worst = maxi(worst, Time.get_ticks_usec() - f0)
			if fin:
				break
		var t2: int = Time.get_ticks_usec()
		var r: Dictionary = g.result
		var ev: Dictionary = r.ev
		var sh: PackedStringArray = []
		for b in range(BIOMES.size()):
			if float(ev.share[b]) >= 0.005:
				sh.append("%s %d%%" % [BIOMES[b], int(round(float(ev.share[b]) * 100.0))])
		var held: PackedStringArray = []
		for h in ev.held:
			held.append("%s%d%s%s" % ["city " if h.kind == WorldPlanet.KIND_CITY else "town ", h.id, " (home)" if h.id == g.home else "", " fallen" if h.fallen else ""])
		var okText: String = str(r.ok) + (" (waived: Game Design 2026-10-23 4, his home and a standing city held)" if r.get("waived", false) else "")
		print("stage %d  %s  %s, %d cols  rule %s  ring %s%s  ok %s  must %s%s  score %.2f  repeat %s  damaged before: %s" % [ch, opp, g.size, int(r.spec.cols), g.rule, str(r.kind),
			"" if int(r.place) < 0 else " of place %d" % int(r.place), okText, str(r.must), "  relaxed" if r.relaxed else "", float(r.score), str(r.get("repeat", false)), str(damaged)])
		if g.rule == "boss" and not r.ok and not r.get("waived", false):
			bad += 1
			print("    FAIL: the boss's ring is under Whole's minimum without Game Design's waiver (his home and a standing city)")
		if r.get("repeat", false):
			repeats += 1
			print("    REPEAT: a ring the run has fought (World's last resort: nothing else met even the crude minimum)")
		print("    ring: %s; land %d%%, coast %d; holds %d cities, %d towns: %s" % [", ".join(sh), int(round(float(ev.land) * 100.0)), int(ev.coast), int(ev.cities), int(ev.towns), ", ".join(held)])
		print("    picked in %d frames (%d reads, one every %d frames): begin %.1f ms, worst frame %.1f ms, all %.1f ms; stage seed %d" % [frames, g.reads, int(SimRun.framesPerRead[g.size]), (t1 - t0) / 1000.0, worst / 1000.0, (t2 - t0) / 1000.0, g.matchSeed()])
		# the same pick made at once
		var g2: SimRun.GroundJob = SimRun.beginGround(run, ch, opp, {"damaged": damaged.duplicate(), "used": used.duplicate()})
		g2.finishNow()
		if JSON.stringify(g2.setup()) != JSON.stringify(g.setup()):
			bad += 1
			print("    FAIL: picked at once it is another ring")
		# the stage from its setup alone, twice
		var hs: Array = []
		for k in range(2):
			var S := SimCore.createSim()
			SimCore.newMatch(S, g.matchSeed(), {}, g.setup())
			if S.arenaCols != int(r.spec.cols):
				bad += 1
				print("    FAIL: the match's arena is %d columns, not the ring's %d" % [S.arenaCols, int(r.spec.cols)])
			for t in range(ticks):
				SimCore.step(S)
			hs.append(SimHash.stateHash(S).gameplay)
			SimCore.dispose(S)
		if hs[0] != hs[1]:
			bad += 1
			print("    FAIL: the stage played twice differs")
		else:
			print("    the stage from its setup: %d ticks, the same twice (%s)" % [ticks, str(hs[0]).substr(0, 12)])
		used.append(JSON.parse_string(JSON.stringify(g.setup().arena)))   # as the stage's header carries it
		if wear:
			for h in ev.held:
				if not damaged.has(int(h.id)):
					damaged.append(int(h.id))
	print("run_ground: %s; %d repeats" % ["passed" if bad == 0 else "%d FAILED" % bad, repeats])
	quit(0 if bad == 0 else 1)
