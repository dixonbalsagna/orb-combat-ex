extends SceneTree
# The calm turn's read for Simulation's K (window 20, third add-on; docs/world/gen2-read-speed.md section 4): the turn data's warmTotal shares k among the rings, a host's read-ahead changes nothing in the state,
# and a ring's blend and held places made in steps are the whole read's.
#   godot --headless --path . --script res://sim/world/tools/calm_read_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func turn(k: int, total: bool, ahead: int, ticks: int, gen: int = 2) -> Dictionary:
	WorldClimate.useGen(gen)
	WorldRingPick.cfg().turn["warmTotal"] = 1 if total else 0
	var S := SimCore.createSim()
	SimCore.newMatch(S, 1, {}, {"planet": 7, "touch": 3, "arena": {"cols": 2400, "turn": true}, "planetGen": gen, "intro": false})
	for t in range(30):
		SimCore.step(S)
	S.T = 100.0
	var px: float = 0.5 * (S.fighters[0].x + S.fighters[1].x)
	var c: Array = WorldEpoch.ask(S, "check", px, 1, 0)
	WorldEpoch.choose(S, c.size() - 1, k, 2.5)
	var tr: Array = []
	var reach: int = 0
	for g in range(ticks):
		if ahead > 0:
			WorldEpoch.readAhead(S, ahead)
			for p in WorldEpoch.warmPlan(S):
				reach = maxi(reach, int(p[0]) - int(p[2]))
		SimCore.step(S)
		if S.epoch.next == null:
			break
		if g % 20 == 0:
			tr.append(str(SimHash.stateHash(S).gameplay))
	return {"S": S, "trace": tr, "reach": reach}


func _init() -> void:
	var a: Dictionary = turn(12, true, 0, 60)
	var b: Dictionary = turn(12, false, 0, 60)
	var wa: Array = a.S.epoch.warm
	var wb: Array = b.S.epoch.warm
	ok(wa.size() == 2 and wa[0].cols == 60 * 6 and wa[1].cols == 60 * 6 and wb[0].cols == 60 * 12, "two rings, k 12: warmTotal reads 6 of each a tick (%d, %d columns after 60 ticks), without it 12 each (%d)" % [wa[0].cols, wa[1].cols, wb[0].cols])
	var c: Dictionary = turn(12, true, 0, 60)
	ok(a.trace == c.trace, "a turn with warmTotal is the same twice")
	# a host's read-ahead leaves the state alone
	var d: Dictionary = turn(12, true, 200, 60)
	ok(d.trace == a.trace and d.reach > 100, "a host's read-ahead (200 units between ticks; the job was up to %d columns ahead of the count) changes no state: the state hash the same every 20 ticks" % d.reach)
	var e1: Dictionary = turn(32, false, 0, 400)
	var e2: Dictionary = turn(32, false, 300, 400)
	ok(e1.trace == e2.trace and e1.S.tick == e2.S.tick and str(SimHash.stateHash(e1.S).gameplay) == str(SimHash.stateHash(e2.S).gameplay), "a whole turn to its swap, with read-ahead (300 units a tick) and without, is the same state on the same tick (%d)" % e1.S.tick)
	# the ring's blend and places in steps
	WorldClimate.useGen(2)
	SimConst.setArena(2400)
	var P := WorldPlanet.make(7)
	var T: Array = WorldPlanet.unitFromDraws(0.37, 0.62)
	var spec: Dictionary = WorldRingPick.roundSpec(T, 2400, 0.9)
	var ring: Dictionary = WorldRingPick.ringFrom(spec.c, 2400, spec.t)
	var whole: WorldPlanet.Slice = WorldPlanet.readSlice(P, ring, ring.u)
	var allSame: bool = true
	var line: String = ""
	for units in [1, 37, 400, 1 << 30]:
		var job := WorldPlanet.RingJob.new(P, ring)
		job.lazy = true
		while job.i < 2400:
			job.readTo(2400)
		var calls: int = 0
		while not job.heldStep(units):
			calls += 1
		var sl: WorldPlanet.Slice = job.slice
		var same: bool = sl.heights == whole.heights and sl.biomes == whole.biomes and sl.fine == whole.fine and str(sl.held) == str(whole.held) and not sl.pending
		allSame = allSame and same
		line += " %s (%d calls)" % ["whole" if units > 100000 else str(units), calls + 1]
	ok(allSame, "a lazy ring's blend and held places made at several budgets a call are readSlice's, bit for bit (steps of%s)" % [line])
	WorldRingPick.cfg().turn["warmTotal"] = 0
	print("CALMREAD: %d check(s) failed" % fails)
	quit()
