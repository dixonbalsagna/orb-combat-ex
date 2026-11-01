extends SceneTree
## The curve against Game Design's tests (docs/design/rule-of-cool-map.md section 2), on a field world: it keeps its sideways speed,
## never doubles back, lands where it said, speed never jumps, a hit-stop doesn't advance it, two runs give one hash, off does nothing;
## and what earns it.
##   godot --headless --path . --script res://sim/director/tools/arc_check.gd
## Ends on the verdict line.

var failed: int = 0


func _init() -> void:
	DirArc.setForce(0)
	_off()
	DirArc.setForce(1)
	for row in [0, 1]:
		_flight(row, 1.0)
	_flight(0, -1.0)
	_earned()
	_twice()
	_played()
	_meteorPlayed()
	_ignition()
	_meteorBowl()
	_sides()
	_crater()
	_brake()
	DirArc.setForce(-1)
	print("ARC: %d check(s) failed" % failed)
	quit(1 if failed > 0 else 0)


func _expect(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failed += 1


func _fresh(seed: int = 11) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false})
	for f in S.fighters:
		f.ai = null
		f.hp = 100000.0
		f.tier = 4.0
	S.out.fx.clear()
	return S


func _off() -> void:
	var S := _fresh()
	var n: int = S.fighters[1].act.dirI.size()
	S.fighters[1].state = "launched"
	_expect(not DirArc.step(S, S.fighters[1], SimConst.DT), "off: step does nothing")
	_expect(S.fighters[1].act.dirI.size() == n, "off: no slot")
	_expect(not DirArc.heavyFull(S, null, S.fighters[0], S.fighters[1], {"charge": 1.0}), "off: a full charge isn't earned")
	_expect(not DirArc.flying(S), "off: nobody's flying")
	SimCore.dispose(S)


func _flight(row: int, side: float) -> void:
	var S := _fresh()
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.y = WorldTerrain.groundY(S, D.x) + 10.0
	var x0: float = D.x
	DirArc.send(S, A, D, row, side)
	var land: float = -1.0
	var ends: int = 0
	for e in S.out.fx:
		if e.type == "cue" and e.kind == "arc_send":
			land = float(e.x)
			ends = int(e.n)
	_expect(land >= 0.0 and ends > S.tick, "row %d: the send tells the view where he lands" % row)
	var minVx: float = 1.0e18
	var sumVx: float = 0.0
	var n: int = 0
	var back: int = 0
	var jump: float = 0.0
	var apex: float = -1.0e18
	var lastVx: float = 0.0
	var lastVy: float = 0.0
	var sum: float = 0.0
	var offCurve: bool = false
	var total: int = DirArc._ticks(DirArc._row(row))
	var guard: int = 0
	while DirArc._g(D, DirArc.A_ROW) != 0 and guard < total + 5:
		var ox: float = D.x
		DirArc.step(S, D, SimConst.DT)
		S.out.fx.clear()
		guard += 1
		if DirArc._g(D, DirArc.A_ROW) == 0:
			break
		var dx: float = SimWrap.sdx(ox, D.x) * side
		if dx <= 0.0:
			back += 1
		var vx: float = absf(D.vx)
		minVx = minf(minVx, vx)
		sumVx += vx
		n += 1
		sum += dx
		apex = maxf(apex, D.y)
		if n > 1:
			jump = maxf(jump, SimDetMath.hypot(D.vx - lastVx, D.vy - lastVy) / maxf(1.0, SimDetMath.hypot(lastVx, lastVy)))
		lastVx = D.vx
		lastVy = D.vy
	var mean: float = sumVx / maxf(1.0, float(n))
	print("      row %d side %d: %d ticks, apex %.0f, carried %.0f, sideways %.0f to mean %.0f, largest step %.1f%%" % [row, int(side), n, apex, sum, minVx, mean, jump * 100.0])
	_expect(minVx >= 0.5 * mean, "row %d: sideways speed never under half its mean (%.2f)" % [row, minVx / maxf(1.0, mean)])
	_expect(back == 0, "row %d: never doubles back (%d)" % [row, back])
	_expect(jump < 0.2, "row %d: speed never jumps (%.1f%% a tick)" % [row, jump * 100.0])
	_expect(absf(SimWrap.sdx(D.x, land)) < float(DirArc._row(row).d) * 0.2, "row %d: lands near what it said (%.0f off)" % [row, absf(SimWrap.sdx(D.x, land))])
	_expect(D.vy < 0.0 and absf(D.vy) == float(DirArc.cfg().landSpeed), "row %d: the ground sees the data's speed" % row)
	SimCore.dispose(S)


func _earned() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	var D = S.fighters[1]
	var cfg: Dictionary = DirArc.cfg()
	var saved: int = int(cfg.minForms)
	cfg["minForms"] = 0
	D.stunTicks = 0
	_expect(DirArc.earned(S, A, D, {"charge": 0.9}) == -1, "short of full: not earned")
	_expect(DirArc.earned(S, A, D, {"charge": 1.0}) == 1, "full, foe not weak: the high row")
	D.stunTicks = 20
	_expect(DirArc.earned(S, A, D, {"charge": 1.0}) == 0, "full, foe stunned: the meteor")
	A.tier = 3.0
	_expect(DirArc.earned(S, A, D, {"charge": 1.0}) == -1, "under tier 4: not earned")
	A.tier = 4.0
	if A.fd != null:
		cfg["minForms"] = 9
		_expect(DirArc.earned(S, A, D, {"charge": 1.0}) == -1, "too few forms: not earned")
	cfg["minForms"] = 0
	DirArc.send(S, A, D, 0, 1.0)
	S.out.fx.clear()
	_expect(DirArc.earned(S, A, D, {"charge": 1.0}) == -1, "inside the gap between set pieces: not earned")
	cfg["minForms"] = saved
	var ch: Dictionary = DirBrawl.cfg().heavy.charge
	_expect(DirArc.fullTicks(S, A, ch) == int(ch.fullTicks), "no stun banked: the flash is the data's (%d)" % int(ch.fullTicks))
	DirArc.bank(S, A, D, 40)
	_expect(DirArc.fullTicks(S, A, ch) == int(cfg.bankFull), "a banked stun: the flash comes at %d" % int(cfg.bankFull))
	for _k in range(45):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
	S.out.fx.clear()
	S.out.feed.clear()
	_expect(DirArc.fullTicks(S, A, ch) == int(ch.fullTicks), "the stun over: back to the data's")
	A.tier = 3.0
	DirArc.bank(S, A, D, 40)
	_expect(DirArc.fullTicks(S, A, ch) == int(ch.fullTicks), "under tier 4: nothing's banked")
	SimCore.dispose(S)


func _run(seed: int):
	var S := _fresh(seed)
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.y = WorldTerrain.groundY(S, D.x) + 10.0
	DirArc.send(S, A, D, 0, 1.0)
	for _k in range(500):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
		S.out.fx.clear()
		S.out.feed.clear()
	var h = SimHash.stateHash(S)
	var flew: bool = DirArc._g(D, DirArc.A_ROW) == 0
	var st: String = String(D.state)
	SimCore.dispose(S)
	return [h, flew, st]


func _twice() -> void:
	var a = _run(21)
	var b = _run(21)
	_expect(a[0] == b[0], "two runs, one hash")
	_expect(bool(a[1]), "through the sim's own step, he comes off the curve (%s)" % str(a[2]))


## Played: both at tier 4, in a brawl, B held to the flash and let go. Then he lands, and the ground takes him.
func _played() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.x = SimWrap.wrap(A.x + 58.0)
	D.y = A.y
	D.stunTicks = 0
	var names: Array = []
	var cues: int = 0
	var script: Array = []
	for _k in range(5):
		script.append(SimIntent.new())
	var l := SimIntent.new()
	l.light = true
	script.append(l)
	for _k in range(24):
		script.append(SimIntent.new())
	var y := SimIntent.new()
	y.sig = true
	y.sigHeld = true
	script.append(y)
	for _k in range(46):
		var h := SimIntent.new()
		h.sigHeld = true
		script.append(h)
	for _k in range(600):
		script.append(SimIntent.new())
	var hit: bool = false
	var flewTicks: int = 0
	var after: String = ""
	for w in script:
		SimCore.step(S, [w, SimIntent.new()])
		for e in S.out.fx:
			if e.type == "launch_plan":
				names.append(String(e.chosen))
			elif e.type == "cue" and e.kind == "arc_send":
				cues += 1
		S.out.fx.clear()
		S.out.feed.clear()
		if DirArc._g(D, DirArc.A_ROW) != 0:
			flewTicks += 1
			hit = true
		elif hit and after == "":
			after = String(D.state)
	print("      played: %s, on the curve %d ticks, then %s, swing rule %s" % [str(names), flewTicks, after, DirSwing.restRule(S)])
	_expect(names.has("HIGH ARC") or names.has("METEOR"), "B held to the flash at tier 4 goes up the curve")
	_expect(cues == 1, "one send (%d)" % cues)
	_expect(flewTicks > 200, "and flies it (%d)" % flewTicks)
	SimCore.dispose(S)


## A training start at tier 4, in a brawl.
func _trained(seed: int = 11, extra: Dictionary = {}) -> SimState:
	var setup := {"planet": 7, "touch": 2, "planetGen": 3, "intro": false, "startTier": 4}
	setup.merge(extra, true)
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": false, "p2": false}, setup)
	for f in S.fighters:
		f.ai = null
		f.hp = 100000.0
		f.ki = 100.0
	S.fighters[1].x = SimWrap.wrap(S.fighters[0].x + 58.0)
	S.fighters[1].y = S.fighters[0].y
	S.out.fx.clear()
	return S


func _step(S: SimState, a: SimIntent = null) -> Array:
	SimCore.step(S, [a if a != null else SimIntent.new(), SimIntent.new()])
	var names: Array = []
	for e in S.out.fx:
		if e.type == "launch_plan":
			names.append(String(e.chosen))
	S.out.fx.clear()
	S.out.feed.clear()
	return names


func _holdB(S: SimState, ticks: int) -> Array:
	var got: Array = []
	var y := SimIntent.new()
	y.sig = true
	y.sigHeld = true
	got += _step(S, y)
	for _k in range(ticks):
		var h := SimIntent.new()
		h.sigHeld = true
		got += _step(S, h)
	for _k in range(30):
		got += _step(S)
	return got


## The whole route from a training start: a light to open the brawl, the foe stunned, B to the flash: the meteor.
func _meteorPlayed() -> void:
	var S := _trained()
	_expect(S.fighters[0].tier == 4.0 and S.fighters[1].tier == 4.0, "startTier: both at tier 4 (%.0f, %.0f)" % [S.fighters[0].tier, S.fighters[1].tier])
	for _k in range(5):
		_step(S)
	var l := SimIntent.new()
	l.light = true
	_step(S, l)
	for _k in range(24):
		_step(S)
	S.fighters[1].stunTicks = 120
	var got: Array = _holdB(S, 46)
	_expect(got.has("METEOR"), "from a training start, on a stunned foe: the meteor (%s)" % str(got))
	_expect(DirArc.flying(S), "and he's flying")
	_expect(DirSwing.restRule(S) == "meteor", "no swing during the shot")
	SimCore.dispose(S)


## Ignition, played: a level 3 upward stick stun, then B: the flash at 24, so it fits inside the stun.
func _ignition() -> void:
	var S := _trained()
	DirStick.setForce(1)
	for _k in range(5):
		_step(S)
	var l := SimIntent.new()
	l.light = true
	_step(S, l)
	for _k in range(24):
		_step(S)
	var w := SimIntent.new()
	w.rsStart = true
	w.rsHeld = true
	w.rsDir = SimStrikeRead.UP
	_step(S, w)
	for k in range(54):
		var h := SimIntent.new()
		h.rsHeld = true
		h.rsDir = SimStrikeRead.UP
		h.rsLevel = 0 if k < 10 else (1 if k < 28 else 2)
		_step(S, h)
	var r := SimIntent.new()
	r.rsRelease = true
	r.rsDir = SimStrikeRead.UP
	r.rsLevel = 3
	_step(S, r)
	for _k in range(17):
		_step(S)
	var banked: bool = DirArc._g(S.fighters[0], DirArc.A_BANK) > DirBrawl._now(S)
	_expect(banked, "a level 3 upward stick strike banks the charge")
	var stun: int = S.fighters[1].stunTicks
	var got: Array = _holdB(S, 8)   # the hold counts from the strike: the flash comes 7 or so ticks after a press this late
	print("      ignition: stun left at B %d; %s" % [stun, str(got)])
	_expect(got.has("METEOR"), "and B, inside the stun, is the meteor (%s)" % str(got))
	DirStick.setForce(-1)
	SimCore.dispose(S)


## No side from the stick, it takes the better arrival; water scores under ground; only buildings and terrain are read.
func _sides() -> void:
	var S := _trained()
	var D = S.fighters[1]
	var a: float = DirArc.landingScore(S, D, 0, 1.0)
	var b: float = DirArc.landingScore(S, D, 0, -1.0)
	print("      the meteor's landings from the start: this way %.1f, that way %.1f" % [a, b])
	var src: String = FileAccess.get_file_as_string("res://sim/director/arc.gd")
	var body: String = src.substr(src.find("static func landingScore"))
	body = body.substr(0, body.find("## Puts him on the curve"))
	for w in ["popAlive", "popNear", "casualt", "crowd", "menace", "anguish"]:
		_expect(not body.contains(w), "a landing's score doesn't read " + w)
	SimCore.dispose(S)


## The crater: the landing's energy is at most tier 4's hardest send's times 1.5, and it digs.
func _crater() -> void:
	var c: Dictionary = DirArc.cfg()
	var e: float = WorldCrater.impactEnergy(float(c.landSpeed), 4.0)
	var cap: float = WorldCrater.impactEnergy(7000.0, 4.0) * 1.5
	_expect(e <= cap * 1.001, "the landing's energy is at the cap (%.1f of %.1f)" % [e, cap])
	var S := _fresh()
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.y = WorldTerrain.groundY(S, D.x) + 10.0
	D.hp = 1.0
	DirArc.send(S, A, D, 0, 1.0)
	var craters: int = 0
	var was: int = 0
	var guard: int = 0
	while guard < 900:
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
		for e2 in S.out.fx:
			if e2.type == "crater":
				craters += 1
		S.out.fx.clear()
		S.out.feed.clear()
		guard += 1
		if DirArc._g(D, DirArc.A_ROW) == 0 and D.state != "launched":
			break
	print("      after the landing: %s, hp %.0f, %d crater events, %d ticks" % [D.state, D.hp, craters, guard])
	_expect(S.game.ko == null, "a landing doesn't end the match")
	SimCore.dispose(S)


## The brake: nothing before the end of the hang; from there it leaves the curve on its heading.
func _brake() -> void:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 11, {"p1": false, "p2": false}, {"planet": 7, "touch": 2, "planetGen": 3, "intro": false, "brake": true})
	for f in S.fighters:
		f.ai = null
		f.hp = 100000.0
	var A = S.fighters[0]
	var D = S.fighters[1]
	D.y = WorldTerrain.groundY(S, D.x) + 10.0
	DirArc.send(S, A, D, 0, 1.0)
	var total: int = DirArc._ticks(DirArc._row(0))
	var early: bool = false
	var left: int = -1
	var vAt: float = 0.0
	for k in range(total):
		var h := SimIntent.new()
		h.stanceMask = 8
		SimCore.step(S, [SimIntent.new(), h])
		S.out.fx.clear()
		S.out.feed.clear()
		if DirArc._g(D, DirArc.A_ROW) == 0:
			left = k
			vAt = D.vx
			break
	var share: float = float(left) / float(total)
	print("      the brake left the curve at tick %d of %d (%.2f), sideways %.0f" % [left, total, share, vAt])
	_expect(left >= 0 and share >= float(DirArc.cfg().brakeFrom) - 0.02, "a held brake leaves the curve only from the end of the hang (%.2f)" % share)
	_expect(absf(vAt) > 0.0, "on its heading")
	SimCore.dispose(S)


## The meteor's landing: World's bowl, a blast over it, and one a match.
func _meteorBowl() -> void:
	var S := _fresh()
	var A = S.fighters[0]
	var D = S.fighters[1]
	var cfg: Dictionary = DirArc.cfg()
	var saved: int = int(cfg.minForms)
	cfg["minForms"] = 0
	D.stunTicks = 20
	_expect(DirArc.earned(S, A, D, {"charge": 1.0}) == 0, "stunned: the meteor")
	DirArc.send(S, A, D, 0, -1.0)   # this way it lands on land
	S.out.fx.clear()
	_s0(S)
	cfg["minForms"] = saved
	SimCore.dispose(S)


func _s0(S: SimState) -> void:
	var A = S.fighters[0]
	var D = S.fighters[1]
	var n0: int = S.craters.size()
	var alive0: Array = []
	for t in range(600):
		SimCore.step(S, [SimIntent.new(), SimIntent.new()])
		S.out.fx.clear()
		S.out.feed.clear()
		if S.craters.size() > n0:
			break
	_expect(S.craters.size() == n0 + 1, "one crater, on land (%d)" % (S.craters.size() - n0))
	if S.craters.size() <= n0:
		return
	var c = S.craters[S.craters.size() - 1]
	print("      the bowl: radius %.0f, depth %.0f" % [float(c.r), float(c.depth)])
	_expect(float(c.r) > 5000.0, "the meteor's own bowl (%.0f)" % float(c.r))
	var standing: int = 0
	var fell: int = 0
	for b in S.buildings:
		if absf(SimWrap.sdx(c.x, b.x)) < float(c.r) * 0.6:
			if b.alive:
				standing += 1
			else:
				fell += 1
	print("      in the bowl's middle: %d down, %d standing" % [fell, standing])
	_expect(standing == 0 or fell > 0, "the blast takes what's in it")
	D.stunTicks = 20
	var first = S.fighters[0]
	DirArc._s(first, DirArc.A_LAST, 0)
	DirArc._s(first, DirArc.A_USED, 0)
	var cfg: Dictionary = DirArc.cfg()
	cfg["minForms"] = 0
	_expect(DirArc.earned(S, A, D, {"charge": 1.0}) == 1, "the second, on the first value: the high arc")

