extends SceneTree
## Scratch probe of one versus many, stage 3: the interjection and the guards' rules. Matches of 3, 4 and 5 bodies, the
## AI on every one, slot 0 the one and slot 1 the other principal. Rows: what became of each grant; blows from two
## fighters landing on the one within 8 live ticks (hard: never); a guard closing on, launching or knocking back the
## one (hard: never); a blow of a ring guard's landing without a grant (stray); the freeze share; the cost a tick; the
## same match twice.
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
		var r := {"matches": n, "ticks": 0, "kos": {}, "interject": {}, "twoWithin8": 0, "twoWithin8Pairs": {}, "guardSends": 0, "guardKnocks": 0,
			"guardCloses": 0, "stray": 0, "strayKinds": {}, "p1Held": 0, "p1Presses": 0, "brawlTicks": 0, "brawlFreeze": 0, "onOne": 0, "tags": 0, "deterministic": true}
		var times: Array = []
		for m in range(n):
			var res: Dictionary = _match(nb, seed0 + m, cap, r, times)
			if m == 0:
				var again: Dictionary = _match(nb, seed0 + m, cap, {}, [])
				if JSON.stringify(again.hash) != JSON.stringify(res.hash) or int(again.ticks) != int(res.ticks):
					r.deterministic = false
		times.sort()
		r["onOneASecondOfBrawl"] = snappedf(float(r.onOne) / maxf(1.0, float(r.brawlTicks)) * 60.0, 0.01)
		r["freezeShareOfBrawl"] = snappedf(float(r.brawlFreeze) / maxf(1.0, float(r.brawlTicks + r.brawlFreeze)), 0.001)
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
		ai["p" + str(k + 1)] = k != 1
		if k > 0:
			slots.append("RIVAL")
			names.append("G" + str(k))
	SimCore.newMatch(S, seed, ai, {"slots": slots, "names": names})
	var lastHit := {}    # attacker slot -> the live tick his last blow landed on the one
	var lastX := -1000
	var bFrom := -1000
	while S.tick < cap and S.game.ko == null:
		var ex = S.dirS.ex
		var inB: bool = ex != null and String(ex.tpl) == "brawl"
		var roles: Array = []
		for f in S.fighters:
			roles.append(DirRing.role(S, f))
		var partnerSlot: int = S.fighters.find(DirRing.partner(S, S.fighters[0]))
		var it := SimIntent.new()
		var me = S.fighters[1]
		it.mx = SimMathx.jsign(SimWrap.sdx(me.x, S.fighters[0].x))
		if S.tick - bFrom >= 60:
			bFrom = S.tick
			it.heavy = true
		if S.tick - bFrom < 34:
			it.heavyHeld = true
		elif S.tick - lastX >= 10:
			it.light = true
			lastX = S.tick
		if not r.is_empty():
			if DirRing.holds(S, me):
				r.p1Held += 1
			if it.light or it.heavy:
				r.p1Presses += 1
		var t0: int = Time.get_ticks_usec()
		var stepped: bool = SimCore.step(S, [null, it])
		if r.is_empty():
			S.out.fx.clear()
			S.out.feed.clear()
			continue
		times.append(Time.get_ticks_usec() - t0)
		r.ticks += 1
		if inB:
			if stepped:
				r.brawlTicks += 1
			else:
				r.brawlFreeze += 1
		var now: int = DirBrawl._now(S)
		var landedX: Dictionary = {}
		for e in S.out.fx:
			if e.type == "cue" and String(e.kind) == "interject":
				r.interject[String(e.text)] = int(r.interject.get(String(e.text), 0)) + 1
				if String(e.text) == "landed":
					landedX[int(e.actor)] = true
		for e in S.out.fx:
			if e.type == "damage" and e.amount > 0.0 and int(e.victim) == 0:
				var a: int = int(e.attacker)
				if a <= 0:
					continue   # no attacker, or himself
				if inB:
					r.onOne += 1
				if a >= 1 and a < roles.size() and roles[a] == DirRing.RING and not landedX.has(a):
					r.stray += 1
					r.strayKinds[String(e.kind)] = int(r.strayKinds.get(String(e.kind), 0)) + 1
				for b in lastHit.keys():
					if int(b) != a and now - int(lastHit[b]) < 8:
						r.twoWithin8 += 1
						var key: String = str(min(a, int(b))) + "-" + str(max(a, int(b)))
						r.twoWithin8Pairs[key] = int(r.twoWithin8Pairs.get(key, 0)) + 1
				lastHit[a] = now
			elif e.type == "launch" and int(e.actor) == 0 and int(e.target) >= 2:
				r.guardSends += 1
			elif e.type == "knockback" and int(e.victim) == 0 and int(e.attacker) >= 2:
				r.guardKnocks += 1
			elif e.type == "cue" and String(e.kind) == "stagger" and int(e.actor) == 0 and String(e.text) == "flurry" and partnerSlot >= 2:
				r.guardCloses += 1
			elif e.type == "cue" and String(e.kind) == "ring_tag":
				r.tags += 1
		S.out.fx.clear()
		S.out.feed.clear()
	if not r.is_empty():
		var ko: String = "none" if S.game.ko == null else ("the one" if S.game.ko == S.fighters[0] else ("the other principal" if S.game.ko == S.fighters[1] else "a guard"))
		r.kos[ko] = int(r.kos.get(ko, 0)) + 1
	return {"hash": SimHash.stateHash(S), "ticks": S.tick}
