extends SceneTree
## Probe: the chase after a launch, AI v AI, with Simulation's launch curve off or on (the setup's "flight"). For each send
## (an fx "launch": actor the sent body, target the launcher) followed to the sent body's journey end: the flight's ticks;
## the launcher's gap to him at the landing; the launcher's top speed meanwhile; whether the launcher passed him (got
## ahead of him along the send's direction); and the ticks from the landing to the next exchange or approach.
## Medians and shares over all sends.
## -- <matches> <seed0> [--curve] [--ticks=10800]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 10800
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	var curve: bool = args.has("--curve")
	var flights := []
	var gaps := []
	var tops := []
	var resumes := []
	var passed := 0
	var sends := 0
	var minutes := 0.0
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {}, {"flight": curve})
		var cur = null   # {sent, by, t0, dir, top, landed, landT}
		for t in range(ticks):
			SimCore.step(S)
			for e in S.out.fx:
				var ty: String = String(e.type)
				if ty == "launch" and cur == null and int(e.actor) >= 0 and int(e.actor) < 2:
					var sent = S.fighters[int(e.actor)]
					cur = {"sent": int(e.actor), "by": 1 - int(e.actor), "t0": S.tick, "dir": SimMathx.jsign(sent.vx), "top": 0.0, "landed": false, "landT": -1, "passed": false}
					sends += 1
				elif ty == "journey_end" and cur != null and not cur.landed and int(e.actor) == int(cur.sent):
					cur.landed = true
					cur.landT = S.tick
					flights.append(S.tick - int(cur.t0))
					var a = S.fighters[int(cur.by)]
					var d = S.fighters[int(cur.sent)]
					gaps.append(int(DirBands.dist(a, d)))
					tops.append(int(cur.top))
					if cur.passed:
						passed += 1
			if cur != null:
				var a2 = S.fighters[int(cur.by)]
				var d2 = S.fighters[int(cur.sent)]
				if not cur.landed:
					cur.top = maxf(float(cur.top), SimDetMath.hypot(a2.vx, a2.vy))
					if SimWrap.sdx(d2.x, a2.x) * float(cur.dir) > 150.0:
						cur.passed = true
				elif S.dirS.ex != null or DirBands.who(S) >= 0:
					resumes.append(S.tick - int(cur.landT))
					cur = null
				elif S.tick - int(cur.landT) > 1200:
					cur = null
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				break
		minutes += S.T / 60.0
	var r := {"curve": curve, "matches": n, "minutes": snappedf(minutes, 0.1), "sends": sends, "landed": flights.size(),
		"flightTicks": _med(flights), "gapAtLanding": _med(gaps), "launcherTop": _med(tops), "passedShare": snappedf(float(passed) / maxf(1.0, float(flights.size())), 0.01),
		"resumeTicks": _med(resumes), "flightP90": _pct(flights, 0.9), "gapP90": _pct(gaps, 0.9)}
	print(JSON.stringify(r))
	quit()


func _med(a: Array) -> int:
	return _pct(a, 0.5)


func _pct(a: Array, q: float) -> int:
	if a.is_empty():
		return -1
	var b := a.duplicate()
	b.sort()
	return int(b[mini(b.size() - 1, int(q * float(b.size())))])
