extends SceneTree
# Game Design's asks of World (docs/design/run-mode.md section 6), measured on WorldPlanet; and the module's costs.
#   godot --headless --path . --script res://sim/world/tools/planet_measure.gd [-- <seeds> <fallen sets> <touch-downs>]
# Run at below-normal priority; a timing taken while the machine is busy is an upper bound.
var out: Array = []


func say(s: String) -> void:
	print(s)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var nseeds: int = int(args[0]) if args.size() > 0 else 2
	var nsets: int = int(args[1]) if args.size() > 1 else 6
	var ntouch: int = int(args[2]) if args.size() > 2 else 12
	var c: Dictionary = WorldPlanet.cfg()
	# ---- costs
	var P7: WorldPlanet.Planet = WorldPlanet.make(7)
	var t0: int = Time.get_ticks_usec()
	WorldPlanet.forget()
	P7 = WorldPlanet.make(7)
	var tPlanet: float = float(Time.get_ticks_usec() - t0) / 1000.0
	var best: float = 1.0e9
	var pk: Dictionary = WorldPlanet.pick(P7, 3)
	var tSlice: float = 1.0e9
	for rep in range(3):
		WorldPlanet.forget()
		P7 = WorldPlanet.make(7)
		t0 = Time.get_ticks_usec()
		WorldPlanet.readSlice(P7, pk.circle, pk.T)
		tSlice = minf(tSlice, float(Time.get_ticks_usec() - t0) / 1000.0)
	# a slice through both poles
	var poles: Dictionary = WorldPlanet.circleOf(pk.T, WorldPlanet._unit(WorldPlanet._cross(pk.T, [0.0, 1.0, 0.0])))
	var tPolar: float = 1.0e9
	for rep in range(3):
		WorldPlanet.forget()
		P7 = WorldPlanet.make(7)
		t0 = Time.get_ticks_usec()
		WorldPlanet.readSlice(P7, poles, pk.T)
		tPolar = minf(tPolar, float(Time.get_ticks_usec() - t0) / 1000.0)
	var tPick: float = 0.0
	for t in range(20):
		t0 = Time.get_ticks_usec()
		WorldPlanet.pick(P7, t)
		tPick += float(Time.get_ticks_usec() - t0) / 1000.0
	say("COST: planet (places) %.0f ms; slice read, no ice %.0f ms, through both poles %.0f ms (best of 3); a pick %.0f ms (mean of 20)" % [tPlanet, tSlice, tPolar, tPick / 20.0])
	# ---- (a) slices meeting the minimum with 0 to 10 cities fallen
	say("FALLEN: strict / relaxed / strict-or-relaxed share of touch-downs that find a slice, by cities fallen (%d planets x %d fallen sets x %d touch-downs)" % [nseeds, nsets, ntouch])
	var rf := SimRng.new(4242)
	var rows: Dictionary = {}
	for sd in range(nseeds):
		var P: WorldPlanet.Planet = WorldPlanet.make(7 + sd * 4)
		var cityIds: Array = []
		for i in range(P.n):
			if P.kind[i] == WorldPlanet.KIND_CITY:
				cityIds.append(i)
		for fallen in range(0, 11):
			if fallen > cityIds.size():
				continue
			for k in range(nsets):
				# a random set of `fallen` cities
				var pool: Array = cityIds.duplicate()
				var mask := PackedByteArray()
				mask.resize(P.n)
				mask.fill(1)
				for f in range(fallen):
					var j: int = int(rf.next() * float(pool.size()))
					mask[pool[j]] = 0
					pool.remove_at(j)
				for t in range(ntouch):
					var touch: int = 1000 + k * 100 + t
					var rs: bool = WorldPlanet.pick(P, touch, mask, false).ok
					var rel: bool = WorldPlanet.pick(P, touch, mask, true).ok
					var key: int = fallen
					if not rows.has(key):
						rows[key] = [0, 0, 0, 0]
					rows[key][0] += 1
					rows[key][1] += 1 if rs else 0
					rows[key][2] += 1 if rel else 0
					rows[key][3] += 1 if (rs or rel) else 0
	for fallen in range(0, 11):
		if rows.has(fallen):
			var r: Array = rows[fallen]
			say("  %2d fallen: strict %3d%%  relaxed %3d%%  either %3d%%  (%d touch-downs)" % [fallen, round(100.0 * r[1] / r[0]), round(100.0 * r[2] / r[0]), round(100.0 * r[3] / r[0]), r[0]])
	# ---- (b) falls per stage by tier ceiling: a bound and a nearest-first estimate on accepted slices
	say("FALLS: places that can fall in one stage, by the tier's ceiling of the slice's people (an upper bound, and damage spent nearest the touch-down first)")
	var ceil: Array = [0.10, 0.30, 0.60, 0.90]
	var sum_b: Array = [0.0, 0.0, 0.0, 0.0]
	var sum_bc: Array = [0.0, 0.0, 0.0, 0.0]
	var sum_n: Array = [0.0, 0.0, 0.0, 0.0]
	var sum_nc: Array = [0.0, 0.0, 0.0, 0.0]
	var sum_d: Array = [0.0, 0.0, 0.0, 0.0]
	var max_bc: Array = [0, 0, 0, 0]
	var nsl: int = 0
	var P0: WorldPlanet.Planet = WorldPlanet.make(7)
	for t in range(120):
		var pr: Dictionary = WorldPlanet.pick(P0, 500 + t)
		if not pr.ok:
			continue
		var S: WorldPlanet.Slice = WorldPlanet.readSlice(P0, pr.circle, pr.T)
		var ppl: Array = WorldPlanet.slicePeople(P0, S, WorldPlanet.wearNew())
		var total: int = 0
		for v in ppl:
			total += v
		nsl += 1
		# the places by people, smallest first, with kinds
		var items: Array = []
		for i in range(S.held.size()):
			var cx: float = P0.px[S.held[i].id] - pr.T[0]
			var cy: float = P0.py[S.held[i].id] - pr.T[1]
			var cz: float = P0.pz[S.held[i].id] - pr.T[2]
			items.append([ppl[i], S.held[i].kind, P0.R * sqrt(cx * cx + cy * cy + cz * cz)])
		var bySize: Array = items.duplicate()
		bySize.sort_custom(func(a, b): return a[0] < b[0])
		var byDist: Array = items.duplicate()
		byDist.sort_custom(func(a, b): return a[2] < b[2])
		for ti in range(4):
			var budget: float = ceil[ti] * float(total)
			# bound: fell as many as possible (smallest first), each at 60% of its people
			var fb: int = 0
			var fbc: int = 0
			var left: float = budget
			for it in bySize:
				var need: float = 0.6 * float(it[0])
				if need <= left:
					left -= need
					fb += 1
					if it[1] == WorldPlanet.KIND_CITY:
						fbc += 1
			# nearest first: the places in order of distance from the touch-down, each taken to 60% before the next
			var fn: int = 0
			var fnc: int = 0
			var dmg: int = 0
			left = budget
			for it in byDist:
				var need2: float = 0.6 * float(it[0])
				if need2 <= left:
					left -= need2
					fn += 1
					if it[1] == WorldPlanet.KIND_CITY:
						fnc += 1
				else:
					if left >= 0.05 * float(it[0]):
						dmg += 1
					left = 0.0
					break
			sum_b[ti] += fb
			sum_bc[ti] += fbc
			sum_n[ti] += fn
			sum_nc[ti] += fnc
			sum_d[ti] += dmg
			max_bc[ti] = maxi(max_bc[ti], fbc)
	for ti in range(4):
		say("  tier ceiling %2d%%: bound %.2f places (%.2f cities, at most %d); nearest-first %.2f places (%.2f cities), %.2f more left damaged  (%d slices)" % [round(ceil[ti] * 100.0), sum_b[ti] / nsl, sum_bc[ti] / nsl, max_bc[ti], sum_n[ti] / nsl, sum_nc[ti] / nsl, sum_d[ti] / nsl, nsl])
	# ---- (c) three distinct offers with eight cities fallen
	say("OFFERS: three offers with 8 cities fallen: time and result")
	var times: Array = []
	var found3: int = 0
	var relaxedUsed: int = 0
	var trials: int = 0
	for sd in range(nseeds):
		var P2: WorldPlanet.Planet = WorldPlanet.make(7 + sd * 4)
		var cityIds2: Array = []
		for i in range(P2.n):
			if P2.kind[i] == WorldPlanet.KIND_CITY:
				cityIds2.append(i)
		for k in range(10):
			var pool2: Array = cityIds2.duplicate()
			var mask2 := PackedByteArray()
			mask2.resize(P2.n)
			mask2.fill(1)
			for f in range(8):
				var j2: int = int(rf.next() * float(pool2.size()))
				mask2[pool2[j2]] = 0
				pool2.remove_at(j2)
			var t1: int = Time.get_ticks_usec()
			var off: Array = WorldPlanet.offers(P2, 10 + k, mask2)
			times.append(float(Time.get_ticks_usec() - t1) / 1000.0)
			trials += 1
			if off.size() >= 3:
				found3 += 1
			for o in off:
				if o.relaxed:
					relaxedUsed += 1
	times.sort()
	say("  %d trials (8 of %d cities fallen each): three offers found in %d; median %.0f ms, 90th %.0f ms, worst %.0f ms; relaxed minimum used by %d offers" % [trials, 12, found3, times[times.size() / 2], times[int(times.size() * 0.9)], times[times.size() - 1], relaxedUsed])
	var t2: int = Time.get_ticks_usec()
	WorldPlanet.offers(P7, 99, PackedByteArray())
	say("  with none fallen: %.0f ms" % (float(Time.get_ticks_usec() - t2) / 1000.0))
	quit()
