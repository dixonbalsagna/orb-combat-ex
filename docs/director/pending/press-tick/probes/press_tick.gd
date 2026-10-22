extends SceneTree
## Probe: press to the sim's first reaction (Performance's input-latency-2026-10-22.md; Controls' T1: the same tick).
## Slot 0 a player (v2 by default), slot 1 an idle dummy at d units on the ground; 90 idle ticks, then one press (a
## light, a heavy or a signature with the ki) on one tick. For the press tick and the 10 after it: the queue, the
## exchange, the approach, his rush, state and x, the events (type and kind/text). --v1: slot 0 is a v1 record.
## -- <d> <light|heavy|sig> [--v1]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var d: float = float(args[0]) if args.size() > 0 else 250.0
	var kind: String = args[1] if args.size() > 1 else "light"
	var v2: bool = not args.has("--v1")
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {"p1": false, "p2": false}, {"v2": [v2, true]})
	var me = S.fighters[0]
	var it = S.fighters[1]
	var out := {"d": d, "kind": kind, "v2": v2, "ticks": []}
	for k in range(90):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
		if k == 30:
			me.x = SimWrap.wrap(me.x)
			it.x = SimWrap.wrap(me.x + d)
			me.y = WorldTerrain.groundY(S, me.x)
			it.y = WorldTerrain.groundY(S, it.x)
			me.vx = 0.0
			me.vy = 0.0
			it.vx = 0.0
			it.vy = 0.0
			me.ki = 100.0
		S.out.fx.clear()
		S.out.feed.clear()
	out["start"] = {"tick": S.tick, "T": S.T, "cool": S.dirS.cool, "ex": S.dirS.ex != null, "gap": int(absf(SimWrap.sdx(me.x, it.x))), "state": me.state, "band": DirBands.band(me, it)}
	var x0: float = me.x
	for k in range(11):
		var i := SimIntent.new()
		if k == 0:
			if kind == "light":
				i.light = true
			elif kind == "heavy":
				i.heavy = true
			else:
				i.sig = true
				i.sigHeld = true
		SimCore.step(S, [i, SimIntent.new()])
		var ev := []
		for e in S.out.fx:
			var s: String = String(e.type)
			if s == "cue":
				s += ":" + String(e.kind) + "/" + String(e.text)
			elif String(e.kind) != "":
				s += ":" + String(e.kind)
			ev.append(s)
		for fe in S.out.feed:
			ev.append("feed:" + str(fe).substr(0, 40))
		out.ticks.append({"k": k, "tick": S.tick, "q": SimAct.peek(me).size(), "ex": S.dirS.ex != null, "who": DirBands.who(S), "rush": me.rush != null,
			"state": me.state, "dx": int(SimWrap.sdx(x0, me.x)), "cool": snappedf(S.dirS.cool, 0.01), "ev": ev})
		S.out.fx.clear()
		S.out.feed.clear()
	print(JSON.stringify(out))
	quit()
