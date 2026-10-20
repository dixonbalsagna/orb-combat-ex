

## A launch's flight on a curve (sim/core/flight.gd; docs/architecture/feel-core.md). Off: no flight state, and a replay
## carries no flight data. On: the curve's shape; a shallow send shows the kick's ramp (no one-tick jump), the peak, the
## glide at 0.4 and the arrival's rise, and lands where the same send lands with the curve off; a steep send lands
## where it does off (sooner or later: the curve carries him through its slow apex); the cue tells kick, glide,
## arrive and end once each; the brake takes over.
func _flight() -> String:
	if not SimFlight.errors().is_empty():
		return "the flight's data: " + "; ".join(SimFlight.errors())
	if SimReplay.dataHash({"flight": true}) == SimReplay.dataHash({"flight": false}):
		return "a replay with the curve on does not carry its data"
	var S0 := SimCore.createSim()
	SimCore.newMatch(S0, 5, {"p1": false, "p2": false})
	if S0.flightOn != SimFlight.enabled() or (not S0.flightOn and S0.fighters[1].flt != null):
		return "the switch, or flight state with it off"
	SimCore.dispose(S0)
	var c: Array = [SimFlight.curve(1), SimFlight.curve(5), SimFlight.curve(8), SimFlight.curve(19), SimFlight.curve(30), SimFlight.curve(90)]
	if c[0] != 1.0 / float(SimFlight.ramp) or c[1] != 1.0 or c[2] != 1.0 or c[3] <= SimFlight.glide or c[3] >= 1.0 or c[4] != SimFlight.glide or c[5] != SimFlight.glide:
		return "the curve's shape: %s" % str(c)
	var runs := {}
	for key in [["flat", false], ["flat", true], ["steep", false], ["steep", true], ["brake", true]]:
		var M := SimCore.createSim()
		SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"flight": key[1], "brake": key[0] == "brake"})
		var A = M.fighters[0]
		var D = M.fighters[1]
		D.y = WorldTerrain.groundY(M, D.x) + 400.0
		var dir: Dictionary = {"ux": 0.6, "uy": 0.8} if key[0] == "steep" else {"ux": 0.95, "uy": 0.3}
		DirLaunch.doLaunch(M, A, D, dir, 2400.0, false)
		var r := {"peak": SimDetMath.hypot(D.vx, D.vy), "v": [], "land": -1, "dx": 0.0, "cues": [], "jump": 0.0, "brakeAt": -1}
		var x0: float = D.x
		var px: float = D.x
		var py: float = D.y
		var last: float = 0.0
		var held := SimIntent.new()
		held.stanceMask = SimBrake.BIT
		for t in range(1, 900):
			SimCore.step(M, [null, held if key[0] == "brake" else null])
			for e in M.out.fx:
				if e.type == "flight":
					r.cues.append([t, e.text, e.kind])
				elif e.type == "air_brake" and e.text == "start":
					r.brakeAt = t
			M.out.fx.clear()
			M.out.feed.clear()
			if r.land >= 0:
				if t >= r.land + 2:   # the flight's end is told on the tick after the contact
					break
				continue
			if D.state != "launched" or D.jContacts > 0 or D.slide > 0.0 or D.flightHits > 0 or D.wet:
				r.land = t
				r.dx = SimWrap.sdx(x0, D.x)
				continue
			var v: float = SimDetMath.hypot(SimWrap.sdx(px, D.x), D.y - py) / SimConst.DT
			r.v.append(v)
			r.jump = maxf(r.jump, absf(v - last))
			last = v
			px = D.x
			py = D.y
			if key[0] == "brake" and r.brakeAt >= 0 and t > r.brakeAt + 2:
				break
		runs[key[0] + ("_on" if key[1] else "_off")] = r
		SimCore.dispose(M)
	var off: Dictionary = runs.flat_off
	var on: Dictionary = runs.flat_on
	var P: float = on.peak
	if off.land < 0 or on.land < 0:
		return "a flat send did not come down (off %d, on %d)" % [off.land, on.land]
	var tol: float = 0.07
	var pts: Array = [[1, 1.0 / float(SimFlight.ramp)], [SimFlight.ramp, 1.0], [SimFlight.ramp + SimFlight.hold, 1.0], [SimFlight.easeTo + 1, SimFlight.glide]]
	for pt in pts:
		var got: float = on.v[pt[0] - 1] / P
		if absf(got - pt[1]) > tol:
			return "the flat send's speed at tick %d: %.3f of the peak (want %.3f); speeds %s" % [pt[0], got, pt[1], str(on.v.slice(0, 12))]
	var arr: int = -1
	for cue in on.cues:
		if cue[1] == "arrive":
			arr = cue[0]
	if arr < 0 or on.land - arr > SimFlight.arriveTicks + 3 or on.land - arr < SimFlight.arriveTicks - 4:
		return "the arrival was told at tick %d, the contact at %d (want about %d before)" % [arr, on.land, SimFlight.arriveTicks]
	var lastV: float = on.v[on.v.size() - 1] / P
	if lastV < SimFlight.arrive - tol - 0.05:
		return "the arrival's speed: %.3f of the peak (want about %.2f)" % [lastV, SimFlight.arrive]
	if on.jump > P * (1.0 / float(SimFlight.ramp) + tol) or off.jump < 0.9 * off.peak:
		return "the largest change in a tick: %.0f with the curve (want at most a ramp's step of %.0f), %.0f without it" % [on.jump, P / float(SimFlight.ramp), off.jump]
	if on.land <= off.land or absf(on.dx - off.dx) > 0.05 * absf(off.dx) + 20.0:
		return "the flat send: it lands at %.0f in %d ticks with the curve, at %.0f in %d without (want the same place, later)" % [on.dx, on.land, off.dx, off.land]
	var texts: Array = []
	for cue in on.cues:
		texts.append(cue[1])
	if texts.count("kick") != 1 or texts.count("arrive") != 1 or texts.count("end") != 1 or texts[0] != "kick" or texts[texts.size() - 1] != "end" or on.cues[0][0] != 1:
		return "the flight's cues: %s" % str(on.cues)
	var so: Dictionary = runs.steep_off
	var sn: Dictionary = runs.steep_on
	if so.land < 0 or sn.land < 0 or absf(sn.dx - so.dx) > 0.05 * absf(so.dx) + 20.0:
		return "the steep send: it lands at %.0f in %d ticks with the curve, at %.0f in %d without" % [sn.dx, sn.land, so.dx, so.land]
	var br: Dictionary = runs.brake_on
	var be: Array = []
	for cue in br.cues:
		if cue[1] == "end":
			be = cue
	if br.brakeAt < 0 or be.is_empty() or be[0] != br.brakeAt or be[2] != "brake":
		return "the brake: it started at tick %d; the flight's end %s" % [br.brakeAt, str(be)]
	# a match with the curve and hit-stop by weight on replays
	var R := SimCore.createSim()
	var rec := SimReplay.recorder(R, 11, {}, {"flight": true, "hitstop": true})
	var kicks: int = 0
	for t in range(3600):
		rec.step([null, null])
		for e in R.out.fx:
			if e.type == "flight" and e.text == "kick":
				kicks += 1
		R.out.fx.clear()
		R.out.feed.clear()
	var rp: Dictionary = rec.finish()
	SimCore.dispose(R)
	if kicks == 0 or rp.data != SimReplay.dataHash({"flight": true, "hitstop": true}) or not SimReplay.play(JSON.parse_string(JSON.stringify(rp))).ok:
		return "a match with both on (%d launches paced) does not carry their data, or does not play back" % kicks
	return ""


## Hit-stop by weight (sim/core/hitstop.gd). Off: a hit's stop is the one passed. On: each weight's ticks; a hit that
## names none keeps the one passed; stops merge; over the budget a mashed light holds the floor, and a minute of fight
## later the budget is back; the step counts the frozen ticks; a broken region's decisive and the KO's cap (in ko).
func _hitstop() -> String:
	if not SimHitstop.errors().is_empty():
		return "the hit-stop's data: " + "; ".join(SimHitstop.errors())
	if SimReplay.dataHash({"hitstop": true}) == SimReplay.dataHash({"hitstop": false}):
		return "a replay with hit-stop by weight on does not carry its data"
	var O := SimCore.createSim()
	SimCore.newMatch(O, 5, {"p1": false, "p2": false}, {"hitstop": false})
	O.dirS.stop = 0.0
	SimDamage.hit(O, null, O.fighters[0], O.fighters[1], 1.0, {"weight": "heavy", "stop": 0.2})
	if O.hs != null or O.dirS.stop != 0.2:
		return "off: a hit naming a weight held %s (want the 0.2 it passed)" % str(O.dirS.stop)
	SimCore.dispose(O)
	var S := SimCore.createSim()
	SimCore.newMatch(S, 5, {"p1": false, "p2": false}, {"hitstop": true})
	var A = S.fighters[0]
	var D = S.fighters[1]
	var want: Dictionary = {"light_mash": 3, "light": 4, "medium": 7, "heavy": 10, "launch": 14, "launch_full": 16, "decisive": 24, "ko": 30}
	for w in want:
		S.dirS.stop = 0.0
		SimDamage.hit(S, null, A, D, 1.0, {"weight": w, "stop": 0.5})
		if S.dirS.stop != float(want[w]) * SimConst.DT or SimHitstop.ticks(S, w) != want[w]:
			return "%s held %s (want %d ticks)" % [w, str(S.dirS.stop / SimConst.DT), want[w]]
	S.dirS.stop = 0.0
	SimDamage.hit(S, null, A, D, 1.0, {"stop": 0.2})
	if S.dirS.stop != 0.2:
		return "a hit naming no weight held %s (want the 0.2 it passed)" % str(S.dirS.stop)
	S.dirS.stop = 0.0
	SimDamage.hit(S, null, A, D, 1.0, {"weight": "heavy"})
	SimDamage.hit(S, null, A, D, 1.0, {"weight": "light"})
	if S.dirS.stop != 10.0 * SimConst.DT:
		return "a heavy and a light in one tick held %s ticks (want the heavy's 10: they merge)" % str(S.dirS.stop / SimConst.DT)
	if SimHitstop.budgetTicks != 432:
		return "the budget is %d ticks (want 12%% of a minute, 432)" % SimHitstop.budgetTicks
	for i in range(SimHitstop.budgetTicks):
		SimHitstop.frozen(S)
	if SimHitstop.ticks(S, "light_mash") != SimHitstop.mashFloor or SimHitstop.ticks(S, "light") != 4:
		return "over the budget: a mashed light %d (want %d), a tapped one %d (want 4)" % [SimHitstop.ticks(S, "light_mash"), SimHitstop.mashFloor, SimHitstop.ticks(S, "light")]
	var h0: String = SimHash.stateHash(S).gameplay
	for i in range(SimHitstop.windowS * 60 - 1):
		SimHitstop.live(S)
	if SimHitstop.ticks(S, "light_mash") != SimHitstop.mashFloor:
		return "the budget came back before a minute of fight"
	SimHitstop.live(S)
	if SimHitstop.ticks(S, "light_mash") != 3 or S.hs.sum != 0 or SimHash.stateHash(S).gameplay == h0:
		return "a minute of fight later: a mashed light %d (want 3), %d frozen ticks counted; the budget's state not hashed" % [SimHitstop.ticks(S, "light_mash"), S.hs.sum]
	S.dirS.stop = 10.0 * SimConst.DT
	var n0: int = S.hs.n
	for t in range(15):
		SimCore.step(S, [null, null])
	if S.hs.sum < 10 or S.hs.sum > 11 or S.hs.n == n0:
		return "the step counted %d frozen ticks of a 10-tick stop (live %d)" % [S.hs.sum, S.hs.n - n0]
	S.dirS.stop = 0.0
	SimHitstop.afterHit(S, D, [0, 2, 0, 0])
	if S.dirS.stop != 0.0:
		return "no region broke, yet a stop was held"
	var st: Array = D.stage.duplicate()
	D.stage[1] = 3
	SimHitstop.afterHit(S, D, st)
	if S.dirS.stop != 24.0 * SimConst.DT:
		return "a broken region held %s ticks (want decisive's 24)" % str(S.dirS.stop / SimConst.DT)
	D.stage = st
	S.dirS.stop = 4.0 * SimConst.DT   # the finisher's last blow, then the KO in the same tick
	SimDamage.ko(S, D, A)
	if S.game.ko != D or S.dirS.stop != 30.0 * SimConst.DT:
		return "the KO held %s ticks (want the cap's 30), KO %s" % [str(S.dirS.stop / SimConst.DT), str(S.game.ko == D)]
	SimCore.dispose(S)
	return ""
