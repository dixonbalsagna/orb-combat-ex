

## The curve's shared functions (sim/core/flight.gd; docs/architecture/feel-core.md section 6), the brake's public control
## back, and the camera feed outside the light digest. share and kOf by their rule; a predictor's track steps as the live
## flight does, to the bit, for a shallow and a steep send, and predict() names the flight's touchdown tick;
## SimBrake.controlBack ends a flight; a cam_intent cue leaves hashFx as it was, and any other cue moves it; out of the
## digest, one AI match twice with the feed on gives the same cues.
func _shared() -> String:
	if SimFlight.share(5, -1, 0.0) != SimFlight.curve(5) or SimFlight.share(40, 30, 0.4) != 0.4 + (SimFlight.arrive - 0.4) * minf(1.0, 10.0 / float(SimFlight.arriveTicks)):
		return "share: the curve before the arrival, its ramp after"
	if SimFlight.kOf(0.4, 1000.0, 300.0, 400.0) != 0.8 or SimFlight.kOf(1.0, 1000.0, 0.0, 0.0) != SimFlight.kMax or SimFlight.kOf(0.1, 1000.0, 3000.0, 4000.0) != SimFlight.kMin:
		return "kOf: the pace and its two clamps"
	for dir in [{"ux": 0.95, "uy": 0.3}, {"ux": 0.6, "uy": 0.8}]:
		var M := SimCore.createSim()
		SimCore.newMatch(M, 5, {"p1": false, "p2": false}, {"flight": true})
		var A = M.fighters[0]
		var D = M.fighters[1]
		D.y = WorldTerrain.groundY(M, D.x) + 400.0
		DirLaunch.doLaunch(M, A, D, dir, 2400.0, false)
		var tr = SimFlight.track(D.x, D.y, D.vx, D.vy, D.aimB)
		var pr: PackedFloat64Array = SimFlight.predict(M, D.x, D.y, D.vx, D.vy, D.aimB)
		var land: int = -1
		var arrived: bool = false
		for t in range(1, 900):
			SimCore.step(M, [null, null])
			M.out.fx.clear()
			M.out.feed.clear()
			if D.state != "launched" or D.jContacts > 0 or D.slide > 0.0 or D.wet or D.flightHits > 0:
				land = t
				break
			SimFlight.tick(M, tr)
			if tr.x != D.x or tr.y != D.y or tr.vx != D.vx or tr.vy != D.vy or tr.t != D.flt.t or tr.arr != D.flt.arr or tr.k != D.flt.k:
				return "tick %d of the send %s: the track (%.3f, %.3f, k %.4f, arr %d) and the flight (%.3f, %.3f, k %.4f, arr %d) part" % [t, str(dir), tr.x, tr.y, tr.k, tr.arr, D.x, D.y, D.flt.k, D.flt.arr]
			arrived = arrived or tr.arr >= 0
		SimCore.dispose(M)
		if land < 0 or not arrived or int(pr[0]) != land:
			return "the send %s: predict() touches down on tick %d, the flight on %d (arrival told: %s)" % [str(dir), int(pr[0]), land, str(arrived)]
	var B := SimCore.createSim()
	SimCore.newMatch(B, 5, {"p1": false, "p2": false})
	var BD = B.fighters[1]
	BD.y = WorldTerrain.groundY(B, BD.x) + 400.0
	DirLaunch.doLaunch(B, B.fighters[0], BD, {"ux": 0.6, "uy": 0.8}, 2400.0, false)
	for t in range(3):
		SimCore.step(B, [null, null])
	SimBrake.controlBack(B, BD)
	if BD.state == "launched" or BD.launchT != 1.0:
		return "SimBrake.controlBack: he is still %s (traversal %s)" % [BD.state, str(BD.launchT)]
	SimCore.dispose(B)
	var C := SimCore.createSim()
	SimCore.newMatch(C, 5, {"p1": false, "p2": false})
	var h0 := SimHash.Hasher.new()
	SimHash.hashFx(h0, [])
	C.out.fx.clear()
	SimFx.cue(C, C.fighters[0], "cam_intent", "plan", "launch")
	var h1 := SimHash.Hasher.new()
	SimHash.hashFx(h1, C.out.fx)
	C.out.fx.clear()
	SimFx.cue(C, C.fighters[0], "slide_brace", "", "")
	var h2 := SimHash.Hasher.new()
	SimHash.hashFx(h2, C.out.fx)
	SimCore.dispose(C)
	if h1.hex() != h0.hex() or h2.hex() == h0.hex():
		return "the light digest: a cam_intent cue %s it, another cue %s it (want: leaves it, moves it)" % ["moves" if h1.hex() != h0.hex() else "leaves", "moves" if h2.hex() != h0.hex() else "leaves"]
	# out of the digest, the feed's own determinism is held here: one AI match twice with the feed on, the same cues
	var ci = DirInterrupt.data().get("cameraIntent", null)
	if not (ci is Dictionary):
		return "the camera feed's data block is missing"
	var was = ci.get("enabled", false)
	ci["enabled"] = true
	var runs: Array = []
	for run in range(2):
		var R := SimCore.createSim()
		SimCore.newMatch(R, 13, {})
		var hc := SimHash.Hasher.new()
		var n: int = 0
		for t in range(2400):
			SimCore.step(R, null)
			for e in R.out.fx:
				if e.type == "cue" and e.kind == "cam_intent":
					hc.num(float(R.tick))
					hc.num(e.actor)
					hc.text(String(e.text))
					hc.text(String(e.source))
					n += 1
			R.out.fx.clear()
			R.out.feed.clear()
		runs.append([n, hc.hex(), SimHash.stateHash(R).gameplay])
		SimCore.dispose(R)
	ci["enabled"] = was
	if int(runs[0][0]) == 0 or runs[0] != runs[1]:
		return "the camera feed on: %d and %d cues, the same stream %s, the same play %s" % [int(runs[0][0]), int(runs[1][0]), str(runs[0][1] == runs[1][1]), str(runs[0][2] == runs[1][2])]
	return ""
