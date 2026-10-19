extends SceneTree
## Probe: launch anywhere (the thirteenth round). --mode=ai: the AI on both sides. Otherwise slot 0 is a scripted player
## against the AI at --level: route (X every 8 ticks, B at every opening), spam (one light, then B, every string: B 6
## ticks after each of his landed blows) or varied (the route, his stick turned through up, toward and down in turn at
## each B). Every launcher is found as a beat of the exchange (args.launcher), once: its owner, safety (1 sure, 2 hard,
## 3 answerable) and power. Its fate, within 60 ticks: launched (a launch plan of its owner's), perfect-blocked (the
## rival's perfect_block), or not (stopped, missed or guarded). Launches are counted by kind of send and by who launched,
## a match. The AI's guard presses while a launcher that isn't sure is open on it are counted (each is a guess the
## director fixed at an earlier landing, before the launcher existed).
## -- <matches> <seed0> [--mode=ai|route|spam|varied] [--level=medium] [--cap=18000]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 3
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var mode := "ai"
	var cap := 18000
	for s in args:
		if s.begins_with("--mode="):
			mode = s.substr(7)
		if s.begins_with("--level="):
			DirAI.level = s.substr(8)
		if s.begins_with("--cap="):
			cap = int(s.substr(6))
	var react: int = int(DirAI.skill().get("reactTicks", 14))
	var r := {"mode": mode, "level": DirAI.level, "matches": n, "ticks": 0, "launchers": 0, "launchers0": 0, "bySafety": {}, "bySafety0": {},
		"powerSum": 0.0, "fate0": {}, "fateBySafety0": {}, "launches": {"by0": 0, "on0": 0, "byKind0": {}, "byKindAll": {}},
		"aiGuardOnLauncher": 0, "aiGuardSoon": 0, "opensCue": [0, 0], "opensRead": 0, "full": {"by0": 0, "on0": 0, "all": 0, "allSends": 0}, "anywhere": DirBrawl.anywhere(), "aims": [{}, {}], "care": [], "reactTicks": react, "kos": 0, "wins0": 0}
	var kindNames := ["up", "across", "down", "behind", "building"]
	for m in range(n):
		var S := SimCore.createSim()
		var human: bool = mode != "ai"
		SimCore.newMatch(S, seed0 + m, {"p1": not human, "p2": true}, {"v2": [true, false]})
		var me = S.fighters[0]
		var last := -1000
		var bAt := -1
		var bUp := -1
		var turn := 0
		var wasOpen := false
		var wantB := false
		var seen := {}
		var open := []       # [owner slot, safety, the tick it was seen, the press tick, done]
		var guardWas := [DirInterrupt.gi(S.fighters[0], DirInterrupt.GUARD_AT), DirInterrupt.gi(S.fighters[1], DirInterrupt.GUARD_AT)]
		while S.tick < cap and S.game.ko == null:
			var it := SimIntent.new()
			if human:
				if S.tick == bAt:
					it.sig = true
					it.sigHeld = true   # a pad's press: the edge with the level down (an edge alone is a Simple Attack, already wound)
					bUp = S.tick + 2
					bAt = -1
					if mode == "varied":
						var dirs := [[0.0, 1.0], [1.0, 0.0], [0.0, -1.0]]
						var dd = dirs[turn % 3]
						var tw: float = 1.0 if SimWrap.sdx(me.x, S.fighters[1].x) >= 0.0 else -1.0
						it.mx = float(dd[0]) * tw
						it.my = float(dd[1])
						turn += 1
				elif S.tick < bUp:
					it.sigHeld = true
				elif S.tick - last >= 8 and bAt < 0 and not wantB:
					it.light = true
					last = S.tick
			SimCore.step(S, [it, null] if human else null)
			# the route and the varied route: one B at each opening of his, read as QA's route reads it (DirBrawl.launcherOpen)
			var lo: int = DirBrawl.launcherOpen(S, me)
			if human and (mode == "route" or mode == "varied") and lo >= 0 and not wasOpen:
				wantB = true
				r.opensRead += 1
			if lo < 0:
				wantB = false
			if wantB and bAt < 0 and not DirBrawl.busy(S, me):
				bAt = S.tick + 1   # as QA's route: B once his line is free, inside the opening
				wantB = false
			wasOpen = lo >= 0
			var ex = S.dirS.ex
			if ex != null:
				for b in ex.beats:
					if b.done or b.op != "strike" or b.args == null or not b.args.get("launcher", false):
						continue
					var id: int = b.get_instance_id()
					if seen.has(id):
						continue
					seen[id] = true
					var owner: int = S.fighters.find(ex.A if String(b.args.a) == "A" else ex.D)
					var sf: int = int(b.args.get("safety", 1))
					var am: String = str(int(b.args.get("aim", 0)))
					r.aims[owner][am] = int(r.aims[owner].get(am, 0)) + 1
					r.launchers += 1
					r.bySafety[str(sf)] = int(r.bySafety.get(str(sf), 0)) + 1
					r.powerSum += float(b.args.get("power", 1.0))
					if owner == 0:
						r.launchers0 += 1
						r.bySafety0[str(sf)] = int(r.bySafety0.get(str(sf), 0)) + 1
					open.append([owner, sf, S.tick, false])
			for e in S.out.fx:
				var ty: String = String(e.type)
				if ty == "cue":
					var ck: String = String(e.kind)
					if ck == "launch_power":
						r.full.allSends += 1
						if int(e.k) == 1:
							r.full.all += 1
							if int(e.actor) == 0:
								r.full.by0 += 1
							if int(e.target) == 0:
								r.full.on0 += 1
					elif ck == "launcher_open":
						r.opensCue[int(e.actor)] += 1
					elif ck == "perfect_block":
						for q in open:
							if not q[3] and int(q[0]) == 1 - int(e.actor) and S.tick - int(q[2]) <= 60:
								q[3] = true
								_fate(r, q, "perfect")
								break
				elif ty == "launch_plan" and String(e.chosen) != "KNOCK BACK" and String(e.chosen) != "STAY" and String(e.chosen) != "":
					var by: int = int(e.actor)
					for q in open:
						if not q[3] and int(q[0]) == by and S.tick - int(q[2]) <= 60:
							q[3] = true
							_fate(r, q, "launched")
							break
					var kd: int = DirBrawl.kindOfSend({"name": String(e.chosen)})
					var kn: String = kindNames[kd] if kd >= 0 and kd < 5 else "?"
					r.launches.byKindAll[kn] = int(r.launches.byKindAll.get(kn, 0)) + 1
					if by == 0:
						r.launches.by0 += 1
						r.launches.byKind0[kn] = int(r.launches.byKind0.get(kn, 0)) + 1
					if int(e.target) == 0:
						r.launches.on0 += 1
			if human and mode == "spam" and bAt < 0 and DirBrawl._lg(me, DirBrawl.LA_LINK) == S.tick:
				bAt = S.tick + 6
			# the AI's guard presses while a launcher that isn't sure is open on it
			for s in [0, 1]:
				var g: int = DirInterrupt.gi(S.fighters[s], DirInterrupt.GUARD_AT)
				if g != int(guardWas[s]):
					guardWas[s] = g
					if S.fighters[s].ai != null:
						for q in open:
							if not q[3] and int(q[0]) == 1 - s and int(q[1]) != 1 and g - int(q[2]) <= 30:
								r.aiGuardOnLauncher += 1   # a guess made at an earlier landing, pressed its reaction time into the wind-up
								if g - int(q[2]) < react - 2:
									r.aiGuardSoon += 1   # sooner than its reaction time after the launcher was seen (2 ticks of slack for the beat's scheduling)
								break
			var keep := []
			for q in open:
				if not q[3] and S.tick - int(q[2]) > 60:
					q[3] = true
					_fate(r, q, "not")
				if not q[3]:
					keep.append(q)
			open = keep
			S.out.fx.clear()
			S.out.feed.clear()
		r.ticks += S.tick
		if m == 0:
			r.care = [snappedf(float(S.fighters[0].care), 0.01), snappedf(float(S.fighters[1].care), 0.01)]
		if S.game.ko != null:
			r.kos += 1
			if S.game.ko == S.fighters[1]:
				r.wins0 += 1   # slot 0 won: the AI is KO'd
	r["powerMean"] = snappedf(float(r.powerSum) / maxf(1.0, float(r.launchers)), 0.001)
	r["minutes"] = snappedf(float(r.ticks) / 3600.0, 0.1)
	r["launchesByAMatch"] = snappedf(float(r.launches.by0) / maxf(1.0, float(n)), 0.1)
	r["fullByAMatch"] = snappedf(float(r.full.by0) / maxf(1.0, float(n)), 0.1)
	r["fullOnAMatch"] = snappedf(float(r.full.on0) / maxf(1.0, float(n)), 0.1)
	r["fullAMatchAFighter"] = snappedf(float(r.full.all) / maxf(1.0, 2.0 * float(n)), 0.1)
	var ns: int = 0
	var ans: int = 0
	for kk in r.fateBySafety0:
		if not String(kk).begins_with("1:"):
			ns += int(r.fateBySafety0[kk])
			if not String(kk).ends_with(":launched"):
				ans += int(r.fateBySafety0[kk])
	r["answeredShare0"] = snappedf(float(ans) / maxf(1.0, float(ns)), 0.001)
	print(JSON.stringify(r))
	quit()


static func _fate(r: Dictionary, q: Array, how: String) -> void:
	if int(q[0]) != 0:
		return
	r.fate0[how] = int(r.fate0.get(how, 0)) + 1
	var k: String = str(q[1]) + ":" + how
	r.fateBySafety0[k] = int(r.fateBySafety0.get(k, 0)) + 1
