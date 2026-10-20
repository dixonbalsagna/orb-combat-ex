extends SceneTree
## Probe: the camera-intent plan against Research's test (rec 1: every strike and launch has its intent at least 8 ticks
## before contact). The feed on in memory; AI v AI. Each plan's contacts are kept with the tick they were told; each
## landed hit (a damage event with an attacker) is matched to the earliest told contact of the same attacker within
## 3 ticks. cip3: the form is split by the damage kind, and "@ex" marks a hit while a planned (not brawl) exchange runs. Reads: hits, the share told at all, the share told 8 or more ticks ahead, by the plan's source and the
## blow's form; the plans by source; one sample plan.
## -- <matches> <seed0> [--ticks=10800]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 10800
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	DirInterrupt.data()["cameraIntent"]["enabled"] = true
	var r := {"on": DirCamIntent.on(), "matches": n, "hits": 0, "told": 0, "told8": 0, "bySource": {}, "byForm": {}, "plans": {}, "launches": 0, "storyTags": {}, "sample": {}}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {})
		var told := {}   # "slot:n" -> [tick told, source]
		for t in range(ticks):
			SimCore.step(S)
			for e in S.out.fx:
				var ty: String = String(e.type)
				if ty == "cue" and String(e.kind) == "cam_intent":
					if String(e.text) == "plan" and e.has_meta("plan"):
						var pl: Dictionary = e.get_meta("plan")
						var src: String = String(e.source)
						r.plans[src] = int(r.plans.get(src, 0)) + 1
						for tg in pl.story.tags:
							r.storyTags[tg] = int(r.storyTags.get(tg, 0)) + 1
						if r.sample.is_empty() and pl.beats.size() >= 3:
							r.sample = pl
						for b in pl.beats:
							if String(b.op) == "pulse" or String(b.kind) == "window" or String(b.kind) == "move":
								continue
							var key: String = str(int(b.a)) + ":" + str(int(b.n))
							if not told.has(key):
								told[key] = [S.tick, src]
					elif String(e.text) == "launch":
						r.launches += 1
				elif ty == "damage" and float(e.attacker) >= 0.0:
					r.hits += 1
					var a: int = int(e.attacker)
					var best = null
					for dt in [0, -1, 1, -2, 2, -3, 3]:
						var k2: String = str(a) + ":" + str(S.tick + dt)
						if told.has(k2):
							best = told[k2]
							break
					var form: String = (String(e.mode) if String(e.mode) != "" else "planned") + "/" + String(e.kind) + ("@ex" if (S.dirS.ex != null and not DirBrawl.isBrawl(S.dirS.ex)) else "")
					if not r.byForm.has(form):
						r.byForm[form] = [0, 0, 0]
					r.byForm[form][0] += 1
					if best != null:
						r.told += 1
						r.byForm[form][1] += 1
						var lead: int = S.tick - int(best[0])
						var bs: String = String(best[1])
						if not r.bySource.has(bs):
							r.bySource[bs] = [0, 0]
						r.bySource[bs][0] += 1
						if lead >= 8:
							r.told8 += 1
							r.byForm[form][2] += 1
							r.bySource[bs][1] += 1
			S.out.fx.clear()
			S.out.feed.clear()
	r["toldShare"] = snappedf(float(r.told) / maxf(1.0, float(r.hits)), 0.001)
	r["told8Share"] = snappedf(float(r.told8) / maxf(1.0, float(r.hits)), 0.001)
	print(JSON.stringify(r))
	quit()
