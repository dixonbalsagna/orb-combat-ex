extends SceneTree
## Section 15's rows (docs/world/ring-any-angle/game-design.md), AI against AI from a start in town, the same seeds with swings off and on.
##   godot --headless --path . --script res://sim/director/tools/building_read.gd -- <seeds a world> [--cap=25200] [--wall=1]
## Prints BUILDINGS {json} per setting. A read, not a gate: QA's batch is the verdict.

const WORLDS := [[3, 0], [3, 1], [3, 2], [3, 3], [7, 0], [7, 1], [7, 2], [7, 3], [11, 0], [11, 1], [11, 2], [11, 3], [13, 0], [13, 1], [13, 2], [13, 3]]
const NEAR := 4000.0   # standing buildings this close, this many, make it a town (data/director/swing.json buildings)
const COUNT := 3


func _init() -> void:
	var seeds: int = 1
	var cap: int = 25200
	var wall: int = -1
	var visit: int = -1
	var a: PackedStringArray = OS.get_cmdline_user_args()
	for s in a:
		if s.begins_with("--cap="):
			cap = int(s.substr(6))
		elif s.begins_with("--wall="):
			wall = int(s.substr(7))
		elif s.begins_with("--visit="):
			visit = int(s.substr(8))
		elif s.is_valid_int():
			seeds = int(s)
	DirLaunch.setWallForce(wall)
	DirVisit.setForce(visit)
	for v in [["off", 0], ["on", 1]]:
		DirSwing.setForce(int(v[1]))
		print("BUILDINGS " + JSON.stringify(_batch(String(v[0]), seeds, cap)))
	DirSwing.setForce(-1)
	DirLaunch.setWallForce(-1)
	DirVisit.setForce(-1)
	quit(0)


func _town(S: SimState, f) -> bool:
	var n: int = 0
	for bi in WorldStructures.near(S, f.x, NEAR):
		var b = S.buildings[bi]
		if b.alive and absf(SimWrap.sdx(f.x, b.x)) <= NEAR and absf(float(b.z) - float(f.z)) <= NEAR:
			n += 1
			if n >= COUNT:
				return true
	return false


func _batch(name: String, seeds: int, cap: int) -> Dictionary:
	var r := {"swings": name, "fights": 0, "fromTown": 0, "minutes": snappedf(float(cap) / 3600.0, 0.1), "sends": 0, "crossed": 0, "fell": 0, "bodyHits": 0, "noSend": 0, "firstInside90": 0, "beats": 0, "planned": 0,
		"plannedInTown": {"1": 0, "2": 0, "3": 0, "4": 0}, "sendsInTown": {"1": 0, "2": 0, "3": 0, "4": 0}, "knocksInTown": 0, "knocksAimed": 0, "knockHits": 0, "swingStarts": 0, "within1500": 0, "samples": 0, "civLost": 0.0, "wallsInReach": 0, "placesVisited": 0, "sendsFromTown": 0, "firstInside90All": 0, "perFightSends": [], "perFightFell": []}
	for pk in WORLDS:
		for sd in range(seeds):
			var S := SimCore.createSim()
			SimCore.newMatch(S, pk[0] * 100 + pk[1] + 1 + sd * 1000, {}, {"planet": pk[0], "touch": pk[1], "intro": false, "planetGen": 3})
			var inTown: bool = _town(S, S.fighters[0])
			var alive0: int = 0
			for b in S.buildings:
				alive0 += 1 if b.alive else 0
			var sends: int = 0
			DirLaunch.wallSeen = 0
			var visited: Dictionary = {}
			var first: int = -1
			var knockAim: Array = [false, false]
			var ticks: int = 0
			for t in range(cap):
				SimCore.step(S, [SimIntent.new(), SimIntent.new()])
				ticks = t + 1
				for e in S.out.fx:
					if e.type == "launch_plan":
						r.beats += 1
						var LA = S.fighters[int(e.actor)]
						var LD = S.fighters[int(e.target)]
						var here: bool = _town(S, LD)
						var key: String = str(clampi(int(LA.tier), 1, 4))
						if e.chosen == "KNOCK BACK":
							r.knocksInTown += 1 if here else 0
						elif e.chosen != "STAY":
							r.planned += 1
							if here:
								r.plannedInTown[key] += 1
							if e.chosen == "BUILDING SMASH":
								sends += 1
								if first < 0:
									first = t
								if here:
									r.sendsInTown[key] += 1
					elif e.type == "cue" and e.kind == "knock_wall":
						r.knocksAimed += 1
						knockAim[int(e.actor)] = true
					elif e.type == "swing_start":
						r.swingStarts += 1
					elif e.type == "building_hit":
						r.bodyHits += 1
						r.crossed += 1
						if knockAim[int(e.actor)]:
							r.knockHits += 1
							knockAim[int(e.actor)] = false
				S.out.fx.clear()
				S.out.feed.clear()
				if t % 60 == 0:
					var f = S.fighters[0]
					r.samples += 1
					if S.frame != null:
						var P = DirSwing._planet(S)
						for pl in DirSwing.places(S, P, DirSwing._frame(S, f.x), 3000.0):
							visited[int(pl.id)] = true
					for bi in WorldStructures.near(S, f.x, 1500.0):
						var b = S.buildings[bi]
						if b.alive and SimDetMath.hypot(SimWrap.sdx(f.x, b.x), float(b.z) - float(f.z)) <= 1500.0:
							r.within1500 += 1
							break
				if S.game.ko != null:
					break
			var alive1: int = 0
			for b in S.buildings:
				alive1 += 1 if b.alive else 0
			r.fights += 1
			r.wallsInReach += DirLaunch.wallSeen
			r.placesVisited += visited.size()
			r.firstInside90All += 1 if first >= 0 and first < 5400 else 0
			r.fell += alive0 - alive1
			r.perFightFell.append(alive0 - alive1)
			r.perFightSends.append(sends)
			r.sends += sends
			r.civLost += float(S.world.casualties) if "casualties" in S.world else 0.0
			if inTown:
				r.fromTown += 1
				r.sendsFromTown += sends
				r.noSend += 1 if sends == 0 else 0
				r.firstInside90 += 1 if first >= 0 and first < 5400 else 0
			SimCore.dispose(S)
	r.civLost = snappedf(r.civLost, 0.1)
	return r
