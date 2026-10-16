extends SceneTree
## Diagnostic for the guessed perfect block (needs pg.cjs applied): the same scripted player as pg1.gd. For each charge
## of his: did the AI try (GUESS_AT set as it started), did it press (GUESS_P set), and the ticks from its press to the
## blow's landing (the window is 14), or why there was no press. -- <matches> <seed0> [--level=medium]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	for s in args:
		if s.begins_with("--level="):
			DirAI.level = s.substr(8)
	var r := {"charges": 0, "tries": 0, "presses": 0, "released": 0, "triedReleased": 0, "pressedReleased": 0, "gapHist": {}, "releaseN": {}, "pressN": {}}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {"p1": false, "p2": true}, {"v2": [true, false]})
		var me = S.fighters[0]
		var him = S.fighters[1]
		var last := -1000
		var bUntil := -1
		var k := 0
		var tried := false
		var pressAt := -1
		var holdAt := 0
		var prevAt := 0
		var prevP := 0
		while S.tick < 18000 and S.game.ko == null:
			var it := SimIntent.new()
			if S.tick % 150 == 40:
				k += 1
				bUntil = S.tick + 36 + (k * 17) % 37
				it.sig = true
			if S.tick < bUntil:
				it.sigHeld = true
			elif S.tick - last >= 8:
				it.light = true
				last = S.tick
			var stepped: bool = SimCore.step(S, [it, null])
			if not stepped and last == S.tick - 1:
				last = -1000
			var ga: int = DirBrawl._g(him, DirBrawl.GUESS_AT)
			var gp: int = DirBrawl._g(him, DirBrawl.GUESS_P)
			if ga > 0 and prevAt == 0:
				tried = true
			if gp > 0 and prevP == 0:
				pressAt = gp
				var pn: int = DirBrawl._now(S) - DirBrawl._g(me, DirBrawl.HOLD_AT)
				r.pressN[str(pn / 5 * 5)] = int(r.pressN.get(str(pn / 5 * 5), 0)) + 1
				r.presses += 1
			prevAt = ga
			prevP = gp
			for e in S.out.fx:
				if e.type != "cue" or int(e.actor) != 0:
					continue
				if String(e.kind) == "windup" and String(e.text) == "charge":
					r.charges += 1
					tried = false
					pressAt = -1
					holdAt = DirBrawl._g(me, DirBrawl.HOLD_AT)
					# the try is drawn on this same tick
					if DirBrawl._g(him, DirBrawl.GUESS_AT) > 0:
						tried = true
						r.tries += 1
				elif String(e.kind) == "blow" and String(e.text) == "release":
					r.released += 1
					var rn: int = DirBrawl._now(S) - holdAt
					r.releaseN[str(rn / 5 * 5)] = int(r.releaseN.get(str(rn / 5 * 5), 0)) + 1
					if tried:
						r.triedReleased += 1
					if pressAt > 0:
						r.pressedReleased += 1
						var g: int = int(e.n) - pressAt
						r.gapHist[str(g)] = int(r.gapHist.get(str(g), 0)) + 1
					tried = false
					pressAt = -1
			S.out.fx.clear()
			S.out.feed.clear()
	print(JSON.stringify(r))
	quit()
