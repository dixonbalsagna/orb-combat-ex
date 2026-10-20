extends SceneTree
## Trace: the first launch intents of an AI match (the feed on in memory), against the flight that flew. For each: the
## plan (candidate, predicted landing x and flight ticks), then the sent body every 5 ticks (state, x, y, vx, vy) until
## he is free again or 400 ticks pass.
## -- <seed> [--launches=6]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var seed: int = int(args[0]) if args.size() > 0 else 1
	var most := 6
	for s in args:
		if s.begins_with("--launches="):
			most = int(s.substr(11))
	DirInterrupt.data()["cameraIntent"]["enabled"] = true
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {})
	var seen := 0
	var tr = null   # [slot, send tick, predicted x, predicted ticks]
	while S.tick < 18000 and seen < most:
		SimCore.step(S)
		for e in S.out.fx:
			if String(e.type) == "cue" and String(e.kind) == "cam_intent" and String(e.text) == "launch" and tr == null:
				tr = [int(e.target), S.tick, float(e.x), int(e.dur)]
				print("LAUNCH t=", S.tick, " ", String(e.source), " kind=", int(e.k), " u=(", snappedf(float(e.ux), 0.01), ",", snappedf(float(e.uy), 0.01), ") predicted x=", snappedf(float(e.x), 1.0), " ticks=", int(e.dur), " travel=", snappedf(float(e.amount), 1.0), " water=", int(e.y), " from x=", snappedf(S.fighters[int(e.target)].x, 1.0))
		if tr != null:
			var f = S.fighters[int(tr[0])]
			var dt: int = S.tick - int(tr[1])
			if dt % 5 == 0:
				print("   +", dt, " ", f.state, " x=", snappedf(f.x, 1.0), " y=", snappedf(f.y, 1.0), " v=(", snappedf(f.vx, 1.0), ",", snappedf(f.vy, 1.0), ") dx-from-predicted=", snappedf(SimWrap.sdx(float(tr[2]), f.x), 1.0))
			if (f.state == "free" and dt > 5) or dt > 400:
				tr = null
				seen += 1
		S.out.fx.clear()
		S.out.feed.clear()
	quit()
