extends SceneTree
## The launch tick's memos (Performance's second round, docs/perf/impact-stutter.md; docs/director/launch-cost.md):
##   godot --headless --path . --script res://sim/director/tools/launch_cost_check.gd [-- --negative-control]
## - computer fighters on two planets with the biome candidates and the swing on, two copies in step with the memos on and off
##   (DirLaunch.memoOff, DirSwing.memoOff): the same hash on every tick, and every 45 ticks a launch planned each way round at three
##   forces (the swing's launch pick, the jolt's lean, chooseLaunch) with the same candidates, scores, landings and travel
## - the prop memo against WorldGround.matchProps, prop for prop: spans of every size, across the seam, the whole ring and more,
##   a span given backwards, after a prop breaks, after the trees change (a new list and the same list shortened), with World's
##   lone trees laid (the memo stands aside), after the ground under the strip changes
## - the ground memo against WorldTerrain.groundY in a far read, across the seam, before and after a crater and a dent, and groundY itself
##   outside chooseLaunch
## - _standing's memo against a whole read: from a frame it holds, from a new frame, after a building falls
## --negative-control adds 25 units (a third of a body height) to every kept height: the plans or the hashes must part.
## Ends on the verdict line.

const WORLDS: Array = [{"intro": false, "planet": 7, "touch": 1, "planetGen": 3}, {"intro": false, "planet": 12, "touch": 1, "planetGen": 3}]
const TICKS: int = 3600

var failed: int = 0
var negative: bool = false


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	DirLaunch.forceBiome = 1
	DirSwing.setForce(1)
	if negative:
		var parted: int = 0
		for w in WORLDS:
			parted += 1 if _sameHashes(w, 25.0) > 0 else 0
		_expect(parted == WORLDS.size(), "negative control: a kept height off by 25 units is seen (plans or hashes part) on %d of %d worlds" % [parted, WORLDS.size()])
	else:
		for w in WORLDS:
			_expect(_sameHashes(w, 0.0) == 0, "planet %d: memos on and off, the same hash on every tick" % int(w.planet))
			_props(w)
			_ground(w)
			_standing(w)
	DirLaunch.forceBiome = -1
	DirSwing.setForce(-1)
	DirLaunch.memoOff = false
	DirSwing.memoOff = false
	DirLaunch.memoTaint = 0.0
	print("LAUNCH COST: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _new(w: Dictionary) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 4242, {"p1": true, "p2": true}, w)
	return S


## Two copies of one match in step, the memos on (each kept height off by taint) in one and off in the other. Every PROBE ticks
## both also plan a launch each way round (the swing's launch pick, the jolt's lean and chooseLaunch at three forces) and compare
## every candidate the planner scored; every tick both compare the hash. Returns the ticks and plans that differ.
const PROBE: int = 45


func _sameHashes(w: Dictionary, taint: float) -> int:
	var S1 := _new(w)
	var S2 := _new(w)
	var n0: int = DirLaunch.chooseN
	var bad: int = 0
	var badPlans: int = 0
	var plans: int = 0
	var first: int = -1
	for t in range(TICKS):
		_mode(false, taint)
		SimCore.step(S1, [null, null])
		_mode(true, 0.0)
		SimCore.step(S2, [null, null])
		if t % PROBE == PROBE - 1:
			for k in range(2):
				var force: float = [1600.0, 2400.0, 3200.0][(t / PROBE + k) % 3]
				_mode(false, taint)
				var a: Array = _plan(S1, k, force)
				_mode(true, 0.0)
				var b: Array = _plan(S2, k, force)
				plans += 1
				if a != b:
					badPlans += 1
		for S in [S1, S2]:
			S.out.fx.clear()
			S.out.feed.clear()
		if String(SimHash.stateHash(S1).gameplay) != String(SimHash.stateHash(S2).gameplay):
			bad += 1
			if first < 0:
				first = t
	_mode(false, 0.0)
	var cands: int = _seenCands
	_seenCands = 0
	SimCore.dispose(S1)
	SimCore.dispose(S2)
	var launches: int = (DirLaunch.chooseN - n0) / 2
	print("      planet %d: %d launches in the match and %d planned (%d candidates scored, %d of them the biome's); %d of %d plans and %d of %d ticks differ%s" % [int(w.planet), launches - plans, plans, cands, _seenBio, badPlans, plans, bad, TICKS, (", the first tick at %d" % first) if first >= 0 else ""])
	if not negative:
		_expect(plans >= 100 and _seenBio > 0, "planet %d: launches planned (%d), the biome's candidates among them (%d)" % [int(w.planet), plans, _seenBio])
	_seenBio = 0
	return bad + badPlans


var _seenCands: int = 0
var _seenBio: int = 0


func _mode(off: bool, taint: float) -> void:
	DirLaunch.memoOff = off
	DirSwing.memoOff = off
	DirLaunch.memoTaint = taint


## A launch planned by fighter k at the other, as the launch beat plans one: the swing's pick (DirSwing._launchPick, which reads
## the standing buildings and may score the candidates), the jolt's lean, then chooseLaunch. [the pick's turn, the lean, every
## candidate's name, score, landing and travel]
func _plan(S: SimState, k: int, force: float) -> Array:
	var A = S.fighters[k]
	var D = S.fighters[1 - k]
	var pick = DirSwing._launchPick(S, A, D, force)
	var lean: float = DirSwing._joltSign(S, A, D, float(A.x))
	var r: Dictionary = DirLaunch.chooseLaunch(S, A, D, force)
	var out: Array = [float(pick.top.turn) if pick != null else 0.0, lean]
	for c in r.all:
		out.append([String(c.name), float(c.s), float(c.get("land", -1.0)), float(c.get("travel", -1.0)), str(c.get("p", {}))])
		_seenCands += 1
		if bool(c.get("bio", false)):
			_seenBio += 1
	return out


func _props(w: Dictionary) -> void:
	var S := _new(w)
	for t in range(600):
		SimCore.step(S, [null, null])
		S.out.fx.clear()
		S.out.feed.clear()
	var W: float = float(SimConst.NC) * SimConst.COL
	var x: float = float(S.fighters[1].x)
	var spans: Array = [[x - 10.0, x + 10.0], [x - 800.0, x + 800.0], [x - 1500.0, x + 6000.0], [x - 30000.0, x + 30000.0],
		[W - 500.0, W + 500.0], [-700.0, 300.0], [W - 3000.0, W - 10.0], [0.0, W], [-W, 2.0 * W], [x + 5000.0, x - 5000.0], [x, x]]
	for k in range(12):
		spans.append([float(k) * 12345.6 - 4000.0, float(k) * 12345.6 + 900.0 * float(k + 1)])
	var r: Array = _spansSame(S, spans)
	_expect(r[0] == spans.size() and r[1] > 0, "planet %d: the prop memo is matchProps on %d of %d spans (%d props in all)" % [int(w.planet), r[0], spans.size(), r[1]])
	# a prop breaks: the director's ring of broken columns (brokenProps) takes a column that has a smashable prop
	var all: Array = WorldGround.matchProps(S, 0.0, W)
	var col: int = -1
	for p in all:
		if WorldGround.smashIn([p]) >= 0:
			col = int(p.col)
			break
	if col >= 0:
		var f = S.fighters[0]
		DirLaunch._hkSize(f)
		f.act.dirI[DirLaunch._hkBase() + DirLaunch.HK_BRK] = col + 1
		var cx: float = (float(col) + 0.5) * SimConst.COL
		var before: int = WorldGround.matchProps(S, cx - 100.0, cx + 100.0).size()
		var after: Array = DirLaunch._propsNear(S, cx - 100.0, cx + 100.0)
		r = _spansSame(S, spans + [[cx - 100.0, cx + 100.0]])
		_expect(r[0] == spans.size() + 1 and after.size() == before - 1, "planet %d: a broken prop's column loses it, the same as matchProps (%d props there, %d after)" % [int(w.planet), before, after.size()])
		f.act.dirI[DirLaunch._hkBase() + DirLaunch.HK_BRK] = 0
	else:
		_expect(false, "planet %d: a smashable prop somewhere on the ring" % int(w.planet))
	# the trees: a new list, then the same list shortened in place
	var trees: Array = S.trees
	S.trees = trees.slice(0, trees.size() / 2)
	r = _spansSame(S, spans)
	var ok1: bool = r[0] == spans.size()
	S.trees.resize(S.trees.size() / 2)
	r = _spansSame(S, spans)
	_expect(ok1 and r[0] == spans.size(), "planet %d: after the trees change (a new list, and it shortened) the memo is matchProps again" % int(w.planet))
	S.trees = trees
	# World's provisional rows on (the lone trees, laid by the ring's trees): the memo stands aside, and the trees count
	var prov: bool = WorldGround.K_PROVISIONAL
	WorldGround.K_PROVISIONAL = true
	var off: bool = DirLaunch._treesMatter()
	var r3: Array = _spansSame(S, spans)
	S.trees = trees.slice(0, trees.size() / 3)
	var r4: Array = _spansSame(S, spans)
	S.trees = trees
	WorldGround.K_PROVISIONAL = prov
	_expect(off and not DirLaunch._treesMatter() and r3[0] == spans.size() and r4[0] == spans.size(), "planet %d: with the lone trees laid the memo is off and matchProps is read, before and after the trees change; off again it's back" % int(w.planet))
	# the ground under the strip: a column raised in place
	var base0: float = S.base[col if col >= 0 else 100]
	S.base[col if col >= 0 else 100] = base0 + 400.0
	r = _spansSame(S, spans)
	S.base[col if col >= 0 else 100] = base0
	var r2: Array = _spansSame(S, spans)
	_expect(r[0] == spans.size() and r2[0] == spans.size(), "planet %d: after the strip's ground changes, and back, the memo is matchProps" % int(w.planet))
	SimCore.dispose(S)


## [spans where DirLaunch._propsNear is matchProps prop for prop, props compared]
func _spansSame(S: SimState, spans: Array) -> Array:
	var same: int = 0
	var n: int = 0
	for sp in spans:
		var a: Array = DirLaunch._propsNear(S, float(sp[0]), float(sp[1]))
		var b: Array = WorldGround.matchProps(S, float(sp[0]), float(sp[1]), DirLaunch.brokenProps(S))
		n += b.size()
		if a == b:
			same += 1
		else:
			print("      differ: span %s, %d props against %d" % [str(sp), a.size(), b.size()])
	return [same, n]


func _ground(w: Dictionary) -> void:
	var S := _new(w)
	for t in range(300):
		SimCore.step(S, [null, null])
		S.out.fx.clear()
		S.out.feed.clear()
	var W: float = float(SimConst.NC) * SimConst.COL
	var x: float = float(S.fighters[1].x)
	var xs: Array = []
	for k in range(400):
		xs.append(x - 4000.0 + float(k) * 21.7)
	for k in range(40):
		xs.append(W - 200.0 + float(k) * 9.9)
		xs.append(-float(k) * 13.1)
	var r1: Array = _groundSame(S, xs)
	SimField.pointAt(S, x)
	WorldStore.add(S, SimField.ox, SimField.oy, SimField.oz, 260.0, 90.0, 20.0, 1.0, 0, 0, S.T, 0)   # a crater in the field's store
	var c0: int = int(floor(SimWrap.wrap(x + 300.0) / SimConst.COL))
	for k in range(-6, 7):
		S.deform[posmod(c0 + k, SimConst.NC)] -= 40.0 - 6.0 * absf(float(k))   # and a dent in the strip's marks
	var r2: Array = _groundSame(S, xs)
	var outside: bool = DirLaunch._gy(S, x) == WorldTerrain.groundY(S, x)
	_expect(r1[0] == xs.size() and r2[0] == xs.size() and r2[1] > 0 and outside, "planet %d: the ground memo is groundY in a far read on %d and %d of %d reads (%d moved by the crater); groundY outside chooseLaunch" % [int(w.planet), r1[0], r2[0], xs.size(), r2[1]])
	SimCore.dispose(S)


## [reads the memo gives as groundY does in a far read, reads that differ from the last call's] (the last call's kept in _last)
var _last: Array = []


func _groundSame(S: SimState, xs: Array) -> Array:
	DirLaunch._gBegin()
	SimField.far()
	var same: int = 0
	var moved: int = 0
	var now: Array = []
	for k in range(xs.size()):
		var a: float = DirLaunch._gy(S, float(xs[k]))
		var a2: float = DirLaunch._gy(S, float(xs[k]))   # the second read is the kept one
		var b: float = WorldTerrain.groundY(S, float(xs[k]))
		if a == b and a2 == b:
			same += 1
		now.append(b)
		if _last.size() == xs.size() and _last[k] != b:
			moved += 1
	SimField.near()
	DirLaunch._gEnd()
	_last = now
	return [same, moved]


func _standing(w: Dictionary) -> void:
	var S := _new(w)
	for t in range(600):
		SimCore.step(S, [null, null])
		S.out.fx.clear()
		S.out.feed.clear()
	var ok: bool = true
	var n: int = 0
	for k in range(6):
		var fr: Dictionary = DirSwing._frame(S, float(S.fighters[0].x) + float(k) * 3100.0)
		for maxD in [6000.0, 11250.0, 16875.0, 9000.0]:
			var a: Array = DirSwing._standing(S, fr, maxD)   # a new frame, or a nearer reach of one it holds
			var b: Array = DirSwing._standing(S, fr, maxD)   # from the memo
			DirSwing.memoOff = true
			var c: Array = DirSwing._standing(S, fr, maxD)   # whole
			DirSwing.memoOff = false
			ok = ok and a == c and b == c
			n += c.size()
	var fr0: Dictionary = DirSwing._frame(S, float(S.fighters[0].x))
	var l0: Array = DirSwing._standing(S, fr0, 16875.0)
	var fell: bool = false
	if not l0.is_empty():
		var bi: int = int(l0[0][2])
		S.buildings[bi].alive = false
		var a: Array = DirSwing._standing(S, fr0, 16875.0)
		DirSwing.memoOff = true
		var c: Array = DirSwing._standing(S, fr0, 16875.0)
		DirSwing.memoOff = false
		fell = a == c and a.size() == l0.size() - 1
		S.buildings[bi].alive = true
	_expect(ok and fell and n > 0, "planet %d: _standing from the memo is the whole read (%d buildings over 24 reads), and leaves out a building that fell" % [int(w.planet), n])
	SimCore.dispose(S)
