extends SceneTree
## Probe: the AI's perfect block against a charged heavy (Game Design's eleventh round, item 3). Slot 0 is a scripted
## player: X every 8 ticks on the match clock, and every 150 ticks a B held for 36 to 72 ticks (a different length each
## time), so that most of his Bs are charges let go at a spread of moments. Slot 1 is the AI at --level. It counts his
## charged heavies (a release after a windup cue with text charge) and the AI's perfect blocks within 40 ticks of one
## (freezes push the landing), each by when the AI's last guard press came: pressBefore (before the release),
## sameTick, pressAfter (after it: in practice a block of another blow inside those 40 ticks). It also counts the
## AI's fresh guard presses on a release's tick (pressSameTick) and 1 to 14 ticks after it before it lands
## (pressAfterRelease): presses, not blocks.
## -- <matches> <seed0> [--level=medium] [--cap=18000]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var cap := 18000
	for s in args:
		if s.begins_with("--level="):
			DirAI.level = s.substr(8)
		if s.begins_with("--cap="):
			cap = int(s.substr(6))
	var r := {"matches": n, "level": DirAI.level, "releases": 0, "tapReleases": 0, "perfect": 0, "pressBefore": 0, "sameTick": 0, "pressAfter": 0,
		"pressAfterRelease": 0, "pressSameTick": 0, "heavyTaps": 0, "perfectTaps": 0}
	for m in range(n):
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {"p1": false, "p2": true}, {"v2": [true, false]})
		var him = S.fighters[1]
		var last := -1000
		var bUntil := -1
		var k := 0
		var rel := []          # [release tick, landing tick] of his charged heavies still to land
		var taps := []         # landing ticks of his tapped heavies (a windup start cue of his, cell b, not charged)
		var lastGuard: int = DirInterrupt.gi(him, DirInterrupt.GUARD_AT)
		var charging := false  # his heavy's charge started (a windup cue with text charge): its release is a charged one
		while S.tick < cap and S.game.ko == null:
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
			var g: int = DirInterrupt.gi(him, DirInterrupt.GUARD_AT)
			if g != lastGuard:
				lastGuard = g
				for q in rel:
					if g == int(q[0]):
						r.pressSameTick += 1
						break
					if g - int(q[0]) >= 1 and g - int(q[0]) <= 14 and g <= int(q[1]):
						r.pressAfterRelease += 1
						break
			for e in S.out.fx:
				if e.type != "cue":
					continue
				var ck: String = String(e.kind)
				if ck == "windup" and String(e.text) == "charge" and int(e.actor) == 0:
					charging = true
				elif ck == "blow" and String(e.text) == "release" and int(e.actor) == 0:
					if charging:
						r.releases += 1
						rel.append([int(e.amount), int(e.n)])
					else:
						r.tapReleases += 1
					charging = false
				elif ck == "perfect_block" and int(e.actor) == 1:
					var hit := false
					for q in rel:
						if S.tick >= int(q[0]) and S.tick - int(q[0]) <= 40:   # within 40 ticks of its release (freezes push the landing)
							hit = true
							r.perfect += 1
							var ga: int = DirInterrupt.gi(him, DirInterrupt.GUARD_AT)
							if ga < int(q[0]):
								r.pressBefore += 1
							elif ga == int(q[0]):
								r.sameTick += 1
							else:
								r.pressAfter += 1
							rel.erase(q)
							break
					if not hit:
						for t in taps:
							if absi(S.tick - int(t)) <= 3:
								r.perfectTaps += 1
								break
				elif ck == "windup" and String(e.text) == "start" and int(e.actor) == 0 and String(e.source) == "b":
					r.heavyTaps += 1
					taps.append(int(e.n))
			var keep := []
			for q in rel:
				if S.tick - int(q[0]) <= 40:
					keep.append(q)
			rel = keep
			S.out.fx.clear()
			S.out.feed.clear()
	r["perfectShare"] = snappedf(float(r.perfect) / maxf(1.0, float(r.releases)), 0.001)
	print(JSON.stringify(r))
	quit()
