extends SceneTree
# The ring picker (docs/world/shifting-arena-design.md window 4; data/biomes/rings.json; WorldRingPick) with Narrative's four claims (docs/narrative/pending/opponent_grounds.json):
#   godot --headless --path . --script res://sim/world/tools/ringpick_check.gd [-- --planets=12]
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func bitsEq(a: Array, b: Array) -> bool:
	for i in range(a.size()):
		if SimMathx.bits(a[i]) != SimMathx.bits(b[i]):
			return false
	return true


func _init() -> void:
	var planets: int = 12
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planets="):
			planets = int(a.substr(10))
	ok(WorldRingPick.dataErrors().is_empty(), "rings.json loads clean (%s)" % str(WorldRingPick.dataErrors()))
	ok(WorldRingPick.sizeCols("close") == 1200 and WorldRingPick.sizeCols("half") == 2400 and WorldRingPick.sizeCols("whole") == 4800, "the sizes are Game Design's: 1,200, 2,400 and 4,800 columns")
	var claims: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/narrative/pending/opponent_grounds.json")).claims
	ok(claims.keys() == ["RIVAL", "EMPRESS", "CYBORG", "PROTAGONIST"], "Narrative's four claims load (%s)" % str(claims.keys()))
	var P := WorldPlanet.make(7)
	# --- the ring geometry
	var geom: bool = true
	for cols in [4800, 2400, 1200]:
		var sp: Dictionary = WorldRingPick.roundSpec([0.0, 1.0, 0.0], cols, 0.7)
		var ring: Dictionary = WorldRingPick.ringFrom(sp.c, cols, sp.t)
		var p0: Array = WorldRingPick.ringPoint(ring, 0.0)
		for i in range(3):
			if absf(p0[i] - sp.t[i]) > 1e-9:
				geom = false
		var worst: float = 0.0
		for k in range(0, 360, 7):
			var q: Array = WorldRingPick.ringPoint(ring, float(k) * PI / 180.0)
			worst = maxf(worst, absf(q[0] * q[0] + q[1] * q[1] + q[2] * q[2] - 1.0))
			worst = maxf(worst, absf(WorldPlanet.lateral(P, ring, q[0], q[1], q[2])) / P.R)
		if worst > 1e-9:
			geom = false
	ok(geom, "a ring round a point (1,200, 2,400 and 4,800 columns): the touch-down is its first point, every point is unit and on the ring")
	var thr: Dictionary = WorldRingPick.throughSpec(WorldPlanet.unitFromDraws(0.3, 0.6), 2400, 1.1)
	var rg2: Dictionary = WorldRingPick.ringFrom(thr.c, 2400, thr.t)
	var p00: Array = WorldRingPick.ringPoint(rg2, 0.0)
	ok(absf(p00[0] - thr.t[0]) < 1e-9 and absf(p00[1] - thr.t[1]) < 1e-9 and absf(p00[2] - thr.t[2]) < 1e-9 and absf(WorldPlanet.lateral(P, rg2, thr.t[0], thr.t[1], thr.t[2])) < 0.01, "a ring through a point has it as the touch-down, zero lateral on it")
	var spec1: Dictionary = WorldRingPick.roundSpec(WorldPlanet.unitFromDraws(0.31, 0.77), 1200, 2.3)
	var ar: Dictionary = WorldRingPick.arenaOf(spec1)
	var back: Dictionary = WorldRingPick.ringOfArena(JSON.parse_string(JSON.stringify(ar)))
	var direct: Dictionary = WorldRingPick.ringFrom(spec1.c, 1200, spec1.t)
	ok(back.has("u") and bitsEq(back.u, direct.u) and bitsEq(back.v, direct.v) and bitsEq(back.c, direct.c) and ar.cols == 1200, "an arena as a setup carries a ring exactly (the axis and touch-down as bit patterns, through JSON and back)")
	# --- the read agrees with the picker's own count on a great circle
	var pr: Dictionary = WorldPlanet.pick(P, 3)
	var ev0: Dictionary = WorldPlanet.evalCircle(P, pr.circle, PackedByteArray())
	var ev1: Dictionary = WorldRingPick.evalRing(P, {"c": pr.circle.n, "t": pr.circle.u, "cols": 4800, "kind": "through", "place": -1})
	var sum: float = 0.0
	for x in ev1.share:
		sum += x
	ok(ev1.cities == ev0.cities and ev1.towns == ev0.towns and absf(sum - 1.0) < 1e-9, "the ring read of the picker's own great circle holds the same cities (%d) and towns (%d) as evalCircle, and its shares sum to 1" % [ev1.cities, ev1.towns])
	# --- the candidates
	var c1: Array = WorldRingPick.candidates(P, "half", 5, [3])
	var c2: Array = WorldRingPick.candidates(P, "half", 5, [3])
	var c3: Array = WorldRingPick.candidates(P, "half", 6, [3])
	ok(c1.size() == 48 and c1[0].place == 3 and bitsEq(c1[7].c, c2[7].c) and not bitsEq(c1[7].c, c3[7].c), "48 candidates a Half, the pinned place first, the same from the same stream and different from another")
	# --- the picks across planets
	var stats := {"n": 0, "ok": 0, "must": 0, "both": 0, "tried": 0, "ms": 0}
	var detail: Dictionary = {}
	var homeOf: Dictionary = {}
	var t0: int = Time.get_ticks_msec()
	for sd in range(1, planets + 1):
		var PP := WorldPlanet.make(sd)
		# a stand-in home for each claim: the planet's most populous city (homes are placed when Orb names them)
		var city: int = -1
		for i in range(PP.n):
			if PP.kind[i] == WorldPlanet.KIND_CITY and (city < 0 or PP.people[i] > PP.people[city]):
				city = i
		for name in ["RIVAL", "EMPRESS", "CYBORG", "PROTAGONIST"]:
			for size in ["close", "half", "whole"]:
				var tt: int = Time.get_ticks_msec()
				var r: Dictionary = WorldRingPick.pick(PP, claims[name], size, sd * 10 + 1, {"home": -1})
				stats.ms += Time.get_ticks_msec() - tt
				stats.n += 1
				stats.tried += int(r.tried)
				if r.ok:
					stats.ok += 1
				if r.must:
					stats.must += 1
				if r.ok and r.must:
					stats.both += 1
				var key: String = "%s/%s" % [name, size]
				if not detail.has(key):
					detail[key] = [0, 0, 0]
				detail[key][0] += 1
				detail[key][1] += 1 if r.ok else 0
				detail[key][2] += 1 if (r.ok and r.must) else 0
				# a pick that says ok holds the size's minimum, whatever the claim
				if r.ok and not WorldRingPick.meets(r.ev, size):
					ok(false, "planet %d %s %s: ok without the minimum" % [sd, name, size])
	var total_ms: int = Time.get_ticks_msec() - t0
	for k in detail:
		print("    %s: %d picks, %d met the size's minimum, %d met it and the claim's must-cross" % [k, detail[k][0], detail[k][1], detail[k][2]])
	ok(stats.ok >= int(0.85 * float(stats.n)), "%d of %d picks (%d planets, 4 claims, 3 sizes) found a ring that meets its size's minimum" % [stats.ok, stats.n, planets])
	ok(stats.both >= int(0.6 * float(stats.n)), "%d of %d also meet the claim's must-cross" % [stats.both, stats.n])
	print("    mean candidates read a pick: %.1f; mean %.0f ms a pick on this PC (a shared machine: informational)" % [float(stats.tried) / float(stats.n), float(stats.ms) / float(stats.n)])
	# --- claims differ: on one planet at one size the four claims do not all choose the same ring
	var PP7 := WorldPlanet.make(7)
	var chosen: Dictionary = {}
	for name in ["RIVAL", "EMPRESS", "CYBORG", "PROTAGONIST"]:
		var r2: Dictionary = WorldRingPick.pick(PP7, claims[name], "half", 71, {"home": -1})
		chosen[name] = SimMathx.bits(r2.spec.c[0]) + SimMathx.bits(r2.spec.c[1])
	var distinct: Dictionary = {}
	for k in chosen:
		distinct[chosen[k]] = true
	ok(distinct.size() >= 3, "on planet 7 at Half, the four claims choose %d different rings" % distinct.size())
	# --- the claim's meaning: an Empress ring has more plains than a Rival ring, a Rival ring more mountains, a Protagonist ring more open water
	var plains: Dictionary = {"RIVAL": 0.0, "EMPRESS": 0.0}
	var mount: Dictionary = {"RIVAL": 0.0, "EMPRESS": 0.0}
	var water: Dictionary = {"PROTAGONIST": 0.0, "EMPRESS": 0.0}
	var cn: int = 0
	for sd in range(1, planets + 1):
		var PX := WorldPlanet.make(sd)
		for name in ["RIVAL", "EMPRESS", "PROTAGONIST"]:
			var rr: Dictionary = WorldRingPick.pick(PX, claims[name], "half", sd * 10 + 2, {"home": -1})
			if name in plains:
				plains[name] += rr.ev.share[1]
				mount[name] += rr.ev.share[4]
			if name in water:
				water[name] += rr.ev.share[0]
		cn += 1
	ok(plains.EMPRESS > plains.RIVAL and mount.RIVAL > mount.EMPRESS and water.PROTAGONIST > water.EMPRESS, "the claims show in the rings (mean over %d planets, Half): plains Empress %.2f against Rival %.2f; mountains Rival %.2f against Empress %.2f; open water Protagonist %.2f against Empress %.2f" % [cn, plains.EMPRESS / cn, plains.RIVAL / cn, mount.RIVAL / cn, mount.EMPRESS / cn, water.PROTAGONIST / cn, water.EMPRESS / cn])
	# --- a pick in steps is the pick in one call
	var jb: WorldRingPick.PickJob = WorldRingPick.beginPick(PP7, claims.CYBORG, "half", 99, {"home": -1})
	var steps: int = 0
	while not jb.step(3):
		steps += 1
	var rone: Dictionary = WorldRingPick.pick(PP7, claims.CYBORG, "half", 99, {"home": -1})
	ok(steps >= 10 and bitsEq(jb.result.spec.c, rone.spec.c) and jb.result.idx == rone.idx, "a pick stepped three candidates at a time (%d steps) is the pick in one call" % (steps + 1))
	# --- the same pick twice; the first and the boss rings
	var ra: Dictionary = WorldRingPick.pick(PP7, claims.CYBORG, "half", 99, {"home": -1})
	var rb: Dictionary = WorldRingPick.pick(PP7, claims.CYBORG, "half", 99, {"home": -1})
	ok(bitsEq(ra.spec.c, rb.spec.c) and bitsEq(ra.spec.t, rb.spec.t) and ra.idx == rb.idx, "the same claim, size and stream pick the same ring, to the bit")
	var home: int = 0
	var evh: Dictionary = {}
	var fr: Dictionary = WorldRingPick.firstRing(PP7, home, 3)
	var fe: Dictionary = WorldRingPick.evalRing(PP7, {"c": fr.c, "t": fr.t, "cols": fr.cols, "kind": "round", "place": home})
	var holdsHome: bool = false
	for h in fe.held:
		if h.id == home:
			holdsHome = true
	ok(fr.cols == 1200 and holdsHome, "the first ring is a Close ring round the player's home, which it holds as its centre")
	var boss = WorldRingPick.bossRing(PP7, home, PackedByteArray())
	var bring: Dictionary = WorldRingPick.ringFrom(boss.c, boss.cols, boss.t)
	var a: Array = WorldRingPick.placePoint(PP7, home)
	var b2: Array = WorldRingPick.placePoint(PP7, boss.other)
	ok(boss.cols == 4800 and absf(WorldPlanet.lateral(PP7, bring, a[0], a[1], a[2])) < 0.5 and absf(WorldPlanet.lateral(PP7, bring, b2[0], b2[1], b2[2])) < 0.5, "the boss's ring is the great circle through his home and the most populous other place (both within half a unit of it)")
	# --- a match on a picked ring plays and plays the same twice
	var res: Array = []
	var pick1: Dictionary = WorldRingPick.pick(PP7, claims.RIVAL, "close", 5, {"home": -1})
	for r in range(2):
		var S := SimCore.createSim()
		SimCore.newMatch(S, 1, {}, {"planet": 7, "arena": WorldRingPick.arenaOf(pick1.spec), "intro": false})
		for t in range(1200):
			SimCore.step(S)
		res.append("%d/%d/%s" % [S.base.size(), S.buildings.size(), str(SimHash.stateHash(S).gameplay)])
	ok(res[0] == res[1] and res[0].begins_with("1200/"), "a match on the Rival's Close ring (%s) builds from it, plays 1,200 ticks and plays the same twice" % res[0])
	print("RINGPICK: %d check(s) failed" % fails)
	quit()
