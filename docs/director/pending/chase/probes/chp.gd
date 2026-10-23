extends SceneTree
## Probe (7c): the chase of a launch is the zip; data/director/interrupts.json chase on in memory.
##  --mode=ai: AI v AI at a level. Chases (cue chase start), catches, landings, stops; the catch share (QA: at least 60%);
##    chases a match; the ki each paid; the chaser's speed.
##  --mode=player: slot 0 a player sends slot 1 across (the launch planner at 1,800), then presses X with LT held 4 ticks
##    after; for 150 ticks: the chase's start, its speed, the catch (and the send on after it) or the landing, the ki paid.
## -- <matches> <seed0> [--mode=ai|player] [--level=medium] [--ticks=10800]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var mode := "ai"
	var ticks := 10800
	for s in args:
		if s.begins_with("--mode="):
			mode = s.substr(7)
		elif s.begins_with("--level="):
			DirAI.level = s.substr(8)
		elif s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	DirInterrupt.data()["chase"]["enabled"] = true
	var r := {"mode": mode, "level": DirAI.level if DirAI.level != "" else "default", "on": DirChase.on()}
	if mode == "player":
		r["runs"] = []
		for m in range(n):
			r.runs.append(_player(seed0 + m))
	else:
		r["matches"] = n
		r["chases"] = {"start": 0, "catch": 0, "landing": 0, "stopped": 0}
		r["perMatch"] = []
		r["kiPaid"] = {}
		r["speeds"] = []
		r["minutes"] = 0.0
		for m in range(n):
			var S := SimCore.createSim()
			SimCore.newMatch(S, seed0 + m, {}, {})
			var here := 0
			for t in range(ticks):
				var k0 := [S.fighters[0].ki, S.fighters[1].ki]
				SimCore.step(S)
				for e in S.out.fx:
					if String(e.type) == "cue" and String(e.kind) == "chase":
						var tx: String = String(e.text)
						r.chases[tx] = int(r.chases.get(tx, 0)) + 1
						if tx == "start":
							here += 1
							var a: int = int(e.actor)
							var paid: int = int(round(float(k0[a]) - S.fighters[a].ki))
							r.kiPaid[str(paid)] = int(r.kiPaid.get(str(paid), 0)) + 1
							r.speeds.append(int(e.amount))
				S.out.fx.clear()
				S.out.feed.clear()
				if S.game.ko != null:
					break
			r.perMatch.append(here)
			r.minutes += S.T / 60.0
		r["minutes"] = snappedf(r.minutes, 0.1)
		r["catchShare"] = snappedf(float(r.chases.catch) / maxf(1.0, float(r.chases.start)), 0.01)
		r.speeds.sort()
	print(JSON.stringify(r))
	quit()


func _player(seed: int) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, {"v2": [true, true], "intro": false})
	for k in range(60):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
	S.out.fx.clear()
	S.out.feed.clear()
	var me = S.fighters[0]
	var it = S.fighters[1]
	S.dirS.ex = null
	S.dirS.cool = 0.0
	for f in [me, it]:
		f.state = "free"
		f.rush = null
		f.vx = 0.0
		f.vy = 0.0
		f.stunTicks = 0
	it.x = SimWrap.wrap(me.x + 150.0)
	me.y = WorldTerrain.groundY(S, me.x) + 120.0
	it.y = me.y
	me.ki = 100.0
	var plan: Dictionary = DirLaunch.chooseLaunch(S, me, it, 1800.0, true)
	if plan.is_empty():
		return {"err": "no plan"}
	DirLaunch.doLaunch(S, me, it, plan, 1800.0)
	var out := {"plan": String(plan.get("name", "")), "start": -1, "speed": 0, "catch": -1, "landing": -1, "stopped": -1, "sendOn": "", "kiPaid": 0, "gapAtEnd": -1}
	var ki0: float = me.ki
	for k in range(150):
		var i := SimIntent.new()
		if k == 4:
			i.light = true
			i.stanceMask = DirZip.LT
		elif k > 4:
			i.stanceMask = DirZip.LT
		SimCore.step(S, [i, SimIntent.new()])
		for e in S.out.fx:
			var ty: String = String(e.type)
			if ty == "cue" and String(e.kind) == "chase" and int(e.actor) == 0:
				var tx: String = String(e.text)
				if out.get(tx, -2) is int and int(out[tx]) == -1:
					out[tx] = k
				if tx == "start":
					out.speed = int(e.amount)
					out.kiPaid = int(round(ki0 - me.ki))
				if tx != "start":
					out.gapAtEnd = int(DirBands.dist(me, it))
			elif ty == "launch" and int(e.actor) == 1 and out.catch >= 0 and out.sendOn == "":
				out.sendOn = "sent on at " + str(int(e.amount)) + " u/s"
		S.out.fx.clear()
		S.out.feed.clear()
		if out.catch >= 0 or out.landing >= 0 or out.stopped >= 0:
			if k > 20 + maxi(int(out.catch), maxi(int(out.landing), int(out.stopped))):
				break
	return out
