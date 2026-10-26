extends SceneTree
## wat.gd: drops into water (Game Design's rulings-2026-10-26 row 6), with water.enabled set in memory (and --off for the
## rule off). From a copy's root with the park in: godot --headless --path . --script res://wat.gd -- <runs> <seed0> [--off] [--dive]
## Each run: both fighters players with no input, over the middle of the longest open water (World's surfaceAt, not
## waded), 200 units up; one is dropped (the zip's knock-down: 24 ticks, falling at 900 u/s). With --dive the dropped one
## holds the stick down the whole time (the rule lifts him whatever he presses).
## Reads: the live ticks from going under to the surface cue and to being set at it, his state and height then against
## the surface, and with --off where he is after 300 ticks.

func _init() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(a[0]) if a.size() > 0 else 5
	var seed0: int = int(a[1]) if a.size() > 1 else 1
	var off: bool = a.has("--off")
	var dive: bool = a.has("--dive")
	var w: Dictionary = DirInterrupt.data().get("water", {})
	w["enabled"] = not off
	var runs := []
	for k in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + k, {"p1": true, "p2": true}, {"v2": [true, true], "intro": false})
		for q in range(60):
			SimCore.step(S, [SimIntent.new(), SimIntent.new()])
		var me = S.fighters[0]
		var it = S.fighters[1]
		var x: float = -1.0   # the middle of the longest run of water the rule sees
		var best: int = 0
		var run: int = 0
		for col in range(SimConst.NC):
			var cx: float = float(col) * SimConst.COL
			if DirWater.top(S, cx) > DirWater.DRY:
				run += 1
				if run > best and run >= 24:
					best = run
					x = cx - float(run / 2) * SimConst.COL
			else:
				run = 0
		if x < 0.0:
			runs.append({"err": "no open water"})
			SimCore.dispose(S)
			continue
		S.dirS.ex = null
		S.dirS.cool = 0.0
		for f in [me, it]:
			f.state = "free"
			f.rush = null
			f.vx = 0.0
			f.vy = 0.0
			f.stunTicks = 0
		me.x = SimWrap.wrap(x - 400.0)
		it.x = x
		me.y = 200.0 + DirWater.top(S, me.x)
		it.y = 200.0 + DirWater.top(S, it.x)
		SimFighter.drop(S, it, 24, 0.0, -900.0)
		S.out.fx.clear()
		var out := {"x": snappedf(x, 1.0), "span": best, "under": -1, "surface": -1, "set": -1, "state": "", "y": 0.0, "top": 0.0, "dropEnd": ""}
		var t0: int = DirBrawl._now(S)
		for t in range(300):
			var ii := SimIntent.new()
			if dive:
				ii.my = -1.0
			SimCore.step(S, [SimIntent.new(), ii])
			var lt: int = DirBrawl._now(S) - t0
			var top: float = DirWater.top(S, it.x)
			if out.under < 0 and it.y < top:
				out.under = lt
			for e in S.out.fx:
				if String(e.type) == "cue" and String(e.kind) == "water" and int(e.actor) == 1:
					if String(e.text) == "surface" and out.surface < 0:
						out.surface = lt
					elif String(e.text) == "surfaced" and out.set < 0:
						out.set = lt
				elif String(e.type) == "drop_end" and int(e.actor) == 1 and out.dropEnd == "":
					out.dropEnd = str(e.get("kind")) + "@" + str(lt)
			S.out.fx.clear()
			S.out.feed.clear()
			if not off and out.set >= 0:
				break
		out.state = it.state
		out.y = snappedf(it.y, 0.1)
		out.top = snappedf(DirWater.top(S, it.x), 0.1)
		if out.under >= 0 and out.set >= 0:
			out["underToSet"] = out.set - out.under
		runs.append(out)
		SimCore.dispose(S)
	print(JSON.stringify({"off": off, "dive": dive, "runs": runs}))
	quit()
