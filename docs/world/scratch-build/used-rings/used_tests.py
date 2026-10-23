import sys
p = sys.argv[1] + 'sim/world/tools/ringpick_check.gd'
s = open(p, encoding='utf-8').read()
a = '''	print("RINGPICK: %d check(s) failed" % fails)'''
assert s.count(a) == 1
new = '''	# --- a run never fights the same ring twice (opts.used)
	var uStat := {"n": 0, "passed": 0, "repeat": 0, "ok": 0}
	var usedOk: bool = true
	for sd in range(1, 6):
		var PU := WorldPlanet.make(sd)
		for name in ["RIVAL", "EMPRESS", "CYBORG", "PROTAGONIST"]:
			for size in ["close", "half", "whole"]:
				var first: Dictionary = WorldRingPick.pick(PU, claims[name], size, sd * 10 + 1, {"home": -1})
				var again: Dictionary = WorldRingPick.pick(PU, claims[name], size, sd * 10 + 1, {"home": -1, "used": [first.spec]})
				uStat.n += 1
				if again.ok:
					uStat.ok += 1
				if again.repeat:
					uStat.repeat += 1
				var cand: Dictionary = {"c": again.spec.c, "cols": again.spec.cols, "kind": again.kind, "place": again.place}
				if not WorldRingPick.usedMatch(cand, WorldRingPick.usedList([first.spec])):
					uStat.passed += 1
	ok(uStat.passed >= int(0.9 * float(uStat.n)) and uStat.repeat == uStat.n - uStat.passed, "over 5 planets x 4 claims x 3 sizes (%d picks), the second pick with the first in opts.used is a ring the first is not %d times (%d of them still meet the size's minimum); the rest had nothing else and say so (repeat)" % [uStat.n, uStat.passed, uStat.ok])
	var base: Dictionary = WorldRingPick.pick(PP7, claims.CYBORG, "half", 99, {"home": -1})
	var noUsed: Dictionary = WorldRingPick.pick(PP7, claims.CYBORG, "half", 99, {"home": -1, "used": []})
	ok(noUsed.idx == base.idx and bitsEq(noUsed.spec.c, base.spec.c) and not noUsed.repeat, "an empty used list is no used list: the pick is the one it was")
	var skip: Dictionary = WorldRingPick.pick(PP7, claims.CYBORG, "half", 99, {"home": -1, "used": [base.spec]})
	var viaArena: Dictionary = WorldRingPick.pick(PP7, claims.CYBORG, "half", 99, {"home": -1, "used": [JSON.parse_string(JSON.stringify(WorldRingPick.arenaOf(base.spec)))]})
	var viaPlace: Dictionary = WorldRingPick.pick(PP7, claims.CYBORG, "half", 99, {"home": -1, "used": [{"place": base.place, "kind": base.kind, "cols": base.spec.cols}]})
	ok(skip.idx != base.idx and not skip.repeat and viaArena.idx == skip.idx and bitsEq(viaArena.spec.c, skip.spec.c), "a used ring is passed over (the pick moves on from candidate %d to %d), and a setup.arena that has been through JSON, exact bits, is the same entry as the spec" % [base.idx, skip.idx])
	ok(viaPlace.idx != base.idx and (base.place < 0 or viaPlace.place != base.place), "a used entry that names a place and a kind passes over every candidate round or through that place")
	# the same circle with another touch-down, and a Whole ring's axis the other way round, are the same ring
	var ring2: Dictionary = {"c": base.spec.c, "t": WorldRingPick.ringPoint(WorldRingPick.ringFrom(base.spec.c, int(base.spec.cols), base.spec.t), 1.0), "cols": base.spec.cols}
	ok(WorldRingPick.usedMatch({"c": base.spec.c, "cols": base.spec.cols, "kind": "round", "place": 1}, WorldRingPick.usedList([ring2])), "the same circle with another touch-down is the same ring")
	var wr: Dictionary = WorldRingPick.pick(PP7, claims.RIVAL, "whole", 7, {"home": -1})
	var neg: Array = [-wr.spec.c[0], -wr.spec.c[1], -wr.spec.c[2]]
	var longer: Dictionary = {"c": neg, "cols": wr.spec.cols}
	ok(WorldRingPick.usedMatch({"c": wr.spec.c, "cols": wr.spec.cols, "kind": "through", "place": -1}, WorldRingPick.usedList([longer])) and not WorldRingPick.usedMatch({"c": wr.spec.c, "cols": 1200, "kind": "round", "place": -1}, WorldRingPick.usedList([longer])), "a Whole ring's axis the other way round is the same circle, and a ring of another length is not the same ring")
	# nothing else: every candidate used, the pick still returns a ring, scored down, and says it repeats
	var allc: Array = WorldRingPick.candidates(PP7, "half", WorldRingPick.beginPick(PP7, claims.CYBORG, "half", 99, {"home": -1}).cands.size() * 0 + 99, [])
	var everything: Array = []
	for cc in allc:
		everything.append({"c": cc.c, "cols": cc.cols})
	var lastu: Dictionary = WorldRingPick.pick(PP7, claims.CYBORG, "half", 99, {"home": -1, "used": everything})
	ok(lastu.spec.cols == 2400 and lastu.repeat and lastu.score <= base.score + 1e-9 + float(WorldRingPick.cfg().homeBonus), "with every candidate already fought the pick still returns a ring, flagged as a repeat, its score taken down by %.2f" % float(WorldRingPick.cfg().usedPenalty))
	# stepped is the same as all at once with used
	var jbu: WorldRingPick.PickJob = WorldRingPick.beginPick(PP7, claims.CYBORG, "half", 99, {"home": -1, "used": [base.spec]})
	while not jbu.step(2):
		pass
	ok(jbu.result.idx == skip.idx and bitsEq(jbu.result.spec.c, skip.spec.c), "a stepped pick with a used list is the one made at once")
	print("RINGPICK: %d check(s) failed" % fails)'''
s = s.replace(a, new)
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('tests added')
