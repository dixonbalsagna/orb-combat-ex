extends SceneTree
## 2v2 across fights (sim/core/cross.gd): godot --headless --path . --script res://sim/core/tools/cross_check.gd
## - with the switch on and the fights apart, each fight is what it is with the switch off, tick by tick
## - a shot from outside lands exactly as the same shot from inside would, clean, guarded or dodged, on the next tick, and
##   passes a partner; one fired across can be perfect-blocked and comes back; a shot inside the other fight's beam is eaten
## - a beam stops at the first enemy of the other fight on its line and names him first; it passes a partner, a dodge, and
##   anyone past its own target; a mine's blast and a blow reach the other fight's enemy
## - a hit on someone held lands the first tick his fight is free; a hit follows its body through a trade, and a trade
##   between teams is refused
## - a rollback across hits on their way, the hash sees them, and the walks between ticks leave S holding its fight
## - a replay of two fights with players in slots 0 and 2 and a toggle; an AI match of four together, twice, one hash
## --negative-control loses what's sent, lands it twice, and loses a shot going over, and the checks have to see each.

var fails: int = 0
var negative: bool = false
var notes: Array = []


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func _new(seed: int, cross: bool, ai: bool = false, extra: Dictionary = {}) -> SimState:
	var su: Dictionary = {"intro": false, "fights": 2, "cross": cross}
	su.merge(extra, true)
	var S := SimCore.createSim()
	SimCore.newMatch(S, seed, {"p1": ai, "p2": ai, "p3": ai, "p4": ai}, su)
	return S


func _drain(S: SimState) -> void:
	S.out.fx.clear()
	S.out.feed.clear()


## f stands at x, at ref's height and depth, still.
func _put(f, x: float, ref) -> void:
	f.x = SimWrap.wrap(x)
	f.y = ref.y
	f.z = ref.z
	f.vx = 0.0
	f.vy = 0.0


## The four, by starting slot: [p1, p2, p3, p4]. p1 and p3 are a team, p2 and p4 the other.
func _four(S: SimState) -> Array:
	var b: Array = SimStage.bodies(S)
	var out: Array = []
	for k in ["p1", "p2", "p3", "p4"]:
		for f in b:
			if f.keys == k:
				out.append(f)
	return out


func _sentAt() -> int:
	var c: int = 0
	for k in SimCross.sent:
		c += int(SimCross.sent[k])
	return c


## A bolt from p1 at a target 600 in front of him: p4 in the other fight (across) or p2, his own opponent (inside), with
## the other one far behind. pressed: p1 has made a blast press, so the director's rules meet it. guard: the target holds
## guard; dodge: he's in his dodge as it arrives. Returns [drop, tick it went over or -1, tick it landed or -1, gone].
func _bolt(seed: int, across: bool, pressed: bool, guard: bool, dodge: bool) -> Array:
	var S := _new(seed, true)
	var q: Array = _four(S)
	var A = q[0]
	var T = q[3] if across else q[1]
	var other = q[1] if across else q[3]
	_put(T, A.x + 600.0 * A.face, A)
	_put(other, A.x - 4000.0 * A.face, A)
	_put(q[2], A.x - 6000.0 * A.face, A)
	if pressed:
		DirInterrupt.si(A, DirInterrupt.BLAST_AT, S.tick)
	var hp0: float = T.hp
	var sh = SimShots.fire(S, 0, "bolt", {"ux": A.face, "uy": 0.0})
	var over: int = -1
	var landed: int = -1
	for t in range(40):
		if guard:
			T.stance = 1.0
		if dodge:
			T.act.dodgeTick = S.tick
		var c0: int = _sentAt()
		SimCore.step(S)
		_drain(S)
		S.stage.fights[1].out.fx.clear()
		if over < 0 and _sentAt() > c0:
			over = S.tick
		if landed < 0 and T.hp < hp0:
			landed = S.tick
	var gone: bool = not S.shots.has(sh) and not S.stage.fights[1].shots.has(sh)
	var out: Array = [hp0 - T.hp, over, landed, gone]
	SimCore.dispose(S)
	return out


func _shot() -> void:
	var on: bool = DirBlast.on()
	notes.append("director's blast rules: %s" % ("on" if on else "off"))
	for c in [[false, false, false, "clean, no press: the plain rule"], [true, false, false, "clean"], [true, true, false, "guarded"], [true, false, true, "dodged"]]:
		var a: Array = _bolt(11, true, c[0], c[1], c[2])
		var b: Array = _bolt(11, false, c[0], c[1], c[2])
		ok(absf(float(a[0]) - float(b[0])) < 1e-9, "a shot from outside, %s, lands as from inside (%.3f against %.3f)" % [c[3], a[0], b[0]])
		ok(a[1] > 0, "... it went over (%s)" % c[3])
		if float(a[0]) > 0.0:
			ok(a[2] == a[1] + 1, "... and landed on that fight's next tick (over %d, landed %d)" % [a[1], a[2]])
			ok(a[3], "... and ended there")
		notes.append("bolt %s: across %.2f, inside %.2f" % [c[3], a[0], b[0]])
	if on:
		var clean: Array = _bolt(11, true, true, false, false)
		var guarded: Array = _bolt(11, true, true, true, false)
		var dodged: Array = _bolt(11, true, true, false, true)
		ok(float(guarded[0]) < float(clean[0]), "... his guard takes some of it (%.2f against %.2f)" % [guarded[0], clean[0]])
		ok(float(dodged[0]) == 0.0, "... his dodge lets it pass (%.2f)" % dodged[0])
	# a partner of p1's in the other fight on the line: it passes him and flies on
	var S := _new(11, true)
	var q: Array = _four(S)
	var A = q[0]
	_put(q[1], A.x - 900.0 * A.face, A)
	_put(q[2], A.x + 600.0 * A.face, A)
	_put(q[3], A.x - 4000.0 * A.face, A)
	var hp0: float = q[2].hp
	var s0: int = _sentAt()
	var sh = SimShots.fire(S, 0, "bolt", {"ux": A.face, "uy": 0.0})
	for t in range(30):
		SimCore.step(S)
		_drain(S)
	ok(q[2].hp == hp0 and _sentAt() == s0 and S.shots.has(sh), "a shot passes a partner in the other fight and flies on")
	SimCore.dispose(S)


## A shot fired across (SimCross.fireAt) seeks the other fight's enemy there: his fight sees it coming, his perfect block
## sends it back, and it comes over to the shooter.
func _deflect() -> void:
	if not DirBlast.on():
		notes.append("deflect: blasts off, not run")
		return
	var S := _new(19, true)
	var q: Array = _four(S)
	var A = q[0]
	_put(q[1], A.x - 900.0 * A.face, A)
	_put(q[3], A.x + 700.0 * A.face, A)
	_put(q[2], A.x - 5000.0 * A.face, A)
	DirInterrupt.si(A, DirInterrupt.BLAST_AT, S.tick)
	var hpA: float = A.hp
	var hpD: float = q[3].hp
	var sh = SimCross.fireAt(S, A, "bolt", q[3])
	ok(sh != null and S.stage.fights[1].shots.has(sh) and sh.owner == -1 and sh.from == "p1", "a shot fired across is made in his fight, from outside")
	var seen: bool = false
	var marked: bool = false
	for t in range(80):
		SimStage.enter(S, 1)
		if DirBlast.incoming(S, q[3]):
			seen = true
		if not marked and DirBlast.windowShot(S, q[3]) != null:
			marked = DirBlast.mark(S, q[3])
		SimStage.enter(S, 0)
		SimCore.step(S)
		_drain(S)
		S.stage.fights[1].out.fx.clear()
	ok(seen, "... his fight sees it coming")
	ok(marked and q[3].hp == hpD, "... his perfect block takes nothing (marked %s, %.2f)" % [str(marked), hpD - q[3].hp])
	if SimShots.scatter:
		notes.append("deflect: the shot went wild (scatter on); p1 took %.2f" % (hpA - A.hp))
	else:
		ok(A.hp < hpA, "... and it came back over to the shooter (%.2f)" % (hpA - A.hp))
	SimCore.dispose(S)


## The same shot with the other fight held: it lands on the first tick that fight is live again.
func _held() -> void:
	var S := _new(12, true)
	var q: Array = _four(S)
	var A = q[0]
	_put(q[1], A.x - 900.0 * A.face, A)
	_put(q[3], A.x + 600.0 * A.face, A)
	_put(q[2], A.x - 4000.0 * A.face, A)
	SimShots.fire(S, 0, "bolt", {"ux": A.face, "uy": 0.0})
	var hp0: float = q[3].hp
	var sentTick: int = -1
	var landTick: int = -1
	var live: Array = []
	for t in range(60):
		var c0: int = _sentAt()
		if sentTick < 0:
			S.stage.fights[1].dirS.stop = 0.3   # held until the shot's well past
		var t1: float = S.stage.fights[1].T
		SimCore.step(S)
		_drain(S)
		if sentTick < 0 and _sentAt() > c0:
			sentTick = S.tick
		if S.stage.fights[1].T != t1:
			live.append(S.tick)
		if landTick < 0 and q[3].hp < hp0:
			landTick = S.tick
	var firstLive: int = -1
	for t in live:
		if t > sentTick:
			firstLive = t
			break
	ok(sentTick > 0 and firstLive > sentTick + 1 and landTick == firstLive, "a shot on someone held lands the first tick his fight is live (over %d, live again %d, landed %d)" % [sentTick, firstLive, landTick])
	SimCore.dispose(S)


## A mine of p1's: the other fight's enemy sets it off and takes its blast; a partner on it doesn't set it off.
func _mine() -> void:
	for partner in [false, true]:
		var S := _new(13, true)
		var q: Array = _four(S)
		var A = q[0]
		var sh = SimShots.fire(S, 0, "mine", {})
		ok(sh != null, "a mine is laid")
		if sh == null:
			SimCore.dispose(S)
			return
		_put(A, A.x - 3000.0 * A.face, A)
		_put(q[1], A.x - 900.0 * A.face, A)
		var tgt = q[2] if partner else q[3]
		var other = q[3] if partner else q[2]
		_put(other, sh.x + 5000.0, A)
		for t in range(int(SimShots.kinds["mine"].mine.armTicks) + 2):
			SimCore.step(S)
			_drain(S)
		tgt.x = sh.x
		tgt.y = sh.y - SimShots.chest
		tgt.z = sh.z
		tgt.vx = 0.0
		tgt.vy = 0.0
		var hp0: float = tgt.hp
		for t in range(90):
			SimCore.step(S)
			_drain(S)
		if partner:
			ok(sh.fuse < 0 and tgt.hp == hp0, "a partner on the mine doesn't set it off (fuse %d)" % sh.fuse)
		else:
			ok(sh.dead and tgt.hp < hp0, "an enemy of the other fight sets the mine off and takes its blast (%.1f)" % (hp0 - tgt.hp))
		SimCore.dispose(S)


## A beam of p1's along his facing, with p2 (his own target) at own, p3 (a partner) at mate and p4 at foe, each ahead of him
## when positive and far behind when 0. Returns [p4's drop, how often he dropped, the beam, p3's drop, whether p4 was named
## first before it reached him, the shot of p4's fired back across it at tick 3, p4's fight's hold after the hit].
func _beamRun(own: float, mate: float, foe: float, guard: bool = false, dodge: bool = false) -> Array:
	var S := _new(14, true)
	var q: Array = _four(S)
	var A = q[0]
	_put(q[1], A.x + (own if own > 0.0 else -9000.0) * A.face, A)
	_put(q[2], A.x + (mate if mate > 0.0 else -6000.0) * A.face, A)
	_put(q[3], A.x + foe * A.face, A)
	var b := SimState.Beam.new()
	b.A = A; b.ox = A.x; b.oy = A.y + SimShots.chest; b.ux = A.face; b.uy = 0.0; b.len = 2000.0
	b.p = 0.0; b.t = 0.0; b.life = 0.95; b.w = 24.0 + A.tier * 9.0; b.variant = "HORIZON CLEAVE"; b.col = A.aura
	b.sf = 1.0; b.cap = -1; b.pw = 1.0; b.oz = A.z
	S.beams.append(b)
	var hpMate: float = q[2].hp
	var hp0: float = q[3].hp
	var drops: int = 0
	var last: float = hp0
	var named: bool = false
	var stop1: float = 0.0
	var eat = null
	for t in range(60):
		if guard:
			q[3].stance = 1.0
		if dodge:
			q[3].act.dodgeTick = S.tick
		if t == 3:
			SimStage.enter(S, 1)
			eat = SimShots.fire(S, S.fighters.find(q[3]), "bolt", {"ux": -A.face, "uy": 0.0, "x": SimWrap.wrap(A.x + 300.0 * A.face), "y": b.oy, "z": A.z})
			SimStage.enter(S, 0)
		SimCore.step(S)
		_drain(S)
		S.stage.fights[1].out.fx.clear()
		if b.first == "p4" and q[3].hp == hp0:
			named = true
		if q[3].hp < last:
			drops += 1
			last = q[3].hp
			stop1 = S.stage.fights[1].dirS.stop
	var out: Array = [hp0 - q[3].hp, drops, b, hpMate - q[2].hp, named, eat, stop1]
	SimCore.dispose(S)
	return out


func _beam() -> void:
	var r: Array = _beamRun(0.0, 500.0, 800.0)
	var b = r[2]
	ok(r[1] == 1, "a beam hits the first enemy of the other fight on its line once (%d times, %.1f)" % [r[1], r[0]])
	ok(r[4], "... he's named first on it before it reaches him")
	ok(absf(b.stopAt - 800.0) < 1.0, "... and it stops at him (%.1f)" % b.stopAt)
	ok(r[6] > 0.0, "... his fight holds (%.3f s)" % r[6])
	ok(r[3] == 0.0, "... his partner on the line is passed")
	ok(r[5] != null and r[5].dead, "a shot of the other fight inside the beam is eaten")
	notes.append("beam: %.1f, stopped at %.1f" % [r[0], b.stopAt])
	var g: Array = _beamRun(0.0, 500.0, 800.0, true)
	ok(g[1] == 1 and float(g[0]) < float(r[0]), "... his guard takes some of it (%.1f against %.1f)" % [g[0], r[0]])
	var d: Array = _beamRun(0.0, 500.0, 800.0, false, true)
	ok(d[1] == 0 and d[2].stopAt < 0.0, "... in his dodge it passes him and goes on (%d hits, stop %.1f)" % [d[1], d[2].stopAt])
	var past: Array = _beamRun(600.0, 0.0, 800.0)
	ok(past[1] == 0 and past[2].first == "" and past[2].stopAt < 0.0, "an enemy past the beam's own target isn't first and isn't hit (%d)" % past[1])
	var near: Array = _beamRun(900.0, 0.0, 700.0)
	ok(near[1] == 1 and absf(near[2].stopAt - 700.0) < 1.0, "... one before it is (%d, %.1f)" % [near[1], near[2].stopAt])


## Encounter's call: enemiesNear finds the other fight's enemy, not a partner; strike lands through SimDamage.hit there,
## holding that fight and not this one.
func _blow() -> void:
	var S := _new(15, true)
	var q: Array = _four(S)
	var A = q[0]
	_put(q[1], A.x - 900.0 * A.face, A)
	_put(q[2], A.x + 150.0 * A.face, A)
	_put(q[3], A.x + 300.0 * A.face, A)
	var near: Array = SimCross.enemiesNear(S, A, 1000.0)
	ok(near.size() == 1 and near[0] == q[3], "enemiesNear lists the other fight's enemy and not a partner")
	ok(SimCross.enemiesNear(S, A, 200.0).is_empty(), "... within its reach only")
	var hp0: float = q[3].hp
	SimCross.strike(S, A, q[3], 40.0, {"weight": "light", "stop": 0.05})
	ok(S.stage.mail.size() == 1, "a blow sent across waits on the stage, once (%d)" % S.stage.mail.size())
	SimCore.step(S)
	_drain(S)
	var d: float = hp0 - q[3].hp
	ok(d > 0.0, "... and lands on the next tick (%.2f)" % d)
	ok(S.stage.fights[1].dirS.stop > 0.0 and S.dirS.stop == 0.0, "... holding his fight and not the striker's")
	for t in range(30):
		SimCore.step(S)
		_drain(S)
	ok(absf((hp0 - q[3].hp) - d) < 1e-9 and S.stage.mail.is_empty(), "... once")
	SimCross.strike(S, A, q[2], 40.0, {})
	ok(S.stage.mail.is_empty(), "a blow for a partner is refused")
	notes.append("blow: 40 sent, %.2f landed" % d)
	SimCore.dispose(S)


## A blow on its way follows its body through a trade; a trade between teams is refused with the switch on, and allowed off.
func _trade() -> void:
	var S := _new(16, true)
	var q: Array = _four(S)
	var A = q[0]
	_put(q[3], A.x + 300.0 * A.face, A)
	var hp0: float = q[3].hp
	SimCross.strike(S, A, q[3], 40.0, {"weight": "light"})
	ok(not SimStage.trade(S, q[0], q[3]), "a trade between teams is refused")
	ok(SimStage.trade(S, q[3], q[1]), "a trade between partners is allowed")
	ok(SimStage.fightOf(S, q[3]) == 0, "... and p4 is in fight 0")
	SimCore.step(S)
	_drain(S)
	ok(q[3].hp < hp0 and S.stage.mail.is_empty(), "the blow lands on him in his new fight")
	SimCore.dispose(S)
	var O := _new(16, false)
	var r: Array = _four(O)
	ok(SimStage.trade(O, r[0], r[3]), "with the switch off a trade is as it was")
	SimCore.dispose(O)


## A rollback across hits on their way: the same ticks again, by hash and digest; the hash and digest see the mail.
func _rollback() -> void:
	var S := _new(17, true)
	var q: Array = _four(S)
	var A = q[0]
	_put(q[3], A.x + 300.0 * A.face, A)
	var h0: String = "%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)]
	SimCross.strike(S, A, q[3], 40.0, {"weight": "light"})
	var h1: String = "%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)]
	S.stage.fights[1].dirS.stop = 0.1
	ok(h0.get_slice(" ", 0) != h1.get_slice(" ", 0), "the hash sees a hit on its way")
	ok(h0.get_slice(" ", 1) != h1.get_slice(" ", 1), "... and the digest")
	var snap: NetSnapshot = NetSnapshot.take(S)
	SimShots.fire(S, 0, "bolt", {"ux": A.face, "uy": 0.0})
	var hs: Array = []
	for t in range(40):
		SimCore.step(S)
		_drain(S)
		hs.append("%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)])
	NetSnapshot.restore(S, snap)
	SimShots.fire(S, 0, "bolt", {"ux": A.face, "uy": 0.0})
	var differ: int = 0
	for t in range(40):
		SimCore.step(S)
		_drain(S)
		if "%s %s" % [str(SimHash.stateHash(S).gameplay), NetDesync.digest(S)] != hs[t]:
			differ += 1
	ok(differ == 0, "a rollback across hits and a shot on their way: 40 ticks, %d differ" % differ)
	SimCore.dispose(S)


## Two of the same match, four together and fighting; one holds fight 1 between ticks as NetLan does, and reads the hash and
## the digest there. Every tick the same, and the reads leave fight 1 in S.
func _between() -> void:
	var X := _new(18, true, true)
	var Y := _new(18, true, true)
	for S in [X, Y]:
		var q: Array = _four(S)
		for k in range(1, 4):
			_put(q[k], q[0].x + 120.0 * k * q[0].face, q[0])
	var differ: int = 0
	var kept: bool = true
	for t in range(900):
		SimCore.step(X)
		SimCore.step(Y)
		SimStage.enter(X, 1)
		var hx: String = str(SimHash.stateHash(X).gameplay) + NetDesync.digest(X)
		kept = kept and X.stage.cur == 1
		var hy: String = str(SimHash.stateHash(Y).gameplay) + NetDesync.digest(Y)
		if hx != hy:
			differ += 1
		X.out.fx.clear(); X.out.feed.clear(); X.stage.fights[0].out.fx.clear(); X.stage.fights[0].out.feed.clear()
		_drain(Y)
		Y.stage.fights[1].out.fx.clear()
	ok(differ == 0, "holding fight 1 between ticks changes nothing: 900 ticks, %d differ" % differ)
	ok(kept, "... and the hash and the digest leave S holding it")
	SimCore.dispose(X)
	SimCore.dispose(Y)


## A replay of two fights: players in slots 0 and 2, the computer in 1 and 3, slot 2 handed to the computer half way.
func _replay() -> void:
	var setup: Dictionary = {"intro": false, "fights": 2, "cross": true}
	var S := SimCore.createSim()
	var rec := SimReplay.recorder(S, 21, {"p1": false, "p2": true, "p3": false, "p4": true}, setup)
	ok(rec.replay.ai.has("p3") and rec.replay.ai.has("p4"), "a two-fight replay's header names all four")
	var rng := SimRng.new(99)
	var two: int = 0
	for t in range(900):
		var ins: Array = [null, null, null, null]
		for k in [0, 2]:
			var i := SimIntent.new()
			i.mx = float(int(rng.next() * 255.0) - 127) / 127.0
			i.light = rng.next() < 0.08
			i.heavy = rng.next() < 0.03
			i.guard = rng.next() < 0.2
			ins[k] = i
		if t == 450:
			rec.toggle(2)
		rec.step(ins)
		S.out.fx.clear(); S.out.feed.clear()
	for e in rec.replay.inputs:
		if int(e[1]) == 2:
			two += 1
	var rp: Dictionary = rec.finish()
	ok(two > 0, "slot 2's inputs are recorded (%d entries)" % two)
	var r: Dictionary = SimReplay.play(rp)
	ok(r.ok, "the replay of two fights reproduces (%s at %d)" % [r.reason, r.firstBadTick])
	rp.inputs = rp.inputs.filter(func(e): return int(e[1]) != 2)
	var r2: Dictionary = SimReplay.play(rp)
	ok(not r2.ok, "... and without slot 2's entries it doesn't (%s at %d)" % [r2.reason, r2.firstBadTick])
	SimCore.dispose(S)


## Four computer fighters together: twice, one hash, and nothing to a partner. Then the same seed with the fights apart, on
## and off: each fight the same, tick by tick.
func _ai() -> void:
	var finals: Array = []
	for run in range(2):
		SimCross.sent = {}
		SimCross.landed = {}
		SimCross.partners = 0
		var S := _new(31, true, true)
		var q: Array = _four(S)
		for k in range(1, 4):
			_put(q[k], q[0].x + 200.0 * k * q[0].face, q[0])
		var close: int = 0
		for t in range(2400):
			SimCore.step(S)
			_drain(S)
			S.stage.fights[1].out.fx.clear()
			if SimStage.gap(S) < 2000.0:
				close += 1
		finals.append(str(SimHash.stateHash(S).gameplay) + NetDesync.digest(S))
		if run == 0:
			notes.append("ai together: within 2,000 for %d of 2,400 ticks; sent %s, landed %s" % [close, str(SimCross.sent), str(SimCross.landed)])
			ok(SimCross.partners == 0, "none sent to a partner")
		SimCore.dispose(S)
	ok(finals[0] == finals[1], "two runs one hash")
	for seed in [41, 42]:
		var On := _new(seed, true, true)
		var Off := _new(seed, false, true)
		var first: int = -1
		for t in range(1500):
			SimCore.step(On)
			SimCore.step(Off)
			_drain(On)
			_drain(Off)
			if first < 0 and _fightVals(On) != _fightVals(Off):
				first = t
		ok(first < 0, "seed %d apart: the switch on changes neither fight (first differs at %d)" % [seed, first])
		SimCore.dispose(On)
		SimCore.dispose(Off)


func _fightVals(S: SimState) -> Array:
	var v: Array = []
	for i in range(S.stage.fights.size()):
		SimStage.enter(S, i)
		v.append_array(SimHash.collect(S, "gameplay"))
	SimStage.enter(S, 0)
	return v


func _run() -> void:
	if negative:
		for mode in [1, 2, 3]:
			SimCross.blind = mode
			var f0: int = fails
			print("-- planted: %s" % ["", "lost", "landed twice", "a shot lost going over"][mode])
			if mode == 3:
				_shot()
			else:
				_blow()
			var seen: int = fails - f0
			fails = f0
			ok(seen > 0, "the negative control's planted break %d is seen (%d checks)" % [mode, seen])
		SimCross.blind = 0
		print("CROSS negative control: %d check(s) failed" % fails)
		quit(1 if fails > 0 else 0)
		return
	_shot()
	_deflect()
	_held()
	_mine()
	_beam()
	_blow()
	_trade()
	_rollback()
	_between()
	_replay()
	_ai()
	for n in notes:
		print("  " + n)
	print("CROSS: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)


func _init() -> void:
	negative = OS.get_cmdline_user_args().has("--negative-control")
	_run()
