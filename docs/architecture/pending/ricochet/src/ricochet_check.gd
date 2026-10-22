

## The ricochet's glance (sim/core/ricochet.gd; docs/architecture/ricochet-core.md). Off: a replay carries no ricochet
## data, and a contact is World's as before. The rule by its cases (the line on his whole speed), the slope's scope and
## predict() in any frame. On, on the test world's steep uphill (49 degrees): a fast send 20 degrees into the slope
## glances (keep of the speed, mirrored, flying on, told once; World's bounce event with its keep); a full row, a slow
## send and one 60 degrees into the slope do not; on level ground the same fast shallow send skids (Orb's skid stands); a
## building's face glances a steep send and not a level one; with the curve on the glance ends its paced leg; a
## ricochet match replays.
func _ricochet() -> String:
	if not SimRicochet.errors().is_empty():
		return "the ricochet's data: " + "; ".join(SimRicochet.errors())
	if SimReplay.dataHash({"ricochet": true}) == SimReplay.dataHash({"ricochet": false}):
		return "a replay with ricochets on does not carry their data"
	var K: float = SimRicochet.keep
	var r: PackedFloat64Array = SimRicochet.rule(-1600.0, 3000.0, 0)
	if r[0] != 1.0 or r[1] != K * 1600.0 or r[2] != K * 3000.0:
		return "rule: a shallow contact at 3,400 glances (got %s)" % str(r)
	if SimRicochet.rule(-1000.0, 3000.0, 0)[0] != 1.0:
		return "rule: the line is on the whole speed (3,162, only 1,000 into the surface: a glance)"
	if SimRicochet.rule(-400.0, 1000.0, 0)[0] != 2.0 or SimRicochet.rule(-3000.0, 1000.0, 0)[0] != 0.0 or SimRicochet.rule(-1600.0, 3000.0, SimRicochet.maxInRow)[0] != 0.0 or SimRicochet.rule(500.0, 3000.0, 0)[0] != 0.0:
		return "rule: under the line, steeper, a full row, moving away"
	if SimRicochet.steepGround(0.0) or SimRicochet.steepGround(0.5) or not SimRicochet.steepGround(0.6) or not SimRicochet.steepGround(-0.7):
		return "the slope's scope: ground of slope 0 and 0.5 (27 degrees) is not a ricochet's, 0.6 and -0.7 are"
	var pv: PackedFloat64Array = SimRicochet.predict(3000.0, -1600.0, 0.0, 1.0, 0)
	if pv[0] != 1.0 or absf(pv[1] - K * 3000.0) > 1e-9 or absf(pv[2] - K * 1600.0) > 1e-9:
		return "predict on a level surface: %s" % str(pv)
	var pw: PackedFloat64Array = SimRicochet.predict(1600.0, 3000.0, -1.0, 0.0, 0)
	if pw[0] != 1.0 or absf(pw[1] + K * 1600.0) > 1e-9 or absf(pw[2] - K * 3000.0) > 1e-9:
		return "predict on a face toward -x: %s" % str(pw)
	# steep ground: sends at the test world's 49-degree uphill, a given angle into the slope; and the same fast shallow
	# send on level ground. [name, degrees into the slope (or -1: level ground, 30 down), force, on, full row, curve]
	var cases: Array = [["glance", 20.0, 3000.0, true, false, false],
		["off", 20.0, 3000.0, false, false, false],
		["full row", 20.0, 3000.0, true, true, false],
		["slow", 20.0, 1200.0, true, false, false],
		["steep", 60.0, 3000.0, true, false, false],
		["curve", 20.0, 3000.0, true, false, true],
		["level", -1.0, 5000.0, true, false, false]]
	var got: Dictionary = {}
	var rad: float = SimMathx.f64("400921fb54442d18") / 180.0
	for c in cases:
		var M := SimCore.createSim()
		SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"ricochet": c[3], "flight": c[5]})
		var A = M.fighters[0]
		var D = M.fighters[1]
		var dir: Dictionary = {"ux": 0.866, "uy": -0.5}
		if c[1] >= 0.0:
			D.x = _steepX(M)
			if D.x < 0.0:
				return "the test world has no steep uphill of 480 units"
			var s: float = (WorldTerrain.groundY(M, SimWrap.wrap(D.x + 8.0)) - WorldTerrain.groundY(M, D.x)) / 8.0
			var q: float = sqrt(1.0 + s * s)
			var ca: float = SimDetMath.cos(float(c[1]) * rad)
			var sa: float = SimDetMath.sin(float(c[1]) * rad)
			dir = {"ux": (ca + sa * s) / q, "uy": (ca * s - sa) / q}   # the slope's tangent turned c[1] degrees into it
			D.y = WorldTerrain.groundY(M, D.x) + 25.0
		else:
			D.x = _flatX(M, D.x)
			D.y = WorldTerrain.groundY(M, D.x) + 40.0
		DirLaunch.doLaunch(M, A, D, dir, c[2], false)
		if c[4]:
			D.ricN = D.launchN
			D.rics = SimRicochet.maxInRow
		var res := {"ric": [], "bounce": [], "land": "", "contact": false, "before": 0.0, "state": "", "vy": 0.0, "end": ""}
		var prev: float = 0.0
		for t in range(1, 60):
			prev = SimDetMath.hypot(D.vx / D.launchT, D.vy)
			SimCore.step(M, [null, null])
			for e in M.out.fx:
				if e.type == "ricochet":
					res.ric.append(e)
					res.before = prev
					res.state = D.state
					res.vy = D.vy
				elif e.type == "bounce":
					res.contact = true
					if res.bounce.is_empty():
						res.bounce.append(e.keep)
				elif e.type == "land":
					res.contact = true
					if res.land == "":
						res.land = String(e.kind)
				elif e.type == "flight" and e.text == "end":
					res.end = String(e.kind)
			M.out.fx.clear()
			M.out.feed.clear()
			if not res.ric.is_empty() or res.contact:
				break
		got[c[0]] = res
		SimCore.dispose(M)
	var g: Dictionary = got["glance"]
	if g.ric.size() != 1 or String(g.ric[0].kind) != "glance" or g.state != "launched" or g.vy <= 0.0 or int(g.ric[0].n) != 1:
		return "a fast send 20 degrees into a steep slope: %d glances told, he is %s going %s" % [g.ric.size(), g.state, "up" if g.vy > 0.0 else "down"]
	if absf(g.ric[0].amount - K * g.before) > 0.04 * g.before or g.bounce.is_empty() or g.bounce[0] != K:
		return "the glance kept %.0f of %.0f (want about %.0f), World's bounce keep %s" % [g.ric[0].amount, g.before, K * g.before, str(g.bounce)]
	for k in ["off", "full row", "slow", "steep", "level"]:
		if not got[k].ric.is_empty() or not got[k].contact:
			return "%s: %d glances, a contact %s (want none, and World's contact)" % [k, got[k].ric.size(), str(got[k].contact)]
	if got["level"].land != "skid":
		return "a fast shallow send on level ground landed '%s' (want Orb's skid)" % got["level"].land
	var cv: Dictionary = got["curve"]
	if cv.ric.size() != 1 or cv.end != "glance":
		return "with the curve on: %d glances, its paced leg ended '%s' (want glance)" % [cv.ric.size(), cv.end]
	# a building's face: a steep send glances, a level one does not
	var B := SimCore.createSim()
	SimCore.newMatch(B, 5, {"p1": false, "p2": false}, {"ricochet": true})
	var BD = B.fighters[1]
	var bb = B.buildings[0]
	BD.state = "launched"
	BD.launchT = 1.0
	BD.vx = 400.0
	BD.vy = 1000.0
	BD.aimB = bb.idx
	B.out.fx.clear()
	if SimRicochet.offFace(B, BD, bb, BD.y, bb.x - bb.w * 0.5, 1.0) or BD.aimB != bb.idx:
		return "a face met at a whole 1,077 glanced (under the line)"
	BD.vx = 2000.0
	BD.vy = 3000.0
	if not SimRicochet.offFace(B, BD, bb, BD.y + 10.0, bb.x - bb.w * 0.5, 1.0):
		return "a steep send at 2,000 into a face did not glance"
	if BD.vx != -K * 2000.0 or BD.vy != K * 3000.0 or BD.aimB != -1 or B.out.fx.is_empty() or B.out.fx[B.out.fx.size() - 1].type != "ricochet" or BD.rics != 1:
		return "the face's glance: velocity (%s, %s), aim %d, rics %d" % [str(BD.vx), str(BD.vy), BD.aimB, BD.rics]
	BD.vx = 5000.0
	BD.vy = 500.0
	BD.aimB = bb.idx
	if SimRicochet.offFace(B, BD, bb, BD.y, bb.x - bb.w * 0.5, 1.0):
		return "a level send into a face glanced (it is the wall slam's)"
	SimCore.dispose(B)
	# a ricochet match replays
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 11, {}, {"ricochet": true})
	for t in range(3600):
		rec.step([null, null])
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if rp.data != SimReplay.dataHash({"ricochet": true}) or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a ricochet match does not carry its data, or does not play back"
	return ""


## The first x from `from` (in steps of 160) with 640 units of dry ground ahead within 3 units of level.
func _flatX(S: SimState, from: float) -> float:
	var x: float = from
	for i in range(600):
		var lo: float = 1.0e9
		var hi: float = -1.0e9
		var wet: bool = false
		for k in range(21):
			var xk: float = SimWrap.wrap(x + 32.0 * float(k))
			var g: float = WorldTerrain.groundY(S, xk)
			lo = minf(lo, g)
			hi = maxf(hi, g)
			wet = wet or WorldTerrain.seaAt(S, xk)
		if hi - lo < 3.0 and not wet:
			return x
		x = SimWrap.wrap(x + 160.0)
	return from


## The first x (in steps of 16 from the world's start) with 480 units of dry ground ahead rising at a slope of 0.75 to 2.5
## (37 to 68 degrees) the whole way, and 120 units into it; -1 when the world has none.
func _steepX(S: SimState) -> float:
	var x: float = 0.0
	var run: float = 0.0
	while x < SimConst.W:
		var s: float = (WorldTerrain.groundY(S, SimWrap.wrap(x + 8.0)) - WorldTerrain.groundY(S, x)) / 8.0
		if s >= 0.75 and s <= 2.5 and not WorldTerrain.seaAt(S, x):
			run += 8.0
			if run >= 480.0:
				return SimWrap.wrap(x - 480.0 + 120.0)
		else:
			run = 0.0
		x += 8.0
	return -1.0
