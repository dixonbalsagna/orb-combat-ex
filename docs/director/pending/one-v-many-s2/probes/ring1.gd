extends SceneTree
## Scratch probe of one versus many, stage 2 (DirRing): matches of 3, 4 and 5 bodies, the AI on every one, slot 0 the
## one. It reads stage 2's proof rows and the cost a tick, and plays each body count's first match twice to compare
## the state hash at its end.
## -- <matches a count> <seed0> [--ticks=18000] [--counts=3,4,5]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 4
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var cap := 18000
	var counts := [3, 4, 5]
	for s in args:
		if s.begins_with("--ticks="):
			cap = int(s.substr(8))
		if s.begins_with("--counts="):
			counts = []
			for c in s.substr(9).split(","):
				counts.append(int(c))
	var out := {}
	for nb in counts:
		var r := {"matches": n, "ticks": 0, "kos": {}, "ringBlowsOnOne": 0, "refused": 0, "tags": 0, "tagWhy": {}, "tagGapMin": -1,
			"threats": 0, "threatGapMax": 0, "brawlTicks": 0, "brawlFreeze": 0, "blowsOnOneInBrawl": 0, "oneBlows": 0, "deterministic": true, "ringKinds": {}, "stepInStuck": 0}
		var times: Array = []
		for m in range(n):
			var res: Dictionary = _match(nb, seed0 + m, cap, r, times)
			if m == 0:
				var again: Dictionary = _match(nb, seed0 + m, cap, {}, [])
				if JSON.stringify(again.hash) != JSON.stringify(res.hash) or int(again.ticks) != int(res.ticks):
					r.deterministic = false
		times.sort()
		var live: float = maxf(1.0, float(r.brawlTicks))
		r["blowsOnOneASecondOfBrawl"] = snappedf(float(r.blowsOnOneInBrawl) / live * 60.0, 0.01)
		r["freezeShareOfBrawl"] = snappedf(float(r.brawlFreeze) / maxf(1.0, float(r.brawlTicks + r.brawlFreeze)), 0.001)
		r["tagsAMinuteOfBrawl"] = snappedf(float(r.tags) / maxf(1.0, live / 3600.0), 0.1)
		r["meanUs"] = snappedf(times.reduce(func(a, b): return a + b, 0) / maxf(1.0, float(times.size())), 0.1) if times.size() > 0 else 0
		r["p99Us"] = times[int(times.size() * 0.99)] if times.size() > 0 else 0
		out[str(nb) + " bodies"] = r
	print(JSON.stringify(out))
	quit()


func _match(nb: int, seed: int, cap: int, r: Dictionary, times: Array) -> Dictionary:
	var S := SimCore.createSim()
	var slots := ["PROTAGONIST"]
	var names := ["ONE"]
	var ai := {}
	for k in range(nb):
		ai["p" + str(k + 1)] = true
		if k > 0:
			slots.append("RIVAL")
			names.append("G" + str(k))
	SimCore.newMatch(S, seed, ai, {"slots": slots, "names": names})
	var lastTag := -1
	var lastThreat: Dictionary = {}
	while S.tick < cap and S.game.ko == null:
		var ex = S.dirS.ex
		var inB: bool = ex != null and String(ex.tpl) == "brawl"
		var roles: Array = []
		for f in S.fighters:
			roles.append(DirRing.role(S, f))
		var t0: int = Time.get_ticks_usec()
		var stepped: bool = SimCore.step(S, null)
		if not r.is_empty():
			times.append(Time.get_ticks_usec() - t0)
			r.ticks += 1
			if inB:
				if stepped:
					r.brawlTicks += 1
				else:
					r.brawlFreeze += 1
			var now: int = DirBrawl._now(S)
			for e in S.out.fx:
				if e.type == "damage" and e.amount > 0.0:
					var a: int = int(e.attacker)
					if int(e.victim) == 0 and a >= 1 and a < roles.size():
						if roles[a] == DirRing.RING:
							r.ringBlowsOnOne += 1
							var rk: String = String(e.kind) + " / now " + ["none", "one", "partner", "ring"][DirRing.role(S, S.fighters[a])] + " / " + String(S.fighters[a].state)
							r.ringKinds[rk] = int(r.ringKinds.get(rk, 0)) + 1
						if inB:
							r.blowsOnOneInBrawl += 1
					if a == 0:
						r.oneBlows += 1
				elif e.type == "cue":
					var ck: String = String(e.kind)
					if ck == "ring_tag":
						r.tags += 1
						r.tagWhy[String(e.text)] = int(r.tagWhy.get(String(e.text), 0)) + 1
						if lastTag >= 0:
							var gap: int = now - lastTag
							r.tagGapMin = gap if int(r.tagGapMin) < 0 else mini(int(r.tagGapMin), gap)
						lastTag = now
						lastThreat.erase(int(e.actor))   # the new partner leaves the ring
						lastThreat[int(e.target)] = now   # the old one joins it
					elif ck == "ring_threat":
						r.threats += 1
						var who: int = int(e.actor)
						if lastThreat.has(who):
							r.threatGapMax = maxi(int(r.threatGapMax), now - int(lastThreat[who]))
						lastThreat[who] = now
		if not r.is_empty():
			var nw: int = DirBrawl._now(S)
			for k in range(1, S.fighters.size()):
				var g = S.fighters[k]
				if g.state != "free" or DirRing.role(S, g) != DirRing.RING or DirBrawl._g(g, DirBrawl.SENT) != 0:
					lastThreat[k] = nw   # the gap counts only while he stands free in the ring
				elif DirRing._g(g, DirRing.STEP_IN) == 1 and nw - DirRing._g(g, DirRing.THREAT_AT) > 180:
					r.stepInStuck += 1
		S.out.fx.clear()
		S.out.feed.clear()
	if not r.is_empty():
		for k in range(1, S.fighters.size()):
			r.refused += DirRing._g(S.fighters[k], DirRing.REFUSED)
		var ko: String = "none" if S.game.ko == null else ("the one" if S.game.ko == S.fighters[0] else "a guard")
		r.kos[ko] = int(r.kos.get(ko, 0)) + 1
	return {"hash": SimHash.stateHash(S), "ticks": S.tick}
