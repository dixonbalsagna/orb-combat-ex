import sys
p = sys.argv[1] + 'sim/world/tools/ringpick_check.gd'
s = open(p, encoding='utf-8').read()
a = '''	print("RINGPICK: %d check(s) failed" % fails)'''
assert s.count(a) == 1
new = '''	# --- the first ring turns toward land when it is under Close's minimum (Game Design rulings-2026-10-23 section 6)
	var P3 := WorldPlanet.make(3)
	var coastal: int = 8   # planet 3's city 8: the ring round it is 26% land against Close's 40%
	var base3: Dictionary = WorldRingPick.roundSpec(WorldRingPick.placePoint(P3, coastal), 1200, 0.0)
	var ev3: Dictionary = WorldRingPick.evalRing(P3, {"c": base3.c, "t": base3.t, "cols": 1200, "kind": "round", "place": coastal})
	var fr3: Dictionary = WorldRingPick.firstRing(P3, coastal, 11)
	var evt: Dictionary = WorldRingPick.evalRing(P3, {"c": fr3.c, "t": fr3.t, "cols": fr3.cols, "kind": "through", "place": coastal})
	var ring3: Dictionary = WorldRingPick.ringFrom(fr3.c, fr3.cols, fr3.t)
	var hp: Array = WorldRingPick.placePoint(P3, coastal)
	ok(not WorldRingPick.meets(ev3, "close") and ev3.land < 0.4 and fr3.turned and fr3.kind == "through" and WorldRingPick.meets(evt, "close") and evt.land > ev3.land and absf(WorldPlanet.lateral(P3, ring3, hp[0], hp[1], hp[2])) < 0.5, "a coastal home (planet 3, city 8: the ring round it is %.0f%% land): the first ring turns to a ring through the home that meets Close's minimum with %.0f%% land, the home on it" % [100.0 * ev3.land, 100.0 * evt.land])
	var P7b := WorldPlanet.make(7)
	var keep: Dictionary = WorldRingPick.firstRing(P7b, 0, 3)
	var old: Dictionary = WorldRingPick.roundSpec(WorldRingPick.placePoint(P7b, 0), 1200, SimRng.new((3 * 7919 + 15485863) & 0xFFFFFFFF).next() * 2.0 * SimMathx.PI)
	ok(not keep.turned and keep.kind == "round" and bitsEq(keep.c, old.c) and bitsEq(keep.t, old.t), "a first ring that already meets the minimum is the ring it was, to the bit (planet 7, home 0)")
	var fallen := PackedByteArray()
	fallen.resize(P3.n)
	fallen.fill(0)
	var stands: Dictionary = WorldRingPick.firstRing(P3, coastal, 11, {"standing": fallen})
	var story: Dictionary = WorldRingPick.roundSpec(WorldRingPick.placePoint(P3, coastal), 1200, SimRng.new((11 * 7919 + 15485863) & 0xFFFFFFFF).next() * 2.0 * SimMathx.PI)
	ok(not stands.turned and stands.kind == "round" and bitsEq(stands.c, story.c) and bitsEq(stands.t, story.t), "when no bearing meets the minimum (every place fallen) the story's ring stands as it is")
	var fixedN: int = 0
	var failN: int = 0
	var allOk: bool = true
	for pl in range(1, 9):
		var PQ := WorldPlanet.make(pl)
		for h in range(PQ.n):
			if int(PQ.kind[h]) != WorldPlanet.KIND_CITY:
				continue
			var fb2: Dictionary = WorldRingPick.roundSpec(WorldRingPick.placePoint(PQ, h), 1200, 0.0)
			var fe2: Dictionary = WorldRingPick.evalRing(PQ, {"c": fb2.c, "t": fb2.t, "cols": 1200, "kind": "round", "place": h})
			if WorldRingPick.meets(fe2, "close"):
				continue
			failN += 1
			var turned: Dictionary = WorldRingPick.firstRing(PQ, h, 11)
			var te2: Dictionary = WorldRingPick.evalRing(PQ, {"c": turned.c, "t": turned.t, "cols": turned.cols, "kind": turned.kind, "place": h})
			if turned.turned and WorldRingPick.meets(te2, "close"):
				fixedN += 1
			else:
				allOk = false
	ok(failN >= 8 and allOk, "over 8 planets' cities, every first ring that missed the minimum (%d of them) was turned to one that meets it (%d)" % [failN, fixedN])
	var jf: WorldRingPick.FirstJob = WorldRingPick.beginFirstRing(P3, coastal, 11)
	var fsteps: int = 0
	while not jf.step(2):
		fsteps += 1
	ok(jf.spec.turned and bitsEq(jf.spec.c, fr3.c) and bitsEq(jf.spec.t, fr3.t) and fsteps >= 2 and jf.total == 13, "a stepped first ring (%d steps of 2, up to %d reads) is the one made at once, and the same twice" % [fsteps + 1, jf.total])
	var S3 := SimCore.createSim()
	SimCore.newMatch(S3, 1, {}, {"planet": 3, "touch": 3, "arena": WorldRingPick.arenaOf(fr3), "intro": false})
	for t in range(120):
		SimCore.step(S3)
	ok(S3.arenaCols == 1200 and S3.fighters.size() == 2, "the turned first ring plays: a match on its arena, 120 ticks")
	print("RINGPICK: %d check(s) failed" % fails)'''
s = s.replace(a, new)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('tests added')
