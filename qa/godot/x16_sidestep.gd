extends SceneTree
## X-16: a defender who sidesteps a beam at three ranges (sprint A1, A-COMBAT-08; expected to FAIL until the beam is rebuilt in A3, where a beam can be stepped out of). A scripted attacker on the real input hub throws a stick beam (RB and the right stick toward him, let go
## to fire); a scripted defender (raw intent on slot 1) answers it by STEPPING OUT OF ITS LINE: from the moment the beam's window opens (the cue beam_window) he moves straight up with the left stick (up to --sidestep ticks) and nothing else, no dodge tap, no guard.
## The pair starts at --ranges (default 300,2500,6000 units apart on the ground, the attacker facing him); each trial is one seeded match run to the beam's outcome or --limit ticks. Today a beam reaches its target at any distance, so a sidestep is expected to avoid nothing.
##   bash tools/godot-run.sh --path <tree copy with qa/godot/qa_planet.gd> --script res://qa/godot/x16_sidestep.gd -- <trials a range> <baseSeed> [--ranges=300,2500,6000] [--sidestep=40] [--limit=600]
## One line, X16 <json>: for each range the trials, the beams fired at him, the outcomes (HIT, DODGE, GUARD, CLASH, ESCAPE, DEFLECT, none), the stick refusals of the attacker, how far he had moved from the beam's line when it arrived (the height he had climbed), and the verdict:
## PASS if the sidestep avoided the beam (DODGE, ESCAPE or DEFLECT) in at least 80% of the beams thrown at every range, FAIL otherwise, and FAIL where no beam could be thrown (today: expected FAIL). Read-only with respect to sim/.
const QaPlanet = preload("res://qa/godot/qa_planet.gd")

var hub: SimInputHub


func _init() -> void:
	var pos: Array = []
	var ranges: Array = [300, 2500, 6000]
	var sidestep: int = 40
	var limit: int = 600
	var debug: bool = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ranges="):
			ranges = Array(a.substr(9).split(",", false)).map(func(x): return int(x))
		elif a.begins_with("--sidestep="):
			sidestep = int(a.substr(11))
		elif a.begins_with("--limit="):
			limit = int(a.substr(8))
		elif a == "--debug":
			debug = true
		else:
			pos.append(a)
	var trials: int = int(pos[0]) if pos.size() > 0 else 10
	var base: int = int(pos[1]) if pos.size() > 1 else 1
	SimInputData.load_and_apply()
	var out := {"trials": trials, "sidestep": sidestep, "ranges": {}}
	var pass_all: bool = true
	for rng_u in ranges:
		var outc := {}
		var fired: int = 0
		var climbs: Array = []
		var refs := {}
		for k in range(trials):
			var r: Dictionary = _trial(base + k, float(rng_u), sidestep, limit, debug and k == 0)
			for rk in r.refs:
				refs[rk] = int(refs.get(rk, 0)) + int(r.refs[rk])
			if r.fired:
				fired += 1
				climbs.append(r.climb)
			outc[r.out] = int(outc.get(r.out, 0)) + 1
		var avoided: int = 0
		for key in outc:
			if key in ["DODGE", "ESCAPE", "DEFLECT"]:
				avoided += int(outc[key])
		var share: float = float(avoided) / float(maxi(1, fired))   # of the beams thrown; a range where none could be thrown cannot be read and counts as a FAIL
		if fired == 0 or share < 0.8:
			pass_all = false
		climbs.sort()
		out.ranges[str(rng_u)] = {"beamsFired": fired, "outcomes": outc, "refusals": refs, "avoidedShare": snappedf(share, 0.001), "medianClimb": snappedf(float(climbs[climbs.size() / 2]) if not climbs.is_empty() else 0.0, 1.0)}
	out["verdict"] = "PASS" if pass_all else "FAIL"
	out["dataHash"] = str(SimReplay.dataHash({}))
	print("X16 " + JSON.stringify(out))
	quit()


func _trial(seed_: int, dist: float, sidestep: int, limit: int, debug: bool = false) -> Dictionary:
	hub = SimInputHub.new()
	var su: Dictionary = QaPlanet.setup(seed_, hub.setup())
	su["intro"] = false
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed_, {"p1": false, "p2": false}, su)
	hub.set_pad_has_right_stick(0, true)
	hub.pad_button(0, "lb", true)   # binds the pad to slot 0 with a guard press, not an attack: an X here started a lunge and a brawl at the short range (QA 2026-11-20), so no beam could be thrown there
	hub.pad_button(0, "lb", false)
	var A = S.fighters[0]
	var D = S.fighters[1]
	for f in S.fighters:
		f.ki = 100.0
		f.hp = 100000.0
	D.x = SimWrap.wrap(A.x + dist)
	A.face = 1.0
	D.face = -1.0
	A.y = WorldTerrain.groundY(S, A.x)
	D.y = WorldTerrain.groundY(S, D.x)
	var res := {"fired": false, "out": "none", "climb": 0.0, "refs": {}}
	var phase: int = 0
	var until: int = 30
	var win_open: int = -1
	var y0: float = D.y
	var held_rb: bool = false
	for t in range(limit):
		# the attacker: after 30 quiet ticks, RB and the stick toward him for 50 ticks, let go to fire
		hub.pad_stick(0, 0.0, 0.0)
		if phase == 0 and t >= until:
			hub.pad_button(0, "rb", true)
			held_rb = true
			phase = 1
			until = t + 6
		elif phase == 1 and t >= until:
			phase = 2
			until = t + 50
		elif phase == 2:
			hub.pad_stick_right(0, signf(SimWrap.sdx(A.x, D.x)), 0.0)
			if t >= until:
				hub.pad_stick_right(0, 0.0, 0.0)
				phase = 3
				until = t + 6
		elif phase == 3 and t >= until:
			hub.pad_button(0, "rb", false)
			held_rb = false
			phase = 4
		# the defender: a raw intent, up with the left stick from the window's opening for `sidestep` ticks
		var di := SimIntent.new()
		if win_open >= 0 and t - win_open <= sidestep:
			di.my = 1.0
		hub.set_humans(true, true)
		hub.set_struggle(0, SimDir.inStruggle(S, A))
		var its: Array = [hub.intent(0), di]
		var pausing: bool = S.pause.left > 0
		if SimCore.step(S, its):
			hub.consumed()
		elif pausing:
			if S.pause.left > 0:
				hub.drop_edges()
			else:
				hub.resume()
		var done: bool = false
		for e in S.out.fx:
			if debug and e.type == "cue" and (int(e.actor) == 0 or str(e.kind).begins_with("beam")):
				print("DBG range %.0f t=%d actor=%d %s:%s state0=%s state1=%s" % [dist, t, int(e.actor), str(e.kind), str(e.text), A.state, D.state])
			if e.type == "cue":
				var k: String = str(e.kind)
				if k == "beam_window" and str(e.text) == "start" and win_open < 0:
					win_open = t
				elif k == "beam_fire" and int(e.actor) == 0:
					res.fired = true
				elif k == "stick_refused" and int(e.actor) == 0:
					var rs: String = str(e.text) + "/" + str(e.get("source"))
					res.refs[rs] = int(res.refs.get(rs, 0)) + 1
			elif e.type == "beam_outcome" and int(e.actor) == 0:
				res.out = str(e.kind)
				res.climb = D.y - y0
				done = true
		hub.on_events(S.out.fx)
		S.out.fx.clear()
		S.out.feed.clear()
		if done:
			break
	SimCore.dispose(S)
	return res
