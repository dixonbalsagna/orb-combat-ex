extends SceneTree
## Scratch bench (Performance, 2026-10-31): the cost of a swing tick on the arena stack, paired against the same tick with no swing.
##   godot --headless --path . --script res://sim/core/tools/swing_bench.gd -- --planet=7 --reps=4
## Same seed and same ticks every run, so the work is identical and load only adds time: the per-tick minimum over reps is the cost. Rep 1 is also kept (cold nodes).

const T0: int = 300   # ticks of match before the swing is asked

var planet: int = 7
var reps: int = 4
var W: int = 110


func setup3(seed: int) -> Dictionary:
	return {"planet": seed, "touch": 1, "planetGen": 3, "intro": false}


## One run: a match to T0, then W ticks timed; returns {step: [us], own: [us], reads: [n], active: [0/1]}
func run(ask, air: bool) -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 77, {"p1": true, "p2": true}, setup3(planet))
	for t in range(T0):
		SimCore.step(S)
		S.out.fx.clear()
		S.out.feed.clear()
	if air:
		for f in S.fighters:
			f.y = 3000.0
	if ask != null:
		SimSwing.ask(S, ask)
	SimSwing.rlKey = -1
	var r := {"step": [], "own": [], "reads": [], "active": []}
	SimSwing.tpo = 0; SimSwing.npo = 0; SimSwing.nidx = 0; SimSwing.tidx = 0; SimSwing.tlim = 0; SimSwing.trise = 0
	for t in range(W):
		SimSwing.tus = 0
		SimField.reads = 0
		var a: int = Time.get_ticks_usec()
		SimCore.step(S)
		var b: int = Time.get_ticks_usec()
		r.step.append(b - a)
		r.own.append(SimSwing.tus)
		r.reads.append(SimField.reads)
		r.active.append(1 if S.swing != null and S.swing.active else 0)
		if SimSwing.incr:
			checkIdx(S)
			if S.swing != null and S.swing.active:
				stale(S)
		S.out.fx.clear()
		S.out.feed.clear()
	r["parts"] = [SimSwing.tpo, SimSwing.npo, SimSwing.nidx, SimSwing.tidx, SimSwing.tlim, SimSwing.trise]
	SimCore.dispose(S)
	return r


var idxBad: int = 0
var bandMax := [0.0, 0.0, 0.0, 0.0, 0.0]   # the worst stale pose (units, x and z) of a building within 1000, 2000, 4000, 8000, beyond 8000 of the fighters' midpoint
var bandEdge := [1000.0, 2000.0, 4000.0, 8000.0, 1e9]


func stale(S: SimState) -> void:
	var mid: float = SimWrap.wrap(S.fighters[0].x + SimWrap.sdx(S.fighters[0].x, S.fighters[1].x) * 0.5)
	for i in range(S.bX.size()):
		SimField.strip(S, S.bQ[i * 3], S.bQ[i * 3 + 1], S.bQ[i * 3 + 2])
		var e: float = absf(SimWrap.sdx(SimField.sx, S.bX[i])) + absf(SimField.sz - S.bZ[i])
		var d: float = sqrt(pow(SimWrap.sdx(mid, SimField.sx), 2.0) + SimField.sz * SimField.sz)   # on the fight plane, z is about 0: the ground's distance counts depth
		for q in range(5):
			if d < bandEdge[q]:
				bandMax[q] = maxf(bandMax[q], e)
				break
var idxChecked: int = 0


func checkIdx(S: SimState) -> void:
	var want: Array = []
	for k in range(WorldStructures.BUCKETS):
		want.append(PackedInt32Array())
	for i in range(S.buildings.size()):
		var k: int = mini(int(SimWrap.wrap(S.buildings[i].x) / (SimConst.W / 128.0)), WorldStructures.BUCKETS - 1)
		want[k].append(i)
	idxChecked += 1
	for k in range(WorldStructures.BUCKETS):
		if S.bIdx[k] != want[k]:
			idxBad += 1
			return


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--planet="):
			planet = int(a.substr(9))
		elif a.begins_with("--reach="):
			SimSwing.POSE_REACH = float(a.substr(8))
		elif a == "--planet-reach":
			SimSwing.planetMode = true
		elif a == "--incr":
			SimSwing.incr = true
		elif a.begins_with("--reps="):
			reps = int(a.substr(7))
	var cases := [
		["stand/none", null, false],
		["stand/launch30", {"deg": 30.0, "cause": "launch"}, false],
		["stand/brawl10", {"deg": 10.0, "cause": "brawl"}, false],
		["stand/small8blow", {"deg": 8.0, "cause": "small", "blow": true}, false],
		["air/none", null, true],
		["air/launch60", {"deg": 60.0, "cause": "launch"}, true],
		["air/chase30", {"deg": 30.0, "cause": "chase"}, true],
	]
	var res := {}   # name -> {min step[], min own[], reads[], active[], first step[], first own[]}
	for rep in range(reps):
		for c in cases:
			var r: Dictionary = run(c[1], c[2])
			if not res.has(c[0]):
				res[c[0]] = {"parts": r.parts.duplicate(), "step": r.step.duplicate(), "own": r.own.duplicate(), "reads": r.reads, "active": r.active, "fstep": r.step.duplicate(), "fown": r.own.duplicate()}
			else:
				var m: Dictionary = res[c[0]]
				for q in [0, 3, 4, 5]:
					m.parts[q] = mini(m.parts[q], r.parts[q])
				for i in range(W):
					m.step[i] = mini(m.step[i], r.step[i])
					m.own[i] = mini(m.own[i], r.own[i])
	print("planet %d, %d reps, swing asked at tick %d, window %d ticks. Times in microseconds; min over reps per tick (cold = rep 1)." % [planet, reps, T0, W])
	print("%-18s %6s %9s %9s %9s %9s %9s %9s %9s" % ["case", "ticks", "own mean", "own p95", "own max", "d-step", "d p95", "d max", "reads/t"])
	for c in cases:
		if c[1] == null:
			continue
		var base: Dictionary = res["air/none" if c[2] else "stand/none"]
		var m: Dictionary = res[c[0]]
		var n: int = 0
		var own: Array = []
		var d: Array = []
		var rd: int = 0
		var rb: int = 0
		for i in range(W):
			if m.active[i] == 1:
				n += 1
				own.append(m.own[i])
				d.append(m.step[i] - base.step[i])
				rd += m.reads[i]
				rb += base.reads[i]
		if n == 0:
			print("%-18s no active ticks" % c[0])
			continue
		own.sort()
		var ds: Array = d.duplicate()
		ds.sort()
		var so: float = 0.0
		for v in own:
			so += v
		var sd: float = 0.0
		for v in d:
			sd += v
		var p95i: int = mini(n - 1, int(ceil(0.95 * n)) - 1)
		print("%-18s %6d %9.0f %9d %9d %9.0f %9d %9d %9.2f" % [c[0], n, so / n, own[p95i], own[n - 1], sd / n, ds[p95i], ds[n - 1], float(rd - rb) / n])
	print("parts over the whole window, min over reps: poses us | poses done | index rebuilds | rebuild us | _limit us | rise backstop us")
	for c in cases:
		if c[1] != null:
			print("%-18s %s" % [c[0], str(res[c[0]].parts)])
	for k in ["stand/none", "air/none"]:
		var b: Dictionary = res[k]
		var s: float = 0.0
		for v in b.step:
			s += v
		print("baseline %-12s step mean %.0f us, reads/tick %.2f" % [k, s / W, float(b.reads.reduce(func(a, x): return a + x, 0)) / W])
	print("reach %.0f: worst stale pose (units) by distance of the building from the fighters: <1000 %.1f, <2000 %.1f, <4000 %.1f, <8000 %.1f, beyond %.1f" % [SimSwing.POSE_REACH, bandMax[0], bandMax[1], bandMax[2], bandMax[3], bandMax[4]])
	print("index equals a full rebuild: %d of %d ticks differ" % [idxBad, idxChecked] if SimSwing.incr else "(incremental off)")
	quit(0)
