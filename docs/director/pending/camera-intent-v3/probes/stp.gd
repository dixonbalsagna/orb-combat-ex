extends SceneTree
## Probe: the camera feed's stories at the climaxes, after Rendering's roll probe (docs/rendering/camera-roll.md). AI v AI,
## the feed on in memory. At each decisive event, each finisher_start and each ko: is a plan held then (a plan cue sent
## at or before this tick whose span, its last beat's tick, reaches it), and what is the best held one's weight, its tags
## and its source. And all plans' weights, the finisher plans, and the lead of the earliest held plan that isn't the
## decisive moment's own (the ticks it was told ahead).
## -- <matches> <seed0> [--ticks=7200]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 7200
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	DirInterrupt.data()["cameraIntent"]["enabled"] = true
	var r := {"matches": n, "climaxes": 0, "held": 0, "heldDecisive": 0, "byKind": {}, "unheldKinds": {}, "bestW": {}, "planW": {}, "planSources": {}, "finisherPlans": 0, "lead": [], "leadsByKind": {}}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {})
		var held := []   # [sent tick, last tick, w, tags, source]
		for t in range(ticks):
			SimCore.step(S)
			var climax := []
			for e in S.out.fx:
				var ty: String = String(e.type)
				if ty == "cue" and String(e.kind) == "cam_intent" and String(e.text) == "plan" and e.has_meta("plan"):
					var pl: Dictionary = e.get_meta("plan")
					var w: int = int(pl.story.w)
					var src: String = String(e.source)
					held.append([S.tick, int(e.n), w, pl.story.tags, src])
					r.planW[str(w)] = int(r.planW.get(str(w), 0)) + 1
					r.planSources[src] = int(r.planSources.get(src, 0)) + 1
					if pl.story.tags.has("finisher"):
						r.finisherPlans += 1
				elif ty == "decisive":
					climax.append("decisive:" + String(e.kind))
				elif ty == "finisher_start":
					climax.append("finisher_start")
				elif ty == "ko":
					climax.append("ko")
			for c in climax:
				r.climaxes += 1
				r.byKind[c] = int(r.byKind.get(c, 0)) + 1
				var best = null
				var earliest = null
				for h in held:
					if int(h[0]) <= S.tick and int(h[1]) >= S.tick:
						if best == null or int(h[2]) > int(best[2]):
							best = h
						if String(h[4]) != "decisive" and (earliest == null or int(h[0]) < int(earliest[0])):
							earliest = h
				if best == null:
					r.unheldKinds[c] = int(r.unheldKinds.get(c, 0)) + 1
					continue
				r.held += 1
				if best[3].has("decisive"):
					r.heldDecisive += 1
				r.bestW[str(int(best[2]))] = int(r.bestW.get(str(int(best[2])), 0)) + 1
				if earliest != null:
					var lead: int = S.tick - int(earliest[0])
					r.lead.append(lead)
					if not r.leadsByKind.has(c):
						r.leadsByKind[c] = []
					r.leadsByKind[c].append(lead)
			held = held.filter(func(h): return int(h[1]) >= S.tick - 60)
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				break
	var ls: Array = r.lead.duplicate()
	ls.sort()
	r["leadMedian"] = ls[ls.size() / 2] if ls.size() > 0 else -1
	r["leadUnder8"] = ls.filter(func(x): return x < 8).size()
	r.erase("lead")
	for k in r.leadsByKind:
		var a: Array = r.leadsByKind[k]
		a.sort()
		r.leadsByKind[k] = [a.size(), a[a.size() / 2]]
	print(JSON.stringify(r))
	quit()
