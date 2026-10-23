extends SceneTree
# The calm-moment turn (docs/world/calm-turn-world.md; world/epoch.gd; data/biomes/rings.json turn):
#   godot --headless --path . --script res://sim/world/tools/epoch_check.gd [-- --ticks=600]
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func vclose(a: Array, b: Array, e: float = 1e-9) -> bool:
	return absf(a[0] - b[0]) < e and absf(a[1] - b[1]) < e and absf(a[2] - b[2]) < e


func setup(cols: int, turn: bool = true) -> Dictionary:
	return {"planet": 7, "touch": 3, "arena": {"cols": cols, "turn": turn}, "intro": false}


func mid(S: SimState) -> float:
	return 0.5 * (S.fighters[0].x + S.fighters[1].x)


## A match, run a little, with a crater and a hurt building near the pair, ready to turn.
func ready(cols: int, seed: int = 1) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, setup(cols))
	for t in range(30):
		SimCore.step(S)
	S.T = 100.0
	return S


## The sim warms a decided turn's rings itself, k columns of each a tick (WorldEpoch.tick); no host calls anything. Here k is made large so one tick, with no hold, reads them all.
func warmAll(S: SimState) -> void:
	S.epoch.next.k = 100000
	WorldEpoch.tick(S, false)


## A match that plays by SimCore.step alone (no host, no director) with a turn decided at tick 30: the tick it swaps on and its hash. mode 1: the slices kept outside the state are lost at tick 20 (a state
## carried into another process); mode 2: the state is hashed every tick (what a host or a replay tool reads).
func playRun(sd: int, mode: int, fb: float = 2.5) -> Dictionary:
	var S := ready(2400, sd)
	WorldEpoch.ask(S, "replay", mid(S), 1, 0)
	WorldEpoch.choose(S, 2, 64, fb)
	var swapTick: int = -1
	var hs: String = ""
	for t in range(1800):
		SimCore.step(S)
		if mode == 1 and t == 20:
			WorldEpoch._jobs.clear()
		if mode == 2:
			hs = str(SimHash.stateHash(S).gameplay)
		if swapTick < 0 and S.epoch.n == 1:
			swapTick = t
	return {"tick": swapTick, "hash": str(SimHash.stateHash(S).gameplay), "cold": S.epoch.cold, "unprep": S.epoch.unprep, "waited": S.epoch.waited, "refused": S.epoch.refused}


func nearest(S: SimState, x: float):
	var best = null
	for b in S.buildings:
		if best == null or absf(SimWrap.sdx(x, b.x)) < absf(SimWrap.sdx(x, best.x)):
			best = b
	return best


func _init() -> void:
	var ticks: int = 600
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	var d: Dictionary = WorldRingPick.cfg().turn
	ok(WorldRingPick.dataErrors().is_empty() and int(d.on) == 0 and int(d.maxTurns) == 4 and float(d.gapSeconds) == 60.0 and float(d.driftDeg) == 40.0, "the turn's data stands at Game Design's caps (4 turns, 60 s apart, 40 degrees of drift) and is off")
	var maxb: float = 0.0
	for b in d.bearings:
		maxb = maxf(maxb, float(b))
	ok(maxb <= 10.0, "no candidate bearing is over 10 degrees (%s)" % str(d.bearings))
	# --- the geometry of a turn
	var P := WorldPlanet.make(7)
	var geom: bool = true
	var worstAngle: float = 0.0
	for cols in [4800, 2400, 1200]:
		SimConst.setArena(cols)
		var spec: Dictionary = WorldRingPick.roundSpec(WorldPlanet.unitFromDraws(0.37, 0.62), cols, 0.9) if cols < 4800 else WorldRingPick.throughSpec(WorldPlanet.unitFromDraws(0.37, 0.62), cols, 0.9)
		var old: Dictionary = WorldRingPick.ringFrom(spec.c, cols, spec.t)
		var pc: int = cols / 2 + 137
		for deg in [-10.0, -2.5, 5.0, 10.0]:
			var ns: Dictionary = WorldEpoch.turned(P, spec, pc, deg)
			var nr: Dictionary = WorldRingPick.ringFrom(ns.c, cols, ns.t)
			var m0: Array = WorldPlanet.columnPoint(P, old, pc)
			var m1: Array = WorldPlanet.columnPoint(P, nr, pc)
			if not vclose(m0, m1, 1e-9):
				geom = false
			# the tangent at the pivot turns by deg
			var a0: Array = WorldPlanet.columnPoint(P, old, pc - 1)
			var b0: Array = WorldPlanet.columnPoint(P, old, pc + 1)
			var a1: Array = WorldPlanet.columnPoint(P, nr, pc - 1)
			var b1: Array = WorldPlanet.columnPoint(P, nr, pc + 1)
			var t0: Array = WorldPlanet._unit([b0[0] - a0[0], b0[1] - a0[1], b0[2] - a0[2]])
			var t1: Array = WorldPlanet._unit([b1[0] - a1[0], b1[1] - a1[1], b1[2] - a1[2]])
			var ang: float = acos(clampf(t0[0] * t1[0] + t0[1] * t1[1] + t0[2] * t1[2], -1.0, 1.0)) * 180.0 / PI
			worstAngle = maxf(worstAngle, absf(ang - absf(deg)))
			if cols == 4800 and absf(WorldEpoch.driftOf(spec.c, ns.c) - absf(deg)) > 1e-6:
				geom = false
	SimConst.setArena(SimConst.PLANET_NC)
	ok(geom and worstAngle < 0.02, "a turn keeps the pivot's column on the same point (a Whole, a Half and a Close ring) and turns the way the ring runs there by its bearing (worst error %.4f degrees); a Whole ring drifts its bearing" % worstAngle)
	# --- the match
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 1, {}, {"planet": 7, "touch": 3, "arena": {"cols": 2400}, "intro": false})
	ok(S0.epoch == null, "with the turn off (the data's switch, no setup.arena.turn) there is no epoch")
	var S := ready(2400)
	ok(S.epoch != null and S.epoch.n == 0 and S.epoch.ring.cols == 2400, "setup.arena.turn gives the match an epoch on its ring")
	var E: Dictionary = S.epoch
	var px: float = mid(S)
	# the caps
	S.T = 30.0
	ok(WorldEpoch.ask(S, "test", px, 1, 0).is_empty(), "under 60 s of fight time into the match there is no turn to ask")
	S.T = 100.0
	var cands: Array = WorldEpoch.ask(S, "test", px, 1, 0)
	ok(cands.size() >= 2 and cands[0].bearing == 2.5 and cands[cands.size() - 1].bearing <= 10.0, "at 100 s the ask gives the candidates on the +x side (%d, bearings %s)" % [cands.size(), str(cands.map(func(c): return c.bearing))])
	var withPlaces: int = 0
	for c in cands:
		for p in c.places:
			if p.has("id") and p.has("kind") and p.has("arc") and absf(p.arc) <= float(d.viewUnits):
				withPlaces += 1
	print("    places brought into view by the candidates: %d" % withPlaces)
	# a hurt building and a crater near the pair, to see them carried
	var nb = nearest(S, px)
	nb.hp = nb.maxhp * 0.25
	var fallen = null
	for b in S.buildings:
		if b != nb and absf(SimWrap.sdx(px, b.x)) < 3000.0 and b.alive and fallen == null:
			fallen = b
	if fallen != null:
		fallen.alive = false
		fallen.hp = 0.0
	var cr = WorldCrater.dig(S, px + 200.0, 4.0, S.fighters[1], "impact", 0.0, 1.0)
	var pcCol: int = posmod(int(round(px / SimConst.COL)), SimConst.NC)
	var baseAt: float = S.base[pcCol]
	var deformAt: float = S.deform[(pcCol + 6) % SimConst.NC]
	var farCol: int = posmod(pcCol + 700, SimConst.NC)   # 22,400 units on: outside the zone
	var pop0: float = S.world.pop0
	var cas0: float = S.world.casualties
	var nbCount0: int = S.buildings.size()
	WorldEpoch.choose(S, 1)
	ok(WorldEpoch.warmAngles(S).is_empty() and S.epoch.warm.size() == 2, "a decided turn has two rings to warm (the chosen bearing and the smallest candidate) and none is warm yet")
	WorldEpoch.tick(S, true)
	ok(S.epoch.n == 0 and S.epoch.cold == 0, "no ring is read on the tick: a decided turn on calm ground with no warm ring does not swap")
	warmAll(S)
	ok(WorldEpoch.warmAngles(S).size() == 2 and absf(WorldEpoch.warmAngles(S).min()) == 2.5 and absf(WorldEpoch.warmAngles(S).max()) == 5.0, "warmAngles says which bearings are read (5 and 2.5)")
	# calm: not while a fighter is in flight; a hold of false does nothing
	S.fighters[0].state = "launched"
	WorldEpoch.tick(S, true)
	ok(S.epoch.n == 0, "a body in flight stops the turn (World's calm check)")
	S.fighters[0].state = "free"
	WorldEpoch.tick(S, false)
	ok(S.epoch.n == 0, "no hold, no turn")
	var hashBefore: String = str(SimHash.stateHash(S).gameplay)
	# Simulation's conditions on the hash: a turn that is decided but not swapped, and the ring a match is on, are in it
	var Sd := ready(2400)
	var hUndecided: String = str(SimHash.stateHash(Sd).gameplay)
	WorldEpoch.ask(Sd, "test", mid(Sd), 1, 0)
	WorldEpoch.choose(Sd, 0)
	var hDecided0: String = str(SimHash.stateHash(Sd).gameplay)
	var Se := ready(2400)
	WorldEpoch.ask(Se, "test", mid(Se), 1, 0)
	WorldEpoch.choose(Se, 3)
	var hDecided3: String = str(SimHash.stateHash(Se).gameplay)
	ok(hUndecided != hDecided0 and hDecided0 != hDecided3, "a turn that is decided but not yet swapped is in the state hash, and its bearing with it")
	var shBefore: int = Sd.epoch.sh
	warmAll(Sd)
	ok(str(SimHash.stateHash(Sd).gameplay) != hDecided0, "how many of a decided turn's rings are read is in the hash (when a swap may happen)")
	warmAll(Se)
	WorldEpoch.tick(Sd, true)
	WorldEpoch.tick(Se, true)
	ok(Sd.epoch.sh != shBefore and Sd.epoch.sh == WorldPlanet.sliceHash(WorldPlanet.sliceRing(7, WorldRingPick.ringFrom(Sd.epoch.ring.c, 2400, Sd.epoch.ring.t))) and Sd.epoch.sh != Se.epoch.sh and str(SimHash.stateHash(Sd).gameplay) != str(SimHash.stateHash(Se).gameplay), "after the swap the state hash holds the new ring's slice hash: two different turns from one state hash differently")
	var fx0: int = S.out.fx.size()
	WorldEpoch.tick(S, true)
	ok(S.epoch.n == 1 and S.epoch.next == null and absf(S.epoch.lastT - 100.0) < 1e-9, "calm and held: the turn happens (epoch 1 at 100 s)")
	var turned: bool = false
	for e in S.out.fx:
		if e.type == "arena_turn" and e.n == 1 and absf(e.x - float(pcCol) * SimConst.COL) < 1.0:
			turned = true
	ok(turned, "an arena_turn event says so (turn 1, at the pivot)")
	ok(str(SimHash.stateHash(S).gameplay) != hashBefore, "the epoch is in the state hash")
	# what stayed
	var same: bool = nearest(S, px) == nb and nb.hp == nb.maxhp * 0.25 and (fallen == null or (fallen in S.buildings and not fallen.alive))
	ok(same, "the buildings near the pair are the same buildings with the same hurt and fallen state")
	ok(S.base[pcCol] == baseAt and absf(S.deform[(pcCol + 6) % SimConst.NC] - deformAt) < 1e-6, "the ground and the crater under the pair are as they were")
	var inZone: bool = false
	for c in S.craters:
		if cr != null and c == cr:
			inZone = true
	ok(cr == null or inZone, "the crater record is carried")
	var P2 := WorldPlanet.make(7)
	var nr: Dictionary = WorldRingPick.ringFrom(S.epoch.ring.c, 2400, S.epoch.ring.t)
	var sl = WorldPlanet.sliceRing(7, nr)
	ok(S.base[farCol] == sl.heights[farCol] and S.deform[farCol] == 0.0, "outside the zone the ground is the new ring's, and unmarked")
	ok(S.base.size() == 2400 and S.world.casualties == cas0 and S.world.pop0 == pop0, "the arrays keep their length and the ledger is not touched (casualties %.0f, pop0 %.0f)" % [S.world.casualties, S.world.pop0])
	var seenIds: Dictionary = {}
	var uniq: bool = true
	var inside: bool = true
	var dry: bool = true
	for b in S.buildings:
		var key: String = "%d/%d" % [b.place, b.plan]
		if seenIds.has(key):
			uniq = false
		seenIds[key] = true
		if b.x < 0.0 or b.x >= SimConst.W:
			inside = false
		if WorldStructures.baseY(S, b) < -1.0 * 75.0:
			dry = false
	ok(uniq and inside and dry, "every building has a unique place and plan, stands inside the world and on dry ground (%d buildings, %d before)" % [S.buildings.size(), nbCount0])
	for f in S.fighters:
		if f.y < WorldTerrain.groundY(S, f.x) - 0.001:
			ok(false, "a fighter is under the new ground")
	# --- the caps after a turn
	ok(WorldEpoch.ask(S, "test", px, 1, 0).is_empty(), "straight after a turn there is no new ask (60 s apart)")
	S.T = 170.0
	ok(not WorldEpoch.ask(S, "test", px, -1, 0).is_empty(), "60 s later there is")
	S.epoch.ask = null
	S.epoch.n = 4
	ok(WorldEpoch.ask(S, "test", px, 1, 0).is_empty(), "and none past the fourth turn")
	# --- the drift cap
	var S2 := ready(4800)
	var e2: Dictionary = S2.epoch
	var pc2: int = posmod(int(round(mid(S2) / SimConst.COL)), SimConst.NC)
	var ring2: Dictionary = WorldRingPick.ringFrom(e2.ring.c, 4800, e2.ring.t)
	var M2: Array = WorldPlanet.columnPoint(P, ring2, pc2)
	e2.c0 = WorldEpoch._rot(e2.ring.c, M2, -36.0 * PI / 180.0)   # the axis is 36 degrees from where it began, the way a +x turn would add to
	var cs2: Array = WorldEpoch.ask(S2, "test", mid(S2), 1, 0)
	var maxd: float = 0.0
	for c in cs2:
		maxd = maxf(maxd, c.drift)
	ok(cs2.size() == 1 and maxd <= 40.0 + 1e-9 and cs2[0].bearing == 2.5, "a ring already 36 degrees from its first axis is offered only the turn that keeps it within 40 (%d of 4 candidates, drift %.1f)" % [cs2.size(), maxd])
	# --- the places a turn brings into view are the places the new ring holds and the old did not, near the pivot
	var listed: int = 0
	var wrong: int = 0
	var lists: int = 0
	for sd in range(1, 9):
		SimConst.setArena(4800)
		var PL := WorldPlanet.make(sd)
		var pk: Dictionary = WorldPlanet.pick(PL, 2)
		if not pk.ok:
			continue
		var spc: Dictionary = {"c": pk.circle.n, "t": pk.circle.u, "cols": 4800}
		var Ex: Dictionary = {"ring": spc, "c0": spc.c}
		var old2: Dictionary = WorldRingPick.ringFrom(spc.c, 4800, spc.t)
		for pcx in [600, 1900, 3300]:
			for sdn in [1, -1]:
				for c in WorldEpoch.candidates(PL, Ex, pcx, sdn):
					lists += 1
					var nr2: Dictionary = WorldRingPick.ringFrom(c.spec.c, 4800, c.spec.t)
					for pp in c.places:
						listed += 1
						if not WorldEpoch._held(PL, nr2, pp.id) or WorldEpoch._held(PL, old2, pp.id) or absf(pp.arc) > float(d.viewUnits):
							wrong += 1
	ok(lists >= 40 and wrong == 0, "over 8 planets, 3 pivots and both sides (%d candidate lists), every place a turn lists (%d in all) is held by the new ring, not the old, within view" % [lists, listed])
	# --- a landing turns less rather than not at all: the angle is scaled so the ground under the fighters moves at most moveMax units (450 since Game Design 2026-10-23), never under 2 degrees
	var MM: float = float(d.moveMax)
	# Warm rings only: the chosen bearing (10) and the smallest candidate (2.5). The swap takes the largest warm angle that keeps the pair's ground within moveMax units; if none does it waits; if even 2 degrees
	# would not it refuses (the pick is dropped, the director asks again).
	var scaledOk: bool = true
	var scaleLog: Array = []
	var seen: Dictionary = {}
	for off in [0.0, 3600.0, 11000.0, 12000.0, 14000.0, 40000.0]:   # 450: ten to 2,590 units, 2.5 degrees to 10,300, waits to 12,900, refused past
		var Sg := ready(4800)
		var pxg: float = mid(Sg)
		var P4 := WorldPlanet.make(7)
		WorldEpoch.ask(Sg, "landing", pxg - off, 1, 0)   # the pivot predicted `off` units from where the pair rest
		WorldEpoch.choose(Sg, 3)   # the 10 degree candidate
		warmAll(Sg)
		var ringG: Dictionary = WorldRingPick.ringFrom(Sg.epoch.ring.c, 4800, Sg.epoch.ring.t)
		var smax: float = 0.0
		for f in Sg.fighters:
			smax = maxf(smax, absf(SimWrap.sdx(float(Sg.epoch.next.pc) * SimConst.COL, f.x)))
		var kind: String = "refuse" if smax * sin(2.0 * PI / 180.0) > MM else ("wait" if smax * sin(2.5 * PI / 180.0) > MM and smax * sin(10.0 * PI / 180.0) > MM else ("ten" if smax * sin(10.0 * PI / 180.0) <= MM else "twofive"))
		seen[kind] = true
		WorldEpoch.tick(Sg, true)
		var used: float = 0.0
		for e in Sg.out.fx:
			if e.type == "arena_turn":
				used = e.amount
		var nrG: Dictionary = WorldRingPick.ringFrom(Sg.epoch.ring.c, 4800, Sg.epoch.ring.t)
		var move: float = 0.0
		for f in Sg.fighters:
			var colf: int = posmod(int(round(f.x / SimConst.COL)), SimConst.NC)
			var a1: Array = WorldPlanet.columnPoint(P4, ringG, colf)
			var b1: Array = WorldPlanet.columnPoint(P4, nrG, colf)
			move = maxf(move, sqrt(pow(a1[0] - b1[0], 2) + pow(a1[1] - b1[1], 2) + pow(a1[2] - b1[2], 2)) * P4.R)
		var good: bool = Sg.epoch.cold == 0
		if kind == "refuse":
			good = good and Sg.epoch.n == 0 and Sg.epoch.next == null and Sg.epoch.refused == 1 and WorldEpoch.warmAngles(Sg).is_empty() and not WorldEpoch.ask(Sg, "again", pxg, 1, 0).is_empty()
		elif kind == "wait":
			good = good and Sg.epoch.n == 0 and Sg.epoch.next != null and Sg.epoch.waited >= 1
			# the next moment: the pair on the pivot, and the same decided turn goes ahead at its own bearing
			for f in Sg.fighters:
				f.x = float(Sg.epoch.next.pc) * SimConst.COL
			WorldEpoch.tick(Sg, true)
			good = good and Sg.epoch.n == 1 and Sg.epoch.cold == 0
			for e in Sg.out.fx:
				if e.type == "arena_turn":
					used = e.amount
			good = good and absf(used - 10.0) < 1e-9
		else:
			var wantDeg: float = 10.0 if kind == "ten" else 2.5
			good = good and Sg.epoch.n == 1 and absf(used - wantDeg) < 1e-9 and move <= MM * 1.02
		if not good:
			scaledOk = false
		scaleLog.append("%.0f off: smax %.0f %s%s" % [off, smax, kind, "" if kind == "refuse" or kind == "wait" else " (%.1f degrees, ground moved %.0f)" % [used, move]])
	ok(scaledOk and seen.has("ten") and seen.has("twofive") and seen.has("wait") and seen.has("refuse"), "swap on a warm ring only: the 10 degrees, else the warm 2.5 if it holds the ground within moveMax (450), else it waits for the next moment, and when even 2 would move it more it refuses and the director can ask again (%s)" % " | ".join(scaleLog))
	var Sc := ready(2400)
	WorldEpoch.ask(Sc, "t", mid(Sc), 1, 0)
	WorldEpoch.choose(Sc, 0)
	ok(Sc.epoch.next.tick == Sc.tick and Sc.epoch.next.due == 0, "choose records its tick and the moment's due")
	WorldEpoch.cancel(Sc)
	ok(Sc.epoch.next == null and Sc.epoch.ask == null and not WorldEpoch.ask(Sc, "t", mid(Sc), 1, 0).is_empty(), "cancel drops a pending pick, and the director can ask again")
	# --- the warm read is the read
	var Sw := ready(1200)
	WorldEpoch.ask(Sw, "test", mid(Sw), 1, 0)
	WorldEpoch.choose(Sw, 0)
	var spw: int = 0
	Sw.epoch.next.k = 64
	while WorldEpoch.warmAngles(Sw).is_empty():
		WorldEpoch.tick(Sw, false)
		spw += 1
		if spw == 3:
			WorldEpoch.tick(Sw, true)   # a ring that is part read is not warm: no swap
			if Sw.epoch.n != 0 or not WorldEpoch.warmAngles(Sw).is_empty():
				fails += 1
				print("  FAIL  a part-read ring swapped or counted warm")
	var rr: Dictionary = WorldRingPick.ringFrom(Sw.epoch.next.spec.c, 1200, Sw.epoch.next.spec.t)
	var slw = WorldPlanet.sliceRing(7, rr)
	var P3 := WorldPlanet.make(7)
	var cold = WorldPlanet.readSlice(P3, rr, rr.u)
	ok(spw >= 15 and WorldPlanet.sliceHash(slw) == WorldPlanet.sliceHash(cold) and slw.held.size() == cold.held.size(), "a ring read 64 columns at a time (%d steps) is readSlice's slice, hash and held places" % (spw + 1))
	# --- a turn is the same with or without the warm read, and on every size, and plays on
	var hashes: Array = []
	var colds: Array = []
	for warm in [0, 1, 2]:   # warmed 100 columns a call, warmed 640 a call, and a state carried into a process that never warmed it (the jobs are gone: the swap reads, and says so)
		var Sx := ready(2400)
		WorldEpoch.ask(Sx, "test", mid(Sx), 1, 0)
		var step: int = 100 if warm == 0 else 640
		WorldEpoch.choose(Sx, 2, step)
		while WorldEpoch.warmAngles(Sx).size() < 2:
			WorldEpoch.tick(Sx, false)
		if warm == 2:
			WorldEpoch._jobs.clear()
		WorldEpoch.tick(Sx, true)
		for t in range(ticks):
			SimCore.step(Sx)
		hashes.append("%d/%s" % [Sx.epoch.n, str(SimHash.stateHash(Sx).gameplay)])
		colds.append(Sx.epoch.cold)
	ok(hashes[0] == hashes[1] and hashes[1] == hashes[2] and hashes[0].begins_with("1/") and colds == [0, 0, 1], "a Half match turned at 100 s plays %d ticks on to the same hash however the rings were warmed (100 or 640 columns a call, or read cold: the cold read is counted, %s) (%s)" % [ticks, str(colds), hashes[0].substr(0, 14)])
	var runs: Array = []
	for r in range(2):
		var Sy := ready(1200)
		WorldEpoch.ask(Sy, "test", mid(Sy), -1, 0)
		WorldEpoch.choose(Sy, 3)
		warmAll(Sy)
		WorldEpoch.tick(Sy, true)
		for t in range(ticks):
			SimCore.step(Sy)
		runs.append("%d/%d/%s" % [Sy.epoch.n, Sy.buildings.size(), str(SimHash.stateHash(Sy).gameplay)])
	ok(runs[0] == runs[1] and runs[0].begins_with("1/"), "a Close match turned to the -x side at the largest bearing plays on and plays the same twice (%s)" % runs[0])
	var Sz := ready(4800)
	var zb: int = Sz.buildings.size()
	WorldEpoch.ask(Sz, "test", mid(Sz), 1, 0)
	WorldEpoch.choose(Sz, 0)
	warmAll(Sz)
	WorldEpoch.tick(Sz, true)
	for t in range(300):
		SimCore.step(Sz)
	ok(Sz.epoch.n == 1 and Sz.buildings.size() > 0 and zb != 118, "a Whole match turns too and plays on (%d buildings before, %d after)" % [zb, Sz.buildings.size()])
	# --- the pick's interface: k, and the fallback ring (2.5 for a landing, 0 for a form pick's exact pivot)
	var Sf := ready(2400)
	WorldEpoch.ask(Sf, "t", mid(Sf), 1, 0)
	WorldEpoch.choose(Sf, 3, 16, 0.0)
	var hf0: String = str(SimHash.stateHash(Sf).gameplay)
	ok(Sf.epoch.warm.size() == 1 and Sf.epoch.next.k == 16 and Sf.epoch.next.fb == 0.0, "fallbackDeg 0 (a form pick) warms one ring, at the k the pick brings")
	var Sg2 := ready(2400)
	WorldEpoch.ask(Sg2, "t", mid(Sg2), 1, 0)
	WorldEpoch.choose(Sg2, 3, 16, 2.5)
	ok(Sg2.epoch.warm.size() == 2 and Sg2.epoch.next.fb == 2.5 and str(SimHash.stateHash(Sg2).gameplay) != hf0, "a landing pick (fallback 2.5) warms two, and k and the fallback are in the hash")
	var Sh2 := ready(2400)
	WorldEpoch.ask(Sh2, "t", mid(Sh2), 1, 0)
	WorldEpoch.choose(Sh2, 0, 0, 2.5)
	ok(Sh2.epoch.warm.size() == 1 and Sh2.epoch.next.k == int(d.warmCols), "a fallback not under the chosen bearing is left out, and k 0 is the data's")
	var cols16: int = 0
	var Si := ready(2400)
	WorldEpoch.ask(Si, "t", mid(Si), 1, 0)
	WorldEpoch.choose(Si, 3, 16, 2.5)
	for t in range(10):
		SimCore.step(Si)
	for w in Si.epoch.warm:
		cols16 = maxi(cols16, int(w.cols))
	ok(cols16 == 160 and Si.epoch.n == 0, "SimCore.step alone warms: 10 sim ticks at k 16 read 160 columns of each ring")
	# --- a replay of a match that turns, headless, no host: the same swap tick as play
	var turning: Array = []
	var A: Dictionary = {}
	for sd in range(1, 13):
		A = playRun(sd, 0)
		if A.tick >= 0:
			turning.append([sd, A])
			if turning.size() >= 2:
				break
	var replayOk: bool = turning.size() >= 1
	var rlog: Array = []
	for tr in turning:
		var B: Dictionary = playRun(tr[0], 0)   # the replay
		var Cc: Dictionary = playRun(tr[0], 1)   # slices lost mid-warm
		var Dd: Dictionary = playRun(tr[0], 2)   # hashed every tick
		var identical: bool = B.tick == tr[1].tick and B.hash == tr[1].hash and Cc.tick == tr[1].tick and Cc.hash == tr[1].hash and Dd.tick == tr[1].tick and Dd.hash == tr[1].hash and Cc.cold == 0 and tr[1].cold == 0 and tr[1].unprep == 0
		if not identical:
			replayOk = false
		rlog.append("seed %d swaps on tick %d (waited %d)" % [tr[0], tr[1].tick, tr[1].waited])
	ok(replayOk, "a match played by SimCore.step alone (no host) turns on the same tick and to the same hash when replayed, when its slices are lost mid-warm, and when it is hashed every tick (%s)" % " | ".join(rlog))
	# --- the swap's preparation is made by the warm ticks, and the turn is the same with or without it
	var ph: Array = []
	var pun: Array = []
	var ptime: Array = []
	for mode in [0, 1]:   # 0: the warm ticks prepared it; 1: the preparation is lost before the swap (the swap makes it itself)
		var Sp := ready(2400)
		WorldEpoch.ask(Sp, "prep", mid(Sp), 1, 0)
		WorldEpoch.choose(Sp, 3, 64, 2.5)
		var guard: int = 0
		var allReady: bool = false
		while not allReady and guard < 1500:
			WorldEpoch.tick(Sp, false)
			guard += 1
			allReady = WorldEpoch.warmAngles(Sp).size() == Sp.epoch.warm.size() and WorldEpoch._plans.has(Sp.worldId)
			if allReady:
				var plp: Dictionary = WorldEpoch._plans[Sp.worldId]
				allReady = int(plp.wtN) >= SimConst.NC and plp.e.size() == Sp.epoch.warm.size()
				for kk in plp.e:
					if not (plp.e[kk].ready and plp.e[kk].sh >= 0):
						allReady = false
		if mode == 1:
			WorldEpoch._plans.clear()
		for f in Sp.fighters:
			f.x = float(Sp.epoch.next.pc) * SimConst.COL
		var tp0: int = Time.get_ticks_usec()
		WorldEpoch.tick(Sp, true)
		ptime.append(float(Time.get_ticks_usec() - tp0) / 1000.0)
		for t in range(120):
			SimCore.step(Sp)
		ph.append("%d/%s" % [Sp.epoch.n, str(SimHash.stateHash(Sp).gameplay)])
		pun.append(int(Sp.epoch.unprep))
	ok(ph[0] == ph[1] and ph[0].begins_with("1/") and pun == [0, 1], "a swap on the preparation the warm ticks made (%.1f ms) is the swap that makes it itself (%.1f ms): the same state hash after 120 ticks (%s); unprep counts [%s]" % [ptime[0], ptime[1], ph[0].substr(0, 14), ",".join(PackedStringArray(pun.map(func(v): return str(v))))])
	# WorldWater.init is the water it was: the original laps, written out here, over a hand-made world and planet rings with and without sea
	var waterOk: bool = true
	var seaSeen: int = 0
	var cases: Array = [[{"intro": false}, 1]]
	for pl2 in [1, 3, 5, 7, 11]:
		for cc in [1200, 2400, 4800]:
			cases.append([{"planet": pl2, "touch": 3, "arena": {"cols": cc}, "intro": false}, pl2])
	for cs in cases:
		var Sw2 := SimCore.createSim()
		SimCore.newMatch(Sw2, 1, {}, cs[0])
		var ref := PackedFloat32Array()
		ref.resize(SimConst.NC)
		ref.fill(0.0)
		var NC2: int = SimConst.NC
		var lowr: PackedFloat32Array = WorldTerrain.lowD(Sw2)
		for i in range(NC2):
			if Sw2.base[i] < WorldWater.RESERVOIR_BASE:
				ref[i] = maxf(0.0, WorldWater.SEA_LEVEL - (Sw2.base[i] + lowr[i]))
		for dir in [1, -1]:
			var wet: bool = false
			for lap in range(2 * NC2):
				var i2: int = lap % NC2 if dir == 1 else NC2 - 1 - (lap % NC2)
				if Sw2.base[i2] < WorldWater.RESERVOIR_BASE:
					wet = true
				elif wet:
					var g2: float = Sw2.base[i2] + lowr[i2]
					if g2 < WorldWater.SHORE_WET:
						ref[i2] = WorldWater.SEA_LEVEL - g2
					else:
						wet = false
		WorldWater.init(Sw2)
		if Sw2.water != ref:
			waterOk = false
		for i in range(NC2):
			if ref[i] > 0.0:
				seaSeen += 1
				break
	ok(waterOk and seaSeen >= 2, "WorldWater.init over the hand-made world and 15 planet rings (%d of them with sea): the same water as the original laps, bit for bit" % seaSeen)
	print("EPOCH: %d check(s) failed" % fails)
	quit()
