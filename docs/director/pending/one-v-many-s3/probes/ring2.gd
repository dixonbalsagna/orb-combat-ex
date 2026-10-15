extends SceneTree
## Scratch probe of stage 2's press rows: slot 0 is a scripted player who presses X every 8 ticks on the match clock
## and holds his stick toward his partner; every other body is the AI. For 2 (a 1v1, the baseline), 3, 4 and 5
## bodies: his presses, the blows he threw (the brawl's blow cue), and every press_ack he got, by its reason.
## -- <matches a count> <seed0> [--ticks=18000] [--counts=2,3,4,5]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 3
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var cap := 18000
	var counts := [2, 3, 4, 5]
	for s in args:
		if s.begins_with("--ticks="):
			cap = int(s.substr(8))
		if s.begins_with("--counts="):
			counts = []
			for c in s.substr(9).split(","):
				counts.append(int(c))
	var out := {}
	for nb in counts:
		var r := {"matches": n, "presses": 0, "blows": 0, "acks": {}, "tags": 0, "pressesInQuiet": 0}
		for m in range(n):
			var S := SimCore.createSim()
			var slots := ["PROTAGONIST"]
			var ai := {"p1": false}
			for k in range(1, nb):
				slots.append("RIVAL")
				ai["p" + str(k + 1)] = true
			SimCore.newMatch(S, seed0 + m, ai, {"slots": slots} if nb > 2 else {})
			var one = S.fighters[0]
			var last := -1000
			while S.tick < cap and S.game.ko == null:
				var it := SimIntent.new()
				var p = DirRing.partner(S, one)
				it.mx = SimMathx.jsign(SimWrap.sdx(one.x, p.x))
				var pressed := false
				if S.tick - last >= 8:
					it.light = true
					last = S.tick
					pressed = true
				var quiet: bool = S.dirS.ex == null
				var stepped: bool = SimCore.step(S, [it, null])
				if pressed:
					if stepped:
						r.presses += 1
						if quiet:
							r.pressesInQuiet += 1
					else:
						last = -1000   # a press made in a freeze is not read: press again
				for e in S.out.fx:
					if e.type == "cue" and int(e.actor) == 0:
						var ck: String = String(e.kind)
						if ck == "blow":
							r.blows += 1
						elif ck == "press_ack":
							r.acks[String(e.text)] = int(r.acks.get(String(e.text), 0)) + 1
					elif e.type == "cue" and String(e.kind) == "ring_tag":
						r.tags += 1
				S.out.fx.clear()
				S.out.feed.clear()
		r["blowsAPress"] = snappedf(float(r.blows) / maxf(1.0, float(r.presses)), 0.001)
		out[str(nb) + " bodies"] = r
	print(JSON.stringify(out))
	quit()
