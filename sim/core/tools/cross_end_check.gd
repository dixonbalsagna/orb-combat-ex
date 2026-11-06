extends SceneTree
## 2v2, a finished fight (sim/core/cross.gd, SimStage.rejoin): godot --headless --path . --script res://sim/core/tools/cross_end_check.gd
## - a first KO doesn't end the match: the fallen body is out, his fight keeps stepping its winner, and the other fight runs on;
##   with the switch off, a fight's KO is the end as before
## - an out body is inert: a shot passes him and a blow for him is refused; his fight's winner is still reached from outside
## - the match ends when a team has nobody standing
## - both fights finished, one standing on each team: after the second KO's moment, the two standing are one fight's pair, its
##   KO cleared, their wear and brink as they stood, their times on the new clock; a launch in flight holds it back
## - a rollback across a rejoin; four computer fighters together, twice, one hash, and no match ended by a first KO
## --negative-control leaves the fallen body standing (not out), and the checks have to see it.

var fails: int = 0
var negative: bool = false
var notes: Array = []


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func _new(seed: int, cross: bool, ai: bool = false) -> SimState:
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": ai, "p2": ai, "p3": ai, "p4": ai}, {"intro": false, "fights": 2, "cross": cross})
	return S


func _four(S: SimState) -> Array:
	var b: Array = SimStage.bodies(S)
	var out: Array = []
	for k in ["p1", "p2", "p3", "p4"]:
		for f in b:
			if f.keys == k:
				out.append(f)
	return out


func _drain(S: SimState) -> void:
	for i in range(S.stage.fights.size()):
		var o = S.out if i == S.stage.cur else S.stage.fights[i].out
		o.fx.clear()
		o.feed.clear()


func _steps(S: SimState, n: int) -> void:
	for t in range(n):
		SimCore.step(S)
		_drain(S)


func _put(f, x: float, ref) -> void:
	f.x = SimWrap.wrap(x)
	f.y = ref.y
	f.z = ref.z
	f.vx = 0.0
	f.vy = 0.0


## D falls to A in D's fight, between ticks.
func _ko(S: SimState, D, A) -> void:
	SimStage.enter(S, SimStage.fightOf(S, D))
	SimDamage.ko(S, D, A)
	SimStage.enter(S, 0)


## The clock of the fight f is in.
func _clock(S: SimState, f) -> float:
	var i: int = SimStage.fightOf(S, f)
	return S.T if i == S.stage.cur else S.stage.fights[i].T


## The KO event in fight i's output, or null.
func _koEv(S: SimState, i: int):
	for e in (S.out if i == S.stage.cur else S.stage.fights[i].out).fx:
		if e.type == "ko":
			return e
	return null


func _game(S: SimState, i: int):
	return S.game if i == S.stage.cur else S.stage.fights[i].game


func _firstKO() -> void:
	var S := _new(51, true)
	var q: Array = _four(S)
	_ko(S, q[1], q[0])
	ok(q[1].out and S.stage.over == -1 and not SimCore.ended(S), "a first KO: he's out and the match goes on")
	var e = _koEv(S, 0)
	ok(e != null and e.over == false and e.winners.is_empty(), "... its event says the match isn't over, and names no winners")
	var t0: float = S.T
	var t1: float = S.stage.fights[1].T
	_steps(S, 300)
	ok(S.T > t0 and S.stage.fights[1].T > t1 and not SimCore.ended(S), "... his fight keeps stepping its winner, and the other fight runs on")
	ok(q[0].state == "free" and not q[0].out, "... the winner stands free")
	SimCore.dispose(S)
	var O := _new(51, false)
	var r: Array = _four(O)
	_ko(O, r[1], r[0])
	ok(SimCore.ended(O), "with the switch off, a fight's KO is the end as before")
	var eo = _koEv(O, 0)
	ok(eo != null and eo.over and eo.winners == [0], "... its event says so, and names the winner's slot (%s)" % (str(eo.winners) if eo != null else "none"))
	SimCore.dispose(O)


## p2 out in fight 0; then p4 (fight 1) shoots and strikes p1, fight 0's winner, and p3 (fight 1) shoots and strikes p2.
func _inert() -> void:
	var S := _new(52, true)
	var q: Array = _four(S)
	_ko(S, q[1], q[0])
	_steps(S, 240)   # his KO's send lands
	var A = q[0]
	_put(q[3], A.x + 600.0 * A.face, A)
	_put(q[2], A.x + 5000.0 * A.face, A)
	var hp1: float = A.hp
	SimStage.enter(S, 1)
	SimShots.fire(S, S.fighters.find(q[3]), "bolt", {"ux": -A.face, "uy": 0.0})
	SimStage.enter(S, 0)
	_steps(S, 30)
	ok(A.hp < hp1, "a shot from outside reaches the finished fight's winner (%.1f)" % (hp1 - A.hp))
	var hp1b: float = A.hp
	SimCross.strike(S, q[3], A, 30.0, {"weight": "light"})
	_steps(S, 2)
	ok(A.hp < hp1b, "... and a blow (%.1f)" % (hp1b - A.hp))
	var D = q[1]
	_put(q[2], D.x + 600.0, D)
	_put(q[3], D.x + 5000.0, D)
	_put(A, D.x - 5000.0, D)
	var hp2: float = D.hp
	var y: float = D.y + SimShots.chest
	SimStage.enter(S, 1)
	var sh = SimShots.fire(S, S.fighters.find(q[2]), "bolt", {"ux": -1.0, "uy": 0.0, "y": y})
	SimStage.enter(S, 0)
	_steps(S, 30)
	ok(D.hp == hp2, "a shot passes the out body (%.1f)" % (hp2 - D.hp))
	SimCross.strike(S, q[2], D, 30.0, {"weight": "light"})
	ok(S.stage.mail.is_empty(), "a blow for the out body is refused")
	SimCore.dispose(S)


func _teamOut() -> void:
	var S := _new(53, true)
	var q: Array = _four(S)
	_ko(S, q[1], q[0])
	_steps(S, 10)
	_ko(S, q[3], q[2])
	ok(S.stage.over == 1 and SimCore.ended(S), "the match ends when a team has nobody standing (over %d)" % S.stage.over)
	var e = _koEv(S, 1)
	ok(e != null and e.over and e.winners == [0, 2], "... the last KO's event says so, and names the winning team's slots (%s)" % (str(e.winners) if e != null else "none"))
	SimCore.dispose(S)


## p2 falls to p1 in fight 0, then p3 to p4 in fight 1: p1 and p4 stand, one on each team. Returns S at the second KO.
func _two(seed: int) -> SimState:
	var S := _new(seed, true)
	var q: Array = _four(S)
	_ko(S, q[1], q[0])
	_steps(S, 200)
	_ko(S, q[2], q[3])
	return S


func _rejoin() -> void:
	var S := _two(54)
	var q: Array = _four(S)
	var p4 = q[3]
	p4.stage[1] = 2   # wear on a region and the brink, to be kept
	p4.brink = true
	var stage0: Array = p4.stage.duplicate()
	var early: int = -1
	var at: int = -1
	var pre: float = 0.0
	var post: float = 0.0
	var launched: int = -1
	var landed: int = -1
	for t in range(1200):
		if launched < 0 and _game(S, 1).koT >= SimCross.rejoinAfter - 0.3:   # a launch in flight as the moment ends holds the rejoin back
			SimStage.enter(S, 1)
			SimDir.doLaunch(S, q[2], p4, {"ux": 0.0, "uy": 1.0}, 2400.0)
			SimStage.enter(S, 0)
			launched = t
		var before: float = p4.hurtT - _clock(S, p4)
		SimCore.step(S)
		_drain(S)
		if launched >= 0 and landed < 0 and p4.state != "launched":
			landed = t
		if S.stage.rejoined > 0 and at < 0:
			at = t
			pre = before
			post = p4.hurtT - _clock(S, p4)
		if at < 0 and _game(S, 1).koT >= SimCross.rejoinAfter and early < 0:
			early = t
	ok(early >= 0 and landed > early and at >= landed, "the rejoin waits for the second KO's moment and a launch in flight (moment over at %d, landed at %d, rejoined at %d)" % [early, landed, at])
	var f0: Array = S.fighters
	ok(S.stage.rejoined == 1 and f0.has(q[0]) and f0.has(p4), "the two standing are fight 0's pair")
	ok(S.stage.fights[1].fighters.has(q[1]) and S.stage.fights[1].fighters.has(q[2]), "... and the two out the other's")
	ok(S.game.ko == null and S.game.ts == 1.0 and not SimCore.ended(S), "... the fight's KO is cleared, and the match goes on")
	ok(p4.stage == stage0 and p4.brink, "... his wear and the brink as they stood")
	ok(absf(post - pre) <= 0.02, "... his times on the new clock: what he had left, less the tick (%.4f against %.4f)" % [post, pre])
	var hp: float = p4.hp
	SimShots.fire(S, S.fighters.find(q[0]), "bolt", {"target": S.fighters.find(p4)})
	_steps(S, 80)   # a seeking shot arrives within 45 ticks, however far
	ok(p4.hp < hp, "... and they fight as a pair (%.1f)" % (hp - p4.hp))
	_ko(S, p4, q[0])
	ok(S.stage.over == 1 and SimCore.ended(S), "the rejoined fight's KO ends the match")
	notes.append("rejoin: the second KO's moment over at tick %d, his launch landed at %d, rejoined at %d" % [early, landed, at])
	SimCore.dispose(S)


func _rollback() -> void:
	var S := _two(55)
	_steps(S, 100)
	var snap: NetSnapshot = NetSnapshot.take(S)
	var hs: Array = []
	for t in range(500):
		SimCore.step(S)
		_drain(S)
		hs.append("%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)])
	var r1: int = S.stage.rejoined
	NetSnapshot.restore(S, snap)
	ok(S.stage.rejoined == 0, "the restore is before the rejoin")
	var differ: int = 0
	for t in range(500):
		SimCore.step(S)
		_drain(S)
		if "%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)] != hs[t]:
			differ += 1
	ok(r1 == 1 and differ == 0, "a rollback across the rejoin: 500 ticks, %d differ (rejoined %d)" % [differ, r1])
	SimCore.dispose(S)


## Four computer fighters together until the match ends, or 45,000 ticks, with the director's match ending on (main's data has
## it off, and then nobody is finished: no KO in 18,000 ticks on three seeds).
func _ai() -> void:
	DirEnding._force = 1
	for seed in [61, 62]:
		var finals: Array = []
		var line: String = ""
		for run in range(2):
			var S := _new(seed, true, true)
			var q: Array = _four(S)
			for k in range(1, 4):
				_put(q[k], q[0].x + 200.0 * k * q[0].face, q[0])
			var first: int = -1
			var early: bool = false
			var t: int = 0
			while t < 45000 and not SimCore.ended(S):
				SimCore.step(S)
				_drain(S)
				t += 1
				if first < 0:
					for f in q:
						if f.out:
							first = t
					if first >= 0 and SimCore.ended(S):
						var standing: Array = [0, 0]
						for f in q:
							if not f.out:
								standing[SimCross.team(f)] += 1
						early = standing[0] > 0 and standing[1] > 0
			var due: bool = S.stage.over < 0 and S.stage.rejoined == 0
			var stand: Array = []
			for f in q:
				if not f.out:
					stand.append(f)
			due = due and stand.size() == 2 and SimCross.team(stand[0]) != SimCross.team(stand[1]) and SimStage.fightOf(S, stand[0]) != SimStage.fightOf(S, stand[1])
			for i in range(2):
				due = due and _game(S, i).ko != null and _game(S, i).koT > SimCross.rejoinAfter + 5.0
			ok(not due, "seed %d: no rejoin left waiting with both fights finished and one standing on each team" % seed)
			finals.append(str(SimHash.stateHash(S).gameplay) + NetDesync.digest(S))
			if run == 0:
				var outs: Array = []
				for f in q:
					if f.out:
						outs.append(f.keys)
				line = "seed %d: first out at %d, rejoined %d, ended %s at %d, out %s" % [seed, first, S.stage.rejoined, str(SimCore.ended(S)), t, str(outs)]
				ok(not early, "seed %d: a first KO didn't end the match" % seed)
			SimCore.dispose(S)
		notes.append(line)
		ok(finals[0] == finals[1], "seed %d: two runs, one hash" % seed)
	DirEnding._force = -1


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	if negative:
		SimCross.blind = 4
		var f0: int = fails
		_firstKO()
		_inert()
		_teamOut()
		var seen: int = fails - f0
		fails = f0
		SimCross.blind = 0
		ok(seen > 0, "the negative control's fallen body left standing is seen (%d checks)" % seen)
		print("CROSSEND negative control: %d check(s) failed" % fails)
		quit(1 if fails > 0 else 0)
		return
	_firstKO()
	_inert()
	_teamOut()
	_rejoin()
	_rollback()
	_ai()
	for n in notes:
		print("  " + n)
	print("CROSSEND: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
