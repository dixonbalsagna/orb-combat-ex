extends SceneTree
## Scratch bench (Performance, 2026-10-31), on the re-cut field-frame (S.bList): the swing tick in whole AI matches, and the same forced asks as swing_bench.gd.
##   godot --headless --path . --script res://sim/core/tools/swing_bench2.gd -- --mode=natural --planet=7 --ticks=3600 --reps=3
##   godot --headless --path . --script res://sim/core/tools/swing_bench2.gd -- --mode=forced --planet=7 --reps=3     (a tree with data/director/swing.json "enabled": false, so only the asks swing)
## Needs hook-7-recut.mjs on the tree (SimSwing.tus, tlist, nlay, ...). The match is the same every rep, so load only adds time: the per-tick minimum over reps is the cost.

var mode: String = "natural"
var planet: int = 7
var reps: int = 3
var ticks: int = 3600
var T0: int = 300
const EDGES := [1000.0, 2000.0, 4000.0, 8000.0, 16000.0, 29000.0, 1e9]


func setup3(seed: int) -> Dictionary:
	return {"planet": seed, "touch": 1, "planetGen": 3, "intro": false}


## One run of n ticks from a new match; ask: null (natural, or no swing) or a dict asked at T0. Returns per-tick arrays and the match facts.
var rep0: bool = true


func run(n: int, ask, air: bool) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": true, "p2": true}, setup3(planet))
	if SimField._F != null:
		WorldField.bakeStep(SimField._F, 1 << 40)   # the host's load bakes the ring (planet_load.gd); a bare newMatch does not, and the first reads would build the bake on the spot
	var r := {"step": [], "own": [], "active": [], "shots": [], "sent": [], "list": [], "lay": [], "tlist": [], "tpose": [], "trb": [], "nrb": [], "nb": S.bX.size(), "stale": [], "inlist_near": 0.0}
	var bandMax := []
	for i in range(EDGES.size()):
		bandMax.append(0.0)
	var nearBad: float = 0.0
	if mode == "forced":
		for t in range(T0):
			SimCore.step(S)
			S.out.fx.clear(); S.out.feed.clear()
		if air:
			for f in S.fighters:
				f.y = 3000.0
		if ask != null:
			SimSwing.ask(S, ask)
		n = 110
	SimSwing.tus = 0; SimSwing.tlist = 0; SimSwing.nlay = 0; SimSwing.tpose = 0; SimSwing.nposes = 0; SimSwing.trb = 0; SimSwing.nrb = 0
	for t in range(n):
		SimSwing.tus = 0
		var l0: int = SimSwing.nlay
		var lt0: int = SimSwing.tlist
		var tp0: int = SimSwing.tpose
		var tr0: int = SimSwing.trb
		var nr0: int = SimSwing.nrb
		DirSwing.pm.clear()
		var rd0: int = SimField._F.reads if SimField._F != null else 0
		var a: int = Time.get_ticks_usec()
		SimCore.step(S)
		var b: int = Time.get_ticks_usec()
		var act: bool = S.swing != null and S.swing.active
		r.step.append(b - a)
		if rep0 and DirSwing.pm.has("m_choose"):
			print("LAUNCH tick %d step %d, new lattice nodes %d, choose %d biome %d brunt %d predict %d swing %s" % [t, b - a, (SimField._F.reads if SimField._F != null else 0) - rd0, DirSwing.pm.get("m_choose", 0), DirSwing.pm.get("L4_biome", 0), DirSwing.pm.get("L2_brunt", 0), DirSwing.pm.get("predict", 0), str(act)])
		if b - a > 20000 and rep0:
			var fl: Array = []
			for e in S.out.feed:
				fl.append(String(e.tag) + " " + String(e.sub).substr(0, 70))
			print("HITCH tick %d %d us, new lattice nodes %d, swing %s marks %s: %s" % [t, b - a, (SimField._F.reads if SimField._F != null else 0) - rd0, str(act), str(DirSwing.pm), " | ".join(fl.slice(0, 3))])
		r.own.append(SimSwing.tus)
		r.active.append(1 if act else 0)
		r.shots.append(S.shots.size())
		r.sent.append(1 if (S.fighters[0].aimB >= 0 or S.fighters[1].aimB >= 0) else 0)
		r.list.append(S.bList.size())
		r.lay.append(SimSwing.nlay - l0)
		r.tlist.append(SimSwing.tlist - lt0)
		r.tpose.append(SimSwing.tpose - tp0)
		r.trb.append(SimSwing.trb - tr0)
		r.nrb.append(SimSwing.nrb - nr0)
		if act and t % 6 == 0 and S.frame != null:
			var inl := {}
			for i in S.bList:
				inl[i] = true
			var mid: float = SimWrap.wrap(S.fighters[0].x + SimWrap.sdx(S.fighters[0].x, S.fighters[1].x) * 0.5)
			for i in range(S.bX.size()):
				if inl.has(i):
					continue
				SimField.strip(S, S.bDir[i * 3], S.bDir[i * 3 + 1], S.bDir[i * 3 + 2])
				var e: float = absf(SimWrap.sdx(SimField.sx, S.bX[i])) + absf(SimField.sz - S.bZ[i])
				var d: float = sqrt(pow(SimWrap.sdx(mid, SimField.sx), 2.0) + SimField.sz * SimField.sz)
				for q in range(EDGES.size()):
					if d < EDGES[q]:
						bandMax[q] = maxf(bandMax[q], e)
						break
		S.out.fx.clear(); S.out.feed.clear()
	r["band"] = bandMax
	r["end"] = "tick %d, x %.3f / %.3f, hp %.3f / %.3f, swing n %d" % [S.tick, S.fighters[0].x, S.fighters[1].x, S.fighters[0].hp, S.fighters[1].hp, S.swing.n if S.swing != null else -1]
	r["nlay"] = SimSwing.nlay
	SimCore.dispose(S)
	return r


func pct(a: Array, p: float) -> float:
	if a.is_empty():
		return 0.0
	var s: Array = a.duplicate()
	s.sort()
	return float(s[mini(s.size() - 1, int(ceil(p * s.size())) - 1)])


func mean(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var t: float = 0.0
	for v in a:
		t += v
	return t / a.size()


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.substr(7)
		elif a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--reps="):
			reps = int(a.substr(7))
		elif a.begins_with("--ticks="):
			ticks = int(a.substr(8))
	var cases: Array = [["natural", null, false]]
	if mode == "forced":
		cases = [["stand/none", null, false], ["stand/launch30", {"deg": 30.0, "cause": "launch"}, false], ["stand/brawl10", {"deg": 10.0, "cause": "brawl"}, false], ["stand/small8blow", {"deg": 8.0, "cause": "small", "blow": true}, false], ["air/none", null, true], ["air/launch60", {"deg": 60.0, "cause": "launch"}, true], ["air/chase30", {"deg": 30.0, "cause": "chase"}, true]]
	var res := {}
	for rep in range(reps):
		rep0 = rep == 0
		for c in cases:
			var r: Dictionary = run(ticks, c[1], c[2])
			if not res.has(c[0]):
				res[c[0]] = r
			else:
				var m: Dictionary = res[c[0]]
				for k in ["step", "own", "tlist", "tpose", "trb"]:
					for i in range(m[k].size()):
						m[k][i] = mini(m[k][i], r[k][i])
	print("end state of rep 1 (identical every run if the match is deterministic): " + str(res[cases[0][0]].end))
	print("planet %d, mode %s, %d reps. Microseconds; per-tick minimum over reps." % [planet, mode, reps])
	for c in cases:
		var m: Dictionary = res[c[0]]
		var own: Array = []
		var stp_a: Array = []
		var stp_i: Array = []
		var lays: Array = []
		var withshots: int = 0
		var withsent: int = 0
		var lt: Array = []
		var rbt: int = 0
		var n: int = 0
		for i in range(m.step.size()):
			if m.active[i] == 1:
				n += 1
				own.append(m.own[i])
				stp_a.append(m.step[i])
				if m.shots[i] > 0:
					withshots += 1
				if m.sent[i] == 1:
					withsent += 1
				if m.lay[i] > 0:
					lays.append(m.tlist[i])
				rbt += m.trb[i]
			else:
				stp_i.append(m.step[i])
		if n == 0:
			print("%-16s no swing ticks (match of %d ticks, %d buildings)" % [c[0], m.step.size(), m.nb])
			print("                 step mean %.0f us, p95 %.0f" % [mean(m.step), pct(m.step, 0.95)])
			continue
		print("%-16s swing ticks %5d of %d | own mean %6.0f p95 %6.0f max %6.0f | step in swing mean %6.0f p50 %6.0f p95 %6.0f, outside mean %6.0f p50 %6.0f p95 %6.0f | list laid %d times, %.0f us each (max %.0f) | rebucket %d us in all | ticks with a shot %d, with a sent body %d | list size mean %.0f of %d" % [c[0], n, m.step.size(), mean(own), pct(own, 0.95), pct(own, 1.0), mean(stp_a), pct(stp_a, 0.5), pct(stp_a, 0.95), mean(stp_i), pct(stp_i, 0.5), pct(stp_i, 0.95), lays.size(), mean(lays), pct(lays, 1.0), rbt, withshots, withsent, mean(m.list), m.nb])
		var order: Array = range(m.step.size())
		order.sort_custom(func(x, y): return m.step[x] > m.step[y])
		var top: String = ""
		for q in range(6):
			var i: int = order[q]
			top += " [tick %d: %d us, swing %d, own %d]" % [i, m.step[i], m.active[i], m.own[i]]
		print("                 slowest ticks:" + top)
		print("                 worst stale pose of a building NOT in the list, by distance from the fighters' midpoint (units): <1000 %.1f, <2000 %.1f, <4000 %.1f, <8000 %.1f, <16000 %.1f, <29000 %.1f, beyond %.1f" % m.band)
	quit(0)
