extends SceneTree
## The terrain audit, ported to the planet store (terrain-globe-plan.md step 0 and 2; the strip's is terrain_audit.gd). From the repo root:
##   godot --headless --path . --script res://sim/world/tools/globe_audit.gd -- [firstSeed=1] [count=40] [ticks=3600] [maxSteps=6] [settleGrooves=0]
## Plays AI-vs-AI matches on gen 3 planets (7, 12, 3, 13, 17 in turn) and at the end samples the store's ground (WorldStore.heightDelta, the marks alone) along eight bearings out from every live record, at
## the strip's 32-unit spacing, and counts steps of more than one body height (75) between neighbours. Prints a line a match and, last, GLOBEAUDIT: the matches over maxSteps steps (the goal: 0 to 6 a match over 40 seeds).
## Also the deepest centre of a live crater against its radius (the shaft measure: 0.26 at most), the records by kind, and that the audit found marks (a globe match with none is an audit that saw nothing, and fails).
## Changes nothing in a match and draws nothing from S.rng. The long run goes at below-normal priority (CLAUDE.md).

const BH: float = 75.0
const PLANETS: Array = [7, 12, 3, 13, 17]
const SPACING: float = 32.0


func _init() -> void:
	var a: Array = OS.get_cmdline_user_args()
	var first: int = int(a[0]) if a.size() > 0 else 1
	var count: int = int(a[1]) if a.size() > 1 else 40
	var ticks: int = int(a[2]) if a.size() > 2 else 3600
	var maxSteps: int = int(a[3]) if a.size() > 3 else 6
	if a.size() > 4:   # the fifth word: 1 puts the groove settling on (globe.settleGrooves), 0 leaves it as shipped
		WorldCraters.setSettleGrooves(int(a[4]) == 1)
	var over: int = 0
	var empty: int = 0
	var worst: int = 0
	var totSteps: int = 0
	var shaftMax: float = 0.0
	for m in range(count):
		var seed: int = first + m
		var r: Dictionary = _match(seed, PLANETS[(seed - 1) % PLANETS.size()], ticks)
		if int(r.steps) > 0:
			print("   steps by the kinds of record there: %s" % str(r.kinds))
		print("seed %d planet %d: %d records (%d craters, %d trenches), %d superseded, %d steps over 1 bh (%d from the craters alone), the deepest crater relief when dug (ring against centre) %.3f of its radius" % [seed, PLANETS[(seed - 1) % PLANETS.size()], r.n, r.craters, r.trenches, r.sup, r.steps, r.csteps, r.shaft])
		totSteps += int(r.steps)
		worst = maxi(worst, int(r.steps))
		shaftMax = maxf(shaftMax, float(r.shaft))
		if int(r.steps) > maxSteps:
			over += 1
		if int(r.n) == 0:
			empty += 1
	print("steps over 1 bh a match: total %d, worst %d, goal at most %d; deepest centre %.3f of its radius (goal 0.26)" % [totSteps, worst, maxSteps, shaftMax])
	print("GLOBEAUDIT: %d match(es) over %d steps, %d with no marks" % [over, maxSteps, empty])
	quit(0)


func _match(seed: int, planet: int, ticks: int) -> Dictionary:
	WorldClimate.useGen(3)
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {}, {"intro": false, "planet": planet, "touch": 1 + seed % 3, "planetGen": 3})
	for t in range(ticks):
		if S.game.ko != null:
			break
		SimCore.step(S, null)
		S.out.fx.clear()
		S.out.feed.clear()
	var out := {"n": int(S.storeN), "craters": 0, "trenches": 0, "sup": 0, "steps": 0, "shaft": 0.0, "csteps": 0, "kinds": {}}
	var seen: Dictionary = {}   # the places a step was counted at, to a 16-unit cell: a step the records round it all see is one step
	var C := SimState.new()      # the live craters alone: the shaft measure (a groove through a bowl is not a shaft) and the steps craters make
	var ck: Array = []
	var R: float = SimConst.PLANET_NC * SimConst.COL / (2.0 * SimMathx.PI)
	for k in range(int(S.storeN)):
		var o: int = k * WorldStore.STRIDE
		var kd: int = int(S.store[o])
		if WorldStore.superseded(S, k):
			out.sup += 1
			continue
		if kd == WorldStore.KIND_CRATER:
			out.craters += 1
			var rr: float = S.store[o + 4]
			var c: Array = WorldStore.centreOf(S, k)
			ck.append(k)
			WorldStore.add(C, c[0], c[1], c[2], rr, S.store[o + 5], S.store[o + 6], S.store[o + 7], int(S.store[o + 10]), int(S.store[o + 11]), S.store[o + 8], int(S.store[o + 9]))
			out.shaft = maxf(out.shaft, WorldGlobe.relief(C, c, 1.2 * rr) / rr)   # the crater's relief just after it was dug: the ring at 1.2 R against its centre, in the craters made so far (a later neighbour's rim raises the ring and is not the shaft)
		elif kd == WorldStore.KIND_TRENCH or kd == WorldStore.KIND_SCAR:
			out.trenches += 1
		else:
			continue
		var q: Array = WorldStore.centreOf(S, k)
		var reach: float = (S.store[o + 4] * 2.2) if kd == WorldStore.KIND_CRATER else (S.store[o + 8] * 3.0 + 600.0)
		var b: Array = WorldGlobe.basis(q)
		for bi in range(8):
			var prev: float = WorldStore.heightDelta(S, q[0], q[1], q[2])
			var d: float = SPACING
			while d <= reach:
				var p: Array = WorldGlobe.pointAt(q, b, bi, d)
				var h: float = WorldStore.heightDelta(S, p[0], p[1], p[2])
				if absf(h - prev) > BH:
					var cell: String = "%d,%d,%d" % [int(floor(p[0] * R / 16.0)), int(floor(p[1] * R / 16.0)), int(floor(p[2] * R / 16.0))]
					if not seen.has(cell):
						seen[cell] = true
						out.steps += 1
						var ks: String = ""
						for kk in WorldStore.at(S, p[0], p[1], p[2]):
							var kn: String = ["crater", "crack", "scorch", "trench", "?", "scar", "heap", "merge"][int(S.store[kk * WorldStore.STRIDE])]
							if not ks.contains(kn):
								ks += kn + " "
						out.kinds[ks] = int(out.kinds.get(ks, 0)) + 1
				prev = h
				d += SPACING
	# the craters alone: the deepest centre against its radius, and the steps their bowls make
	var cseen: Dictionary = {}
	for i in range(int(C.storeN)):
		var oc: int = i * WorldStore.STRIDE
		var qc: Array = WorldStore.centreOf(C, i)
		var rc: float = C.store[oc + 4]
		var bc: Array = WorldGlobe.basis(qc)
		for bi in range(8):
			var pv: float = WorldStore.heightDelta(C, qc[0], qc[1], qc[2])
			var dc: float = SPACING
			while dc <= rc * 2.2:
				var pc: Array = WorldGlobe.pointAt(qc, bc, bi, dc)
				var hc: float = WorldStore.heightDelta(C, pc[0], pc[1], pc[2])
				if absf(hc - pv) > BH:
					var cell2: String = "%d,%d,%d" % [int(floor(pc[0] * R / 16.0)), int(floor(pc[1] * R / 16.0)), int(floor(pc[2] * R / 16.0))]
					if not cseen.has(cell2):
						cseen[cell2] = true
						out.csteps += 1
				pv = hc
				dc += SPACING
	SimCore.dispose(S)
	return out
