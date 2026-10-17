extends SceneTree
## QA's read of the AI against charged attacks (Game Design's eleventh and twelfth rounds; Orb: "the CPU opponent was able to easily perfect block every charged attack I used").
## The method is Encounter's probe (docs/director/pending/perfect-guess/probes/pg1.gd), kept as QA's own so that it runs on any build and carries the wall cap and the validity fields.
## Slot 0 is a scripted player: X every 8 ticks on the match clock, and every 150 ticks a B (--cell=b, a charged heavy) or a Y (--cell=y, a charged medium) held for a different length each time
## (b: 36 to 72 ticks; y: 14 to 40), so that most of his holds are charges let go at a spread of moments. Slot 1 is the AI at --level. It counts:
##  - charges begun (a windup cue with text charge), releases (a release after one), and the AI's perfect blocks within 40 ticks of a release, each by when the AI's last guard press came:
##    pressBefore (before the release), sameTick, pressAfter;
##  - the HARD TEST: the AI's fresh guard presses on a release's tick (pressSameTick) and 1 to 14 ticks after it, before the blow lands (pressAfterRelease): none, at every level;
##  - the STALE MARK (the fault Encounter found on main: a press made at the wind-up's end marked the blow, and the mark stayed however long he held): perfect blocks whose AI press came more than 14 ticks
##    (the perfect window) before the blow landed. A guess made across the charge can only block with a press inside the window, so after the fix there are none;
##  - the rate by hold length: releases and perfect blocks by the charge's length in ticks from the charge cue to the release, in bins of 10 (byHold);
##  - the answers (the twelfth round: what rises by level): a perfect block, a blow that stops the charge before the release (the AI lands a damaging blow on him while he charges), or giving ground
##    (a miss cue with text gave_ground on his charged blow, within 45 ticks of the release).
## -- <matches> <seed0> [--level=medium] [--cell=b|y] [--cap=18000] [--wall=300] [--budget=3600]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 10
	var seed0: int = int(args[1]) if args.size() > 1 else 1
	var cap := 18000
	var cell := "b"
	var wall: float = 300.0
	var budget: float = 3600.0
	for s in args:
		if s.begins_with("--level="):
			DirAI.level = s.substr(8)
		elif s.begins_with("--cell="):
			cell = s.substr(7)
		elif s.begins_with("--cap="):
			cap = int(s.substr(6))
		elif s.begins_with("--wall="):
			wall = float(s.substr(7))
		elif s.begins_with("--budget="):
			budget = float(s.substr(9))
	var r := {"probe": "charge", "cell": cell, "level": DirAI.level, "requested": n, "n": 0, "wallCapped": 0, "budgetStopped": false, "charges": 0, "releases": 0, "tapReleases": 0, "perfect": 0,
		"pressBefore": 0, "sameTick": 0, "pressAfter": 0, "pressAfterRelease": 0, "pressSameTick": 0, "stale": 0, "stopped": 0, "gaveGround": 0, "byHold": {}}
	var t_start: int = Time.get_ticks_msec()
	for m in range(n):
		if float(Time.get_ticks_msec() - t_start) / 1000.0 > budget:
			r.budgetStopped = true
			break
		var t_match: int = Time.get_ticks_msec()
		var S := SimCore.createSim()
		SimCore.newMatch(S, seed0 + m, {"p1": false, "p2": true}, {"v2": [true, false]})
		var him = S.fighters[1]
		var last := -1000
		var held_until := -1
		var k := 0
		var rel := []          # [release tick, landing tick, hold length, answered] of his charged blows still to land
		var last_guard: int = DirInterrupt.gi(him, DirInterrupt.GUARD_AT)
		var charging := false  # his blow's charge started (a windup cue with text charge): its release is a charged one
		var cstart := -1       # the tick the charge began
		var capped := false
		while S.tick < cap and S.game.ko == null:
			if float(Time.get_ticks_msec() - t_match) / 1000.0 > wall:
				capped = true
				break
			var it := SimIntent.new()
			if S.tick % 150 == 40:
				k += 1
				if cell == "y":
					held_until = S.tick + 14 + (k * 7) % 27
					it.heavy = true
				else:
					held_until = S.tick + 36 + (k * 17) % 37
					it.sig = true
			if S.tick < held_until:
				if cell == "y":
					it.heavyHeld = true
				else:
					it.sigHeld = true
			elif S.tick - last >= 8:
				it.light = true
				last = S.tick
			var stepped: bool = SimCore.step(S, [it, null])
			if not stepped and last == S.tick - 1:
				last = -1000
			var g: int = DirInterrupt.gi(him, DirInterrupt.GUARD_AT)
			if g != last_guard:
				last_guard = g
				for q in rel:
					if g == int(q[0]):
						r.pressSameTick += 1
						break
					if g - int(q[0]) >= 1 and g - int(q[0]) <= 14 and g <= int(q[1]):
						r.pressAfterRelease += 1
						break
			for e in S.out.fx:
				if e.type == "damage":
					# a blow of the AI's that lands on him while he is still charging stops the charge (it never reaches a release)
					if charging and e.amount > 0.0 and int(e.attacker) == 1 and int(e.victim) == 0:
						r.stopped += 1
						charging = false
					continue
				if e.type != "cue":
					continue
				var ck: String = String(e.kind)
				if ck == "windup" and String(e.text) == "charge" and int(e.actor) == 0:
					charging = true
					cstart = S.tick
					r.charges += 1
				elif ck == "blow" and String(e.text) == "release" and int(e.actor) == 0:
					if charging:
						r.releases += 1
						var hold: int = S.tick - cstart if cstart >= 0 else -1
						var bin: String = str(clampi(hold / 10, 0, 6) * 10) + ("+" if hold >= 60 else "")
						var bh: Array = r.byHold.get(bin, [0, 0])
						bh[0] = int(bh[0]) + 1
						r.byHold[bin] = bh
						rel.append([int(e.amount), int(e.n), bin, false])
					else:
						r.tapReleases += 1
					charging = false
				elif ck == "miss" and String(e.text) == "gave_ground":
					for q in rel:
						if S.tick >= int(q[0]) and S.tick - int(q[0]) <= 45 and not bool(q[3]):
							q[3] = true
							r.gaveGround += 1
							break
				elif ck == "perfect_block" and int(e.actor) == 1:
					for q in rel:
						if S.tick >= int(q[0]) and S.tick - int(q[0]) <= 40:
							r.perfect += 1
							q[3] = true
							var ga: int = DirInterrupt.gi(him, DirInterrupt.GUARD_AT)
							if ga < int(q[0]):
								r.pressBefore += 1
							elif ga == int(q[0]):
								r.sameTick += 1
							else:
								r.pressAfter += 1
							if int(q[1]) - ga > 14:
								r.stale += 1
							var bh2: Array = r.byHold.get(String(q[2]), [0, 0])
							bh2[1] = int(bh2[1]) + 1
							r.byHold[String(q[2])] = bh2
							rel.erase(q)
							break
			var keep := []
			for q in rel:
				if S.tick - int(q[0]) <= 40:
					keep.append(q)
			rel = keep
			S.out.fx.clear()
			S.out.feed.clear()
		SimCore.dispose(S)
		if capped:
			r.wallCapped += 1
		else:
			r.n += 1
	r["perfectShare"] = snappedf(float(r.perfect) / maxf(1.0, float(r.releases)), 0.001)
	print(JSON.stringify(r))
	quit()
