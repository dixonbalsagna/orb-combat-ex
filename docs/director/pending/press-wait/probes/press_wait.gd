extends SceneTree
## Probe (7a), each waiting tick put down to its reason. Slot 0 a scripted player (v2): toward the rival when out of reach,
## a light every 6 to 25 ticks (a heavy one press in 5), its own LCG; slot 1 the AI. For each of the player's presses made
## with no exchange running and the director's cooldown on (after a match's first exchange), until his exchange or
## approach starts: each tick's reason, in DirExchange._start's order (an exchange or approach running, he not free or
## stunned, the rival safe out of his crater, THE COOLDOWN (DirPress.held), the rival launched or locked, else other).
## Reads: ticks by reason; the cooldown's own ticks for a press (worst, by the end kind: at most the cap, 6 or 12); the
## cooldown's ticks past the end plus the cap (must be 0); the presses the cooldown alone held to the end (it held them
## and nothing else did). --off: press.capTicks -1 in memory (as before 7a).
## -- <matches> <seed0> [--ticks=10800] [--off]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 5
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var ticks := 10800
	for s in args:
		if s.begins_with("--ticks="):
			ticks = int(s.substr(8))
	if args.has("--off"):
		DirInterrupt.data()["press"]["capTicks"] = -1
	var r := {"off": args.has("--off"), "matches": n, "presses": 0, "tracked": 0, "byReason": {}, "coolTicks": {}, "worstCool": {"exchange": 0, "setpiece": 0},
		"coolPastCap": 0, "worstPastCap": 0, "minutes": 0.0}
	var lcg: int = 12345
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {"p1": false, "p2": true}, {"v2": [true, true], "intro": false})
		var me = S.fighters[0]
		var ai = S.fighters[1]
		var next: int = 40
		var track = null   # {at, end, kind, cool, past}
		var endTick: int = -1
		var endKind: String = "exchange"
		for t in range(ticks):
			var i := SimIntent.new()
			var d: float = SimWrap.sdx(me.x, ai.x)
			if absf(d) > 300.0:
				i.mx = 1.0 if d > 0.0 else -1.0
			var pressed := false
			if S.tick >= next and me.state == "free":
				lcg = (lcg * 1103515245 + 12345) % 2147483648
				if lcg % 5 == 0:
					i.heavy = true
				else:
					i.light = true
				pressed = true
				next = S.tick + 6 + int(lcg >> 8) % 20
			if pressed:
				r.presses += 1
			if pressed and track == null and S.dirS.ex == null and DirBands.who(S) < 0 and S.dirS.cool > 0.0 and S.dirS.exN > 0:
				track = {"at": S.tick, "end": endTick, "kind": endKind, "cool": 0, "past": 0}
				r.tracked += 1
			var exBefore = S.dirS.ex
			SimCore.step(S, [i, null])
			if exBefore != null and S.dirS.ex == null:
				endTick = S.tick
				endKind = "setpiece" if DirPress._setPiece(S, exBefore) else "exchange"
			if track == null:
				S.out.fx.clear()
				S.out.feed.clear()
				if S.game.ko != null:
					break
				continue
			var mine: bool = (S.dirS.ex != null and S.dirS.ex.A == me) or DirBands.who(S) == 0
			if mine or (S.dirS.ex != null) or SimAct.peek(me).is_empty():
				# started (or the rival's exchange took over, or his request was spent): the press is done
				if not mine:
					var k0: String = "ended otherwise"
					r.byReason[k0] = int(r.byReason.get(k0, 0)) + 1
				var kd: String = String(track.kind)
				r.worstCool[kd] = maxi(int(r.worstCool[kd]), int(track.cool))
				r.coolTicks[str(track.cool)] = int(r.coolTicks.get(str(track.cool), 0)) + 1
				r.worstPastCap = maxi(int(r.worstPastCap), int(track.past))
				track = null
			else:
				var D = ai
				var why: String = "other"
				if DirBands.who(S) >= 0:
					why = "approach"
				elif me.state != "free" and me.state != "charging":
					why = "not free"
				elif me.stunTicks > 0:
					why = "stunned"
				elif DirBury.safe(S, D):
					why = "rival safe"
				elif DirPress.held(S, me):
					why = "cooldown"
				elif D.state == "launched" or D.state == "locked":
					why = "rival " + String(D.state)
				r.byReason[why] = int(r.byReason.get(why, 0)) + 1
				if why == "cooldown":
					track.cool += 1
					var cap: int = int(DirPress.cfg().get("setPieceCapTicks", 12)) if String(track.kind) == "setpiece" else int(DirPress.cfg().get("capTicks", 6))
					if int(track.end) >= 0 and S.tick > int(track.end) + cap:
						track.past += 1
						r.coolPastCap += 1
			S.out.fx.clear()
			S.out.feed.clear()
			if S.game.ko != null:
				break
		r.minutes += S.T / 60.0
	r["minutes"] = snappedf(r.minutes, 0.1)
	print(JSON.stringify(r))
	quit()
