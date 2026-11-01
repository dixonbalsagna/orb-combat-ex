extends SceneTree
## The swing's bands, read from seeded AI matches with the switch on (game-design.md sections 2, 10, 11). For QA to fold in.
##   godot --headless --path . --script res://sim/director/tools/swing_read.gd -- <matches> <seed0> [--cap=25200]
## Plays on field worlds, QA's four planets and four touches. Prints one line of JSON: big swings and jolts a match, a share of
## fight time, by cause, sizes, the shortest gaps, the rest before a landing, what a standing fighter's ground did, and the
## civilian share at the end for the band.

const PLANETS := [3, 7, 11, 13]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var cap := 25200
	for s in args:
		if s.begins_with("--cap="):
			cap = int(s.substr(6))
	DirSwing.setForce(1)
	var r := {"matches": n, "ticks": 0, "swingTicks": 0, "big": 0, "jolts": 0, "nudges": 0, "asks": 0, "byCause": {}, "sizeBuckets": {}, "minGapBig": 1.0e9, "minGapJolt": 1.0e9, "asksByCause": {}, "standingMaxSweep": 0.0, "landMoving": 0, "landMovingBy": {}, "launchesFlown": 0, "civLost": []}
	for m in range(n):
		var seed: int = seed0 + m
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed, {}, {"planet": PLANETS[(seed - 1) % 4], "touch": ((seed - 1) / 4) % 4, "planetGen": 3, "intro": false})
		if S.frame == null:
			print("planet %d touch %d has no field world" % [PLANETS[(seed - 1) % 4], ((seed - 1) / 4) % 4])
			quit(3)
			return
		var lastBig := -1
		var lastJolt := -1
		var pop0: float = _pop(S)
		var was := ["", ""]
		var stood := [false, false]
		var xs := [0.0, 0.0]
		while S.tick < cap and S.game.ko == null:
			xs[0] = float(S.fighters[0].x)
			xs[1] = float(S.fighters[1].x)
			var pv: float = SimSwing._pivot(S)
			SimCore.step(S)
			r.ticks += 1
			var running: bool = S.swing.active
			var small: bool = S.swing.cause == "small"
			if running and S.swing.rate > 0.0:
				r.swingTicks += 1
				for k in range(2):
					var f = S.fighters[k]
					if SimSwing._standing(S, f):
						var sweep: float = absf(SimWrap.sdx(xs[k], pv)) * S.swing.rate * SimMathx.PI / 180.0   # where the law saw him: a blitz may warp him after it
						if not small and stood[k]:   # (the tick he lands on, the law hasn't seen him yet)
							r.standingMaxSweep = maxf(float(r.standingMaxSweep), sweep)
			for k in range(2):
				stood[k] = SimSwing._standing(S, S.fighters[k])
			for k in range(2):
				var st: String = S.fighters[k].state
				if was[k] == "launched" and st != "launched" and running and not small and S.swing.rate > 20.0:
					r.landMoving += 1
					r.landMovingBy[str(S.swing.cause)] = int(r.landMovingBy.get(str(S.swing.cause), 0)) + 1
				was[k] = st
			for e in S.out.fx:
				if e.type != "cue":
					continue
				if e.kind == "swing_place":
					var cause: String = str(e.source)
					r.byCause[cause] = int(r.byCause.get(cause, 0)) + 1
					if cause == "jolt":
						r.jolts += 1
						if lastJolt >= 0:
							r.minGapJolt = minf(float(r.minGapJolt), float(S.tick - lastJolt) / 60.0)
						lastJolt = S.tick
					else:
						r.big += 1
						if lastBig >= 0:
							r.minGapBig = minf(float(r.minGapBig), float(S.tick - lastBig) / 60.0)
						lastBig = S.tick
						var b: String = str(int(absf(float(e.amount)) / 30.0) * 30)
						r.sizeBuckets[b] = int(r.sizeBuckets.get(b, 0)) + 1
				elif e.kind == "swing_nudge":
					r.nudges += 1
			for l in S.out.feed:
				if String(l.tag).begins_with("SWING "):
					r.asks += 1
					var ck: String = String(l.tag).substr(6)
					r.asksByCause[ck] = int(r.asksByCause.get(ck, 0)) + 1
			S.out.fx.clear()
			S.out.feed.clear()
		(r.civLost as Array).append(snappedf(1.0 - _pop(S) / maxf(1.0, pop0), 0.001))
		SimCore.dispose(S)
	r["bigPerMatch"] = snappedf(float(r.big) / float(n), 0.01)
	r["joltsPerMatch"] = snappedf(float(r.jolts) / float(n), 0.01)
	r["nudgesPerMatch"] = snappedf(float(r.nudges) / float(n), 0.01)
	r["fightShare"] = snappedf(100.0 * float(r.swingTicks) / maxf(1.0, float(r.ticks)), 0.01)
	r["minutes"] = snappedf(float(r.ticks) / 3600.0 / float(n), 0.01)
	print("SWING " + JSON.stringify(r))
	quit()


func _pop(S) -> float:
	var t: float = 0.0
	for b in S.buildings:
		t += float(b.popAlive)
	return t
