extends SceneTree
## Scripted cases for the brawl's rules: each sets a scene with two scripted players (no AI) and checks one rule.
## From the repo root:
##   godot --headless --path . --script res://sim/director/tools/brawl_cases.gd
## Exits 0 when every case passes. A case whose scene never arose fails: it has proved nothing.
##
## Case 1, the reel of a medium held past its wind-up (brawl-c2.md section 14). A fighter who holds Y past the
## medium's wind-up has a blow that waits for its button and has no landing tick yet. A light that lands on him
## then reels him for the light's reel, counted from the tick it lands; it had been counted from his blow's landing
## tick, so his reel never ended and he threw nothing more in that brawl.

const REEL_MOST := 60   # live ticks: no reel of a light is near this long


func _init() -> void:
	var fails := 0
	fails += _report("a light on a medium held past its wind-up reels him for the light's reel, and he throws again", _parkedMediumReel())
	print("brawl cases: " + ("all passed" if fails == 0 else str(fails) + " FAILED"))
	quit(1 if fails > 0 else 0)


func _report(what: String, err: String) -> int:
	print(("PASS  " if err == "" else "FAIL  ") + what + ("" if err == "" else ": " + err))
	return 0 if err == "" else 1


## Slot 0 flies at an idle rival and taps X into a brawl, then holds Y. On the first tick his medium waits for its
## button the rival taps X. When that light lands, his reel must end within REEL_MOST live ticks; and once it has
## ended, a tap of his X must put a blow on its way.
func _parkedMediumReel() -> String:
	var seen := 0
	var threw := 0
	for sd in range(1, 7):
		var S := SimCore.createSim()
		SimCore.newMatch(S, sd, {"p1": false, "p2": false}, {"v2": [true, true]})
		var me = S.fighters[0]
		var him = S.fighters[1]
		var lastX := -1000
		var phase := 0          # 0 getting into a brawl, 1 settling, 2 holding Y, 3 reeling, 4 his X after the reel
		var settle := 0
		var rivalTap := -1000
		var hitAt := -1
		var tapAt := -1
		while S.tick < 3600 and S.game.ko == null and phase < 5:
			var a := SimIntent.new()
			var b := SimIntent.new()
			var inB: bool = DirBrawl.inBrawl(S, me)
			var parked: bool = inB and DirBrawl._g(me, DirBrawl.LINE) == 2 and DirBrawl._g(me, DirBrawl.KIND) == DirBrawl.MEDIUM
			if phase == 0:
				a.mx = SimMathx.jsign(SimWrap.sdx(me.x, him.x))
				if inB:
					phase = 1
					settle = 0
				elif S.tick - lastX >= 8:
					a.light = true
					lastX = S.tick
			elif phase == 1:
				if not inB:
					phase = 0
				else:
					var idle: bool = DirBrawl._g(me, DirBrawl.LINE) == 0 and DirBrawl._g(him, DirBrawl.LINE) == 0 and me.stunTicks <= 0 and him.stunTicks <= 0 and DirBrawl._g(me, DirBrawl.HELD_P) == 0
					settle = settle + 1 if idle else 0
					if settle >= 6:
						phase = 2
						a.heavy = true
						a.heavyHeld = true
			elif phase == 2:
				a.heavyHeld = true
				if not inB:
					phase = 0
				elif parked and S.tick - rivalTap >= 3:
					b.light = true
					rivalTap = S.tick
				elif DirBrawl._g(me, DirBrawl.LINE) == 0 and rivalTap < 0:
					phase = 1   # the medium went before the rival's tap: set the scene again
					settle = 0
			elif phase == 3:
				if DirBrawl._now(S) >= DirBrawl._g(me, DirBrawl.REEL_AT) and me.stunTicks <= 0:
					if not inB:
						phase = 5   # the brawl ended meanwhile: the reel's length was the case
					else:
						a.light = true
						tapAt = S.tick
						phase = 4
			elif phase == 4:
				if inB and DirBrawl._g(me, DirBrawl.LINE) != 0:
					threw += 1
					phase = 5
				elif S.tick - tapAt > 12:
					return "seed %d: his reel ended, and his X put no blow on its way in 12 ticks" % sd
				elif S.tick - tapAt >= 2 and DirBrawl._g(me, DirBrawl.LINE) == 0:
					a.light = true   # a press made in a freeze is not read: press again
			var wasParked: bool = parked
			var stepped: bool = SimCore.step(S, [a, b])
			if not stepped and rivalTap == S.tick - 1:
				rivalTap = -1000
			if phase == 2 and wasParked:
				for e in S.out.fx:
					if e.type == "damage" and e.amount > 0.0 and int(e.victim) == 0 and int(e.attacker) == 1:
						hitAt = S.tick
				if hitAt >= 0:
					seen += 1
					var left: int = DirBrawl._g(me, DirBrawl.REEL_AT) - DirBrawl._now(S)
					if left > REEL_MOST:
						return "seed %d, tick %d: the light landed on his waiting medium and his reel has %d live ticks to run" % [sd, S.tick, left]
					phase = 3
			S.out.fx.clear()
			S.out.feed.clear()
	if seen == 0:
		return "the scene never arose: no light landed on a medium that waited for its button in six matches"
	if threw == 0:
		return "no match reached his tap after the reel (%d reels read)" % seen
	return ""
