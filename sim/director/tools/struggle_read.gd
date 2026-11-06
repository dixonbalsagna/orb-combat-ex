extends SceneTree
## The beam struggle's reads (rule-of-cool.md section 2, QA's rows). --mode=ai: the AI on both slots. Otherwise slot 0 is a
## scripted player against the AI at --level: outside a struggle X every 8 ticks and a signature (B with the energy family)
## every 90 ticks and every 6 through the AI's beam tell, so that beams fly and clash; inside one, by --mode:
##   two, three, four (a press that many ticks after each pulse), mash (every 3 ticks), turbo (every 6), none, letgo (A 2
##   ticks after a pulse, once the point is in the quarter nearest him), caught (A off the pulse, same place).
##   godot --headless --path . --script res://sim/director/tools/struggle_read.gd -- <matches> <seed0> [--mode=ai] [--level=medium] [--cap=18000]
## Prints one line of JSON: how they end, how long they last, who won, and the AI's share of pulses, drawn and landed.


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var mode := "ai"
	var cap := 18000
	for s in args:
		if s.begins_with("--mode="):
			mode = s.substr(7)
		elif s.begins_with("--level="):
			DirAI.level = s.substr(8)
		elif s.begins_with("--cap="):
			cap = int(s.substr(6))
	var r := {"mode": mode, "level": DirAI.level, "matches": n, "struggles": 0, "ends": {}, "evenStart": 0, "moreSurgesWon": 0,
		"crossed": 0, "winners": 0, "fromBehind": 0, "playerIn": 0, "playerWon": 0, "playerLost": 0, "playerDrew": 0, "playerOverwhelmed": 0,
		"ticks": [], "aiDrawn": 0, "aiPulsesAll": 0, "aiPressed": 0, "aiPulsesSeen": 0, "strays": 0, "void": 0, "letgo": 0}
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
		var lo := 1.0
		var hi := 0.0
		var crossed := false
		var was := 0.5
		var seen := 0
		var cnt := {"A": 0, "D": 0}
		while S.tick < cap and S.game.ko == null:
			var it := SimIntent.new()
			it.mode = 0   # an Arena pad's edges, not Simple's rising levels (SimPressRead.struggle_press)
			if human:
				if st != null and side != "":
					var since: int = S.tick - pulseSeen
					var nearMe: float = float(S.game.clash.mid) if side == "A" else 1.0 - float(S.game.clash.mid)
					match mode:
						"two":
							it.light = since == 1   # the cue is seen a tick after its pulse, and this press lands a tick later
						"three":
							it.light = since == 2
						"four":
							it.light = since == 3
						"mash":
							it.light = S.tick % 3 == 0
						"turbo":
							it.light = S.tick % 6 == 0
						"letgo":
							it.context = since == 1 and nearMe <= 0.25
						"caught":
							it.context = since == 10 and nearMe <= 0.25
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
					was = float(S.game.clash.mid)
					lo = was
					hi = was
					crossed = false
					seen = 0
					cnt = {"A": 0, "D": 0}
					for sd in ["A", "D"]:
						if (ex.A if sd == "A" else ex.D).ai != null:
							r.aiDrawn += (st["ai" + sd] as Array).size()
							r.aiPulsesAll += int(DirBeam._bs().pulses)
			if st != null and S.game.clash != null:
				var mm: float = float(S.game.clash.mid)
				if (was - 0.5) * (mm - 0.5) < 0.0:
					crossed = true
				was = mm
				lo = minf(lo, mm)
				hi = maxf(hi, mm)
			for e in S.out.fx:
				if e.type != "cue":
					continue
				var ck: String = String(e.kind)
				if ck == "beam_pulse":
					pulseSeen = S.tick
					seen += 1
				elif ck == "beam_stray" and st != null:
					if String(e.text) == "void":
						r.void += 1
					else:
						r.strays += 1
				elif ck == "beam_clash_end":
					r["clashEnd:" + String(e.text)] = int(r.get("clashEnd:" + String(e.text), 0)) + 1
					if not r.has("clashEndAt"):
						r["clashEndAt"] = "x %.0f y %.0f z %.1f energy %.0f surges %d winner %d" % [e.x, e.y, e.z, e.energy, int(e.n), int(e.winner)]
				elif ck == "beam_end" and st != null:
					r.struggles += 1
					var how: String = String(e.text)
					if String(e.source) == "letgo":
						how = "letgo"
						r.letgo += 1
					r.ends[how] = int(r.ends.get(how, 0)) + 1
					r.ticks.append(S.tick - t0)
					var mid: float = float(st.mid)
					var head: float = float(st.head)
					var winA: bool = mid > 0.5
					if how == "letgo":
						winA = st.letGo == "D"
					var drew: bool = how == "detonate"
					var sa: int = int(st.surgesA)
					var sd: int = int(st.surgesD)
					if ex != null:
						for q in [["A", ex.A, sa], ["D", ex.D, sd]]:
							if q[1].ai != null:
								r.aiPressed += int(q[2])
								r.aiPulsesSeen += seen
					if absf(head) < 0.10 and not drew and sa != sd:
						r.evenStart += 1
						if (sa > sd) == winA:
							r.moreSurgesWon += 1
					if crossed:
						r.crossed += 1
					if not drew:
						r.winners += 1
						if (winA and lo < 0.4) or (not winA and hi > 0.6):
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
		SimCore.dispose(S)
	var tk: Array = r.ticks
	tk.sort()
	r.ticks = {"n": tk.size(), "median": tk[tk.size() / 2] if tk.size() > 0 else -1}
	r["aiDrawnShare"] = snappedf(float(r.aiDrawn) / maxf(1.0, float(r.aiPulsesAll)), 0.001)
	r["aiPressedShare"] = snappedf(float(r.aiPressed) / maxf(1.0, float(r.aiPulsesSeen)), 0.001)
	print(JSON.stringify(r))
	quit()
