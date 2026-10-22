extends SceneTree
## Probe: 4c and 4d.
##  --mode=approach: slot 0 a standing player, slot 1 the AI, 14,000 units apart at the start. The AI's top speed in free
##    flight at him (closing on him) while more than 2,000 units away, over the first 900 ticks, per match; and its top
##    speed flying away (its Escape, which 4d doesn't hold). --cap: approachCap on in memory.
##  --mode=windows: AI v AI with hit-stop by weight on (the setup's own). On the first live tick after each freeze, every
##    pending strike with a perfect-block window open on its defender (not a brawl light): its live ticks left; how many
##    are under 5, by class. window_hold cues and perfect blocks counted. --fzoff: freezeWindows.minLiveTicks 0 in memory.
## -- <matches> <seed0> [--mode=approach|windows] [--cap] [--fzoff] [--ticks=10800]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var mode := "windows"
	var ticks := 10800
	for s in args:
		if s.begins_with("--mode="):
			mode = s.substr(7)
		elif s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	if args.has("--cap"):
		DirAI.skill()["approachCap"]["enabled"] = true
	if args.has("--fzoff"):
		DirInterrupt.data()["freezeWindows"]["minLiveTicks"] = 0
	var r := {"mode": mode, "matches": n, "cap": args.has("--cap"), "fzoff": args.has("--fzoff")}
	if mode == "approach":
		r["top"] = []
		r["away"] = []
		for m in range(n):
			var S := SimCore.createSim()
			SimCore.newMatch(S, seed0 + m, {"p1": false, "p2": true}, {"v2": [true, true]})
			S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 14000.0)
			var top := 0.0
			var away := 0.0
			for t in range(900):
				SimCore.step(S, [SimIntent.new(), null])
				var a = S.fighters[1]
				var sd: float = SimWrap.sdx(a.x, S.fighters[0].x)
				if a.state == "free" and absf(sd) > 2000.0:
					if a.vx * sd > 0.0:
						top = maxf(top, SimDetMath.hypot(a.vx, a.vy))
					else:
						away = maxf(away, SimDetMath.hypot(a.vx, a.vy))
				S.out.fx.clear()
				S.out.feed.clear()
			r.top.append(int(top))
			r.away.append(int(away))
	else:
		r["afterFreeze"] = 0
		r["under5"] = {}
		r["minLeft"] = {}
		r["holds"] = 0
		r["perfects"] = 0
		r["freezes"] = 0
		r["minutes"] = 0.0
		for m in range(n):
			var S := SimCore.createSim()
			SimCore.newMatch(S, seed0 + m, {}, {"hitstop": true})
			var wasFrozen := false
			for t in range(ticks):
				var t0: float = S.T
				SimCore.step(S)
				var live: bool = S.T != t0
				if live and wasFrozen and S.dirS.ex != null:
					r.freezes += 1
					var ex = S.dirS.ex
					for b in ex.beats:
						if b.done or b.op != "strike" or b.args == null or not (b.args.get("o") is Dictionary) or b.args.get("sure", false):
							continue
						var cls: String = String(b.args.o.get("class", ""))
						if cls == "" or cls == "blow":
							continue
						var d = ex.D if String(b.args.get("d", "D")) == "D" else ex.A
						var w: float = DirInterrupt._window(d, cls, ex.kind == "heavy")
						if w < 5.0:
							continue
						var left: float = (b.t - ex.t) * DirData.TICKS_PER_SEC
						if left > w + 0.5:
							continue
						r.afterFreeze += 1
						r.minLeft[cls] = minf(float(r.minLeft.get(cls, 999.0)), snappedf(left, 0.1))
						if left < 4.999:
							r.under5[cls] = int(r.under5.get(cls, 0)) + 1
				wasFrozen = not live
				for e in S.out.fx:
					if String(e.type) == "cue" and String(e.kind) == "window_hold":
						r.holds += 1
					elif String(e.type) == "cue" and String(e.kind) == "perfect_block":
						r.perfects += 1
				S.out.fx.clear()
				S.out.feed.clear()
				if S.game.ko != null:
					break
			r.minutes += S.T / 60.0
		r["minutes"] = snappedf(r.minutes, 0.1)
	print(JSON.stringify(r))
	quit()
