extends SceneTree
# The campaign's route on the ring (docs/design/campaign.md; docs/world/campaign-route.md; WorldCampaign, data/biomes/campaign.json): the places of each column within the flight band, the ring turn between
# columns, the climax's ring through the boss's home, the side story's place, and the planet's wounds as place state only.
#   godot --headless --path . --script res://sim/world/tools/campaign_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func vclose(a: Array, b: Array, e: float = 1e-6) -> bool:
	return absf(a[0] - b[0]) < e and absf(a[1] - b[1]) < e and absf(a[2] - b[2]) < e


## A Half ring through the planet's n-th city (the city is at the touch-down), as a setup's arena.
func ringThrough(P: WorldPlanet.Planet, nth: int, cols: int = 2400, phi: float = 0.7) -> Dictionary:
	var k: int = -1
	var id: int = 0
	for i in range(P.n):
		if P.kind[i] == WorldPlanet.KIND_CITY:
			k += 1
			if k == nth:
				id = i
				break
	return WorldRingPick.arenaOf(WorldRingPick.throughSpec(WorldRingPick.placePoint(P, id), cols, phi))


func fresh(setup: Dictionary) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, setup)
	S.out.fx.clear()
	return S


func _init() -> void:
	ok(WorldCampaign.dataErrors().is_empty(), "campaign.json is clean (%s)" % str(WorldCampaign.dataErrors()))
	ok(not WorldCampaign.enabled(), "campaign.json ships with the campaign off")
	WorldCampaign.setOn(true)
	var COL: float = SimConst.COL
	var speed: float = WorldCampaign.K_SPEED
	var sepCols: int = WorldCampaign.K_SEP_C
	for gen in [1, 2]:
		WorldClimate.useGen(gen)
		var okN: int = 0
		var total: int = 0
		var bandOk: bool = true
		var sepOk: bool = true
		var settledOk: bool = true
		var turned: int = 0
		var turnOk: bool = true
		var counts: Dictionary = {}
		var detOk: bool = true
		var t0: int = Time.get_ticks_usec()
		for sd in [7, 3, 11, 25]:
			var P := WorldPlanet.make(sd)
			var arena: Dictionary = ringThrough(P, 0)
			var spec: Dictionary = WorldCampaign.specOf(arena)
			var cols: int = int(spec.cols)
			var pc: int = cols / 2
			var used: Array = []
			var here: Dictionary = arena
			for col in range(1, 5):
				var r: Dictionary = WorldCampaign.column(sd, 100 + sd, col, here, pc, {"used": used})
				total += 1
				if r.ok:
					okN += 1
				counts[r.sites.size()] = int(counts.get(r.sites.size(), 0)) + 1
				var settledN: int = 0
				for s in r.sites:
					if s.entry < WorldCampaign.K_MIN_C or s.entry > mini(WorldCampaign.K_MAX_C, cols / 2):
						bandOk = false
					if s.settled:
						settledN += 1
					if s.place >= 0:
						used.append(s.place)
				for a in range(r.sites.size()):
					for b in range(a + 1, r.sites.size()):
						if absi(WorldCampaign.arcCols(pc + r.sites[a].arc, pc + r.sites[b].arc, int(r.cols))) < sepCols:
							sepOk = false
				if col == 4 and r.ok and settledN < 1:
					settledOk = false
				if sd == 7 and col == 1:
					var again: Dictionary = WorldCampaign.column(sd, 100 + sd, 1, arena, pc, {})
					var third: Dictionary = WorldCampaign.column(sd, 100 + sd, 1, arena, pc, {})
					detOk = JSON.stringify(again) == JSON.stringify(third)
				if r.turn != null:
					turned += 1
					# the turned ring passes through the pair's point: the old ring's point at pc is the new ring's point at its touch-down
					var oldRing: Dictionary = WorldRingPick.ringOfArena(here)
					var newRing: Dictionary = WorldRingPick.ringOfArena(r.start)
					var pOld: Array = WorldRingPick.ringPoint(oldRing, float(pc - cols / 2) * COL / (P.R * float(oldRing.st)))
					var pNew: Array = WorldRingPick.ringPoint(newRing, 0.0)
					if not vclose(pOld, pNew, 1.0e-6) or absf(float(r.turn.deg)) > 61.0 or int(r.cols) != cols:
						turnOk = false
				here = r.start
				pc = int(r.pc)
		var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0 / float(total)
		ok(bandOk, "gen %d: every place of columns 1 to 4 is %d to %d columns from the pair (on a Close ring the band ends at the far side)" % [gen, WorldCampaign.K_MIN_C, WorldCampaign.K_MAX_C])
		ok(sepOk, "gen %d: the places of a column are at least %d columns apart" % [gen, WorldCampaign.K_SEP_C])
		ok(okN >= total * 3 / 4, "gen %d: %d of %d columns got every place they ask for (sizes %s); the town in column 4: %s" % [gen, okN, total, str(counts), "always" if settledOk else "NOT always"])
		ok(settledOk, "gen %d: column 4 offers a settled place whenever it is ok" % gen)
		ok(turnOk, "gen %d: %d column(s) turned the ring: each new ring passes through the pair's point, within the data's bearings, the same length" % [gen, turned])
		ok(detOk, "gen %d: a column is the same twice" % gen)
		print("    cost: %.0f ms a column (turns tried both ways)" % ms)
	WorldClimate.useGen(1)
	# a different episode seed offers different places; a used place is not offered again
	var P7 := WorldPlanet.make(7)
	var arena7: Dictionary = ringThrough(P7, 0)
	var pc7: int = 1200
	var sets: Dictionary = {}
	for es in range(10):
		var r: Dictionary = WorldCampaign.column(7, 500 + es * 17, 2, arena7, pc7, {"turn": false})
		var key: String = ""
		for s in r.sites:
			key += "%d/%d," % [s.place, s.arc]
		sets[key] = true
	ok(sets.size() >= 4, "ten episode seeds offer %d different sets of places in column 2 on one ring" % sets.size())
	var c1: Dictionary = WorldCampaign.column(7, 500, 2, arena7, pc7, {"turn": false})
	var usedPl: Array = []
	for s in c1.sites:
		if s.place >= 0:
			usedPl.append(s.place)
	var c1b: Dictionary = WorldCampaign.column(7, 500, 2, arena7, pc7, {"turn": false, "used": usedPl})
	var reuse: bool = false
	for s in c1b.sites:
		if usedPl.has(s.place) and s.place >= 0:
			reuse = true
	ok(not reuse, "the places an episode has used are not offered again")
	var job: WorldCampaign.ColumnJob = WorldCampaign.beginColumn(7, 500, 2, arena7, pc7, {})
	var nSteps: int = 1
	var tj0: int = Time.get_ticks_usec()
	var worstStep: int = 0
	while true:
		var t1: int = Time.get_ticks_usec()
		var fin: bool = job.step(1)
		worstStep = maxi(worstStep, Time.get_ticks_usec() - t1)
		if fin:
			break
		nSteps += 1
	ok(nSteps == 9 and JSON.stringify(job.result) == JSON.stringify(WorldCampaign.column(7, 500, 2, arena7, pc7, {})), "stepped a ring a call, a column takes %d calls (the longest %.0f ms) and is the same answer as at once" % [nSteps, float(worstStep) / 1000.0])
	# the climax: the ring through the pair and the boss's home
	var home: int = -1
	for i in range(P7.n):
		if P7.kind[i] == WorldPlanet.KIND_CITY and absf(WorldPlanet.lateral(P7, WorldRingPick.ringOfArena(arena7), P7.px[i], P7.py[i], P7.pz[i])) > 20000.0:
			home = i
			break
	home = 5 if home < 0 else home
	var cl: Dictionary = WorldCampaign.column(7, 500, 5, arena7, pc7, {"pin": home})
	var okc: bool = cl.ok and cl.sites.size() == 1 and cl.sites[0].place == home and int(cl.cols) == SimConst.PLANET_NC and cl.resize == true
	var ringC: Dictionary = WorldRingPick.ringOfArena(cl.start)
	var Hp: Array = WorldRingPick.placePoint(P7, home)
	var latc: float = absf(WorldPlanet.lateral(P7, ringC, Hp[0], Hp[1], Hp[2]))
	ok(okc and latc < 1.0, "the climax is one place, the boss's home (%d), on the whole ring through the pair and it (its lateral distance %.2f units), %.1f s of flight%s" % [home, latc, cl.sites[0].flightS, " (the build-up)" if cl.get("far", false) else ""])
	# a side story (Game Design rulings 2026-10-26 item 2): a named place in the flight band; else any named place on the ring; else the ring turns to bring one along it; never an unnamed site; if all fail the draw is spent
	var how: Dictionary = {"band": 0, "widened": 0, "turned": 0, "none": 0}
	var sideOk: bool = true
	var tried: int = 0
	var townReach: float = float(P7.c.townReach)
	for nth in range(8):
		for phi in [0.7, 2.0, 3.3, 4.6]:
			var ar: Dictionary = ringThrough(P7, nth, 2400, phi)
			var sd1: Dictionary = WorldCampaign.side(7, 77, 3, ar, 1200, {})
			tried += 1
			if not sd1.ok:
				how.none += 1
				if not (sd1.get("spent", false) and not sd1.has("place")):
					sideOk = false
				continue
			how[sd1.how] += 1
			var ringS: Dictionary = WorldRingPick.ringOfArena(sd1.arena)
			var pp: Array = WorldRingPick.placePoint(P7, int(sd1.place))
			if not (sd1.place >= 0 and vclose(ringS.c, pp, 1.0e-9) and int(sd1.arena.cols) == WorldCampaign.K_SIDE_COLS and sd1.site.settled and not sd1.site.fallen):
				sideOk = false
			var onRing: Dictionary = WorldRingPick.ringOfArena(sd1.ring)
			var reach: float = townReach * P7.rad[int(sd1.place)] if P7.kind[int(sd1.place)] != WorldPlanet.KIND_CITY else float(P7.c.cityReach) * P7.rad[int(sd1.place)]
			if sd1.how != "turned" and absf(WorldPlanet.lateral(P7, WorldRingPick.ringOfArena(ar), pp[0], pp[1], pp[2])) >= reach:
				sideOk = false   # a place on the ring as it is lies on it
			if sd1.how == "band" and (int(sd1.site.entry) < WorldCampaign.K_MIN_C or int(sd1.site.entry) > mini(WorldCampaign.K_MAX_C, 1200)):
				sideOk = false
			if sd1.how == "turned":
				var degOk: bool = sd1.turn != null and WorldCampaign.K_BEAR.has(absf(float(sd1.turn.deg)))
				if not degOk or absf(WorldPlanet.lateral(P7, onRing, pp[0], pp[1], pp[2])) >= reach:
					sideOk = false   # the turned ring holds the place, at one of the data's bearings
			elif sd1.turn != null:
				sideOk = false
	ok(sideOk and how.band + how.widened + how.turned + how.none == tried and how.band >= 1, "a side story's place is always a named city or town with a Close ring round it: of %d rings of planet 7, %d had one in the band, %d widened to any on the ring, %d turned the ring, %d had none (the draw is spent)" % [tried, how.band, how.widened, how.turned, how.none])
	var sdAvoid: Dictionary = {}
	for phi in [0.7, 2.0, 3.3, 4.6]:
		for nth in range(8):
			var ar2: Dictionary = ringThrough(P7, nth, 2400, phi)
			var s0: Dictionary = WorldCampaign.side(7, 77, 3, ar2, 1200, {})
			if s0.ok:
				var s1: Dictionary = WorldCampaign.side(7, 77, 3, ar2, 1200, {"sites": [int(s0.site.arc)]})
				sdAvoid = {"a": s0, "b": s1}
				break
		if not sdAvoid.is_empty():
			break
	var avoidOk: bool = sdAvoid.is_empty() or (not sdAvoid.b.ok) or int(sdAvoid.b.place) != int(sdAvoid.a.place)
	ok(avoidOk, "a side story's place keeps clear of a column's own places")
	# how often the ring turns (rulings 2026-10-26 item 5: 40 to 60% of columns 1 to 4): 6 planets, 2 rings each, the four columns walked on as an episode would
	var turnedN: int = 0
	var colsN: int = 0
	for gen in [1, 2]:
		WorldClimate.useGen(gen)
		for sd in [7, 3, 11, 25, 5, 9]:
			var Pt := WorldPlanet.make(sd)
			for nth in range(2):
				var here: Dictionary = ringThrough(Pt, nth)
				var pcw: int = 1200
				for colw in range(1, 5):
					var rj: Dictionary = WorldCampaign.column(sd, 100 + sd + nth, colw, here, pcw, {})
					colsN += 1
					if rj.turn != null:
						turnedN += 1
					here = rj.start
					pcw = int(rj.pc)
	var share: float = float(turnedN) / float(colsN)
	ok(share >= 0.40 and share <= 0.60, "the ring turns in %.0f%% of %d columns (both generations, 6 planets, 2 rings, columns 1 to 4): Game Design's target is 40 to 60%% (minGain %.2f, bonus %.2f)" % [100.0 * share, colsN, WorldCampaign.K_TURN_GAIN, WorldCampaign.K_TURN_BONUS])
	WorldClimate.useGen(1)
	# the planet's wounds: place state only
	var S0 := fresh({"planet": 7, "touch": 3, "arena": {"cols": 2400}, "intro": false})
	var pl: int = -1
	var cnt: Dictionary = {}
	for b in S0.buildings:
		if b.place >= 0:
			cnt[b.place] = int(cnt.get(b.place, 0)) + 1
	for k in cnt.keys():
		if pl < 0 or cnt[k] > cnt[pl]:
			pl = k
	ok(pl >= 0 and WorldCampaign.wearOf(S0).is_empty(), "a stage that has lost nothing has no wear (the biggest place has %d buildings)" % [cnt.get(pl, 0)])
	var kills: int = 0
	for b in S0.buildings:
		if b.place == pl and kills < int(float(cnt[pl]) * 0.4):
			WorldStructures.damageBuilding(S0, b, 1.0e9, S0.fighters[0], "implode", b.x, 0.0)
			kills += 1
	var w0: Dictionary = WorldCampaign.wearOf(S0)
	ok(w0.get(str(pl), 0) == 2, "a place that lost %d of %d buildings is band %s (ruined)" % [kills, cnt[pl], str(w0.get(str(pl), 0))])
	var w1: Dictionary = WorldCampaign.mergeWear({str(pl): 3, "999": 1}, w0)
	ok(w1[str(pl)] == 3 and w1["999"] == 1 and WorldCampaign.mergeWear(w0, {})[str(pl)] == 2, "the run's place state keeps the worse band of each place and nothing is healed")
	var stand: PackedByteArray = WorldCampaign.standingOf(P7, w1)
	ok(stand[pl] == 0 and WorldCampaign.damagedOf(w1).has(pl) and stand.size() == P7.n and stand.count(0) == 1, "a fallen place (band 3) is not standing for the ring picker, and the hurt ones are listed")
	var plain := fresh({"planet": 7, "touch": 3, "arena": {"cols": 2400}, "intro": false})
	var worn := fresh({"planet": 7, "touch": 3, "arena": {"cols": 2400}, "intro": false, "wear": {str(pl): 2}})
	var worn2 := fresh({"planet": 7, "touch": 3, "arena": {"cols": 2400}, "intro": false, "wear": {str(pl): 2}})
	var fallen: int = 0
	var hpDown: bool = true
	for i in range(plain.buildings.size()):
		var a = plain.buildings[i]
		var b = worn.buildings[i]
		if a.place == pl:
			if not b.alive:
				fallen += 1
			elif b.hp >= a.hp:
				hpDown = false
		elif a.alive != b.alive or a.hp != b.hp:
			hpDown = false
	var want: int = int(round(float(WorldCampaign.K_W_FALLEN[2]) * float(cnt[pl])))
	ok(fallen == want and hpDown, "wear band 2 lays %d of the place's %d buildings fallen (the data's %.0f%%) and weakens the rest, and touches no other place" % [fallen, cnt[pl], 100.0 * float(WorldCampaign.K_W_FALLEN[2])])
	ok(worn.world.casualties == 0.0 and worn.world.structuresLost == 0.0 and worn.world.pop0 < plain.world.pop0 and worn.world.pop0 >= 1.0, "the wear is no casualty and no loss of the stage: the people who are gone leave the stage's count (%.0f of %.0f)" % [worn.world.pop0, plain.world.pop0])
	ok(str(SimHash.stateHash(worn).gameplay) == str(SimHash.stateHash(worn2).gameplay) and str(SimHash.stateHash(worn).gameplay) != str(SimHash.stateHash(plain).gameplay), "the same wear lays the same stage, and a worn stage is not a fresh one")
	WorldCampaign.setOn(false)
	var off := fresh({"planet": 7, "touch": 3, "arena": {"cols": 2400}, "intro": false, "wear": {str(pl): 2}})
	ok(str(SimHash.stateHash(off).gameplay) == str(SimHash.stateHash(plain).gameplay), "with the campaign off a setup's wear is ignored: the match is the plain one")
	WorldCampaign.setOn(true)
	# the turn in a running sim: the campaign's bearing, the fight's machinery, no count against the fight's four
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}, "intro": false})
	for t in range(30):
		SimCore.step(S)
	var px: float = 0.5 * (S.fighters[0].x + S.fighters[1].x)
	var pcS: int = posmod(int(round(px / COL)), SimConst.NC)
	var ring0: Dictionary = WorldRingPick.ringFrom(S.epoch.ring.c, int(S.epoch.ring.cols), S.epoch.ring.t)
	var cands: Array = WorldEpoch.askCampaign(S, px, 40.0, 0)
	ok(cands.size() == 1 and absf(float(cands[0].bearing) - 40.0) < 1e-9, "the campaign asks for a turn of 40 degrees (the fight's own are at most 10) and gets the one candidate")
	WorldEpoch.choose(S, 0, 100000, 0.0)
	var g: int = 0
	while WorldEpoch.warmAngles(S).size() < S.epoch.warm.size() and g < 100:
		WorldEpoch.tick(S, false)
		g += 1
	g = 0
	while S.epoch.next != null and g < 40:
		WorldEpoch.tick(S, true)
		g += 1
	var ring1: Dictionary = WorldRingPick.ringFrom(S.epoch.ring.c, int(S.epoch.ring.cols), S.epoch.ring.t)
	var mid: int = SimConst.NC / 2
	var stp: float = COL / (P7.R * float(ring0.st))
	var q0: Array = WorldRingPick.ringPoint(ring0, float(pcS - mid) * stp)
	var q1: Array = WorldRingPick.ringPoint(ring1, float(pcS - mid) * stp)
	var drift: float = WorldEpoch.driftOf(ring0.c, ring1.c)
	var wantDrift: float = 2.0 * WorldPlanet.asinf(float(ring0.st) * SimDetMath.sin(40.0 * SimMathx.PI / 180.0 * 0.5)) * 180.0 / SimMathx.PI   # the centre of a ring of angular radius theta moves this far when its heading at the pivot turns by 40 degrees
	ok(S.epoch.next == null and int(S.epoch.n) == 0 and vclose(q0, q1, 1.0e-6) and absf(drift - wantDrift) < 0.5, "the turn happened on a calm tick: the ring's heading turned 40 degrees about the pair's point (its axis %.1f, as geometry says %.1f), the point did not move, and it is not counted among the fight's four (n %d)" % [drift, wantDrift, int(S.epoch.n)])
	print("CAMPAIGN: %d check(s) failed" % fails)
	quit()
