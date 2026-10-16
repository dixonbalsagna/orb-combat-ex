extends SceneTree
## Probe: the beam struggle as a tug of war (rule-of-cool.md section 2). --mode=ai: the AI on both slots. Otherwise
## slot 0 is a scripted player against the AI at --level: outside a struggle X every 8 ticks and a signature (B with
## the energy family) every 90 ticks and every 6 through the AI's beam tell, so that beams fly and clash; inside one,
## by --mode: beat (a press the tick after each pulse's cue),
## late (3 ticks after it), mash (every 3 ticks) or none. Each struggle is followed to its end: the head start, the
## surges and strays of each side, whether the point crossed the middle, how it ended and who won, and whether the
## winner was more than 10% down at some point. -- <matches> <seed0> [--mode=ai|beat|late|mash|none] [--level=medium]
## [--cap=18000]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
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
	var r := {"mode": mode, "level": DirAI.level, "matches": n, "struggles": 0, "ends": {}, "evenStart": 0, "moreSurgesWon": 0,
		"crossed": 0, "fromBehind": 0, "playerIn": 0, "playerWon": 0, "playerLost": 0, "playerDrew": 0, "playerOverwhelmed": 0,
		"ticks": [], "surgesPerSide": 0, "straysPerSide": 0}
	for m in range(n):
		var S := SimCore.createSim()
		var human: bool = mode != "ai"
		SimCore.newMatch(S, seed0 + m, {"p1": not human, "p2": true}, {"v2": [true, false]})
		var me = S.fighters[0]
		var last := -1000
		var st = null
		var side := ""
		var pulseSeen := -1000
		var t0 := 0
		while S.tick < cap and S.game.ko == null:
			var it := SimIntent.new()
			var inS: bool = st != null and side != ""
			if human:
				if inS:
					var since: int = S.tick - pulseSeen
					if mode == "beat" and since == 1:
						it.light = true
					elif mode == "late" and since == 3:
						it.light = true
					elif mode == "mash" and S.tick % 3 == 0:
						it.light = true
				elif S.tick % 90 == 45 or (S.dirS.ex != null and S.dirS.ex.kind == "sig" and S.dirS.ex.A != me and S.game.clash == null and S.tick % 6 == 0):
					it.mode = 1   # with the energy family held, B is the signature: his own beam, or his answer to the AI's
					it.sig = true
				elif S.tick - last >= 8:
					it.light = true
					last = S.tick
			SimCore.step(S, [it, null] if human else null)
			var ex = S.dirS.ex
			if st == null and ex != null and S.game.clash != null:
				var rb = DirBeam._struggleBeat(ex)
				if rb != null:
					st = rb.args.bs
					side = "A" if ex.A == me else ("D" if ex.D == me else "")
					t0 = S.tick
			for e in S.out.fx:
				if e.type != "cue":
					continue
				var ck: String = String(e.kind)
				if ck == "beam_pulse":
					pulseSeen = S.tick
				elif ck == "beam_end" and st != null:
					r.struggles += 1
					var how: String = String(e.text)
					r.ends[how] = int(r.ends.get(how, 0)) + 1
					r.ticks.append(S.tick - t0)
					var mid: float = float(st.mid)
					var head: float = float(st.head)
					var winA: bool = mid > 0.5
					var drew: bool = how == "detonate"
					var sa: int = int(st.surgesA)
					var sd: int = int(st.surgesD)
					r.surgesPerSide += sa + sd
					r.straysPerSide += int(st.straysA) + int(st.straysD)
					if absf(head) < 0.10 and not drew and sa != sd:
						r.evenStart += 1
						if (sa > sd) == winA:
							r.moreSurgesWon += 1
					if bool(st.crossed):
						r.crossed += 1
					if not drew and ((winA and float(st.minMid) < 0.4) or (not winA and float(st.maxMid) > 0.6)):
						r.fromBehind += 1
					if side != "":
						r.playerIn += 1
						if drew:
							r.playerDrew += 1
						elif winA == (side == "A"):
							r.playerWon += 1
						else:
							r.playerLost += 1
							if how == "overwhelmed":
								r.playerOverwhelmed += 1
					st = null
					side = ""
			S.out.fx.clear()
			S.out.feed.clear()
	var tk: Array = r.ticks
	tk.sort()
	r.ticks = {"n": tk.size(), "median": tk[tk.size() / 2] if tk.size() > 0 else -1}
	r.surgesPerSide = snappedf(float(r.surgesPerSide) / maxf(1.0, 2.0 * float(r.struggles)), 0.01)
	r.straysPerSide = snappedf(float(r.straysPerSide) / maxf(1.0, 2.0 * float(r.struggles)), 0.01)
	print(JSON.stringify(r))
	quit()
