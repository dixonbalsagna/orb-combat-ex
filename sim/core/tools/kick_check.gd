extends SceneTree
## The kick and the coin turn (docs/architecture/kick.md): godot --headless --path . --script res://sim/core/tools/kick_check.gd
## The numbers in data, Game Design's limits on the overspeed, the switch, and two runs and a rollback through kicks and plants.

var fails: int = 0


func ok(c: bool, what: String) -> void:
	if not c:
		fails += 1
		print("FAIL  " + what)


func _mk(sep: float, on: bool = true, more: Dictionary = {}) -> SimState:
	var S := SimCore.createSim()
	var su: Dictionary = {"kick": on, "intro": false}
	su.merge(more)
	SimCore.newMatch(S, 77, {"p1": false, "p2": false}, su)
	var a = S.fighters[0]
	var b = S.fighters[1]
	a.x = 2000.0
	b.x = SimWrap.wrap(2000.0 + sep)
	a.y = 2000.0
	b.y = 2000.0
	a.vx = 0.0
	a.vy = 0.0
	return S


## Flies f a tick with the stick at mx, flat out; returns his top speed.
func _fly(S: SimState, mx: float, dash: bool = true) -> float:
	var f = S.fighters[0]
	var i := SimIntent.new()
	i.mx = mx
	i.dash = dash
	var sp: float = SimFighter.flightSpeed(S, f, dash)
	SimKick.move(S, f, i, sp, 1.0 - SimDetMath.pow(0.0008, SimConst.DT))
	S.tick += 1
	return sp


## The kick's shape: instant on the first tick, then a straight climb to top speed, never over it, and at other values of the data.
func _shape(instant: float, climb: int) -> void:
	var S := _mk(3000.0, true, {"instant": instant, "climbTicks": climb})
	var f = S.fighters[0]
	var sp: float = _fly(S, 1.0)
	ok(absf(f.vx / sp - (instant if climb > 0 else 1.0)) < 1e-9, "shape %.1f/%d: the first tick (%.4f of top)" % [instant, climb, f.vx / sp])
	var last: float = f.vx
	var peak: float = f.vx / sp
	var rose: bool = true
	for t in range(40):
		_fly(S, 1.0)
		rose = rose and f.vx >= last - 1e-9
		last = f.vx
		peak = maxf(peak, f.vx / sp)
		if t == climb:
			ok(absf(f.vx / sp - 1.0) < 1e-9, "shape %.1f/%d: top speed by the end of the climb (%.4f)" % [instant, climb, f.vx / sp])
	ok(rose, "shape %.1f/%d: it only rises" % [instant, climb])
	ok(peak <= 1.0 + 1e-9, "shape %.1f/%d: never over top speed with the overspeed off (%.3f)" % [instant, climb, peak])
	ok(absf(f.vx / sp - 1.0) < 1e-9, "shape %.1f/%d: it stays at top speed after (%.4f)" % [instant, climb, f.vx / sp])
	var h0: String = SimHash.stateHash(S).gameplay
	S.kickClimb += 1
	ok(SimHash.stateHash(S).gameplay != h0, "shape %.1f/%d: its values are in the hash" % [instant, climb])
	SimCore.dispose(S)


## Flying at the rival from far away: he keeps the speed he had until he's close, then comes down without flying through him; away, he still gains. Without keepTop, the old fall.
func _keep() -> void:
	var run := func(keep: bool, sep: float, dir: float) -> Array:
		SimKick.keepTop = keep
		var S := SimCore.createSim()
		SimCore.newMatch(S, 77, {"p1": false, "p2": false}, {"kick": true, "intro": false})
		var f = S.fighters[0]
		var o = S.fighters[1]
		f.x = 40000.0
		o.x = 40000.0 + sep
		f.y = 3000.0
		o.y = 3000.0
		var peak: float = 0.0
		var atNear: float = 0.0
		var fell: bool = false
		var last: float = 0.0
		var closest: float = 1e18
		for t in range(240):
			var i := SimIntent.new()
			i.mx = dir
			i.dash = true
			SimCore.step(S, [i, null])
			S.out.fx.clear()
			S.out.feed.clear()
			var gap: float = absf(SimWrap.sdx(f.x, o.x))
			closest = minf(closest, gap)
			var v: float = absf(f.vx)
			if t > SimKick.climbTicks + 1 and gap > SimConst.BOOST_NEAR + 200.0 and v < last - 1e-6:
				fell = true
			if gap > SimConst.BOOST_NEAR:
				atNear = v
			peak = maxf(peak, v)
			last = v
			if dir > 0.0 and f.x >= o.x:
				break
		SimCore.dispose(S)
		return [peak, atNear, fell, closest, last]
	var a: Array = run.call(true, 6500.0, 1.0)
	ok(not a[2], "keepTop: flying at the rival he never slows until he's close (peak %.0f, at 1,500 %.0f)" % [a[0], a[1]])
	var b: Array = run.call(false, 6500.0, 1.0)
	ok(b[2], "without it the traversal's fall is there (peak %.0f, at 1,500 %.0f)" % [b[0], b[1]])
	ok(a[1] > b[1], "keepTop arrives faster than the old fall (%.0f, %.0f)" % [a[1], b[1]])
	var c: Array = run.call(true, 6500.0, -1.0)
	ok(c[0] > a[0], "away, he still gains (%.0f)" % c[0])
	print("keepTop: from 6,500: peak %.0f, at 1,500 %.0f, closest %.0f; without: at 1,500 %.0f" % [a[0], a[1], a[3], b[1]])
	SimKick.keepTop = true


func _toward() -> void:
	var S := _mk(9000.0)
	var f = S.fighters[0]
	var peak: float = 0.0
	var sp: float = 0.0
	for t in range(60):
		sp = _fly(S, 1.0)
		peak = maxf(peak, f.vx / sp)
	ok(peak >= SimKick.topShare - 0.02, "toward: the overspeed reaches its share (%.3f)" % peak)
	ok(absf(f.vx / sp - 1.0) < 0.02, "toward: it eases back to top speed (%.3f)" % (f.vx / sp))
	SimCore.dispose(S)


func _away() -> void:
	var S := _mk(3000.0)   # inside charge range, flying away
	var f = S.fighters[0]
	var peak: float = 0.0
	var sp: float = 0.0
	for t in range(60):
		sp = _fly(S, -1.0)
		peak = maxf(peak, -f.vx / sp)
	ok(peak <= 1.0 + 1e-9, "away, in range: no overspeed (%.3f)" % peak)
	SimCore.dispose(S)
	var S2 := _mk(SimKick.chargeRange + 2000.0)   # beyond it, away
	var p2: float = 0.0
	for t in range(20):
		var s2: float = _fly(S2, -1.0)
		p2 = maxf(p2, -S2.fighters[0].vx / s2)
	ok(p2 >= SimKick.topShare - 0.02, "away, beyond range: the overspeed (%.3f)" % p2)
	SimCore.dispose(S2)


func _repeat() -> void:
	var S := _mk(9000.0)
	var f = S.fighters[0]
	var peaks: Array = []
	for n in range(4):
		f.vx = 0.0
		f.vy = 0.0
		f.kik.t = 0
		var p: float = 0.0
		for t in range(12):
			var sp: float = _fly(S, 1.0)
			p = maxf(p, f.vx / sp)
		peaks.append(p)
		_fly(S, 0.0, false)
	ok(peaks[0] > 1.2 and peaks[1] > 1.2, "repeats: the first two kicks go over (%s)" % str(peaks))
	ok(peaks[2] <= 1.0 + 1e-9, "repeats: the third inside the window doesn't (%.3f)" % peaks[2])
	S.tick += SimKick.repeatTicks + 1
	f.vx = 0.0
	f.vy = 0.0
	f.kik.t = 0
	var p3: float = 0.0
	for t in range(12):
		var sp3: float = _fly(S, 1.0)
		p3 = maxf(p3, f.vx / sp3)
	ok(p3 > 1.2, "repeats: past the window it's back, no cooldown (%.3f)" % p3)
	SimCore.dispose(S)


func _zip() -> void:
	var S := _mk(SimKick.chargeRange + 2000.0)
	var f = S.fighters[0]
	f.kik.off = SimKick.afterZip
	var p: float = 0.0
	for t in range(10):
		var sp: float = _fly(S, -1.0)
		p = maxf(p, -f.vx / sp)
	ok(p <= 1.0 + 1e-9, "after a zip: none away (%.3f)" % p)
	f.vx = 0.0
	f.vy = 0.0
	f.kik.t = 0
	f.kik.off = SimKick.afterZip
	f.kik.t1 = -1
	f.kik.t2 = -1
	var q: float = 0.0
	for t in range(10):
		var sq: float = _fly(S, 1.0)
		q = maxf(q, f.vx / sq)
	ok(q > 1.2, "after a zip: toward still goes over (%.3f)" % q)
	SimCore.dispose(S)


func _coin() -> void:
	var S := _mk(9000.0)
	var f = S.fighters[0]
	var sp: float = _fly(S, 1.0)
	f.vx = sp
	f.kik.t = 0
	var plant: int = 0
	var told: int = 0
	var at95: int = -1
	for t in range(30):
		_fly(S, -1.0)
		for e in S.out.fx:
			if e.type == "coin_plant":
				told += 1
		S.out.fx.clear()
		if f.vx == 0.0 and t < 12:
			plant += 1
		if at95 < 0 and -f.vx >= 0.95 * sp:
			at95 = t + 1
	ok(plant == SimKick.plantTicks, "coin: he plants for its ticks (%d)" % plant)
	ok(told == 1, "coin: one plant told (%d)" % told)
	ok(at95 > 0 and at95 <= SimKick.brakeTicks + SimKick.plantTicks + S.kickClimb, "coin: full speed the other way soon after (%d ticks)" % at95)
	print("coin: 95%% the other way in %d ticks" % at95)
	SimCore.dispose(S)


## The plant has no invulnerability: it's a plain free fighter to the rest of the sim.
func _noInvul() -> void:
	var S := _mk(3000.0)
	var f = S.fighters[0]
	var sp: float = _fly(S, 1.0)
	f.vx = sp
	f.kik.t = 0
	var hp0: float = f.hp
	_fly(S, -1.0)
	ok(f.kik.turn > 0 and f.state == "free", "plant: he stays a free fighter while it runs")
	ok(f.hp == hp0, "plant: nothing here moved his health")
	SimCore.dispose(S)


## AI fights with the kick on: flat-out flights, kicks and plants all through.
func _run(on, ticks: int, rollAt: int = -1) -> Dictionary:
	var S := SimCore.createSim()
	var setup: Dictionary = {"intro": false}
	if on != null:
		setup["kick"] = on
	SimCore.newMatch(S, 12345, {"p1": true, "p2": true}, setup)
	var snap: NetSnapshot = null
	var kicks: int = 0
	var plants: int = 0
	var at: Array = []
	var bad: int = 0
	for t in range(ticks):
		if t == rollAt:
			snap = NetSnapshot.take(S)
		SimCore.step(S)
		if rollAt >= 0 and t >= rollAt:
			at.append(SimHash.stateHash(S).gameplay)
		for e in S.out.fx:
			if e.type == "kick":
				kicks += 1
			if e.type == "coin_plant":
				plants += 1
		S.out.fx.clear()
		S.out.feed.clear()
	if rollAt >= 0:
		var d0: String = NetDesync.digest(S)
		NetSnapshot.restore(S, snap)
		for t in range(rollAt, ticks):
			SimCore.step(S)
			S.out.fx.clear()
			S.out.feed.clear()
			if SimHash.stateHash(S).gameplay != at[t - rollAt]:
				bad += 1
		ok(NetDesync.digest(S) == d0, "rollback: the digest is the same after the re-run")
	var h: String = SimHash.stateHash(S).gameplay
	SimCore.dispose(S)
	return {"h": h, "kicks": kicks, "plants": plants, "bad": bad}


## A pad's flips: flat out, the stick over one way then the other, and let go now and then. The rival keeps still.
func _flips() -> Dictionary:
	var S := SimCore.createSim()
	SimCore.newMatch(S, 12345, {"p1": false, "p2": false}, {"kick": true, "intro": false})
	var stick := func(t: int) -> Array:
		var a := SimIntent.new()
		var b := SimIntent.new()
		var ph: int = t % 200
		a.dash = ph < 170
		a.mx = 0.0 if ph >= 170 else (1.0 if ph < 60 or ph >= 110 else -1.0)
		return [a, b]
	var hs: Array = []
	var snap: NetSnapshot = null
	var kicks: int = 0
	var plants: int = 0
	var bad: int = 0
	for t in range(900):
		if t == 200:
			snap = NetSnapshot.take(S)
		SimCore.step(S, stick.call(t))
		if t >= 200:
			hs.append(SimHash.stateHash(S).gameplay)
			for e in S.out.fx:
				if e.type == "kick":
					kicks += 1
				if e.type == "coin_plant":
					plants += 1
		S.out.fx.clear()
		S.out.feed.clear()
	NetSnapshot.restore(S, snap)
	for t in range(200, 900):
		SimCore.step(S, stick.call(t))
		S.out.fx.clear()
		S.out.feed.clear()
		if SimHash.stateHash(S).gameplay != hs[t - 200]:
			bad += 1
	SimCore.dispose(S)
	return {"bad": bad, "kicks": kicks, "plants": plants}


func _whole() -> void:
	var a: Dictionary = _run(true, 3600)
	var b: Dictionary = _run(true, 3600)
	ok(a.h == b.h, "two runs give one hash")
	ok(a.kicks > 0, "AI fights kick (%d, %d plants)" % [a.kicks, a.plants])
	print("whole: %d kicks, %d plants in 3,600 ticks" % [a.kicks, a.plants])
	var r: Dictionary = _flips()
	ok(r.bad == 0 and r.kicks > 2 and r.plants > 2, "rollback across %d kicks and %d plants: every tick the same (%d differ)" % [r.kicks, r.plants, r.bad])
	print("rollback: %d kicks, %d plants in the window" % [r.kicks, r.plants])
	var off: Dictionary = _run(false, 600)
	var dflt: Dictionary = _run(null, 600)
	ok(off.h == dflt.h, "off: the same as a match with no word of it")
	ok(off.kicks == 0, "off: no kick told")
	var S := _mk(9000.0)
	var h0: String = SimHash.stateHash(S).gameplay
	S.fighters[0].kik.turn += 1
	ok(SimHash.stateHash(S).gameplay != h0, "its state is in the hash")
	S.fighters[0].kik.turn -= 1
	var d0: String = NetDesync.digest(S)
	S.fighters[0].kik.t += 1
	ok(NetDesync.digest(S) != d0, "its state is in the desync digest")
	SimCore.dispose(S)
	ok(SimReplay.dataHash({"kick": true}) != SimReplay.dataHash({"kick": false}), "the data is in a replay's key with it on")


func _init() -> void:
	ok(SimKick.errors().is_empty(), "the data loads: %s" % str(SimKick.errors()))
	ok(not SimKick.enabled(), "the switch is off")
	ok(not SimKick.overOn, "the overspeed's switch is off")
	var D := _mk(3000.0)
	ok(D.kickInstant == SimKick.instant and D.kickClimb == SimKick.climbTicks, "with no word in the setup, the data's values")
	SimCore.dispose(D)
	_shape(SimKick.instant, SimKick.climbTicks)
	_shape(0.9, 6)
	_shape(0.8, 12)
	_shape(1.0, 0)
	_coin()
	_keep()
	SimKick.overOn = true   # the limits on the overspeed, for when it's on
	_toward()
	_away()
	_repeat()
	_zip()
	SimKick.overOn = false
	_noInvul()
	_whole()
	print("KICK: %d check(s) failed" % fails)
	quit(1 if fails > 0 else 0)
