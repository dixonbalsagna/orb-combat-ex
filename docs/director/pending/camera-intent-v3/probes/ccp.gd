extends SceneTree
## Probe: the camera feed's touchdown with Simulation's launch curve on (the setup's "flight"), AI v AI, the feed on in
## memory. For each cam_intent launch cue, the tick it names (n) against the tick the sent body first meets something
## (his flight cue's "end", or a building_hit or journey_end of his, whichever first): the error in ticks, and in live
## ticks (the cue's flight ticks against the live ticks run since it: a freeze or a pause in the flight isn't in it).
## -- <matches> <seed0> [--nocurve] [--ticks=10800]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 10800
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	var curve: bool = not args.has("--nocurve")
	DirInterrupt.data()["cameraIntent"]["enabled"] = true
	var errs := {}
	var liveErrs := {}
	var cues := 0
	var met := 0
	var sample := []
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {"flight": curve})
		var want := {}   # slot -> [told n, cue tick, curve flag]
		for t in range(ticks):
			var t0: float = S.T
			SimCore.step(S)
			if S.T != t0:
				for k in want:
					want[k][3] += 1
			for e in S.out.fx:
				var ty: String = String(e.type)
				if ty == "cue" and String(e.kind) == "cam_intent" and String(e.text) == "launch":
					var sl: int = int(e.target)
					var cv: bool = e.has_meta("launch") and bool(e.get_meta("launch").get("curve", false))
					want[sl] = [int(e.n), S.tick, cv, 0, int(e.dur)]
					cues += 1
				elif (ty == "building_hit" or ty == "journey_end" or (ty == "flight" and String(e.text) == "end")) and want.has(int(e.actor)):
					var w = want[int(e.actor)]
					var d: int = S.tick - int(w[0])
					var key: String = str(clampi(d, -6, 6)) + ("" if w[2] else "u")
					errs[key] = int(errs.get(key, 0)) + 1
					var lk: String = str(clampi(int(w[3]) - int(w[4]), -6, 6))
					liveErrs[lk] = int(liveErrs.get(lk, 0)) + 1
					met += 1
					if sample.size() < 8 and absi(d) > 1:
						sample.append("m%d t%d told %d (cue t%d) met by %s" % [m, S.tick, int(w[0]), int(w[1]), ty])
					want.erase(int(e.actor))
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				break
	print(JSON.stringify({"curve": curve, "matches": n, "cues": cues, "met": met, "errorTicks": errs, "liveErrorTicks": liveErrs, "sample": sample}))
	quit()
