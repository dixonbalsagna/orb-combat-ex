extends SceneTree
# WorldPlanet's time-sliced loading: a job gives the same bits as the whole call however it is stepped.
#   godot --headless --path . --script res://sim/world/tools/planet_job_check.gd
var fails: int = 0


func ok(c: bool, w: String) -> void:
	print("  %s  %s" % ["ok  " if c else "FAIL", w])
	if not c:
		fails += 1


func hexd(x: float) -> String:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_double(0, x)
	return b.hex_encode()


func placesKey(P: WorldPlanet.Planet) -> String:
	var s: String = "%d:" % P.n
	for i in range(P.n):
		s += "%s%s%s%d%s;" % [hexd(P.px[i]), hexd(P.py[i]), hexd(P.pz[i]), P.kind[i], hexd(P.rad[i])]
	for i in range(P.people.size()):
		s += str(P.people[i]) + ","
	return s


func _init() -> void:
	# ---- the order
	var ord: PackedInt32Array = WorldPlanet.columnOrder(SimConst.NC)
	var seen := {}
	for i in ord:
		seen[i] = true
	ok(ord.size() == SimConst.NC and seen.size() == SimConst.NC and ord[0] == WorldPlanet.TOUCH_COL and ord[1] == WorldPlanet.TOUCH_COL + 1 and ord[2] == WorldPlanet.TOUCH_COL - 1, "the columns come nearest the touch-down first, each once (%d)" % ord.size())
	# ---- the places: a job gives the planet the whole call gives, for any chunk
	WorldPlanet.forget()
	var Pw: WorldPlanet.Planet = WorldPlanet.make(13)   # a planet with no story entry: Everhold's places are stored, there is nothing to step
	var want: String = placesKey(Pw)
	var p11w: WorldPlanet.Planet = WorldPlanet.make(11)
	var want11: String = placesKey(p11w)
	var allSame: bool = true
	var chunks := [1, 37, 1000000]
	for ch in chunks:
		WorldPlanet.forget()
		var job := WorldPlanet.PlaceJob.new(13)
		var guard: int = 0
		while not job.done and guard < 100000:
			job.step(ch)
			guard += 1
		if placesKey(job.P) != want:
			allSame = false
	ok(allSame, "the places of planet 13 are the same bits stepped by 1, 37 or all at once")
	WorldPlanet.forget()
	var j11 := WorldPlanet.PlaceJob.new(11)
	while not j11.done:
		j11.step(500)
	ok(placesKey(j11.P) == want11, "and planet 11's")
	var memo := WorldPlanet.PlaceJob.new(11)
	ok(memo.done and memo.P == j11.P, "a finished planet is memoised: the next job is done at once")
	WorldPlanet.forget()
	var story := WorldPlanet.PlaceJob.new(7)
	ok(story.done and story.P.n == 42, "a story planet (Everhold) is done at once: its places are stored")
	# ---- the pick
	WorldPlanet.forget()
	var P: WorldPlanet.Planet = WorldPlanet.make(7)
	var pickSame: bool = true
	for t in range(14):
		for mode in [0, 1, 2]:
			var wholeD: Dictionary
			var job2: WorldPlanet.PickJob
			if mode == 0:
				wholeD = WorldPlanet.pick(P, t)
				job2 = WorldPlanet.PickJob.new(P, t, PackedByteArray(), false, false)
			elif mode == 1:
				wholeD = WorldPlanet.pick(P, t, PackedByteArray(), true)
				job2 = WorldPlanet.PickJob.new(P, t, PackedByteArray(), true, false)
			else:
				wholeD = WorldPlanet.pickEither(P, t)
				job2 = WorldPlanet.PickJob.new(P, t, PackedByteArray(), false, true)
			var guard2: int = 0
			while not job2.done and guard2 < 10000:
				job2.step(1 + (t * 7) % 60)
				guard2 += 1
			var r2: Dictionary = job2.result
			if r2.ok != wholeD.ok or r2.index != wholeD.index or r2.tried != wholeD.tried or hexd(r2.T[0]) != hexd(wholeD.T[0]):
				pickSame = false
			if mode == 2 and r2.relaxed != wholeD.relaxed:
				pickSame = false
	ok(pickSame, "a pick job gives the pick, relaxed pick and offers' pick of 14 touch-downs (same circle, index, tries, point), stepped by 1 to 60")
	# ---- the slice
	var pr: Dictionary = WorldPlanet.pick(P, 3)
	var whole: WorldPlanet.Slice = WorldPlanet.readSlice(P, pr.circle, pr.T)
	var wantHash: int = WorldPlanet.sliceHash(whole)
	var hashes := []
	for ch2 in [1, 13, 500, 1000000]:
		var sj := WorldPlanet.SliceJob.new(P, pr.circle, pr.T, PackedByteArray())
		var g: int = 0
		while not sj.done and g < 100000:
			sj.step(ch2)
			g += 1
		hashes.append(WorldPlanet.sliceHash(sj.S))
		if ch2 == 1000000:
			ok(sj.S.held.size() == whole.held.size() and not sj.S.provisional, "the finished slice holds the same places and is no longer provisional")
	ok(hashes[0] == wantHash and hashes[1] == wantHash and hashes[2] == wantHash and hashes[3] == wantHash, "the slice hash is the whole read's (%08x) stepped by 1, 13, 500 or all at once" % wantHash)
	# the coarse stage, and nearest first
	var sj2 := WorldPlanet.SliceJob.new(P, pr.circle, pr.T, PackedByteArray())
	var coarseUnits: int = sj2.coarse.size() + 8
	sj2.step(coarseUnits)
	var sumErr: float = 0.0
	var worstErr: float = 0.0
	var biomeSame: int = 0
	for i in range(SimConst.NC):
		var e: float = absf(sj2.S.heights[i] - whole.heights[i])
		sumErr += e
		worstErr = maxf(worstErr, e)
		if sj2.S.biomes[i] == whole.biomes[i]:
			biomeSame += 1
	ok(sj2.S.provisional and sj2.phase == 1, "after the coarse stage (%d columns of work) the slice is provisional and the full read is next" % coarseUnits)
	print("        coarse read against the full one: mean height error %.1f units, worst %.0f; biomes equal in %.1f%% of columns" % [sumErr / SimConst.NC, worstErr, 100.0 * float(biomeSame) / SimConst.NC])
	sj2.step(300)
	var nearFinal: bool = true
	for k in range(ord.size()):
		if k >= 300:
			break
		var col: int = ord[k]
		if sj2.S.heights[col] != whole.heights[col] or sj2.S.biomes[col] != whole.biomes[col]:
			nearFinal = false
	ok(nearFinal, "after 300 units of the full read the 300 columns nearest the touch-down are already final")
	# a slice through both poles (the floes and bergs the coarse read cannot see)
	var poles: Dictionary = WorldPlanet.circleOf(pr.T, WorldPlanet._unit(WorldPlanet._cross(pr.T, [0.0, 1.0, 0.0])))
	var wholeP: WorldPlanet.Slice = WorldPlanet.readSlice(P, poles, pr.T)
	var sjp := WorldPlanet.SliceJob.new(P, poles, pr.T, PackedByteArray())
	sjp.step(sjp.coarse.size() + 8)
	var polarBiomeSame: int = 0
	for i in range(SimConst.NC):
		if sjp.S.biomes[i] == wholeP.biomes[i]:
			polarBiomeSame += 1
	print("        through both poles: coarse biomes equal in %.1f%% of columns" % (100.0 * float(polarBiomeSame) / SimConst.NC))
	sjp.step(1000000)
	ok(WorldPlanet.sliceHash(sjp.S) == WorldPlanet.sliceHash(wholeP), "a polar slice finishes to the whole read's bits as well")
	# ---- the whole load
	WorldPlanet.forget()
	var lj := WorldPlanet.beginLoad(7, 3)
	var stages := {}
	var frames: int = 0
	while not lj.done and frames < 100000:
		lj.step(30)
		stages[lj.stage] = true
		frames += 1
	var ref: WorldPlanet.Slice = WorldPlanet.sliceFor(7, 3)
	ok(lj.done and lj.ok and WorldPlanet.sliceHash(lj.slice) == wantHash and ref == lj.slice, "a load job (planet, pick, slice) finishes in %d frames of 30 units to the same slice, and the memo holds it" % frames)
	ok(lj.slice != null and not lj.slice.provisional and lj.progress() == 1.0, "and reports done")
	WorldPlanet.forget()
	var P13: WorldPlanet.Planet = WorldPlanet.make(13)   # no story entry: the places are generated, so the load has a first stage to step through
	var pr13: Dictionary = WorldPlanet.pick(P13, 3)
	var want13: int = WorldPlanet.sliceHash(WorldPlanet.readSlice(P13, pr13.circle, pr13.T))
	WorldPlanet.forget()
	var lj2 := WorldPlanet.beginLoad(13, 3)
	lj2.step(5)
	var prov: bool = lj2.stage == 0
	lj2.step(9000)
	var sawProv: bool = lj2.slice != null and lj2.slice.provisional
	lj2.finishNow()
	ok(prov and sawProv and lj2.done and WorldPlanet.sliceHash(lj2.slice) == want13, "finishNow after a partial step gives the same bits (a skipped intro does not skip the load)")
	var lj3 := WorldPlanet.beginLoad(13, 3)
	ok(lj3.done and lj3.slice == lj2.slice, "a load of a slice already memoised is done at once")
	# a touch-down with no slice: ok is false and the job ends
	WorldPlanet.forget()
	var standingNone := PackedByteArray()
	standingNone.resize(WorldPlanet.make(7).n)
	var lj4 := WorldPlanet.beginLoad(7, 5, standingNone)
	lj4.finishNow()
	ok(lj4.done and not lj4.ok and lj4.slice == null, "with every place fallen no circle is found: the job ends with ok false")
	print("PLANETJOB: %d check(s) failed" % fails)
	quit()
